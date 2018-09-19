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
#potentials of nondisp technologies
PotentialsArray = hcat([select(PotNonDispTable, Symbol(n)) for n in NONDISP]...)
potentials = NamedArray(PotentialsArray, (ZONES, NONDISP), ("Zones","NondispTech"))
#potentials of STOR
StorPotArray = array(select(PotPumpStorTable, :Potential))
PotPumpStor =NamedArray(StorPotArray, (ZONES,),("Zones",))
#annuites of TECHNOLOGY
AnnuitiesArray =array(select(TechTable, :Annuity))
annuities =NamedArray(AnnuitiesArray, (TECHNOLOGY,), ("Technologies",))
#annuities of STOR
StorArray =array(select(StoregesTable, :Annuity))
AnnuitiesStor = NamedArray(StorArray, (STOR,), ("Storages",))
#marginal cost of TECHNOLOGY
mc =NamedArray(select(TechTable, :MC), (TECHNOLOGY,), ("Technologies",))
EtaTech =NamedArray(select(TechTable, :eta), (TECHNOLOGY,), ("Technologies",))
EtaStor =NamedArray(select(StoregesTable, :eta), (STOR,), ("Storeges",))
eta     =vcat(EtaTech, EtaStor)

#carbon content for implemenation of maximum CO2 emission
CarbCon =NamedArray(select(TechTable, :CarbCon), (TECHNOLOGY,), ("Technologies",))
