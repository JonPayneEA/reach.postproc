# Parameter construction and conversion --------------------------------------

#' Detect the effective order of an autoregressive model
#'
#' Finds the final coefficient whose absolute value exceeds `tolerance`.
#' Trailing inactive coefficients are removed, but internal zeros are retained.
#'
#' @param coefficients Numeric AR coefficients ordered from `a_1` to `a_p`.
#' @param tolerance Non-negative tolerance used to identify inactive terms.
#'
#' @return A single integer. Returns zero when no coefficient is active.
#'
#' @examples
#' detect_ar_order(c(1.85, -0.85, 0))
#' detect_ar_order(c(1.2, 0, -0.2))
#'
#' @export
detect_ar_order <- function(
    coefficients,
    tolerance = 1e-8
) {
  validate_numeric_vector(
    x = coefficients,
    argument = "coefficients"
  )

  validate_non_negative_scalar(
    x = tolerance,
    argument = "tolerance"
  )

  active_indices <- which(
    abs(coefficients) > tolerance
  )

  if (length(active_indices) == 0L) {
    return(0L)
  }

  as.integer(
    max(active_indices)
  )
}

#' Detect the effective order of a moving-average model
#'
#' @inheritParams detect_ar_order
#'
#' @return A single integer. Returns zero for an empty or inactive vector.
#'
#' @export
detect_ma_order <- function(
    coefficients,
    tolerance = 1e-8
) {
  if (length(coefficients) == 0L) {
    return(0L)
  }

  detect_ar_order(
    coefficients = coefficients,
    tolerance = tolerance
  )
}

#' Convert AR coefficient sign convention
#'
#' @param coefficients Numeric AR coefficients.
#' @param from Sign convention currently used by `coefficients`.
#' @param to Required sign convention.
#'
#' @return Numeric coefficients in the requested convention.
#'
#' @export
convert_sign_convention <- function(
    coefficients,
    from = c("Deltares", "Standard"),
    to = c("Deltares", "Standard")
) {
  from <- match.arg(from)
  to <- match.arg(to)

  validate_numeric_vector(
    x = coefficients,
    argument = "coefficients"
  )

  if (identical(from, to)) {
    return(coefficients)
  }

  -coefficients
}

#' Construct an autoregressive parameter set
#'
#' Converts coefficients to the Deltares convention, detects effective model
#' order and returns a validated `ARParameterSet`.
#'
#' @param coefficients Numeric AR coefficients ordered from first to highest
#'   order. Alternatively, supply coefficients through `...`.
#' @param label Single character description.
#' @param sign_convention Convention used by supplied coefficients.
#' @param order_tolerance Tolerance used to remove inactive trailing terms.
#' @param ... Alternative coefficient input. Do not combine with
#'   `coefficients`.
#'
#' @return An `ARParameterSet` in the Deltares convention.
#'
#' @examples
#' ar_parameters(
#'   coefficients = c(1.765, -0.72625, -0.040656)
#' )
#'
#' ar_parameters(
#'   coefficients = c(-1.765, 0.72625, 0.040656),
#'   sign_convention = "Standard"
#' )
#'
#' @export
ar_parameters <- function(
    coefficients = NULL,
    label = "AR parameter set",
    sign_convention = c("Deltares", "Standard"),
    order_tolerance = 1e-8,
    ...
) {
  sign_convention <- match.arg(sign_convention)

  coefficients_from_dots <- unlist(
    list(...),
    recursive = TRUE,
    use.names = TRUE
  )

  if (
    !is.null(coefficients) &&
      length(coefficients_from_dots) > 0L
  ) {
    stop_bad_argument(
      paste0(
        "Supply AR coefficients through `coefficients` ",
        "or through `...`, not both."
      )
    )
  }

  coefficient_values <- if (is.null(coefficients)) {
    coefficients_from_dots
  } else {
    coefficients
  }

  validate_numeric_vector(
    x = coefficient_values,
    argument = "coefficients"
  )

  validate_non_negative_scalar(
    x = order_tolerance,
    argument = "order_tolerance"
  )

  # Convert once at construction. Downstream calculations can then use one
  # convention without repeated branches or ambiguous signs.
  coefficient_values <- convert_sign_convention(
    coefficients = coefficient_values,
    from = sign_convention,
    to = "Deltares"
  )

  model_order <- detect_ar_order(
    coefficients = coefficient_values,
    tolerance = order_tolerance
  )

  if (model_order == 0L) {
    stop_bad_argument(
      "At least one AR coefficient must exceed `order_tolerance`."
    )
  }

  coefficient_values <- coefficient_values[
    seq_len(model_order)
  ]

  names(coefficient_values) <- paste0(
    "a_",
    seq_along(coefficient_values)
  )

  ARParameterSet(
    coefficients = coefficient_values,
    order = as.integer(model_order),
    sign_convention = "Deltares",
    order_tolerance = as.numeric(order_tolerance),
    label = as.character(label)
  )
}

#' Return the 2024 EA default AR parameters
#'
#' @return An AR(3) `ARParameterSet`.
#'
#' @export
default_ar_parameters <- function() {
  ar_parameters(
    coefficients = c(
      a_1 = 1.765,
      a_2 = -0.72625,
      a_3 = -0.040656
    ),
    label = "2024 EA default"
  )
}

#' Construct a characteristic root from time scales
#'
#' Implements `z = exp(-1 / tau) * exp(2 * pi * i / T)`.
#'
#' @param decay_time Decay time in model steps. Negative values represent
#'   exponential growth.
#' @param oscillation_period Oscillation period in model steps. Use `Inf` for
#'   a positive real root and `2` for a negative real root.
#'
#' @return One complex characteristic root.
#'
#' @export
root_from_timescale <- function(
    decay_time,
    oscillation_period = Inf
) {
  if (
    length(decay_time) != 1L ||
      !is.numeric(decay_time) ||
      is.na(decay_time) ||
      decay_time == 0
  ) {
    stop_bad_argument(
      "`decay_time` must be one non-zero numeric value."
    )
  }

  if (
    length(oscillation_period) != 1L ||
      !is.numeric(oscillation_period) ||
      is.na(oscillation_period) ||
      oscillation_period < 2
  ) {
    stop_bad_argument(
      "`oscillation_period` must be at least 2 or `Inf`."
    )
  }

  magnitude <- exp(
    -1 / decay_time
  )

  if (is.infinite(oscillation_period)) {
    return(
      as.complex(magnitude)
    )
  }

  angle <- 2 * pi / oscillation_period

  magnitude * exp(
    1i * angle
  )
}

#' Convert characteristic roots to AR parameters
#'
#' Expands the polynomial whose roots are supplied and converts its
#' coefficients to the Deltares AR convention.
#'
#' @param root_values Numeric or complex characteristic roots.
#' @param label Description assigned to the result.
#' @param tolerance Maximum accepted residual imaginary component.
#'
#' @return An `ARParameterSet`.
#'
#' @export
roots_to_parameters <- function(
    root_values,
    label = "Derived from roots",
    tolerance = 1e-10
) {
  if (
    (!is.numeric(root_values) && !is.complex(root_values)) ||
      length(root_values) < 1L ||
      anyNA(root_values)
  ) {
    stop_bad_argument(
      "`root_values` must contain non-missing numeric or complex values."
    )
  }

  polynomial <- as.complex(1)

  for (root_value in root_values) {
    polynomial <- multiply_polynomials(
      first = polynomial,
      second = c(1, -root_value)
    )
  }

  coefficients <- -polynomial[-1L]

  if (any(abs(Im(coefficients)) > tolerance)) {
    stop_bad_argument(
      paste0(
        "The roots do not produce real AR parameters. ",
        "Supply complex roots as conjugate pairs."
      )
    )
  }

  roots_result <- Re(coefficients)
  names(roots_result) <- paste0(
    "a_",
    seq_along(roots_result)
  )

  ar_parameters(
    coefficients = roots_result,
    label = label,
    order_tolerance = tolerance
  )
}

#' Construct AR parameters from root time scales
#'
#' @param decay_times Numeric decay times in model steps.
#' @param oscillation_periods Numeric periods corresponding to
#'   `decay_times`.
#' @param label Description assigned to the result.
#' @param tolerance Numerical tolerance passed to `roots_to_parameters()`.
#'
#' @return An `ARParameterSet`.
#'
#' @export
ar_parameters_from_timescales <- function(
    decay_times,
    oscillation_periods = rep(Inf, length(decay_times)),
    label = "Derived from timescales",
    tolerance = 1e-10
) {
  validate_numeric_vector(
    x = decay_times,
    argument = "decay_times",
    allow_infinite = TRUE
  )

  validate_numeric_vector(
    x = oscillation_periods,
    argument = "oscillation_periods",
    allow_infinite = TRUE
  )

  if (length(decay_times) != length(oscillation_periods)) {
    stop_bad_argument(
      "`decay_times` and `oscillation_periods` must have equal lengths."
    )
  }

  root_values <- mapply(
    FUN = root_from_timescale,
    decay_time = decay_times,
    oscillation_period = oscillation_periods,
    SIMPLIFY = TRUE
  )

  roots_to_parameters(
    root_values = root_values,
    label = label,
    tolerance = tolerance
  )
}

#' Solve AR parameters from mixed root and coefficient constraints
#'
#' Solves unknown AR coefficients from known characteristic roots and any fixed
#' AR coefficients. The number of supplied roots must equal the number of
#' unknown coefficients.
#'
#' @param order Required AR order.
#' @param decay_times Decay times for known roots.
#' @param oscillation_periods Periods for known roots.
#' @param coefficients Numeric vector of length `order`; use `NA` for unknowns.
#' @param label Description assigned to the result.
#' @param tolerance Numerical tolerance for residual imaginary components.
#'
#' @return An `ARParameterSet`. A `solution_diagnostics` attribute reports
#'   matrix rank, condition number and residuals.
#'
#' @export
solve_ar_parameters <- function(
    order = 3L,
    decay_times,
    oscillation_periods,
    coefficients = rep(NA_real_, order),
    label = "Mixed-constraint solution",
    tolerance = 1e-10
) {
  order <- validate_whole_number(
    x = order,
    argument = "order",
    minimum = 1L
  )

  if (
    length(decay_times) != length(oscillation_periods) ||
      any(is.na(decay_times) != is.na(oscillation_periods))
  ) {
    stop_bad_argument(
      "The decay-time and period constraints are incompatible."
    )
  }

  if (!is.numeric(coefficients) || length(coefficients) != order) {
    stop_bad_argument(
      "`coefficients` must be a numeric vector with length equal to `order`."
    )
  }

  known_root_rows <- !is.na(decay_times)

  root_values <- mapply(
    FUN = root_from_timescale,
    decay_time = decay_times[known_root_rows],
    oscillation_period = oscillation_periods[known_root_rows],
    SIMPLIFY = TRUE
  )

  unknown_indices <- which(is.na(coefficients))
  known_indices <- which(!is.na(coefficients))

  if (length(root_values) != length(unknown_indices)) {
    stop_bad_argument(
      "The number of supplied roots must equal the number of unknown coefficients."
    )
  }

  # Each supplied root satisfies the characteristic equation. Columns of the
  # design matrix correspond to unknown coefficients.
  design_matrix <- vapply(
    X = unknown_indices,
    FUN = function(index) {
      root_values^(order - index)
    },
    FUN.VALUE = complex(length(root_values))
  )

  if (is.null(dim(design_matrix))) {
    design_matrix <- matrix(
      design_matrix,
      ncol = 1L
    )
  }

  right_hand_side <- root_values^order

  if (length(known_indices) > 0L) {
    known_terms <- vapply(
      X = known_indices,
      FUN = function(index) {
        coefficients[[index]] * root_values^(order - index)
      },
      FUN.VALUE = complex(length(root_values))
    )

    if (is.null(dim(known_terms))) {
      known_terms <- matrix(
        known_terms,
        ncol = 1L
      )
    }

    right_hand_side <- right_hand_side - rowSums(known_terms)
  }

  condition_number <- kappa(design_matrix)
  solution <- solve(design_matrix, right_hand_side)

  if (max(abs(Im(solution))) > tolerance) {
    stop_bad_argument(
      "The supplied constraints produce materially complex AR coefficients."
    )
  }

  coefficients[unknown_indices] <- Re(solution)

  if (condition_number > 1e12) {
    warning(
      "The mixed-constraint solution is ill-conditioned.",
      call. = FALSE
    )
  }

  result <- ar_parameters(
    coefficients = coefficients,
    label = label,
    order_tolerance = tolerance
  )

  attr(result, "solution_diagnostics") <- data.table::data.table(
    matrix_rank = qr(design_matrix)$rank,
    condition_number = condition_number,
    equation_residual = max(
      Mod(design_matrix %*% solution - right_hand_side)
    ),
    imaginary_residual = max(
      abs(Im(solution))
    )
  )

  result
}

#' Calculate observed-minus-simulated model errors
#'
#' @param observed Numeric observed values.
#' @param simulated Numeric simulated values of equal length.
#'
#' @return Numeric error values using `observed - simulated`.
#'
#' @export
calculate_model_error <- function(observed, simulated) {
  if (
    !is.numeric(observed) ||
      !is.numeric(simulated) ||
      length(observed) != length(simulated)
  ) {
    stop_bad_argument(
      "`observed` and `simulated` must be equally long numeric vectors."
    )
  }

  observed - simulated
}
