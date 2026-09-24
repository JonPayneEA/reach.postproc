test_that("defaults pass",{expect_true(assess(default_ar_parameters())@passed)})
test_that("root round trip works",{p<-default_ar_parameters();q<-roots_to_parameters(roots(p)@values);expect_equal(p@coefficients,q@coefficients,tolerance=1e-9)})
test_that("decomposition equals recurrence",{p<-default_ar_parameters();f<-forecast_ar(p,initial_errors=c(.2,.15,.1),steps=50);d<-decompose_ar(p,initial_errors=c(.2,.15,.1),steps=50);r<-d[,.(value=sum(contribution_real)),by=step];expect_equal(r$value,f@series$ar_error,tolerance=1e-9)})
test_that("unit circle is circular",{p<-plot_ar(roots(default_ar_parameters()));circle<-attr(p,"unit_circle_data");expect_equal(sqrt(circle$x^2+circle$y^2),rep(1,nrow(circle)),tolerance=1e-12)})
