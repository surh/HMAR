library(tidyverse)
library(AMOR)

args <- list(abun = "hmp_qin2012_relative.abundance.txt",
             map = "hmp.subsite_map.txt",
             genomes = "../2019-03-27.hmp_samples_per_species_per_site/hmp.subsite_Buccal.mucosa_genomes.txt",
             outdir = "output/")

# Read abund and map
map <- read_tsv(args$map, col_types = cols(.default = col_character()))
map <- as.data.frame(map)
row.names(map) <- map$ID
tab <- read.am(args$abun, format = "am", simplify = TRUE)

# Crate dataset
if(!all(map$ID %in% colnames(tab))){
  stop("ERROR: missing samples")
}
tab <- tab[ , map$ID ] 
Dat <- create_dataset(Tab = tab, Map = map)
rm(map, tab)
gc()
Dat <- clean(Dat)
Dat

# Read genome list
genomes <- read_tsv(args$genomes, col_names = FALSE, col_types = 'c') %>% unlist
genomes

# Calculate means and medians
means <- remove_taxons(Dat, setdiff(taxa(Dat), genomes)) %>%
  pool_samples(groups = "Group", FUN = mean) %>%
  as.data.frame()
medians <- remove_taxons(Dat, setdiff(taxa(Dat), genomes)) %>%
  pool_samples(groups = "Group", FUN = median)

means <- means %>% as.data.frame %>%
  mutate(spec = row.names(means)) %>% as_tibble()
medians <- medians %>% as.data.frame %>%
  mutate(spec = row.names(medians)) %>% as_tibble()

Freqs <- means %>%
  full_join(medians, by = "spec", suffix = c(".mean", ".median")) %>%
  dplyr::select(spec, everything())
Freqs
filename <- paste0(c("summary_abundances.txt"), collapse = ".")
filename <- file.path(args$outdir, filename)
write_tsv(Freqs, filename)


# Plot
g <- genomes[1]
cat(g, "\n")

if(g %in% taxa(Dat)){
  p1 <- plotgg_taxon(Dat, taxon = g, x = "Group", col = "Group") +
    ggtitle(label = g) +
    scale_y_sqrt() +
    theme(axis.text.x = element_blank())
  p1 
  filename <- paste0(c(g, "abundances.png"), collapse = ".")
  filename <- file.path(args$outdir, filename)
  ggsave(filename, p1, width = 6, height = 5, dpi = 200)
}


















