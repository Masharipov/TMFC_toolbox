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
no_file = {};

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
    'Units','normalized','Position',[0.03 0.05 0.94 0.64],'FontUnits','normalized','FontSize',0.48, ...
    'HorizontalAlignment','center','backgroundcolor','w','ForegroundColor',[0 0 0]);

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
% Select parent folder (contains sub-*/anat)
% -------------------------------------------------------------------------
function select_anat_root(~,~)
    tmp = deblank(spm_select(1,'dir','Select parent folder (contains sub-*/.../anat)',{},anat_root,'..'));
    if ~isempty(tmp)
        anat_root = tmp;
        set(ST_MW_S0_txt,'String',anat_root,'ForegroundColor',[0 0 0],...
            'HorizontalAlignment','center');
        set(ST_MW_LB1,'String','');
        anat_paths = {};
        % If we already had a selected subfolder, refresh the displayed relative path
        anat_subfolder_full = '';
        anat_subfolder_rel  = '';
        set(ST_MW_S1_txt,'String','Not selected','ForegroundColor','red','HorizontalAlignment','center');
    end
end

% -------------------------------------------------------------------------
% Select the ANAT subfolder for the first subject
% -------------------------------------------------------------------------
function select_subfolder(~,~)
    set(ST_MW_S1_txt,'String','Not selected','ForegroundColor','red','HorizontalAlignment','center');

    % try <anat_root>/<sub-01>; fallback to anat_root; else to subject_paths{1}
    [~, subj_id1] = fileparts(subject_paths{1});
    start_dir = fullfile(anat_root, subj_id1);
    if ~exist(start_dir,'dir')
        start_dir = anat_root;
    end
    if ~exist(start_dir,'dir')
        start_dir = subject_paths{1};
    end

    sel_dir = deblank(spm_select(1,'dir','Select ANAT subfolder',{},start_dir,'..'));

    if ~isempty(sel_dir)
       anat_subfolder_full = sel_dir;
       update_rel_display();  % compute & show relative path
       set(ST_MW_LB1,'String','');
    else
       fprintf(2,'Please select ''structural'' subfolder for the first subject.\n'); 
    end
end

% -------------------------------------------------------------------------
% Compute relative path & show it
% -------------------------------------------------------------------------
function update_rel_display()
    if isempty(anat_subfolder_full) || ~isfolder(anat_subfolder_full)
        set(ST_MW_S1_txt,'String','Not selected','ForegroundColor','red', ...
            'HorizontalAlignment','center');
        anat_subfolder_rel = '';
        return;
    end

    [~, subj_id1] = fileparts(subject_paths{1});
    base_first = [fullfile(anat_root, subj_id1) filesep];
    tmp_rel = '';

    % Try strict relative path
    if strncmpi(anat_subfolder_full, base_first, numel(base_first))
        tmp_rel = anat_subfolder_full(numel(base_first)+1:end);
    else
        % Try fallback relative to subject_paths{1}
        base_first2 = [subject_paths{1} filesep];
        tmp_rel = strrep(anat_subfolder_full, base_first2, '');
    end

    % If both fail (different roots or mismatched names) - use folder name only
    if isempty(tmp_rel) || strcmp(tmp_rel, anat_subfolder_full)
        [~, tmp_rel] = fileparts(anat_subfolder_full);
    end

    % If tmp_rel starts with the first subject ID, strip it (avoid subject-specific prefixes)
    prefix = [subj_id1 filesep];
    if strncmpi(tmp_rel, prefix, numel(prefix))
        tmp_rel = tmp_rel(numel(prefix)+1:end);
    end

    % If user selected the subject folder itself (e.g. T1 files directly inside),
    % keep it as relative path = subject folder
    if strcmpi(anat_subfolder_full, fullfile(anat_root, subj_id1))
        tmp_rel = subj_id1;
    end

    anat_subfolder_rel = tmp_rel;

    % Update GUI text
    set(ST_MW_S1_txt, 'String', anat_subfolder_rel, ...
        'ForegroundColor', [0 0 0], 'HorizontalAlignment', 'center');
end

% -------------------------------------------------------------------------
% Apply text filter and generate paths 
% -------------------------------------------------------------------------
function apply_filter(~,~)
    f = msgbox('Selecting structural images. Please wait . . .');
    if ~isempty(anat_subfolder_rel)
        txt_filter = get(ST_MW_S2_E,'String');
        txt_filter = strrep(txt_filter,' ','');
        if ~isempty(txt_filter) 
            anat_paths = {};
            no_file = {};
            
            % Prepare subject paths
            subject_paths = strtrim(subject_paths); 

            % Build ANAT paths for all subjects (uses anat_root if available)
            for iSub = 1:size(subject_paths,1)
                [~, subj_id] = fileparts(subject_paths{iSub});
                subj_base = fullfile(anat_root, subj_id);

                % If exact match not found – search for closest folder in anat_root
                if ~exist(subj_base,'dir')

                    % Try direct wildcard match
                    d = dir(fullfile(anat_root, ['*' subj_id '*']));
                    d = d([d.isdir]);
                    d = d(~ismember({d.name},{'.','..'}));             
                
                    % Try substring-based search
                    if isempty(d)
                        d_all = dir(anat_root);
                        d_all = d_all([d_all.isdir]);
                        names = setdiff({d_all.name},{'.','..'});
                        bestName = '';
                        bestScore = -inf;
                        for k = 1:numel(names)
                            common = lcsstr(subj_id, strrep(names{k}, filesep, '_'));
                            sc = numel(common);
                            if sc > bestScore
                                bestScore = sc;
                                bestName = names{k};
                            end
                        end
                
                        if ~isempty(bestName)
                            subj_base = fullfile(anat_root, bestName);
                            if bestScore < 4
                                fprintf(2,'[Notice] No clear match for "%s" in "%s". Please check folder names.\n', ...
                                    subj_id, anat_root);
                            end
                        else
                            subj_base = subject_paths{iSub}; 
                        end
                    else
                        subj_base = fullfile(anat_root, d(1).name);
                    end
                end  
                
                % Build search path
                if (ispc && ~isempty(strfind(anat_subfolder_rel, ':\'))) || (~ispc && strncmp(anat_subfolder_rel, filesep, 1))
                    search_dir = anat_subfolder_rel;
                else
                    search_dir = fullfile(subj_base, anat_subfolder_rel);
                end

                % If folder not found, try subject folder itself
                if ~isfolder(search_dir)
                    search_dir = subj_base;
                end
                
                fprintf('Searching in: %s | pattern: %s\n', search_dir, txt_filter);
                anat_file = dir(fullfile(search_dir, txt_filter));
                
                if ~isempty(anat_file)
                    anat_paths = vertcat(anat_paths,fullfile(search_dir,anat_file(1).name));
                else
                    no_file = vertcat(no_file,subject_paths(iSub));
                end
            end
            set(ST_MW_LB1,'String',cellstr(anat_paths));

            % If the filter found nothing at all, warn in command line
            if isempty(anat_paths)
                fprintf(2,'No images matched the filter "%s" within "%s". Please check the root/subfolder and filter.\n',...
                    txt_filter, anat_subfolder_rel);
            end

            clear anat_file
        else
            fprintf(2,'Filter is empty or invalid. Please re-enter.\n');
        end
    else
        fprintf(2,'Please select ''structural'' subfolder for the first subject before applying text filter.\n');
    end
    try; close(f); end
end

% -------------------------------------------------------------------------
% Clear anat paths
% -------------------------------------------------------------------------
function clear_paths(~,~)
    if isempty(anat_paths)
        disp('No images to remove.');
    else
        anat_paths = {};
        set(ST_MW_LB1,'String',anat_paths,'Value',[]);
        disp('All images have been removed.');
    end
end

% -------------------------------------------------------------------------
% Add all structural images manually
% -------------------------------------------------------------------------
function add_images(~,~)
    no_file = {}
    anat_paths = {};
    sel = spm_select(inf,'any','Select structural images for all subjects',{},subject_paths{1},'T1.*\.nii$');
    if ~isempty(sel), anat_paths = cellstr(sel); end
    if isempty(anat_paths)
        fprintf(2,'Structural images were not selected. Please try again.\n');
    end
    set(ST_MW_LB1,'String',cellstr(anat_paths));
end

% -------------------------------------------------------------------------
% Export anat paths
% -------------------------------------------------------------------------
function export_paths(~,~)
    nSubs = numel(subject_paths);
    nFiles = numel(anat_paths);

    if isempty(anat_paths)
        fprintf(2,'No images selected, please try again.\n');
        return;
    end

    % CASE 1: Filter-based selection 
    if exist('no_file','var') && ~isempty(no_file)
        if nFiles == nSubs
            disp('Structural images have been selected.');
            uiresume(ST_MW);
        else
            % Some subjects missing (known from filtering)
            missing_file_GUI(no_file);
        end
        return;
    end

    % CASE 2: Manual selection
    % Assume user selected files in order of subject_paths
    if nFiles == nSubs
        disp('Structural images have been selected.');
        uiresume(ST_MW);
        return;
    elseif nFiles > nSubs
        fprintf(2,'The number of structural images must equal the number of selected SPM.mat files. Please try again.\n');
        return;
    else
        % Fewer files than subjects -> assume missing at the end
        missing_idx = (nFiles + 1):nSubs;
        missing_file_GUI(subject_paths(missing_idx));
    end
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
% Longest common substring, case-insensitive
% -------------------------------------------------------------------------
function s = lcsstr(a,b)
a = lower(a); b = lower(b);
na = numel(a); nb = numel(b);
L = zeros(na+1, nb+1, 'uint16');
bestLen = 0; bestEnd = 0;
for i = 1:na
    ai = a(i);
    for j = 1:nb
        if ai == b(j)
            L(i+1,j+1) = L(i,j) + 1;
            if L(i+1,j+1) > bestLen
                bestLen = L(i+1,j+1);
                bestEnd = i;
            end
        end
    end
end
if bestLen == 0
    s = '';
else
    s = a(bestEnd-bestLen+1:bestEnd);
end
end

% -------------------------------------------------------------------------
uiwait(ST_MW);
delete(ST_MW);
end
