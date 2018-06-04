
module TransportModel

using JuMP
using Clp
using Plots
using RecipesBase
using NamedArrays

export transport_model, areaplot

function transport_model(sets::Dict, param::Dict; timeset::UnitRange=1:8760, solver=ClpSolver())

    PLANTS = sets["Plants"]
    DISP = sets["Disp"]
    NONDISP = sets["Nondisp"]
    STOR = sets["Stor"]
    ZONES = sets["Zones"]
    PLANT_ZONE = sets["Plant_Zone"]
    PLANT_TECH = sets["Plant_Tech"]
    STOR_ZONE = sets["Storage_Zone"]
    NONDISP_ZONES = sets["Nondisp_Zones"]
    NONDISP_TECH = sets["Nondisp_Tech"]

    demand = param["demand"]
    g_max = param["g_max"]
    mc = param["mc"]
    g_res = param["g_res"]
    stor_max = param["stor_max"]
    stor_g_max = param["stor_g_max"]
    ntc = param["ntc"]

    HOUR = collect(timeset)

    println("Building Model")
    transport_problem = Model(solver=solver)
    @variables transport_problem begin
            G[DISP, HOUR] >= 0
            G_RES[NONDISP, HOUR] >= 0
            G_stor[STOR, HOUR] >= 0 #generation from storage
            L[STOR, HOUR] >= 0 #current storage level
            D_stor[STOR, HOUR] >= 0 #consumption from storage
            EX[ZONES, ZONES, HOUR] >= 0 #Exchange between zones
    end

    for s in STOR
        JuMP.fix(L[s, HOUR[1]], 0)
        JuMP.fix(L[s, HOUR[end]], 0)
        JuMP.fix(G_stor[s, HOUR[1]], 0)
    end

    @objective(transport_problem, Min,
        sum(mc[disp] * G[disp, hour] for disp in DISP, hour in HOUR)
        );

    # Add zonal market clearing constraint for transport model
    @constraint(transport_problem, Market_Clearing[zone=ZONES, hour=HOUR],
        sum(G[disp, hour] for disp in intersect(DISP , PLANT_ZONE[zone]))
        + sum(G_RES[nondisp, hour] for nondisp in intersect(NONDISP , PLANT_ZONE[zone]))
        + sum(G_stor[stor, hour] for stor in intersect(STOR , STOR_ZONE[zone]))
        ==
        demand[hour, zone]
        - sum(EX[from_zone, zone, hour] for from_zone in ZONES)
        + sum(EX[zone, to_zone, hour] for to_zone in ZONES)
        + sum(D_stor[stor, hour] for stor in intersect(STOR , STOR_ZONE[zone])));

    @constraint(transport_problem, NTC[to_zone=ZONES, from_zone=ZONES,hour=HOUR],
        EX[from_zone, to_zone, hour] <= ntc[from_zone, to_zone]);

    @constraint(transport_problem, Max_Generation[disp=DISP, hour=HOUR],
        G[disp, hour] <= g_max[disp] );

    @constraint(transport_problem, Curtailment[nondisp=NONDISP, hour=HOUR],
        G_RES[nondisp, hour] <= g_res[nondisp, hour]);

    @constraint(transport_problem, Storage_Level[sto=STOR, hour=HOUR; hour != HOUR[1]],
        L[sto, hour] == L[sto, hour-1] + 0.88*D_stor[sto, hour] - G_stor[sto, hour] );

    @constraint(transport_problem, Max_Storage_Level[sto=STOR, hour=HOUR],
        L[sto, hour] <= stor_max[sto] );

    @constraint(transport_problem, Max_Storage_Generation[sto=STOR, hour=HOUR],
        G_stor[sto, hour] <= stor_g_max[sto] );

    @constraint(transport_problem, Max_Storage_Withdraw[sto=STOR, hour=HOUR],
        D_stor[sto, hour] <= stor_g_max[sto]);

    println("Start solving")

    status = solve(transport_problem)
    println(status)
    results = Dict()

    results["Generation"] = NamedArray(getvalue(G).innerArray, (DISP, HOUR), ("Plant", "Hour"))
    results["Generation_Res"] = NamedArray(getvalue(G_RES).innerArray, (NONDISP, HOUR), ("Plant", "Hour"))
    results["Storage"] = NamedArray(getvalue(G_stor).innerArray, (STOR, HOUR), ("Plant", "Hour"))

    # Use when you have implemented the zonal energy balance
    results["Price"] = NamedArray(getdual(Market_Clearing).innerArray, (ZONES, HOUR), ("Zone", "Hour"))
    return results
end

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
end
