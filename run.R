#!/usr/local/bin/Rscript

task <- dyncli::main()

# load libraries
library(dyncli, warn.conflicts = FALSE)
library(dynwrap, warn.conflicts = FALSE)
library(dplyr, warn.conflicts = FALSE)
library(purrr, warn.conflicts = FALSE)

library(cellTree, warn.conflicts = FALSE)

#####################################
###           LOAD DATA           ###
#####################################
expression <- task$expression
parameters <- task$parameters
priors <- task$priors

start_cell <-
  if (!is.null(priors$start_id)) {
    sample(priors$start_id, 1)
  } else {
    NULL
  }

if (parameters$rooting_method == "null") {
  parameters$rooting_method <- NULL
}

# TIMING: done with preproc
timings <- list(method_afterpreproc = Sys.time())

#####################################
###        INFER TRAJECTORY       ###
#####################################

# infer the LDA model
lda_out <- cellTree::compute.lda(
  Matrix::t(expression) + min(expression) + 1,
  k.topics = parameters$num_topics,
  method = parameters$method,
  log.scale = FALSE,
  sd.filter = parameters$sd_filter,
  tot.iter = parameters$tot_iter,
  tol = parameters$tolerance
)

# check whether there is prior information available
start.group.label <- NULL
grouping <- NULL

if (!is.null(priors$groups_id)) {
  grouping <-
    priors$groups_id %>%
    dplyr::slice(match(cell_id, rownames(expression))) %>%
    pull(group_id)
  if (!is.null(priors$start_id)) {
    start.group.label <-
      priors$groups_id %>% 
      filter(cell_id == priors$start_id) %>%
      pull(group_id)
  }
}

# construct the backbone tree
mst_tree <- cellTree::compute.backbone.tree(
  lda.results = lda_out,
  grouping = grouping,
  start.group.label = start.group.label,
  absolute.width = parameters$absolute_width,
  width.scale.factor = parameters$width_scale_factor,
  outlier.tolerance.factor = parameters$outlier_tolerance_factor,
  rooting.method = parameters$rooting_method,
  only.mst = FALSE,
  merge.sequential.backbone = FALSE
)

# TIMING: done with trajectory inference
timings$method_aftermethod <- Sys.time()

# simplify sample graph to just its backbone
cell_graph <-
  igraph::as_data_frame(mst_tree, "edges") %>%
  dplyr::select(from, to, length = weight) %>%
  mutate(
    from = rownames(expression)[from],
    to = rownames(expression)[to],
    directed = FALSE
  )
to_keep <-
 igraph::V(mst_tree)$is.backbone %>%
  setNames(rownames(expression))

#####################################
###     SAVE OUTPUT TRAJECTORY    ###
#####################################
output <-
  wrap_data(
    cell_ids = rownames(expression)
  ) %>%
  add_cell_graph(
    cell_graph = cell_graph,
    to_keep = to_keep
  )  %>%
  add_timings(
    timings = timings
  )

dyncli::write_output(output, task$output)
