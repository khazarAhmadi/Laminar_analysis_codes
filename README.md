# Laminar_analysis_codes
This repository contains several scripts for preprocessing and layerfication of hippocampus from submillimeter fMRI data acquired at 7 Tesla. The scripts call functions from multiple neuroimaging packages including SPM, FSL, ANTS and Hippunfold. 
It also uses the BM4D filter (1) for denoising of the structural image, based on the work of Lüsebrink et al., (2). Additionally, acompcor (component based noise correction method) is employed to mitigate the noise in the fMRI data (3). Detailed instructons on how to run the preprocessin script can be found in "HowTo-7T_registration_ANTs_V3.docx". To bin the hippocampal subfields across different depths, read "instructions.odt". The codes are still under further development and need to be cleaned up. 


References:
1. Maggioni, M., Katkovnik, V., Egiazarian, K., & Foi, A. (2012). Nonlocal transform-domain filter for volumetric data denoising and reconstruction. IEEE transactions on image processing, 22(1), 119-133.
2. Lüsebrink, F., Mattern, H., Yakupov, R., Acosta-Cabronero, J., Ashtarayeh, M., Oeltze-Jafra, S., & Speck, O. (2021). Comprehensive ultrahigh resolution whole brain in vivo MRI dataset as a human phantom. Scientific Data, 8(1), 138.
3. Behzadi, Y., Restom, K., Liau, J., & Liu, T. T. (2007). A component based noise correction method (CompCor) for BOLD and perfusion based fMRI. Neuroimage, 37(1), 90-101.
