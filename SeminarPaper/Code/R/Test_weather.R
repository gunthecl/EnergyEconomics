################################################################################
#
# Clustering of wind and pv time series
#
################################################################################

rm(list = ls())

# List all packages needed for session
neededPackages = c("dplyr", "tidyr", "psych", "cluster", "distances", 
                   "ecodist", "magrittr", "lattice", "MASS", "GGally",
                   "NbClust", "rlist", "caret", "ggplot2", "reshape2", "grid")
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
wd.path = "X:/guec/other/EnergyEconomics/SeminarPaper/Code/R/"


# Read in wind and pv data set
dat.res            <- read.csv(paste0(wd.path,"ninja_pv_wind_profiles_1985-2016_final.csv"), 
                          stringsAsFactors = FALSE)
dat.load.2015      <- read.csv(paste0(wd.path,"time_series_load_2015_final.csv"), 
                          stringsAsFactors = FALSE)

# Source needed functions
setwd(wd.path)
source("HelperFunctions.R")

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

var.vec.load <- c("LU_load_entsoe_power_statistics",
                  "DE_load_entsoe_power_statistics", 
                  "DK_load_entsoe_power_statistics",
                  "FR_load_entsoe_power_statistics",
                  "GB_load_entsoe_power_statistics",
                  "IB_load_entsoe_power_statistics")

dat.original <- dat.res[,var.vec]

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

# Bind load data (2015) to all years
load.vec         <- dat.load[rep(seq_len(nrow(dat.load)), times = nrow(dat.original)/nrow(dat.load)),]

dat.original     <- cbind(dat.original, load.vec)

rm(dat.load, dat.load.2015, var.vec, var.vec.load, years.sequence,
   dat.res, load.vec, hours.year, leap.days.vec, leap.hours,
   neededPackages, allPackages)

# Normalize with maximum value
dat <-  as.data.frame(apply(dat.original, 2, function(x){
  
             ( x - max(x)) / (max(x) - min(x))
                                                }))

#dat2 <-  as.data.frame(apply(dat.original, 2, function(x){
#  ( x - mean(x)) / sd(x)
#}))

# Keep only every third hour
#dat <- dat[seq(from = 1, to = nrow(dat), by = 3),]

# Reshape data (each hour becomes a variable)
#dat$hour <- rep(paste0("h", 1:24), nrow(dat)/24)
dat.new      <- list()
dat.unscaled <- dat.original

# Drop observations to deal with full weaks
no.drop      <- nrow(dat.original)-floor(nrow(dat.original)/7/24)*7*24
dat          <- dat[-c((nrow(dat)-no.drop+1):nrow(dat)),]
dat.unscaled <- dat.original[-c((nrow(dat.original)-no.drop+1):nrow(dat.original)),]
dat.original <- dat.unscaled

# Extend data set to wide format (each hour as variable)
# for (i in 1:(nrow(dat)/(24))){
#   
#   j       <- i*24 - 23
#   
#   dat.day   <- dat[j:(j+23),]
#   data_long <- melt(dat.day)
#   data_wide <- t(data_long$value)
#   colnames(data_wide) <- data_long$variable
#   
#   dat.new[[i]] <- data_wide
#   
# }
# 
# 
# dat <- data.frame(list.rbind(dat.new))
# 
# # Repeat for unscaled data
# for (i in 1:(nrow(dat.unscaled)/(24))){
#   
#   j       <- i*24 - 23
#   
#   dat.day   <- dat.unscaled[j:(j+23),]
#   data_long <- melt(dat.day)
#   data_wide <- t(data_long$value)
#   colnames(data_wide) <- data_long$variable
#   
#   dat.new[[i]] <- data_wide
#   
# }

# Extend data set to wide format (each hour of a week as variable)
for (i in 1:(nrow(dat)/(24*7))){
  
  j       <- i*24*7 - (24*7-1)
  
  dat.week  <- dat[j:(j+167),]
  data_long <- melt(dat.week)
  data_wide <- t(data_long$value)
  colnames(data_wide) <- data_long$variable
  
  dat.new[[i]] <- data_wide
  
}


dat <- data.frame(list.rbind(dat.new))

# Repeat for unscaled data
for (i in 1:(nrow(dat.unscaled)/(24*7))){
  
  j       <- i*24*7 - (24*7-1)
  
  dat.week  <- dat.unscaled[j:(j+167),]
  data_long <- melt(dat.week)
  data_wide <- t(data_long$value)
  colnames(data_wide) <- data_long$variable
  
  dat.new[[i]] <- data_wide
  
}



dat.unscaled <- data.frame(list.rbind(dat.new))


# Use euclidean distance
Dis.ecl <- dist(dat, method = "euclidean")

# Hierachcal cluster analysis based on Ward & euclidean distance
clus <- hclust(Dis.ecl, method = "ward.D2")
#par(mar = rep(2, 4))
#plot(clus)
#plot(clus, hang = -1, cex = 0.6)
#dendrogram <- as.dendrogram(clus)
#plot(dendrogram, ylab = "Height", leaflab = "none")

# Determine the number of clusters
no.cl    = 30
clusters = cutree(clus, k = no.cl) 
#rect.hclust(clus, k= no.cl, border="red") 

# Find centroids and medoids of clusters
centroid.vec  <- clust.centroid(dataframe = dat.unscaled, clusters.IND = clusters)
medoid.IND    <- clust.medoid(clusters.IND = clusters, distancematrix = as.matrix(Dis.ecl))
medoid.vec    <- dat.unscaled[medoid.IND,]
    
# Determine cluster sizes
cluster.size  <- table(clusters)



######################################################################
## Compare load duration, wind and pv factor curves for Germany

# Find columns of German load data
col.load.GER     <- grepl("DE_load", colnames(medoid.vec))
GER.load         <- medoid.vec[,col.load.GER]
col.load.GER.org <- grepl("DE_load", colnames(dat.original))

# Mutiply each cluster with its size
days.list   <- list()
days.repl   <- for (i in 1:length(cluster.size)){
  
  x <- as.data.frame(GER.load[rep(i, cluster.size[i]),])  
  
  days.list[[i]] <- x
  
}

GER.load.repl <- data.frame(list.rbind(days.list))
GER.load.repl <- sort(unlist(GER.load.repl), decreasing = TRUE)
GER.load.org  <- dat.original[,col.load.GER.org]
GER.load.org  <- sort(GER.load.org, decreasing = TRUE)


GER.load.both <- as.data.frame(cbind(GER.load.org, GER.load.repl))
GER.load.both$hour <- 1:nrow(GER.load.both)
ggplot(GER.load.both, aes(x = hour)) + 
    geom_line(aes(y = GER.load.org, colour = "Original LDC" )) + 
    geom_line(aes(y = GER.load.repl, colour = "Replicated LDC")) + 
    scale_colour_manual("", 
                        breaks = c("Original LDC", "Replicated LDC"),
                        values = c("grey", "brown")) +
    ylab(label="Load in MWh") + 
    xlab("Hours") + 
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.background = element_blank(), axis.line = element_line(colour = "grey")) + theme(
              plot.margin=unit(c(1,1,1,2), "cm"),
              panel.grid = element_blank(),
              axis.ticks.x=element_blank(),
              axis.text.x=element_blank(),
              panel.background = element_blank(),
              legend.key=element_blank())

rm(GER.load.both, GER.load.org, GER.load.repl,
   col.load.GER, col.load.GER.org)

# Find columns of German pv data
col.pv.GER     <- grepl("DE_pv", colnames(medoid.vec))
GER.load         <- medoid.vec[,col.pv.GER]
col.pv.GER.org <- grepl("DE_pv", colnames(dat.original))

# Mutiply each cluster with its size
days.list   <- list()
days.repl   <- for (i in 1:length(cluster.size)){
  
  x <- as.data.frame(GER.load[rep(i, cluster.size[i]),])  
  
  days.list[[i]] <- x
  
}

GER.pv.repl <- data.frame(list.rbind(days.list))
GER.pv.repl <- sort(unlist(GER.pv.repl), decreasing = TRUE)
GER.pv.org  <- dat.original[,col.pv.GER.org]
GER.pv.org  <- sort(GER.pv.org, decreasing = TRUE)


GER.pv.both <- as.data.frame(cbind(GER.pv.org, GER.pv.repl))
GER.pv.both$hour <- 1:nrow(GER.pv.both)
ggplot(GER.pv.both, aes(x = hour)) + 
    geom_line(aes(y = GER.pv.org, colour = "Original pv series" )) + 
    geom_line(aes(y = GER.pv.repl, colour = "Replicated pv series")) + 
    scale_colour_manual("", 
                        breaks = c("Original pv series", "Replicated pv series"),
                        values = c("grey", "orange")) +
    ylab(label="Load in MWh") + 
    xlab("Hours") + 
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.background = element_blank(), axis.line = element_line(colour = "grey")) + theme(
              plot.margin=unit(c(1,1,1,2), "cm"),
              panel.grid = element_blank(),
              axis.ticks.x=element_blank(),
              axis.text.x=element_blank(),
              panel.background = element_blank(),
              legend.key=element_blank())


rm(GER.pv.both, GER.pv.org, GER.pv.repl,
   col.pv.GER, col.pv.GER.org)

# Find columns of German onshore wind data
col.wind_on.GER     <- grepl("DE_wind_on", colnames(medoid.vec))
GER.load            <- medoid.vec[,col.wind_on.GER]
col.wind_on.GER.org <- grepl("DE_wind_on", colnames(dat.original))

# Mutiply each cluster with its size
days.list   <- list()
days.repl   <- for (i in 1:length(cluster.size)){
  
  x <- as.data.frame(GER.load[rep(i, cluster.size[i]),])  
  
  days.list[[i]] <- x
  
}

GER.wind_on.repl <- data.frame(list.rbind(days.list))
GER.wind_on.repl <- sort(unlist(GER.wind_on.repl), decreasing = TRUE)
GER.wind_on.org  <- dat.original[,col.wind_on.GER.org]
GER.wind_on.org  <- sort(GER.wind_on.org, decreasing = TRUE)

# Find columns of German offshore wind data
col.wind_off.GER     <- grepl("DE_wind_off", colnames(medoid.vec))
GER.load             <- medoid.vec[,col.wind_off.GER]
col.wind_off.GER.org <- grepl("DE_wind_off", colnames(dat.original))

# Mutiply each cluster with its size
days.list   <- list()
days.repl   <- for (i in 1:length(cluster.size)){
  
  x <- as.data.frame(GER.load[rep(i, cluster.size[i]),])  
  
  days.list[[i]] <- x
  
}

GER.wind_off.repl <- data.frame(list.rbind(days.list))
GER.wind_off.repl <- sort(unlist(GER.wind_off.repl), decreasing = TRUE)
GER.wind_off.org  <- dat.original[,col.wind_off.GER.org]
GER.wind_off.org  <- sort(GER.wind_off.org, decreasing = TRUE)

# Rescale replicated data set 
gamma             <- (mean(GER.wind_off.repl)- mean(GER.wind_off.org))
GER.wind_off.repl <- scale(GER.wind_off.repl, center = gamma, scale = FALSE)
gamma             <- (mean(GER.wind_on.repl)- mean(GER.wind_on.org))
GER.wind_on.repl <- scale(GER.wind_on.repl, center = gamma, scale = FALSE)

GER.wind.both      <- as.data.frame(cbind(GER.wind_on.org,  GER.wind_on.repl,
                                          GER.wind_off.org, GER.wind_off.repl))

GER.wind.both$hour <- 1:nrow(GER.wind.both)


ggplot(GER.wind.both, aes(x = hour)) + 
  geom_line(aes(y = GER.wind_on.org, colour = "Original onshore series" )) + 
  geom_line(aes(y = GER.wind_on.repl, colour = "Replicated onshore series")) + 
  geom_line(aes(y = GER.wind_off.org, colour = "Original offshore series" )) + 
  geom_line(aes(y = GER.wind_off.repl, colour = "Replicated offshore series")) +
  scale_colour_manual("", 
                      breaks = c("Original onshore series", "Replicated onshore series",
                                 "Original offshore series", "Replicated offshore series"),
                      values = c("grey", "light blue", " dark blue", "dark green")) +
  ylab(label="Load in MWh") + 
  xlab("Hours") + 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "grey")) + theme(
          plot.margin=unit(c(1,1,1,2), "cm"),
          panel.grid = element_blank(),
          axis.ticks.x=element_blank(),
          axis.text.x=element_blank(),
          panel.background = element_blank(),
          legend.key=element_blank())

length(GER.wind_off.org) == length(GER.wind_off.repl)

rm(GER.wind.both, GER.wind_on.org, GER.wind_on.repl,
   col.wind_on.GER, col.wind_on.GER.org,
  GER.wind_off.org, GER.wind_off.repl,
   col.wind_off.GER, col.wind_off.GER.org)

################################################################################
# Reproduce 2015 weather year with cluster medoids

# # Daily Basis
# days.2015       <- {(365*30)+1}:{365*31}
# hours.2015      <- {(365*30*24)+1}:{365*31*24}
# cluster.2015    <- clusters[days.2015]
# 
# dat.2015.medoid.raw  <- medoid.vec[cluster.2015,]
# dat.2015.medoid.list <- list()
# # Merge hours back into one vector
# for (i in 1:23){
#   
#     vec.hours <- {i*24-23}:{i*24}
#     col.vec   <-  dat.2015.medoid.raw[,vec.hours]
#     day       <- list()
#     
#     for (j in 1:nrow(col.vec)){
#       
#       day[[j]] <- as.numeric(col.vec[j,])
#       
#       
#     }
#     
#     dat.2015.medoid.list[[i]] <- unlist(t(day))
#   
#   
# }

# Weekly Basis
weeks.2015      <- {1564}:{1564+51}
hours.2015      <- {(365*30*24)+1}:{365*31*24}
cluster.2015    <- clusters[weeks.2015]

dat.2015.medoid.raw  <- medoid.vec[cluster.2015,]
dat.2015.medoid.list <- list()

# Merge hours back into one vector
for (i in 1:23){
  
  vec.hours <- {i*168-167}:{i*168}
  col.vec   <-  dat.2015.medoid.raw[,vec.hours]
  week       <- list()
  
  for (j in 1:nrow(col.vec)){
    
    week[[j]] <- as.numeric(col.vec[j,])
    
    
  }
  
  dat.2015.medoid.list[[i]] <- unlist(t(week))
  
  
}


# Finish replicated and original 2015 data set
dat.2015.medoid           <- data.frame(t(list.rbind(dat.2015.medoid.list)))
colnames(dat.2015.medoid) <- colnames(dat.original)
dat.2015.org              <- dat.original[hours.2015,]

# Duplicated last day of the year
dat.2015.medoid <- rbind(dat.2015.medoid, dat.2015.medoid[8713:8736,])

# Rescale replicated data set
mean.org   = apply(dat.2015.org, 2, mean)
mean.clust = apply(dat.2015.medoid, 2, mean)
gamma      = (mean.clust-mean.org)
dat.2015.medoid.scaled = as.data.frame(scale(dat.2015.medoid, center = gamma, scale = FALSE))

rm(dat.2015.medoid.raw, dat.2015.medoid.list)

# Compare both data sets
dat.compare  <- cbind(dat.2015.medoid.scaled, dat.2015.org)
vec.names    <- colnames(dat.2015.org)
colnames(dat.compare) <- c(paste0(vec.names, ".rep"), paste0(vec.names, ".org"))
dat.compare$hour  <- 1:8760


ggplot(dat.compare, aes(x = hour)) + 
    geom_line(aes(y = sort(DE_load_entsoe_power_statistics.org, 
                           decreasing = TRUE), colour = "Original LDC" )) + 
    geom_line(aes(y = sort(DE_load_entsoe_power_statistics.rep, 
                           decreasing = TRUE), colour = "Replicated LDC")) + 
    scale_colour_manual("", 
                        breaks = c("Original LDC", "Replicated LDC"),
                        values = c("grey", "brown")) +
    ylab(label="Load in MWh") + 
    xlab("Hour") + 
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.background = element_blank(), axis.line = element_line(colour = "grey")) + theme(
              plot.margin=unit(c(1,1,1,2), "cm"),
              panel.grid = element_blank(), 
              panel.background = element_blank(),
              legend.key=element_blank())


ggplot(dat.compare, aes(x = hour)) + 
    geom_line(aes(y = sort(DE_pv_national_current.org, 
                           decreasing = TRUE), colour = "Original pv curve" )) + 
    geom_line(aes(y = sort(DE_pv_national_current.rep, 
                           decreasing = TRUE), colour = "Replicated pv curve")) + 
    scale_colour_manual("", 
                        breaks = c("Original pv curve", "Replicated pv curve"),
                        values = c("grey", "orange")) +
    ylab(label="Capacity factor") + 
    xlab("Hour") + 
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.background = element_blank(), axis.line = element_line(colour = "grey")) + theme(
              plot.margin=unit(c(1,1,1,2), "cm"),
              panel.grid = element_blank(), 
              panel.background = element_blank(),
              legend.key=element_blank())


ggplot(dat.compare, aes(x = hour)) + 
    geom_line(aes(y = sort(DE_wind_onshore_current.org, 
                           decreasing = TRUE), colour = "Original onshore wind" )) + 
    geom_line(aes(y = sort(DE_wind_onshore_current.rep, 
                           decreasing = TRUE), colour = "Replicated onshore wind")) + 
    geom_line(aes(y = sort(DE_wind_offshore_current.org, 
                           decreasing = TRUE), colour = "Original offshore wind" )) + 
    geom_line(aes(y = sort(DE_wind_offshore_current.rep, 
                           decreasing = TRUE), colour = "Replicated offshore wind")) + 
    scale_colour_manual("", 
                        breaks = c("Original onshore wind", "Replicated onshore wind",
                                   "Original offshore wind", "Replicated offshore wind" ),
                        values = c("grey81",  "light blue","grey39","dark blue")) +
    ylab(label="Capacity factor") + 
    xlab("Hour") + 
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.background = element_blank(), axis.line = element_line(colour = "grey")) + theme(
              plot.margin=unit(c(1,1,1,2), "cm"),
              panel.grid = element_blank(), 
              panel.background = element_blank(),
              legend.key=element_blank())



# Store 2015 replicated data
save(dat.2015.medoid.scaled, file = "2015_replicated.rda")

################################################################################
# Export
## Store each scenario separately 
scenarios <- list()
# for (i in 1:nrow(medoid.vec)){
#     
#     data.raw       <- list()
#     steps          <- ncol(medoid.vec)/24
#     
#     for (j in 1:steps){
#         
#     hours.day    <- {j*24-23}:{j*24}  
#     new.variable <- t(medoid.vec[i,hours.day]) 
#     
#     colnames(new.variable) <- colnames(medoid.vec[i,hours.day])[1]
#     data.raw[[j]] <- (new.variable)
#     }
#     
#     scenarios[[i]] <- list.cbind(data.raw)
#     
# }

for (i in 1:nrow(medoid.vec)){
  
  data.raw       <- list()
  steps          <- ncol(medoid.vec)/24/7
  
  for (j in 1:steps){
    
    hours.week    <- {j*24*7-167}:{j*24*7}  
    new.variable <- t(medoid.vec[i,hours.week]) 
    
    colnames(new.variable) <- colnames(medoid.vec[i,hours.week])[1]
    data.raw[[j]] <- (new.variable)
  }
  
  scenarios[[i]] <- list.cbind(data.raw)
  
}



## Split each technology separately 

scenario.tech <- list()
pv       <- seq(from = 1, to = 17, by = 3)
onshore  <- seq(from = 2, to = 17, by = 3)
offshore <- seq(from = 3, to = 17, by = 3)
load     <- 18:23

country <- c("LU", "DE", "DK", "FR", "UK", "IB")

# Weekly data
vec.hour <- 1:168
# Daly data
#vec.hour <- 1:24


for (i in 1:30){

   # Save pv vector
   scenario.tech[[paste0(i, "pv")]]           <- scenarios[[i]][vec.hour,pv]
   colnames(scenario.tech[[paste0(i, "pv")]]) <- country
   rownames(scenario.tech[[paste0(i, "pv")]]) <- vec.hour
   scenario.tech[[paste0(i, "pv")]]           <- data.frame(scenario.tech[[paste0(i, "pv")]])
   
   # Save onshore vector
   scenario.tech[[paste0(i, "on")]] <- scenarios[[i]][ vec.hour,onshore]
   colnames(scenario.tech[[paste0(i, "on")]]) <- country
   rownames(scenario.tech[[paste0(i, "on")]]) <- vec.hour
   scenario.tech[[paste0(i, "on")]]    <- data.frame(scenario.tech[[paste0(i, "on")]])
   
   # Save offshore vector
   scenario.tech[[paste0(i, "off")]] <- scenarios[[i]][ vec.hour,offshore]
   colnames(scenario.tech[[paste0(i, "off")]]) <- country[1:5]
   rownames(scenario.tech[[paste0(i, "off")]]) <- vec.hour
   scenario.tech[[paste0(i, "off")]] <- data.frame(scenario.tech[[paste0(i, "off")]])
   # Save load vector
   scenario.tech[[paste0(i, "load")]] <- scenarios[[i]][ vec.hour,load]
   colnames(scenario.tech[[paste0(i, "load")]]) <- country
   rownames(scenario.tech[[paste0(i, "load")]]) <-  vec.hour
   scenario.tech[[paste0(i, "load")]] <- data.frame(scenario.tech[[paste0(i, "load")]])
   
    
}



mean.vecs <- list()
for (i in 1:30){
    
    
    mean.vecs[[i]] <- apply(scenarios[[i]], 2, mean)
    
}

z <- list.rbind(mean.vecs)

#save(medoid.vec, file = "scenario30.rda")
save(scenarios, file = "scenarios30_week.rda")
save(scenario.tech, file = "scenariotech30_week.rda")
write.csv(x = medoid.vec, file = "test.csv")
write.csv(x = scenario.tech, file = "tech_week.csv")


# Save weights fpr scenarios
weights <- cluster.size/sum(cluster.size)

# Sanity check
sum(cluster.size) == nrow(dat.original)/24/7

save(weights, file = "weights30_week.rda")
write.csv(x = weights, file = "weights30_week.csv")

labels.country <- country
tech <- c("pv", "onshore", "offshore", "load")
labels.tech    <- cbind((rep(1:30, each = 4)), tech)

write.csv(x = labels.tech, file = "labelscen_week.csv")
write.csv(x = country, file = "labelcountry_week.csv")

