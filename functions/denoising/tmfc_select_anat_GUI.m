function [anat_paths] =  tmfc_select_anat_GUI(subject_paths)

% =======[ Task-Modulated Functional Connectivity Denoise Toolbox ]========
% 
% Opens a GUI to select structural T1-weighted images in native space 
% (not normalized). 
%
% First, select the parent folder that contains the subject folders
% with ANAT subfolders. This may differ from the parent folder
% that contains the subject folders with STAT subfolders, which is 
% selected by default.
% 
% Then select the ANAT subfolder for the first subject and apply text
% filter (e.g., *T1*.nii) to match all T1 images.
%
% Alternatively, you can select all T1 images manually.
%
% A flat ANAT folder is also supported when each filename contains a unique
% subject identifier (e.g., sub-01_T1w.nii, sub-02_T1w.nii). Select that
% flat folder as Parent folder and leave ANAT subfolder as Not selected.
%
% ----------------EXAMPLE #1 (SPM-like folder structure)-------------------
% There is no need to change the parent folder to select structural files.
%
% project/
% ├─ rawdata/   # DICOM
% └─ derivatives/ <------ [Parent folder with ANAT subfolders (BY DEFAULT)]
%    ├─ sub-01/   <------ [Selected subject folder]                                          
%    │  ├─ anat/  <------ [Select the ANAT subfolder for the first subject] (1)            
%    │  │  ├─ *T1*.nii  <------------------------------ [Apply text filter] (2)
%    │  │  └─ *T1*.nii derivatives (tissue seg., bias-corrected T1, etc.)
%    │  ├─ func/
%    │  │  ├─ sess-01/
%    │  │  │  ├─ Unprocessed functional files (*.nii)
%    │  │  │  └─ Preprocessed functional files:
%    │  │  │     ● smoothed + normalized + realigned (swar*.nii or swr*.nii)
%    │  │  │     ● unsmoothed + normalized + realigned (war*.nii or wr*.nii) 
%    │  │  └─ sess-02/ ... 
%    │  └─ stat/                # first-level models (one folder per GLM)
%    │     ├─ GLM-01/
%    │     │  ├─ SPM.mat  <---------------------- [Selected SPM.mat file]
%    │     │  └─ TMFC_denoise/ <------------------------- [Output folder]
%    │     └─ GLM-02/ ...
%    └─ sub-02/ ...
%
%
%
% --------------EXAMPLE #2 (BIDS-like folder structure)--------------------
% "project/derivatives/firstlevel-spm" parent folder with STAT subfolders
% needs to be changed to "project" — parent folder with ANAT subfolders
%
% project/  <----------------- [Select parent folder (contains sub-*/anat)] (1)
% ├── sub-01/
% │   ├── ses-01/                
% │   │   ├── anat/  <--- [Select the ANAT subfolder for the first subject] (2)
% │   │   │   └── Structural file: *T1*.nii   <-------- [Apply text filter] (3)
% │   │   └── func/
% │   │       └── Functional files (unprocessed)
% │   └── ses-02/ ...
% ├── sub-02/ ... 
% └── derivatives
%     ├── fmriprep/
%     │   ├── sub-01/
%     │   │   ├── ses-01/
%     │   │   │   └── func/
%     │   │   │       └── Preprocessed functional files:
%     │   │   │           ● smoothed + normalized + realigned
%     │   │   │           ● unsmoothed + normalized + realigned
%     │   │   └── ses-02/ ...
%     │   └── sub-02/ ...
%     └── firstlevel-spm/ <---------- [Parent folder with ANAT subfolders (BY DEFAULT)] (Needs to be changed!)
%         ├── sub-01/     <---------- [Selected subject folder]                       
%         │   ├── GLM-01/
%         │   │   ├── SPM.mat        <----------- [Selected SPM.mat file]
%         │   │   └── TMFC_denoise/  <------------------- [Output folder]
%         │   └── GLM-02/ ...
%         └── sub-02/ ...
%
%
%
% --------------EXAMPLE #3 (Other non-BIDS folder structure)---------------
% "project/firstlevel-spm" parent folder with STAT subfolders needs to be
% changed to "project/nifti" — parent folder with ANAT subfolders
%
% project/
% ├─ rawdata/   # DICOM
% ├─ nifti/ <----------------- [Select parent folder (contains sub-*/anat)] (1)
% │  ├─ sub-01/                                         
% │  │  ├─ anat/  <------ [Select the ANAT subfolder for the first subject] (2)            
% │  │  │  ├─ *T1*.nii  <------------------------------ [Apply text filter] (3)
% │  │  │  └─ *T1*.nii derivatives (tissue seg., bias-corrected T1, etc.)
% │  │  └─ func/
% │  │     ├─ sess-01/
% │  │     │  ├─ Unprocessed functional files (*.nii)
% │  │     │  └─ Preprocessed functional files (*.nii):
% │  │     │     ● smoothed + normalized + realigned 
% │  │     │     ● unsmoothed + normalized + realigned 
% │  │     └─ sess-02/ ... 
% │  └─ sub-02/ ...   
% └─ firstlevel-spm/ <---- [Parent folder with ANAT subfolders (BY DEFAULT)] (Needs to be changed!)
%    ├─ sub-01/   <-------------------------- [Selected subject folder]  
%    │  ├─ GLM-01/
%    │  │  ├─ SPM.mat  <----------------------- [Selected SPM.mat file]
%    │  │  └─ TMFC_denoise/ <-------------------------- [Output folder]
%    │  └─ GLM-02/ ...
%    └─ sub-02/ ...
%
%
% =========================================================================
% Copyright (C) 2025 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

anat_paths = {};
txt_filter = '';
anat_root = '';              
anat_subfolder_full = '';    
anat_subfolder_rel  = '';
manual_first_subj_name = '';
no_file = {};
user_changed_root = false;
selection_mode = 'none';

if ischar(subject_paths), subject_paths = cellstr(subject_paths); end
subject_paths = subject_paths(:);  

% -------------------------------------------------------------------------
% GUI elements 
% -------------------------------------------------------------------------
ST_MW = figure('Name','Select structural images','NumberTitle','off','Units','normalized',...
    'Position',[0.30 0.22 0.45 0.60],'MenuBar','none','ToolBar','none','color','w',...
    'CloseRequestFcn',@ST_MW_exit);

ST_S1_str = {'Structural images must be in native space (not normalized).'};
ST_txt_1 = uicontrol(ST_MW,'Style','text','String',ST_S1_str,'Units','normalized',...
    'Position',[0.03 0.92 0.95 0.05],'fontunits','normalized','FontSize',0.48,...
    'HorizontalAlignment','left','backgroundcolor','w');

% Parent folder with ANAT subfolders (by default)
def_root = fileparts(subject_paths{1});
if isempty(def_root), def_root = filesep; end
anat_root = def_root; % default root = parent of Subject 1

% Button: Select parent folder (contains sub-*/anat)
ST_MW_S0 = uicontrol(ST_MW,'Style','pushbutton','String','Select parent folder (contains sub-*/.../anat)', ...
    'TooltipString','Folder that directly contains subject folders (e.g., sub-01, sub-02) with ANAT subfolders (which include *T1*.nii images).',...
    'Units','normalized','Position',[0.025 0.82 0.41 0.080],'FontUnits','normalized','FontSize',0.295, ...
    'callback',@select_anat_root);

% Box panel: Parent folder with ANAT subfolders
ST_MW_S0_panel = uipanel(ST_MW,'Units','normalized','Position',[0.45 0.823 0.525 0.076], ...
    'HighlightColor',[0.78 0.78 0.78],'BorderType','line','backgroundcolor','w');

% Box text: Parent folder with ANAT subfolders
ST_MW_S0_txt = uicontrol('Parent',ST_MW_S0_panel,'Style','text','String',anat_root, ...
    'Units','normalized','Position',[0.03 0.05 0.94 0.64], ...
    'FontUnits','points','FontSize',9, ...
    'HorizontalAlignment','center','backgroundcolor','w', ...
    'ForegroundColor',[0 0 0],'TooltipString',anat_root);

% Button: Select ANAT subfolder
ST_MW_S1 = uicontrol(ST_MW,'Style','pushbutton','String','Select the ANAT subfolder for the first subject',...
    'Units','normalized','Position',[0.025 0.73 0.41 0.080],'FontUnits','normalized','FontSize',0.295,...
    'callback',@select_subfolder);

% Box panel: ANAT subfolder
ST_MW_S1_panel = uipanel(ST_MW,'Units','normalized','Position',[0.45 0.733 0.525 0.076],...
    'HighlightColor',[0.78 0.78 0.78],'BorderType','line','backgroundcolor','w');

% Box text: ANAT subfolder
ST_MW_S1_txt = uicontrol('Parent',ST_MW_S1_panel,'Style','text','String','Not selected','ForegroundColor','red',...
    'Units','normalized','Position',[0.03 0.09 0.94 0.64],'FontUnits','normalized','FontSize',0.50,...
    'HorizontalAlignment','center','backgroundcolor','w');

% Button: Text filter
ST_MW_S2 = uicontrol(ST_MW,'Style','pushbutton','String','Apply text filter unique for structural images:',...
    'Units','normalized','Position',[0.025 0.64 0.41 0.080],'FontUnits','normalized','FontSize',0.295,...
    'callback',@apply_filter);

% Edit: Text filter
ST_MW_S2_E = uicontrol(ST_MW,'Style','Edit','String','*T1*.nii*','Units','normalized',...
    'Position',[0.45 0.64 0.525 0.080],'FontUnits','normalized','FontSize',0.32,'backgroundcolor','w');

% List of ANAT files
ST_MW_LB1 = uicontrol(ST_MW,'Style','listbox','String','','Max',100000,'Units','normalized',...
    'Position',[0.025 0.25 0.95 0.37],'FontUnits','points','FontSize',10,'Value',[]);

% Button: Select all structural images manually
ST_MW_S3 = uicontrol(ST_MW,'Style','pushbutton','String','Select all structural images manually',...
    'Units','normalized','Position',[0.0245 0.15 0.475 0.080],'FontUnits','normalized','FontSize',0.30,'callback',@add_images);

% Button: Clear all
ST_MW_S4 = uicontrol(ST_MW,'Style','pushbutton','String','Clear all','Units','normalized',...
    'Position',[0.51 0.15 0.466 0.080],'FontUnits','normalized','FontSize',0.30,'callback',@clear_paths);

% Button: OK
ST_MW_OK   = uicontrol(ST_MW,'Style','pushbutton','String','OK','Units','normalized',...
    'Position',[0.300 0.045 0.199 0.078],'FontUnits','normalized','FontSize',0.30,'callback',@export_paths);

% Button: Help
ST_MW_HELP = uicontrol(ST_MW,'Style','pushbutton','String','Help','Units','normalized',...
    'Position',[0.510 0.045 0.200 0.078],'FontUnits','normalized','FontSize',0.30,'callback',@open_help);

movegui(ST_MW,'center');

% -------------------------------------------------------------------------
% Close GUI 
% -------------------------------------------------------------------------
function ST_MW_exit(~,~)
    anat_paths = {};
    fprintf(2,'Structural images are not selected.\n');
    uiresume(ST_MW);
end

% -------------------------------------------------------------------------
% Reset ANAT choice, preview, and cached results
% -------------------------------------------------------------------------
function reset_anat_choice()
    anat_subfolder_full = '';
    anat_subfolder_rel = '';
    manual_first_subj_name = '';
    anat_paths = {};
    no_file = {};
    selection_mode = 'none';
    set(ST_MW_S1_txt,'String','Not selected','ForegroundColor','red', ...
        'HorizontalAlignment','center','TooltipString','');
    set(ST_MW_LB1,'String',{},'Value',[]);
end

% -------------------------------------------------------------------------
% Select parent folder (contains sub-*/anat)
% -------------------------------------------------------------------------
function select_anat_root(~,~)
    tmp = deblank(spm_select(1,'dir','Select parent folder (contains sub-*/.../anat)',{},anat_root,'..'));
    if isempty(tmp), return; end

    anat_root = regexprep(tmp,'[\\/]+$','');
    user_changed_root = ~strcmpi(anat_root,regexprep(def_root,'[\\/]+$',''));
    set(ST_MW_S0_txt,'String',anat_root,'TooltipString',anat_root, ...
        'ForegroundColor',[0 0 0],'HorizontalAlignment','center');
    reset_anat_choice();
end

% -------------------------------------------------------------------------
% Select the ANAT subfolder for the first subject
% -------------------------------------------------------------------------
function select_subfolder(~,~)
    % Reopening ANAT resets the old choice, including when Cancel is pressed
    reset_anat_choice();

    start_dir = resolve_anat_subject_base(1);
    if isempty(start_dir), start_dir = anat_root; end
    if ~isfolder(start_dir), start_dir = anat_root; end

    sel_dir = deblank(spm_select(1,'dir','Select ANAT subfolder',{},start_dir,'..'));
    if isempty(sel_dir)
        fprintf('TMFC: ANAT folder not selected.\n');
        return;
    end

    anat_subfolder_full = regexprep(sel_dir,'[\\/]+$','');
    update_rel_display();
end

% -------------------------------------------------------------------------
% Interpret explicitly selected folder relative to ANAT parent
% -------------------------------------------------------------------------
function update_rel_display()
    manual_first_subj_name = '';
    anat_subfolder_rel = '';

    root_clean = strrep(regexprep(anat_root,'[\\/]+$',''), '/', filesep);
    selected_clean = strrep(regexprep(anat_subfolder_full,'[\\/]+$',''), '/', filesep);
    prefix = [root_clean filesep];

    if ~isfolder(selected_clean) || ~strncmpi(selected_clean,prefix,numel(prefix))
        fprintf(2,'TMFC: Select an ANAT folder inside %s.\n',anat_root);
        reset_anat_choice();
        return;
    end

    % First folder below the parent is the user's explicit subject choice.
    parts = regexp(selected_clean(numel(prefix)+1:end),'[\\/]+','split');
    manual_first_subj_name = parts{1};
    anat_subfolder_rel = strjoin(parts(2:end),filesep);

    if isempty(anat_subfolder_rel)
        display_text = manual_first_subj_name;
    else
        display_text = anat_subfolder_rel;
    end
    set(ST_MW_S1_txt,'String',display_text,'ForegroundColor',[0 0 0], ...
        'HorizontalAlignment','center','TooltipString',anat_subfolder_full);
end

% -------------------------------------------------------------------------
% Apply text filter and generate paths
% -------------------------------------------------------------------------
function apply_filter(~,~)
    anat_paths = {};
    no_file = {};
    selection_mode = 'none';
    set(ST_MW_LB1,'String',{},'Value',[]);

    txt_filter = strrep(get(ST_MW_S2_E,'String'),' ','');
    if isempty(txt_filter)
        fprintf(2,'TMFC: ANAT filter is empty.\n');
        return;
    end

    f = msgbox('Selecting structural images. Please wait . . .');
    nSub = numel(subject_paths);
    subject_bases = cell(nSub,1);

    for iSub = 1:nSub
        if iSub == 1 && ~isempty(manual_first_subj_name)
            % An explicit choice resolves ambiguity for the first subject
            subject_bases{iSub} = fullfile(anat_root,manual_first_subj_name);
        else
            subject_bases{iSub} = resolve_anat_subject_base(iSub);
        end
    end

    % Flat ANAT directory: unique subject-specific names are mandatory.
    % Only entered when the user chose a different parent and none of the
    % subjects resolves to a subfolder under it.
    flat_mode = false;
    if user_changed_root && isempty(manual_first_subj_name) && all(cellfun(@isempty,subject_bases))
        hits = dir(fullfile(anat_root,txt_filter));
        hits = hits(~[hits.isdir]);
        flat_mode = ~isempty(hits);
    end

    if ~flat_mode
        for iSub = 1:nSub
            if isempty(subject_bases{iSub})
                fprintf(2,'TMFC: Cannot match ANAT subject %d (%s) under %s.\n',iSub,subject_paths{iSub},anat_root);
                try, close(f); catch, end
                return;
            end
        end

        keys = cellfun(@lower,subject_bases,'UniformOutput',false);
        if numel(unique(keys)) ~= nSub
            fprintf(2,'TMFC: Multiple subjects map to the same ANAT folder. Selection canceled.\n');
            try, close(f); catch, end
            return;
        end
    end

    selected = cell(nSub,1);
    preview = cell(nSub,1);

    if flat_mode
        hits = dir(fullfile(anat_root,txt_filter));
        hits = hits(~[hits.isdir]);
        fprintf('TMFC: Flat ANAT folder with %d candidate files.\n',numel(hits));
    end

    for iSub = 1:nSub
        if flat_mode
            match = find(arrayfun(@(x) flat_filename_matches_subject(x.name,iSub),hits));
            if numel(match)==1
                selected{iSub} = fullfile(anat_root,hits(match).name);
            elseif isempty(match)
                fprintf(2,'TMFC: No unambiguous ANAT filename for subject %d in flat folder.\n',iSub);
            else
                fprintf(2,'TMFC: %d ANAT files match subject %d in flat folder. Use a narrower filter.\n',numel(match),iSub);
            end
        else
            if isempty(anat_subfolder_rel)
                search_dir = subject_bases{iSub};
            else
                search_dir = fullfile(subject_bases{iSub},anat_subfolder_rel);
            end
            fprintf('Searching in: %s | pattern: %s\n',search_dir,txt_filter);
            if isfolder(search_dir)
                hits_one = dir(fullfile(search_dir,txt_filter));
                hits_one = hits_one(~[hits_one.isdir]);
                if numel(hits_one)==1
                    selected{iSub} = fullfile(search_dir,hits_one(1).name);
                elseif numel(hits_one)>1
                    fprintf(2,'TMFC: %d ANAT files match subject %d. Use a narrower filter.\n',numel(hits_one),iSub);
                else
                    fprintf(2,'TMFC: No ANAT image found for subject %d.\n',iSub);
                end
            else
                fprintf(2,'TMFC: ANAT directory does not exist: %s\n',search_dir);
            end
        end

        if isempty(selected{iSub})
            no_file{end+1,1} = subject_paths{iSub};
            preview{iSub} = sprintf('[no matches] Subject %d: %s',iSub,subject_paths{iSub});
        else
            preview{iSub} = selected{iSub};
        end
    end

    % Reject the same T1 file assigned to multiple subjects
    nonempty = selected(~cellfun(@isempty,selected));
    low_paths = cellfun(@lower,nonempty,'UniformOutput',false);
    if numel(unique(low_paths)) ~= numel(nonempty)
        fprintf(2,'TMFC: The same ANAT file was assigned to multiple subjects. Selection canceled.\n');
        anat_paths = {};
        no_file = subject_paths;
    elseif isempty(no_file)
        anat_paths = selected;
        selection_mode = 'filter';
    else
        % Show partial matches in the list, but never allow partial export
        anat_paths = {};
    end
    set(ST_MW_LB1,'String',preview,'Value',[]);
    try, close(f); catch, end
end

% -------------------------------------------------------------------------
% Clear anat paths
% -------------------------------------------------------------------------
function clear_paths(~,~)
    if isempty(anat_paths)
        disp('No images to remove.');
    else
        disp('All images have been removed.');
    end
    anat_paths = {};
    no_file = {};
    selection_mode = 'none';
    set(ST_MW_LB1,'String',{},'Value',[]);
end

% -------------------------------------------------------------------------
% Add all structural images manually
% -------------------------------------------------------------------------
function add_images(~,~)
    no_file = {};
    anat_paths = {};
    selection_mode = 'none';
    set(ST_MW_LB1,'String',{},'Value',[]);
    sel = spm_select(inf,'any','Select structural images for all subjects',{},subject_paths{1},'T1.*\.nii$');
    if ~isempty(sel)
        anat_paths = cellstr(sel);
        selection_mode = 'manual';
    else
        fprintf(2,'Structural images were not selected. Please try again.\n');
    end
    set(ST_MW_LB1,'String',anat_paths,'Value',[]);
end

% -------------------------------------------------------------------------
% Export anat paths
% -------------------------------------------------------------------------
function export_paths(~,~)
    nSub = numel(subject_paths);
    if isempty(anat_paths) || strcmp(selection_mode,'none')
        fprintf(2,'No valid structural images selected. Please try again.\n');
        if ~isempty(no_file), missing_file_GUI(no_file); end
        return;
    end

    if numel(anat_paths) ~= nSub || any(cellfun(@isempty,anat_paths))
        fprintf(2,'TMFC: ANAT selection must contain exactly one image per subject (%d).\n',nSub);
        return;
    end
    paths = anat_paths(:);
    keys = cellfun(@lower,paths,'UniformOutput',false);
    if numel(unique(keys)) ~= nSub
        fprintf(2,'TMFC: The same ANAT file was assigned to multiple subjects.\n');
        return;
    end
    if ~all(cellfun(@isfile,paths))
        fprintf(2,'TMFC: One or more selected ANAT files no longer exist.\n');
        return;
    end

    if strcmp(selection_mode,'manual')
        fprintf('TMFC: Manual ANAT selection uses the order of the selected subjects.\n');
    end
    disp('Structural images have been selected.');
    uiresume(ST_MW);
end

% -------------------------------------------------------------------------
% Warning window: missing images
% -------------------------------------------------------------------------
function missing_file_GUI(file_missing)
    ST_WW = figure('Name','Missing structural images','NumberTitle','off','Units','normalized','Position',[0.32 0.30 0.35 0.28],'color','w','MenuBar','none','ToolBar','none','WindowStyle','Modal');
    ST_WW_LB = uicontrol(ST_WW,'Style','listbox','String',file_missing,'Max',inf,'Units','normalized','Position',[0.032 0.250 0.940 0.520],'FontUnits','points','FontSize',10,'Value',[]);
    ST_WW_S1 = uicontrol(ST_WW,'Style','text','String','Warning: structural images are missing for the following subjects:',...
        'Units','normalized','Position',[0.15 0.820 0.720 0.095],...
        'FontUnits','points','FontSize',11,'HorizontalAlignment','center','backgroundcolor','w');
    ST_WW_close = uicontrol(ST_WW,'Style','pushbutton','String','OK','Units','normalized','Position',[0.415 0.06 0.180 0.120],'FontUnits','normalized','FontSize',0.30,'callback',@close_SS_WW);
    movegui(ST_WW,'center');
    uiwait(ST_WW); 
    function close_SS_WW(~,~)
        close(ST_WW);
    end
end

% -------------------------------------------------------------------------
% Help window
% -------------------------------------------------------------------------
function open_help(~,~)
    page1 = {
        ''
        '   First, select the parent folder that contains all subject folders' 
        '   with ANAT subfolders (if necessary).'
        ''
        '   Then select the ANAT subfolder for the first subject and apply text'
        '   filter (e.g., *T1*.nii) to match all T1 images.'
        ''
        '   You may also try the filter without choosing an ANAT subfolder.'
        '   For a shared flat folder, select it as Parent folder and leave'
        '   ANAT subfolder as Not selected. Filenames must identify subjects.'
        ''
        ''
        '   ================= EXAMPLE #1 (SPM-like folder structure) =================='
        ''
        '   There is no need to change the parent folder to select structural files.'
        ''
        '   project/'
        '   ├─ rawdata/      # DICOM'
        '   └─ derivatives/  <-------- [Parent folder with ANAT subfolders (BY DEFAULT)]'
        '      ├─ sub-01/    <-------- [Selected subject folder]'
        '      │  ├─ anat/   <-------- [Select the ANAT subfolder for the first subject] (1)'
        '      │  │  ├─ *T1*.nii  <--------------------------------- [Apply text filter] (2)'
        '      │  │  └─ *T1*.nii derivatives (tissue seg., bias-corrected T1, etc.)'
        '      │  ├─ func/'
        '      │  │  ├─ sess-01/'
        '      │  │  │  ├─ Unprocessed functional files (*.nii)'
        '      │  │  │  └─ Preprocessed functional files:'
        '      │  │  │       ◦ smoothed + normalized + realigned (swar*.nii or swr*.nii)'
        '      │  │  │       ◦ unsmoothed + normalized + realigned (war*.nii or wr*.nii)'
        '      │  │  └─ sess-02/ ...'
        '      │  └─ stat/    # first-level models (one folder per GLM)'
        '      │     ├─ GLM-01/'
        '      │     │  ├─ SPM.mat      <----------------------- [Selected SPM.mat file]'
        '      │     │  └─ TMFC_denoise/ <------------------------------ [Output folder]'
        '      │     └─ GLM-02/ ...'
        '      └─ sub-02/ ...'
    };

    page2 = {
        ''
        '   ================ EXAMPLE #2 (BIDS-like folder structure) ================='
        ''
        '   "project/derivatives/firstlevel-spm" parent folder with STAT subfolders needs'
        '   to be changed to "project" — parent folder with ANAT subfolders.'
        ''
        '   project/   <----------------- [Select parent folder (contains sub-*/anat)]  (1)'
        '   ├── sub-01/'
        '   │   ├── ses-01/'
        '   │   │   ├── anat/  <---- [Select the ANAT subfolder for the first subject]  (2)'
        '   │   │   │   └── *T1*.nii   <-------------------------- [Apply text filter]  (3)'
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
        '       └── firstlevel-spm/  <-- [Parent folder with ANAT (BY DEFAULT)](Needs to be changed!)'
        '           ├── sub-01/     <--------------------------- [Selected subject folder]'
        '           │   ├── GLM-01/'
        '           │   │   ├── SPM.mat        <------------------ [Selected SPM.mat file]'
        '           │   │   └── TMFC_denoise/  <-------------------------- [Output folder]'
        '           │   └── GLM-02/ ...'
        '           └── sub-02/ ...'
    };

    page3 = {
        ''
        '   ================ EXAMPLE #3 (Other non-BIDS folder structure) ================'
        ''
        '   "project/firstlevel-spm" parent folder with STAT subfolders needs'
        '   to be changed to "project/nifti"  — parent folder with ANAT subfolders.'
        ''
        '   project/'
        '   ├─ rawdata/ # DICOM'
        '   ├─ nifti/   <------------------- [Select parent folder (contains sub-*/anat)]  (1)'
        '   │  ├─ sub-01/'
        '   │  │  ├─ anat/  <---------- [Select the ANAT subfolder for the first subject]  (2)'
        '   │  │  │  ├─ *T1*.nii  <---------------------------------- [Apply text filter]  (3)'
        '   │  │  │  └─ *T1*.nii derivatives (tissue seg., bias-corrected T1, etc.)'
        '   │  │  └─ func/'
        '   │  │     ├─ sess-01/'
        '   │  │     │  ├─ Unprocessed functional files (*.nii)'
        '   │  │     │  └─ Preprocessed functional files (*.nii):'
        '   │  │     │     ◦ smoothed + normalized + realigned'
        '   │  │     │     ◦ unsmoothed + normalized + realigned'
        '   │  │     └─ sess-02/ ...'
        '   │  └─ sub-02/ ...'
        '   └─ firstlevel-spm/  <-- [Parent folder with ANAT subfolders (BY DEFAULT)](Needs to be changed!)'
        '      ├─ sub-01/   <------------------------------ [Selected subject folder]'
        '      │  ├─ GLM-01/'
        '      │  │  ├─ SPM.mat    <------------------------- [Selected SPM.mat file]'
        '      │  │  └─ TMFC_denoise/   <---------------------------- [Output folder]'
        '      │  └─ GLM-02/ ...'
        '      └─ sub-02/ ...'
    };

    pages = {page1, page2, page3};
    cur = 1; total = numel(pages);

    ST_HELP = figure('Name','Help','NumberTitle','off','Units','normalized', ...
        'Position',[0.22 0.10 0.60 0.75], 'MenuBar','none','ToolBar','none', ...
        'Color','w','WindowStyle','Modal');

    txtArea = uicontrol(ST_HELP,'Style','edit', ...
        'Units','normalized','Position',[0.05 0.14 0.90 0.78], ...
        'BackgroundColor','w','Enable','inactive', ...
        'Max', 2, 'Min', 0, ...                     
        'HorizontalAlignment','left', ...
        'FontName','Courier New','FontUnits','normalized','FontSize',0.025);

    btnPrev = uicontrol(ST_HELP,'Style','pushbutton','String','Previous', ...
        'Units','normalized','Position',[0.05 0.05 0.14 0.06], ...
        'FontUnits','normalized','FontSize',0.35, 'Callback',@go_prev);

    pageLbl = uicontrol(ST_HELP,'Style','text','String','', ...
        'Units','normalized','Position',[0.205 0.035 0.19 0.06], ...
        'BackgroundColor','w', 'HorizontalAlignment','center', ...
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

% -------------------------------------------------------------------------
% Resolve ANAT subject: exact individual path component, then bounded
% prefix/suffix matching with non-alphanumeric boundaries
% -------------------------------------------------------------------------
function subj_base = resolve_anat_subject_base(iSub)
    subj_base = '';
    if ~isfolder(anat_root), return; end

    d = dir(anat_root);
    d = d([d.isdir]);
    names = setdiff({d.name},{'.','..'});
    parts = regexp(regexprep(strtrim(subject_paths{iSub}),'[\\/]+$',''),'[\\/]+','split');

    % Exact match, excluding directory components shared by subjects
    for k = numel(parts):-1:1
        id = parts{k};
        if isempty(id) || component_shared(id,iSub), continue; end
        hit = find(strcmpi(id,names));
        if numel(hit)==1
            subj_base = fullfile(anat_root,names{hit});
            return;
        end
    end

    % Use the deepest unique source component, not a shared 'stat'/'GLM'
    src_name = deepest_unique_component(iSub);
    if isempty(src_name), return; end

    matches = false(1,numel(names));
    src_pattern = ['(?<![a-z0-9])' regexptranslate('escape',src_name) '(?![a-z0-9])'];
    for j = 1:numel(names)
        dst_name = names{j};
        dst_pattern = ['(?<![a-z0-9])' regexptranslate('escape',dst_name) '(?![a-z0-9])'];
        matches(j) = ~isempty(regexpi(dst_name,src_pattern,'once')) || ~isempty(regexpi(src_name,dst_pattern,'once'));
    end

    idx = find(matches);
    if numel(idx)==1
        subj_base = fullfile(anat_root,names{idx});
        fprintf('TMFC: Matched ANAT subject folder "%s" to "%s".\n',src_name,names{idx});
    elseif numel(idx)>1
        fprintf(2,'TMFC: Ambiguous ANAT subject folder match for "%s" under %s.\n',src_name,anat_root);
    end
end

function id = deepest_unique_component(iSub)
    id = '';
    parts = regexp(regexprep(strtrim(subject_paths{iSub}),'[\\/]+$',''),'[\\/]+','split');
    for k = numel(parts):-1:1
        if ~isempty(parts{k}) && ~component_shared(parts{k},iSub)
            id = parts{k};
            return;
        end
    end
end

function shared = component_shared(id,iSub)
    shared = false;
    for jSub = 1:numel(subject_paths)
        if jSub==iSub, continue; end
        parts = regexp(regexprep(strtrim(subject_paths{jSub}),'[\\/]+$',''),'[\\/]+','split');
        if any(strcmpi(id,parts))
            shared = true;
            return;
        end
    end
end

% -------------------------------------------------------------------------
% Flat ANAT: match subject-specific filenames.
% A single arbitrary trailing underscore-delimited descriptor is tolerated,
% e.g. 'sub-01_firstlevel' -> filename 'sub-01_T1w.nii'.
% -------------------------------------------------------------------------
function tf = flat_filename_matches_subject(filename,iSub)
    tf = false;
    src_name = deepest_unique_component(iSub);
    if isempty(src_name), return; end

    candidates = {src_name};
    idx = find(src_name=='_',1,'last');
    if ~isempty(idx) && idx>1
        candidates{end+1} = src_name(1:idx-1);
    end

    for k = 1:numel(candidates)
        id = candidates{k};
        if numel(id)<3, continue; end
        pattern = ['(?<![a-z0-9])' regexptranslate('escape',id) '(?![a-z0-9])'];

        % The filename token must identify this subject uniquely among the
        % source subject paths, not just happen to match its prefix.
        shared = false;
        for jSub = 1:numel(subject_paths)
            if jSub==iSub, continue; end
            other = deepest_unique_component(jSub);
            if ~isempty(regexpi(other,pattern,'once'))
                shared = true;
                break;
            end
        end
        if ~shared && ~isempty(regexpi(filename,pattern,'once'))
            tf = true;
            return;
        end
    end
end

% -------------------------------------------------------------------------
uiwait(ST_MW);
delete(ST_MW);
end
