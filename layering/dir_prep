#!/bin/bash

## This script will use the .gii files on surface boundaries of inner and outer hippocampus in a custom MATLAB script which back-projects the surface data back to anatomy space. 

cat folders_list.txt | while read line; do 
cd $line/functional/LME/nuisance-removed/
mkdir layers
mkdir Run{1..8}
for m in {1..8};do mv afni_3dTproject/Run$m-withMean.nii.gz ../Run$m/; done 
cd ../../../..; done 
