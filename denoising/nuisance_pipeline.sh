#!/bin/bash

## This script generates denoised images of the fMRI data by detrending (temporal filtering), removal of motion estimates and  components of acompcor for singal in WM and csf. 
## Requires AFNI, MATLAB, SPM, and 'fmri_comcor.m' from fmri_denoising-master added to MATLAB path.  
## Author: Khazar Ahmadi

cat folders_list.txt | while read line; do 
cd $line/functional
mkdir -p LME/nuisance-removed/
mkdir afni_3dTproject
cp -r preprocess_output_complete/*-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii.gz LME/nuisance-removed/ 
cp -r preprocess_output_complete/*-AP-dummyRemoved-sliceRemove_MoCorr.params LME/nuisance-removed/ # copy and also rename motion estimates 
cd LME/nuisance-removed/

for l in {1..8};do # 8 is number of runs.
mv Run$l-AP-dummyRemoved-sliceRemove_MoCorr.params Run$l-AP-dummyRemoved-sliceRemove_MoCorr.txt;done # 8 number of runs 
mkdir FAST-masks
cp ../../structural/FSL_fast/WM_new_cropped_bin_eroded.nii.gz FAST-masks/
cp ../../structural/FSL_fast/csf_new_cropped_eroded.nii.gz FAST-masks/
mkdir unzip-nii

for a  in *.gz ; do gunzip -c $a > unzip-nii/`echo $a | sed s/.gz//`; done # acompcor depends on spm functions which does not handle .gz files. unzip the data, but it will be deleted later not to take additional disk space.

matlab -nodisplay -nodesktop -r "AFNI_motion_Converter;quit" ## change the columns of motion according to AFNI format
for l in {1..8};do mv Run$l-Motion-AFNI-converted.txt Run$l-Motion-AFNI-converted.1D; done

matlab -nodisplay -nodesktop -r "CompCor_Automatization;quit" 
## this line runs a MATLAB snippet to generate a matrix with size of number_of_time_points X 10 ICA components as text files, which will be used by afni 3dTproject command to detrend and denoise the fMRI data

rm -r unzip-nii
rm -r FAST-masks

for f in {1..8}; do 3dTproject -input Run$f-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii.gz -prefix afni_3dTproject/Run$f-denoised.nii.gz -polort 2 -ort Run$f-Motion-AFNI-converted.1D -ort Run$f-compcor-fixed5comps.txt; done 

## The output looks noisy, because '3dTproject' removes mean from the data. Using below MATLAB sniipet, the mean is put back into the data.

matlab -nodisplay -nodesktop -r "Denoised_wtihMean;quit"

echo "MATLAB processing finished"

## Get the tSNR of original and denoised data for later comparison ----> QUALITY CONTROL MEASURES

for n in {1..8}; do fslmaths Run$n-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii.gz -Tmean Run$n-mean.nii.gz ; fslmaths Run$n-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii.gz -Tstd Run$n-tstd.nii.gz; fslmaths Run$n-mean.nii.gz -div Run$n-tstd.nii.gz Run$n-tSNR.nii.gz; done

rm *-tstd.nii.gz 
rm *-mean.nii.gz

cd ../afni_3dTproject
for n in {1..8}; do fslmaths Run$n-withMean.nii.gz -Tmean Run$n-mean_afni.nii.gz; fslmaths Run$n-withMean.nii.gz -Tstd Run$n-tstd_afni.nii.gz; fslmaths Run$n-mean_afni.nii.gz -div Run$n-tstd_afni.nii.gz Run$n-tSNR_afni.nii.gz; done

rm *-mean_afni.nii.gz
rm *-tstd_afni.nii.gz

cd ../../../../../
done 
