function load_data(folder::String)
    # load files
    tech_table          = loadtable(string(folder, "/tech.csv"))
    storages_table      = loadtable(string(folder, "/storages.csv"))
    potNondisp_table    = loadtable(string(folder, "/PotNonDisp.csv"))
    potStor_table       = loadtable(string(folder, "/PotPumpStor.csv"))
    ntc_table           = loadtable(string(folder, "/ntc.csv"))
    policies_table      = loadtable(string(folder, "/policies.csv"))

    # derive sets from input data files
    DISP = select(filter(row -> row.Type=="disp", tech_table), :Technology)
    DISP = convert(Array, DISP)

    NONDISP = select(filter(row -> row.Type=="nondisp", tech_table), :Technology)
    NONDISP = convert(Array, NONDISP)

    TECHNOLOGY = array(select(tech_table, :Technology))
    TECHNOLOGY = convert(Array, TECHNOLOGY)

    ZONES = array(select(potNondisp_table, :Country))
    ZONES = convert(Array, ZONES)

    STOR = array(select(storages_table, :Technology))
    STOR = convert(Array, STOR)

    scenarios, HOURS = load_RData(
        "test_scenario/stochastic/scenariotech30.rda",
        "test_scenario/stochastic/weights30.csv")
    SCENARIOS = collect(keys(scenarios))

    #HOURS = collect(1:24)

    ntc_array = hcat([select(ntc_table, Symbol(z)) for z in ZONES]...)
    ntc = NamedArray(ntc_array, (ZONES, ZONES), ("From_zone", "To_zone"))

    potentials_array = hcat([select(potNondisp_table, Symbol(n))
        for n in NONDISP]...)
    potentials = NamedArray(potentials_array, (ZONES, NONDISP),
        ("Zones","Nondisp"))

    storPot_array = array(select(potStor_table, :Potential))
    potPumpStor = NamedArray(storPot_array, (ZONES,),("Zones",))

    annuity_array = array(select(tech_table, :Annuity))
    annuity = NamedArray(annuity_array, (TECHNOLOGY,), ("Technologies",))

    storOCPower_array = array(select(storages_table, :annuity_oc_power))
    annuity_oc_power = NamedArray(storOCPower_array, (STOR,), ("Storages",))

    storOCEnergy_array = array(select(storages_table, :annuity_oc_energy))
    annuity_oc_energy = NamedArray(storOCEnergy_array, (STOR,), ("Storages",))

    mc = NamedArray(select(tech_table, :MC), (TECHNOLOGY,), ("Technologies",))
    etaTech = NamedArray(select(tech_table, :eta), (TECHNOLOGY,),
        ("Technologies",))
    etaStor = NamedArray(select(storages_table, :eta), (STOR,), ("Storages",))
    #eta     = vcat(etaTech, etaStor)
    # carbon content for implemenation of maximum CO2 emission
    carbCon = NamedArray(select(tech_table, :CarbCon), (TECHNOLOGY,),
        ("Technologies",)) # in t/MWh

    resShare = NamedArray(select(policies_table, :resShare),
        (ZONES,), ("Zone",))

    # sets dictionary
    sets = Dict(
        "Hours"     => HOURS,
        "Zones"     => ZONES,
        "Tech"      => TECHNOLOGY,
        "Disp"      => DISP,
        "Nondisp"   => NONDISP,
        "Storage"   => STOR,
        "Scenarios" => SCENARIOS
    )

    # parameters dictionary
    param = Dict(
        "NTC"                   => ntc,
        "Tech Efficiency"       => etaTech,
        "Storage Efficiency"    => etaStor,
        "MarginalCost"          => mc,
        "Annuity"               => annuity,
        "AnnuityPower"          => annuity_oc_power,
        "AnnuityEnergy"         => annuity_oc_energy,
        "ResShare"              => resShare,
        "RES Potentials"        => potentials,
        "Stor Potentials"       => potPumpStor,
        "Scenario Data"         => scenarios
    )
    return sets, param
end
