---
title: 'Reference'
---

## Glossary

adapter (`future`)
: The way that your code calls `future` to run in parallel, usually by a small change like using `future_lapply` instead of `lapply`

backend (`future`)
: The way that `future` parallelizes your code, e.g., through multiple R sessions or submitting SLURM jobs

core or CPU
: The part of a computer that actually does the computing, often multiple on one computer can work simultaneously

HPCC
: High performance computing cluster

`.libPaths()`
: The `R` command that shows you where your packages are installed and loaded from

library
: A directory where R packages are stored

module
: The way that software is stored and loaded on the HPCC

node
: An entire computer, many of which are connected together to create the HPCC

[OnDemand](https://ondemand.hpcc.msu.edu)
: The website to access graphical HPCC programs like RStudio through your browser

package
: A collection of R code that you can load and use in your code

parallelization
: Running different parts of a program at the same time, the main way to speed up code through the HPCC

R
: A programming language, and a command to start an R interpreter on the command line

`.Renviron`
: The file that contains environment variables set when R starts

`.Rprofile`
: The file that contains R commands that run when R starts

`RScript`
: The command to run a list of R commands in a file (usually ending with `.R`) on the command line

RStudio
: An Integrated Development Environment (IDE) where you can write and run R code

RStudio Project
: A way to organize your R code in RStudio, facilitated through an `.RProj` file in a directory

SLURM
: The HPCC's batch manager
