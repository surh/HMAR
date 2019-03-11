library(HMVAR)
library(tidyverse)

# Eventually replace this with argparse
args <- list(midas_dir = "midas_output_small/",
             map_file = "map.txt",
             outdir = "benchmark_imputation",
             prefix = "test",
             # gemma = "~/bin/gemma.0.93b",
             bimbam = "~/bin/bimbam",
             # gemma_version = 'bugwas',
             # pcs = "pcs.txt",
             # pval_thres = 1e-6,
             focal_group = "Supragingival.plaque",
             hidden_proportion = 0.1)

# Main output directory
dir.create(args$outdir)

# Create list for filenames
Files <- list(Dirs = list(),
              Files = list())

### Read and process original data
# Read map
map <- read_tsv(args$map_file, col_types = 'cc')
map <- map %>% select(sample = ID, Group = Group)

# Convert to bimbam
Files$Dirs$bimbam_dir <- file.path(args$outdir, "original")
midas_bimbam <- midas_to_bimbam(midas_dir = args$midas_dir,
                                map = map,
                                outdir = Files$Dirs$bimbam_dir,
                                focal_group = args$focal_group,
                                prefix = NULL)
Files$Files$midas_geno_file <- midas_bimbam$filenames$geno_file
Files$Files$pheno_file <- midas_bimbam$filenames$pheno_file
Files$Files$snp_file <- midas_bimbam$filenames$snp_file
rm(map)

### Hide 10% of data
Files$Dirs$data_hidden_dir <- file.path(args$outdir, "data_hidden_geno_files/")
dir.create(Files$Dirs$data_hidden_dir)
set.seed(12345)
# midas_bimbam$Dat$geno

gen_only <- midas_bimbam$Dat$geno %>% select(-site_id, -minor_allele, -major_allele) %>% as.matrix
gen_only_mask <- which(!is.na(gen_only))
hidden_index <- sample(gen_only_mask,
                       size = round(length(gen_only_mask) * args$hidden_proportion,
                                    digits = 0), replace = FALSE)
batch_name <- "batch0"
res <- tibble(batch = batch_name, gen = gen_only[hidden_index])

# sum(!is.na(gen_only))
gen_only[hidden_index] <- NA
# sum(!is.na(gen_only))
gen_only <- cbind(midas_bimbam$Dat$geno %>% select(site_id, minor_allele, major_allele), gen_only) %>% as_tibble
# gen_only
# Write batch with hidden data
hidden_gen_file <- file.path(Files$Dirs$data_hidden_dir, paste(c(batch_name, 'geno.bimbam'), collapse = "_"))
write_tsv(gen_only, path = hidden_gen_file, col_names = FALSE)

# Impute batch
Files$Dirs$imputed_dir <- file.path(args$outdir, "imputed_from_hidden")
hidden_immputed_file <- bimbam_impute(geno_file = hidden_gen_file,
                                      pheno_file = midas_bimbam$filenames$pheno_file,
                                      pos_file = midas_bimbam$filenames$snp_file,
                                      bimbam = args$bimbam,
                                      outdir = Files$Dirs$imputed_dir,
                                      em_runs = 10,
                                      em_steps = 20,
                                      em_clusters = 15,
                                      prefix = batch_name)
# Load imputed and compare
hidden_imputed <- read_delim(hidden_immputed_file, col_names = FALSE, delim = " ",
                           col_types = cols(X1 = col_character(),
                                            X2 = col_character(),
                                            X3 = col_character(),
                                            .default = col_number()))
# hidden_imputed
# match(c('a','a', 'c'), letters[1:5] )
# midas_bimbam$Dat$geno
# Sorting
hidden_imputed <- hidden_imputed[ match(midas_bimbam$Dat$geno$site_id, hidden_imputed$X1 ), ] 
hidden_imputed <- hidden_imputed %>% select(-X1, -X2, -X3) %>% as.matrix
res <- res %>% bind_cols(imputed = hidden_imputed[hidden_index])

