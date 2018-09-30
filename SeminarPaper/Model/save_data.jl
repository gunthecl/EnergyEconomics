function save_data(results::Dict, sets::Dict, resShare::Int,
    timeStamp::DateTime, hDet::String, hSto::String)

    hDet = parse(Int, hDet)
    hSto = parse(Int, hSto)
    timeStamp = Dates.format(timeStamp, "yyyy-mm-dd HH_MM")

    path = string("output_data/", timeStamp, "_", resShare, "%")
    mkpath("output_data")

    for r in keys(results)
        if r == "Deterministic"
            mkpath(string(path, "_", hDet, "h_", r))
            for y in keys(results[r])
                len = collect(1:length(sets["Tech"]))
                cap = DataFrame(Technology=sets["Tech"],
                                DK=len,
                                FR=len,
                                DE=len,
                                IB=len,
                                LU=len,
                                UK=len)
                len_stor = collect(1:length(sets["Storage"]))
                cap_stor = DataFrame(Technology=sets["Storage"],
                                DK=len_stor,
                                FR=len_stor,
                                DE=len_stor,
                                IB=len_stor,
                                LU=len_stor,
                                UK=len_stor)
                mkpath(string(path, "_", hDet, "h_", r, "/", y))
                for z in keys(results[r][y])
                    mkpath(string(path, "_", hDet, "h_", r, "/", y, "/", z))
                    for key in keys(results[r][y][z])
                        if contains(key, "Storage")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(data)
                            names!(df, [Symbol(s) for s in sets["Storage"]])
                            if contains(key, "Storage Power")
                                cap_stor[Symbol(z)] = data
                            end
                        elseif contains(key, "Exchange")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(data)
                            names!(df, [Symbol(z) for z in sets["Zones"]])
                        elseif contains(key, "Price")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(Price=data)
                        elseif contains(key, "Generation")
                            hours = collect(1:hDet)
                            array = convert(Array, results[r][y][z][key])
                            data = hcat(hours, array)
                            df = DataFrame(data)
                            ext_set = vcat("Hours", sets["Tech"])
                            names!(df, [Symbol(t) for t in ext_set])
                        elseif contains(key, "Capacity")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(data)
                            names!(df, [Symbol(t) for t in sets["Tech"]])
                            cap[Symbol(z)] = data
                        elseif contains(key, "Curtailment")
                            data = convert(Array, results[r][y][z][key])
                            df = DataFrame(data)
                            names!(df, [Symbol(ndisp) for ndisp in sets["Nondisp"]])
                        end
                        CSV.write(string(path, "_", hDet, "h_", r, "/", y, "/", z,"/", key, ".csv"), df)
                    end
                end
                append!(cap, cap_stor)
                sets["Tech"] = sets["Tech"][1:7]
                CSV.write(string(path, "_", hDet, "h_", r, "/", y, "/", "Capacity.csv"), cap)
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
                        CSV.write(string(path, "_", hSto, "h_", r, "/", z,"/", key, ".csv"), df)
                    elseif contains(key, "Capacity")
                        data = convert(Array, results[r][z][key])
                        df = DataFrame(data)
                        names!(df, [Symbol(t) for t in sets["Tech"]])
                        CSV.write(string(path, "_", hSto, "h_", r, "/", z,"/", key, ".csv"), df)
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
                                hours = collect(1:hSto)
                                array = convert(Array, results[r][z][key][d])
                                data = hcat(hours, array)
                                df = DataFrame(data)
                                ext_set= vcat("Hours", sets["Tech"])
                                names!(df, [Symbol(t) for t in ext_set])
                            elseif contains(d, "Curtailment")
                                data = convert(Array, results[r][z][key][d])
                                df = DataFrame(data)
                                names!(df, [Symbol(ndisp) for ndisp in sets["Nondisp"]])
                            end
                            CSV.write(string(path, "_", hSto, "h_", r, "/", z,"/", key, "/", d, ".csv"), df)
                        end
                    end
                end
            end
        end
    end
end
