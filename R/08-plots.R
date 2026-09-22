# Plot methods ----------------------------------------------------------------

S7::method(plot_ar, CharacteristicRoots) <- function(x, ...) {
  unit_circle <- data.table::data.table(
    angle = seq(0, 2 * pi, length.out = 361L)
  )

  unit_circle[
    ,
    `:=`(
      x = cos(angle),
      y = sin(angle)
    )
  ]

  ggplot2::ggplot() +
    ggplot2::geom_line(
      data = unit_circle,
      ggplot2::aes(x = x, y = y),
      colour = "grey70"
    ) +
    ggplot2::geom_point(
      data = x@table,
      ggplot2::aes(
        x = root_real,
        y = root_imaginary,
        colour = is_growing
      ),
      size = 3
    ) +
    ggplot2::coord_equal() +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Real component",
      y = "Imaginary component",
      colour = "Growing",
      title = "Characteristic roots"
    )
}

S7::method(plot_ar, ARForecast) <- function(
    x,
    ...,
    colours = c(ar_error = "#005EA5")
) {
  ggplot2::ggplot(
    x@series,
    ggplot2::aes(
      x = lead_time_hours,
      y = ar_error
    )
  ) +
    ggplot2::geom_hline(
      yintercept = 0,
      colour = "grey70"
    ) +
    ggplot2::geom_line(
      colour = unname(colours[[1L]]),
      linewidth = 0.8
    ) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Lead time, hours",
      y = "AR error",
      title = "Forecast AR error"
    )
}

S7::method(plot_ar, ARAssessment) <- function(x, ...) {
  plot_data <- data.table::copy(x@tests)
  plot_data[, status := ifelse(failed, "Fail", "Pass")]

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = status,
      y = test,
      colour = status
    )
  ) +
    ggplot2::geom_point(size = 4) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = paste("Parameter assessment:", x@result),
      x = NULL,
      y = NULL,
      colour = NULL
    )
}

S7::method(plot_ar, ARMAResponse) <- function(x, ...) {
  ggplot2::ggplot(
    x@series,
    ggplot2::aes(
      x = step,
      y = arma_error
    )
  ) +
    ggplot2::geom_hline(
      yintercept = 0,
      colour = "grey70"
    ) +
    ggplot2::geom_line(
      colour = "#005EA5"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Time step",
      y = "Response",
      title = "ARMA unit response"
    )
}
