%% Add voxelwise temporal mean back to AFNI 3dTproject denoised outputs
% Purpose: Add the mean signal (over time) to denoised fMRI runs
% Dependencies: load_nifti, save_nifti (from FreeSurfer)
% Considering the large size of .nii files, this function is memory-intensive! To avoide system crash, it is recommended to run each subject separately from their corresponding directory.  

clear; clc;
N_runs = 8; % number of runs
base_dir = pwd; % current directory assumed to contain data folders

fprintf('=== Starting mean restoration for %d runs ===\n', N_runs);


%for n = 1:length(folders_comb)
 %   cd(strcat(folders_comb{n,1},'functional/LME/nuisance-removed/'))
    for m = 1:N_runs
    	printf('\n[Run %d] Processing...\n', run);
        a = load_nifti(convertStringsToChars(strcat('Run',string(m),'-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii.gz')));
        fourthDim = size(a.vol);
        b = reshape(a.vol,[],fourthDim(4));
        c = mean(b,2);
        F = load_nifti(convertStringsToChars(strcat('afni_3dTproject/','Run',string(m),'-denoised.nii.gz')));
        e = reshape(c,[fourthDim(1:3)]);
        mean_back = F.vol + e;
        FF = load_nifti(convertStringsToChars(strcat('afni_3dTproject/','Run',string(m),'-denoised.nii.gz')),1);
        FF.vol = mean_back;
        cd afni_3dTproject/
        save_nifti(FF,convertStringsToChars(strcat('Run',string(m),'-withMean.nii.gz')));
        cd ../
    end 
    %cd ../../../../
%end
