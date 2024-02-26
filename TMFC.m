function TMFC
    
% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens the main GUI window.
%
% The tmfc structure contains the following structures:
%    
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^31 = 2GB (how much RAM can be used at
%                            the same time during GLM estimation)
%   tmfc.defaults.resmem   - true or false (store temporaty files during
%                            GLM estimation in RAM or on disk)
%   
%   tmfc.project_path      - The path where all results will be saved
%   
%   tmfc.subjects.path     - Paths to individual subject SPM.mat files
%   tmfc.subjects.FIR:            - 1 or 0 (completed or not)
%   tmfc.subjects.LSS_after_FIR   - 1 or 0 (completed or not)
%   tmfc.subjects.LSS_without_FIR - 1 or 0 (completed or not)
%
%   tmfc.FIR.window        - FIR window length in doc memory[s]
%   tmfc.FIR.bins          - Number of FIR time bins
% 
%   tmfc.LSS_after_FIR.conditions   - Conditions of interest for LSS 
%                                     regression after FIR regression
%                                     (based on residual time series)
%   tmfc.LSS_without_FIR.conditions - Conditions of interest for LSS
%                                     regression without FIR regression
%                                     (based on original time series)            
%
%   tmfc.ROI_set:         - information about the selected ROI set
%                           and completed TMFC procedures
%
% =========================================================================
%
% Copyright (C) 2023 Ruslan Masharipov
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

if isempty(findobj('Tag', 'TMFC_MW')) == 1  
    
    tmfc = struct;
    % Set up TMFC structure
    tmfc.defaults.parallel = 0;      
    tmfc.defaults.maxmem = 2^31;
    tmfc.defaults.resmem = true;
    tmfc.defaults.analysis = 1;
%     tmfc.project_path = '';
%     tmfc.subjects(1).path = '';
%     
%     tmfc.FIR.window = NaN;
%     tmfc.FIR.bins = NaN;
%     
%     tmfc.subjects(1).FIR = [];
%     tmfc.subjects(1).LSS = [];
%     tmfc.subjects(1).LSS_after_FIR = [];
%     
%     tmfc.LSS.conditions = [];
%     tmfc.LSS_after_FIR.conditions = [];
%     tmfc.ROI_set = [];
       
%     % Initializing handles & elements of the GUI    
%     handles.MAIN_F = figure('Name', 'TMFC Toolbox', 'NumberTitle', 'off', 'Units', 'norm', 'Position', [0.40 0.26 0.205 0.575], 'MenuBar', 'none', 'ToolBar', 'none', 'color', 'w', 'Tag', 'MAIN_WINDOW');%'Resize', 'off', 
%     
%     % Select subjects
%     handles.SUB = uicontrol('Style', 'pushbutton', 'String', 'Subjects', 'Units', 'norm', 'Position', [0.06 0.86 0.40 0.0715],'FontUnits','normalized');
%     handles.SUB_stat = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', 'red', 'Units', 'norm', 'Position',[0.55 0.84 0.40 0.0715], 'backgroundcolor', 'w','FontUnits','normalized');
%     
%     % FIR task regression
%     handles.FIR_TR = uicontrol('Style', 'pushbutton', 'String', 'FIR task regression', 'Units', 'normalized', 'Position', [0.06 0.765 0.40 0.0715],'FontUnits','normalized');
%     handles.FIR_TR_stat = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position', [0.55 0.745 0.40 0.0715], 'backgroundcolor', 'w','FontUnits','normalized');
%     
%     % LSS after FIR
%     handles.LSS_R = uicontrol('Style', 'pushbutton', 'String', 'LSS after FIR', 'Units', 'normalized', 'Position', [0.06 0.669 0.40 0.0715],'FontUnits','normalized');
%     handles.LSS_R_stat = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position', [0.55 0.653 0.40 0.0715], 'backgroundcolor', 'w','FontUnits','normalized');
%    
%     % LSS without FIR 
%     handles.LSS_RW = uicontrol('Style', 'pushbutton', 'String', 'LSS without FIR', 'Units', 'normalized', 'Position', [0.06 0.571 0.40 0.0715],'FontUnits','normalized');
%     handles.LSS_RW_stat = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position', [0.55 0.551 0.40 0.0715], 'backgroundcolor', 'w','FontUnits','normalized');
%    
%     % Background connectivity, BSC-LSS, gPPI 
%     handles.BGFC = uicontrol('Style', 'pushbutton', 'String', 'Background connectivity', 'Units', 'normalized', 'Position',[0.06 0.475 0.875 0.0715]);
%     handles.BSC = uicontrol('Style', 'pushbutton', 'String', 'BSC-LSS','Units', 'normalized', 'Position', [0.06 0.380 0.875 0.0715]);
%     handles.gPPI = uicontrol('Style', 'pushbutton', 'String', 'gPPI', 'Units', 'normalized', 'Position', [0.06 0.280 0.875 0.0715]);
%    
%     % Save project, Open project, Change paths, Settings
%     handles.save_p = uicontrol('Style', 'pushbutton', 'String', 'Save project', 'Units', 'normalized', 'Position', [0.06 0.130 0.40 0.0715]);
%     handles.open_p = uicontrol('Style', 'pushbutton', 'String', 'Open project', 'Units', 'normalized', 'Position', [0.536 0.130 0.40 0.0715]);
%     handles.change_p = uicontrol('Style', 'pushbutton', 'String', 'Change paths', 'Units', 'normalized', 'Position', [0.06 0.038 0.40 0.0715]);
%     handles.settings = uicontrol('Style', 'pushbutton', 'String', 'Settings', 'Units', 'normalized', 'Position', [0.536 0.038 0.40 0.0715]);
    
    
    
    % Main TMFC Window
    handles.TMFC_MW = figure('Name', 'TMFC Toolbox','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'norm', 'Position', [0.115 0.0875 0.250 0.850], 'color', 'w', 'Tag', 'TMFC_MW');
    
    % Box Panels
    handles.MP1 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.03 0.85 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP2 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.03 0.65 0.94 0.19],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP3 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.03 0.511 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP4 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.03 0.37 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP5 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.03 0.23 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.MP6 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.03 0.01 0.94 0.13],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');    
    handles.SP1 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.54 0.922 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP2 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.54 0.863 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP3 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.54 0.782 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP4 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.54 0.722 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP6 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.54 0.582 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP8 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.54 0.442 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    handles.SP9 = uipanel(handles.TMFC_MW,'Units', 'normalized','Position',[0.54 0.302 0.40 0.0473],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    
    % Buttons
    handles.TMFC_MW_B1 = uicontrol('Style', 'pushbutton', 'String', 'Subjects', 'Units', 'normalized', 'Position', [0.06 0.92 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B2 = uicontrol('Style', 'pushbutton', 'String', 'ROI set', 'Units', 'normalized', 'Position', [0.06 0.86 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B3 = uicontrol('Style', 'pushbutton', 'String', 'VOIs', 'Units', 'normalized', 'Position', [0.06 0.78 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B4 = uicontrol('Style', 'pushbutton', 'String', 'PPIs', 'Units', 'normalized', 'Position', [0.06 0.72 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B5a = uicontrol('Style', 'pushbutton', 'String', 'gPPI', 'Units', 'normalized', 'Position', [0.06 0.66 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B5b = uicontrol('Style', 'pushbutton', 'String', 'gPPI FIR', 'Units', 'normalized', 'Position', [0.54 0.66 0.40 0.05],'FontUnits','normalized','FontSize',0.33);    
    handles.TMFC_MW_B6 = uicontrol('Style', 'pushbutton', 'String', 'LSS GLM', 'Units', 'normalized', 'Position', [0.06 0.58 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B7 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS', 'Units', 'normalized', 'Position', [0.06 0.52 0.88 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B8 = uicontrol('Style', 'pushbutton', 'String', 'FIR task regression', 'Units', 'normalized', 'Position', [0.06 0.44 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B9 = uicontrol('Style', 'pushbutton', 'String', 'Background connectivity', 'Units', 'normalized', 'Position', [0.06 0.38 0.88 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B10 = uicontrol('Style', 'pushbutton', 'String', 'LSS GLM after FIR', 'Units', 'normalized', 'Position', [0.06 0.30 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B11 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS after FIR', 'Units', 'normalized', 'Position', [0.06 0.24 0.88 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B12 = uicontrol('Style', 'pushbutton', 'String', 'Results', 'Units', 'normalized', 'Position', [0.06 0.16 0.88 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B13a = uicontrol('Style', 'pushbutton', 'String', 'Open project', 'Units', 'normalized', 'Position', [0.06 0.08 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B13b = uicontrol('Style', 'pushbutton', 'String', 'Save project', 'Units', 'normalized', 'Position', [0.54 0.08 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B14a = uicontrol('Style', 'pushbutton', 'String', 'Change paths', 'Units', 'normalized', 'Position', [0.06 0.02 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_MW_B14b = uicontrol('Style', 'pushbutton', 'String', 'Settings', 'Units', 'normalized', 'Position', [0.54 0.02 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    
    % String counters
    % red = 'red'
    % green = [0.219, 0.341, 0.137]
    % orange = [0.773, 0.353, 0.067]
    handles.TMFC_MW_S1 = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', 'red', 'Units', 'norm', 'Position',[0.555 0.926 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_MW_S2 = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', 'red', 'Units', 'norm', 'Position',[0.555 0.867 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_MW_S3 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.787 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_MW_S4 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.727 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_MW_S6 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.587 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_MW_S8 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.447 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_MW_S10 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.307 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    
    % CallBack functions corresponding to each button
    set(handles.TMFC_MW, 'CloseRequestFcn', {@Close_TMFC, handles.TMFC_MW}); 
    set(handles.TMFC_MW_B1, 'callback', {@Action_SUB_SEL, handles.TMFC_MW});
    set(handles.TMFC_MW_B8, 'callback', {@Action_FIR_REG, handles.TMFC_MW});
    set(handles.TMFC_MW_B12, 'callback', {@reset, handles.TMFC_MW});
    set(handles.TMFC_MW_B13a, 'callback', {@LOAD_PROJ, handles.TMFC_MW});
    set(handles.TMFC_MW_B14b, 'callback', {@Action_Settings, handles.TMFC_MW});
    
%     set(handles.open_p, 'callback', {@LOAD_PROJ, handles.TMFC_MW});
%     set(handles.change_p, 'callback', {@CP_GUI, handles.TMFC_MW});
%     set(handles.settings, 'callback', {@Settings, handles.TMFC_MW});
     
%     set(handles.FIR_TR, 'callback', {@FIR_REG, handles.TMFC_MW});
%     set(handles.LSS_R, 'callback', {@LSS_REG, handles.TMFC_MW});
%     set(handles.LSS_RW, 'callback', {@LSS_REGW, handles.TMFC_MW});
%     set(handles.BGFC, 'callback', {@BGFC_EX, handles.TMFC_MW});
%     set(handles.BSC, 'callback', {@BSC_EX, handles.TMFC_MW});
%     set(handles.gPPI, 'callback', {@gPPI_EX, handles.TMFC_MW});
    set(handles.TMFC_MW_B13b, 'callback', {@tempsave, handles.TMFC_MW});

else
    figure(findobj('Tag', 'TMFC_MW')); 
    warning('TMFC toolbox is already running');    
end
    
    function reset(ButtonH, EventData, TMFC_MW)
        
        tmfc = struct;
        tmfc.defaults.parallel = 0;      
        tmfc.defaults.maxmem = 2^31;
        tmfc.defaults.resmem = true;
        
        set(handles.TMFC_MW_S1, 'String', 'Not selected','ForegroundColor', 'red');
        set(handles.TMFC_MW_S2, 'String', 'Not selected','ForegroundColor', 'red');
        set(handles.TMFC_MW_S3, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
        set(handles.TMFC_MW_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
        set(handles.TMFC_MW_S6, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
        set(handles.TMFC_MW_S8, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
        set(handles.TMFC_MW_S10, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
        
        disp('tmfc reset');
        disp(tmfc);
    end

    function tempsave(ButtonH, EventData, TMFC_MW)
        assignin('base', 'tmfc', tmfc);
    end
%% ========================[ Select Subjects ]=============================
% Select subjects and check SPM.mat files
function Action_SUB_SEL(ButtonH, EventData, TMFC_MW)
    MW_Freeze(1);
    sel_paths = tmfc_select_subjects_GUI(1);
    if isempty(sel_paths)
        MW_Freeze(0);
        disp('Subjects not selected');
    else 
       L_paths = size(sel_paths);
       for SS_i = 1:L_paths(1) 
           tmfc.subjects(SS_i).path = char(sel_paths(SS_i));       
       end
       
       disp('Please Select a folder for the new TMFC project');    % Select project path
       TMFC_SS_select_proj_path(L_paths(1));
       project_path = spm_select(1,'dir','Select a folder for the new TMFC project',{},pwd);
        if strcmp(project_path, '')
            warning('Project Path Not selected, Subjects not saved');
            try
                MW_Freeze(0);
            end
            return;
        else
            fprintf('%d subjects have been selected \n', L_paths(1));
            set(handles.TMFC_MW_S1,'String', strcat(num2str(L_paths(1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
            tmfc.project_path = project_path;
            MW_Freeze(0);
        end
    end
    disp(tmfc);
end


%% ========================[ FIR Regression ]==============================

function Action_FIR_REG(ButtonH, EventData, TMFC_MW)
               
    % Freezing the Main window
    MW_Freeze(1);
    
    
    disp('Initiating FIR regression');
    if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
        % Checking if subjects has been selected
        
        if ~isfield(tmfc, 'FIR') 
        % Checking if FIR has been executed before
        
            [tmfc.FIR.window,tmfc.FIR.bins] = TMFC_FIR_BW_GUI();
            % Eneter bins & windows
            
             if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)
                % Initial exeuction of FIR regression
                new_run = tmfc_FIR(tmfc, 1);
                for i=1:length(tmfc.subjects)
                    tmfc.subjects(i).FIR = new_run(i);
                end
             end
             
        elseif isfield(tmfc, 'FIR') && ~isfield(tmfc.subjects, 'FIR')
            
            % Exeuction if CTLR + C is pressed 
            % Can add code for exuection from last complied .mat file
            [tmfc.FIR.window,tmfc.FIR.bins] = TMFC_FIR_BW_GUI();
            
             if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)
                new_run = tmfc_FIR(tmfc, 1);
                for i=1:length(tmfc.subjects)
                    tmfc.subjects(i).FIR = new_run(i);
                end
             end
            
        else
            
            % Other cases 'Restart' and 'Continue'
            if ~isnan(tmfc.FIR.window) && ~isnan(tmfc.FIR.bins) 
                
                
                if tmfc.subjects(length(tmfc.subjects)).FIR == 1                  
                    
                    % Restart case
                    STATUS = TMFC_FIR_RES_GUI();
                    if STATUS == 1
                        [tmfc.FIR.window,tmfc.FIR.bins] = TMFC_FIR_BW_GUI();
                        if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)                            
                            disp('Restarting FIR Regression');
                            re_run = tmfc_FIR(tmfc, 1);
                            for i=1:length(tmfc.subjects)
                                tmfc.subjects(i).FIR = re_run(i);
                            end
                        end
                    end
                    
                    
                else
                    % Continue case
                    for i=1:length(tmfc.subjects)
                        FIR_index = NaN;
                        if isnan(tmfc.subjects(i).FIR)
                            FIR_index = i;
                            break;
                        end
                    end
                    
                    FIR_dec = TMFC_FIR_CON_GUI(FIR_index);
                    
                    if FIR_dec == 0
                        con_run = tmfc_FIR(tmfc,FIR_index);
                        for i=FIR_index:length(tmfc.subjects)
                            tmfc.subjects(i).FIR = con_run(i);
                        end
                    elseif FIR_dec == 1
                        [tmfc.FIR.window,tmfc.FIR.bins] = TMFC_FIR_BW_GUI();
                        if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)                                                    
                            con_run = tmfc_FIR(tmfc,1);
                            for i=1:length(tmfc.subjects)
                                tmfc.subjects(i).FIR = con_run(i);
                            end
                        end
                    else
                        warning('FIR Regression not initiated');
                    end
                    
                end
            end
        end
            
    else
        warning('Please select subjects to continue with FIR Regression');
    end
    
    
        MW_Freeze(0);
        disp(tmfc);
        
    end % Closing FIR Regress Function
       
    

%% =============================[ Close ]==================================
 
% Function to peform Save & Exit from TMFC function. This function is 
% linked to the close button on the top right handside of the Window

% NEED TO ADD CONDITION WHEN TMFC VARIABLE IS DELETED BUT TRY TO EXIT
% DELETE TMFC in WS-> Close TMFC -> DO NOT ASK TO SAVE (Give warning)
function Close_TMFC(ButtonH, EventData, TMFC_MW) 
    
        % Exit Dialouge GUI
        EXIT_PROMPT = figure('Name', 'TMFC: Exit', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.25 0.20],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'EXIT_FIN', 'WindowStyle','modal'); %X Y W H

        % Content - Can be changed to a single sentence using \html or
        % sprtinf
        EX_Q1 = uicontrol(EXIT_PROMPT,'Style','text','String', 'Would you like to save your progress','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);
        EX_Q2 = uicontrol(EXIT_PROMPT,'Style','text','String', 'before exiting TMFC toolbox?', 'Units','normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);

        % Buttons of the GUI
        EX_YES = uicontrol(EXIT_PROMPT,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.38);
        EX_NO = uicontrol(EXIT_PROMPT,'Style','pushbutton', 'String', 'No','Units', 'normalized','fontunits','normalized', 'fontSize', 0.38);

        % Spawn Positions of the GUI text boxes & buttons
        EX_Q1.Position = [0.04 0.55 0.94 0.260];
        EX_Q2.Position = [0.10 0.40 0.80 0.260];
        EX_YES.Position = [0.16 0.18 0.300 0.200];
        EX_NO.Position = [0.57 0.18 0.300 0.200];

        % Colour of Text boxes & actions of buttons
        set([EX_Q1,EX_Q2],'backgroundcolor',get(EXIT_PROMPT,'color'));
        set(EX_NO, 'callback', @EX_WO_SAVE);
        set(EX_YES, 'callback', @EX_W_SAVE);
        
        % EX_NO = Exit without saving TMFC toolbox
        % EX_YES = Save & then Exit TMFC toolbox
        
    % Function to Exit toolbox WITHOUT saving TMFC variable
    function EX_WO_SAVE(~,~)
        % Closes dialouge box -> closes Main GUI
        close(EXIT_PROMPT);
        delete(handles.TMFC_MW);
        disp('Goodbye!');
    end
    
    % Function to Exit toolbox AFTER saving TMFC variable
    function EX_W_SAVE(~,~)
        % Performs saving of TMFC variable using SAVE_PROJECT function
        CT_1 = SAVE_PROJ();
        
        % Based on the result of successful save, TMFC toolbox is
        % closed (i.e. Save->Save Status-> Close Main GUI)
        if CT_1 == 1
            close(EXIT_PROMPT);
            delete(handles.TMFC_MW);
            disp('Goodbye!');
        end
    end
end
    
%% ==========================[ Save Project ]==============================

    % Function to perform Saving of TMFC variable from workspace to
    % individual .m file in user desired location
    
    function SAVE_STAT = SAVE_PROJ(ButtonH, EventData, TMFC_MW)
       
        % Acquire variable from Workspace
        %TMFC = evalin('base', 'tmfc');
        
        % Ask user for Filename & location name:
        [filename_SO, pathname_SO] = uiputfile('*.mat', 'Save TMFC variable as'); %pwd
        
        % Set Flag save status to Zero, this flag is used in the future as
        % a reference to check if the Save was successful or not
        SAVE_STAT = 0;
        
        % Check if FileName or Path is missing or not available 
        if isequal(filename_SO, 0) || isequal(pathname_SO, 0)
            error('TMFC variable not saved, File name or Save Directory not selected');
        
        else
            % If all data is available
            % Construct full path: PATH + FileName
            % e.g (D:\user\matlab\ + Test.m)
            
            fullpath = fullfile(pathname_SO, filename_SO);
            
            % D receives the save status of the variable in the desingated
            % location
            SAVE_STAT = Saver(fullpath);
            
            % If the variable was successfully saved then display info
            if SAVE_STAT == 1
                fprintf('File saved successfully in path: %s\n', fullpath);
            else
                fprintf('File not saved ');
            end
            %save(pathname, replace( filename, '.mat' , "" ));
            %save(fullpath, 'TMFC');
            %fprintf('File saved successfully in path: %s\n', fullpath);
        end
              
    end

%% ====================[ Background Connectivity ]=========================
function BGFC_EX(ButtonH, EventData, TMFC_MW)
    % -1 = no selection or creation 
    % 0 reutrn = NEW ROI Created and have to select it 
    % 1 ROI selected from existing list
    D = tmfc_select_ROIs_GUI();
    fprintf('Continue BGFC with ROI # = %d \n', D);
    
end


%% =====================[ Beta Series Corelation ]=========================
function BSC_EX(ButtonH, EventData, TMFC_MW)
    BSC_entry = tmfc_select_ROIs_GUI();
    fprintf('Continue BSC with ROI # = %d \n', BSC_entry);
    if BSC_entry ~= -1
        tmfc_BSC_GUI(tmfc,BSC_entry);
    end
end

%% =============================[ Close ]==================================
function gPPI_EX(ButtonH, EventData, TMFC_MW)
    D = tmfc_select_ROIs_GUI();
    fprintf('Continue gPPI with ROI # = %d \n', D);
end


%% ==========================[ Load Project ]==============================

    % Function to perform loading of TMFC variable from .m file 
    % to Workspace in matlab
    
    function LOAD_PROJ(ButtonH, EventData, TMFC_MW)
        
        % Get File name, Directory of File to be loaded
        [filename_LO, pathname_LO] = uigetfile(pwd,'*.mat', 'Select .mat file');
        
        % If user has selected a file the proceed else warning
        if filename_LO ~= 0                                              
            % Construct Full Path to file
            fullpath_L = fullfile(pathname_LO, filename_LO);            
            
            % Load Data from File into temporary variable
            loaded_data_L = load(fullpath_L);            
            
            % Get the name of the variable as in file 
            variable_name_L = fieldnames(loaded_data_L);                
            
            % Get value of the variable as in file
            tmfc = loaded_data_L.(variable_name_L{1});      
            
            % Assign generated data into Base workspace under corresponding
            % variable name
            %assignin('base', variable_name_L{1}, variable_value_L);
            %assignin('base', 'tmfc', variable_value_L);
            %tmfc = evalin('base', 'tmfc');
            
            %disp(variable_value_L);
            %tmfc = load(variable_value_L);
            %disp(tmfc);
            % Supporting Function - To Update TMFC GUI when loading data
            evaluate_file(tmfc);
            
        else
            warning('No file selected');
        end
        
    end     


%% ==========================[ Change Paths ]==============================

% Function to perform change of paths using Select subs
function CP_GUI(ButtonH, EventData, TMFC_MW)
    try
        % Select subjects to change the Path 
        % Using Select_Subjects_GUI (without checking)
        D = tmfc_select_subjects_GUI(0);  
        % 
        % Continue exectuion using Change paths GUI (feed selected paths to change_paths_gui)
        tmfc_change_paths_GUI(D);    
    catch
        % If user 
        disp('No subject files selected for path change');
    end        
end

%% ============================[ Settings ]================================

% Function that launches Settings Window & Synchronizes new options 

% Variables to store & display selected settings in the settings window
% Type of computing (Default computing: Sequential - 0, Parallel - 1)
SET_COMPUTING = {'Sequential computing', 'Parallel computing'};
SET_STORAGE = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
SET_SEED = {'Seed-to-voxel and ROI-to-ROI','ROI-to-ROI','Seed-to-voxel only'};

function Action_Settings(ButtonH, EventData, TMFC_MW)
        
    % Create the Main figure for settings Window
    TMFC_SET = figure('Name', 'TMFC Toolbox','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'norm', 'Position', [0.415 0.0875 0.250 0.850], 'color', 'w', 'Tag', 'TMFC_MW_Settings','resize', 'off','WindowStyle','modal');
    
    % Textual Data to be displayed on the settings window
    SET_TEXT_1 = {'Parallel computing use Parallel Computing Toolbox. The number of workers in a parallel pool can be changed in MATLAB settings.'};
    SET_TEXT_2 = {'This option temporary changes resmem variable in spm_defaults, which governing whether temporary files during GLM estimation are stored on disk or kept in memory. If you have enough available RAM, not writing the files to disk will speed the estimation.'};
    SET_TEXT_3a = {'Max RAM temporary changes maxmem variable in spm_defaults, which indicates how much memory can be used at the same time during GLM estimation. If your computer has a large amount of RAM, you can increase that memory setting:'};
    SET_TEXT_3b = {'• 2^31 = 2GB','• 2^32 = 4GB', '• 2^33 = 8GB','• 2^34 = 16GB','• 2^35 = 32GB'};
    SET_TEXT_4 = {'Perform seed-to-voxel or ROI-to-ROI analysis or both. Applies to gPPI and BSC methods.','',...
        'Seed-to-voxel gPPI is computationally expensive and can take a long time as it estimates the gPPI model parameters for each voxel.','',...
        'Seed-to-voxel BSC calculates relatively fast (about as ROI-to-ROI analysis) since voxel-wise correlations are not computationally expensive.'};

    % Initializing Drop down menus of options for Settings Window
    TMFC_SET_MP1 = uipanel(TMFC_SET,'Units', 'normalized','Position',[0.03 0.865 0.94 0.125],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    TMFC_SET_MP2 = uipanel(TMFC_SET,'Units', 'normalized','Position',[0.03 0.685 0.94 0.17],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    TMFC_SET_MP3 = uipanel(TMFC_SET,'Units', 'normalized','Position',[0.03 0.375 0.94 0.30],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    TMFC_SET_MP4 = uipanel(TMFC_SET,'Units', 'normalized','Position',[0.03 0.10 0.94 0.265],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    
    TMFC_SET_P1 = uicontrol(TMFC_SET,'Style','popupmenu', 'String', SET_COMPUTING ,'Units', 'normalized', 'Position',[0.048 0.908 0.90 0.07],'fontunits','normalized', 'fontSize', 0.265);
    TMFC_SET_P2 = uicontrol(TMFC_SET,'Style','popupmenu', 'String', SET_STORAGE ,'Units', 'normalized', 'Position',[0.048 0.775 0.90 0.07],'fontunits','normalized', 'fontSize', 0.265);
    TMFC_SET_P4 = uicontrol(TMFC_SET,'Style','popupmenu', 'String', SET_SEED ,'Units', 'normalized', 'Position',[0.048 0.282 0.90 0.07],'fontunits','normalized', 'fontSize', 0.265);
    
    TMFC_SET_OK = uicontrol(TMFC_SET,'Style', 'pushbutton', 'String', 'OK', 'Units', 'normalized', 'Position', [0.3 0.03 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    TMFC_SET_E1 = uicontrol(TMFC_SET,'Style','edit','String', tmfc.defaults.maxmem,'Units', 'normalized', 'HorizontalAlignment', 'center','Position',[0.72 0.61 0.22 0.05],'fontunits','normalized', 'fontSize', 0.38);
    
    TMFC_SET_S1 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_1,'Units', 'normalized', 'Position',[0.05 0.87 0.90 0.07],'fontunits','normalized','fontSize', 0.265, 'HorizontalAlignment', 'left','backgroundcolor','w');
    TMFC_SET_S2 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_2,'Units', 'normalized', 'Position',[0.05 0.69 0.90 0.11],'fontunits','normalized','fontSize', 0.16, 'HorizontalAlignment', 'left','backgroundcolor','w');
    TMFC_SET_S3_1 = uicontrol(TMFC_SET,'Style','text','String', 'Max RAM for GLM esimtation (bits):','Units', 'normalized', 'Position',[0.048 0.61 0.65 0.04],'fontunits','normalized', 'fontSize', 0.46,'HorizontalAlignment', 'left','backgroundcolor','w');%
    TMFC_SET_S3_2 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_3a,'Units', 'normalized', 'Position',[0.05 0.505 0.90 0.09],'fontunits','normalized','fontSize', 0.19, 'HorizontalAlignment', 'left','backgroundcolor','w');
    TMFC_SET_S3_3 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_3b,'Units', 'normalized', 'Position',[0.11 0.38 0.27 0.12],'fontunits','normalized','fontSize', 0.155, 'HorizontalAlignment', 'left','backgroundcolor','w');
    TMFC_SET_S4 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_4,'Units', 'normalized', 'Position',[0.05 0.11 0.90 0.20],'fontunits','normalized','fontSize', 0.088, 'HorizontalAlignment', 'left','backgroundcolor','w');
    
    set(TMFC_SET_OK , 'callback', @OK_SYNC);   


    TMFC_SET_COPY = tmfc;
        % The following functions perform Synchronization after OK
        % button has been pressed 
        
        function OK_SYNC(~,~)

            % Create a local copy of the TMFC variable
           %SET_SYNC = evalin('base', 'tmfc');

           % SYNC: Computation type
           % Check status of string in stat box -> if changed -> SWAP
           % details -> Change TMFC variable -> END          
           
           C_1 = (TMFC_SET_P1.String(TMFC_SET_P1.Value));
           if strcmp(C_1{1},'Sequential computing')
               SET_COMPUTING = {'Sequential computing','Parallel computing'};
               set(TMFC_SET_P1, 'String', SET_COMPUTING);
               tmfc.defaults.parallel = 0;

           elseif strcmp(C_1{1},'Parallel computing')
               SET_COMPUTING = {'Parallel computing','Sequential computing',};
               set(TMFC_SET_P1, 'String', SET_COMPUTING);
               tmfc.defaults.parallel = 1;
           end


           % SYNC: Storage type
           % Check status of string in stat box -> if changed -> SWAP
           % details -> Change TMFC variable -> END
           C_2 = (TMFC_SET_P2.String(TMFC_SET_P2.Value));
           if strcmp(C_2{1}, 'Store temporary files for GLM estimation in RAM')
               SET_STORAGE = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
               set(TMFC_SET_P2, 'String', SET_STORAGE);
               tmfc.defaults.resmem =  true;

           elseif strcmp(C_2{1}, 'Store temporary files for GLM estimation on disk')
               SET_STORAGE = {'Store temporary files for GLM estimation on disk','Store temporary files for GLM estimation in RAM'};
               set(TMFC_SET_P2, 'String', SET_STORAGE);
               tmfc.defaults.resmem =  false;
           end
           
           
           % SYNC: Maximum Memory Value
           % Check status of string in stat box -> if changed -> SWAP
           % details -> Change TMFC variable -> END
           DG4_STR = get(TMFC_SET_E1,'String');
           DG4 = eval(DG4_STR);
           if DG4 ~= 2^31
               set(TMFC_SET_E1, 'String', DG4_STR);
               tmfc.defaults.maxmem = DG4;
           end

           C_4 = (TMFC_SET_P4.String(TMFC_SET_P4.Value));
           if strcmp(C_4{1}, 'Seed-to-voxel and ROI-to-ROI')
               SET_SEED = {'Seed-to-voxel and ROI-to-ROI','ROI-to-ROI','Seed-to-voxel only'};
               set(TMFC_SET_P4, 'String', SET_SEED);
               tmfc.defaults.analysis =  1;

           elseif strcmp(C_4{1}, 'ROI-to-ROI')
               SET_SEED = {'ROI-to-ROI','Seed-to-voxel only','Seed-to-voxel and ROI-to-ROI'};
               set(TMFC_SET_P4, 'String', SET_SEED);
               tmfc.defaults.analysis =  2;
           elseif strcmp(C_4{1}, 'Seed-to-voxel only')
               SET_SEED = {'Seed-to-voxel only','Seed-to-voxel and ROI-to-ROI','ROI-to-ROI'};
               set(TMFC_SET_P4, 'String', SET_SEED);
               tmfc.defaults.analysis =  3;
           end
           
           if TMFC_SET_COPY.defaults.parallel == tmfc.defaults.parallel &&...
              TMFC_SET_COPY.defaults.maxmem == tmfc.defaults.maxmem &&...
              TMFC_SET_COPY.defaults.resmem == tmfc.defaults.resmem&&...
              TMFC_SET_COPY.defaults.analysis == tmfc.defaults.analysis 
               disp('Settings have not been changed');
           else
               
               disp('Settings have been updated');
               
           end
           close(TMFC_SET);
           
        end
    
end




%% ========================[ LSS Regression ]==============================

function LSS_REG(ButtonH, EventData, TMFC_MW)
    
   L_checker = evalin('base', 'tmfc');
   
   if isnan(L_checker.FIR.bins) & isnan(L_checker.FIR.window) 
       warning('Please complete FIR Regression before proceeding with LSS regression');
   elseif ~isnan(L_checker.FIR.bins) & ~isnan(L_checker.FIR.window) & isnan(L_checker.subjects(length(L_checker.subjects)).FIR)
       warning('Please complete the FIR Regression of all subjects before proceeding with LSS regression');
   elseif isempty(L_checker.LSS_after_FIR.conditions)
           tmfc_LSS_GUI(L_checker.subjects(1).path, 1);
           LSS_RUNNER(1);
   else
       LSS_Lindex = 0;
       LSS_flag = false;
       L_checker_2 = evalin('base', 'tmfc');
       LSS_len_sub = length(L_checker_2.subjects);
       dimension = size(L_checker_2.subjects(length(L_checker_2.subjects)).LSS_after_FIR);
       
       
       % conditions for Start, restart & continue
       
      for i = 1:LSS_len_sub

          if LSS_flag == true
               break;
          end

           for j = 1:dimension(1)

               if LSS_flag == true
                   break;
               end

               for k = 1:dimension(2)
                   if L_checker_2.subjects(i).LSS_after_FIR(j,k) == 0 | isnan(L_checker_2.subjects(i).LSS_after_FIR(j,k))
                       LSS_Lindex = [i,j,k];
                       LSS_flag = true;
                       break;
                   end
               end
           end
       end
       
       
       % condition 1
       if isnan(L_checker_2.subjects(1).LSS_after_FIR)
           LSS_RUNNER(1);
           
       % condition 2 - there maybe a logical error here
       % (LSS_Lindex == [LSS_len_sub, dimension(1), dimension(2)])
       elseif LSS_Lindex == 0 & LSS_flag == false
       %elseif L_checker_2.subjects(LSS_len_sub).LSS_after_FIR(dimension(1),dimension(2)) == 0 & isnan(L_checker_2.subjects(LSS_len_sub).LSS_after_FIR(1,1))
           
          tmfc_LSS_GUI(L_checker_2.subjects(1).path, 2);
          %uiwait();
          
          h77 = findobj('Tag', 'TMFC_MW');
          h77_V = getappdata(h77, 'RESTART_LSS');
          
          if h77_V == 1
              
              % ask for conditions again
              tmfc_LSS_GUI(L_checker_2.subjects(1).path, 1);
              
              h78 = findobj('Tag', 'TMFC_MW');
              h78_V = getappdata(h78, 'LSS_NO_COND');
              
              if h78_V ~= 1
                  LSS_RUNNER(1);
              end
          end
           
       else    
           % condition 3

           for i = 1:LSS_len_sub

              if LSS_flag == true
                   break;
              end

               for j = 1:dimension(1)

                   if LSS_flag == true
                       break;
                   end

                   for k = 1:dimension(2)
                       if L_checker_2.subjects(i).LSS_after_FIR(j,k) == 0 
                           LSS_Lindex = [i,j-1,k];
                           LSS_flag = true;
                           break;
                       end
                   end
               end
           end

           tmfc_LSS_GUI(L_checker_2.subjects(1).path, 3, LSS_Lindex(1));


           h54 = findobj('Tag', 'TMFC_MW');
           h54_V = getappdata(h54, 'CONTD_LSS');

           if h54_V == 1
              setappdata(h54_V, 'CONTD_LSS', 0);
              LSS_RUNNER(int32(LSS_Lindex(1)));

           elseif h54_V == 2
               setappdata(h54_V, 'CONTD_LSS', 0);
               tmfc_LSS_GUI(L_checker_2.subjects(1).path, 1);

               h53 = findobj('Tag', 'TMFC_MW');
               h53_V = getappdata(h53, 'LSS_NO_COND');

               if h53_V ~= 1
                   setappdata(h53, 'LSS_NO_COND', 0);
                   LSS_RUNNER(1);
               end
           else
               disp('LSS Regression not initiated');
               %warning('Something isnt right here, contact devs for LSS reg issue');
           end
       end     
   end    
           
end % Closing LSS regress

       % FIR Function the performs computation 
    function LSS_RUNNER(str_sub)
        
        % Freeze buttons on Main Window
        LSS_TMFC = evalin('base', 'tmfc');
        set([handles.SUB,handles.FIR_TR, handles.LSS_R, handles.LSS_RW, handles.BSC, handles.gPPI,handles.save_p, handles.open_p, handles.change_p, handles.settings,handles.BGFC],'Enable', 'off');
        
        % Actuator Function 
        try
            tmfc_LSS_after_FIR(LSS_TMFC, str_sub);
        end
        
        % Unfrezee action after completion of actuation
        set([handles.SUB,handles.FIR_TR, handles.LSS_R, handles.LSS_RW, handles.BSC, handles.gPPI,handles.save_p, handles.open_p, handles.change_p, handles.settings,handles.BGFC],'Enable', 'on');
        disp('LSS task regression completed');
    end
     
%% =====================[ Supporting Functions ]===========================

    % Failsafe function to pervent unintended freeze of TMFC Main Window
    try
        h1_UNFREZ = findobj('Tag','TMFC_MW');
        F1_data = guidata(h1_UNFREZ); 
        set([F1_data.SUB,F1_data.FIR_TR, F1_data.LSS_R, F1_data.LSS_RW, F1_data.BSC, F1_data.gPPI,F1_data.save_p, F1_data.open_p, F1_data.change_p, F1_data.settings,F1_data.BGFC],'Enable', 'on');
    end
            
                
    try % MAJOR CHANGE
        guidata(handles.TMFC_MW, handles);
    end


% This function performs Independent save & returns the status
% of saving. 0 - Success, 1 - Fail
function SAVER_STAT =  Saver(save_path)

    try 
        % Major change may affect the funcitoning of TMFC variable
        %EXPORT = evalin('base', 'tmfc');
        %save(save_path, 'EXPORT');
        %tmfc = evalin('base', 'tmfc');
        save(save_path, 'tmfc');
        SAVER_STAT = 1;
        % Save Success
    catch 
        SAVER_STAT = 0;
        % Save Fail 
    end
end

function evaluate_file(tmfc) % function to update the TMFC window after loading a tmfc project
    %BPL = evalin('base', 'tmfc');
    %BPL_LEN = length(BPL.subjects);
    set(handles.TMFC_MW_S1,'String', strcat(num2str(length(tmfc.subjects)), ' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
    
   
%     V_FIR = 0;
%     V_LSS_A_FIR = 0;
%     for i = 1:BPL_LEN
%         % checking status of FIR completion
%         if ~isnan(BPL.subjects(i).FIR)
%             V_FIR = V_FIR + 1 ;
%         end
%         % checkinf status of LSS completion
%         if ~isnan(BPL.subjects(i).LSS_after_FIR)
%             V_LSS_A_FIR = V_LSS_A_FIR + 1;
%         end
%         
%     end
    
%     if V_FIR ~= 0
%         set(handles.FIR_TR_stat,'ForegroundColor',[0.219, 0.341, 0.137]);
%         set(handles.FIR_TR_stat,'String',strcat(num2str(V_FIR), '/', num2str(BPL_LEN), ' done'));
%     else 
%         set(handles.FIR_TR_stat,'ForegroundColor',[0.773, 0.353, 0.067]);
%         set(handles.FIR_TR_stat,'String','Not done');
%     end
%     
%     if V_LSS_A_FIR ~= 0
%         set(handles.LSS_R_stat,'ForegroundColor',[0.219, 0.341, 0.137]);
%         set(handles.LSS_R_stat,'String',strcat(num2str(V_LSS_A_FIR), '/', num2str(BPL_LEN), ' done'));
%     else 
%         set(handles.LSS_R_stat,'ForegroundColor',[0.773, 0.353, 0.067]);
%         set(handles.LSS_R_stat,'String','Not done');
%     end
%     
%     switch BPL.defaults.parallel
%         case 1
%             COMPUTING = {'Parallel computing','Sequential computing',};           
%         case 0 
%            COMPUTING = {'Sequential computing','Parallel computing'};
%            
%     end
%     
%     switch BPL.defaults.resmem
%         case true
%             STORAGE = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'}; 
%         case false 
%             STORAGE = {'Store temporary files for GLM estimation on disk','Store temporary files for GLM estimation in RAM'};
%            
%     end
%     
%     
%     
%     V_LSS = 0;
    %for i = 1:BPL_LEN
    %    if ~isnan(BPL.subjects(i).LSS_residual_ts)
    %    V_LSS = V_LSS + 1 ;
    %    end
    %end
    
    %if V_LSS ~= 0
    %    set(handles.LSS_R_stat,'ForegroundColor',[0.219, 0.341, 0.137]);
    %    set(handles.LSS_R_stat,'String',strcat(num2str(V_LSS), '/', num2str(BPL_LEN), ' done'));
    %end
    
    
    %if BPL.ROIs(1).paths ~= ""
    %    set(handles.ROI_stat,'ForegroundColor',[0.219, 0.341, 0.137]);
    %    set(handles.ROI_stat,'String',length(BPL.ROIs)+' selected');
    %end
    
end

%% Freeze Window
function MW_Freeze(STATE)

    switch(STATE)
        case 0 
            STATE = 'on';
        case 1
            STATE = 'off';
    end
    set([handles.TMFC_MW_B1, handles.TMFC_MW_B2, handles.TMFC_MW_B3, handles.TMFC_MW_B4,...
                handles.TMFC_MW_B5a, handles.TMFC_MW_B5b, handles.TMFC_MW_B6, handles.TMFC_MW_B7,...
                handles.TMFC_MW_B8, handles.TMFC_MW_B9, handles.TMFC_MW_B10, handles.TMFC_MW_B11,...
                handles.TMFC_MW_B12,handles.TMFC_MW_B13a,handles.TMFC_MW_B13b,handles.TMFC_MW_B14a...
                handles.TMFC_MW_B14b], 'Enable', STATE);

     end
          

end  

%%
function TMFC_SS_select_proj_path(S)
    TMFC_SS_PP = figure('Name', 'Select project paths', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.40 0.20 0.10],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @OKAY, 'Tag', 'Proj_path');
    PP_details = {'Next, select the project path where all results and temporary files will be stored'};
    TMFC_SS_PP_S1 = uicontrol(TMFC_SS_PP,'Style','text','String',strcat(num2str(S), ' subjects selected'),'Units', 'normalized', 'Position',[0.35 0.70 0.30 0.17],'backgroundcolor','w','fontunits','normalized','fontSize', 0.55,'ForegroundColor',[0.219, 0.341, 0.137]);
    TMFC_SS_PP_S2 = uicontrol(TMFC_SS_PP,'Style','text','String',PP_details,'Units', 'normalized', 'Position',[0.05 0.38 0.90 0.30],'backgroundcolor','w','fontunits','normalized','fontSize', 0.34);
    OK = uicontrol(TMFC_SS_PP,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.4 0.14 0.2 0.2]);
    set(OK, 'callback', @OKAY);
    
    function OKAY(~,~)
        delete(TMFC_SS_PP);
    end
    uiwait();
end

%%

function [STATUS] = TMFC_FIR_CON_GUI(INDEX)

    % STATUS = 1 - restart FIR 
    % STATUS = 0 - continue FIR
    % STATUS = -1 - no action

    TMFC_FIR_CONT = figure('Name', 'FIR task regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.20 0.18],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Contd_FIR','CloseRequestFcn', @CANCEL); %X Y W H

    TMFC_FIR_CONT_S1 = uicontrol(TMFC_FIR_CONT,'Style','text','String', 'Start FIR task regression from','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38, 'Position',[0.10 0.55 0.80 0.260]);
    TMFC_FIR_CONT_S2 = uicontrol(TMFC_FIR_CONT,'Style','text','String', strcat('subject №',num2str(INDEX),'?'), 'Units','normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38, 'Position',[0.10 0.40 0.80 0.260]);

    TMFC_FIR_CONT_YES = uicontrol(TMFC_FIR_CONT,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.28, 'Position',[0.12 0.15 0.320 0.270]);
    TMFC_FIR_CONT_RESTART = uicontrol(TMFC_FIR_CONT,'Style','pushbutton', 'String', '<html>&#160 No, start from <br>the first subject','Units', 'normalized','fontunits','normalized', 'fontSize', 0.28,'Position',[0.56 0.15 0.320 0.270]);

    set([TMFC_FIR_CONT_S1,TMFC_FIR_CONT_S2],'backgroundcolor',get(TMFC_FIR_CONT,'color'));
    set(TMFC_FIR_CONT_YES, 'callback', @CONTINUE);
    set(TMFC_FIR_CONT_RESTART, 'callback', @RESTART);

    function CANCEL(~,~)
        delete(TMFC_FIR_CONT);
        STATUS = -1;
    end
    
    % Function to set status in MAIN_WINDOW appdata (To continue from
    % last processed subject) 
    function CONTINUE(~,~)
        STATUS = 0;
        delete(TMFC_FIR_CONT);
    end

    % Function to set status in MAIN_WINDOW appdata (To Restart from
    % the first subject)
    function RESTART(~,~)
        STATUS = 1;
        delete(TMFC_FIR_CONT);
    end

    
    uiwait();
end

function [STATUS] = TMFC_FIR_RES_GUI(~,~)

    % STATUS = 1 - restart FIR 
    % STATUS = 0 - dont restart FIR 

    TMFC_FIR_RES = figure('Name', 'FIR task regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.16 0.14],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Restart_FIR','CloseRequestFcn', @CANCEL); %X Y W H

    TMFC_FIR_RES_S1 = uicontrol(TMFC_FIR_RES,'Style','text','String', {'Recompute FIR task','regression for all subjects.?'},'Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38, 'Position', [0.10 0.55 0.80 0.260]);
    TMFC_FIR_RES_OK = uicontrol(TMFC_FIR_RES,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.48, 'Position', [0.14 0.25 0.320 0.170]);
    TMFC_FIR_RES_CL = uicontrol(TMFC_FIR_RES,'Style','pushbutton', 'String', 'Cancel','Units', 'normalized','fontunits','normalized', 'fontSize', 0.48,'Position',[0.52 0.25 0.320 0.170]);

    set(TMFC_FIR_RES_S1,'backgroundcolor',get(TMFC_FIR_RES,'color'));
    set(TMFC_FIR_RES_CL, 'callback', @CANCEL);
    set(TMFC_FIR_RES_OK, 'callback', @RESTART);

    % Function to close the Window
    function CANCEL(~,~)
        delete(TMFC_FIR_RES);
        STATUS = 0;
    end

    % Function to Restart FIR Regression
    function RESTART(~,~)
        STATUS = 1;
        delete(TMFC_FIR_RES);
    end
    uiwait();
end

function [win, bin] = TMFC_FIR_BW_GUI(~,~)

    TMFC_FIR_BW = figure('Name', 'FIR task regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.22 0.18],'Resize','off',...
        'MenuBar', 'none', 'ToolBar', 'none','Tag','FIR_REG_NUM', 'WindowStyle','modal','CloseRequestFcn', @TMFC_FIR_BW_stable_Exit); 
    set(gcf,'color','w');
    
    TMFC_FIR_BW_S1 = uicontrol(TMFC_FIR_BW,'Style','text','String', 'Enter FIR window length (in seconds):','Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40, 'Position',[0.08 0.62 0.65 0.200]);
    TMFC_FIR_BW_S2 = uicontrol(TMFC_FIR_BW,'Style','text','String', 'Enter the number of FIR time bins:','Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40,'Position',[0.08 0.37 0.65 0.200]);
    TMFC_FIR_BW_E1 = uicontrol(TMFC_FIR_BW,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.67 0.185 0.170]);%,'InputType', 'digits');
    TMFC_FIR_BW_E2 = uicontrol(TMFC_FIR_BW,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.42 0.185 0.170]);
    TMFC_FIR_BW_OK = uicontrol(TMFC_FIR_BW,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.21 0.13 0.230 0.170]);
    TMFC_FIR_BW_HELP = uicontrol(TMFC_FIR_BW,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.52 0.13 0.230 0.170]);

    set(TMFC_FIR_BW_S1,'backgroundcolor',get(TMFC_FIR_BW,'color'));
    set(TMFC_FIR_BW_S2,'backgroundcolor',get(TMFC_FIR_BW,'color'));
    set(TMFC_FIR_BW_OK, 'callback', @TMFC_FIR_BW_EXTRACT);
    set(TMFC_FIR_BW_HELP, 'callback', @TMFC_FIR_BW_HELP_POP);

   
    function TMFC_FIR_BW_stable_Exit(~,~)
       %h76 = findobj('Tag', 'MAIN_WINDOW');
       %setappdata(h76, 'NO_COND', 1); 
       win = NaN; 
       bin = NaN; 
       delete(TMFC_FIR_BW);
    end

    % Generates the HELP WINDOW within the GUI 
    function TMFC_FIR_BW_HELP_POP(~,~)

            TMFC_FIR_BW_HELPWW = figure('Name', 'FIR task regression: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.62 0.26 0.22 0.48],'Resize','off','MenuBar', 'none','ToolBar', 'none');
            set(gcf,'color','w');

            TMFC_FIR_BW_DETAILS = {'Finite impulse response (FIR) task regression are used to remove co-activations from BOLD time-series.','',...
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
                TMFC_FIR_BW_DETAILS_2 = {'Number of FIR bins = FIR window length/TR'};

            TMFC_FIR_BW_LS2_DTS_1 = uicontrol(TMFC_FIR_BW_HELPWW,'Style','text','String', TMFC_FIR_BW_DETAILS,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.035, 'Position',[0.06 0.16 0.885 0.800]);
            TMFC_FIR_BW_LS2_DTS_2 = uicontrol(TMFC_FIR_BW_HELPWW,'Style','text','String', TMFC_FIR_BW_DETAILS_2,'Units', 'normalized', 'HorizontalAlignment', 'Center','fontunits','normalized', 'fontSize', 0.30, 'Position',[0.06 0.10 0.885 0.10]);
            TMFC_FIR_BW_LS2_OK = uicontrol(TMFC_FIR_BW_HELPWW,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35, 'Position',[0.39 0.04 0.240 0.070]);

            set(TMFC_FIR_BW_LS2_DTS_1,'backgroundcolor',get(TMFC_FIR_BW_HELPWW,'color'));
            set(TMFC_FIR_BW_LS2_DTS_2,'backgroundcolor',get(TMFC_FIR_BW_HELPWW,'color'));
            set(TMFC_FIR_BW_LS2_OK, 'callback', @TMFC_FIR_BW_CLOSE_LS2_OK);

            function TMFC_FIR_BW_CLOSE_LS2_OK(~,~)
                close(TMFC_FIR_BW_HELPWW);
            end
    end



    % Function to extract the entered number from the user
    function TMFC_FIR_BW_EXTRACT(~,~)

       Window = str2double(get(TMFC_FIR_BW_E1, 'String'));
       bins = str2double(get(TMFC_FIR_BW_E2, 'String'));

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
           %h76_b = findobj('Tag', 'MAIN_WINDOW');
           %setappdata(h76_b, 'NO_COND', 0); 
           delete(TMFC_FIR_BW);
       end

    end
    uiwait();
end