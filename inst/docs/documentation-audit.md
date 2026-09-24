# Documentation audit checklist

Every exported function should provide:

- a one-sentence purpose;
- enough context to explain when the function should be used;
- argument descriptions covering type, order, units, sign convention, length, missing-value rules and valid choices;
- a return-value description naming the important columns or accessors;
- at least one runnable example;
- links to related functions where they clarify a workflow.

After applying the patch, run `devtools::document()` and inspect `pkgdown::build_reference()` output.
