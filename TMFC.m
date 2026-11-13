function TMFC
    
% =====[ Task-Modulated Functional Connectivity (TMFC) toolbox v1.9.7 ]====
%
% Opens the main GUI window.
%
% The tmfc structure has the following fields:
%    
%   tmfc.defaults.parallel  - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem    - e.g. 2^32 = 4GB (how much RAM can be used at
%                             the same time during GLM estimation)
%   tmfc.defaults.resmem    - true or false (store temporary files during
%                             GLM estimation in RAM or on disk)
%   tmfc.defaults.analysis  - 1 (Seed-to-voxel and ROI-to-ROI analyses)
%                           - 2 (ROI-to-ROI analysis only)
%                           - 3 (Seed-to-voxel analysis only)
%
%   tmfc.session_mode       - 'strict' or 'repeated'
%                             'strict'   - same number of runs with
%                                          corresponding run-specific conditions
%                             'repeated' - exchangeable repeated runs with the
%                                          same condition structure; subjects may
%                                          have different numbers of runs
%
%   tmfc.subject_naming     - 'original' - use original subject folder names
%                             'standard' - use Subject_XXXX names
%
%   tmfc.next_subject       - Next available Subject_XXXX number
%                             (used with standard naming)
%   
%   tmfc.project_path       - The path where all results will be saved
%   
%   tmfc.subjects.path      - Paths to individual subject SPM.mat files
%   tmfc.subjects.name      - Subject names within the TMFC project
%                             (original subject names are used by default)
%
%   tmfc.subjects.FIR             - 1 or 0 (completed or not)
%   tmfc.subjects.LSS             - 1 or 0 (completed or not)
%   tmfc.subjects.LSS_after_FIR   - 1 or 0 (completed or not)
%
%   tmfc.ROI_set            - Information about the selected ROI set
%                             and completed TMFC procedures
%                             (see tmfc_select_ROIs_GUI and
%                              tmfc_create_ROI_set)
%
%   tmfc.ROI_set_number     - The number of the ROI set currently selected
%
%   tmfc.FIR.window         - FIR window length [seconds]
%   tmfc.FIR.bins           - Number of FIR time bins
%
%   tmfc.LSS.conditions             - Conditions of interest for LSS
%                                     regression without FIR regression
%                                     (based on original time series) 
%   tmfc.LSS_after_FIR.conditions   - Conditions of interest for LSS 
%                                     regression after FIR regression
%                                     (based on residual time series)
%   tmfc.ROI_set(i).gPPI.conditions - Conditions of interest for gPPI and
%                                     gPPI-FIR regression
%                                     (see tmfc_conditions_GUI and
%                                      tmfc_get_conditions)
%
%   tmfc.ROI_set(i).BSC             - 'mean' or 'first_eigenvariate'
%   tmfc.ROI_set(i).BSC_after_FIR   - 'mean' or 'first_eigenvariate'
%
%   tmfc.ROI_set(i).PPI_centering   - 'with_mean_centering' or
%                                     'no_mean_centering'
%
%   tmfc.ROI_set(i).gPPI_FIR.window - FIR window length [seconds]
%   tmfc.ROI_set(i).gPPI_FIR.bins   - Number of FIR time bins
%                                     (for gPPI-FIR GLM)
%
% =========================================================================
%
% Copyright (C) 2026 Ruslan Masharipov
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

%-Check SPM version
%--------------------------------------------------------------------------
if exist('spm','file')
    spm_version = spm('Ver');
    if ~isequal(spm_version,'SPM12') && ~isequal(spm_version,'SPM25')
        warning('Your SPM version: %s. TMFC toolbox was tested only with SPM12 and SPM25.', spm_version)
    end
else
    error('SPM not found on MATLAB path.');
end

%-Check TMFC toolbox version
%--------------------------------------------------------------------------
localVer  = 'v.1.9.7';
try
    r = webread(sprintf('https://api.github.com/repos/%s/%s/releases/latest', ...
                        'IHB-IBR-department','TMFC_toolbox'), ...
                         weboptions('Timeout',5));
    latestVer = r.tag_name;
catch
    latestVer = '';
end

if isempty(latestVer)
    fprintf(2,['Could not check for updates automatically. ' ...
        'Please check the latest version on GitHub:\n' ...
        'https://github.com/IHB-IBR-department/TMFC_toolbox/releases\n']);
elseif ~strcmp(localVer,latestVer)
    fprintf('Update available: %s. Please visit: https://github.com/IHB-IBR-department/TMFC_toolbox/releases\n',latestVer);
end

%% ==================[ Set up GUI and TMFC structure ]=====================
if isempty(findobj('Tag', 'TMFC_GUI')) 
    
	% Set up TMFC structure
    tmfc.defaults.parallel = 0;      
    tmfc.defaults.maxmem = 2^32;
    tmfc.defaults.resmem = true;
    tmfc.defaults.analysis = 1;
    
    % Main TMFC GUI
    main_GUI.TMFC_GUI = figure('Name',['TMFC toolbox ' localVer],'MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.63 0.0875 0.250 0.850], 'color', 'w', 'Tag', 'TMFC_GUI');
    
    % Box Panels
    main_GUI.MP1 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.85 0.94 0.13],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.MP2 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.65 0.94 0.19],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.MP3 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.511 0.94 0.13],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.MP4 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.37 0.94 0.13],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.MP5 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.23 0.94 0.13],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.MP6 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.03 0.01 0.94 0.13],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');    
    main_GUI.SP1 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.922 0.40 0.0473],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.SP2 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.863 0.40 0.0473],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.SP3 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.782 0.40 0.0473],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.SP4 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.722 0.40 0.0473],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.SP6 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.582 0.40 0.0473],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.SP8 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.442 0.40 0.0473],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    main_GUI.SP9 = uipanel(main_GUI.TMFC_GUI,'Units', 'normalized','Position',[0.54 0.302 0.40 0.0473],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    
    % Buttons
    main_GUI.TMFC_GUI_B1 = uicontrol('Style', 'pushbutton', 'String', 'Subjects', 'Units', 'normalized', 'Position', [0.06 0.92 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B2 = uicontrol('Style', 'pushbutton', 'String', 'ROI set', 'Units', 'normalized', 'Position', [0.06 0.86 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B3 = uicontrol('Style', 'pushbutton', 'String', 'VOIs', 'Units', 'normalized', 'Position', [0.06 0.78 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B4 = uicontrol('Style', 'pushbutton', 'String', 'PPIs', 'Units', 'normalized', 'Position', [0.06 0.72 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B5a = uicontrol('Style', 'pushbutton', 'String', 'gPPI', 'Units', 'normalized', 'Position', [0.06 0.66 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B5b = uicontrol('Style', 'pushbutton', 'String', 'gPPI FIR', 'Units', 'normalized', 'Position', [0.54 0.66 0.40 0.05],'FontUnits','normalized','FontSize',0.33);    
    main_GUI.TMFC_GUI_B6 = uicontrol('Style', 'pushbutton', 'String', 'LSS GLM', 'Units', 'normalized', 'Position', [0.06 0.58 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B7 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS', 'Units', 'normalized', 'Position', [0.06 0.52 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B8 = uicontrol('Style', 'pushbutton', 'String', 'FIR task regression', 'Units', 'normalized', 'Position', [0.06 0.44 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B9 = uicontrol('Style', 'pushbutton', 'String', 'Background connectivity', 'Units', 'normalized', 'Position', [0.06 0.38 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B10 = uicontrol('Style', 'pushbutton', 'String', 'LSS GLM after FIR', 'Units', 'normalized', 'Position', [0.06 0.30 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B11 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS after FIR', 'Units', 'normalized', 'Position', [0.06 0.24 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B12a = uicontrol('Style', 'pushbutton', 'String', 'Statistics', 'Units', 'normalized', 'Position', [0.06 0.16 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B12b = uicontrol('Style', 'pushbutton', 'String', 'Results', 'Units', 'normalized', 'Position', [0.54 0.16 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B13a = uicontrol('Style', 'pushbutton', 'String', 'Open project', 'Units', 'normalized', 'Position', [0.06 0.08 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B13b = uicontrol('Style', 'pushbutton', 'String', 'Save project', 'Units', 'normalized', 'Position', [0.54 0.08 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B14a = uicontrol('Style', 'pushbutton', 'String', 'Tools', 'Units', 'normalized', 'Position', [0.06 0.02 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    main_GUI.TMFC_GUI_B14b = uicontrol('Style', 'pushbutton', 'String', 'Settings', 'Units', 'normalized', 'Position', [0.54 0.02 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    
    % String display
    main_GUI.TMFC_GUI_S1 = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', [1, 0, 0], 'Units', 'normalized', 'Position',[0.555 0.926 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'BackgroundColor', 'w');
    main_GUI.TMFC_GUI_S2 = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', [1, 0, 0], 'Units', 'normalized', 'Position',[0.555 0.867 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'BackgroundColor', 'w');
    main_GUI.TMFC_GUI_S3 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position',[0.555 0.787 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'BackgroundColor', 'w');
    main_GUI.TMFC_GUI_S4 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position',[0.555 0.727 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'BackgroundColor', 'w');
    main_GUI.TMFC_GUI_S6 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position',[0.555 0.587 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'BackgroundColor', 'w');
    main_GUI.TMFC_GUI_S8 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position',[0.555 0.447 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'BackgroundColor', 'w');
    main_GUI.TMFC_GUI_S10 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position',[0.555 0.307 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'BackgroundColor', 'w');
    
    % CallBack functions corresponding to each button
    set(main_GUI.TMFC_GUI, 'CloseRequestFcn', {@close_GUI, main_GUI.TMFC_GUI}); 
    set(main_GUI.TMFC_GUI_B1,   'callback',   {@select_subjects_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B2,   'callback',   {@ROI_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B3,   'callback',   {@VOI_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B4,   'callback',   {@PPI_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B5a,  'callback',   {@gPPI_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B5b,  'callback',   {@gPPI_FIR_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B6,   'callback',   {@LSS_GLM_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B7,   'callback',   {@BSC_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B8,   'callback',   {@FIR_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B9,   'callback',   {@BGFC_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B10,  'callback',   {@LSS_FIR_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B11,  'callback',   {@BSC_after_FIR_GUI, main_GUI.TMFC_GUI});   
    set(main_GUI.TMFC_GUI_B12a, 'callback',   {@statistics_GUI, main_GUI.TMFC_GUI});               
    set(main_GUI.TMFC_GUI_B12b, 'callback',   {@results_GUI, main_GUI.TMFC_GUI});               
    set(main_GUI.TMFC_GUI_B13a, 'callback',   {@load_project_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B13b, 'callback',   {@save_project_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B14a, 'callback',   {@tools_GUI, main_GUI.TMFC_GUI});
    set(main_GUI.TMFC_GUI_B14b, 'callback',   {@settings_GUI, main_GUI.TMFC_GUI});    
    % warning('off','backtrace');
else
    figure(findobj('Tag', 'TMFC_GUI')); 
    warning('TMFC toolbox is already running.');
    return;
end

%% ========================[ Select subjects ]=============================
function select_subjects_GUI(~,~,~)

    % Freeze main TMFC GUI
    freeze_GUI(1);

    % Manage subjects in existing project
    if isfield(tmfc,'subjects') && ~isempty(tmfc.subjects)
        [subject_action, selected_subjects] = tmfc_manage_subjects_GUI(tmfc);
        switch subject_action
            %--------------------------------------------------------------
            case 'add'
                disp('TMFC: Select new subject(s) to add.');

                % Select candidate subjects without cohort-level validation
                [SPM_paths_new, subject_paths_new] = tmfc_select_subjects_GUI(0);

                if isempty(SPM_paths_new)
                    freeze_GUI(0);
                    disp('TMFC: No new subjects selected.');
                    return;
                end

                % Validate candidates against the existing TMFC project
                [SPM_paths_new, subject_paths_new, add_type] = tmfc_validate_new_subjects(tmfc,SPM_paths_new,subject_paths_new);

                if isempty(SPM_paths_new)
                    freeze_GUI(0);
                    disp('TMFC: No valid new subjects to add.');
                    return;
                end

                fprintf('TMFC: %d valid new subject(s).\n',length(SPM_paths_new));

                if any(add_type == 2)
                    answer = questdlg( ...
                        ['The selected subject(s) have a different number of runs.' sprintf('\n\n') ...
                        'TMFC can convert the project to repeated-run mode, where runs are treated as ' ...
                        'repeated instances of the same design and subjects may have different numbers of runs.' sprintf('\n\n') ...
                        'After conversion, between-run contrasts will no longer be available. ' ...
                        'Existing run-specific results will be preserved, but existing gPPI and BSC contrasts will be reset.' sprintf('\n\n') ...
                        'Convert the project to repeated-run mode?'], ...
                        'Convert to repeated-run mode', ...
                        'Convert','Cancel','Cancel');

                    if ~strcmp(answer,'Convert')
                        disp('TMFC: Subject addition cancelled.');
                        freeze_GUI(0);
                        return;
                    end
                end

                % Work on a temporary copy until subject addition is fully completed
                tmfc_new = tmfc;
                nSub_old = length(tmfc.subjects);

                % Append new subjects
                tmfc_new = tmfc_append_subjects(tmfc_new,SPM_paths_new,subject_paths_new,add_type);

                if isfield(tmfc_new,'ROI_set')
                    for iSet = 1:length(tmfc_new.ROI_set)
                        ROI_set = tmfc_new.ROI_set(iSet);                       

                        % -------------------------------------------------
                        % Backward compatibility: infer ROI type
                        if isfield(ROI_set,'type') && ~isempty(ROI_set.type)
                            ROI_type = ROI_set.type;
                        else
                            if isfield(ROI_set.ROIs,'path') && ~isfield(ROI_set.ROIs,'radius')
                                ROI_type = 'binary_images';
                            elseif ~isfield(ROI_set.ROIs,'path') && isfield(ROI_set.ROIs,'radius')
                                ROI_type = 'fixed_spheres';
                            elseif isfield(ROI_set.ROIs,'moving_radius')
                                ROI_type = 'moving_spheres_inside_fixed_spheres';
                            else
                                ROI_type = 'moving_spheres_inside_binary_images';
                            end
                            tmfc_new.ROI_set(iSet).type = ROI_type;
                        end

                        % -------------------------------------------------
                        % Subject-specific binary ROIs
                        if strcmp(ROI_type,'subject_specific_binary_images')

                            fprintf('TMFC: Select ROIs for new subjects in ROI set "%s".\n',ROI_set.set_name);

                            % Select ROIs only for newly added subjects
                            tmfc_tmp = tmfc_new;
                            tmfc_tmp.subjects = tmfc_new.subjects(nSub_old+1:end);

                            nROI = length(ROI_set.ROIs);
                            ROI_paths = tmfc_select_subject_ROIs_GUI(tmfc_tmp,ROI_set.set_name,nROI);

                            if isempty(ROI_paths)
                                freeze_GUI(0);
                                disp('TMFC: Subject addition cancelled.');
                                return;
                            end

                            for iNew = 1:size(ROI_paths,1)
                                iSub = nSub_old + iNew;
                                for iROI = 1:nROI
                                    tmfc_new.ROI_set(iSet).ROIs(iROI).path(iSub).subjects = ROI_paths{iNew,iROI};
                                end
                            end
                        end
                    end
                end

                % Extend ROI sets before committing new subjects
                try
                    % Create only missing ROI masks
                    if isfield(tmfc_new,'ROI_set')
                        tmfc_new = tmfc_extend_ROI_sets(tmfc_new);
                    end

                    % Commit only after successful ROI extension
                    tmfc = tmfc_new;
                    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
     
                    % Update GUI
                    nSub = length(tmfc.subjects);
    
                    set(main_GUI.TMFC_GUI_S1,'String', ...
                        [num2str(nSub) ' selected'], ...
                        'ForegroundColor',[0.219, 0.341, 0.137]);
    
                    tmfc = update_tmfc_progress(tmfc);
    
                    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
                    fprintf('TMFC: %d new subject(s) added. %d subject(s) total.\n',length(SPM_paths_new),nSub);
                catch ME
                    freeze_GUI(0);
                    fprintf(2, '\n%s\n', repmat('=',1,30));
                    fprintf(2, '    Subject addition failed\n');
                    fprintf(2, '%s\n\n', repmat('=',1,30));
                    rethrow(ME);
                end

                
            %--------------------------------------------------------------
            case 'remove'
                % Confirm subject removal
                answer = questdlg( ...
                    sprintf('Remove %d selected subject(s) from the TMFC project?', ...
                    length(selected_subjects)), ...
                    'Remove subjects', ...
                    'Remove','Cancel','Cancel');

                if ~strcmp(answer,'Remove')
                    disp('TMFC: Subject removal cancelled.');
                    freeze_GUI(0);
                    return;
                end

                % Ask whether subject-specific TMFC files should also be deleted
                answer = questdlg( ...
                    ['Delete all TMFC output files for the removed subject(s)?' sprintf('\n\n') ...
                    'Source SPM.mat files and first-level data will not be deleted.'], ...
                    'Delete TMFC files', ...
                    'Yes','No','Cancel','No');

                if strcmp(answer,'Cancel') || isempty(answer)
                    freeze_GUI(0);
                    disp('TMFC: Subject removal cancelled.');
                    return;
                end

                delete_files = strcmp(answer,'Yes');

                try
                    tmfc = tmfc_remove_subjects(tmfc,selected_subjects,delete_files);

                    % Save updated project
                    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

                    % Update GUI
                    nSub = length(tmfc.subjects);
                    set(main_GUI.TMFC_GUI_S1,'String', ...
                        [num2str(nSub) ' selected'], ...
                        'ForegroundColor',[0.219, 0.341, 0.137]);
                    tmfc = update_tmfc_progress(tmfc);
                    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
                    fprintf('TMFC: %d subject(s) removed. %d subject(s) remaining.\n',length(selected_subjects),nSub);
                catch ME
                    freeze_GUI(0);
                    fprintf(2, '\n%s\n', repmat('=',1,30));
                    fprintf(2, '    Subject removal failed\n');
                    fprintf(2, '%s\n\n', repmat('=',1,30));
                    rethrow(ME);
                end
            %--------------------------------------------------------------    
            case 'remove_all'

                % Confirm full reset
                answer = questdlg( ...
                    ['Remove all subjects and reset the current TMFC project?' sprintf('\n\n') ...
                    'All project settings, ROI sets and analysis progress will be cleared.'], ...
                    'Remove all subjects', ...
                    'Remove all','Cancel','Cancel');

                if ~strcmp(answer,'Remove all')
                    freeze_GUI(0);
                    disp('TMFC: Remove all subjects cancelled.');
                    return;
                end

                % Ask whether TMFC output files should also be deleted
                answer = questdlg( ...
                    ['Delete all TMFC output files from the current project folder?' sprintf('\n\n') ...
                    'Source SPM.mat files and first-level data will not be deleted.'], ...
                    'Delete TMFC files', ...
                    'Yes','No','Cancel','No');

                if strcmp(answer,'Cancel') || isempty(answer)
                    freeze_GUI(0);
                    disp('TMFC: Remove all subjects cancelled.');
                    return;
                end

                delete_files = strcmp(answer,'Yes');

                try
                    project_path = tmfc.project_path;

                    if delete_files
                        project_folders = { ...
                            'ROI_sets', ...
                            'LSS_regression', ...
                            'FIR_regression', ...
                            'LSS_regression_after_FIR'};

                        for iFolder = 1:length(project_folders)
                            folder_path = fullfile(project_path,project_folders{iFolder});
                            if isdir(folder_path)
                                rmdir(folder_path,'s');
                            end
                        end
                    end

                    autosave_file = fullfile(project_path,'tmfc_autosave.mat');
                    if exist(autosave_file,'file')
                        delete(autosave_file);
                    end

                    tmfc = major_reset(tmfc);
                    disp('TMFC: All subjects removed. Project reset.');

                catch ME
                    freeze_GUI(0);
                    fprintf(2, '\n%s\n', repmat('=',1,30));
                    fprintf(2, '    Project reset failed\n');
                    fprintf(2, '%s\n\n', repmat('=',1,30));
                    rethrow(ME);
                end
            %-------------------------------------------------------------- 
            case 'close'
                disp('TMFC: Subject management closed.');
        end
        freeze_GUI(0);
        return;
    end

    % Initial subject selection
    [SPM_paths, subject_paths, ~, session_mode] = tmfc_select_subjects_GUI(1);
    
    % If subjects are not selected - unfreeze
    if isempty(SPM_paths)
        freeze_GUI(0);
        disp('TMFC: Subjects not selected.');
    else
        % Clear TMFC structure and refresh main TMFC GUI
        tmfc = major_reset(tmfc);
        tmfc.session_mode = session_mode;

        % Select subject naming format
        [sub_names] = tmfc_subject_naming_GUI;
        tmfc.subject_naming = sub_names;

        % Check uniqueness of original subject names
        if strcmp(sub_names,'original')
            subject_names = cell(size(subject_paths,1),1);
            for iSub = 1:size(subject_paths,1)
                subject_path = subject_paths{iSub};
                if ~isempty(subject_path) && subject_path(end) == filesep
                    subject_path(end) = [];
                end
                [~,subject_names{iSub}] = fileparts(subject_path);
            end
            for iSub = 1:length(subject_names)-1
                if any(strcmpi(subject_names{iSub},subject_names(iSub+1:end)))
                    warning('TMFC: Subject names must be unique.');
                    tmfc = major_reset(tmfc);
                    freeze_GUI(0);
                    return;
                end
            end
        end

        % Add subject paths to TMFC structure
        for iSub = 1:size(SPM_paths,1)
            tmfc.subjects(iSub).path = SPM_paths{iSub};
            if strcmp(sub_names,'original')
                tmfc.subjects(iSub).name = subject_names{iSub};
            else
                tmfc.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
            end
        end

        % Store next available standard subject number
        if strcmp(tmfc.subject_naming,'standard')
            tmfc.next_subject = size(SPM_paths,1) + 1;
        end

        % Select TMFC project folder
        disp('TMFC: Please select a folder for the new TMFC project.');
        tmfc_select_project_path(size(SPM_paths,1)); % Dialog window
        project_path = spm_select(1,'dir','Select a folder for the new TMFC project',{},pwd);

        % Check if project folder is selected
        if strcmp(project_path, '')
            warning('TMFC: Project folder not selected. Subjects not saved.');
            tmfc = major_reset(tmfc);
            freeze_GUI(0);
            return;
        else
            % Add project path to TMFC structure
            fprintf('TMFC: %d subject(s) selected.\n', size(SPM_paths,1));
            set(main_GUI.TMFC_GUI_S1,'String', strcat(num2str(size(SPM_paths,1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
            tmfc.project_path = project_path;
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            freeze_GUI(0);
        	cd(tmfc.project_path);
    	end
	end
end

%% ============================[ ROI set ]=================================
% Select ROIs and apply individual first-level masks to them
function ROI_GUI(~,~,~)

    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
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
            set(main_GUI.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(1).set_name, ' (',num2str(length(tmfc.ROI_set(1).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
            tmfc = ROI_set_initializer(tmfc);
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
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
                tmfc.ROI_set(nSet+1).type = new_ROI_set.type;
                tmfc.ROI_set(nSet+1).ROIs = new_ROI_set.ROIs;
                if isfield(new_ROI_set,'F')
                    tmfc.ROI_set(nSet+1).F = new_ROI_set.F;
                end
                tmfc.ROI_set_number = nSet+1;
                disp('New ROI set selected.');
                set(main_GUI.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(nSet+1).set_name, ' (',num2str(length(tmfc.ROI_set(nSet+1).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
                tmfc = ROI_set_initializer(tmfc);
                save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
                set(main_GUI.TMFC_GUI_S3,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
                set(main_GUI.TMFC_GUI_S4,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
            end
            
        % Switch to selected ROI set
        elseif ROI_set_check == 0 && ROI_set_number > 0

            % Check ROI masks before switching
            if check_ROI_masks(tmfc,ROI_set_number) == 0
                warning('One or more ROI masks are missing. Check the ROI_sets subfolder.');
                freeze_GUI(0);
                return;
            end

            fprintf('\nSelected ROI set: %s. \n', char(ROI_set_list(ROI_set_number,2)));
            tmfc.ROI_set_number = ROI_set_number;
            set(main_GUI.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(ROI_set_number).set_name, ' (',num2str(length(tmfc.ROI_set(ROI_set_number).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
            tmfc = update_gPPI(tmfc);
            
        % If user cancels operation
        else
            disp('No new ROI set selected.');
        end
    end

    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
    
    % Unfreeze main TMFC GUI
    freeze_GUI(0);   
end

%% =============================[ VOIs ]===================================
% Perform volume of interest (VOI) computation for selected ROI set
function VOI_GUI(~,~,~)
    
    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~exist(tmfc.subjects(1).path,'file')
        error('SPM.mat file for the first subject does not exist.')
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    elseif ~isfield(tmfc,'ROI_set')
        warning('Select ROIs.'); return;
    end
    ROI_check = check_ROI_masks(tmfc,tmfc.ROI_set_number);
    if ROI_check == 0
        error('One or more ROI masks are missing. Check the ROI_sets subfolder.')
    end

    % Freeze main TMFC GUI
    cd(tmfc.project_path);
    freeze_GUI(1);

    nSub = length(tmfc.subjects);
    nROI = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);

    try
        cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
    end    

    % Update TMFC structure
    try
        w = waitbar(0,'Please wait...','Name','Updating VOI progress');
        for iSub = 1:nSub
            SPM = load(tmfc.subjects(iSub).path).SPM;
            
            if strcmp(tmfc.session_mode,'repeated')
                sess_num = 1:length(SPM.Sess);
            else
                sess_num = unique([cond_list.sess]);
            end

            nSess = length(sess_num);
            check_VOI = zeros(nROI,nSess);

            for jROI = 1:nROI
                for kSess = 1:nSess
                    if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs',tmfc.subjects(iSub).name, ...
                            ['VOI_' tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name '_' num2str(sess_num(kSess)) '.mat']), 'file')
                        check_VOI(jROI,kSess) = 1;
                    end
                end
            end
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI = double(~any(check_VOI(:) == 0));
            try
                waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
            end
        end
        clear SPM sess_num
    end

    try, delete(w); catch, end

    % Update main TMFC GUI
    track_VOI = 0;
    for iSub = 1:nSub
        if tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI == 0
            track_VOI = iSub;
            break;
        end
    end
    if track_VOI == 0
        set(main_GUI.TMFC_GUI_S3,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
    elseif track_VOI == 1
        set(main_GUI.TMFC_GUI_S3,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
    else
        set(main_GUI.TMFC_GUI_S3,'String', strcat(num2str(track_VOI-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
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
        gPPI_conditions = tmfc_conditions_GUI(tmfc.subjects(1).path,2,tmfc.session_mode);   
        if isstruct(gPPI_conditions)
            if restart_VOI == 1 || continue_VOI == 0
                tmfc = reset_gPPI(tmfc);
            end
            tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = gPPI_conditions;
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
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
    catch ME
        freeze_GUI(0);
        fprintf(2, '\n%s\n', repmat('=',1,30));
        fprintf(2, '    VOI computation failed\n');
        fprintf(2, '%s\n\n', repmat('=',1,30));
        rethrow(ME);
    end

    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);     
end

%% =============================[ PPIs ]===================================
% Perform PPI computation for selected ROI set
function PPI_GUI(~,~,~)
    
    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~exist(tmfc.subjects(1).path,'file')
        error('SPM.mat file for the first subject does not exist.')
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    elseif ~isfield(tmfc,'ROI_set')
        warning('Select ROIs.'); return;
    elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).VOI] == 0)
        warning('VOIs must be calculated for all subjects.'); return;         
    elseif ~isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI') || ...
            ~isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI) || ...
            isempty(tmfc.ROI_set(tmfc.ROI_set_number).gPPI) || ...
            ~isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI,'conditions') || ...
            isempty(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions)
        error('Select conditions of interest. VOIs must be calculated for all subjects.');
    end

    % Freeze main TMFC GUI
    cd(tmfc.project_path);
    freeze_GUI(1);

    nSub = length(tmfc.subjects);
    nROI = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
    cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
    nCond = length(cond_list);

    % Update TMFC structure   
    w = waitbar(0,'Please wait...','Name','Updating PPI progress');
    for iSub = 1:nSub

        % Repeated runs
        if strcmp(tmfc.session_mode,'repeated')
            SPM = load(tmfc.subjects(iSub).path).SPM;
            sess_num = 1:length(SPM.Sess);

            check_PPI = zeros(nROI,length(sess_num),nCond);

            for jROI = 1:nROI
                for kSess = 1:length(sess_num)
                    s = sess_num(kSess);

                    for kCond = 1:nCond

                        cond = cond_list(kCond).number;

                        if isfield(cond_list,'pmod') && ~isempty(cond_list(kCond).pmod)
                            pmod = cond_list(kCond).pmod;
                        else
                            pmod = 1;
                        end

                        if isfield(cond_list,'bf') && ~isempty(cond_list(kCond).bf)
                            bf = cond_list(kCond).bf;
                        else
                            bf = 1;
                        end

                        cond_name = char(SPM.Sess(s).U(cond).name(pmod));

                        file_name = ...
                            ['[Run_' num2str(s) ']_[Cond_' num2str(cond) ']_[' ...
                            regexprep(cond_name,' ','_') ']'];

                        if bf == 2
                            file_name = [file_name '_[TimeDeriv]'];
                        elseif bf == 3
                            file_name = [file_name '_[DispDeriv]'];
                        end

                        if exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs', ...
                                tmfc.subjects(iSub).name, ...
                                ['PPI_[' regexprep(tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name,' ','_') ']_' ...
                                file_name '.mat']),'file')

                            check_PPI(jROI,kSess,kCond) = 1;
                        end
                    end
                end
            end

        % Strict mode
        else
            check_PPI = zeros(nROI,nCond);

            for jROI = 1:nROI
                for kCond = 1:nCond

                    file_name = strrep(cond_list(kCond).file_name,'[Sess_','[Run_');

                    file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                        tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs', ...
                        tmfc.subjects(iSub).name, ...
                        ['PPI_[' regexprep(tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name,' ','_') ']_' ...
                        file_name '.mat']);

                    % Backward compatibility
                    file_old = strrep(file_new,'[Run_','[Sess_');

                    if exist(file_new,'file') || exist(file_old,'file')
                        check_PPI(jROI,kCond) = 1;
                    end
                end
            end
        end
        
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = double(~any(check_PPI(:) == 0));
        try
            waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
        end
    end

    clear SPM sess_num
    try, delete(w); catch, end

    % Update main TMFC GUI
    track_PPI = 0;
    for iSub = 1:nSub
        if tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI == 0
            track_PPI = iSub;
            break;
        end
    end
    if track_PPI == 0
        set(main_GUI.TMFC_GUI_S4,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
    elseif track_PPI == 1
        set(main_GUI.TMFC_GUI_S4,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
    else
        set(main_GUI.TMFC_GUI_S4,'String', strcat(num2str(track_PPI-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
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
            % Define mean centering
            if start_sub == 1
                centering = PPI_centering_GUI;
                if isempty(centering)
                    freeze_GUI(0);
                    return;
                end
                tmfc.ROI_set(tmfc.ROI_set_number).PPI_centering = centering;
                save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            end
            % Run PPI calculation
            sub_check = tmfc_PPI(tmfc,tmfc.ROI_set_number,start_sub);
            for iSub = start_sub:nSub
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = sub_check(iSub);
            end
            disp('PPI computation completed.');
        catch ME
            freeze_GUI(0);
            fprintf(2, '\n%s\n', repmat('=',1,30));
            fprintf(2, '    PPI computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,30));
            rethrow(ME);
        end
    end

    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);  
end

%% =============================[ gPPI ]===================================
% Perform gPPI analysis for selected ROI set
function gPPI_GUI(~,~,~)
               
    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~exist(tmfc.subjects(1).path,'file')
        error('SPM.mat file for the first subject does not exist.')
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    elseif ~isfield(tmfc,'ROI_set')
        warning('Select ROIs.'); return;
    elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).VOI] == 0)
        warning('VOIs must be calculated for all subjects.'); return;
    elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).PPI] == 0)
        warning('Calculate PPIs for all subjects.'); return;
    elseif ~isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI') || ...
            ~isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI) || ...
            isempty(tmfc.ROI_set(tmfc.ROI_set_number).gPPI) || ...
            ~isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI,'conditions') || ...
            isempty(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions)
        error('Select conditions of interest. VOIs must be calculated for all subjects.');
    end

    % Freeze main TMFC GUI
    cd(tmfc.project_path);
    freeze_GUI(1);

    nSub = length(tmfc.subjects);
    nROI = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
    cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
    nCond = length(cond_list);

    % Update TMFC structure
    w = waitbar(0,'Please wait...','Name','Updating gPPI progress');
    for iSub = 1:nSub
        check_gPPI = ones(1,nCond);
        
        % Repeated runs
        if strcmp(tmfc.session_mode,'repeated')
            SPM = load(tmfc.subjects(iSub).path).SPM;
            sess_num = 1:length(SPM.Sess);
    
            for jCond = 1:nCond
    
                if isfield(cond_list,'bf') && ~isempty(cond_list(jCond).bf)
                    bf = cond_list(jCond).bf;
                else
                    bf = 1;
                end
    
                % Check run-specific files
                for kSess = 1:length(sess_num)
    
                    file_name = ...
                        ['[Run_' num2str(sess_num(kSess)) ']_[Cond_' ...
                        num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];
    
                    if bf == 2
                        file_name = [file_name '_[TimeDeriv]'];
                    elseif bf == 3
                        file_name = [file_name '_[DispDeriv]'];
                    end
    
                    % Check ROI-to-ROI files
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                        if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                                'ROI_to_ROI','symmetrical', ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.mat']),'file')
                            check_gPPI(jCond) = 0;
                        end
                    end
    
                    % Check seed-to-voxel files (last ROI only)
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                        if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                                'Seed_to_voxel', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.nii']),'file')
                            check_gPPI(jCond) = 0;
                        end
                    end
                end
    
                % Check across-run files
                file_name = ...
                    ['[All_Runs]_[Cond_' num2str(cond_list(jCond).number) ']_[' ...
                    regexprep(cond_list(jCond).name,' ','_') ']'];
    
                if bf == 2
                    file_name = [file_name '_[TimeDeriv]'];
                elseif bf == 3
                    file_name = [file_name '_[DispDeriv]'];
                end
    
                % Check ROI-to-ROI files
                if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                    if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                            'ROI_to_ROI','symmetrical', ...
                            [tmfc.subjects(iSub).name '_Contrast_' ...
                            num2str(jCond,'%04.f') '_' file_name '.mat']),'file')
                        check_gPPI(jCond) = 0;
                    end
                end
    
                % Check seed-to-voxel files (last ROI only)
                if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                    if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                            'Seed_to_voxel', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                            [tmfc.subjects(iSub).name '_Contrast_' ...
                            num2str(jCond,'%04.f') '_' file_name '.nii']),'file')
                        check_gPPI(jCond) = 0;
                    end
                end
            end
    
        % Strict mode
        else
            for jCond = 1:nCond

                file_name = strrep(cond_list(jCond).file_name,'[Sess_','[Run_');

                % Check ROI-to-ROI files
                if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2

                    file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                        tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                        'ROI_to_ROI','symmetrical', ...
                        [tmfc.subjects(iSub).name '_Contrast_' ...
                        num2str(jCond,'%04.f') '_' file_name '.mat']);

                    % Backward compatibility
                    file_old = strrep(file_new,'[Run_','[Sess_');

                    if ~exist(file_new,'file') && ~exist(file_old,'file')
                        check_gPPI(jCond) = 0;
                    end
                end

                % Check seed-to-voxel files (last ROI only)
                if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3

                    file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                        tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                        'Seed_to_voxel', ...
                        tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                        [tmfc.subjects(iSub).name '_Contrast_' ...
                        num2str(jCond,'%04.f') '_' file_name '.nii']);

                    % Backward compatibility
                    file_old = strrep(file_new,'[Run_','[Sess_');

                    if ~exist(file_new,'file') && ~exist(file_old,'file')
                        check_gPPI(jCond) = 0;
                    end
                end
            end
        end

        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI = double(~any(check_gPPI(:) == 0));
        try
            waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
        end
    end

    clear SPM sess_num
    try, delete(w); catch, end

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

        if strcmp(tmfc.session_mode,'repeated')
            fprintf('\ngPPI was calculated for all subjects with %d Condition(s). \n',nCond);
        else
            fprintf('\ngPPI was calculated for all subjects, %d Run(s) (SPM sessions) and %d Condition(s). \n', ...
                max([cond_list.sess]),nCond);
        end
        
        disp('To calculate gPPI for different conditions, recompute VOIs and PPIs with desired conditions.');       

        % Default contrasts were calculated, but contrast info was not stored in tmfc structure
        if isempty(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(1).title)
            for cond_PPI = 1:nCond

                if strcmp(tmfc.session_mode,'repeated')

                    contrasts(cond_PPI).title = ...
                        ['[All_Runs]_[Cond_' num2str(cond_list(cond_PPI).number) ']_[' ...
                        regexprep(cond_list(cond_PPI).name,' ','_') ']'];

                    if isfield(cond_list,'bf') && ~isempty(cond_list(cond_PPI).bf)
                        if cond_list(cond_PPI).bf == 2
                            contrasts(cond_PPI).title = ...
                                [contrasts(cond_PPI).title '_[TimeDeriv]'];
                        elseif cond_list(cond_PPI).bf == 3
                            contrasts(cond_PPI).title = ...
                                [contrasts(cond_PPI).title '_[DispDeriv]'];
                        end
                    end

                else
                    contrasts(cond_PPI).title = cond_list(cond_PPI).file_name;
                end

                contrasts(cond_PPI).weights = zeros(1,nCond);
                contrasts(cond_PPI).weights(1,cond_PPI) = 1;
            end
            for iCon = 1:length(contrasts)
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(iCon).title = contrasts(iCon).title;
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(iCon).weights = contrasts(iCon).weights;
            end
            clear contrasts
        end

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
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        catch ME
            freeze_GUI(0);       
            fprintf(2, '\n%s\n', repmat('=',1,40));
            fprintf(2, '    New contrasts computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,40));
            rethrow(ME);
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
            
            % Update default contrasts
            for iCon = 1:length(contrasts)
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(iCon).title = contrasts(iCon).title;
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(iCon).weights = contrasts(iCon).weights;
            end

            % Calculate previously defined custom contrasts for processed subjects
            nDefault = length(contrasts);
            nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI);
            for iCon = nDefault+1:nCon
                seed2vox_or_ROI2ROI(tmfc,iCon,1,start_sub);
            end

            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('gPPI computation completed.');
        catch ME
            freeze_GUI(0);
        	fprintf(2, '\n%s\n', repmat('=',1,31));
            fprintf(2, '    gPPI computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,31));
            rethrow(ME);
        end 
    end

    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);   
end

%% ===========================[ gPPI FIR ]=================================
% Perform gPPI-FIR analysis for selected ROI set
function gPPI_FIR_GUI(~,~,~)

    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~exist(tmfc.subjects(1).path,'file')
        error('SPM.mat file for the first subject does not exist.')
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    elseif ~isfield(tmfc,'ROI_set')
        warning('Select ROIs.'); return;
    elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).VOI] == 0)
        warning('VOIs must be calculated for all subjects.'); return;
    elseif any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).PPI] == 0)
        warning('Calculate PPIs for all subjects.'); return;    
    elseif ~isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI') || ...
            ~isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI) || ...
            isempty(tmfc.ROI_set(tmfc.ROI_set_number).gPPI) || ...
            ~isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI,'conditions') || ...
            isempty(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions)
        error('Select conditions of interest. VOIs must be calculated for all subjects.');
    end

    % Freeze main TMFC GUI
    cd(tmfc.project_path);
    freeze_GUI(1);

    nSub = length(tmfc.subjects);
    nROI = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
    cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
    nCond = length(cond_list);

    % Update TMFC structure 
    w = waitbar(0,'Please wait...','Name','Updating gPPI-FIR progress');
    for iSub = 1:nSub
        check_gPPI_FIR = ones(1,nCond);
        
        % Repeated runs
        if strcmp(tmfc.session_mode,'repeated')
            SPM = load(tmfc.subjects(iSub).path).SPM;
            sess_num = 1:length(SPM.Sess);

            for jCond = 1:nCond

                if isfield(cond_list,'bf') && ~isempty(cond_list(jCond).bf)
                    bf = cond_list(jCond).bf;
                else
                    bf = 1;
                end

                % Check run-specific files
                for kSess = 1:length(sess_num)

                    file_name = ...
                        ['[Run_' num2str(sess_num(kSess)) ']_[Cond_' ...
                        num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];

                    if bf == 2
                        file_name = [file_name '_[TimeDeriv]'];
                    elseif bf == 3
                        file_name = [file_name '_[DispDeriv]'];
                    end

                    % Check ROI-to-ROI files
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                        if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                                'ROI_to_ROI','symmetrical', ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.mat']),'file')
                            check_gPPI_FIR(jCond) = 0;
                        end
                    end

                    % Check seed-to-voxel files (last ROI only)
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                        if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                                'Seed_to_voxel', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.nii']),'file')
                            check_gPPI_FIR(jCond) = 0;
                        end
                    end
                end

                % Check across-run files
                file_name = ...
                    ['[All_Runs]_[Cond_' num2str(cond_list(jCond).number) ']_[' ...
                    regexprep(cond_list(jCond).name,' ','_') ']'];

                if bf == 2
                    file_name = [file_name '_[TimeDeriv]'];
                elseif bf == 3
                    file_name = [file_name '_[DispDeriv]'];
                end

                % Check ROI-to-ROI files
                if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                    if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                            'ROI_to_ROI','symmetrical', ...
                            [tmfc.subjects(iSub).name '_Contrast_' ...
                            num2str(jCond,'%04.f') '_' file_name '.mat']),'file')
                        check_gPPI_FIR(jCond) = 0;
                    end
                end

                % Check seed-to-voxel files (last ROI only)
                if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                    if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                            'Seed_to_voxel', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                            [tmfc.subjects(iSub).name '_Contrast_' ...
                            num2str(jCond,'%04.f') '_' file_name '.nii']),'file')
                        check_gPPI_FIR(jCond) = 0;
                    end
                end
            end

        % Strict mode
        else
            for jCond = 1:nCond

                file_name = strrep(cond_list(jCond).file_name,'[Sess_','[Run_');

                % Check ROI-to-ROI files
                if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2

                    file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                        tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                        'ROI_to_ROI','symmetrical', ...
                        [tmfc.subjects(iSub).name '_Contrast_' ...
                        num2str(jCond,'%04.f') '_' file_name '.mat']);

                    % Backward compatibility
                    file_old = strrep(file_new,'[Run_','[Sess_');

                    if ~exist(file_new,'file') && ~exist(file_old,'file')
                        check_gPPI_FIR(jCond) = 0;
                    end
                end

                % Check seed-to-voxel files (last ROI only)
                if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3

                    file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                        tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                        'Seed_to_voxel', ...
                        tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                        [tmfc.subjects(iSub).name '_Contrast_' ...
                        num2str(jCond,'%04.f') '_' file_name '.nii']);

                    % Backward compatibility
                    file_old = strrep(file_new,'[Run_','[Sess_');

                    if ~exist(file_new,'file') && ~exist(file_old,'file')
                        check_gPPI_FIR(jCond) = 0;
                    end
                end
            end
        end

        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = double(~any(check_gPPI_FIR(:) == 0));
        try
            waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
        end
    end

    clear SPM sess_num
    try, delete(w); catch, end

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
        if ~isnan(FIR_window) && ~isnan(FIR_bins)
            tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.window = FIR_window;
            tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.bins = FIR_bins;
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        else
            warning('Define the window length and number of time bins for gPPI-FIR regression.');
            freeze_GUI(0);
            return;
        end

    % gPPI-FIR was calculated for all subjects 
    elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).gPPI_FIR] == 0)

        calculate_gPPI_FIR = 0;
        
        if strcmp(tmfc.session_mode,'repeated')
            fprintf('\ngPPI-FIR was calculated for all subjects with %d Condition(s). \n',nCond);
        else
            fprintf('\ngPPI-FIR was calculated for all subjects, %d Run(s) (SPM sessions) and %d Condition(s). \n', ...
                max([cond_list.sess]),nCond);
        end

        disp('To calculate gPPI-FIR for different conditions, recompute VOIs and PPIs with desired conditions.');

        % Default contrasts were calculated, but contrast info was not stored in tmfc structure
        if isempty(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(1).title)
            for cond_PPI = 1:nCond
                if strcmp(tmfc.session_mode,'repeated')

                    contrasts(cond_PPI).title = ...
                        ['[All_Runs]_[Cond_' num2str(cond_list(cond_PPI).number) ']_[' ...
                        regexprep(cond_list(cond_PPI).name,' ','_') ']'];

                    if isfield(cond_list,'bf') && ~isempty(cond_list(cond_PPI).bf)
                        if cond_list(cond_PPI).bf == 2
                            contrasts(cond_PPI).title = ...
                                [contrasts(cond_PPI).title '_[TimeDeriv]'];
                        elseif cond_list(cond_PPI).bf == 3
                            contrasts(cond_PPI).title = ...
                                [contrasts(cond_PPI).title '_[DispDeriv]'];
                        end
                    end
                else
                    contrasts(cond_PPI).title = cond_list(cond_PPI).file_name;
                end
                contrasts(cond_PPI).weights = zeros(1,nCond);
                contrasts(cond_PPI).weights(1,cond_PPI) = 1;
            end

            for iCon = 1:length(contrasts)
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(iCon).title = contrasts(iCon).title;
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(iCon).weights = contrasts(iCon).weights;
            end
            clear contrasts
        end

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
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        catch ME
            freeze_GUI(0);       
            fprintf(2, '\n%s\n', repmat('=',1,40));
            fprintf(2, '    New contrasts computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,40));
            rethrow(ME);
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
    if calculate_gPPI_FIR == 1
        disp('Initiating gPPI-FIR computation...');
        try
            [sub_check, contrasts] = tmfc_gPPI_FIR(tmfc,tmfc.ROI_set_number,start_sub);   

            for iSub = start_sub:nSub
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = sub_check(iSub);
            end

            % Update default contrasts
            for iCon = 1:length(contrasts)
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(iCon).title = contrasts(iCon).title;
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(iCon).weights = contrasts(iCon).weights;
            end

            % Calculate previously defined custom contrasts for processed subjects
            nDefault = length(contrasts);
            nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR);
            for iCon = nDefault+1:nCon
                seed2vox_or_ROI2ROI(tmfc,iCon,2,start_sub);
            end

            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('gPPI-FIR computation completed.');
        catch ME
            freeze_GUI(0);
            fprintf(2, '\n%s\n', repmat('=',1,35));
            fprintf(2, '    gPPI-FIR computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,35));
            rethrow(ME);
        end 
    end 

    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);    
end

%% ============================[ LSS GLM ]=================================
% Estimate LSS GLMs
function LSS_GLM_GUI(~,~,~)
    
    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~exist(tmfc.subjects(1).path,'file')
        error('SPM.mat file for the first subject does not exist.')
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    end

    % Freeze main TMFC GUI
    cd(tmfc.project_path);
    freeze_GUI(1);

    try
        cond_list = tmfc.LSS.conditions;
        nCond = length(cond_list);   
    end

    nSub = length(tmfc.subjects);

    % Update TMFC structure 
    LSS_done = ones(1,nSub);

    try
        w = waitbar(0,'Please wait...','Name','Updating LSS progress');
        for iSub = 1:nSub             
            SPM = load(tmfc.subjects(iSub).path).SPM;
            
            if strcmp(tmfc.session_mode,'repeated')
                sess_num = 1:length(SPM.Sess);
            else
                sess_num = unique([cond_list.sess]);
            end

            nSess = length(sess_num);

            for jSess = 1:nSess 
                % Trials of interest
                nTrial = 0;
                trial.cond = [];
                trial.number = [];
                for kCond = 1:nCond
                    if strcmp(tmfc.session_mode,'repeated') || cond_list(kCond).sess == sess_num(jSess)
                        nTrial = nTrial + length(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons);
                        trial.cond = [trial.cond; repmat(cond_list(kCond).number,length(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons),1)];
                        trial.number = [trial.number; (1:length(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons))'];
                    end
                end
                % Check individual trial GLMs
                for kTrial = 1:nTrial
                    file_new = fullfile(tmfc.project_path,'LSS_regression',tmfc.subjects(iSub).name,'GLM_batches', ...
                        ['GLM_[Run_' num2str(sess_num(jSess)) ']_[Cond_' num2str(trial.cond(kTrial)) ']_[' ...
                        regexprep(char(SPM.Sess(sess_num(jSess)).U(trial.cond(kTrial)).name(1)),' ','_') ']_[Trial_' ...
                        num2str(trial.number(kTrial)) '].mat']);

                    file_old = fullfile(tmfc.project_path,'LSS_regression',tmfc.subjects(iSub).name,'GLM_batches', ...
                        ['GLM_[Sess_' num2str(sess_num(jSess)) ']_[Cond_' num2str(trial.cond(kTrial)) ']_[' ...
                        regexprep(char(SPM.Sess(sess_num(jSess)).U(trial.cond(kTrial)).name(1)),' ','_') ']_[Trial_' ...
                        num2str(trial.number(kTrial)) '].mat']);

                    if exist(file_new,'file') || exist(file_old,'file')
                       condition(trial.cond(kTrial)).trials(trial.number(kTrial)) = 1;
                    else           
                       condition(trial.cond(kTrial)).trials(trial.number(kTrial)) = 0;
                       LSS_done(iSub) = 0;
                    end
                end
                tmfc.subjects(iSub).LSS.session(sess_num(jSess)).condition = condition;
                clear condition
            end
            try
                waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
            end
            clear SPM trial nTrial
        end
    end
    try, delete(w); catch, end

    % Update main TMFC GUI
    if exist('cond_list','var')
        track_LSS = find(LSS_done == 0,1,'first');

        if isempty(track_LSS)
            track_LSS = 0;
        end
    else
        track_LSS = 1;
    end
    
    if track_LSS == 0
        set(main_GUI.TMFC_GUI_S6,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
    elseif track_LSS == 1
        set(main_GUI.TMFC_GUI_S6,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
    else
        set(main_GUI.TMFC_GUI_S6,'String', strcat(num2str(track_LSS-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
    end

    restart_LSS = -1;
    continue_LSS = -1;

    % LSS was not calculated
    if track_LSS == 1    

        start_sub = 1;
        define_LSS_conditions = 1;

    % LSS was calculated for all subjects 
    elseif track_LSS == 0

        % Ask user to restart LSS computation
        restart_LSS = tmfc_restart_GUI(2);

        if restart_LSS == 1
            start_sub = 1;
            define_LSS_conditions = 1;
        else
            disp('LSS computation not initiated.');
            freeze_GUI(0); 
            return;
        end

    % LSS was calculated for some subjects  
    else

        % Ask user to continue or restart LSS computation
        continue_LSS = tmfc_continue_GUI(track_LSS,2);

        % Continue LSS computation
        if continue_LSS == 1
            start_sub = track_LSS;
            define_LSS_conditions = 0;
        % Restart LSS computation
        elseif continue_LSS == 0
            start_sub = 1;
            define_LSS_conditions = 1;
        else
            disp('LSS computation not initiated.'); 
            freeze_GUI(0);
            return;
        end
    end

    % Select LSS conditions
    if define_LSS_conditions == 1   
        LSS_conditions = tmfc_conditions_GUI(tmfc.subjects(1).path,3,tmfc.session_mode);   
        if isstruct(LSS_conditions)
            if restart_LSS == 1 || continue_LSS == 0
                tmfc = reset_LSS(tmfc);
            end
            tmfc.LSS.conditions = LSS_conditions;
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('Conditions of interest selected.');
        else
            warning('Conditions of interest not selected.');
            freeze_GUI(0);
            return;
        end
    end

    % Compute LSS
    disp('Initiating LSS computation...');
    try
        sub_check = tmfc_LSS(tmfc,start_sub);      
        for iSub = start_sub:nSub
            tmfc.subjects(iSub).LSS = sub_check(iSub);
        end
        save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        disp('LSS computation completed.');
    catch ME
        freeze_GUI(0);
        fprintf(2, '\n%s\n', repmat('=',1,30));
        fprintf(2, '    LSS computation failed\n');
        fprintf(2, '%s\n\n', repmat('=',1,30));
        rethrow(ME);
    end
    
    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);        
end

%% ============================= [ BSC ] ==================================
% Calculate beta-series correlations (BSC)
function BSC_GUI(~,~,~)

    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    elseif ~isfield(tmfc,'ROI_set')
        warning('Select ROIs.'); return;
    elseif ~isfield(tmfc.subjects,'LSS')
        warning('Compute LSS GLMs for all selected subjects.'); return;
    end
    ROI_check = check_ROI_masks(tmfc,tmfc.ROI_set_number);
    if ROI_check == 0
        error('One or more ROI masks are missing. Check the ROI_sets subfolder.')
    end

    nSub = length(tmfc.subjects);
    
    % Check LSS progress
    cond_list = tmfc.LSS.conditions;
    nCond = length(cond_list);

    for iSub = 1:nSub
        SPM = load(tmfc.subjects(iSub).path).SPM;

        if strcmp(tmfc.session_mode,'repeated')
            sess_num = 1:length(SPM.Sess);
        else
            sess_num = unique([cond_list.sess]);
        end

        for jSess = 1:length(sess_num)
            for kCond = 1:nCond
                if strcmp(tmfc.session_mode,'repeated') || cond_list(kCond).sess == sess_num(jSess)
                    LSS_progress = tmfc.subjects(iSub).LSS.session(sess_num(jSess)).condition(cond_list(kCond).number).trials;
                    if any(LSS_progress == 0)
                        error('Compute LSS GLMs for all selected subjects.');
                    end
                end
            end
        end
    end

    clear SPM sess_num LSS_progress

    % Freeze main TMFC GUI
    cd(tmfc.project_path);
    freeze_GUI(1);

    % Update TMFC structure
    w = waitbar(0,'Please wait...','Name','Updating BSC progress');
    for iSub = 1:nSub
        beta_series_file = fullfile(tmfc.project_path,'ROI_sets', ...
            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS', ...
            'Beta_series',[tmfc.subjects(iSub).name '_beta_series.mat']);

        BSC_done = exist(beta_series_file,'file') == 2;

        % In repeated mode, require repeated-run beta-series format
        if BSC_done && strcmp(tmfc.session_mode,'repeated')
            try
                tmp = load(beta_series_file,'beta_series');
                BSC_done = isfield(tmp,'beta_series') && ~isempty(tmp.beta_series) && isfield(tmp.beta_series,'run');
            catch
                BSC_done = false;
            end
        end

        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC = double(BSC_done);
        try
            waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
        end
    end
    try, delete(w); catch, end

    % First subject with incomplete BSC
    track_BSC = find([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BSC] == 0,1,'first');

    if isempty(track_BSC)
        track_BSC = 0;
    end

    % Previously defined BSC settings
    has_BSC_settings = isfield(tmfc.ROI_set(tmfc.ROI_set_number),'BSC') && ~isempty(tmfc.ROI_set(tmfc.ROI_set_number).BSC);

    % BSC was not calculated
    if ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BSC] == 1)                           

        disp('Initiating BSC LSS computation...');   

        try
            start_sub = 1;

            % For a full BSC calculation, allow settings to be selected again
            % Use the previous choices as defaults, if available
            previous_summary = 'mean';
            previous_scrubbing = 1;
            if has_BSC_settings
                previous_summary = tmfc.ROI_set(tmfc.ROI_set_number).BSC;
                previous_scrubbing = 0; % Legacy BSC used no beta scrubbing
                if isfield(tmfc.ROI_set(tmfc.ROI_set_number),'BSC_beta_scrubbing') && ...
                        ~isempty(tmfc.ROI_set(tmfc.ROI_set_number).BSC_beta_scrubbing) && ...
                        isfield(tmfc.ROI_set(tmfc.ROI_set_number).BSC_beta_scrubbing,'perform')
                    previous_scrubbing = tmfc.ROI_set(tmfc.ROI_set_number).BSC_beta_scrubbing.perform;
                end
            end

            [summary,perform_beta_scrubbing] = BSC_extraction_GUI(previous_summary,previous_scrubbing);
            if isempty(summary)
                disp('BSC LSS computation not initiated.');
                freeze_GUI(0);
                return;
            end

            % Preserve saved settings if a subsequent dialog is canceled
            tmfc_run = tmfc;
            tmfc_run.ROI_set(tmfc.ROI_set_number).BSC = summary;
            [sub_check,contrasts,beta_scrubbing_summary,FD_options] = tmfc_BSC(tmfc_run,tmfc.ROI_set_number,1,perform_beta_scrubbing,[],[],start_sub);

            if isempty(sub_check)
                disp('BSC LSS computation not initiated.');
                freeze_GUI(0);
                return;
            end

            tmfc.ROI_set(tmfc.ROI_set_number).BSC = summary;

            if ~isempty(FD_options)
                tmfc.FD_options = FD_options;
            end

            tmfc.ROI_set(tmfc.ROI_set_number).BSC_beta_scrubbing = beta_scrubbing_summary;

            % Update BSC progress
            for iSub = 1:nSub
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC = sub_check(iSub);
            end

            % Update default contrasts
            for iCon = 1:length(contrasts)
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iCon).title = contrasts(iCon).title;
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iCon).weights = contrasts(iCon).weights;
            end

            % Calculate previously defined custom contrasts
            nDefault = length(contrasts);
            nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC);

            for iCon = nDefault+1:nCon
                seed2vox_or_ROI2ROI(tmfc,iCon,3,start_sub);
            end

            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('BSC LSS computation completed.');

        catch ME
            freeze_GUI(0);
            fprintf(2, '\n%s\n', repmat('=',1,34));
            fprintf(2, '    BSC LSS computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,34));
            rethrow(ME);
        end

    % BSC was calculated for all subjects
    elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BSC] == 0)

        if strcmp(tmfc.session_mode,'repeated')
            fprintf('\nBSC was calculated for all subjects with repeated runs and %d Condition(s). \n', ...
                length(tmfc.LSS.conditions));
        else
            fprintf('\nBSC was calculated for all subjects, %d Run(s) (SPM sessions) and %d Condition(s). \n', ...
                max([tmfc.LSS.conditions.sess]), length(tmfc.LSS.conditions));
        end

        disp('To calculate BSC for different conditions, recompute LSS GLMs with desired conditions.');         
        
        % Define default contrasts if empty
        if isempty(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(1).title)
            cond_list = tmfc.LSS.conditions;
            nCond = length(cond_list);
            for iCond = 1:nCond
                if strcmp(tmfc.session_mode,'repeated')
                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iCond).title = ...
                        ['[All_Runs]_[Cond_' num2str(cond_list(iCond).number) ']_[' ...
                        regexprep(cond_list(iCond).name,' ','_') ']'];
                else
                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iCond).title = ...
                        ['[Run_' num2str(cond_list(iCond).sess) ']_[Cond_' ...
                        num2str(cond_list(iCond).number) ']_[' ...
                        regexprep(cond_list(iCond).name,' ','_') ']'];
                end
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iCond).weights = zeros(1,nCond);
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iCond).weights(1,iCond) = 1;
            end   
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        end
        
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
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        catch ME
            freeze_GUI(0);       
            fprintf(2, '\n%s\n', repmat('=',1,40));
            fprintf(2, '    New contrasts computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,40));
            rethrow(ME);
        end

    % BSC was calculated for some subjects 
    else
        disp('Initiating BSC LSS computation...');
        try
            start_sub = track_BSC;

            % Reuse previously defined BSC settings
            if ~has_BSC_settings
                % Backward compatibility: old BSC versions used mean extraction
                tmfc.ROI_set(tmfc.ROI_set_number).BSC = 'mean';
            end

            if isfield(tmfc.ROI_set(tmfc.ROI_set_number),'BSC_beta_scrubbing') && ...
                    ~isempty(tmfc.ROI_set(tmfc.ROI_set_number).BSC_beta_scrubbing) && ...
                    isfield(tmfc.ROI_set(tmfc.ROI_set_number).BSC_beta_scrubbing,'perform')

                beta_scrubbing_summary = tmfc.ROI_set(tmfc.ROI_set_number).BSC_beta_scrubbing;
            else
                % Backward compatibility: legacy BSC was calculated without beta scrubbing
                beta_scrubbing_summary.perform = 0;
                beta_scrubbing_summary.FD_thr = [];
                beta_scrubbing_summary.time_window = [];
                beta_scrubbing_summary.min_flagged_TRs = [];
            end

            perform_beta_scrubbing = beta_scrubbing_summary.perform;

            if perform_beta_scrubbing == 1
                beta_scrubbing_options.FD_thr = beta_scrubbing_summary.FD_thr;
                beta_scrubbing_options.time_window = beta_scrubbing_summary.time_window;
                beta_scrubbing_options.min_flagged_TRs = beta_scrubbing_summary.min_flagged_TRs;
            else
                beta_scrubbing_options = [];
            end

            % Do not clear old BSC files; process only incomplete/new subjects
            [sub_check,contrasts,beta_scrubbing_summary,FD_options] = tmfc_BSC(tmfc,tmfc.ROI_set_number,0,perform_beta_scrubbing,beta_scrubbing_options,[],start_sub);
      
            if isempty(sub_check)
                disp('BSC LSS computation not initiated.');
                freeze_GUI(0);
                return;
            end

            if ~isempty(FD_options)
                tmfc.FD_options = FD_options;
            end

            tmfc.ROI_set(tmfc.ROI_set_number).BSC_beta_scrubbing = beta_scrubbing_summary;
            for iSub = start_sub:nSub
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC = sub_check(iSub);
            end

            % Update default contrast definitions
            for iCon = 1:length(contrasts)
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iCon).title = contrasts(iCon).title;
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(iCon).weights = contrasts(iCon).weights;
            end

            % Calculate previously defined custom contrasts only for processed subjects
            nDefault = length(contrasts);
            nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC);

            for iCon = nDefault+1:nCon
                seed2vox_or_ROI2ROI(tmfc,iCon,3,start_sub);
            end

            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('BSC LSS computation completed.');
        catch ME
            freeze_GUI(0);
            fprintf(2, '\n%s\n', repmat('=',1,34));
            fprintf(2, '    BSC LSS computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,34));
            rethrow(ME);
        end
    end

    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);    
end

%% =========================[ FIR regression ]=============================
% Calculate FIR GLMs (residuals can be used for BGFC analysis and LSS_after_FIR GLMs)
function FIR_GUI(~,~,~)
    
    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~exist(tmfc.subjects(1).path,'file')
        error('SPM.mat file for the first subject does not exist.')
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    end
    
    % Freeze main TMFC GUI
    cd(tmfc.project_path);
    freeze_GUI(1);
    
    nSub = length(tmfc.subjects);
    
    % Update TMFC structure
    w = waitbar(0,'Please wait...','Name','Updating FIR progress');
    for iSub = 1:nSub
        if exist(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'GLM_batch.mat'),'file')
            tmfc.subjects(iSub).FIR = 1;
        else
            tmfc.subjects(iSub).FIR = 0;
        end
        try
            waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
        end
    end
    try, delete(w); catch, end    

    % Update main TMFC GUI
    track_FIR = 0;
    for iSub = 1:nSub
        if tmfc.subjects(iSub).FIR == 0
            track_FIR = iSub;
            break;
        end
    end   
    if track_FIR == 0
        set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
    elseif track_FIR == 1
        set(main_GUI.TMFC_GUI_S8,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
    else
        set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(track_FIR-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
    end
    
    restart_FIR = -1;
    continue_FIR = -1;

    % FIR GLMs were not calculated
    if ~any([tmfc.subjects(:).FIR] == 1)

        start_sub = 1;
        define_FIR_params = 1;

    % FIR GLMs were calculated for all subjects 
    elseif ~any([tmfc.subjects(:).FIR] == 0)
                 
        % Ask user to restart FIR computation
        restart_FIR = tmfc_restart_GUI(1);

        if restart_FIR == 1
            start_sub = 1;
            define_FIR_params = 1;
        else
            disp('FIR computation not initiated.');
            freeze_GUI(0); 
            return;
        end
        
    % FIR GLMs were calculated for some subjects  
    else

        % Ask user to continue or restart FIR computation
        continue_FIR = tmfc_continue_GUI(track_FIR,1);

        % Continue FIR computation
        if continue_FIR == 1
            start_sub = track_FIR;
            define_FIR_params = 0;
        % Restart FIR computation
        elseif continue_FIR == 0
            start_sub = 1;
            define_FIR_params = 1;
        else
            disp('FIR computation not initiated.'); 
            freeze_GUI(0);
            return;
        end
    end
    
    % Define FIR regression parameters
    if define_FIR_params == 1
        [window, bins] = tmfc_FIR_GUI(0);
        if isnan(window) || isnan(bins)
            warning('Define FIR parameters.');
            freeze_GUI(0);
            return;
        else           
            if restart_FIR == 1 || continue_FIR == 0
                tmfc = reset_FIR(tmfc);
                set(main_GUI.TMFC_GUI_S10, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
            end
            tmfc.FIR.window = window;
            tmfc.FIR.bins = bins;
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('FIR parameters selected.');
        end
    end

    % Compute FIR task regression
    disp('Initiating FIR computation...');
    try
        sub_check = tmfc_FIR(tmfc,start_sub);      
        for iSub = start_sub:nSub
            tmfc.subjects(iSub).FIR = sub_check(iSub);
        end
        save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        disp('FIR computation completed.');
    catch ME
        freeze_GUI(0);
        fprintf(2, '\n%s\n', repmat('=',1,30));
        fprintf(2, '    FIR computation failed\n');
        fprintf(2, '%s\n\n', repmat('=',1,30));
        rethrow(ME);
    end   
    
    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);
    
end

%% =============================[ BGFC ]===================================
% Calculate background functional connectivity (BGFC) 
function BGFC_GUI(~,~,~)

    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~exist(tmfc.subjects(1).path,'file')
        error('SPM.mat file for the first subject does not exist.')
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    elseif ~isfield(tmfc,'ROI_set')
        warning('Select ROIs.'); return;
    elseif ~isfield(tmfc.subjects,'FIR')
        warning('Calculate FIR task regression.'); return;
    elseif ~all([tmfc.subjects(:).FIR])
        error('Calculate FIR task regression for all subjects.');
    end
    ROI_check = check_ROI_masks(tmfc,tmfc.ROI_set_number);
    if ROI_check == 0
        error('One or more ROI masks are missing. Check the ROI_sets subfolder.')
    end

    nSub = length(tmfc.subjects);

    % Update BGFC progress
    w = waitbar(0,'Please wait...','Name','Updating BGFC progress');

    for iSub = 1:nSub
        SPM = load(tmfc.subjects(iSub).path).SPM;
        check_BGFC = zeros(1,length(SPM.Sess));
        for jSess = 1:length(SPM.Sess)       
            file_new = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC','ROI_to_ROI', ...
                [tmfc.subjects(iSub).name '_Run_' num2str(jSess) '.mat']);

            file_old = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC','ROI_to_ROI', ...
                [tmfc.subjects(iSub).name '_Session_' num2str(jSess) '.mat']);

            if exist(file_new,'file') || exist(file_old,'file')
                check_BGFC(jSess) = 1;
            end
        end

        % In repeated mode, also require the across-run average
        if strcmp(tmfc.session_mode,'repeated')
            file_all_runs = fullfile(tmfc.project_path,'ROI_sets', ...
                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC','ROI_to_ROI', ...
                [tmfc.subjects(iSub).name '_All_Runs.mat']);
            all_runs_done = exist(file_all_runs,'file') == 2;
        else
            all_runs_done = true;
        end

        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BGFC = double(~any(check_BGFC == 0) && all_runs_done);

        try
            waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
        end
    end
    try, delete(w); catch, end
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
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('BGFC computation completed.');
        catch ME
            freeze_GUI(0);
            fprintf(2, '\n%s\n', repmat('=',1,31));
            fprintf(2, '    BGFC computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,31));
            rethrow(ME);
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
                for iSub = track_BGFC:nSub
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BGFC = sub_check(iSub);
                end
                save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
                disp('BGFC computation completed.');
            else
                warning('BGFC computation not initiated.');
            end
        catch ME
            freeze_GUI(0);
        	fprintf(2, '\n%s\n', repmat('=',1,31));
            fprintf(2, '    BGFC computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,31));
            rethrow(ME);
        end
    end 

    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);    
end

%% =========================[ LSS after FIR ]==============================
% Estimate LSS GLMs after FIR task regression 
function LSS_FIR_GUI(~,~,~)

    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return;
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~exist(tmfc.subjects(1).path,'file')
        error('SPM.mat file for the first subject does not exist.')
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    elseif ~isfield(tmfc.subjects,'FIR')
        warning('Calculate FIR task regression.'); return;
    elseif ~all([tmfc.subjects(:).FIR])
        error('Calculate FIR task regression for all subjects.');
    end

    % Freeze main TMFC GUI
    cd(tmfc.project_path);
    freeze_GUI(1);

    try
        cond_list = tmfc.LSS_after_FIR.conditions;
        nCond = length(cond_list);
    end

    nSub = length(tmfc.subjects);

    % Update TMFC structure   
    LSS_after_FIR_done = ones(1,nSub);

    try
        w = waitbar(0,'Please wait...','Name','Updating LSS after FIR progress');
        for iSub = 1:nSub             
            SPM = load(tmfc.subjects(iSub).path).SPM;

            if strcmp(tmfc.session_mode,'repeated')
                sess_num = 1:length(SPM.Sess);
            else
                sess_num = unique([cond_list.sess]);
            end

            nSess = length(sess_num);

            for jSess = 1:nSess 
                % Trials of interest
                nTrial = 0;
                trial.cond = [];
                trial.number = [];
                for kCond = 1:nCond
                    if strcmp(tmfc.session_mode,'repeated') || cond_list(kCond).sess == sess_num(jSess)
                        nTrial = nTrial + length(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons);
                        trial.cond = [trial.cond; repmat(cond_list(kCond).number,length(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons),1)];
                        trial.number = [trial.number; (1:length(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons))'];
                    end
                end
                % Check individual trial GLMs
                for kTrial = 1:nTrial
                    file_new = fullfile(tmfc.project_path,'LSS_regression_after_FIR',tmfc.subjects(iSub).name,'GLM_batches', ...
                        ['GLM_[Run_' num2str(sess_num(jSess)) ']_[Cond_' num2str(trial.cond(kTrial)) ']_[' ...
                        regexprep(char(SPM.Sess(sess_num(jSess)).U(trial.cond(kTrial)).name(1)),' ','_') ']_[Trial_' ...
                        num2str(trial.number(kTrial)) '].mat']);

                    file_old = fullfile(tmfc.project_path,'LSS_regression_after_FIR',tmfc.subjects(iSub).name,'GLM_batches', ...
                        ['GLM_[Sess_' num2str(sess_num(jSess)) ']_[Cond_' num2str(trial.cond(kTrial)) ']_[' ...
                        regexprep(char(SPM.Sess(sess_num(jSess)).U(trial.cond(kTrial)).name(1)),' ','_') ']_[Trial_' ...
                        num2str(trial.number(kTrial)) '].mat']);

                    if exist(file_new,'file') || exist(file_old,'file')
                       condition(trial.cond(kTrial)).trials(trial.number(kTrial)) = 1;
                    else           
                       condition(trial.cond(kTrial)).trials(trial.number(kTrial)) = 0;
                       LSS_after_FIR_done(iSub) = 0;
                    end
                end
                tmfc.subjects(iSub).LSS_after_FIR.session(sess_num(jSess)).condition = condition;
                clear condition
            end
            try
                waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
            end
            clear SPM trial nTrial
        end
    end
    try, delete(w); catch, end

    % Update main TMFC GUI
    if exist('cond_list','var')
        track_LSS_after_FIR = find(LSS_after_FIR_done == 0,1,'first');

        if isempty(track_LSS_after_FIR)
            track_LSS_after_FIR = 0;
        end
    else
        track_LSS_after_FIR = 1;
    end
    
    if track_LSS_after_FIR == 0
        set(main_GUI.TMFC_GUI_S10,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
    elseif track_LSS_after_FIR == 1
        set(main_GUI.TMFC_GUI_S10,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
    else
        set(main_GUI.TMFC_GUI_S10,'String', strcat(num2str(track_LSS_after_FIR-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
    end

    restart_LSS_after_FIR = -1;
    continue_LSS_after_FIR = -1;

    % LSS_after_FIR was not calculated
    if track_LSS_after_FIR == 1    

        start_sub = 1;
        define_LSS_after_FIR_conditions = 1;

    % LSS_after_FIR was calculated for all subjects 
    elseif track_LSS_after_FIR == 0

        % Ask user to restart LSS_after_FIR computation
        restart_LSS_after_FIR = tmfc_restart_GUI(3);

        if restart_LSS_after_FIR == 1
            start_sub = 1;
            define_LSS_after_FIR_conditions = 1;
        else
            disp('LSS after FIR computation not initiated.');
            freeze_GUI(0); 
            return;
        end

    % LSS_after_FIR was calculated for some subjects  
    else

        % Ask user to continue or restart LSS_after_FIR computation
        continue_LSS_after_FIR = tmfc_continue_GUI(track_LSS_after_FIR,3);

        % Continue LSS_after_FIR computation
        if continue_LSS_after_FIR == 1
            start_sub = track_LSS_after_FIR;
            define_LSS_after_FIR_conditions = 0;
        % Restart LSS_after_FIR computation
        elseif continue_LSS_after_FIR == 0
            start_sub = 1;
            define_LSS_after_FIR_conditions = 1;
        else
            disp('LSS after FIR computation not initiated.'); 
            freeze_GUI(0);
            return;
        end
    end

    % Select LSS_after_FIR conditions
    if define_LSS_after_FIR_conditions == 1   
        LSS_after_FIR_conditions = tmfc_conditions_GUI(tmfc.subjects(1).path,3,tmfc.session_mode);   
        if isstruct(LSS_after_FIR_conditions)
            if restart_LSS_after_FIR == 1 || continue_LSS_after_FIR == 0
                tmfc = reset_LSS_after_FIR(tmfc);
            end
            tmfc.LSS_after_FIR.conditions = LSS_after_FIR_conditions;
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('Conditions of interest selected.');
        else
            warning('Conditions of interest not selected.');
            freeze_GUI(0);
            return;
        end
    end

    % Compute LSS_after_FIR
    disp('Initiating LSS after FIR computation...');
    try
        sub_check = tmfc_LSS_after_FIR(tmfc,start_sub);      
        for iSub = start_sub:nSub
            tmfc.subjects(iSub).LSS_after_FIR = sub_check(iSub);
        end
        save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        disp('LSS after FIR computation completed.');
    catch ME
        freeze_GUI(0);
        fprintf(2, '\n%s\n', repmat('=',1,41));
        fprintf(2, '    LSS after FIR computation failed\n');
        fprintf(2, '%s\n\n', repmat('=',1,41));
        rethrow(ME);
    end

    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);        
end

%% =========================[ BSC after FIR ]==============================
% Calculate beta-series correlations after FIR regression (BSC after FIR)
function BSC_after_FIR_GUI(~,~,~)

    % Initial checks
    if ~isfield(tmfc,'subjects')
        warning('Select subjects.'); return; 
    elseif strcmp(tmfc.subjects(1).path, '')
        warning('Select subjects.'); return;
    elseif ~isfield(tmfc,'project_path')
        error('Select TMFC project folder.');
    elseif ~isfield(tmfc,'ROI_set')
        warning('Select ROIs.'); return;
    elseif ~isfield(tmfc.subjects,'LSS_after_FIR')
        warning('Compute LSS after FIR for all selected subjects.'); return;
    end
    ROI_check = check_ROI_masks(tmfc,tmfc.ROI_set_number);
    if ROI_check == 0
        error('One or more ROI masks are missing. Check the ROI_sets subfolder.')
    end
    
    nSub = length(tmfc.subjects);

    % Check LSS after FIR progress 
    cond_list = tmfc.LSS_after_FIR.conditions;
    nCond = length(cond_list);

    for iSub = 1:nSub
        SPM = load(tmfc.subjects(iSub).path).SPM;

        if strcmp(tmfc.session_mode,'repeated')
            sess_num = 1:length(SPM.Sess);
        else
            sess_num = unique([cond_list.sess]);
        end

        for jSess = 1:length(sess_num)
            for kCond = 1:nCond
                if strcmp(tmfc.session_mode,'repeated') || cond_list(kCond).sess == sess_num(jSess)
                    LSS_FIR_progress = tmfc.subjects(iSub).LSS_after_FIR.session(sess_num(jSess)).condition(cond_list(kCond).number).trials;
                    if any(LSS_FIR_progress == 0)
                        error('Compute LSS after FIR for all selected subjects.');
                    end
                end
            end
        end
    end

    % Freeze main TMFC GUI
    cd(tmfc.project_path);
    freeze_GUI(1);

    % Update TMFC structure
    w = waitbar(0,'Please wait...','Name','Updating BSC after FIR progress');
    for iSub = 1:nSub
        beta_series_file = fullfile(tmfc.project_path,'ROI_sets', ...
            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR', ...
            'Beta_series',[tmfc.subjects(iSub).name '_beta_series.mat']);

        BSC_after_FIR_done = exist(beta_series_file,'file') == 2;

        % In repeated mode, require repeated-run beta-series format
        if BSC_after_FIR_done && strcmp(tmfc.session_mode,'repeated')
            try
                tmp = load(beta_series_file,'beta_series');
                BSC_after_FIR_done = isfield(tmp,'beta_series') && ~isempty(tmp.beta_series) && isfield(tmp.beta_series,'run');
            catch
                BSC_after_FIR_done = false;
            end
        end

        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC_after_FIR = double(BSC_after_FIR_done);
        try
            waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
        end
    end
    try, delete(w); catch, end

    % First subject with incomplete BSC after FIR
    track_BSC_after_FIR = find([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BSC_after_FIR] == 0,1,'first');

    if isempty(track_BSC_after_FIR)
        track_BSC_after_FIR = 0;
    end

    % Previously defined BSC after FIR settings
    has_BSC_after_FIR_settings = ...
        isfield(tmfc.ROI_set(tmfc.ROI_set_number),'BSC_after_FIR') && ...
        ~isempty(tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR);

    % BSC after FIR was not calculated
    if ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BSC_after_FIR] == 1)                           

        disp('Initiating BSC LSS after FIR computation...');   

        try
            start_sub = 1;
            
            % For a full BSC-after-FIR calculation, allow settings to be
            % selected again, using previous choices as defaults
            previous_summary = 'mean';
            previous_scrubbing = 1;
            if has_BSC_after_FIR_settings
                previous_summary = tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR;
                previous_scrubbing = 0; % Legacy BSC used no beta scrubbing
                if isfield(tmfc.ROI_set(tmfc.ROI_set_number),'BSC_after_FIR_beta_scrubbing') && ...
                        ~isempty(tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR_beta_scrubbing) && ...
                        isfield(tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR_beta_scrubbing,'perform')
                    previous_scrubbing = tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR_beta_scrubbing.perform;
                end
            end

            [summary,perform_beta_scrubbing] = BSC_extraction_GUI(previous_summary,previous_scrubbing);
            if isempty(summary)
                disp('BSC LSS after FIR computation not initiated.');
                freeze_GUI(0);
                return;
            end

            % Preserve saved settings if a subsequent dialog is canceled
            tmfc_run = tmfc;
            tmfc_run.ROI_set(tmfc.ROI_set_number).BSC_after_FIR = summary;
            [sub_check,contrasts,beta_scrubbing_summary,FD_options] = tmfc_BSC_after_FIR(tmfc_run,tmfc.ROI_set_number,1,perform_beta_scrubbing,[],[],start_sub);

            if isempty(sub_check)
                disp('BSC LSS after FIR computation not initiated.');
                freeze_GUI(0);
                return;
            end

            tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR = summary;

            if ~isempty(FD_options)
                tmfc.FD_options = FD_options;
            end

            tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR_beta_scrubbing = beta_scrubbing_summary;

            % Update BSC after FIR progress 
            for iSub = start_sub:nSub
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC_after_FIR = sub_check(iSub);
            end

            % Update default contrasts
            for iCon = 1:length(contrasts)
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(iCon).title = contrasts(iCon).title;
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(iCon).weights = contrasts(iCon).weights;
            end

            % Calculate previously defined custom contrasts
            nDefault = length(contrasts);
            nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR);

            for iCon = nDefault+1:nCon
                seed2vox_or_ROI2ROI(tmfc,iCon,4,start_sub);
            end

            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('BSC LSS after FIR computation completed.');
        catch ME
            freeze_GUI(0);
            fprintf(2, '\n%s\n', repmat('=',1,41));
            fprintf(2, '    BSC LSS after FIR computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,41));
            rethrow(ME);
        end

    % BSC after FIR was calculated for all subjects
    elseif ~any([tmfc.ROI_set(tmfc.ROI_set_number).subjects(:).BSC_after_FIR] == 0)

        if strcmp(tmfc.session_mode,'repeated')
            fprintf('\nBSC after FIR was calculated for all subjects with %d Condition(s). \n', ...
                length(tmfc.LSS_after_FIR.conditions));
        else
            fprintf('\nBSC after FIR was calculated for all subjects, %d Run(s) (SPM sessions) and %d Condition(s). \n', ...
                max([tmfc.LSS_after_FIR.conditions.sess]), length(tmfc.LSS_after_FIR.conditions));
        end
        
        disp('To calculate BSC after FIR for different conditions, recompute LSS after FIR with desired conditions.');         
        
        % Define default contrasts if empty
        if isempty(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(1).title)
            cond_list = tmfc.LSS_after_FIR.conditions;
            nCond = length(cond_list);
            for iCond = 1:nCond
                if strcmp(tmfc.session_mode,'repeated')
                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(iCond).title = ...
                        ['[All_Runs]_[Cond_' num2str(cond_list(iCond).number) ']_[' ...
                        regexprep(cond_list(iCond).name,' ','_') ']'];
                else
                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(iCond).title = ...
                        ['[Run_' num2str(cond_list(iCond).sess) ']_[Cond_' ...
                        num2str(cond_list(iCond).number) ']_[' ...
                        regexprep(cond_list(iCond).name,' ','_') ']'];
                end
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(iCond).weights = zeros(1,nCond);
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(iCond).weights(1,iCond) = 1;
            end 
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        end
        
        % Number of previously calculated contrasts
        nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR);

        try
            % Specify new contrasts
            tmfc = tmfc_specify_contrasts_GUI(tmfc,tmfc.ROI_set_number,4);

            % Calculate new contrasts
            if nCon ~= length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR)       
                for iCon = nCon+1:length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR)
                    seed2vox_or_ROI2ROI(tmfc,iCon,4);
                end
            end
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        catch ME
            freeze_GUI(0);       
            fprintf(2, '\n%s\n', repmat('=',1,40));
            fprintf(2, '    New contrasts computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,40));
            rethrow(ME);
        end

    % BSC after FIR was calculated for some subjects 
    else
        disp('Initiating BSC LSS after FIR computation...');
        try
            start_sub = track_BSC_after_FIR;

            % Reuse previously defined BSC after FIR settings
            if ~has_BSC_after_FIR_settings
                % Backward compatibility: old BSC versions used mean extraction
                tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR = 'mean';
            end

            if isfield(tmfc.ROI_set(tmfc.ROI_set_number),'BSC_after_FIR_beta_scrubbing') && ...
                    ~isempty(tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR_beta_scrubbing) && ...
                    isfield(tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR_beta_scrubbing,'perform')

                beta_scrubbing_summary = tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR_beta_scrubbing;
            else
                % Backward compatibility: legacy BSC was calculated without beta scrubbing
                beta_scrubbing_summary.perform = 0;
                beta_scrubbing_summary.FD_thr = [];
                beta_scrubbing_summary.time_window = [];
                beta_scrubbing_summary.min_flagged_TRs = [];
            end

            perform_beta_scrubbing = beta_scrubbing_summary.perform;

            if perform_beta_scrubbing == 1
                beta_scrubbing_options.FD_thr = beta_scrubbing_summary.FD_thr;
                beta_scrubbing_options.time_window = beta_scrubbing_summary.time_window;
                beta_scrubbing_options.min_flagged_TRs = beta_scrubbing_summary.min_flagged_TRs;
            else
                beta_scrubbing_options = [];
            end

            % Do not clear old BSC files; process only incomplete/new subjects
            [sub_check,contrasts,beta_scrubbing_summary,FD_options] = tmfc_BSC_after_FIR(tmfc,tmfc.ROI_set_number,0,perform_beta_scrubbing,beta_scrubbing_options,[],start_sub);
        
            if isempty(sub_check)
                disp('BSC LSS after FIR computation not initiated.');
                freeze_GUI(0);
                return;
            end

            if ~isempty(FD_options)
                tmfc.FD_options = FD_options;
            end
            
            tmfc.ROI_set(tmfc.ROI_set_number).BSC_after_FIR_beta_scrubbing = beta_scrubbing_summary;

            % Update only processed subjects
            for iSub = start_sub:nSub
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC_after_FIR = sub_check(iSub);
            end

            % Update default contrast definitions
            for iCon = 1:length(contrasts)
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(iCon).title = contrasts(iCon).title;
                tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(iCon).weights = contrasts(iCon).weights;
            end

            % Calculate previously defined custom contrasts only for processed subjects
            nDefault = length(contrasts);
            nCon = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR);

            for iCon = nDefault+1:nCon
                seed2vox_or_ROI2ROI(tmfc,iCon,4,start_sub);
            end

            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
            disp('BSC LSS after FIR computation completed.');
        catch ME
            freeze_GUI(0);
            fprintf(2, '\n%s\n', repmat('=',1,44));
            fprintf(2, '    BSC LSS after FIR computation failed\n');
            fprintf(2, '%s\n\n', repmat('=',1,44));
            rethrow(ME);
        end
    end

    save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');

    % Unfreeze main TMFC GUI
    freeze_GUI(0);
end

%% ==========================[ Load project ]==============================
% Load TMFC project (*.mat file)
function load_project_GUI(~,~,~)

	[filename, path] = uigetfile('*.mat', 'Select TMFC project file');

    if isequal(filename,0)
        warning('No file selected to load.');
        return;
    end
                                         
    fullpath = fullfile(path,filename);           

    % Load data into temporary variable
    loaded_data = load(fullpath);  

    if ~isfield(loaded_data,'tmfc')
        warning('Selected file is not in TMFC format, please select another file.');
        return;
    end

    % Work on a temporary copy until project validation is completed
    tmfc_new = loaded_data.tmfc;
                            
    if ~isfield(tmfc_new,'defaults')
        tmfc_new.defaults.parallel = 0;
        tmfc_new.defaults.maxmem = 2^32;
        tmfc_new.defaults.resmem = true;
        tmfc_new.defaults.analysis = 1;
    end
    
    if ~isfield(tmfc_new.defaults,'parallel')
        tmfc_new.defaults.parallel = 0;
    end
    if ~isfield(tmfc_new.defaults,'maxmem')
        tmfc_new.defaults.maxmem = 2^32;
    end
    if ~isfield(tmfc_new.defaults,'resmem')
        tmfc_new.defaults.resmem = true;
    end
    if ~isfield(tmfc_new.defaults,'analysis')
        tmfc_new.defaults.analysis = 1;
    end

    if ~isfield(tmfc_new,'session_mode') || isempty(tmfc_new.session_mode)
        tmfc_new.session_mode = 'strict';
    end

    %----------------------------------------------------------------------
    % Check project path
    if ~isfield(tmfc_new,'project_path') || isempty(tmfc_new.project_path) || ~isdir(tmfc_new.project_path)
        warning('TMFC project path not specified or does not exist. TMFC project not loaded.');
        return;
    end
           
    %----------------------------------------------------------------------
    % Check subjects
    if ~isfield(tmfc_new,'subjects') || isempty(tmfc_new.subjects)
        warning('Subjects not specified. TMFC project not loaded.');
        return;
    end

    nSub = length(tmfc_new.subjects);
    sub_check = zeros(1,nSub);

    for iSub = 1:nSub
        sub_check(iSub) = exist(tmfc_new.subjects(iSub).path,'file') == 2;
    end

    if any(sub_check == 0)
        fprintf('\nMissing SPM.mat file(s):\n');
        for iSub = find(sub_check == 0)
            fprintf('  %s\n',tmfc_new.subjects(iSub).path);
        end
        warning('SPM.mat files for one or more subjects are missing. TMFC project not loaded.');
        return;
    end

    %----------------------------------------------------------------------
    % Backward compatibility: subject names
    if ~isfield(tmfc_new.subjects,'name')
        for iSub = 1:nSub
            tmfc_new.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
        end
    end

    %----------------------------------------------------------------------
    % Check subject name uniqueness
    subject_names = {tmfc_new.subjects.name};
    for iSub = 1:length(subject_names)-1
        if any(strcmpi(subject_names{iSub},subject_names(iSub+1:end)))
            warning('TMFC: Subject names must be unique. TMFC project not loaded.');
            return;
        end
    end

    %--------------------------------------------------------------
    % Backward compatibility: infer subject naming convention
    if (~isfield(tmfc_new,'subject_naming') || isempty(tmfc_new.subject_naming)) && isfield(tmfc_new,'subjects')
        standard_names = true;
        for iSub = 1:nSub
            if isempty(regexp(tmfc_new.subjects(iSub).name,'^Subject_\d{4}$','once'))
                standard_names = false;
                break;
            end
        end
        if standard_names
            tmfc_new.subject_naming = 'standard';
        else
            tmfc_new.subject_naming = 'original';
        end
    end
    
    %--------------------------------------------------------------
    % Backward compatibility: define next standard subject number
    if strcmp(tmfc_new.subject_naming,'standard') && (~isfield(tmfc_new,'next_subject') || isempty(tmfc_new.next_subject))
        subject_numbers = zeros(1,length(tmfc_new.subjects));
        for iSub = 1:length(tmfc_new.subjects)
            token = regexp(tmfc_new.subjects(iSub).name,'^Subject_(\d+)$','tokens','once');
            if ~isempty(token)
                subject_numbers(iSub) = str2double(token{1});
            end
        end
        tmfc_new.next_subject = max(subject_numbers) + 1;
    end

    %----------------------------------------------------------------------
    % Candidate passed basic validation
    tmfc_old = tmfc;
    freeze_GUI(1);
    old_path = pwd;

    try
        cd(tmfc_new.project_path);

        %------------------------------------------------------------------
        % Resume interrupted ROI extension
        ROI_extension_needed = check_ROI_extension(tmfc_new);
        if ROI_extension_needed
            fprintf('TMFC: Incomplete ROI extension detected. Resuming ROI mask creation.\n');
            tmfc_new = tmfc_extend_ROI_sets(tmfc_new);
            disp('TMFC: ROI extension completed.');
        end

        %--------------------------------------------------------------
        % Check selected ROI set after recovery
        if isfield(tmfc_new,'ROI_set') && ~isempty(tmfc_new.ROI_set)
            if ~isfield(tmfc_new,'ROI_set_number')
                tmfc_new.ROI_set_number = 1;
            end

            if tmfc_new.ROI_set_number < 1 || tmfc_new.ROI_set_number > length(tmfc_new.ROI_set)
                error('Invalid ROI set number in TMFC project.');
            end

            if check_ROI_masks(tmfc_new,tmfc_new.ROI_set_number) == 0
                error('One or more ROI masks are missing. Check the ROI_sets subfolder.');
            end
        end

        %--------------------------------------------------------------
        % Commit validated project
        tmfc = tmfc_new;

        % Save recovered ROI extension
        if ROI_extension_needed
            save(fullfile(tmfc.project_path,'tmfc_autosave.mat'),'tmfc');
        end
                   
        %--------------------------------------------------------------
        % Reset TMFC progress
        set(main_GUI.TMFC_GUI_S1,'String',[num2str(nSub) ' selected'],'ForegroundColor',[0.219, 0.341, 0.137]);
        set(main_GUI.TMFC_GUI_S2,'String', 'Not selected','ForegroundColor',[1, 0, 0]);
        set(main_GUI.TMFC_GUI_S3,'String', 'Not selected','ForegroundColor',[0.773, 0.353, 0.067]);
        set(main_GUI.TMFC_GUI_S4,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
        set(main_GUI.TMFC_GUI_S6,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
        set(main_GUI.TMFC_GUI_S8,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
        set(main_GUI.TMFC_GUI_S10,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);

        %--------------------------------------------------------------
        % Update TMFC GUI
        tmfc = update_tmfc_progress(tmfc);
        fprintf('Loaded file: "%s".\n', filename);

    catch ME
        tmfc = tmfc_old;
        cd(old_path);
        freeze_GUI(0);

        fprintf(2,'\n%s\n',repmat('=',1,30));
        fprintf(2,'    TMFC project loading failed\n');
        fprintf(2,'%s\n\n',repmat('=',1,30));

        rethrow(ME);
	end
end

%% ==========================[ Save project ]==============================
% Save TMFC project file
function save_status = save_project_GUI(~,~,~)

    [filename, pathname] = uiputfile('*.mat', 'Save TMFC project file');
    save_status = 0;
    
    % Check file name and path
    if isequal(filename,0) || isequal(pathname,0)
        warning('TMFC project not saved. File name or project path not selected.');  
    else    
        fullpath = fullfile(pathname, filename);
        try 
            save(fullpath, 'tmfc');
            save_status = 1;
            fprintf('TMFC project saved: %s\n', fullpath);
        catch 
            save_status = 0;
            disp('TMFC project not saved.');
        end       
    end       
end

%% ==========================[ Change paths ]==============================
% Change paths in selected SPM.mat files
function tools_GUI(~,~,~)

    tmfc_tools_GUI = figure('Name', 'TMFC tools','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.180 0.35 0.200 0.200], 'color', 'w', 'Tag', 'TMFC_GUI_tools','resize', 'off','WindowStyle','modal');
    tmfc_tools_denoise = uicontrol(tmfc_tools_GUI,'Style', 'pushbutton', 'String', 'Denoise', 'Units', 'normalized', 'Position', [0.180 0.70 0.65 0.19],'FontUnits','normalized','FontSize',0.35,'callback', @denoise);
    tmfc_tools_change_paths = uicontrol(tmfc_tools_GUI,'Style', 'pushbutton', 'String', 'Change paths', 'Units', 'normalized', 'Position', [0.180 0.42 0.65 0.19],'FontUnits','normalized','FontSize',0.35,'callback', @change_paths);
    tmfc_tools_gPPI_asm = uicontrol(tmfc_tools_GUI,'Style', 'pushbutton', 'String', 'gPPI asymmetry', 'Units', 'normalized', 'Position', [0.180 0.14 0.65 0.19],'FontUnits','normalized','FontSize',0.35,'callback', @gPPI_asm);
    movegui(tmfc_tools_GUI,'center');
    
    % Denoising -----------------------------------------------------------
    function denoise(~,~)
        % Close tool window
        close(tmfc_tools_GUI);
        TMFC_denoise;
    end
    
    % Change Paths --------------------------------------------------------
    function change_paths(~,~)

        % Close tool window
        close(tmfc_tools_GUI);

        disp('Select SPM.mat files to change paths...');

        % Select subject & do not check SPM.mat files
        subjects = tmfc_select_subjects_GUI(0);

        if ~isempty(subjects)
            tmfc_change_paths_GUI(subjects);
        else
            disp('No SPM.mat files selected for path change.');
        end
    end

    % Estimate gPPI asymmetry ---------------------------------------------
    function gPPI_asm(~,~)

        % Close tool window
        close(tmfc_tools_GUI);

        disp('Work in progress. Please wait for future updates.');
        %tmfc_estimate_gPPI_asymmetry_GUI();

    end    
end

%% ============================[ Settings ]================================
set_computing = {'Sequential computing', 'Parallel computing'};
set_storage = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
set_analysis = {'Seed-to-voxel and ROI-to-ROI','ROI-to-ROI only','Seed-to-voxel only'};

function settings_GUI(~,~,~)

    tmfc_set = figure('Name', 'TMFC toolbox','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.380 0.0875 0.250 0.850], 'color', 'w', 'Tag', 'TMFC_GUI_Settings','resize', 'off','WindowStyle','modal');


    set_str_1 = {'The number of workers in a parallel pool can be changed in MATLAB settings. NOTE: Parallel computations might be slower than sequential ones on low-end PCs.'};
    set_str_2 = {'This option temporarily changes the resmem variable in spm_defaults, which governs whether temporary files created during GLM estimation are stored on disk or kept in memory. If you have enough available RAM, not writing files to disk will speed estimation.'};
    set_str_3 = {'“Max RAM” temporarily changes the maxmem variable in spm_defaults, which indicates how much memory can be used simultaneously during GLM estimation. If your computer has a large amount of RAM, you can increase this setting:'};
    set_str_4 = {'* 2^31 = 2GB','* 2^32 = 4GB', '* 2^33 = 8GB','* 2^34 = 16GB','* 2^35 = 32GB'};
    set_str_5 = {'Perform seed-to-voxel or ROI-to-ROI analysis, or both. Applies to gPPI and BSC methods.','', ...
             'Seed-to-voxel gPPI is computationally expensive and can take a long time because it estimates gPPI model parameters for each voxel.','', ...
             'Seed-to-voxel BSC computes relatively quickly (about as fast as ROI-to-ROI analysis) since voxel-wise correlations are not computationally expensive.'};

    % Drop down menus
    % MP = Main  panel
    tmfc_set_MP1 = uipanel(tmfc_set,'Units', 'normalized','Position',[0.03 0.865 0.94 0.125],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    tmfc_set_MP2 = uipanel(tmfc_set,'Units', 'normalized','Position',[0.03 0.685 0.94 0.17],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    tmfc_set_MP3 = uipanel(tmfc_set,'Units', 'normalized','Position',[0.03 0.375 0.94 0.30],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    tmfc_set_MP4 = uipanel(tmfc_set,'Units', 'normalized','Position',[0.03 0.10 0.94 0.265],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    
    tmfc_set_P1 = uicontrol(tmfc_set,'Style','popupmenu', 'String', set_computing ,'Units', 'normalized', 'Position',[0.048 0.908 0.90 0.07],'fontunits','normalized', 'fontSize', 0.265);
    tmfc_set_P2 = uicontrol(tmfc_set,'Style','popupmenu', 'String', set_storage ,'Units', 'normalized', 'Position',[0.048 0.775 0.90 0.07],'fontunits','normalized', 'fontSize', 0.265);
    tmfc_set_P3 = uicontrol(tmfc_set,'Style','popupmenu', 'String', set_analysis ,'Units', 'normalized', 'Position',[0.048 0.282 0.90 0.07],'fontunits','normalized', 'fontSize', 0.265);
    
    tmfc_set_ok = uicontrol(tmfc_set,'Style', 'pushbutton', 'String', 'OK', 'Units', 'normalized', 'Position', [0.3 0.03 0.40 0.05],'FontUnits','normalized','FontSize',0.33,'callback', @sync_set);
    tmfc_set_E1 = uicontrol(tmfc_set,'Style','edit','String', tmfc.defaults.maxmem,'Units', 'normalized', 'HorizontalAlignment', 'center','Position',[0.72 0.615 0.22 0.05],'fontunits','normalized', 'fontSize', 0.38);
    
    if isunix; fontscale = [0.9, 0.85, 0.9, 0.83]; else; fontscale = [1, 1 ,1, 1]; end

    tmfc_set_S1 = uicontrol(tmfc_set,'Style','text','String', set_str_1,'Units', 'normalized', 'Position',[0.05 0.87 0.90 0.07],'fontunits','normalized','fontSize', 0.245*fontscale(1), 'HorizontalAlignment', 'left','BackgroundColor','w');
    tmfc_set_S2 = uicontrol(tmfc_set,'Style','text','String', set_str_2,'Units', 'normalized', 'Position',[0.05 0.69 0.90 0.11],'fontunits','normalized','fontSize', 0.16*fontscale(2), 'HorizontalAlignment', 'left','BackgroundColor','w');
    tmfc_set_S3a = uicontrol(tmfc_set,'Style','text','String', 'Max RAM for GLM estimation (bytes):','Units', 'normalized', 'Position',[0.048 0.61 0.65 0.04],'fontunits','normalized', 'fontSize', 0.46,'HorizontalAlignment', 'left','BackgroundColor','w');%
    tmfc_set_S3 = uicontrol(tmfc_set,'Style','text','String', set_str_3,'Units', 'normalized', 'Position',[0.05 0.495 0.90 0.11],'fontunits','normalized','fontSize', 0.16*fontscale(3), 'HorizontalAlignment', 'left','BackgroundColor','w');
    tmfc_set_S4 = uicontrol(tmfc_set,'Style','text','String', set_str_4,'Units', 'normalized', 'Position',[0.39 0.38 0.27 0.11],'fontunits','normalized','fontSize', 0.15*fontscale(3), 'HorizontalAlignment', 'left','BackgroundColor','w');
    tmfc_set_S5 = uicontrol(tmfc_set,'Style','text','String', set_str_5,'Units', 'normalized', 'Position',[0.05 0.11 0.90 0.20],'fontunits','normalized','fontSize', 0.088*fontscale(4), 'HorizontalAlignment', 'left','BackgroundColor','w');
    
    tmfc_copy = tmfc;

    % Update settings -----------------------------------------------------
    function sync_set(~,~)        
        
    	C_1{1} = get(tmfc_set_P1, 'String');
        C_1{2} = get(tmfc_set_P1, 'Value');
        if strcmp(C_1{1}(C_1{2}),'Sequential computing')
        	set_computing = {'Sequential computing','Parallel computing'};
        	set(tmfc_set_P1, 'String', set_computing);
        	tmfc.defaults.parallel = 0;

        elseif strcmp(C_1{1}(C_1{2}),'Parallel computing')
            set_computing = {'Parallel computing','Sequential computing'};
            set(tmfc_set_P1, 'String', set_computing);
            tmfc.defaults.parallel = 1;
        end
        clear C_1


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

        C_3 = strtrim(get(tmfc_set_E1,'String'));
        val = str2double(C_3);
        if isnan(val)
            tok = regexp(C_3, '^\s*(\d+)\s*\^\s*(\d+)\s*$', 'tokens', 'once');
            if ~isempty(tok)
                base = str2double(tok{1});
                expo = str2double(tok{2});
                val  = base^expo;
            end
        end
        
        if ~isnan(val) && isfinite(val) && val > 0
            tmfc.defaults.maxmem = val;
            set(tmfc_set_E1, 'String', num2str(val));
        else
            warndlg('Max RAM: Enter a positive number (e.g., 2^34 or 17179869184).','Invalid value');
        end

        clear C_3 

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

        % Comparison 
        if tmfc_copy.defaults.parallel == tmfc.defaults.parallel && ...
           tmfc_copy.defaults.maxmem == tmfc.defaults.maxmem && ...
           tmfc_copy.defaults.resmem == tmfc.defaults.resmem && ...
           tmfc_copy.defaults.analysis == tmfc.defaults.analysis
        	disp('Settings have not been changed.');
        else
        	disp('Settings have been updated.');
        end
        close(tmfc_set);
    end   
end

%% =============================[ Close ]==================================
function close_GUI(~,~,~) 
       
    exit_msg = figure('Name', 'TMFC: Exit', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.20 0.15],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'EXIT_FIN', 'WindowStyle','modal');
    
    exit_str1 = uicontrol(exit_msg,'Style','text','String', 'Would you like to save your progress','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38, 'Position',[0.04 0.55 0.94 0.260],'BackgroundColor',get(exit_msg,'color'));
    exit_str2 = uicontrol(exit_msg,'Style','text','String', 'before exiting TMFC toolbox?', 'Units','normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38, 'Position',[0.10 0.40 0.80 0.260],'BackgroundColor',get(exit_msg,'color'));

    exit_yes = uicontrol(exit_msg,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.40,'Position',[0.16 0.18 0.300 0.200],'callback', @exit_save);
    exit_no = uicontrol(exit_msg,'Style','pushbutton', 'String', 'No','Units', 'normalized','fontunits','normalized', 'fontSize', 0.40,'Position',[0.57 0.18 0.300 0.200],'callback', @exit_no_save);     

    function exit_no_save(~,~)
        close(exit_msg);
        delete(main_GUI.TMFC_GUI);
        disp('Goodbye!');
    end

    function exit_save(~,~)
        save_status = save_project_GUI();
        if save_status == 1
            close(exit_msg);
            delete(main_GUI.TMFC_GUI);
            disp('Goodbye!');
        end
    end    
end

%% ===========================[ Statistics ]===============================
function statistics_GUI(~,~,~)
	freeze_GUI(1);
    TMFC_statistics();
    freeze_GUI(0);
end

%% ============================[ Results ]=================================
function results_GUI(~,~,~)
    tmfc_results_GUI();
end

%% =========[ Update main TMFC GUI after loading a TMFC project ]==========
function tmfc = update_tmfc_progress(tmfc)
    
    nSub = length(tmfc.subjects);
    w = waitbar(0,'Please wait...','Name','Updating TMFC project');

    %----------------------------------------------------------------------
    % Update ROI set 
    if isfield(tmfc,'ROI_set')
        try, waitbar(1/8,w,'Updating ROI set...'); end
        
        if ~isfield(tmfc,'ROI_set_number')  
            tmfc.ROI_set_number = 1;
        end
        
        if isfield(tmfc.ROI_set,'ROIs')
            % Backward compatibility: infer ROI type
            for iSet = 1:length(tmfc.ROI_set)
                if ~isfield(tmfc.ROI_set(iSet),'type') || isempty(tmfc.ROI_set(iSet).type)
                    if isfield(tmfc.ROI_set(iSet).ROIs,'path') && ~isfield(tmfc.ROI_set(iSet).ROIs,'radius')
                        tmfc.ROI_set(iSet).type = 'binary_images';
                    elseif ~isfield(tmfc.ROI_set(iSet).ROIs,'path') && isfield(tmfc.ROI_set(iSet).ROIs,'radius')
                        tmfc.ROI_set(iSet).type = 'fixed_spheres';
                    elseif isfield(tmfc.ROI_set(iSet).ROIs,'moving_radius')
                        tmfc.ROI_set(iSet).type = 'moving_spheres_inside_fixed_spheres';
                    else
                        tmfc.ROI_set(iSet).type = 'moving_spheres_inside_binary_images';
                    end
                end
            end
            ROI_check = check_ROI_masks(tmfc,tmfc.ROI_set_number);
        else
            ROI_check = 0;
        end
        
        if ROI_check == 1
            set(main_GUI.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(tmfc.ROI_set_number).set_name, ' (',num2str(length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]); 
        else
            freeze_GUI(0); try, delete(w); catch, end
            error('One or more ROI masks are missing. Check the ROI_sets subfolder.');
        end
    else
        set(main_GUI.TMFC_GUI_S2, ...
            'String','Not selected', ...
            'ForegroundColor',[1, 0, 0]);
        set(main_GUI.TMFC_GUI_S3, ...
            'String','Not done', ...
            'ForegroundColor',[0.773, 0.353, 0.067]);
        set(main_GUI.TMFC_GUI_S4, ...
            'String','Not done', ...
            'ForegroundColor',[0.773, 0.353, 0.067]);
    end
    
    %----------------------------------------------------------------------
    % Update VOIs, PPIs, gPPI, gPPI-FIR
    if isfield(tmfc,'subjects') && isfield(tmfc,'ROI_set')
        try, waitbar(2/8,w,'Updating VOIs, PPIs, gPPI and gPPI-FIR...'); end
        tmfc = update_gPPI(tmfc);
    end
    
    %----------------------------------------------------------------------
    % Update LSS      
    if isfield(tmfc,'subjects') && isfield(tmfc,'LSS')

        % If conditions are missing/empty -> treat as "not computed"
        if ~isfield(tmfc.LSS,'conditions') || isempty(tmfc.LSS.conditions)
            set(main_GUI.TMFC_GUI_S6,'String','Not done','ForegroundColor',[0.773, 0.353, 0.067]);
        else
            try
                cond_list = tmfc.LSS.conditions;
                nCond = numel(cond_list);
      
                try, waitbar(3/8,w,'Updating LSS GLMs...'); end

                LSS_done = ones(1,nSub);

                for iSub = 1:nSub
                    SPM = load(tmfc.subjects(iSub).path).SPM;

                    if strcmp(tmfc.session_mode,'repeated')
                        sess_num = 1:length(SPM.Sess);
                    else
                        sess_num = unique([cond_list.sess]);
                    end

                    nSess = length(sess_num);

                    for jSess = 1:nSess
                        % Trials of interest
                        nTrial = 0; trial.cond = []; trial.number = [];
                        for kCond = 1:nCond
                            if strcmp(tmfc.session_mode,'repeated') || cond_list(kCond).sess == sess_num(jSess)
                                nOns = numel(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons);
                                nTrial      = nTrial + nOns;
                                trial.cond   = [trial.cond;   repmat(cond_list(kCond).number, nOns, 1)];
                                trial.number = [trial.number; (1:nOns)'];
                            end
                        end
                        % Check individual trial GLMs
                        condition = struct(); 
                        for kTrial = 1:nTrial
                            file_new = fullfile(tmfc.project_path,'LSS_regression',tmfc.subjects(iSub).name,'GLM_batches', ...
                                ['GLM_[Run_' num2str(sess_num(jSess)) ']_[Cond_' num2str(trial.cond(kTrial)) ']_[' ...
                                regexprep(char(SPM.Sess(sess_num(jSess)).U(trial.cond(kTrial)).name(1)),' ','_') ...
                                ']_[Trial_' num2str(trial.number(kTrial)) '].mat']);

                            file_old = fullfile(tmfc.project_path,'LSS_regression',tmfc.subjects(iSub).name,'GLM_batches', ...
                                ['GLM_[Sess_' num2str(sess_num(jSess)) ']_[Cond_' num2str(trial.cond(kTrial)) ']_[' ...
                                regexprep(char(SPM.Sess(sess_num(jSess)).U(trial.cond(kTrial)).name(1)),' ','_') ...
                                ']_[Trial_' num2str(trial.number(kTrial)) '].mat']);

                            if exist(file_new,'file') || exist(file_old,'file')
                                condition(trial.cond(kTrial)).trials(trial.number(kTrial)) = 1;
                            else
                                condition(trial.cond(kTrial)).trials(trial.number(kTrial)) = 0;
                                LSS_done(iSub) = 0;
                            end
                        end
                        tmfc.subjects(iSub).LSS.session(sess_num(jSess)).condition = condition;
                    end
                    clear SPM trial nTrial
                end
    
                % Progress across subjects
                track_LSS = find(LSS_done == 0,1,'first');

                if isempty(track_LSS)
                    track_LSS = 0;
                end
    
                % GUI update
                if track_LSS == 0
                    set(main_GUI.TMFC_GUI_S6,'String',sprintf('%d/%d done',nSub,nSub),'ForegroundColor',[0.219, 0.341, 0.137]);
                elseif track_LSS == 1
                    set(main_GUI.TMFC_GUI_S6,'String','Not done','ForegroundColor',[0.773, 0.353, 0.067]);
                else
                    set(main_GUI.TMFC_GUI_S6,'String',sprintf('%d/%d done',track_LSS-1,nSub),'ForegroundColor',[0.219, 0.341, 0.137]);
                end
    
                clear cond_list nCond sess_num nSess
            catch 
                if exist('iSub','var')
                    fprintf(2,'Problem with subject %d: %s\n',iSub,tmfc.subjects(iSub).path);
                end
                warning('LSS progress not updated. Check LSS conditions.');
            end
        end
    end   
    
    %----------------------------------------------------------------------
    % Update BSC-LSS
    if isfield(tmfc,'subjects') && isfield(tmfc,'ROI_set') && isfield(tmfc,'LSS')
        try, waitbar(4/8,w,'Updating BSC-LSS...'); end
        for iSub = 1:nSub
            beta_series_file = fullfile(tmfc.project_path,'ROI_sets', ...
                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS', ...
                'Beta_series',[tmfc.subjects(iSub).name '_beta_series.mat']);

            BSC_done = exist(beta_series_file,'file') == 2;

            if BSC_done && strcmp(tmfc.session_mode,'repeated')
                try
                    tmp = load(beta_series_file,'beta_series');
                    BSC_done = isfield(tmp,'beta_series') && ~isempty(tmp.beta_series) && isfield(tmp.beta_series,'run');
                catch
                    BSC_done = false;
                end
            end

            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC = double(BSC_done);
        end
    end
    
    %----------------------------------------------------------------------
    % Update FIR
    if isfield(tmfc,'subjects') && isfield(tmfc.subjects,'FIR') 
        try, waitbar(5/8,w,'Updating FIR GLMs...'); end
        for iSub = 1:nSub
            if exist(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'GLM_batch.mat'),'file')
                tmfc.subjects(iSub).FIR = 1;
            else
                tmfc.subjects(iSub).FIR = 0;
            end
        end
        track_FIR = 0;
        for iSub = 1:nSub
            if tmfc.subjects(iSub).FIR == 0
                track_FIR = iSub;
                break;
            end
        end   
        if track_FIR == 0
            set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
        elseif track_FIR == 1
            set(main_GUI.TMFC_GUI_S8,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
        else
            set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(track_FIR-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
        end
    end
    
    %----------------------------------------------------------------------
    % Update BGFC 
    if isfield(tmfc,'subjects') && isfield(tmfc,'ROI_set') && isfield(tmfc.subjects,'FIR')
        
        try, waitbar(6/8,w,'Updating BGFC...'); end
        
        for iSub = 1:nSub
            SPM = load(tmfc.subjects(iSub).path).SPM;
            check_BGFC = zeros(1,length(SPM.Sess));
            for jSess = 1:length(SPM.Sess)
                file_new = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC','ROI_to_ROI', ...
                    [tmfc.subjects(iSub).name '_Run_' num2str(jSess) '.mat']);

                file_old = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC','ROI_to_ROI', ...
                    [tmfc.subjects(iSub).name '_Session_' num2str(jSess) '.mat']);

                if exist(file_new,'file') || exist(file_old,'file')
                    check_BGFC(jSess) = 1;
                end
            end

            % In repeated mode, also require the across-run average
            if strcmp(tmfc.session_mode,'repeated')
                file_all_runs = fullfile(tmfc.project_path,'ROI_sets', ...
                    tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC','ROI_to_ROI', ...
                    [tmfc.subjects(iSub).name '_All_Runs.mat']);

                all_runs_done = exist(file_all_runs,'file') == 2;
            else
                all_runs_done = true;
            end

            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BGFC = double(~any(check_BGFC == 0) && all_runs_done);
        end
        clear SPM
    end
    
    %----------------------------------------------------------------------
    % Update LSS after FIR
    if isfield(tmfc,'subjects') && isfield(tmfc,'LSS_after_FIR')

        % If conditions are missing or empty -> treat as "not computed"
        if ~isfield(tmfc.LSS_after_FIR,'conditions') || isempty(tmfc.LSS_after_FIR.conditions)
            set(main_GUI.TMFC_GUI_S10,'String','Not done','ForegroundColor',[0.773, 0.353, 0.067]);
        else
            try
                cond_list = tmfc.LSS_after_FIR.conditions;
                nCond = numel(cond_list);
          
                try, waitbar(7/8,w,'Updating LSS after FIR GLMs...'); end

                LSS_after_FIR_done = ones(1,nSub);

                for iSub = 1:nSub
                    SPM = load(tmfc.subjects(iSub).path).SPM;

                    if strcmp(tmfc.session_mode,'repeated')
                        sess_num = 1:length(SPM.Sess);
                    else
                        sess_num = unique([cond_list.sess]);
                    end

                    nSess = length(sess_num);

                    for jSess = 1:nSess 
                        % Trials of interest
                        nTrial = 0; trial.cond = []; trial.number = [];
                        for kCond = 1:nCond
                            if strcmp(tmfc.session_mode,'repeated') || cond_list(kCond).sess == sess_num(jSess)
                                nTrial = nTrial + length(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons);
                                trial.cond = [trial.cond; repmat(cond_list(kCond).number,length(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons),1)];
                                trial.number = [trial.number; (1:length(SPM.Sess(sess_num(jSess)).U(cond_list(kCond).number).ons))'];
                            end
                        end
                        % Check individual trial GLMs
                        condition = struct();
                        for kTrial = 1:nTrial
                            file_new = fullfile(tmfc.project_path,'LSS_regression_after_FIR',tmfc.subjects(iSub).name,'GLM_batches', ...
                                ['GLM_[Run_' num2str(sess_num(jSess)) ']_[Cond_' num2str(trial.cond(kTrial)) ']_[' ...
                                regexprep(char(SPM.Sess(sess_num(jSess)).U(trial.cond(kTrial)).name(1)),' ','_') ...
                                ']_[Trial_' num2str(trial.number(kTrial)) '].mat']);

                            file_old = fullfile(tmfc.project_path,'LSS_regression_after_FIR',tmfc.subjects(iSub).name,'GLM_batches', ...
                                ['GLM_[Sess_' num2str(sess_num(jSess)) ']_[Cond_' num2str(trial.cond(kTrial)) ']_[' ...
                                regexprep(char(SPM.Sess(sess_num(jSess)).U(trial.cond(kTrial)).name(1)),' ','_') ...
                                ']_[Trial_' num2str(trial.number(kTrial)) '].mat']);

                            if exist(file_new,'file') || exist(file_old,'file')
                                condition(trial.cond(kTrial)).trials(trial.number(kTrial)) = 1;
                            else
                                condition(trial.cond(kTrial)).trials(trial.number(kTrial)) = 0;
                                LSS_after_FIR_done(iSub) = 0;
                            end
                        end
                        tmfc.subjects(iSub).LSS_after_FIR.session(sess_num(jSess)).condition = condition;
                        clear condition
                    end
                    clear SPM trial nTrial
                end

                % Progress across subjects
                track_LSS_after_FIR = find(LSS_after_FIR_done == 0,1,'first');

                if isempty(track_LSS_after_FIR)
                    track_LSS_after_FIR = 0;
                end

                % GUI
                if track_LSS_after_FIR == 0
                    set(main_GUI.TMFC_GUI_S10,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
                elseif track_LSS_after_FIR == 1
                    set(main_GUI.TMFC_GUI_S10,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
                else
                    set(main_GUI.TMFC_GUI_S10,'String', strcat(num2str(track_LSS_after_FIR-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
                end
            catch
                if exist('iSub','var')
                    fprintf(2,'Problem with subject %d: %s\n',iSub,tmfc.subjects(iSub).path);
                end
                warning('LSS after FIR progress not updated. Check LSS after FIR conditions.')
            end
        end
    end
    
    %----------------------------------------------------------------------
    % Update BSC after FIR
    if isfield(tmfc,'subjects') && isfield(tmfc,'ROI_set') && isfield(tmfc,'LSS_after_FIR')
        try, waitbar(8/8,w,'Updating BSC after FIR...'); end
        for iSub = 1:nSub
            beta_series_file = fullfile(tmfc.project_path,'ROI_sets', ...
                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR', ...
                'Beta_series',[tmfc.subjects(iSub).name '_beta_series.mat']);

            BSC_after_FIR_done = exist(beta_series_file,'file') == 2;

            % In repeated mode, require repeated-run beta-series format
            if BSC_after_FIR_done && strcmp(tmfc.session_mode,'repeated')
                try
                    tmp = load(beta_series_file,'beta_series');
                    BSC_after_FIR_done = isfield(tmp,'beta_series') && ~isempty(tmp.beta_series) && isfield(tmp.beta_series,'run');
                catch
                    BSC_after_FIR_done = false;
                end
            end

            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).BSC_after_FIR = double(BSC_after_FIR_done);
        end
    end

    try, delete(w); catch, end
    
    %----------------------------------------------------------------------
    % Update settings
    switch tmfc.defaults.parallel
        case 1
            set_computing = {'Parallel computing','Sequential computing'};           
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
end

%% ========================[ Check ROI masks ]=============================
function ROI_check = check_ROI_masks(tmfc,ROI_set_number)
    ROI_check = 1;
    for iROI = 1:length(tmfc.ROI_set(ROI_set_number).ROIs)
        if ~isfield(tmfc.ROI_set(ROI_set_number).ROIs(iROI),'path_masked') || isempty(tmfc.ROI_set(ROI_set_number).ROIs(iROI).path_masked)
            ROI_check = 0;
            return;
        end
        path_masked = tmfc.ROI_set(ROI_set_number).ROIs(iROI).path_masked;

        % Backward compatibility with old ROI sets
        if ischar(path_masked)
            if ~exist(path_masked,'file')
                ROI_check = 0;
                return;
            end
        else
            for jSub = 1:length(tmfc.subjects)
                if length(path_masked) < jSub || ~isfield(path_masked(jSub),'subjects') || isempty(path_masked(jSub).subjects) || ~exist(path_masked(jSub).subjects,'file')
                    ROI_check = 0;
                    return;
                end
            end
        end
    end
end

%% =================[ Check incomplete ROI extension ]=====================
function extension_needed = check_ROI_extension(tmfc)

    extension_needed = false;

    if ~isfield(tmfc,'ROI_set') || isempty(tmfc.ROI_set) || ~isfield(tmfc,'subjects') || isempty(tmfc.subjects)
        return;
    end

    nSub = length(tmfc.subjects);

    for iSet = 1:length(tmfc.ROI_set)
        for iROI = 1:length(tmfc.ROI_set(iSet).ROIs)

            if ~isfield(tmfc.ROI_set(iSet).ROIs(iROI),'path_masked')
                continue;
            end

            path_masked = tmfc.ROI_set(iSet).ROIs(iROI).path_masked;

            % Old ROI sets with one common mask are not incomplete
            if ~isstruct(path_masked)
                continue;
            end

            % Subject was added but ROI extension was not completed
            if length(path_masked) < nSub
                extension_needed = true;
                return;
            end

            for jSub = 1:nSub
                if ~isfield(path_masked(jSub),'subjects') || isempty(path_masked(jSub).subjects)
                    extension_needed = true;
                    return;
                end
            end
        end
    end
end

%% ====================[ Subject naming format GUI ]=======================
function [sub_names] = tmfc_subject_naming_GUI

    sub_names = 'original';
    
    MW_str = {'Subject subfolders within TMFC project can use the original subject names or can be named in a standard "TMFC" way (Subject_XXXX).'};
    
    sub_names_options = {'Original subject naming format','TMFC subject naming format'};
    
    SN_GUI_MW = figure('Name','Subject names','NumberTitle','off','Units','normalized', ...
        'Position',[0.35 0.42 0.3 0.2],'Resize','on','MenuBar','none','ToolBar','none', ...
        'Tag','tmfc_sub_naming_GUI','color','w','WindowStyle','modal','CloseRequestFcn',@exit_MW); 

    movegui(SN_GUI_MW,'center');

    if isunix; fontscale = 0.9; else; fontscale = 1; end

    SN_txt = uicontrol(SN_GUI_MW,'Style','text','String',MW_str,'Units','normalized','Position',[0.03 0.57 0.95 0.23],'fontunits','normalized','fontSize',0.32*fontscale,'BackgroundColor','w'); 
    SN_pop = uicontrol(SN_GUI_MW,'Style','popupmenu','String',sub_names_options,'Units','normalized','Position',[0.26 0.28 0.5 0.23],'fontunits','normalized','FontSize',0.32);     
    
    SN_MW_OK = uicontrol(SN_GUI_MW,'Style','pushbutton','String','OK','Units','normalized', ...
        'Position',[0.41 0.09 0.2 0.15],'fontunits','normalized','FontSize',0.40,'callback',@read_data);
          
    % Read & Sync Data
    function read_data(~,~)       
       temp_sub_names = get(SN_pop,'value'); 
       if temp_sub_names == 2
           sub_names = 'standard';
       end      
       uiresume(SN_GUI_MW);
    end
    
    % Exit
    function exit_MW(~,~)
        sub_names = 'original';
        disp('Original subject naming format will be used.');
        uiresume(SN_GUI_MW);
    end
    
    uiwait(SN_GUI_MW);
    delete(SN_GUI_MW);
end

%% ========================[ PPI centering GUI ]===========================
function centering = PPI_centering_GUI

    centering = 'with_mean_centering';
    
    MW_str_1 = {'Apply mean centering of the psychological regressor prior to the deconvolution and PPI term calculation (Di, Reynolds and Biswal, 2017; Masharipov et al., 2024)'};
    
    MW_str_2 = { ...
        ['Note: The same whitening transform is applied to the seed signal and deconvolution matrix.' sprintf('\n') ...
         'In subsequent gPPI model estimation, PHYS is derived from unwhitened and unfiltered' sprintf('\n') ...
         'BOLD data adjusted for regressors of no interest, avoiding double whitening (Masharipov & Kireev, 2026).']};
    
    set_centering = {'Enable mean centering', 'Disable mean centering'};
    
    PPI_GUI_MW = figure('Name', 'Psychophysiological interaction', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.28 0.42 0.44 0.30],'Resize','on','MenuBar', 'none', 'ToolBar', 'none','Tag','tmfc_PPI_term_GUI', 'color', 'w','WindowStyle','modal','CloseRequestFcn', @exit_MW); 
    
    if isunix; fontscale = 0.95; else; fontscale = 1; end

    PPI_centering_txt = uicontrol(PPI_GUI_MW,'Style','text','String', MW_str_1,'Units', 'normalized', 'Position',[0.022 0.76 0.93 0.15],'fontunits','normalized', 'fontSize', 0.35*fontscale,'BackgroundColor','w'); 
    PPI_centering_pop = uicontrol(PPI_GUI_MW , 'Style', 'popupmenu', 'String', set_centering,'Units', 'normalized', 'Position',[0.35 0.60 0.32 0.15],'fontunits','normalized', 'fontSize', 0.36);     
    
    PPI_whitening_txt = uicontrol(PPI_GUI_MW,'Style','text','String', MW_str_2,'Units', 'normalized', 'Position',[0.02 0.34 0.95 0.24],'fontunits','normalized', 'fontSize', 0.22*fontscale,'BackgroundColor','w'); 

    PPI_MW_OK = uicontrol(PPI_GUI_MW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.41 0.09 0.2 0.12],'fontunits','normalized', 'fontSize', 0.40,'callback', @read_data);
          
    % Read & Sync Data
    function read_data(~,~)
       
       temp_center = get(PPI_centering_pop, 'value'); 
       if temp_center == 2
           centering = 'no_mean_centering';
       end      
       
       uiresume(PPI_GUI_MW);
    end
    
    % Exit
    function exit_MW(~,~)
        centering = '';
        uiresume(PPI_GUI_MW);
    end
    
    uiwait(PPI_GUI_MW);
    delete(PPI_GUI_MW);
end

%% =======================[ BSC extraction GUI ]===========================
function [summary,perform_beta_scrubbing] = BSC_extraction_GUI(previous_summary,previous_scrubbing)

    if nargin < 1 || isempty(previous_summary)
        previous_summary = 'mean';
    end
    if nargin < 2 || isempty(previous_scrubbing)
        previous_scrubbing = 1;
    end

    summary = previous_summary;
    perform_beta_scrubbing = previous_scrubbing;

    extraction_value = 1;
    if strcmp(previous_summary,'first_eigenvariate')
        extraction_value = 2;
    end
    scrubbing_value = 1;
    if previous_scrubbing == 1
        scrubbing_value = 2;
    end
    
    BSC_GUI_MW = figure('Name', 'Beta series correlation', 'NumberTitle', 'off', ...
        'Units', 'normalized', 'Position', [0.38 0.40 0.28 0.24], 'Resize', 'on', ...
        'MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'tmfc_BSC_extraction_GUI', ...
        'color', 'w', 'WindowStyle', 'modal', 'CloseRequestFcn', @exit_MW); 
    
    MW_txt_1 = uicontrol(BSC_GUI_MW,'Style','text', ...
        'String', 'Select averaging to extract beta series from ROIs:', ...
        'Units', 'normalized', 'Position',[0.04 0.76 0.95 0.12], ...
        'fontunits','normalized', 'fontSize', 0.50, 'BackgroundColor','w'); 
    
    MW_E1 = uicontrol(BSC_GUI_MW , 'Style', 'popupmenu', ...
        'String', {'Mean', 'First eigenvariate'}, 'Value', extraction_value, ...
        'Units', 'normalized', 'Position',[0.29 0.58 0.45 0.16], ...
        'fontunits','normalized', 'fontSize', 0.40);     
    
    MW_txt_2 = uicontrol(BSC_GUI_MW,'Style','text', ...
        'String', 'Perform beta scrubbing:', ...
        'Units', 'normalized', 'Position',[0.04 0.38 0.95 0.12], ...
        'fontunits','normalized', 'fontSize', 0.50, 'BackgroundColor','w'); 
    
    MW_E2 = uicontrol(BSC_GUI_MW , 'Style', 'popupmenu', ...
        'String', {'No', 'Yes'}, 'Value', scrubbing_value, ...
        'Units', 'normalized', 'Position',[0.38 0.22 0.27 0.16], ...
        'fontunits','normalized', 'fontSize', 0.40);     
    
    MW_OK = uicontrol(BSC_GUI_MW,'Style','pushbutton','String', 'OK', ...
        'Units', 'normalized','Position',[0.39 0.05 0.25 0.12], ...
        'fontunits','normalized', 'fontSize', 0.40,'callback', @read_data);
    
    movegui(BSC_GUI_MW,'center');
    
    % Read & sync data
    function read_data(~,~)
        temp_var = get(MW_E1, 'value'); 
        if temp_var == 2
            summary = 'first_eigenvariate';
        else
            summary = 'mean';
        end
        
        temp_scrub = get(MW_E2, 'value');
        if temp_scrub == 2
            perform_beta_scrubbing = 1;
        else
            perform_beta_scrubbing = 0;
        end
        
        uiresume(BSC_GUI_MW);
    end

    % Cancel operation
    function exit_MW(~,~)
        summary = '';
        perform_beta_scrubbing = [];
        uiresume(BSC_GUI_MW);
    end
    
    uiwait(BSC_GUI_MW);
    delete(BSC_GUI_MW);
end

%% =================[ Freeze/unfreeze main TMFC GUI ]======================
function freeze_GUI(state)

	switch(state)
        case 0 
            state = 'on';
        case 1
            state = 'off';
    end
    set([main_GUI.TMFC_GUI_B1, main_GUI.TMFC_GUI_B2, main_GUI.TMFC_GUI_B3, main_GUI.TMFC_GUI_B4,...
                main_GUI.TMFC_GUI_B5a, main_GUI.TMFC_GUI_B5b, main_GUI.TMFC_GUI_B6, main_GUI.TMFC_GUI_B7,...
                main_GUI.TMFC_GUI_B8, main_GUI.TMFC_GUI_B9, main_GUI.TMFC_GUI_B10, main_GUI.TMFC_GUI_B11,...
                main_GUI.TMFC_GUI_B12a,main_GUI.TMFC_GUI_B12b,main_GUI.TMFC_GUI_B13a,main_GUI.TMFC_GUI_B13b,...
                main_GUI.TMFC_GUI_B14a,main_GUI.TMFC_GUI_B14b], 'Enable', state);

end      

%% ==============[ Reset main TMFC GUI & TMFC structure ]==================
function [tmfc] = major_reset(tmfc)

    try 
        tmfc = rmfield(tmfc,'subjects');
    end

    try
        tmfc = rmfield(tmfc,'subject_naming');
    end

    try
        tmfc = rmfield(tmfc,'next_subject');
    end

    try
        tmfc = rmfield(tmfc,'session_mode');
    end

    try 
        tmfc = rmfield(tmfc,'project_path');
    end

    try 
        tmfc = rmfield(tmfc,'ROI_set');
    end

    try
        tmfc = rmfield(tmfc,'ROI_set_legacy');
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

    try
        tmfc = rmfield(tmfc,'FD_options');
    end

    set([main_GUI.TMFC_GUI_S1,main_GUI.TMFC_GUI_S2], 'String', 'Not selected','ForegroundColor',[1, 0, 0]);
    set([main_GUI.TMFC_GUI_S3,main_GUI.TMFC_GUI_S4,main_GUI.TMFC_GUI_S6,main_GUI.TMFC_GUI_S8,main_GUI.TMFC_GUI_S10], 'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
end

%% ===========[ Update VOI, PPI, gPPI and gPPI_FIR progress ]==============
function [tmfc] = update_gPPI(tmfc)
           
    if ~isfield(tmfc,'ROI_set_number')
        tmfc.ROI_set_number = 1;
    end

    if isempty(findall(0,'type','figure','name','Updating TMFC project'))
        w2 = waitbar(0,'Please wait...','Name','Updating TMFC project');
    end

    nSub  = length(tmfc.subjects);
    nROI  = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);

    ROI_set = tmfc.ROI_set(tmfc.ROI_set_number);

    has_gPPI_conditions = ...
        isfield(ROI_set,'gPPI') && ...
        isstruct(ROI_set.gPPI) && ...
        ~isempty(ROI_set.gPPI) && ...
        isfield(ROI_set.gPPI,'conditions') && ...
        ~isempty(ROI_set.gPPI.conditions);

    if ~has_gPPI_conditions
        set(main_GUI.TMFC_GUI_S3, ...
            'String','Not done', ...
            'ForegroundColor',[0.773, 0.353, 0.067]);
        set(main_GUI.TMFC_GUI_S4, ...
            'String','Not done', ...
            'ForegroundColor',[0.773, 0.353, 0.067]);
        try, delete(w2); catch, end
        return;
    end

    cond_list = ROI_set.gPPI.conditions;
    nCond = length(cond_list);

    % ------------------------[Update VOI progress]----------------------------
    try
        waitbar(1/4,w2,'Updating VOI progress...');
    end

    % Update TMFC structure
    try
        for iSub = 1:nSub
            SPM = load(tmfc.subjects(iSub).path).SPM;

            if strcmp(tmfc.session_mode,'repeated')
                sess_num = 1:length(SPM.Sess);
            else
                sess_num = unique([cond_list.sess]);
            end

            nSess = length(sess_num);
            check_VOI = zeros(nROI,nSess);

            for jROI = 1:nROI
                for kSess = 1:nSess
                    if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs',tmfc.subjects(iSub).name, ...
                            ['VOI_' tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name '_' num2str(sess_num(kSess)) '.mat']), 'file')
                        check_VOI(jROI,kSess) = 1;
                    end
                end
            end
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI = double(~any(check_VOI(:) == 0));
        end
        clear SPM sess_num
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
            set(main_GUI.TMFC_GUI_S3, 'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);       
        elseif track_VOI == 1
            set(main_GUI.TMFC_GUI_S3, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
        else
            set(main_GUI.TMFC_GUI_S3, 'String', strcat(num2str(track_VOI-1), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);       
        end
    end

    % ------------------------[Update PPI progress]----------------------------
    try
        waitbar(2/4,w2,'Updating PPI progress...');
    end

    % Update TMFC structure
    try
        for iSub = 1:nSub
            % Repeated runs
            if strcmp(tmfc.session_mode,'repeated')
                SPM = load(tmfc.subjects(iSub).path).SPM;
                sess_num = 1:length(SPM.Sess);

                check_PPI = zeros(nROI,length(sess_num),nCond);

                for jROI = 1:nROI
                    for kSess = 1:length(sess_num)
                        s = sess_num(kSess);

                        for kCond = 1:nCond

                            cond = cond_list(kCond).number;

                            if isfield(cond_list,'pmod') && ~isempty(cond_list(kCond).pmod)
                                pmod = cond_list(kCond).pmod;
                            else
                                pmod = 1;
                            end

                            if isfield(cond_list,'bf') && ~isempty(cond_list(kCond).bf)
                                bf = cond_list(kCond).bf;
                            else
                                bf = 1;
                            end

                            cond_name = char(SPM.Sess(s).U(cond).name(pmod));

                            file_name = ...
                                ['[Run_' num2str(s) ']_[Cond_' num2str(cond) ']_[' ...
                                regexprep(cond_name,' ','_') ']'];

                            if bf == 2
                                file_name = [file_name '_[TimeDeriv]'];
                            elseif bf == 3
                                file_name = [file_name '_[DispDeriv]'];
                            end

                            if exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                    tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs', ...
                                    tmfc.subjects(iSub).name, ...
                                    ['PPI_[' regexprep(tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name,' ','_') ']_' ...
                                    file_name '.mat']),'file')

                                check_PPI(jROI,kSess,kCond) = 1;
                            end
                        end
                    end
                end

            % Strict mode
            else
                check_PPI = zeros(nROI,nCond);
                for jROI = 1:nROI
                    for kCond = 1:nCond
                        file_name = strrep(cond_list(kCond).file_name,'[Sess_','[Run_');

                        file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs', ...
                            tmfc.subjects(iSub).name, ...
                            ['PPI_[' regexprep(tmfc.ROI_set(tmfc.ROI_set_number).ROIs(jROI).name,' ','_') ']_' ...
                            file_name '.mat']);

                        % Backward compatibility
                        file_old = strrep(file_new,'[Run_','[Sess_');

                        if exist(file_new,'file') || exist(file_old,'file')
                            check_PPI(jROI,kCond) = 1;
                        end
                    end
                end
            end
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = double(~any(check_PPI(:) == 0));
        end
        clear SPM sess_num
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
            set(main_GUI.TMFC_GUI_S4, 'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);       
        elseif track_PPI == 1
            set(main_GUI.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
        else
            set(main_GUI.TMFC_GUI_S4, 'String', strcat(num2str(track_PPI-1), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);       
        end
    end

    % ------------------------[Update gPPI progress]---------------------------
    try
        waitbar(3/4,w2,'Updating gPPI progress...');
    end

    % Update TMFC structure
    try
        for iSub = 1:nSub
            check_gPPI = ones(1,nCond);
            
            % Repeated runs
            if strcmp(tmfc.session_mode,'repeated')
                SPM = load(tmfc.subjects(iSub).path).SPM;
                sess_num = 1:length(SPM.Sess);

                for jCond = 1:nCond

                    if isfield(cond_list,'bf') && ~isempty(cond_list(jCond).bf)
                        bf = cond_list(jCond).bf;
                    else
                        bf = 1;
                    end

                    % Check run-specific files
                    for kSess = 1:length(sess_num)

                        file_name = ...
                            ['[Run_' num2str(sess_num(kSess)) ']_[Cond_' ...
                            num2str(cond_list(jCond).number) ']_[' ...
                            regexprep(cond_list(jCond).name,' ','_') ']'];

                        if bf == 2
                            file_name = [file_name '_[TimeDeriv]'];
                        elseif bf == 3
                            file_name = [file_name '_[DispDeriv]'];
                        end

                        % Check ROI-to-ROI files
                        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                            if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                    tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                                    'ROI_to_ROI','symmetrical', ...
                                    [tmfc.subjects(iSub).name '_Contrast_' ...
                                    num2str(jCond,'%04.f') '_' file_name '.mat']),'file')
                                check_gPPI(jCond) = 0;
                            end
                        end

                        % Check seed-to-voxel files (last ROI only)
                        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                            if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                    tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                                    'Seed_to_voxel', ...
                                    tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' ...
                                    num2str(jCond,'%04.f') '_' file_name '.nii']),'file')
                                check_gPPI(jCond) = 0;
                            end
                        end
                    end

                    % Check across-run files
                    file_name = ...
                        ['[All_Runs]_[Cond_' num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];

                    if bf == 2
                        file_name = [file_name '_[TimeDeriv]'];
                    elseif bf == 3
                        file_name = [file_name '_[DispDeriv]'];
                    end

                    % Check ROI-to-ROI files
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                        if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                                'ROI_to_ROI','symmetrical', ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.mat']),'file')
                            check_gPPI(jCond) = 0;
                        end
                    end

                    % Check seed-to-voxel files (last ROI only)
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                        if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                                'Seed_to_voxel', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.nii']),'file')
                            check_gPPI(jCond) = 0;
                        end
                    end
                end

                % Strict mode
            else
                for jCond = 1:nCond

                    file_name = strrep(cond_list(jCond).file_name,'[Sess_','[Run_');

                    % Check ROI-to-ROI files
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2

                        file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                            'ROI_to_ROI','symmetrical', ...
                            [tmfc.subjects(iSub).name '_Contrast_' ...
                            num2str(jCond,'%04.f') '_' file_name '.mat']);

                        % Backward compatibility
                        file_old = strrep(file_new,'[Run_','[Sess_');

                        if ~exist(file_new,'file') && ~exist(file_old,'file')
                            check_gPPI(jCond) = 0;
                        end
                    end

                    % Check seed-to-voxel files (last ROI only)
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3

                        file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI', ...
                            'Seed_to_voxel', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                            [tmfc.subjects(iSub).name '_Contrast_' ...
                            num2str(jCond,'%04.f') '_' file_name '.nii']);

                        % Backward compatibility
                        file_old = strrep(file_new,'[Run_','[Sess_');

                        if ~exist(file_new,'file') && ~exist(file_old,'file')
                            check_gPPI(jCond) = 0;
                        end
                    end
                end
            end

            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI = double(~any(check_gPPI(:) == 0));
        end
    end

    % -----------------------[Update gPPI-FIR progress]------------------------
    try
        waitbar(4/4,w2,'Updating gPPI-FIR progress...');
    end

    % Update TMFC structure
    try
        for iSub = 1:nSub
            check_gPPI_FIR = ones(1,nCond);
            
            % Repeated runs
            if strcmp(tmfc.session_mode,'repeated')
                SPM = load(tmfc.subjects(iSub).path).SPM;
                sess_num = 1:length(SPM.Sess);

                for jCond = 1:nCond

                    if isfield(cond_list,'bf') && ~isempty(cond_list(jCond).bf)
                        bf = cond_list(jCond).bf;
                    else
                        bf = 1;
                    end

                    % Check run-specific files
                    for kSess = 1:length(sess_num)

                        file_name = ...
                            ['[Run_' num2str(sess_num(kSess)) ']_[Cond_' ...
                            num2str(cond_list(jCond).number) ']_[' ...
                            regexprep(cond_list(jCond).name,' ','_') ']'];

                        if bf == 2
                            file_name = [file_name '_[TimeDeriv]'];
                        elseif bf == 3
                            file_name = [file_name '_[DispDeriv]'];
                        end

                        % Check ROI-to-ROI files
                        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                            if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                    tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                                    'ROI_to_ROI','symmetrical', ...
                                    [tmfc.subjects(iSub).name '_Contrast_' ...
                                    num2str(jCond,'%04.f') '_' file_name '.mat']),'file')
                                check_gPPI_FIR(jCond) = 0;
                            end
                        end

                        % Check seed-to-voxel files (last ROI only)
                        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                            if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                    tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                                    'Seed_to_voxel', ...
                                    tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' ...
                                    num2str(jCond,'%04.f') '_' file_name '.nii']),'file')
                                check_gPPI_FIR(jCond) = 0;
                            end
                        end
                    end

                    % Check across-run files
                    file_name = ...
                        ['[All_Runs]_[Cond_' num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];

                    if bf == 2
                        file_name = [file_name '_[TimeDeriv]'];
                    elseif bf == 3
                        file_name = [file_name '_[DispDeriv]'];
                    end

                    % Check ROI-to-ROI files
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
                        if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                                'ROI_to_ROI','symmetrical', ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.mat']),'file')
                            check_gPPI_FIR(jCond) = 0;
                        end
                    end

                    % Check seed-to-voxel files (last ROI only)
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
                        if ~exist(fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                                'Seed_to_voxel', ...
                                tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.nii']),'file')
                            check_gPPI_FIR(jCond) = 0;
                        end
                    end
                end

                % Strict mode
            else
                for jCond = 1:nCond

                    file_name = strrep(cond_list(jCond).file_name,'[Sess_','[Run_');

                    % Check ROI-to-ROI files
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2

                        file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                            'ROI_to_ROI','symmetrical', ...
                            [tmfc.subjects(iSub).name '_Contrast_' ...
                            num2str(jCond,'%04.f') '_' file_name '.mat']);

                        % Backward compatibility
                        file_old = strrep(file_new,'[Run_','[Sess_');

                        if ~exist(file_new,'file') && ~exist(file_old,'file')
                            check_gPPI_FIR(jCond) = 0;
                        end
                    end

                    % Check seed-to-voxel files (last ROI only)
                    if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3

                        file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR', ...
                            'Seed_to_voxel', ...
                            tmfc.ROI_set(tmfc.ROI_set_number).ROIs(nROI).name, ...
                            [tmfc.subjects(iSub).name '_Contrast_' ...
                            num2str(jCond,'%04.f') '_' file_name '.nii']);

                        % Backward compatibility
                        file_old = strrep(file_new,'[Run_','[Sess_');

                        if ~exist(file_new,'file') && ~exist(file_old,'file')
                            check_gPPI_FIR(jCond) = 0;
                        end
                    end
                end
            end

            tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = double(~any(check_gPPI_FIR(:) == 0));
        end
    end
    
    try
        close(w2);
    end
end

%% ====[ Reset VOI, PPI, gPPI, gPPI-FIR progress and delete old files ]====
function [tmfc] = reset_gPPI(tmfc)

    disp('Deleting old files...');

    % Reset progress    
    for iSub = 1:length(tmfc.subjects)
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).VOI = 0;
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).PPI = 0;
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI = 0;
        tmfc.ROI_set(tmfc.ROI_set_number).subjects(iSub).gPPI_FIR = 0;
    end
    set(main_GUI.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);

    % Delete old VOI files
    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs'),'s'); 

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
    
    % Clear mean centering 
    tmfc.ROI_set(tmfc.ROI_set_number).PPI_centering = [];

    % Clear contrasts
    if ~isfield(tmfc.ROI_set(tmfc.ROI_set_number),'contrasts') || ~isstruct(tmfc.ROI_set(tmfc.ROI_set_number).contrasts) || isempty(tmfc.ROI_set(tmfc.ROI_set_number).contrasts)
        tmfc.ROI_set(tmfc.ROI_set_number).contrasts = struct;
    else
        if isfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'gPPI')
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts = rmfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'gPPI');
        end
        if isfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'gPPI_FIR')
            tmfc.ROI_set(tmfc.ROI_set_number).contrasts = rmfield(tmfc.ROI_set(tmfc.ROI_set_number).contrasts,'gPPI_FIR');
        end
    end
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI.title = [];
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI.weights = [];
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR.title = [];
    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR.weights = [];
end

%% ==========[ Reset LSS and BSC progress and delete old files ]===========
function [tmfc] = reset_LSS(tmfc)

    disp('Deleting old files...');

    % Reset LSS progress
    if isfield(tmfc,'LSS')
        tmfc = rmfield(tmfc,'LSS');
    end

    if isfield(tmfc.subjects,'LSS')
        tmfc.subjects = rmfield(tmfc.subjects,'LSS');
    end

    % Delete old LSS files
    if isdir(fullfile(tmfc.project_path,'LSS_regression'))
        rmdir(fullfile(tmfc.project_path,'LSS_regression'),'s');
    end

    % Reset BSC
    if isfield(tmfc,'ROI_set') && ~isempty(tmfc.ROI_set)
        for iSet = 1:length(tmfc.ROI_set)
            % Reset BSC progress
            if isfield(tmfc.ROI_set(iSet),'subjects')
                for iSub = 1:length(tmfc.ROI_set(iSet).subjects)
                    tmfc.ROI_set(iSet).subjects(iSub).BSC = 0;
                end
            end

            % Delete old BSC files
            if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(iSet).set_name,'BSC_LSS'))
                rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(iSet).set_name,'BSC_LSS'),'s');
            end

            % Clear BSC averaging
            tmfc.ROI_set(iSet).BSC = [];

            % Clear BSC contrasts
            if ~isfield(tmfc.ROI_set(iSet),'contrasts') || ~isstruct(tmfc.ROI_set(iSet).contrasts) || isempty(tmfc.ROI_set(iSet).contrasts)
                tmfc.ROI_set(iSet).contrasts = struct;
            elseif isfield(tmfc.ROI_set(iSet).contrasts,'BSC')
                tmfc.ROI_set(iSet).contrasts = rmfield(tmfc.ROI_set(iSet).contrasts,'BSC');
            end

            tmfc.ROI_set(iSet).contrasts.BSC.title = [];
            tmfc.ROI_set(iSet).contrasts.BSC.weights = [];
        end

        if isfield(tmfc.ROI_set,'BSC_beta_scrubbing')
            tmfc.ROI_set = rmfield(tmfc.ROI_set,'BSC_beta_scrubbing');
        end
    end
end

%% ====[ Reset LSS and BSC (after FIR) progress and delete old files ]=====
function [tmfc] = reset_LSS_after_FIR(tmfc)

    disp('Deleting old files...');

    % Reset LSS after FIR progress
    if isfield(tmfc,'LSS_after_FIR')
        tmfc = rmfield(tmfc,'LSS_after_FIR');
    end

    if isfield(tmfc.subjects,'LSS_after_FIR')
        tmfc.subjects = rmfield(tmfc.subjects,'LSS_after_FIR');
    end

    % Delete old LSS after FIR files
    if isdir(fullfile(tmfc.project_path,'LSS_regression_after_FIR'))
        rmdir(fullfile(tmfc.project_path,'LSS_regression_after_FIR'),'s');
    end

    % Reset BSC after FIR
    if isfield(tmfc,'ROI_set') && ~isempty(tmfc.ROI_set)
        for iSet = 1:length(tmfc.ROI_set)

            % Reset BSC after FIR progress
            if isfield(tmfc.ROI_set(iSet),'subjects')
                for iSub = 1:length(tmfc.ROI_set(iSet).subjects)
                    tmfc.ROI_set(iSet).subjects(iSub).BSC_after_FIR = 0;
                end
            end

            % Delete old BSC after FIR files
            if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(iSet).set_name,'BSC_LSS_after_FIR'))
                rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(iSet).set_name,'BSC_LSS_after_FIR'),'s');
            end

            % Clear BSC after FIR averaging
            tmfc.ROI_set(iSet).BSC_after_FIR = [];

            % Clear BSC after FIR contrasts
            if ~isfield(tmfc.ROI_set(iSet),'contrasts') || ~isstruct(tmfc.ROI_set(iSet).contrasts) || isempty(tmfc.ROI_set(iSet).contrasts)
                tmfc.ROI_set(iSet).contrasts = struct;
            elseif isfield(tmfc.ROI_set(iSet).contrasts,'BSC_after_FIR')
                tmfc.ROI_set(iSet).contrasts = rmfield(tmfc.ROI_set(iSet).contrasts,'BSC_after_FIR');
            end

            tmfc.ROI_set(iSet).contrasts.BSC_after_FIR.title = [];
            tmfc.ROI_set(iSet).contrasts.BSC_after_FIR.weights = [];
        end
        
        if isfield(tmfc.ROI_set,'BSC_after_FIR_beta_scrubbing')
            tmfc.ROI_set = rmfield(tmfc.ROI_set,'BSC_after_FIR_beta_scrubbing');
        end
    end
end

%% ==[ Reset FIR, BGFC, BSC/LSS after FIR progress and delete old files ]==
function [tmfc] = reset_FIR(tmfc)
    
    disp('Deleting old files...');

    % Reset FIR progress
    if isfield(tmfc.subjects,'FIR')
        for iSub = 1:length(tmfc.subjects)
            tmfc.subjects(iSub).FIR = 0;
        end
    end

    % Delete old FIR 
    if isdir(fullfile(tmfc.project_path,'FIR_regression'))
        rmdir(fullfile(tmfc.project_path,'FIR_regression'),'s');
    end  

    % Delete old LSS after FIR files
    if isdir(fullfile(tmfc.project_path,'LSS_regression_after_FIR'))
        rmdir(fullfile(tmfc.project_path,'LSS_regression_after_FIR'),'s');
    end
    
    % Reset LSS after FIR progress
    if isfield(tmfc,'LSS_after_FIR')
        tmfc = rmfield(tmfc,'LSS_after_FIR');
    end

    if isfield(tmfc.subjects,'LSS_after_FIR')
        tmfc.subjects = rmfield(tmfc.subjects,'LSS_after_FIR');
    end

    % Reset ROI-set-specific analyses
    if isfield(tmfc,'ROI_set') && ~isempty(tmfc.ROI_set)
        
        % Clear BSC after FIR beta-scrubbing settings
        if isfield(tmfc.ROI_set,'BSC_after_FIR_beta_scrubbing')
            tmfc.ROI_set = rmfield(tmfc.ROI_set,'BSC_after_FIR_beta_scrubbing');
        end

        for iSet = 1:length(tmfc.ROI_set)

            % Reset BGFC and BSC after FIR progress
            if isfield(tmfc.ROI_set(iSet),'subjects')
                for iSub = 1:length(tmfc.ROI_set(iSet).subjects)
                    tmfc.ROI_set(iSet).subjects(iSub).BGFC = 0;
                    tmfc.ROI_set(iSet).subjects(iSub).BSC_after_FIR = 0;
                end
            end

            % Delete old BGFC files
            if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(iSet).set_name,'BGFC'))
                rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(iSet).set_name,'BGFC'),'s');
            end

            % Delete old BSC after FIR files
            if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(iSet).set_name,'BSC_LSS_after_FIR'))
                rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(iSet).set_name,'BSC_LSS_after_FIR'),'s');
            end

            % Clear BSC after FIR settings
            tmfc.ROI_set(iSet).BSC_after_FIR = [];

            % Clear BSC after FIR contrasts
            if ~isfield(tmfc.ROI_set(iSet),'contrasts') || ~isstruct(tmfc.ROI_set(iSet).contrasts) || isempty(tmfc.ROI_set(iSet).contrasts)
                tmfc.ROI_set(iSet).contrasts = struct;
            elseif isfield(tmfc.ROI_set(iSet).contrasts,'BSC_after_FIR')
                tmfc.ROI_set(iSet).contrasts = rmfield(tmfc.ROI_set(iSet).contrasts,'BSC_after_FIR');
            end

            tmfc.ROI_set(iSet).contrasts.BSC_after_FIR.title = [];
            tmfc.ROI_set(iSet).contrasts.BSC_after_FIR.weights = [];
        end
    end
end

%% ========[ Calculate seed-to-voxel and/or ROI-to-ROI contrast]===========
function seed2vox_or_ROI2ROI(tmfc,contrast_number,analysis_type,start_sub)

    if nargin < 4 || isempty(start_sub)
        start_sub = 1;
    end

    switch(tmfc.defaults.analysis)

        case 1  % Seed-to-voxel and ROI-to-ROI analyses

            % ROI-to-ROI 
            sub_check_ROI2ROI = tmfc_ROI_to_ROI_contrast(tmfc,analysis_type,contrast_number,tmfc.ROI_set_number,start_sub);                           
            if sub_check_ROI2ROI(length(tmfc.subjects)) == 1
                fprintf('ROI-to-ROI contrast calculated: No %d.\n',contrast_number);
            else
                warning('ROI-to-ROI contrast failed.');
            end

            % Seed-to-voxel
            sub_check_seed2vox = tmfc_seed_to_voxel_contrast(tmfc,analysis_type,contrast_number,tmfc.ROI_set_number,start_sub);
            if sub_check_seed2vox(length(tmfc.subjects)) == 1
                fprintf('Seed-to-voxel contrast calculated: No %d.\n',contrast_number);
            else
                warning('Seed-to-voxel contrast failed.');
            end

        case 2  % ROI-to-ROI only

            sub_check_ROI2ROI = tmfc_ROI_to_ROI_contrast(tmfc,analysis_type,contrast_number,tmfc.ROI_set_number,start_sub);                           
            if sub_check_ROI2ROI(length(tmfc.subjects)) == 1
                fprintf('ROI-to-ROI contrast calculated: No %d.\n',contrast_number);
            else
                warning('ROI-to-ROI contrast failed.');
            end

        case 3  % Seed-to-voxel only

            sub_check_seed2vox = tmfc_seed_to_voxel_contrast(tmfc,analysis_type,contrast_number,tmfc.ROI_set_number,start_sub);
            if sub_check_seed2vox(length(tmfc.subjects)) == 1
                fprintf('Seed-to-voxel contrast calculated: No %d.\n',contrast_number);
            else
                disp('Seed-to-voxel contrast failed.');
            end
    end
end

guidata(main_GUI.TMFC_GUI, main_GUI);

end
% ===============================[ END ]===================================

%%
%--------------------------------------------------------------------------
%                            [ Subfunctions ]
%--------------------------------------------------------------------------

%% =================[ Select TMFC project folder GUI ]=====================
function tmfc_select_project_path(nSub)

    tmfc_project_path_GUI = figure('Name', 'Select TMFC project path', 'NumberTitle', 'off', 'Units', 'normalized', ...
        'Position', [0.40 0.45 0.24 0.14], 'MenuBar', 'none', 'ToolBar', 'none', ...
        'color', 'w', 'Resize', 'off', 'WindowStyle', 'modal', 'CloseRequestFcn', @ok_action, ...
        'Tag', 'TMFC_project_path');
    project_path_string = {'Next, select the project path where all results and temporary files will be stored.'};
    % PP = project path
    tmfc_PP_GUI_S1 = uicontrol(tmfc_project_path_GUI, 'Style', 'text', 'String', strcat(num2str(nSub), ' subjects selected'), 'Units', 'normalized', 'Position', [0.30 0.72 0.40 0.17], 'BackgroundColor', 'w', 'fontunits', 'normalized', 'fontSize', 0.64,'ForegroundColor', [0.219, 0.341, 0.137]);
    tmfc_PP_GUI_S2 = uicontrol(tmfc_project_path_GUI, 'Style', 'text', 'String', project_path_string, 'Units', 'normalized', 'Position', [0.055 0.38 0.90 0.30], 'BackgroundColor', 'w', 'fontunits', 'normalized', 'fontSize', 0.38);
    tmfc_PP_GUI_OK = uicontrol(tmfc_project_path_GUI, 'Style', 'pushbutton', 'String', 'OK', 'Units', 'normalized', ...
        'Position', [0.35 0.12 0.3 0.2], 'fontunits', 'normalized', 'fontSize', 0.42, 'callback', @ok_action);
    movegui(tmfc_project_path_GUI,'center');

    function ok_action(~,~)
        uiresume(tmfc_project_path_GUI);
    end

    uiwait(tmfc_project_path_GUI);
    delete(tmfc_project_path_GUI);
end

%% ==================[ ROI set related subfunctions ]======================

%--------------------------------------------------------------------------
% Reset TMFC progress for selected ROI set
%--------------------------------------------------------------------------
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

%--------------------------------------------------------------------------
% Switch between previously defined ROI sets or add a new ROI set (GUI)
%--------------------------------------------------------------------------
function [ROI_set_check, ROI_set_number] = ROI_set_switcher(ROI_set_list)

    ROI_set_check = 0;
    ROI_set_number = 0;
    tmp_set_number = 1;

    ROI_set_GUI = figure('Name', 'Select ROI set', 'NumberTitle', 'off', 'Units', 'normalized', ...
                        'Position', [0.35 0.40 0.28 0.35], 'color', 'w', 'MenuBar', 'none', 'ToolBar', 'none');

    ROI_set_GUI_disp =   uicontrol(ROI_set_GUI, 'Style', 'listbox', 'String', ROI_set_list(:,2), 'Units', 'normalized', ...
                        'Position', [0.048 0.25 0.91 0.49], 'fontunits', 'normalized', 'fontSize', 0.09, 'Value', 1, 'callback', @ROI_set_select);

    ROI_set_GUI_S1 =     uicontrol(ROI_set_GUI, 'Style', 'text', 'String', 'Select ROI set', 'Units', 'normalized', 'fontunits', 'normalized', 'fontSize', 0.54, ...
                        'Position', [0.31 0.85 0.400 0.09], 'BackgroundColor', get(ROI_set_GUI,'color'));

    ROI_set_GUI_S2 =     uicontrol(ROI_set_GUI, 'Style', 'text', 'String', 'Sets:', 'Units', 'normalized', 'fontunits', 'normalized', 'fontSize', 0.60, ...
                        'Position', [0.04 0.74 0.100 0.08], 'BackgroundColor', get(ROI_set_GUI,'color'));

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
        uiresume(ROI_set_GUI);
    end

    function ROI_set_add_new(~,~)
        ROI_set_check = 1;
        ROI_set_number = 0;
        uiresume(ROI_set_GUI);
    end

    uiwait(ROI_set_GUI);  
    delete(ROI_set_GUI);
end

%% ======================[ Restart/continue GUI ]==========================

%--------------------------------------------------------------------------
% Ask user to restart computations:
% restart_status = 1 - restart 
% restart_status = 0 - do not restart 

% Option:
% 1 - FIR
% 2 - LSS
% 3 - LSS after FIR
% 4 - VOIs
% 5 - PPIs
%--------------------------------------------------------------------------
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
    
    if isunix; fontscale = 0.95; else; fontscale = 1; end

    tmfc_restart_MW = figure('Name', restart_str_0, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.18 0.14], ...
                      'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Restart_WIN','CloseRequestFcn', @cancel);
    tmfc_restart_str = uicontrol(tmfc_restart_MW,'Style','text','String',restart_str_1 ,'Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', ...
                           'fontSize', 0.40*fontscale, 'Position', [0.10 0.55 0.80 0.260],'BackgroundColor',get(tmfc_restart_MW,'color'));
    tmfc_restart_ok = uicontrol(tmfc_restart_MW,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized', ...
                           'fontSize', 0.48, 'Position', [0.14 0.22 0.320 0.20],'callback', @restart);
    tmfc_restart_cancel = uicontrol(tmfc_restart_MW,'Style','pushbutton', 'String', 'Cancel','Units', 'normalized','fontunits','normalized', ...
                           'fontSize', 0.48,'Position',[0.52 0.22 0.320 0.20],'callback', @cancel);

    movegui(tmfc_restart_MW,'center');

    function cancel(~,~)
        restart_status = 0;
        uiresume(tmfc_restart_MW);
    end

    function restart(~,~)
        restart_status = 1;
        uiresume(tmfc_restart_MW);
    end

    uiwait(tmfc_restart_MW);  
    delete(tmfc_restart_MW);
end

%--------------------------------------------------------------------------
% Ask user to restart or continue computations:
% continue_status = 1    - continue 
% continue_status = 0    - restart 
% continue_status = -1   - cancel (do nothing)
%
% Option:
% 1 - FIR
% 2 - LSS
% 3 - LSS after FIR
% 4 - VOIs
% 5 - PPIs
% 6 - gPPI
% 7 - gPPI-FIR
% 8 - BGFC
%--------------------------------------------------------------------------
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

    if isunix; fontscale = 0.8; else; fontscale = 1; end

    tmfc_cont_MW = figure('Name', cont_str_0, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.20 0.18], 'Resize', 'off', 'color', 'w', ...
                      'MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Contd_FIR','CloseRequestFcn', @cancel); 
    tmfc_cont_str1 = uicontrol(tmfc_cont_MW,'Style','text','String', cont_str_1,'Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', ...
                            'fontSize', 0.38*fontscale, 'Position',[0.10 0.55 0.80 0.260],'BackgroundColor',get(tmfc_cont_MW,'color'));
    tmfc_cont_str2 = uicontrol(tmfc_cont_MW,'Style','text','String', strcat('subject No. ',num2str(iSub),'?'), 'Units','normalized', 'HorizontalAlignment', 'center', ...
                            'fontunits','normalized', 'fontSize', 0.38*fontscale, 'Position',[0.10 0.40 0.80 0.260],'BackgroundColor',get(tmfc_cont_MW,'color'));
    tmfc_cont_yes = uicontrol(tmfc_cont_MW,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.28, ...
                             'Position',[0.12 0.15 0.320 0.270],'callback', @cont);
    tmfc_cont_restart = uicontrol(tmfc_cont_MW,'Style','pushbutton', 'String', restart_str,'Units', 'normalized','fontunits','normalized', 'fontSize', 0.28, ...
                                 'Position',[0.56 0.15 0.320 0.270],'callback', @restart);
    movegui(tmfc_cont_MW,'center');

    function cancel(~,~)
        continue_status = -1;
        uiresume(tmfc_cont_MW);
    end

    function cont(~,~)
        continue_status = 1;
        uiresume(tmfc_cont_MW);
    end

    function restart(~,~)
        if ~strcmp(restart_str, 'Cancel')
            continue_status = 0;
            uiresume(tmfc_cont_MW);
        else
            continue_status = -1;
            uiresume(tmfc_cont_MW);
        end
    end

    uiwait(tmfc_cont_MW);
    delete(tmfc_cont_MW);
end

%% ================[ Dialog box for PPI recomputation ]====================
function PPI_recompute()
    PPI_recomp_GUI = figure('Name', 'PPI', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.24 0.12],'MenuBar', 'none', ...
                           'ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @ok_action, 'Tag', 'PPI');
    PPI_details = {'PPI computation completed.','To change conditions of interest, recompute VOIs.'};
    
    if isunix; fontscale = 0.95; else; fontscale = 1; end

    PPI_recomp_str = uicontrol(PPI_recomp_GUI,'Style','text','String',PPI_details,'Units', 'normalized', 'Position',[0.05 0.5 0.90 0.30], ...
                            'BackgroundColor','w','fontunits','normalized','fontSize', 0.38*fontscale);
    PPI_recomp_ok = uicontrol(PPI_recomp_GUI,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.38 0.18 0.23 0.2], ...
                            'fontunits','normalized','fontSize', 0.48,'callback', @ok_action);
    
    movegui(PPI_recomp_GUI,'center');
    
    function ok_action(~,~)
        uiresume(PPI_recomp_GUI);
    end
    uiwait(PPI_recomp_GUI);
    delete(PPI_recomp_GUI);
end

%% ==[ GUI: window length and time bins for FIR or gPPI-FIR regression ]===
% case 0 = FIR 
% case 1 = gPPI-FIR
function [window, bins] = tmfc_FIR_GUI(cases)
	
	switch (cases)
        case 0
        	GUI_title = 'FIR task regression'; 
            GUI_str_1 = 'Enter FIR window length (in seconds):';
            GUI_str_2 = 'Enter the number of FIR time bins:';
            GUI_str_help = 'FIR task regression: Help';
    
        case 1
            GUI_title = 'gPPI FIR regression'; 
            GUI_str_1 = 'Enter FIR window length (in seconds) for gPPI:';
            GUI_str_2 = 'Enter the number of FIR time bins for gPPI:';
            GUI_str_help = 'gPPI FIR: Help';
	end
    
    tmfc_FIR_BW_GUI = figure('Name', GUI_title, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.28 0.18],'Resize','off',...
        'MenuBar', 'none', 'ToolBar', 'none','Tag','TMFC_WB_NUM', 'WindowStyle','modal','color', 'w','CloseRequestFcn', @tmfc_FIR_BW_GUI_Exit); 

    if isunix; fontscale = 0.95; else; fontscale = 1; end

    tmfc_FIR_BW_GUI_S1 = uicontrol(tmfc_FIR_BW_GUI,'Style','text','String', GUI_str_1,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40*fontscale, 'Position',[0.08 0.62 0.65 0.200],'BackgroundColor',get(tmfc_FIR_BW_GUI,'color'));
    tmfc_FIR_BW_GUI_S2 = uicontrol(tmfc_FIR_BW_GUI,'Style','text','String', GUI_str_2,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40*fontscale,'Position',[0.08 0.37 0.65 0.200],'BackgroundColor',get(tmfc_FIR_BW_GUI,'color'));
    tmfc_FIR_BW_GUI_E1 = uicontrol(tmfc_FIR_BW_GUI,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.67 0.185 0.170], 'fontSize', 0.44);
    tmfc_FIR_BW_GUI_E2 = uicontrol(tmfc_FIR_BW_GUI,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.42 0.185 0.170], 'fontSize', 0.44);
    tmfc_FIR_BW_GUI_ok = uicontrol(tmfc_FIR_BW_GUI,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.21 0.13 0.230 0.170],'callback', @tmfc_FIR_BW_extract);
    tmfc_FIR_BW_GUI_help = uicontrol(tmfc_FIR_BW_GUI,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.56 0.13 0.230 0.170],'callback', @tmfc_FIR_help_GUI);
    movegui(tmfc_FIR_BW_GUI,'center');
    
    %----------------------------------------------------------------------
    function tmfc_FIR_BW_GUI_Exit(~,~)
    	window = NaN; 
    	bins = NaN; 
    	uiresume(tmfc_FIR_BW_GUI);
    end

    %----------------------------------------------------------------------
    function tmfc_FIR_help_GUI(~,~)

    	tmfc_FIR_help = figure('Name', GUI_str_help, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.62 0.26 0.22 0.48],'Resize','off','MenuBar', 'none','ToolBar', 'none');
        set(gcf,'color','w');

        tmfc_help_str = {'Finite impulse response (FIR) task regression is used to remove co-activations from BOLD time series.', '', ...
             'Co-activations are simultaneous (de)activations without communication between brain regions.', '', ...
             'Co-activations spuriously inflate task-modulated functional connectivity (TMFC) estimates.', '', ...
             'This option regresses out (1) co-activations with arbitrary HRF shapes and (2) confounds specified in the', ...
             'original SPM.mat file (e.g., motion, physiological noise, etc.).', '', ...
             'Functional images for residual time series (Res_*.nii in FIR_GLM folders) will be used for TMFC analysis.', '', ...
             'Typically, the FIR window length covers the event duration plus ~18 s to capture the hemodynamic response.', '', ...
             'Typically, the FIR time bin equals the repetition time (TR). Therefore:', ''};

        TMFC_BW_DETAILS_2 = {'Number of FIR bins = FIR window length/TR'};

        if isunix; fontscale = 0.8; else; fontscale = 1; end    

        tmfc_FIR_help_S1 = uicontrol(tmfc_FIR_help,'Style','text','String', tmfc_help_str,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.035*fontscale, 'Position',[0.06 0.16 0.885 0.800],'BackgroundColor',get(tmfc_FIR_help,'color'));
        tmfc_FIR_help_S2 = uicontrol(tmfc_FIR_help,'Style','text','String', TMFC_BW_DETAILS_2,'Units', 'normalized', 'HorizontalAlignment', 'Center','fontunits','normalized', 'fontSize', 0.28*fontscale, 'Position',[0.06 0.08 0.885 0.10],'BackgroundColor',get(tmfc_FIR_help,'color'));
        tmfc_FIR_help_ok = uicontrol(tmfc_FIR_help,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35, 'Position',[0.39 0.04 0.240 0.070],'callback', @tmfc_FIR_help_close);
        movegui(tmfc_FIR_help,'center');

        function tmfc_FIR_help_close(~,~)
            close(tmfc_FIR_help);
        end
    end
    
    %----------------------------------------------------------------------
    % Function to extract the entered number from the user
    function tmfc_FIR_BW_extract(~,~)

        window_tmp = str2double(get(tmfc_FIR_BW_GUI_E1, 'String'));
        bins_tmp = str2double(get(tmfc_FIR_BW_GUI_E2, 'String'));

        if isnan(window_tmp)
        	fprintf(2,'Please enter a natural number for the window length.\n');
        elseif ~isnan(window_tmp) && isnan(bins_tmp)
        	fprintf(2,'Please enter a natural number for time bins.\n');
        elseif ~(window_tmp > 0)
        	fprintf(2,'Please enter a natural number for the window length.\n');
        elseif ~(bins_tmp > 0 && floor(bins_tmp) == bins_tmp)
        	fprintf(2,'Please enter a natural number for time bins.\n');
        else
        	window = window_tmp; 
        	bins = bins_tmp;   
        	uiresume(tmfc_FIR_BW_GUI);
        end
    end

    uiwait(tmfc_FIR_BW_GUI);    
    delete(tmfc_FIR_BW_GUI);
end

%% ===============[ Dialog box for BGFC recomputation ]====================
function recompute_BGFC(tmfc)

recompute_BGFC_GUI = figure('Name', 'BGFC', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.5 0.12], ...
    'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @ok_action, 'Tag', 'BGFC');    
BGFC_details = {strcat('BGFC was calculated for all subjects. FIR settings: ', 32, num2str(tmfc.FIR.window), ...
             ' [s] window and ', 32, num2str(tmfc.FIR.bins),' time bins.'),...
             'To calculate BGFC with different FIR settings, recompute FIR task regression with desired window length and number of time bins.'};

if isunix; fontscale = 0.85; else; fontscale = 1; end

BGFC_recomp_GUI_S1 = uicontrol(recompute_BGFC_GUI,'Style','text','String',BGFC_details,'Units', 'normalized', 'Position',[0.05 0.5 0.90 0.30],'fontunits','normalized','fontSize', 0.38*fontscale,'BackgroundColor','w');
BGFC_recomp_ok = uicontrol(recompute_BGFC_GUI,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.45 0.18 0.1 0.24],'fontunits','normalized','fontSize', 0.40,'callback', @ok_action);
movegui(recompute_BGFC_GUI,'center');

function ok_action(~,~)
    uiresume(recompute_BGFC_GUI);
end

uiwait(recompute_BGFC_GUI);
delete(recompute_BGFC_GUI);

end

% =================================[ END ]=================================
