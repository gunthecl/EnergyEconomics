function load_data(hours::Int64, folder::String)
    # load files
    demand_table    = loadtable(string(folder, "/zone_demand.csv"))
    tech_table      = loadtable(string(folder, "/tech.csv"))
    storage_table   = loadtable(string(folder, "/storages.csv"))
    ntc_table       = loadtable(string(folder, "/ntc.csv"))
    solar_table     = loadtable(string(folder, "/solar_availability.csv"))
    onshore_table   = loadtable(string(folder, "/wind_off_availability.csv"))
    offshore_table  = loadtable(string(folder, "/wind_on_availability.csv"))
    policies_table  = loadtable(string(folder, "/policies.csv"))
    # derive sets from input data files
    TECHNOLOGY  = Array(select(tech_table, :technology))
    NONDISP     = select(filter(row-> row.type == "nondisp", tech_table),
                    :technology)
    NONDISP     = convert(Array, NONDISP)
    DISP        = setdiff(TECHNOLOGY, NONDISP)
    STOR        = Array(select(storage_table, :technology))
    HOURS       = select(demand_table, :Hour)
    ZONES       = string.(colnames(demand_table)[2:end])
    # sets dictionary
    sets = Dict(
        "Hours"     => HOURS,
        "Zones"     => ZONES,
        "Tech"      => TECHNOLOGY,
        "Disp"      => DISP,
        "Nondisp"   => NONDISP,
        "Storage"   => STOR
    )
    # derive input parameters from data files
    demand_array = hcat([select(demand_table, Symbol(z)) for z in ZONES]...)
    demand = NamedArray(demand_array, (HOURS, ZONES), ("Hour", "Zone"))

    ntc_array = hcat([select(ntc_table, Symbol(z)) for z in ZONES]...)
    ntc = NamedArray(ntc_array, (ZONES, ZONES), ("From_zone", "To_zone"))

    i = 0.04 # expected annual interest
    annuity             = map(row-> row.oc * (i+1)^row.lifetime /
                        (((1+i)^row.lifetime)-1), tech_table)
    annuity_oc_power    = map(row-> row.oc_power * (i+1)^row.lifetime /
                        (((1+i)^row.lifetime)-1), storage_table)
    annuity_oc_energy   = map(row-> row.oc_storage * (i+1)^row.lifetime /
                        (((1+i)^row.lifetime)-1), storage_table)
    annuity             = NamedArray(annuity, (TECHNOLOGY,), ("Technology",))
    annuity_oc_power    = NamedArray(annuity_oc_power, (STOR,), ("Storage",))
    annuity_oc_energy   = NamedArray(annuity_oc_energy, (STOR,), ("Storage",))

    mc  = NamedArray(select(tech_table, :mc), (TECHNOLOGY,), ("Technology",))
    eta = NamedArray(select(storage_table, :efficiency), (STOR,), ("Storage",))
    resShare  = NamedArray(select(policies_table, :res_share), (ZONES,),
        ("Zone",))

    avail_arr_solar     = hcat([select(solar_table, Symbol(z))
                        for z in ZONES]...)
    avail_arr_onshore   = hcat([select(onshore_table, Symbol(z))
                        for z in ZONES]...)
    avail_arr_offshore  = hcat([select(offshore_table, Symbol(z))
                        for z in ZONES]...)

    avail_solar     = NamedArray(avail_arr_solar, (HOURS,ZONES),
                    ("Hour","Zone"))
    avail_onshore   = NamedArray(avail_arr_onshore, (HOURS,ZONES),
                    ("Hour","Zone"))
    avail_offshore  = NamedArray(avail_arr_offshore, (HOURS,ZONES),
                    ("Hour","Zone"))
    # parameters dictionary
    param = Dict(
        "Demand"        => demand,
        "NTC"           => ntc,
        "PV"            => avail_solar,
        "WindOnshore"   => avail_onshore,
        "WindOffshore"  => avail_offshore,
        "Efficiency"    => eta,
        "MarginalCost"  => mc,
        "Annuity"       => annuity,
        "AnnuityPower"  => annuity_oc_power,
        "AnnuityEnergy" => annuity_oc_energy,
        "ResShare"      => resShare
    )
    return sets, param
end
