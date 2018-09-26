function load_RData(file_stochastic::String, file_weight::String,
    file_deterministic::String)
    """
    Note: IB must be last indexing name for zones! Wind Offshore tables are
          appended by a fitting zeros array to include IB as a zone. (Make the
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
            hcat(off_array, zeros(length(HOURS),1)), (HOURS, ZONES),
            ("Hours", "Zones"))
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
    HOURS = collect(1:size(rData["1987pv"])[1])
    # determine years
    num_years = Int(length(unique(keys(rData)))/4)
    years = Array{String}(num_years)
    i = 1
    for key in unique(keys(rData))
        if contains(key, "load")
            years[i] = split(key, "l")[1]
            i = i+1
        end
    end
    sort!(years)
    weatherYears = OrderedDict()
    for num in collect(1:length(years))
        year = years[num]
        weatherYears[year] = OrderedDict()
        # select data
        pv_array    = Array(rData[string(year,"pv")])
        on_array    = Array(rData[string(year,"on")])
        off_array   = Array(rData[string(year,"off")])
        load_array  = Array(rData[string(year,"load")])
        # fill in NamedArrays
        weatherYears[year]["PV"]           = NamedArray(pv_array, (HOURS, ZONES),
            ("Hours", "Zones"))
        weatherYears[year]["WindOnshore"]  = NamedArray(on_array, (HOURS, ZONES),
            ("Hours", "Zones"))
        weatherYears[year]["WindOffshore"] = NamedArray(
            hcat(off_array, zeros(length(HOURS),1)), (HOURS, ZONES),
            ("Hours", "Zones"))
        weatherYears[year]["Demand"]       = NamedArray(load_array, (HOURS, ZONES),
            ("Hours", "Zones"))
    end

    return scenarios, weatherYears
end
