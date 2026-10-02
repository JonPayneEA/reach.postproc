test_that("et_ar_configuration rejects mismatched AR order", {
  steady <- default_ar_parameters()
  mismatched <- ar_parameters(c(0.5, 0.3))
  expect_error(
    et_ar_configuration(steady, mismatched, logical_et_trigger(c(FALSE, TRUE))),
    "same AR order"
  )
})

test_that("et_ar_configuration rejects an object that is not an et_ar_trigger", {
  steady <- default_ar_parameters()
  expect_error(
    et_ar_configuration(steady, steady, list(type = "logical")),
    "trigger constructor"
  )
})

test_that("et_ar_configuration accepts matched order and a valid trigger", {
  config <- et_ar_configuration(
    default_et_ar_steady_parameters(),
    event_ar_parameters(48),
    logical_et_trigger(c(FALSE, TRUE))
  )
  expect_s3_class(config, "et_ar_configuration")
  expect_identical(config$label, "ET-AR configuration")
})

test_that("event_ar_parameters rejects a non-positive response time", {
  expect_error(event_ar_parameters(0), "positive")
  expect_error(event_ar_parameters(-5), "positive")
})
