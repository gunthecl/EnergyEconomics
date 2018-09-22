################################################################################
#
# Analysis of weather year & selection of deterministic scenarios
#
################################################################################

rm(list = ls())

# List all packages needed for session
neededPackages = c("dplyr", "tidyr", "psych", "reshape", "ggjoy",
                    "rlist", "stringr", "ggplot2", "reshape2")
allPackages    = c(neededPackages %in% installed.packages()[,"Package"])

# Install packages (if not already installed)
if (!all(allPackages)) {
    missingIDX = which(allPackages == FALSE)
    needed     = neededPackages[missingIDX]
    lapply(needed, install.packages)
}

# Load all defined packages
lapply(neededPackages, function(x) suppressPackageStartupMessages(
    library(x, character.only = TRUE)))

################################################################################

## Change path to working directory
wd.path = "/Users/Lenovo/documents/Github/EnergyEconomics/SeminarPaper/Code/R/"


# Read in wind and pv data set
dat.res            <- read.csv(paste0(wd.path,"ninja_pv_wind_profiles_1985-2016_final.csv"), 
                               stringsAsFactors = FALSE)

# Source needed functions
setwd(wd.path)

################################################################################

# Use weighted average for Spain & Portugal, Luxembourg & Netherlands & Belgium

dat.res$LU_pv_national_current   <- (dat.res$BE_pv_national_current*0.426 
                                      + dat.res$LU_pv_national_current*0.034
                                      + dat.res$NL_pv_national_current*0.54)

dat.res$IB_pv_national_current   <- (dat.res$ES_pv_national_current*0.845 
                                      + dat.res$PT_pv_national_current*0.155)

dat.res$LU_wind_onshore_current  <- (dat.res$BE_wind_onshore_current*0.426 
                                      + dat.res$LU_wind_national_current*0.034
                                      + dat.res$NL_wind_onshore_current*0.54)

dat.res$IB_wind_onshore_current  <-  (dat.res$ES_wind_national_current*0.845 
                                       + dat.res$PT_wind_national_current*0.155)

dat.res$LU_wind_offshore_current <- (dat.res$BE_wind_offshore_current*0.441 
                                      + dat.res$NL_wind_offshore_current*0.559)

# Select columns 
var.vec     <- c("LU_pv_national_current", "LU_wind_onshore_current", "LU_wind_offshore_current",
                 "DE_pv_national_current", "DE_wind_onshore_current", "DE_wind_offshore_current",
                 "DK_pv_national_current", "DK_wind_onshore_current", "DK_wind_offshore_current",
                 "FR_pv_national_current", "FR_wind_onshore_current", "FR_wind_offshore_current",
                 "GB_pv_national_current", "GB_wind_onshore_current", "GB_wind_offshore_current",
                 "IB_pv_national_current", "IB_wind_onshore_current")

dat.original <- dat.res[,var.vec]

# Drop leap year days
leap.hours      <- c((59*24+1):(59*24+24))
years.sequence  <- seq(from = 3, to = (2016-1985+3), by = 4)
hours.year      <- 365*24
leap.days.vec   <- list()

for (i in years.sequence){
    
    j   <- which(years.sequence == i) 
    
    leap.days.vec[[i]]     <- leap.hours + (hours.year*i + 24*(j-1))
    
    
}

leap.days.vec <- sort(unlist(leap.days.vec))

# Sanity check
length(leap.days.vec) == length(years.sequence)*24

# Exclude leap year days
dat.original     <- dat.original[-leap.days.vec,]

# Restructure data to year data
list.year.hours <- list()
for (i in 1:32){
    
    list.year.hours[[1984+i]] <- {(365*(i-1)*24)+1}:{365*i*24}
}

year.vec          <- rep(1985:2016, each = 8760)
dat.original$year <- year.vec

# Calculate mean availabilities and sd
mean.values      <- dat.original %>% 
                    group_by(year) %>%
                    summarise_all((mean))

mean.all        <- dat.original %>% 
                   summarise_all((mean))

mean.values      <- gather(data = mean.values, key = "Variable",... = 2:18)

country.vec      <- str_sub(mean.values$Variable, start = 1, end = 2)
variable.vec     <- str_sub(mean.values$Variable, start = 4, end = 50)

mean.values$Country <- country.vec
mean.values$var     <- variable.vec

ggplot(data = mean.values, aes(x=var, y=value)) + geom_boxplot(aes(fill=Country)) + 
    labs(title="Annual mean availability", 
         y="Availability")


mean.values <- spread(data = mean.values[,c(1,3:5)], key = "var", value = "value")


ggplot(mean.values, aes(x=factor(year), group=Country, colour=Country)) +
    geom_line(aes(y = pv_national_current), linetype = "dashed") + 
    geom_line(aes(y = wind_onshore_current)) + 
    geom_line(aes(y = wind_offshore_current), linetype="twodash") +
    labs(title="Annual mean availability", 
         y="Availability",
         x = "Year")

# Extreme weather years
dat.2010         <- dat.original[list.year.hours[[2010]],] # low wind, average pv
dat.2003 <- dat.original[list.year.hours[[2003]],] # low wind, aa pv
#dat.1990 <- dat.original[list.year.hours[[1990]],] # high wind, aa pv
dat.2015 <- dat.original[list.year.hours[[2015]],] # high wind, aa pv
dat.1998 <- dat.original[list.year.hours[[1998]],] # high wind, low pv (except Spain)
dat.1987 <- dat.original[list.year.hours[[1987]],] # low wind, low pv 


scenario.determ <- list()
pv       <- seq(from = 1, to = 17, by = 3)
onshore  <- seq(from = 2, to = 17, by = 3)
offshore <- seq(from = 3, to = 17, by = 3)

country <- c("LU", "DE", "DK", "FR", "UK", "IB")


for (i in (c(1987, 1998, 2003,2010,2015))){
    
    # Save pv vector
    scenario.determ[[paste0(i, "pv")]]   <- dat.original[list.year.hours[[i]],pv]
    colnames(scenario.determ[[paste0(i, "pv")]]) <- country
    rownames(scenario.determ[[paste0(i, "pv")]]) <- 1:8760
    scenario.determ[[paste0(i, "pv")]]           <- data.frame(scenario.determ[[paste0(i, "pv")]])
    
    # Save onshore vector
    scenario.determ[[paste0(i, "on")]] <- dat.original[list.year.hours[[i]],onshore]
    colnames(scenario.determ[[paste0(i, "on")]]) <- country
    rownames(scenario.determ[[paste0(i, "on")]]) <- 1:8760
    scenario.determ[[paste0(i, "on")]]    <- data.frame(scenario.determ[[paste0(i, "on")]])
    
    # Save offshore vector
    scenario.determ[[paste0(i, "off")]] <- dat.original[list.year.hours[[i]],offshore]
    colnames(scenario.determ[[paste0(i, "off")]]) <- country[1:5]
    rownames(scenario.determ[[paste0(i, "off")]]) <- 1:8760
    scenario.determ[[paste0(i, "off")]] <- data.frame(scenario.determ[[paste0(i, "off")]])
    
    
}

save(scenario.determ, file = "scenarios_deterministic.rda")



