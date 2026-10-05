simple_aligned <- function() {
  time <- as.POSIXct("2024-01-01", tz = "UTC") + 0:9 * 900
  simulated <- rep(1, 10)
  observed <- simulated
  observed[1:3] <- simulated[1:3] + c(0.2, 0.15, 0.1) # errors feeding the order-3 seed

  align_forecast_series(
    data.frame(date_time = time, value = observed),
    data.frame(date_time = time, value = simulated),
    interval_minutes = 15
  )
}

test_that("single_origin_ar_update matches forecast_ar() + apply_ar_update() directly", {
  aligned <- simple_aligned()
  parameters <- default_ar_parameters()

  result <- single_origin_ar_update(parameters, aligned, origin = 4L)

  errors <- c(0.1, 0.15, 0.2) # rows 3, 2, 1: newest first
  expected_projection <- forecast_ar(parameters, initial_errors = errors, steps = 7L)
  expected_applied <- apply_ar_update(
    simulated = rep(1, 7),
    ar_error = expected_projection@series$ar_error
  )

  expect_equal(result$ar_error[4:10], expected_applied$ar_error)
  expect_equal(result$updated[4:10], expected_applied$updated)
})

test_that("single_origin_ar_update leaves rows before the origin as NA", {
  result <- single_origin_ar_update(default_ar_parameters(), simple_aligned(), origin = 4L)
  expect_true(all(is.na(result$ar_error[1:3])))
  expect_true(all(is.na(result$updated[1:3])))
  expect_false(anyNA(result$updated[4:10]))
})

test_that("single_origin_ar_update accepts a POSIXct origin matching the date_time column", {
  aligned <- simple_aligned()
  by_index <- single_origin_ar_update(default_ar_parameters(), aligned, origin = 4L)
  by_time <- single_origin_ar_update(
    default_ar_parameters(), aligned, origin = aligned_series(aligned)$date_time[4]
  )
  expect_equal(by_index$updated, by_time$updated)
})

test_that("single_origin_ar_update rejects an origin with too little prior history", {
  expect_error(
    single_origin_ar_update(default_ar_parameters(), simple_aligned(), origin = 3L),
    "fewer than the 3 prior rows"
  )
})

test_that("single_origin_ar_update rejects an origin index out of range", {
  expect_error(
    single_origin_ar_update(default_ar_parameters(), simple_aligned(), origin = 999L),
    "out of range"
  )
})

test_that("single_origin_ar_update rejects a POSIXct origin matching no row", {
  expect_error(
    single_origin_ar_update(
      default_ar_parameters(), simple_aligned(),
      origin = as.POSIXct("2099-01-01", tz = "UTC")
    ),
    "exactly one row"
  )
})

test_that("single_origin_ar_update rejects missing values in the seed window", {
  aligned <- simple_aligned()
  series <- aligned_series(aligned)
  series$observed[2] <- NA
  broken <- align_forecast_series(
    data.frame(date_time = series$date_time, value = series$observed),
    data.frame(date_time = series$date_time, value = series$simulated),
    interval_minutes = 15
  )
  expect_error(
    single_origin_ar_update(default_ar_parameters(), broken, origin = 4L),
    "missing values"
  )
})

test_that("single_origin_ar_update records provenance attributes", {
  aligned <- simple_aligned()
  result <- single_origin_ar_update(default_ar_parameters(), aligned, origin = 4L)
  expect_equal(attr(result, "origin_index"), 4L)
  expect_equal(attr(result, "origin_date_time"), aligned_series(aligned)$date_time[4])
  expect_equal(attr(result, "initial_errors"), c(0.1, 0.15, 0.2))
})

test_that("plot_single_origin_update returns a ggplot built on the update result", {
  result <- single_origin_ar_update(default_ar_parameters(), simple_aligned(), origin = 4L)
  p <- plot_single_origin_update(result)
  expect_s3_class(p, "ggplot")

  p_with_error <- plot_single_origin_update(result, include_ar_error = TRUE)
  expect_s3_class(p_with_error, "ggplot")
})

test_that("plot_single_origin_update rejects input that isn't a single_origin_ar_update() result", {
  expect_error(
    plot_single_origin_update(data.frame(date_time = 1, observed = 1)),
    "single_origin_ar_update"
  )
})
