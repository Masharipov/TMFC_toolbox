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
% filter (e.g., *war*.nii, *wr*.nii, or *preproc*.nii) to match all
% unsmoothed, normalized, realigned functional images.
% Compressed functional images (*.nii.gz) are not supported. Decompress
% them to *.nii before selection.
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
func_subfolder_rel = '';
manual_first_subj_name = '';
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
    'Units','normalized','Position',[0.03 0.05 0.94 0.64], ...
    'FontUnits','points','FontSize',9, ...
    'HorizontalAlignment','center','BackgroundColor','w','ForegroundColor',[0 0 0], ...
    'TooltipString',func_root);

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
        user_changed_root = ~strcmpi(tmp, func_root_default);
        func_root = tmp;
        set(SF_MW_S0_txt,'String',func_root, ...
            'TooltipString',func_root, ...
            'ForegroundColor',[0 0 0],'HorizontalAlignment','center');
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

    % Reset previous FUNC selection before opening the dialog
    func_subfolder_full = '';
    func_subfolder_rel = '';
    manual_first_subj_name = '';
    user_changed_subf = false;

    % Clear previous results and mappings
    func_paths = [];
    no_files = {};
    unsm_index = struct([]);
    preserve_spm_paths = false;
    spm_first_images = {};

    set(SF_MW_S1_txt,'String','Not selected', ...
        'ForegroundColor',[1 0.55 0], ...
        'HorizontalAlignment','center', ...
        'TooltipString','');

    set(SF_MW_LB1,'String',{},'Value',[]);

    % Determine initial directory
    func_subj_name = resolve_func_subject_name(func_root,1);
    if isempty(func_subj_name)
        start_dir = func_root;
    else
        start_dir = fullfile(func_root,func_subj_name);
    end
    if ~exist(start_dir,'dir'), start_dir = func_root; end

    % Select new FUNC folder
    sel_dir = deblank(spm_select(1,'dir', ...
        'Select ''functional'' subfolder',{},start_dir,'..'));

    if ~isempty(sel_dir)
        sel_dir = regexprep(sel_dir,'[\\/]+$','');
        user_changed_subf = true;
        func_subfolder_full = sel_dir;
        update_rel_display();
    else
        fprintf('TMFC: FUNC folder not selected.\n');
    end
end

% -------------------------------------------------------------------------
% Compute relative path & show it (relative to <func_root>/<sub-01>)
% -------------------------------------------------------------------------
function update_rel_display()

    manual_first_subj_name = '';
    func_subfolder_rel = '';

    root_clean = strrep(regexprep(func_root,'[\\/]+$',''), '/', filesep);
    selected_clean = strrep(regexprep(func_subfolder_full,'[\\/]+$',''), '/', filesep);

    prefix = [root_clean filesep];

    % The selected folder must be inside FUNC root.
    if ~strncmpi(selected_clean,prefix,numel(prefix))
        fprintf(2,'TMFC: Select a FUNC folder inside %s.\n',func_root);

        user_changed_subf = false;
        func_subfolder_full = '';

        set(SF_MW_S1_txt,'String','Not selected','ForegroundColor',[1 0.55 0]);
        return;
    end

    % The first component is the explicitly selected subject folder
    rel_path = selected_clean(numel(prefix)+1:end);
    parts = regexp(rel_path,'[\\/]+','split');

    manual_first_subj_name = parts{1};

    % Remaining components are the common FUNC subfolder structure
    func_subfolder_rel = strjoin(parts(2:end),filesep);

    if isempty(func_subfolder_rel)
        display_text = manual_first_subj_name;
    else
        display_text = func_subfolder_rel;
    end

    set(SF_MW_S1_txt,'String',display_text, ...
        'ForegroundColor',[0 0 0], ...
        'HorizontalAlignment','center', ...
        'TooltipString',func_subfolder_full);
end

% -------------------------------------------------------------------------
% Build scan groups
% -------------------------------------------------------------------------
function groups = build_scan_groups(SPM)
    files = {SPM.xY.VY.fname};
    low_files = cellfun(@lower, files, 'UniformOutput', false);
    [~,~,file_id] = unique(low_files);
    counts = accumarray(file_id(:),1);
    is4D = counts(file_id) > 1;

    groups = struct('orig_dir',{},'orig_file',{},'is4D',{},'scan_indices',{});
    seen = {};
    for k = 1:numel(files)
        [d,~,~] = fileparts(files{k});
        if is4D(k)
            key = ['FILE:' low_files{k}];
        else
            key = ['DIR:' lower(d)];
        end
        gi = find(strcmp(seen,key),1,'first');
        if isempty(gi)
            seen{end+1} = key;
            gi = numel(groups)+1;
            groups(gi).orig_dir = d;
            groups(gi).orig_file = files{k};
            groups(gi).is4D = is4D(k);
            groups(gi).scan_indices = k;
        else
            groups(gi).scan_indices(end+1) = k;
        end
    end
end

% -------------------------------------------------------------------------
% Match 4D files when several runs share one original SPM directory
% -------------------------------------------------------------------------
function cand = match_shared_dir_4D(cand, groups, g)
    if isempty(cand) || ~groups(g).is4D
        return;
    end
    related = find([groups.is4D] & strcmpi({groups.orig_dir},groups(g).orig_dir));
    if numel(related) < 2 || numel(cand) >= numel(groups(g).scan_indices)
        return;  
    end

    % Compare all source runs to all filenames matching the user's filter
    dist = zeros(numel(related),numel(cand));
    for i = 1:numel(related)
        [~,src_name,src_ext] = fileparts(groups(related(i)).orig_file);
        src_name = lower([src_name src_ext]);
        for j = 1:numel(cand)
            target_name = lower(cand(j).name);
            dist(i,j) = name_edit_distance(src_name,target_name) / max(numel(src_name),numel(target_name));
        end
    end

    row = find(related == g,1);
    [best,j] = min(dist(row,:));
    candidate_best = min(dist(:,j));
    % Accept only a unique mutual best match
    if best >= 0.5 || sum(dist(row,:) == best) ~= 1 || sum(dist(:,j) == candidate_best) ~= 1 || best ~= candidate_best
        fprintf(2,'TMFC: No unambiguous functional filename match for %s.\n',groups(g).orig_file);
        cand = cand([]);
    else
        cand = cand(j);
    end
end

function distance = name_edit_distance(a,b)
    previous = 0:numel(b);
    for i = 1:numel(a)
        current = zeros(1,numel(b)+1);
        current(1) = i;
        for j = 1:numel(b)
            current(j+1) = min([previous(j+1)+1, current(j)+1, previous(j)+(a(i) ~= b(j))]);
        end
        previous = current;
    end
    distance = previous(end);
end

% -------------------------------------------------------------------------
% Match 3D series in a shared flat directory
% -------------------------------------------------------------------------
function cand = match_flat_3D(cand, groups, g)
    if isempty(cand), return; end

    % Extract the common filename stem and volume number
    tokens = regexp({cand.name},'^(.*?)(\d+)(\.[^.]+)$','tokens','once');

    if any(cellfun(@isempty,tokens))
        fprintf(2,'TMFC: Cannot identify 3D volume numbers.\n');
        cand = cand([]);
        return;
    end

    stems = cellfun(@(t) lower(t{1}),tokens,'UniformOutput',false);
    nums = cellfun(@(t) str2double(t{2}),tokens);

    % Build one representative filename per series
    unique_stems = unique(stems,'stable');
    series_names = cell(size(unique_stems));

    for i = 1:numel(unique_stems)
        ix = find(strcmp(stems,unique_stems{i}),1);
        series_names{i} = [unique_stems{i} tokens{ix}{3}];
    end

    series = struct('name',series_names);

    % Match the series against the original SPM run
    matched = match_shared_dir_4D(series,groups,g);

    if numel(matched) ~= 1
        cand = cand([]);
        return;
    end

    ix = find(strcmpi({series.name},matched.name),1);
    selected = find(strcmp(stems,unique_stems{ix}));

    nExpected = numel(groups(g).scan_indices);

    % Require exactly the expected consecutive volume numbers
    if numel(selected) ~= nExpected || ~isequal(sort(nums(selected)),1:nExpected)
        fprintf(2,'TMFC: Missing or duplicate 3D volumes in %s.\n',matched.name);
        cand = cand([]);
        return;
    end

    % Numerical rather than alphabetical ordering
    [~,order] = sort(nums(selected));
    cand = cand(selected(order));
end

% -------------------------------------------------------------------------
% Apply text filter: find unsmoothed files per session/run dir
% -------------------------------------------------------------------------
function apply_filter(~,~)
    f = msgbox('Selecting functional images. Please wait . . .');
    set(SF_MW_LB1,'String','');    % clear preview
    func_paths = [];              % clear previously exported paths
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

    % Resolve subject folders or detect an explicitly selected flat directory
    nSub = numel(subject_paths);
    func_subject_names = cell(nSub,1);

    for iSub = 1:nSub
        if iSub == 1 && user_changed_subf && ~isempty(manual_first_subj_name)
            % Explicit manual selection takes priority for subject 1
            func_subject_names{iSub} = manual_first_subj_name;
        else
            % All other subjects use automatic matching
            func_subject_names{iSub} = resolve_func_subject_name(func_root,iSub);
        end
    end

    flat_mode = false;

    % A shared flat directory must be explicitly selected by the user
    if user_changed_root && all(cellfun(@isempty,func_subject_names))
        hits = dir(fullfile(func_root,dir_filter));
        hits = hits(~[hits.isdir]);

        if ~isempty(hits)
            flat_mode = true;

            for iSub = 1:nSub
                p = regexprep(strtrim(subject_paths{iSub}),'[\\/]+$','');
                [~,func_subject_names{iSub}] = fileparts(p);
            end
        end
    end

    % Reject unresolved subjects
    for iSub = 1:nSub
        if isempty(func_subject_names{iSub})
            fprintf(2,'TMFC: Cannot match subject %d (%s) under %s.\n',iSub,subject_paths{iSub},func_root);
            try, close(f); catch, end
            return;
        end
    end

    keys = cellfun(@lower,func_subject_names,'UniformOutput',false);
    if numel(unique(keys)) ~= nSub
        fprintf(2,'TMFC: Multiple subjects resolve to the same FUNC folder. Automatic selection canceled.\n');
        try, close(f); catch, end
        return;
    end
    
    flat_groups = struct('orig_dir',{},'orig_file',{},'is4D',{},'scan_indices',{});
    flat_offset = zeros(nSub,1);

    if flat_mode
        for s = 1:nSub
            A = load(SPM_paths{s},'SPM');
            G = build_scan_groups(A.SPM);

            if isempty(G) || any(~[G.is4D])
                fprintf(2,'TMFC: Flat-folder selection requires SPM.mat to reference 4D run files.\n');
                try, close(f); catch, end
                return;
            end

            flat_offset(s) = numel(flat_groups);

            for k = 1:numel(G)
                G(k).orig_dir = func_root;
            end

            flat_groups = [flat_groups G];
        end

        F = dir(fullfile(func_root,dir_filter));
        F = F(~[F.isdir]);
        if contains_gzip_nifti(F)
            try, close(f); catch, end
            reject_compressed_functional();
            return;
        end

        nRuns = numel(flat_groups);
        nScans = sum(arrayfun(@(g) numel(g.scan_indices),flat_groups));

        flat_is3D = false;

        if numel(F) == nRuns
            % One 4D file per run
            fprintf('TMFC: Flat folder: %d 4D files.\n',nRuns);
        elseif numel(F) == nScans
            % One 3D file per scan
            flat_is3D = true;
            fprintf('TMFC: Flat folder: %d 3D files.\n',nScans);
        else
            fprintf(2,'TMFC: Flat-folder file count mismatch (files: %d; runs: %d; scans: %d).\n',numel(F),nRuns,nScans);
            try, close(f); catch, end
            return;
        end
    end

    % Preview one image from each matched run or session
    preview_lines = {};

    for iSub = 1:nSub
        subj_id = func_subject_names{iSub};
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
            if flat_mode
                cand_dirs = {func_root};
            else
                cand_dirs = generate_candidates(orig_dir, subj_id, func_root, func_subfolder_rel, subject_paths);
            end
            
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

                if contains_gzip_nifti(cand)
                    try, close(f); catch, end
                    reject_compressed_functional();
                    return;
                end
                
                if flat_mode
                    sid_pattern = [regexptranslate('escape',lower(subj_id)) '(?![a-z0-9])'];
                    keep = cellfun(@(name)~isempty(regexp(lower(name),sid_pattern,'once')),{cand.name});
                    cand = cand(keep);
                    if flat_is3D
                        cand = match_flat_3D(cand,flat_groups,flat_offset(iSub)+g);
                    else
                        cand = match_shared_dir_4D(cand,flat_groups,flat_offset(iSub)+g);
                    end
                else
                    cand = match_shared_dir_4D(cand,groups,g);
                end
                
                if ~isempty(cand) && numel(cand) > 1 && numel(cand) ~= numel(scan_idx)
                    fprintf(2,'TMFC: Ignoring %d files in %s (expected %d scans for this run).\n',numel(cand),td,numel(scan_idx));
                    cand = [];
                end
                if ~isempty(cand)
                    target_dir = td;
                    break;
                end
            end

            % If still empty, do a bounded BFS under the subject's FUNC root,
            % ranking hits by overlap with the STAT remainder (session/run hint).
            if isempty(cand)
                subj_root = fullfile(func_root,subj_id);
                rr_hint   = split_parts(remainder_under_subject(orig_dir, subj_id));

                if user_changed_subf && ~isempty(func_subfolder_rel)
                    subj_root = fullfile(subj_root,func_subfolder_rel);
                    if ~isempty(rr_hint)
                        rr_hint = rr_hint(end);
                    end
                end

                td = bfs_find_dir_with_pattern(subj_root, dir_filter, 3, rr_hint);
                if ~isempty(td)
                    fprintf('BFS found: %s | pattern: %s\n', td, dir_filter);
                    cand = dir(fullfile(td, dir_filter));
                    if ~isempty(cand)
                        cand = cand(~[cand.isdir]);
                        names = {cand.name};
                        is_hdr = endsWith(lower(names), '.hdr');
                        cand(is_hdr) = [];
                    end
                    if contains_gzip_nifti(cand)
                        try, close(f); catch, end
                        reject_compressed_functional();
                        return;
                    end
                    cand = match_shared_dir_4D(cand,groups,g);
                    if ~isempty(cand) && numel(cand) > 1 && numel(cand) ~= numel(scan_idx)
                        fprintf(2,'TMFC: Ignoring %d files in %s (expected %d scans for this run).\n', ...
                            numel(cand),td,numel(scan_idx));
                        cand = [];
                    end
                    if ~isempty(cand)
                        target_dir = td;
                    end
                end
            end

            % Fallback to original SPM folder (only if the user did NOT change root/subfolder)
            orig_parts = regexp(orig_dir,'[\\/]+','split');
            if isempty(cand) && (~user_changed_root && ~user_changed_subf) && ...
                    (any(strcmpi(subj_id,orig_parts)) || nSub == 1)
                fprintf('Fallback to original SPM folder: %s | pattern: %s\n', orig_dir, dir_filter);
                cand = dir(fullfile(orig_dir, dir_filter));
                if ~isempty(cand)
                    cand = cand(~[cand.isdir]);
                    names = {cand.name};
                    is_hdr = endsWith(lower(names), '.hdr');
                    cand(is_hdr) = [];
                end

                if contains_gzip_nifti(cand)
                    try, close(f); catch, end
                    reject_compressed_functional();
                    return;
                end
                cand = match_shared_dir_4D(cand,groups,g);
                if ~isempty(cand) && numel(cand) > 1 && numel(cand) ~= numel(scan_idx)
                    fprintf(2,'TMFC: Ignoring %d files in %s (expected %d scans for this run).\n', ...
                        numel(cand),orig_dir,numel(scan_idx));
                    cand = [];
                end
                if ~isempty(cand)
                    target_dir = orig_dir;
                end
            end

            if ~isempty(cand)
                % sort by name (assumes zero-padded numbering; common for NIfTI series)
                if flat_mode && flat_is3D
                    names = {cand.name}';  % Already sorted by volume number
                else
                    names = sort({cand.name}');
                end

                unsm_files = cellfun(@(z) fullfile(target_dir,z), names, 'UniformOutput', false);

                % Do not silently reuse the same functional file for two
                % different groups from this subject's SPM design.
                reused = false;
                for prev = 1:numel(out_groups)
                    old_files = out_groups(prev).unsm_files;
                    for q = 1:numel(unsm_files)
                        if any(strcmpi(unsm_files{q},old_files))
                            reused = true;
                            break;
                        end
                    end
                    if reused, break; end
                end
                if reused
                    fprintf(2,'TMFC: The same functional image was matched to multiple runs for subject %s.\n',subj_id);
                    preview_lines{end+1,1} = sprintf('   [%02d] [duplicate images across runs]',g);
                    continue;
                end

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
        if contains_gzip_nifti({SPM.xY.VY.fname})
            try, close(fpr1); catch, end
            reject_compressed_functional();
            return;
        end
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
        for jSub = 1:numel(SPM_paths)
            SPM = load(SPM_paths{jSub}).SPM;
            if contains_gzip_nifti({SPM.xY.VY.fname})
                reject_compressed_functional();
                return;
            end
        end
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

    for iSub = 1:numel(unsm_index)
        if ~isfield(unsm_index(iSub),'groups')
            continue;
        end
        for g = 1:numel(unsm_index(iSub).groups)
            if contains_gzip_nifti(unsm_index(iSub).groups(g).unsm_files)
                try, close(f3); catch, end
                reject_compressed_functional();
                return;
            end
        end
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

            if numel(unsmf) > 1 && numel(unsmf) ~= numel(scan_idx)
                fprintf(2,'TMFC: Functional series length mismatch for subject %d, group %d.\n',jSub,g);
                continue;
            end

            if numel(unsmf) == 1
                % 4D file
                file4D = unsmf{1};
                % Validate requested volume indices against the actual NIfTI header
                try
                    nVol = numel(spm_vol(file4D));
                catch ME
                    fprintf(2,'TMFC: Cannot read functional file %s: %s\n',file4D,ME.message);
                    continue;
                end
                requested = arrayfun(@(k) SPM.xY.VY(k).n(1), scan_idx);
                if any(~isfinite(requested) | requested < 1 | ...
                        requested ~= floor(requested) | requested > nVol)
                    fprintf(2,'TMFC: Invalid volume indices in %s (available: %d; requested: %d to %d).\n', ...
                        file4D,nVol,min(requested),max(requested));
                    continue;
                end
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
                if any(strcmpi(fnames{k},fnames(1:k-1)))
                    fprintf(2,'TMFC: Reused functional volume for subject %d: %s\n', ...
                        jSub,fnames{k});
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
% Reject compressed functional NIfTI (not supported downstream by denoise)
% -------------------------------------------------------------------------
function tf = contains_gzip_nifti(paths)
    if isempty(paths)
        tf = false;
        return;
    end
    if isstruct(paths), paths = {paths.name}; end
    if ischar(paths) || isstring(paths), paths = cellstr(paths); end
    tf = any(cellfun(@(p) ~isempty(regexpi(p,'\.nii\.gz(,\d+)?$','once')),paths));
end

function reject_compressed_functional()
    func_paths = [];
    unsm_index = struct([]);
    no_files = {};
    preserve_spm_paths = false;
    spm_first_images = {};
    set(SF_MW_LB1,'String',{},'Value',[]);
    message = ['Compressed functional NIfTI files (*.nii.gz) are not supported ' ...
               'by TMFC_denoise. Decompress them to *.nii before selecting ' ...
               'or preserving functional image paths.'];
    fprintf(2,'TMFC: %s\n',message);
    errordlg(message,'Unsupported functional image format','modal');
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
        '   filter (e.g., *war*.nii, *wr*.nii, or *preproc*.nii) to match all fMRI images.'
        ''
        '   Supported: *.nii (3D/4D), *.img/*.hdr (3D).'
        '   NOT supported: compressed functional *.nii.gz. Decompress to *.nii first.' 
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
        '   SHARED FLAT FOLDER (without subject/run subfolders):'
        ''
        '   Select the shared folder as Parent folder.'
        '   Leave FUNC subfolder as "Not selected".'
        '   Enter the filename filter and click Apply text filter.'
        ''
        '   Supported layouts:'
        '   - One 4D file per run.'
        '   - One numbered 3D file per scan (e.g., run-01_0001.nii).'
        ''
        '   All selected files must use the same layout (3D or 4D).'
        '   Mixed 3D/4D layouts are not supported.'
        '   SPM.mat must reference 4D run files.'
        ''
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
    func_subj_name = subj_id; % Already resolved and verified in apply_filter

    base_rel = sanitize_base_rel(func_subfolder_rel, func_root, subject_paths, func_subj_name);

    remainder = remainder_under_subject(orig_dir, subj_id);

    br = split_parts(base_rel);
    rr = split_parts(remainder);

    k = common_prefix_len(br, rr);
    tail = rr(k+1:end);

    C1 = fullfile(func_root, func_subj_name, br{:}, tail{:});
    if isempty(br)
        C2 = fullfile(func_root, func_subj_name, rr{:});
    else
        C2 = '';
    end
    C3 = fullfile(func_root, func_subj_name, br{:});

    rr2 = strip_stat_tokens(rr);
    k2 = common_prefix_len(br, rr2);
    tail2 = rr2(k2+1:end);
    C4 = fullfile(func_root, func_subj_name, br{:}, tail2{:});

    cand_dirs = unique_nonempty({C1,C2,C3,C4});
end

% Exact subject-folder matching based on individual subject paths
function name = resolve_func_subject_name(root_dir,iSub)
    name = '';
    if ~exist(root_dir,'dir'), return; end

    d = dir(root_dir);
    d = d([d.isdir]);
    names = setdiff({d.name},{'.','..'});
    parts = regexp(regexprep(strtrim(subject_paths{iSub}),'[\\/]+$',''),'[\\/]+','split');

    for k = numel(parts):-1:1
        id = parts{k};
        if isempty(id), continue; end
        hit = find(strcmpi(id,names));
        if numel(hit) ~= 1, continue; end

        shared = false;
        for jSub = 1:numel(subject_paths)
            if jSub == iSub, continue; end
            other_parts = regexp(regexprep(strtrim(subject_paths{jSub}),'[\\/]+$',''),'[\\/]+','split');
            if any(strcmpi(id,other_parts))
                shared = true;
                break;
            end
        end
        if ~shared
            name = names{hit};
            return;
        end
    end

    % Fallback: match subject names with arbitrary prefixes/suffixes.
    % Require a complete name match with non-alphanumeric boundaries.
    src_name = parts{end};
    matches = false(1,numel(names));
    for j = 1:numel(names)
        dst_name = names{j};
        src_pattern = ['(?<![a-z0-9])' regexptranslate('escape',src_name) '(?![a-z0-9])'];
        dst_pattern = ['(?<![a-z0-9])' regexptranslate('escape',dst_name) '(?![a-z0-9])'];
        matches(j) = ~isempty(regexpi(dst_name,src_pattern,'once')) || ~isempty(regexpi(src_name,dst_pattern,'once'));
    end
    idx = find(matches);
    if numel(idx) == 1
        name = names{idx};
        fprintf('TMFC: Matched subject folder "%s" to "%s".\n',src_name,name);
    elseif numel(idx) > 1
        fprintf(2,'TMFC: Ambiguous subject folder match for "%s" under %s.\n',src_name,root_dir);
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
    % Collect all hits, then rank by overlap with rr_hint (component LCP), then shorter depth
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

    % Rank hits by common-prefix with rr_hint (relative to root_dir), then by smaller depth, then lexicographic
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

    % Choose only if the highest-ranked directory is unambiguous
    [~, ord] = sortrows([(-scores(:)) depths(:)], [1 2]);
    if numel(ord) > 1 && scores(ord(1)) == scores(ord(2)) && ...
            depths(ord(1)) == depths(ord(2))
        fprintf(2,'TMFC: Ambiguous functional directory match under %s. Select a more specific folder.\n',root_dir);
        return;
    end
    best = hits{ord(1)};
end

% -------------------------------------------------------------------------
uiwait(SF_MW);
delete(SF_MW);
end
