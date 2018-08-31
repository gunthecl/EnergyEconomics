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
wd.path = "/Users/claudiaguenther/Documents/EnergyEconomics/SeminarPaper/Code/R/"


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

# Normalize with maximum value
dat <-  as.data.frame(apply(dat.original, 2, function(x){
  
             ( x - max(x)) / (max(x) - min(x))
                                                }))

#dat <-  as.data.frame(apply(dat.original, 2, function(x){
  
#  ( x - mean(x)) / sd(x)
  
#}))

# Keep only every third hour
#dat <- dat[seq(from = 1, to = nrow(dat), by = 3),]

# Reshape data (each hour becomes a variable)
#dat$hour <- rep(paste0("h", 1:24), nrow(dat)/24)
dat.new  <- list()

# Drop observations to deal with full weaks
no.drop <- nrow(dat.original)-floor(nrow(dat.original)/7/24)*7*24
dat     <- dat[-c((nrow(dat)-no.drop+1):nrow(dat)),]

for (i in 1:(nrow(dat)/(24*7))){
  
  j       <- i*24*7 - 167
  
  dat.day   <- dat[j:(j+167),]
  data_long <- melt(dat.day)
  data_wide <- t(data_long$value)
  colnames(data_wide) <- data_long$variable
  
  dat.new[[i]] <- data_wide
  
}


dat <- data.frame(list.rbind(dat.new))


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
no.cl    = 40
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
centroid.vec  <- clust.centroid(dataframe = dat, clusters.IND = cluster.k$cluster)
medoid.IND    <- clust.medoid(clusters.IND = cluster.k$cluster, distancematrix = as.matrix(Dis.ecl))
medoid.vec    <- dat[medoid.IND,]
    
################################################################################
# Check suitability of cluster solution

# Compare original LDC and fitted (here GB)

test.GB.load <- medoid.vec[,2521:2688]
days.list    <- list()
days.repl    <- for (i in 1:length(cluster.k$size)){
  
              x <- as.data.frame(test.GB.load[rep(i, cluster.k$size[i]),])  
            
              days.list[[i]] <- x
              
}

test.GB      <- data.frame(list.rbind(days.list))
all.hours.GB <- unlist(test.GB)
org.GB       <- dat.original[-c((nrow(dat.original)-no.drop+1):nrow(dat.original)),]
org.GB       <- sort((  (org.GB$GB_load_entsoe_power_statistics - max(org.GB$GB_load_entsoe_power_statistics))/
                       (max(org.GB$GB_load_entsoe_power_statistics)- min(org.GB$GB_load_entsoe_power_statistics))), decreasing = TRUE)

par(mar = rep(2, 4))
plot(sort(all.hours.GB, decreasing = TRUE),type="l",col="red")
lines(org.GB, col="green")

length(org.GB) == length(all.hours.GB)


######################################################################