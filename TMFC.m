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
    handles.TMFC_GUI_B7 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS', 'Units', 'normalized', 'Position', [0.06 0.52 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B8 = uicontrol('Style', 'pushbutton', 'String', 'FIR task regression', 'Units', 'normalized', 'Position', [0.06 0.44 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B9 = uicontrol('Style', 'pushbutton', 'String', 'Background connectivity', 'Units', 'normalized', 'Position', [0.06 0.38 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B10 = uicontrol('Style', 'pushbutton', 'String', 'LSS GLM after FIR', 'Units', 'normalized', 'Position', [0.06 0.30 0.40 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B11 = uicontrol('Style', 'pushbutton', 'String', 'BSC LSS after FIR', 'Units', 'normalized', 'Position', [0.06 0.24 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
    handles.TMFC_GUI_B12 = uicontrol('Style', 'pushbutton', 'String', 'Results', 'Units', 'normalized', 'Position', [0.06 0.16 0.884 0.05],'FontUnits','normalized','FontSize',0.33);
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
    set(handles.TMFC_GUI_B1, 'callback', {@select_subjects, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B2, 'callback', {@ROI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B3, 'callback', {@VOI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B4, 'callback', {@PPI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B5a, 'callback', {@gPPI, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B5b, 'callback', {@gPPI_FIR, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B6, 'callback', {@LSS_GLM, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B7, 'callback', {@BSC, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B8, 'callback', {@FIR, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B9, 'callback', {@BGFC, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B10, 'callback', {@LSS_FIR, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B11, 'callback', {@BSC_after_FIR, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B12, 'callback', {@reset, handles.TMFC_GUI});               
    set(handles.TMFC_GUI_B13a, 'callback', {@open_project, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B13b, 'callback', {@save_project, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B14a, 'callback', {@change_paths, handles.TMFC_GUI});
    set(handles.TMFC_GUI_B14b, 'callback', {@settings, handles.TMFC_GUI});    
else
    % Warning prompt if user tries to open TMFC when already running
    figure(findobj('Tag', 'TMFC_GUI')); 
    warning('TMFC toolbox is already running');    
end
%% ========================[ Select Subjects ]=============================
% Select subjects and check SPM.mat files for processing
% Dependencies: 
%       - tmfc_select_subjects_GUI.m (External)
%       - tmfc_select_project_path() (Internal)
function select_subjects(ButtonH, EventData, TMFC_GUI)
    
    % Freeze TMFC Main Window
    MW_Freeze(1);
    
    % Selection of paths using 4 stage file existence checks
    sel_paths = tmfc_select_subjects_GUI(1);
    
    % If paths are not selected - Unfreeze 
    if isempty(sel_paths)
        MW_Freeze(0);
        fprintf('\nSubjects not selected\n');
    else 
       
       % Update paths to TMFC variable
       L_paths = size(sel_paths);
       for SS_i = 1:L_paths(1) 
           tmfc.subjects(SS_i).path = char(sel_paths(SS_i));       
       end
       
       % Project Path selection
       fprintf('Please select a folder for the new TMFC project\n');    
       tmfc_select_project_path(L_paths(1)); % Warning Dialogue box
       % Select project path
       project_path = spm_select(1,'dir','Select a folder for the new TMFC project',{},pwd);
       
       % Verify if project path is selected
       if strcmp(project_path, '')
            warning('Project path not selected, Subjects not saved');
            try
                MW_Freeze(0);
            end
            return;
       else
           % assign to TMFC variable
            fprintf('%d subjects have been successfully selected \n', L_paths(1));
            set(handles.TMFC_GUI_S1,'String', strcat(num2str(L_paths(1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
            tmfc.project_path = project_path;
            
            % Clearning old instances of TMFC data 
            tmfc = major_reset(tmfc);
            MW_Freeze(0);
       end       
    end

    % Change path to project folder
    try
        cd(tmfc.project_path);  
    end
end

%% ============================[ ROI set ]=================================
% Selection of ROI sets for subjects processing 
% Dependencies: 
%       - tmfc_select_ROIs_GUI.m (External)
%       - ROI_initializer()      (Internal)
%       - ROI_set()              (Internal)
%       - update_gPPI()          (Internal)

function ROI(ButtonH, EventData, TMFC_GUI)

    % Checking if project path has been selected
   if isfield(tmfc, 'project_path')
    
       % Change to project Directory
       cd(tmfc.project_path);    
    
       % Freeze main TMFC Window
       MW_Freeze(1);
    
       % Check if ROI sets already exist 
       if ~isfield(tmfc, 'ROI_set')
           
           % Selection of ROIs 
           ROI_hold = tmfc_select_ROIs_GUI(tmfc);  
           
           % If ROIs have been selected continue and assign data to TMFC var
           if isstruct(ROI_hold)
               tmfc.ROI_set_number = 1;
               tmfc.ROI_set(1) = ROI_hold;
               set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(1).set_name, ' (',num2str(length(tmfc.ROI_set(1).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
               
               % Initialize processing fields (e.g LSS etc)
               tmfc = ROI_initializer(tmfc);
           end
        
        else
            % Additional ROI selection after initialization
            
            % Creationg & storage of existing ROI sets
            lst_4 = {};
            for l = 1:length(tmfc.ROI_set)
                matter = {l,horzcat(tmfc.ROI_set(l).set_name, ' (',num2str(length(tmfc.ROI_set(l).ROIs)),' ROIs)')};
                lst_4 = vertcat(lst_4, matter);
            end  
    
            % User selects current ROI set or Add new ROI set
            [R_ans, pos] = ROI_set(lst_4);
            SZ_4 = size(lst_4);
    
            if R_ans == 1
                
               % Add new ROI set
               new_ROI_set = tmfc_select_ROIs_GUI(tmfc);
               
               % Assign new data only if selected by user
               if isstruct(new_ROI_set)
                   tmfc.ROI_set(SZ_4(1)+1).set_name = new_ROI_set.set_name;
                   tmfc.ROI_set(SZ_4(1)+1).ROIs = new_ROI_set.ROIs;
                   tmfc.ROI_set_number = SZ_4(1)+1;
                   fprintf('\nROIs have been succesfully selected\n');
                   set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(SZ_4(1)+1).set_name, ' (',num2str(length(tmfc.ROI_set(SZ_4(1)+1).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
                   tmfc = ROI_initializer(tmfc);
                   set(handles.TMFC_GUI_S3,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);    
                   set(handles.TMFC_GUI_S4,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
               end
    
               
            elseif R_ans == 0 && pos ~=0
                % Selection of ROI set (No addition of new ROI Set)
                fprintf('\nSelected ROI for processing is: %s \n', char(lst_4(pos,2)));
                tmfc.ROI_set_number = pos;
                set(handles.TMFC_GUI_S2,'String', horzcat(tmfc.ROI_set(pos).set_name, ' (',num2str(length(tmfc.ROI_set(pos).ROIs)),' ROIs)'),'ForegroundColor',[0.219, 0.341, 0.137]);
                tmfc = update_gPPI(tmfc);
            else
                % If user cancels operation
                fprintf('\nROIs have not been selected\n');
            end
       end
   
   else
       % Warning if user has not selected subjects
        warning('Please select subjects to continue with ROI set selection');
   end
   % Unfreeze TMFC Main Window
   MW_Freeze(0);
   
end % Closing ROI selection

%% ================================[ VOIs ]================================
% Performing VOI processing for ROI sets
% Dependencies: 
%       - tmfc_VOI.m      (External)
%       - tmfc_gPPI_GUI.m (External)
%       - reset_gPPI()    (Internal)
%       - tmfc_restart_GUI()   (Internal)
%       - tmfc_continue_GUI()  (Internal)

function VOI(ButtonH, EventData, TMFC_GUI)
% Checking for subjects selection
     try 
         
        % Change to project directory & Freeze TMFC window
        cd(tmfc.project_path);       
        MW_Freeze(1);
               
        % Track & Update VOI progress to TMFC variable & window 
        try
        V_VOI = 0;
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
        % Update VOI progress to TMFC variable & Window 
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
        
        % Check if subjects have been selected
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
            % Check if ROI set has been selected
             if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
                 
                 % Check if ROI conditions have been selected
                if ~isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI')
                    % First time execution 
                    
                    % Selection of gPPI conditions
                    tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = tmfc_gPPI_GUI(tmfc.subjects(1).path);
                    
                    % Proceed with VOI processing if conditions are selected
                    if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions) && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).VOI == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).VOI == 0
                        
                        % Reset status & progress of VOI, PPI, gPPI, gPPI_FIR
                        tmfc = reset_gPPI(tmfc, 3);
                        fprintf('\nInitiating VOI computation\n');
                        % Processing VOIs
                        sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, 1);
                        for i=1:length(tmfc.subjects)
                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                        end
                        fprintf('VOI computation completed\n');
                        
                    end

                % Execution if Ctrl + C is pressed
                elseif isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).VOI == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).VOI == 0
                    
                    % Selection of gPPI conditions
                    tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = tmfc_gPPI_GUI(tmfc.subjects(1).path);
                    
                    % Reset status & progress of VOI, PPI, gPPI, gPPI_FIR
                    tmfc = reset_gPPI(tmfc, 3);
                    
                    % Continue processing if gPPI conditions are selected
                    if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions)
                        
                        % Processing of VOIs
                        sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, 1);
                        for i=1:length(tmfc.subjects)
                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                        end
                        fprintf('VOI computation completed\n');
                        
                    end
                    
                else
                    % Execution for Restart & Continue cases
                    if isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI, 'conditions') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).VOI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).VOI == 1
                       
                        % Restart case 
                        
                        % Confirm recomputaiton with user
                        STATUS = tmfc_restart_GUI(4);
                        
                        if STATUS == 1
                            % Storage of old conditions if user cancels midway
                            verify_old = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
                            
                            % Selection of gPPI conditions
                            tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = tmfc_gPPI_GUI(tmfc.subjects(1).path);
                            
                             % Continue processing if gPPI conditions are selected
                            if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions)
                                
                                % Reset status & progress of VOI, PPI, gPPI, gPPI_FIR
                                tmfc = reset_gPPI(tmfc, 3);
                                
                                % Deletion of old file/folder directories
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
                                
                                % Processing of VOIs
                                sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, 1);
                                for i=1:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                                end
                                
                                fprintf('\nVOI computation completed\n');
                                
                            else
                                % If user has cancelled midway, assign the
                                % previously selected conditions back to TMFC
                                tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = verify_old;                            
                            end
                        end 
                        
                    else
                        % Continue case
                        
                        % Confirmation if user wants to Continue or Restart
                        STATUS = tmfc_continue_GUI(V_VOI, 4);
                        
                        % Continue case
                        if STATUS == 0
                            
                            % Processing of VOIs 
                            sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, V_VOI);
                            for i=V_VOI:length(tmfc.subjects)
                                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                            end
                            fprintf('\nVOI computation completed\n');

                        elseif STATUS == 1
                            % Restart case
                            
                            % Storage of old conditions if user cancels midway
                            verify_old = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
                            
                            % Selection of gPPI conditions
                            tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = tmfc_gPPI_GUI(tmfc.subjects(1).path);
                            
                            % Continue processing if gPPI conditions are selected
                            if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions)
                                
                                % Reset status & progress of PPI, gPPI, gPPI_FIR
                                tmfc = reset_gPPI(tmfc, 2);
                                
                                % Deletion of old file/folder directories
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
                                    fprintf('\nDeleting old files\n');
                                end
                                
                                % Processing of VOIs
                                sub_check = tmfc_VOI(tmfc,tmfc.ROI_set_number, 1);
                                for i=1:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = sub_check(i);
                                end
                                fprintf('\nVOI computation completed\n');
                                
                            else
                                % If user has cancelled midway, assign the
                                % previously selected conditions back to TMFC
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
                
     catch
         warning('Please select subjects & project path to perform VOI computation');
     end
     
     % Unfreeze TMFC Main Window
     MW_Freeze(0);
     
end

%% =============================== [ PPIs ] ===============================
% Performing PPI processing for ROI sets
% Dependencies: 
%       - tmfc_PPI.m      (External)
%       - PPI_recompute()      (Internal)
%       - tmfc_continue_GUI()  (Internal)

function PPI(ButtonH, EventData, TMFC_GUI)
    
    % Checking for subjects selection
    try
        
        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);       
        MW_Freeze(1);
        
        % Track & Update PPI progress to TMFC variable & Window 
        try
        V_PPI = 0;
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
        % Update PPI progress to TMFC variable & Window 
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
      
        % Check if subjects have been selected
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
             % Check if ROI set has been selected
             if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
                
                % Check if VOIs has been computed 
                 if tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).VOI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).VOI == 1
                     
                     % First time execution 
                     if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions) && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).PPI == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).PPI == 0
                         
                        fprintf('\nInitiating PPI computation\n');
                         
                        % Processing PPIs
                        sub_check = tmfc_PPI(tmfc,tmfc.ROI_set_number, 1);
                        for i=1:length(tmfc.subjects)
                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = sub_check(i);
                        end
                        fprintf('PPI computation completed\n');
                        
                     else
                         % If PPIs are already computed then show instructions
                         if isfield(tmfc.ROI_set(tmfc.ROI_set_number),'gPPI') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).PPI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).PPI == 1
                             PPI_recompute(); % Dialouge box for Recomputation
                             fprintf('Recompute VOIs to change conditions\n');
                        else
                            % Continue processing PPIs 
                            
                            % Confirmation if user wants to Continue or Cancel
                            STATUS = tmfc_continue_GUI(V_PPI, 5);
                            
                            % Processing Continue PPIs
                            if STATUS == 0
                                sub_check = tmfc_PPI(tmfc,tmfc.ROI_set_number, V_PPI);
                                for i=V_PPI:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = sub_check(i);
                                end
                                fprintf('PPI computation completed\n');
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
                
    catch 
        warning('Please select subjects & compute VOIs to perform PPI computation');
    end   
    
    % UnFreeze TMFC Main Window
    MW_Freeze(0);
    
end % Closing PPI function

%% =============================== [ gPPI ] ===============================
% Performing gPPI processing for ROI sets
% Dependencies: 
%       - tmfc_gPPI.m                   (External)
%       - tmfc_ROI_to_ROI_contrast      (External)
%       - tmfc_seed_to_voxel_contrast   (External)
%       - tmfc_specify_contrasts_GUI    (External)
%       - tmfc_continue_GUI()           (Internal)

function gPPI(ButtonH, EventData, TMFC_GUI)
               
            
    % Checking for subjects selection
    try 
        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);    
        MW_Freeze(1);
                
        % Track & Update gPPI progress to TMFC variable & Window 
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
        
        % Update gPPI progress to TMFC variable & Window 
        try
            SZ_tmfc = size(tmfc.subjects);
            V_gPPI = 0;
            for i = 1:SZ_tmfc(2)
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI == 0
                    V_gPPI = i ;
                    break;
                end
            end
        end
        
        % Check if subjects have been selected
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
            % Check if ROI set has been selected
            if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
            
                % Check if PPIs has been computed
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).PPI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).PPI == 1
                    
                    % First time execution 
                    if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions) && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).gPPI == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).gPPI == 0
                        
                        fprintf('\n Initiating gPPI computation\n');
                        
                        % Processing gPPIs & generation of default contrasts
                        [sub_check, contrasts] = tmfc_gPPI(tmfc,tmfc.ROI_set_number, 1);
                        
                        % Assigning progress of contrasts, gPPI to TMFC
                        for i = 1:length(contrasts)
                            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(i).title = contrasts(i).title;
                            tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI(i).weights = contrasts(i).weights;
                        end
                        for i=1:length(tmfc.subjects)
                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI = sub_check(i);
                        end
                        fprintf('gPPI computation completed\n');
                        
                    else
                        % Selection of Contrasts
                        if isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI, 'conditions') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).gPPI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).gPPI == 1
                             fprintf('\nContinue to select contrasts\n');
                             
                             % Variable to store length of previously selected contrasts
                             verify_tmfc = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI);
                             
                             % Selection of Contrasts
                             tmfc = tmfc_specify_contrasts_GUI(tmfc, tmfc.ROI_set_number, 1);

                             % if new contrasts added then proceed with processing
                             if verify_tmfc ~= length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI)    
                                 
                                 % Perform computation of gPPI for all newly added contrasts
                                 for i = verify_tmfc+1:length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI)
                                     
                                     % ROI to ROI generation
                                     sub_check_roi = tmfc_ROI_to_ROI_contrast(tmfc, 1, i, tmfc.ROI_set_number);                           
                                     if sub_check_roi(length(tmfc.subjects)) == 1
                                         fprintf('ROI-ROI contrasts succefully generated for contrast №: %d\n', i);
                                     else
                                         disp('ROI-ROI contrasts failed');
                                     end
                                     
                                     % Seed to Voxel generation
                                     sub_check_svox = tmfc_seed_to_voxel_contrast(tmfc, 1,i, tmfc.ROI_set_number);
                                      if sub_check_svox(length(tmfc.subjects)) == 1
                                         fprintf('Seed-Voxel contrasts succefully generated for contrast №: %d\n', i);
                                     else
                                         disp('Seed-Voxel contrasts failed');
                                     end
                                     
                                 end
                             end
                             
                        else
                            % Continue gPPI Computation
                            STATUS = tmfc_continue_GUI(V_gPPI, 6);
                            
                            % Processing gPPI 
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
        
    catch
        warning('Please select subjects & compute PPIs to perform gPPI computation');
    end
    
    % Unfreeze TMFC Main Window
    MW_Freeze(0);
            
end % Closing gPPI function

%% ============================= [ gPPI FIR ] =============================
% Performing gPPI FIR processing for ROI sets
% Dependencies: 
%       - tmfc_gPPI_FIR.m               (External)
%       - tmfc_ROI_to_ROI_contrast      (External)
%       - tmfc_seed_to_voxel_contrast   (External)
%       - tmfc_specify_contrasts_GUI    (External)
%       - tmfc_FIR_GUI()                 (Internal)
%       - tmfc_continue_GUI()           (Internal)

function gPPI_FIR(ButtonH, EventData, TMFC_GUI)
            
    % Checking for subjects selection
    try 
        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);    
        MW_Freeze(1);
        
        % Track & Update gPPI FIR progress to TMFC variable & Window
        try
        V_gPPI_FIR = 0;
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
        
        % Update gPPI FIR progress to TMFC variable & Window 
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
        
        % Check if subjects have been selected
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
            % Check if ROI set has been selected
            if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
            
                % Check if PPIs has been computed
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).PPI == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).PPI == 1
                    
                    % First time execution 
                    if isstruct(tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions) && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).gPPI_FIR == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).gPPI_FIR == 0 && ~isfield(tmfc, 'gPPI_FIR') 
                            
                            % Selection of Windows & Bins
                            [tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.window,tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.bins] = tmfc_FIR_GUI(0);
                            
                            % If windows & Bins are selected continue processing
                            if ~isnan(tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.window) || ~isnan(tmfc.ROI_set(tmfc.ROI_set_number).gPPI_FIR.bins)
                                
                                fprintf('\n Initiating gPPI FIR computation\n');
                                
                                % Processing gPPIs & generation of default contrasts
                                [sub_check, contrasts] = tmfc_gPPI_FIR(tmfc,tmfc.ROI_set_number, 1);
                                
                                % Assigning progress of contrasts, gPPI to TMFC
                                for i = 1:length(contrasts)
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(i).title = contrasts(i).title;
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR(i).weights = contrasts(i).weights;
                                end
                                for i=1:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR = sub_check(i);
                                end
                                fprintf('gPPI FIR computation completed\n');
                            end
                        
                    else
                        % Selection of Contrasts case
                        if isfield(tmfc.ROI_set(tmfc.ROI_set_number).gPPI, 'conditions') && tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).gPPI_FIR == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).gPPI_FIR == 1
                             fprintf('\nContinue to select contrasts\n');
                             
                             % Variable to store length of previously selected contrasts
                             verify_tmfc = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR);
                             
                             % Selection of Contrasts
                             tmfc = tmfc_specify_contrasts_GUI(tmfc, tmfc.ROI_set_number, 2);

                             % if new contrasts added then proceed with processing
                             if verify_tmfc ~= length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI_FIR)      
                                 
                                 % Perform computation of gPPI FIR for all newly added contrasts
                                 for i=verify_tmfc+1:length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.gPPI)
                                     
                                     % ROI to ROI generation
                                     sub_check_roi = tmfc_ROI_to_ROI_contrast(tmfc, 2, i, tmfc.ROI_set_number);                           
                                     if sub_check_roi(length(tmfc.subjects)) == 1
                                         fprintf('ROI-ROI contrasts succefully generated for contrast №: %d\n', i);
                                     else
                                         disp('ROI-ROI contrasts failed');
                                     end
                                     
                                     % Seed to Voxel generation
                                     sub_check_svox = tmfc_seed_to_voxel_contrast(tmfc, 2, i, tmfc.ROI_set_number);
                                      if sub_check_svox(length(tmfc.subjects)) == 1
                                         fprintf('Seed-Voxel contrasts succefully generated for contrast №: %d\n', i);
                                     else
                                         disp('Seed-Voxel contrasts failed');
                                      end
                                      
                                 end
                                 
                             end
                             
                        else
                            % Continue gPPI FIR Computation
                            STATUS = tmfc_continue_GUI(V_gPPI_FIR, 7);
                            
                            % Processing gPPI FIR
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
        
    catch
        warning('Please select subjects & compute PPIs to perform gPPI computation');
    end
    % Unfreeze TMFC Main Window
    MW_Freeze(0);
    
end % Closing gPPI FIR function

%% ============================[ LSS GLM ]=================================
% Performing LSS GLM processing 
% Dependencies: 
%       - tmfc_LSS_GUI.m          (External)
%       - tmfc_LSS.m              (External)
%       - tmfc_restart_GUI()      (Internal)
%       - tmfc_continue_GUI()     (Internal)

function LSS_GLM(ButtonH, EventData, TMFC_GUI)

    try
        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);           
        MW_Freeze(1);
        
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
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            elseif V_LSS == 1
                set(handles.TMFC_GUI_S6,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
            else
                set(handles.TMFC_GUI_S6,'String', strcat(num2str(V_LSS-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
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
                    if any(tmfc.subjects(SZ_tmfc(2)).LSS.session(SZS_tmfc).condition(tmfc.LSS.conditions.number).trials == 1)

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
                                    if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'))
                                        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'),'s');
                                    end
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
                                    if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'))
                                        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS'),'s');
                                    end
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
        
    % Unfreeze TMFC Main Window
    MW_Freeze(0);
        
end

%% ================================ [ BSC ] ===============================
% Performing BSC LSS processing 
% Dependencies: 
%       - tmfc_BSC.m                         (External)
%       - tmfc_specify_contrasts_GUI.m       (External)
%       - tmfc_ROI_to_ROI_contrast.m         (External)
%       - tmfc_seed_to_voxel_contrast.m      (External)

function BSC(buttonH, EventData, TMFC_GUI)

    % Checking for subjects selection
    try
        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);
        MW_Freeze(1);
        
        % Track & Update BSC progress to TMFC variable & Window
        try
            V_BSC = 0;
            for subi = 1:length(tmfc.subjects)
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS','Beta_series',['Subject_' num2str(subi,'%04.f') '_beta_series.mat']), 'file')
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).BSC = 1;
                else
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).BSC = 0;
                end
            end
            
        end
        
        % Update BSC progress to TMFC variable 
        try
            SZ_tmfc = size(tmfc.subjects);
            V_BSC = 0;
            for i = 1:SZ_tmfc(2)
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BSC == 0
                    V_BSC = i ;
                    break;
                end
            end           
        end
        
        % Track & Store the number of Conditions, Sessions & Trials for LSS
        try
           SZC_tmfc = size(tmfc.LSS.conditions);
           post = tmfc.subjects(length(tmfc.subjects)).LSS.session(max(tmfc.LSS.conditions.sess)).condition(SZC_tmfc(2)).trials; 
        end
        
        
        % Check if Seubjects have been selected
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
            
            % Check if LSS has been computed
            if isfield(tmfc.subjects, 'LSS')
                
                % Check if all LSS variables have been processed
                if ~any(post == 0)
                    
                    % Check if ROI set has been selected
                    if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
                        
                        if tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).BSC == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).BSC == 0                           
                                % First time execution of BSC
                                
                                fprintf('\nInitiating BSC LSS computation\n');   
                                
                                 % Processing BSC LSS & generation of default contrasts
                                [sub_check, contrasts] = tmfc_BSC(tmfc,tmfc.ROI_set_number);
                                
                                % Assigning progress of contrasts, BSC to TMFC
                                for i = 1:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BSC = sub_check(i);
                                end
                                for i = 1:length(contrasts)
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(i).title = contrasts(i).title;
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC(i).weights = contrasts(i).weights;
                                end
                                fprintf('BSC LSS computation completed\n');
                                
                        else
                            
                            % Restart Case
                            if tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).BSC == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).BSC == 1
                                fprintf('\nBSC has been completely calcualted using the LSS settings of %d Sessions and %d Conditions. \n', max(tmfc.LSS.conditions.sess), SZC_tmfc(2));
                                fprintf('To calcualte BSC with different settings, please recompute LSS BSC with desrided combination of sessions and conditions \n');         
                                fprintf('\nContinue to select contrasts\n');
                                
                                % Variable to store length of previously selected contrasts
                                verify_tmfc = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC);
                                 
                                 % Selection of Contrasts
                                 tmfc = tmfc_specify_contrasts_GUI(tmfc, tmfc.ROI_set_number, 3);
                                 
                                 % if new contrasts added then proceed with processing
                                 if verify_tmfc ~= length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC)       
                                     
                                     % Perform computation of BSC for all newly added contrasts
                                     for i = verify_tmfc+1:length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC)
                                         
                                         % ROI to ROI generation
                                         sub_check_roi = tmfc_ROI_to_ROI_contrast(tmfc, 3, i, tmfc.ROI_set_number);                           
                                         if sub_check_roi(length(tmfc.subjects)) == 1
                                             fprintf('ROI-ROI contrasts succefully generated for contrast №: %d\n', i);
                                         else
                                             fprintf('ROI-ROI contrasts failed\n');
                                         end
                                         
                                         % Seed to Voxel generation
                                         sub_check_svox = tmfc_seed_to_voxel_contrast(tmfc, 3, i, tmfc.ROI_set_number);
                                          if sub_check_svox(length(tmfc.subjects)) == 1
                                             fprintf('Seed-Voxel contrasts succefully generated for contrast №: %d\n', i);
                                         else
                                             fprintf('Seed-Voxel contrasts failed\n');
                                          end
                                          
                                     end
                                     
                                 end                                 
                                 
                            else
                                % Restart computations
                                
                                % Processing BSC computation
                                fprintf('\nInitiating BSC LSS computation\n'); 
                                sub_check = tmfc_BSC(tmfc,tmfc.ROI_set_number);
                                for i = 1:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BSC = sub_check(i);
                                end
                                fprintf('\nBSC computation completed\n');
                                
                            end
                            
                        end
                        
                    else
                        warning('Please select ROIs to continue with BSC computation');
                    end
                    
                else
                    warning('Please complete LSS GLM computation to proceed with BSC computation');
                end
                
            else
                warning('Please compute LSS GLM for the selected subjects to proceed with computation of Beta Series Correlation');
            end
            
        else
            warning('Please select subjects and compute LSS GLM to proceed with BSC computaiton');
        end
        
        
    catch
        warning('Please select subjects & compute LSS GLM to perform BSC computation');    
    end
    
    % Unfreeze TMFC Main Window
    MW_Freeze(0);
    
end

%% ========================[ FIR Regression ]==============================
% Performing FIR processing 
% Dependencies: 
%       - tmfc_FIR.m             (External)
%       - tmfc_FIR_GUI()         (Internal)
%       - tmfc_restart_GUI()     (Internal)
%       - tmfc_continue_GUI()    (Internal)

function FIR(ButtonH, EventData, TMFC_GUI)
    
    % Checking for subjects selection
    try

        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);           
        MW_Freeze(1);

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
            for i = 1:SZ_tmfc(2)
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

        % Check if subjects have been selected
        if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')

            % Checking if FIR has been executed before
            if ~isfield(tmfc, 'FIR') 

                % Ask user for Bins & windows
                [tmfc.FIR.window,tmfc.FIR.bins] = tmfc_FIR_GUI(0);


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


            elseif isfield(tmfc, 'FIR') && tmfc.subjects(1).FIR == 0 
                % Exeuction if CTLR + C is pressed 

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
                                    if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'))
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
                                    if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BGFC'))
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

    catch
       warning('Please select subjects & project path to perform FIR regression');
    end 
    
     % Unfreeze TMFC Main Window
    MW_Freeze(0);
    
end

%% =============================== [ BGFC ] ===============================
% Performing BGFC processing 
% Dependencies: 
%       - tmfc_BGFC.m            (External)
%       - tmfc_continue_GUI()    (Internal)
%       - recompute_BGFC()       (Internal)

function BGFC(buttonH, EventData, TMFC_GUI)

    % Checking for subjects selection
    try 
       
       % Change to project directory & Freeze TMFC Window
       cd(tmfc.project_path); 
       MW_Freeze(1);
       
       % Track & Update BGFC progress to TMFC variable & Window 
       try
           V_BGFC = 0;
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
       
       % Update BGFC progress to TMFC variable & Window 
       try
            SZ_tmfc = size(tmfc.subjects);
            V_BGFC = 0;
            for i = 1:SZ_tmfc(2)
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BGFC == 0
                    V_BGFC = i ;
                    break;
                end
            end
        end

       % Check if subjects have been selected
       if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
           
           % Check if FIR has been processed for BGFC
           if isfield(tmfc.subjects, 'FIR') 

               % If FIR has been processed
               if ~tmfc.subjects(length(tmfc.subjects)).FIR == 0 
                   
                 % If ROI set has been selected
                 if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
                     
                    % Computation of BGFC condition
                    if tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).BGFC == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).BGFC == 0
                    
                        % First time execution
                        
                        fprintf('\nInitiating BGFC computation\n');
                        % Processing of BGFC Computation
                        sub_check = tmfc_BGFC(tmfc,tmfc.ROI_set_number, 1);
                        for i=1:length(tmfc.subjects)
                            tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BGFC = sub_check(i);
                        end
                        fprintf('BGFC computation completed\n');
                    
                    else
                        % Other cases of Restart/continue
                        
                        % If BGFC is completely computed, then show message
                        if tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).BGFC == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).BGFC == 1
                            fprintf('BGFC has been completely calcualted using the FIR settings of %d Windows and %d bins. \n', tmfc.FIR.window,tmfc.FIR.bins);
                            fprintf('To calcualte BGFC with different settings, please recompute FIR with desrided combination of windows and bins \n');         
                            recompute_BGFC(tmfc);
                            
                        else
                            
                            % Continue BGFC computation
                            
                            % Ask user for continue or cancel
                            STATUS = tmfc_continue_GUI(V_BGFC, 8);
                            if STATUS == 0
                                
                                fprintf('\nContinuing BGFC computation \n');
                                sub_check = tmfc_BGFC(tmfc,tmfc.ROI_set_number, V_BGFC);
                                for i=V_BGFC:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BGFC = sub_check(i);
                                end
                                fprintf('BGFC computation completed\n');
                                
                            else
                                
                                warning('BGFC computation not initiated');
                            end
                                
                        end
                        
                    end
                    
                 else
                    warning('Please select ROIs to continue with BGFC computation');                    
                 end

               else
                   warning('Please complete FIR computation to proceed with BGFC computation');
               end
               
           else
               warning('Please compute FIR for the selected subjects to proceed with computation of Background connectivity function');
           end
           
       else
           warning('Please select subjects and compute FIR to proceed with BGFC computaiton');
       end
               
    catch
        warning('Please select subjects & compute FIRs to perform BGFC computaiton');
    end
    
   % Unfreeze TMFC Main Window
   MW_Freeze(0);
    
end

%% ============================[ LSS FIR ]=================================
% Performing LSS FIR processing 
% Dependencies: 
%       - tmfc_LSS_GUI.m            (External)
%       - tmfc_LSS_after_FIR.m      (External)
%       - tmfc_restart_GUI()        (Internal)
%       - tmfc_continue_GUI()       (Internal)
    
function LSS_FIR(ButtonH, EventData, TMFC_GUI)

    % Checking for subjects selection
    try
        % Change to project directory & Freeze TMFC Window
        cd(tmfc.project_path);           
        MW_Freeze(1);

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
                    set(handles.TMFC_GUI_S10,'String', strcat(num2str(SZ_tmfc(2)), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
                elseif V_LSS == 1
                    set(handles.TMFC_GUI_S10,'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);       
                else
                    set(handles.TMFC_GUI_S10,'String', strcat(num2str(V_LSS-1), '/', num2str(SZ_tmfc(2)), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
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
                        if any(tmfc.subjects(SZ_tmfc(2)).LSS_after_FIR.session(SZS_tmfc).condition(tmfc.LSS_after_FIR.conditions.number).trials == 1)

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
                                        if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'))
                                            rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'),'s');
                                        end
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
                                        if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'))
                                            rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR'),'s');
                                        end
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
    
    % Unfreeze TMFC Main Window
    MW_Freeze(0);
        
end

%% =========================== [ BSC after FIR] ===========================
% Performing BSC FIR processing 
% Dependencies: 
%       - tmfc_BSC_after_FIR.m            (External)
%       - tmfc_specify_contrasts_GUI.m    (External)
%       - tmfc_ROI_to_ROI_contrast.m      (External)
%       - tmfc_seed_to_voxel_contrast.m   (External)

function BSC_after_FIR(ButtonH, EventData, TMFC_GUI)

    % Checking for subjects selection
    try
       % Change to project directory & Freeze TMFC Window
       cd(tmfc.project_path);
       MW_Freeze(1);
       
       % Track & Update BSC FIR progress to TMFC variable & Window
       try
           V_BSC = 0;
            for subi = 1:length(tmfc.subjects)
                if exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(tmfc.ROI_set_number).set_name,'BSC_LSS_after_FIR','Beta_series',['Subject_' num2str(subi,'%04.f') '_beta_series.mat']), 'file')
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).BSC_after_FIR = 1;
                else
                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(subi).BSC_after_FIR = 0;
                end
            end 
       end
       
       % Update BSC progress to TMFC variable 
       try
           SZ_tmfc = size(tmfc.subjects);
            V_BSC = 0;
            for i = 1:SZ_tmfc(2)
                % checking status of BSC completion
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BSC_after_FIR == 0
                    V_BSC = i ;
                    break;
                end
            end    
       end
       
       % Track & Store the number of Conditions, Sessions, trial LSS for FIR
       try
           SZC_tmfc = size(tmfc.LSS_after_FIR.conditions);
           post = tmfc.subjects(length(tmfc.subjects)).LSS_after_FIR.session(max(tmfc.LSS_after_FIR.conditions.sess)).condition(SZC_tmfc(2)).trials; 
       end
       
       % Check if Seubjects have been selected
       if isfield(tmfc,'subjects') && ~strcmp(tmfc.subjects(1).path, '')
           
           % Check if LSS FIR has been computed
           if isfield(tmfc.subjects, 'LSS_after_FIR')
               
               % Check if all LSS FIR variables have been processed
               if ~any(post == 0)
                   
                   % Check if ROI set has been selected
                   if isfield(tmfc, 'ROI_set_number') && isstruct(tmfc.ROI_set)
                       
                        if tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).BSC_after_FIR == 0 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).BSC_after_FIR == 0
                                % First time execution of BSC
                                
                                fprintf('\nInitiating BSC after FIR computation\n');  
                                
                                % Processing BSC LSS & generation of default contrasts
                                [sub_check, contrasts] = tmfc_BSC_after_FIR(tmfc,tmfc.ROI_set_number);
                                
                                % Assigning progress of contrasts, BSC FIR to TMFC
                                for i = 1:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BSC_after_FIR = sub_check(i);
                                end
                                for i = 1:length(contrasts)
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(i).title = contrasts(i).title;
                                    tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR(i).weights = contrasts(i).weights;
                                end
                                fprintf('BSC after FIR computation completed\n');
                                
                        else
                            
                            % Restart case
                            if tmfc.ROI_set(tmfc.ROI_set_number).subjects(1).BSC_after_FIR == 1 && tmfc.ROI_set(tmfc.ROI_set_number).subjects(length(tmfc.subjects)).BSC_after_FIR == 1
                                fprintf('\nBSC after FIR has been completely calcualted using the LSS FIR settings of %d Sessions and %d Conditions. \n', max(tmfc.LSS_after_FIR.conditions.sess), SZC_tmfc(2));
                                fprintf('To calcualte BSC after FIR with different settings, please recompute LSS FIR with desrided combination of sessions and conditions \n');         
                                fprintf('\nContinue to select contrasts\n');
                                
                                % Variable to store length of previously selected contrasts
                                verify_tmfc = length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR);
                                
                                 % Selection of Contrasts
                                 tmfc = tmfc_specify_contrasts_GUI(tmfc, tmfc.ROI_set_number, 4);

                                 % if new contrasts added then proceed with processing
                                 if verify_tmfc ~= length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR)      
                                     
                                     % Perform computation of BSC FIR for all newly added contrasts
                                     for i=verify_tmfc+1:length(tmfc.ROI_set(tmfc.ROI_set_number).contrasts.BSC_after_FIR)
                                         
                                         % ROI to ROI generation
                                         sub_check_roi = tmfc_ROI_to_ROI_contrast(tmfc, 4, i, tmfc.ROI_set_number);                           
                                         if sub_check_roi(length(tmfc.subjects)) == 1
                                             fprintf('ROI-ROI contrasts succefully generated for contrast №: %d\n', i);
                                         else
                                             fprintf('ROI-ROI contrasts failed\n');
                                         end
                                         
                                         % Seed to Voxel generation
                                         sub_check_svox = tmfc_seed_to_voxel_contrast(tmfc, 4, i, tmfc.ROI_set_number);
                                          if sub_check_svox(length(tmfc.subjects)) == 1
                                             fprintf('Seed-Voxel contrasts succefully generated for contrast №: %d\n', i);
                                         else
                                             fprintf('Seed-Voxel contrasts failed\n');
                                         end
                                          
                                     end
                                    
                                 end
                                 
                            else
                                % Restart Computation
                                
                                % Processing BSC FIR computation
                                sub_check = tmfc_BSC_after_FIR(tmfc,tmfc.ROI_set_number);
                                for i = 1:length(tmfc.subjects)
                                    tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BSC_after_FIR = sub_check(i);
                                end
                                fprintf('\nBSC after FIR computation completed\n');
                            end
                            
                        end
                   
                   else
                        warning('Please select ROIs to continue with BSC computation');
                   end
                       
               else
                   warning('Please complete LSS FIR computation to proceed with BSC after FIR computation');
               end
               
           else
                warning('Please compute LSS FIR for the selected subjects to proceed with computation of Beta Series Correlation');
           end
           
       else
           warning('Please select subjects and compute LSS FIR to proceed with BSC after FIR computaiton');
       end
       
    catch
        warning('Please select subjects & compute LSS FIR to perform BSC after FIR computation');    
    end
    
   % Unfreeze TMFC Main Window
   MW_Freeze(0);
    
end

%% ==========================[ Load project ]==============================
% Loading of (*.mat) into TMFC toolbox
% Dependencies:
%       - evaluate_file() (Internal)

function open_project(ButtonH, EventData, TMFC_GUI)

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

        % Evaluate file & Update TMFC, TMFC window with progress
        tmfc = evaluate_file(tmfc);
        fprintf('Successfully loaded file "%s.m"\n', filename_LO);
    else
        warning('No file selected to load');
    end

end  % Closing Load project function

%% ==========================[ Save project ]==============================
% Function to perform Saving of TMFC variable from workspace to individual .m file in user desired location
% Dependencies:
%       - saver() (Internal)

function save_stat = save_project(ButtonH, EventData, TMFC_GUI)
       
    % Ask user for Filename & location name:
    [filename_SO, pathname_SO] = uiputfile('*.mat', 'Save TMFC variable as'); %pwd
    
    % Set Flag save status to Zero, this flag is used in the future as
    % a reference to check if the Save was successful or not
    save_stat = 0;
    
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
        save_stat = saver(fullpath);
        
        % If the variable was successfully saved then display info
        if save_stat == 1
            fprintf('File saved successfully in path: %s\n', fullpath);
        else
            fprintf('File not saved ');
        end
    end
          
end % Closing Save project Function

%% ==========================[ Change Paths ]==============================
% Function to perform Change paths of TMFC subjects
% Dependencies:
%       - tmfc_select_subjects_GUI.m (External)

function change_paths(ButtonH, EventData, TMFC_GUI)
    
    fprintf('\nSelect subjects whose paths are to be changed...\n');
    
        % Use Select subjects.m WITHOUT 4 Stage file check
        D = tmfc_select_subjects_GUI(0);  
        
        if ~isempty(D)
            tmfc_change_paths_GUI(D);  
        else
            fprintf('\nNo subject files selected for path change\n');
        end
    
end % Closing ChangePath Function

%% ============================[ Settings ]================================
% Function to setup & change presets of TMFC Toolbox

% Variables for Settings GUI
SET_COMPUTING = {'Sequential computing', 'Parallel computing'};
SET_STORAGE = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
SET_SEED = {'Seed-to-voxel and ROI-to-ROI','ROI-to-ROI','Seed-to-voxel only'};

function settings(ButtonH, EventData, TMFC_GUI)
        
    % Create the Main figure for settings Window
    TMFC_SET = figure('Name', 'TMFC Toolbox','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'norm', 'Position', [0.380 0.0875 0.250 0.850], 'color', 'w', 'Tag', 'TMFC_GUI_Settings','resize', 'off','WindowStyle','modal');
    
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
    TMFC_SET_E1 = uicontrol(TMFC_SET,'Style','edit','String', tmfc.defaults.maxmem,'Units', 'normalized', 'HorizontalAlignment', 'center','Position',[0.72 0.615 0.22 0.05],'fontunits','normalized', 'fontSize', 0.38);
    
    TMFC_SET_S1 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_1,'Units', 'normalized', 'Position',[0.05 0.87 0.90 0.07],'fontunits','normalized','fontSize', 0.265, 'HorizontalAlignment', 'left','backgroundcolor','w');
    TMFC_SET_S2 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_2,'Units', 'normalized', 'Position',[0.05 0.69 0.90 0.11],'fontunits','normalized','fontSize', 0.16, 'HorizontalAlignment', 'left','backgroundcolor','w');
    TMFC_SET_S3_1 = uicontrol(TMFC_SET,'Style','text','String', 'Max RAM for GLM esimtation (bits):','Units', 'normalized', 'Position',[0.048 0.61 0.65 0.04],'fontunits','normalized', 'fontSize', 0.46,'HorizontalAlignment', 'left','backgroundcolor','w');%
    TMFC_SET_S3_2 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_3a,'Units', 'normalized', 'Position',[0.05 0.50 0.90 0.11],'fontunits','normalized','fontSize', 0.175, 'HorizontalAlignment', 'left','backgroundcolor','w');
    TMFC_SET_S3_3 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_3b,'Units', 'normalized', 'Position',[0.11 0.38 0.27 0.11],'fontunits','normalized','fontSize', 0.165, 'HorizontalAlignment', 'left','backgroundcolor','w');
    TMFC_SET_S4 = uicontrol(TMFC_SET,'Style','text','String', SET_TEXT_4,'Units', 'normalized', 'Position',[0.05 0.11 0.90 0.20],'fontunits','normalized','fontSize', 0.088, 'HorizontalAlignment', 'left','backgroundcolor','w');
    
    set(TMFC_SET_OK , 'callback', @OK_SYNC);   



    TMFC_SET_COPY = tmfc;

    % The following functions perform Synchronization after OK button has been pressed 
    function OK_SYNC(~,~)

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

%% =============================[ Close ]==================================
 
% Function to peform Save & Exit from TMFC function. 
% This function is linked to the close button on the top right handside of the Window

function close_GUI(ButtonH, EventData, TMFC_GUI) 
       
    % Exit Dialouge GUI
    EXIT_PROMPT = figure('Name', 'TMFC: Exit', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.20 0.15],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'EXIT_FIN', 'WindowStyle','modal'); %X Y W H

    % Content - Can be changed to a single sentence using \html or
    % sprtinf
    EX_Q1 = uicontrol(EXIT_PROMPT,'Style','text','String', 'Would you like to save your progress','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);
    EX_Q2 = uicontrol(EXIT_PROMPT,'Style','text','String', 'before exiting TMFC toolbox?', 'Units','normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);

    % Buttons of the GUI
    EX_YES = uicontrol(EXIT_PROMPT,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.40);
    EX_NO = uicontrol(EXIT_PROMPT,'Style','pushbutton', 'String', 'No','Units', 'normalized','fontunits','normalized', 'fontSize', 0.40);

    % Spawn Positions of the GUI text boxes & buttons
    EX_Q1.Position = [0.04 0.55 0.94 0.260];
    EX_Q2.Position = [0.10 0.40 0.80 0.260];
    EX_YES.Position = [0.16 0.18 0.300 0.200];
    EX_NO.Position = [0.57 0.18 0.300 0.200];

    % Colour of Text boxes & actions of buttons
    set([EX_Q1,EX_Q2],'backgroundcolor',get(EXIT_PROMPT,'color'));
    set(EX_NO, 'callback', @EX_WO_SAVE);
    set(EX_YES, 'callback', @EX_W_SAVE);
       
        
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
        CT_1 = save_project();
        
        % Based on the result of successful save, TMFC toolbox is
        % closed (i.e. Save->Save Status-> Close Main GUI)
        if CT_1 == 1
            close(EXIT_PROMPT);
            delete(handles.TMFC_GUI);
            disp('Goodbye!');
        end
        
    end
    
end 

%% ===========================[ Reset ]===================================
function reset(ButtonH, EventData, TMFC_GUI)
    assignin('base', 'tmfc', tmfc);
    fprintf('\nCurrent TMFC variable has been saved to workspace\n');
end

%% =====================[ Supporting Functions ]===========================

% GUI Data Sync for TMFC Main Window
try 
    guidata(handles.TMFC_GUI, handles);
end


% Freeze/Unfreeze TMFC Window 
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


% Reset TMFC Window & Variable after new Subjects are selected
function [tmfc] = major_reset(tmfc)

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


% Function to update & intialize progress of VOI, PPI, gPPI, gPPI_FIR
function [tmfc] = update_gPPI(tmfc)

    % Track & Update VOI progress with genearted files
    try
        V_VOI = 0;
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

    % Update VOI progress to TMFC variable & Window 
    try
        SZ_tmfc = size(tmfc.subjects);
        V_VOI = 0;
        for i = 1:SZ_tmfc(2)
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

    % Track & Update PPI progress with genearted files
    try
        V_PPI = 0;
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
    
    % Update PPI progress to TMFC variable & Window 
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

    % Track & Update gPPI progress with genearted files
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
    
    % Update gPPI progress to TMFC variable & Window 
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

    % Track & Update gPPI_FIR progress with genearted files
    try
        V_gPPI_FIR = 0;
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
    
    % Update gPPI_FIR progress to TMFC variable & Window 
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


% Function to perform Independent saving & return of save status, where
function SAVER_STAT =  saver(save_path)
% 0 - Successfull save, 1 - Failed save
    try 
        save(save_path, 'tmfc');
        SAVER_STAT = 1;
        % Save Success
    catch 
        SAVER_STAT = 0;
        % Save Fail 
    end
end


% Function to reset VOI, PPI, gPPI, gPPI_FIR & conditions based on cases
function [tmfc] = reset_gPPI(tmfc, cases)
    
    switch (cases)
        
        case 1
            % Reset VOI, PPI, gPPI, gPPI FIR & gPPI Conditions       
            for i=1:length(tmfc.subjects)
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = 0;
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = 0;
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI = 0;
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR = 0;
            end
            set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
            tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions = [];
    
        case 2 
            % Reset PPI, gPPI 
            for i=1:length(tmfc.subjects)
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = 0;
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI = 0;
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR = 0;
            end
            set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
            
        
        case 3
            % Reset all VOI, PPI, gPPI, gPPI FIR        
            for i=1:length(tmfc.subjects)
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).VOI = 0;
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).PPI = 0;
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI = 0;
                tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).gPPI_FIR = 0;
            end
            set(handles.TMFC_GUI_S4, 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067]);
    end

end


% function to update the TMFC window after loading a tmfc project
function tmfc = evaluate_file(tmfc) 
    
    try
        MW_Freeze(1);
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
            V_BGFC = 0;
            for i = 1:SZ_tmfc(2)
                % checking status of BGFC completion
                if tmfc.ROI_set(tmfc.ROI_set_number).subjects(i).BGFC == 0
                    V_BGFC = i ;
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
            condi = 0;
            if SZC_tmfc(2) == 1 
                condi = tmfc.LSS_after_FIR.conditions.number;
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
     
     MW_Freeze(0);
    catch
        warning('Error with reading save file');
    end
    
end


function [tmfc] = reset_BGFC(tmfc)
    if isfield(tmfc.ROI_set(tmfc.ROI_set_number).subjects(1),'BGFC') 
        
    end
end

% =================================[ END ]=================================

end  
%% =================[ Independent Supporting Functions ]===================

%% Project Path Selection Diagloue 
function tmfc_select_project_path(S)
% Function to show Warning Dialouge for selection of subjects project path 
    TMFC_SS_PP = figure('Name', 'Select project paths', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.24 0.14],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @OKAY, 'Tag', 'TMFC_project_path');
    PP_details = {'Next, select the project path where all results and temporary files will be stored'};
    TMFC_SS_PP_S1 = uicontrol(TMFC_SS_PP,'Style','text','String',strcat(num2str(S), ' subjects selected'),'Units', 'normalized', 'Position',[0.30 0.72 0.40 0.17],'backgroundcolor','w','fontunits','normalized','fontSize', 0.64,'ForegroundColor',[0.219, 0.341, 0.137]);
    TMFC_SS_PP_S2 = uicontrol(TMFC_SS_PP,'Style','text','String',PP_details,'Units', 'normalized', 'Position',[0.055 0.38 0.90 0.30],'backgroundcolor','w','fontunits','normalized','fontSize', 0.38);
    OK = uicontrol(TMFC_SS_PP,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.35 0.12 0.3 0.2],'fontunits','normalized','fontSize', 0.42);
    set(OK, 'callback', @OKAY);
    movegui(TMFC_SS_PP,'center');
    
    function OKAY(~,~)
        delete(TMFC_SS_PP);
    end
    uiwait();
end

%% ROI Set related functions
function [tmfc] = ROI_initializer(tmfc)
% Function to reset progress of ROI variables after selection of set
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
function [new_flag, position] = ROI_set(LIST_SETS,~)
% Function to select current ROI set or add new ROI Set
    new_flag = 0;
    position = 0;
    
    ROI_set_GUI = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.28 0.35],'color','w','MenuBar', 'none','ToolBar', 'none');

    ROI_set_GUI_disp = uicontrol(ROI_set_GUI , 'Style', 'listbox', 'String', LIST_SETS(:,2),'Units', 'normalized', 'Position',[0.048 0.25 0.91 0.49],'fontunits','normalized', 'fontSize', 0.09);

    ROI_set_GUI_S1 = uicontrol(ROI_set_GUI,'Style','text','String', 'Select ROI set','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.54);
    ROI_set_GUI_S2 = uicontrol(ROI_set_GUI,'Style','text','String', 'Sets:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.60);
    
    ROI_set_GUI_OK = uicontrol(ROI_set_GUI,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_set_GUI_Select = uicontrol(ROI_set_GUI,'Style','pushbutton', 'String', 'Add new ROI set','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
     
    ROI_set_GUI_S1.Position = [0.31 0.85 0.400 0.09];
    ROI_set_GUI_S2.Position = [0.04 0.74 0.100 0.08];
     
    ROI_set_GUI_OK.Position = [0.16 0.10 0.28 0.10]; % W H
    ROI_set_GUI_Select.Position = [0.56 0.10 0.28 0.10];
    
    selection_3 = {};
    set(ROI_set_GUI_disp, 'Value', 1);
    selection_3 = 1;
    
    set(ROI_set_GUI_S1,'backgroundcolor',get(ROI_set_GUI,'color'));
    set(ROI_set_GUI_S2,'backgroundcolor',get(ROI_set_GUI,'color'));
    set(ROI_set_GUI_disp, 'callback', @action_select_M1);
    
    set(ROI_set_GUI_OK, 'callback', @ROI_set_OK);
    set(ROI_set_GUI_Select, 'callback', @ROI_set_SELECT);
    movegui(ROI_set_GUI,'center');
     
    function action_select_M1(~,~)
        index = get(ROI_set_GUI_disp, 'Value');  % Retrieves the users selection LIVE
        selection_3 = index;    
    end
    
    function ROI_set_OK(~,~)
        new_flag = 0;
        position = selection_3;
        close(ROI_set_GUI);
    end

    function ROI_set_SELECT(~,~)
        new_flag = 1;
        close(ROI_set_GUI);
        position = 0;
    end
    
    uiwait();
    
end

%% Restart - Continue GUI Control Functions
% GUI Function to ask user confirmation for Restart/Cancel, where
    % STATUS = 1 - restart FIR 
    % STATUS = 0 - dont restart FIR 
function [STATUS] = tmfc_restart_GUI(option)


    res_str_0 = '';
    res_str_1 = {};
    
    switch (option)
        case 1
            % FIR
            res_str_0 = 'FIR task regression';
            res_str_1 = {'Recompute FIR task', 'regression for all subjects?'};
        case 2
            % LSS
            res_str_0 = 'LSS GLM regression';
            res_str_1 = {'Recompute LSS GLM', 'regression for all subjects?'};
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
    movegui(TMFC_RES,'center');

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

% GUI Function to ask user confirmation for Continue/restart/cancel, where
    % STATUS = 1 - restart FIR 
    % STATUS = 0 - dont restart FIR 
    % STATUS = -1 - no Action
function [STATUS] = tmfc_continue_GUI(INDEX, option)
    
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
        case 8
            % BGFC
            res_str_0 = 'BGFC computation';
            res_str_1 = {'Continue BGFC computation from'};
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
    movegui(TMFC_CONT,'center');

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

%% Dialouge box for PPI recomputation explanation
function PPI_recompute()
TMFC_PPI_Diag = figure('Name', 'PPI', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.24 0.12],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @OKAY, 'Tag', 'PPI');
    PPI_details = {'PPI computation completed. To change conditions of interest, recompute VOIs'};
    TMFC_PPI_S1 = uicontrol(TMFC_PPI_Diag,'Style','text','String',PPI_details,'Units', 'normalized', 'Position',[0.05 0.5 0.90 0.30],'backgroundcolor','w','fontunits','normalized','fontSize', 0.38);
    OK = uicontrol(TMFC_PPI_Diag,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.38 0.18 0.23 0.2],'fontunits','normalized','fontSize', 0.48);
    movegui(TMFC_PPI_Diag,'center');
    set(OK, 'callback', @OKAY);

    function OKAY(~,~)
        delete(TMFC_PPI_Diag);
    end
    uiwait();

end

%% GUI to select Windows & Bins for FIR & gPPI FIR 
function [win, bin] = tmfc_FIR_GUI(cases)

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
    TMFC_BW_E1 = uicontrol(TMFC_BW,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.67 0.185 0.170], 'fontSize', 0.44);%,'InputType', 'digits');
    TMFC_BW_E2 = uicontrol(TMFC_BW,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'Position', [0.76 0.42 0.185 0.170], 'fontSize', 0.44);
    TMFC_BW_OK = uicontrol(TMFC_BW,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.21 0.13 0.230 0.170]);
    TMFC_BW_HELP = uicontrol(TMFC_BW,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized','fontSize', 0.4, 'Position', [0.52 0.13 0.230 0.170]);

    set(TMFC_BW_S1,'backgroundcolor',get(TMFC_BW,'color'));
    set(TMFC_BW_S2,'backgroundcolor',get(TMFC_BW,'color'));
    set(TMFC_BW_OK, 'callback', @TMFC_BW_EXTRACT);
    set(TMFC_BW_HELP, 'callback', @TMFC_BW_HELP_POP);
    movegui(TMFC_BW,'center');

   
    function TMFC_BW_stable_Exit(~,~)
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
           delete(TMFC_BW);
       end

    end
    uiwait();
end

%% Dialouge box for BGFC recomputation explanation
function recompute_BGFC(tmfc)
TMFC_BGFC_Diag = figure('Name', 'BGFC', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.45 0.24 0.12],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle', 'modal','CloseRequestFcn', @OKAY, 'Tag', 'BGFC');    
    B1 = {strcat('BGFC computation completed using ',32,num2str(tmfc.FIR.window),' Windows & ',32,num2str(tmfc.FIR.bins),' Bins.'),'To change the number of windows & bins, recompute FIRs'};
    TMFC_BGFC_S1 = uicontrol(TMFC_BGFC_Diag,'Style','text','String',B1,'Units', 'normalized', 'Position',[0.05 0.5 0.90 0.30],'fontunits','normalized','fontSize', 0.38,'backgroundcolor','w');
    OK = uicontrol(TMFC_BGFC_Diag,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.35 0.18 0.3 0.24],'fontunits','normalized','fontSize', 0.40);
    
    set(OK, 'callback', @OKAY);
    movegui(TMFC_BGFC_Diag,'center');
    
    function OKAY(~,~)
        delete(TMFC_BGFC_Diag);
    end
    uiwait();

end

% =================================[ END ]=================================
