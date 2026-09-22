# Print methods ---------------------------------------------------------------

#' @export
print.ARParameterSet <- function(x, ...) {
  cat("<ARParameterSet>\n")
  cat("Label: ", x@label, "\n", sep = "")
  cat("Order: ", x@order, "\n", sep = "")
  cat("Convention: ", x@sign_convention, "\n", sep = "")
  print(x@coefficients)
  invisible(x)
}

#' @export
print.CharacteristicRoots <- function(x, ...) {
  cat("<CharacteristicRoots>\n")
  print(x@table)
  invisible(x)
}

#' @export
print.ARForecast <- function(x, ...) {
  cat("<ARForecast>\n")
  print(x@series)
  invisible(x)
}

#' @export
print.ARAssessment <- function(x, ...) {
  cat("<ARAssessment> ", x@result, "\n", sep = "")
  cat(x@summary, "\n")
  print(x@tests)
  invisible(x)
}

#' @export
print.ARMAResponse <- function(x, ...) {
  cat("<ARMAResponse>\n")
  print(x@series)
  invisible(x)
}

#' @export
print.ARLeadTimeResult <- function(x, ...) {
  cat("<ARLeadTimeResult>\n")
  cat(
    "Lead times, minutes: ",
    paste(x@lead_times_minutes, collapse = ", "),
    "\n",
    sep = ""
  )
  print(x@series)
  invisible(x)
}
