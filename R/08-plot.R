# ggplot2 methods. Calculations remain separate from presentation.

S7::method(plot_ar, CharacteristicRoots) <- function(x, ...) {
  circle <- data.table::data.table(
    angle = seq(0, 2 * pi, length.out = 361L)
  )
  circle[, `:=`(x = cos(angle), y = sin(angle))]
  ggplot2::ggplot() +
    ggplot2::geom_line(data = circle, ggplot2::aes(x = x, y = y), colour = "grey70") +
    ggplot2::geom_hline(yintercept = 0, colour = "grey80") +
    ggplot2::geom_vline(xintercept = 0, colour = "grey80") +
    ggplot2::geom_point(
      data = x@table,
      ggplot2::aes(x = root_real, y = root_imaginary, colour = is_growing),
      size = 3
    ) +
    ggplot2::scale_colour_manual(values = c(`FALSE` = "#005EA5", `TRUE` = "#D4351C")) +
    ggplot2::labs(x = "Real component", y = "Imaginary component",
                  colour = "Growing", title = "Characteristic roots") +
    ggplot2::theme_minimal() +
    ggplot2::coord_equal()
}

S7::method(plot_ar, ARForecast) <- function(x, ...) {
  ggplot2::ggplot(x@series, ggplot2::aes(x = lead_time_hours, y = ar_error)) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
    ggplot2::geom_line(colour = "#005EA5", linewidth = 0.8) +
    ggplot2::labs(x = "Lead time, hours", y = "AR error", title = "Forecast AR error") +
    ggplot2::theme_minimal()
}

S7::method(plot_ar, ARAssessment) <- function(x, ...) {
  data <- data.table::copy(x@tests)
  data[, status := ifelse(failed, "Fail", "Pass")]
  data[, test := factor(test, levels = rev(test))]
  ggplot2::ggplot(data, ggplot2::aes(x = status, y = test, colour = status)) +
    ggplot2::geom_point(size = 4) +
    ggplot2::scale_colour_manual(values = c(Pass = "#00703C", Fail = "#D4351C")) +
    ggplot2::labs(x = NULL, y = NULL, colour = NULL, title = paste("Parameter assessment:", x@result)) +
    ggplot2::theme_minimal()
}

S7::method(plot_ar, ARMAResponse) <- function(x, ...) {
  ggplot2::ggplot(x@series, ggplot2::aes(x = step, y = arma_error)) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
    ggplot2::geom_line(colour = "#005EA5", linewidth = 0.8) +
    ggplot2::labs(x = "Time step", y = "Response", title = "ARMA unit response") +
    ggplot2::theme_minimal()
}
