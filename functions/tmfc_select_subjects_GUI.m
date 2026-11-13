 function [SPM_paths, subject_paths, SPM_subfolder, session_mode] = tmfc_select_subjects_GUI(SPM_check)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for selecting individual subject SPM.mat files
% created by SPM after first level GLM estimation. Optionally checks
% SPM.mat files: 
% (1) checks if all SPM.mat and mask.nii files are present in the specified paths
% (2) checks if the same conditions and HRF basis functions are specified in all SPM.mat files
% (3) checks if output folders specified in SPM.mat files exist
% (4) checks if functional files specified in SPM.mat files exist
%
% FORMAT [SPM_paths, subject_paths, SPM_subfolder, session_mode] = tmfc_select_subjects_GUI(SPM_check)
%
%   Inputs: 
%   SPM_check         - 0 or 1 (don't check or check SPM.mat files)
%
%   Outputs:
%   SPM_paths         - Full paths to selected SPM.mat files
%   subject_paths     - Paths to selected subjects
%   SPM_subfolder     - Subfolder for SPM.mat files
%   session_mode      - 'strict' or 'repeated'
%                       'strict'   - same number of runs (SPM sessions) and matching conditions across subjects
%                       'repeated' - different numbers of exchangeable runs with the same conditions in each run
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin == 0
	SPM_check = 1;
end

spm_jobman('initcfg');
                    
% SS = select subjects, MW = main window 
SS_MW = figure('Name', 'Select subjects', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.36 0.25 0.35 0.575],'MenuBar', 'none','ToolBar', 'none','color','w','CloseRequestFcn',@SS_MW_exit);
SS_MW_S1 = uicontrol(SS_MW,'Style','text','String', 'Not Selected','ForegroundColor','red','Units', 'normalized', 'Position',[0.500 0.820 0.450 0.095],'backgroundcolor','w','FontUnits','normalized','FontSize',0.25);
SS_MW_S2 = uicontrol(SS_MW,'Style','text','String', 'Not Selected','ForegroundColor','red','Units', 'normalized', 'Position',[0.500 0.720 0.450 0.095],'backgroundcolor','w','FontUnits','normalized','FontSize',0.25);
SS_MW_LB1 = uicontrol(SS_MW, 'Style', 'listbox', 'String', '','Max', 100000,'Units', 'normalized', 'Position',[0.033 0.250 0.920 0.490],'FontUnits','points','FontSize',10,'Value', [],'callback', @SS_LB_select);
SS_MW_sel_sub = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Select subject folders','Units', 'normalized', 'Position',[0.033 0.850 0.455 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @select_sub);
SS_MW_sel_mat = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Select SPM.mat file (first subject)','Units', 'normalized', 'Position',[0.033 0.750 0.455 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @select_SPM_mat);
SS_MW_add_new = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Add new subject','Units', 'normalized', 'Position',[0.033 0.14 0.300 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @add_new);
SS_MW_rem = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Remove selected subject','Units', 'normalized', 'Position',[0.346 0.14 0.300 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @remove_sub);
SS_MW_rem_all = uicontrol(SS_MW,'Style','pushbutton', 'String', 'Clear all subjects','Units', 'normalized', 'Position',[0.660 0.14 0.300 0.095],'FontUnits','normalized','FontSize',0.25,'callback', @remove_all);

% Button: Help
SS_MW_HELP = uicontrol(SS_MW,'Style','pushbutton','String','Help', ...
    'Units','normalized','Position',[0.55 0.04 0.200 0.080], ...
    'FontUnits','normalized','FontSize',0.28,'Callback',@open_help);

% Button: OK
SS_MW_conf = uicontrol(SS_MW,'Style','pushbutton', 'String', 'OK', ...
    'Units', 'normalized', 'Position',[0.24 0.04 0.200 0.080], ...
    'FontUnits','normalized','FontSize',0.28,'callback', @confirm_paths);

movegui(SS_MW,'center');

% Temporary variables
subject_paths_tmp = {};       % Variable to store subject paths
subject_full_path = {};       % Variable to store full paths
SPM_mat_path = {};            % Variable to store subfolder for SPM.mat file
selected_sub = {};            % Variable to store the selected list of paths (as INDEX)
add_new_subs = {};            % Variable used to add new subjects
session_mode = 'strict';

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
    subject_paths_tmp = add_subjects();             

    if isempty(subject_paths_tmp)
    	disp('TMFC Subjects: 0 Subjects selected');
        set(SS_MW_S1,'String','Not selected','ForegroundColor','red');
        set(SS_MW_S2,'String','Not selected','ForegroundColor','red');
        SPM_mat_path = {};
        subject_full_path = {};
    else
        fprintf('TMFC Subjects: Subjects selected: %d \n', size(subject_paths_tmp,1));
        disp('TMFC Subjects: Select the SPM.mat file for the first subject.');
        set(SS_MW_S1,'String', strcat(num2str(size(subject_paths_tmp,1)),' selected'),'ForegroundColor',[0.219, 0.341, 0.137]);    
        set(SS_MW_S2,'String','Not selected','ForegroundColor','red');
        SPM_mat_path = {};
        subject_full_path = {};
    end
    
    if isempty(subject_full_path) && isempty(SPM_mat_path) && isempty(subject_paths_tmp)
        fprintf(2,'No subjects selected.\n');
        SPM_mat_path = {}; 
        subject_full_path = {}; 
        subject_paths_tmp = {}; 
        set(SS_MW_S1,'String','Not selected','ForegroundColor','red');
        set(SS_MW_S2,'String','Not selected','ForegroundColor','red');
    end 
end

%--------------------------------------------------------------------------
% Select SPM.mat file
function select_SPM_mat(~,~)
    if isempty(subject_paths_tmp)
        fprintf(2,'TMFC Subjects: Please select subject folders.\n');        
        
    elseif isempty(subject_full_path) && isempty(subject_paths_tmp)
        fprintf(2,'TMFC Subjects: Please select subject folders.\n');
        set(SS_MW_S2,'String','Not selected','ForegroundColor','red');
        set(SS_MW_LB1, 'String', '');
        
    else
        [subject_full_path, SPM_mat_path] = add_mat_file(subject_paths_tmp);            
        if ~isempty(SPM_mat_path)
            set(SS_MW_LB1, 'String', subject_full_path);                          
            disp('TMFC Subjects: The SPM.mat file has been succesfully selected.');
            set(SS_MW_S2,'String','Selected','ForegroundColor',[0.219, 0.341, 0.137]);
            SPM_subfolder = strrep(SPM_mat_path, '\SPM.mat', '');
        else
            fprintf(2,'TMFC Subjects: The SPM.mat file has not been selected.\n');
            set(SS_MW_S2,'String','Not selected','ForegroundColor','red');
            set(SS_MW_LB1,'String','');
        end 
    end
end

%--------------------------------------------------------------------------
% Add new subjects to the list
function add_new(~,~)   
    if isempty(subject_paths_tmp) || isempty(subject_full_path)
        fprintf(2,'TMFC Subjects: No existing list of subjects present. Please select subjects via ''Select subject folders'' button. \n');
        
    elseif isempty(SPM_mat_path)
        fprintf(2,'TMFC Subjects: Cannot add new subjects without SPM.mat file. Please select subjects via ''Select subject folders'' button and proceed to Select SPM.mat file. \n');

    else
        add_subs_full_path = {};                    
        add_new_subs = add_subjects();             
        
        if isempty(add_new_subs)
            fprintf(2,'TMFC Subjects: No newly selected subjects. \n');
        else
            subs_exist = size(subject_full_path,1); 
            
            for iSub = 1:size(add_new_subs,1)
               add_subs_full_path =  vertcat(add_subs_full_path,strcat(char(add_new_subs(iSub,:)),char(SPM_mat_path)));
            end
                        
            subject_full_path = vertcat(subject_full_path, add_subs_full_path);   % Joining existing list of subjects with new subjects
            new_subs_count = size(unique(subject_full_path)) - subs_exist;        % Removing duplicates
            subject_full_path = unique(subject_full_path,'stable');
            
            subject_paths_tmp = vertcat(subject_paths_tmp, add_new_subs);
            subject_paths_tmp = unique(subject_paths_tmp,'stable');

            if new_subs_count(1) == 0
                fprintf(2,'TMFC Subjects: Newly selected subjects are already present in the list, no new subjects added. \n');
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
        fprintf(2,'TMFC Subjects: There are no selected subjects to remove from the list. Please select subjects to remove.\n');
    else
        subject_full_path(selected_sub,:) = [];   
        subject_paths_tmp(selected_sub,:) = [];   
        fprintf('TMFC Subjects: Number of subjects removed: %d. \n', size(selected_sub,2));
        
        set(SS_MW_LB1,'Value',[]);                                             
        set(SS_MW_LB1, 'String', subject_full_path);                              
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
    if isempty(subject_paths_tmp) || isempty(subject_full_path)
        fprintf(2,'TMFC Subjects: No subjects present to remove.\n');
    else
        subject_paths_tmp = {};
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
% Help window
function open_help(~,~)
   page1 = {
        ''
        '   ========================== EXAMPLE #1 (SPM-like folder structure) =========================='
        ''
        '   (1) Select the subject folders (each containing a STAT subfolder with an SPM.mat file).'  
        '   (2) Select the SPM.mat file for the first subject.'
        ''
        '   project/'
        '   ├─ rawdata/ #DICOM' 
        '   └─ derivatives/'
        '      ├─ sub-01/    <------------------------------------------ [Select subject folder #1]  (1)' 
        '      │  ├─ anat/'
        '      │  │  ├─ *T1*.nii'
        '      │  │  └─ *T1*.nii derivatives'
        '      │  ├─ func/'
        '      │  │  ├─ run-01/'
        '      │  │  │  ├─ Unprocessed functional files (*.nii)'
        '      │  │  │  └─ Preprocessed functional files:'
        '      │  │  │       ◦ smoothed + norm. + real. (e.g., swar*.nii)'
        '      │  │  │       ◦ unsmoothed + norm. + real. (e.g., war*.nii)' 
        '      │  │  └─ run-02/ ...'
        '      │  └─ stat/              # first-level models (one folder per GLM)'
        '      │     ├─ GLM-01/'
        '      │     │  ├─ SPM.mat  <-------------- [Select the SPM.mat file for the first subject]  (2)'
        '      │     │  └─ TMFC_denoise/ <----------------------------------------- [Output folder]'
        '      │     └─ GLM-02/ ...'
        '      └─ sub-02/ ...  <---------------------------------------- [Select subject folder #2]  (1)'
    };

    page2 = {
        ''
        '   ========================== EXAMPLE #2 (BIDS-like folder structure) ========================='
        ''
        '   (1) Select the subject folders (each containing a STAT subfolder with an SPM.mat file).'  
        '   (2) Select the SPM.mat file for the first subject.'
        ''
        '   project/'
        '   ├── sub-01/'
        '   │   ├── ses-01/'
        '   │   │   ├── anat/'
        '   │   │   │   └── *T1*.nii'
        '   │   │   └── func/     # Unprocessed functional files'
        '   │   └── ses-02/ ...'
        '   ├── sub-02/ ...'
        '   └── derivatives'
        '       ├── fmriprep/'
        '       │   ├── sub-01/'
        '       │   │   ├── ses-01/'
        '       │   │   │   └── func/'
        '       │   │   │       └── Preprocessed functional files:'
        '       │   │   │           ◦ smoothed + normalized + realigned'
        '       │   │   │           ◦ unsmoothed + normalized + realigned'
        '       │   │   └── ses-02/ ...'
        '       │   └── sub-02/ ...'
        '       └── firstlevel-spm/'
        '           ├── sub-01/     <----------------------------------- [Select subject folder #1]  (1)'
        '           │   ├── GLM-01/'
        '           │   │   ├── SPM.mat  <--------- [Select the SPM.mat file for the first subject]  (2)'
        '           │   │   └── TMFC_denoise/  <----------------------------------- [Output folder]'
        '           │   └── GLM-02/ ...'
        '           └── sub-02/ ...  <---------------------------------- [Select subject folder #2]  (1)'
    };

    page3 = {
        ''
        '   ========================== EXAMPLE #3 (Other non-BIDS folder structure) ====================='
        ''
        '   (1) Select the subject folders (each containing a STAT subfolder with an SPM.mat file).'  
        '   (2) Select the SPM.mat file for the first subject.'
        ''
        '   project/'
        '   ├─ rawdata/ # DICOM'
        '   ├─ nifti/'
        '   │  ├─ sub-01/'
        '   │  │  ├─ anat/'
        '   │  │  │  ├─ *T1*.nii  '
        '   │  │  │  └─ *T1*.nii derivatives'
        '   │  │  └─ func/'
        '   │  │     ├─ run-01/'
        '   │  │     │  ├─ Unprocessed functional files (*.nii)'
        '   │  │     │  └─ Preprocessed functional files (*.nii):'
        '   │  │     │     ◦ smoothed + normalized + realigned'
        '   │  │     │     ◦ unsmoothed + normalized + realigned'
        '   │  │     └─ run-02/ ...'
        '   │  └─ sub-02/ ...'
        '   └─ firstlevel-spm/'
        '      ├─ sub-01/   <------------------------------------------- [Select subject folder #1]  (1)'
        '      │  ├─ GLM-01/'
        '      │  │  ├─ SPM.mat   <---------------- [Select the SPM.mat file for the first subject]  (2)'
        '      │  │  └─ TMFC_denoise/   <------------------------------------------ [Output folder]'
        '      │  └─ GLM-02/ ...'
        '      └─ sub-02/ ...   <--------------------------------------- [Select subject folder #2]  (1)'
    };

    pages = {page1,page2,page3};
    cur=1; total=numel(pages);

    ST_HELP = figure('Name','Help','NumberTitle','off','Units','normalized', ...
        'Position',[0.22 0.10 0.60 0.75], 'MenuBar','none','ToolBar','none', ...
        'Color','w','WindowStyle','Modal');

    txtArea = uicontrol(ST_HELP,'Style','edit', ...
        'Units','normalized','Position',[0.05 0.14 0.90 0.78], ...
        'BackgroundColor','w','Enable','inactive', ...
        'Max', 2, 'Min', 0, 'HorizontalAlignment','left', ...
        'FontName','Courier New','FontUnits','normalized','FontSize',0.025);

    btnPrev = uicontrol(ST_HELP,'Style','pushbutton','String','Previous', ...
        'Units','normalized','Position',[0.05 0.05 0.14 0.06], ...
        'FontUnits','normalized','FontSize',0.35, 'Callback',@go_prev);

    pageLbl = uicontrol(ST_HELP,'Style','text','String','', ...
        'Units','normalized','Position',[0.205 0.035 0.19 0.06], ...
        'BackgroundColor','w','HorizontalAlignment','center', ...
        'FontUnits','normalized','FontSize',0.40);

    btnNext = uicontrol(ST_HELP,'Style','pushbutton','String','Next', ...
        'Units','normalized','Position',[0.405 0.05 0.14 0.06], ...
        'FontUnits','normalized','FontSize',0.35, 'Callback',@go_next);

    btnOK = uicontrol(ST_HELP,'Style','pushbutton','String','OK', ...
        'Units','normalized','Position',[0.81 0.05 0.14 0.06], ...
        'FontUnits','normalized','FontSize',0.35, ...
        'Callback',@(s,e) close(ST_HELP));

    render_page(); movegui(ST_HELP,'center'); uiwait(ST_HELP);

    function render_page()
        set(txtArea,'String', pages{cur});
        set(pageLbl,'String', sprintf('Page %d of %d', cur, total));
        set(btnPrev,'Enable', tern(cur>1,'on','off'));
        set(btnNext,'Enable', tern(cur<total,'on','off'));
    end
    function go_prev(~,~), if cur>1, cur=cur-1; render_page(); end, end
    function go_next(~,~), if cur<total, cur=cur+1; render_page(); end, end
    function out = tern(cond,a,b), if cond, out=a; else, out=b; end, end
end

%--------------------------------------------------------------------------
% Check SPM.mat files and export paths
function confirm_paths(~,~)
	file_correct = {};
    file_exist = {};
    file_dir = {};
    file_func = {};
         
    % Initial checks
    if isempty(subject_paths_tmp)
        fprintf(2,'TMFC Subjects: There are no selected subjects. Please select subjects and SPM.mat files.\n');
    elseif (isempty(subject_full_path) && isempty(SPM_mat_path)) || (~isempty(subject_paths_tmp) && isempty(SPM_mat_path))
        fprintf(2,'TMFC Subjects: Please select the SPM.mat file for the first subject.\n');
    elseif (isempty(subject_full_path) && ~isempty(SPM_mat_path))
        fprintf(2,'TMFC Subjects: Please re-select subjects and SPM.mat file if required.\n');
    else
        SS_MW_exit(SS_MW);   
        
        % Check SPM.mat files
        if SPM_check == 1              
            % Stage 1 - Check SPM.mat and mask.nii files existence
            [file_exist,subject_file_exist] = check_file_exist(subject_full_path,subject_paths_tmp);        
            if size(file_exist,1) == 0
            	fprintf(2,'TMFC Subjects: (Stage 1 Check Failed) - Selected SPM.mat or mask.nii files are missing from the directories. Please try again.\n');
                reset_paths();
            else                
                % Stage 2 - Check conditions and HRF basis functions specified in SPM.mat files
                [file_correct,subject_file_correct,session_mode] = check_file_cond(file_exist,subject_file_exist);          
                if size(file_correct,1) == 0
                    fprintf(2,'TMFC Subjects: (Stage 2 Check Failed) - Selected SPM.mat files have incompatible task conditions or HRF basis functions.\n');
                    reset_paths();
                else                    
                    % Stage 3 - Check output directories 
                    [file_dir,subject_file_dir] = check_file_dir(file_correct,subject_file_correct);
                    if size(file_dir,1) == 0
                        fprintf(2,'TMFC Subjects: (Stage 3 Check Failed) - Directory where the output files will be saved are missing (check SPM.swd). Please select correct SPM.mat files or change paths in SPM.mat files.\n');
                        reset_paths();
                    else                        
                        % Stage 4 - Check functional files
                        [file_func,subject_file_func] = check_file_func(file_dir,subject_file_dir);                
                        if size(file_func,1) == 0
                            fprintf(2,'TMFC Subjects: (Stage 4 Check Failed) - Functional files specified in SPM.mat file are missing. Please select correct SPM.mat files or change paths in SPM.mat files.\n');
                            reset_paths();
                        else
                            SPM_paths = file_func; 
                            subject_paths = subject_file_func;
                        end
                    end 
                end
            end
        else
            SPM_paths = subject_full_path; 
            subject_paths = subject_paths_tmp;
        end
    end                                                                 
end      

%--------------------------------------------------------------------------
% Clear temporary variables
function reset_paths(~,~)
	subject_paths_tmp = {};
    subject_full_path = {};
    SPM_mat_path = {};
    add_new_subs = {};
    selected_sub = {};
    SPM_subfolder = {};
end

%--------------------------------------------------------------------------
% Close select subjects GUI window
function SS_MW_exit(~,~) 
    if exist('paths', 'var') == 0
        SPM_paths = [];
        subject_paths = [];
        SPM_subfolder = [];
    end
    uiresume(SS_MW);
end

uiwait(SS_MW);
delete(SS_MW)
return;

end

%% Select subjects
function subject_dir = add_subjects(~,~)
    subjects = spm_select(inf,'dir','Select subject folders',{},pwd,'..');
    subject_dir = {};                % Cell to store subjects    
    % Updating list of Subjects
    for iSub = 1:size(subjects,1)
    	subject_dir = vertcat(subject_dir, deblank(subjects(iSub,:)));
    end
    subject_dir = unique(subject_dir,'stable');
end              

%% Select SPM.mat file
function [subject_full_path, SPM_mat_path] = add_mat_file(subject_dir)

    subject_full_path = {};
    SPM_mat_path = {};

    mat_file_path = spm_select(1,'^SPM\.mat$','Select the SPM.mat file for the first subject',{}, strtrim(subject_dir{1}),'SPM.*');

    if isempty(mat_file_path)
        return;
    end

    mat_file_path = strtrim(mat_file_path);

    % Find which selected subject folder contains the SPM.mat file
    for iSub = 1:numel(subject_dir)
        base = strtrim(subject_dir{iSub});
        if base(end) == filesep
            base(end) = [];
        end
        prefix = [base filesep];
        if strncmpi(mat_file_path,prefix,numel(prefix))
            SPM_mat_path = mat_file_path(numel(base)+1:end);
            break;
        end
    end

    if isempty(SPM_mat_path)
        fprintf(2,'Selected SPM.mat is outside the selected subject folders.\n');
        return;
    end

    % Construct SPM.mat paths for all subjects
    for iSub = 1:numel(subject_dir)
        subject_full_path{end+1,1} = fullfile(strtrim(subject_dir{iSub}),SPM_mat_path(2:end));
    end
end

%% Check SPM.mat and mask.nii files existence
function [file_exist,subject_file_exist] = check_file_exist(subject_full_path,subject_paths_tmp)

    file_exist = {};
    file_not_exist = {};   
    subject_file_exist = {};
    
    % Check if SPM.mat and mask.nii files exist
    for iSub = 1:length(subject_full_path) 
        if exist(subject_full_path{iSub}, 'file') && exist(fullfile(fileparts(subject_full_path{iSub}),'mask.nii'),'file') 
            file_exist{iSub,1} = subject_full_path{iSub};
            subject_file_exist{iSub,1} = subject_paths_tmp{iSub};
        else
            file_not_exist{iSub,1} = subject_full_path{iSub};
        end                
    end 
    
    % Check if the variables storing the existing files are empty
    try
        file_exist = file_exist(~cellfun('isempty', file_exist)); 
        subject_file_exist = subject_file_exist(~cellfun('isempty', subject_file_exist));
    end

    try 
        file_not_exist = file_not_exist(~cellfun('isempty',file_not_exist)); 
    end
    
    % Show missing SPM.mat or mask.nii files
    if length(file_exist) ~= length(subject_full_path)      
    	% SS_WW = select subjects warning window
        SS_WW1 = figure('Name', 'Select subjects', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');
        SS_WW_LB = uicontrol(SS_WW1, 'Style', 'listbox', 'String', file_not_exist,'Max',inf,'Units', 'normalized', 'Position',[0.032 0.250 0.940 0.520],'FontUnits','points','FontSize',10);
        SS_WW_S1 = uicontrol(SS_WW1,'Style','text','String', 'Warning, the following subjects have missing SPM.mat or mask.nii files:','Units', 'normalized', 'Position',[0.15 0.820 0.720 0.095], 'FontUnits','normalized','FontSize',0.5,'backgroundcolor', 'w');
        SS_WW_close = uicontrol(SS_WW1,'Style','pushbutton', 'String', 'OK','Units', 'normalized',  'Position',[0.415 0.06 0.180 0.120] ,'FontUnits','normalized','FontSize',0.30,'callback', @close_SS_WW);
        movegui(SS_WW1,'center');
        uiwait(SS_WW1);
    end
    
    function close_SS_WW(~,~)
        close(SS_WW1);
    end   
end

%% Check conditions and HRF basis functions specified in SPM.mat files
function [file_correct,subject_file_correct,session_mode] = check_file_cond(file_exist,subject_file_exist)
    
    file_incorrect = {};
    file_correct = {};
    subject_file_correct = {};
    session_mode = 'strict';
    
    if length(file_exist) > 1

        w = waitbar(0,'Check conditions and HRF basis functions','Name','Check SPM.mat files');

        % Check number of runs (SPM sessions)
        nSess = zeros(length(file_exist),1);
        for iSub = 1:length(file_exist)
            SPM = load(file_exist{iSub}).SPM;
            nSess(iSub) = length(SPM.Sess);
        end

        % =================================================================
        % STRICT MODE: all subjects have the same number of runs
        % =================================================================
        if length(unique(nSess)) == 1

            % Reference SPM.mat file
            file_correct{1,1} = file_exist{1};
            subject_file_correct{1,1} = subject_file_exist{1};
            SPM_ref = load(file_exist{1});
            basis_ref = strtrim(SPM_ref.SPM.xBF.name);
    
            % Reference structure for conditions
            for iSess = 1:length(SPM_ref.SPM.Sess)
                cond_ref(iSess).sess = struct('name', {SPM_ref.SPM.Sess(iSess).U(:).name});
            end
    
            % Start check
            for iSub = 2:length(file_exist)
                
                % SPM.mat file to check
                SPM = load(file_exist{iSub}).SPM;
    
                % Structure for conditions to check
                for jSess = 1:length(SPM.Sess)
                    cond(jSess).sess = struct('name', {SPM.Sess(jSess).U(:).name});
                end 
    
                if ~isequaln(cond_ref,cond) || ~strcmpi(strtrim(SPM.xBF.name),basis_ref)
                    file_incorrect{iSub,1} = file_exist{iSub};
                else
                    file_correct{iSub,1} = file_exist{iSub};
                    subject_file_correct{iSub,1} = subject_file_exist{iSub};
                end
    
                try
                    waitbar(iSub/length(file_exist),w);
                end
    
                clear SPM cond
            end
        % =================================================================
        % REPEATED MODE: subjects have different numbers of runs
        % =================================================================
        else

            % First run of the first subject is used as reference
            SPM_ref = load(file_exist{1}).SPM;
            cond_ref = struct('name', {SPM_ref.Sess(1).U(:).name});
            basis_ref = strtrim(SPM_ref.xBF.name);

            % Every run of every subject must have the same conditions
            for iSub = 1:length(file_exist)

                SPM = load(file_exist{iSub}).SPM;
                cond_match = 1;

                if ~strcmpi(strtrim(SPM.xBF.name),basis_ref)
                    cond_match = 0;
                end
                
                if cond_match == 1
                    for iSess = 1:length(SPM.Sess)
                        cond = struct('name', {SPM.Sess(iSess).U(:).name});
                        if ~isequaln(cond_ref, cond)
                            cond_match = 0;
                            break
                        end
                    end
                end

                if cond_match == 0
                    file_incorrect{iSub,1} = file_exist{iSub};
                else
                    file_correct{iSub,1} = file_exist{iSub};
                    subject_file_correct{iSub,1} = subject_file_exist{iSub};
                end

                try
                    waitbar(iSub/length(file_exist),w);
                end

                clear SPM cond
            end
        end
    else
        file_correct = file_exist;
        subject_file_correct = subject_file_exist;
    end

    try
        close(w)
    end

    try
        file_correct = file_correct(~cellfun('isempty', file_correct));
        subject_file_correct = subject_file_correct(~cellfun('isempty', subject_file_correct));
    end

    try
        file_incorrect = file_incorrect(~cellfun('isempty', file_incorrect));
    end

    % Show incorrect SPM.mat files
    if length(file_correct) ~= length(file_exist)
        if isunix; fontscale = 0.85; else; fontscale = 1; end
        SS_WW2 = figure('Name', 'Select subjects', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.30 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');
        SS_WW_LB = uicontrol(SS_WW2, 'Style', 'listbox', 'String', file_incorrect,'Max',inf,'Units', 'normalized', 'Position',[0.032 0.250 0.940 0.520],'FontUnits','points','FontSize',10);
        SS_WW_S1 = uicontrol(SS_WW2, 'Style', 'text', ...
            'String', {'Warning, the following SPM.mat files have', ...
            'different conditions or HRF basis functions specified:'}, ...
            'Units', 'normalized', ...
            'Position', [0.08 0.80 0.84 0.16], ...
            'FontUnits', 'points', 'FontSize', 10, ...
            'HorizontalAlignment', 'center', ...
            'backgroundcolor', 'w');
        SS_WW_close = uicontrol(SS_WW2,'Style','pushbutton', 'String', 'OK','Units', 'normalized',  'Position',[0.415 0.06 0.180 0.120] ,'FontUnits','normalized','FontSize',0.30,'callback', @close_SS_WW);
        movegui(SS_WW2,'center');
        uiwait(SS_WW2);
    end

    % Check whether subjects remaining after condition/basis check still have different numbers of runs
    if length(file_correct) > 1

        nSess_correct = zeros(length(file_correct),1);

        for iSub = 1:length(file_correct)
            SPM = load(file_correct{iSub}).SPM;
            nSess_correct(iSub) = length(SPM.Sess);
        end

        if length(unique(nSess_correct)) > 1

%             answer = questdlg(sprintf([ ...
%                 'Different numbers of runs (SPM sessions) were detected.\n\n' ...
%                 'TMFC can analyze these subjects together only if the runs are repeated ' ...
%                 'acquisitions of the same experimental design/context and can be treated as exchangeable.\n\n' ...
%                 'Between-run contrasts are not supported in this case.\n\n' ...
%                 'Continue?']), ...
%                 'Different numbers of runs', ...
%                 'Continue','Cancel','Continue');

                answer = 'Cancel';
    
                SS_WW5 = figure('Name', 'Different numbers of runs', 'NumberTitle', 'off', ...
                    'Units', 'normalized', 'Position', [0.32 0.30 0.36 0.27], ...
                    'Color', 'w', 'MenuBar', 'none', 'ToolBar', 'none', ...
                    'WindowStyle', 'Modal', 'CloseRequestFcn', @cancel_runs);
                
                SS_WW_S1 = uicontrol(SS_WW5, 'Style', 'text', ...
                    'String', { ...
                    'Different numbers of runs (SPM sessions) were detected.' ...
                    '' ...
                    'TMFC can analyze these subjects together only if the runs are repeated acquisitions of the same experimental design/context and can be treated as exchangeable.' ...
                    '' ...
                    'Between-run contrasts are not supported in this case.' ...
                    '' ...
                    'Continue?'}, ...
                    'Units', 'normalized', 'Position', [0.07 0.25 0.86 0.66], ...
                    'BackgroundColor', 'w', 'HorizontalAlignment', 'center', ...
                    'FontUnits', 'points', 'FontSize', 12);
                
                SS_WW_continue = uicontrol(SS_WW5, 'Style', 'pushbutton', ...
                    'String', 'Continue', 'Units', 'normalized', ...
                    'Position', [0.25 0.07 0.20 0.11], ...
                    'FontUnits', 'points', 'FontSize', 11, ...
                    'Callback', @continue_runs);
                
                SS_WW_cancel = uicontrol(SS_WW5, 'Style', 'pushbutton', ...
                    'String', 'Cancel', 'Units', 'normalized', ...
                    'Position', [0.55 0.07 0.20 0.11], ...
                    'FontUnits', 'points', 'FontSize', 11, ...
                    'Callback', @cancel_runs);
                
                movegui(SS_WW5,'center');
                uicontrol(SS_WW_continue);
                uiwait(SS_WW5);

            if strcmp(answer,'Continue')
                session_mode = 'repeated';
            else
                file_correct = {};
                subject_file_correct = {};
            end

        end
    end

    function continue_runs(~,~)
        answer = 'Continue';
        uiresume(SS_WW5);
        delete(SS_WW5);
    end

    function cancel_runs(~,~)
        answer = 'Cancel';
        uiresume(SS_WW5);
        delete(SS_WW5);
    end
    
    function close_SS_WW(~,~)
        close(SS_WW2);
    end
end


%% Check output directories (SPM.swd) specified in SPM.mat files
function [file_dir,subject_file_dir] = check_file_dir(file_correct,subject_file_correct)

	file_dir = {};
    file_no_dir = {};
    subject_file_dir = {};

    w = waitbar(0,'Check directories','Name','Check SPM.mat files');

    for iSub = 1:length(file_correct)
        
        SPM = load(file_correct{iSub}).SPM;

        if ~isfield(SPM, 'swd')
            close(w);
            error('SPM.swd field does not exist. Check SPM.mat files. Try to estimate GLM.');
        end

        if exist(SPM.swd, 'dir')
            file_dir{iSub,1} = file_correct{iSub};
            subject_file_dir{iSub,1} = subject_file_correct{iSub};
        else
            file_no_dir{iSub,1} = file_correct{iSub};
        end

        
        clear SPM
        
        try
            waitbar(iSub/length(file_correct),w);
        end
    end
  
    try
        close(w)
    end

    try
        file_dir = file_dir(~cellfun('isempty', file_dir));
        subject_file_dir = subject_file_dir(~cellfun('isempty', subject_file_dir));
    end
    
    try 
        file_no_dir = file_no_dir(~cellfun('isempty',file_no_dir)); 
    end
    
    % Show incorrect SPM.mat files
    if length(file_dir) ~= length(file_correct)
        if isunix; fontscale = 0.9; else; fontscale = 1; end
        SS_WW3 = figure('Name', 'Select subjects', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');
        SS_WW_LB = uicontrol(SS_WW3, 'Style', 'listbox', 'String', file_no_dir,'Max',inf,'Units', 'normalized', 'Position',[0.032 0.250 0.940 0.520],'FontUnits','points','FontSize',10);
        SS_WW_S1 = uicontrol(SS_WW3,'Style','text','String', 'Warning, the output folder (SPM.swd) specified in the following SPM.mat files do not exist:','Units', 'normalized', 'Position',[0.08 0.820 0.840 0.080], 'FontUnits','normalized','FontSize',0.56*fontscale,'backgroundcolor', 'w');
        SS_WW_close = uicontrol(SS_WW3,'Style','pushbutton', 'String', 'OK','Units', 'normalized',  'Position',[0.415 0.06 0.180 0.120] ,'FontUnits','normalized','FontSize',0.30,'callback', @close_SS_WW);
        movegui(SS_WW3,'center');
    	uiwait(SS_WW3);
    end
    
    function close_SS_WW(~,~)
    	close(SS_WW3);
    end   
end
            
%% Check functional files specified in SPM.mat files 
function [file_func,subject_file_func] = check_file_func(file_dir,subject_file_dir) 

    file_func = {};
    file_no_func = {};
    subject_file_func = {};

    w = waitbar(0,'Check functional files','Name','Check SPM.mat files');

    for iSub = 1:length(file_dir) 
        
        SPM = load(file_dir{iSub}).SPM;
        
        for jImage = 1:length(SPM.xY.VY)
            funct_check(jImage) = exist(SPM.xY.VY(jImage).fname, 'file');
        end
        
        if nnz(funct_check) == length(SPM.xY.VY)
            file_func{iSub,1} = file_dir{iSub};
            subject_file_func{iSub,1} = subject_file_dir{iSub};
        else
            file_no_func{iSub,1} = file_dir{iSub};
        end
        clear SPM funct_check      
        
        try
            waitbar(iSub/length(file_dir),w);
        end
        
    end

    try
        close(w)
    end
    
    try
        file_func = file_func(~cellfun('isempty', file_func));
        subject_file_func = subject_file_func(~cellfun('isempty', subject_file_func));
    end
    
    try 
        file_no_func = file_no_func(~cellfun('isempty',file_no_func)); 
    end
    
    if length(file_func) ~= length(file_dir)
        if isunix; fontscale = 0.85; else; fontscale = 1; end
        SS_WW4 = figure('Name', 'Select subjects', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.32 0.26 0.35 0.28], 'color', 'w','MenuBar', 'none','ToolBar', 'none');
        SS_WW_LB = uicontrol(SS_WW4, 'Style', 'listbox', 'String', file_no_func,'Max',inf,'Units', 'normalized', 'Position',[0.032 0.250 0.940 0.520],'FontUnits','points','FontSize',10);
        SS_WW_S1 = uicontrol(SS_WW4,'Style','text','String', 'Warning, the functional files specified in the following SPM.mat files do not exist:','Units', 'normalized', 'Position',[0.15 0.820 0.750 0.095], 'FontUnits','normalized','FontSize',0.5*fontscale,'backgroundcolor', 'w');
        SS_WW_close = uicontrol(SS_WW4,'Style','pushbutton', 'String', 'OK','Units', 'normalized',  'Position',[0.415 0.06 0.180 0.120] ,'FontUnits','normalized','FontSize',0.30,'callback', @close_SS_WW);
        movegui(SS_WW4,'center');
        uiwait(SS_WW4);
    end
    
    function close_SS_WW(~,~)
        close(SS_WW4);
    end
end

