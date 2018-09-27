function save_data(results::Dict, resShare::Int, timeStamp::DateTime,
    hDet::String, hSto::String)

    timeStamp = Dates.format(timeStamp, "yyyy-mm-dd HH_MM")

    path = string("output_data/", timeStamp, "_", resShare, "%")
    mkpath("output_data")

    for r in keys(results)
        if r == "Deterministic"
            mkpath(string(path, "_", hDet, "h_", r))
            for y in keys(results[r])
                mkpath(string(path, "_", hDet, "h_", r, "/", y))
                for z in keys(results[r][y])
                    mkpath(string(path, "_", hDet, "h_", r, "/", y, "/", z))
                    for key in keys(results[r][y][z])
                        if contains(key, "Storage")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(data)
                            names!(df, [Symbol(s) for s in sets["Storage"]])
                        elseif contains(key, "Exchange")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(data)
                            names!(df, [Symbol(z) for z in sets["Zones"]])
                        elseif contains(key, "Price")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(Price=data)
                        elseif contains(key, "Capacity") || contains(key, "Generation")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(data)
                            names!(df, [Symbol(t) for t in sets["Tech"]])
                        elseif contains(key, "Curtailment")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(data)
                            names!(df, [Symbol(ndisp) for ndisp in sets["Nondisp"]])
                        end
                        CSV.write(string(path, "_", hDet, "h_", r, "/", y, "/", z,"/", key), df)
                    end
                end
            end
        elseif r == "Stochastic"
            mkpath(string(path, "_", hSto, "h_", r))
            for z in keys(results[r])
                mkpath(string(path, "_", hSto, "h_", r, "/", z))
                rand_scen = rand(1:length(param["Stochastic Data"]))
                for key in keys(results[r][z])
                    if contains(key, "Storage")
                        data = convert(Array, results[r][z][key])
                        df = DataFrame(data)
                        names!(df, [Symbol(s) for s in sets["Storage"]])
                        CSV.write(string(path, "_", hSto, "h_", r, "/", z,"/", key), df)
                    elseif contains(key, "Capacity")
                        data = convert(Array, results[r][z][key])
                        df = DataFrame(data)
                        names!(df, [Symbol(t) for t in sets["Tech"]])
                        CSV.write(string(path, "_", hSto, "h_", r, "/", z,"/", key), df)
                    elseif contains(key, string("Scenario ", rand_scen))
                        mkpath(string(path, "_", hSto, "h_", r, "/", z, "/", key))
                        for d in keys(results[r][z][key])
                            if contains(d, "Storage")
                                data = convert(Array, results[r][z][key][d])
                                df = DataFrame(data)
                                names!(df, [Symbol(s) for s in sets["Storage"]])
                            elseif contains(d, "Exchange")
                                data = convert(Array, results[r][z][key][d])
                                df = DataFrame(data)
                                names!(df, [Symbol(z) for z in sets["Zones"]])
                            elseif contains(d, "Price")
                                data = convert(Array, results[r][z][key][d])
                                df = DataFrame(Price=data)
                            elseif  contains(d, "Generation")
                                data = convert(Array, results[r][z][key][d])
                                df = DataFrame(data)
                                names!(df, [Symbol(t) for t in sets["Tech"]])
                            elseif contains(d, "Curtailment")
                                data = convert(Array, results[r][z][key][d])
                                df = DataFrame(data)
                                names!(df, [Symbol(ndisp) for ndisp in sets["Nondisp"]])
                            end
                            CSV.write(string(path, "_", hSto, "h_", r, "/", z,"/", key, "/", d), df)
                        end
                    end
                end
            end
        end
    end
end
