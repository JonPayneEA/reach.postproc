# Package documentation and imports ------------------------------------------

#' reach.postproc: post-processing for flood forecasts
#'
#' Provides S7 classes and data.table-based functions for autoregressive and
#' autoregressive moving-average flood-forecast post-processing.
#'
#' Data import belongs to `reach.io`. Rating conversion belongs to
#' `reach.rate`. This package aligns prepared series, applies post-processing,
#' assesses parameter behaviour and scores fixed lead-time performance.
#'
#' @keywords internal
#' @import data.table
"_PACKAGE"

# Tell data.table that expressions evaluated from this package deliberately use
# data.table syntax. The NAMESPACE import above is the primary mechanism; this
# flag also protects development workflows that source files before rebuilding
# the namespace.
.datatable.aware <- TRUE
