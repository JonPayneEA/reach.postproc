test_that("ET-AR does not switch where trigger is false", {
 cfg <- et_ar_configuration(default_ar_parameters(), event_ar_parameters(48), logical_et_trigger(rep(FALSE,20)))
 et <- forecast_et_ar(cfg,c(.2,.15,.1),rep(1,20))
 base <- forecast_ar(default_ar_parameters(),initial_errors=c(.2,.15,.1),steps=20)
 expect_equal(et$series$ar_error, forecast_series(base)$ar_error, tolerance=1e-10)
})
test_that("ET-AR switches once and remains continuous", {
 cfg <- et_ar_configuration(default_et_ar_steady_parameters(),event_ar_parameters(48),logical_et_trigger(c(FALSE,FALSE,TRUE,rep(FALSE,7))))
 et <- forecast_et_ar(cfg,c(.2,.15,.1),rep(1,10))
 expect_equal(et$switch_step,3L)
 expect_equal(et$series$parameter_state,c("steady","steady",rep("event",8)))
 expect_true(all(is.finite(et$series$ar_error)))
})
test_that("first-step trigger equals event recurrence", {
 event <- event_ar_parameters(48); cfg <- et_ar_configuration(default_et_ar_steady_parameters(),event,logical_et_trigger(rep(TRUE,10)))
 et <- forecast_et_ar(cfg,c(.2,.15,.1),rep(1,10))
 direct <- forecast_ar(event,initial_errors=c(.2,.15,.1),steps=10)
 expect_equal(et$series$ar_error,forecast_series(direct)$ar_error,tolerance=1e-10)
})
test_that("ET-AR forecast series is a data.table, not a data.frame", {
  cfg <- et_ar_configuration(default_ar_parameters(), event_ar_parameters(48), logical_et_trigger(rep(FALSE, 5)))
  et <- forecast_et_ar(cfg, c(.2, .15, .1), rep(1, 5))
  expect_true(data.table::is.data.table(et$series))
})
test_that("updated-threshold trigger switches immediately when the initial value already meets it", {
  cfg <- et_ar_configuration(
    default_et_ar_steady_parameters(), event_ar_parameters(48),
    updated_threshold_trigger(threshold = 1.0, direction = "above", initial_value = 1.2, quantity = "level")
  )
  result <- forecast_et_ar(cfg, c(.2, .15, .1), rep(1, 5))
  expect_equal(result$switch_step, 1L)
  expect_equal(result$series$parameter_state, rep("event", 5))
})
test_that("updated-threshold trigger stays steady while the updated value remains below threshold", {
  cfg <- et_ar_configuration(
    default_et_ar_steady_parameters(), event_ar_parameters(48),
    updated_threshold_trigger(threshold = 5.0, direction = "above", initial_value = 0.5, quantity = "level")
  )
  result <- forecast_et_ar(cfg, c(.2, .15, .1), rep(0.1, 5))
  expect_true(is.na(result$switch_step))
  expect_equal(result$series$parameter_state, rep("steady", 5))
})
