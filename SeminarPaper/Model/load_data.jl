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

    HOURS = collect(1:24)

    ntc_array = hcat([select(ntc_table, Symbol(z)) for z in ZONES]...)
    ntc = NamedArray(ntc_array, (ZONES, ZONES), ("From_zone", "To_zone"))

    potentials_array = hcat([select(potNondisp_table, Symbol(n))
        for n in NONDISP]...)
    potentials = NamedArray(PotentialsArray, (ZONES, NONDISP),
        ("Zones","Nondisp"))

    storPot_array = array(select(potStor_table, :Potential))
    potPumpStor = NamedArray(StorPotArray, (ZONES,),("Zones",))

    annuities_array = array(select(tech_table, :Annuity))
    annuities = NamedArray(AnnuitiesArray, (TECHNOLOGY,), ("Technologies",))

    stor_array = array(select(storages_table, :Annuity))
    annuitiesStor = NamedArray(StorArray, (STOR,), ("Storages",))

    mc = NamedArray(select(tech_table, :MC), (TECHNOLOGY,), ("Technologies",))
    etaTech = NamedArray(select(tech_table, :eta), (TECHNOLOGY,),
        ("Technologies",))
    etaStor = NamedArray(select(storages_table, :eta), (STOR,), ("Storages",))
    eta     = vcat(EtaTech, EtaStor)
    # carbon content for implemenation of maximum CO2 emission
    carbCon = NamedArray(select(tech_table, :CarbCon), (TECHNOLOGY,),
        ("Technologies",)) # in t/MWh

    # Don't know how to handle this one...
    #annuity_oc_power    = NamedArray(annuity_oc_power, (STOR,), ("Storage",))
    #annuity_oc_energy   = NamedArray(annuity_oc_energy, (STOR,), ("Storage",))

    resShare = NamedArray(select(policies_table, :resShare),
        (ZONES,), ("Zone",))

#=
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
=#

    # sets dictionary
    sets = Dict(
        "Hours"     => HOURS,
        "Zones"     => ZONES,
        "Tech"      => TECHNOLOGY,
        "Disp"      => DISP,
        "Nondisp"   => NONDISP,
        "Storage"   => STOR
    )

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
