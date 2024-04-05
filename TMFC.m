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
%   tmfc.subjects.FIR:            - 1 or 0 (completed or not)
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
%   tmfc.ROI_set(i).gPPI.conditions            - Conditions of interest for gPPI and
%                                     gPPI-FIR regression
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

if isempty(findobj('Tag', 'TMFC_GUI')) == 1  
    
    % Set up TMFC structure
    tmfc.defaults.parallel = 0;      
    tmfc.defaults.maxmem = 2^32;
    tmfc.defaults.resmem = true;
    tmfc.defaults.analysis = 1;
    
    % Main TMFC Window
    handles.TMFC_GUI = figure('Name','TMFC Toolbox','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'norm', 'Position', [0.115 0.0875 0.250 0.850], 'color', 'w', 'Tag', 'TMFC_GUI');
    
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
    handles.TMFC_GUI_B7 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS', 'Units', 'normalized', 'Position', [0.06 0.52 0.88 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B8 = uicontrol('Style', 'pushbutton', 'String', 'FIR task regression', 'Units', 'normalized', 'Position', [0.06 0.44 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B9 = uicontrol('Style', 'pushbutton', 'String', 'Background connectivity', 'Units', 'normalized', 'Position', [0.06 0.38 0.88 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B10 = uicontrol('Style', 'pushbutton', 'String', 'LSS GLM after FIR', 'Units', 'normalized', 'Position', [0.06 0.30 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B11 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS after FIR', 'Units', 'normalized', 'Position', [0.06 0.24 0.88 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B12 = uicontrol('Style', 'pushbutton', 'String', 'Results', 'Units', 'normalized', 'Position', [0.06 0.16 0.88 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B13a = uicontrol('Style', 'pushbutton', 'String', 'Open project', 'Units', 'normalized', 'Position', [0.06 0.08 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B13b = uicontrol('Style', 'pushbutton', 'String', 'Save project', 'Units', 'normalized', 'Position', [0.54 0.08 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B14a = uicontrol('Style', 'pushbutton', 'String', 'Change paths', 'Units', 'normalized', 'Position', [0.06 0.02 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B14b = uicontrol('Style', 'pushbutton', 'String', 'Settings', 'Units', 'normalized', 'Position', [0.54 0.02 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    
    % String counters
    % green = [0.219, 0.341, 0.137]
    % orange = [0.773, 0.353, 0.067]
    handles.TMFC_GUI_S1 = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', [1, 0, 0], 'Units', 'norm', 'Position',[0.555 0.926 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S2 = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', [1, 0, 0], 'Units', 'norm', 'Position',[0.555 0.867 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S3 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.787 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S4 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.727 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S6 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.587 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S8 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.447 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    handles.TMFC_GUI_S10 = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'norm', 'Position',[0.555 0.307 0.38 0.03],'FontUnits','normalized','FontSize',0.56,'backgroundcolor', 'w');
    
    % CallBack functions corresponding to each button
    set(handles.TMFC_GUI, 'CloseRequestFcn', {@close_GUI, handles.TMFC_GUI}); 
    set(handles.TMFC_GUI_B1, 'callback', {@select_subjects, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B2, 'callback', {@ROI_sel, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B3, 'callback', {@VOI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B4, 'callback', {@PPI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B5a, 'callback', {@gPPI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B5b, 'callback', {@gPPI_FIR, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B6, 'callback', {@LSS_GLM, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B8, 'callback', {@FIR, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B10, 'callback', {@LSS_FIR, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B12, 'callback', {@reset, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B13a, 'callback', {@load_project, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B14a, 'callback', {@CP_GUI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B14b, 'callback', {@tmfc_settings, handles.TMFC_GUI});
       
    % BSC
    % BGFC
    % BSC_after_FIR
    
    % Results

    % save_project
    % change_paths

    %

    set(handles.TMFC_GUI_B13b, 'callback', {@tempsave, handles.TMFC_GUI});

else
    figure(findobj('Tag', 'TMFC_GUI')); 
    warning('TMFC toolbox is already running');    
end

%% ==============================[ Reset ]=============REMOVE later========
function reset(ButtonH, EventData, TMFC_GUI)
    
    tmfc = struct;
    tmfc.defaults.parallel = 0;      
    tmfc.defaults.maxmem = 2^32;
    tmfc.defaults.resmem = true;
    tmfc.defaults.analysis = 1;
    
    set(handles.TMFC_GUI_S1, 'String', 'Not selected','ForegroundColor', [1, 0, 0]);
    set(handles.TMFC_GUI_S2, 'String', 'Not selected','ForegroundColor', [1, 0, 0]);
    set(handles.TMFC_GUI_S3, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
    set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
    set(handles.TMFC_GUI_S6, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
    set(handles.TMFC_GUI_S8, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
    set(handles.TMFC_GUI_S10, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
    
    disp('tmfc reset');
    disp(tmfc);
end

%% ===========================[ TMP Save ]=============REMOVE later========
function tempsave(ButtonH, EventData, TMFC_GUI)
    assignin('base', 'tmfc', tmfc);
end
%% ============================= [ gPPI FIR ] =============================
function gPPI_FIR(ButtonH, EventData, TMFC_GUI)
            
    try 
        cd(tmfc.project_path);    
        
        MW_Freeze(1);
        V_gPPI_FIR = 0;
        try
        %% Check gPPI FIR
        R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
        for subi = 1:length(tmfc.subjects)
            for k = 1:R
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR','GLM_batches',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name, ...
                ['Subject_' num2str(subi,'%04.f') '_gPPI_FIR_GLM.mat']), 'file')
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI_FIR = 1;
                else            
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI_FIR = 0;
                end
            end
        end
        clear R
        end
        try
            SZ_tmfc = size(tmfc.subjects);
            V_gPPI_FIR = 0;
            for i = 1:SZ_tmfc(2)
                % checking status of gPPI_FIR completion
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR == 0
                    V_gPPI_FIR = i ;
                    break;
                end
            end
        end
        
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
            if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
            
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).PPI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).PPI == 1
                    
                    if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions) && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).gPPI_FIR == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).gPPI_FIR == 0 && ~isfield(tmfc, 'gPPI_FIR') 
                            
                            [tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.window,tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.bins] = TMFC_BW_GUI(0);
                            
                            if ~isnan(tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.window) || ~isnan(tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.bins)
                                [sub_check, contrasts] = tmfc_gPPI_FIR(tmfc,tmfc.ROI_set_number, 1);
                                for i = 1:length(contrasts)
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(i).title = contrasts(i).title;
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(i).weights = contrasts(i).weights;
                                end
                                for i=1:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR = sub_check(i);
                                end
                                disp('gPPI FIR computation completed');
                            end
                        
                    else
                        
                        if isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI, 'conditions') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).gPPI_FIR == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).gPPI_FIR == 1
                             disp('Continue to select contrasts');
                             tmfc = tmfc_specify_contrasts_GUI(tmfc, tmfc.ROI_set_number, 2);
                        else
                            STATUS = TMFC_CON_GUI(V_gPPI_FIR, 7);
                            if STATUS == 0
                                sub_check = tmfc_gPPI_FIR(tmfc,tmfc.ROI_set_number, V_gPPI_FIR);
                                for i=V_gPPI_FIR:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR = sub_check(i);
                                end
                                disp('gPPI FIR computation completed');
                            else
                                disp('gPPI FIR computation not initiated');
                            end
                             
                        end
                        
                    end
                
                
                    
                    
                else
                    warning('Please complete PPI computation to proceed with gPPI FIR computation');
                end
                
            else
                warning('Please select ROIs & compute VOIs to continue with PPI computation');
            end
            
        else
           warning('Please select subjects & compute PPIs to continue with gPPI computation');
        end
        
        
        
        MW_Freeze(0);
    catch
        warning('Please select subjects & compute PPIs to perform gPPI computation');
    end
    
    
    
    
end
%% =============================== [ gPPI ] ===============================
function gPPI(ButtonH, EventData, TMFC_GUI)
            
    try 
        cd(tmfc.project_path);    
        
        MW_Freeze(1);
        % check gPPI 
        try
        V_gPPI = 0;
        R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
        for subi = 1:length(tmfc.subjects)
            for k = 1:R
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI','GLM_batches',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name, ...
                        ['Subject_' num2str(subi,'%04.f') '_gPPI_GLM.mat']), 'file')
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI = 1;
                else            
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI = 0;
                end
            end
        end
        clear R
        end
        try
            SZ_tmfc = size(tmfc.subjects);
            V_gPPI = 0;
            for i = 1:SZ_tmfc(2)
                % checking status of gPPI completion
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI == 0
                    V_gPPI = i ;
                    break;
                end
            end
        end
        
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
            if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
            
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).PPI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).PPI == 1
                    
                    
                    if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions) && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).gPPI == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).gPPI == 0
                        
                        [sub_check, contrasts] = tmfc_gPPI(tmfc,tmfc.ROI_set_number, 1);
                        % assigning contrasts to tmfc
                        for i = 1:length(contrasts)
                            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(i).title = contrasts(i).title;
                            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(i).weights = contrasts(i).weights;
                        end
                        for i=1:length(tmfc.subjects)
                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI = sub_check(i);
                        end
                        disp('gPPI computation completed');
                    else
                        
                        if isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI, 'conditions') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).gPPI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).gPPI == 1
                             disp('Continue to select contrasts');
                             tmfc = tmfc_specify_contrasts_GUI(tmfc, tmfc.ROI_set_number, 1);
                        else
                            STATUS = TMFC_CON_GUI(V_gPPI, 6);
                            if STATUS == 0
                                sub_check = tmfc_gPPI(tmfc,tmfc.ROI_set_number, V_gPPI);
                                for i=V_gPPI:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI = sub_check(i);
                                end
                                disp('gPPI computation completed');
                            else
                                disp('gPPI computation not initiated');
                            end
                             
                        end
                        
                    end
                
                
                    
                    
                else
                    warning('Please complete PPI computation to proceed with gPPI computation');
                end
                
            else
                warning('Please select ROIs & compute VOIs to continue with PPI computation');
            end
            
        else
           warning('Please select subjects & compute PPIs to continue with gPPI computation');
        end
        
        
        
        MW_Freeze(0);
    catch
        warning('Please select subjects & compute PPIs to perform gPPI computation');
    end
    
    
    
    
end

%% =============================== [ PPIs ] ===============================
function PPI(ButtonH, EventData, TMFC_GUI)
    
    try
        cd(tmfc.project_path);       
        MW_Freeze(1);
        V_PPI = 0;
        try
        cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
        sess = []; sess_num = []; N_sess = [];
        for i = 1:length(cond_list)
            sess(i) = cond_list(i).sess;
        end
        sess_num = unique(sess);
        N_sess = length(sess_num);
        R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);

        for subi = 1:length(tmfc.subjects)
            SPM = load(tmfc.subjects(subi).path);
            for k = 1:R
                for j = 1:N_sess
                    if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs',['Subject_' num2str(subi,'%04.f')], ...
                                ['PPI_[' regexprep(tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name,' ','_') ...
                                ']_[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                                regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') '].mat']), 'file')
                        check(j) = 1;
                    else
                        check(j) = 0;
                    end
                end
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).PPI = double(~any(check==0));
                clear check 
            end
            clear SPM
        end
        clear cond_list sess sess_num N_sess R
        end
        
        try
            SZ_tmfc = size(tmfc.subjects);
            V_PPI = 0;
            for i = 1:SZ_tmfc(2)
                % checking status of VOI completion
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI == 0
                    V_PPI = i ;
                    break;
                end
            end
            if V_PPI == 0
                set(handles.TMFC_GUI_S4,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_FIR == 1
                set(handles.TMFC_GUI_S4,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S4,'String', strcat(num2str(V_PPI-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
      
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
             if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
                
                 if tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).VOI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).VOI == 1
                     disp('Initiating PPIs computation');
                     
                     if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions) && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).PPI == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).PPI == 0
                         
                        sub_check = tmfc_PPI(tmfc,tmfc.ROI_set_number, 1);
                        for i=1:length(tmfc.subjects)
                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = sub_check(i);
                        end
                        disp('PPI computation completed');
                     else
                         
                         if isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).PPI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).PPI == 1
                             PPI_OKAY();
                             disp('Recompute VOIs to change conditions');
                            %disp('restart');
%                             STATUS = TMFC_RES_GUI(5);
%                             if STATUS == 1
%                                 sub_check = tmfc_PPI(tmfc,tmfc.ROI_set_number, 1);
%                                 for i=1:length(tmfc.subjects)
%                                     tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = sub_check(i);
%                                 end                                
%                             end
                        else
                            % Continue case
                            STATUS = TMFC_CON_GUI(V_PPI, 5);
                            if STATUS == 0
                                sub_check = tmfc_PPI(tmfc,tmfc.ROI_set_number, V_PPI);
                                for i=V_PPI:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = sub_check(i);
                                end
                                disp('PPI computation completed');
                            else
                                warning('PPI computation not initiated');
                            end

                        end
                         
                     end
                 
                 
                     
                 else
                     warning('Please complete VOI computation to proceed with PPI computation');
                     
                 end

             else
                 
             warning('Please select ROIs & compute VOIs to continue with PPI computation');
             end
             
            
        else
            warning('Please select subjects & compute VOIs to continue with PPI computation');
        end


        
        MW_Freeze(0);
        
    catch 
        warning('Please select subjects & compute VOIs to perform PPI computation');
    end   
    
end


%% ================================[ VOIs ]================================
function VOI(ButtonH, EventData, TMFC_GUI)
    
     try 
        cd(tmfc.project_path);       
        
        MW_Freeze(1);
        
        %% Check VOI
        V_VOI = 0;
        try
        cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
        sess = []; sess_num = []; N_sess = [];
        for i = 1:length(cond_list)
            sess(i) = cond_list(i).sess;
        end
        sess_num = unique(sess);
        N_sess = length(sess_num);
        R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);

        for subi = 1:length(tmfc.subjects)    
            for k = 1:R
                for j = 1:N_sess
                    if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs',['Subject_' num2str(subi,'%04.f')], ...
                            ['VOI_' tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name '_' num2str(j) '.mat']), 'file')
                        check(j) = 1;
                    else
                        check(j) = 0;
                    end
                end
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).VOI = double(~any(check==0));
                clear check 
            end
        end
        clear cond_list sess sess_num N_sess R
        end
        
        try
            SZ_tmfc = size(tmfc.subjects);
            V_VOI = 0;
            for i = 1:SZ_tmfc(2)
                % checking status of VOI completion
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI == 0
                    V_VOI = i ;
                    break;
                end
            end
            
            if V_VOI == 0
                set(handles.TMFC_GUI_S3,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_FIR == 1
                set(handles.TMFC_GUI_S3,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S3,'String', strcat(num2str(V_VOI-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
            
        end
        
        % Computation
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
             if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
                 disp('Initiating VOI computation');
            if ~isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI')
                % first time execution 
                
                % selection gPPI conditions
                tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = tmfc_gPPI_GUI(tmfc.subjects(1).path);
                
                if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions) && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).VOI == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).VOI == 0
                    tmfc = reset_VPGPPI(tmfc, 3);
                    sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, 1);
                    for i=1:length(tmfc.subjects)
                        tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                    end
                    disp('VOI computation completed');
                
                end
                
            elseif isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).VOI == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).VOI == 0
                
                tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = tmfc_gPPI_GUI(tmfc.subjects(1).path);
                tmfc = reset_VPGPPI(tmfc, 3);
                if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions)
                    sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, 1);
                    for i=1:length(tmfc.subjects)
                        tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                    end
                    disp('VOI computation completed');
                end
            else
                
                if isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI, 'conditions') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).VOI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).VOI == 1
                    %disp('restart');
                    STATUS = TMFC_RES_GUI(4);
                    if STATUS == 1
                        verify_old = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
                        tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = tmfc_gPPI_GUI(tmfc.subjects(1).path);
                        if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions)
                            tmfc = reset_VPGPPI(tmfc, 3);
                            try
                                % VOI
                                rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs'),'s');                                
                                % PPIs
                                if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs'))
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs'),'s');
                                end
                                % gPPI
                                if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI'))
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI'),'s');
                                end
                                % gPPI-FIR
                                if fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR')
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR'),'s');
                                end
                                disp('Deleting old files');
                            end
                            sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, 1);
                            for i=1:length(tmfc.subjects)
                                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                            end
                            disp('VOI computation completed');
                        else
                            tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = verify_old;                            
                        end
                    end
                else
                    % Continue case
                    %V_VOI
                    STATUS = TMFC_CON_GUI(V_VOI, 4);
                    if STATUS == 0
                        sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, V_VOI);
                        for i=V_VOI:length(tmfc.subjects)
                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                        end
                        disp('VOI computation completed');
                        
                    elseif STATUS == 1
                        verify_old = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
                        tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = tmfc_gPPI_GUI(tmfc.subjects(1).path);
                        if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions)
                            tmfc = reset_VPGPPI(tmfc, 2);
                            try
                                rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs'),'s');                             
                                % PPIs
                                if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs'))
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs'),'s');
                                end
                                % gPPI
                                if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI'))
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI'),'s');
                                end
                                % gPPI-FIR
                                if fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR')
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR'),'s');
                                end
                                disp('Deleting old files');
                            end
                            sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, 1);
                            for i=1:length(tmfc.subjects)
                                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                            end
                            disp('VOI computation completed');
                        else
                            tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = verify_old;                            
                        end
                    else
                        warning('VOI computation not initiated');
                    end
 
                end
                
            end
            else
            
            warning('Please select ROIs to continue with VOI computation');
            end
            
        else
            warning('Please select subjects to continue with VOI computation');
        end
               
        MW_Freeze(0);
        
        
     catch
         warning('Please select subjects & project path to perform VOI computation');
     end
end

%% ========================[ Select Subjects ]=============================
% Select subjects and check SPM.mat files
function select_subjects(ButtonH, EventData, TMFC_GUI)
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
            set(handles.TMFC_GUI_S1,'String', strcat(num2str(L_paths(1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
            tmfc.project_path = project_path;
            MW_Freeze(0);
        end
    end
   try
    cd(tmfc.project_path);  
   end
   
   tmfc = major_reset(tmfc);
   
   disp(tmfc);
end


%% ========================[ FIR Regression ]==============================

function FIR(ButtonH, EventData, TMFC_GUI)
    
    try
        cd(tmfc.project_path);           

    % Freezing the Main window
    MW_Freeze(1);
    
    try
               % track
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
            for i = 1:SZ_tmfc(2)
                % checking status of FIR completion
                if tmfc.subjects(i).FIR == 0
                    V_FIR = i ;
                    break;
                end
            end

            if V_FIR == 0
                set(handles.TMFC_GUI_S8,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_FIR == 1
                set(handles.TMFC_GUI_S8,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S8,'String', strcat(num2str(V_FIR-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
        pause(0.1); 
    end
    
    
    
    disp('Initiating FIR regression');
    if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
        % Checking if subjects has been selected
        
        if ~isfield(tmfc, 'FIR') 
        % Checking if FIR has not been executed before
        
            [tmfc.FIR.window,tmfc.FIR.bins] = TMFC_BW_GUI(0);
            % Eneter bins & windows
            
             if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)
                % Initial execuction of FIR regression
                sub_check = tmfc_FIR(tmfc, 1);
                for i=1:length(tmfc.subjects)
                    tmfc.subjects(i).FIR = sub_check(i);
                end
             end
             
        elseif isfield(tmfc, 'FIR') && tmfc.subjects(1).FIR == 0 %~isfield(tmfc.subjects, 'FIR')
            
            % Exeuction if CTLR + C is pressed 
            % Can add code for exuection from last complied .mat file
            [tmfc.FIR.window,tmfc.FIR.bins] = TMFC_BW_GUI(0);
            
             if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)
                sub_check = tmfc_FIR(tmfc, 1);
                for i=1:length(tmfc.subjects) % change to len(new_run)
                    tmfc.subjects(i).FIR = sub_check(i);
                end
             end
            
        else
            
            % Other cases 'Restart' and 'Continue'
            if ~isnan(tmfc.FIR.window) && ~isnan(tmfc.FIR.bins) 
                
                if tmfc.subjects(length(tmfc.subjects)).FIR == 1                  
                    
                    % Restart case
                    STATUS = TMFC_RES_GUI(1);
                    if STATUS == 1
                        [tmfc.FIR.window,tmfc.FIR.bins] = TMFC_BW_GUI(0);
                        if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)                            
                            disp('Restarting FIR regression');
                            try
                                rmdir(fullfile(tmfc.project_path,'FIR_regression'),'s');
                                if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'))
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'),'s');
                                end
                                disp('Deleting old files');
                            end
                            sub_check = tmfc_FIR(tmfc, 1);
                            for i=1:length(tmfc.subjects)
                                tmfc.subjects(i).FIR = sub_check(i);
                            end
                        end
                    end
                    
                    
                else
                    % Continue case
                    for i=1:length(tmfc.subjects)
                        FIR_index = [];
                        if tmfc.subjects(i).FIR == 0
                            FIR_index = i;
                            break;
                        end
                    end
                    
                    FIR_dec = TMFC_CON_GUI(FIR_index,1);
                    
                    if FIR_dec == 0
                        con_run = tmfc_FIR(tmfc,FIR_index);
                        for i=FIR_index:length(tmfc.subjects)
                            tmfc.subjects(i).FIR = con_run(i);
                        end
                    elseif FIR_dec == 1
                        [tmfc.FIR.window,tmfc.FIR.bins] = TMFC_BW_GUI(0);
                        if ~isnan(tmfc.FIR.window) || ~isnan(tmfc.FIR.bins)   
                            try
                                rmdir(fullfile(tmfc.project_path,'FIR_regression'),'s');
                                if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'))
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'),'s');
                                end
                                disp('Deleting old files');
                            end
                            con_run = tmfc_FIR(tmfc,1);
                            for i=1:length(tmfc.subjects)
                                tmfc.subjects(i).FIR = con_run(i);
                            end
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
    
    
        MW_Freeze(0);
    catch
       warning('Please select subjects & project path to perform FIR regression');
    end 
    
    end % Closing FIR Regress Function
       

%% =============================[ Close ]==================================
 
% Function to peform Save & Exit from TMFC function. This function is 
% linked to the close button on the top right handside of the Window

% NEED TO ADD CONDITION WHEN TMFC VARIABLE IS DELETED BUT TRY TO EXIT
% DELETE TMFC in WS-> Close TMFC -> DO NOT ASK TO SAVE (Give warning)
function close_GUI(ButtonH, EventData, TMFC_GUI) 
    
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
        delete(handles.TMFC_GUI);
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
            delete(handles.TMFC_GUI);
            disp('Goodbye!');
        end
    end
end
    
%% ==========================[ Save Project ]==============================

% Function to perform Saving of TMFC variable from workspace to
% individual .m file in user desired location

function SAVE_STAT = SAVE_PROJ(ButtonH, EventData, TMFC_GUI)
   
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

%% ==========================[ Load Project ]==============================
function load_project(ButtonH, EventData, TMFC_GUI)

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
        tmfc = evaluate_file(tmfc);

    else
        warning('No file selected');
    end

end   

%% ==========================[ Change Paths ]==============================
function CP_GUI(ButtonH, EventData, TMFC_GUI)
    
    disp('Select subjects whose paths are to be changed');
    
        D = tmfc_select_subjects_GUI(0);  
        
        if ~isempty(D)
            tmfc_change_paths_GUI(D);  
        else
            disp('No subject files selected for path change');
        end
    
end

%% ============================[ Settings ]================================
SET_COMPUTING = {'Sequential computing', 'Parallel computing'};
SET_STORAGE = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
SET_SEED = {'Seed-to-voxel and ROI-to-ROI','ROI-to-ROI','Seed-to-voxel only'};

function tmfc_settings(ButtonH, EventData, TMFC_GUI)
        
    % Create the Main figure for settings Window
    TMFC_SET = figure('Name', 'TMFC Toolbox','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'norm', 'Position', [0.415 0.0875 0.250 0.850], 'color', 'w', 'Tag', 'TMFC_GUI_Settings','resize', 'off','WindowStyle','modal');
    
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
       if DG4 > 2^30
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

%% ============================[ LSS GLM ]=================================
function LSS_GLM(ButtonH, EventData, TMFC_GUI)

    try
        cd(tmfc.project_path);           
    

    
    % Freezing the Main window
    MW_Freeze(1);
    L_break = 0;
    V_LSS = 0;
     try
     
     % code-----
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
            socket = 0;
            if SZC_tmfc(2) == 1 
                socket = tmfc.LSS.conditions.number;
            end
            for i = 1:SZ_tmfc(2)
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
                                    if ~socket==0
                                        % if there is only one condition
                                        if any(tmfc.subjects(i).LSS.session(j).condition(socket).trials == 0)
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
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_LSS == 1
                set(handles.TMFC_GUI_S6,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(V_LSS-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
        pause(0.1); 
     end
    
    % Runner code
    if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
        % Checking if subjects has been selected
        disp('Initiating LSS GLM');
        if ~isfield(tmfc, 'LSS') 
        % First time exeuction

            % select conditions    
            tmfc.LSS.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
            
            if isstruct(tmfc.LSS.conditions) && ~isfield(tmfc.subjects, 'LSS')
               
                sub_check = tmfc_LSS(tmfc,1);
                for i=1:length(tmfc.subjects)
                    tmfc.subjects(i).LSS = sub_check(i);
                end
                
            end
            
        elseif isfield(tmfc.LSS, 'conditions') && ~isfield(tmfc.subjects, 'LSS')
            % Execution if CTLR + C is pressed 
            % Can add code for exuection from last complied .mat file
            
            tmfc.LSS.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
            
            if isstruct(tmfc.LSS.conditions)
               
                sub_check = tmfc_LSS(tmfc,1);
                for i=1:length(tmfc.subjects)
                    tmfc.subjects(i).LSS = sub_check(i);
                end
                
            end
                
        else
            if isfield(tmfc.LSS, 'conditions') && isfield(tmfc.subjects, 'LSS') 
                
                % Restart case
                % if last subject's LSS is proccessed, then restart
                if any(tmfc.subjects(SZ_tmfc(2)).LSS.session(SZS_tmfc).condition(tmfc.LSS.conditions.number).trials == 1)
                    
                    STATUS = TMFC_RES_GUI(2);
                    if STATUS == 1
                        verify_old = tmfc.LSS.conditions;
                        tmfc.LSS.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
                        if isstruct(tmfc.LSS.conditions)
                            try
                                rmdir(fullfile(tmfc.project_path,'LSS_regression'),'s');
                                if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'))
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'),'s');
                                end
                                disp('Deleting old files');
                            end
                            sub_check = tmfc_LSS(tmfc,1);
                            for i=1:length(tmfc.subjects)
                                tmfc.subjects(i).LSS = sub_check(i);
                            end
                        else
                            tmfc.LSS.conditions = verify_old;                            
                        end
                    end

                else
                    % Continue case
                    STATUS = TMFC_CON_GUI(V_LSS, 2);
                    if STATUS == 0
                        sub_check = tmfc_LSS(tmfc,V_LSS);
                        for i=V_LSS:length(tmfc.subjects)
                            tmfc.subjects(i).LSS = sub_check(i);
                        end
                    elseif STATUS == 1
                        verify_old = tmfc.LSS.conditions;
                        tmfc.LSS.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
                        if isstruct(tmfc.LSS.conditions)
                            try
                                rmdir(fullfile(tmfc.project_path,'LSS_regression'),'s');
                                if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'))
                                    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'),'s');
                                end
                                disp('Deleting old files');
                            end
                            sub_check = tmfc_LSS(tmfc,1);
                            for i=1:length(tmfc.subjects)
                                tmfc.subjects(i).LSS = sub_check(i);
                            end
                        else
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
    
    
        MW_Freeze(0);
    catch
       warning('Please select subjects & project path to perform LSS GLM regression');
    end
        
end % closing LSS regression

%% ============================[ LSS GLM ]=================================
function LSS_FIR(ButtonH, EventData, TMFC_GUI)

    try
        cd(tmfc.project_path);           
    

    
    % Freezing the Main window
    MW_Freeze(1);
    L_break = 0;
    V_LSS = 0;
     try
     
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
            socket = 0;
            if SZC_tmfc(2) == 1 
                socket = tmfc.LSS_after_FIR.conditions.number;
            end
            for i = 1:SZ_tmfc(2)
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
                                    if ~socket==0
                                        % if there is only one condition
                                        if any(tmfc.subjects(i).LSS_after_FIR.session(j).condition(socket).trials == 0)
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
                set(handles.TMFC_GUI_S10,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_LSS == 1
                set(handles.TMFC_GUI_S10,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S10,'String', strcat(num2str(V_LSS-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
        pause(0.1); 
    end
    
    if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
        % Checking if subjects has been selected
        last_size = size(tmfc.subjects);
        if isfield(tmfc.subjects, 'FIR') && tmfc.subjects(last_size(2)).FIR == 1
        disp('Initiating LSS after FIR');        
        
            if ~isfield(tmfc, 'LSS_after_FIR') 
            % First time exeuction

                % select conditions    
                tmfc.LSS_after_FIR.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);

                if isstruct(tmfc.LSS_after_FIR.conditions) && ~isfield(tmfc.subjects, 'LSS_after_FIR')

                    sub_check = tmfc_LSS_after_FIR(tmfc,1);
                    for i=1:length(tmfc.subjects)
                        tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                    end

                end

            elseif isfield(tmfc.LSS_after_FIR, 'conditions') && ~isfield(tmfc.subjects, 'LSS_after_FIR')
                % Execution if CTLR + C is pressed 
                % Can add code for exuection from last complied .mat file

                tmfc.LSS_after_FIR.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);

                if isstruct(tmfc.LSS_after_FIR.conditions)

                    sub_check = tmfc_LSS_after_FIR(tmfc,1);
                    for i=1:length(tmfc.subjects)
                        tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                    end

                end

            else
                if isfield(tmfc.LSS_after_FIR, 'conditions') && isfield(tmfc.subjects, 'LSS_after_FIR') 

                    % Restart case
                    % if last subject's LSS is proccessed, then restart
                    if any(tmfc.subjects(SZ_tmfc(2)).LSS_after_FIR.session(SZS_tmfc).condition(tmfc.LSS_after_FIR.conditions.number).trials == 1)

                        STATUS = TMFC_RES_GUI(3);
                        if STATUS == 1
                            verify_old = tmfc.LSS_after_FIR.conditions;
                            tmfc.LSS_after_FIR.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
                            if isstruct(tmfc.LSS_after_FIR.conditions)
                                try
                                    rmdir(fullfile(tmfc.project_path,'LSS_regression_after_FIR'),'s');
                                    if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'))
                                        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'),'s');
                                    end
                                    disp('Deleting old files');
                                end
                                sub_check = tmfc_LSS_after_FIR(tmfc,1);
                                for i=1:length(tmfc.subjects)
                                    tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                                end
                            else
                                tmfc.LSS_after_FIR.conditions = verify_old;                            
                            end
                        end

                    else
                        % continue case
                        STATUS = TMFC_CON_GUI(V_LSS, 3);
                        % THE ERROR occures somewhere here
                        if STATUS == 0
                            disp(V_LSS);
                            sub_check = tmfc_LSS_after_FIR(tmfc,V_LSS);
                            % THE ERROR TO here
                            for i=V_LSS:length(tmfc.subjects)
                                tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                            end
                        elseif STATUS == 1
                            verify_old = tmfc.LSS_after_FIR.conditions;
                            tmfc.LSS_after_FIR.conditions = tmfc_LSS_GUI(tmfc.subjects(1).path);
                            if isstruct(tmfc.LSS_after_FIR.conditions)
                                try
                                    rmdir(fullfile(tmfc.project_path,'LSS_regression_after_FIR'),'s');
                                    if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'))
                                        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'),'s');
                                    end
                                    disp('Deleting old files');
                                end
                                sub_check = tmfc_LSS_after_FIR(tmfc,1);
                                for i=1:length(tmfc.subjects)
                                    tmfc.subjects(i).LSS_after_FIR = sub_check(i);
                                end
                            else
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
    
    
        MW_Freeze(0);
    catch
       warning('Please select subjects & project path to perform LSS after FIR regression');
    end
        
end

%% ============================[ ROI SET ]=================================
function ROI_sel(ButtonH, EventData, TMFC_GUI)

   if isfield(tmfc, 'project_path')

   cd(tmfc.project_path);    

   MW_Freeze(1);

   if ~isfield(tmfc, 'ROI_set')
       ROI_hold = tmfc_select_ROIs_GUI(tmfc);  
       if isstruct(ROI_hold)
           tmfc.ROI_set_number = 1;
           tmfc.ROI_set(1) = ROI_hold;
           set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(1).set_name, ' (',num2str(length(tmfc.ROI_set(1).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
           tmfc = ROI_initializer(tmfc);
       end

       
   else


        lst_4 = {};
        for l = 1:length(tmfc.ROI_set)
            matter = {l,horzcat(tmfc.ROI_set(l).set_name, ' (',num2str(length(tmfc.ROI_set(l).ROIs)),' ROIs)')};
            lst_4 = vertcat(lst_4, matter);
        end  

        [R_ans, pos] = ROI_F2(lst_4);
        SZ_4 = size(lst_4);

        if R_ans == 1

           % Add new ROI set
           new_ROI_set = tmfc_select_ROIs_GUI(tmfc);
           

           if isstruct(new_ROI_set)
               %tmfc.ROI_set(SZ_4(1)+1) = new_ROI_set;
               tmfc.ROI_set(SZ_4(1)+1).set_name = new_ROI_set.set_name;
               tmfc.ROI_set(SZ_4(1)+1).ROIs = new_ROI_set.ROIs;
               tmfc.ROI_set_number = SZ_4(1)+1;
               disp('ROIs have been succesfully selected');
               set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(SZ_4(1)+1).set_name, ' (',num2str(length(tmfc.ROI_set(SZ_4(1)+1).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
               tmfc = ROI_initializer(tmfc);
               set(handles.TMFC_GUI_S3,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);    
               set(handles.TMFC_GUI_S4,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
           end

        elseif R_ans == 0 && pos ~=0

            fprintf('Selected ROI for processing is: %s \n', char(lst_4(pos,2)));
            tmfc.ROI_set_number = pos;
            set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(pos).set_name, ' (',num2str(length(tmfc.ROI_set(pos).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
            tmfc = update_VP_PP_GP(tmfc);
        else
            disp('ROIs have not been selected');

        end



   end


   MW_Freeze(0);

   else
        warning('Please select subjects to continue with ROI set selection');
    end
end

%% =====================[ Supporting Functions ]===========================
      
try 
    guidata(handles.TMFC_GUI, handles);
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

%%
function tmfc = evaluate_file(tmfc) % function to update the TMFC window after loading a tmfc project
    
    try
        cd(tmfc.project_path); 
    end
    
    
    % Add condition: if tmfc.subjcest is empyt set handlex.tmfc gui to NOT
    % SELECTED 
    
    % update subjects
    try
        set(handles.TMFC_GUI_S1,'String', strcat(num2str(length(tmfc.subjects)), ' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
    end
   
    % Update ROI set
    try 
        if isfield(tmfc,'ROI_set_number')            
            set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(tmfc.ROI_set_number).set_name, ' (',num2str(length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);                   
        end
    end
    
    % update FIR
    try
       % track
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
            for i = 1:SZ_tmfc(2)
                % checking status of FIR completion
                if tmfc.subjects(i).FIR == 0
                    V_FIR = i ;
                    break;
                end
            end

            if V_FIR == 0
                set(handles.TMFC_GUI_S8,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_FIR == 1
                set(handles.TMFC_GUI_S8,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S8,'String', strcat(num2str(V_FIR-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
        pause(0.1); 
    end

    
    tmfc = update_VP_PP_GP(tmfc);
    
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
            socket = 0;
            if SZC_tmfc(2) == 1 
                socket = tmfc.LSS.conditions.number;
            end
            for i = 1:SZ_tmfc(2)
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
                                    if ~socket==0
                                        % if there is only one condition
                                        if any(tmfc.subjects(i).LSS.session(j).condition(socket).trials == 0)
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
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_LSS == 1
                set(handles.TMFC_GUI_S6,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(V_LSS-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
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
            socket = 0;
            if SZC_tmfc(2) == 1 
                socket = tmfc.LSS_after_FIR.conditions.number;
            end
            for i = 1:SZ_tmfc(2)
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
                                    if ~socket==0
                                        % if there is only one condition
                                        if any(tmfc.subjects(i).LSS_after_FIR.session(j).condition(socket).trials == 0)
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
                set(handles.TMFC_GUI_S10,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_LSS == 1
                set(handles.TMFC_GUI_S10,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S10,'String', strcat(num2str(V_LSS-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end
        pause(0.1); 
    end
     
     switch tmfc.defaults.parallel
         case 1
             SET_COMPUTING = {'Parallel computing','Sequential computing',};           
         case 0 
            SET_COMPUTING = {'Sequential computing','Parallel computing'};
     end   
     
     switch tmfc.defaults.resmem
         case true
             SET_STORAGE = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
         case false 
            SET_STORAGE = {'Store temporary files for GLM estimation on disk','Store temporary files for GLM estimation in RAM'};
     end          
     
     switch tmfc.defaults.analysis
         case 1
             SET_SEED = {'Seed-to-voxel and ROI-to-ROI','ROI-to-ROI','Seed-to-voxel only'};
         case 2 
             SET_SEED = {'ROI-to-ROI','Seed-to-voxel only','Seed-to-voxel and ROI-to-ROI'};
         case 3
             SET_SEED = {'Seed-to-voxel only','Seed-to-voxel and ROI-to-ROI','ROI-to-ROI'};
     end
    
end

%% Freeze Window
function MW_Freeze(STATE)

    switch(STATE)
        case 0 
            STATE = 'on';
        case 1
            STATE = 'off';
    end
    set([handles.TMFC_GUI_B1, handles.TMFC_GUI_B2, handles.TMFC_GUI_B3, handles.TMFC_GUI_B4,...
                handles.TMFC_GUI_B5a, handles.TMFC_GUI_B5b, handles.TMFC_GUI_B6, handles.TMFC_GUI_B7,...
                handles.TMFC_GUI_B8, handles.TMFC_GUI_B9, handles.TMFC_GUI_B10, handles.TMFC_GUI_B11,...
                handles.TMFC_GUI_B12,handles.TMFC_GUI_B13a,handles.TMFC_GUI_B13b,handles.TMFC_GUI_B14a...
                handles.TMFC_GUI_B14b], 'Enable', STATE);

end
         
%% Reset after new Subjects
function [tmfc] = major_reset(tmfc)

% tmfc = rmfield(tmfc, 'subjects');
% tmfc = rmfield(tmfc,'project_path');
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

set(handles.TMFC_GUI_S2,'String', 'Not selected','ForegroundColor',[1, 0, 0]);
set(handles.TMFC_GUI_S3,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
set(handles.TMFC_GUI_S4,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
set(handles.TMFC_GUI_S6,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
set(handles.TMFC_GUI_S8,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
set(handles.TMFC_GUI_S10,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);

end

function [tmfc] = reset_VPGPPI(tmfc, cases)                            

switch (cases)
    
    case 1
        % reset all three        
        for i=1:length(tmfc.subjects)
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR = 0;
        end
        set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
        tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = [];
    case 2 
        % reset PPI, gPPI 
        for i=1:length(tmfc.subjects)
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR = 0;
        end
        set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
        %tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = [];
    case 3
        % reset all three        
        for i=1:length(tmfc.subjects)
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI = 0;
            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR = 0;
        end
        set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);

end

end

function [tmfc] = update_VP_PP_GP(tmfc)
    % update VOI
        V_VOI = 0;
        try
        cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
        %maybe require gPPI FIR conditions
        sess = []; sess_num = []; N_sess = [];
        for i = 1:length(cond_list)
            sess(i) = cond_list(i).sess;
        end
        sess_num = unique(sess);
        N_sess = length(sess_num);
        R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);

        for subi = 1:length(tmfc.subjects)    
            for k = 1:R
                for j = 1:N_sess
                    if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'VOIs',['Subject_' num2str(subi,'%04.f')], ...
                            ['VOI_' tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name '_' num2str(j) '.mat']), 'file')
                        check(j) = 1;
                    else
                        check(j) = 0;
                    end
                end
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).VOI = double(~any(check==0));
                clear check 
            end
        end
        clear cond_list sess sess_num N_sess R
        end
        try
            SZ_tmfc = size(tmfc.subjects);
            V_VOI = 0;
            for i = 1:SZ_tmfc(2)
                % checking status of VOI completion
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI == 0
                    V_VOI = i ;
                    break;
                end
            end

            if V_VOI == 0
                set(handles.TMFC_GUI_S3,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_VOI == 1
                set(handles.TMFC_GUI_S3,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S3,'String', strcat(num2str(V_VOI-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end

        end




    % Update PPI
        V_PPI = 0;
        try
        cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions; %tmfc.gPPI.conditions;
        sess = []; sess_num = []; N_sess = [];
        for i = 1:length(cond_list)
            sess(i) = cond_list(i).sess;
        end
        sess_num = unique(sess);
        N_sess = length(sess_num);
        R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);

        for subi = 1:length(tmfc.subjects)
            SPM = load(tmfc.subjects(subi).path);
            for k = 1:R
                for j = 1:N_sess
                    if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'PPIs',['Subject_' num2str(subi,'%04.f')], ...
                                ['PPI_[' regexprep(tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name,' ','_') ...
                                ']_[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                                regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') '].mat']), 'file')
                        check(j) = 1;
                    else
                        check(j) = 0;
                    end
                end
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).PPI = double(~any(check==0));
                clear check 
            end
            clear SPM
        end
        clear cond_list sess sess_num N_sess R
        end 
        try
            SZ_tmfc = size(tmfc.subjects);
            V_PPI = 0;
            for i = 1:SZ_tmfc(2)
                % checking status of VOI completion
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI == 0
                    V_PPI = i ;
                    break;
                end
            end
            if V_PPI == 0
                set(handles.TMFC_GUI_S4,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_PPI == 1
                set(handles.TMFC_GUI_S4,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S4,'String', strcat(num2str(V_PPI-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end
        end


     % gPPI
      try
        V_gPPI = 0;
        R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
        for subi = 1:length(tmfc.subjects)
            for k = 1:R
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI','GLM_batches',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name, ...
                        ['Subject_' num2str(subi,'%04.f') '_gPPI_GLM.mat']), 'file')
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI = 1;
                else            
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI = 0;
                end
            end
        end
        clear R
     end
     try
        R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
        for subi = 1:length(tmfc.subjects)
            for k = 1:R
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI','GLM_batches',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name, ...
                        ['Subject_' num2str(subi,'%04.f') '_gPPI_GLM.mat']), 'file')
                    %tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).subjects(subi).gPPI = 1;
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI = 1;
                else
                    %tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).subjects(subi).gPPI = 0;
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI = 0;
                end
            end
        end
        clear R
     end

     
   % Check gPPI-FIR
    V_gPPI_FIR = 0;
    try
        %% Check gPPI FIR
        R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
        for subi = 1:length(tmfc.subjects)
            for k = 1:R
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR','GLM_batches',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name, ...
                ['Subject_' num2str(subi,'%04.f') '_gPPI_FIR_GLM.mat']), 'file')
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI_FIR = 1;
                else            
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI_FIR = 0;
                end
            end
        end
        clear R
    end
   try
    R = length(tmfc.ROI_set(tmfc.ROI_set_number).ROIs);
    for subi = 1:length(tmfc.subjects)
        for k = 1:R
            if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'gPPI_FIR','GLM_batches',tmfc.ROI_set(tmfc.ROI_set_number).ROIs(k).name, ...
                    ['Subject_' num2str(subi,'%04.f') '_gPPI_FIR_GLM.mat']), 'file')
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI_FIR = 1;
            else
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).gPPI_FIR = 0;
            end
        end
    end
    clear R       
   end
           
   
end

end  
%%
function TMFC_SS_select_proj_path(S)
    TMFC_SS_PP = figure('Name', 'Select project paths', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.24 0.14],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @OKAY, 'Tag', 'Proj_path');
    PP_details = {'Next, select the project path where all results and temporary files will be stored'};
    TMFC_SS_PP_S1 = uicontrol(TMFC_SS_PP,'Style','text','String',strcat(num2str(S), ' subjects selected'),'Units', 'normalized', 'Position',[0.35 0.72 0.30 0.17],'backgroundcolor','w','fontunits','normalized','fontSize', 0.70,'ForegroundColor',[0.219, 0.341, 0.137]);
    TMFC_SS_PP_S2 = uicontrol(TMFC_SS_PP,'Style','text','String',PP_details,'Units', 'normalized', 'Position',[0.05 0.38 0.90 0.30],'backgroundcolor','w','fontunits','normalized','fontSize', 0.38);
    OK = uicontrol(TMFC_SS_PP,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.33 0.14 0.3 0.2]);
    set(OK, 'callback', @OKAY);
    
    function OKAY(~,~)
        delete(TMFC_SS_PP);
    end
    uiwait();
end

function [STATUS] = TMFC_CON_GUI(INDEX, option)

    % STATUS = 1 - restart Operation 
    % STATUS = 0 - continue Operation
    % STATUS = -1 - no action

    
    res_str_0 = '';
    res_str_1 = {};
    b_res = '';
    switch (option)
        case 1
            % FIR
            res_str_0 = 'FIR task regression';
            res_str_1 = {'Continue FIR task regression from'};
            b_res = '<html>&#160 No, start from <br>the first subject';
        case 2
            % LSS
            res_str_0 = 'LSS GLM regression';
            res_str_1 = {'Continue LSS GLM regression from'};
            b_res = '<html>&#160 No, start from <br>the first subject';
        case 3
            % LSS after FIR
            res_str_0 = 'LSS after FIR regression';
            res_str_1 = {'Continue LSS after FIR regression from'};
            b_res = '<html>&#160 No, start from <br>the first subject';
        case 4 
            % VOIs
            res_str_0 = 'VOI computation';
            res_str_1 = {'Continue VOI computation from'};
            b_res = '<html>&#160 No, start from <br>the first subject';
        case 5
            % PPIs
            res_str_0 = 'PPI computation';
            res_str_1 = {'Continue PPI computation from'};
            b_res = 'Cancel';
        case 6
            % gPPIs
            res_str_0 = 'gPPI computation';
            res_str_1 = {'Continue gPPI computation from'};
            b_res = 'Cancel';
        case 7
            % gPPI FIR
            res_str_0 = 'gPPI FIR computation';
            res_str_1 = {'Continue gPPI FIR computation from'};
            b_res = 'Cancel';
    end
    
    
    TMFC_CONT = figure('Name', res_str_0, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.20 0.18],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Contd_FIR','CloseRequestFcn', @CANCEL); %X Y W H

    TMFC_CONT_S1 = uicontrol(TMFC_CONT,'Style','text','String', res_str_1,'Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38, 'Position',[0.10 0.55 0.80 0.260]);
    TMFC_CONT_S2 = uicontrol(TMFC_CONT,'Style','text','String', strcat('subject №',num2str(INDEX),'?'), 'Units','normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38, 'Position',[0.10 0.40 0.80 0.260]);

    TMFC_CONT_YES = uicontrol(TMFC_CONT,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.28, 'Position',[0.12 0.15 0.320 0.270]);
    TMFC_CONT_RESTART = uicontrol(TMFC_CONT,'Style','pushbutton', 'String', b_res,'Units', 'normalized','fontunits','normalized', 'fontSize', 0.28,'Position',[0.56 0.15 0.320 0.270]);

    set([TMFC_CONT_S1,TMFC_CONT_S2],'backgroundcolor',get(TMFC_CONT,'color'));
    set(TMFC_CONT_YES, 'callback', @CONTINUE);
    set(TMFC_CONT_RESTART, 'callback', @RESTART);

    function CANCEL(~,~)
        delete(TMFC_CONT);
        STATUS = -1;
    end
    
    % Function to set status in MAIN_WINDOW appdata (To continue from
    % last processed subject) 
    function CONTINUE(~,~)
        STATUS = 0;
        delete(TMFC_CONT);
    end

    % Function to set status in MAIN_WINDOW appdata (To Restart from
    % the first subject)
    function RESTART(~,~)
        if ~strcmp(b_res, 'Cancel')
            STATUS = 1;
            delete(TMFC_CONT);
        else
            STATUS = -2;
            delete(TMFC_CONT);
        end
    end

    
    uiwait();
end

function [STATUS] = TMFC_RES_GUI(option)

    % STATUS = 1 - restart FIR 
    % STATUS = 0 - dont restart FIR 
    res_str_0 = '';
    res_str_1 = {};
    
    switch (option)
        case 1
            % FIR
            res_str_0 = 'FIR task regression';
            res_str_1 = {'Recompute FIR Task', 'regression for all subjects?'};
        case 2
            % LSS
            res_str_0 = 'LSS GLM regression';
            res_str_1 = {'Recompute LSS GL', 'regression for all subjects?'};
        case 3
            % LSS after FIR
            res_str_0 = 'LSS after FIR regression';
            res_str_1 = {'Recompute LSS after FIR', 'regression for all subjects?'};
        case 4
            % VOIs
            res_str_0 = 'VOI computation';
            res_str_1 = {'Recompute VOI', 'computations for all subjects?'};
        case 5
            % PPIs
            res_str_0 = 'PPI computation';
            res_str_1 = {'Recompute PPI', 'computations for all subjects?'};
    end
    
    TMFC_RES = figure('Name', res_str_0, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.18 0.14],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Restart_WIN','CloseRequestFcn', @CANCEL); %X Y W H
    
    %
    TMFC_RES_S1 = uicontrol(TMFC_RES,'Style','text','String',res_str_1 ,'Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.40, 'Position', [0.10 0.55 0.80 0.260]);
    TMFC_RES_OK = uicontrol(TMFC_RES,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.48, 'Position', [0.14 0.22 0.320 0.20]);
    TMFC_RES_CL = uicontrol(TMFC_RES,'Style','pushbutton', 'String', 'Cancel','Units', 'normalized','fontunits','normalized', 'fontSize', 0.48,'Position',[0.52 0.22 0.320 0.20]);

    set(TMFC_RES_S1,'backgroundcolor',get(TMFC_RES,'color'));
    set(TMFC_RES_CL, 'callback', @CANCEL);
    set(TMFC_RES_OK, 'callback', @RESTART);

    % Function to close the Window
    function CANCEL(~,~)
        delete(TMFC_RES);
        STATUS = 0;
    end

    % Function to Restart FIR Regression
    function RESTART(~,~)
        STATUS = 1;
        delete(TMFC_RES);
    end
    uiwait();
end

function [win, bin] = TMFC_BW_GUI(cases)

     % case 0 = FIR 
     % case 1 = gPPI FIR
     switch (cases)
        case 0
            Title_BW = 'FIR task regression'; 
            ST1 = 'Enter FIR window length (in seconds):';
            ST2 = 'Enter the number of FIR time bins:';
            ST_HP = 'FIR task regression: Help';
    
        case 1
            Title_BW = 'gPPI FIR computation'; 
            ST1 = 'Enter FIR window length (in seconds) for gPPI:';
            ST2 = 'Enter the number of FIR time bins for gPPI:';
            ST_HP = 'gPPI FIR: Help';
     end
    
    
    TMFC_BW = figure('Name', Title_BW, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.22 0.18],'Resize','off',...
        'MenuBar', 'none', 'ToolBar', 'none','Tag','TMFC_WB_NUM', 'WindowStyle','modal','CloseRequestFcn', @TMFC_BW_stable_Exit); 
    set(gcf,'color','w');
    
    TMFC_BW_S1 = uicontrol(TMFC_BW,'Style','text','String', ST1,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40, 'Position',[0.08 0.62 0.65 0.200]);
    TMFC_BW_S2 = uicontrol(TMFC_BW,'Style','text','String', ST2,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40,'Position',[0.08 0.37 0.65 0.200]);
    TMFC_BW_E1 = uicontrol(TMFC_BW,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.67 0.185 0.170]);%,'InputType', 'digits');
    TMFC_BW_E2 = uicontrol(TMFC_BW,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.42 0.185 0.170]);
    TMFC_BW_OK = uicontrol(TMFC_BW,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.21 0.13 0.230 0.170]);
    TMFC_BW_HELP = uicontrol(TMFC_BW,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.52 0.13 0.230 0.170]);

    set(TMFC_BW_S1,'backgroundcolor',get(TMFC_BW,'color'));
    set(TMFC_BW_S2,'backgroundcolor',get(TMFC_BW,'color'));
    set(TMFC_BW_OK, 'callback', @TMFC_BW_EXTRACT);
    set(TMFC_BW_HELP, 'callback', @TMFC_BW_HELP_POP);

   
    function TMFC_BW_stable_Exit(~,~)
       %h76 = findobj('Tag', 'MAIN_WINDOW');
       %setappdata(h76, 'NO_COND', 1); 
       win = NaN; 
       bin = NaN; 
       delete(TMFC_BW);
    end

    % Generates the HELP WINDOW within the GUI 
    function TMFC_BW_HELP_POP(~,~)

            TMFC_BW_HELPWW = figure('Name', ST_HP, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.62 0.26 0.22 0.48],'Resize','off','MenuBar', 'none','ToolBar', 'none');
            set(gcf,'color','w');

            TMFC_BW_DETAILS = {'Finite impulse response (FIR) task regression are used to remove co-activations from BOLD time-series.','',...
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

            TMFC_BW_LS2_DTS_1 = uicontrol(TMFC_BW_HELPWW,'Style','text','String', TMFC_BW_DETAILS,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.035, 'Position',[0.06 0.16 0.885 0.800]);
            TMFC_BW_LS2_DTS_2 = uicontrol(TMFC_BW_HELPWW,'Style','text','String', TMFC_BW_DETAILS_2,'Units', 'normalized', 'HorizontalAlignment', 'Center','fontunits','normalized', 'fontSize', 0.30, 'Position',[0.06 0.10 0.885 0.10]);
            TMFC_BW_LS2_OK = uicontrol(TMFC_BW_HELPWW,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35, 'Position',[0.39 0.04 0.240 0.070]);

            set(TMFC_BW_LS2_DTS_1,'backgroundcolor',get(TMFC_BW_HELPWW,'color'));
            set(TMFC_BW_LS2_DTS_2,'backgroundcolor',get(TMFC_BW_HELPWW,'color'));
            set(TMFC_BW_LS2_OK, 'callback', @TMFC_BW_CLOSE_LS2_OK);

            function TMFC_BW_CLOSE_LS2_OK(~,~)
                close(TMFC_BW_HELPWW);
            end
    end



    % Function to extract the entered number from the user
    function TMFC_BW_EXTRACT(~,~)

       Window = str2double(get(TMFC_BW_E1, 'String'));
       bins = str2double(get(TMFC_BW_E2, 'String'));

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
           delete(TMFC_BW);
       end

    end
    uiwait();
end

% ROI Set functions
function [new_flag, position] = ROI_F2(LIST_SETS,~)
    
    new_flag = 0;
    position = 0;
    
    ROI_2 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.28 0.35],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

    ROI_2_disp = uicontrol(ROI_2 , 'Style', 'listbox', 'String', LIST_SETS(:,2),'Units', 'normalized', 'Position',[0.048 0.25 0.91 0.49],'fontunits','normalized', 'fontSize', 0.09);

    ROI_2_S1 = uicontrol(ROI_2,'Style','text','String', 'Select ROI set','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.58);
    ROI_2_S2 = uicontrol(ROI_2,'Style','text','String', 'Sets:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.64);
    
    ROI_2_OK = uicontrol(ROI_2,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_2_Select = uicontrol(ROI_2,'Style','pushbutton', 'String', 'Add new ROI set','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
     
    ROI_2_S1.Position = [0.29 0.85 0.400 0.09];
    ROI_2_S2.Position = [0.04 0.74 0.100 0.08];
     
    ROI_2_OK.Position = [0.16 0.10 0.28 0.10]; % W H
    ROI_2_Select.Position = [0.56 0.10 0.28 0.10];
    
    selection_3 = {};
    set(ROI_2_disp, 'Value', 1);
    selection_3 = 1;
    
    set(ROI_2_S1,'backgroundcolor',get(ROI_2,'color'));
    set(ROI_2_S2,'backgroundcolor',get(ROI_2,'color'));
    set(ROI_2_disp, 'callback', @action_select_M1);
    
    set(ROI_2_OK, 'callback', @ROI_F2_OK);
    set(ROI_2_Select, 'callback', @ROI_F2_SELECT);
    
     
    function action_select_M1(~,~)
        index = get(ROI_2_disp, 'Value');  % Retrieves the users selection LIVE
        selection_3 = index;    
    end

    
    
    function ROI_F2_OK(~,~)
        new_flag = 0;
        position = selection_3;
        close(ROI_2);
    end

    function ROI_F2_SELECT(~,~)
        new_flag = 1;
        close(ROI_2);
        position = 0;
    end
    
    uiwait();
    
end

function [tmfc] = ROI_initializer(tmfc)

   for j=1:length(tmfc.subjects)
       tmfc.ROI_set(tmfc.ROI_set_number).subjects(j).BGFC = 0;
       tmfc.ROI_set(tmfc.ROI_set_number).subjects(j).BSC = 0;
       tmfc.ROI_set(tmfc.ROI_set_number).subjects(j).BSC_after_FIR = 0;       
       tmfc.ROI_set(tmfc.ROI_set_number).subjects(j).VOI = 0;       
       tmfc.ROI_set(tmfc.ROI_set_number).subjects(j).PPI = 0;       
       tmfc.ROI_set(tmfc.ROI_set_number).subjects(j).gPPI = 0;       
       tmfc.ROI_set(tmfc.ROI_set_number).subjects(j).gPPI_FIR = 0;       
   end
   
   tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI.title = [];
   tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI.weights= [];
   
   tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR.title = [];
   tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR.weights= [];
   
   tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC.title = [];
   tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC.weights= [];
   
   tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR.title = [];
   tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR.weights= [];
   

end

function PPI_OKAY()
TMFC_PPI_Diag = figure('Name', 'PPI', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.24 0.12],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @OKAY, 'Tag', 'PPI');
    PPI_details = {'PPI computation completed. To change conditions of interest, recompute VOIs'};
    TMFC_PPI_S1 = uicontrol(TMFC_PPI_Diag,'Style','text','String',PPI_details,'Units', 'normalized', 'Position',[0.05 0.5 0.90 0.30],'backgroundcolor','w','fontunits','normalized','fontSize', 0.38);
    OK = uicontrol(TMFC_PPI_Diag,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.35 0.18 0.3 0.2],'fontunits','normalized','fontSize', 0.38);
    set(OK, 'callback', @OKAY);
    
    function OKAY(~,~)
        delete(TMFC_PPI_Diag);
    end
    uiwait();

end


% OUTLINE
    
    % CD project path
    
    % freeze window 
    
    % tracking progress 
    
    % CHECK - Subjects, should be selected, 
    % CHECK - ROIs should be selected

    % Select gPPI Conditions =  tmfc_gPPI_GUI();
    % perform VOIs
    
    % check conditions for restart & continue 
    

    % send back to tmfc 

    % open contrasts 

    % unfreeze