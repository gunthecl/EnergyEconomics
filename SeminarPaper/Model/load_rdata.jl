function load_RData(file_stochastic::String, file_weight::String,
    file_deterministic::String)
    """
    Note: IB must be last indexing name for zones! Wind Offshore tables are
          appended by a 24x1 zeros array to include IB as a zone. (Make the
          investment model more accessible for indexing)
    """
    # -------------------------------------------------------------------------
    # stochastic data
    # -------------------------------------------------------------------------
    # load RData file
    rData = RData.load(file_stochastic, convert=true)
    rData = rData["scenario.tech"] # discard nesting level
    # load weights table
    weight_table = JuliaDB.loadtable(file_weight)
    weight = select(weight_table, (:weight))
    # respect unique order of rData
    ZONES = Array{String}(6)
    for (num, name) in enumerate(names(rData["1pv"]))
        name = string(name)
        ZONES[num] = name
    end
    HOURS = collect(1:size(rData["1pv"])[1])
    num_scenarios = length(weight)
    scenarios = OrderedDict()
    for num in collect(1:num_scenarios)
        scen = string("Scenario ", num)
        scenarios[scen] = OrderedDict()
        # select data
        pv_array    = Array(rData[string(num,"pv")])
        on_array    = Array(rData[string(num,"on")])
        off_array   = Array(rData[string(num,"off")])
        load_array  = Array(rData[string(num,"load")])
        # fill in NamedArrays
        scenarios[scen]["PV"]           = NamedArray(pv_array, (HOURS, ZONES),
            ("Hours", "Zones"))
        scenarios[scen]["WindOnshore"]  = NamedArray(on_array, (HOURS, ZONES),
            ("Hours", "Zones"))
        scenarios[scen]["WindOffshore"] = NamedArray(
            hcat(off_array, zeros(24,1)), (HOURS, ZONES), ("Hours", "Zones"))
        scenarios[scen]["Demand"]       = NamedArray(load_array, (HOURS, ZONES),
            ("Hours", "Zones"))
        scenarios[scen]["Weight"]       = weight[num]
    end

    # -------------------------------------------------------------------------
    # deterministic data
    # -------------------------------------------------------------------------
    rData = RData.load(file_deterministic, convert=true)
    rData = rData["scenario.determ"] # discard nesting level
    # respect unique order of rData
    ZONES = Array{String}(6)
    for (num, name) in enumerate(names(rData["1987pv"]))
        name = string(name)
        ZONES[num] = name
    end




    return scenarios, HOURS
end
