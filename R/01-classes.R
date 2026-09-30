class_data_table <- S7::new_S3_class("data.table")
#' @noRd
FlodeARParameterSet <- S7::new_class("FlodeARParameterSet",properties=list(coefficients=S7::class_numeric,order=S7::class_integer,sign_convention=S7::class_character,order_tolerance=S7::class_numeric,label=S7::class_character))
#' @noRd
FlodeCharacteristicRoots <- S7::new_class("FlodeCharacteristicRoots",properties=list(parameters=FlodeARParameterSet,values=S7::class_complex,table=class_data_table,time_step_minutes=S7::class_numeric))
#' @noRd
FlodeARForecast <- S7::new_class("FlodeARForecast",properties=list(parameters=FlodeARParameterSet,initial_errors=S7::class_numeric,series=class_data_table,time_step_minutes=S7::class_numeric))
#' @noRd
FlodeARAssessment <- S7::new_class("FlodeARAssessment",properties=list(parameters=FlodeARParameterSet,passed=S7::class_logical,result=S7::class_character,summary=S7::class_character,tests=class_data_table,roots=FlodeCharacteristicRoots))
#' @noRd
FlodeARMAResponse <- S7::new_class("FlodeARMAResponse",properties=list(parameters=FlodeARParameterSet,ma_parameters=S7::class_numeric,series=class_data_table))
#' @noRd
FlodeAlignedForecastSeries <- S7::new_class("FlodeAlignedForecastSeries",properties=list(series=class_data_table,diagnostics=class_data_table,metadata=S7::class_list))
#' @noRd
FlodeARLeadTimeResult <- S7::new_class("FlodeARLeadTimeResult",properties=list(parameters=FlodeARParameterSet,series=class_data_table,lead_times_minutes=S7::class_numeric,time_step_minutes=S7::class_numeric,metadata=S7::class_list))
