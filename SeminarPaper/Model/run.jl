# ------------------------------------------------------------------------------
# load Julia packages
# ------------------------------------------------------------------------------
using NamedArrays
using JuliaDB
using DataStructures
using RData
using JuMP
using Gurobi
using Plots, StatPlots, UnicodePlots

# include functions
include("load_data.jl")
include("load_rdata.jl")
include("greenfield_stoch.jl")
include("greenfield_determ.jl")

# ------------------------------------------------------------------------------
# load input data
# ------------------------------------------------------------------------------
sets, param = load_data("input_data", false, 80)

# TODO: 2015 whole time series, all 5 years every second hour
results  = Dict()
results["Stochastic"] = invest_stochastic(sets, param, 1:24, GurobiSolver())
for year in sets["Years"]
    results["Deterministic"] = Dict()
    results["Deterministic"][year] = invest_deterministic(sets, param,
        year, 1:8760, GurobiSolver())
end

s = "Deterministic"
# quick overview
for z in sets["Zones"]
    capacity = round.(Array(results[s]["1987"][z]["Capacity"])./1000,1)
    capacity_type = names(results[s]["1987"][z]["Capacity"])[1]
    storage_type = names(results[s]["1987"][z]["Storage Power"])[1]
    storage = round.(Array(results[s]["1987"][z]["Storage Power"])./1000,1)
    label = vcat(capacity_type, storage_type)
    data = vcat(capacity, storage)
    display(barplot(label, data, title=string(z, " installed capacity [MW]")))
end

# Convert to exportable dataframe format
x = convert(Array, results["Deterministic"]["1987"]["UK"]["Capacity"])
df = DataFrame(x)
names!(df, [Symbol(t) for t in sets["Tech"]])
CSV.write("test", df)
