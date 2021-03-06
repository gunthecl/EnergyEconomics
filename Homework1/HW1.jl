using JuMP
using Gurobi
using Plots
using RecipesBase
using NamedArrays

HOUR = collect(1:24)
DISP = ["Nuclear",
        "Lignite",
        "Hard coal",
        "Natural gas"]
RES = ["Wind", "Solar"]
TECH = vcat(DISP, RES, "Storage gen")
demand = [60,
          59,
          56,
          58,
          64,
          69,
          79,
          85,
          81,
          79,
          78,
          78,
          80,
          81,
          82,
          83,
          84,
          85,
          89,
          88,
          86,
          82,
          80,
          71]
co_price = 7
c_fuel = NamedArray([3, 6.21, 10.6, 31.08], (DISP,), ("Technologies",))
eta    = NamedArray([0.33, 0.42, 0.42, 0.59], (DISP,), ("Technologies",))
om     = NamedArray([10, 6, 6, 2], (DISP,), ("Technologies",))
lambda = NamedArray([0, 0.399, 0.337, 0.201], (DISP,), ("Technologies",))
mc = c_fuel ./ eta + co_price .* lambda + om

g_max = NamedArray([20, 30, 25, 15], (DISP,), ("Technologies",))
solar_availability = [
0
0
0
0.004
0.027
0.071
0.129
0.2
0.281
0.377
0.429
0.433
0.364
0.287
0.197
0.113
0.04
0.001
0
0
0
0
0
0
]
wind_availability = [
0.323
0.337
0.354
0.385
0.402
0.395
0.379
0.378
0.372
0.369
0.379
0.386
0.375
0.344
0.299
0.259
0.233
0.209
0.152
0.098
0.085
0.089
0.113
0.155
]
installed_solar = 25
installed_wind = 40

res_infeed = hcat(wind_availability*installed_wind, solar_availability*installed_solar)'
g_res = NamedArray(res_infeed, (RES,HOUR), ("Renewable Energy Source", "Hour"))

#= Task 3 Renewables
res_availability     = hcat(wind_availability*installed_wind, solar_availability*installed_solar)'
g_max_res            = NamedArray([1,1], (RES,), ("Max. generation parameter",)) # which parameters should we use?
res_infeed           = hcat(res_availability.*g_max_res)
=#

storage_max = 15
storage_gen = 5

dispatch_problem = Model(solver=GurobiSolver())

@variables dispatch_problem begin
        G[DISP, HOUR] >= 0 # generation from power plants
        G_stor[HOUR] >= 0 #generation from storage
        L[HOUR] >= 0 #current storage level
        D_stor[HOUR] >= 0 #consumption from storage
end

#= Task 3 Renewables
@variables dispatch_problem begin
        G[DISP, HOUR] >= 0 # generation from power plants
        G_stor[HOUR] >= 0 #generation from storage
        L[HOUR] >= 0 #current storage level
        D_stor[HOUR] >= 0 #consumption from storage
        g_res[RES, HOUR] >= 0
end
=#

JuMP.fix(L[1], 0)
JuMP.fix(L[24], 0)
JuMP.fix(G_stor[1], 0)

#= Task 2a: Set the storage level to 50% in the first time step
JuMP.fix(L[1], storage_max*0.5)
JuMP.fix(L[24], 0)
=#

#= Task 2b: Set the storage level to 50% in the first and last time step
JuMP.fix(L[1], storage_max*0.5)
JuMP.fix(L[24], storage_max*0.5)
=#

#= Task 2c: Force the start- and endlevel to be equal, without specifying a value

JuMP.fix(G_stor[1], 0)

start_end = [1,24]

@constraint(dispatch_problem, storage_restr[hour=start_end],
    L[1] == L[24]
);
=#

@objective(dispatch_problem, Min,
    sum(mc[disp] * G[disp, hour] for disp in DISP, hour in HOUR));

@constraint(dispatch_problem, Market_Clearing[hour=HOUR],
sum(G[disp, hour] for disp in DISP)
+ sum(g_res[res, hour] for res in RES)
+ G_stor[hour]
==
demand[hour]
+ D_stor[hour]
);

@constraint(dispatch_problem, Max_Generation[disp=DISP, hour=HOUR],
    G[disp, hour] <= g_max[disp]
);

@constraint(dispatch_problem, Storage_Level[hour=HOUR; hour != 1],
    L[hour] == L[hour-1] + 0.88*D_stor[hour] - G_stor[hour]
);

@constraint(dispatch_problem, Max_Storage_Level[hour=HOUR],
    L[hour] <= storage_max
);

@constraint(dispatch_problem, Max_Storage_Withdraw[hour=HOUR],
    D_stor[hour] <= storage_gen
);

#= Task 3 Renewables
# 3a: No curtailment and storages
@constraint(dispatch_problem, Res_Generation_max[res=RES, hour=HOUR],
    g_res[res, hour] <= res_infeed[res, hour]
);

# 3b: Curtailment, but no storages
@constraint(dispatch_problem, Res_Generation_max[res=RES, hour=HOUR],
    g_res[res, hour] <= res_infeed[res, hour]
);

@constraint(dispatch_problem, Res_Generation_min[res=RES, hour=HOUR],
    g_res[res, hour] <= res_infeed[res, hour]*0.9
);

# Remember to disable storages!

# 3b: Curtailment and storages
@constraint(dispatch_problem, Res_Generation_max[res=RES, hour=HOUR],
    g_res[res, hour] <= res_infeed[res, hour]
);

@constraint(dispatch_problem, Res_Generation_min[res=RES, hour=HOUR],
    g_res[res, hour] <= res_infeed[res, hour]*0.9
);

=#

solve(dispatch_problem)

result = vcat(getvalue(G).innerArray, g_res, getvalue(G_stor).innerArray')'
generation = NamedArray(result, (HOUR, TECH), ("Hour", "Technology"))
storage_withdraw = -getvalue(D_stor).innerArray
storage_level = getvalue(L).innerArray
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
l = @layout([a{0.9h};b])
dispatch_plot = areaplot(generation, label=TECH, title="Dispatch",
    color=reshape([:red, :brown, :grey, :orange, :blue, :yellow, :purple],1, length(TECH)),
    legend=:bottomleft)
plot!(dispatch_plot, storage_withdraw, fill=0, label="Storage withdraw", color=:purple)
plot!(dispatch_plot, demand, c=:black, label="Demand", width=3, legend=:bottomright)

level_plot = plot(storage_level, width=2, color=:black, legend=false, title="Storage level")


plot(dispatch_plot,level_plot, layout=l)
savefig("dispatch.pdf")
# Calculate total costs (marginal cost * production)
all_mc = vcat(mc,0,0,0)
hourly_cost = generation*all_mc
total_cost = sum(hourly_cost)
# Crosscheck calculated costs

getobjectivevalue(dispatch_problem::Model)
