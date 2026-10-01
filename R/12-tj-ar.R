#' Forecast a Time Jumped AR error series
#'
#' Estimate modal weights from non-consecutive historic errors separated by `jump`
#' timesteps, then project the characteristic-root solution forwards.
#' @param parameters An AR parameter set.
#' @param error_history Numeric error history supplied newest first. It must
#'   contain at least `1 + (order - 1) * jump` values.
#' @param jump Positive whole number of timesteps between selected errors. Use
#'   `1L` for conventional consecutive-error AR.
#' @param steps Positive whole number of projected timesteps.
#' @param time_step_minutes Minutes represented by one timestep.
#' @returns An object of class `tj_ar_forecast` containing selected inputs,
#'   modal weights, root contributions and projected error.
#' @examples
#' history <- c(0.20, 0.19, 0.23, 0.18, 0.17, 0.16, 0.15, 0.14, 0.13, 0.12, 0.11)
#' result <- forecast_tj_ar(default_ar_parameters(), history, jump = 5L, steps = 24L)
#' tj_ar_series(result)
#' @export
forecast_tj_ar <- function(parameters,
                           error_history,
                           jump = 1L,
                           steps = 480L,
                           time_step_minutes = 15) {
  jump <- as.integer(jump)
  steps <- as.integer(steps)
  p <- parameters@order
  if (length(jump) != 1L ||
      is.na(jump) ||
      jump < 1L)
    stop("`jump` must be a positive whole number.", call. = FALSE)
  if (length(steps) != 1L ||
      is.na(steps) ||
      steps < 1L)
    stop("`steps` must be positive.", call. = FALSE)
  required <- 1L + (p - 1L) * jump
  if (!is.numeric(error_history) ||
      anyNA(error_history) ||
      length(error_history) < required)
    stop(
      sprintf(
        "`error_history` must contain at least %d complete values.",
        required
      ),
      call. = FALSE
    )
  selected_indices <- 1L + (0:(p - 1L)) * jump
  selected_errors <- error_history[selected_indices]
  roots_values <- roots(parameters)@values
  selected_times <- -selected_indices
  design <- outer(
    selected_times,
    roots_values,
    function(tt, rr) {
      rr^tt
    }
  )
  
  # Scale each root column before solving. Negative modal times can produce
  # extremely large inverse powers for rapidly decaying roots. Column scaling
  # improves numerical conditioning without changing the mathematical solution.
  column_scale <- apply(
    Mod(
      design
    ),
    2L,
    max
  )
  
  if (
    any(
      !is.finite(
        column_scale
      )
    ) ||
    any(
      column_scale == 0
    )
  ) {
    stop(
      paste0(
        "The TJ-AR modal-weight system cannot be scaled for jump = ",
        jump,
        ". Reduce the jump or review the characteristic roots."
      ),
      call. = FALSE
    )
  }
  
  scaled_design <- sweep(
    design,
    MARGIN = 2L,
    STATS = column_scale,
    FUN = "/"
  )
  
  condition_number <- kappa(
    scaled_design,
    exact = TRUE
  )
  
  if (
    !is.finite(
      condition_number
    ) ||
    condition_number > 1e12
  ) {
    stop(
      paste0(
        "The TJ-AR modal-weight system is numerically singular for jump = ",
        jump,
        ". Scaled condition number: ",
        format(
          condition_number,
          scientific = TRUE,
          digits = 4
        ),
        ". Reduce the jump. A large jump suppresses the fast roots and ",
        "can make their modal weights impossible to estimate reliably."
      ),
      call. = FALSE
    )
  }
  
  scaled_weights <- qr.solve(
    scaled_design,
    as.complex(
      selected_errors
    ),
    tol = 1e-12
  )
  
  weights <- scaled_weights / column_scale
  
  forecast_step <- seq_len(steps)
  modal_time <- forecast_step - 1L
  contributions <- data.table::rbindlist(lapply(seq_along(roots_values), function(j) {
    value <- weights[j] * roots_values[j]^modal_time
    data.table::data.table(
      step = forecast_step,
      lead_time_minutes = forecast_step * time_step_minutes,
      lead_time_hours = forecast_step * time_step_minutes / 60,
      modal_time = modal_time,
      root_number = j,
      contribution_real = Re(value),
      contribution_imaginary = Im(value)
    )
  }))
  series <- contributions[, .(ar_error = sum(contribution_real)), by = .(step, lead_time_minutes, lead_time_hours)]
  inputs <- data.table::data.table(
    input_number = seq_len(p),
    history_index = selected_indices,
    modal_time = selected_times,
    error = selected_errors
  )
  weight_table <- data.table::data.table(
    root_number = seq_along(roots_values),
    root_real = Re(roots_values),
    root_imaginary = Im(roots_values),
    weight_real = Re(weights),
    weight_imaginary = Im(weights)
  )
  structure(
    list(
      parameters = parameters,
      jump = jump,
      selected_inputs = inputs,
      weights = weight_table,
      contributions = contributions,
      series = series,
      time_step_minutes = time_step_minutes
    ),
    class = "tj_ar_forecast"
  )
}

#' Extract a TJ-AR projected series
#' @param x A result from [forecast_tj_ar()].
#' @returns A copied `data.table` of projected error by lead time.
#' @examples
#' # tj_ar_series(result)
#' @export
tj_ar_series <- function(x)
  data.table::copy(x$series)

#' Assess a proposed TJ-AR jump size
#'
#' Compare a jump with characteristic-root timescales. This is a diagnostic, not
#' a universal pass/fail rule.
#' @param parameters An AR parameter set.
#' @param jump Positive whole timestep jump.
#' @param noise_decorrelation_steps Optional estimate of noise decorrelation time.
#' @returns One-row `data.table` with jump-to-root ratios and warnings.
#' @examples
#' assess_jump_size(default_ar_parameters(), jump = 5L, noise_decorrelation_steps = 3)
#' @export
assess_jump_size <- function(parameters,
                             jump,
                             noise_decorrelation_steps = NULL) {
  jump <- as.integer(jump)
  d <- root_table(roots(parameters))
  decay <- sort(d$decay_time_steps[is.finite(d$decay_time_steps)], decreasing = TRUE)
  principal <- if (length(decay) >= 1L)
    decay[1]
  else
    NA_real_
  middle <- if (length(decay) >= 2L)
    decay[2]
  else
    NA_real_
  fast <- if (length(decay) >= 3L)
    decay[3]
  else
    tail(decay, 1)
  data.table::data.table(
    jump = jump,
    principal_decay_steps = principal,
    middle_decay_steps = middle,
    fast_decay_steps = fast,
    jump_to_middle_ratio = jump / middle,
    jump_to_fast_ratio = jump / fast,
    smaller_than_noise_decorrelation = if (is.null(noise_decorrelation_steps))
      NA
    else
      jump < noise_decorrelation_steps,
    effective_order_warning = ifelse(
      is.finite(middle) &&
        jump > 3 * middle,
      "Jump may suppress middle and fast roots; behaviour may approach AR(1).",
      ifelse(
        is.finite(fast) &&
          jump > 3 * fast,
        "Fast-root contribution may be negligible; behaviour may approach AR(2).",
        "No strong effective-order warning."
      )
    )
  )
}

#' Compare TJ-AR sensitivity across jump sizes
#'
#' Calculate and plot TJ-AR projections for several candidate jump sizes.
#' Numerically invalid jumps are omitted from the plot and recorded in the
#' returned plot object's `failed_jumps` attribute.
#'
#' @param parameters An AR parameter set.
#' @param error_history Complete error history supplied newest first.
#' @param jumps Positive whole-number jump sizes to compare.
#' @param steps Positive whole number of forecast steps.
#' @param time_step_minutes Minutes represented by one model timestep.
#'
#' @returns A `ggplot` showing each numerically valid projection. The plot has
#'   a `failed_jumps` attribute containing any omitted jump sizes and their
#'   corresponding error messages.
#'
#' @examples
#' history <- seq(
#'   0.2,
#'   0.05,
#'   length.out = 30
#' ) +
#'   rep(
#'     c(
#'       -0.01,
#'       0.01
#'     ),
#'     15
#'   )
#'
#' plot_jump_sensitivity(
#'   default_ar_parameters(),
#'   history,
#'   jumps = c(
#'     1L,
#'     3L,
#'     5L
#'   )
#' )
#'
#' @export
plot_jump_sensitivity <- function(
    parameters,
    error_history,
    jumps = c(
      1L,
      3L,
      5L
    ),
    steps = 96L,
    time_step_minutes = 15
) {
  jumps <- unique(
    as.integer(
      jumps
    )
  )
  
  if (
    !length(
      jumps
    ) ||
    anyNA(
      jumps
    ) ||
    any(
      jumps < 1L
    )
  ) {
    stop(
      "`jumps` must contain positive whole numbers.",
      call. = FALSE
    )
  }
  
  results <- vector(
    "list",
    length(
      jumps
    )
  )
  
  failures <- vector(
    "list",
    length(
      jumps
    )
  )
  
  for (
    index in seq_along(
      jumps
    )
  ) {
    jump <- jumps[[index]]
    
    forecast <- tryCatch(
      {
        forecast_tj_ar(
          parameters = parameters,
          error_history = error_history,
          jump = jump,
          steps = steps,
          time_step_minutes = time_step_minutes
        )
      },
      error = function(error) {
        failures[[index]] <<- data.table::data.table(
          jump = jump,
          error = conditionMessage(
            error
          )
        )
        
        NULL
      }
    )
    
    if (
      !is.null(
        forecast
      )
    ) {
      series <- tj_ar_series(
        forecast
      )
      
      series[
        ,
        jump := jump
      ]
      
      results[[index]] <- series
    }
  }
  
  results <- Filter(
    Negate(
      is.null
    ),
    results
  )
  
  failures <- Filter(
    Negate(
      is.null
    ),
    failures
  )
  
  failed_jumps <- if (
    length(
      failures
    )
  ) {
    data.table::rbindlist(
      failures
    )
  } else {
    data.table::data.table(
      jump = integer(),
      error = character()
    )
  }
  
  if (
    !length(
      results
    )
  ) {
    stop(
      paste0(
        "No jump size produced a numerically stable TJ-AR projection.\n",
        paste(
          paste0(
            "jump = ",
            failed_jumps$jump,
            ": ",
            failed_jumps$error
          ),
          collapse = "\n"
        )
      ),
      call. = FALSE
    )
  }
  
  data <- data.table::rbindlist(
    results
  )
  
  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = lead_time_hours,
      y = ar_error,
      colour = factor(
        jump
      )
    )
  ) +
    ggplot2::geom_hline(
      yintercept = 0,
      colour = "grey70"
    ) +
    ggplot2::geom_line() +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Lead time, hours",
      y = "Projected error",
      colour = "Jump"
    )
  
  attr(
    plot,
    "failed_jumps"
  ) <- failed_jumps
  
  if (
    nrow(
      failed_jumps
    ) > 0L
  ) {
    warning(
      paste0(
        "The following jump sizes were omitted because their TJ-AR ",
        "systems were numerically singular: ",
        paste(
          failed_jumps$jump,
          collapse = ", "
        ),
        ". Inspect attr(plot, \"failed_jumps\") for details."
      ),
      call. = FALSE
    )
  }
  
  plot
}
