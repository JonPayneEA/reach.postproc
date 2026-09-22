# S7 generics used by the AR and ARMA object model.

roots <- S7::new_generic(
  "roots",
  dispatch_args = "x",
  fun = function(x, ...) S7::S7_dispatch()
)

assess <- S7::new_generic(
  "assess",
  dispatch_args = "x",
  fun = function(x, ...) S7::S7_dispatch()
)

forecast_ar <- S7::new_generic(
  "forecast_ar",
  dispatch_args = "x",
  fun = function(x, ..., initial_errors, steps = 480L, time_step_minutes = 15) {
    S7::S7_dispatch()
  }
)

response <- S7::new_generic(
  "response",
  dispatch_args = "x",
  fun = function(x, ..., ma_parameters = numeric(), steps = 480L) {
    S7::S7_dispatch()
  }
)

decompose_ar <- S7::new_generic(
  "decompose_ar",
  dispatch_args = "x",
  fun = function(x, ..., initial_errors, steps = 480L, time_step_minutes = 15) {
    S7::S7_dispatch()
  }
)

plot_ar <- S7::new_generic(
  "plot_ar",
  dispatch_args = "x",
  fun = function(x, ...) S7::S7_dispatch()
)
