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

if nargin == 0
    SPM_check = 1;
end

% Freeze Main TMFC window
freeze_GUI(1);
                      
% SS = select subjects, MW = main window 
SS_MW = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.36 0.25 0.35 0.575],'MenuBar', 'none','ToolBar', 'none','color','w','CloseRequestFcn',@SS_MW_exit);
SS_MW_S1 = uicontrol(SS_MW,'Style','text','String', 'Not Selected','ForegroundColor','red','Units', 'normalized', 'Position',[0.500 0.820 0.450 0.095],'backgroundcolor','w','FontUnits','normalized','FontSize',0.25);
SS_MW_S2 = uicontrol(SS_MW,'Style','text','String', 'Not Selected','ForegroundColor','red','Units', 'normalized', 'Position',[0.500 0.720 0.450 0.095],'backgroundcolor','w','FontUnits','normalized','FontSize',0.25);
SS_MW_LB1 = uicontrol(SS_MW, 'Style', 'listbox', 'String', '','Max',100,'Units', 'normalized', 'Position',[0.033 0.250 0.920 0.490],'FontUnits','normalized','FontSize',0.045,'Value', [],'callback', @SS_LB_select);
SS_MW_sel_sub = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Select subject folders','Units', 'normalized', 'Position',[0.033 0.850 0.455 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @select_sub);
SS_MW_sel_mat = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Select SPM.mat file for Subject #1','Units', 'normalized', 'Position',[0.033 0.750 0.455 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @select_SPM_mat);
SS_MW_add_new = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Add new subject','Units', 'normalized', 'Position',[0.033 0.14 0.300 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @add_new);
SS_MW_rem = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Remove selected subject','Units', 'normalized', 'Position',[0.346 0.14 0.300 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @remove_sub);
SS_MW_rem_all = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Clear all subjects','Units', 'normalized', 'Position',[0.660 0.14 0.300 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @remove_all);
SS_MW_conf = uicontrol(SS_MW,'Style','pushbutton', 'String', 'OK','Units', 'normalized', 'Position',[0.390 0.04 0.200 0.080],'FontUnits','normalized','FontSize',0.28,'callback', @confirm_paths);
movegui(SS_MW,'center');

% Local variables that work throughout the RunTime up to checking stage
subject_dir = {};             % Variable to store subject path
subject_full_path = {};       % Variable to store full path 
SPM_mat_path = {};            % Varaible to store subfolder for SPM.mat file

selected_sub = {};            % Variable to store the selected list of paths (as INDEX)
add_new_subs = {};            % Variable used to create & merge new subjects

%--------------------------------------------------------------------------
% Select subjects from the list
function SS_LB_select(~,~)
    index = get(SS_MW_LB1, 'Value');     
    selected_sub = index;                
end

%--------------------------------------------------------------------------
% Select subjects
function select_sub(~,~)
    
    set(SS_MW_LB1, 'String', '');              
    subject_dir = add_subjects();             

    if isempty(subject_dir)
        disp('TMFC Subjects: 0 Subjects selected');
        set(SS_MW_S1,'String', 'Not selected','ForegroundColor','red');
        set(SS_MW_S2,'String', 'Not selected','ForegroundColor','red');
        SPM_mat_path = {};
        subject_full_path = {};
    else
        fprintf('TMFC Subjects: Subjects selected are: %d \n', size(subject_dir,1));
        disp('TMFC Subjects: Proceed to Select SPM.mat file');
        set(SS_MW_S1,'String', strcat(num2str(size(subject_dir,1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);    
        set(SS_MW_S2,'String', 'Not selected','ForegroundColor','red');
        SPM_mat_path = {};
        subject_full_path = {};
    end
    
    if isempty(subject_full_path) && isempty(SPM_mat_path) && isempty(subject_dir)
        warning('TMFC Subjects: No Subjects selected');
        SPM_mat_path = {}; 
        subject_full_path = {}; 
        subject_dir = {}; 
        set(SS_MW_S1,'String', 'Not selected','ForegroundColor','red');
        set(SS_MW_S2,'String', 'Not selected','ForegroundColor','red');
    end 
end

%--------------------------------------------------------------------------
% Select SPM.mat file
function select_SPM_mat(~,~)
    if isempty(subject_dir)
        warning('TMFC Subjects: Please select subject folders.');        
        
    elseif isempty(subject_full_path) && isempty(subject_dir)
        warning('TMFC Subjects: Please select subject folders.');
        set(SS_MW_S2,'String', 'Not selected','ForegroundColor','red');
        set(SS_MW_LB1, 'String', '');
        
    else
        [subject_full_path, SPM_mat_path] = add_mat_file(subject_dir);            
        if ~isempty(SPM_mat_path)
            set(SS_MW_LB1, 'String', subject_full_path);                          
            disp('TMFC Subjects: The SPM.mat file has been succesfully selected.');
            set(SS_MW_S2,'String', 'Selected','ForegroundColor',[0.219, 0.341, 0.137]);
        else
            warning('TMFC Subjects: The SPM.mat file has not been selected.');
        end 
    end
end

%--------------------------------------------------------------------------
% Add new subjects to the list
function add_new(~,~)   
    if isempty(subject_dir) || isempty(subject_full_path)
        warning('TMFC Subjects: No existing list of subjects present. Please select subjects via ''Select subject folders'' button.');
        
    elseif isempty(SPM_mat_path)
        warning('TMFC Subjects: Cannot add new subjects without SPM.mat file. Please select subjects via ''Select subject folders'' button and proceed to Select SPM.mat file.');

    else
        add_subs_full_path = {};                    
        add_new_subs = add_subjects();             
        
        if isempty(add_new_subs)
            warning('TMFC Subjects: No newly selected subjects');
        else
            subs_exist = size(subject_full_path,1); 
            
            for iSub = 1:size(add_new_subs,1)
               add_subs_full_path =  vertcat(add_subs_full_path,strcat(char(add_new_subs(iSub,:)),char(SPM_mat_path)));
            end
                        
            subject_full_path = vertcat(subject_full_path, add_subs_full_path);   % Joining exisiting list of subjects with new Subjects
            new_subs_count = size(unique(subject_full_path)) - subs_exist;        % Removing Duplicates
            subject_full_path = unique(subject_full_path);
           
            if new_subs_count(1) == 0
                warning('TMFC Subjects: Newly selected subjects are already present in the list, no new subjects added');
            else
                fprintf('TMFC Subjects: New subjects selected: %d. \n', new_subs_count(1)); 
            end   
        end 
        
        set(SS_MW_LB1, 'String', subject_full_path);                              % Updating display with new subjects
        set(SS_MW_S1,'String', strcat(num2str(size(subject_full_path,1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);
        clear add_subs_full_path new_subs_count add_new_subs
    end
end

%--------------------------------------------------------------------------
% Remove subjects from the list
function remove_sub(~,~)    
    if isempty(selected_sub)
        warning('TMFC Subjects: There are no selected subjects to remove from the list. Please select subjects to remove.');
    else
        subject_full_path(selected_sub,:) = [];                                         
        fprintf('TMFC Subjects: Number of subjects removed: %d. \n', size(selected_sub,2));
        
        set(SS_MW_LB1,'Value',[]);                                             
        set(SS_MW_LB1, 'String', subject_full_path);                              % Updating the display with the new list of subjects after removal 
        selected_sub ={};
        
        if size(subject_full_path,1) < 1
            set(SS_MW_S1,'String', 'Not selected','ForegroundColor','red');
        else
            set(SS_MW_S1,'String', strcat(num2str(size(subject_full_path,1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137])
        end
    end
end 

%--------------------------------------------------------------------------
% Remove all subjects
function remove_all(~,~)
    if isempty(subject_dir) || isempty(subject_full_path)
        warning('TMFC Subjects: No subjects present to remove.');
    else
        subject_dir = {};
        subject_full_path = {};
        SPM_mat_path = {};
        add_new_subs = {}; 
        
        disp('TMFC Subjects: All subjects have been removed.');
        set(SS_MW_LB1, 'String', '');                
        set(SS_MW_S1,'String', 'None selected','ForegroundColor','red');
        set(SS_MW_S2,'String', 'None selected','ForegroundColor','red');
    end 
end

%--------------------------------------------------------------------------
% Check SPM.mat files and export paths
 function confirm_paths(~,~)

	file_correct = {};
    file_exist = {};
    file_dir = {};
    file_func = {};
         
    % Initial checks
    if isempty(subject_dir)
        warning('TMFC Subjects: There are no selected subjects. Please select subjects and SPM.mat files.');
    elseif (isempty(subject_full_path) && isempty(SPM_mat_path)) || (~isempty(subject_dir) && isempty(SPM_mat_path))
        warning('TMFC Subjects: Please select SPM.mat file for the first subject.');
    elseif (isempty(subject_full_path) && ~isempty(SPM_mat_path))
        warning('TMFC Subjects: Please Re-select subjects and SPM.mat file if required.');
    else
        SS_MW_exit(SS_MW);   
        freeze_GUI(1);
        
        % Check SPM.mat files
        if SPM_check == 1
                
            % Stage 1 - Check SPM.mat files existence
            [file_exist] = check_file_exist(subject_full_path);        
            if size(file_exist,1) == 0
            	warning('TMFC Subjects: (Stage 1 Check Failed) - Selected SPM.mat files are missing from the directories. Please try again.');
                reset_paths();
            else
                
                % Stage 2 - Check task conditions
                [file_correct] = check_file_cond(file_exist);          
                if size(file_correct,1) == 0
                    warning('TMFC Subjects: (Stage 2 Check Failed) - Selected SPM.mat files have different task conditions and/or number of sessions. Please select SPM.mat files with the same task conditions and number of sessions.');
                    reset_paths();
                else
                    
                    % Stage 3 - Check output directories 
                    [file_dir] = check_file_dir(file_correct);
                    if size(file_correct,1) == 0
                        warning('TMFC Subjects: (Stage 3 Check Failed) - Directory where the output files will be saved are missing (check SPM.swd). Please select correct SPM.mat files or change paths in SPM.mat files.');
                        reset_paths();
                    else
                        
                        % Stage 4 - Check functional files
                        [file_func] = check_file_func(file_dir);
                
                        if size(file_dir,1) == 0
                            warning('TMFC Subjects: (Stage 4 Check Failed) - Functional files specified in SPM.mat file are missing. Please select correct SPM.mat files or change paths in SPM.mat files.');
                            reset_paths();
                        else
                            paths = file_func;
                            freeze_GUI(0)
                        end
                    end 
                end
            end
        else
            paths = subject_full_path; 
            freeze_GUI(0);
        end
    end                                                                 
end      

%--------------------------------------------------------------------------
% Clear temporary variables
function reset_paths(~,~)
    subject_dir = {};
    subject_full_path = {};
    SPM_mat_path = {};
    add_new_subs = {};
    selected_sub = {};
end

%--------------------------------------------------------------------------
% Close select subjects GUI window
function SS_MW_exit(~,~) 
    delete(SS_MW);
    if exist('paths', 'var') == 0
        paths = [];
        freeze_GUI(0);
    end   
end

uiwait(SS_MW);
return;

end

%% Select subjects
function subject_dir = add_subjects(~,~)

    subjects = spm_select(inf,'dir','Select subject folders',{},pwd,'..');
    subject_dir = {};                % Cell to store subjects    
    % Updating list of Subjects
    for iSub = 1:size(subjects,1)
        subject_dir = vertcat(subject_dir, subjects(iSub,:));
    end
    subject_dir = unique(subject_dir);
    clear subjects
end              

%% Select SPM.mat file
function [subject_full_path, SPM_mat_path] = add_mat_file(subject_dir)

    subject_full_path = {};  
    [mat_file_path] = spm_select( 1,'any','Select SPM.mat file for the first subject',{}, strtrim(subject_dir(1,:)), 'SPM.*');    
    [SPM_mat_path] = strrep(mat_file_path, strtrim(subject_dir(1,:)),'');     
        
    for iSub = 1:size(subject_dir,1)
    	subject_full_path =  vertcat(subject_full_path,strcat(char(subject_dir(iSub,:)),char(SPM_mat_path)));
    end
    clear mat_file_path
end 

%% Check SPM.mat files existence
function [file_exist] = check_file_exist(subject_full_path)

    file_exist = {};
    file_not_exist = {};     
    
    % Condition to verify if file exists in the location
    for iSub = 1:length(subject_full_path) 
        if exist(subject_full_path{iSub}, 'file')
            file_exist{iSub,1} = subject_full_path{iSub};
        else
            file_not_exist{iSub,1} = subject_full_path{iSub};
        end                
    end 
    
    % Checks if the variables storing the existing files are empty or full
    try
        file_exist = file_exist(~cellfun('isempty', file_exist)); 
    end

    try 
        file_not_exist = file_not_exist(~cellfun('isempty',file_not_exist)); 
    end
    
    % Show missing SPM.mat files
    if length(file_exist) ~= length(subject_full_path)      
        % SS_WW = select subjects warning window
        SS_WW = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');
        SS_WW_LB = uicontrol(SS_WW, 'Style', 'listbox', 'String', file_not_exist,'Max',100,'Units', 'normalized', 'Position',[0.028 0.250 0.940 0.520],'FontUnits','normalized','FontSize',0.08);
        SS_WW_S1 = uicontrol(SS_WW,'Style','text','String', 'Warning, the following SPM.mat files are missing:','Units', 'normalized', 'Position',[0.15 0.820 0.720 0.095], 'FontUnits','normalized','FontSize',0.5,'backgroundcolor', 'w');
        SS_WW_close = uicontrol(SS_WW,'Style','pushbutton', 'String', 'OK','Units', 'normalized',  'Position',[0.415 0.06 0.180 0.120] ,'FontUnits','normalized','FontSize',0.30,'callback', @close_SS_WW);
        movegui(SS_WW,'center');
        uiwait();
    end
    
    function close_SS_WW(~,~)
        delete(SS_WW);
    end   
    
    clear file_not_exist
end

%% Check conditions specified in SPM.mat files
function [file_correct] = check_file_cond(subject_full_path)
    
    file_incorrect = {};
    file_correct = {};
    
    if length(subject_full_path) > 1

        w = waitbar(0,'Check conditions','Name','Check SPM.mat files');

        % Reference SPM.mat file
        file_correct{1,1} = subject_full_path{1};
        SPM_ref = load(subject_full_path{1});

        % Reference structure for conditions
        for iSub = 1:length(SPM_ref.SPM.Sess)
            cond_ref(iSub).sess = struct('name', {SPM_ref.SPM.Sess(iSub).U(:).name});
        end

        % Start check
        for iSub = 2:length(subject_full_path)
            
            % SPM.mat file to check
            SPM = load(subject_full_path{iSub});

            % Structure for conditions to check
            for jSub = 1:length(SPM.SPM.Sess)
                cond(jSub).sess = struct('name', {SPM.SPM.Sess(jSub).U(:).name});
            end 

            if ~isequaln(cond_ref, cond)
                file_incorrect{iSub,1} = subject_full_path{iSub};
            else
                file_correct{iSub,1} = subject_full_path{iSub};
            end

            try
                waitbar(iSub/length(subject_full_path),w);
            end

            clear SPM cond
        end
        
    else
        file_correct = subject_full_path;
    end

    try
        close(w)
    end

    try
        file_correct = file_correct(~cellfun('isempty', file_correct));
    end

    try
        file_incorrect = file_incorrect(~cellfun('isempty', file_incorrect));
    end

    % Show incorrect SPM.mat files
    if length(file_correct) ~= length(subject_full_path)
        % Creation of GUI Figure 
        SS_WW = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');
        SS_WW_LB = uicontrol(SS_WW, 'Style', 'listbox', 'String', file_incorrect,'Max',100,'Units', 'normalized', 'Position',[0.028 0.250 0.940 0.520],'FontUnits','normalized','FontSize',0.08);
        SS_WW_S1 = uicontrol(SS_WW,'Style','text','String', 'Warning, the following SPM.mat files have different conditions specified:','Units', 'normalized', 'Position',[0.15 0.820 0.720 0.095], 'FontUnits','normalized','FontSize',0.5,'backgroundcolor', 'w');%
        SS_WW_close = uicontrol(SS_WW,'Style','pushbutton', 'String', 'OK','Units', 'normalized',  'Position',[0.415 0.06 0.180 0.120] ,'FontUnits','normalized','FontSize',0.30,'callback', @close_SS_WW);
        movegui(SS_WW,'center');
        uiwait();
    end
    
    function close_SS_WW(~,~)
        close(SS_WW);
    end
    clear SPM_ref file_incorrect cond_ref
end


%% Check output directories (SPM.swd) specified in SPM.mat files
function [file_dir] = check_file_dir(subject_full_path)

	file_dir = {};
    file_no_dir = {};
    w = waitbar(0,'Check directories','Name','Check SPM.mat files');

    for iSub = 1:length(subject_full_path)
        
        SPM = load(subject_full_path{iSub});
        
        if exist(SPM.SPM.swd, 'dir') 
            file_dir{iSub,1} = subject_full_path{iSub};
        else
            file_no_dir{iSub,1} = subject_full_path{iSub};
        end
        
        clear SPM
        
        try
            waitbar(iSub/length(subject_full_path),w);
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
    
    % Show incorrect SPM.mat files
    if length(file_dir) ~= length(subject_full_path)
        SS_WW = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');
        SS_WW_LB = uicontrol(SS_WW, 'Style', 'listbox', 'String', file_no_dir,'Max',100,'Units', 'normalized', 'Position',[0.028 0.250 0.940 0.520],'FontUnits','normalized','FontSize',0.08);
        SS_WW_S1 = uicontrol(SS_WW,'Style','text','String', 'Warning, the output folder (SPM.swd) specified in the following SPM.mat files do not exist:','Units', 'normalized', 'Position',[0.15 0.820 0.720 0.095], 'FontUnits','normalized','FontSize',0.5,'backgroundcolor', 'w');%
        SS_WW_close = uicontrol(SS_WW,'Style','pushbutton', 'String', 'OK','Units', 'normalized',  'Position',[0.415 0.06 0.180 0.120] ,'FontUnits','normalized','FontSize',0.30,'callback', @close_SS_WW);
        movegui(SS_WW,'center');
    	uiwait();
    end
    
    function close_SS_WW(~,~)
    	delete(SS_WW);
    end   

    clear file_no_dir
end
            
%% Check functional files specified in SPM.mat files 
function [file_func] = check_file_func(subject_full_path)

    file_func = {};
    file_no_func = {};
    w = waitbar(0,'Check functional files','Name','Check SPM.mat files');

    for iSub = 1:length(subject_full_path) 
        
        SPM = load(subject_full_path{iSub});
        
        for j = 1:length(SPM.SPM.xY.VY)
            funct_check(j) = exist(SPM.SPM.xY.VY(j).fname, 'file');
        end
        
        if nnz(funct_check) == length(SPM.SPM.xY.VY)
            file_func{iSub,1} = subject_full_path{iSub};
        else
            file_no_func{iSub,1} = subject_full_path{iSub};
        end
        clear SPM funct_check      
        
        try
            waitbar(iSub/length(subject_full_path),w);
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
    
    if length(file_func) ~= length(subject_full_path)
        SS_WW = figure('Name', 'Subject Manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');
        SS_WW_LB = uicontrol(SS_WW, 'Style', 'listbox', 'String', file_no_func,'Max',100,'Units', 'normalized', 'Position',[0.028 0.250 0.940 0.520],'FontUnits','normalized','FontSize',0.08);
        SS_WW_S1 = uicontrol(SS_WW,'Style','text','String', 'Warning, the functional files specified in the following SPM.mat files do not exist:','Units', 'normalized', 'Position',[0.15 0.820 0.720 0.095], 'FontUnits','normalized','FontSize',0.5,'backgroundcolor', 'w');%
        SS_WW_close = uicontrol(SS_WW,'Style','pushbutton', 'String', 'OK','Units', 'normalized',  'Position',[0.415 0.06 0.180 0.120] ,'FontUnits','normalized','FontSize',0.30,'callback', @close_SS_WW);
        movegui(SS_WW,'center');
        uiwait();
    end
    
    function close_SS_WW(~,~)
        delete(SS_WW);
    end

    clear file_no_func
end


%% Freeze/unfreeze main TMFC GUI
function freeze_GUI(state)

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
            main_GUI.TMFC_GUI_B12a,main_GUI.TMFC_GUI_B12b,main_GUI.TMFC_GUI_B13a,main_GUI.TMFC_GUI_B13b,...
            main_GUI.TMFC_GUI_B14a,main_GUI.TMFC_GUI_B14b], 'Enable', state);
    end       
     
end
