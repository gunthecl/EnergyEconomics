# ------------------------------------------------------------------------------
# load Julia packages
# ------------------------------------------------------------------------------
#using Plots, StatPlots
using NamedArrays
using JuliaDB
using RData
using JuMP
using Gurobi

# include functions
include("load_data.jl")
include("load_rdata.jl")
include("greenfield.jl")

# ------------------------------------------------------------------------------
# load input data
# ------------------------------------------------------------------------------
sets, param = load_data("input_data")
results = invest(sets, param, 1:200, GurobiSolver())

# quick Overview
for z in sets["Zones"]
    print("\n\n\n------------------ $z ------------------\n\n\n")
    capacity = round.(Array(results[z]["Capacity"])./1000,1)
    capacity_type = names(results[z]["Capacity"])[1]
    display(barplot(capacity_type, capacity,
                    title=string(z, " installed capacity [MW]")))
    gen_sum = sum(Array(results[z]["Generation"]))
    stor_gen_sum = sum(Array(results[z]["Storage Generation"]))
    stor_con_sum = sum(Array(results[z]["Storage Consumption"]))
    ex_sum = sum(Array(results[z]["Exchange"]))
    total_gen = gen_sum + stor_gen_sum - stor_con_sum + ex_sum
    demand = sum(Array(param["Demand"][:, z]))
    display(barplot(["Total Generation", "Demand"], [total_gen, demand]))
end

# generation plot
cap = zeros(1,5)
cap_name = sets["Tech"]
ctg = repeat(cap_name, inner=length(sets["Zones"]))
name = repeat(sets["Zones"], outer=length(cap_name))
for z in sets["Zones"]
    cap = vcat(cap, Array(Array(results[z]["Capacity"])'))
end
cap = cap[setdiff(1:end, 1), :]
groupedbar(name, cap/1e3, group = ctg, bar_position=:stack, lw=0,
            ylabel = "installed capacity in MW", framestyle=:box)

# TODO: time series plot

@userplot Areaplot
@recipe function f(a::Areaplot)
    data = cumsum(a.args[1], 2)

    seriestype := :line
    fillrange := 0

    @series begin
        data[:,1]
    end

    for i in 2:size(data, 2)
    @series begin
            fillrange := data[:,i-1]
            data[:,i]
        end
    end
end
