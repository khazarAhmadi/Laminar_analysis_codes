% This script applies bias-field correction and removes thermal noise from INV1 image using BMD4 filter.
%Requaires presurfer and bm4d.m from the following repository to be added to MATLAB path. Also, Freesurfer
%must be installed in your system. https://github.com/fluese/reconstructionPipeline (see also reference 4, in README). 
folders = readcell('../folders_list.txt');

for m = 1:length(folders)
    folders_comb{m,1} = convertStringsToChars(strcat(string(folders{m,1}),'_',folders{m,2},'_',...
   string(folders{m,3}),'_',folders{m,4},'_',folders{m,5}));
end 
load('BM4D_settings.mat')
for n = 1:length(folders_comb)
    cd(strcat(folders_comb{n,1},'/','structural','/','T1'))
    presurf_INV2('MP2RAGE-INV1.nii.gz'); % ok to pretend that INV1 is INV2 image...
    % This will generate a folder with multiple outputs including bias-field corrected image
    cd('/presurf_INV1')
    z = load_nifti('MP2RAGE-INV1_biascorrected.nii');
    z1 = load_nifti('MP2RAGE-INV1_biascorrected.nii',1); % load it without volume info
    [y_est, sigma_est] = bm4d(z.vol, settings);
    z1.vol = y_est;
    save_nifti(z1,'MP2RAGE-INV1_biascorrected_BM4D.nii');
    cd ../../../../
end
