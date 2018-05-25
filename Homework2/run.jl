cd("/Users/claudiaguenther/Documents/Studium/MEMS/SS2018/EnergyEconomics/Template2")
using JuliaDB
using NamedArrays
using Plots
using Revise
include("model/template.jl")
using TransportModel

###############################################################################
# Load data from csv files #
###############################################################################
plant_data = loadtable("data/plant_data.csv")
storage_data = loadtable("data/storage_data.csv")
demand_data = loadtable("data/demand.csv")
zone_data = loadtable("data/zone_data.csv")
mc_data = loadtable("data/mc.csv")
pv_availability = loadtable("data/pv_availability.csv")
wind_availability = loadtable("data/wind_availability.csv")
ntc_data = loadtable("data/ntc.csv")

###############################################################################
# Derive sets from loaded data #
###############################################################################

TECH = select(mc_data, :technology)
TECH = convert(Array, TECH)

PLANTS = select(plant_data, :plant)
PLANTS = convert(Array, PLANTS)

DISP = select(filter(row-> row.type == "disp", plant_data), :plant)
DISP = convert(Array, DISP)

NONDISP = select(filter(row-> row.type == "nondisp", plant_data), :plant)
NONDISP = convert(Array, NONDISP)

CONV = select(filter(row-> row.category == "conventional", plant_data), :plant)
CONV = convert(Array, CONV)

RES = select(filter(row-> row.category == "renewable", plant_data), :plant)
RES = convert(Array, RES)

STOR = Array(select(storage_data, :plant))

ZONES = select(zone_data, :zone)
ZONES = convert(Array, ZONES)

NONDISP_TECH = ["Wind", "Solar"]

PLANT_TECH = Dict()
for tech in TECH
    PLANT_TECH[tech] = convert(Array, select(filter(row-> row.technology == tech, plant_data), :plant))
end
PLANT_ZONE = Dict()
for zone in ZONES
    PLANT_ZONE[zone] = convert(Array, select(filter(row-> row.zone == zone, plant_data), :plant))
end

STOR_ZONE = Dict()
for zone in ZONES
    STOR_ZONE[zone] = convert(Array, select(filter(row-> row.zone == zone, storage_data), :plant))
end

NONDISP_ZONES = Dict()
for tech in NONDISP_TECH, zone in ZONES
    plants = []
    for plant in intersect(PLANT_TECH[tech], PLANT_ZONE[zone])
        push!(plants, plant)
    end
    NONDISP_ZONES[zone, tech] = plants
end

ZONE_PLANTS = Dict(collect(zip(columns(plant_data, :plant), columns(plant_data, :zone))))


TECH_PLANTS = Dict(collect(zip(columns(plant_data, :plant), columns(plant_data, :technology))))

###############################################################################
# Save sets into a dict #
###############################################################################
sets = Dict(
    "Tech" => TECH,
    "Plants" => PLANTS,
    "Conv" => CONV,
    "Res" => RES,
    "Disp" => DISP,
    "Nondisp" => NONDISP,
    "Stor" => STOR,
    "Zones" => ZONES,
    "Plant_Zone" => PLANT_ZONE,
    "Storage_Zone" => STOR_ZONE,
    "Plant_Tech" => PLANT_TECH,
    "Nondisp_Zones" => NONDISP_ZONES,
    "Nondisp_Tech" => NONDISP_TECH)

###############################################################################
# Create NamedArrays containing the parameters #
###############################################################################
stor_max = NamedArray(select(storage_data, :capacity), (STOR,), ("Storage",))

stor_g_max = NamedArray(select(storage_data, :generation), (STOR,), ("Storage",))

hours = select(demand_data, 1)

g_max = NamedArray(select(plant_data, :capacity), (PLANTS,), ("Plants",))


demand_array = hcat([select(demand_data, :demand).* columns(zone_data, :demand_share)[i] for i in 1:length(ZONES)]...)


demand = NamedArray(demand_array, (hours,ZONES), ("Hours","Zone"))

ntc_array = hcat([select(ntc_data, Symbol(z)) for z in ZONES]...)

ntc = NamedArray(ntc_array, (ZONES,ZONES), ("from_zone","to_zone"))

#### NTC Scaling

# ntc *= 0.5 ## 50% Capacitys

# Set ntc to zero
ntc *= 0


co2price = 14
mc_tech = select(mc_data, :fuelcost) ./ select(mc_data, :efficiency) + select(mc_data, :sef) .* co2price + select(mc_data, :om)
mc_tech = NamedArray(mc_tech, (TECH,), ("tech",))


mc = NamedArray([mc_tech[tech] for tech in columns(plant_data, :technology)], (PLANTS,),("plant",))

availability_wind_array = hcat([columns(wind_availability, Symbol(z)) for z in ZONES]...)

availability_pv_array = hcat([columns(pv_availability, Symbol(z)) for z in ZONES]...)


combined_avail_array = reshape(hcat(availability_wind_array, availability_pv_array),8760, 4, 2)
availability = NamedArray(combined_avail_array, (hours, ZONES, ["Wind", "Solar"]), ("Hour", "Zone", "Technology"))

g_res_array = zeros(length(NONDISP), length(hours))
for (i,plant) in enumerate(NONDISP), (j,hour) in enumerate(hours)
    g_res_array[i, j] = availability[hour,ZONE_PLANTS[plant],TECH_PLANTS[plant]] .* g_max[plant]
end

g_res = NamedArray(g_res_array, (NONDISP, hours), ("Plants", "Hours"))

###############################################################################
# Save parameters as a dict #
###############################################################################

param = Dict(
    "g_max" => g_max,
    "demand" => demand,
    "g_res" => g_res,
    "mc" => mc,
    "stor_max" => stor_max,
    "stor_g_max" => stor_g_max,
    "ntc" => ntc)

###############################################################################
# Run the model #
###############################################################################
results = TransportModel.transport_model(sets, param, timeset=1:168)

###############################################################################
# Process the Results
###############################################################################

function gen_by_zone(result_dict::Dict)
    gen = vcat(result_dict["Generation"], result_dict["Generation_Res"])
    setnames!(gen, PLANTS, 1)
    return Dict(zone => gen[PLANT_ZONE[zone],:] for zone in ZONES)
end

function sum_by_tech(gen_array)
    plants_in_zone = names(gen_array, 1)
    tech_in_zone = Array([Set([TECH_PLANTS[plant] for plant in plants_in_zone])...])
    gen_by_tech = hcat([sum(gen_array[plant,:] for plant in PLANT_TECH[tech] if plant in plants_in_zone) for tech in tech_in_zone]...)
    setnames!(gen_by_tech, tech_in_zone, 2)
    return gen_by_tech
end

function plot_dispatch_per_zone(result_dict::Dict)
    color_dict = Dict(
                "Nuclear" => :red,
                "Lignite" => :brown,
                "Hard coal" => :grey,
                "Natural gas" => :orange,
                "Biomass" => :green,
                "Wind" => :blue,
                "Solar" => :yellow,
                "PSP" => :lightblue,
                "Battery" => :purple )

    plots = []
    gen_by_zone_dict = gen_by_zone(result_dict)
    for (i,zone) in enumerate(ZONES)
        gen_by_tech = sum_by_tech(gen_by_zone_dict[zone])
        techs = names(gen_by_tech, 2)
        colors = reshape([color_dict[tech] for tech in techs], 1, length(techs))
        i == 3 ? leg = :topleft : leg = false
        new_plot = areaplot(gen_by_tech,
            label=techs,
            c=colors,
            legend=leg,
            title=zone
            )
        plot!(new_plot, demand[1:168, zone], c="black", label="Demand", width=3)
        push!(plots, new_plot)
    end
    return plot(plots...)
end

dispatch_plot = plot_dispatch_per_zone(results)
#savefig(dispatch_plot, "Dispatch_plot3a.pdf")

# Use when you have implemented the zonal energy balance
price_plot = plot(results["Price"]', label=ZONES, width=3)
#savefig(price_plot, "Price_plot3a.pdf")
