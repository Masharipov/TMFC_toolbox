function TMFC
    
% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens the main GUI window.
%
% The tmfc structure contains the following structures:
%    
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^32 = 4GB (how much RAM can be used at
%                            the same time during GLM estimation)
%   tmfc.defaults.resmem   - true or false (store temporaty files during
%                            GLM estimation in RAM or on disk)
%   tmfc.defaults.analysis - 1 (Seed-to-voxel and ROI-to-ROI analyses)
%                          - 2 (ROI-to-ROI analysis only)
%                          - 3 (Seed-to-voxel analysis only)
%   
%   tmfc.project_path      - The path where all results will be saved
%   
%   tmfc.subjects.path     - Paths to individual subject SPM.mat files
%   tmfc.subjects.FIR             - 1 or 0 (completed or not)
%   tmfc.subjects.LSS             - 1 or 0 (completed or not)
%   tmfc.subjects.LSS_after_FIR   - 1 or 0 (completed or not)
%
%   tmfc.ROI_set:          - information about the selected ROI set
%                            and completed TMFC procedures
%
%   tmfc.FIR.window        - FIR window length [seconds]
%   tmfc.FIR.bins          - Number of FIR time bins
%
%   tmfc.LSS.conditions             - Conditions of interest for LSS
%                                     regression without FIR regression
%                                     (based on original time series) 
%   tmfc.LSS_after_FIR.conditions   - Conditions of interest for LSS 
%                                     regression after FIR regression
%                                     (based on residual time series)
%
%   tmfc.ROI_set(i).gPPI.conditions - Conditions of interest for gPPI and
%                                     gPPI-FIR regression
%
% =========================================================================
%
% Copyright (C) 2024 Ruslan Masharipov
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.
%
% Contact email: masharipov@ihb.spb.ru

%% ==================[ Set up GUI and TMFC structure ]=====================

if isempty(findobj('Tag', 'TMFC_GUI')) == 1  
    
    % Set up TMFC structure
    tmfc.defaults.parallel = 0;      
    tmfc.defaults.maxmem = 2^32;
    tmfc.defaults.resmem = true;
    tmfc.defaults.analysis = 1;
    
    % Main TMFC GUI
    handles.TMFC_GUI = figure('Name','TMFC Toolbox','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'norm', 'Position', [0.63 0.0875 0.250 0.850], 'color', 'w', 'Tag', 'TMFC_GUI');
    
    % Box Panels
    handles.MP1 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.85 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP2 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.65 0.94 0.19],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP3 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.511 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP4 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.37 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP5 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.23 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP6 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.01 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');    
    handles.SP1 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.922 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP2 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.863 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP3 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.782 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP4 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.722 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP6 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.582 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP8 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.442 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP9 = uipanel(handles.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.302 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    
    % Buttons
    handles.TMFC_GUI_B1 = uicontrol('Style', 'pushbutton', 'String', 'Subjects', 'Units', 'normalized', 'Position', [0.06 0.92 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B2 = uicontrol('Style', 'pushbutton', 'String', 'ROI set', 'Units', 'normalized', 'Position', [0.06 0.86 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B3 = uicontrol('Style', 'pushbutton', 'String', 'VOIs', 'Units', 'normalized', 'Position', [0.06 0.78 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B4 = uicontrol('Style', 'pushbutton', 'String', 'PPIs', 'Units', 'normalized', 'Position', [0.06 0.72 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B5a = uicontrol('Style', 'pushbutton', 'String', 'gPPI', 'Units', 'normalized', 'Position', [0.06 0.66 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B5b = uicontrol('Style', 'pushbutton', 'String', 'gPPI FIR', 'Units', 'normalized', 'Position', [0.54 0.66 0.40 0.05],'FontUnits','normalized','FontSize',0.33);    
    handles.TMFC_GUI_B6 = uicontrol('Style', 'pushbutton', 'String', 'LSS GLM', 'Units', 'normalized', 'Position', [0.06 0.58 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B7 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS', 'Units', 'normalized', 'Position', [0.06 0.52 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B8 = uicontrol('Style', 'pushbutton', 'String', 'FIR task regression', 'Units', 'normalized', 'Position', [0.06 0.44 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B9 = uicontrol('Style', 'pushbutton', 'String', 'Background connectivity', 'Units', 'normalized', 'Position', [0.06 0.38 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B10 = uicontrol('Style', 'pushbutton', 'String', 'LSS GLM after FIR', 'Units', 'normalized', 'Position', [0.06 0.30 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B11 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS after FIR', 'Units', 'normalized', 'Position', [0.06 0.24 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B12a = uicontrol('Style', 'pushbutton', 'String', 'Statistics', 'Units', 'normalized', 'Position', [0.06 0.16 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B12b = uicontrol('Style', 'pushbutton', 'String', 'Results', 'Units', 'normalized', 'Position', [0.54 0.16 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B13a = uicontrol('Style', 'pushbutton', 'String', 'Open project', 'Units', 'normalized', 'Position', [0.06 0.08 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B13b = uicontrol('Style', 'pushbutton', 'String', 'Save project', 'Units', 'normalized', 'Position', [0.54 0.08 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B14a = uicontrol('Style', 'pushbutton', 'String', 'Change paths', 'Units', 'normalized', 'Position', [0.06 0.02 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B14b = uicontrol('Style', 'pushbutton', 'String', 'Settings', 'Units', 'normalized', 'Position', [0.54 0.02 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    
    % String display
    handles.TMFC_GUI_S1 = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', [1, 0, 0], 'Units', 'norm', 'Position',[0.555 0.926 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S2 = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', [1, 0, 0], 'Units', 'norm', 'Position',[0.555 0.867 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S3 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.787 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S4 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.727 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S6 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.587 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S8 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.447 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S10 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.307 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    
    % CallBack functions corresponding to each button
    set(handles.TMFC_GUI, 'CloseRequestFcn', {@close_GUI, handles.TMFC_GUI}); 
    set(handles.TMFC_GUI_B1,   'callback',   {@select_subjects_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B2,   'callback',   {@ROI_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B3,   'callback',   {@VOI_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B4,   'callback',   {@PPI_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B5a,  'callback',   {@gPPI_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B5b,  'callback',   {@gPPI_FIR_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B6,   'callback',   {@LSS_GLM_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B7,   'callback',   {@BSC_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B8,   'callback',   {@FIR_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B9,   'callback',   {@BGFC_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B10,  'callback',   {@LSS_FIR_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B11,  'callback',   {@BSC_after_FIR_GUI, handles.TMFC_GUI});   
    set(handles.TMFC_GUI_B12a, 'callback',   {@statistics_GUI, handles.TMFC_GUI});               
    set(handles.TMFC_GUI_B12b, 'callback',   {@results_GUI, handles.TMFC_GUI});               
    set(handles.TMFC_GUI_B13a, 'callback',   {@load_project_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B13b, 'callback',   {@save_project_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B14a, 'callback',   {@change_paths_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B14b, 'callback',   {@settings_GUI, handles.TMFC_GUI});    
    warning('off','backtrace')
else
    % Warning if user tries to open TMFC when it is already running
    figure(findobj('Tag', 'TMFC_GUI')); 
    warning('TMFC toolbox is already running.');    
end

%% ========================[ Select subjects ]=============================
% Select subjects and check SPM.mat files
function select_subjects_GUI(ButtonH, EventData, TMFC_GUI)
    
% Freeze main TMFC GUI
freeze_GUI(1);

% Select subjects and check SPM.mat files
subject_paths = tmfc_select_subjects_GUI(1);

% If subjects are not selected - unfreeze 
if isempty(subject_paths)
    freeze_GUI(0);
    disp('TMFC: Subjects not selected.');
else 
   % Clear TMFC structure and resfresh main TMFC GUI            
   tmfc = major_reset(tmfc);

   % Add subject paths to TMFC structure
   for iSub = 1:size(subject_paths,1) 
       tmfc.subjects(iSub).path = char(subject_paths(iSub));       
   end

   % Select TMFC project folder
   disp('TMFC: Please select a folder for the new TMFC project.');    
   tmfc_select_project_path(size(subject_paths,1)); % Dialog window
   project_path = spm_select(1,'dir','Select a folder for the new TMFC project',{},pwd);

   % Verify if project folder is selected
   if strcmp(project_path, '')
        warning('TMFC: Project folder not selected. Subjects not saved.');
        try
            freeze_GUI(0);
        end
        return;
   else
       % Add project path to TMFC structure
        fprintf('TMFC: %d subject(s) selected.\n', size(subject_paths,1));
        set(handles.TMFC_GUI_S1,'String', strcat(num2str(size(subject_paths,1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
        tmfc.project_path = project_path;

        freeze_GUI(0);
        
        cd(tmfc.project_path); 
   end       
end
    
end

%% ============================[ ROI set ]=================================
% Select ROIs and apply group-mean binary mask to them
function ROI_GUI(ButtonH, EventData, TMFC_GUI)

% Initial checks
if ~isfield(tmfc,'subjects')
    error('Select subjects.');
elseif strcmp(tmfc.subjects(1).path, '')
    error('Select subjects.');
elseif ~exist(tmfc.subjects(1).path,'file')
    error('SPM.mat file for the first subject does not exist.')
elseif ~isfield(tmfc,'project_path')
    error('Select TMFC project folder.');
end
    
% Freeze main TMFC GUI
cd(tmfc.project_path);    
freeze_GUI(1);

% Check if ROI sets already exist 
if ~isfield(tmfc,'ROI_set')

    % Select ROIs 
    ROI_set = tmfc_select_ROIs_GUI(tmfc);  

    % Add ROI set info to TMFC structure & update main TMFC GUI
	if isstruct(ROI_set)
        tmfc.ROI_set_number = 1;
        tmfc.ROI_set(1) = ROI_set;
        set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(1).set_name, ' (',num2str(length(tmfc.ROI_set(1).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
        tmfc = ROI_set_initializer(tmfc);
    end

else

    % List of previously defined ROI sets
    ROI_set_list = {};
    for iSet = 1:length(tmfc.ROI_set)
        ROI_set_tmp = {iSet,horzcat(tmfc.ROI_set(iSet).set_name, ' (',num2str(length(tmfc.ROI_set(iSet).ROIs)),' ROIs)')};
        ROI_set_list = vertcat(ROI_set_list, ROI_set_tmp);
    end  

    % Switch between previously defined ROI sets or add a new ROI set
    [ROI_set_check, ROI_set_number] = ROI_set_switcher(ROI_set_list);
	nSet = size(ROI_set_list,1);
    
    % Add new ROI set
	if ROI_set_check == 1

       % Select new ROIs
       new_ROI_set = tmfc_select_ROIs_GUI(tmfc);

       % Add a new ROI set info to TMFC structure & update main TMFC GUI
       if isstruct(new_ROI_set)
           tmfc.ROI_set(nSet+1).set_name = new_ROI_set.set_name;
           tmfc.ROI_set(nSet+1).ROIs = new_ROI_set.ROIs;
           tmfc.ROI_set_number = nSet+1;
           disp('New ROI set selected.');
           set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(nSet+1).set_name, ' (',num2str(length(tmfc.ROI_set(nSet+1).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
           tmfc = ROI_set_initializer(tmfc);
           set(handles.TMFC_GUI_S3,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);    
           set(handles.TMFC_GUI_S4,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
       end
    
    % Switch to selected ROI set
	elseif ROI_set_check == 0 && ROI_set_number > 0
        fprintf('\nSelected ROI set: %s. \n', char(ROI_set_list(ROI_set_number,2)));
        tmfc.ROI_set_number = ROI_set_number;
        set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(ROI_set_number).set_name, ' (',num2str(length(tmfc.ROI_set(ROI_set_number).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
        tmfc = update_gPPI(tmfc);
    % If user cancels operation
    else
        disp('No new ROI set selected.');
    end
end

% Unfreeze main TMFC GUI
freeze_GUI(0);
   
end

%% =============================[ VOIs ]===================================
% Perform VOI computation for selected ROI set
function VOI_GUI(ButtonH, EventData, TMFC_GUI)
    
% Initial checks
if ~isfield(tmfc,'subjects')
    error('Select subjects.');
elseif strcmp(tmfc.subjects(1).path, '')
    error('Select subjects.');
elseif ~exist(tmfc.subjects(1).path,'file')
    error('SPM.mat file for the first subject does not exist.')
elseif ~isfield(tmfc,'project_path')
    error('Select TMFC project folder.');
elseif ~isfield(tmfc,'ROI_set_number')
    error('Select ROI set number.');
elseif ~isfield(tmfc,'ROI_set')
    error('Select ROIs.');
end

% Freeze main TMFC GUI
cd(tmfc.project_path);
freeze_GUI(1);

nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);

try
    cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
    sess = []; sess_num = []; nSess = [];
    for iCond = 1:length(cond_list)
    	sess(iCond) = cond_list(iCond).sess;
    end
    sess_num = unique(sess);
    nSess = length(sess_num); 
end    

% Update TMFC structure
try
    for iSub = 1:nSub
        check_VOI = zeros(nROI,nSess);
        for jROI = 1:nROI
            for kSess = 1:nSess
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs',['Subject_' num2str(iSub,'%04.f')], ...
                        ['VOI_' tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name '_' num2str(kSess) '.mat']), 'file')
                    check_VOI(jROI,kSess) = 1;
                end
            end
        end
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI = double(~any(check_VOI(:) == 0));
    end
end

% Update main TMFC GUI
track_VOI = 0;
for i = 1:nSub
    if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI == 0
        track_VOI = i;
        break;
    end
end
if track_VOI == 0
    set(handles.TMFC_GUI_S3,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
elseif track_VOI == 1
    set(handles.TMFC_GUI_S3,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
else
    set(handles.TMFC_GUI_S3,'String', strcat(num2str(track_VOI-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
end

restart_VOI = -1;
continue_VOI = -1;
        
% VOI was not calculated
if ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).VOI] == 1)    
    
    start_sub = 1;
    define_gPPI_conditions = 1;
    
% VOI was calculated for all subjects    
elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).VOI] == 0)    

	% Ask user to restart VOI computation
	restart_VOI = tmfc_restart_GUI(4);
    
    % Reset VOI, PPI, gPPI and gPPI-FIR progress and delete old files
    if restart_VOI == 1
        start_sub = 1;
        define_gPPI_conditions = 1;
    else
        disp('VOI computation not initiated.');
        freeze_GUI(0); 
        return;
    end 

% VOI was calculated for some subjects  
else

    % Ask user to continue or restart VOI computation
    continue_VOI = tmfc_continue_GUI(track_VOI,4);

    % Continue VOI computation
    if continue_VOI == 1
        start_sub = track_VOI;
        define_gPPI_conditions = 0;
    % Restart VOI computation
    elseif continue_VOI == 0
        start_sub = 1;
        define_gPPI_conditions = 1;
    else
        disp('VOI computation not initiated.'); 
        freeze_GUI(0);
        return;
    end
end

% Select gPPI conditions
if define_gPPI_conditions == 1   
    gPPI_conditions = tmfc_gPPI_GUI(tmfc.subjects(1).path);   
    if isstruct(gPPI_conditions)
        if restart_VOI == 1 || continue_VOI == 0
        	tmfc = reset_gPPI(tmfc,1);
        end
        tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = gPPI_conditions;
        disp('Conditions of interest selected.');
    else
        disp('Conditions of interest not selected.');
        freeze_GUI(0);
        return;
    end
end

% Compute VOIs
disp('Initiating VOI computation...');
try
    sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number,start_sub);      
    for iSub = start_sub:nSub
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI = sub_check(iSub);
    end
    disp('VOI computation completed.');
catch
    freeze_GUI(0);
    error('Error: Calculate VOIs for all subjects.');
end
               
% Unfreeze main TMFC GUI
freeze_GUI(0);
     
end

%% ===============================[ PPIs ]=================================
% Perform PPI computation for selected ROI set
function PPI_GUI(ButtonH, EventData, TMFC_GUI)
    
% Initial checks
if ~isfield(tmfc,'subjects')
    error('Select subjects.');
elseif strcmp(tmfc.subjects(1).path, '')
    error('Select subjects.');
elseif ~exist(tmfc.subjects(1).path,'file')
    error('SPM.mat file for the first subject does not exist.')
elseif ~isfield(tmfc,'project_path')
    error('Select TMFC project folder.');
elseif ~isfield(tmfc,'ROI_set_number')
    error('Select ROI set number.');
elseif ~isfield(tmfc,'ROI_set')
    error('Select ROIs.');
elseif ~isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI')
    error('Select conditions of interest.');
elseif ~isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI,'conditions')
    error('Select conditions of interest. Calculate VOIs for all subjects.');
elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).VOI] == 0)
    error('Calculate VOIs for all subjects.');
end

% Freeze main TMFC GUI
cd(tmfc.project_path);
freeze_GUI(1);

nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
nCond = length(cond_list);

% Update TMFC structure    
for iSub = 1:nSub
    SPM = load(tmfc.subjects(iSub).path);
    check_PPI = zeros(nROI,nCond);
    for jROI = 1:nROI
        for kCond = 1:nCond
            if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs',['Subject_' num2str(iSub,'%04.f')], ...
                        ['PPI_[' regexprep(tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name,' ','_') ']_' cond_list(kCond).file_name '.mat']), 'file')    
            	check_PPI(jROI,kCond) = 1;
            end
        end
    end
    tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = double(~any(check_PPI(:) == 0));
    clear SPM
end

% Update main TMFC GUI
track_PPI = 0;
for iSub = 1:nSub
    if tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI == 0
        track_PPI = iSub;
        break;
    end
end
if track_PPI == 0
    set(handles.TMFC_GUI_S4,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
elseif track_PPI == 1
    set(handles.TMFC_GUI_S4,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
else
    set(handles.TMFC_GUI_S4,'String', strcat(num2str(track_PPI-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
end   

% PPI was not calculated
if ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).PPI] == 1)
    
    calculate_PPI = 1;
    start_sub = 1;

% PPI was calculated for all subjects 
elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).PPI] == 0)
	
    % Dialog window: Help info for PPI recomputation
    calculate_PPI = 0;
    PPI_recompute();
    freeze_GUI(0);
    disp('Recompute VOIs to change conditions of interest for gPPI analysis.');
    
% PPI was calculated for some subjects  
else
    
	% Ask user to continue PPI computation
    continue_PPI = tmfc_continue_GUI(track_PPI,5);
    if continue_PPI == 1
        calculate_PPI = 1;
        start_sub = track_PPI;
    else
        disp('PPI computation not initiated.');
        freeze_GUI(0);
        return;
    end
end

% Compute PPIs
if calculate_PPI == 1
    disp('Initiating PPI computation...');
    try
        sub_check = tmfc_PPI(tmfc,tmfc.ROI_set_number,start_sub);
        for iSub = start_sub:nSub
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = sub_check(iSub);
        end
        disp('PPI computation completed.');
    catch
        freeze_GUI(0);
        error('Error: Calculate PPIs for all subjects.');
    end
end

% Unfreeze main TMFC GUI
freeze_GUI(0);
    
end

%% ==============================[ gPPI ]==================================
% Perform gPPI analysis for selected ROI set
function gPPI_GUI(ButtonH, EventData, TMFC_GUI)
               
% Initial checks
if ~isfield(tmfc,'subjects')
    error('Select subjects.');
elseif strcmp(tmfc.subjects(1).path, '')
    error('Select subjects.');
elseif ~exist(tmfc.subjects(1).path,'file')
    error('SPM.mat file for the first subject does not exist.')
elseif ~isfield(tmfc,'project_path')
    error('Select TMFC project folder.');
elseif ~isfield(tmfc,'ROI_set_number')
    error('Select ROI set number.');
elseif ~isfield(tmfc,'ROI_set')
    error('Select ROIs.');
elseif ~isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI')
    error('Select conditions of interest. Calculate VOIs for all subjects.');
elseif ~isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI,'conditions')
    error('Select conditions of interest. Calculate VOIs for all subjects.');
elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).VOI] == 0)
    error('Calculate VOIs for all subjects.');
elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).PPI] == 0)
    error('Calculate PPIs for all subjects.');
end

% Freeze main TMFC GUI
cd(tmfc.project_path);
freeze_GUI(1);

nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
nCond = length(cond_list);
                
% Update TMFC structure 
for iSub = 1:nSub
    check_gPPI = ones(1,nCond);
	for jCond = 1:nCond
        % Check ROI-to-ROI files
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
            if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI','ROI_to_ROI','symmetrical', ...
                             ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.mat']),'file')
            	check_gPPI(jCond) = 0;
            end
        end
        % Check seed-to-voxel files
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
            if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI','Seed_to_voxel',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                             ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.nii']),'file')
                check_gPPI(jCond) = 0;
            end
        end
	end
    tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI = double(~any(check_gPPI(:) == 0));
end

% Update main TMFC GUI
track_gPPI = 0;
for iSub = 1:nSub
    if tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI == 0
        track_gPPI = iSub;
        break;
    end
end
        
% gPPI was not calculated
if ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).gPPI] == 1)
    
    calculate_gPPI = 1;
    start_sub = 1;   

% gPPI was calculated for all subjects 
elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).gPPI] == 0)
    
    calculate_gPPI = 0;
    fprintf('\ngPPI was calculated for all subjects, %d Session(s) and %d Condition(s). \n', ...
        max([tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions.sess]), size(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions,2));
    disp('To calculate gPPI for different conditions, recompute VOIs and PPIs with desired conditions.');         
    
    % Number of previously calculated contrasts
    nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI);   
    try
        % Specify new contrasts
        tmfc = tmfc_specify_contrasts_GUI(tmfc,tmfc.ROI_set_number,1);      
        % Calculate new contrasts
        if nCon ~= length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI)
            for iCon = nCon+1:length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI)                                     
                seed2vox_or_ROI2ROI(tmfc,iCon,1);
            end
        end
    catch
        freeze_GUI(0);       
        error('Error: Calculate new contrasts.');
    end
    
% gPPI was calculated for some subjects
else
	% Ask user to continue gPPI computation
    continue_gPPI = tmfc_continue_GUI(track_gPPI,6);
    if continue_gPPI == 1
        calculate_gPPI = 1;
        start_sub = track_gPPI;
    else
        disp('gPPI computation not initiated.');
        freeze_GUI(0);
        return;
    end
end
                
% Compute gPPI
if calculate_gPPI == 1    
	disp('Initiating gPPI computation...');
    try
        [sub_check, contrasts] = tmfc_gPPI(tmfc,tmfc.ROI_set_number,start_sub);    
        for iSub = start_sub:nSub
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI = sub_check(iSub);
        end
        for iCon = 1:length(contrasts)
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(iCon).title = contrasts(iCon).title;
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(iCon).weights = contrasts(iCon).weights;
        end
        disp('gPPI computation completed.');
    catch
        freeze_GUI(0);
        error('Error: Calculate gPPI for all subjects.');
    end 
end

% Unfreeze main TMFC GUI
freeze_GUI(0);   

end

%% =============================[ gPPI FIR ]===============================
% Perform gPPI-FIR analysis for selected ROI set
function gPPI_FIR_GUI(ButtonH, EventData, TMFC_GUI)

% Initial checks
if ~isfield(tmfc,'subjects')
    error('Select subjects.');
elseif strcmp(tmfc.subjects(1).path, '')
    error('Select subjects.');
elseif ~exist(tmfc.subjects(1).path,'file')
    error('SPM.mat file for the first subject does not exist.')
elseif ~isfield(tmfc,'project_path')
    error('Select TMFC project folder.');
elseif ~isfield(tmfc,'ROI_set_number')
    error('Select ROI set number.');
elseif ~isfield(tmfc,'ROI_set')
    error('Select ROIs.');
elseif ~isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI')
    error('Select conditions of interest. Calculate VOIs for all subjects.');
elseif ~isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI,'conditions')
    error('Select conditions of interest. Calculate VOIs for all subjects.');
elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).VOI] == 0)
    error('Calculate VOIs for all subjects.');
elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).PPI] == 0)
    error('Calculate PPIs for all subjects.');
end
    
% Freeze main TMFC GUI
cd(tmfc.project_path);
freeze_GUI(1);

nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
nCond = length(cond_list);
                
% Update TMFC structure 
for iSub = 1:nSub
    check_gPPI_FIR = ones(1,nCond);
	for jCond = 1:nCond
        % Check ROI-to-ROI files
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
            if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','symmetrical', ...
                             ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.mat']),'file')
            	check_gPPI_FIR(jCond) = 0;
            end
        end
        % Check seed-to-voxel files
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
            if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR','Seed_to_voxel',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                             ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.nii']),'file')
                check_gPPI_FIR(jCond) = 0;
            end
        end
	end
    tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = double(~any(check_gPPI_FIR(:) == 0));
end

% Update main TMFC GUI
track_gPPI_FIR = 0;
for iSub = 1:nSub
    if tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR == 0
        track_gPPI_FIR = iSub;
        break;
    end
end
        
% gPPI-FIR was not calculated
if ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).gPPI_FIR] == 1)
    
    calculate_gPPI_FIR = 1;
    start_sub = 1;
    
    % Define FIR parameters
    [FIR_window,FIR_bins] = tmfc_FIR_GUI(1);
    if ~isnan(FIR_window) || ~isnan(FIR_bins)
        tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.window = FIR_window;
        tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.bins = FIR_bins;
    end

% gPPI-FIR was calculated for all subjects 
elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).gPPI_FIR] == 0)
    
    calculate_gPPI_FIR = 0;
    fprintf('\ngPPI-FIR was calculated for all subjects, %d Session(s) and %d Condition(s). \n', ...
        max([tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions.sess]), size(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions,2));
    disp('To calculate gPPI-FIR for different conditions, recompute VOIs and PPIs with desired conditions.');         
    
    % Number of previously calculated contrasts
    nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR);
    try
        % Specify new contrasts
        tmfc = tmfc_specify_contrasts_GUI(tmfc,tmfc.ROI_set_number,2);      
        % Calculate new contrasts
        if nCon ~= length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR)
            for iCon = nCon+1:length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR)                                     
                seed2vox_or_ROI2ROI(tmfc,iCon,2);
            end
        end
    catch
        freeze_GUI(0);       
        error('Error: Calculate new contrasts.');
    end

% gPPI-FIR was calculated for some subjects
else
	% Ask user to continue gPPI-FIR computation
    continue_gPPI_FIR = tmfc_continue_GUI(track_gPPI_FIR,7);
    if continue_gPPI_FIR == 1
        calculate_gPPI_FIR = 1;
        start_sub = track_gPPI_FIR;
    else
        disp('gPPI-FIR computation not initiated.');
        freeze_GUI(0);
        return;
    end
end
               
% Compute gPPI-FIR
if calculate_gPPI_FIR == 0
    disp('Initiating gPPI-FIR computation...');
    try
        [sub_check, contrasts] = tmfc_gPPI_FIR(tmfc,tmfc.ROI_set_number,start_sub);    
        for iSub = start_sub:nSub
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = sub_check(iSub);
        end
        for iCon = 1:length(contrasts)
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(iCon).title = contrasts(iCon).title;
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(iCon).weights = contrasts(iCon).weights;
        end
        disp('gPPI computation completed.');
    catch
        freeze_GUI(0);
        error('Error: Calculate gPPI for all subjects.');
    end 
end 

% Unfreeze main TMFC GUI
freeze_GUI(0);
    
end

%% ============================[ LSS GLM ]=================================
% Estimate LSS GLMs
function LSS_GLM_GUI(ButtonH, EventData, TMFC_GUI)

    try
        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);           
        freeze_GUI(1);
        
        L_break = 0;
        V_LSS = 0;
        
        % Track & Update LSS progress to TMFC variable & Window 
        try
            cond_list = tmfc.LSS.conditions;
            sess = []; sess_num = []; N_sess = [];
            for i = 1:length(cond_list)
                sess(i) = cond_list(i).sess;
            end
            sess_num = unique(sess);
            N_sess = length(sess_num);

            for subi = 1:length(tmfc.subjects)              
                SPM = load(tmfc.subjects(subi).path);
                for j = 1:N_sess 
                    % Trials of interest
                    E = 0;
                    trial.cond = [];
                    trial.number = [];
                    for k = 1:length(cond_list)
                        if cond_list(k).sess == sess_num(j)
                            E = E + length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons);
                            trial.cond = [trial.cond; repmat(cond_list(k).number,length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons),1)];
                            trial.number = [trial.number; (1:length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons))'];
                        end
                    end
                    % Check
                    for k = 1:E
                        if exist(fullfile(tmfc.project_path,'LSS_regression',['Subject_' num2str(subi,'%04.f')],'GLM_batches', ...
                                                ['GLM_[Sess_' num2str(sess_num(j)) ']_[Cond_' num2str(trial.cond(k)) ']_[' ...
                                                regexprep(char(SPM.SPM.Sess(sess_num(j)).U(trial.cond(k)).name),' ','_') ']_[Trial_' ...
                                                num2str(trial.number(k)) '].mat']), 'file')
                           condition(trial.cond(k)).trials(trial.number(k)) = 1;
                        else           
                           condition(trial.cond(k)).trials(trial.number(k)) = 0;
                        end
                    end
                    tmfc.subjects(subi).LSS.session(sess_num(j)).condition = condition;
                    clear condition
                end
                clear SPM E trial
            end
            clear cond_list sess sess_num N_sess
        end

        % Update LSS progress to TMFC variable & Window 
        try
            SZ_tmfc = size(tmfc.subjects);
            allValues = [tmfc.LSS.conditions.sess];
            SZS_tmfc = max(allValues); % maximum Sessions
            SZC_tmfc = size(tmfc.LSS.conditions); % maximum Conditions
            condi = 0;
            if SZC_tmfc(2) == 1 
                condi = tmfc.LSS.conditions.number;
            end
            for i = 1:length(tmfc.subjects) 
                % Checking status of LSS completion
                if L_break == 1
                    break;
                else
                    for j = 1:SZS_tmfc
                        if L_break == 1
                            break;
                        else
                            for k = 1:SZC_tmfc(2)
                                if L_break == 1
                                    break;
                                else
                                    if ~condi==0
                                        % if there is only one condition
                                        if any(tmfc.subjects(i).LSS.session(j).condition(condi).trials == 0)
                                            V_LSS = i ;
                                            L_break = 1;
                                            break;
                                        end
                                    else
                                        if any(tmfc.subjects(i).LSS.session(j).condition(k).trials == 0)
                                            V_LSS = i ;
                                            L_break = 1;
                                            break;
                                        end
                                    end
                                end
                            end
                        end
                    end                
                end
            end
            disp(V_LSS);

            if V_LSS == 0
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(length(tmfc.subjects) ), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_LSS == 1
                set(handles.TMFC_GUI_S6,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(V_LSS-1), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
     
        % Check if subjects has been selected
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
            % Check if LSS has been initated before
            if ~isfield(tmfc, 'LSS') 
            
                % First time execution
                
                % Select conditions for LSS
                tmfc.LSS.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);

                % Conditions are selected, initiate LSS
                if isstruct(tmfc.LSS.conditions) && ~isfield(tmfc.subjects, 'LSS')
                    
                    % Processing LSS 
                    fprintf('\nInitiating LSS GLM\n');
                    sub_check = tmfc_LSS(tmfc,1);
                    for i=1:length(tmfc.subjects)
                        tmfc.subjects(i).LSS = sub_check(i);
                    end
                    fprintf('LSS GLM processing completed\n');
                end

                 
            elseif isfield(tmfc.LSS, 'conditions') && ~isfield(tmfc.subjects, 'LSS')
                % Execution if CTLR + C is pressed 
                
                % Select Conditions for LSS
                tmfc.LSS.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);

                % If conditions are selected, initiate LSS
                if isstruct(tmfc.LSS.conditions)

                    % Proccessing of LSS GLM
                    fprintf('\nInitiating LSS GLM\n');
                    sub_check = tmfc_LSS(tmfc,1);
                    for i=1:length(tmfc.subjects)
                        tmfc.subjects(i).LSS = sub_check(i);
                    end
                    fprintf('LSS GLM processing completed\n');
                end

            else
                % Executions for Continue & Restart cases
                if isfield(tmfc.LSS, 'conditions') && isfield(tmfc.subjects, 'LSS') 

                    
                    % Restart case
                    if any(tmfc.subjects(length(tmfc.subjects) ).LSS.session(SZS_tmfc).condition(tmfc.LSS.conditions.number).trials == 1) && any(tmfc.subjects(1).LSS.session(1).condition(tmfc.LSS.conditions.number).trials == 1)

                        % Ask user for Restart or Continue
                        STATUS = tmfc_restart_GUI(2);
                        if STATUS == 1
                            
                            % Create Copy of old conditions
                            verify_old = tmfc.LSS.conditions;
                            
                            % Ask user for new set of Conditions
                            tmfc.LSS.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
                            
                            % If Conditions are selected
                            if isstruct(tmfc.LSS.conditions)
                                
                                % Remove Previously processed LSS files
                                try
                                    rmdir(fullfile(tmfc.project_path,'LSS_regression'),'s');
                                    if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'))
                                        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'),'s');
                                    end
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts = rmfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'BSC');
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC.title = [];
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC.weights = [];
                                    fprintf('\nDeleting old files\n');
                                end
                                
                                % Processing of LSS GLM
                                fprintf('\nInitiating LSS GLM\n');
                                sub_check = tmfc_LSS(tmfc,1);
                                for i=1:length(tmfc.subjects)
                                    tmfc.subjects(i).LSS = sub_check(i);
                                end
                                fprintf('LSS GLM processing completed\n');
                                
                            else
                                % If conditions not selected, restore previously existing conditions
                                tmfc.LSS.conditions = verify_old;                            
                            end
                            
                        end

                    else

                        % Continue case
                        STATUS = tmfc_continue_GUI(V_LSS, 2);
                        
                        % If user Continues processing
                        if STATUS == 0
                            fprintf('\nContinuing LSS GLM\n');
                            sub_check = tmfc_LSS(tmfc,V_LSS);
                            for i=V_LSS:length(tmfc.subjects)
                                tmfc.subjects(i).LSS = sub_check(i);
                            end
                            fprintf('LSS GLM processing completed\n');
                            
                        elseif STATUS == 1
                            % IF user Restarts processing
                            
                            % Create Copy of old conditions 
                            verify_old = tmfc.LSS.conditions;
                            
                            % Ask user for new conditions
                            tmfc.LSS.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
                            
                            % If new conditions are selected
                            if isstruct(tmfc.LSS.conditions)
                                
                                % Remove Previously processed LSS files
                                try
                                    rmdir(fullfile(tmfc.project_path,'LSS_regression'),'s');
                                    if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'))
                                        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'),'s');
                                    end
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts = rmfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'BSC');
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC.title = [];
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC.weights = [];
                                    disp('Deleting old files');
                                end
                                
                                % Processing of LSS GLM
                                sub_check = tmfc_LSS(tmfc,1);
                                for i=1:length(tmfc.subjects)
                                    tmfc.subjects(i).LSS = sub_check(i);
                                end
                                
                            else
                                % If conditions not selected, restore previously existing conditions
                                tmfc.LSS.conditions = verify_old;                            
                            end
                            
                        else
                            warning('LSS regression not initiated');
                        end
                        
                    end
                    
                end
                
            end

        else
            warning('Please select subjects to continue with LSS Regression');
        end

    catch
       warning('Please select subjects & project path to perform LSS GLM regression');
    end
        
    % Unfreeze main TMFC GUI
    freeze_GUI(0);
        
end

%% ============================== [ BSC ] =================================
% Calculate beta-series correlations (BSC)
% Dependencies: 
%       - tmfc_BSC.m                         (External)
%       - tmfc_specify_contrasts_GUI.m       (External)
%       - tmfc_ROI_to_ROI_contrast.m         (External)
%       - tmfc_seed_to_voxel_contrast.m      (External)

function BSC_GUI(buttonH, EventData, TMFC_GUI)

% Initial checks
if ~isfield(tmfc,'subjects')
    error('Select subjects.');
elseif strcmp(tmfc.subjects(1).path, '')
    error('Select subjects.');
elseif ~isfield(tmfc,'project_path')
    error('Select TMFC project folder.');
elseif ~isfield(tmfc,'ROI_set_number')
    error('Select ROI set number.');
elseif ~isfield(tmfc,'ROI_set')
    error('Select ROIs.');
elseif ~isfield(tmfc.subjects,'LSS')
    error('Compute LSS GLMs for all selected subjects.');
end

% Check LSS progress (w.r.t last subject, last session)
LSS_progress = tmfc.subjects(length(tmfc.subjects)).LSS.session(max([tmfc.LSS.conditions.sess])).condition(size(tmfc.LSS.conditions,2)).trials; 
if any(LSS_progress == 0)
    error('Compute LSS GLMs for all selected subjects.');
end

nSub = length(tmfc.subjects);

% Freeze main TMFC GUI
cd(tmfc.project_path);
freeze_GUI(1);

% Update BSC progress
for iSub = 1:nSub
    if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS', ...
            'Beta_series',['Subject_' num2str(iSub,'%04.f') '_beta_series.mat']), 'file')
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC = 1;
    else
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC = 0;
    end
end

% BSC was not calculated
if ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BSC] == 1)                           
        
    disp('Initiating BSC LSS computation...');   
    
    try
        % Processing BSC LSS & generation of default contrasts
        [sub_check, contrasts] = tmfc_BSC(tmfc,tmfc.ROI_set_number);

        % Update BSC progress & BSC contrasts in TMFC structure
        for iSub = 1:nSub
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC = sub_check(iSub);
        end
        for iSub = 1:nSub
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iSub).title = contrasts(iSub).title;
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iSub).weights = contrasts(iSub).weights;
        end
        disp('BSC LSS computation completed.');
    catch
        freeze_GUI(0);
        error('Error: Calculate BSC for all subjects.');
    end
    
% BSC was calculated for all subjects
elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BSC] == 0)
    
    fprintf('\nBSC was calculated for all subjects, %d Session(s) and %d Condition(s). \n', max([tmfc.LSS.conditions.sess]), size(tmfc.LSS.conditions,2));
    disp('To calculate BSC for different conditions, recompute LSS GLMs with desired conditions.');         

    % Number of previously calculated contrasts
    nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC);
    
    try
        % Specify new contrasts
        tmfc = tmfc_specify_contrasts_GUI(tmfc,tmfc.ROI_set_number,3);

        % Calculate new contrasts
        if nCon ~= length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC)       
            for iCon = nCon+1:length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC)
                seed2vox_or_ROI2ROI(tmfc,iCon,3);
            end
        end
    catch
        freeze_GUI(0);       
        error('Error: Calculate new contrasts.');
    end
    
% BSC was calculated for some subjects (recompute)
else
    
    disp('Initiating BSC LSS computation...');
    
    try
        sub_check = tmfc_BSC(tmfc,tmfc.ROI_set_number);
        for iSub = 1:nSub
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC = sub_check(iSub);
        end

        disp('BSC LSS computation completed.');
    catch
        freeze_GUI(0);
        error('Error: Recompute BSC for all subjects.');
    end

end

% Unfreeze main TMFC GUI
freeze_GUI(0);
    
end

%% ========================[ FIR Regression ]==============================
% Performing FIR processing 
% Dependencies: 
%       - tmfc_FIR.m             (External)
%       - tmfc_FIR_GUI()         (Internal)
%       - tmfc_restart_GUI()     (Internal)
%       - tmfc_continue_GUI()    (Internal)

function FIR_GUI(ButtonH, EventData, TMFC_GUI)
    
    % Checking for subjects selection
    %try

        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);           
        freeze_GUI(1);

        % Logical Condition to perform FIR if already computed
        if isfield(tmfc,'FIR') && ~isnan(tmfc.FIR.window) && ~isnan(tmfc.FIR.bins)
            
            % Track & Update FIR progress to TMFC variable & Window 
            try
                for subi = 1:length(tmfc.subjects)              
                    SPM = load(tmfc.subjects(subi).path);
                    if exist(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(subi,'%04.f')],['Res_' num2str(sum(SPM.SPM.nscan),'%04.f') '.nii']), 'file')
                       tmfc.subjects(subi).FIR = 1;
                    else           
                       tmfc.subjects(subi).FIR = 0;       
                    end

                end
            end

            % Update FIR progress to TMFC variable & Window 
            try
                SZ_tmfc = size(tmfc.subjects);
                V_FIR = 0;
                for i = 1:length(tmfc.subjects) 
                    if tmfc.subjects(i).FIR == 0
                        V_FIR = i ;
                        break;
                    end
                end
                if V_FIR == 0
                    set(handles.TMFC_GUI_S8,'String', strcat(num2str(length(tmfc.subjects) ), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
                elseif V_FIR == 1
                    set(handles.TMFC_GUI_S8,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
                else
                    set(handles.TMFC_GUI_S8,'String', strcat(num2str(V_FIR-1), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
                end
            end
        end
        

        % Check if subjects have been selected
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')

            % Checking if FIR has been executed before
            if ~isfield(tmfc, 'FIR') 

                % Ask user for Bins & windows
                [tmfc.FIR.window,tmfc.FIR.bins] = tmfc_FIR_GUI(0);
                if isnan(tmfc.FIR.window) || isnan(tmfc.FIR.bins)
                    tmfc = rmfield(tmfc, 'FIR');
                else
                    
                % If user enters Bins & windows then continue processing
                 if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)

                    fprintf('\nInitiating FIR Computation\n');

                    % Processing FIR Computation
                    sub_check = tmfc_FIR(tmfc, 1);
                    for i=1:length(tmfc.subjects)
                        tmfc.subjects(i).FIR = sub_check(i);
                    end
                    try
                        % reset BGFC is ROI set exists
                    end
                    fprintf('\nFIR Computation Completed\n');
                 end
                end

            elseif isfield(tmfc, 'FIR') && tmfc.subjects(1).FIR == 0
                % Execution if CTLR + C is pressed 

                % Ask user to enter bins & windows
                [tmfc.FIR.window,tmfc.FIR.bins] = tmfc_FIR_GUI(0);

                % If user enters bins & windows
                 if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)

                    fprintf('\nInitiating FIR Computation\n');
                    % Processing FIR Computation
                    sub_check = tmfc_FIR(tmfc, 1);
                    for i=1:length(tmfc.subjects) % change to len(new_run)
                        tmfc.subjects(i).FIR = sub_check(i);
                    end
                    fprintf('\nFIR Computation Completed\n');
                 end

            else

                % Other cases 'Restart' and 'Continue'
                if ~isnan(tmfc.FIR.window) && ~isnan(tmfc.FIR.bins) 

                    % Restart Case
                    if tmfc.subjects(length(tmfc.subjects)).FIR == 1                  

                        % Ask if user wants to restart or cancel
                        STATUS = tmfc_restart_GUI(1);

                        if STATUS == 1

                            verify_old_FIR_W = tmfc.FIR.window;
                            verify_old_FIR_B = tmfc.FIR.bins;

                            % Ask user for Bins & Window
                            [tmfc.FIR.window,tmfc.FIR.bins] = tmfc_FIR_GUI(0);

                            % If User enters bins & Windows
                            if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)                            
                                fprintf('\nRestarting FIR regression\n');

                                % Remove previously processed files
                                try
                                    rmdir(fullfile(tmfc.project_path,'FIR_regression'),'s');
                                    if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'))
                                        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'),'s');
                                    end
                                    try
                                        for i = 1:length(tmfc.subjects)
                                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BGFC = 0;
                                        end 
                                    end
                                    fprintf('Deleting old files\n');
                                end

                                % Processing FIR Computations
                                fprintf('\nRestarting FIR Computations\n');
                                sub_check = tmfc_FIR(tmfc, 1);
                                for i=1:length(tmfc.subjects)
                                    tmfc.subjects(i).FIR = sub_check(i);
                                end
                                fprintf('\nFIR Computation Completed\n');
                            else
                                tmfc.FIR.window = verify_old_FIR_W;
                                tmfc.FIR.bins = verify_old_FIR_B;
                            end

                        end

                    else
                        % Continue case

                        % Check progress of FIR computation
                        for i=1:length(tmfc.subjects)
                            FIR_index = [];
                            if tmfc.subjects(i).FIR == 0
                                FIR_index = i;
                                break;
                            end
                        end

                        % Ask if user wants to continue/restart or cancel
                        FIR_dec = tmfc_continue_GUI(FIR_index,1);

                        % If user continues
                        if FIR_dec == 0

                            fprintf('\nContinuting FIR computation\n');
                            con_run = tmfc_FIR(tmfc,FIR_index);
                            for i=FIR_index:length(tmfc.subjects)
                                tmfc.subjects(i).FIR = con_run(i);
                            end
                            fprintf('\nFIR Computation Completed\n');

                        % IF user decides to restart
                        elseif FIR_dec == 1

                            % Ask user for bins & windows
                            [tmfc.FIR.window,tmfc.FIR.bins] = tmfc_FIR_GUI(0);

                            % If bins & Windows are provided
                            if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)   

                                % Remove previously processed files
                                try
                                    rmdir(fullfile(tmfc.project_path,'FIR_regression'),'s');
                                    if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'))
                                        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'),'s');
                                    end
                                    try
                                        for i = 1:length(tmfc.subjects)
                                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BGFC = 0;
                                        end 
                                    end
                                    fprintf('Deleting old files\n');
                                end

                                fprintf('\nRestarting FIR Computation\n');
                                % Processing FIR Computations
                                con_run = tmfc_FIR(tmfc,1);
                                for i=1:length(tmfc.subjects)
                                    tmfc.subjects(i).FIR = con_run(i);
                                end
                                fprintf('FIR Computation Completed\n');
                            end

                        else
                            warning('FIR regression not initiated');
                        end

                    end

                end

            end

        else
            warning('Please select subjects to perform FIR Regression');
        end

    %catch
    %   warning('Please select subjects & project path to perform FIR regression');
    %end 
    
     % Unfreeze main TMFC GUI
    freeze_GUI(0);
    
end

%% ==============================[ BGFC ]==================================
% Calculate background functional connectivity (BGFC) 
% Dependencies: 
%       - tmfc_BGFC.m            (External)
%       - tmfc_continue_GUI()    (Internal)
%       - recompute_BGFC()       (Internal)

function BGFC_GUI(buttonH, EventData, TMFC_GUI)

% Initial checks
if ~isfield(tmfc,'subjects')
    error('Select subjects.');
elseif strcmp(tmfc.subjects(1).path, '')
    error('Select subjects.');
elseif ~exist(tmfc.subjects(1).path,'file')
    error('SPM.mat file for the first subject does not exist.')
elseif ~isfield(tmfc,'project_path')
    error('Select TMFC project folder.');
elseif ~isfield(tmfc,'ROI_set_number')
    error('Select ROI set number.');
elseif ~isfield(tmfc,'ROI_set')
    error('Select ROIs.');
elseif ~isfield(tmfc.subjects,'FIR')
    error('Calculate FIR task regression.');
elseif any([tmfc.subjects(:).FIR]) == 0 
    error('Calculate FIR task regression for all subjects.');
end

nSub = length(tmfc.subjects);
       
% Update BGFC progress
SPM = load(tmfc.subjects(1).path); 
for iSub = 1:nSub
    check_BGFC = zeros(1,length(SPM.SPM.Sess));
    for jSess = 1:length(SPM.SPM.Sess)       
       if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC','ROI_to_ROI', ... 
                   ['Subject_' num2str(iSub,'%04.f') '_Session_' num2str(jSess) '.mat']), 'file')
           check_BGFC(jSess) = 1;
       end
    end
    tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BGFC = double(~any(check_BGFC == 0));
end
clear SPM

track_BGFC = 0;
for iSub = 1:nSub
    if tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BGFC == 0
        track_BGFC = iSub;
        break;
    end
end

% Freeze main TMFC GUI
cd(tmfc.project_path);
freeze_GUI(1);
                     
% BGFC was not calculated
if ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BGFC] == 1)

    disp('Initiating BGFC computation...');
    
    try
        sub_check = tmfc_BGFC(tmfc,tmfc.ROI_set_number,1);
        for iSub = 1:nSub
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BGFC = sub_check(iSub);
        end
        disp('BGFC computation completed.');
    catch
        freeze_GUI(0);
        error('Error: Calculate BGFC for all subjects.');
    end
    
% BGFC was calculated for all subjects    
elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BGFC] == 0)
    
    fprintf('BGFC was calculated for all subjects, FIR settings: %d [s] window and %d time bins.\n', tmfc.FIR.window,tmfc.FIR.bins);
    disp('To calculate BGFC with different FIR settings, recompute FIR task regression with desired window length and number of time bins.');         
    recompute_BGFC(tmfc);

% BGFC was calculated for some subjects
else
    try
        % Ask user to continue BGFC computation
        continue_BGFC = tmfc_continue_GUI(track_BGFC,8);
        if continue_BGFC == 1
            disp('Continuing BGFC computation...');
            sub_check = tmfc_BGFC(tmfc,tmfc.ROI_set_number,track_BGFC);
            for i = track_BGFC:nSub
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BGFC = sub_check(i);
            end
            disp('BGFC computation completed.');
        else
            warning('BGFC computation not initiated.');
        end
    catch
        freeze_GUI(0);
        error('Error: Continue BGFC computation.');
    end
end          
    
% Unfreeze main TMFC GUI
freeze_GUI(0);
    
end

%% ============================[ LSS FIR ]=================================
% Performing LSS FIR processing 
% Dependencies: 
%       - tmfc_LSS_GUI.m            (External)
%       - tmfc_LSS_after_FIR.m      (External)
%       - tmfc_restart_GUI()        (Internal)
%       - tmfc_continue_GUI()       (Internal)
    
function LSS_FIR_GUI(ButtonH, EventData, TMFC_GUI)

    % Checking for subjects selection
    try
        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);           
        freeze_GUI(1);

        % Variables to store progress of LSS FIR progression
        L_break = 0;
        V_LSS = 0;
        
        % Track & Update LSS FIR progress to TMFC variable & Window 
        try
            cond_list = tmfc.LSS_after_FIR.conditions;
            sess = []; sess_num = []; N_sess = [];
            for i = 1:length(cond_list)
                sess(i) = cond_list(i).sess;
            end
            sess_num = unique(sess);
            N_sess = length(sess_num);

            for subi = 1:length(tmfc.subjects)              
                SPM = load(tmfc.subjects(subi).path);
                for j = 1:N_sess 
                    % Trials of interest
                    E = 0;
                    trial.cond = [];
                    trial.number = [];
                    for k = 1:length(cond_list)
                        if cond_list(k).sess == sess_num(j)
                            E = E + length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons);
                            trial.cond = [trial.cond; repmat(cond_list(k).number,length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons),1)];
                            trial.number = [trial.number; (1:length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons))'];
                        end
                    end
                    % Check
                    for k = 1:E
                        if exist(fullfile(tmfc.project_path,'LSS_regression_after_FIR',['Subject_' num2str(subi,'%04.f')],'GLM_batches', ...
                                                ['GLM_[Sess_' num2str(sess_num(j)) ']_[Cond_' num2str(trial.cond(k)) ']_[' ...
                                                regexprep(char(SPM.SPM.Sess(sess_num(j)).U(trial.cond(k)).name),' ','_') ']_[Trial_' ...
                                                num2str(trial.number(k)) '].mat']), 'file')
                           condition(trial.cond(k)).trials(trial.number(k)) = 1;
                        else           
                           condition(trial.cond(k)).trials(trial.number(k)) = 0;
                        end
                    end
                    tmfc.subjects(subi).LSS_after_FIR.session(sess_num(j)).condition = condition;
                    clear condition
                end
                clear SPM E trial
            end
            clear cond_list sess sess_num N_sess
        end
        
        % Update LSS FIR progress to TMFC variable & Window 
        try
                SZ_tmfc = size(tmfc.subjects);
                allValues = [tmfc.LSS_after_FIR.conditions.sess];
                SZS_tmfc = max(allValues); % maximum Sessions
                SZC_tmfc = size(tmfc.LSS_after_FIR.conditions); % maximum Conditions
                condi = 0;
                if SZC_tmfc(2) == 1 
                    condi = tmfc.LSS_after_FIR.conditions.number;
                end
                for i = 1:length(tmfc.subjects) 
                    % Checking status of LSS after FIR completion
                    if L_break == 1
                        break;
                    else
                        for j = 1:SZS_tmfc
                            if L_break == 1
                                break;
                            else
                                for k = 1:SZC_tmfc(2)
                                    if L_break == 1
                                        break;
                                    else
                                        if ~condi==0
                                            % if there is only one condition
                                            if any(tmfc.subjects(i).LSS_after_FIR.session(j).condition(condi).trials == 0)
                                                V_LSS = i ;
                                                L_break = 1;
                                                break;
                                            end
                                        else
                                            if any(tmfc.subjects(i).LSS_after_FIR.session(j).condition(k).trials == 0)
                                                V_LSS = i ;
                                                L_break = 1;
                                                break;
                                            end
                                        end
                                    end
                                end
                            end
                        end                
                    end
                end

                if V_LSS == 0
                    set(handles.TMFC_GUI_S10,'String', strcat(num2str(length(tmfc.subjects) ), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
                elseif V_LSS == 1
                    set(handles.TMFC_GUI_S10,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
                else
                    set(handles.TMFC_GUI_S10,'String', strcat(num2str(V_LSS-1), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
                end
        end

        % Check if subjects have been selected
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
            % Checking the progression of the subjects
            last_size = size(tmfc.subjects);
            if isfield(tmfc.subjects, 'FIR') && tmfc.subjects(last_size(2)).FIR == 1
                           
                % Check if LSS FIR has been computed
                if ~isfield(tmfc, 'LSS_after_FIR') 
                    % First time exeuction

                    % Select LSS conditions    
                    tmfc.LSS_after_FIR.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);

                    % If LSS conditions has been selected by user
                    if isstruct(tmfc.LSS_after_FIR.conditions) && ~isfield(tmfc.subjects, 'LSS_after_FIR')

                        fprintf('\nInitializing LSS FIR Computation\n');
                        sub_check = tmfc_LSS_after_FIR(tmfc,1);
                        for i=1:length(tmfc.subjects)
                            tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                        end
                        fprintf('LSS FIR Computation Completed\n');
                        
                    end

                elseif isfield(tmfc.LSS_after_FIR, 'conditions') && ~isfield(tmfc.subjects, 'LSS_after_FIR')
                    % Execution if CTLR + C is pressed 
                    
                    % Select LSS conditions    
                    tmfc.LSS_after_FIR.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);

                    % If LSS conditions has been selected by user
                    if isstruct(tmfc.LSS_after_FIR.conditions)

                        fprintf('\nInitializing LSS FIR Computation\n');
                        sub_check = tmfc_LSS_after_FIR(tmfc,1);
                        for i=1:length(tmfc.subjects)
                            tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                        end
                        fprintf('LSS FIR Computation Completed\n');
                        
                    end

                else
                    
                    % For other conditions of exeuction 
                    if isfield(tmfc.LSS_after_FIR, 'conditions') && isfield(tmfc.subjects, 'LSS_after_FIR') 

                        % Restart case
                        if any(tmfc.subjects(length(tmfc.subjects) ).LSS_after_FIR.session(SZS_tmfc).condition(tmfc.LSS_after_FIR.conditions.number).trials == 1) && any(tmfc.subjects(1).LSS_after_FIR.session(1).condition(tmfc.LSS_after_FIR.conditions.number).trials == 1)

                            % Ask user if Restart or cancel 
                            STATUS = tmfc_restart_GUI(3);
                            
                            if STATUS == 1
                                
                                % Storage of conditions for restoration
                                verify_old = tmfc.LSS_after_FIR.conditions;
                                
                                % Ask user for New conditions
                                tmfc.LSS_after_FIR.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
                                
                                % IF conditions are selected
                                if isstruct(tmfc.LSS_after_FIR.conditions)
                                    
                                    % Remove previously generated files & directories
                                    try
                                        rmdir(fullfile(tmfc.project_path,'LSS_regression_after_FIR'),'s');
                                        if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'))
                                            rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'),'s');
                                        end
                                        tmfc.ROI_set(tmfc.ROI_set_number).contrasts = rmfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'BSC_after_FIR');
                                        tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR.title = [];
                                        tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR.weights = [];
                                        fprintf('\nDeleting old files\n');
                                    end
                                    
                                    fprintf('\nRestarting LSS FIR Computation\n');
                                    sub_check = tmfc_LSS_after_FIR(tmfc,1);
                                    for i=1:length(tmfc.subjects)
                                        tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                                    end
                                    fprintf('LSS FIR Computation Completed\n');
                                    
                                else
                                    % Restoring Previous LSS FIR Conditions if user cancels operation
                                    tmfc.LSS_after_FIR.conditions = verify_old;                            
                                end
                                
                            end

                        else
                            % Continue case
                            
                            % Ask user if Continue, Cancel, restart
                            STATUS = tmfc_continue_GUI(V_LSS, 3);
                            
                            % If Continue
                            if STATUS == 0
                                
                                fprintf('\nContinuing LSS FIR Computation\n');
                                sub_check = tmfc_LSS_after_FIR(tmfc,V_LSS);
                                for i=V_LSS:length(tmfc.subjects)
                                    tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                                end
                                fprintf('LSS FIR Computation Completed\n');
                                
                            elseif STATUS == 1
                                
                                % Storage of conditions for restoration
                                verify_old = tmfc.LSS_after_FIR.conditions;
                                
                                % Ask user for New conditions
                                tmfc.LSS_after_FIR.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
                                
                                % IF conditions are selected
                                if isstruct(tmfc.LSS_after_FIR.conditions)
                                    
                                    % Remove previously generated files & directories
                                    try
                                        rmdir(fullfile(tmfc.project_path,'LSS_regression_after_FIR'),'s');
                                        if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'))
                                            rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'),'s');
                                        end
                                        tmfc.ROI_set(tmfc.ROI_set_number).contrasts = rmfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'BSC_after_FIR');
                                        tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR.title = [];
                                        tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR.weights = [];
                                        disp('Deleting old files');
                                    end
                                    
                                    fprintf('\nRestarting LSS FIR Computation\n');
                                    sub_check = tmfc_LSS_after_FIR(tmfc,1);
                                    for i=1:length(tmfc.subjects)
                                        tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                                    end
                                    fprintf('LSS FIR Computation Completed\n');
                                    
                                else
                                    % Restoring Previous LSS FIR Conditions if user cancels operation
                                    tmfc.LSS_after_FIR.conditions = verify_old;                            
                                end
                                
                            else
                                warning('LSS after FIR regression not initiated');
                            end
                            
                        end
                        
                    end
                    
                end

            else
                warning('Please complete FIR regression to continue with LSS regression');
            end

        else
            warning('Please select subjects to continue with LSS Regression');
        end
            
    catch
       warning('Please select subjects & project path to perform LSS after FIR regression');
    end
    
    % Unfreeze main TMFC GUI
    freeze_GUI(0);
        
end

%% ==========================[ BSC after FIR ]=============================
% Calculate beta-series correlations after FIR regression (BSC after FIR)
% Dependencies: 
%       - tmfc_BSC_after_FIR.m            (External)
%       - tmfc_specify_contrasts_GUI.m    (External)
%       - tmfc_ROI_to_ROI_contrast.m      (External)
%       - tmfc_seed_to_voxel_contrast.m   (External)

function BSC_after_FIR_GUI(ButtonH, EventData, TMFC_GUI)

% Initial checks
if ~isfield(tmfc,'subjects')
    error('Select subejcts'); 
elseif strcmp(tmfc.subjects(1).path, '')
    error('Select subjects.');
elseif ~isfield(tmfc,'project_path')
    error('Select TMFC project folder.');
elseif ~isfield(tmfc,'ROI_set_number')
    error('Select ROI set number.');
elseif ~isfield(tmfc,'ROI_set')
    error('Select ROIs.');
elseif ~isfield(tmfc.subjects,'LSS_after_FIR')
    error('Compute LSS after FIR for all selected subjects.');
end

% Check LSS after FIR progress (w.r.t last subject, last session)
LSS_FIR_progress = tmfc.subjects(length(tmfc.subjects)).LSS_after_FIR.session(max([tmfc.LSS_after_FIR.conditions.sess])).condition(size(tmfc.LSS_after_FIR.conditions,2)).trials; 
if any(LSS_FIR_progress == 0)
    error('Compute LSS after FIR for all selected subjects.');
end

% Freeze main TMFC GUI
cd(tmfc.project_path);
freeze_GUI(1);

% Update BSC after FIR progress
for subi = 1:length(tmfc.subjects)
    if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR', ...
            'Beta_series',['Subject_' num2str(subi,'%04.f') '_beta_series.mat']), 'file')
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).BSC_after_FIR = 1;
    else
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).BSC_after_FIR = 0;
    end
end

% BSC after FIR was not calculated
if ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BSC_after_FIR] == 1)                           
        
    disp('Initiating BSC LSS after FIR computation...');   
    
    try
        % Processing BSC after FIR & generation of default contrasts
        [sub_check, contrasts] = tmfc_BSC_after_FIR(tmfc,tmfc.ROI_set_number);

        % Update BSC after FIR progress & BSC after FIR contrasts in TMFC structure
        for i = 1:length(tmfc.subjects)
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BSC_after_FIR = sub_check(i);
        end
        for i = 1:length(contrasts)
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(i).title = contrasts(i).title;
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(i).weights = contrasts(i).weights;
        end
        disp('BSC LSS after FIR computation completed.');
    catch
        freeze_GUI(0);
        error('Error: Calculate BSC after FIR for all subjects.');
    end
    
% BSC after FIR was calculated for all subjects
elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BSC_after_FIR] == 0)
    
    fprintf('\nBSC after FIR was calculated for all subjects, %d Sessions and %d Conditions. \n', max([tmfc.LSS_after_FIR.conditions.sess]), size(tmfc.LSS_after_FIR.conditions,2));
    disp('To calculate BSC after FIR for different conditions, recompute LSS after FIR with desired conditions.');         

    % Number of previously calculated contrasts
    N_contrasts = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR);
    
    try
        % Specify new contrasts
        tmfc = tmfc_specify_contrasts_GUI(tmfc,tmfc.ROI_set_number,3);

        % Calculate new contrasts
        if N_contrasts ~= length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR)       
            for i = N_contrasts+1:length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR)
                seed2vox_or_ROI2ROI(tmfc,i,4);
            end
        end
    catch
        freeze_GUI(0);       
        error('Error: Calculate new contrasts.');
    end
    
% BSC after FIR was calculated for some subjects (recompute)
else
    
    disp('Initiating BSC LSS after FIR computation...');
    
    try
        sub_check = tmfc_BSC_after_FIR(tmfc,tmfc.ROI_set_number);
        for i = 1:length(tmfc.subjects)
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BSC_after_FIR = sub_check(i);
        end

        disp('BSC LSS after FIR computation completed.');
    catch
        freeze_GUI(0);
        error('Error: Recompute BSC after FIR for all subjects.');
    end

end

% Unfreeze main TMFC GUI
freeze_GUI(0);
    
end

%% ==========================[ Load project ]==============================
% Loading TMFC project (*.mat) into TMFC toolbox
% Dependencies:
%       - evaluate_file() (Internal)
%
% Variable description: 
% filename = Name of .mat file selected by user (e.g. tmfc_project.mat)
% path     = path of .mat file selected by user (e.g. C:\User\matlab\)
% fullpath = complete path + filename as one string (e.g. C:\User\matlab\tmfc_project.mat)
% loaded_data = using function ('load'), data from .mat file is loaded to internal workspace 
% variable_name = temporary storage of variable to compare if loaded file is in TMFC format or not. 

function load_project_GUI(ButtonH, EventData, TMFC_GUI)

    % Get File name, Directory of File to be loaded
    [filename, path] = uigetfile(pwd,'*.mat', 'Select .mat file');

    % If user has selected a file the proceed else warning
    if filename ~= 0                                              
        % Construct Full Path to file
        fullpath = fullfile(path, filename);           

        % Load Data from File into temporary variable
        loaded_data = load(fullpath);            

        % Get the name of the variable as in file 
        variable_name = fieldnames(loaded_data);                 
           
        if strcmp('tmfc', variable_name{1}) 
            
        	% Get value of the variable as in file
            tmfc = loaded_data.(variable_name{1});       

            % Evaluate file & Update TMFC, TMFC window with progress
            tmfc = load_project(tmfc);
            fprintf('Successfully loaded file "%s"\n', filename);
            
        else
            warning('Selected file is not in TMFC format, please select again.');
        end
    else
        warning('No file selected to load.');
    end
end

%% ==========================[ Save project ]==============================
% Function to save TMFC variable from workspace to individual .mat file in user desired location
% Dependencies:
%       - saver() (Internal)

function save_status = save_project_GUI(ButtonH, EventData, TMFC_GUI)
       
    % Ask user for Filename & location name:
    [filename, pathname] = uiputfile('*.mat', 'Save TMFC variable as');
    
    % Set Flag save status to zero, this flag is used in the future as
    % a reference to check if the save was successful or not
    save_status = 0;
    
    % Check if FileName or Path is missing or not available 
    if isequal(filename,0) || isequal(pathname,0)
        warning('TMFC variable not saved. File name or Save Directory not selected');  
    else
        % If all data is available
        % Construct full path: PATH + FileName
        
        fullpath = fullfile(pathname, filename);
        
        % D receives the save status of the variable in the desingated location
        save_status = file_save(fullpath);
        
        % If the variable was successfully saved then display info
        if save_status == 1
            fprintf('File saved successfully in path: %s\n', fullpath);
        else
            fprintf('File not saved.');
        end
    end       
end

% =========================================================================
% Function to perform Independent saving & return of save status, where
% 0 - Successfully saved, 1 - Failed to save
% =========================================================================
function save_status =  file_save(save_path)
    try 
        save(save_path, 'tmfc');
        save_status = 1;
        % Save Successful 
    catch 
        save_status = 0;
        % Save Unsuccessful 
    end
end

%% ==========================[ Change Paths ]==============================
% Function to perform Change paths of TMFC subjects
% Dependencies:
%       - tmfc_select_subjects_GUI.m (External)

function change_paths_GUI(ButtonH, EventData, TMFC_GUI)
    
	disp('Select SPM.mat files to change paths...');
    
    % Use Select subjects.m WITHOUT 4 Stage file check
    subjects = tmfc_select_subjects_GUI(0);  

    if ~isempty(subjects)
        tmfc_change_paths_GUI(subjects);  
    else
        disp('No SPM.mat files selected for path change.');
    end
    
end

%% ============================[ Settings ]================================
% Function to setup & change presets of TMFC Toolbox

set_computing = {'Sequential computing', 'Parallel computing'};
set_storage = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
set_analysis = {'Seed-to-voxel and ROI-to-ROI','ROI-to-ROI only','Seed-to-voxel only'};

function settings_GUI(ButtonH, EventData, TMFC_GUI)
        
    % Create the Main figure for settings window
    tmfc_set = figure('Name', 'TMFC Toolbox','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'norm', 'Position', [0.380 0.0875 0.250 0.850], 'color', 'w', 'Tag', 'TMFC_GUI_Settings','resize', 'off','WindowStyle','modal');
    
    % Text data to be displayed on the settings window
    set_str_1 = {'Parallel computing use Parallel Computing Toolbox. The number of workers in a parallel pool can be changed in MATLAB settings.'};
    set_str_2 = {'This option temporary changes resmem variable in spm_defaults, which governing whether temporary files during GLM estimation are stored on disk or kept in memory. If you have enough available RAM, not writing the files to disk will speed the estimation.'};
    set_str_3 = {'Max RAM temporary changes maxmem variable in spm_defaults, which indicates how much memory can be used at the same time during GLM estimation. If your computer has a large amount of RAM, you can increase that memory setting:'};
    set_str_4 = {'* 2^31 = 2GB','* 2^32 = 4GB', '* 2^33 = 8GB','* 2^34 = 16GB','* 2^35 = 32GB'};
    set_str_5 = {'Perform seed-to-voxel or ROI-to-ROI analysis or both. Applies to gPPI and BSC methods.','',...
        'Seed-to-voxel gPPI is computationally expensive and can take a long time as it estimates the gPPI model parameters for each voxel.','',...
        'Seed-to-voxel BSC calculates relatively fast (about as ROI-to-ROI analysis) since voxel-wise correlations are not computationally expensive.'};

    % Initializing Drop down menus of options for settings window
    % MP = Main  panel
    tmfc_set_MP1 = uipanel(tmfc_set,'Units', 'normalized','Position',[0.03 0.865 0.94 0.125],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    tmfc_set_MP2 = uipanel(tmfc_set,'Units', 'normalized','Position',[0.03 0.685 0.94 0.17],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    tmfc_set_MP3 = uipanel(tmfc_set,'Units', 'normalized','Position',[0.03 0.375 0.94 0.30],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    tmfc_set_MP4 = uipanel(tmfc_set,'Units', 'normalized','Position',[0.03 0.10 0.94 0.265],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    
    tmfc_set_P1 = uicontrol(tmfc_set,'Style','popupmenu', 'String', set_computing ,'Units', 'normalized', 'Position',[0.048 0.908 0.90 0.07],'fontunits','normalized', 'fontSize', 0.265);
    tmfc_set_P2 = uicontrol(tmfc_set,'Style','popupmenu', 'String', set_storage ,'Units', 'normalized', 'Position',[0.048 0.775 0.90 0.07],'fontunits','normalized', 'fontSize', 0.265);
    tmfc_set_P3 = uicontrol(tmfc_set,'Style','popupmenu', 'String', set_analysis ,'Units', 'normalized', 'Position',[0.048 0.282 0.90 0.07],'fontunits','normalized', 'fontSize', 0.265);
    
    tmfc_set_ok = uicontrol(tmfc_set,'Style', 'pushbutton', 'String', 'OK', 'Units', 'normalized', 'Position', [0.3 0.03 0.40 0.05],'FontUnits','normalized','FontSize',0.33,'callback', @sync_set);
    tmfc_set_E1 = uicontrol(tmfc_set,'Style','edit','String', tmfc.defaults.maxmem,'Units', 'normalized', 'HorizontalAlignment', 'center','Position',[0.72 0.615 0.22 0.05],'fontunits','normalized', 'fontSize', 0.38);
    
    tmfc_set_S1 = uicontrol(tmfc_set,'Style','text','String', set_str_1,'Units', 'normalized', 'Position',[0.05 0.87 0.90 0.07],'fontunits','normalized','fontSize', 0.245, 'HorizontalAlignment', 'left','backgroundcolor','w');
    tmfc_set_S2 = uicontrol(tmfc_set,'Style','text','String', set_str_2,'Units', 'normalized', 'Position',[0.05 0.69 0.90 0.11],'fontunits','normalized','fontSize', 0.16, 'HorizontalAlignment', 'left','backgroundcolor','w');
    tmfc_set_S3a = uicontrol(tmfc_set,'Style','text','String', 'Max RAM for GLM esimtation (bits):','Units', 'normalized', 'Position',[0.048 0.61 0.65 0.04],'fontunits','normalized', 'fontSize', 0.46,'HorizontalAlignment', 'left','backgroundcolor','w');%
    tmfc_set_S3 = uicontrol(tmfc_set,'Style','text','String', set_str_3,'Units', 'normalized', 'Position',[0.05 0.495 0.90 0.11],'fontunits','normalized','fontSize', 0.16, 'HorizontalAlignment', 'left','backgroundcolor','w');
    tmfc_set_S4 = uicontrol(tmfc_set,'Style','text','String', set_str_4,'Units', 'normalized', 'Position',[0.39 0.38 0.27 0.11],'fontunits','normalized','fontSize', 0.15, 'HorizontalAlignment', 'left','backgroundcolor','w');
    tmfc_set_S5 = uicontrol(tmfc_set,'Style','text','String', set_str_5,'Units', 'normalized', 'Position',[0.05 0.11 0.90 0.20],'fontunits','normalized','fontSize', 0.088, 'HorizontalAlignment', 'left','backgroundcolor','w');
    
    tmfc_copy = tmfc;

    % The following functions perform synchronization after OK button has been pressed 
    function sync_set(~,~)

       % SYNC: Computation type
       % Check status of string in stat box -> if changed -> SWAP
       % details -> Change TMFC variable -> END          

       C_1{1} = get(tmfc_set_P1, 'String');
       C_1{2} = get(tmfc_set_P1, 'Value');
       if strcmp(C_1{1}(C_1{2}),'Sequential computing')
           set_computing = {'Sequential computing','Parallel computing'};
           set(tmfc_set_P1, 'String', set_computing);
           tmfc.defaults.parallel = 0;

       elseif strcmp(C_1{1}(C_1{2}),'Parallel computing')
           set_computing = {'Parallel computing','Sequential computing',};
           set(tmfc_set_P1, 'String', set_computing);
           tmfc.defaults.parallel = 1;
       end
       clear C_1

       % SYNC: Storage type
       % Check status of string in stat box -> if changed -> SWAP
       % details -> Change TMFC variable -> END
       C_2{1} = get(tmfc_set_P2, 'String');
       C_2{2} = get(tmfc_set_P2, 'Value');
       if strcmp(C_2{1}(C_2{2}), 'Store temporary files for GLM estimation in RAM')
           set_storage = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
           set(tmfc_set_P2, 'String', set_storage);
           tmfc.defaults.resmem =  true;

       elseif strcmp(C_2{1}(C_2{2}), 'Store temporary files for GLM estimation on disk')
           set_storage = {'Store temporary files for GLM estimation on disk','Store temporary files for GLM estimation in RAM'};
           set(tmfc_set_P2, 'String', set_storage);
           tmfc.defaults.resmem =  false;
       end
       clear C_2
       
       % SYNC: Maximum Memory Value
       % Check status of string in stat box -> if changed -> SWAP
       % details -> Change TMFC variable -> END
       DG4_STR = get(tmfc_set_E1,'String');
       DG4 = eval(DG4_STR);
       if DG4 > 2^32
           set(tmfc_set_E1, 'String', DG4_STR);
           tmfc.defaults.maxmem = DG4;
       end
       
       C_4{1} = get(tmfc_set_P3, 'String');
       C_4{2} = get(tmfc_set_P3, 'Value');
       if strcmp(C_4{1}(C_4{2}), 'Seed-to-voxel and ROI-to-ROI')
           set_analysis = {'Seed-to-voxel and ROI-to-ROI','ROI-to-ROI only','Seed-to-voxel only'};
           set(tmfc_set_P3, 'String', set_analysis);
           tmfc.defaults.analysis =  1;

       elseif strcmp(C_4{1}(C_4{2}), 'ROI-to-ROI only')
           set_analysis = {'ROI-to-ROI only','Seed-to-voxel only','Seed-to-voxel and ROI-to-ROI'};
           set(tmfc_set_P3, 'String', set_analysis);
           tmfc.defaults.analysis =  2;
           
       elseif strcmp(C_4{1}(C_4{2}), 'Seed-to-voxel only')
           set_analysis = {'Seed-to-voxel only','Seed-to-voxel and ROI-to-ROI','ROI-to-ROI only'};
           set(tmfc_set_P3, 'String', set_analysis);
           tmfc.defaults.analysis =  3;
       end
       clear C_4
       
       % Comparision 
       if tmfc_copy.defaults.parallel == tmfc.defaults.parallel &&...
          tmfc_copy.defaults.maxmem == tmfc.defaults.maxmem &&...
          tmfc_copy.defaults.resmem == tmfc.defaults.resmem &&...
          tmfc_copy.defaults.analysis == tmfc.defaults.analysis 
           disp('Settings have not been changed.');
       else
           disp('Settings have been updated.');
       end
       close(tmfc_set);
    end   
end

%% =============================[ Close ]==================================
 
% Function to peform Save & Exit (Close button)
function close_GUI(ButtonH, EventData, TMFC_GUI) 
       
% Exit Dialog GUI
exit_msg = figure('Name', 'TMFC: Exit', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.20 0.15],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'EXIT_FIN', 'WindowStyle','modal'); %X Y W H

% Content - Can be changed to a single sentence using \html or sprtinf
ex_str1 = uicontrol(exit_msg,'Style','text','String', 'Would you like to save your progress','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38, 'Position',[0.04 0.55 0.94 0.260],'backgroundcolor',get(exit_msg,'color'));
ex_str2 = uicontrol(exit_msg,'Style','text','String', 'before exiting TMFC toolbox?', 'Units','normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38,'Position',[0.10 0.40 0.80 0.260],'backgroundcolor',get(exit_msg,'color'));

% Buttons of the GUI
ex_yes = uicontrol(exit_msg,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.40,'Position',[0.16 0.18 0.300 0.200],'callback', @ex_w_save);
ex_no = uicontrol(exit_msg,'Style','pushbutton', 'String', 'No','Units', 'normalized','fontunits','normalized', 'fontSize', 0.40,'Position',[0.57 0.18 0.300 0.200],'callback', @ex_wo_save);     

% Function to Exit toolbox WITHOUT saving TMFC variable
function ex_wo_save(~,~)
    % Closes Dialog box -> closes Main GUI
    close(exit_msg);
    delete(handles.TMFC_GUI);
    disp('Goodbye!');
end

% Function to Exit toolbox AFTER saving TMFC variable
function ex_w_save(~,~)
    % Performs saving of TMFC variable using SAVE_PROJECT function
    save_status = save_project_GUI();

    % Based on the result of successful save, TMFC toolbox is
    % closed (i.e. Save->Save Status-> Close Main GUI)
    if save_status == 1
        close(exit_msg);
        delete(handles.TMFC_GUI);
        disp('Goodbye!');
    end
end
    
end

%% ==========================[ Statistics ]================================
function statistics_GUI(ButtonH, EventData, TMFC_GUI)
    freeze_GUI(1);
    tmfc_statistics_GUI();
    freeze_GUI(0);
end

%% ===========================[ Results ]==================================
function results_GUI(ButtonH, EventData, TMFC_GUI)
    tmfc_results_GUI();
end

%% =================[ Freeze/unfreeze main TMFC GUI ]======================
function freeze_GUI(state)

    switch(state)
        case 0 
            state = 'on';
        case 1
            state = 'off';
    end
    set([handles.TMFC_GUI_B1, handles.TMFC_GUI_B2, handles.TMFC_GUI_B3, handles.TMFC_GUI_B4,...
                handles.TMFC_GUI_B5a, handles.TMFC_GUI_B5b, handles.TMFC_GUI_B6, handles.TMFC_GUI_B7,...
                handles.TMFC_GUI_B8, handles.TMFC_GUI_B9, handles.TMFC_GUI_B10, handles.TMFC_GUI_B11,...
                handles.TMFC_GUI_B12a,handles.TMFC_GUI_B12b,handles.TMFC_GUI_B13a,handles.TMFC_GUI_B13b,...
                handles.TMFC_GUI_B14a,handles.TMFC_GUI_B14b], 'Enable', state);

end      

%% ==============[ Reset main TMFC GUI & TMFC structure ]==================
function [tmfc] = major_reset(tmfc)

try 
    tmfc = rmfield(tmfc,'subjects');
end
try 
    tmfc = rmfield(tmfc,'project_path');
end
try 
    tmfc = rmfield(tmfc,'ROI_set');
end
try
    tmfc = rmfield(tmfc,'ROI_set_number');
end
try
    tmfc = rmfield(tmfc,'LSS');
end
try 
    tmfc = rmfield(tmfc,'FIR');
end
try
    tmfc = rmfield(tmfc,'LSS_after_FIR');
end

set([handles.TMFC_GUI_S1,handles.TMFC_GUI_S2], 'String', 'Not selected','ForegroundColor',[1, 0, 0]);
set([handles.TMFC_GUI_S3,handles.TMFC_GUI_S4,handles.TMFC_GUI_S6,handles.TMFC_GUI_S8,handles.TMFC_GUI_S10], 'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);

end

%% ===========[ Update VOI, PPI, gPPI and gPPI_FIR progress ]==============
function [tmfc] = update_gPPI(tmfc)

nSub  = length(tmfc.subjects);
nROI  = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);

try
    cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
    sess = []; sess_num = []; nSess = [];
    for iCond = 1:length(cond_list)
        sess(iCond) = cond_list(iCond).sess;
    end
    sess_num = unique(sess);
    nSess = length(sess_num);
    nCond = length(cond_list);    
end
    
% ------------------------[Update VOI progress]----------------------------

% Update TMFC structure
try
	for iSub = 1:nSub
        check_VOI = zeros(nROI,nSess);
        for jROI = 1:nROI
            for kSess = 1:nSess
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs',['Subject_' num2str(iSub,'%04.f')], ...
                        ['VOI_' tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name '_' num2str(kSess) '.mat']), 'file')
                    check_VOI(jROI,kSess) = 1;
                end
            end
        end
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI = double(~any(check_VOI(:) == 0));
    end
end

% Update main TMFC GUI
try
    track_VOI = 0;
    for iSub = 1:nSub
        if tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI == 0
            track_VOI = iSub;
            break;
        end
    end

    if track_VOI == 0
        set(handles.TMFC_GUI_S3, 'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);       
    elseif track_VOI == 1
        set(handles.TMFC_GUI_S3, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
    else
        set(handles.TMFC_GUI_S3, 'String', strcat(num2str(track_VOI-1), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);       
    end
end

% ------------------------[Update PPI progress]----------------------------

% Update TMFC structure
try
    for iSub = 1:nSub
        SPM = load(tmfc.subjects(iSub).path);
        check_PPI = zeros(nROI,nCond);
        for jROI = 1:nROI
            for kCond = 1:nCond
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs',['Subject_' num2str(iSub,'%04.f')], ...
                        ['PPI_[' regexprep(tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name,' ','_') ']_' cond_list(kCond).file_name '.mat']), 'file')
                    check_PPI(jROI,kCond) = 1;
                end
            end
        end
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = double(~any(check_PPI(:) == 0));
        clear SPM
    end
end 

% Update main TMFC GUI
try
    track_PPI = 0;
    for iSub = 1:nSub
        if tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI == 0
            track_PPI = iSub;
            break;
        end
    end
    if track_PPI == 0
        set(handles.TMFC_GUI_S4, 'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);       
    elseif track_PPI == 1
        set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
    else
        set(handles.TMFC_GUI_S4, 'String', strcat(num2str(track_PPI-1), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);       
    end
end

% ------------------------[Update gPPI progress]---------------------------

% Update TMFC structure
try
    for iSub = 1:nSub
        check_gPPI = ones(1,nCond);
        for jCond = 1:nCond
            % Check ROI-to-ROI files
            if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI','ROI_to_ROI','symmetrical', ...
                                 ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.mat']),'file')
                    check_gPPI(jCond) = 0;
                end
            end
            % Check seed-to-voxel files
            if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI','Seed_to_voxel',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                                 ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.nii']),'file')
                    check_gPPI(jCond) = 0;
                end
            end
        end
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI = double(~any(check_gPPI(:) == 0));
    end
end

% -----------------------[Update gPPI-FIR progress]------------------------

% Update TMFC structure
try
    for iSub = 1:nSub
        check_gPPI_FIR = ones(1,nCond);
        for jCond = 1:nCond
            % Check ROI-to-ROI files
            if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','symmetrical', ...
                                 ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.mat']),'file')
                    check_gPPI_FIR(jCond) = 0;
                end
            end
            % Check seed-to-voxel files
            if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR','Seed_to_voxel',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                                 ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.nii']),'file')
                    check_gPPI_FIR(jCond) = 0;
                end
            end
        end
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = double(~any(check_gPPI_FIR(:) == 0));
    end
end

end

%% ====[ Reset VOI, PPI, gPPI, gPPI-FIR progress and delete old files ]====
function [tmfc] = reset_gPPI(tmfc,cases)

disp('Deleting old files...');

switch cases
    
	case 1
        % Reset all: VOI, PPI, gPPI, gPPI-FIR        
        for iSub = 1:length(tmfc.subjects)
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = 0;
        end
        set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
        
        % Delete old VOI files
        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs'),'s'); 
        
    case 2 
        % Reset PPI, gPPI, gPPI-FIR 
        for iSub = 1:length(tmfc.subjects)
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = 0;
        end
        set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
end

% Delete old PPI files
if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs'))
    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs'),'s');
end

% Delete old gPPI files
if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI'))
    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI'),'s');
end

% Delete old gPPI-FIR files
if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR'))
    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR'),'s');
end

% Clear contrasts
try
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts = rmfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'gPPI');
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts = rmfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'gPPI_FIR');
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI.title = [];
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI.weights = [];
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR.title = [];
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR.weights = [];
end

end

%% =======[ Update the main TMFC GUI after loading a TMFC project ]========
function tmfc = load_project(tmfc) 
    
    try
        freeze_GUI(1);
    try
        cd(tmfc.project_path); 
    end
    
    % Update subjects
    try
        set(handles.TMFC_GUI_S1,'String', strcat(num2str(length(tmfc.subjects)), ' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
    end
   
    % Update ROI set
    try 
        if isfield(tmfc,'ROI_set_number')            
            set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(tmfc.ROI_set_number).set_name, ' (',num2str(length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]); 
        elseif isfield(tmfc,'ROI_set')
            tmfc.ROI_set_number = 1;
            set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(tmfc.ROI_set_number).set_name, ' (',num2str(length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]); 
        end
    end
    
    % Update FIR
    try
        % Track
        for subi = 1:length(tmfc.subjects)              
            SPM = load(tmfc.subjects(subi).path);
            if exist(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(subi,'%04.f')],['Res_' num2str(sum(SPM.SPM.nscan),'%04.f') '.nii']), 'file')

               tmfc.subjects(subi).FIR = 1;
            else           
               tmfc.subjects(subi).FIR = 0;       
            end

        end
        try
            SZ_tmfc = size(tmfc.subjects);
            V_FIR = 0;
            for i = 1:length(tmfc.subjects) 
                % checking status of FIR completion
                if tmfc.subjects(i).FIR == 0
                    V_FIR = i ;
                    break;
                end
            end

            if V_FIR == 0
                set(handles.TMFC_GUI_S8,'String', strcat(num2str(length(tmfc.subjects) ), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_FIR == 1
                set(handles.TMFC_GUI_S8,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S8,'String', strcat(num2str(V_FIR-1), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
        pause(0.1); 
    end

    % update BGFC
    try
       try
       SPM = load(tmfc.subjects(1).path); 
        for subi = 1:length(tmfc.subjects)
           for j = 1:length(SPM.SPM.Sess)       
               if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC','ROI_to_ROI', ... 
                           ['Subject_' num2str(subi,'%04.f') '_Session_' num2str(j) '.mat']), 'file')
                   check(j) = 1;
               else
                   check(j) = 0;
               end
           end
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).BGFC = double(~any(check==0));
            clear check
        end
        clear SPM
       end
       try
            SZ_tmfc = size(tmfc.subjects);
            track_BGFC = 0;
            for i = 1:length(tmfc.subjects) 
                % checking status of BGFC completion
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BGFC == 0
                    track_BGFC = i ;
                    break;
                end
            end
       end
    end
    
    
    tmfc = update_gPPI(tmfc);
    
    % update LSS
     try
     
     % code-----
        L_break = 0;
        V_LSS = 0;
        cond_list = tmfc.LSS.conditions;
        sess = []; sess_num = []; N_sess = [];
        for i = 1:length(cond_list)
            sess(i) = cond_list(i).sess;
        end
        sess_num = unique(sess);
        N_sess = length(sess_num);

        for subi = 1:length(tmfc.subjects)              
            SPM = load(tmfc.subjects(subi).path);
            for j = 1:N_sess 
                % Trials of interest
                E = 0;
                trial.cond = [];
                trial.number = [];
                for k = 1:length(cond_list)
                    if cond_list(k).sess == sess_num(j)
                        E = E + length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons);
                        trial.cond = [trial.cond; repmat(cond_list(k).number,length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons),1)];
                        trial.number = [trial.number; (1:length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons))'];
                    end
                end
                % Check
                for k = 1:E
                    if exist(fullfile(tmfc.project_path,'LSS_regression',['Subject_' num2str(subi,'%04.f')],'GLM_batches', ...
                                            ['GLM_[Sess_' num2str(sess_num(j)) ']_[Cond_' num2str(trial.cond(k)) ']_[' ...
                                            regexprep(char(SPM.SPM.Sess(sess_num(j)).U(trial.cond(k)).name),' ','_') ']_[Trial_' ...
                                            num2str(trial.number(k)) '].mat']), 'file')
                       condition(trial.cond(k)).trials(trial.number(k)) = 1;
                    else           
                       condition(trial.cond(k)).trials(trial.number(k)) = 0;
                    end
                end
                tmfc.subjects(subi).LSS.session(sess_num(j)).condition = condition;
                clear condition
            end
            clear SPM E trial
        end
        clear cond_list sess sess_num N_sess
        % code ---
        
        try
            SZ_tmfc = size(tmfc.subjects);
            allValues = [tmfc.LSS.conditions.sess];
            SZS_tmfc = max(allValues); % maximum Sessions
            SZC_tmfc = size(tmfc.LSS.conditions); % maximum Conditions
            condi = 0;
            if SZC_tmfc(2) == 1 
                condi = tmfc.LSS.conditions.number;
            end
            for i = 1:length(tmfc.subjects) 
                % Checking status of LSS completion
                if L_break == 1
                    break;
                else
                    for j = 1:SZS_tmfc
                        if L_break == 1
                            break;
                        else
                            for k = 1:SZC_tmfc(2)
                                if L_break == 1
                                    break;
                                else
                                    if ~condi==0
                                        % if there is only one condition
                                        if any(tmfc.subjects(i).LSS.session(j).condition(condi).trials == 0)
                                            V_LSS = i ;
                                            L_break = 1;
                                            break;
                                        end
                                    else
                                        if any(tmfc.subjects(i).LSS.session(j).condition(k).trials == 0)
                                            V_LSS = i ;
                                            L_break = 1;
                                            break;
                                        end
                                    end
                                end
                            end
                        end
                    end                
                end
            end

            if V_LSS == 0
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(length(tmfc.subjects) ), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_LSS == 1
                set(handles.TMFC_GUI_S6,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(V_LSS-1), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
        pause(0.1); 
     end
     
             
     % LSS after FIR
     try
     L_break = 0;
     V_LSS = 0;

     % code-----
        cond_list = tmfc.LSS_after_FIR.conditions;
        sess = []; sess_num = []; N_sess = [];
        for i = 1:length(cond_list)
            sess(i) = cond_list(i).sess;
        end
        sess_num = unique(sess);
        N_sess = length(sess_num);

        for subi = 1:length(tmfc.subjects)              
            SPM = load(tmfc.subjects(subi).path);
            for j = 1:N_sess 
                % Trials of interest
                E = 0;
                trial.cond = [];
                trial.number = [];
                for k = 1:length(cond_list)
                    if cond_list(k).sess == sess_num(j)
                        E = E + length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons);
                        trial.cond = [trial.cond; repmat(cond_list(k).number,length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons),1)];
                        trial.number = [trial.number; (1:length(SPM.SPM.Sess(sess_num(j)).U(cond_list(k).number).ons))'];
                    end
                end
                % Check
                for k = 1:E
                    if exist(fullfile(tmfc.project_path,'LSS_regression_after_FIR',['Subject_' num2str(subi,'%04.f')],'GLM_batches', ...
                                            ['GLM_[Sess_' num2str(sess_num(j)) ']_[Cond_' num2str(trial.cond(k)) ']_[' ...
                                            regexprep(char(SPM.SPM.Sess(sess_num(j)).U(trial.cond(k)).name),' ','_') ']_[Trial_' ...
                                            num2str(trial.number(k)) '].mat']), 'file')
                       condition(trial.cond(k)).trials(trial.number(k)) = 1;
                    else           
                       condition(trial.cond(k)).trials(trial.number(k)) = 0;
                    end
                end
                tmfc.subjects(subi).LSS_after_FIR.session(sess_num(j)).condition = condition;
                clear condition
            end
            clear SPM E trial
        end
        clear cond_list sess sess_num N_sess
        % code ---

        try
            SZ_tmfc = size(tmfc.subjects);
            allValues = [tmfc.LSS_after_FIR.conditions.sess];
            SZS_tmfc = max(allValues); % maximum Sessions
            SZC_tmfc = size(tmfc.LSS_after_FIR.conditions); % maximum Conditions
            condi = 0;
            if SZC_tmfc(2) == 1 
                condi = tmfc.LSS_after_FIR.conditions.number;
            end
            for i = 1:length(tmfc.subjects) 
                % Checking status of LSS after FIR completion
                if L_break == 1
                    break;
                else
                    for j = 1:SZS_tmfc
                        if L_break == 1
                            break;
                        else
                            for k = 1:SZC_tmfc(2)
                                if L_break == 1
                                    break;
                                else
                                    if ~condi==0
                                        % if there is only one condition
                                        if any(tmfc.subjects(i).LSS_after_FIR.session(j).condition(condi).trials == 0)
                                            V_LSS = i ;
                                            L_break = 1;
                                            break;
                                        end
                                    else
                                        if any(tmfc.subjects(i).LSS_after_FIR.session(j).condition(k).trials == 0)
                                            V_LSS = i ;
                                            L_break = 1;
                                            break;
                                        end
                                    end
                                end
                            end
                        end
                    end                
                end
            end

            if V_LSS == 0
                set(handles.TMFC_GUI_S10,'String', strcat(num2str(length(tmfc.subjects) ), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_LSS == 1
                set(handles.TMFC_GUI_S10,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S10,'String', strcat(num2str(V_LSS-1), '/', num2str(length(tmfc.subjects) ), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
        pause(0.1); 
    end
     
     switch tmfc.defaults.parallel
         case 1
             set_computing = {'Parallel computing','Sequential computing',};           
         case 0 
            set_computing = {'Sequential computing','Parallel computing'};
     end   
     
     switch tmfc.defaults.resmem
         case true
         	set_storage = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
         case false 
            set_storage = {'Store temporary files for GLM estimation on disk','Store temporary files for GLM estimation in RAM'};
     end          
     
     switch tmfc.defaults.analysis
         case 1
             set_analysis = {'Seed-to-voxel and ROI-to-ROI','ROI-to-ROI only','Seed-to-voxel only'};
         case 2 
             set_analysis = {'ROI-to-ROI only','Seed-to-voxel only','Seed-to-voxel and ROI-to-ROI'};
         case 3
             set_analysis = {'Seed-to-voxel only','Seed-to-voxel and ROI-to-ROI','ROI-to-ROI only'};
     end
     
     freeze_GUI(0);
    catch
        warning('Error with reading save file');
    end
    
end

% Calculate seed-to-voxel and/or ROI-to-ROI contrast
function seed2vox_or_ROI2ROI(tmfc,contrast_number,analysis_type)

switch(tmfc.defaults.analysis)

	case 1  % Seed-to-voxel and ROI-to-ROI analyses

        % ROI-to-ROI 
        sub_check_ROI2ROI = tmfc_ROI_to_ROI_contrast(tmfc,analysis_type,contrast_number,tmfc.ROI_set_number);                           
        if sub_check_ROI2ROI(length(tmfc.subjects)) == 1
        	fprintf('ROI-to-ROI contrast calculated: No %d.\n',contrast_number);
        else
        	warning('ROI-to-ROI contrast failed.');
        end

        % Seed-to-voxel
        sub_check_seed2vox = tmfc_seed_to_voxel_contrast(tmfc,analysis_type,contrast_number,tmfc.ROI_set_number);
        if sub_check_seed2vox(length(tmfc.subjects)) == 1
        	fprintf('Seed-to-voxel contrast calculated: No %d.\n',contrast_number);
        else
        	warning('Seed-to-voxel contrast failed.');
        end

    case 2  % ROI-to-ROI only

        sub_check_ROI2ROI = tmfc_ROI_to_ROI_contrast(tmfc,analysis_type,contrast_number,tmfc.ROI_set_number);                           
        if sub_check_ROI2ROI(length(tmfc.subjects)) == 1
        	fprintf('ROI-to-ROI contrast calculated: No %d.\n',contrast_number);
        else
        	warning('ROI-to-ROI contrast failed.');
        end

    case 3  % Seed-to-voxel only

        sub_check_seed2vox = tmfc_seed_to_voxel_contrast(tmfc,analysis_type,contrast_number,tmfc.ROI_set_number);
        if sub_check_seed2vox(length(tmfc.subjects)) == 1
        	fprintf('Seed-to-voxel contrast calculated: No %d.\n',contrast_number);
        else
        	disp('Seed-to-voxel contrast failed.');
        end
end
end

% ================================[ END ]==================================

end


%% ======================================================================== 
%  ========================[ Internal functions ]==========================
%  ========================================================================

%% Select TMFC project folder dialog window 
function tmfc_select_project_path(nSub)

tmfc_project_path_GUI = figure('Name', 'Select project paths', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.24 0.14], 'MenuBar', 'none', 'ToolBar', 'none', ...
                          'color', 'w', 'Resize', 'off', 'WindowStyle', 'modal', 'CloseRequestFcn', @ok_action, 'Tag', 'TMFC_project_path');
project_path_string = {'Next, select the project path where all results and temporary files will be stored'};
% PP = project path
tmfc_PP_GUI_S1 = uicontrol(tmfc_project_path_GUI, 'Style', 'text', 'String', strcat(num2str(nSub), ' subjects selected'), 'Units', 'normalized', 'Position', [0.30 0.72 0.40 0.17], 'backgroundcolor', 'w', 'fontunits', 'normalized', 'fontSize', 0.64,'ForegroundColor', [0.219, 0.341, 0.137]);
tmfc_PP_GUI_S2 = uicontrol(tmfc_project_path_GUI, 'Style', 'text', 'String', project_path_string, 'Units', 'normalized', 'Position', [0.055 0.38 0.90 0.30], 'backgroundcolor', 'w', 'fontunits', 'normalized', 'fontSize', 0.38);
tmfc_PP_GUI_OK = uicontrol(tmfc_project_path_GUI, 'Style', 'pushbutton', 'String', 'OK', 'Units', 'normalized', 'Position', [0.35 0.12 0.3 0.2], 'fontunits', 'normalized', 'fontSize', 0.42, 'callback', @ok_action);
movegui(tmfc_project_path_GUI,'center');

function ok_action(~,~)
    delete(tmfc_project_path_GUI);
end

uiwait();
end

%% ROI set related functions

% =========================================================================
% Reset TMFC analysis progress for selected ROI set
% =========================================================================
function [tmfc] = ROI_set_initializer(tmfc)

for iSub = 1:length(tmfc.subjects)
   tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BGFC = 0;
   tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC = 0;
   tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC_after_FIR = 0;       
   tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI = 0;       
   tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = 0;       
   tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI = 0;       
   tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = 0;       
end

tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI.title = [];
tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI.weights = [];

tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR.title = [];
tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR.weights = [];

tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC.title = [];
tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC.weights = [];

tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR.title = [];
tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR.weights = [];

end

% =========================================================================
% Switch between previously defined ROI sets or add a new ROI Set
% =========================================================================
function [ROI_set_check, ROI_set_number] = ROI_set_switcher(ROI_set_list)

ROI_set_check = 0;
ROI_set_number = 0;
tmp_set_number = 1;

ROI_set_GUI = figure('Name', 'Select ROI set', 'NumberTitle', 'off', 'Units', 'normalized', ...
                    'Position', [0.35 0.40 0.28 0.35], 'color', 'w', 'MenuBar', 'none', 'ToolBar', 'none');
                
ROI_set_GUI_disp =   uicontrol(ROI_set_GUI, 'Style', 'listbox', 'String', ROI_set_list(:,2), 'Units', 'normalized', ...
                    'Position', [0.048 0.25 0.91 0.49], 'fontunits', 'normalized', 'fontSize', 0.09, 'Value', 1, 'callback', @ROI_set_select);
                
ROI_set_GUI_S1 =     uicontrol(ROI_set_GUI, 'Style', 'text', 'String', 'Select ROI set', 'Units', 'normalized', 'fontunits', 'normalized', 'fontSize', 0.54, ...
                    'Position', [0.31 0.85 0.400 0.09], 'backgroundcolor', get(ROI_set_GUI,'color'));
                
ROI_set_GUI_S2 =     uicontrol(ROI_set_GUI, 'Style', 'text', 'String', 'Sets:', 'Units', 'normalized', 'fontunits', 'normalized', 'fontSize', 0.60, ...
                    'Position', [0.04 0.74 0.100 0.08], 'backgroundcolor', get(ROI_set_GUI,'color'));
                
ROI_set_GUI_ok =     uicontrol(ROI_set_GUI, 'Style', 'pushbutton', 'String', 'OK', 'Units', 'normalized', 'fontunits', 'normalized', 'fontSize', 0.4, ...
                    'Position', [0.16 0.10 0.28 0.10], 'callback', @ROI_set_ok);
                
ROI_set_GUI_Select = uicontrol(ROI_set_GUI, 'Style', 'pushbutton', 'String', 'Add new ROI set', 'Units', 'normalized', 'fontunits', 'normalized', 'fontSize', 0.4, ...
                    'Position', [0.56 0.10 0.28 0.10], 'callback', @ROI_set_add_new);
   
movegui(ROI_set_GUI,'center');

function ROI_set_select(~,~)
    index = get(ROI_set_GUI_disp, 'Value');
    tmp_set_number = index;    
end

function ROI_set_ok(~,~)
    ROI_set_check = 0;
    ROI_set_number = tmp_set_number;
    close(ROI_set_GUI);
end

function ROI_set_add_new(~,~)
    ROI_set_check = 1;
    ROI_set_number = 0;
    close(ROI_set_GUI);
end

uiwait();  

end

%% Restart/continue dialog windows

% =========================================================================
% Function to ask user to restart computations:
% restart_status = 1 - restart 
% restart_status = 0 - do not restart 
% =========================================================================
function [restart_status] = tmfc_restart_GUI(option)

restart_str_0 = '';
restart_str_1 = {};
    
switch option
	case 1
        % FIR
        restart_str_0 = 'FIR task regression';
        restart_str_1 = {'Recompute FIR task', 'regression for all subjects?'};
    case 2
        % LSS
        restart_str_0 = 'LSS GLM regression';
        restart_str_1 = {'Recompute LSS GLM', 'regression for all subjects?'};
    case 3
        % LSS after FIR
        restart_str_0 = 'LSS after FIR regression';
        restart_str_1 = {'Recompute LSS after FIR', 'regression for all subjects?'};
    case 4
        % VOIs
        restart_str_0 = 'VOI computation';
        restart_str_1 = {'Recompute VOIs', 'for all subjects?'};
    case 5
        % PPIs
        restart_str_0 = 'PPI computation';
        restart_str_1 = {'Recompute PPIs', 'for all subjects?'};
end
    
tmfc_restart_MW = figure('Name', restart_str_0, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.18 0.14], ...
                  'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Restart_WIN','CloseRequestFcn', @cancel);
tmfc_restart_str = uicontrol(tmfc_restart_MW,'Style','text','String',restart_str_1 ,'Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', ...
                       'fontSize', 0.40, 'Position', [0.10 0.55 0.80 0.260],'backgroundcolor',get(tmfc_restart_MW,'color'));
tmfc_restart_ok = uicontrol(tmfc_restart_MW,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized', ...
                       'fontSize', 0.48, 'Position', [0.14 0.22 0.320 0.20],'callback', @restart);
tmfc_restart_cancel = uicontrol(tmfc_restart_MW,'Style','pushbutton', 'String', 'Cancel','Units', 'normalized','fontunits','normalized', ...
                       'fontSize', 0.48,'Position',[0.52 0.22 0.320 0.20],'callback', @cancel);
                   
movegui(tmfc_restart_MW,'center');

% Function to close the restart dialog window
function cancel(~,~)
    restart_status = 0;
    delete(tmfc_restart_MW);
end

% Function to restart computations
function restart(~,~)
    restart_status = 1;
    delete(tmfc_restart_MW);
end

uiwait();
    
end

% =========================================================================
% Function to ask user to restart or continue computations:
% continue_status = 1    - continue 
% continue_status = 0    - restart 
% continue_status = -1   - cancel
% =========================================================================
function [continue_status] = tmfc_continue_GUI(iSub,option)
    
cont_str_0 = '';
cont_str_1 = {};
restart_str = '';
switch (option)
    case 1
        % FIR
        cont_str_0 = 'FIR task regression';
        cont_str_1 = {'Continue FIR task regression from'};
        restart_str = '<html>&#160 No, start from <br>the first subject';
    case 2
        % LSS
        cont_str_0 = 'LSS GLM regression';
        cont_str_1 = {'Continue LSS GLM regression from'};
        restart_str = '<html>&#160 No, start from <br>the first subject';
    case 3
        % LSS after FIR
        cont_str_0 = 'LSS after FIR regression';
        cont_str_1 = {'Continue LSS after FIR regression from'};
        restart_str = '<html>&#160 No, start from <br>the first subject';
    case 4 
        % VOIs
        cont_str_0 = 'VOI computation';
        cont_str_1 = {'Continue VOI computation from'};
        restart_str = '<html>&#160 No, start from <br>the first subject';
    case 5
        % PPIs
        cont_str_0 = 'PPI computation';
        cont_str_1 = {'Continue PPI computation from'};
        restart_str = 'Cancel';
    case 6
        % gPPIs
        cont_str_0 = 'gPPI computation';
        cont_str_1 = {'Continue gPPI computation from'};
        restart_str = 'Cancel';
    case 7
        % gPPI FIR
        cont_str_0 = 'gPPI FIR computation';
        cont_str_1 = {'Continue gPPI FIR computation from'};
        restart_str = 'Cancel';
    case 8
        % BGFC
        cont_str_0 = 'BGFC computation';
        cont_str_1 = {'Continue BGFC computation from'};
        restart_str = 'Cancel';            
end


tmfc_cont_MW = figure('Name', cont_str_0, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.20 0.18], 'Resize', 'off', 'color', 'w', ...
                  'MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Contd_FIR','CloseRequestFcn', @cancel); 
tmfc_cont_str1 = uicontrol(tmfc_cont_MW,'Style','text','String', cont_str_1,'Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', ...
                        'fontSize', 0.38, 'Position',[0.10 0.55 0.80 0.260],'backgroundcolor',get(tmfc_cont_MW,'color'));
tmfc_cont_str2 = uicontrol(tmfc_cont_MW,'Style','text','String', strcat('subject No',num2str(iSub),'?'), 'Units','normalized', 'HorizontalAlignment', 'center', ...
                        'fontunits','normalized', 'fontSize', 0.38, 'Position',[0.10 0.40 0.80 0.260],'backgroundcolor',get(tmfc_cont_MW,'color'));
tmfc_cont_yes = uicontrol(tmfc_cont_MW,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.28, ...
                         'Position',[0.12 0.15 0.320 0.270],'callback', @cont);
tmfc_cont_restart = uicontrol(tmfc_cont_MW,'Style','pushbutton', 'String', restart_str,'Units', 'normalized','fontunits','normalized', 'fontSize', 0.28, ...
                             'Position',[0.56 0.15 0.320 0.270],'callback', @restart);
movegui(tmfc_cont_MW,'center');

% Function to close the continue dialog window
function cancel(~,~)
	continue_status = -1;
    delete(tmfc_cont_MW);
end

% Function to continue computations
function cont(~,~)
    continue_status = 1;
    delete(tmfc_cont_MW);
end

% Function to restart computations
function restart(~,~)
    if ~strcmp(restart_str, 'Cancel')
        continue_status = 0;
        delete(tmfc_cont_MW);
    else
        continue_status = -1;
        delete(tmfc_cont_MW);
    end
end

uiwait();

end

%% Dialog box for PPI recomputation explanation
function PPI_recompute()
    PPI_recomp_GUI = figure('Name', 'PPI', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.24 0.12],'MenuBar', 'none', ...
                           'ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @ok_action, 'Tag', 'PPI');
    PPI_details = {'PPI computation completed.','To change conditions of interest, recompute VOIs.'};
    
    PPI_recomp_str = uicontrol(PPI_recomp_GUI,'Style','text','String',PPI_details,'Units', 'normalized', 'Position',[0.05 0.5 0.90 0.30], ...
                            'backgroundcolor','w','fontunits','normalized','fontSize', 0.38);
    PPI_recomp_ok = uicontrol(PPI_recomp_GUI,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.38 0.18 0.23 0.2], ...
                            'fontunits','normalized','fontSize', 0.48,'callback', @ok_action);
    
    movegui(PPI_recomp_GUI,'center');
    
    function ok_action(~,~)
        delete(PPI_recomp_GUI);
    end
    uiwait();
end

%% GUI to select Windows & Bins for FIR & gPPI FIR 
function [win, bin] = tmfc_FIR_GUI(cases)

	% case 0 = FIR 
	% case 1 = gPPI FIR
	switch (cases)
        case 0
        	GUI_title = 'FIR task regression'; 
            ST1 = 'Enter FIR window length (in seconds):';
            ST2 = 'Enter the number of FIR time bins:';
            ST_HP = 'FIR task regression: Help';
    
        case 1
            GUI_title = 'gPPI FIR computation'; 
            ST1 = 'Enter FIR window length (in seconds) for gPPI:';
            ST2 = 'Enter the number of FIR time bins for gPPI:';
            ST_HP = 'gPPI FIR: Help';
	end
    
    
    % TMFC_FIR_BW_GUI = BW = Bins and Window
    tmfc_FIR_BW_GUI = figure('Name', title_GUI_win, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.22 0.18],'Resize','off',...
        'MenuBar', 'none', 'ToolBar', 'none','Tag','TMFC_WB_NUM', 'WindowStyle','modal','CloseRequestFcn', @tmfc_FIR_BW_GUI_Exit); 
    set(gcf,'color','w');
    % S1, S2 = String 1, 2
    % E1, E2 = Edit box 1, Edit box 2, to enter Number of bins and window
    tmfc_FIR_BW_GUI_S1 = uicontrol(tmfc_FIR_BW_GUI,'Style','text','String', GUI_str_1,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40, 'Position',[0.08 0.62 0.65 0.200],'backgroundcolor',get(tmfc_FIR_BW_GUI,'color'));
    tmfc_FIR_BW_GUI_S2 = uicontrol(tmfc_FIR_BW_GUI,'Style','text','String', GUI_str_2,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40,'Position',[0.08 0.37 0.65 0.200],'backgroundcolor',get(tmfc_FIR_BW_GUI,'color'));
    tmfc_FIR_BW_GUI_E1 = uicontrol(tmfc_FIR_BW_GUI,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.67 0.185 0.170], 'fontSize', 0.44);
    tmfc_FIR_BW_GUI_E2 = uicontrol(tmfc_FIR_BW_GUI,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.42 0.185 0.170], 'fontSize', 0.44);
    tmfc_FIR_BW_GUI_ok = uicontrol(tmfc_FIR_BW_GUI,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.21 0.13 0.230 0.170],'callback', @tmfc_FIR_BW_extract);
    tmfc_FIR_BW_GUI_help = uicontrol(tmfc_FIR_BW_GUI,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.52 0.13 0.230 0.170],'callback', @tmfc_FIR_help_GUI);
    movegui(tmfc_FIR_BW_GUI,'center');
   
    function tmfc_FIR_BW_GUI_Exit(~,~)
    	win = NaN; 
    	bin = NaN; 
    	delete(tmfc_FIR_BW_GUI);
    end

    % Generates the HELP WINDOW within the GUI 
    function tmfc_FIR_help_GUI(~,~)

        tmfc_FIR_help = figure('Name', GUI_str_help, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.62 0.26 0.22 0.48],'Resize','off','MenuBar', 'none','ToolBar', 'none');
        set(gcf,'color','w');

        tmfc_help_str = {'Finite impulse response (FIR) task regression are used to remove co-activations from BOLD time-series.','',...
            'Co-activations are simultaneous (de)activations', 'without communication between brain regions.',...
            '',...
            'Co-activations spuriously inflate task-modulated','functional connectivity (TMFC) estimates.','',...
            'This option regress out (1) co-activations with any','possible shape and (2) confounds specified in the original',...
            'SPM.mat file (e.g., motion, physiological noise, etc).',...
            '','Functional images for residual time-series(Res_*.nii in',...
            'FIR_GLM folders) will be further used for TMFC analysis.','',...
            'Typically, the FIR window length covers the duration of',...
            'the event and an additional 18s to account for the likely',...
            'duration of the hemodynamic response.','',...
            'Typically, the FIR time bin is equal to one repetition time',...
            '(TR). Therefore, the number of FIR time bins is equal to:',''};
            TMFC_BW_DETAILS_2 = {'Number of FIR bins = FIR window length/TR'};

        tmfc_FIR_help_S1 = uicontrol(tmfc_FIR_help,'Style','text','String', tmfc_help_str,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.035, 'Position',[0.06 0.16 0.885 0.800],'backgroundcolor',get(tmfc_FIR_help,'color'));
        tmfc_FIR_help_S2 = uicontrol(tmfc_FIR_help,'Style','text','String', TMFC_BW_DETAILS_2,'Units', 'normalized', 'HorizontalAlignment', 'Center','fontunits','normalized', 'fontSize', 0.30, 'Position',[0.06 0.10 0.885 0.10],'backgroundcolor',get(tmfc_FIR_help,'color'));
        tmfc_FIR_help_ok = uicontrol(tmfc_FIR_help,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35, 'Position',[0.39 0.04 0.240 0.070],'callback', @tmfc_FIR_help_close);

        function tmfc_FIR_help_close(~,~)
            close(tmfc_FIR_help);
        end
    end

    % Function to extract the entered number from the user
    function tmfc_FIR_BW_extract(~,~)

       Window = str2double(get(tmfc_FIR_BW_GUI_E1, 'String'));
       bins = str2double(get(tmfc_FIR_BW_GUI_E2, 'String'));

       if isnan(Window)
           warning('Please enter a numeric value for the number of windows');
       elseif ~isnan(Window) && isnan(bins)
           warning('Please eneter a numeric value for the number of bins');
       elseif Window == 0 || Window < 0
           warning('Entered value for ''Windows'' cannot be zero or negative, Please re-enter');
       elseif bins == 0 || bins < 0
           warning('Entered value for ''Bins'' cannot be zero or negative, Please re-enter');
       else
           win = Window; 
           bin = bins;   
           delete(tmfc_FIR_BW_GUI);
       end

    end

uiwait();
    
end

%% Dialog box for BGFC recomputation
function recompute_BGFC(tmfc)

recompute_BGFC_GUI = figure('Name', 'BGFC', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.5 0.12], ...
    'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @ok_action, 'Tag', 'BGFC');    
BGFC_details = {strcat('BGFC was calculated for all subjects. FIR settings: ', 32, num2str(tmfc.FIR.window), ...
             ' [s] window and ', 32, num2str(tmfc.FIR.bins),' time bins.'),...
             'To calculate BGFC with different FIR settings, recompute FIR task regression with desired window length and number of time bins.'};
BGFC_recomp_GUI_S1 = uicontrol(recompute_BGFC_GUI,'Style','text','String',BGFC_details,'Units', 'normalized', 'Position',[0.05 0.5 0.90 0.30],'fontunits','normalized','fontSize', 0.38,'backgroundcolor','w');
BGFC_recomp_ok = uicontrol(recompute_BGFC_GUI,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.45 0.18 0.1 0.24],'fontunits','normalized','fontSize', 0.40,'callback', @ok_action);
movegui(recompute_BGFC_GUI,'center');

function ok_action(~,~)
    delete(recompute_BGFC_GUI);
end

uiwait();

end

% =================================[ END ]=================================
