Laminar Analysis Codes for Hippocampal fMRI

This repository contains a collection of scripts for preprocessing and layerification of the hippocampus using submillimeter BOLD-based fMRI data acquired at 7 Tesla.

The study focuses on investigating laminar profiles of hippocampal subfields during navigation in a virtual arena. The scripts leverage tools and functions from the following neuroimaging software packages:

AFNI

FSL

ANTs

HippUnfold

To a lesser extent: FreeSurfer, SPM, and ASHS

⚠️ The codebase is under active development.

Results have been presented at ISMRM 2024, and the corresponding manuscript is currently in preparation. The accompanying fMRI dataset will be made publicly available on the Open Science Framework (OSF) platform soon.

🧠 Image Processing Overview

An INV1 image from the MP2RAGE sequence was used for segmentation of hippocampal subregions. This image was:

Bias-field corrected

Denoised using the BM4D algorithm [1]

For fMRI preprocessing, aCompCor was applied to account for physiological noise components [2].

Additional instructions and processing details can be found in the Walk-through.odt document included in this repository.

References

1. Laminar profile of hippocampal subregions during spatial navigation. K Ahmadi, D Stawarczyk, V Pfaffenrot, CA Gomez, Z Patai, DG Norris, Axmacher, N. (2024). Proc Intl Soc Mag Reson Med 32 890. https://archive.ismrm.org/2024/0890.html

2. Pfaffenrot, V., Bouyeure, A., Gomes, C. A., Kashyap, S., Axmacher, N., & Norris, D. G. (2025). Characterizing BOLD activation patterns in the human hippocampus with laminar fMRI. Imaging Neuroscience, 3, imag_a_00532.

3. Lüsebrink, F., Mattern, H., Yakupov, R., Acosta-Cabronero, J., Ashtarayeh, M., Oeltze-Jafra, S., & Speck, O. (2021). Comprehensive ultrahigh resolution whole brain in vivo MRI dataset as a human phantom. Scientific Data, 8(1), 138.

4. Behzadi, Y., Restom, K., Liau, J., & Liu, T. T. (2007). A component based noise correction method (CompCor) for BOLD and perfusion based fMRI. NeuroImage, 37(1), 90–101.
