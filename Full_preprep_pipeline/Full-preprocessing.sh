#!/bin/bash

################################ Bash Script which takes care of preprocessing of fMRI data at 7T, based on scripts of Sriranga Kashyap. Requires ANTS, FSL, MATLAB, and presurfer to be installed in your system. Make sure that 'sk_ants_Realign_Estimate_KA.sh', 'sk_antsFineReg.sh', and 'sk_ants_Realign_Reslice.sh' are in the same directory as this script.     

## copying the data to designated folder
cat folders_list.txt | while read line; do  
cd $line/functional/AP
for f in *-AP-dummyRemoved-sliceRemove.nii.gz ; do cp $f ../preprocess_output_complete/$f ; done
cd ../PA
for n in *-PA-dummyRemoved-sliceRemove.nii.gz; do cp $n ../preprocess_output_complete/$n ; done; 

cd ../../
cp structural/T1/MP2RAGE-UNI.nii.gz functional/preprocess_output_complete/ # copy UNI and INV2 images from the MP2RAGE acquisition to designated folder
cp structural/T1/MP2RAGE-INV2.nii.gz functional/preprocess_output_complete/
cd ../; done 

while IFS= read -r line1 && IFS= read -r line2 <&3; do  # copy data from sessions 2 a well
cd $line1/AP/
for ff in *-AP-dummyRemoved-sliceRemove.nii.gz ; do cp $ff ../../$line2/functional/preprocess_output_complete/$ff ; done
cd ../PA
for nn in *-PA-dummyRemoved-sliceRemove.nii.gz; do cp $nn ../../$line2/functional/preprocess_output_complete/$nn ; done
cd ../../; done < Sessions2s.txt 3< folders_list.txt 

## Create a mean image of the functional runs 
cat folders_list.txt | while read line; do 
cd $line/functional/preprocess_output_complete/

ls *-AP-dummyRemoved-sliceRemove.nii.gz |sed -Ee 's/\x1b\[[0-9;]+m//g' > AP-list.txt
cat AP-list.txt | sed 's/.......$//' > AP-list-Noending.txt
cat AP-list-Noending.txt | while read line;do antsMotionCorr -d 3 -a "$line".nii.gz -o "$line"_avg.nii.gz ;done

ls *-PA-dummyRemoved-sliceRemove.nii.gz |sed -Ee 's/\x1b\[[0-9;]+m//g' > PA-list.txt
cat PA-list.txt | sed 's/.......$//' > PA-list-Noending.txt
cat PA-list-Noending.txt | while read line;do antsMotionCorr -d 3 -a "$line".nii.gz -o "$line"_avg.nii.gz ;done


## Perform distortion and motion correction on the data. n is number of threads (allocate higher number if you have more) and t is TR which is 2.5 s in our case. 8 is the number of fMRI data  
for b in {1..8}; do
./sk_ants_Realign_Estimate_KA.sh -n 28 -t 2.5 -a Run$b-AP-dummyRemoved-sliceRemove.nii.gz -b Run$b-PA-dummyRemoved-sliceRemove.nii.gz; done
 
## MPRAGize anatomy and obtain WM mask, based on functions from 'presurfer package'.
UNI='MP2RAGE-UNI.nii.gz'
INV2='MP2RAGE-INV2.nii.gz'
matlab -nodisplay -nodesktop -r "[mprageised_im, wmseg_im] = MPRAGEise('$UNI', '$INV2');quit"
 
## Coregister Run1 to MPRAGE image, and then align each functional run to the first run and finally co-register it to the MPRAGE image, using boundary-based registration and spline interpolation

flirt -dof 6 -interp spline -schedule /usr/local/fsl/etc/flirtsch/bbr.sch -ref MP2RAGE-UNI_MPRAGEised.nii.gz -in Run1-AP-dummyRemoved-sliceRemove_DistCorr_template0.nii.gz -omat Run1-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR.mat -out Run1-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR_Warped.nii.gz -wmseg MP2RAGE-UNI_MPRAGEised_WMmask.nii.gz 

for k in {2..8}; do # align the remaining runs to first run
./sk_antsFineReg.sh -f Run1-AP-dummyRemoved-sliceRemove_DistCorr_template0.nii.gz -m Run$k-AP-dummyRemoved-sliceRemove_DistCorr_template0.nii.gz -g Run1-AP-dummyRemoved-sliceRemove_fixedMask.nii.gz -n Run$k-AP-dummyRemoved-sliceRemove_fixedMask.nii.gz -x 1;done

flirt -dof 6 -interp spline -schedule /usr/local/fsl/etc/flirtsch/bbr.sch -ref MP2RAGE-UNI_MPRAGEised.nii.gz -in Run2-AP-dummyRemoved-sliceRemove_DistCorr_template0.nii.gz -omat Run2-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR.mat -out Run2-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR_Warped.nii.gz -wmseg MP2RAGE-UNI_MPRAGEised_WMmask.nii.gz # Here, I do this separately for run2 because it has been acquired on the same day and immediately after run 1 while run 3-8 were acquired on a 2nd day, so registration involves an additional step. See below

for kk in {3..8}; do
c3d_affine_tool -ref Run1-AP-dummyRemoved-sliceRemove_DistCorr_template0.nii.gz -src Run$kk-AP-dummyRemoved-sliceRemove_DistCorr_template0.nii.gz -itk Run$kk-AP-dummyRemoved-sliceRemove_DistCorr_template0_antsFineReg_0GenericAffine.mat -ras2fsl -o Run$kk-AP-dummyRemoved-sliceRemove_DistCorr_template0_antsFineReg_ITK-to-FSL.mat

convert_xfm -omat run$kk-to-run1_fslBBR_init.mat -concat Run1-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR.mat Run$kk-AP-dummyRemoved-sliceRemove_DistCorr_template0_antsFineReg_ITK-to-FSL.mat

flirt -dof 6 -interp spline -schedule /usr/local/fsl/etc/flirtsch/bbr.sch -ref MP2RAGE-UNI_MPRAGEised.nii.gz -in Run$kk-AP-dummyRemoved-sliceRemove_DistCorr_template0.nii.gz -omat Run$kk-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR.mat -out Run$kk-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR_Warped.nii.gz -wmseg MP2RAGE-UNI_MPRAGEised_WMmask.nii.gz -init run$kk-to-run1_fslBBR_init.mat;done

## Convert FSL-based transfomation matrix to ITK-based matrix.
for j in {1..8}; do
c3d_affine_tool Run$j-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR.mat -ref MP2RAGE-UNI_MPRAGEised.nii.gz -src Run$j-AP-dummyRemoved-sliceRemove_DistCorr_template0.nii.gz -fsl2ras -oitk Run$j-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR-to-ITK.mat;done

## Reslice the coregistered functional images. This spits out 2 outputs one in the functiona space and the other zero-padded image in anatomy space 
./sk_ants_Realign_Reslice.sh -x Run1-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR-to-ITK.mat -f MP2RAGE-UNI_MPRAGEised.nii.gz -t 2.5 -n 20 -a Run1-AP-dummyRemoved-sliceRemove.nii.gz

for yy in {2..8}; do

./sk_ants_Realign_Reslice.sh -r Run1-AP-dummyRemoved-sliceRemove_DistCorr_template0.nii.gz -u Run$yy-AP-dummyRemoved-sliceRemove_DistCorr_template0_antsFineReg_0GenericAffine.mat -f MP2RAGE-UNI_MPRAGEised.nii.gz -x Run$yy-AP-dummyRemoved-sliceRemove_DistCorr_template0_fslBBR-to-ITK.mat -t 2.5 -n 20 -a Run$yy-AP-dummyRemoved-sliceRemove.nii.gz;done 

## remove all the .txt files
rm *.txt;

cd ../../../; done 
