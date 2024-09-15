%% This script calls VPF_create_hippocampus_layers and creates a structure with 30 bins in each hippocampal subregion and each time point 

folders = readcell('folders_list.txt');
rule = '1 2 3 4'; % 1 = sub, 2 = ca1, 3 = ca2, 4 = ca3 
N_layers = [20 10]; % extende another 10 bins beyond the inner surface to cover SRLM
N_run = 8;
for m = 1:length(folders)
    folders_comb{m,1} = convertStringsToChars(strcat(string(folders{m,1}),'_',folders{m,2},'_',...
    string(folders{m,3}),'_',folders{m,4},'_',folders{m,5}));
end 

for m = 1:length(folders_comb)
    cd(folders_comb{m,1})
    subject_id = m + 1;
    surf_path = fullfile(pwd,strcat('/structural/HUoutput-INV1based/hippunfold/sub-',sprintf('%04.0f',subject_id),'/surf'));
    T1_path = fullfile(pwd,strcat('/structural/HUoutput-INV1based/hippunfold/sub-',sprintf('%04.0f',subject_id),'/anat/',...
    'sub-',sprintf('%04.0f',subject_id),'_desc-preproc_T2w.nii'));
    for n = 1:N-run
        sampled_img = {fullfile(pwd,convertStringsToChars(strcat('/functional/LME/nuisance-removed/Run',...
            string(n),'/','Run',string(n),'-withMean.nii.gz')))};
        layers = VPF_create_hippocampus_layers(sampled_img,subject_id,surf_path,T1_path,N_layers,rule);
        cd (convertStringsToChars(strcat('/functional/LME/nuisance-removed/Run',string(n))));
        save('layers.mat','layers');
        cd ../
    end
    cd ../../../../
end