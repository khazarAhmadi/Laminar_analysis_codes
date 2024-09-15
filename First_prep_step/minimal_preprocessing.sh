#!/bin/bash

## This snippet does the first steps of preprocessing including discrarding dummy volumes (until the scanner reaches steady state) and removal of one slice from top and one from bottom. Requires AFNI and FSL packages to be installed in your machine. It calls AFNI 3dTcat for discarding the first 3 volumes and fslroi toget rid of corrupted slices. 

## Start with 1st session data
cat folders_list.txt | while read line; do 
cd $line/functional/AP/
# first preparation for dummy removal
find -maxdepth 1 -name 'Run*-AP.nii.gz' | sort > list-AP.txt
sed 's/$/'[3..$]'/' list-AP.txt > list-AP-updated.txt 
cat list-AP.txt | sed 's/.nii.gz.*/-dummyRemoved.nii.gz/' > list-AP-AFNI.txt
paste list-AP-AFNI.txt list-AP-updated.txt | while IFS="@" read -r f1 f2;do 3dTcat -prefix $f1 $f2; done 

# then discard the two slices
find -type f -name 'Run*-AP-dummyRemoved.nii.gz' | sort > list-AP-sliceRemoval.txt
cat list-AP-sliceRemoval.txt | sed 's/.nii.gz.*/-sliceRemove.nii.gz/' > list-fsl-sliceRemove-AP.txt
paste list-AP-sliceRemoval.txt list-fsl-sliceRemove-AP.txt | while IFS=@ read -r f1 f2;do fslroi $f1 $f2 0 -1 0 -1 1 38; done

# now do the same for data acquired in opposite PE direction
cd ../PA
find -maxdepth 1 -name 'Run*-PA.nii.gz' | sort > list-PA.txt
sed 's/$/'[3..$]'/' list-PA.txt > list-PA-updated.txt 
cat list-PA.txt | sed 's/.nii.gz.*/-dummyRemoved.nii.gz/' > list-PA-AFNI.txt
paste list-PA-AFNI.txt list-PA-updated.txt | while IFS="@" read -r f1 f2;do 3dTcat -prefix $f1 $f2; done 
 
find -type f -name 'Run*-PA-dummyRemoved.nii.gz' | sort > list-PA-sliceRemoval.txt
cat list-PA-sliceRemoval.txt | sed 's/.nii.gz.*/-sliceRemove.nii.gz/' > list-fsl-sliceRemove-PA.txt
paste list-PA-sliceRemoval.txt list-fsl-sliceRemove-PA.txt | while IFS=@ read -r f1 f2;do fslroi $f1 $f2 0 -1 0 -1 1 38; done
cd ../
mkdir preprocess_output_complete/ # create this folder to keep the outputs of whole-preprocessing steps including motion/distortion/alignment (see Full-preprocessing.sh)
cd ../../;done 


## repeat it for the data of the 2nd day/session acquisition
cat Sessions2s.txt | while read line; do
cd $line/AP/
find -maxdepth 1 -name 'Run*-AP.nii.gz' | sort > list-AP.txt
sed 's/$/'[3..$]'/' list-AP.txt > list-AP-updated.txt 
cat list-AP.txt | sed 's/.nii.gz.*/-dummyRemoved.nii.gz/' > list-AP-AFNI.txt
paste list-AP-AFNI.txt list-AP-updated.txt | while IFS="@" read -r f1 f2;do 3dTcat -prefix $f1 $f2; done 
find -type f -name 'Run*-AP-dummyRemoved.nii.gz' | sort > list-AP-sliceRemoval.txt
cat list-AP-sliceRemoval.txt | sed 's/.nii.gz.*/-sliceRemove.nii.gz/' > list-fsl-sliceRemove-AP.txt
paste list-AP-sliceRemoval.txt list-fsl-sliceRemove-AP.txt | while IFS=@ read -r f1 f2;do fslroi $f1 $f2 0 -1 0 -1 1 38; done

cd ../PA
find -maxdepth 1 -name 'Run*-PA.nii.gz' | sort > list-PA.txt
sed 's/$/'[3..$]'/' list-PA.txt > list-PA-updated.txt 
cat list-PA.txt | sed 's/.nii.gz.*/-dummyRemoved.nii.gz/' > list-PA-AFNI.txt
paste list-PA-AFNI.txt list-PA-updated.txt | while IFS="@" read -r f1 f2;do 3dTcat -prefix $f1 $f2; done 

find -type f -name 'Run*-PA-dummyRemoved.nii.gz' | sort > list-PA-sliceRemoval.txt
cat list-PA-sliceRemoval.txt | sed 's/.nii.gz.*/-sliceRemove.nii.gz/' > list-fsl-sliceRemove-PA.txt
paste list-PA-sliceRemoval.txt list-fsl-sliceRemove-PA.txt | while IFS=@ read -r f1 f2;do fslroi $f1 $f2 0 -1 0 -1 1 38; done

cd ../../; done 
