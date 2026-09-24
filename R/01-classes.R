class_data_table <- S7::new_S3_class("data.table")
#'
#' @noRd
ARParameterSet <- S7::new_class("ARParameterSet", properties=list(
 coefficients=S7::class_numeric, order=S7::class_integer,
 sign_convention=S7::class_character, order_tolerance=S7::class_numeric,
 label=S7::class_character))
#'
#' @noRd
CharacteristicRoots <- S7::new_class("CharacteristicRoots", properties=list(
 parameters=ARParameterSet, values=S7::class_complex, table=class_data_table,
 time_step_minutes=S7::class_numeric))
#'
#' @noRd
ARForecast <- S7::new_class("ARForecast", properties=list(
 parameters=ARParameterSet, initial_errors=S7::class_numeric,
 series=class_data_table, time_step_minutes=S7::class_numeric))
#'
#' @noRd
ARAssessment <- S7::new_class("ARAssessment", properties=list(
 parameters=ARParameterSet, passed=S7::class_logical,
 result=S7::class_character, summary=S7::class_character,
 tests=class_data_table, roots=CharacteristicRoots))
#'
#' @noRd
ARMAResponse <- S7::new_class("ARMAResponse", properties=list(
 parameters=ARParameterSet, ma_parameters=S7::class_numeric, series=class_data_table))
#'
#' @noRd
AlignedForecastSeries <- S7::new_class("AlignedForecastSeries", properties=list(
 series=class_data_table, diagnostics=class_data_table, metadata=S7::class_list))
#'
#' @noRd
ARLeadTimeResult <- S7::new_class("ARLeadTimeResult", properties=list(
 parameters=ARParameterSet, series=class_data_table,
 lead_times_minutes=S7::class_numeric, time_step_minutes=S7::class_numeric,
 metadata=S7::class_list))
