#!/bin/bash
while IFS= read -r line1 && IFS= read -r line2 <&3; do 
cd $line1/structural/T2

flirt -in TSE2.nii.gz -ref TSE1.nii.gz -omat TSE2to1-motion.txt -out TSE2_realigned.nii.gz -v  # align the 2nd and 3rd T2-weighted TSE images to the 1st image

flirt -in TSE3.nii.gz -ref TSE1.nii.gz -omat TSE3to1-motion.txt -out TSE3_realigned.nii.gz -v   

3dMean -verbose -prefix TSE_averaged.nii.gz TSE1.nii.gz TSE2_realigned.nii.gz TSE3_realigned.nii.gz # get the averaged mean of all

fslroi TSE_averaged.nii.gz TSE_averaged_SliceRemoved.nii.gz 0 -1 0 -1 1 38 # discrard one slice from the top and one from bottom
cd ../


mkdir -p HUinput/$line2/anat
mkdir HUoutput
mkdir -p HUinput_INV1/$line2/anat
mkdir HUoutput-INV1based

cp ../functional/preprocess_output_trimed/MP2RAGE-UNI_MPRAGEised.nii.gz HUinput/$line2/anat/T1w.nii.gz # copy T1 and T2-TSE images to this directory to run Hippunfold on standard mode
cp T2/TSE_averaged_SliceRemoved.nii.gz HUinput/$line2/anat/T2w.nii.gz

cp T1/presurf_INV1/MP2RAGE-INV1_biascorrected_BM4D.nii HUinput_INV1/$line2/anat/T2w.nii.gz # copy the denoised and bias-field corrected short-TI T1 image that has a T2-like contrast, rename it as T2. This is needed for later layerification

singularity run -e khanlab_hippunfold_latest.sif HUinput/ HUoutput participant --modality T2w --t1-reg-template -p --cores all # Run Hippunfold using singularity in standard mode

singularity run -e khanlab_hippunfold_latest.sif HUinput_INV1/ HUoutput-INV1based participant -p --cores all --modality T2w # Run Hippunfolder for layerification

# once Hippunfold is run, navigate to HUoutput->hippunfold->sub00xx->anat load itk snap and view the cropped T2 weighted hippocampi and load the labels as a segmentation image 
 

### Now run ASHS for segmentation of adjacent MTL structures in addition to hippocampus

mkdir ASHS_output
# for this you need to adjust the path with respect to your ASHS and its atlas directories
nohup ../../../../../../home/kahmadi/ashs-fastashs_beta/bin/ashs_main.sh -P -I $line2 -d -a ../../../../../../home/kahmadi/ashs-atlases/ -g HUinput/$line2/anat/T1w.nii.gz -f HUinput/$line2/anat/T2w.nii.gz -w ASHS_output 

cd ../../;
 done < folders_list.txt 3< HippUnfold_numbering.txt
