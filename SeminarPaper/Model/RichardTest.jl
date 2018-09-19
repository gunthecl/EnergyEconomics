using NamedArrays
using JuliaDB
using JuMP
inputfolder="input data" # determine folder for inputdata

#load csv and create tables
#demand_table    =loadtable(string(inputfolder, "/test_zone_demand.csv"))
TechTable           =loadtable(string(inputfolder, "/tech.csv"))
PotPumpStorTable    =loadtable(string(inputfolder, "/PotPumpStor.csv"))
StoregesTable       =loadtable(string(inputfolder, "/storages.csv"))
PotNonDispTable     =loadtable(string(inputfolder, "/PotNonDisp.csv"))
