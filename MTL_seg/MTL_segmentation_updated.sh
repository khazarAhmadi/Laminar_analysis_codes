#!/bin/bash
# -------------------------------------------------------------------------
# Structural preprocessing pipeline: requires FSL, AFNI, ASHS and HippUnfold
# 1. Aligns second and third T2-weighted TSE images to the first image
# 2. Average & crop slices
# 3. Prepare inputs for HippUnfold (standard + INV1-based)
# 4. Run HippUnfold via Singularity
# 5. Run ASHS segmentation
# -------------------------------------------------------------------------

# ---------------- User-configurable paths ----------------
SIF_PATH="/home/kahmadi/khanlab_hippunfold_latest.sif"
ASHS_BIN="/home/kahmadi/ashs-fastashs_beta/bin/ashs_main.sh"
ASHS_ATLAS="/home/kahmadi/ashs-atlases"

# ---------------- Safety checks ----------------
if [[ ! -f "$SIF_PATH" ]]; then
  echo "❌ ERROR: HippUnfold Singularity image not found: $SIF_PATH"
  echo "update SIF_PATH in this script."
  exit 1
fi

if [[ ! -x "$ASHS_BIN" ]]; then
  echo "❌ ERROR: ASHS executable not found or not executable: $ASHS_BIN"
  exit 1
fi

if [[ ! -d "$ASHS_ATLAS" ]]; then
  echo "❌ ERROR: ASHS atlas directory not found: $ASHS_ATLAS"
  exit 1
fi

# ---------------- Main analysis ----------------

while IFS= read -r line1 && IFS= read -r line2 <&3; do 
cd $line1/structural/T2

flirt -in TSE2.nii.gz -ref TSE1.nii.gz -omat TSE2to1-motion.txt -out TSE2_realigned.nii.gz -v  # align the 2nd and 3rd T2-weighted TSE images to the 1st image

flirt -in TSE3.nii.gz -ref TSE1.nii.gz -omat TSE3to1-motion.txt -out TSE3_realigned.nii.gz -v 

echo "  Averaging TSE images..."  

3dMean -verbose -prefix TSE_averaged.nii.gz TSE1.nii.gz TSE2_realigned.nii.gz TSE3_realigned.nii.gz 

echo "  Removing one slice from top and and one from bottom slice..."
fslroi TSE_averaged.nii.gz TSE_averaged_SliceRemoved.nii.gz 0 -1 0 -1 1 38 
cd ../



echo "  Preparing HippUnfold input directories..."
mkdir -p HUinput/$line2/anat
mkdir HUoutput
mkdir -p HUinput_INV1/$line2/anat
mkdir HUoutput-INV1based

cp ../functional/preprocess_output_complete/MP2RAGE-UNI_MPRAGEised.nii.gz HUinput/$line2/anat/T1w.nii.gz # copy T1 and T2-TSE images to this directory to run Hippunfold on standard mode
cp T2/TSE_averaged_SliceRemoved.nii.gz HUinput/$line2/anat/T2w.nii.gz

cp T1/presurf_INV1/MP2RAGE-INV1_biascorrected_BM4D.nii HUinput_INV1/$line2/anat/T2w.nii.gz # copy the denoised and bias-field corrected short-TI T1 image that has a T2-like contrast, rename it as T2. This is needed for later layerification



singularity run -e "$SIF_PATH" HUinput/ HUoutput participant --modality T2w --t1-reg-template -p --cores all # Run Hippunfold using singularity in standard mode

singularity run -e "$SIF_PATH" HUinput_INV1/ HUoutput-INV1based participant -p --cores all --modality T2w # Run Hippunfolder using INV1 image which will be later used for layerification.

# once Hippunfold is run, navigate to HUoutput->hippunfold->sub00xx->anat load itk snap and view the cropped T2 weighted hippocampi and load the labels as a segmentation image 
 

### Now run ASHS for segmentation of adjacent MTL structures in addition to hippocampus


echo "  Running ASHS segmentation..."
mkdir ASHS_output

# for this you need to adjust the path with respect to your ASHS and its atlas directories
nohup "$ASHS_BIN" -P -I $line2 -d -a "$ASHS_ATLAS" -g HUinput/$line2/anat/T1w.nii.gz -f HUinput/$line2/anat/T2w.nii.gz -w ASHS_output 

cd ../../;
done < folders_list.txt 3< HippUnfold_numbering.txt
