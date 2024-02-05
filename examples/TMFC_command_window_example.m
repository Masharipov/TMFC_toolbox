clear

%% Setting up computation parameters

% Sequential or parallel computing (0 or 1)
tmfc.defaults.parallel = 0;         % Sequential
% Store temporaty files during GLM estimation in RAM or on disk
tmfc.defaults.resmem = true;        % RAM
% How much RAM can be used at the same time during GLM estimation
tmfc.defaults.maxmem = 2^31;        % 2GB
 
%% Setting up paths

% The path where all results will be saved
tmfc.project_path = 'C:\TMFC_toolbox\test_data\Empirical_data\TMFC_block_project';

% Paths to individual subject SPM.mat files
% tmfc.subjects(1).path = 'C:\TMFC_toolbox\test_data\Empirical_data\Block_design\Subjects\sub_001\stat\Standard_GLM\SPM.mat';
% tmfc.subjects(2).path = 'C:\TMFC_toolbox\test_data\Empirical_data\Block_design\Subjects\sub_002\stat\Standard_GLM\SPM.mat';
% tmfc.subjects(3).path = 'C:\TMFC_toolbox\test_data\Empirical_data\Block_design\Subjects\sub_003\stat\Standard_GLM\SPM.mat';
% etc

% Alternativelly, use the TMFC GUI to select subjects
SPM_check = 1;                      % Check SPM.mat files
[paths] = tmfc_select_subjects_GUI([],SPM_check);

for i = 1:length(paths)
    tmfc.subjects(i).path = paths{i};
end

%% FIR task regression (regress out co-activations and save residual time series)

% FIR window length in [s]
tmfc.FIR_window = 24;
% Nmber of FIR time bins
tmfc.FIR_bins = 24;

% Run FIR task regression
start_sub = 1;                      % Start from the 1st subject
[sub_check] = tmfc_FIR_regress(tmfc,start_sub);

%% LSS regression after FIR task regression (use residual time series)

% Define conditions of interest
tmfc.LSS_after_FIR.conditions(1).sess   = 1;   
tmfc.LSS_after_FIR.conditions(1).number = 1;
tmfc.LSS_after_FIR.conditions(2).sess   = 1;
tmfc.LSS_after_FIR.conditions(2).number = 2;
tmfc.LSS_after_FIR.conditions(3).sess   = 2;
tmfc.LSS_after_FIR.conditions(3).number = 1; 
tmfc.LSS_after_FIR.conditions(4).sess   = 2;
tmfc.LSS_after_FIR.conditions(4).number = 2; 

% Alternatively, use the TMFC GUI to select conditions of interest
[conditions] = tmfc_LSS_GUI(tmfc.subjects(1).path);
tmfc.LSS_after_FIR.conditions = conditions;

% Run LSS regression
[sub_check] = tmfc_LSS_after_FIR(tmfc,start_sub);

%% Select ROIs

% Define ROI set
tmfc.ROI_set(1).set_name = 'three_ROIs';
tmfc.ROI_set(1).ROIs(1).name = 'ROI_002_mask';
tmfc.ROI_set(1).ROIs(2).name = 'ROI_003_mask';
tmfc.ROI_set(1).ROIs(3).name = 'ROI_005_mask';
tmfc.ROI_set(1).ROIs(1).path = 'C:\TMFC_toolbox\test_data\Empirical_data\ROIs\ROI_002_mask.nii';
tmfc.ROI_set(1).ROIs(2).path = 'C:\TMFC_toolbox\test_data\Empirical_data\ROIs\ROI_003_mask.nii';
tmfc.ROI_set(1).ROIs(3).path = 'C:\TMFC_toolbox\test_data\Empirical_data\ROIs\ROI_005_mask.nii';

tmfc.ROI_set(2).set_name = 'two_ROIs';
tmfc.ROI_set(2).ROIs(1).name = 'ROI_005_mask';
tmfc.ROI_set(2).ROIs(2).name = 'ROI_008_mask';
tmfc.ROI_set(2).ROIs(1).path = 'C:\TMFC_toolbox\test_data\Empirical_data\ROIs\ROI_005_mask.nii';
tmfc.ROI_set(2).ROIs(2).path = 'C:\TMFC_toolbox\test_data\Empirical_data\ROIs\ROI_008_mask.nii';

% Alternatively, use the TMFC GUI to select ROIs
%
% The tmfc_select_ROIs_GUI function creates group binary mask based on
% 1st-level masks (SPM.VM) and applies it to all selected ROIs. Empty ROIs
% will be removed. Masked ROIs will be limited to only voxels which have 
% data for all subjects. The dimensions, orientation, and voxel sizes of 
% the masked ROI images will be adjusted according to the group binary mask

[ROI_set] = tmfc_select_ROIs_GUI(tmfc);
tmfc.ROI_set = ROI_set;

%% BSC-LSS after FIR task regression (use residual time series)

% Extract and correlate mean beta series for conditions of interest
ROI_set = 1;                        % Select ROI set
[sub_check, contrasts] = tmfc_BSC_after_FIR(tmfc,ROI_set);

% Update contrasts info
tmfc.ROI_set(1).contrasts.BSC_after_FIR = contrasts;

% These are default contrasts (will be created automatically):
% tmfc.ROI_set(1).contrasts.BSC_after_FIR(1).title = 'Sess_1_Cond_1';
% tmfc.ROI_set(1).contrasts.BSC_after_FIR(2).title = 'Sess_1_Cond_2';
% tmfc.ROI_set(1).contrasts.BSC_after_FIR(3).title = 'Sess_2_Cond_1';
% tmfc.ROI_set(1).contrasts.BSC_after_FIR(4).title = 'Sess_2_Cond_2';
% tmfc.ROI_set(1).contrasts.BSC_after_FIR(1).weights = [1 0 0 0];
% tmfc.ROI_set(1).contrasts.BSC_after_FIR(2).weights = [0 1 0 0];
% tmfc.ROI_set(1).contrasts.BSC_after_FIR(3).weights = [0 0 1 0];
% tmfc.ROI_set(1).contrasts.BSC_after_FIR(4).weights = [0 0 0 1];

% tmfc.ROI_set(2).contrasts.BSC_after_FIR(1).title = 'Sess_1_Cond_1';
% tmfc.ROI_set(2).contrasts.BSC_after_FIR(2).title = 'Sess_1_Cond_2';
% tmfc.ROI_set(2).contrasts.BSC_after_FIR(3).title = 'Sess_2_Cond_1';
% tmfc.ROI_set(2).contrasts.BSC_after_FIR(4).title = 'Sess_2_Cond_2';
% tmfc.ROI_set(2).contrasts.BSC_after_FIR(1).weights = [1 0 0 0];
% tmfc.ROI_set(2).contrasts.BSC_after_FIR(2).weights = [0 1 0 0];
% tmfc.ROI_set(2).contrasts.BSC_after_FIR(3).weights = [0 0 1 0];
% tmfc.ROI_set(2).contrasts.BSC_after_FIR(4).weights = [0 0 0 1];

% New contrasts:
tmfc.ROI_set(1).contrasts.BSC_after_FIR(5).title = 'Cond1_vs_Cond2';
tmfc.ROI_set(1).contrasts.BSC_after_FIR(6).title = 'Cond2_vs_Cond1';
tmfc.ROI_set(1).contrasts.BSC_after_FIR(5).weights = [0.5 -0.5 0.5 -0.5];
tmfc.ROI_set(1).contrasts.BSC_after_FIR(6).weights = [-0.5 0.5 -0.5 0.5];

tmfc.ROI_set(2).contrasts.BSC_after_FIR(5).title = 'Cond1_vs_Cond2';
tmfc.ROI_set(2).contrasts.BSC_after_FIR(6).title = 'Cond2_vs_Cond1';
tmfc.ROI_set(2).contrasts.BSC_after_FIR(5).weights = [0.5 -0.5 0.5 -0.5];
tmfc.ROI_set(2).contrasts.BSC_after_FIR(6).weights = [-0.5 0.5 -0.5 0.5];

% Calculate contrasts
type = 1;                           % BSC-LSS after FIR
con = [5,6];                        % Calculate contrasts #5 and #6
[sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,con,ROI_set);
[sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,con,ROI_set);

%% gPPI after FIR task regression (use residual time series)

% VOI extraction
ROI_set = 1;                        % Select ROI set
start_sub = 1;                      % Start from the 1st subject
[sub_check] = tmfc_VOI_after_FIR(tmfc,ROI_set,start_sub);

% Define conditions of interest
tmfc.gPPI_after_FIR.conditions = tmfc.LSS_after_FIR.conditions; % Use the same conditions as for LSS regression

% PPI calculation
[sub_check] = tmfc_PPI_after_FIR(tmfc,ROI_set,start_sub);

% gPPI calculation
[sub_check] = tmfc_gPPI_after_FIR(tmfc,ROI_set,start_sub);

