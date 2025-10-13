% This scripts is meant to automatize the 'acompcor' function to remove
% non-bld signal from WM and csf. Requires fmri_compcor.m afrom the following Github repository: https://github.com/dmascali/fmri_denoising. Add the whole folder to MATLAB path. The script will run in no-display mode and is called by 'nuisance_pipeline.sh' script. 

%folders = readcell('../folders_list.txt');
N_run = 8;
%for m = 1:length(folders)
 %   folders_comb{m,1} = convertStringsToChars(strcat(string(folders{m,1}),'_',folders{m,2},'_',...
  %  string(folders{m,3}),'_',folders{m,4},'_',folders{m,5}));
%end 

%for n = 1:length(folders_comb)
    for m = 1:N_run
        data{1,m} = fullfile('unzip-nii/','Run',string(m),'-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii');
    end
%end


rois{1,1} = fullfile('FAST-masks/csf_new_cropped_eroded.nii.gz');
rois{1,2} = fullfile('FAST-masks/WM_new_cropped_bin_eroded.nii.gz'); 

dime = [5 5]; % find 5 independent components for csf and another 5 components for wm

%for n = 1:length(folders_comb)
    for m = 1:N_run
        x{1,m} = fmri_compcor(convertStringsToChars(data{1,m}),rois(1,:),dime,'PolOrder', 1 );
        writematrix(x{1,m},strcat('Run',string(m),'-compcor-fixed5comps.txt'),'Delimiter','\t');
    end
%end 


