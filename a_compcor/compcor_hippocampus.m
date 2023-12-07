clear;clc;
%create roi of bad regions due to heartbeat and breathing based on the residuals of a first-pass GLM

sub_id = 'P23';
mainpath = '/media/kahmadi/Elements1/DavidsData/20220214_P23_7123_S1_Struct';
statspath = '/home/pfaffenrot/work/postdoc/projects/ANT_workdir/rwls_stats/';
structpath =  fullfile(mainpath,'/structural/HUinput/sub-0023/anat/presurf_UNI/T1w_biascorrected_BM4D.nii');
mask_path = fullfile(mainpath,'/functional/preprocess_output_complete/Run1-AP-fixedMask-coregistered.nii.gz');
unfoldpath = fullfile(mainpath,'/structural/HUoutput-INV1based/hippunfold/sub-0023/anat'); 

%% 
%create hippocampus mask

hippo_mask_hdr = load_nifti([unfoldpath '/sub-0023_hemi-L_space-T2w_desc-subfields_atlas-bigbrain_dseg.nii.gz']);
hippo_mask_L = hippo_mask_hdr.vol>0;
hippo_mask_R = load_nifti([unfoldpath '/sub-0023_hemi-R_space-T2w_desc-subfields_atlas-bigbrain_dseg.nii.gz']).vol>0;

hippo_mask_L(hippo_mask_R>0) = hippo_mask_R(hippo_mask_R>0);
hippo_mask = imdilate(logical(hippo_mask_L),strel('disk',2));
hippo_mask_hdr.vol = hippo_mask;

save_nifti(hippo_mask_hdr,[unfoldpath '/hippo_mask.nii']);
%%
hippo_mask_path = [unfoldpath '/hippo_mask.nii'];

hdr = load_nifti([statspath 'ResMS.nii']);
ResMS = hdr.vol;

% ResMS(isnan(ResMS)) = 0;


roi = abs(ResMS)>3*std(ResMS(:),[],1,"omitnan");
hdr.vol = roi;

save_nifti(hdr,[statspath 'high_ResMS_mask.nii']);

%%
%bring the fixedmask of the ANTs layer pipeline into anatomical space and clean it up a little bit
transpath = '/home/pfaffenrot/work/postdoc/projects/ANT_workdir/custom_reg2anat.txt';

reslice_flags = struct('mask',0,'mean',0,'interp',4,'which',[2 0]);

trans = table2array(readtable(transpath));
trans = ea_antsmat2mat(str2num(trans{1,2})',str2num(trans{2,2})');

spm_get_space(mask_path,trans*spm_get_space(mask_path));
spm_reslice(cellstr(char(structpath,mask_path)),reslice_flags);

%%
[p,m,ext] = fileparts(mask_path); 
mask = load_nifti([p '/r' m ext]).vol;
% mask = load_nifti(mask_path).vol;
mask(abs(mask)<1e-3) = 0;
mask(isnan(mask)) = 0;
mask = logical(mask);

for ii = 1:size(mask,3)
    mask(:,:,ii) = imdilate(imfill(imclose(mask(:,:,ii),strel('disk',12)),'holes'),strel('disk',12)); 
end
%%
% load the data into memory. To save space, mask and vectorize them
runs = 3;
N    = 486;

load([statspath 'SPM.mat']);

%some voxels with high residuals might be within the hippocampus. It is essential to not incorporate them into acompcor.
%Hence, use a hippocampus mask based on hippounfold segmentations, dilate it a bit and mask out those hippocampus voxels.
roi(hippo_mask) = 0;
roi = roi(mask);
%%
for run = runs
%     mypath = ['/media/pfaffenrot/Elements/postdoc/projects/hippocampus_VASO/derivatives/pipeline/7512/ses-02/func/run' num2str(run) '/func/'];

mypath = [mainpath '/func/run' num2str(run) '/func/'];

    for vol = 1:N

        if vol == 1
            hdr = load_nifti([mypath 'mag_POCS_r' num2str(run) '_1' sprintf('%03d',vol-1) '_Warped-to-Anat.nii']);
            tmp = hdr.vol(mask);
            img = zeros(length(tmp),N);
            img(:,vol) = tmp;
            clear tmp
        else
            tmp = load_nifti([mypath 'mag_POCS_r' num2str(run) '_1' sprintf('%03d',vol-1) '_Warped-to-Anat.nii']).vol;
            img(:,vol) = tmp(mask);
        end
    end
    

%     confounds = SPM.xX.pKX([(1:8)+8*(run-1) 25+(run-1)],1+(run-1)*N:run*N);
    
    confounds = SPM.xX.pKX((3:8)+8*(run-1),1+(run-1)*N:run*N);


    X = fmri_compcor(img,{roi},0.5,'confounds',confounds');

    writematrix(X,[mypath 'compcor_motion_confounds.txt'],'Delimiter',' ')
end
