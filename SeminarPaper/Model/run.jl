# ------------------------------------------------------------------------------
# load Julia packages
# ------------------------------------------------------------------------------
using NamedArrays
using JuliaDB
using DataStructures
using RData
using CSV
using DataFrames
using Dates
using JuMP
using Gurobi
using Plots, StatPlots, UnicodePlots

# include functions
include("load_data.jl")
include("load_rdata.jl")
include("save_data.jl")
include("greenfield_stoch.jl")
include("greenfield_determ.jl")

# ------------------------------------------------------------------------------
# load input data
# ------------------------------------------------------------------------------
folder      = "input_data"      # input data folder
resShare    = 80                # RES share in %
bisect      = true              # true = take every second hour
hSto        = 1:24              # number of timesteps in stochastic model
hDet        = 1:4380            # numer of timesteps in deterministic model

sets, param = load_data(folder, bisect, resShare)

# TODO: 2015 whole time series, all 5 years every second hour
results  = Dict()
results["Stochastic"] = invest_stochastic(sets, param, h_stoch, GurobiSolver())
results["Deterministic"] = Dict()
for year in sets["Years"]
    if year == "2016"

    else
        results["Deterministic"][year] = invest_deterministic(sets, param,
            year, h_det, GurobiSolver())
    end
end

hours_det = string(length(hDet))
hours_sto = string(length(hSto))
save_data(results, resShare, Dates.now(), hours_det, hours_sto)

s = "Deterministic"
# quick overview
for z in sets["Zones"]
    capacity = round.(Array(results[s]["2015"][z]["Capacity"])./1000,1)
    capacity_type = names(results[s]["2015"][z]["Capacity"])[1]
    storage_type = names(results[s]["2015"][z]["Storage Power"])[1]
    storage = round.(Array(results[s]["2015"][z]["Storage Power"])./1000,1)
    label = vcat(capacity_type, storage_type)
    data = vcat(capacity, storage)
    display(barplot(label, data, title=string(z, " installed capacity [GW]")))
end
