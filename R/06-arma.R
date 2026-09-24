#' Evaluate a deterministic ARMA error recurrence
#'
#' Calculate an error series from autoregressive memory, current residual
#' innovations and moving-average memory. This function evaluates a supplied
#' ARMA model; it does not estimate AR or MA parameters from observations.
#'
#' @param parameters An AR parameter set created by [ar_parameters()],
#'   [default_ar_parameters()] or [ar_parameters_from_timescales()]. The
#'   coefficient order determines how many values `initial_errors` must contain.
#'   Coefficients are stored internally in the Deltares convention.
#' @param initial_errors Numeric vector containing the error values immediately
#'   before the first forecast step. Supply values **newest first**. For AR(3),
#'   use `c(error_t_minus_1, error_t_minus_2, error_t_minus_3)`. The vector must
#'   have the same length as the AR order and must not contain missing values.
#' @param residuals Numeric vector of innovations to apply during the forecast.
#'   One value is required for each output timestep. Use `0` where no new
#'   innovation is applied. A unit impulse response uses `c(1, 0, 0, ...)`.
#' @param ma_parameters Numeric vector of moving-average coefficients, ordered
#'   from the most recent residual to the oldest. An empty vector, the default,
#'   evaluates an AR-only model. These are MA coefficients, not rolling-average
#'   window weights.
#' @param previous_residuals Numeric vector containing residual innovations from
#'   before the first forecast step, supplied newest first. Its length must equal
#'   `length(ma_parameters)`. Use `numeric(length(ma_parameters))` when no earlier
#'   innovations should contribute.
#'
#' @returns A `data.table` with one row per forecast step and columns containing
#'   the AR contribution, current residual contribution, MA contribution and
#'   resulting ARMA error.
#'
#' @examples
#' parameters <- default_ar_parameters()
#'
#' innovations <- c(1, rep(0, 23))
#'
#' arma_forecast <- forecast_arma(
#'   parameters = parameters,
#'   initial_errors = c(0, 0, 0),
#'   residuals = innovations,
#'   ma_parameters = c(-0.5, -0.25),
#'   previous_residuals = c(0, 0)
#' )
#'
#' head(arma_forecast)
#' @export
forecast_arma<-function(parameters,initial_errors,residuals,ma_parameters=numeric(),previous_residuals=numeric()){if(length(initial_errors)!=parameters@order)stop_bad_argument("Initial errors must match AR order.");if(length(previous_residuals)!=length(ma_parameters))stop_bad_argument("Previous residuals must match MA order.");es<-initial_errors;rs<-previous_residuals;out<-vector("list",length(residuals));for(i in seq_along(residuals)){ar<-sum(parameters@coefficients*es);ma<-if(length(ma_parameters))sum(ma_parameters*rs)else 0;total<-ar+ma+residuals[i];out[[i]]<-data.table::data.table(step=i-1L,ar_contribution=ar,residual_contribution=residuals[i],ma_contribution=ma,arma_error=total);es<-if(parameters@order==1L)total else c(total,es[-parameters@order]);if(length(ma_parameters))rs<-if(length(ma_parameters)==1L)residuals[i]else c(residuals[i],rs[-length(rs)])};data.table::rbindlist(out)}
S7::method(response,ARParameterSet)<-function(x,...,ma_parameters=numeric(),steps=480L){q<-detect_ma_order(ma_parameters);b<-if(q)ma_parameters[seq_len(q)]else numeric();res<-numeric(steps);res[1]<-1;ARMAResponse(parameters=x,ma_parameters=b,series=forecast_arma(x,numeric(x@order),res,b,numeric(length(b))))}
#' Compare AR and ARMA response components
#'
#' Return long-format responses suitable for plotting the effect of adding MA
#' terms to a supplied AR parameter set.
#'
#' @param parameters An AR parameter object.
#' @param ma_parameters Numeric MA coefficients ordered from most recent to
#'   oldest residual. Use `numeric()` for an AR-only comparison.
#' @param steps Positive whole number of response timesteps.
#'
#' @returns A long `data.table` containing response step, value and component
#'   label.
#'
#' @examples
#' components <- response_components(
#'   default_ar_parameters(),
#'   ma_parameters = c(-0.5, -0.25),
#'   steps = 48L
#' )
#'
#' head(components)
#' @export
response_components<-function(parameters,ma_parameters=numeric(),steps=480L){q<-detect_ma_order(ma_parameters);b<-if(q)ma_parameters[seq_len(q)]else numeric();ar<-response(parameters,steps=steps)@series[,.(step=step,response=arma_error,component="AR")];both<-response(parameters,ma_parameters=b,steps=steps)@series[,.(step=step,response=arma_error,component="ARMA")];data.table::rbindlist(list(ar,both))}
