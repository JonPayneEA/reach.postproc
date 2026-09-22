# Internal validation and numerical helpers.

.stop_bad <- function(message) stop(message, call. = FALSE)

.assert_numeric_vector <- function(x, name, min_length = 1L, finite = TRUE) {
  if (!is.numeric(x) || length(x) < min_length || anyNA(x)) {
    .stop_bad(sprintf("`%s` must be a non-missing numeric vector.", name))
  }
  if (finite && any(!is.finite(x))) {
    .stop_bad(sprintf("`%s` must contain only finite values.", name))
  }
  invisible(x)
}

.assert_whole_number <- function(x, name, minimum = 0L) {
  if (length(x) != 1L || !is.numeric(x) || is.na(x) ||
      !is.finite(x) || x < minimum || x != as.integer(x)) {
    .stop_bad(sprintf("`%s` must be one whole number not less than %s.", name, minimum))
  }
  invisible(as.integer(x))
}

.multiply_polynomials <- function(first, second) {
  result <- complex(length = length(first) + length(second) - 1L)
  for (i in seq_along(first)) {
    for (j in seq_along(second)) {
      result[[i + j - 1L]] <- result[[i + j - 1L]] + first[[i]] * second[[j]]
    }
  }
  result
}

.as_dt_copy <- function(x) {
  if (!data.table::is.data.table(x)) x <- data.table::as.data.table(x)
  data.table::copy(x)
}

.format_number <- function(x, digits = 6L) {
  format(x, digits = digits, trim = TRUE, scientific = FALSE)
}
