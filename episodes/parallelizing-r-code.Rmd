---
title: 'Parallelizing your R code with `future`'
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How can you use HPCC resources to make your R code run faster?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Introduce the R package `future`
- Demonstrate some simple ways to parallelize your code with `foreach` and `future_lapply`
- Explain different parallelization backends

::::::::::::::::::::::::::::::::::::::::::::::::

## Basics of parallelization

The HPCC is made up of lots of computers that have processors with lots of cores.
Your laptop probably has a processor with 4-8 cores while the largest nodes on the HPCC have 128 cores.

All this said though, HPCC nodes are *not* inherently faster than standard computers.
In fact, having many cores in a processor usually comes at the cost of slightly slower processing speeds.
One of the primary benefits of running on the HPCC is that that you can speed up your throughput by doing many tasks at the same time on multiple processors, nodes, or both.
This is called running your code in *parallel*.

Except for a few exceptions (like linear algebra routines), this speedup isn't automatic!
You will need to make some changes to your code so it knows what resources to use and how to split up its execution across those resources.
We'll use the "[Futureverse](https://www.futureverse.org/)" of R packages to help us do this quickly.

## Writing code that runs on multiple cores

Let's start with a small example of some code that can be sped up by running in parallel.
In RStudio, create a new R Script and enter the following code:

```r
t <- proc.time()

x <- 1:10
z <- rep(NA, length(x))  # Preallocate the result vector

for(i in seq_along(x)) {
  Sys.sleep(0.5)
  z[i] <- sqrt(x[i])
}

print(proc.time() - t)

```

Create a new directory in your `r_workshop` project called `src` and save it as `src/test_sqrt.R`.
Click the Source button at the top of the editor window in RStudio, and see the output:

```output
   user  system elapsed 
  0.016   0.009   5.006
```

This means that it took about 5 seconds for the code to run.
Of course, this all came from us asking the code to sleep for half a second each loop iteration!
This is just to simulate a long running chunk of code that we might want to parallelize.

:::::::::::::::::::::::::::::::::::::: callout

## A digression on vectorization

Ignoring the `Sys.sleep(0.5)` part of our loop, if we just wanted the square root of all of the elements in `x`, we should never use a loop!
R thrives with vectorization, meaning that we can apply a function to a whole vector at once.
This will also trigger some of those linear algebra libraries that can auto-parallelize some of your code.

For example, compare

```r
t <- proc.time()

x <- 1:10
z <- rep(NA, length(x))  # Preallocate the result vector
for(i in seq_along(x)) {
z[i] <- sqrt(x[i])
}

print(proc.time() - t)
```

```output
   user  system elapsed 
  0.004   0.000   0.005 
```

to

```r
t <- proc.time()

x <- 1:10
z <- sqrt(x)

print(proc.time() - t)
```

```output
   user  system elapsed 
      0       0       0 
```

Not only is the vectorized code much cleaner, it's much faster too!

::::::::::::::::::::::::::::::::::::::::::::::

Let's parallelize this with a combination of the `foreach` and the `doFuture` packages.
Start a new R script with the following lines

```r
library(foreach)
library(doFuture)
plan(sequential)

t <- proc.time()

x <- 1:10
z <- foreach(xi = x) %dofuture% {
  Sys.sleep(0.5)
  sqrt(xi)
}

print(proc.time() - t)
```

and save as `src/test_sqrt_multisession.R`.

Notice that this is very close to our original code, but we made a few changes:

- We changed the `for` loop into a `foreach` statement.
    - The `xi = x` lets us iterate over `x` and use `xi` as an element rather than indexing.
    - The block that happens on each "iteration" is preceded by `%dofuture%`.
    This tells `foreach` how to run each of the iterations, and in this case, uses the `future` package behind the scenes.
- `z` is now the output of `foreach` statement rather than preallocated and subsequently changed on each iteration of the `for` loop.
Each element is the last result of the code block for each input `xi`.

Let's run the code:

```output
   user  system elapsed 
  0.050   0.012   5.051
```

Huh? It's slower!
Well, we forgot one thing.
We changed our code to get ready for parallelization, but we didn't say *how* we want to parallelize it.

Well, actually, we did.
The `plan(sequential)` line tells `future` that we want to run each loop iteration sequentially, i.e., the same exact way the original for loop works!
We just added some extra overhead of having the `future` package manage it for us.

### The multisession backend

To parallelize things, we change the plan.
There are a few options, but we'll start with the `multisession` plan.
Change `plan(sequential)` to `plan(multisession)` and run again:

```output
   user  system elapsed 
  0.646   0.019   2.642
```

Much better!
What future did behind the scenes is check how many cores we have allotted to our RStudio session with

```r
availableCores()
```

```output
cgroups.cpuset 
             8
```

and make that many R sessions in the background.
Each of these sessions gets a loop iteration to run, and when finished, if there are still more, it will run another one.

We can tell `future` to use a certain number of workers in the `plan`, which will override the number of cores.
Add the `workers` option to `plan(multisession)` like

```r
plan(multisession, workers = 5)
```

and rerun to get

```output
   user  system elapsed 
  0.327   0.010   1.923 
```

It's even faster! With five workers, each worker has exactly two iterations to work on, and we don't have the overhead of the three extra ones that wait around to do nothing.

### The multicore backend

In addition to a `multisession` plan, we can use the `multicore` plan to utilize all of our cores.
Instead of starting multiple R sessions, `future` forks the main process into as many processes as specified workers.
This generally has less overhead, and one major advantage is that all of the workers share the memory of the original process.
In the `multisession` plan, each worker copied the part of `x` it had to work on into new memory which can really add up for large inputs.
However, in the `multicore` case, since the memory is shared, it is not writable.

Unfortunately, the `multicore` plan is less stable in GUI environments like RStudio.
Thus, it can only be used in scripts [running from the command line](r-command-line.Rmd), so we will ignore it for now.

## Writing code that runs on multiple nodes

Now that we know how to make the most of the cores we reserved, how can we scale up further?
One of the major benefits of the HPCC is the fact that there are plenty of different nodes for you to run your code on!
With just a few changes to the `future` setup, we can transition from a "multicore" to "multinode" setup.

### The cluster backend

To use the `cluster` backend, you need a list of nodes you can access through SSH.
Usually, you would submit a SLURM job requesting multiple nodes and use these, but we will save that for [a future section](r-slurm-jobs.Rmd).

For now, we'll practice by using some development nodes.

Copy `src/test_sqrt_multisession.R` to `src/test_sqrt_cluster.R`, and replace the `plan` line with the following:

```r
hostnames <- c("dev-amd20", "dev-intel18")
plan(cluster, workers = hostnames)
```

When we run the code, we get:

```output
Error: there is no package called 'doFuture'
```

Hmm, something went wrong.
It turns out that `future` isn't always sure what's available on the hosts we pass it to build the cluster with.
We have to tell it what library path to use, and that it should set the working directory on each node to our current working directory.

```r
hostnames <- c("dev-amd20", "dev-intel18")
wd <- getwd()
setwd_cmd <- cat("setwd('", wd, "')", sep = "")
plan(cluster, workers = hostnames,
     rscript_libs = .libPaths(),
     rscript_startup = setwd_cmd)
```

Now let's run again:

```output
setwd('/mnt/ufs18/home-237/k0068027/r_workshop')   user  system elapsed 
  0.233   0.044   2.769 
```

The output is a little wonky because it runs the `rscript_startup` command, but we were still able to save some time!

### The batchtools_slurm backend

As we saw, using `cluster` plan can be tricky to get right.
A much easier way to advantage of multiple nodes is to use the `batchtools.slurm` backend.
This allows us to submit SLURM jobs for each iteration of our for loop.
The HPCC scheduler will then control where and when these jobs run, rather than you needing to provide that information ahead of time.

The simplest way to do this, is to use the `future.batchtools` package.
Copy `src/test_sqrt_multisession.R` to `src/test_sqrt_slurm.R`, load the `future.batchtool` package, and replace the `plan` section with the `batchtools_slurm` plan:

``` r
library(foreach)
library(doFuture)
library(future.batchtools)
plan(batchtools_slurm)
```

Running the code gives us

``` output
   user  system elapsed 
  6.916   2.083  39.614
```

So we experience a much longer wait...
But this make sense!
We just sent off ten SLURM jobs to sit in the HPCC queue, get started, do a tiny computation, shut down, and send back the result.

This is definitely *not* the kind of setting where we should use the `batchtools_slurm` backend, but imagine if the inside of the for loop was extremely resource intensive.
In this case, it might make sense to send each iteration off into its own job with its own reserved resources.

Speaking of which, what resources did we ask for in each of these submitted jobs?
We never specified anything.
The `future.batchtools` package comes with a set of default templates.
Here's the `slurm.tmpl` file in the `library/future.batchtools/templates` directory under our project directory:

``` bash
#!/bin/bash
######################################################################
# A batchtools launch script template for Slurm
#
# Author: Henrik Bengtsson 
######################################################################

#SBATCH --job-name=<%= job.name %>
#SBATCH --output=<%= log.file %>
#SBATCH --nodes=1
#SBATCH --time=00:05:00

## Resources needed:
<% if (length(resources) > 0) {
  opts <- unlist(resources, use.names = TRUE)
  opts <- sprintf("--%s=%s", names(opts), opts)
  opts <- paste(opts, collapse = " ") %>
#SBATCH <%= opts %>
<% } %>

## Launch R and evaluated the batchtools R job
Rscript -e 'batchtools::doJobCollection("<%= uri %>")'
```

Now, there are some parts that don't look like like a normal SLURM script, but we see that each SLURM job automatically requests one node and five minutes.
The remaining resources are set to the default values (usually 1 CPU and 750MB of memory).

What if you want to change these values?
The strange lines in the template SLURM script allow us to pass in extra resources when we set the `plan`.
For example, if you need each loop iteration to have 1GB of memory and 10 minutes of runtime, we can replace the `batchtools_slurm` line with

``` r
plan(batchtools_slurm, resources = list(mem = "1GB",
                                        time="00:10:00"))
```

The `resources` argument is a list where each entry's name is the SLURM constraint and the value is a string with the desired value.
See the [list of job specifications in the ICER documentation](https://docs.icer.msu.edu/List_of_Job_Specifications/) for more details.

Unfortunately, this method of specifying resources is not very flexible.
In particular, the resource names have to satisfy R's variable naming rules, which means that specifying `cpus-per-task` is impossible because of the dashes.

Alternatively, it is better to create your own template script that will be used to submit your jobs.
If you save a template like the one above to your working directory as `batchtools.slurm.tmpl`, it will be used instead.
For more information, see the [`future.batchtools` documentation](https://future.batchtools.futureverse.org/).

## Other ways to use the `future` backends

We decided to setup our parallelization in a for loop using the `foreach` package.
But there are a few other ways to do this as well.
Most fit the paradigm of defining a function to "map" over the elements in an array. 

One common example is using the `lapply` function in base R.
We could rewrite our example above using `lapply` (without any parallelization) like this:

``` r
slow_sqrt <- function(x) {
  Sys.sleep(0.5)
  sqrt(x)
}

x <- 1:10
z <- lapply(x, slow_sqrt)  # apply slow_sqrt to each element of x

```

To parallelize, we can use the `future.apply` package, replace `lapply` with `future_lapply`, and setup the backend exactly the same way:

``` r

library(future.apply)
plan(multisession, workers = 5)

slow_sqrt <- function(x) {
  Sys.sleep(0.5)
  sqrt(x)
}

x <- 1:10
z <- future_lapply(x, slow_sqrt)

```

The "[Futureverse](https://www.futureverse.org/)" (i.e., the list of packages related to `future`) also includes `furrr`, a `future`-ized version of the Tidyverse package `purrr`.
Additionally, the `doFuture` package contains adapters to parallelize `plyr` and `BiocParallel` mapping functions.

The upshot is that if you have code that's setup (or can be setup) in the style of mapping a function over arrays, you can parallelize it by employing an adapter to the `future` backend.

::::::::::::::::::::::::::::::::::::: keypoints 

- Setup code you want to parallelize as "mapping" a function over an array
- Setup a `future` backend to distribute each of these function applications over cores, nodes, or both
- Use the `batchtools_slurm` backend to have `future` submit SLURM jobs for you
- Use a `future` adapter to link your code to the backend

::::::::::::::::::::::::::::::::::::::::::::::::
