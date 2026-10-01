test_that("rainfall accumulation trigger uses moving window", {
  x <- rainfall_accumulation_trigger(c(0,1,2,3,0), 3L, 5)
  expect_equal(x$data$accumulated_rainfall, c(0,1,3,6,5))
  expect_equal(x$data$triggered, c(FALSE,FALSE,FALSE,TRUE,TRUE))
})
test_that("CWI scaling follows Part 2 piecewise rule", {
  expect_equal(cwi_rainfall_factor(c(120,125,145,165,170)), c(1,1,.5,0,0))
})
