# ACEVBM

### Why this?

I need my own VBM pipeline because,

- For some reason FSLVBM doesn't like some of my projects MRI
- Maybe I can integrate it into the main NI analysis pipeline
- I don't like/understand other people pipelines

### What it does?

Basically it takes the Freesurfer segmentation of every experiment and construct the gray matter (GM) from it. Then take the GM images and construct a template 
using ANTs script *antsMultivariateTemplateConstruction2.sh*. I tried to mimick the FSL name conventions so I can run *randomise* command in the same way at the end.

### Dependencies

- SLURM :-D
- FSL
- ANTs
- Perl modules
  - File::Temp
  - File::Find::Rule
  - Cwd
  - File::Basename

