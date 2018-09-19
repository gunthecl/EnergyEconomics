using NamedArrays
using JuliaDB
using JuMP
inputfolder="input data" # determine folder for inputdata

###############################################################################
                ###load csv and create tables###
###############################################################################
#demand_table    =loadtable(string(inputfolder, "/test_zone_demand.csv"))
TechTable           =loadtable(string(inputfolder, "/tech.csv"))
StoregesTable       =loadtable(string(inputfolder, "/storages.csv"))
PotNonDispTable     =loadtable(string(inputfolder, "/PotNonDisp.csv"))
PotPumpStorTable    =loadtable(string(inputfolder, "/PotPumpStor.csv"))
# derive sets from input data files
DISP        =select(filter(row -> row.Type=="disp", TechTable), :Technology)
DISP        =convert(Array, DISP)

NONDISP     =select(filter(row -> row.Type=="nondisp", TechTable), :Technology)
NONDISP     =convert(Array, NONDISP)

TECHNOLOGY  =array(select(TechTable, :Technology))
TECHNOLOGY  =convert(Array, TECHNOLOGY)

ZONES       =array(select(PotNonDispTable, :Country))
ZONES       =convert(Array, ZONES)

STOR        =array(select(StoregesTable, :Technology))
STOR        =convert(Array, STOR)

# sets dictionary
sets = Dict(
    #"Hours"     => HOURS,
    "Zones"     => ZONES,
    "Tech"      => TECHNOLOGY,
    "Disp"      => DISP,
    "Nondisp"   => NONDISP,
    "Storage"   => STOR
    )
###############################################################################
            ###derive inputparameters from created arrays###
###############################################################################
#potentials = NamedArray(potentials_array, (ZONES, NONDISP), ("Zones","NondispTech"))
potentials  =NamedArray(PotNonDispTable,(NONDISP, ZONES),("NondispTech","Zones"))
