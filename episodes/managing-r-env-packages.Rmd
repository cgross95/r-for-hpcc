---
title: 'Managing R package installation and environment'
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How can you install and organize packages in R?
- What are some best practices for setting up a project on the HPCC?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Explain where packages are kept and how to customize the location
- Demonstrate how to setup an RStudio project
- Share ways to effectively organize your projects for collaboration

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
[1] "/cvmfs/pub_software.icer.msu.edu/software/R/4.0.3-foss-2020a/lib64/R/library"
```

Depending on whether you've used R before and some behind the scenes setup, the output may be different for you.
However, this directory (or one like, starting with `/opt/software`) should always be one entry in your `.libPaths()`, and points to all of the packages that are pre-installed on the HPCC.
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
  'lib = "/cvmfs/pub_software.icer.msu.edu/software/R/4.0.3-foss-2020a/lib64/R/library"' is not writable
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

If your `.libPaths()` had a local directory (that is, one you're allowed to write and read to) before the one in `/cvmfs` or `/opt/software`, you won't need to follow the preceding steps.

::::::::::::::::::::::::::::::::::::


You may then be asked to select a CRAN mirror.
This is the location where the package is downloaded from.
Usually, `71` is a good choice for us because it's from the University of Michigan (closer means faster downloads).

R will download and install the package. We can now use it like we normally would! From the R console:

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

:::::::::::::::::::::::::::::::::: callout

## Do your packages require external dependencies?

Often, packages will require some extra software to install, run, or both.
Getting external dependencies lined up correctly can be a big challenge, especially on the HPCC.
Here are some general tips:

1. Read the documentation for the package you're using and take note of any dependencies you need and their versions. This information is also included under SystemRequirements on a package's [CRAN](https://cran.r-project.org/) page.
2. Make sure that software is available before you try to install/use the R package. This could involve:
    - Loading it through the HPCC module system. **Note**: This is not possible (yet) in RStudio on the HPCC. You will have to [use R through the command line](r-command-line.Rmd).
    - Installing it yourself in a way that R can find it.
3. If a package's setup instructions suggest something like `sudo apt-get ...` or `sudo dnf install ...` under the Linux instructions, this is a sign that it needs external dependencies.
These methods won't work for installation on the HPCC; instead, look for and load HPCC modules for similar names.
4. Sometimes you'll need to load more than one module, but they will have dependencies that conflict with each other (or even R itself!).
In this case, [contact the research consultants at ICER](https://contact.icer.msu.edu) and we will do our best to help you out.

::::::::::::::::::::::::::::::::::::::::::

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

Here's an example: we can set the CRAN mirror (the location we download packages from) to be one hosted by the University of Michigan with the R command

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

The functions `.First` and `.Last` (that don't take any arguments) can be defined in the `.Rprofile` file to run any code before starting and after ending an R session respectively.
Define these functions so that R will print `### Hello <user> ###` at the beginning of an R session and `### Goodbye <user> ###` at the end (where `<user>` is your username).

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
3. In a global directory where R is installed. On the HPCC, for version 4.0.3, this is the file `$R_HOME/etc/Renviron` (you can check where `$R_HOME` is with `Sys.getenv("$R_HOME")`).

This means that you can setup per project profile and environment files, and use them by starting R in those directories. However, RStudio usually starts R in your home directory. Instead, the most effective way to achieve this is through RStudio Projects.

Start by creating an RStudio Project with button that looks like a plus sign on top of a cube near the Edit menu.

![](fig/rstudio-project-button.png){alt="The new RStudio Project button in RStudio"}

Select New Directory, then New Project from the options.
Under Directory name, use `r_workshop`, and make sure that it's a subdirectory of your home directory `~`.
We'll leave the other options alone for now, but note that RStudio will integrate nicely into a workflow using git and GitHub!
Click Create Project to finish.

Your new RStudio Project will be loaded. This means a few things:

1. A new session of R will be started in the project directory.
2. This directory will be your new working directory (check `getwd()`!).
3. The file browser has moved to this directory.
4. A file called `r_workshop.Rproj` has been created. This file saves some options for how you edit your project in RStudio.

At any time, you can navigate to your project directory in the RStudio file browser and click the `.Rproj` file to load up this project or any other.
Now that we have this set up, we could create a local `.Rprofile` or `.Renviron` file just for this project.

If you share your project, you can share any of these files as well (including your `.Rproj`) so others can use it too!

:::::::::::::::::::::::::::::::: challenge

## A mini package isolation solution

Suppose you're working on a project with some super special versions of packages that you don't want to mess up other packages that you'll use in other projects.
The right way to do this is with a package manager like [`packrat`](https://rstudio.github.io/packrat/) or the newer [`renv`](https://rstudio.github.io/renv/articles/renv.html).
But we'll create a quick approximation.

Set your `R_LIBS_USER` environment variable to point to a directory called `library` in your `r_workshop` directory.
Make sure that this **only** happens when you start R in your `r_workshop` directory, and not always!

Restart R, check your work with the `.libPaths()`, and install the following packages:

  - `future`
  - `doFuture`
  - `foreach`
- `future.batchtools`

These packages won't be available anywhere outside of this project.

:::::::::::::::::: solution

Create the file `~/r_workshop/.Renviron` with the following line

```text
R_LIBS_USER="./library"
```

Restarting R we check our library paths

```r
.libPaths()
```
```output
[1] "/mnt/ufs18/home-237/k0068027/r_workshop/library" 
[2] "/cvmfs/pub_software.icer.msu.edu/software/R/4.0.3-foss-2020a/lib64/R/library"
```

and see that our `library` directory is first.

If we install `future`, it goes into this directory:

```r
install.packages("future")
```
```output
Installing package into `/mnt/ufs18/home-237/k0068027/r_workshop/library`
(as `lib` is unspecified)
```
One important note: if you share a project like this with anyone in the future, **don't** share the library directory.
Other people may be using different operating systems that these downloaded packages won't work on, and libraries can grow in size very quickly!
So long as you share the setup files, they can download them on their own.
Again though, the better way is to use a package manager like `renv` and share the files with all of the necessary packages.

:::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::


## Best practices for a portable project (and when and how to break the rules)

It is very likely that you are not the only person working with your code:
there are other people in your lab or outside that you should be ready to share your analyses with.
There are a few ways to setup your R project to make things less painful to share.

And even if you're not collaborating, you're still sharing with future you!
Staying organized will help you return to an old project and get up and running faster.

Tips: 

- Don't leave `install.packages` commands in your scripts.
Run them from the R console, and document what you need so that others can install them themselves later.
Or better yet, get [a package isolation solution](https://rstudio.github.io/renv/articles/renv.html) to do it for you, as discussed above.
- Organize the files in your project into separate folders. A [commonly used setup](https://github.com/swcarpentry/good-enough-practices-in-scientific-computing/blob/gh-pages/good-enough-practices-for-scientific-computing.pdf) is something like
    - `data/` for raw data that you shouldn't ever change
    - `results/` for generated files and output (e.g., you should be able to delete this folder and exactly regenerate it from your code.)
    - `src/` for your code, like `.R` files
    - `bin/` for any other programs you need to run your analyses
    - `doc/` for text documents associated with your project
- Use relative paths inside your project.
Instead of using `C:\Users\me\Documents\lab_files\research\experiment1.csv`, put `experiment1.csv` into the `data/` directory in your project folder and only reference it as `data/experiment1.csv`.
- Reuse your code.
If you need to run the same analysis on two different inputs, don't copy your script and find-and-replace `data/experiment1.csv` with `data/experiment2.csv`.
Instead, structure your script as a function that takes a filename as input.
Then write a script that sources the script your function is in and calls that function with two different filenames.
- Separate the steps in your analyses into separate scripts (which ideally wrap the step into a function).
You can chain all of your scripts together in one `run_all.R` script that sets up your input files and runs each step on those inputs in order.

All of this being said, rules of thumb can always be broken, but you should have a really good reason to do so.
Oftentimes, using a supercomputer can be that reason.

For example, you may be using the HPCC to analyze some very large files that wouldn't be easy to share in a `data/` directory under your project.
Maybe these live in your group's research space on the HPCC so you don't have to copy them around.
In this case, it might make sense to use an absolute path to this file in your R scripts, e.g., `/mnt/research/my_lab/big_experiment/experiment1.csv`.

If you do decide to do this however, make sure you only do it one time (e.g., set this path to a variable one time and use that variable everywhere), and document where you do it!
This will make it easy to change if you do ever need to share or move your project or data.



::::::::::::::::::::::::::::::::::::: keypoints 

- The `.libPaths()` function shows you where R looks for and installs packages
- Set the `R_LIBS_USER` environment variable in the `.Renviron` file to change where R looks for and installs libraries
- Add functions and set options in the `.Rprofile` file to customize your R session
- Start R from your project directory and use relative paths

::::::::::::::::::::::::::::::::::::::::::::::::
