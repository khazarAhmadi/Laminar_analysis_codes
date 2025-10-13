Laminar Analysis Codes for Hippocampal fMRI

This repository contains a collection of scripts for preprocessing and layerification of the hippocampus using submillimeter BOLD-based fMRI data acquired at 7 Tesla.

The study focuses on investigating laminar profiles of hippocampal subfields during navigation in a virtual arena. The scripts leverage tools and functions from the following neuroimaging software packages:

AFNI

FSL

ANTs

HippUnfold

and to a lesser extent: FreeSurfer, SPM, and ASHS

⚠️ The codebase is under active development.

Results have been presented at ISMRM 2024 [1], and the corresponding manuscript is currently in preparation. The accompanying fMRI dataset will be made publicly available on the Open Science Framework (OSF) platform soon.

🧠 Image Processing Overview

An INV1 image from the MP2RAGE sequence was used for segmentation of hippocampal subregions. This image was bias-field corrected and denoised using the BM4D algorithm [2]. Hippocampal layerification is performed in accordance with previous studies [3-4].  For fMRI preprocessing, aCompCor was applied to account for physiological noise components [5-6].

Additional instructions and processing details can be found in the Walk-through.odt document included in this repository.

References

1. Ahmadi, K., Stawarczyk, D., Pfaffenrot, V., Gomez, CA., Patai, Z., Norris, DG., Axmacher, N. (2024). Laminar profile of hippocampal subregions during spatial navigation. Proc Intl Soc Mag Reson Med 32 890. https://archive.ismrm.org/2024/0890.html

2. Lüsebrink, F., Mattern, H., Yakupov, R., Acosta-Cabronero, J., Ashtarayeh, M., Oeltze-Jafra, S., & Speck, O. (2021). Comprehensive ultrahigh resolution whole brain in vivo MRI dataset as a human phantom. Scientific Data, 8(1), 138.

3. Ahmadi, K., Swegle, S., Kashyap, S., Bouyeure, A., Bandettini, P., Axmacher, N., & Huber, L. (2025). Blood volume sensitive laminar fMRI with VASO in human hippocampus: Capabilities and biophysical challenges at clinical 7T scanners. bioRxiv, 2025-08.

4. Pfaffenrot, V., Bouyeure, A., Gomes, C. A., Kashyap, S., Axmacher, N., & Norris, D. G. (2025). Characterizing BOLD activation patterns in the human hippocampus with laminar fMRI. Imaging Neuroscience, 3, imag_a_00532.

5. Behzadi, Y., Restom, K., Liau, J., & Liu, T. T. (2007). A component based noise correction method (CompCor) for BOLD and perfusion based fMRI. NeuroImage, 37(1), 90–101.

6. Mascali, D., Moraschi, M., DiNuzzo, M., Tommasin, S., Fratini, M., Gili, T., ... & Giove, F. (2021). Evaluation of denoising strategies for task‐based functional connectivity: Equalizing residual motion artifacts between rest and cognitively demanding tasks. Human brain mapping, 42(6), 1805-1828.
