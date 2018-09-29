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

dat.load.2015      <- read.csv(paste0(wd.path,"time_series_load_2015_final.csv"), 
                               stringsAsFactors = FALSE)


dat.2015.repl      <- load("2015_replicated.rda")

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


# Sum load for Spain & Portugal, Luxembourg & Netherlands & Belgium
dat.load.2015$LU_load_entsoe_power_statistics <-  ( dat.load.2015$BE_load_entsoe_power_statistics
                                                    + dat.load.2015$LU_load_entsoe_power_statistics
                                                    + dat.load.2015$NL_load_entsoe_power_statistics)

dat.load.2015$IB_load_entsoe_power_statistics <-  ( dat.load.2015$ES_load_entsoe_power_statistics
                                                    + dat.load.2015$PT_load_entsoe_power_statistics)

# Select columns 
var.vec     <- c("LU_pv_national_current", "LU_wind_onshore_current", "LU_wind_offshore_current",
                 "DE_pv_national_current", "DE_wind_onshore_current", "DE_wind_offshore_current",
                 "DK_pv_national_current", "DK_wind_onshore_current", "DK_wind_offshore_current",
                 "FR_pv_national_current", "FR_wind_onshore_current", "FR_wind_offshore_current",
                 "GB_pv_national_current", "GB_wind_onshore_current", "GB_wind_offshore_current",
                 "IB_pv_national_current", "IB_wind_onshore_current")

dat.original <- dat.res[,var.vec]

var.vec.load <- c("LU_load_entsoe_power_statistics",
                  "DE_load_entsoe_power_statistics", 
                  "DK_load_entsoe_power_statistics",
                  "FR_load_entsoe_power_statistics",
                  "GB_load_entsoe_power_statistics",
                  "IB_load_entsoe_power_statistics")

dat.load     <- dat.load.2015[,var.vec.load]


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

library(plyr)
mean.values$var = revalue(mean.values$var, c("pv_national_current"="PV", 
                      "wind_onshore_current"="Wind Onshore",
                      "wind_offshore_current" = "Wind Offshore"))
       
ggplot(data = mean.values, aes(x=var, y=value)) + geom_boxplot(aes(fill=Country)) + 
    labs(x = "",
         y="Annual mean availability")  +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) + theme(
          axis.title.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.y=element_blank(),
       #   plot.margin=unit(c(1,1,1,2), "cm"),
          panel.grid = element_blank(), 
          panel.background = element_blank(),
          legend.background = element_blank(),
          legend.box.background = element_blank())


mean.values <- spread(data = mean.values[,c(1,3:5)], key = "var", value = "value")


mean.export <- mean.values %>% filter(year %in% c(1987, 1998, 2003,2010,2015))
write.csv(mean.export, file = "mean_avail_selected_years")

library(xtable)
options(xtable.floating = FALSE) 
options(xtable.timestamp = "")
xtable(mean.export)

mean.export <- melt(data = data.frame(mean.export), id.vars = c("year", "Country"))
mean.export$year <- as.factor(mean.export$year)


ggplot((mean.export), aes(fill=variable, y=value, x=year)) + 
  geom_bar( stat="identity") +
  scale_fill_brewer(palette = "Set3") +
  facet_wrap(~variable)


ggplot(mean.values, aes(x=factor(year), group=Country, colour=Country)) +
    geom_line(aes(y = PV), linetype = "dashed") + 
    geom_line(aes(y = 'Wind Onshore' )) + 
    geom_line(aes(y = 'Wind offshore'), linetype="twodash") +
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
    
    # Save load vector
    scenario.determ[[paste0(i, "load")]] <- dat.load
    colnames(scenario.determ[[paste0(i, "load")]]) <- country
    rownames(scenario.determ[[paste0(i, "load")]]) <- 1:8760
    scenario.determ[[paste0(i, "load")]] <- data.frame(scenario.determ[[paste0(i, "load")]])
    
    
}

# Save replicated from 2015 Data

# Save pv vector
scenario.determ[["2016pv"]]           <- dat.2015.medoid.scaled[,pv]
colnames(scenario.determ[["2016pv"]])<- country
rownames(scenario.determ[["2016pv"]]) <- 1:8760
scenario.determ[["2016pv"]]           <- data.frame(scenario.determ[["2016pv"]])

# Save onshore vector
scenario.determ[["2016on"]]           <- dat.2015.medoid.scaled[,onshore]
colnames(scenario.determ[["2016on"]]) <- country
rownames(scenario.determ[["2016on"]]) <- 1:8760
scenario.determ[["2016on"]]    <- data.frame(scenario.determ[["2016on"]])

# Save offshore vector
scenario.determ[["2016off"]] <- dat.2015.medoid.scaled[,offshore]
colnames(scenario.determ[["2016off"]]) <- country[1:5]
rownames(scenario.determ[["2016off"]]) <- 1:8760
scenario.determ[["2016off"]] <- data.frame(scenario.determ[["2016off"]])


scenario.determ[["2016load"]]           <- dat.2015.medoid.scaled[,18:23]
colnames(scenario.determ[["2016load"]])  <- country
rownames(scenario.determ[["2016load"]])  <- 1:8760


save(scenario.determ, file = "scenarios_deterministic.rda")



