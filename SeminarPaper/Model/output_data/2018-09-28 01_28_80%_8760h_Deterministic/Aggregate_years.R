setwd("/Users/claudiaguenther/Documents/EnergyEconomics/SeminarPaper/Model/output_data/2018-09-28 01_28_80%_8760h_Deterministic")
wd <- getwd()
org2015 <- list()
rep2015 <- list()


for (i in c("DE", "DK", "FR","IB", "LU", "UK")){

org2015[[i]] <-read.csv(paste0(wd, "/2015_original/",i, "/Capacity"), sep = ",", header = TRUE)

rep2015[[i]] <-read.csv(paste0(wd, "/2015_replica/",i, "/Capacity"), sep = ",", header = TRUE)

}

dat.org2015 <- rlist::list.rbind(org2015)
dat.rep2015 <- rlist::list.rbind(rep2015)

org2015_aggr <- apply(dat.org2015, 2, sum)
rep2015_aggr <- apply(dat.rep2015, 2, sum)


setwd("/Users/claudiaguenther/Documents/EnergyEconomics/SeminarPaper/Model/output_data/2018-09-30 17_00_40%_4380h_Deterministic")
#setwd("/Users/claudiaguenther/Documents/EnergyEconomics/SeminarPaper/Model/output_data/2018-09-30 15_19_80%_4380h_Deterministic")

wd <- getwd()

dat1987 <- list()
dat1998 <- list()
dat2003 <- list()
dat2010 <- list()
dat2015 <- list()


for (i in c("DE", "DK", "FR","IB", "LU", "UK")){
    
    dat1987[[i]] <-read.csv(paste0(wd, "/1987/",i, "/Capacity.csv"), sep = ",", header = TRUE)
    dat1987[[i]]["PumpedStorage E"] <-read.csv(paste0(wd, "/1987/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,1]
    dat1987[[i]]["Battery E"] <-read.csv(paste0(wd, "/1987/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,2]
    dat1987[[i]]["PumpedStorage P"] <-read.csv(paste0(wd, "/1987/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,1]
    dat1987[[i]]["Battery P"] <-read.csv(paste0(wd, "/1987/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,2]   
    dat1998[[i]] <-read.csv(paste0(wd, "/1998/",i, "/Capacity.csv"), sep = ",", header = TRUE)
    dat1998[[i]]["PumpedStorage E"] <-read.csv(paste0(wd, "/1998/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,1]
    dat1998[[i]]["Battery E"] <-read.csv(paste0(wd, "/1998/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,2]
    dat1998[[i]]["PumpedStorage P"] <-read.csv(paste0(wd, "/1998/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,1]
    dat1998[[i]]["Battery P"] <-read.csv(paste0(wd, "/1998/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,2] 
    dat2003[[i]] <-read.csv(paste0(wd, "/2003/",i, "/Capacity.csv"), sep = ",", header = TRUE)
    dat2003[[i]]["PumpedStorage E"] <-read.csv(paste0(wd, "/2003/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,1]
    dat2003[[i]]["Battery E"] <-read.csv(paste0(wd, "/2003/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,2]
    dat2003[[i]]["PumpedStorage P"] <-read.csv(paste0(wd, "/2003/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,1]
    dat2003[[i]]["Battery P"] <-read.csv(paste0(wd, "/2003/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,2] 
    dat2010[[i]] <-read.csv(paste0(wd, "/2010/",i, "/Capacity.csv"), sep = ",", header = TRUE)
    dat2010[[i]]["PumpedStorage E"] <-read.csv(paste0(wd, "/2010/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,1]
    dat2010[[i]]["Battery E"] <-read.csv(paste0(wd, "/2010/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,2]
    dat2010[[i]]["PumpedStorage P"] <-read.csv(paste0(wd, "/2010/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,1]
    dat2010[[i]]["Battery P"] <-read.csv(paste0(wd, "/2010/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,2] 
    dat2015[[i]] <-read.csv(paste0(wd, "/2015/",i, "/Capacity.csv"), sep = ",", header = TRUE)
    dat2015[[i]]["PumpedStorage E"] <-read.csv(paste0(wd, "/2015/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,1]
    dat2015[[i]]["Battery E"] <-read.csv(paste0(wd, "/2015/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,2]
    dat2015[[i]]["PumpedStorage P"] <-read.csv(paste0(wd, "/2015/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,1]
    dat2015[[i]]["Battery P"] <-read.csv(paste0(wd, "/2015/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,2] 
    

}

setwd("/Users/claudiaguenther/Documents/EnergyEconomics/SeminarPaper/Model/output_data/2018-09-30 17_00_40%_168h_Stochastic")
#setwd("/Users/claudiaguenther/Documents/EnergyEconomics/SeminarPaper/Model/output_data/2018-09-30 15_19_80%_168h_Stochastic")

wd <- getwd()


datstoch <- list()
for (i in c("DE", "DK", "FR","IB", "LU", "UK")){
    
    datstoch[[i]] <-read.csv(paste0(wd,"/",i, "/Capacity.csv"), sep = ",", header = TRUE)
    datstoch[[i]]["PumpedStorage E"] <-read.csv(paste0(wd, "/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,1]
    datstoch[[i]]["Battery E"] <-read.csv(paste0(wd, "/",i, "/Storage Energy.csv"), sep = ",", header = TRUE)[,2]
    datstoch[[i]]["PumpedStorage P"] <-read.csv(paste0(wd, "/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,1]
    datstoch[[i]]["Battery P"] <-read.csv(paste0(wd, "/",i, "/Storage Power.csv"), sep = ",", header = TRUE)[,2] 
    
}



dat1987  <- rlist::list.rbind(dat1987)
dat1998  <- rlist::list.rbind(dat1998)
dat2003  <- rlist::list.rbind(dat2003)
dat2010  <- rlist::list.rbind(dat2010)
dat2015  <- rlist::list.rbind(dat2015)
datstoch <- rlist::list.rbind(datstoch)
    
dat1987$country <-rownames(dat1987)
dat1998$country <-rownames(dat1998)
dat2003$country <-rownames(dat2003)
dat2010$country <-rownames(dat2010)
dat2015$country <-rownames(dat2015)
datstoch$country <- rownames(datstoch)

dat1987$year <-1987
dat1998$year <-1998
dat2003$year <-2003
dat2010$year <-2010
dat2015$year <-2015
datstoch$year <- "stoch"


library(ggplot2)
library(reshape)
stat1987 <- melt(dat1987, id.vars = c("country", "year"))
stat1998 <- melt(dat1998, id.vars = c("country", "year"))
stat2003 <- melt(dat2003, id.vars = c("country", "year"))
stat2010 <- melt(dat2010, id.vars = c("country", "year"))
stat2015 <- melt(dat2015, id.vars = c("country", "year"))
statstoch <- melt(datstoch, id.vars = c("country", "year"))

statall <- rbind(stat1987, stat1998, 
                 stat2003, stat2010, stat2015
              , statstoch
                 )

stat.spread <- spread(statall, key = "variable", value = value)
xtable(stat.spread)

# Grouped
ggplot(test, aes(fill=variable, y=value, x=country)) + 
    geom_bar(position="dodge", stat="identity")

# Stacked
ggplot(test, aes(fill=variable, y=value, x=country)) + 
    geom_bar( stat="identity")

ggplot(statall, aes(fill=variable, y=value, x=country)) + 
    geom_bar( stat="identity") +
    scale_fill_brewer(palette = "Set1") +
    facet_wrap(~year)

ggplot(statall, aes(fill=variable, y=value, x=country)) + 
    geom_bar( stat="identity") +
    scale_fill_brewer(palette = "Set3") +
    facet_wrap(~year)

ggplot(statall, aes(fill=country, y=value, x=year)) + 
    geom_bar( stat="identity") +
    scale_fill_brewer(palette = "Set3") +
    facet_wrap(~variable, scales = "free" )


ggplot(statall, aes(fill=variable, y=value, x=country)) + 
    geom_bar( stat="identity", position = "fill") +
    scale_fill_brewer(palette = "Spectral") +
    facet_wrap(~year)


# Exclude not relevant techs
stat_select <- statall %>% filter(variable %in% c(
                                                 "Lignite", "Gas",
                                                 #, 
                                               #  "WindOnshore", "WindOffshore", "PVGround",
                                               #  "PVRoof"
                                                "PumpedStorage E", "PumpedStorage P"
                                                ))

library(plyr)
stat_select$Country <- stat_select$country
stat_select$variable = revalue(stat_select$variable, c(
                                                      "Lignite" = "Lignite", "Gas" = "Gas",
                                                      #, 
                                                      # "WindOnshore" = "Wind Onshore", 
                                                      # "WindOffshore" = "Wind Offshore",
                                                      # "PVGround" = "PV Ground",
                                                      # "PVRoof" = "PV Roof"
                                                       "PumpedStorage E" = "Pumped Storage Energy", 
                                                      "PumpedStorage P" = "Pumped Storage Power"
                                                       ))

ggplot(stat_select, aes(fill=Country, y=value/1000, x=as.factor(year))) + 
    geom_bar( stat="identity") +
    scale_fill_brewer(palette = "Set3") +
    facet_wrap(~variable
           #    , scales = "free" 
               ) + 
    labs(x = "",
        y="Capacity in GW / GWh")  +
    theme(strip.background =element_rect(fill="white")) +
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.background = element_blank(), axis.line = element_line(colour = "grey")) + theme(
        #     axis.title.x=element_blank(),
              axis.ticks.x=element_blank(),
       #       axis.title.y=element_blank(),
              panel.grid = element_blank(), 
              panel.background = element_blank(),
              legend.background = element_blank(),
              legend.box.background = element_blank()
              )

