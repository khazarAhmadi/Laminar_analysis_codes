% This snippet puts back the mean of each voxel over time to denoised
% outputs of AFNI 3dTproject
%% Note that I did not make this script to do the calculation for all runs and subjects because it gets memory-intensive and the code crashes. Better to use it individually. 
%folders = readcell('folders_list.txt');
N_run = 8;
%for m = 1:length(folders)
 %   folders_comb{m,1} = convertStringsToChars(strcat(string(folders{m,1}),'_',folders{m,2},'_',...
   % string(folders{m,3}),'_',folders{m,4},'_',folders{m,5}));
%end 
%for n = 1:length(folders_comb)
 %   cd(strcat(folders_comb{n,1},'functional/LME/nuisance-removed/'))
    for m = 1:N_runs
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
