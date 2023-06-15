---
title: 'Managing R package installation and environment'
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How do you write a lesson using R Markdown and `{sandpaper}`?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Explain how to use markdown with the new lesson template
- Demonstrate how to include pieces of code, figures, and nested challenge blocks

::::::::::::::::::::::::::::::::::::::::::::::::

## Libraries

The HPCC has multiple versions of R installed, and many of those versions have a large number of R packages pre-installed.
But there will come a time when your workflow requires a new package that isn't already installed. For this, you can use R's built-in `install.packages` function.

Before we do that though, we should check which libraries we have access to.
We can do this by typing `.libPaths()` into the R console:

```r
.libPaths()
```
```output
[1] "/opt/software/R/4.0.3-foss-2020a/lib64/R/library"
```

Depending on whether you've used R before and some behind the scenes setup, the output may be different for you.
However, this directory should always be one entry in your `.libPaths()`, and points to all of the packages that are pre-installed on the HPCC.
When you use `install.packages()` in the future, by default, it will install to the first entry in your `.libPaths()`.

:::::::::::::::::::::::::::::::::: callout

## What's the difference between a library and a package?

A library is just a collection of packages.
When you use `library(<package>)`, you are telling R to look in your libraries for the desired package.
When you use `install.packages(<package>)`, you are telling R to install the desired package into the first library on your `.libPaths()`.

::::::::::::::::::::::::::::::::::::::::::

## Installing packages

Now, let's try to install a package:

```r
install.packages("cowsay")
```
```
Warning in install.packages :
  'lib = "/opt/software/R/4.0.3-foss-2020a/lib64/R/library"' is not writable
Would you like to use a personal library instead? (yes/No/cancel)
```

R detects that our first available library is not writable by users (this is because it's shared by everyone on the HPCC).
Instead, it offers to create a personal library for you and install the package there.
Type `yes`, and you will be asked to create a new personal library at the default location

```output
Would you like to create a personal library
‘~/R/x86_64-pc-linux-gnu-library/4.0’
to install packages into? (yes/No/cancel)
```

Type yes again, and this will become your new personal library.

:::::::::::::::::::::::::::: callout

## Do you already have a personal library?

If your `.libPaths()` had a local directory before the one in `/opt/software`, you won't need to follow the preceding steps.

::::::::::::::::::::::::::::::::::::


You will then be asked to select a CRAN mirror.
This is the location where the package is downloaded from.
Usually, `71` is a good choice for us because it's from the University of Michigan (closer means faster downloads).

R will download and install the package. We can now use it like normal! From the R console:

```r
library(cowsay)
say("Hello world!")
```
```output

 -------------- 
Hello world! 
 --------------
    \
      \
        \
            |\___/|
          ==) ^Y^ (==
            \  ^  /
             )=*=(
            /     \
            |     |
           /| | | |\
           \| | |_|/\
      jgs  //_// ___/
               \_)
  
```

## Managing your environment

Let's summarize what happened:

1. We installed a package.
2. The first location in `.libPaths()` wasn't writable.
3. So we created a personal library.
4. The new location was added to our `.libPaths()`

```r
.libPaths()
```
```output
[1] "/mnt/ufs18/home-237/k0068027/R/x86_64-pc-linux-gnu-library/4.0"
[2] "/opt/software/R/4.0.3-foss-2020a/lib64/R/library" 
```

What if in the future you don't want to use this default local library?
Or you want to use one with a different name?
R has an environment variable exactly for this: `R_LIBS_USER`!
If this environment variable is set before you start R, it will use the value as your personal library.
This means, it will show up first on `.libPaths()` and will be the default location for `install.packages` to use.

But how do we set it?
If we're running R from the command line (which we'll [talk about later](r-command-line.Rmd)), you can export this variable in the command line before you start R:

```bash
export R_LIBS_USER="~/Rlibs"
R
```

But not only will we have to do this every time we run R, this process is also hidden away behind the scenes when we use RStudio from OnDemand!
There's another option: the `.Renviron` file.
Before R starts up (no matter if it's from the command line or Rstudio), it will look at all the environment variables in this file and set them.

Let's practice. In RStudio, open a new Text File and type

```text
R_LIBS_USER="~/Rlibs"
```

Then save this file in your home directory with the name `.Renviron`.
Don't forget the leading `.`!

In the Session menu of RStudio, click Restart R. Now, let's check our `.libPaths()`:

```r
.libPaths()
```
```
[1] "/mnt/ufs18/home-237/k0068027/Rlibs"              
[2] "/opt/software/R/4.0.3-foss-2020a/lib64/R/library"
```

Our new library is first! If we try and load `cowsay`, it doesn't exist:

```r
library(cowsay)
```
```
Error in library(cowsay) : there is no package called 'cowsay'
```

This is because it's in the autogenerated personal library, not `~/Rlibs`.
However, we can install it into our new library with no problems.

Before we do that though, let's talk about another file that R looks at when it starts up: `.Rprofile`.
This file contains commands that R will run before anything you run.

Here's an example: setting the CRAN mirror is annoying to do every time.
We can do this before we install a package with the R command

```r
options(repos = "https://repo.miserver.it.umich.edu/cran/")
```

Let's put this in our `.Rprofile` so it automatically happens before any R session starts up.
As before, use RStudio to open a new Text File and type

```text
local({
  options(repos = "https://repo.miserver.it.umich.edu/cran/")
})
```

The `local` part ensures that no output from code we write is available to us in the R session: just the options get set.
It's good practice to put any code you write in your `.Rprofile` in a call to `local` to keep R from accidentally loading any large objects which slows down startup.

Save this in your home directory as `.Rprofile` and restart R as before.
Now install `cowsay`:

```r
install.packages("cowsay")
```
```output
Installing package into '/mnt/ufs18/home-237/k0068027/Rlibs'
(as 'lib' is unspecified)
also installing the dependencies 'fortunes', 'rmsfact'
...
```

It installs into our specified personal library, and didn't ask for a mirror!

::::::::::::::::::::::::::::::::::::: challenge 

## Startup and shutdown code

The functions `.First` and `.Last` can be defined in the `.Rprofile` file to run any code before starting and after ending an R session respectively.
Define these functions so that R will print `### Hello <user> ###` at the beginning of an R session and `### Goodby <user> ###` at the end (where `<user>` is your username).

Restart your R session to test your solution.

As a bonus, use `Sys.getenv` and the `USER` environment variable to say hello and goodbye to whoever is using the `.Rprofile`.

:::::::::::::::::::::::: solution 

```r
.First <- function() cat("### Hello", Sys.getenv("USER"), "###\n")
.Last <- function() cat("### Goodbye", Sys.getenv("USER"), "###\n")
```

:::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::


:::::::::::::::::::::::::::::::::::::::challenge

## Back to basics

Keeping very specialized code in your `.Rprofile` and `.Renviron` files can make it harder to execute your code on other computers.
For now, move `.Rprofile` to `.Rprofile.bak` and `.Renviron` to `.Renviron.bak` so you're at a clean slate going forward.
In the future, you can reference the changes you've made in the `.bak` files and choose what to keep in your own files.

::::::::::::::::::::::::::::::::::::::::::::::::

## Project and package management

The `.Rprofile` and `.Renviron` files don't have to live in your home directory.
In fact, R checks for them in a set order:

1. In the directory where R is started.
2. In your home directory.
3. In a global directory where R is installed. On the HPCC, for version 4.0.3, this is the file `/opt/software/R/4.0.3-foss-2020a/lib64/R/etc/Renviron`.

This means that you can setup per project profile and environment files, and use them by starting R in those directories. However, RStudio usually starts R in your home directory. Instead, the most effective way to achieve this is through RStudio projects.

