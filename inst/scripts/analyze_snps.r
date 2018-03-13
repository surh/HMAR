library(AMOR)

indir <- "~/micropopgen/data/test_data/midas/merged.snps/"
map_file <- "~/micropopgen/data/test_data/midas/map.txt"

# get midas merge output dirs
dirs <- list.dirs(indir, recursive = FALSE)
dirs

Res <- NULL
for(dir in dirs){
  dir <- dirs[2]
  snp_freq_file <- paste(dir, "snps_freq.txt", sep = "/")
  snp_depth_file <- paste(dir, "snps_depth.txt", sep = "/")
  snp_info_file <- paste(dir, "snps_info.txt", sep = "/")
  
  # Read data
  Freq <- read.table(snp_freq_file,
                     header = TRUE, row.names = 1)
  Depth <- read.table(snp_depth_file,
                      header = TRUE, row.names = 1)
  Info <- read.table(snp_info_file,
                     header = TRUE, sep = "\t")
  row.names(Info) <- as.character(Info$site_id)
  
  # Read map
  Map <- read.table(map_file, sep = "\t", header = TRUE)
  row.names(Map) <- as.character(Map$ID)
  Map <- droplevels(Map[ colnames(Freq), ])
  
  # Create datasets
  Freq <- create_dataset(Freq, Map, Info)
  Depth <- create_dataset(Depth, Map, Info)
  
  # Get combinations
  combinations <- combn(levels(Map$Group),m = 2)
  
  for(i in 1:ncol(combinations)){
    sites <- combinations[,i]
    
    # Select comparison
    Freq.s <- subset(Freq, Group %in% c("Supragingival plaque", "Buccal mucosa"),
                   drop = TRUE)
    Depth.s <- subset(Depth, Group %in% c("Supragingival plaque", "Buccal mucosa"),
                    drop = TRUE)
    
    # Clean
    Depth.s <- clean(Depth.s)
    Freq.s <- remove_samples(Freq.s, samples = setdiff(samples(Freq.s), samples(Depth.s)))
    Freq.s <- remove_taxons(Freq.s, taxons = setdiff(taxa(Freq.s), taxa(Depth.s)))
    
    # PCA
    Dat.pca <- PCA(Freq.s)
    p1 <- plotgg(Dat.pca, col = "Group")
    # p1
    filename <- paste(basename(dir),
                      "_",
                      gsub(pattern = " ", replacement = ".",
                           paste(combinations[,1], collapse = "_")),
                      "_snps.pca.svg", sep = "")
    ggsave(filename, p1, width = 5, height = 5)
    
    m1 <- lm(PC1 ~ Group, data = p1$data)
  }
}





# Res <- NULL
# for(gene in levels(Info$gene_id)){
#   # gene <- levels(Info$gene_id)[1]
# 
#   # Res <- rbind(Res, data.frame(gene = gene, D = 0, P = 0))
#   snps <- taxa(Dat)[ Dat$Tax$gene_id == gene & !is.na(Dat$Tax$gene_id == gene) ]
#   to_remove <- setdiff(taxa(Dat), snps)
#   
#   Dat.sub <- remove_taxons(Dat, taxons = to_remove)
#   Dat2.sub <- remove_taxons(Dat2, taxons = to_remove)
#   Dat2.sub <- clean(Dat2.sub)
#   
#   Dat.sub <- remove_samples(Dat.sub, samples = setdiff(samples(Dat.sub), samples(Dat2.sub)))
#   
#   Dat.sub <- subset(Dat.sub, Group %in% c("Supragingival plaque", "Buccal mucosa"), drop = TRUE)
#   Dat2.sub <- subset(Dat2.sub, Group %in% c("Supragingival plaque", "Buccal mucosa"), drop = TRUE)
#   
#   
#   Dat.pca <- PCA(Dat.sub)
#   p1 <- plotgg(Dat.pca, col = "Group")
#   # p1
#   # barplot(rowSums(Dat2.sub$Tab > 0))
#   # 
#   
#   for(i in 1:length(taxa(Dat.sub))){
#     depth <- Dat2.sub$Tab[i,]
#     freq <- Dat.sub$Tab[i,]
#     groups <- Dat.sub$Map$Group
#     
#     freq <- freq[ depth > 0 ]
#     groups <- groups[ depth > 0 ]
#     
#     # all(names(depth) == names(freq))
#     # (depth > 0) * (groups == "Buccal mucosa")
#     
#     tab <- ftable(groups ~ factor(freq > 0.5))
#     
#     if(sum(diag(tab)) == 0 | sum(diag(tab )) == length(groups)){
#       # Res$P[ Res$gene == gene ] <- Res$P[ Res$gene == gene ] + 1
#       res <- data.frame(Site = taxa(Dat.sub)[i], nsamples = length(groups), DN = "D",
#                         major_allele = Dat.sub$Tax[i, "major_allele"],
#                         minor_allele = Dat.sub$Tax[i, "minor_allele"],
#                         aa = Dat.sub$Tax[i, "amino_acids"],
#                         gene_id = gene)
#     }else{
#       # Res$D[ Res$gene == gene ] <- Res$D[ Res$gene == gene ] + 1
#       res <- data.frame(Site = taxa(Dat.sub)[i], nsamples = length(groups), DN = "P",
#                         major_allele = Dat.sub$Tax[i, "major_allele"],
#                         minor_allele = Dat.sub$Tax[i, "minor_allele"],
#                         aa = Dat.sub$Tax[i, "amino_acids"],
#                         gene_id = gene)
#     }
#     Res <- rbind(Res,res)
#   }
# 
#   
#   
#   
# }

