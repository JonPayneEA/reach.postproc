# S7 classes. data.table is formally represented as an S3 class.

class_data_table <- S7::new_S3_class("data.table")

ARParameterSet <- S7::new_class(
  "ARParameterSet",
  properties = list(
    coefficients = S7::class_numeric,
    order = S7::class_integer,
    label = S7::class_character
  ),
  validator = function(self) {
    errors <- character()
    if (length(self@coefficients) < 1L || anyNA(self@coefficients) ||
        any(!is.finite(self@coefficients))) {
      errors <- c(errors, "@coefficients must contain finite, non-missing values")
    }
    if (length(self@order) != 1L || self@order < 1L ||
        self@order != length(self@coefficients)) {
      errors <- c(errors, "@order must equal the number of coefficients")
    }
    if (length(self@label) != 1L || is.na(self@label)) {
      errors <- c(errors, "@label must be one non-missing character value")
    }
    if (length(errors)) errors
  }
)

CharacteristicRoots <- S7::new_class(
  "CharacteristicRoots",
  properties = list(
    parameters = ARParameterSet,
    values = S7::class_complex,
    table = class_data_table,
    time_step_minutes = S7::class_numeric
  )
)

ARForecast <- S7::new_class(
  "ARForecast",
  properties = list(
    parameters = ARParameterSet,
    initial_errors = S7::class_numeric,
    series = class_data_table,
    time_step_minutes = S7::class_numeric
  )
)

ARAssessment <- S7::new_class(
  "ARAssessment",
  properties = list(
    parameters = ARParameterSet,
    passed = S7::class_logical,
    result = S7::class_character,
    tests = class_data_table,
    roots = CharacteristicRoots
  )
)

ARMAResponse <- S7::new_class(
  "ARMAResponse",
  properties = list(
    parameters = ARParameterSet,
    ma_parameters = S7::class_numeric,
    series = class_data_table
  )
)
