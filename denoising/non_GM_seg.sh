#!/bin/bash

## This script segments the brain tissue into GM, CSF and WM mask with FSL FAST command, of which the latter two will be eroded and used in ICA-based 'acopmcor' for physiological noise reduction. 
## Requires FSL

cat folders_list.txt | while read line; do 
cd $line/structural/
mkdir FSL_fast 
cp ../functional/preprocess_output_complete/MP2RAGE-UNI_MPRAGEised.nii.gz FSL_fast/ # copy noise-removed UNI image 
cd FSL_fast/

bet MP2RAGE-UNI_MPRAGEised.nii.gz T1 -f 0.3
fast -n 3 -t 1 -o fast_T1 -b bias -B biasedRemoved T1.nii.gz
fslmaths fast_T1_pveseg.nii.gz -thr 1 -uthr 1 csf_new.nii.gz # get the mask of CSF and WM
fslmaths fast_T1_pveseg.nii.gz -thr 3 -uthr 3 WM_new.nii.gz

# We need to crop the WM, csf mask based on FOV of the fMRI data that is already aligned to anatomy
3dTstat -mean -prefix ../../functional/LME/nuisance-removed/Run1-mean.nii.gz ../../functional/LME/nuisance-removed/Run1-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii.gz # get the mean of 1st run
 
fslmaths WM_new.nii.gz -mas ../../functional/LME/nuisance-removed/Run1-mean.nii.gz -bin WM_new_cropped_bin.nii.gz # crop and binarize the masks 

fslmaths csf_new.nii.gz -mas ../../functional/LME/nuisance-removed/Run1-mean.nii.gz csf_new_cropped.nii.gz 

fslmaths WM_new_cropped_bin.nii.gz -kernel gauss 1 -ero WM_new_cropped_bin_eroded.nii.gz 
fslmaths csf_new_cropped.nii.gz -kernel gauss 1 -ero csf_new_cropped_eroded.nii.gz
# erode the mask, as sometimes few voxels are mislabeled and include the hippocampus mask. 
# Check the output visually, if the eroding has been too aggressive, reduce the threshold of gaussian kernel.  

cd ../../..
done 
