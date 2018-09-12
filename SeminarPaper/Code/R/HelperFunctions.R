# Function to find centroid in cluster i
clust.centroid = function(dataframe, clusters.IND) {
    
    clusters.found = unique(clusters.IND)
    centroid.list  = numeric()
    
    for(j in 1:length(clusters.found)){
        
        c   = clusters.found[j]
        memb = which(clusters.IND == c)
        
        # Find medoid (shortes distance to other cluster members)
        centroid = colMeans(dataframe[memb,])
        
        # Save centroid
        if(j == 1){
            centroid.list = centroid 
            
        } else {
            centroid.list = rbind(centroid.list, centroid)}
    }    
    
    rownames(centroid.list)  = clusters.found
    return(centroid.list)
}

# Function to find medoid in clusters i
clust.medoid = function(distancematrix, clusters.IND) {
    
    clusters.found = sort(unique(clusters.IND))
    cluster.list   = list()
    
    for(j in 1:length(clusters.found)){
        
        c   = clusters.found[j]
        memb = which(clusters.IND == c)
        
        # Find medoid (shortes distance to other cluster members)
        cluster.list[[j]] = names(which.min(rowSums(distancematrix[memb, memb])))
        
    }    
    
    unlist(cluster.list)
    
}
