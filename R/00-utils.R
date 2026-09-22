# Internal validation and numerical helpers ----------------------------------

stop_bad_argument <- function(message) {
  stop(message, call. = FALSE)
}

validate_numeric_vector <- function(
    x,
    argument,
    minimum_length = 1L,
    allow_infinite = FALSE
) {
  is_invalid <- !is.numeric(x) ||
    length(x) < minimum_length ||
    anyNA(x)

  if (is_invalid) {
    stop_bad_argument(
      sprintf(
        "`%s` must be a non-missing numeric vector.",
        argument
      )
    )
  }

  if (!allow_infinite && any(!is.finite(x))) {
    stop_bad_argument(
      sprintf(
        "`%s` must contain only finite values.",
        argument
      )
    )
  }

  invisible(x)
}

validate_non_negative_scalar <- function(x, argument) {
  is_invalid <- length(x) != 1L ||
    !is.numeric(x) ||
    is.na(x) ||
    !is.finite(x) ||
    x < 0

  if (is_invalid) {
    stop_bad_argument(
      sprintf(
        "`%s` must be one non-negative finite number.",
        argument
      )
    )
  }

  invisible(x)
}

validate_positive_scalar <- function(x, argument) {
  validate_non_negative_scalar(x, argument)

  if (x == 0) {
    stop_bad_argument(
      sprintf(
        "`%s` must be greater than zero.",
        argument
      )
    )
  }

  invisible(x)
}

validate_whole_number <- function(
    x,
    argument,
    minimum = 0L
) {
  is_invalid <- length(x) != 1L ||
    !is.numeric(x) ||
    is.na(x) ||
    !is.finite(x) ||
    x < minimum ||
    x != as.integer(x)

  if (is_invalid) {
    stop_bad_argument(
      sprintf(
        "`%s` must be one whole number not less than %s.",
        argument,
        minimum
      )
    )
  }

  as.integer(x)
}

as_data_table_copy <- function(x) {
  data.table::copy(
    data.table::as.data.table(x)
  )
}

multiply_polynomials <- function(first, second) {
  result <- complex(
    length = length(first) + length(second) - 1L
  )

  for (first_index in seq_along(first)) {
    for (second_index in seq_along(second)) {
      result_index <- first_index + second_index - 1L

      result[[result_index]] <- result[[result_index]] +
        first[[first_index]] * second[[second_index]]
    }
  }

  result
}
