# ------------------------------------------------------------------------------
# load Julia packages
# ------------------------------------------------------------------------------
#using Plots, StatPlots
using NamedArrays
using JuliaDB
using JuMP
using Gurobi

# include functions
include("load_data.jl")
include("greenfield.jl")

# ------------------------------------------------------------------------------
# load input data
# ------------------------------------------------------------------------------
sets, param = load_data("test_data")
results = invest(sets, param, GurobiSolver())

# Quick Overview
for z in sets["Zones"]
    capacity = round.(Array(results[z]["Capacity"])./1000,1)
    capacity_type = names(results[z]["Capacity"])[1]
    display(barplot(capacity_type, capacity,
                    title=string(z, " installed capacity [MWh]")))
end
