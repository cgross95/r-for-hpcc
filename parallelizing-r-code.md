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
In fact, having many cores in a processor usually come at the cost of slightly slower processing speeds.
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
Add the following lines to the end of your `test_sqrt.R` script:

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

Notice that this is very close to our original code, but we made a few changes:

- We changed the `for` loop with a `foreach` statement.
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
We just added some extra overhead of using the extra packages.

### The multisession backend

To parallelize things, we change the plan.
There are a few options, but we'll start with the `multisession` plan.
Change the `plan(sequential)` to `plan(multisession)` and run again:

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

In addition to a `multisession` plan, we can also utilize all of our cores with the `multicore` plan.
Instead of starting multiple R sessions, `future` forks the main process into as many processes as specified workers.
This generally has less overhead, and one major advantage is that all of the workers share the memory of the original process.
In the `multisession` plan, each worker copied the bit of `x` it had to work on into new memory which can really add up for large inputs.
However, in the `multicore` case, since the memory is shared, it is not writable.

Unfortunately, the `multicore` plan is less stable in GUI environments like RStudio.
Thus, it can only be used in scripts [running from the command line](r-command-line.Rmd), so we will ignore it for now.

## Writing code that runs on multiple nodes

## The cluster backend

To use the `cluster` backend, you need a list of nodes you can access through SSH.
Usually, you would submit a SLURM job requesting multiple nodes and use these, but we will save that for [a future section](r-slurm-jobs.Rmd).

For now, we'll practice by using some development nodes.
Replace the `plan` line with the following:

```r
hostnames <- c("dev-amd20", "dev-intel18")
plan(cluster, workers = hostnames)
```

and run:

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

## The batchtools.slurm backend

::::::::::::::::::::::::::::::::::::: keypoints 

- Use `.md` files for episodes when you want static content
- Use `.Rmd` files for episodes when you need to generate output
- Run `sandpaper::check_lesson()` to identify any issues with your lesson
- Run `sandpaper::build_lesson()` to preview your lesson locally

::::::::::::::::::::::::::::::::::::::::::::::::

