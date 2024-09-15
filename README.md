This repository contains several scripts for preprocessing and layerification of hippocampus from submillimeter fMRI data that are acquired @ 7 Tesla. The scripts call several functions from AFNI, FSL, ANTS, Hippunfold and to a lesser extent Freesurfer, SPM and ASHS. The codes are still under further development and will be cleaned up soon. The accompanying data will be uploaded in OSF platform.
An INV1 image from MP2RAGE sequence was used for segmentation of hippocampal subregions after being bias-field corrected and denoised using BM4D [1]. 'acompCor' was applied to fMRI data to account for physiological noise [2]. Additional details can be found in the 'Walk-through.odt'.
References:
1.	Lüsebrink, F., Mattern, H., Yakupov, R., Acosta-Cabronero, J., Ashtarayeh, M., Oeltze-Jafra, S., & Speck, O. (2021). Comprehensive ultrahigh resolution whole brain in vivo MRI dataset as a human phantom. Scientific Data, 8(1), 138.
2.	Behzadi, Y., Restom, K., Liau, J., & Liu, T. T. (2007). A component based noise correction method (CompCor) for BOLD and perfusion based fMRI. Neuroimage, 37(1), 90-101.

