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
%   tmfc.FIR_window        - FIR window length in [s]
%   tmfc.FIR_bins          - Number of FIR time bins
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

if isempty(findobj('Tag', 'MAIN_WINDOW')) == 1 
    
    % Set up TMFC structure
    tmfc.defaults.parallel = 0;      
    tmfc.defaults.maxmem = 2^31;
    tmfc.defaults.resmem = true;

    tmfc.project_path = '';
    tmfc.subjects(1).path = '';
    
    tmfc.FIR_window = NaN;
    tmfc.FIR_bins = NaN;
    
    tmfc.subjects(1).FIR = [];
    tmfc.subjects(1).LSS_after_FIR = [];
    tmfc.subjects(1).LSS_without_FIR = [];
    
    tmfc.LSS_after_FIR.conditions = [];
    tmfc.LSS_without_FIR.conditions = [];

    tmfc.ROI_set = [];
    
    % Assign TMFC project variables 
    assignin('base', 'tmfc', tmfc);

    % Initializing handles & elements of the GUI    
    handles.MAIN_F = figure('Name', 'TMFC Toolbox', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.26 0.205 0.575], 'MenuBar', 'none', 'ToolBar', 'none', 'color', 'w', 'Resize', 'off', 'Tag', 'MAIN_WINDOW');
    
    % Select subjects
    handles.SUB = uicontrol('Style', 'pushbutton', 'String', 'Subjects', 'Units', 'normalized', 'Position', [0.06 0.86 0.40 0.0715]);
    handles.SUB_stat = uicontrol('Style', 'text', 'String', 'Not selected', 'ForegroundColor', 'red', 'Units', 'normalized', 'Position',[0.55 0.84 0.40 0.0715], 'backgroundcolor', 'w'); 
    
    % FIR task regression
    handles.FIR_TR = uicontrol('Style', 'pushbutton', 'String', 'FIR task regression', 'Units', 'normalized', 'Position', [0.06 0.765 0.40 0.0715]);
    handles.FIR_TR_stat = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position', [0.55 0.745 0.40 0.0715], 'backgroundcolor', 'w');
    
    % LSS after FIR
    handles.LSS_R = uicontrol('Style', 'pushbutton', 'String', 'LSS after FIR', 'Units', 'normalized', 'Position', [0.06 0.669 0.40 0.0715]);
    handles.LSS_R_stat = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position', [0.55 0.653 0.40 0.0715], 'backgroundcolor', 'w');
   
    % LSS without FIR 
    handles.LSS_RW = uicontrol('Style', 'pushbutton', 'String', 'LSS without FIR', 'Units', 'normalized', 'Position', [0.06 0.571 0.40 0.0715]);
    handles.LSS_RW_stat = uicontrol('Style', 'text', 'String', 'Not done', 'ForegroundColor', [0.773, 0.353, 0.067], 'Units', 'normalized', 'Position', [0.55 0.551 0.40 0.0715], 'backgroundcolor', 'w');
   
    % Background connectivity, BSC-LSS, gPPI 
    handles.BGFC = uicontrol('Style', 'pushbutton', 'String', 'Background connectivity', 'Units', 'normalized', 'Position',[0.06 0.475 0.875 0.0715]);
    handles.BSC = uicontrol('Style', 'pushbutton', 'String', 'BSC-LSS','Units', 'normalized', 'Position', [0.06 0.380 0.875 0.0715]);
    handles.gPPI = uicontrol('Style', 'pushbutton', 'String', 'gPPI', 'Units', 'normalized', 'Position', [0.06 0.280 0.875 0.0715]);
   
    % Save project, Open project, Change paths, Settings
    handles.save_p = uicontrol('Style', 'pushbutton', 'String', 'Save project', 'Units', 'normalized', 'Position', [0.06 0.130 0.40 0.0715]);
    handles.open_p = uicontrol('Style', 'pushbutton', 'String', 'Open project', 'Units', 'normalized', 'Position', [0.536 0.130 0.40 0.0715]);
    handles.change_p = uicontrol('Style', 'pushbutton', 'String', 'Change paths', 'Units', 'normalized', 'Position', [0.06 0.038 0.40 0.0715]);
    handles.settings = uicontrol('Style', 'pushbutton', 'String', 'Settings', 'Units', 'normalized', 'Position', [0.536 0.038 0.40 0.0715]);

    % CallBack functions corresponding to each button
    set(handles.MAIN_F, 'CloseRequestFcn', {@Close_TMFC, handles.MAIN_F}); 
    set(handles.save_p, 'callback', {@SAVE_PROJ, handles.MAIN_F});
    set(handles.open_p, 'callback', {@LOAD_PROJ, handles.MAIN_F});
    set(handles.change_p, 'callback', {@CP_GUI, handles.MAIN_F});
    set(handles.settings, 'callback', {@Settings, handles.MAIN_F});
    set(handles.SUB, 'callback', {@SUB_SEL, handles.MAIN_F});
    set(handles.FIR_TR, 'callback', {@FIR_REG, handles.MAIN_F});
    set(handles.LSS_R, 'callback', {@LSS_REG, handles.MAIN_F});
    set(handles.LSS_RW, 'callback', {@LSS_REGW, handles.MAIN_F});
    set(handles.BGFC, 'callback', {@BGFC_EX, handles.MAIN_F});
    set(handles.BSC, 'callback', {@BSC_EX, handles.MAIN_F});
    set(handles.gPPI, 'callback', {@gPPI_EX, handles.MAIN_F});
    
else
    figure(findobj('Tag', 'MAIN_WINDOW')); 
    warning('TMFC toolbox is already running');    
end
    
%% ====================[ Background Connectivity ]=========================
function BGFC_EX(ButtonH, EventData, MAIN_F)
    tmfc_select_ROIs_GUI();
end

%% =====================[ Beta Series Corelation ]=========================
function BSC_EX(ButtonH, EventData, MAIN_F)
    tmfc_select_ROIs_GUI();
end

%% =============================[ Close ]==================================
function gPPI_EX(ButtonH, EventData, MAIN_F)
    tmfc_select_ROIs_GUI();
end


%% =============================[ Close ]==================================
 
% Function to peform Save & Exit from TMFC function. This function is 
% linked to the close button on the top right handside of the Window

% NEED TO ADD CONDITION WHEN TMFC VARIABLE IS DELETED BUT TRY TO EXIT
% DELETE TMFC in WS-> Close TMFC -> DO NOT ASK TO SAVE (Give warning)
function Close_TMFC(ButtonH, EventData, MAIN_F) 
    
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
        delete(handles.MAIN_F);
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
            delete(handles.MAIN_F);
            disp('Goodbye!');
        end
    end
end
    
%% ==========================[ Save Project ]==============================

    % Function to perform Saving of TMFC variable from workspace to
    % individual .m file in user desired location
    
    function SAVE_STAT = SAVE_PROJ(ButtonH, EventData, MAIN_F)
       
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

    % Function to perform loading of TMFC variable from .m file 
    % to Workspace in matlab
    
    function LOAD_PROJ(ButtonH, EventData, MAIN_F)
        
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
            variable_value_L = loaded_data_L.(variable_name_L{1});      
            
            % Assign generated data into Base workspace under corresponding
            % variable name
            %assignin('base', variable_name_L{1}, variable_value_L);
            assignin('base', 'tmfc', variable_value_L);
            
            % Supporting Function - To Update TMFC GUI when loading data
            evaluate_file();
            
        else
            warning('No file selected');
        end
        
    end


%% ==========================[ Change Paths ]==============================

% Function to perform change of paths using Select subs
function CP_GUI(ButtonH, EventData, MAIN_F)
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
COMPUTING = {'Sequential computing', 'Parallel computing'};
STORAGE = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};

function Settings(ButtonH, EventData, MAIN_F)
        
    % Creates local copy of the TMFC variable and uses the most recent
    % version of data & settings
    SET_VAR = evalin('base', 'tmfc');

    % Create the Main figure for settings Window
    MAIN_F_SET = figure('Name', 'Settings', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.62 0.26 0.205 0.575],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','Tag', 'MAIN_WINDOW_Settings','WindowStyle','modal');%,'WindowStyle','modal'
    
    % Textual Data to be displayed on the settings window
    TEXT_1 = {'Parallel computing use Parallel Computing Toolbox. The number of workers in a parallel pool can be changed in MATLAB settings.'};
    TEXT_2 = {'This option temporary changes resmem variable in spm_defaults, which governing whether temporary files during GLM estimation are stored on disk or kept in memory. If you have enough available RAM, not writing the files to disk will speed the estimation.'};
    TEXT_3 = {'Max RAM temporary changes maxmem variable in spm_defaults, which indicates how much memory can be used at the same time during GLM estimation. If your computer has a large amount of RAM, you can increase that memory setting:'};
    TEXT_4 = {'• 2^31 = 2GB','• 2^32 = 4GB', '• 2^33 = 8GB','• 2^34 = 16GB','• 2^35 = 32GB'};

    % Initializing Drop down menus of options for Settings Window
    
    % Drop Down: Type of Computing
    MF_S1 = uicontrol(MAIN_F_SET ,'Style','popupmenu', 'String', COMPUTING ,'Units', 'normalized', 'Position',[0.04 0.87 0.90 0.08],'fontunits','normalized', 'fontSize', 0.30);
    MF_S1_STAT = uicontrol(MAIN_F_SET, 'Style','text','String', TEXT_1,'Units', 'normalized', 'Position',[0.04 0.795 0.90 0.10],'fontunits','normalized','fontSize', 0.24, 'HorizontalAlignment', 'left','backgroundcolor','w');%,'FontWeight', 'Bold',

    % Drop Down: Type of Storage
    MF_S2 = uicontrol(MAIN_F_SET ,'Style','popupmenu', 'String', STORAGE,'Units', 'normalized', 'Position',[0.04 0.69 0.90 0.08],'fontunits','normalized', 'fontSize', 0.30);
    MF_S2_STAT = uicontrol(MAIN_F_SET, 'Style','text','String', TEXT_2,'Units', 'normalized', 'Position',[0.04 0.555 0.86 0.16],'fontunits','normalized','fontSize', 0.14, 'HorizontalAlignment', 'left','backgroundcolor','w');%,'FontWeight', 'Bold',

    % Text box: Size of RAM to be used & its elaboration
    MF_S3_STAT = uicontrol(MAIN_F_SET, 'Style','text','String', 'Max RAM for GLM esimtation (bits):','Units', 'normalized', 'Position',[0.04 0.45 0.65 0.08],'fontunits','normalized', 'fontSize', 0.30,'backgroundcolor','w','HorizontalAlignment', 'left');%
    MF_S3_EDIT = uicontrol(MAIN_F_SET,'Style','edit','String', SET_VAR.defaults.maxmem,'Units', 'normalized', 'HorizontalAlignment', 'center','Position',[0.72 0.485 0.22 0.06],'fontunits','normalized', 'fontSize', 0.41);
    MF_S3_STAT_2 = uicontrol(MAIN_F_SET, 'Style','text','String', TEXT_3,'Units', 'normalized', 'Position',[0.04 0.31 0.84 0.16],'fontunits','normalized','fontSize', 0.14, 'HorizontalAlignment', 'left','backgroundcolor','w');%,'FontWeight', 'Bold',
    MF_S3_STAT_3 = uicontrol(MAIN_F_SET, 'Style','text','String', TEXT_4,'Units', 'normalized', 'Position',[0.08 0.155 0.30 0.16],'fontunits','normalized','fontSize', 0.15, 'HorizontalAlignment', 'left','backgroundcolor','w');%,'FontWeight', 'Bold',

    % OKAY & Synchronize button
    MF_S_OK = uicontrol(MAIN_F_SET,'Style','pushbutton','String', 'OK','Units', 'normalized','Position', [0.36 0.06 0.32 0.06],'fontunits','normalized', 'fontSize', 0.35);

    
    set(MF_S_OK , 'callback', @OK_SYNC);   


        % The following functions perform Synchronization after OK
        % button has been pressed 
        
        function OK_SYNC(~,~)

            % Create a local copy of the TMFC variable
           SET_SYNC = evalin('base', 'tmfc');

           % SYNC: Computation type
           % Check status of string in stat box -> if changed -> SWAP
           % details -> Change TMFC variable -> END          
           
           C_1 = (MF_S1.String(MF_S1.Value));
           if strcmp(C_1{1},'Sequential computing')
               COMPUTING = {'Sequential computing','Parallel computing'};
               set(MF_S1, 'String', COMPUTING);
               SET_SYNC.defaults.parallel = 0;

           elseif strcmp(C_1{1},'Parallel computing')
               COMPUTING = {'Parallel computing','Sequential computing',};
               set(MF_S1, 'String', COMPUTING);
               SET_SYNC.defaults.parallel = 1;
           end


           % SYNC: Storage type
           % Check status of string in stat box -> if changed -> SWAP
           % details -> Change TMFC variable -> END
           C_2 = (MF_S2.String(MF_S2.Value));
           
           if strcmp(C_2{1}, 'Store temporary files for GLM estimation in RAM')
               STORAGE = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'};
               set(MF_S2, 'String', STORAGE);
               SET_SYNC.defaults.resmem =  true;

           elseif strcmp(C_2{1}, 'Store temporary files for GLM estimation on disk')
               STORAGE = {'Store temporary files for GLM estimation on disk','Store temporary files for GLM estimation in RAM'};
               set(MF_S2, 'String', STORAGE);
               SET_SYNC.defaults.resmem =  false;

           end
           
           
           % SYNC: Maximum Memory Value
           % Check status of string in stat box -> if changed -> SWAP
           % details -> Change TMFC variable -> END
           DG4_STR = get(MF_S3_EDIT,'String');
           DG4 = eval(DG4_STR);
           if DG4 ~= 2^31
               set(MF_S3_EDIT, 'String', DG4_STR);
               SET_SYNC.defaults.maxmem = DG4;
           end

           assignin('base', 'tmfc', SET_SYNC);
           disp('Settings have been updated');
           close(MAIN_F_SET);
           
        end

        % Resizer function
        %function RESIZER(SIZE)
        %    set([handles.SUB,handles.SUB_stat,handles.FIR_TR, handles.FIR_TR_stat, handles.LSS_R, handles.LSS_R_stat, handles.ROI, handles.ROI_stat, handles.BSC, handles.gPPI, handles.save_p, handles.open_p, handles.change_p, handles.settings, handles.BGFC],'fontunits','normalized', 'fontSize', SIZE);
        %end
    
end

%% ========================[ Select Subjects ]=============================

% Select subjects and check SPM.mat files
function SUB_SEL(~, ~, MAIN_F)
    tmfc_select_subjects_GUI(1);
end

%% ========================[ FIR Regression ]==============================

    function FIR_REG(ButtonH, EventData, MAIN_F)
        
    % Function that performs Cordinates & performs FIR Regression 
    % Supporting functions (External) - tmfc_FIR_GUI(), tmfc_FIR_regress()
    %                      (Internal) - FIR_Runner()
        
    % Freezing the Main window
    try
        h_FREZ = findobj('Tag','MAIN_WINDOW');
        F_data = guidata(h_FREZ); 
        set([F_data.SUB,F_data.FIR_TR, F_data.LSS_R, F_data.LSS_RW, F_data.BSC, F_data.gPPI,F_data.save_p, F_data.open_p, F_data.change_p, F_data.settings,F_data.BGFC],'Enable', 'off');
    end
    
        % Checking if the FIR_WINDOWS & BINS GUI is open 
        try 
            CHECK_FIR = findobj('Tag', 'FIR_REG_NUM');
        end 
        
        % Continue with selection if the window doesn't exist
        if isempty(CHECK_FIR)
        
            % Initialize Local copy of start index & TMFC variable in runtime
            N_index = 0;
            SUB_EXT = evalin('base', 'tmfc');

            % If there exists subjects in the TMFC variable then proceed
            if ~strcmp(SUB_EXT.subjects(1).path, '')
                
                % Check if FIR WINDOWS is not NaN, enter WIN & BIN
                if isnan(SUB_EXT.FIR_window)
                   tmfc_FIR_GUI(1);               
                   uiwait();
                end

                % Create second local copy of TMFC that collects WIN & BIN
                SUB_EXT_2 = evalin('base', 'tmfc');
                % Create variable to store the length of subjects
                DG = length(SUB_EXT_2.subjects);

                % Check condition if FIR WINDOWS & BINS is not ZERO or NaN
                if SUB_EXT_2.FIR_window ~= 0 & SUB_EXT_2.FIR_bins ~= 0 & isnan(SUB_EXT_2.FIR_window) == 0 & isnan(SUB_EXT_2.FIR_bins) == 0 %HERE

                    
                    % CONDITION 1: When running FIR Regression for the
                    % FIRST TIME (EMPTY)
                    
                    % Check if first subject is processed (i.e. is NaN)
                    if isnan(SUB_EXT_2.subjects(1).FIR) % 
                        FIR_RUNNER(1);

                    % CONDITION 2: When running FIR Regression after 
                    % FULL COMPUTATION IS COMPELTED (Full Re-Run)
                    
                    % Condition to check if the last subject is computed
                    elseif isnan(SUB_EXT_2.subjects(DG).FIR) == 0% FULL RE-RUN                        
                        tmfc_FIR_GUI(2); % GUI to ask Restart Permission
                        uiwait();
                        
                        % Obtain status of Restart from User (0/1)
                        h18 = findobj('Tag', 'MAIN_WINDOW');
                        h18_V = getappdata(h18, 'RESTART_FIR');
                        
                        % If Restart is allowed, proceed
                        if h18_V == 1
                            
                            % Ask for WINDOWS & BINS
                            tmfc_FIR_GUI(1);                                           % Enter Windows & Bins 
                            uiwait();
                            
                            h19 = findobj('Tag', 'MAIN_WINDOW');
                            h19_V = getappdata(h19, 'NO_COND');
                            
                            % Check if FIR_windows & bins were closed or
                            % given by the user
                            
                            if h19_V ~= 1 | isempty(h19_V)    
                                FIR_RUNNER(1);
                            end
                            
                        end

                    else
                        % CONDITION 3: When running FIR Regression from 
                        % THE MIDDLE OR CONTINUATION (Last processed sub)
                        
                        % Find the last procssed subject (i.e. not NaN)
                        SUB_EXT_3 = evalin('base', 'tmfc');
                        for i = 1:DG
                            if isnan(SUB_EXT_3.subjects(i).FIR) == 1
                                N_index = i; % INDEX of last processed subject is found
                                break;
                            end
                        end
                        
                        % Ask User if they want to continue from the Index
                        % GUI for Continue or Restart action
                        tmfc_FIR_GUI(3, N_index); 
                        uiwait();
                        
                        % Get Status of Continuation
                        h5 = findobj('Tag', 'MAIN_WINDOW');
                        D5 = getappdata(h5, 'CONTD_FIR');
                        
                        if D5 == 1 % Continue computation from the Last processed index
                            setappdata(h5,'CONTD_FIR', 0);
                            FIR_RUNNER(int32(N_index));
                            
                        elseif D5 == 2 % Restart Computation from the first subject
                            tmfc_FIR_GUI(1);        % Enter Windows & Bins 
                            uiwait();     
                            
                            h29 = findobj('Tag', 'MAIN_WINDOW');
                            h29_V = getappdata(h29, 'NO_COND');
                            
                            if h29_V ~= 1 | isempty(h29_V)  
                                FIR_RUNNER(1);
                            end
                            
                        else
                            warning('Somethings not right here, the status of CONTD_FIR was not changed by the GUI via App data');
                        end
                        
                    end % Closing if statement for CONDITION 3
                    
                else
                    warning('Please enter the Windows and bins to perform FIR Regression');
                    
                    
                end % Closing if statement for FIR Regress Conditions (1,2,3)
                
            else
                warning('Please select subjects to peform FIR regression');
            end % Closing If statement to check WINDOWS & BINS 

            else
                warning('FIR Regression is already running');
        end % Closing if Statment to check if FIR exists
 
        try          % Unfrezee action after completion of actuation
        set([handles.SUB,handles.FIR_TR, handles.LSS_R, handles.LSS_RW, handles.BSC, handles.gPPI,handles.save_p, handles.open_p, handles.change_p, handles.settings,handles.BGFC],'Enable', 'on');
        end
        
    end % Closing FIR Regress Function
       

    % FIR Function the performs computation 
    function FIR_RUNNER(str_sub)
        
        % Freeze buttons on Main Window
        FIR_TMFC = evalin('base', 'tmfc');
        set([handles.SUB,handles.FIR_TR, handles.LSS_R, handles.LSS_RW, handles.BSC, handles.gPPI,handles.save_p, handles.open_p, handles.change_p, handles.settings,handles.BGFC],'Enable', 'off');
        
        % Actuator Function 
        try
            tmfc_FIR_regress(FIR_TMFC, str_sub);
        end
        
        % Unfrezee action after completion of actuation
        set([handles.SUB,handles.FIR_TR, handles.LSS_R, handles.LSS_RW, handles.BSC, handles.gPPI,handles.save_p, handles.open_p, handles.change_p, handles.settings,handles.BGFC],'Enable', 'on');
        disp('FIR task regression completed');
    end
    
    
%% ========================[ LSS Regression ]==============================

function LSS_REG(ButtonH, EventData, MAIN_F)
    
   L_checker = evalin('base', 'tmfc');
   
   if isnan(L_checker.FIR_bins) & isnan(L_checker.FIR_window) 
       warning('Please complete FIR Regression before proceeding with LSS regression');
   elseif ~isnan(L_checker.FIR_bins) & ~isnan(L_checker.FIR_window) & isnan(L_checker.subjects(length(L_checker.subjects)).FIR)
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
       
       % condition 1
       if isnan(L_checker_2.subjects(1).LSS_after_FIR)
           LSS_RUNNER(1);
           
       % condition 2 - there maybe a logical error here
       elseif L_checker_2.subjects(LSS_len_sub).LSS_after_FIR(dimension(1),dimension(2)) == 0
           
          tmfc_LSS_GUI(L_checker_2.subjects(1).path, 2);
          %uiwait();
          
          h77 = findobj('Tag', 'MAIN_WINDOW');
          h77_V = getappdata(h77, 'RESTART_LSS');
          
          if h77_V == 1
              
              % ask for conditions again
              tmfc_LSS_GUI(L_checker_2.subjects(1).path, 1);
              
              h78 = findobj('Tag', 'MAIN_WINDOW');
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
                           LSS_Lindex = [i,j,k];
                           LSS_flag = true;
                           break;
                       end
                   end
               end
           end

           tmfc_LSS_GUI(L_checker_2.subjects(1).path, 3, LSS_Lindex(1));


           h54 = findobj('Tag', 'MAIN_WINDOW');
           h54_V = getappdata(h54, 'CONTD_LSS');

           if h54_V == 1
              setappdata(h54_V, 'CONTD_LSS', 0);
              LSS_RUNNER(int32(LSS_Lindex(1)));

           elseif h54_V == 2
               setappdata(h54_V, 'CONTD_LSS', 0);
               tmfc_LSS_GUI(L_checker_2.subjects(1).path, 1);

               h53 = findobj('Tag', 'MAIN_WINDOW');
               h53_V = getappdata(h53, 'LSS_NO_COND');

               if h53_V ~= 1
                   setappdata(h53, 'LSS_NO_COND', 0);
                   LSS_RUNNER(1);
               end
           else
               warning('Something isnt right here, contact devs for LSS reg issue');
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
        h1_UNFREZ = findobj('Tag','MAIN_WINDOW');
        F1_data = guidata(h1_UNFREZ); 
        set([F1_data.SUB,F1_data.FIR_TR, F1_data.LSS_R, F1_data.LSS_RW, F1_data.BSC, F1_data.gPPI,F1_data.save_p, F1_data.open_p, F1_data.change_p, F1_data.settings,F1_data.BGFC],'Enable', 'on');
    end
            
                
    try % MAJOR CHANGE
        guidata(handles.MAIN_F, handles);
    end


% This function performs Independent save & returns the status
% of saving. 0 - Success, 1 - Fail
function SAVER_STAT =  Saver(save_path)

    try 
        % Major change may affect the funcitoning of TMFC variable
        %EXPORT = evalin('base', 'tmfc');
        %save(save_path, 'EXPORT');
        tmfc = evalin('base', 'tmfc');
        save(save_path, 'tmfc');
        SAVER_STAT = 1;
        % Save Success
    catch 
        SAVER_STAT = 0;
        % Save Fail 
    end
end

function evaluate_file() % function to update the TMFC window after loading a tmfc project
    BPL = evalin('base', 'tmfc');
    BPL_LEN = length(BPL.subjects);
    set(handles.SUB_stat,'ForegroundColor',[0.219, 0.341, 0.137]);
    set(handles.SUB_stat,'String',strcat(num2str(BPL_LEN), ' selected'));
   
    V_FIR = 0;
    for i = 1:BPL_LEN
        if ~isnan(BPL.subjects(i).FIR)
        V_FIR = V_FIR + 1 ;
        end
    end
    if V_FIR ~= 0
        set(handles.FIR_TR_stat,'ForegroundColor',[0.219, 0.341, 0.137]);
        set(handles.FIR_TR_stat,'String',strcat(num2str(V_FIR), '/', num2str(BPL_LEN), ' done'));
    else 
        set(handles.FIR_TR_stat,'ForegroundColor',[0.773, 0.353, 0.067]);
        set(handles.FIR_TR_stat,'String','Not done');
    end
    
    switch BPL.defaults.parallel
        case 1
            COMPUTING = {'Parallel computing','Sequential computing',};           
        case 0 
           COMPUTING = {'Sequential computing','Parallel computing'};
           
    end
    
    switch BPL.defaults.resmem
        case true
            STORAGE = {'Store temporary files for GLM estimation in RAM', 'Store temporary files for GLM estimation on disk'}; 
        case false 
            STORAGE = {'Store temporary files for GLM estimation on disk','Store temporary files for GLM estimation in RAM'};
           
    end
    
    
    
    V_LSS = 0;
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

end