function load_RData(file_scenario::String, file_weight::String,
    HOURS::Any, ZONES::Any)
    # load RData file
    rData = RData.load(file_scenario, convert=true)
    rData = rData["scenario.tech"] # discard nesting level
    # load weights table
    weight_table = JuliaDB.loadtable(file_weight)
    weight = select(weight_table, (:weight))

    num_scenarios = length(weight)
    scenarios = Dict()
    for num in collect(1:num_scenarios)
        scen = string("Scenario ", num)
        scenarios[scen] = Dict()
        # select data
        pv_array    = Array(rData[string(num,"pv")])
        on_array    = Array(rData[string(num,"pv")])
        off_array   = Array(rData[string(num,"off")])
        load_array  = Array(rData[string(num,"load")])
        # fill in NamedArrays
        scenarios[scen]["PV"]       = NamedArray(pv_array, (HOURS, ZONES),
            ("Hours", "Zones"))
        scenarios[scen]["Onshore"]  = NamedArray(on_array, (HOURS, ZONES),
            ("Hours", "Zones"))
        scenarios[scen]["Offshore"] = NamedArray(off_array,
            (HOURS, filter(e->e≠"IB",ZONES)), ("Hours", "Zones"))
        scenarios[scen]["Demand"]   = NamedArray(load_array, (HOURS, ZONES),
            ("Hours", "Zones"))
        scenarios[scen]["Weight"]   = weight[num]
    end
    return scenarios
end
