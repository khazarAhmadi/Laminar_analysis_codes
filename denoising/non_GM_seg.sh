#!/bin/bash

## This script segments the brain tissue into GM, CSF and WM mask with FSL FAST command, of which the latter two will be eroded and used in ICA-based 'acopmcor' for removal of non-bold signal. 

cat folders_list.txt | while read line; do 
cd $line/structural/
mkdir FSL_fast 
do cp ../functional/preprocess_output_complete/MP2RAGE-UNI_MPRAGEised.nii.gz FSL_fast/ # copy noise-removed UNI image 
cd FSL_fast/
bet MP2RAGE-UNI_MPRAGEised.nii.gz T1 -f 0.3
fast -n 3 -t 1 -o fast_T1 -b bias -B biasedRemoved T1.nii.gz
fslmaths fast_T1_pveseg.nii.gz -uthr 1 csf_new.nii.gz # get the mask of CSF and WM
fslmaths fast_T1_pveseg.nii.gz -thr 3 WM_new.nii.gz
# We need to crop the WM, csf mask based on FOV of the fMRI data that is already aligned to anatomy
3dTstat -mean -prefix ../../functional/LME/nuisance-removed/Run1-mean.nii.gz ../../functional/LME/nuisance-removed/Run1-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii.gz # get the mean of 1st run
 
fslmaths WM_new.nii.gz -mas ../../functional/LME/nuisance-removed/Run1-mean.nii.gz WM_new_cropped.nii.gz # crop the masks 
fslmaths WM_new_cropped.nii.gz -bin WM_new_cropped_bin.nii.gz
fslmaths csf_new.nii.gz -mas ../../functional/LME/nuisance-removed/Run1-mean.nii.gz csf_new_cropped.nii.gz 

fslmaths WM_new_cropped_bin.nii.gz -kernel gauss 1 -ero WM_new_cropped_bin_eroded.nii.gz # erode the mask, as sometimes it penetrates inside the hippocampus mask. Check the output, if it has eroded too much, reduce the threshold. 
fslmaths csf_new_cropped.nii.gz -kernel gauss 1 -ero csf_new_cropped_eroded.nii.gz

