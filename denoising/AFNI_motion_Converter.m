%% convert ANTS motion output in AFNI formaat (Roll, pitch, yaw, dS, dL, dP) 
% This will be later used for afni 3dTproject
%folders = readcell('folders_list.txt');
N_run = 8;
%for m = 1:length(folders)
  %  folders_comb{m,1} = convertStringsToChars(strcat(string(folders{m,1}),'_',folders{m,2},'_',...
 %   string(folders{m,3}),'_',folders{m,4},'_',folders{m,5}));
%end 
%for n = 1:length(folders_comb)
 %   cd(strcat(folders_comb{n,1},'functional/LME/nuisance-removed/'))
    for m = 1:N_runs
        a = readmatrix(strcat('Run',string(m),'-AP-dummyRemoved-sliceRemove_MoCorr.txt')); 
        b = [a(:,6),a(:,4),a(:,5),a(:,3),a(:,1),a(:,2)];
        writematrix(b,strcat('Run',string(m),'-Motion-AFNI-converted.txt'));   
    end
    %cd ../../../../
%end 
