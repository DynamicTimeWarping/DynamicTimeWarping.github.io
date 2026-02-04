# *dtw*: Dynamic Time Warping in R

The [dtw](https://cran.r-project.org/package=dtw) package is part of
CRAN, the Comprehensive R Archive Network. The R version is the
reference implemenation of the algorithms.

## Installation

To install the latest stable version of the package,
issue the following command in the R console:  

```R
> install.packages("dtw")
```

This installs the official package from CRAN and is the only supported installation method. )Packages on conda-forge are maintained by third parties and are not supported.)

## Getting started

Begin from the installed documentation:  

```R
> library(dtw) 
> demo(dtw)
> ?dtw 
> ?plot.dtw
```


## Online documentation

The package manual pages can also be [browsed
online](https://www.rdocumentation.org/packages/dtw).

## Quickstart

    ## A noisy sine wave as query
    idx<-seq(0,6.28,len=100);
    query<-sin(idx)+runif(100)/10;
    
    ## A cosine is for template; sin and cos are offset by 25 samples
    template<-cos(idx)
    
    ## Find the best match with the canonical recursion formula
    library(dtw);
    alignment<-dtw(query,template,keep=TRUE);
    
    ## Display the warping curve, i.e. the alignment curve
    plot(alignment,type="threeway")
    
    ## Align and plot with the Rabiner-Juang type VI-c unsmoothed recursion
    plot(
        dtw(query,template,keep=TRUE,
            step=rabinerJuangStepPattern(6,"c")),
        type="twoway",offset=-2);
    
    ## See the recursion relation, as formula and diagram
    rabinerJuangStepPattern(6,"c")
    plot(rabinerJuangStepPattern(6,"c"))
    
    ## And much more!
	

[![](images/thumbs/thumb_example10.png)](images/11.html) &emsp; &emsp; &emsp;
 [Try online!](https://colab.research.google.com/github/DynamicTimeWarping/notebooks/blob/master/R_DTW_Quickstart.ipynb)


