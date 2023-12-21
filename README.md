# CTN-2PM
Various functions/code written while doing my PhD at the Nedergaard lab for handling and processing data from a Bergamo Throlabs 2-photon microscope.

## Pre-processing 
Currently 2 functions here to convert Thorlabs directories with folders of single images + xml meta-data to 16-bit tiff stacks and excel tabular metadata(only most relevant metadata): 
* `Thor2PM2tiff.m`  - as described above
* `Thor2PM2tiff_blackout.m` - Same as previous function but also removes all images from saved tiff-stack that are "blank" from PMTs being turned off for optogenetic stimulation etc. returns location and number of removed frames.

## Calibration
