# S7 classes -----------------------------------------------------------------

class_data_table <- S7::new_S3_class(
  "data.table"
)

#' Autoregressive parameter set
#'
#' Stores autoregressive coefficients in the Deltares sign convention used
#' internally by `reach.postproc`.
#'
#' @section Properties:
#' - `coefficients`: Named numeric vector ordered from `a_1` to `a_p`.
#' - `order`: Effective model order.
#' - `sign_convention`: Internal sign convention. Always `"Deltares"`.
#' - `order_tolerance`: Tolerance used to remove inactive trailing terms.
#' - `label`: Human-readable description of the parameter set.
#'
#' @export
ARParameterSet <- S7::new_class(
  "ARParameterSet",
  properties = list(
    coefficients = S7::class_numeric,
    order = S7::class_integer,
    sign_convention = S7::class_character,
    order_tolerance = S7::class_numeric,
    label = S7::class_character
  ),
  validator = function(self) {
    errors <- character()

    if (
      length(self@coefficients) < 1L ||
        anyNA(self@coefficients) ||
        any(!is.finite(self@coefficients))
    ) {
      errors <- c(
        errors,
        "@coefficients must contain finite, non-missing values"
      )
    }

    if (
      length(self@order) != 1L ||
        self@order < 1L ||
        self@order != length(self@coefficients)
    ) {
      errors <- c(
        errors,
        "@order must equal the number of active coefficients"
      )
    }

    if (!identical(self@sign_convention, "Deltares")) {
      errors <- c(
        errors,
        "@sign_convention must be 'Deltares'"
      )
    }

    if (
      length(self@order_tolerance) != 1L ||
        self@order_tolerance < 0
    ) {
      errors <- c(
        errors,
        "@order_tolerance must be one non-negative value"
      )
    }

    if (length(self@label) != 1L || is.na(self@label)) {
      errors <- c(
        errors,
        "@label must be one non-missing character value"
      )
    }

    if (length(errors) > 0L) {
      errors
    }
  }
)

#' Characteristic roots of an AR model
#'
#' Stores complex characteristic roots and their interpreted decay and
#' oscillation times.
#'
#' @section Properties:
#' - `parameters`: Source `ARParameterSet`.
#' - `values`: Complex root values in polynomial order.
#' - `table`: Root diagnostics as a `data.table`.
#' - `time_step_minutes`: Duration represented by one model step.
#'
#' @export
CharacteristicRoots <- S7::new_class(
  "CharacteristicRoots",
  properties = list(
    parameters = ARParameterSet,
    values = S7::class_complex,
    table = class_data_table,
    time_step_minutes = S7::class_numeric
  )
)

#' Autoregressive error forecast
#'
#' Stores a projected AR error series and the inputs used to initialise it.
#'
#' @section Properties:
#' - `parameters`: Source `ARParameterSet`.
#' - `initial_errors`: Input errors ordered newest first.
#' - `series`: Forecast values as a `data.table`.
#' - `time_step_minutes`: Duration represented by one model step.
#'
#' @export
ARForecast <- S7::new_class(
  "ARForecast",
  properties = list(
    parameters = ARParameterSet,
    initial_errors = S7::class_numeric,
    series = class_data_table,
    time_step_minutes = S7::class_numeric
  )
)

#' AR parameter quality assessment
#'
#' Stores the result of applying the configured AR quality criteria.
#'
#' @section Properties:
#' - `parameters`: Assessed `ARParameterSet`.
#' - `passed`: Overall logical result.
#' - `result`: `"Pass"` or `"Fail"`.
#' - `summary`: Human-readable interpretation.
#' - `tests`: Individual tests as a `data.table`.
#' - `roots`: Associated `CharacteristicRoots`.
#'
#' @export
ARAssessment <- S7::new_class(
  "ARAssessment",
  properties = list(
    parameters = ARParameterSet,
    passed = S7::class_logical,
    result = S7::class_character,
    summary = S7::class_character,
    tests = class_data_table,
    roots = CharacteristicRoots
  )
)

#' ARMA impulse response
#'
#' Stores a deterministic response to a unit residual impulse.
#'
#' @section Properties:
#' - `parameters`: AR component as an `ARParameterSet`.
#' - `ma_parameters`: Active MA coefficients.
#' - `series`: Response values as a `data.table`.
#'
#' @export
ARMAResponse <- S7::new_class(
  "ARMAResponse",
  properties = list(
    parameters = ARParameterSet,
    ma_parameters = S7::class_numeric,
    series = class_data_table
  )
)

#' Fixed lead-time AR results
#'
#' Stores rolling, fixed lead-time AR-updated series for one or more lead times.
#'
#' @section Properties:
#' - `parameters`: Source `ARParameterSet`.
#' - `series`: Long-format lead-time results as a `data.table`.
#' - `lead_times_minutes`: Evaluated lead times.
#' - `time_step_minutes`: Duration represented by one model step.
#' - `metadata`: Site and measurement metadata.
#'
#' @export
ARLeadTimeResult <- S7::new_class(
  "ARLeadTimeResult",
  properties = list(
    parameters = ARParameterSet,
    series = class_data_table,
    lead_times_minutes = S7::class_numeric,
    time_step_minutes = S7::class_numeric,
    metadata = S7::class_list
  )
)
