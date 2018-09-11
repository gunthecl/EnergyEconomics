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
sets, param = load_data(8760, "test_data")
results = invest(sets, param, GurobiSolver())

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
for z in sets["Zones"]
    cap = vcat(cap, Array(Array(results[z]["Capacity"])'))
    cap_name = names(results[z]["Capacity"])[1]
    ctg = repeat(cap_name, inner=length(sets["Zones"]))
    name = repeat(sets["Zones"], outer=length(cap_name))
end
cap = cap[setdiff(1:end, 1), :]
groupedbar(name, cap, group = ctg, bar_position=:stack, lw=0)
