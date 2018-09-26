# ------------------------------------------------------------------------------
# load Julia packages
# ------------------------------------------------------------------------------
#using Plots, StatPlots
using NamedArrays
using JuliaDB
using DataStructures
using RData
using JuMP
using Gurobi
using UnicodePlots

# include functions
include("load_data.jl")
include("load_rdata.jl")
include("greenfield_stoch.jl")
include("greenfield_determ.jl")

# ------------------------------------------------------------------------------
# load input data
# ------------------------------------------------------------------------------
sets, param = load_data("input_data")

results  = Dict()
results["Stochastic"] = invest_stochastic(sets, param, 1:24, GurobiSolver())
for year in sets["Years"]
    results["Deterministic"] = Dict()
    results["Deterministic"][year] = invest_deterministic(sets, param,
        year, 1:4380, GurobiSolver())
end

s = "Stochastic"
# quick overview
for z in sets["Zones"]
    capacity = round.(Array(results[s][z]["Capacity"])./1000,1)
    capacity_type = names(results[s][z]["Capacity"])[1]
    storage_type = names(results[s][z]["Storage Power"])[1]
    storage = round.(Array(results[s][z]["Storage Power"])./1000,1)
    label = vcat(capacity_type, storage_type)
    data = vcat(capacity, storage)
    display(barplot(label, data, title=string(z, " installed capacity [MW]")))
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


for year in names(param["Deterministic Data"])
    for series in names(param["Deterministic Data"][year])
        param["Deterministic Data"][year][series] = savg(param["Deterministic Data"][year][series])
    end
end

function savg(named_array)
    hour = collect(1:4380)
    id   = names(named_array)[2]
    arr = Array{Any}(4380,6)
    avg = Array{Any}(8760,6)
    i = 1
    x = 1
    while i < size(a)[1]
        for j = collect(1:6)
            avg[i,j] = (a[i,j]+a[i+1,j])/2
        end
        arr[x,:] = avg[i,:]
        i = i+2
        x = x+1
    end
    avg_array = NamedArray(arr, (hour, id), ("Hours", "Zones"))
end
