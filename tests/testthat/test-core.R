test_that("defaults work",{p<-default_ar_parameters();expect_true(data.table::is.data.table(roots(p)@table));expect_true(assess(p)@passed)})
test_that("sign convention converts",{expect_equal(ar_parameters(c(-1.765,.72625,.040656),sign_convention="Standard")@coefficients,default_ar_parameters()@coefficients)})
test_that("trailing zero is removed",{expect_identical(ar_parameters(c(1.85,-.85,0))@order,2L)})
test_that("AR1 policy is configurable",{p<-ar_parameters(.9);expect_false(assess(p)@passed);expect_true(assess(p,permitted_orders=1:3)@passed)})
test_that("decomposition agrees",{p<-default_ar_parameters();f<-forecast_ar(p,initial_errors=c(.2,.15,.1),steps=100L)@series;d<-decompose_ar(p,initial_errors=c(.2,.15,.1),steps=100L);z<-d[step>0,.(v=sum(contribution_real)),by=step];expect_equal(f$ar_error,z$v,tolerance=1e-9)})
test_that("mixed solver works",{p<-solve_ar_parameters(3,c(12,1/3),c(Inf,2),c(1.765,NA,NA));expect_equal(p@coefficients[1],1.765)})
test_that("response components exist",{x<-response_components(default_ar_parameters(),c(-.5,-.25),20);expect_setequal(unique(x$component),c("AR","MA","ARMA"))})


test_that("series alignment diagnoses timestamps", {
  time <- as.POSIXct("2026-01-01", tz = "UTC") + 0:9 * 900
  obs <- data.table::data.table(date_time = time, value = 1:10)
  sim <- data.table::data.table(date_time = time, value = 0:9)
  result <- align_forecast_series(obs, sim, interval_minutes = 15)
  expect_equal(result$error, rep(1, 10))
  expect_true(attr(result, "alignment_diagnostics")$regular_time_step)
})

test_that("fixed lead recurrence and roots agree", {
  time <- as.POSIXct("2026-01-01", tz = "UTC") + 0:99 * 900
  data <- data.table::data.table(date_time = time, observed = sin(1:100 / 10), simulated = 0)
  p <- default_ar_parameters()
  recurrence <- fixed_lead_ar(p, data, lead_times_minutes = c(30, 60, 90))@series
  roots <- fixed_lead_ar(p, data, lead_times_minutes = c(30, 60, 90), method = "roots")@series
  expect_equal(recurrence$updated, roots$updated, tolerance = 1e-8)
})

test_that("invalid lead-time ratios fail", {
  data <- data.table::data.table(date_time = 1:20, observed = 1:20, simulated = 1:20)
  expect_error(fixed_lead_ar(default_ar_parameters(), data, lead_times_minutes = 20, time_step_minutes = 15))
})

test_that("lead-time scoring returns data.table", {
  time <- as.POSIXct("2026-01-01", tz = "UTC") + 0:49 * 900
  data <- data.table::data.table(date_time = time, observed = sin(1:50 / 10), simulated = 0)
  result <- fixed_lead_ar(default_ar_parameters(), data, lead_times_minutes = 30)
  expect_true(data.table::is.data.table(score_lead_times(result)))
})
