function invest_deterministic(sets::Dict, param::Dict, year::String,
    timeset::UnitRange=1:8760, solver=solver)

    HOURS   = collect(timeset)
    TECH    = sets["Tech"]
    DISP    = sets["Disp"]
    NONDISP = sets["Nondisp"]
    ZONES   = sets["Zones"]
    STOR    = sets["Storage"]

    Invest = Model(solver=GurobiSolver())

    # generation
    @variable(Invest, G[HOURS, ZONES, TECH]      >= 0)  # electricity generation
    @variable(Invest, G_STOR[HOURS, ZONES, STOR] >= 0)  # storage generation
    @variable(Invest, D_STOR[HOURS, ZONES, STOR] >= 0)  # storage consumption
    @variable(Invest, L_STOR[HOURS, ZONES, STOR] >= 0)  # storage level
    # capacities
    @variable(Invest, CAP[ZONES, TECH]      >= 0) # installed capacity
    @variable(Invest, CAP_ST_E[ZONES, STOR] >= 0) # storage energy
    @variable(Invest, CAP_ST_P[ZONES, STOR] >= 0) # storage power
    # renewables
    @variable(Invest, CU[HOURS, ZONES, NONDISP] >= 0) # curtailment
    # exports
    @variable(Invest, EX[HOURS, ZONES, ZONES] >= 0)
    # fix variables
    for zone in ZONES, stor in STOR
        JuMP.fix(G_STOR[HOURS[1], zone, stor], 0)
        JuMP.fix(L_STOR[HOURS[1], zone, stor], 0)
    end
    # objective function
    @objective(Invest, Min,
        + sum(param["Annuity"][tech] * CAP[zone, tech]
            for tech in TECH, zone in ZONES)
        + 0.5 * sum(param["AnnuityPower"][stor] * CAP_ST_P[zone, stor]
            for stor in STOR, zone in ZONES)
        + 0.5 * sum(param["AnnuityEnergy"][stor] * CAP_ST_E[zone, stor]
            for stor in STOR, zone in ZONES)
        + sum(param["MarginalCost"][tech] * G[hour, zone, tech]
            for hour in HOURS, tech in TECH, zone in ZONES)
        + sum(param["Storage MarginalCost"][stor] * G_STOR[hour, zone, stor]
            for hour in HOURS, stor in STOR, zone in ZONES)
        );
    # constraints
    @constraint(Invest, EnergyBalance[hour=HOURS, zone=ZONES],
        sum(G[hour, zone, tech] for tech in TECH)
        + sum(G_STOR[hour, zone, stor] for stor in STOR)
        ==
        param["Deterministic Data"][year]["Demand"][hour, zone]
        - sum(EX[hour, from_zone, zone] for from_zone in ZONES)
        + sum(EX[hour, zone, to_zone] for to_zone in ZONES)
        + sum(D_STOR[hour, zone, stor] for stor in STOR)
    );

    @constraint(Invest, NTC[hour=HOURS, to_zone=ZONES,
        from_zone=ZONES],
        EX[hour, from_zone, to_zone] <= param["NTC"][from_zone, to_zone]
    );

    @constraint(Invest, MaxGeneration[hour=HOURS, zone=ZONES,
        disp=DISP],
        G[hour, zone, disp] <= CAP[zone, disp]
    );

    @constraint(Invest, StorageLevel[hour=HOURS, zone=ZONES,
        stor=STOR; hour != HOURS[1]],
        L_STOR[hour, zone, stor]
        ==
        L_STOR[hour-1, zone, stor] + param["Storage Efficiency"][stor] *
        D_STOR[hour, zone, stor] - G_STOR[hour, zone, stor]
    );

    @constraint(Invest, StorageLevelEquality[zone=ZONES, stor=STOR],
        L_STOR[HOURS[1], zone, stor]
        ==
        L_STOR[HOURS[end], zone, stor]
    );

    @constraint(Invest, MaxStorageLevel[hour=HOURS, zone=ZONES, stor=STOR],
        L_STOR[hour, zone, stor] <= CAP_ST_E[zone, stor]
    );

    @constraint(Invest, MaxStorageGeneration[hour=HOURS, zone=ZONES, stor=STOR],
        G_STOR[hour, zone, stor] <= CAP_ST_P[zone, stor]
    );

    @constraint(Invest, MaxStorageWithdraw[hour=HOURS, zone=ZONES, stor=STOR],
        D_STOR[hour, zone, stor] <= CAP_ST_P[zone, stor]
    );

    @constraint(Invest, StorageGeneration[hour=HOURS, zone=ZONES, stor=STOR;
        hour != HOURS[1]],
        G_STOR[hour, zone, stor] <= L_STOR[hour-1, zone, stor]
    );

    @constraint(Invest, StorageWithdraw[hour=HOURS, zone=ZONES, stor=STOR;
        hour != HOURS[1]],
        D_STOR[hour, zone, stor]
        <=
        CAP_ST_P[zone, stor] - L_STOR[hour-1, zone, stor]
    );

    lenResConst = length(HOURS)*length(ZONES)*length(NONDISP)
    i = 1
    @constraintref ResAvailability[1:lenResConst]
    for hour in HOURS, zone in ZONES, ndisp in NONDISP
        if ndisp != "PVRoof" && ndisp != "PVGround"
            ResAvailability[i] = @constraint(Invest,
                G[hour, zone, ndisp]
                <=
                param["Deterministic Data"][year][ndisp][hour, zone] *
                CAP[zone, ndisp]
                );
            i = i + 1
        else
            ResAvailability[i] = @constraint(Invest,
                G[hour, zone, ndisp]
                <=
                param["Deterministic Data"][year]["PV"][hour, zone] *
                CAP[zone, ndisp]
                );
            i = i+1
        end
    end

    @constraint(Invest, RESMax[zone=ZONES, ndisp=NONDISP],
        CAP[zone, ndisp] <= param["RES Potentials"][zone, ndisp]
        );

    @constraint(Invest, PumpStorMaxPower[zone=ZONES, stor=["PumpedStor"]],
        CAP_ST_P[zone, stor] <= param["Stor Potentials"][zone]
        );

    @constraint(Invest, ResQuota,
        sum(G[hour, zone, ndisp] for hour in HOURS, zone in ZONES,
            ndisp in NONDISP)
        ==
        param["ResShare"]/100 *
        sum(param["Deterministic Data"][year]["Demand"][hour, zone]
            for hour in HOURS, zone in ZONES)
        - sum(EX[hour, from_zone, zone] for hour in HOURS, zone in ZONES,
            from_zone in ZONES)
        + sum(EX[hour, zone, to_zone] for hour in HOURS, zone in ZONES,
            to_zone in ZONES)

    );
    # call solver
    status = solve(Invest)
    # format solution
    generation  = NamedArray(
        getvalue(G.innerArray), (HOURS, ZONES, TECH),
        ("Hour", "Zone", "Technology"))
    storage_gen = NamedArray(
        getvalue(G_STOR.innerArray), (HOURS, ZONES, STOR),
        ("Hour", "Zone", "Technology"))
    storage_con = NamedArray(
        getvalue(D_STOR.innerArray), (HOURS, ZONES, STOR),
        ("Hour", "Zone", "Technology"))
    storage_lvl = NamedArray(
        getvalue(L_STOR.innerArray), (HOURS, ZONES, STOR),
        ("Hour", "Zone", "Technology"))

    cap = NamedArray(getvalue(CAP.innerArray), (ZONES, TECH),
        ("Zone", "Technology"))
    cap_stor_energy = NamedArray(getvalue(CAP_ST_E.innerArray), (ZONES, STOR),
        ("Zone", "Technology"))
    cap_stor_power = NamedArray(getvalue(CAP_ST_P.innerArray), (ZONES, STOR),
        ("Zone", "Technology"))
    curtailment = NamedArray(getvalue(CU.innerArray),
        (HOURS, ZONES, NONDISP),
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
        results[zone]["Curtailment"] = curtailment[:, zone, :]
        results[zone]["Exchange"] = exchange[:, :, zone]
        results[zone]["Price"] = price[:, zone]
        results[zone]["Capacity"] = cap[zone, :]
        results[zone]["Storage Energy"] = cap_stor_energy[zone, :]
        results[zone]["Storage Power"] = cap_stor_power[zone, :]
    end

    return results

end
