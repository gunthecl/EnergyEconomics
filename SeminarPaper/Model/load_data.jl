function load_data(folder::String, avg::Bool)
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

    scenarios, weatherYears = load_RData(
        "test_scenario/stochastic/scenariotech30.rda",
        "test_scenario/stochastic/weights30.csv",
        "test_scenario/deterministic/scenarios_deterministic.rda")
    SCENARIOS = collect(keys(scenarios))
    YEARS     = collect(keys(weatherYears))

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
    mc_stor = NamedArray(select(storages_table, :MC), (STOR,), ("Storages",))
    etaTech = NamedArray(select(tech_table, :eta), (TECHNOLOGY,),
        ("Technologies",))
    etaStor = NamedArray(select(storages_table, :eta), (STOR,), ("Storages",))
    # carbon content for implemenation of maximum CO2 emission
    carbCon = NamedArray(select(tech_table, :CarbCon), (TECHNOLOGY,),
        ("Technologies",)) # in t/MWh

    resShare = NamedArray(select(policies_table, :resShare),
        (ZONES,), ("Zone",))

    # sets dictionary
    sets = Dict(
        "Zones"     => ZONES,
        "Tech"      => TECHNOLOGY,
        "Disp"      => DISP,
        "Nondisp"   => NONDISP,
        "Storage"   => STOR,
        "Scenarios" => SCENARIOS,
        "Years"     => YEARS
    )

    # parameters dictionary
    param = Dict(
        "NTC"                   => ntc,
        "Tech Efficiency"       => etaTech,
        "Storage Efficiency"    => etaStor,
        "MarginalCost"          => mc,
        "Storage MarginalCost"  => mc_stor,
        "Annuity"               => annuity,
        "AnnuityPower"          => annuity_oc_power,
        "AnnuityEnergy"         => annuity_oc_energy,
        "ResShare"              => resShare,
        "RES Potentials"        => potentials,
        "Stor Potentials"       => potPumpStor,
        "Stochastic Data"       => scenarios,
        "Deterministic Data"    => weatherYears
    )

    if avg == true
        for year in names(param["Deterministic Data"])
            for series in names(param["Deterministic Data"][year])
                param["Deterministic Data"][year][series] = m_avg(
                    param["Deterministic Data"][year][series])
            end
        end
    end

    return sets, param
end

# helper functions
function m_avg(named_array)
    hour = collect(1:4380)
    id   = names(named_array)[2]
    arr = Array{Any}(4380,6)
    avg = Array{Any}(8760,6)
    i = 1
    x = 1
    while i < size(named_array)[1]
        for j = collect(1:6)
            avg[i, j] = (named_array[i, j] + named_array[i+1, j]) / 2
        end
        arr[x,:] = avg[i,:]
        i = i+2
        x = x+1
    end
    named_array = NamedArray(arr, (hour, id), ("Hours", "Zones"))
    return named_array
end
