function [ROI_paths] = tmfc_select_subject_ROIs_GUI(tmfc,ROI_set_name,nROI_expected)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI to select subject-specific ROI binary images.
%
% First, select the parent folder that contains the subject folders with
% ROI subfolders. By default, the parent folder is determined from the
% selected first-level SPM.mat files.
%
% Then select the ROI subfolder for the first subject and apply a text
% filter (e.g., *.nii) to select ROI images. For automatic selection, the
% same ROI filenames must exist for all subjects.
%
% Alternatively, ROI images can be selected manually for each subject.
% In this case, filenames may differ, but the same number of ROIs must be
% selected for every subject in corresponding ROI order.
%
% Output:
%   ROI_paths{iSub,jROI} - Path to j-th ROI for i-th subject 
%
% Optional inputs:
%   ROI_set_name   - ROI set name displayed in the GUI window
%   nROI_expected  - Required number of ROIs per subject
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin < 2
    ROI_set_name = '';
end

if nargin < 3
    nROI_expected = [];
end

if ~isfield(tmfc,'subjects') || isempty(tmfc.subjects)
    error('No subjects are present in the TMFC project.');
end

ROI_paths = {};
txt_filter = '';
ROI_subfolder_full = '';
ROI_subfolder_rel = '';
no_file = {};

nSub = length(tmfc.subjects);

% Get SPM directories
SPM_dirs = cell(nSub,1);
for iSub = 1:nSub
    SPM_dirs{iSub} = fileparts(tmfc.subjects(iSub).path);
end

% Determine common parent folder
ROI_root = SPM_dirs{1};

while true
    root_sep = [ROI_root filesep];
    common_root = 1;

    for iSub = 1:nSub
        if ~strcmpi(SPM_dirs{iSub},ROI_root) && ...
           ~strncmpi(SPM_dirs{iSub},root_sep,numel(root_sep))
            common_root = 0;
            break;
        end
    end

    if common_root
        break;
    end

    parent = fileparts(ROI_root);

    if isempty(parent) || strcmp(parent,ROI_root)
        break;
    end

    ROI_root = parent;
end

% Subject folders are resolved from their own SPM paths against the
% selected ROI parent folder. The SPM paths may have different ancestors.

% -------------------------------------------------------------------------
% GUI elements
% -------------------------------------------------------------------------
GUI_name = 'Select subject-specific ROI images';

if ~isempty(ROI_set_name)
    GUI_name = [GUI_name ': ' ROI_set_name];
end

ROI_MW = figure('Name',GUI_name,'NumberTitle','off','Units','normalized',...
    'Position',[0.30 0.22 0.45 0.60],'MenuBar','none','ToolBar','none','color','w',...
    'CloseRequestFcn',@ROI_MW_exit);

if isempty(nROI_expected)
    ROI_S1_str = {'Select corresponding ROI binary images for all subjects.'};
else
    ROI_S1_str = {['Select ' num2str(nROI_expected) ' corresponding ROI binary images for each subject.']};
end
ROI_txt_1 = uicontrol(ROI_MW,'Style','text','String',ROI_S1_str,'Units','normalized',...
    'Position',[0.03 0.92 0.95 0.05],'fontunits','normalized','FontSize',0.48,...
    'HorizontalAlignment','left','backgroundcolor','w');

% Button: Select parent folder
ROI_MW_S0 = uicontrol(ROI_MW,'Style','pushbutton',...
    'String','Select parent folder (contains subject folders)',...
    'TooltipString','Folder that contains subject folders with subject-specific ROI images.',...
    'Units','normalized','Position',[0.025 0.82 0.41 0.080],...
    'FontUnits','normalized','FontSize',0.295,...
    'callback',@select_ROI_root);

% Box panel: Parent folder
ROI_MW_S0_panel = uipanel(ROI_MW,'Units','normalized',...
    'Position',[0.45 0.823 0.525 0.076],...
    'HighlightColor',[0.78 0.78 0.78],'BorderType','line',...
    'backgroundcolor','w');

% Box text: Parent folder
ROI_MW_S0_txt = uicontrol('Parent',ROI_MW_S0_panel,'Style','text',...
    'String',ROI_root,'Units','normalized',...
    'Position',[0.03 0.05 0.94 0.64],...
    'FontUnits','points','FontSize',9,...
    'HorizontalAlignment','center','backgroundcolor','w',...
    'ForegroundColor',[0 0 0],'TooltipString',ROI_root);

% Button: Select ROI subfolder
ROI_MW_S1 = uicontrol(ROI_MW,'Style','pushbutton',...
    'String','Select the ROI subfolder for the first subject',...
    'Units','normalized','Position',[0.025 0.73 0.41 0.080],...
    'FontUnits','normalized','FontSize',0.295,...
    'callback',@select_subfolder);

% Box panel: ROI subfolder
ROI_MW_S1_panel = uipanel(ROI_MW,'Units','normalized',...
    'Position',[0.45 0.733 0.525 0.076],...
    'HighlightColor',[0.78 0.78 0.78],'BorderType','line',...
    'backgroundcolor','w');

% Box text: ROI subfolder
ROI_MW_S1_txt = uicontrol('Parent',ROI_MW_S1_panel,'Style','text',...
    'String','Not selected','ForegroundColor','red',...
    'Units','normalized','Position',[0.03 0.09 0.94 0.64],...
    'FontUnits','normalized','FontSize',0.50,...
    'HorizontalAlignment','center','backgroundcolor','w');

% Button: Text filter
ROI_MW_S2 = uicontrol(ROI_MW,'Style','pushbutton',...
    'String','Apply text filter for ROI images:',...
    'Units','normalized','Position',[0.025 0.64 0.41 0.080],...
    'FontUnits','normalized','FontSize',0.295,...
    'callback',@apply_filter);

% Edit: Text filter
ROI_MW_S2_E = uicontrol(ROI_MW,'Style','Edit','String','*.nii*',...
    'Units','normalized','Position',[0.45 0.64 0.525 0.080],...
    'FontUnits','normalized','FontSize',0.32,'backgroundcolor','w');

% List of ROI files
ROI_MW_LB1 = uicontrol(ROI_MW,'Style','listbox','String','','Max',100000,...
    'Units','normalized','Position',[0.025 0.25 0.95 0.37],...
    'FontUnits','points','FontSize',10,'Value',[]);

% Button: Select all ROI images manually
ROI_MW_S3 = uicontrol(ROI_MW,'Style','pushbutton',...
    'String','Select ROI images manually for each subject',...
    'Units','normalized','Position',[0.0245 0.15 0.475 0.080],...
    'FontUnits','normalized','FontSize',0.30,...
    'callback',@add_images);

% Button: Clear all
ROI_MW_S4 = uicontrol(ROI_MW,'Style','pushbutton','String','Clear all',...
    'Units','normalized','Position',[0.51 0.15 0.466 0.080],...
    'FontUnits','normalized','FontSize',0.30,...
    'callback',@clear_paths);

% Button: OK
ROI_MW_OK = uicontrol(ROI_MW,'Style','pushbutton','String','OK',...
    'Units','normalized','Position',[0.300 0.045 0.199 0.078],...
    'FontUnits','normalized','FontSize',0.30,...
    'callback',@export_paths);

% Button: Help
ROI_MW_HELP = uicontrol(ROI_MW,'Style','pushbutton','String','Help',...
    'Units','normalized','Position',[0.510 0.045 0.200 0.078],...
    'FontUnits','normalized','FontSize',0.30,...
    'callback',@open_help);

movegui(ROI_MW,'center');

% -------------------------------------------------------------------------
% Close GUI
% -------------------------------------------------------------------------
function ROI_MW_exit(~,~)
    ROI_paths = {};
    fprintf(2,'Subject-specific ROI images are not selected.\n');
    uiresume(ROI_MW);
end

% -------------------------------------------------------------------------
% Select parent folder
% -------------------------------------------------------------------------
function select_ROI_root(~,~)
    tmp = deblank(spm_select(1,'dir','Select parent folder (contains subject folders)',{},ROI_root,'..'));

    if ~isempty(tmp)
        ROI_root = tmp;

        set(ROI_MW_S0_txt,'String',ROI_root,...
            'TooltipString',ROI_root,...
            'ForegroundColor',[0 0 0],...
            'HorizontalAlignment','center');

        ROI_paths = {};
        no_file = {};
        ROI_subfolder_full = '';
        ROI_subfolder_rel = '';

        set(ROI_MW_S1_txt,'String','Not selected',...
            'ForegroundColor','red',...
            'HorizontalAlignment','center');

        set(ROI_MW_LB1,'String','');
    end
end

% -------------------------------------------------------------------------
% Select ROI subfolder for the first subject
% -------------------------------------------------------------------------
function select_subfolder(~,~)

    set(ROI_MW_S1_txt,'String','Not selected',...
        'ForegroundColor','red',...
        'HorizontalAlignment','center');

    start_dir = resolve_subject_base(1);

    if ~exist(start_dir,'dir')
        start_dir = ROI_root;
    end

    sel_dir = deblank(spm_select(1,'dir',...
        'Select ROI subfolder for the first subject',{},start_dir,'..'));

    if ~isempty(sel_dir)
        ROI_subfolder_full = sel_dir;
        update_rel_display();
        ROI_paths = {};
        no_file = {};
        set(ROI_MW_LB1,'String','');
    else
        fprintf(2,'Please select the ROI subfolder for the first subject.\n');
    end
end

% -------------------------------------------------------------------------
% Compute relative ROI subfolder path and display it
% -------------------------------------------------------------------------
function update_rel_display()

    if isempty(ROI_subfolder_full) || ~exist(ROI_subfolder_full,'dir')
        set(ROI_MW_S1_txt,'String','Not selected',...
            'ForegroundColor','red',...
            'HorizontalAlignment','center');
        ROI_subfolder_rel = '';
        return;
    end

    base_first = resolve_subject_base(1);

    if strcmpi(ROI_subfolder_full,base_first)
        ROI_subfolder_rel = '';
        disp_string = '<subject folder>';
    else
        base_first_sep = [base_first filesep];

        if strncmpi(ROI_subfolder_full,base_first_sep,numel(base_first_sep))
            ROI_subfolder_rel = ROI_subfolder_full(numel(base_first_sep)+1:end);
            disp_string = ROI_subfolder_rel;
        else
            [~,ROI_subfolder_rel] = fileparts(ROI_subfolder_full);
            disp_string = ROI_subfolder_rel;
        end
    end

    set(ROI_MW_S1_txt,'String',disp_string,...
        'ForegroundColor',[0 0 0],...
        'HorizontalAlignment','center');
end

% -------------------------------------------------------------------------
% Apply text filter and generate ROI paths
% -------------------------------------------------------------------------
function apply_filter(~,~)

    if isempty(ROI_subfolder_full)
        fprintf(2,'Please select the ROI subfolder for the first subject before applying text filter.\n');
        return;
    end

    txt_filter = get(ROI_MW_S2_E,'String');
    txt_filter = strrep(txt_filter,' ','');

    if isempty(txt_filter)
        fprintf(2,'Filter is empty or invalid. Please re-enter.\n');
        return;
    end

    f = msgbox('Selecting subject-specific ROI images. Please wait...');

    ROI_paths = {};
    no_file = {};
    set(ROI_MW_LB1,'String','','Value',[]);

    % Match each SPM subject to a distinct ROI subject folder
    subject_bases = cell(nSub,1);
    for iSub = 1:nSub
        subject_bases{iSub} = resolve_subject_base(iSub);
        if isempty(subject_bases{iSub})
            fprintf(2,'TMFC: Cannot match subject %d (SPM: %s) to a folder in %s.\n',iSub,SPM_dirs{iSub},ROI_root);
            fprintf(2,'TMFC: Select the ROI images manually or use matching subject folder names.\n');
            try, close(f); catch, end
            return;
        end
    end

    subject_bases_lower = cellfun(@lower,subject_bases,'UniformOutput',false);
    if numel(unique(subject_bases_lower)) ~= nSub
        fprintf(2,'TMFC: Two or more subjects match the same ROI folder. Automatic selection canceled.\n');
        try, close(f); catch, end
        return;
    end

    % Find ROI filenames for the first subject
    first_base = subject_bases{1};
    first_dir = build_search_dir(first_base);

    fprintf('Searching in: %s | pattern: %s\n',first_dir,txt_filter);

    ROI_files = dir(fullfile(first_dir,txt_filter));
    ROI_files = ROI_files(~[ROI_files.isdir]);

    if isempty(ROI_files)
        fprintf(2,'No ROI images matched the filter "%s" within "%s".\n',txt_filter,first_dir);
        try
            close(f);
        catch
        end
        return;
    end

    ROI_names = sort({ROI_files.name});
    nROI = length(ROI_names);

    % Check number of ROIs against existing ROI set
    if ~isempty(nROI_expected) && nROI ~= nROI_expected
        fprintf(2,'Please select exactly %d ROI images for each subject. %d ROI images were found.\n',nROI_expected,nROI);
        try
            close(f);
        catch
        end
        return;
    end

    ROI_paths = cell(nSub,nROI);

    % Find the same ROI filenames for all subjects
    for iSub = 1:nSub

        subj_base = subject_bases{iSub};
        search_dir = build_search_dir(subj_base);

        fprintf('Searching in: %s | pattern: %s\n',search_dir,txt_filter);

        for jROI = 1:nROI
            ROI_file = fullfile(search_dir,ROI_names{jROI});

            if exist(ROI_file,'file')
                ROI_paths{iSub,jROI} = ROI_file;
            else
                no_file = vertcat(no_file,{ROI_file});
            end
        end
    end

    % Display selected paths
    display_paths = reshape(ROI_paths.',[],1);
    display_paths = display_paths(~cellfun('isempty',display_paths));
    set(ROI_MW_LB1,'String',display_paths);

    if isempty(no_file)
        fprintf('%d ROI(s) found for each of %d subjects.\n',nROI,nSub);
    else
        fprintf(2,'%d subject-specific ROI image(s) are missing.\n',length(no_file));
    end

    try
        close(f);
    catch
    end
end

% -------------------------------------------------------------------------
% Clear ROI paths
% -------------------------------------------------------------------------
function clear_paths(~,~)

    if isempty(ROI_paths)
        disp('No images to remove.');
    else
        ROI_paths = {};
        no_file = {};
        set(ROI_MW_LB1,'String','','Value',[]);
        disp('All images have been removed.');
    end
end

% -------------------------------------------------------------------------
% Select ROI images manually for each subject
% -------------------------------------------------------------------------
function add_images(~,~)

    ROI_paths = {};
    no_file = {};
    nROI = [];

    for iSub = 1:nSub

        start_dir = resolve_subject_base(iSub);
        if isempty(start_dir) || ~exist(start_dir,'dir')
            start_dir = ROI_root;
        end

        if ~isempty(ROI_subfolder_rel)
            tmp_dir = fullfile(start_dir,ROI_subfolder_rel);
            if exist(tmp_dir,'dir')
                start_dir = tmp_dir;
            end
        end

        sel = spm_select(inf,'image',['Select ROI images for subject ' num2str(iSub) ' of ' num2str(nSub) ' in corresponding ROI order'],{},start_dir);

        if isempty(sel)
            ROI_paths = {};
            fprintf(2,'ROI images were not selected for subject %d.\n',iSub);
            set(ROI_MW_LB1,'String','');
            return;
        end

        sub_paths = cellstr(sel);

        for jROI = 1:length(sub_paths)
            sub_paths{jROI} = regexprep(deblank(sub_paths{jROI}),',\d+$','');
        end

        if iSub == 1
            nROI = length(sub_paths);
            % Check number of ROIs against existing ROI set
            if ~isempty(nROI_expected) && nROI ~= nROI_expected
                ROI_paths = {};
                fprintf(2,'Please select exactly %d ROI images for each subject. %d ROI images were selected.\n',nROI_expected,nROI);
                set(ROI_MW_LB1,'String','');
                return;
            end
            ROI_paths = cell(nSub,nROI);
        else
            if length(sub_paths) ~= nROI
                ROI_paths = {};
                fprintf(2,'The same number of ROI images must be selected for every subject.\n');
                set(ROI_MW_LB1,'String','');
                return;
            end
        end

        for jROI = 1:nROI
            ROI_paths{iSub,jROI} = sub_paths{jROI};
        end
    end

    display_paths = reshape(ROI_paths.',[],1);
    set(ROI_MW_LB1,'String',display_paths);

    fprintf('%d ROI(s) selected for each of %d subjects.\n',nROI,nSub);
end

% -------------------------------------------------------------------------
% Export ROI paths
% -------------------------------------------------------------------------
function export_paths(~,~)

    if isempty(ROI_paths)
        fprintf(2,'No ROI images selected, please try again.\n');
        return;
    end

    if ~isempty(no_file)
        missing_file_GUI(no_file);
        return;
    end

    if size(ROI_paths,1) ~= nSub || any(cellfun('isempty',ROI_paths(:)))
        fprintf(2,'ROI images are missing for one or more subjects.\n');
        return;
    end

    if ~isempty(nROI_expected) && size(ROI_paths,2) ~= nROI_expected
        fprintf(2,'Please select exactly %d ROI images for each subject.\n',nROI_expected);
        return;
    end

    fprintf('Subject-specific ROI images have been selected: %d ROI(s) for %d subjects.\n',size(ROI_paths,2),nSub);

    uiresume(ROI_MW);
end

% -------------------------------------------------------------------------
% Warning window: missing ROI images
% -------------------------------------------------------------------------
function missing_file_GUI(file_missing)

    ROI_WW = figure('Name','Missing ROI images','NumberTitle','off',...
        'Units','normalized','Position',[0.32 0.30 0.35 0.28],...
        'color','w','MenuBar','none','ToolBar','none',...
        'WindowStyle','Modal');

    ROI_WW_LB = uicontrol(ROI_WW,'Style','listbox',...
        'String',file_missing,'Max',inf,...
        'Units','normalized','Position',[0.032 0.250 0.940 0.520],...
        'FontUnits','points','FontSize',10,'Value',[]);

    ROI_WW_S1 = uicontrol(ROI_WW,'Style','text',...
        'String','Warning: ROI images are missing for one or more subjects:',...
        'Units','normalized','Position',[0.15 0.820 0.720 0.095],...
        'FontUnits','points','FontSize',11,...
        'HorizontalAlignment','center','backgroundcolor','w');

    ROI_WW_close = uicontrol(ROI_WW,'Style','pushbutton',...
        'String','OK','Units','normalized',...
        'Position',[0.415 0.06 0.180 0.120],...
        'FontUnits','normalized','FontSize',0.30,...
        'callback',@close_ROI_WW);

    movegui(ROI_WW,'center');
    uiwait(ROI_WW);

    function close_ROI_WW(~,~)
        close(ROI_WW);
    end
end

% -------------------------------------------------------------------------
% Help window
% -------------------------------------------------------------------------
function open_help(~,~)

    help_text = {
        ''
        'Select subject-specific ROI binary images.'
        ''
        'First, select the parent folder containing all subject folders.'
        'Then select the ROI subfolder for the first subject and apply a text'
        'filter to identify all ROI images.'
        ''
        'For automatic selection, the same ROI filenames must exist for every subject.'
        ''
        'Example:'
        ''
        'project/  <-------------------------------- [Select parent folder]'
        '├─ sub-01/'
        '│  └─ ROIs/  <----------- [Select ROI subfolder for first subject]'
        '│     ├─ ROI_1.nii  <------------------------- [Apply text filter]'
        '│     ├─ ROI_2.nii'
        '│     └─ ROI_3.nii'
        '├─ sub-02/'
        '│  └─ ROIs/'
        '│     ├─ ROI_1.nii'
        '│     ├─ ROI_2.nii'
        '│     └─ ROI_3.nii'
        '└─ sub-03/ ...'
        ''
        'Alternatively, ROI images can be selected manually for each subject.'
        'In this case, filenames may differ, but the same number of ROIs must be'
        'selected for every subject in corresponding ROI order.'
    };

    ROI_HELP = figure('Name','Help','NumberTitle','off',...
        'Units','normalized','Position',[0.30 0.20 0.45 0.60],...
        'MenuBar','none','ToolBar','none','Color','w',...
        'WindowStyle','Modal');

    ROI_HELP_txt = uicontrol(ROI_HELP,'Style','edit',...
        'String',help_text,...
        'Units','normalized','Position',[0.05 0.14 0.90 0.80],...
        'BackgroundColor','w','Enable','inactive',...
        'Max',2,'Min',0,...
        'HorizontalAlignment','left',...
        'FontName','Courier New',...
        'FontUnits','normalized','FontSize',0.032);

    ROI_HELP_OK = uicontrol(ROI_HELP,'Style','pushbutton',...
        'String','OK',...
        'Units','normalized','Position',[0.40 0.04 0.20 0.07],...
        'FontUnits','normalized','FontSize',0.35,...
        'callback',@(s,e) close(ROI_HELP));

    movegui(ROI_HELP,'center');
end

% -------------------------------------------------------------------------
% Resolve corresponding subject folder within selected ROI root
% -------------------------------------------------------------------------
function subj_base = resolve_subject_base(iSub)

    subj_base = '';
    if ~exist(ROI_root,'dir')
        return;
    end

    % Search for an exact subject-folder name among the components of this
    % subject's own SPM path, starting with the deepest component
    path_parts = regexp(SPM_dirs{iSub},'[\\/]+','split');
    for k = numel(path_parts):-1:1
        if isempty(path_parts{k})
            continue;
        end
        candidate = fullfile(ROI_root,path_parts{k});
        if exist(candidate,'dir')
            subj_base = candidate;
            return;
        end
    end

    % A single subject may use the ROI root directly
    if nSub == 1
        subj_base = ROI_root;
    end
end

% -------------------------------------------------------------------------
% Build ROI search directory
% -------------------------------------------------------------------------
function search_dir = build_search_dir(subj_base)
    if isempty(ROI_subfolder_rel)
        search_dir = subj_base;
    else
        search_dir = fullfile(subj_base,ROI_subfolder_rel);
    end
end

% -------------------------------------------------------------------------
uiwait(ROI_MW);
delete(ROI_MW);

end
