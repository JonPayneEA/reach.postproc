# EA parameter-quality assessment.

S7::method(assess, ARParameterSet) <- function(x, ..., maximum_decay_time = 240,
                                                minimum_useful_decay_time = 8,
                                                rapid_decay_exception = 1,
                                                oscillation_ratio = 4.605,
                                                time_step_minutes = 15) {
  root_object <- roots(x, time_step_minutes = time_step_minutes)
  root_table <- root_object@table
  growing <- root_table[root_modulus > 1, root_number]
  too_slow <- root_table[decay_time_steps >= maximum_decay_time, root_number]
  all_too_fast <- all(root_table$decay_time_steps < minimum_useful_decay_time)
  bad_oscillation <- root_table[
    is_oscillating &
      decay_time_steps >= rapid_decay_exception &
      oscillation_period_steps < oscillation_ratio * decay_time_steps,
    root_number
  ]
  tests <- data.table::data.table(
    test_id = c("a", "b", "c", "d"),
    test = c("Exponential growth", "Excessive decay time", "All roots decay too quickly",
             "Unacceptable oscillation"),
    failed = c(length(growing) > 0L, length(too_slow) > 0L, all_too_fast,
               length(bad_oscillation) > 0L),
    affected_roots = list(growing, too_slow,
                          if (all_too_fast) root_table$root_number else integer(),
                          bad_oscillation),
    criterion = c(
      "Any root has modulus greater than one.",
      sprintf("Any root has tau >= %s steps.", maximum_decay_time),
      sprintf("All roots have tau < %s steps.", minimum_useful_decay_time),
      sprintf("Any root has T < %s tau, unless tau < %s.", oscillation_ratio, rapid_decay_exception)
    )
  )
  failed <- any(tests$failed)
  ARAssessment(
    parameters = x,
    passed = !failed,
    result = if (failed) "Fail" else "Pass",
    tests = tests,
    roots = root_object
  )
}
