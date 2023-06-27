---
title: 'Submitting R code to SLURM'
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How do you write a SLURM submission script?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Explain the general structure of a SLURM script
- Explain how and why to request different resources with SLURM 
- Give sample template SLURM scripts for submitting R code

::::::::::::::::::::::::::::::::::::::::::::::::

## SLURM scripts

Now that we understand how to parallelize R code and run it on the command line, let's put it all together.
We'll write a SLURM script to submit our code to run on compute nodes on the HPCC.

We've already seen an [example of a SLURM script in the parallelization section](parallelizing-r-code.Rmd#the-batchtools_slurm-backend), where `future` was submitting SLURM jobs for us.
However, if we want to have more control, we'll have to understand how to write these ourselves.

The basic structure of a SLURM script can be split into three parts:

- The `#!/bin/bash` line
- Resources specifications
- Code you want to run (as if you're inputting it on the command line)

The `#!/bin/bash` line always needs to be there.
It just tells the system to run your code with `bash`, which is what you're using on the command line.

The second section is where we specify resources.
This is done using lines in the form

```bash
#SBATCH --option=<value>
```

The options let you specify things like

- The time you need to run your code, e.g., `#SBATCH --time=01:05:30` for 1 hour, 5 minutes, and 30 seconds
- The number of cores you want to run your code on, e.g., `#SBATCH --cpus-per-task=8` for 8 cores
- The number of nodes you need to run your code on, e.g., `#SBATCH --nodes=2` for 2 nodes
- The amount of memory your code will need, e.g., `#SBATCH --mem=10GB` for 10GB or ``--mem-per-cpu=750MB` for 750MB per core you ask for
- The SLURM account you want to use (if you have a buy-in node), e.g., `#SBATCH --account=my_buyin` to activate the buy-in nodes associated to the `my_buyin` account

Finally, you will add your code below these `#SBATCH`.
This code is exactly what you would enter on the command line to run your R scripts as we showed in the [previous epsiode](r-command-line.Rmd).

## A SLURM script template

``` bash
#!/bin/bash

#SBATCH --time=00:05:00  # 5 minutes
#SBATCH --cpus-per-task=1  # Use 1 core
#SBATCH --mem-per-cpu=500MB  # Use 500MB of memory per core requested
#SBATCH --nodes=1  # Use 1 node

# Load the R module
module purge
module load GCC/10.2.0 OpenMPI/4.0.5 R/4.0.3

# Get to our project directory
cd ~/r_workshop

# Run the script
Rscript src/test_sqrt.R
```

A template like this will work for you 90% of the time, where all you need to do is set your resources correctly, load the right version of R, set the directory you want to work in, and choose your script.

## SLURM script submission

Create a new directory in our R project directory called `slurm`, and save the above file there as `single_core.sh`.
Then submit the script with `sbatch`:

``` bash
sbatch slurm/single_core.sh
```

The script will sit in the queue until its resources are available.
We can check on its status with

``` bash
squeue --me
```

After the script has run, we can see its output in a file with a name like `slurm-<jobid>.out` in the current working directory.

``` bash
cat slurm-TBD.out
```

``` output
TBD
```

Congratulations!
We've just completed the workflow for submitting any job on the HPCC.

:::::::::::::::::::::::::::::::::::::: challenge

## Submitting a multicore job

Copy your submission script to `slurm/multi_core.sh`.
Adjust it to request five cores and change it so that you run `test_sqrt_parallel.R` with a `multicore` backend for `future` with five workers.
Submit the job and compare the time it took to run with the single core job.

::::::::::::::::::::::::: solution

`multi_core.sh`:

``` bash
#!/bin/bash

#SBATCH --time=00:05:00  # 5 minutes
#SBATCH --cpus-per-task=5  # Use 5 cores
#SBATCH --mem-per-cpu=500MB  # Use 500MB of memory per core requested
#SBATCH --nodes=1  # Use 1 node

# Load the R module
module purge
module load GCC/10.2.0 OpenMPI/4.0.5 R/4.0.3

# Get to our project directory
cd ~/r_workshop

# Run the script
Rscript src/test_sqrt_parallel.R
```

`test_sqrt_parallel.R`:

``` r
library(foreach)
library(doFuture)
plan(multicore, workers = 5)

t <- proc.time()

x <- 1:10
z <- foreach(xi = x) %dofuture% {
  Sys.sleep(0.5)
  sqrt(xi)
}

print(proc.time() - t)
```

::::::::::::::::::::::::::::::::::


## Cleaning up the output

Leaving the output in the directory we run the script in will get messy.
For the steps below, you will need the [list of SLURM job specifications](https://docs.icer.msu.edu/List_of_Job_Specifications/).

1. Create the directory `results` in your project directory.
2. For the previous job script, change the name for the job allocation to `multi_core-<jobid>` where `<jobid>` is the number that SLURM assigns your job.
3. Change it so the output and error files are stored in your project directory under `results/<jobname>.out` and `results/<jobname>.err` where `<jobname>` is the name you set in the previous step.

*Hint*: you can reference the job ID in `#SBATCH` lines with `%j` and the job name with `%x`.

::::::::::::::::::::::::: solution

`multi_core.sh`:

``` bash
#!/bin/bash

#SBATCH --time=00:05:00  # 5 minutes
#SBATCH --cpus-per-task=5  # Use 5 cores
#SBATCH --mem-per-cpu=500MB  # Use 500MB of memory per core requested
#SBATCH --nodes=1  # Use 1 node
#SBATCH --job-name=multi_core-%j
#SBATCH --output=~/r_workshop/results/%x.out
#SBATCH --error=~/r_workshop/results/%x.err

# Load the R module
module purge
module load GCC/10.2.0 OpenMPI/4.0.5 R/4.0.3

# Get to our project directory
cd ~/r_workshop

# Run the script
Rscript src/test_sqrt_parallel.R
```

::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::

## Submitting SLURM scripts for code that runs on multiple nodes

### Using the `future` package

In the section on writing parallel code across multiple nodes using the `future` package, we discussed two approaches: using the `cluster` backend, and having `future` submit SLURM jobs for you.
In the latter case, you would only need to submit your controller script to SLURM using a simple submission script like the one above.
The `batchtools_slurm` backend will submit SLURM jobs for the hard work that you want parallelized (though, as discussed, you may need to write a template script).

In the former case of using the `cluster` backend, we had to tell `future` which nodes we want it to run on.
Luckily `future` has SLURM in mind and can query the nodes available in your SLURM job with `parallelly:availableWorkers()`.
It automatically uses these as the `workers` when specifying the plan, so you can leave that argument out, specifying your plan like

``` r
hostnames <- c("dev-amd20", "dev-intel18")
wd <- getwd()
setwd_cmd <- cat("setwd('", wd, "')", sep = "")
plan(cluster,
     rscript_libs = .libPaths(),
     rscript_startup = setwd_cmd)
```

### For MPI jobs

MPI is a one of the most popular ways to write code in many languages that runs on multiple nodes.
You may write something that uses it explicitly (e.g., the [`Rmpi`](https://cran.r-project.org/web/packages/Rmpi/Rmpi.pdf) or [`pdbMPI`](https://cran.r-project.org/web/packages/pbdMPI/pbdMPI.pdf) packages), or implicitly, by using a package that uses MPI behind the scenes (e.g., [`doMPI`](https://cran.r-project.org/web/packages/doMPI/vignettes/doMPI.pdf)).

Any code using MPI must be called in a special way that lets the code know about the environment it's running on.
Practically, this means that you need to preface the `Rscript` command with `srun` with the option `--cpus-per-task` so MPI knows how many CPUs it can use per task.

Here is an example script:

``` bash
#!/bin/bash

#SBATCH --time=00:10:00  # 10 minutes
#SBATCH --tasks=6  # MPI will start 6 versions of the program
#SBATCH --cpus-per-task=8  # Use 8 cores per task (48 in total)
#SBATCH --mem-per-cpu=1GB  # Use 1GB of memory per core requested
#SBATCH --nodes=2  # Distribute the tasks across 2 nodes

# Load the R module
module purge
module load GCC/10.2.0 OpenMPI/4.0.5 R/4.0.3

# Get to our project directory
cd ~/r_workshop

# Run the script
srun --cpus-per-task=$SLURM_CPUS_PER_TASK Rscript src/some_MPI_script.R
```

Notice that we added an `#SBATCH` line for `tasks` and used the `$SLURM_CPUS_PER_TASK` variable to set the option for `srun`.
This ensures that whatever we set in the `#SBATCH --cpus-per-task` line will be used by `srun`.

::::::::::::::::::::::::::::::::::::: keypoints 

- A SLURM script requests resources
- Generally, the only code you need in a SLURM script is loading the R module, changing to the right directory and running your R code with `Rscript`
- Check the status of your jobs with `squeue --me`

::::::::::::::::::::::::::::::::::::::::::::::::

