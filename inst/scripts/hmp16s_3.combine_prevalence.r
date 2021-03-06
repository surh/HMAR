
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

setwd("~/micropopgen/exp/2018/today3/")


files <- c("../today/hmmcp.v13.hq.otu.fullprev.txt",
           "../today/hmmcp.v35.hq.otu.fullprev.txt",
           "../today2/hmqcp.v13.otu.fullprev.txt",
           "../today2/hmqcp.v35.otu.fullprev.txt")

Prev <- NULL
for(i in 1:length(files)){
  # i <- 1
  # i <- 3
  
  prev <- read.table(files[i], sep = "\t", header = TRUE)
  cat(files[i], "\n")
  # head(prev)
  
  prev$Rank <- NA
  for(g in levels(prev$Group)){
    # g <- levels(prev$Group)[1]
    cat("\n", g, "\n")
    
    prev$Rank[ prev$Group == g ] <- rank(-prev$Proportion[ prev$Group == g ])
  }
  
  # Shorten name
  prev$Taxon <- sapply(strsplit(as.character(prev$Taxon), ";"),
                       function(x) paste(x[length(x) - 1], x[length(x)], sep = ";"))
  prev$Taxon <- gsub(pattern = "[gf]__", replacement = "", x = prev$Taxon)
  # prev$Taxon <- sub(pattern = "g__", replacement = "", x = prev$Taxon)
  # head(prev)
  
  # Set method
  prev$Method <- sub(pattern = ".fullprev.txt",
                     replacement = "",
                     x = basename(files[i]))
  # head(prev)
  
  Prev <- rbind(Prev, prev)
}

# Count average rank
head(Prev)
Prev <- subset(Prev, !(Taxon %in% c("unclassified;unclassified", ";", ";unclassified")))

# Check that each fam;genus appears only once per group
counts <- aggregate(Rank ~ Taxon + Group + Method, data = Prev,FUN = length )
head(counts)
counts[ counts$Rank > 1, ]

# Count
counts <- aggregate(Rank ~ Taxon + Group, data = Prev,FUN = length )
head(counts)
ranks <- aggregate(Rank ~ Taxon + Group, data = Prev, FUN = sum )
head(ranks)
prop <- aggregate(Proportion ~ Taxon + Group, data = Prev, FUN = median )
head(prop)

# Combine and keep only detected by all methods
dat <- ranks
dat$Count <- counts$Rank
dat$Proportion <- prop$Proportion
head(dat)
dat <- subset(dat, Count == 4)
head(dat)
dat <- dat[ order(dat$Group, dat$Rank, decreasing = FALSE), ]
subset(dat, Rank < 60)


subset(dat, Taxon == "Pseudomonadaceae;Pseudomonas")
subset(dat, Taxon == "Staphylococcaceae;Staphylococcus")
subset(dat, Taxon == "Bacillaceae;Bacillus")


subset(dat, Proportion > 0.75)
