% script for get layer profiles of CA1 and CA3 based on Viktor's updated 
% script
% get the average bins across hemispheres 
load('layers.mat');
layers(:,2) = [];
layers_avg = (layers{1,1}+layers{2,1})./2;
save('layers_Hemisphere_average.mat','layers_avg');
%% plot the profiles averaged across all time-points 
load('layers_Hemisphere_average.mat');
% If there are corrupted volumes, write them here and exclude them.
%corrupt = [278];
%layers_avg(:,corrupt,:) = [];
N_layers = 30;
for m = 1:N_layers
vols_avg_CA1(m) = mean(layers_avg(m,:,1));
end
for m = 1:N_layers
vols_avg_CA3(m) = mean(layers_avg(m,:,2));
end
%make the threshold line for distinguishing SRLM
%y_threshold = linspace(800,1300,30);
y_threshold = linspace(800,1300,30);
x_threshold(1,1:30) = 10; % 10th bin is where SRLM ends
x = 1:30;
names = {'SRLM','inner','outer'};
figure('color','w')
plot(x,vols_avg_CA1,'LineWidth',2,'Color','b');hold on
plot(x,vols_avg_CA3,'LineWidth',2,'Color','r');hold on
ylabel('BOLD baseline signal [a.u]');hold on
plot(x_threshold,y_threshold,'LineWidth',2,'Color','k','LineStyle','--');hold on
set(gca,'xtick',[3,11,30],'xticklabel',names);
legend('CA1','CA3','SRLM border');hold on
axis('square');
ax = gca;
ax.FontSize = 16;
%exportgraphics(gcf,'CA1-CA3-profiles-MeanOfAllVols.eps');
%% preparation to find the volumes index during navigation
clearvars -except N_layers layers_avg y_threshold x_threshold corrupt
cd ../../../../../../For_Khazar/P3
Run1 = readtable('Log_3_6.xlsx');
% get the correct time points
starting_vols = find(table2array(Run1(:,14)));
Run1(1:(starting_vols-1),:) = [];
Run1(:,15) = array2table(ceil(table2array(Run1(:,15))./2));
% get the navigation coordinates
navi_1 = find(strcmp(table2cell(Run1(:,7)),'Phase_NAVI_TimeNotOver')|...
strcmp(table2cell(Run1(:,7)),'Phase_NAVI_TimeOver')|...
strcmp(table2cell(Run1(:,7)),'Phase_REENCODING')|...
strcmp(table2cell(Run1(:,7)),'Phase_FEEDBACK')==1);
Run1_navi = Run1(navi_1,:);
not_moving = find(table2array(Run1_navi(:,8))==0);
Run1_navi(not_moving,:) = []; % get rid of initial zeros 
objnr = unique(table2array(Run1_navi(:,16)),'stable'); % stable -> returns values without sorting 
for j = 1:length(objnr)
    objects_1{j} = Run1_navi(find(table2array(Run1_navi(:,16))==objnr(j)),:);
end
for t = 1:length(objects_1)
    Trial{t} = unique(table2array(objects_1{1,t}(:,6)));
end

for n = 1:length(objnr)
    location_1_x(n) = table2array(unique(Run1_navi(find(table2array(Run1_navi(:,16))==objnr(n)),17)));
end

for n = 1:length(objnr)
    location_1_y(n) = table2array(unique(Run1_navi(find(table2array(Run1_navi(:,16))==objnr(n)),18)));
end

for j = 1:length(objects_1)
    object1_wo_recode{j} = find(strcmp(table2cell(objects_1{1,j}(:,7)),'Phase_REENCODING')==1);
end
object_1_new = objects_1;

for k = 1: length(objects_1)
    object_1_new{1,k}(object1_wo_recode{1,k},:) = [];
end

for m = 1:length(object_1_new)
    for n = 1:3
    object_1_triabl_based{n,m} = object_1_new{1,m}(find(table2array(object_1_new{1,m}(:,6))==Trial{1,m}(n)),:);
    end
end
Trial_sorted = cell2mat(Trial);
for x = 1:18 % 18 is number of trials 
    Trial_sorted_new(x) = find(Trial_sorted(:)==x);
end
for y = 1:length(Trial_sorted_new)
    object_1_triabl_based_new(y) = object_1_triabl_based(Trial_sorted_new(y));
end

% get rid of stationary periods
for q = 1:length(object_1_triabl_based_new)
 [v{q}, w{q}] = unique(table2array(object_1_triabl_based_new{1,q}(:,8)), 'stable' );
end 

for a = 1:length(w)
    duplicate_stationary_values{a} = setdiff( 1:numel(table2array(object_1_triabl_based_new{1,a}(:,8))), w{1,a});
end
object_1_triabl_based_new_NO_stationary = object_1_triabl_based_new;

for z = 1:length(object_1_triabl_based_new_NO_stationary)
    object_1_triabl_based_new_NO_stationary{1,z}(duplicate_stationary_values{1,z},:) = [];
end 

cd ../../20210813_P03_7075_S1_Struct/functional/LME/Orig_preprocessed/layers_INV1_hippunfold/Run6/
clearvars -except object_1_triabl_based_new_NO_stationary layers_avg N_layers y_threshold x_threshold corrupt
for j = 1:length(object_1_triabl_based_new_NO_stationary)
    vol_number{j} = unique(object_1_triabl_based_new_NO_stationary{1,j}(:,15));
end
navigation_volumes= [];
for n = 1:length(vol_number)
    navigation_volumes = [navigation_volumes;table2array(vol_number{1,n})];
end
%% exclude corrupted volumes 
corrupt_vol = ismember(navigation_volumes,corrupt);

for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        corrupt_trial_vol{a,b} = double(ismember(table2array(vol_number{1,a}(b,1)),navigation_volumes(find(corrupt_vol))));
    end
end
corrupt_trial_vol(cellfun(@isempty,corrupt_trial_vol)) = {0};
[row,column] = find(cell2mat(corrupt_trial_vol));
for n = 1:18
vol_number{1,n} = table2cell(vol_number{1,n});
end
vol_number{1,row}(column)=[];

if find(corrupt_vol) > 0
    navigation_volumes(find(corrupt_vol)) = [];
end

%% plot the profiles for the timepoint when subject was navigating
CA1_nav = layers_avg(:,navigation_volumes,1);
CA3_nav = layers_avg(:,navigation_volumes,2);
x = 1:30;
names = {'SRLM','inner','outer'};
figure('color','w')
plot(x,mean(CA1_nav,2),'LineWidth',2,'Color','b');hold on
plot(x,mean(CA3_nav,2),'LineWidth',2,'Color','r');hold on
ylabel('BOLD signal during navigation [a.u]');hold on
plot(x_threshold,y_threshold,'LineWidth',2,'Color','k','LineStyle','--');hold on
set(gca,'xtick',[3,11,30],'xticklabel',names);
%set(gcf, 'Position',get(0,'ScreenSize'));
legend('CA1','CA3','SRLM border');hold on
axis('square');
ax = gca;
ax.FontSize = 16;
%% Plot the profile for individual volumes with and without navigation phase
CA1 = layers_avg(:,:,1);
CA1_no_Nav = CA1;
CA1_no_Nav(:,navigation_volumes) = [];
CA3 = layers_avg(:,:,2);
CA3_no_Nav = CA3;
CA3_no_Nav(:,navigation_volumes) = [];
%figure('color','w','Units','normalized','OuterPosition',[0 0 1 1])
figure('color','w');
subplot(2,2,1)
plot(CA1_no_Nav(:,:));hold on
ylabel('Bold signal in CA1 in each volume but navigation phase');
subplot(2,2,2)
plot(CA1_nav(:,:));hold on
ylabel('Bold signal in CA1 only in navigation volumes');
subplot(2,2,3)
plot(CA3_no_Nav(:,:));hold on
ylabel('Bold signal in CA3 in each volume but navigation phase');
subplot(2,2,4)
plot(CA3_nav(:,:));hold on
ylabel('Bold signal in CA3 only in navigation volumes');
%exportgraphics(gcf,'Comparison_Profiles_without_with_Navigation.eps');
%% write BOLD values per navigation timepoint  in a .xlsx files
writematrix(CA1_nav,'CA1_navigation_withoutTrials.xlsx');
writematrix(CA3_nav,'CA3_navigation_withoutTrials.xlsx');
%% write BOLD signla averaged across navigation points of each trial
SRLM_CA1 = mean(CA1(1:10,:));
SRLM_CA3 = mean(CA3(1:10,:));
for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        SRLM_CA1_trials{a,b} = SRLM_CA1(table2array(vol_number{1,a}(b,1)));
    end
end
writecell(SRLM_CA1_trials,'SRLM_CA1_navi_trials.xlsx');

for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        SRLM_CA3_trials{a,b} = SRLM_CA3(table2array(vol_number{1,a}(b,1)));
    end
end
writecell(SRLM_CA3_trials,'SRLM_CA3_navi_trials.xlsx');

CA1_inner = mean(CA1(11:16,:));
CA1_middle = mean(CA1(17:24,:));
CA1_outer = mean(CA1(25:end,:));
CA3_inner = mean(CA3(11:16,:));
CA3_middle = mean(CA3(17:24,:));
CA3_outer = mean(CA3(25:end,:));

for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        CA1_inner_trials{a,b} = CA1_inner(table2array(vol_number{1,a}(b,1)));
    end
end
writecell(CA1_inner_trials,'CA1_inner_navi_trials.xlsx');

for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        CA1_middle_trials{a,b} = CA1_middle(table2array(vol_number{1,a}(b,1)));
    end
end
writecell(CA1_middle_trials,'CA1_middle_navi_trials.xlsx');

for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        CA1_outer_trials{a,b} = CA1_outer(table2array(vol_number{1,a}(b,1)));
    end
end
writecell(CA1_outer_trials,'CA1_outer_navi_trials.xlsx');

for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        CA3_inner_trials{a,b} = CA3_inner(table2array(vol_number{1,a}(b,1)));
    end
end
writecell(CA3_inner_trials,'CA3_inner_navi_trials.xlsx');

for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        CA3_middle_trials{a,b} = CA3_middle(table2array(vol_number{1,a}(b,1)));
    end
end
writecell(CA3_middle_trials,'CA3_middle_navi_trials.xlsx');

for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        CA3_outer_trials{a,b} = CA3_outer(table2array(vol_number{1,a}(b,1)));
    end
end
writecell(CA3_outer_trials,'CA3_outer_navi_trials.xlsx');
%% get the average BOLD value for each trial
clearvars -except vol_number
SRLM_CA1_trials_avg = readmatrix('SRLM_CA1_navi_trials.xlsx','Range',1);
SRLM_CA3_trials_avg = readmatrix('SRLM_CA3_navi_trials.xlsx','Range',1);
SRLM_CA1_trials_avg = nanmean(SRLM_CA1_trials_avg,2);
SRLM_CA3_trials_avg = nanmean(SRLM_CA3_trials_avg,2);
SRLM_all = [SRLM_CA1_trials_avg,SRLM_CA3_trials_avg];
SRLM_all = array2table(SRLM_all);
SRLM_all.Properties.VariableNames(1,1:2) = {'SRLM_CA1','SRLM_CA3'};
writetable(SRLM_all,'SRLM_all_average.xlsx');
CA1_inner_trials_avg = readmatrix('CA1_inner_navi_trials.xlsx','Range',1);
CA1_middle_trials_avg = readmatrix('CA1_middle_navi_trials.xlsx','Range',1);
CA1_outer_trials_avg = readmatrix('CA1_outer_navi_trials.xlsx','Range',1);
CA1_inner_trials_avg = nanmean(CA1_inner_trials_avg,2);
CA1_middle_trials_avg = nanmean(CA1_middle_trials_avg,2);
CA1_outer_trials_avg = nanmean(CA1_outer_trials_avg,2);
CA3_inner_trials_avg = readmatrix('CA3_inner_navi_trials.xlsx','Range',1);
CA3_middle_trials_avg = readmatrix('CA3_middle_navi_trials.xlsx','Range',1);
CA3_outer_trials_avg = readmatrix('CA3_outer_navi_trials.xlsx','Range',1);
CA3_inner_trials_avg = nanmean(CA3_inner_trials_avg,2);
CA3_middle_trials_avg = nanmean(CA3_middle_trials_avg,2);
CA3_outer_trials_avg = nanmean(CA3_outer_trials_avg,2);

CA_all = [CA1_inner_trials_avg,CA1_middle_trials_avg,CA1_outer_trials_avg,...
    CA3_inner_trials_avg,CA3_middle_trials_avg,CA3_outer_trials_avg];
CA_all = array2table(CA_all);
CA_all.Properties.VariableNames(1,1:6) = {'CA1inner','CA1middle','CA1outer','CA3inner','CA3middle','CA3outer'};
writetable(CA_all,'CA_all_average.xlsx');
%% get the BOLD signal in DG per trial 
clearvars -except vol_number
cd ../../
DG = readmatrix('Run8-mean-DG-signal.txt','Range',1);
cd layers_INV1_hippunfold/Run8/
for a = 1:length(vol_number)
    for b = 1:height(vol_number{1,a})
        DG_trials{a,b} = DG(table2array(vol_number{1,a}(b,1)));
    end
end
writecell(DG_trials,'DG_trials.xlsx');
%% get the mean of DG in each trial 
DG_trials_avg = readmatrix('DG_trials.xlsx','Range',1);
DG_trials_avg = nanmean(DG_trials_avg,2);
DG_trials_avg = array2table(DG_trials_avg);   
DG_trials_avg.Properties.VariableNames = {'DG_trials'};
writetable(DG_trials_avg,'DG_trials_average.xlsx');
%% merge all the above CA_all_average into one file and add sub id 
cd 20211011_P10_7079_S1_Struct/functional/LME/Orig_preprocessed/layers_INV1_hippunfold
a = dir();
a(1:2,:) = [];
%%
for n = 1:length(a)
    cd(a(n).name)
    X{n} = readtable('CA_all_average.xlsx');
    cd ../
end

for n = 1:length(a)
    cd(a(n).name)
    X_SRLM{n} = readtable('SRLM_all_average.xlsx');
    cd ../
end

for n = 1:length(a)
    cd(a(n).name)
    X_DG{n} = readtable('DG_trials_average.xlsx');
    cd ../
end
%%
%X_all = [X{1,1};X{1,2};X{1,3};X{1,4};X{1,5};X{1,6};X{1,7};X{1,8}];
X_all = [X{1,1};X{1,2};X{1,3};X{1,4};X{1,5}];
%X_SRLM_all = [X_SRLM{1,1};X_SRLM{1,2};X_SRLM{1,3};X_SRLM{1,4};X_SRLM{1,5};X_SRLM{1,6};X_SRLM{1,7};X_SRLM{1,8}];
X_SRLM_all = [X_SRLM{1,1};X_SRLM{1,2};X_SRLM{1,3};X_SRLM{1,4};X_SRLM{1,5}];
%X_DG_all = [X_DG{1,1};X_DG{1,2};X_DG{1,3};X_DG{1,4};X_DG{1,5};X_DG{1,6};X_DG{1,7};X_DG{1,8}];
X_DG_all = [X_DG{1,1};X_DG{1,2};X_DG{1,3};X_DG{1,4};X_DG{1,5}];
id(1:height(X_all),1) = cell2table({'P_23'});
X_all(:,7) = id;
X_DG_all(:,2) = id;
X_SRLM_all(:,3) = id;
X_all.Properties.VariableNames(1,7) = {'ID'};
X_DG_all.Properties.VariableNames(1,2) = {'ID'};
X_SRLM_all.Properties.VariableNames(1,3) = {'ID'};
writetable(X_all,'CA_all_average_allRuns.xlsx');
writetable(X_SRLM_all,'SRLM_all_average_allRuns.xlsx');
writetable(X_DG_all,'DG_all_average_allRuns.xlsx');