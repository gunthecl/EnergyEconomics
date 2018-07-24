using NamedArrays
using JuliaDB
using JuMP
using Clp
using Gurobi
using Plots, StatPlots



demand_table = loadtable("data/demand.csv", indexcols=1)
costs_table = loadtable("data/costs.csv", indexcols=1) # in kW
storage_table = loadtable("data/storages.csv")
availability_table = loadtable("data/availability.csv", indexcols=1)

TECHNOLOGY = Array(select(costs_table, :Technology))
NONDISP = string.(colnames(availability_table)[2:end])
DISP = setdiff(TECHNOLOGY, NONDISP)
STOR = Array(select(storage_table, :technology))


HOUR = select(demand_table, :Hour)

demand = NamedArray(select(demand_table, :Demand),
                   (select(demand_table, :Hour), ),
                   ("Hour",))

i = 0.04
annuity = map(row-> row.OC * (i+1)^row.Lifetime / (((1+i)^row.Lifetime)-1), costs_table)
annuity_oc_power = map(row-> row.oc_power * (i+1)^row.lifetime / (((1+i)^row.lifetime)-1), storage_table)
annuity_oc_energy = map(row-> row.oc_storage * (i+1)^row.lifetime / (((1+i)^row.lifetime)-1), storage_table)


annuity = NamedArray(annuity,
                    (TECHNOLOGY,),
                    ("Technology",))

annuity_oc_power = NamedArray(annuity_oc_power,
                    (STOR,),
                    ("Storage",))

annuity_oc_energy = NamedArray(annuity_oc_energy,
                              (STOR,),
                              ("Storage",))



mc = NamedArray(select(costs_table, :MC),
                (TECHNOLOGY,),
                ("Technology",))



avail_arr = hcat([columns(availability_table, i) for i in 2:4]...)
avail = NamedArray(avail_arr, (HOUR,NONDISP), ("Hour","Nondisp"))
effic = NamedArray(select(storage_table, :efficiency),
                         (STOR,),
                         ("Storage",))

###############################################################################


function invest(res_share::Int, solver=error("Set a solver!"))

    Invest = Model(solver=solver)

    @variable(Invest, G[HOUR,TECHNOLOGY] >= 0)
    @variable(Invest, CU[HOUR,NONDISP] >= 0)
    @variable(Invest, CAP[TECHNOLOGY] >= 0)
    @variable(Invest, CAP_ST_E[STOR] >= 0) # Installed capacity storage energy
    @variable(Invest, CAP_ST_P[STOR] >= 0) # Installed capacity storage power
    @variable(Invest, L[HOUR, STOR] >= 0) #current storage level
    @variable(Invest, D_stor[HOUR, STOR] >= 0) #consumption from storage)
    @variable(Invest, G_stor[HOUR, STOR] >= 0) #generation from storage)


    for s in STOR
        JuMP.fix(G_stor[HOUR[1], s], 0)
    end


    @objective(Invest, Min,

        sum(mc[tech] * G[hour,tech] * 8760/length(HOUR) for tech in TECHNOLOGY, hour in HOUR)

        + sum(annuity[tech] * CAP[tech] for tech in TECHNOLOGY)
        + 0.5 * sum(annuity_oc_power[stor] * CAP_ST_P[stor] for stor in STOR)
        + 0.5 * sum(annuity_oc_energy[stor] * CAP_ST_E[stor] for stor in STOR) );


    @constraint(Invest, EnergyBalance[hour=HOUR],
        sum(G[hour,tech] for tech in TECHNOLOGY)
        + sum(G_stor[hour, stor] for stor in STOR)
        ==
        demand[hour]
        + sum(D_stor[hour, stor] for stor in STOR));

    @constraint(Invest, MaxGeneration[hour=HOUR, disp=DISP],

        G[hour,disp] <= CAP[disp]);


    @constraint(Invest, MaxInfeed[hour=HOUR, nondisp=NONDISP],
        G[hour,nondisp] + CU[hour,nondisp]
        ==
        avail[hour,nondisp] * CAP[nondisp]);

    @constraint(Invest, ResShare,

        sum(G[hour,nondisp] for hour in HOUR, nondisp in NONDISP)
        ==
        res_share/100 * sum(demand[hour] for  hour in HOUR) );

    @constraint(Invest, Storage_Level[stor=STOR, hour=HOUR; hour != HOUR[1]],
            L[hour, stor] ==  L[hour-1, stor] + effic[stor]*D_stor[hour, stor]
            - G_stor[hour, stor]);

    @constraint(Invest, Free_Lunch[stor=STOR],
            L[HOUR[1], stor ] ==  L[HOUR[end], stor]);

    @constraint(Invest, Max_Storage_Level[stor=STOR, hour=HOUR],
            L[hour, stor] <= CAP_ST_E[stor] );

    @constraint(Invest, Max_Storage_Generation[stor=STOR, hour=HOUR],
                G_stor[hour, stor] <= CAP_ST_P[stor]);

    @constraint(Invest, Max_Storage_Withdraw[stor=STOR, hour=HOUR],
                D_stor[hour, stor] <= CAP_ST_P[stor]);



    status = solve(Invest)

    capacity = NamedArray(getvalue(CAP.innerArray) ./ 1000,
                         (TECHNOLOGY,),
                         ("Technology",))

    generation = NamedArray(getvalue(G.innerArray) ./ 1000000,
                           (HOUR,TECHNOLOGY),
                           ("Hour","Technology"))

    curtailment = NamedArray(getvalue(CU.innerArray) ./ 1000000,
                            (HOUR,NONDISP),
                            ("Hour","Technology"))

    storage     = NamedArray(getvalue(G_stor.innerArray) ./ 1000000,
                       (HOUR,STOR),
                       ("Hour","Storage"))

    storage_D   = NamedArray(getvalue(D_stor.innerArray) ./ 1000000,
                         (HOUR,STOR),
                        ("Hour","Storage"))

   storage_CAP_E = NamedArray(getvalue(CAP_ST_E.innerArray) ./ 1000,
                             (STOR,),
                            ("Storage",))
   storage_CAP_P = NamedArray(getvalue(CAP_ST_P.innerArray) ./ 1000,
                            (STOR,),
                            ("Storage",))

    return capacity, generation, curtailment,
    storage, storage_D, storage_CAP_E, storage_CAP_P
end


scenario = [70,80,90,100]
nr_scenario = length(scenario)
len_tech = length(TECHNOLOGY)
len_stor = length(STOR)


capacity = zeros(len_tech,nr_scenario)
generation = zeros(length(HOUR),nr_scenario)
res_gen = zeros(length(HOUR), nr_scenario)
curtailment = zeros(nr_scenario)
storage    = zeros(len_stor, nr_scenario)
storage_D  = zeros(len_stor, nr_scenario)
storage_CAP_E = zeros(len_stor, nr_scenario)
storage_CAP_P = zeros(len_stor, nr_scenario)

for (i,share) in enumerate(scenario)
    println("Calculating scenario with RES share $share %")
    cap, gen, cur, stor, stord, storcape, storcapp = invest(share, GurobiSolver())
    capacity[:,i] = Array(cap)
    # Calculate renewables generation and store in res_gen[:,i]
    res_gen = Array(gen)
    res_gen = gen[:, 3:5]
    res_cap = capacity[3:5,i]
    for (i,n) in enumerate(res_cap)
        res_gen[:,i] = res_gen[:,i].*res_cap[i]
    end
    generation[:,i] = Array(sum(gen, 2))
    curtailment[i] = sum(cur)
    storage[:,i] = Array(sum(stor, 1))
    storage_D[:,i] = Array(sum(stord, 1))
    storage_CAP_E[:,i] = Array(storcape)
    storage_CAP_P[:,i] = Array(storcapp)
end



colors = [:orange :grey :blue :cyan :yellow]

groupedbar(scenario,
           capacity',
           bar_position = :stack,
           label=TECHNOLOGY,
           color=colors,
           legend=:topleft,
           title="Installed capacity for different RES shares",
           ylabel="Installed capacity in GW",
           xlabel="RES share in %")
p = twinx()
plot!(p,
    scenario,
    curtailment,
    label="Curtailment [TWh]",
    color=:red,
    legend=:left)


function load_curve(demand_table, res_infeed, scenario)
    dem = select(demand_table, :Demand)
    res = zeros(length(HOUR), length(scenario))
    residual = zeros(length(HOUR), length(scenario))
    for (i,s) in enumerate(scenario)
        residual[:,i] = sort(dem - generation[:,i],rev=true)
    end
    plot(HOUR, [dem,residual])
end
