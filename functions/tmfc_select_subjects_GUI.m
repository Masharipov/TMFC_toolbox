function [paths] = tmfc_select_subjects_GUI(SPM_check)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for selecting individual subject SPM.mat files
% created by SPM12 after 1-st level GLM estimation. Optionally checks
% SPM.mat files: 
% (1) checks if all SPM.mat files are present in the specified paths
% (2) checks if the same conditions are specified in all SPM.mat files
% (3) checks if output folders specified in SPM.mat files exist
% (4) checks if functional files specified in SPM.mat files exist
%
% FORMAT [paths] = tmfc_select_subjects_GUI(SPM_check)
%
%   SPM_check         - 0 or 1 (don't check or check SPM.mat files)
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

if nargin == 0
    SPM_check = 1;
end

% Freeze Main TMFC window
GUI_freeze(1);
                      
% Creation of Figure for the Window
TMFC_SS = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.36 0.25 0.35 0.575],'MenuBar', 'none','ToolBar', 'none','color','w','CloseRequestFcn',@close);
TMFC_SS_B1 = uicontrol(TMFC_SS,'Style','pushbutton', 'String', 'Select subject folders','Units', 'normalized', 'Position',[0.033 0.850 0.455 0.095],'FontUnits','normalized','FontSize',0.25);
TMFC_SS_B2 = uicontrol(TMFC_SS,'Style','pushbutton', 'String', 'Select SPM.mat file for Subject №1','Units', 'normalized', 'Position',[0.033 0.750 0.455 0.095],'FontUnits','normalized','FontSize',0.25);
TMFC_SS_B3 = uicontrol(TMFC_SS,'Style','pushbutton', 'String', 'Add new subject','Units', 'normalized', 'Position',[0.033 0.14 0.300 0.095],'FontUnits','normalized','FontSize',0.25);
TMFC_SS_B4 = uicontrol(TMFC_SS,'Style','pushbutton', 'String', 'Remove selected subject','Units', 'normalized', 'Position',[0.346 0.14 0.300 0.095],'FontUnits','normalized','FontSize',0.25);
TMFC_SS_B5 = uicontrol(TMFC_SS,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.390 0.04 0.200 0.080],'FontUnits','normalized','FontSize',0.28);
TMFC_SS_B6 = uicontrol(TMFC_SS,'Style','pushbutton', 'String', 'Clear all subjects','Units', 'normalized', 'Position',[0.660 0.14 0.300 0.095],'FontUnits','normalized','FontSize',0.25);
TMFC_SS_S1 = uicontrol(TMFC_SS,'Style','text','String', 'Not Selected','ForegroundColor','red','Units', 'normalized', 'Position',[0.500 0.820 0.450 0.095],'backgroundcolor','w','FontUnits','normalized','FontSize',0.25);
TMFC_SS_S2 = uicontrol(TMFC_SS,'Style','text','String', 'Not Selected','ForegroundColor','red','Units', 'normalized', 'Position',[0.500 0.720 0.450 0.095],'backgroundcolor','w','FontUnits','normalized','FontSize',0.25);
TMFC_SS_lst = uicontrol(TMFC_SS, 'Style', 'listbox', 'String', '','Max',100,'Units', 'normalized', 'Position',[0.033 0.250 0.920 0.490]);

% Assigning Functions Callbacks for each Element (button, listbox etc)
set(TMFC_SS_B1, 'callback', @action_1)
set(TMFC_SS_B2, 'callback', @action_2)
set(TMFC_SS_B3, 'callback', @action_3)
set(TMFC_SS_B4, 'callback', @action_4)
set(TMFC_SS_B5, 'callback', @action_5)
set(TMFC_SS_B6, 'callback', @action_clr)
set(TMFC_SS_lst, 'callback', @action_select)
set(TMFC_SS_lst, 'Value', []);

% Center Spawn GUI
movegui(TMFC_SS,'center');

% Local Variables that work throughout the RunTime upto checking stage
main_subjects = {};      % Variable to store subject path
file_address = {};       % Variable to store full path 
mat_add = {};            % Varaible to store subfolder for SPM.mat file

selection = {};          % Variable to store the selected list of paths (as INDEX)
add_subs = {};           % Variable used to create & merge new subjects

%% Select subjects
function action_1(~,~)
    
    set(TMFC_SS_lst, 'String', '');           % Intializing display list in the GUI 
    main_subjects = sub_folder();             % Prompt for SPM_DIR select 
    main_subjects = unique(main_subjects);    % Filtering new selection for repetitions
    len_subs_A1 = size(main_subjects);        % Calculation of Size of added subjects
    
    % Logical & Warning Conditions
    if isempty(main_subjects)
        disp('0 Subjects selected');
        set(TMFC_SS_S1,'String', 'Not selected','ForegroundColor','red');
        set(TMFC_SS_S2,'String', 'Not selected','ForegroundColor','red');
        mat_add = '';
        file_address = '';
    else
        fprintf('Subjects selected are: %d \n', len_subs_A1(1));
        disp('Proceed to Select SPM.mat file');
        set(TMFC_SS_S1,'String', strcat(num2str(len_subs_A1(1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);    
        set(TMFC_SS_S2,'String', 'Not selected','ForegroundColor','red');
        mat_add = '';
        file_address = '';
    end
    
    if strcmp(file_address,'') & strcmp(mat_add, '') & strcmp(main_subjects, '')
        warning('No Subjects selected');
        mat_add = ''; 
        file_address = ''; 
        main_subjects = ''; 
        set(TMFC_SS_S1,'String', 'Not selected','ForegroundColor','red');
        set(TMFC_SS_S2,'String', 'Not selected','ForegroundColor','red');
    end 
end


%% SPM.mat file selection
function action_2(~,~)

    % Logical & Warning Condition
    if isempty(main_subjects)
        warning('Please select subject folders');        
        
    elseif strcmp(file_address,'') & strcmp(main_subjects,'')
        warning('Please select subject folders');
        set(TMFC_SS_S2,'String', 'Not selected','ForegroundColor','red');
        set(TMFC_SS_lst, 'String', '');
        
    else
        [file_address, mat_add] = mat_file(main_subjects);                      % Creation of full list of Subs with .FILE extension
        if ~strcmp(mat_add, '')
            set(TMFC_SS_lst, 'String', file_address);                          % Display Full Address of Subs in the GUI
            disp('The SPM.mat file has been succesfully selected');
            set(TMFC_SS_S2,'String', 'Selected','ForegroundColor',[0.219, 0.341, 0.137]);
        end 
    end
end


%% Clear subject list
function action_clr(~,~)

    % Logical & Warning condition
    if isempty(main_subjects) | strcmp(file_address, '')
        warning('No subjects present to clear');
    else
        main_subjects = {};
        file_address = {};
        mat_add = {};
        set(TMFC_SS_lst, 'String', '');                % Clearing Display 
        disp('All selected subjects have been cleared');
        set(TMFC_SS_S1,'String', 'None selected','ForegroundColor','red');
        set(TMFC_SS_S2,'String', 'None selected','ForegroundColor','red');
    end 
end


%% Select subjects from the list
function action_select(~,~)
    index = get(TMFC_SS_lst, 'Value');% Retrieves the users selection LIVE
    selection = index;                % Variable for full selection
end


%% Add new subjects to the list
function action_3(~,~)   

    % Logical & Warning Condition (Iteration i)
    if isempty(main_subjects) | strcmp(file_address, '')
        warning('No existing list of subjects present, Please select subjects via ''Select subject folders'' button');
        
    elseif isempty(mat_add)
        warning('Cannot add new subjects without SPM.mat, Please select subjects via ''Select subject folders'' button and proceed to Select SPM.mat file');

    else
        
        add_subs = mid_sub_folder();              % Addition Function
        
        if isempty(add_subs)
            warning('No newly selected subjects');
        else
            len_exst = size(file_address); % Size of existing subjects
            len_subs_3 = size(add_subs);   % Length of Size of new subjects
            NEW_paths = {};                % Creation of empty array

            
            % Loop to append .FILE Extension to the Newly selected subjects
            for j = 1:len_subs_3(1)
               NEW_paths =  vertcat(NEW_paths,strcat(char(add_subs(j,:)),char(mat_add)));
            end

            file_address = vertcat(file_address, NEW_paths);            % Joining exisiting list of subjects with new Subjects
            new_ones = size(unique(file_address)) - len_exst(1);        % Removing Duplicates
            file_address = unique(file_address);
           
            % Warning & logical Condition (Iteration ii)
            if new_ones(1) == 0
                warning('Newly selected subjects are already present in the list, no new subjects added');
            else
                fprintf('New subjects selected are: %d \n', new_ones(1)); 
            end   
        end 
        
        set(TMFC_SS_lst, 'String', file_address);                               % Updating display with new Subjects
        len_subs = size(file_address);
        set(TMFC_SS_S1,'String', strcat(num2str(len_subs(1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
        
    end
end


%% Remove subjects from the list
function action_4(~,~) 
    
    % Logical & Warning Condition
    if isempty(selection)
        warning('There are no selected subjects to remove from the list, please select subjects once again');
    else
        file_address(selection,:) = [];                                          % Nullifying the Indexs selected as per the user
        holder = size(selection);
        fprintf('Number of subjects removed are: %d \n', holder(2));
        
        set(TMFC_SS_lst,'Value',[]);                                             % Setting Min select value to 1 since it gives a warning of dynamic mismatch
        
        set(TMFC_SS_lst, 'String', file_address);                                % Updating the display with the new list of subjects after removal 
        selection ={};
        
        if size(file_address) < 1
            set(TMFC_SS_S1,'String', 'Not selected','ForegroundColor','red');
        else
            len_subs = size(file_address);
            set(TMFC_SS_S1,'String', strcat(num2str(len_subs(1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137])
        end
    end
end 


%% Check SPM.mat files and export paths
function file_func = action_5(~,~)

    file_correct = {};
    file_incorrect = {};
    file_exist = {};
    file_not_exist = {};
    file_dir = {};
    file_no_dir = {};
    funct_check= {};
    file_func = {};
    file_no_func = {};
      
    
    % Pre conditions to verify existence of subujects 
    if isempty(main_subjects)
        warning('There are no selected subjects, please select subjects and SPM.mat files');
        
    % Condition to check for selected SPM.mat file but not subjects
    elseif (isempty(file_address) & isempty(mat_add)) | (~strcmp(main_subjects, '') & strcmp(mat_add,''));
        warning('Please select SPM.mat file for the first subject');
    
    % Condition to check for Action cleared SPM.mat & Subjects
    elseif (strcmp(file_address, '') & ~strcmp(mat_add, ''));
        warning('Please Re-select the subjects and the SPM.mat file if required');

    else
        close(TMFC_SS);                               % Close Select Subjects GUI    
        
        GUI_freeze(1);
        % Check SPM.mat files
        if SPM_check == 1
                
            % Stage 1 - Check SPM.mat files existence
            [file_exist,file_not_exist] = SPM_EXT_CHK(file_address);        
    
            if size(file_address) == size(file_not_exist) | strcmp(file_exist, '')
                warning('STAGE 1 CHECK FAILED: Selected files are missing from the directories, Please try again');
                Royal_Reset();
            else
                % Stage 2 - Check conditions
                [file_correct, file_incorrect] = SPM_COND(file_exist);          
    
                if size(file_incorrect) == size(file_exist) | strcmp(file_correct,'')
                    warning('STAGE 2 CHECK FAILED: Selected files have incorrect conditions, Please try again');
                    Royal_Reset();
                else
                    % Stage 3 - Check output directories 
                    [file_dir,file_no_dir] = CHECK_DIR(file_correct);
            
                    if size(file_no_dir) == size(file_correct) | strcmp(file_dir,'')
                        warning('STAGE 3 CHECK FAILED: Directories are missing from selected Files, Please try again');
                        Royal_Reset();
                    else
                        % Stage 4 - Check functional files
                        [file_func,file_no_func] = CHECK_FUNCTION(file_dir);
                
                        if size(file_no_func) == size(file_dir) | strcmp(file_func, '')
                            warning('STAGE 4 CHECK FAILED: Selected files are missing from all directories, Please try again');
                            Royal_Reset();
                        else
                            paths = file_func;
                        end
                    end 
                end
            end
        end
        if SPM_check == 0
            paths = file_address; 
            GUI_freeze(0);
        end
    end                                                                 
end      


%% Function to perform clearing & Reset of the Select SUBS GUI
function Royal_Reset(~,~)
    main_subjects = {};
    file_address = {};
    mat_add = {};
end


%% Close select subjects GUI window
function close(~,~) 
    delete(TMFC_SS);
    if exist('paths', 'var') == 0
        paths = [];
        GUI_freeze(0);
    end   
end


uiwait(TMFC_SS);
return;

end


%% Select subjects
function subjects = sub_folder(~,~)

    subs_f = spm_select(inf,'dir','Select folders of all subjects',{},pwd,'..');
    
    subjects = {};                % Cell to store subjects
    len_subs = size(subs_f);      % Length of Subjects

    % Updating list of Subjects
    for i = 1: len_subs(1)
        subjects = vertcat(subjects, subs_f(i,:));
    end
end                


%% Select SPM.mat file
function [full_path, mat_adrs] = mat_file(x)
        
    % Selection of the SPM.mat file for the first subject 
    [mat_f] = spm_select( 1,'any','Select SPM.mat file for the first subject',{}, x(1,:), 'SPM.*');    
    [mat_adrs] = replace(mat_f, x(1,:),''); 
    len_subs = size(x);

    full_path = {}; % Creation of variable to store all the new Full paths of the subjects 
    
    % Concationation & creation of a full scale list of variables
    for i = 1:len_subs(1)
       full_path =  vertcat(full_path,strcat(char(x(i,:)),char(mat_adrs)));
    end
end 


%% Add new subjects 
function New_subjects = mid_sub_folder(~,~)        

    N_subs_f = spm_select(inf,'dir','Select NEW subject folders',{},pwd,'..');
    
    New_subjects = {};
    N_len_subs = size(N_subs_f);

    for i = 1: N_len_subs(1)
        New_subjects = vertcat(New_subjects, N_subs_f(i,:));
    end
end        


%% Check SPM.mat files existence
function [file_exist,file_not_exist] = SPM_EXT_CHK(Y_1)

    file_exist = {};
    file_not_exist = {};     
    
    % Condition to verify if file exists in the location
    for i = 1:length(Y_1) 
        if exist(Y_1{i}, 'file')
            file_exist{i,1} = Y_1{i};
        else
            file_not_exist{i,1} = Y_1{i};
        end                
    end 
    
    % Checks if the variables storing the existing files are empty or full
    try
        file_exist = file_exist(~cellfun('isempty', file_exist)); 
    end

    try 
        file_not_exist = file_not_exist(~cellfun('isempty',file_not_exist)); 
    end

    % Resulting Condition: If all files are NOT present as per the paths
    if length(file_exist) ~= length(Y_1) 
        
        % Creation of Pop up Window & show the respective files that are missing
        f_1 = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w', 'MenuBar', 'none', 'ToolBar', 'none');

        % Initializing Elements of the UI
        lst_1 = uicontrol(f_1, 'Style', 'listbox', 'String', '','Max',100,'Units', 'normalized', 'Position', [0.028 0.280 0.940 0.520],'FontUnits','points','FontSize',12);
        G1_Stat = uicontrol(f_1,'Style','text','String', 'Warning, the following SPM.mat files are missing:','Units', 'normalized', 'Position',[0.220 0.820 0.550 0.095], 'backgroundcolor', 'w','FontUnits','points','FontSize',12);
        G1 = uicontrol(f_1,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.4 0.05 0.180 0.120] ,'FontUnits','points','FontSize',10);%[0.4 0.05 0.180 0.180] 

        % Assigning Functions Callbacks for each Element (button, listbox etc)
        set(lst_1, 'String', file_not_exist);                 
        set(G1, 'Callback', @action_close_GUI_1);
        movegui(f_1,'center');
        uiwait();
        
    end
    
    function action_close_GUI_1(~,~)
        close(f_1);
    end   
end


%% Check conditions specified in SPM.mat files
function [file_correct, file_incorrect] = SPM_COND(Y_2)
    
    file_incorrect = {};
    file_correct = {};
    
    if length(Y_2) > 1

        w = waitbar(0,'Check conditions','Name','Check SPM.mat files');

        % Reference SPM.mat file
        file_correct{1,1} = Y_2{1};
        SPM_ref = load(Y_2{1});

        % Reference structure for conditions
        for j = 1:length(SPM_ref.SPM.Sess)
            cond_ref(j).sess = struct('name', {SPM_ref.SPM.Sess(j).U(:).name});
        end

        % Start check
        for i = 2:length(Y_2)
            
            % SPM.mat file to check
            SPM = load(Y_2{i});

            % Structure for conditions to check
            for j = 1:length(SPM.SPM.Sess)
                cond(j).sess = struct('name', {SPM.SPM.Sess(j).U(:).name});
            end 

            if ~isequaln(cond_ref, cond)
                file_incorrect{i,1} = Y_2{i};
            else
                file_correct{i,1} = Y_2{i};
            end

            try
                waitbar(i/length(Y_2),w);
            end

            clear SPM cond
        end
        
    else
        file_correct = Y_2;
    end
    
    % Close waitbar
    try
        close(w)
    end
    
    % Listing empty Correct & Incorrect files
    try
        file_correct = file_correct(~cellfun('isempty', file_correct));
    end

    try
        file_incorrect = file_incorrect(~cellfun('isempty', file_incorrect));
    end

    % GUI for Correct & Incorrect files
    if length(file_correct) ~=  length(Y_2)
        
        % Creation of GUI Figure
        f_2 = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');

        % Initializing Elements of the UI
        lst_2 = uicontrol(f_2, 'Style', 'listbox', 'String', '','Max',100,'Units', 'normalized', 'Position',[0.028 0.280 0.940 0.520],'FontUnits','points','FontSize',12);
        G2_Stat = uicontrol(f_2,'Style','text','String', 'Warning, in the following SPM.mat files different conditions are specified:','Units', 'normalized', 'Position',[0.120 0.820 0.780 0.095], 'backgroundcolor', 'w','FontUnits','points','FontSize',12);
        G2 = uicontrol(f_2,'Style','pushbutton', 'String', 'OK','Units', 'normalized',  'Position',[0.4 0.05 0.180 0.120] ,'FontUnits','points','FontSize',10);

        % Assigning Functions Callbacks for each Element (button, listbox etc)
        set(lst_2, 'String', file_incorrect);  
        set(G2, 'callback', @action_close_GUI_2)
        movegui(f_2,'center');
        uiwait();
        
    end
    
    function action_close_GUI_2(~,~)
        close(f_2);
    end
end


%% Check output directories (SPM.swd) specified in SPM.mat files
function [file_dir,file_no_dir] = CHECK_DIR(Y_3)

    file_dir = {};
    file_no_dir = {};
    w = waitbar(0,'Check directories','Name','Check SPM.mat files');

    for i = 1:length(Y_3) 
        
        %SPM.mat file to check
        SPM = load(Y_3{i});
        if exist(SPM.SPM.swd, 'dir') 
            file_dir{i,1} = Y_3{i};
        else
            file_no_dir{i,1} = Y_3{i};
        end
        clear SPM
        try
            waitbar(i/length(Y_3),w);
        end
    end

    
    try
        close(w)
    end

    
    try
        file_dir = file_dir(~cellfun('isempty', file_dir));
    end

    
    try 
        file_no_dir = file_no_dir(~cellfun('isempty',file_no_dir)); 
    end
    
    
    if length(file_dir) ~=  length(Y_3)
        
        % Creation of Figure window
        f_3 = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');

        % Initializing Elements of the UI
        lst_3 = uicontrol(f_3, 'Style', 'listbox', 'String', '','Max',100,'Units', 'normalized', 'Position', [0.025 0.280 0.940 0.490],'FontUnits','points','FontSize',12);
        G3_Stat = uicontrol(f_3,'Style','text','String', 'Warning, the output folder (SPM.swd) specified in the following SPM.mat files do not exist: ','Units', 'normalized', 'Position',[0.120 0.820 0.780 0.120], 'backgroundcolor', 'w','FontUnits','points','FontSize',12);
        G3 = uicontrol(f_3,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position', [0.4 0.05 0.180 0.120] ,'FontUnits','points','FontSize',10);

        % Assigning Functions Callbacks for each Element (button, listbox etc)
        set(lst_3, 'String', file_no_dir);  
        set(G3, 'callback', @action_close_GUI_3)
        movegui(f_3,'center');
        uiwait();
    end
    
    function action_close_GUI_3(~,~)
        close(f_3);
    end
end
            
%% Check functional files specified in SPM.mat files 
function [file_func,file_no_func] = CHECK_FUNCTION(Y_4)

    file_func = {};
    file_no_func = {};
    w = waitbar(0,'Check functional files','Name','Check SPM.mat files');

    for i = 1:length(Y_4) 
        
        %SPM.mat file to check
        SPM = load(Y_4{i});
        
        %Check functional files
        for j = 1:length(SPM.SPM.xY.VY)
            funct_check(j) = exist(SPM.SPM.xY.VY(j).fname, 'file');
        end
        
        if nnz(funct_check) == length(SPM.SPM.xY.VY)
            file_func{i,1} = Y_4{i};
        else
            file_no_func{i,1} = Y_4{i};
        end
        clear SPM funct_check      
        
        try
            waitbar(i/length(Y_4),w);
        end
        
    end

    try
        close(w)
    end

    
    try
        file_func = file_func(~cellfun('isempty', file_func));
    end

    
    try 
        file_no_func = file_no_func(~cellfun('isempty',file_no_func)); 
    end
    
    if length(file_func) ~=  length(Y_4)
        
        % Creation of Figure for GUI window
        f_4 = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');

        % Initializing Elements of the UI
        lst_4 = uicontrol(f_4, 'Style', 'listbox', 'String', '','Max',100,'Units', 'normalized', 'Position', [0.025 0.280 0.940 0.490],'FontUnits','points','FontSize',12);
        G4_Stat = uicontrol(f_4,'Style','text','String', 'Warning, the functional files specified in the following SPM.mat files do not exist:','Units', 'normalized', 'Position', [0.140 0.820 0.720 0.120], 'backgroundcolor', 'w','FontUnits','points','FontSize',12);
        G4 = uicontrol(f_4,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.4 0.05 0.180 0.120] ,'FontUnits','points','FontSize',10);

        % Assigning Functions Callbacks for each Element (button, listbox etc)
        set(lst_4, 'String', file_no_func);  
        set(G4, 'callback', @action_close_GUI_4)
        movegui(f_4,'center');
        uiwait();
    end
    
    function action_close_GUI_4(~,~)
        close(f_4);
    end

end


%% Freezing & Unfreezing main TMFC window
function GUI_freeze(state)

    switch(state)
        case 0 
            state = 'on';
        case 1
            state = 'off';
    end

    try
        main_GUI = guidata(findobj('Tag','TMFC_GUI')); 
        set([main_GUI.TMFC_GUI_B1, main_GUI.TMFC_GUI_B2, main_GUI.TMFC_GUI_B3, main_GUI.TMFC_GUI_B4,...
            main_GUI.TMFC_GUI_B5a, main_GUI.TMFC_GUI_B5b, main_GUI.TMFC_GUI_B6, main_GUI.TMFC_GUI_B7,...
            main_GUI.TMFC_GUI_B8, main_GUI.TMFC_GUI_B9, main_GUI.TMFC_GUI_B10, main_GUI.TMFC_GUI_B11,...
            main_GUI.TMFC_GUI_B12,main_GUI.TMFC_GUI_B13a,main_GUI.TMFC_GUI_B13b,main_GUI.TMFC_GUI_B14a...
            main_GUI.TMFC_GUI_B14b], 'Enable', state);
    end       
     
end
