stop_bad_argument <- function(message) stop(message, call. = FALSE)
validate_numeric <- function(x, name, n = 1L, finite = TRUE) {
  if (!is.numeric(x) || length(x) < n || anyNA(x) || (finite && any(!is.finite(x))))
    stop_bad_argument(sprintf("`%s` must be a valid numeric vector.", name))
  invisible(x)
}
validate_whole <- function(x, name, minimum = 0L) {
  if (length(x)!=1L || !is.numeric(x) || is.na(x) || !is.finite(x) || x<minimum || x!=as.integer(x))
    stop_bad_argument(sprintf("`%s` must be a whole number not below %d.",name,minimum))
  as.integer(x)
}
as_dt_copy <- function(x) data.table::copy(data.table::as.data.table(x))
format_hours <- function(steps, minutes) steps * minutes / 60
multiply_polynomials_ascending <- function(first, second) {
  result <- complex(length.out = length(first) + length(second) - 1L)
  for (i in seq_along(first)) for (j in seq_along(second))
    result[[i+j-1L]] <- result[[i+j-1L]] + first[[i]] * second[[j]]
  result
}
