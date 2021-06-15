# ACEVBM

### Why this?

I need my own VBM pipeline because,

- For some reason FSLVBM doesn't like some of my projects MRI
- Maybe I can integrate it into the main NI analysis pipeline
- I don't like/understand other people pipelines

### What it does?

Basically it takes the Freesurfer segmentation of every experiment and construct the gray matter (GM) from it. Then take the GM images and construct a template 
using ANTs script *antsMultivariateTemplateConstruction2.sh*. I tried to mimick the FSL name conventions so I can run *randomise* command in the same way at the end.

This is built on top of SLURM but I think the Worload Manager could be changed without any trouble if needed. Anyway, this is written with heavy paralelization and it is not intended to be ran into a single machine or similar environment

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
