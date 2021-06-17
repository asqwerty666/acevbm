# ACEVBM

### Why this?

I need my own VBM pipeline because,

- For some reason FSLVBM doesn't like some of my projects MRI
- Maybe I can integrate it into the main NI analysis pipeline
- I don't like/understand other people pipelines

### What it does?

Basically it takes the Freesurfer segmentation of every experiment and construct the gray matter (GM) from it. Then take the GM images and construct a template 
using ANTs script *antsMultivariateTemplateConstruction2.sh*. This last was sligthly modified in order to allow a better control of SLURM jobs, using the *-p* (prepend) switch and *#SBATCH* directives. I tried to mimick the FSL name conventions so I can run *randomise* command in the same way at the end.

This is built on top of SLURM but I think the Workload Manager could be changed without any trouble if needed. Anyway, this is written with heavy paralelization and it is not intended to be ran into a single machine or similar environment.

### Dependencies

- SLURM :-D
- Freesurfer
- FSL
- ANTs
- Perl modules
  - File::Temp
  - File::Find::Rule
  - Cwd
  - File::Basename

### Install

First, you need to define the BASH variable **$PIPEDIR**, pointing to wherever your pipeline is. Then the shell and perl scripts should be copied into **$PIPEDIR/bin/** and the standard gray template file (*avg_gray_inMNI.nii.gz*) into **$PIPEDIR/lib/**. Also the *SLURM.pm* file need to be copied into a place where it can be found by your Perl environment and the *antsMultivariateTemplateConstruction2_alt.sh* should be copied to **$ANTS\_PATH**.

and *That's all Folks!*

### How to run

Basically you need a comma separated paired list of subject's IDs and Freesurfer's IDs. Something like,


0001,bert \
0002,murphy \
0003,lena \
...


where *bert*, *murphy* and *lena* are the subjects located at Freesurfer *$SUBJECTDIR* and *0001*, *0002*, *0003* are whatever IDs you want to give it here.

Now, just run,

$ `mktpl.pl -i mylist.csv -o outputdir`

all the intermediate files will be stored into *outputdir* but the final templates will be in a new *stats* directory. So, final results get organized in a similar way to the known FSLVBM scripts would do.

After the script finish you will be able to execute FSL *randomise* command as usual.
