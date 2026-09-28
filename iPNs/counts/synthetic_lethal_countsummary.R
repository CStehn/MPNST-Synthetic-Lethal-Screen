Sweave("synthetic_lethal_countsummary.Rnw");
library(tools);

texi2dvi("synthetic_lethal_countsummary.tex",pdf=TRUE);

