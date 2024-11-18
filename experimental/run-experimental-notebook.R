library(knitr)
library(here)

for (i in 1:140){
  knitr::knit(paste0(here::here(), "/experimental/Experiments-with-rayshader.Rmd"))
}

