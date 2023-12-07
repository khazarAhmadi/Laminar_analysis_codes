
function [mprageised_im, wmseg_im, collected] = MPRAGEise(UNI, INV2, work_dir)

if nargin<3
    work_dir = pwd;
end

display(['Working directory is: ',work_dir])
cd(work_dir)
mprageised =  dir('*_MPRAGEised.nii.gz');
wmfile =  dir('*_WMmask.nii.gz');

collected = 0;
if all([~isempty(mprageised), ~isempty(wmfile)])
    mprageised_im = fullfile(work_dir,mprageised.name);
    wmseg_im = fullfile(work_dir,wmfile.name);
    collected=1;
    return;
end
fprintf('\n################################')
fprintf(['\n\nUNI is: ',UNI, '\n'])
fprintf(['\nINV2 is: ',INV2, '\n\n'])
fprintf('################################\nn')

UNI_out = presurf_MPRAGEise(INV2,UNI);
presurf_UNI(UNI_out)

UNI_out_gz = gzip(UNI_out);

% Copy *_MPRAGEised.nii.gz to root folder
[~,filename,ext]=fileparts(UNI_out_gz);
mprageised_im = fullfile(work_dir,[filename,ext]);
copyfile(UNI_out_gz{:}, mprageised_im);

% Copy *_MPRAGEised.nii.gz to root folder
wmfile = dir(fullfile('**/*WMmask.nii'));
wmfile_gz = gzip(fullfile(wmfile.folder,wmfile.name));
[~,filename,ext]=fileparts(wmfile_gz);
wmseg_im = fullfile(work_dir,[filename,ext]);
copyfile(wmfile_gz{:}, wmseg_im);
