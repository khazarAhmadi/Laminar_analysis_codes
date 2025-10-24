#!/bin/bash

## This tiny snippet will create additional folders and copy the required data for running a custom MATLAB script which back-projects the surface .gii data back to anatomy space. 

cat folders_list.txt | while read line; do 
cd $line/functional/LME/nuisance-removed/
mkdir layers
mkdir Run{1..8}
for m in {1..8}; do mv afni_3dTproject/Run$m-withMean.nii.gz ../Run$m/; done 
cd ../../../..; done 
