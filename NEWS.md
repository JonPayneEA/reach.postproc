# reach.postproc 0.4.3

- Replaced all remaining calls to the removed prototype helper `.dt()` with `as_data_table_copy()`.
- Copied stored lead-time tables before scoring so scoring cannot modify the S7 object by reference.
- Audited the package source, tests and walkthrough for further `.dt()` references.

# reach.postproc 0.4.2

- Replaced bare data.table column lookup in `assess()` with explicit vector indexing.
- Replaced data.table non-standard evaluation in the assessment summary with explicit column access.
- This allows assessment methods to work reliably under `devtools::load_all()` and sourced development workflows.

# reach.postproc 0.4.1

- Added a package-level `@import data.table` directive and `.datatable.aware` flag.
- Replaced the failing root-table `:=` assignment with `data.table::set()`.
- Replaced unresolved local S7 documentation links with stable code references.
- Registered all S3 print methods through roxygen and NAMESPACE.

# reach.postproc 0.4.0

- Reformatted every R source file consistently.
- Expanded complex calculations into readable multi-line code.
- Added roxygen2 documentation to every exported class, generic and function.
- Added mathematical and design comments at the point of calculation.
- Fixed `ar_parameters()` argument capture by placing `...` last.
- Added `CODE_STYLE.md`.

# reach.postproc 0.3.1

- Reworked the walkthrough around the final `reach.io`, `reach.rate` and `reach.postproc` boundaries.
- Added explicit alignment diagnostic checks.
- Added detailed MAE, RMSE and bias scoring examples.
- Added recurrence-versus-root numerical diagnostics.
- Added threshold plotting and controlled output-export examples.
- Retained a fully reproducible synthetic workflow.

# reach.postproc 0.3.0

- Added strict observed/simulated alignment.
- Added fixed lead-time AR forecasts.
- Added independent root-projection verification.
- Added lead-time performance scores and plotting.
- Confirmed that import belongs to reach.io and ratings belong to reach.rate.

# reach.postproc 0.2.0

Implements all functionality from the previous ARMA analysis script within the S7 and data.table package design.
