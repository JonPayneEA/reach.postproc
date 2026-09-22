# Concise print methods. Return the object invisibly for piping.

print.ARParameterSet <- function(x, ...) {
  cat("<ARParameterSet>\n")
  cat("Label: ", x@label, "\n", sep = "")
  cat("Order: ", x@order, "\n", sep = "")
  cat("Coefficients: ", paste(names(x@coefficients), .format_number(x@coefficients), sep = " = ", collapse = ", "), "\n", sep = "")
  invisible(x)
}

print.CharacteristicRoots <- function(x, ...) {
  cat("<CharacteristicRoots>\n")
  print(x@table)
  invisible(x)
}

print.ARForecast <- function(x, ...) {
  cat("<ARForecast>\n")
  cat("Steps: ", nrow(x@series), "\n", sep = "")
  print(x@series)
  invisible(x)
}

print.ARAssessment <- function(x, ...) {
  cat("<ARAssessment> ", x@result, "\n", sep = "")
  print(x@tests)
  invisible(x)
}

print.ARMAResponse <- function(x, ...) {
  cat("<ARMAResponse>\n")
  cat("Steps: ", nrow(x@series), "\n", sep = "")
  print(x@series)
  invisible(x)
}
