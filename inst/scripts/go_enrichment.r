# (C) Copyright 2019 Sur Herrera Paredes
# 
# This file is part of HMVAR.
# 
# HMVAR is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# HMVAR is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with HMVAR.  If not, see <http://www.gnu.org/licenses/>.

Sys.time()

# file <- "~/micropopgen/exp/2018/today/signifincant_mktest"
file <- "signifincant_mktest"
Tab <- read.table(file, header = TRUE, sep = "\t")
head(Tab)

go.dir <- "/home/sur/micropopgen/data/genomes/midas_db_v1.2/GO.annotations/"
# go.dir <- "/home/sur/micropopgen/exp/2018/today/GO.annotations/"

comparisons <- levels(interaction(Tab$A, Tab$B, sep = "_", drop = TRUE))

RES <- NULL
for(c in comparisons){
  # c <- comparisons[1]
  cat(c, "\n")
  
  # Get data from comparison
  dat <- droplevels(subset(Tab, A == strsplit(x = c, split = "_")[[1]][1] & B == strsplit(x = c, split = "_")[[1]][2]))
  specs <- levels(dat$Species)
  
  ANNOTS <- NULL
  for(s in specs){
    # s <- specs[1]
    cat("\t", s, "\n")
    
    go_file <- paste(go.dir, "/", s, ".GO.txt", sep = "")
    cat("\t", go_file, "\n")
    
    go <- read.table(go_file, header = TRUE)
    
    ANNOTS <- rbind(ANNOTS, go)
    rm(go)
  }
  
  bg_counts <- table(ANNOTS$Annotation)
  
  sig_annots <- droplevels(ANNOTS[ ANNOTS$Gene %in% levels(dat$gene), ])
  sig_counts <- table(sig_annots$Annotation)
  
  for(i in 1:length(sig_counts)){
    # i <- 1
    a <- names(sig_counts)[i]
    # cat("\t", a, "\n")
  
    q <- sig_counts[i]
    m <- bg_counts[a]
    n <- nrow(ANNOTS) - m
    k <- nrow(sig_annots)
    
    pval <- 1 - phyper(q = q - 1, m = m, n = n, k = k)
    
    res <- data.frame(comparison = c, annotation = a, nsig = q, nbg = m, pval = pval,
                      row.names = NULL)
    RES <- rbind(RES, res)
  }
}
write.table(RES, "GO_enrichment_by_comparsions.txt", sep = "\t", quote = FALSE,
            col.names = TRUE, row.names = FALSE)

Sys.time()

##### REPEAT by genome and comparison ###########

comparisons <- levels(interaction(Tab$A, Tab$B, Tab$Species, sep = "_", drop = TRUE))

RES <- NULL
for(c in comparisons){
  # c <- comparisons[1]
  cat(c, "\n")
  specs <- paste(strsplit(c, split = "_")[[1]][-(1:2)], collapse = "_")
  
  # Get data from comparison
  dat <- droplevels(subset(Tab, A == strsplit(x = c, split = "_")[[1]][1] & B == strsplit(x = c, split = "_")[[1]][2] & Species == specs))
  # specs <- levels(dat$Species)
  
  ANNOTS <- NULL
  for(s in specs){
    # s <- specs[1]
    cat("\t", s, "\n")
    
    go_file <- paste(go.dir, "/", s, ".GO.txt", sep = "")
    cat("\t", go_file, "\n")
    
    go <- read.table(go_file, header = TRUE)
    
    ANNOTS <- rbind(ANNOTS, go)
    rm(go)
  }
  
  bg_counts <- table(ANNOTS$Annotation)
  
  sig_annots <- droplevels(ANNOTS[ ANNOTS$Gene %in% levels(dat$gene), ])
  sig_counts <- table(sig_annots$Annotation)
  
  for(i in 1:length(sig_counts)){
    # i <- 1
    a <- names(sig_counts)[i]
    # cat("\t", a, "\n")
    
    q <- sig_counts[i]
    m <- bg_counts[a]
    n <- nrow(ANNOTS) - m
    k <- nrow(sig_annots)
    
    pval <- 1 - phyper(q = q - 1, m = m, n = n, k = k)
    
    res <- data.frame(comparison = c, annotation = a, nsig = q, nbg = m, pval = pval,
                      row.names = NULL)
    RES <- rbind(RES, res)
  }
}
write.table(RES, "GO_enrichment_by_comparison_and_species.txt", sep = "\t", quote = FALSE,
            col.names = TRUE, row.names = FALSE)



