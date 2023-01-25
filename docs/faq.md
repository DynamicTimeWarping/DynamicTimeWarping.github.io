# Frequently asked questions

## General

### *How do I choose a step pattern?*

This question has been raised on Stack Overflow; see
[here](http://stackoverflow.com/questions/30247132/r-dtw-package-cumulative-cost-matrix-decreases-at-some-points-along-the-path),
[here](http://stats.stackexchange.com/questions/95920/searching-for-dynamic-time-warping-step-pattern)
and
[here](http://stackoverflow.com/questions/29399514/how-to-decide-which-steppattern-to-use-in-dtw-algorithm).
A good first guess is `symmetric2` (the default), i.e.

``` 
         g[i,j] = min(
             g[i-1,j-1] + 2 * d[i  ,j  ] ,
             g[i  ,j-1] +     d[i  ,j  ] ,
             g[i-1,j  ] +     d[i  ,j  ] ,
         )
```


### *What's all the fuss about normalization? What's wrong with the `symmetric1` recursion I found in Wikipedia/in another implementation?*

An alignment computed with a non-normalizable step pattern has two
serious drawbacks:

1.  It cannot be meaningfully normalized by timeseries length. Hence,
    longer timeseries have naturally higher distances, in turn making
    comparisons impossible.
2.  It favors diagonal steps, therefore it is not robust: two paths
    differing for a small local change (eg. horizontal+vertical step
    rather than diagonal) have very different costs.

This is discussed in section 3.2 of the [JSS
paper](http://www.jstatsoft.org/v31/i07/), section 4.2 of the [AIIM
paper](http://dx.doi.org/10.1016/j.artmed.2008.11.007), section 4.7 of
Rabiner and Juang's [Fundamentals of speech
recognition](http://www.worldcat.org/oclc/26674087) book, and
elsewhere. Make sure you familiarize yourself with those references.  
  
TLDR: just stick to the default `symmetric2` recursion and use the
value of `normalizedDistance`.



### *What about *derivative* dynamic time warping?*

That means that one aligns the derivatives of the inputs. Just use the command
[`diff`](http://stat.ethz.ch/R-manual/R-patched/library/base/html/diff.html) to preprocess
the timeseries.


### *Why do changes in `dist.method` appear to have no effect?*

Because it only makes a difference when aligning *multivariate*
timeseries. It specifies the "pointwise" or local distance used
(before the alignment) between the query feature *vector* at time *i*,
`query[i,]` and the reference feature *vector* at time *j*, `ref[j,]`
. Most distance functions coincide with the Euclidean distance in the
one-dimensional case. Note the following:

```r 
r<-matrix(runif(10),5)  # A 2-D timeseries of length 5
s<-matrix(runif(10),5)  # Ditto

myMethod<-"Manhattan" # Or anything else
al1<-dtw(r,s,dist.method=myMethod)              # Passing the two inputs
al2<-dtw(proxy::dist(r,s,method=myMethod))      # Equivalent, passing the distance matrix

all.equal(al1,al2) 
     
```

### *Can the time/memory requirements be relaxed?*

The first thing you should try is to set the `distance.only=TRUE`
parameter, which skips backtracing and some object copies. Second,
consider downsampling the input timeseries.



### *What is the relation between `dist` and `dtw`?* 

There are two *very different*, *totally unrelated* uses for `dist`.
This is explained at length in the paper, but let's summarize.

1.  If you have **two multivariate** timeseries, you can feed them to
    `dist` to obtain a *local distance matrix*. You then pass this
    matrix to dtw(). This is equivalent to passing the two matrices to
    the dtw() function and specifying a `dist.method` (see also the
    next question).
2.  If you have **many univariate** timeseries, instead of iterating
    over all pairs and applying dtw() to each, you may feed the lot
    (arranged as a matrix) to `proxy::dist` with `method="DTW"`. In this case
    your code does NOT explicitly call dtw(). This is equivalent to
    iterating over all pairs; it is also equivalent to using the
    `dtwDist` convenience function.


## Windowing

### How do I set custom windows?

The `window.type` argument may be passed a custom window function;
it must however accept vector arguments. The easiest solution is to
create a logical matrix of the same size as the cost matrix and wrap it 
as in the following example:

```r
win.f <- function(iw,jw,query.size, reference.size, window.size, ...) compare.window 
# Then use: dtw(x, y, window.type = win.f)
```

### Is it possible to force alignments to respect specific known control points?

Control points or matching pairs force alignment curves to pass through specific points. 
An alternative way to see them is that the matching control point define "epochs" which must match with each other. Control points can be enforced through a block-structured windowing function.
This can be coded rather simply with a window function like the following:

```r
win.f <- function (iw, jw, window_iw, window_jw,query.size,reference.size,...) 
  outer(window_iw, window_jw, FUN = "==")
# Then use: dtw(x, y, window.type = win.f)
```

Where `window_iw` and `window_jw` would be respectively vectors specifying
the epochs (as integers or factors) for the input timeseries. 
The result of the `outer` call can also be modified e.g. to  
enable some slack around the control points.
(Thanks to E. Jarochowska)

(Alternatively, perform several alignments for each interval separately).


## Clustering

### *Can I use the DTW distance to cluster timeseries?*

Of course. You need to start with a dissimilarity matrix, i.e. a
matrix holding in *i,j* the DTW distance between timeseries *i* and
*j*. This matrix is fed to the clustering functions. Obtaining the
dissimilarity matrix is done differently depending on whether your
timeseries are univariate or or multivariate: see the next questions.

### *How do I cluster univariate timeseries of homogeneous length?*

Arrange the timeseries (single-variate) in a matrix *as rows*. Make
sure you use a symmetric pattern. See
[dtwDist](http://www.rdocumentation.org/packages/dtw/functions/dtwDist).

### *How do I cluster *multiple* *multivariate* timeseries?*

You have to handle the loop yourself. Assuming you have data arranged
as `x[time,component,series]`, pseudocode would be:

```R 
 for (i in 1:N) { 
    for (j in 1:N) { 
        result[i,j] <- dtw( dist(x[,,i],x[,,j]), 
		                    distance.only=T )$normalizedDistance 
```

### *Can I compute a DTW-based dissimilarity matrix out of timeseries of different lengths?*

Either loop over the inputs yourself, or pad with NAs and use the
following code:

```R
    dtwOmitNA <-function (x,y)
    {
        a<-na.omit(x)
        b<-na.omit(y)
        return(dtw(a,b,distance.only=TRUE)$normalizedDistance)
    }
    
    ## create a new entry in the registry with two aliases
    pr_DB$set_entry(FUN = dtwOmitNA, names = c("dtwOmitNA"))
    
    d<-dist(dataset, method = "dtwOmitNA") 
```


## Non-discoveries

### *I've discovered a multidimensional/multivariate version of the DTW algorithm! Shall it be included in the package?*

Alas, most likely you haven't. DTW had been "multidimensional" since
its conception. Local distances are computed between *N*-dimensional
vectors; feature vectors have been extensively used in speech
recognition since the '70s (see e.g. things like MFCC, RASTA,
cepstrum, etc). Don't worry: several other people have "rediscovered"
multivariate DTW already. The *dtw* package supports the numerous
types of multi-dimensional local distances that the
[proxy](http://cran.r-project.org/web/packages/proxy/index.html)
package does, as explained in section 3.6 of the [paper in
JSS](http://www.jstatsoft.org/v31/i07/).

### *I've discovered a realtime/early detection version of the DTW algorithm!*

Alas, most likely you haven't. A natural solution for real-time
recognition of timeseries is "unconstrained DTW", which relaxes one or
both endpoint boundary conditions. To my knowledge, the algorithm was
published as early as 1978 by [Rabiner, Rosenberg, and
Levinson](http://dx.doi.org/10.1109/TASSP.1978.1163164) under the name
UE2-1: see e.g. the mini-review in ([Tormene and Giorgino,
2008](http://dx.doi.org/10.1016/j.artmed.2008.11.007)). Feel also free
to learn about the clever algorithms or expositions by [Sakurai et al.
(2007)](http://dx.doi.org/10.1109/ICDE.2007.368963); [Latecki
(2007)](http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=4470291);
[Mori et al. (2006)](http://dx.doi.org/10.1109/ICPR.2006.467);
[Smith-Waterman
(1981)](http://dx.doi.org/10.1016%2F0022-2836%2881%2990087-5);
[Rabiner and Schmidt
(1980)](http://dx.doi.org/10.1109/TASSP.1980.1163422); etc. Open-ended
alignments (at one or both ends) are available in the *dtw* package,
as described in section 3.5 of the [JSS
paper](http://www.jstatsoft.org/v31/i07/).

### *I've discovered a bug in your backtrack algorithm!*

Alas, most likely you haven't. Doing the backtracking step
may be a bit tricky and, in the general case, doing backtracking via
steepest descent on the cost matrix is incorrect. Here's a
counterexample:

```
> library(dtw) 
> dm<-matrix(10,4,4)+diag(rep(1,4))
> al<-dtw(dm,k=T,step=symmetric2)   
> al$localCostMatrix
      [,1] [,2] [,3] [,4]
[1,]  *11* *10*  10   10
[2,]   10   11  *10*  10
[3,]   10   10   11  *10*
[4,]   10   10   10  *11*
> al$costMatrix
      [,1] [,2] [,3] [,4]
[1,]  >11<  21   31   41
[2,]   21  >32<  41   51
[3,]   31   41  >52<  61
[4,]   41   51   61  >72<
      
```

The sum of costs along the correct warping path (above, marked with `*..*`),
starting from `[1,1]`, is 11+10+2\*10+2\*10+11 = 72, which is correct (`=g[4,4]`). 
If you follow a backtracking "steepest descent"  on the cost matrix 
(below, marked with `>..<`), you get the diagonal, with
a total cost of 11+2\*11+2\*11+2\*11=77, which is wrong.

