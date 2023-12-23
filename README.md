# CTN-2PM
Various functions/code written while doing my PhD at the Nedergaard lab for handling and processing data from a Bergamo Throlabs 2-photon microscope.

## Pre-processing 
_A collection of functions to convert ThorLabs imaging output into tiff-stacks and collect relevant metadata._
* `Thor2PM_tiff2stack.m`  - converts Thorlabs output directories with folders of single images + xml meta-data to 16-bit tiff stacks and excel tabular metadata(only most relevant metadata)
* `Thor2PM_tiff2stack_blackout.m` - Same as previous function but also removes all images from saved tiff-stack that are "blank" from PMTs being turned off for optogenetic stimulation etc. returns location and number of removed frames.

## Calibration
_A collection of functions relevant for testing the 2PM laser calibration, XYZ resolution and optimal filter sets for multiplex imaging._
* `laser_center_estimate.m` - function that takes in a z-stack of a fluorescent plate and returns the laser distribution in the objective and which mirrors to tweak to get a better laser "fill" of the objective.
* `laser_center_estimate.m` -   
