# ============================================================ #
# Tool:         Global Variable Declarations
# Description:  Declares data.table and ggplot2 NSE symbols to R CMD check
#               to prevent false "no visible binding" notes.
# Flode Module: reach.hydro (pre-promotion; standalone package)
# Author:       Jonathan Payne, jonathan.payne@example.org
# Created:      2026-09-24
# Modified:     2026-10-02 - JP: added mandatory governance header block
# Tier:         2
# Inputs:       None.
# Outputs:      None (package-level side effect only).
# Dependencies: utils.
# ============================================================ #

# Package-level declarations for data.table and ggplot2 evaluation
#' @importFrom utils globalVariables
NULL

globalVariables(c(
  ".", "arma_error", "component", "contribution_real", "date_time",
  "lead_time_hours", "lead_time_minutes", "modal_stability", "observed",
  "plot_imaginary", "plot_real", "response", "root_imaginary", "root_real",
  "series", "simulated", "stability", "step", "updated", "value"
))
