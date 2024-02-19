clear

%% Setting up computation parameters

% Sequential or parallel computing (0 or 1)
tmfc.defaults.parallel = 1;         % Parallel
% Store temporaty files during GLM estimation in RAM or on disk
tmfc.defaults.resmem = true;        % RAM
% How much RAM can be used at the same time during GLM estimation
tmfc.defaults.maxmem = 2^32;        % 4GB

 
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
[paths] = tmfc_select_subjects_GUI(SPM_check);

for i = 1:length(paths)
    tmfc.subjects(i).path = paths{i};
end


%% Select ROIs

% Use tmfc_select_ROIs_GUI to select ROIs
%
% The tmfc_select_ROIs_GUI function creates group binary mask based on
% 1st-level masks (SPM.VM) and applies it to all selected ROIs. Empty ROIs
% will be removed. Masked ROIs will be limited to only voxels which have 
% data for all subjects. The dimensions, orientation, and voxel sizes of 
% the masked ROI images will be adjusted according to the group binary mask

[ROI_set] = tmfc_select_ROIs_GUI(tmfc);
tmfc.ROI_set(1) = ROI_set;


%% LSS regression

% Define conditions of interest
% tmfc.LSS.conditions(1).sess   = 1;   
% tmfc.LSS.conditions(1).number = 1;
% tmfc.LSS.conditions(2).sess   = 1;
% tmfc.LSS.conditions(2).number = 2;
% tmfc.LSS.conditions(3).sess   = 2;
% tmfc.LSS.conditions(3).number = 1; 
% tmfc.LSS.conditions(4).sess   = 2;
% tmfc.LSS.conditions(4).number = 2; 

% Alternatively, use the TMFC GUI to select conditions of interest
[conditions] = tmfc_LSS_GUI(tmfc.subjects(1).path);
tmfc.LSS.conditions = conditions;

% Run LSS regression
start_sub = 1;                      % Start from the 1st subject
[sub_check] = tmfc_LSS(tmfc,start_sub);


%% BSC-LSS

% Extract and correlate mean beta series for conditions of interest
ROI_set_number = 1;                        % Select ROI set
[sub_check,contrasts] = tmfc_BSC(tmfc,ROI_set_number);

% Update contrasts info
tmfc.ROI_set(ROI_set_number).contrasts.BSC = contrasts;

% Define new contrasts:
tmfc.ROI_set(1).contrasts.BSC(5).title = 'Cond1_vs_Cond2';
tmfc.ROI_set(1).contrasts.BSC(6).title = 'Cond2_vs_Cond1';
tmfc.ROI_set(1).contrasts.BSC(5).weights = [0.5 -0.5 0.5 -0.5];
tmfc.ROI_set(1).contrasts.BSC(6).weights = [-0.5 0.5 -0.5 0.5];

% Calculate contrasts
type = 3;                           % BSC-LSS
contrast_number = [5,6];            % Calculate contrasts #5 and #6
[sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,contrast_number,ROI_set_number);
[sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,contrast_number,ROI_set_number);


%% FIR task regression (regress out co-activations and save residual time series)

% FIR window length in [s]
tmfc.FIR.window = 24;
% Nmber of FIR time bins
tmfc.FIR.bins = 24;

% Run FIR task regression
[sub_check] = tmfc_FIR(tmfc,start_sub);


%% LSS regression after FIR task regression (use residual time series)

% Define conditions of interest
[conditions] = tmfc_LSS_GUI(tmfc.subjects(1).path);
tmfc.LSS_after_FIR.conditions = conditions;

% Run LSS regression
[sub_check] = tmfc_LSS_after_FIR(tmfc,start_sub);


%% BSC-LSS after FIR task regression (use residual time series)

% Extract and correlate mean beta series for conditions of interest
ROI_set_number = 1;                        % Select ROI set
[sub_check,contrasts] = tmfc_BSC_after_FIR(tmfc,ROI_set_number);

% Update contrasts info
tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR = contrasts;

% Define new contrast:
tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(2).title = 'Reverse contrast';
tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(2).weights = [-1];

% Calculate contrasts
type = 4;                           % BSC-LSS after FIR
contrast_number = 2;                % Calculate contrast #2
[sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,contrast_number,ROI_set_number);
[sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,contrast_number,ROI_set_number);

%% BGFC

% Calculate background functional connectivity (BGFC)
[sub_check] = tmfc_BGFC(tmfc,ROI_set_number,start_sub);

%% gPPI

% Define conditions of interest
tmfc.gPPI.conditions = tmfc.LSS.conditions;

% VOI extraction
[sub_check] = tmfc_VOI(tmfc,ROI_set_number,start_sub);

% PPI calculation
[sub_check] = tmfc_PPI(tmfc,ROI_set_number,start_sub);

% gPPI calculation
[sub_check,contrasts] = tmfc_gPPI(tmfc,ROI_set_number,start_sub);

% Update contrasts info
tmfc.ROI_set(ROI_set_number).contrasts.gPPI = contrasts;

% Define new contrasts:
tmfc.ROI_set(1).contrasts.gPPI(5).title = 'Cond1_vs_Cond2';
tmfc.ROI_set(1).contrasts.gPPI(6).title = 'Cond2_vs_Cond1';
tmfc.ROI_set(1).contrasts.gPPI(5).weights = [0.5 -0.5 0.5 -0.5];
tmfc.ROI_set(1).contrasts.gPPI(6).weights = [-0.5 0.5 -0.5 0.5];

% Calculate contrasts
type = 1;                           % gPPI
contrast_number = [5,6];            % Calculate contrasts #5 and #6
[sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,contrast_number,ROI_set_number);
[sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,contrast_number,ROI_set_number);


%% gPPI-FIR (gPPI model with psychological regressors defined by FIR functions)

% gPPI-FIR calculation
[sub_check] = tmfc_gPPI_FIR(tmfc,ROI_set_number,start_sub);

