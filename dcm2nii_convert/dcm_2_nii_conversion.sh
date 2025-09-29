#!/bin/bash
# little snippet for .dcm to .nii cnoversion using .dcm2niix and folder organization 
cat folders_list.txt | while read line; do 
cd $line/
mkdir functional 
mkdir -p structural/T1 structural/T2

## start by converting MP2RAGE data
dcm2niix -f "%f_%p_%t_%s" -p n -z y -o structural/T1 MP2RAGE_FATNAVS_0_75ISO_INV1_0004/ # note that input path may differ in your case. Adjust it accordingly. 

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o structural/T1 MP2RAGE_FATNAVS_0_75ISO_INV2_0005/

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o structural/T1 MP2RAGE_FATNAVS_0_75ISO_UNI_IMAGES_0006/
# rename them
mv structural/T1/MP2RAGE_FATNAVS_0_75ISO_INV1_0004_MP2RAGE_fatnavs_0.75iso_20220526090137_4.nii.gz structural/T1/MP2RAGE-INV1.nii.gz
mv structural/T1/MP2RAGE_FATNAVS_0_75ISO_INV1_0004_MP2RAGE_fatnavs_0.75iso_20220526090137_4.json structural/T1/MP2RAGE-INV1.json
mv structural/T1/MP2RAGE_FATNAVS_0_75ISO_INV2_0005_MP2RAGE_fatnavs_0.75iso_20220526090137_5.nii.gz structural/T1/MP2RAGE-INV2.nii.gz
mv structural/T1/MP2RAGE_FATNAVS_0_75ISO_INV2_0005_MP2RAGE_fatnavs_0.75iso_20220526090137_5.json structural/T1/MP2RAGE-INV2.json
mv structural/T1/MP2RAGE_FATNAVS_0_75ISO_UNI_IMAGES_0006_MP2RAGE_fatnavs_0.75iso_20220526090137_6.nii.gz structural/T1/MP2RAGE-UNI.nii.gz
mv structural/T1/MP2RAGE_FATNAVS_0_75ISO_UNI_IMAGES_0006_MP2RAGE_fatnavs_0.75iso_20220526090137_6.json structural/T1/MP2RAGE-UNI.json
rm -r MP2RAGE_*

## now convert T2-weighted TSE images regquired by Hippunfold and ASHS for segmentation of MTL regions

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o structural/T2 TSE_HIPPOCAMPUS_CORONAL_255V_0007/ # note that input path may differ in your case. Adjust it accordingly. 

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o structural/T2 TSE_HIPPOCAMPUS_CORONAL_235V_0008/

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o structural/T2 TSE_HIPPOCAMPUS_CORONAL_215V_0009/

mv structural/T2/TSE_HIPPOCAMPUS_CORONAL_255V_0007_tse_hippocampus_coronal_255V_20220526090137_7.nii.gz structural/T2/TSE1.nii.gz
mv structural/T2/TSE_HIPPOCAMPUS_CORONAL_255V_0007_tse_hippocampus_coronal_255V_20220526090137_7.json structural/T2/TSE1.json
mv structural/T2/TSE_HIPPOCAMPUS_CORONAL_235V_0008_tse_hippocampus_coronal_235V_20220526090137_8.nii.gz structural/T2/TSE2.nii.gz
mv structural/T2/TSE_HIPPOCAMPUS_CORONAL_235V_0008_tse_hippocampus_coronal_235V_20220526090137_8.json structural/T2/TSE2.json
mv structural/T2/TSE_HIPPOCAMPUS_CORONAL_215V_0009_tse_hippocampus_coronal_215V_20220526090137_9.nii.gz structural/T2/TSE3.nii.gz
mv structural/T2/TSE_HIPPOCAMPUS_CORONAL_228V_215V_0009_tse_hippocampus_coronal_215V_20220526090137_9.json structural/T2/TSE3.json
rm -r TSE_HIPPOCAMPUS_*

## now convert fMRI data from day/session 1 which has 2 datasets with opposite phase-encoding direction
mkdir -p functional/AP functional/PA

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o functional/PA DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R1_E00_M_0010/ # note that input path may differ in your case. Adjust it accordingly. 

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o functional/AP DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R1_E00_M_0011/

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o functional/PA DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R2_E00_M_0012/

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o functional/AP DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R2_E00_M_0013/

mv functional/PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R1_E00_M_0010_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r1_20211027090655_10.nii.gz functional/PA/Run1-PA.nii.gz
mv functional/PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R1_E00_M_0010_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r1_20211027090655_10.json functional/PA/Run1-PA.json
mv functional/PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R2_E00_M_0012_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r2_20211027090655_12.nii.gz functional/PA/Run2-PA.nii.gz
mv functional/PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R2_E00_M_0012_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r2_20211027090655_12.json functional/PA/Run2-PA.json

mv functional/AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R1_E00_M_0011_dzne_ep3d_fmri_pat4_708PF_450vols_r1_20211027090655_11.nii.gz functional/AP/Run1-AP.nii.gz
mv functional/AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R1_E00_M_0011_dzne_ep3d_fmri_pat4_708PF_450vols_r1_20211027090655_11.json functional/AP/Run1-AP.json
mv functional/AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R2_E00_M_0013_dzne_ep3d_fmri_pat4_708PF_450vols_r2_20211027090655_13.nii.gz functional/AP/Run2-AP.nii.gz
mv functional/AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R2_E00_M_0013_dzne_ep3d_fmri_pat4_708PF_450vols_r2_20211027090655_13.json functional/AP/Run2-AP.json
rm -r DZNE_EP3D_* 
cd ../;
done

## convert the 6 remaining fMRI data from day/session 2
cat Sessions2s.txt | while read line; do
cd $line/
mkdir AP PA 
dcm2niix -f "%f_%p_%t_%s" -p n -z y -o PA DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R3_E00_M_0007 # note that input path may differ in your case. Adjust it accordingly. 

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o AP DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R3_E00_M_0008/

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o PA DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R4_E00_M_009/	

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o AP DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R4_E00_M_0010/

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o PA DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R5_E00_M_0011/	

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o AP DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R5_E00_M_0012/

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o PA DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R6_E00_M_0013/	

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o AP DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R6_E00_M_0014/

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o PA DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R7_E00_M_0015/	

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o AP DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R7_E00_M_0016/

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o PA DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R8_E00_M_0017/	

dcm2niix -f "%f_%p_%t_%s" -p n -z y -o AP DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R8_E00_M_0018/

mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R3_E00_M_0007_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r3_20220912094000_7.nii.gz PA/Run3-PA.nii.gz
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R3_E00_M_0007_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r3_20220912094000_7.json PA/Run3-PA.json
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R4_E00_M_0009_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r4_20220912094000_9.nii.gz PA/Run4-PA.nii.gz
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R4_E00_M_0009_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r4_20220912094000_9.json PA/Run4-PA.json
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R5_E00_M_0011_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r5_20220912094000_11.nii.gz PA/Run5-PA.nii.gz
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R5_E00_M_0011_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r5_20220912094000_11.json PA/Run5-PA.json
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R6_E00_M_0013_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r6_20220912094000_13.nii.gz PA/Run6-PA.nii.gz
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R6_E00_M_0013_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r6_20220912094000_13.json PA/Run6-PA.json
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R7_E00_M_0015_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r7_20220912094000_15.nii.gz PA/Run7-PA.nii.gz
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R7_E00_M_0015_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r7_20220912094000_15.json PA/Run7-PA.json
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R8_E00_M_0017_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r8_20220912094000_17.nii.gz PA/Run8-PA.nii.gz
mv PA/DZNE_EP3D_FMRI_PAT4_708PF_10VOLS_PA_R8_E00_M_0017_dzne_ep3d_fmri_pat4_708PF_10vols_PA_r8_20220912094000_17.json PA/Run8-PA.json

mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R3_E00_M_0008_dzne_ep3d_fmri_pat4_708PF_450vols_r3_20220912094000_8.nii.gz AP/Run3-AP.nii.gz
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R3_E00_M_0008_dzne_ep3d_fmri_pat4_708PF_450vols_r3_20220912094000_8.json AP/Run3-AP.json
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R4_E00_M_0010_dzne_ep3d_fmri_pat4_708PF_450vols_r4_20220912094000_10.nii.gz AP/Run4-AP.nii.gz
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R4_E00_M_0010_dzne_ep3d_fmri_pat4_708PF_450vols_r4_20220912094000_10.json AP/Run4-AP.json
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R5_E00_M_0012_dzne_ep3d_fmri_pat4_708PF_450vols_r5_20220912094000_12.nii.gz AP/Run5-AP.nii.gz
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R5_E00_M_0012_dzne_ep3d_fmri_pat4_708PF_450vols_r5_20220912094000_12.json AP/Run5-AP.json
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R6_E00_M_0014_dzne_ep3d_fmri_pat4_708PF_450vols_r6_20220912094000_14.nii.gz AP/Run6-AP.nii.gz
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R6_E00_M_0014_dzne_ep3d_fmri_pat4_708PF_450vols_r6_20220912094000_14.json AP/Run6-AP.json
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R7_E00_M_0016_dzne_ep3d_fmri_pat4_708PF_450vols_r7_20220912094000_16.nii.gz AP/Run7-AP.nii.gz
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R7_E00_M_0016_dzne_ep3d_fmri_pat4_708PF_450vols_r7_20220912094000_16.json AP/Run7-AP.json
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R8_E00_M_0018_dzne_ep3d_fmri_pat4_708PF_450vols_r8_20220912094000_18.nii.gz AP/Run8-AP.nii.gz
mv AP/DZNE_EP3D_FMRI_PAT4_708PF_450VOLS_R8_E00_M_0018_dzne_ep3d_fmri_pat4_708PF_450vols_r8_20220912094000_18.json AP/Run8-AP.json
rm -r DZNE_EP3D_*
cd ../;
done


