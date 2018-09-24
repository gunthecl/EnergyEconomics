#function invest(sets::Dict, param::Dict, timeset::UnitRange=1:8760,
                solver=solver)
timeset = 1:24
    HOURS   = collect(timeset)
    SCEN    = sets["Scenarios"]
    TECH    = sets["Tech"]
    DISP    = sets["Disp"]
    NONDISP = sets["Nondisp"]
    ZONES   = sets["Zones"]
    STOR    = sets["Storage"]

    Invest = Model(solver=GurobiSolver())

    # generation
    @variable(Invest, G[SCEN, HOURS, ZONES, TECH]      >= 0)  # electricity generation
    @variable(Invest, G_STOR[SCEN, HOURS, ZONES, STOR] >= 0)  # storage generation
    @variable(Invest, D_STOR[SCEN, HOURS, ZONES, STOR] >= 0)  # storage consumption
    @variable(Invest, L_STOR[SCEN, HOURS, ZONES, STOR] >= 0)  # storage level
    # capacities
    @variable(Invest, CAP[ZONES, TECH]      >= 0) # installed capacity
    @variable(Invest, CAP_ST_E[ZONES, STOR] >= 0) # storage energy
    @variable(Invest, CAP_ST_P[ZONES, STOR] >= 0) # storage power
    # renewables
    @variable(Invest, CU[SCEN, HOURS, ZONES, NONDISP] >= 0) # curtailment
    # exports
    @variable(Invest, EX[SCEN, HOURS, ZONES, ZONES] >= 0)
    # fix variables
    for scen in SCEN, zone in ZONES, stor in STOR
        JuMP.fix(G_STOR[scen, HOURS[1], zone, stor], 0)
        JuMP.fix(L_STOR[scen, HOURS[1], zone, stor], 0)
    end
    # objective function
    @objective(Invest, Min,
        + sum(param["Annuity"][tech] * CAP[zone, tech]
            for tech in TECH, zone in ZONES)
        + 0.5 * sum(param["AnnuityPower"][stor] * CAP_ST_P[zone, stor]
            for stor in STOR, zone in ZONES)
        + 0.5 * sum(param["AnnuityEnergy"][stor] * CAP_ST_E[zone, stor]
            for stor in STOR, zone in ZONES)
        + sum(param["Scenario Data"][scen]["Weight"] *
            param["MarginalCost"][tech] * G[scen, hour, zone, tech]
            for scen in SCEN, hour in HOURS, tech in TECH, zone in ZONES)
        );
    # constraints
    @constraint(Invest, EnergyBalance[scen=SCEN, hour=HOURS, zone=ZONES],
        sum(G[scen, hour, zone, tech] for tech in TECH)
        + sum(G_STOR[scen, hour, zone, stor] for stor in STOR)
        ==
        param["Scenario Data"][scen]["Demand"][hour, zone]
        - sum(EX[scen, hour, from_zone, zone] for from_zone in ZONES)
        + sum(EX[scen, hour, zone, to_zone] for to_zone in ZONES)
        + sum(D_STOR[scen, hour, zone, stor] for stor in STOR)
    );

    @constraint(Invest, NTC[scen=SCEN, hour=HOURS, to_zone=ZONES,
        from_zone=ZONES],
        EX[scen, hour, from_zone, to_zone] <= param["NTC"][from_zone, to_zone]
    );

    @constraint(Invest, MaxGeneration[scen=SCEN, hour=HOURS, zone=ZONES,
        disp=DISP],
        G[scen, hour, zone, disp] <= CAP[zone, disp]
    );

    @constraint(Invest, StorageLevel[scen=SCEN, hour=HOURS, zone=ZONES,
        stor=STOR; hour != HOURS[1]],
        L_STOR[scen, hour, zone, stor]
        ==
        L_STOR[scen, hour-1, zone, stor] + param["Storage Efficiency"][stor] *
        D_STOR[scen, hour, zone, stor] - G_STOR[scen, hour, zone, stor]
    );

    @constraint(Invest, StorageLevelEquality[scen=SCEN, zone=ZONES, stor=STOR],
        L_STOR[scen, HOURS[1], zone, stor]
        ==
        L_STOR[scen, HOURS[end], zone, stor]
    );

    @constraint(Invest, MaxStorageLevel[scen=SCEN, hour=HOURS, zone=ZONES,
        stor=STOR],
        L_STOR[scen, hour, zone, stor] <= CAP_ST_E[zone, stor]
    );

    @constraint(Invest, MaxStorageGeneration[scen=SCEN, hour=HOURS,
        zone=ZONES, stor=STOR],
        G_STOR[scen, hour, zone, stor] <= CAP_ST_P[zone, stor]
    );

    @constraint(Invest, MaxStorageWithdraw[scen=SCEN, hour=HOURS, zone=ZONES,
        stor=STOR],
        D_STOR[scen, hour, zone, stor] <= CAP_ST_P[zone, stor]
    );

    @constraint(Invest, StorageGeneration[scen=SCEN, hour=HOURS, zone=ZONES,
        stor=STOR; hour != HOURS[1]],
        G_STOR[scen, hour, zone, stor] <= L_STOR[scen, hour-1, zone, stor]
    );

    @constraint(Invest, StorageWithdraw[scen=SCEN, hour=HOURS, zone=ZONES,
        stor=STOR; hour != HOURS[1]],
        D_STOR[scen, hour, zone, stor]
        <=
        CAP_ST_P[zone, stor] - L_STOR[scen, hour-1, zone, stor]
    );

    lenResConst = length(SCEN)*length(HOURS)*length(ZONES)*length(NONDISP)
    i = 1
    @constraintref ResAvailability[1:lenResConst]
    for scen in SCEN, hour in HOURS, zone in ZONES, ndisp in NONDISP
        if ndisp != "PVRoof" && ndisp != "PVGround"
            ResAvailability[i] = @constraint(Invest,
                G[scen, hour, zone, ndisp]
                <=
                param["Scenario Data"][scen][ndisp][hour, zone] *
                CAP[zone, ndisp]
                );
            i = i + 1
        else
            ResAvailability[i] = @constraint(Invest,
                G[scen, hour, zone, ndisp]
                <=
                param["Scenario Data"][scen]["PV"][hour, zone] *
                CAP[zone, ndisp]
                );
            i = i+1
        end
    end

    #TODO: add RES/storage maximum capacity restriction per zone

    @constraint(Invest, ResQuota[zone=ZONES],
        sum(G[hour, zone, ndisp] for hour in HOURS, ndisp in NONDISP)
        ==
        param["ResShare"][zone]/100 *
        sum(param["Demand"][hour] for hour in HOURS)
    );
    # call solver
    status = solve(Invest)
    # format solution
    # TODO: account for scenarios
    generation = NamedArray(getvalue(G.innerArray), (HOURS, ZONES, TECH),
        ("Hour", "Zone", "Technology"))
    storage_gen = NamedArray(getvalue(G_STOR.innerArray), (HOURS, ZONES, STOR),
        ("Hour", "Zone", "Technology"))
    storage_con = NamedArray(getvalue(D_STOR.innerArray), (HOURS, ZONES, STOR),
        ("Hour", "Zone", "Technology"))
    storage_lvl = NamedArray(getvalue(L_STOR.innerArray), (HOURS, ZONES, STOR),
        ("Hour", "Zone", "Technology"))

    cap = NamedArray(getvalue(CAP.innerArray), (ZONES, TECH),
        ("Zone", "Technology"))
    cap_stor_energy = NamedArray(getvalue(CAP_ST_E.innerArray), (ZONES, STOR),
        ("Zone", "Technology"))
    cap_stor_power = NamedArray(getvalue(CAP_ST_P.innerArray), (ZONES, STOR),
        ("Zone", "Technology"))
    curtailment = NamedArray(getvalue(CU.innerArray), (HOURS, ZONES, NONDISP),
        ("Hour", "Zone", "Technology"))
    exchange = NamedArray(getvalue(EX.innerArray), (HOURS, ZONES, ZONES),
        ("Hour", "From_Zone", "To_Zone"))
    price = NamedArray(getdual(EnergyBalance).innerArray, (HOURS, ZONES),
        ("Hour", "Zone"))

    # store results
    results = Dict()
    for zone in ZONES
        results[zone] = Dict()
        results[zone]["Generation"] = generation[:, zone, :]
        results[zone]["Storage Generation"] = storage_gen[:, zone, :]
        results[zone]["Storage Consumption"] = storage_con[:, zone, :]
        results[zone]["Storage Level"] = storage_lvl[:, zone, :]
        results[zone]["Capacity"] = cap[zone, :]
        results[zone]["Storage Energy"] = cap_stor_energy[zone, :]
        results[zone]["Storage Power"] = cap_stor_power[zone, :]
        results[zone]["Curtailment"] = curtailment[:, zone, :]
        results[zone]["Exchange"] = exchange[:, :, zone]
        results["Price"] = price
    end

    #return results

end
