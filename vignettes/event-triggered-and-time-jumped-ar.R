## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(collapse=TRUE,comment="#>",fig.width=9,fig.height=5.5)
library(reach.postproc)
library(data.table)
library(ggplot2)

## ----et-parameters------------------------------------------------------------
steady <- default_et_ar_steady_parameters()
event <- event_ar_parameters(response_time_steps = 48)
root_table(roots(steady, time_step_minutes = 15))
root_table(roots(event, time_step_minutes = 15))

## ----rainfall-trigger---------------------------------------------------------
rainfall <- c(rep(0,8),1,2,3,4,2,1,rep(0,34))
trigger <- rainfall_accumulation_trigger(rainfall,window_steps=8L,threshold=10)
config <- et_ar_configuration(steady,event,trigger,metadata=list(response_time_source="site assessment"))
simulation <- 0.7 + 1.2*exp(-((seq_along(rainfall)-25)/7)^2)
result <- forecast_et_ar(config,c(.2,.19,.18),simulation,time_step_minutes=15)
series <- et_ar_series(result)
ggplot(series,aes(lead_time_minutes/60,updated,colour=parameter_state))+geom_line()+geom_vline(xintercept=series$lead_time_minutes[result$switch_step]/60,linetype="dashed")+theme_minimal()+labs(x="Lead time, hours",y="Updated value",colour="Parameters")

## ----threshold-trigger--------------------------------------------------------
threshold_config <- et_ar_configuration(
  steady,event,
  updated_threshold_trigger(threshold=1.0,initial_value=.8,quantity="level")
)
threshold_result <- forecast_et_ar(threshold_config,c(.2,.19,.18),simulation)
et_ar_series(threshold_result)

## ----cwi-trigger--------------------------------------------------------------
cwi_rainfall_factor(c(120,125,145,165,170))
cwi_trigger <- cwi_adjusted_rainfall_trigger(rainfall,cwi=145,dry_threshold=20,window_steps=8L)

## ----tj-example---------------------------------------------------------------
set.seed(42)
history <- seq(.25,.08,length.out=40)+rnorm(40,0,.015)
tj <- forecast_tj_ar(default_ar_parameters(),history,jump=5L,steps=96L)
tj$selected_inputs
tj_ar_series(tj)

