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
wd.path = "/Users/Lenovo/Documents/Github/EnergyEconomics/SeminarPaper/Code/R/"


# Read in wind and pv data set
dat.res            <- read.csv(paste0(wd.path,"ninja_pv_wind_profiles_1985-2016.csv"), 
                          stringsAsFactors = FALSE)
dat.load.2014      <- read.csv(paste0(wd.path,"time_series_60min_load.csv"), 
                          stringsAsFactors = FALSE)

# Source needed functions
source("HelperFunctions.R")

################################################################################

# Select columns 
var.vec     <- c("DE_pv_national_current", "DE_wind_onshore_current", "DE_wind_offshore_current",
           "DK_pv_national_current", "DK_wind_onshore_current", "DK_wind_offshore_current",
          # "ES_pv_national_current", "ES_wind_national_current",
           "FR_pv_national_current", "FR_wind_onshore_current", "FR_wind_offshore_current",
           "GB_pv_national_current", "GB_wind_onshore_current", "GB_wind_offshore_current")
var.vec.load <- c("DE_load_entsoe_power_statistics", 
                  "DK_load_entsoe_power_statistics",
#                  "ES_load_entsoe_power_statistics",
                  "FR_load_entsoe_power_statistics",
                  "GB_load_entsoe_power_statistics")
dat.original <- dat.res[,var.vec]
dat.load     <- dat.load.2014[,var.vec.load]

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

# Bind load data (2014) to all years
load.vec         <- dat.load[rep(seq_len(nrow(dat.load)), each=nrow(dat.original)/nrow(dat.load)),]

dat.original     <- cbind(dat.original, load.vec)

rm(dat.load, dat.load.2014, var.vec, var.vec.load, years.sequence,
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
dat.new  <- list()

# Drop observations to deal with full weaks
no.drop      <- nrow(dat.original)-floor(nrow(dat.original)/7/24)*7*24
dat          <- dat[-c((nrow(dat)-no.drop+1):nrow(dat)),]
dat.unscaled <- dat.original[-c((nrow(dat.original)-no.drop+1):nrow(dat.original)),]

# Extend data set to wide format (each hour as variable)
for (i in 1:(nrow(dat)/(24))){
  
  j       <- i*24 - 23
  
  dat.day   <- dat[j:(j+23),]
  data_long <- melt(dat.day)
  data_wide <- t(data_long$value)
  colnames(data_wide) <- data_long$variable
  
  dat.new[[i]] <- data_wide
  
}


dat <- data.frame(list.rbind(dat.new))

# Repeat for unscaled data
for (i in 1:(nrow(dat.unscaled)/(24))){
  
  j       <- i*24 - 23
  
  dat.day   <- dat.unscaled[j:(j+23),]
  data_long <- melt(dat.day)
  data_wide <- t(data_long$value)
  colnames(data_wide) <- data_long$variable
  
  dat.new[[i]] <- data_wide
  
}


dat.unscaled <- data.frame(list.rbind(dat.new))


# Use euclidean distance
Dis.ecl <- dist(dat, method = "euclidean")

# Hierachcal cluster analysis based on Ward & euclidean distance
clus <- hclust(Dis.ecl, method = "ward.D2")
par(mar = rep(2, 4))
plot(clus)
plot(clus, hang = -1, cex = 0.6)
dendrogram <- as.dendrogram(clus)
plot(dendrogram, ylab = "Height", leaflab = "none")

# Determine the number of clusters
no.cl    = 60
clusters = cutree(clus, k = no.cl) 
rect.hclust(clus, k= no.cl, border="red") 

# Get centroids: Use for k mean initialization
centroids = clust.centroid(dataframe = dat, clusters.IND = clusters)

# Run k means on extracted centroids
cluster.k          <-  kmeans(dat, centers = centroids)
cluster.center     <-  cluster.k$centers

# Oberve change of cluster membership
final.table <- table(cluster.k$cluster, clusters) # relatively stable
final.memb  <- cluster.k$cluster 

# Find centroids and medoids of clusters
centroid.vec  <- clust.centroid(dataframe = dat.unscaled, clusters.IND = cluster.k$cluster)
medoid.IND    <- clust.medoid(clusters.IND = cluster.k$cluster, distancematrix = as.matrix(Dis.ecl))
medoid.vec    <- dat.unscaled[medoid.IND,]
    
################################################################################
# Check suitability of cluster solution

# Compare original LDC and fitted (here GB)

test.GB.load <- medoid.vec[,361:384]
days.list    <- list()
days.repl    <- for (i in 1:length(cluster.k$size)){
  
              x <- as.data.frame(test.GB.load[rep(i, cluster.k$size[i]),])  
            
              days.list[[i]] <- x
              
}

test.GB      <- data.frame(list.rbind(days.list))
all.hours.GB <- unlist(test.GB)
org.GB       <- dat.original[-c((nrow(dat.original)-no.drop+1):nrow(dat.original)),]
org.GB       <- sort(org.GB$GB_load_entsoe_power_statistics, decreasing = TRUE)

par(mar = rep(2, 4))
plot(sort(all.hours.GB, decreasing = TRUE),type="l",col="red")
lines(org.GB, col="green")

length(org.GB) == length(all.hours.GB)


######################################################################
## Compare load duration, wind and pv factor curves for Germany

# Find columns of German load data
col.load.GER     <- grepl("DE_load", colnames(medoid.vec))
GER.load         <- medoid.vec[,col.load.GER]
col.load.GER.org <- grepl("DE_load", colnames(dat.original))

# Mutiply each cluster with its size
days.list   <- list()
days.repl   <- for (i in 1:length(cluster.k$size)){
  
  x <- as.data.frame(GER.load[rep(i, cluster.k$size[i]),])  
  
  days.list[[i]] <- x
  
}

GER.load.repl <- data.frame(list.rbind(days.list))
GER.load.repl <- unlist(GER.load.repl)
GER.load.org  <- dat.original[1:(nrow(dat.original)-no.drop),col.load.GER.org]
GER.load.org  <- sort(GER.load.org, decreasing = TRUE)

par(mar = rep(2, 4))
plot(sort(GER.load.repl, decreasing = TRUE),type="l",col="red")
lines(GER.load.org, col="green")

length(GER.load.org) == length(GER.load.repl)

# Find columns of German pv data
col.pv.GER     <- grepl("DE_pv", colnames(medoid.vec))
GER.load         <- medoid.vec[,col.pv.GER]
col.pv.GER.org <- grepl("DE_pv", colnames(dat.original))

# Mutiply each cluster with its size
days.list   <- list()
days.repl   <- for (i in 1:length(cluster.k$size)){
  
  x <- as.data.frame(GER.load[rep(i, cluster.k$size[i]),])  
  
  days.list[[i]] <- x
  
}

GER.pv.repl <- data.frame(list.rbind(days.list))
GER.pv.repl <- unlist(GER.pv.repl)
GER.pv.org  <- dat.original[1:(nrow(dat.original)-no.drop),col.pv.GER.org]
GER.pv.org  <- sort(GER.pv.org, decreasing = TRUE)

par(mar = rep(2, 4))
plot(sort(GER.pv.repl, decreasing = TRUE),type="l",col="red")
lines(GER.pv.org, col="green")

length(GER.pv.org) == length(GER.pv.repl)

# Find columns of German onshore wind data
col.wind_on.GER     <- grepl("DE_wind_on", colnames(medoid.vec))
GER.load            <- medoid.vec[,col.wind_on.GER]
col.wind_on.GER.org <- grepl("DE_wind_on", colnames(dat.original))

# Mutiply each cluster with its size
days.list   <- list()
days.repl   <- for (i in 1:length(cluster.k$size)){
  
  x <- as.data.frame(GER.load[rep(i, cluster.k$size[i]),])  
  
  days.list[[i]] <- x
  
}

GER.wind_on.repl <- data.frame(list.rbind(days.list))
GER.wind_on.repl <- unlist(GER.wind_on.repl)
GER.wind_on.org  <- dat.original[1:(nrow(dat.original)-no.drop),col.wind_on.GER.org]
GER.wind_on.org  <- sort(GER.wind_on.org, decreasing = TRUE)

par(mar = rep(2, 4))
plot(sort(GER.wind_on.repl, decreasing = TRUE),type="l",col="red")
lines(GER.wind_on.org, col="green")

length(GER.wind_on.org) == length(GER.wind_on.repl)

# Find columns of German offshore wind data
col.wind_off.GER     <- grepl("DE_wind_off", colnames(medoid.vec))
GER.load         <- medoid.vec[,col.wind_off.GER]
col.wind_off.GER.org <- grepl("DE_wind_off", colnames(dat.original))

# Mutiply each cluster with its size
days.list   <- list()
days.repl   <- for (i in 1:length(cluster.k$size)){
  
  x <- as.data.frame(GER.load[rep(i, cluster.k$size[i]),])  
  
  days.list[[i]] <- x
  
}

GER.wind_off.repl <- data.frame(list.rbind(days.list))
GER.wind_off.repl <- unlist(GER.wind_off.repl)
GER.wind_off.org  <- dat.original[1:(nrow(dat.original)-no.drop),col.wind_off.GER.org]
GER.wind_off.org  <- sort(GER.wind_off.org, decreasing = TRUE)

par(mar = rep(2, 4))
plot(sort(GER.wind_off.repl, decreasing = TRUE),type="l",col="red")
lines(GER.wind_off.org, col="green")

length(GER.wind_off.org) == length(GER.wind_off.repl)

################################################################################
# Reproduce 2014 weather year with cluster medoids

days.2014       <- {365*28+1}:{365*29}
hours.2014      <- {365*29*24+1}:{365*30*24}
cluster.2014    <- cluster.k$cluster[days.2014]

dat.2014.medoid.raw  <- medoid.vec[cluster.2014,]
dat.2014.medoid.list <- list()
# Merge hours back into one vector
for (i in 1:16){
  
    vec.hours <- {i*24-23}:{i*24}
    col.vec   <-  dat.2014.medoid.raw[,vec.hours]
    day       <- list()
    
    for (j in 1:nrow(col.vec)){
      
      day[[j]] <- as.numeric(col.vec[j,])
      
      
    }
    
    dat.2014.medoid.list[[i]] <- unlist(t(day))
  
  
}

# Finish replicated and original 2014 data set
dat.2014.medoid           <- data.frame(t(list.rbind(dat.2014.medoid.list)))
colnames(dat.2014.medoid) <- colnames(dat.original)
dat.2014.org              <- dat.original[hours.2014,]

# Rescale replicated data set
g = apply(dat.2014.org, 2, mean)
t = apply(dat.2014.medoid, 2, mean)
n = apply(dat.2014.org, 2, sd)
m = apply(dat.2014.medoid, 2, sd)
gamma = (t-g)
delta = m/n
f = as.data.frame(scale(dat.2014.medoid, center = gamma, scale = delta))

rm(dat.2014.medoid.raw, dat.2014.medoid.list)

# Compare both data sets
par(mar = rep(2, 4))
plot(sort(f$FR_load_entsoe_power_statistics, decreasing = TRUE),type="l",col="red")
lines(sort(dat.2014.org$FR_load_entsoe_power_statistics, decreasing = TRUE), col="green")

summary(f$FR_load_entsoe_power_statistics)
summary(dat.2014.medoid$FR_load_entsoe_power_statistics)
summary(dat.original$FR_load_entsoe_power_statistics)

