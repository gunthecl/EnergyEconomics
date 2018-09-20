function load_data(folder::String)
folder="input data" # determine folder for inputdata

###############################################################################
                ###load csv and create tables###
###############################################################################

    # load files
    demand_table    = loadtable(string(folder, "/t_zone_demand.csv"))
    TechTable       = loadtable(string(folder, "/tech.csv"))
    StoregesTable   = loadtable(string(folder, "/storages.csv"))
    PotNonDispTable = loadtable(string(folder, "/PotNonDisp.csv"))
    PotPumpStorTable= loadtable(string(folder, "/PotPumpStor.csv"))
    ntc_table       = loadtable(string(folder, "/t_ntc.csv"))
    solar_table     = loadtable(string(folder, "/t_solar_availability.csv"))
    onshore_table   = loadtable(string(folder, "/t_wind_off_availability.csv"))
    offshore_table  = loadtable(string(folder, "/t_wind_on_availability.csv"))
    policies_table  = loadtable(string(folder, "/t_policies.csv"))
    # derive sets from input data files
    DISP = select(filter(row -> row.Type=="disp", TechTable), :Technology)
    DISP = convert(Array, DISP)

    NONDISP = select(filter(row -> row.Type=="nondisp", TechTable), :Technology)
    NONDISP = convert(Array, NONDISP)

    TECHNOLOGY = array(select(TechTable, :Technology))
    TECHNOLOGY = convert(Array, TECHNOLOGY)

    ZONES = array(select(PotNonDispTable, :Country))
    ZONES = convert(Array, ZONES)

    STOR = array(select(StoregesTable, :Technology))
    STOR = convert(Array, STOR)

    HOURS = select(demand_table, :Hour)
    # sets dictionary
    sets = Dict(
        "Hours"     => HOURS,
        "Zones"     => ZONES,
        "Tech"      => TECHNOLOGY,
        "Disp"      => DISP,
        "Nondisp"   => NONDISP,
        "Storage"   => STOR
    )
    ############################################################################
                ###derive input parameters from created arrays###
    ############################################################################
    demand_array = hcat([select(demand_table, Symbol(z)) for z in ZONES]...)
    demand = NamedArray(demand_array, (HOURS, ZONES), ("Hour", "Zone"))

    ntc_array = hcat([select(ntc_table, Symbol(z)) for z in ZONES]...)
    ntc = NamedArray(ntc_array, (ZONES, ZONES), ("From_zone", "To_zone"))
    #potentials of nondisp technologies
    potentials_array = hcat([select(PotNonDispTable, Symbol(n))
        for n in NONDISP]...)
    potentials = NamedArray(PotentialsArray, (ZONES, NONDISP),
        ("Zones","NondispTech"))
    #potentials of STOR
    storPot_array = array(select(PotPumpStorTable, :Potential))
    potPumpStor = NamedArray(StorPotArray, (ZONES,),("Zones",))
    #annuites of TECHNOLOGY
    annuities_array = array(select(TechTable, :Annuity))
    annuities = NamedArray(AnnuitiesArray, (TECHNOLOGY,), ("Technologies",))
    #annuities of STOR
    stor_array = array(select(StoregesTable, :Annuity))
    annuitiesStor = NamedArray(StorArray, (STOR,), ("Storages",))

    mc = NamedArray(select(TechTable, :MC), (TECHNOLOGY,), ("Technologies",))
    #carbon content for implemenation of maximum CO2 emission
    carbCon = NamedArray(select(TechTable, :CarbCon), (TECHNOLOGY,),
        ("Technologies",)) #in t/MWh

    # Don't know how to handle this one...
    #annuity_oc_power    = NamedArray(annuity_oc_power, (STOR,), ("Storage",))
    #annuity_oc_energy   = NamedArray(annuity_oc_energy, (STOR,), ("Storage",))

    resShare = NamedArray(select(policies_table, :resShare),
        (ZONES,), ("Zone",))

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
