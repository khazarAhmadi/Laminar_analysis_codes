% This scripts is meant to automatize the 'acompcor' function to remove
% non-bld signal from WM and csf. 
%folders = readcell('folders_list.txt');
N_run = 8;
%for m = 1:length(folders)
 %   folders_comb{m,1} = convertStringsToChars(strcat(string(folders{m,1}),'_',folders{m,2},'_',...
  %  string(folders{m,3}),'_',folders{m,4},'_',folders{m,5}));
%end 
%for n = 1:length(folders_comb)
    for m = 1:N_run
        %data{n,m} = strcat(folders_comb{n,1},'functional/LME/nuisance-removed/unzip-nii/','Run',string(m),'-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii');
        data{1,m} = strcat('unzip-nii/','Run',string(m),'-AP-dummyRemoved-sliceRemove_MoCorr_DistCorr_anatomyAligned.nii');
    end
%end

%for n = 1:length(folders_comb)
    %rois{n,1} = strcat(folders_comb{n,1},'functional/LME/nuisance-removed/FAST-masks/csf_new_cropped_eroded.nii.gz'); 
    rois{1,1} = strcat('FAST-masks/csf_new_cropped_eroded.nii.gz');  
    %rois{n,2} = strcat(folders_comb{n,1},'functional/LME/nuisance-removed/FAST-masks/WM_new_cropped_bin_eroded.nii.gz'); 
    rois{1,2} = strcat('FAST-masks/WM_new_cropped_bin_eroded.nii.gz');  
%end
dime = [5 5]; % find 5 independent components for csf and another 5 components for wm
%for n = 1:length(folders_comb)
    for m = 1:N_run
        x{1,m} = fmri_compcor(convertStringsToChars(data{1,m}),rois(1,:),dime,'PolOrder', 1 );
    end
%end 

%for n = 1:length(folders_comb)
    for m = 1:N_runs
        %cd(strcat(folders_comb{n,1},'functional/LME/nuisance-removed/'))
        writematrix(x{1,m},strcat('Run',string(m),'-compcor-fixed5comps.txt'),'Delimiter','\t')
        %cd ../../../../
    end
%end
