function [func_paths] = tmfc_select_func_GUI(SPM_paths,subject_paths)

% =======[ Task-Modulated Functional Connectivity Denoise Toolbox ]========
%
% Opens a GUI to select unsmoothed, normalized, realigned functional images.
% 
% First, select the parent folder that contains the subject folders
% with FUNC subfolders. This may differ from the parent folder
% that contains the subject folders with STAT subfolders, which is 
% selected by default.
%
% Then select the FUNC subfolder for the first subject and apply text
% filter (e.g., *war*.nii, *wr*.nii, or *preproc*.nii.gz) to match all
% unsmoothed, normalized, realigned functional images.
%
% NOTE: You can also try applying the text filter without changing folders.
%
%  • If you do NOT select a new parent folder (FUNC root), the toolbox will
%    use the same parent directory as the STAT folder (SPM.mat).
%
%  • If you do NOT select a FUNC subfolder for the first subject, the toolbox
%    will attempt to use the same relative structure as in SPM.xY.VY paths.
%
% In both cases, the search will be performed automatically using paths
% derived from the original SPM.mat configuration, so it may still find the
% correct functional files — provided their locations have not changed.
%
% Alternatively, you can preserve functional image paths from the SPM.mat 
% files (if the GLMs were specified with unsmoothed functional images).
%
% ----------------EXAMPLE #1 (SPM-like folder structure)-------------------
% There is no need to change the parent folder to select functional files.
%
% project/
% ├─ rawdata/   # DICOM
% └─ derivatives/ <---------------------------- [Parent folder with FUNC subfolders (BY DEFAULT)]
%    ├─ sub-01/   <---------------------------------------------------- [Selected subject folder]                                          
%    │  ├─ anat/              
%    │  │  ├─ *T1*.nii  
%    │  │  └─ *T1*.nii derivatives
%    │  ├─ func/  <---------------------------- [Select the FUNC subfolder for the first subject] (1)
%    │  │  ├─ sess-01/
%    │  │  │  ├─ Unprocessed functional files (*.nii)
%    │  │  │  └─ Preprocessed functional files:
%    │  │  │     • smoothed + normalized + realigned (e.g., swar*.nii)
%    │  │  │     • unsmoothed + normalized + realigned (e.g., war*.nii) <---- [Apply text filter] (2)
%    │  │  └─ sess-02/ ... 
%    │  └─ stat/                # first-level models (one folder per GLM)
%    │     ├─ GLM-01/
%    │     │  ├─ SPM.mat  <---------------------------------------------- [Selected SPM.mat file]
%    │     │  └─ TMFC_denoise/ <------------------------------------------------- [Output folder]
%    │     └─ GLM-02/ ...
%    └─ sub-02/ ...
%
%
%
% --------------EXAMPLE #2 (BIDS-like folder structure)--------------------
% "project/derivatives/firstlevel-spm" parent folder with STAT subfolders
% needs to be changed to "project/derivatives/fmriprep" — parent folder
% with FUNC subfolders
%
% project/  
% ├── sub-01/
% │   ├── ses-01/                
% │   │   ├── anat/  
% │   │   │   └── Structural file: *T1*.nii  
% │   │   └── func/
% │   │       └── Functional files (unprocessed)
% │   └── ses-02/ ...
% ├── sub-02/ ... 
% └── derivatives
%     ├── fmriprep/ <------------------ [Select parent folder (contains sub-*/ses-*/func)] (1)
%     │   ├── sub-01/
%     │   │   ├── ses-01/     
%     │   │   │   └── func/   
%     │   │   │       └── Preprocessed functional files:
%     │   │   │           • smoothed + normalized + realigned
%     │   │   │           • unsmoothed + normalized + realigned <----- [Apply text filter] (2)
%     │   │   └── ses-02/ ...
%     │   └── sub-02/ ...
%     └── firstlevel-spm/ <------------- [Parent folder with FUNC subfolders (BY DEFAULT)] (Needs to be changed!)
%         ├── sub-01/     <------------------------------------- [Selected subject folder]                       
%         │   ├── GLM-01/
%         │   │   ├── SPM.mat        <---------------------------- [Selected SPM.mat file]
%         │   │   └── TMFC_denoise/  <------------------------------------ [Output folder]
%         │   └── GLM-02/ ...
%         └── sub-02/ ...
%
%
%
% --------------EXAMPLE #3 (Other non-BIDS folder structure)---------------
% "project/firstlevel-spm" parent folder with FUNC subfolders needs to be
% changed to "project/nifti" — parent folder with FUNC subfolders
%
% project/
% ├─ rawdata/   # DICOM
% ├─ nifti/ <---------------- [Select parent folder (contains sub-*/ses-*/func)] (1)
% │  ├─ sub-01/                                         
% │  │  ├─ anat/             
% │  │  │  ├─ *T1*.nii 
% │  │  │  └─ *T1*.nii derivatives 
% │  │  └─ func/  <----------- [Select the FUNC subfolder for the first subject] (2) 
% │  │     ├─ sess-01/
% │  │     │  ├─ Unprocessed functional files (*.nii)
% │  │     │  └─ Preprocessed functional files (*.nii):
% │  │     │     • smoothed + normalized + realigned 
% │  │     │     • unsmoothed + normalized + realigned <---- [Apply text filter] (3)
% │  │     └─ sess-02/ ... 
% │  └─ sub-02/ ...   
% └─ firstlevel-spm/ <-------- [Parent folder with FUNC subfolders (BY DEFAULT)] (Needs to be changed!)
%    ├─ sub-01/   <----------------------------------- [Selected subject folder]  
%    │  ├─ GLM-01/
%    │  │  ├─ SPM.mat  <-------------------------------- [Selected SPM.mat file]
%    │  │  └─ TMFC_denoise/ <----------------------------------- [Output folder]
%    │  └─ GLM-02/ ...
%    └─ sub-02/ ...
%
% =========================================================================
% Copyright (C) 2025 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin < 2, error('Check inputs.'); end
if ischar(subject_paths), subject_paths = cellstr(subject_paths); end
subject_paths = subject_paths(:);  % column cell

func_paths = [];
func_root = '';                 
func_root_default = '';         
func_subfolder_full = '';       
func_subfolder_rel  = '';       
no_files = {};

preserve_spm_paths = false;   
spm_first_images   = {};     

% Mapping container built by Apply Filter:
% unsm_index(iSub).groups(g) with fields:
%   .orig_dir        (directory from SPM.xY.VY)
%   .target_dir      (mapped under FUNC root)
%   .unsm_files      (cellstr of matched files; 1 = 4D, >1 = 3D series)
%   .scan_indices    (indices of scans in SPM.xY.VY belonging to this dir)
unsm_index = struct([]);

% Track whether user changed root/subfolder (to disable fallback to orig_dir)
user_changed_root = false;
user_changed_subf = false;

% -------------------------------------------------------------------------
% GUI elements
% -------------------------------------------------------------------------
SF_MW = figure('Name','Select unsmoothed functional images','NumberTitle','off', ...
    'Units','normalized','Position',[0.30 0.22 0.45 0.60], ...
    'MenuBar','none','ToolBar','none','Color','w','CloseRequestFcn',@SF_MW_exit);

SF_S1_str = {'Functional images must be realigned, normalized and unsmoothed.'};
uicontrol(SF_MW,'Style','text','String',SF_S1_str,'Units','normalized', ...
    'Position',[0.03 0.92 0.95 0.05],'FontUnits','normalized','FontSize',0.48, ...
    'HorizontalAlignment','left','BackgroundColor','w');

% Parent folder with FUNC subfolders (by default)
func_root_default = fileparts(subject_paths{1});
if isempty(func_root_default), func_root_default = filesep; end
func_root = func_root_default;

% Button: Select parent folder (contains sub-*/ses-*/func)
SF_MW_S0 = uicontrol(SF_MW,'Style','pushbutton','String','Select parent folder (contains sub-*/.../func)', ...
    'TooltipString','Folder that directly contains subject folders (e.g., sub-01, sub-02) with FUNC subfolders (which include unsmoothed functional images).', ...
    'Units','normalized','Position',[0.025 0.82 0.41 0.080],'FontUnits','normalized','FontSize',0.295, ...
    'Callback',@select_func_root);

% Box panel: Select parent folder (contains sub-*/ses-*/func)
SF_MW_S0_panel = uipanel(SF_MW,'Units','normalized','Position',[0.45 0.823 0.525 0.076], ...
    'HighlightColor',[0.78 0.78 0.78],'BorderType','line','BackgroundColor','w');

% Box text: Select parent folder (contains sub-*/ses-*/func)
SF_MW_S0_txt = uicontrol('Parent',SF_MW_S0_panel,'Style','text','String',func_root, ...
    'Units','normalized','Position',[0.03 0.05 0.94 0.64],'FontUnits','normalized','FontSize',0.48, ...
    'HorizontalAlignment','center','BackgroundColor','w','ForegroundColor',[0 0 0]);

% Button: Select the FUNC subfolder for the first subject
SF_MW_S1 = uicontrol(SF_MW,'Style','pushbutton','String','Select the FUNC subfolder for the first subject', ...
    'Units','normalized','Position',[0.025 0.73 0.41 0.080],'FontUnits','normalized','FontSize',0.295, ...
    'Callback',@select_subfolder);

% Box panel: Select the FUNC subfolder for the first subject
SF_MW_S1_panel = uipanel(SF_MW,'Units','normalized','Position',[0.45 0.733 0.525 0.076], ...
    'HighlightColor',[0.78 0.78 0.78],'BorderType','line','BackgroundColor','w');

% Box text: Select the FUNC subfolder for the first subject
SF_MW_S1_txt = uicontrol('Parent',SF_MW_S1_panel,'Style','text','String','Not selected', ...
    'ForegroundColor',[1 0.55 0],'Units','normalized','Position',[0.03 0.09 0.94 0.64], ...
    'FontUnits','normalized','FontSize',0.50,'HorizontalAlignment','center','BackgroundColor','w');

% Button: Text filter
SF_MW_B1 = uicontrol(SF_MW,'Style','pushbutton','String','Apply text filter unique for functional images:', ...
    'Units','normalized','Position',[0.025 0.64 0.41 0.080],'FontUnits','normalized','FontSize',0.295, ...
    'Callback',@apply_filter);

% Edit: Text filter
SF_MW_B1_E = uicontrol(SF_MW,'Style','edit','String','^war*.nii', ...
    'Units','normalized','Position',[0.45 0.64 0.525 0.080], ...
    'FontUnits','normalized','FontSize',0.32,'BackgroundColor','w');

% Preview list (first matched file per subject)
SF_MW_LB1 = uicontrol(SF_MW,'Style','listbox','String','','Max',100000, ...
    'Units','normalized','Position',[0.025 0.25 0.95 0.37],'FontUnits','points', ...
    'FontSize',10,'Value',[]);

% Button: Preserve functional images' paths from SPM.mat files
SF_MW_KEEP = uicontrol(SF_MW,'Style','pushbutton',...
    'String','Preserve functional image paths from the SPM.mat files',...
    'TooltipString','(i.e., if the GLMs were specified with unsmoothed functional images)',...
    'Units','normalized','Position',[0.025 0.15 0.95 0.078],...
    'FontUnits','normalized','FontSize',0.3,...
    'Callback',@preserve_from_spm_cb);

% Button: OK
SF_MW_OK   = uicontrol(SF_MW,'Style','pushbutton','String','OK', ...
    'Units','normalized','Position',[0.300 0.045 0.199 0.078], ...
    'FontUnits','normalized','FontSize',0.30,'Callback',@export_paths);

% Button: Help
SF_MW_HELP = uicontrol(SF_MW,'Style','pushbutton','String','Help', ...
    'Units','normalized','Position',[0.510 0.045 0.200 0.078], ...
    'FontUnits','normalized','FontSize',0.30,'Callback',@open_help);

movegui(SF_MW,'center');

% -------------------------------------------------------------------------
% Close GUI
% -------------------------------------------------------------------------
function SF_MW_exit(~,~)
    func_paths = [];
    fprintf(2,'Functional images are not selected.\n');
    uiresume(SF_MW);
end

% -------------------------------------------------------------------------
% Select FUNC root folder (contains sub-*/ses-*/func)
% -------------------------------------------------------------------------
function select_func_root(~,~)
    tmp = deblank(spm_select(1,'dir','Select parent folder (contains sub-*/.../func)',{},func_root,'..'));
    if ~isempty(tmp)
        user_changed_root = ~strcmp(tmp, func_root);
        func_root = tmp;
        set(SF_MW_S0_txt,'String',func_root,'ForegroundColor',[0 0 0],'HorizontalAlignment','center');
        % changing root cancels preserve-mode
        preserve_spm_paths = false;
        spm_first_images   = {};
        % Reset downstream choices & cached mappings
        func_subfolder_full = '';
        func_subfolder_rel  = '';
        user_changed_subf    = false;
        set(SF_MW_S1_txt,'String','Not selected','ForegroundColor',[1 0.55 0],'HorizontalAlignment','center');
        set(SF_MW_LB1,'String','');  % clear preview list
        unsm_index = struct([]);     % clear mappings
    end
end

% -------------------------------------------------------------------------
% Select FUNC subfolder for the first subject
% -------------------------------------------------------------------------
function select_subfolder(~,~)
    set(SF_MW_S1_txt,'String','Not selected','ForegroundColor',[1 0.55 0],'HorizontalAlignment','center');

    [~, subj_id1] = fileparts(subject_paths{1});
    start_dir = fullfile(func_root, subj_id1);
    if ~exist(start_dir,'dir'), start_dir = func_root; end
    if ~exist(start_dir,'dir'), start_dir = subject_paths{1}; end

    sel_dir = deblank(spm_select(1,'dir','Select ''functional'' subfolder',{},start_dir,'..'));
    if ~isempty(sel_dir)
        user_changed_subf  = true;
        func_subfolder_full = sel_dir;
        update_rel_display();
        set(SF_MW_LB1,'String','');  % clear preview (must re-apply filter)
        unsm_index = struct([]);     % clear mappings
        % selecting a subfolder cancels preserve-mode
        preserve_spm_paths = false;
        spm_first_images   = {};
    else
        fprintf(2,'Please select ''functional'' subfolder for the first subject.\n');
    end
end

% -------------------------------------------------------------------------
% Compute relative path & show it (relative to <func_root>/<sub-01>)
% -------------------------------------------------------------------------
function update_rel_display()
    [~, subj_id1] = fileparts(subject_paths{1});
    base_first = [fullfile(func_root, subj_id1) filesep];

    % Default computation
    if strncmpi(func_subfolder_full, base_first, numel(base_first))
        func_subfolder_rel = func_subfolder_full(numel(base_first)+1:end);
    else
        base_first2 = [subject_paths{1} filesep];
        func_subfolder_rel = strrep(func_subfolder_full, base_first2, '');
    end

    % If user selected subject folder itself - no subfolder
    if isempty(func_subfolder_rel) || strcmpi(func_subfolder_rel, subj_id1)
        func_subfolder_rel = '';
    end

    % Update GUI display
    if isempty(func_subfolder_rel)
        set(SF_MW_S1_txt,'String','Not selected','ForegroundColor',[1 0.55 0],'HorizontalAlignment','center');
    else
        set(SF_MW_S1_txt,'String',func_subfolder_rel,'ForegroundColor',[0 0 0], ...
            'HorizontalAlignment','center');
    end
end

% -------------------------------------------------------------------------
% Build scan groups by original directory in SPM.xY.VY
% -------------------------------------------------------------------------
function groups = build_scan_groups(SPM)
    n = numel(SPM.xY.VY);
    groups = struct('orig_dir',{},'scan_indices',{});
    seen = {};
    for k=1:n
        [d,~,~] = fileparts(SPM.xY.VY(k).fname);
        gi = find(strcmp(d, seen), 1, 'first');
        if isempty(gi)
            seen{end+1} = d;
            gidx = numel(groups)+1;
            groups(gidx).orig_dir    = d;
            groups(gidx).scan_indices = k;
        else
            gidx = gi;
            groups(gidx).scan_indices(end+1) = k;
        end
    end
end

% -------------------------------------------------------------------------
% Apply text filter: find unsmoothed files per session/run dir
% -------------------------------------------------------------------------
function apply_filter(~,~)
    f = msgbox('Selecting functional images. Please wait . . .');
    set(SF_MW_LB1,'String','');    % clear preview
    unsm_index = struct([]);       % reset mappings
    no_files = {};
    % leave preserve-mode when user applies a filter
    preserve_spm_paths = false;
    spm_first_images   = {};

    txt_filter = get(SF_MW_B1_E,'String');
    txt_filter = strrep(txt_filter,' ','');

    if isempty(txt_filter)
        fprintf(2,'Filter is empty or invalid, please re-enter.\n');
        try; close(f); end
        return;
    end

    % 'dir' uses wildcards, not regex; allow '^war*.nii' in UI by stripping '^'
    dir_filter = regexprep(txt_filter,'^\^','');

    % preview lines we’ll render into the listbox
    preview_lines = {};

    for iSub = 1:numel(subject_paths)
        [~, subj_id] = fileparts(subject_paths{iSub});
        SPM = load(SPM_paths{iSub}).SPM;

        % Build groups of scans in order, per original session directory
        groups = build_scan_groups(SPM);

        out_groups = struct('orig_dir',{},'target_dir',{},'unsm_files',{},'scan_indices',{});

        % Subject header in the preview
        preview_lines{end+1,1} = sprintf('▶ %s', subj_id);

        for g = 1:numel(groups)
            orig_dir   = groups(g).orig_dir;
            scan_idx   = groups(g).scan_indices;

            % Try structured candidates derived from STAT->FUNC mapping
            cand_dirs = generate_candidates(orig_dir, subj_id, func_root, func_subfolder_rel, subject_paths);
            
            cand = []; target_dir = '';
            for ci = 1:numel(cand_dirs)
                td = cand_dirs{ci};
                fprintf('Searching in: %s | pattern: %s\n', td, dir_filter);
                cand = dir(fullfile(td, dir_filter));
                if ~isempty(cand)
                    cand = cand(~[cand.isdir]);
                    names = {cand.name};
                    is_hdr = endsWith(lower(names), '.hdr');
                    cand(is_hdr) = [];
                end
                if ~isempty(cand)
                    target_dir = td;
                    break;
                end
            end
            
            % If still empty, do a bounded BFS under the subject's FUNC root,
            % ranking hits by overlap with the STAT remainder (session/run hint).
            if isempty(cand)
                subj_root = fullfile(func_root, resolve_func_subject_name(func_root, subj_id));
                rr_hint   = split_parts(remainder_under_subject(orig_dir, subj_id));
                td = bfs_find_dir_with_pattern(subj_root, dir_filter, 3, rr_hint);  % depth=3 is usually enough
                if ~isempty(td)
                    fprintf('BFS found: %s | pattern: %s\n', td, dir_filter);
                    cand = dir(fullfile(td, dir_filter));
                    if ~isempty(cand)
                        cand = cand(~[cand.isdir]);
                        names = {cand.name};
                        is_hdr = endsWith(lower(names), '.hdr');
                        cand(is_hdr) = [];
                    end
                    if ~isempty(cand)
                        target_dir = td;
                    end
                end
            end
            
            % Fallback to original SPM folder (only if the user did NOT change root/subfolder)
            if isempty(cand) && (~user_changed_root && ~user_changed_subf)
                fprintf('Fallback to original SPM folder: %s | pattern: %s\n', orig_dir, dir_filter);
                cand = dir(fullfile(orig_dir, dir_filter));
                if ~isempty(cand)
                    cand = cand(~[cand.isdir]);
                    names = {cand.name};
                    is_hdr = endsWith(lower(names), '.hdr');
                    cand(is_hdr) = [];
                end
                if ~isempty(cand)
                    target_dir = orig_dir;
                end
            end


            if ~isempty(cand)
                % sort by name (assumes zero-padded numbering; common for NIfTI series)
                names = sort({cand.name}');
                unsm_files = cellfun(@(z) fullfile(target_dir,z), names, 'UniformOutput', false);

                out_groups(end+1).orig_dir    = orig_dir;
                out_groups(end).target_dir    = target_dir;
                out_groups(end).unsm_files    = unsm_files;  % 1 = 4D, >1 = 3D series
                out_groups(end).scan_indices  = scan_idx;

                % Add a per-group preview line (first file only)
                kind = '4D';
                if numel(unsm_files) > 1
                    kind = sprintf('3D×%d', numel(unsm_files));
                end
                preview_lines{end+1,1} = sprintf('   [%02d] %s  (%s)', g, unsm_files{1}, kind);
            else
                % Show that this group had no matches
                preview_lines{end+1,1} = sprintf('   [%02d] [no matches]  (%s)', g, target_dir);
            end
        end

        if isempty(out_groups)
            no_files = vertcat(no_files, subject_paths(iSub));
            % If absolutely nothing for the subject, make sure there's a clear line
            % (header already added; add an explicit "no matches")
            preview_lines{end+1,1} = '   [no matches for subject]';
        else
            unsm_index(iSub).groups = out_groups;
        end

        % Blank line between subjects (purely visual)
        preview_lines{end+1,1} = '';
    end

    if all(cellfun(@(s) contains(s,'no matches','IgnoreCase',true) || isempty(s), preview_lines))
        fprintf(2,'No images matched the filter "%s". Please check the FUNC root/subfolder and filter.\n', txt_filter);
    end

    set(SF_MW_LB1,'String',preview_lines,'Value',[]);
    try; close(f); end
end

% -------------------------------------------------------------------------
% Preserve FUNC paths form SPM.mat files
% -------------------------------------------------------------------------
function preserve_from_spm_cb(~,~)
    % Set mode and preview: first image per subject from SPM.xY.VY(1).fname
    fpr1 = msgbox('Selecting functional images. Please wait . . .');
    preserve_spm_paths = true;
    spm_first_images = cell(numel(SPM_paths),1);
    for iSub = 1:numel(SPM_paths)
        SPM = load(SPM_paths{iSub}).SPM;
        spm_first_images{iSub,1} = SPM.xY.VY(1).fname;
    end
    try; close(fpr1); end
    set(SF_MW_LB1,'String',spm_first_images,'Value',[]);
end

% -------------------------------------------------------------------------
% Check and export paths (per scan; 4D or 3D series handled)
% -------------------------------------------------------------------------
function export_paths(~,~)
    if preserve_spm_paths
        fpr2 = msgbox('Selecting functional images. Please wait . . .');
        func_paths = struct([]);
        for jSub = 1:numel(SPM_paths)
            SPM = load(SPM_paths{jSub}).SPM;
            nScan = numel(SPM.xY.VY);
            func_paths(jSub).fname = cell(nScan,1);
            for kScan = 1:nScan
                v = SPM.xY.VY(kScan);
                func_paths(jSub).fname{kScan,1} = sprintf('%s,%d', v.fname, v.n(1));
            end
        end
        disp('Functional images selected (preserved from SPM.mat).');
        try; close(fpr2); end
        uiresume(SF_MW);
        return;
    end

    f3 = msgbox('Checking functional images. Please wait . . .');

    if isempty(unsm_index) || ~isfield(unsm_index, 'groups') || isempty([unsm_index.groups])
        fprintf(2,'Functional images are not selected, please apply the filter first.\n');
        try; close(f3); end
        return;
    end

    func_paths = struct([]);
    for jSub = 1:numel(SPM_paths)
        SPM = load(SPM_paths{jSub}).SPM;

        if jSub>numel(unsm_index) || ~isfield(unsm_index(jSub),'groups') || isempty(unsm_index(jSub).groups)
            func_paths(jSub).fname = {};
            continue;
        end

        G = unsm_index(jSub).groups;
        nScan = numel(SPM.xY.VY);
        func_paths(jSub).fname = cell(nScan,1);

        for g = 1:numel(G)
            scan_idx = G(g).scan_indices(:)';         
            unsmf    = G(g).unsm_files(:)';           

            if isempty(scan_idx) || isempty(unsmf)
                continue;
            end

            if numel(unsmf) == 1
                % 4D file
                file4D = unsmf{1};
                for kk = scan_idx
                    vol_idx = SPM.xY.VY(kk).n(1);
                    func_paths(jSub).fname{kk,1} = [file4D ',' num2str(vol_idx)];
                end
            else
                % 3D series
                for i = 1:min(numel(scan_idx), numel(unsmf))
                    kk = scan_idx(i);
                    func_paths(jSub).fname{kk,1} = [unsmf{i} ',1'];
                end
            end
        end
    end
    
    % Check existence of all files and collect missing subjects
    missing_subs = {};
    for jSub = 1:numel(func_paths)
        miss_any = false;

        % Skip if struct entry missing
        if ~isfield(func_paths(jSub),'fname') || isempty(func_paths(jSub).fname)
            miss_any = true;
        else
            fnames = func_paths(jSub).fname;
            for k = 1:numel(fnames)
                if isempty(fnames{k})
                    miss_any = true;
                    break;
                end
                parts = strsplit(fnames{k}, ',');
                fpath = strtrim(parts{1});
                if ~isfile(fpath)
                    miss_any = true;
                    break;
                end
            end
        end
    
        if miss_any
            missing_subs{end+1,1} = subject_paths{jSub};
        end
    end

    try; close(f3); end

    if ~isempty(missing_subs)
        fprintf(2,'[Warning] Missing functional files detected for %d subject(s).\n', numel(missing_subs));
        missing_images_GUI(missing_subs);
    else
        disp('All functional images exist and were successfully selected.');
        uiresume(SF_MW);
    end
end

% -------------------------------------------------------------------------
% Warning window: missing images
% -------------------------------------------------------------------------
function missing_images_GUI(no_files_loc)
    SF_WW = figure('Name','Select subjects','NumberTitle','off','Units','normalized', ...
        'Position',[0.32 0.30 0.35 0.28],'Color','w','MenuBar','none','ToolBar','none','WindowStyle','Modal');
    uicontrol(SF_WW,'Style','listbox','String',no_files_loc,'Max',1000,'Units','normalized', ...
        'Position',[0.032 0.250 0.940 0.520],'FontUnits','points','FontSize',10,'Value',[]);
    uicontrol(SF_WW,'Style','text','String', ...
        'Warning, functional images are missing for the following subjects:', ...
        'Units','normalized','Position',[0.15 0.820 0.720 0.095], ...
        'FontUnits','points','FontSize',11,'HorizontalAlignment','center','BackgroundColor','w');
    uicontrol(SF_WW,'Style','pushbutton','String','OK','Units','normalized', ...
        'Position',[0.415 0.06 0.180 0.120],'FontUnits','normalized','FontSize',0.30, ...
        'Callback',@(s,e) close(SF_WW));
    movegui(SF_WW,'center');
    uiwait(SF_WW);
end

% -------------------------------------------------------------------------
% Help window
% -------------------------------------------------------------------------
function open_help(~,~)
   page1 = {
        ''
        '   First, select the parent folder that contains all subject folders' 
        '   with FUNC subfolders (if necessary).'
        ''
        '   Then select the FUNC subfolder for the first subject and apply text'
        '   filter (e.g., *war*.nii, *wr*.nii, or *preproc*.nii.gz) to match all fMRI images.'
        ''
        '   NOTE: You can also try applying the text filter without changing folders.'
        ''
        '   • If you do NOT select a new parent folder (FUNC root), the toolbox will'
        '     use the same parent directory as the STAT folder (SPM.mat).'
        ''
        '   • If you do NOT select a FUNC subfolder for the first subject, the toolbox'
        '     will attempt to use the same relative structure as in SPM.xY.VY paths.'
        ''
        '   In both cases, the search will be performed automatically using paths'
        '   derived from the original SPM.mat configuration, so it may still find the'
        '   correct functional files — provided their locations have not changed.'
        ''
        '   ================= EXAMPLE #1 (SPM-like folder structure) =================='
        ''
        '   There is no need to change the parent folder to select functional files.'
        ''
        '   project/'
        '   ├─ rawdata/      # DICOM'
        '   └─ derivatives/  <-------------------- [Parent folder with FUNC subfolders (BY DEFAULT)]'
        '      ├─ sub-01/    <-------------------------------------------- [Selected subject folder]'
        '      │  ├─ anat/'
        '      │  │  ├─ *T1*.nii'
        '      │  │  └─ *T1*.nii derivatives'
        '      │  ├─ func/  <--------------------- [Select the FUNC subfolder for the first subject] (1)'
        '      │  │  ├─ sess-01/'
        '      │  │  │  ├─ Unprocessed functional files (*.nii)'
        '      │  │  │  └─ Preprocessed functional files:'
        '      │  │  │       ◦ smoothed + norm. + real. (e.g., swar*.nii)'
        '      │  │  │       ◦ unsmoothed + norm. + real. (e.g., war*.nii) <---- [Apply text filter] (2)' 
        '      │  │  └─ sess-02/ ...'
        '      │  └─ stat/              # first-level models (one folder per GLM)'
        '      │     ├─ GLM-01/'
        '      │     │  ├─ SPM.mat  <--------------------------------------- [Selected SPM.mat file]'
        '      │     │  └─ TMFC_denoise/ <------------------------------------------ [Output folder]'
        '      │     └─ GLM-02/ ...'
        '      └─ sub-02/ ...'
    };

    page2 = {
        ''
        '   ================ EXAMPLE #2 (BIDS-like folder structure) ================='
        ''
        '   "project/derivatives/firstlevel-spm" parent folder with STAT subfolders needs to be'
        '   changed to "project/derivatives/fmriprep" — parent folder with FUNC subfolders.'
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
        '       ├── fmriprep/ <----------------- [Select parent folder (contains sub-*/ses-*/func)] (1)'
        '       │   ├── sub-01/'
        '       │   │   ├── ses-01/'
        '       │   │   │   └── func/'
        '       │   │   │       └── Preprocessed functional files:'
        '       │   │   │           ◦ smoothed + normalized + realigned'
        '       │   │   │           ◦ unsmoothed + normalized + realigned <---- [Apply text filter] (2)'
        '       │   │   └── ses-02/ ...'
        '       │   └── sub-02/ ...'
        '       └── firstlevel-spm/  <---- [Parent folder with FUNC (BY DEFAULT)](Needs to be changed!)'
        '           ├── sub-01/     <------------------------------------ [Selected subject folder]'
        '           │   ├── GLM-01/'
        '           │   │   ├── SPM.mat        <--------------------------- [Selected SPM.mat file]'
        '           │   │   └── TMFC_denoise/  <----------------------------------- [Output folder]'
        '           │   └── GLM-02/ ...'
        '           └── sub-02/ ...'
    };

    page3 = {
        ''
        '   ================ EXAMPLE #3 (Other non-BIDS folder structure) ================'
        ''
        '   "project/firstlevel-spm" parent folder with STAT subfolders needs'
        '   to be changed to "project/nifti"  — parent folder with FUNC subfolders.'
        ''
        '   project/'
        '   ├─ rawdata/ # DICOM'
        '   ├─ nifti/   <-------------- [Select parent folder (contains sub-*/ses-*/func)]  (1)'
        '   │  ├─ sub-01/'
        '   │  │  ├─ anat/'
        '   │  │  │  ├─ *T1*.nii  '
        '   │  │  │  └─ *T1*.nii derivatives'
        '   │  │  └─ func/   <---------- [Select the FUNC subfolder for the first subject]  (2)'
        '   │  │     ├─ sess-01/'
        '   │  │     │  ├─ Unprocessed functional files (*.nii)'
        '   │  │     │  └─ Preprocessed functional files (*.nii):'
        '   │  │     │     ◦ smoothed + normalized + realigned'
        '   │  │     │     ◦ unsmoothed + normalized + realigned <---- [Apply text filter] (3)'
        '   │  │     └─ sess-02/ ...'
        '   │  └─ sub-02/ ...'
        '   └─ firstlevel-spm/  <-- [Parent folder with FUNC subfolders (BY DEFAULT)](Needs to be changed!)'
        '      ├─ sub-01/   <----------------------------------- [Selected subject folder]'
        '      │  ├─ GLM-01/'
        '      │  │  ├─ SPM.mat    <------------------------------ [Selected SPM.mat file]'
        '      │  │  └─ TMFC_denoise/   <--------------------------------- [Output folder]'
        '      │  └─ GLM-02/ ...'
        '      └─ sub-02/ ...'
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

% -------------------------------------------------------------------------
% Helpers
% -------------------------------------------------------------------------
function cand_dirs = generate_candidates(orig_dir, subj_id, func_root, func_subfolder_rel, subject_paths)
    orig_dir = strrep(strrep(orig_dir,'/',filesep),'\',filesep);
    func_subj_name = resolve_func_subject_name(func_root, subj_id);

    base_rel = sanitize_base_rel(func_subfolder_rel, func_root, subject_paths, func_subj_name);

    remainder = remainder_under_subject(orig_dir, subj_id);

    br = split_parts(base_rel);
    rr = split_parts(remainder);

    k = common_prefix_len(br, rr);
    tail = rr(k+1:end);

    C1 = fullfile(func_root, func_subj_name, br{:}, tail{:});
    C2 = fullfile(func_root, func_subj_name, rr{:});
    C3 = fullfile(func_root, func_subj_name, br{:});

    rr2 = strip_stat_tokens(rr);
    k2 = common_prefix_len(br, rr2);
    tail2 = rr2(k2+1:end);
    C4 = fullfile(func_root, func_subj_name, br{:}, tail2{:});

    cand_dirs = unique_nonempty({C1,C2,C3,C4});
end

% Best-match subject folder under FUNC root (prefix/suffix tolerant)
function name = resolve_func_subject_name(root_dir, subj_id)
    cand = fullfile(root_dir, subj_id);
    if exist(cand, 'dir')
        name = subj_id; 
        return;
    end
    % list candidates
    d = dir(root_dir);
    d = d([d.isdir]);
    names = setdiff({d.name},{'.','..'});

    % try contains() first
    hit = find(contains(lower(names), lower(subj_id)), 1, 'first');
    if ~isempty(hit)
        name = names{hit}; 
        return;
    end

    % fallback: longest common substring (uses your lcsstr() at file bottom)
    bestName = '';
    bestScore = -inf;
    for k = 1:numel(names)
        common = lcsstr(subj_id, names{k});
        sc = numel(common);
        if sc > bestScore
            bestScore = sc; bestName = names{k};
        end
    end
    if ~isempty(bestName)
        name = bestName;
        if bestScore < 4
            fprintf(2,'[Notice] Weak match for subject "%s" under "%s": picked "%s"\n', ...
                subj_id, root_dir, name);
        end
    else
        % use provided subj_id (will likely fail later, but is explicit)
        name = subj_id;
        fprintf(2,'[Warning] No subject-like folder under "%s" matched "%s".\n', root_dir, subj_id);
    end
end

% Longest common substring, case-insensitive
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

function out = sanitize_base_rel(base_rel, func_root, subject_paths, func_subj_name)
    out = base_rel;
    if isempty(out), return; end

    % normalize seps
    out = strrep(strrep(out,'/',filesep),'\',filesep);

    low_out  = lower(out);
    low_root = lower(func_root);

    if startsWith(low_out, low_root)
        % strip func_root prefix
        rem = out(numel(func_root)+1:end);
        if ~isempty(rem) && rem(1)==filesep, rem = rem(2:end); end

        parts = split_parts(rem);

        % drop a leading subject folder if it’s the current subject
        if ~isempty(parts) && strcmpi(parts{1}, func_subj_name)
            parts(1) = [];
        end

        % also drop a leading subject folder if it’s ANY subject under func_root
        d = dir(func_root); d = d([d.isdir]);
        allsubs = lower(setdiff({d.name},{'.','..'}));
        if ~isempty(parts) && any(strcmpi(lower(parts{1}), allsubs))
            parts(1) = [];
        end

        out = strjoin(parts, filesep);
    end

    % if the remaining rel path still starts with the subject name, drop it
    if startsWith(lower(out), [lower(func_subj_name) filesep])
        out = out(numel(func_subj_name)+2:end);
    elseif strcmpi(out, func_subj_name)
        out = '';
    end
end

function remainder = remainder_under_subject(orig_dir, subj_id)
    low_dir = lower(orig_dir);
    low_key = [filesep lower(subj_id) filesep];
    remainder = '';
    p = strfind(low_dir, low_key);
    if ~isempty(p)
        cut = p(1) + numel(low_key) - 1;
        remainder = orig_dir(cut+1:end);
        if ~isempty(remainder) && remainder(1)==filesep, remainder = remainder(2:end); end
    else
        % best-effort
        [~, remainder] = fileparts(orig_dir);
    end
end

function parts = split_parts(p)
    if isempty(p), parts = {}; return; end
    parts = regexp(p, ['[^' regexptranslate('escape', filesep) ']+'], 'match');
    parts = parts(:)';
end

function k = common_prefix_len(a,b)
    n = min(numel(a), numel(b)); k = 0;
    for i=1:n
        if strcmpi(a{i}, b{i}), k = k + 1; else, break; end
    end
end

function rr2 = strip_stat_tokens(rr)
    if isempty(rr), rr2 = rr; return; end
    tokens = {'stat','stats','firstlevel','firstlvl','firstlvl-spm','firstlevel-spm','spm','models','model','glm'};
    rr2 = rr;
    while ~isempty(rr2)
        head = lower(rr2{1});
        if any(strcmp(head, tokens)) || startsWith(head,'glm') || startsWith(head,'model')
            rr2(1) = [];
        else
            break;
        end
    end
end

function list = unique_nonempty(cellstrs)
    seen = containers.Map('KeyType','char','ValueType','logical');
    list = {};
    for i=1:numel(cellstrs)
        s = cellstrs{i};
        if isempty(s), continue; end
        key = lower(s);
        if ~isKey(seen, key)
            seen(key) = true;
            list{end+1} = s; 
        end
    end
end

function best = bfs_find_dir_with_pattern(root_dir, pattern, max_depth, rr_hint)
    % Collect all hits, then rank by overlap with rr_hint (component LCP), then shorter depth.
    best = '';
    if ~isfolder(root_dir), return; end
    root_dir = char(root_dir);
    rr_hint = rr_hint(:)';

    % BFS
    Q = {root_dir, 0};
    seen = containers.Map('KeyType','char','ValueType','logical');
    seen(lower(root_dir)) = true;
    hits = {}; meta = []; 
    depths = [];

    while ~isempty(Q)
        dir_path = Q{1}; depth = Q{2}; Q(1:2) = [];
        if depth > max_depth, continue; end

        if ~isempty(dir(fullfile(dir_path, pattern)))
            hits{end+1} = dir_path; 
            depths(end+1) = depth;  
        end

        d = dir(dir_path);
        d = d([d.isdir]);
        names = setdiff({d.name},{'.','..'});
        % Stable order
        names = sort(names);
        for i=1:numel(names)
            child = fullfile(dir_path, names{i});
            key = lower(child);
            if ~isKey(seen, key)
                seen(key) = true;
                Q(end+1:end+2) = {child, depth+1}; 
            end
        end
    end

    if isempty(hits), return; end

    % Rank hits by common-prefix with rr_hint (relative to root_dir), then by smaller depth, then lexicographic.
    scores = zeros(1,numel(hits));
    rels = cell(1,numel(hits));
    for i=1:numel(hits)
        h = hits{i};
        rel = h;
        low_h = lower(h);
        low_root = lower(root_dir);
        if startsWith(low_h, [low_root filesep])
            rel = h(numel(root_dir)+2:end);
        elseif strcmpi(low_h, low_root)
            rel = '';
        end
        rels{i} = split_parts(rel);
        scores(i) = common_prefix_len(rels{i}, rr_hint);
    end

    % Pick best
    [~, ord] = sortrows([(-scores(:)) depths(:)], [1 2]); % max score, then min depth
    hits = hits(ord);
    best = hits{1};
end

% -------------------------------------------------------------------------
uiwait(SF_MW);
delete(SF_MW);
end
