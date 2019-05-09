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

#' Expand annotation
#' 
#' Internal function
#'
#' @param gene_id Character
#' @param terms Character string of comma-separated terms for the
#' `gene_id`.
#'
#' @return A tibble with one row per term
#' 
#' @importFrom magrittr %>%
expand_annot <- function(gene_id, terms){
  terms <- stringr::str_split(string = terms, pattern = ",") %>%
    unlist %>%
    stringr::str_replace("^ +", "") %>%
    stringr::str_replace(" +$", "")
  tibble::tibble(gene_id = gene_id,
                 term = terms)
}

#' Convert annotation table to gene or annotation list for topGO
#' 
#' Takes a data frame or tibble that maps genes to annotations,
#' and creates either a list of genes or a list of annotation terms
#' that can be ussed with \link[topGO]{annFUN.gene2GO} or
#' \link[topGO]{annFUN.GO2genes}.
#'
#' @param annots A tibble or data frame that has columns 'gene_id' and
#' 'annots'. Column 'annots' must be a comma-separated charachter string
#' with all the terms that annotate a given 'gene_id'.
#' @param direction Either "geneID2GO" or "GO2geneID". Direction of the
#' list that is produced.
#'
#' @return A named list. If `direction = "geneID2GO"`, then the list has
#' one element per 'gene_id' (named after that gene), and each element
#' of the list is a character vector with all the terms that annotate that
#' gene. If `direction = "GO2geneID"`, the the list has one element per
#' annotation term in 'annots' (named after that term), and each element
#' of the list is a character vector with all the genes annotated with
#' that term.
#' 
#' @export
#' @importFrom magrittr %>%
#'
#' @examples
#' d <- tibble::tibble(gene_id = c('gene1', 'gene2', 'gene3'),
#'                     terms = c(NA, 'term1,term2', 'term2, term3'))
#' annots_to_geneGO(d, direction = "geneID2GO")
#' annots_to_geneGO(d, direction = "GO2geneID")
annots_to_geneGO <- function(annots, direction = "geneID2GO"){
  if(!all(c("gene_id", "terms") %in% colnames(annots))){
    stop("ERROR: missing columns in annots")
  }
  
  if(direction == "geneID2GO"){
    annots <- annots %>%
      purrr::pmap_dfr(expand_annot) %>%
      dplyr::filter(!is.na(term)) %>%
      split(.$gene_id) %>%
      purrr::map(~ .x$term)
    
  }else if(direction == "GO2geneID"){
    annots <- annots %>%
      purrr::pmap_dfr(expand_annot) %>%
      dplyr::filter(!is.na(term)) %>%
      split(.$term) %>%
      purrr::map(~ .x$gene_id)
  }else{
    stop("ERROR: direction must be geneID2GO or GO2geneID", call. = TRUE)
  }
  
  return(annots)
}

#' gene selection function
#' 
#' Internal
#'
#' @param thres score threshold to select function
#'
#' @return A function
gene_sel_fun <- function(thres){
  function(x) x < thres
}

#' Gene Ontology enrichment via topGO
#' 
#' Performs Gene Ontology (GO) enrichment analysis via
#' topGO
#'
#' @param genes Either a character vector with the gene
#' identifiers that are 'significant' or a named numeric vector
#' where the vector names are the gene_identifiers of the universe
#' of genes and the numeric values the genes' scores.
#' @param annots Either a data.frame or tibble that has 'gene_id' and
#' 'terms' column or the result of running \link{annots_to_geneGO} on
#' such table.
#' @param ontology Which ontology to test. See help at \link[topGO]{topGOdata-class}.
#' @param description Description for the test. See help at \link[topGO]{topGOdata-class}.
#' @param algorithm Algortithm for test. See help at \link[topGO]{runTest}.
#' @param statistic Statistic to test. See help at \link[topGO]{runTest}.
#' @param node_size Minimum number of genes per term to test that
#' term. See help at \link[topGO]{topGOdata-class}
#' @param ... Other arguments to specific methods
#'
#' @return A list with elements topgo_data and topgo_res of class
#' topGOdata and topGOresult respecitveley
#' 
#' @export
#' @importClassesFrom topGO topGOdata
test_go <- function(genes, annots,
                    ontology,
                    description, algorithm, statistic,
                    node_size, ...) UseMethod("test_go")


#' @rdname test_go
#' @method test_go character
#' @export
test_go.character <- function(genes, annots,
                              ontology = "BP",
                              description = '',
                              algorithm = 'classic',
                              statistic = 'fisher',
                              node_size = 3, ...){
  
  # Get annotations as gene -> GO list
  if(is.data.frame(annots)){
    annots <- annots_to_geneGO(annots = annots, direction = "geneID2GO")
  }else if(!is.list(annots)){
    stop("ERROR: annots must be either a data.frame or a list.", call. = TRUE)
  }

  # Convert list of significant genes into scores
  gene_scores <- -1*(names(annots) %in% genes)
  names(gene_scores) <- names(annots)

  res <- test_go(genes = gene_scores, annots = annots,
                 ontology = ontology, description = description,
                 algorithm = algorithm, statistic = statistic, node_size = node_size,
                 score_threshold = 0)

  return(res)
  
}

#' @rdname test_go
#' @method test_go numeric
#' @export
#' 
#' @param score_threshold If genes is a numeric vector, then
#' this should be the 'significance' threshold. E.g. if scores are p-values
#' a common threshold would be 0.05.
test_go.numeric <- function(genes, annots,
                            ontology = "BP",
                            description = '',
                            algorithm = 'classic',
                            statistic = 'fisher',
                            node_size = 3,
                            score_threshold = 0.05, ...){
  
  # Get annotations as gene -> GO list
  if(is.data.frame(annots)){
    annots <- annots_to_geneGO(annots = annots, direction = "geneID2GO")
  }else if(!is.list(annots)){
    stop("ERROR: annots must be either a data.frame or a list.", call. = TRUE)
  }

  topGO::groupGOTerms()
  
  # Create topGO data
  go_data <- new("topGOdata",
                 description = description,
                 ontology = ontology,
                 allGenes = genes,
                 geneSelectionFun = gene_sel_fun(score_threshold),
                 nodeSize = node_size,
                 annot = topGO::annFUN.gene2GO,
                 gene2GO = annots)
  
  # perform topGO test
  go_res <- topGO::runTest(go_data,
                           algorithm = algorithm,
                           statistic = statistic)
  
  return(list(topgo_data = go_data, topgo_res = go_res))
}

#' Gene-set Enrichment analysis on one term.
#' 
#' Performs gene-set enrichment analysis on a group of genes.
#' Tests whether the scores among selected genes differ from
#' the overall score dsitribution.
#' 
#' The function currently doesn't check whether some genes in `genes`
#' are missing from `scores`. It will simply ignore those and test among
#' the `genes` found in scores.
#'
#' @param genes Character vector of gene IDs that belong to
#' a group to test.
#' @param scores Named numeric vector of gene scores to be tested.
#' The 'names' attribute must correspond to the values in `genes`.
#' @param test Which test to perform. Either 'wilcoxon' or 'ks'
#' for Wilcoxon Rank Sum and Kolmogorov-Smirnov tests repsectiveley.
#' Test use R's base \link{wilcox.test} and \link{ks.test} respectiveley.
#' @param alternative The alternative hypothesis to test. Either 'greater',
#' 'less' or 'two.sided'. It  corresponds to option 'alternative' in
#' \link{wilcox.test} or \link{ks.test}. Typically, if scores are p-values
#' one wishes to #' test the hypothesis that p-values within 'genes' are 'less'
#' than expected; while if scores are some other type of value (like
#' fold-change abundance) one is trying to test that those values are
#' 'greater'. Keep in mind that the Kolmogorov-Smirnov test is a test of the
#' maximum difference in cumulative distribution values. Therefore, an
#' alternative 'greater' in this case correspons to cases where
#' score is stochastially smaller than the rest. 
#' @param min_size The minimum number of genes in the group for the test
#' to be performed. Basically if the number of genes that appear in
#' 'scores' is less than 'min_size', the test won't be performed.
#'
#' @return If the test is not performed it returns NULL. If the test
#' is performed it returns a tibble with elements: size (the number 
#' of elements in both 'genes' and 'scores'), statistic (the statistic
#' calculated, depends on the test), and p.value (the p-value of the test).
#' 
#' @export
#'
#' @examples
# Create some fake scores
#' set.seed(123)
#' scores <- rnorm(n = 100)
#' names(scores) <- paste('gene', 1:100, sep = "")
#' 
#' # Select some genes and increase their scores
#' genes <- names(scores)[1:10]
#' scores[genes] <- scores[genes] + rnorm(10, mean = 1)
#' 
#' # Test
#' term_gsea(genes, scores)
#' term_gsea(genes, scores, test = 'ks', alternative = 'less')
term_gsea <- function(genes, scores, test = "wilcoxon", alternative = "greater", min_size = 3){
  
  if(!is.character(genes)){
    stop("ERROR: genes must be a character vector", call. = TRUE)
  }
  if(!is.numeric(scores) || is.null(attr(scores, "names"))){
    stop("ERROR: scores must be a named numeric vector", call. = TRUE)
  }
  
  ii <- names(scores) %in% genes
  
  if(sum(ii) < min_size){
    return(tibble::tibble(size = sum(ii), statistic = NA, p.value = NA))
  }
  
  if(test == 'wilcoxon'){
    res <- wilcox.test(scores[ii], scores[!ii], alternative = alternative)
  }else if(test == 'ks'){
    res <- ks.test(scores[ii], scores[!ii], alternative = alternative)
  }else{
    stop("ERROR: Invalid test", call. = TRUE)
  }
  
  tibble::tibble(size = sum(ii), statistic = res$statistic, p.value = res$p.value)
}

#' Gene-set enrichment analysis
#' 
#' Performs Gene-set enrichment analysis on all annotation terms
#' for a set of genes.
#'
#' @param dat A data.frame or tibble. It must contain one row per gene
#' and columns 'gene_id', 'terms', and 'score'. Column 'terms' must be
#' of type character and each entry must be a comma-separated character
#' string of all the terms that annotate the corresponding gene.
#' @param test Which test to perform. Either 'wilcoxon' or 'ks'
#' for Wilcoxon Rank Sum and Kolmogorov-Smirnov tests repsectiveley.
#' Test use R's base \link{wilcox.test} and \link{ks.test} respectiveley.
#' @param alternative The alternative hypothesis to test. Either 'greater',
#' 'less' or 'two.sided'. It  corresponds to option 'alternative' in
#' \link{wilcox.test} or \link{ks.test}. Typically, if scores are p-values
#' one wishes to #' test the hypothesis that p-values within 'genes' are 'less'
#' than expected; while if scores are some other type of value (like
#' fold-change abundance) one is trying to test that those values are
#' 'greater'. Keep in mind that the Kolmogorov-Smirnov test is a test of the
#' maximum difference in cumulative distribution values. Therefore, an
#' alternative 'greater' in this case correspons to cases where
#' score is stochastially smaller than the rest. 
#' @param min_size The minimum number of genes in the group for the test
#' to be performed. Basically if the number of genes that appear in
#' 'scores' is less than 'min_size', the test won't be performed.
#'
#' @return A tibble with elements: term (the annotation term ID), size (the number 
#' of elements in both 'genes' and 'scores'), statistic (the statistic
#' calculated, depends on the test), and p.value (the p-value of the test). The
#' tibble is sorted by increasing p-value.
#' 
#' @export
#' @importFrom magrittr %>%
#'
#' @examples
#' # Make some fake data
#' dat <- tibble::tibble(gene_id = paste('gene', 1:10, sep = ''),
#'                       terms = c('term1,term2,term3',
#'                                 NA,
#'                                 'term2,term3,term4',
#'                                 'term3',
#'                                 'term4,term5',
#'                                 'term6',
#'                                 'term6',
#'                                 'term6,term2',
#'                                 'term6,term7',
#'                                 'term6,term2'),
#'                       score = 1:10)
#' dat
#' 
#' # Test
#' gsea(dat, min_size = 2)
#' gsea(dat, min_size = 3, test = 'ks', alternative = 'less')
gsea <- function(dat, test = 'wilcoxon', alternative = 'greater', min_size = 3){
  if(!all(c('gene_id', 'terms', 'score') %in% colnames(dat))){
    stop("ERROR: missing columns", call. = TRUE)
  }
  
  scores <- dat$score
  names(scores) <- dat$gene_id
  dat <- dat %>% dplyr::select(-score)
  
  # Expand annotations
  dat <- dat %>%
    purrr::pmap_dfr(expand_annot) %>%
    dplyr::filter(!is.na(term))
  
  # Clean background
  scores <- scores[ names(scores) %in% unique(dat$gene_id) ]
  
  # Test
  dat <- dat %>%
    split(.$term) %>%
    purrr::map(~ .x$gene_id) %>%
    purrr::map_dfr(term_gsea, scores = scores,
                   test = test,
                   alternative = alternative,
                   min_size = min_size,
                   .id = "term") %>%
    filter(!is.na(statistic)) %>%
    dplyr::arrange(p.value)
  
  return(dat)
}

