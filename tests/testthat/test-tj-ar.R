test_that("TJ-AR jump one equals normal AR", {
 p <- default_ar_parameters(); history <- c(.2,.15,.1,rep(0,10))
 tj <- forecast_tj_ar(p,history,jump=1L,steps=100)
 direct <- forecast_ar(p,initial_errors=history[1:3],steps=100)
 expect_equal(tj_ar_series(tj)$ar_error,forecast_series(direct)$ar_error,tolerance=1e-9)
})
test_that("TJ selected indices follow jump", {
 tj <- forecast_tj_ar(default_ar_parameters(),seq(.2,.01,length.out=20),jump=5L,steps=10)
 expect_equal(tj$selected_inputs$history_index,c(1L,6L,11L))
})
test_that("combined forecast retains TJ audit information", {
 cfg <- et_ar_configuration(default_et_ar_steady_parameters(),event_ar_parameters(48),logical_et_trigger(rep(FALSE,10)))
 ans <- forecast_et_tj_ar(cfg,seq(.2,.01,length.out=20),5L,rep(1,10))
 expect_equal(ans$tj_initialisation$jump,5L)
 expect_length(ans$tj_initialisation$reconstructed_consecutive_errors,3L)
})
test_that("assess_jump_size ranks roots correctly when the principal root has infinite decay", {
  # default_et_ar_steady_parameters() is deliberately built with an infinite
  # principal decay time. Filtering to finite decay values before ranking
  # (the earlier implementation) drops that root and relabels the remaining
  # two as principal/middle, with "fast" falling back to a duplicate of
  # "middle". The fix must keep Inf as the top-ranked, genuine principal root.
  result <- assess_jump_size(default_et_ar_steady_parameters(), jump = 5L)
  expect_true(is.infinite(result$principal_decay_steps))
  expect_true(is.finite(result$middle_decay_steps))
  expect_true(is.finite(result$fast_decay_steps))
  expect_false(isTRUE(result$middle_decay_steps == result$fast_decay_steps))
  expect_equal(result$jump_to_middle_ratio, 5L / result$middle_decay_steps)
})

test_that("assess_jump_size reports NA fast decay when fewer than three roots are supplied", {
  two_root <- ar_parameters_from_timescales(
    decay_times = c(48, 5),
    oscillation_periods = c(Inf, Inf)
  )
  result <- assess_jump_size(two_root, jump = 2L)
  expect_true(is.finite(result$principal_decay_steps))
  expect_true(is.finite(result$middle_decay_steps))
  expect_true(is.na(result$fast_decay_steps))
})

test_that(
  "jump sensitivity omits numerically singular jumps",
  {
    history <- seq(
      0.25,
      0.08,
      length.out = 40
    )
    
    plot <- expect_warning(
      plot_jump_sensitivity(
        parameters = default_ar_parameters(),
        error_history = history,
        jumps = c(
          1L,
          5L,
          25L
        ),
        steps = 24L
      ),
      regexp = "omitted"
    )
    
    failures <- attr(
      plot,
      "failed_jumps"
    )
    
    expect_s3_class(
      plot,
      "ggplot"
    )
    
    expect_true(
      25L %in% failures$jump
    )
  }
)
