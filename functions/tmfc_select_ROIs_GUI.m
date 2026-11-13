function [ROI_set] = tmfc_select_ROIs_GUI(tmfc)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for selecting ROI masks. Each ROI is masked separately
% by each subject's individual first-level mask (see SPM.VM). Empty ROIs
% will be removed. The dimensions, orientation, and voxel sizes of selected
% binary ROI images will be adjusted according to the corresponding
% individual first-level masks.
%
% -------------------------------------------------------------------------
% Case 1: Select ROI binary images
% Use binary images that are the same for all subjects. Each ROI will be
% masked separately by each subject's individual first-level mask.
% -------------------------------------------------------------------------
% Case 2: Select subject-specific ROI binary images
% Use different binary ROI images for individual subjects. Each ROI will be
% masked by the corresponding subject's individual first-level mask.
% -------------------------------------------------------------------------
% Case 3: Fixed spheres
% Create spheres that are the same for all subjects. The sphere center
% is fixed. Each sphere will be masked separately by each subject's
% individual first-level mask.
% -------------------------------------------------------------------------
% Case 4: Moving spheres inside fixed spheres
% Create subject-specific spheres. The sphere center is moved to the local
% maximum* inside a fixed sphere of larger radius. Each sphere will be
% masked by the corresponding subject's individual first-level mask.
% -------------------------------------------------------------------------
% Case 5: Moving spheres inside ROI binary images
% Create subject-specific spheres. The sphere center is moved to the local
% maximum* inside a binary image. Each sphere will be masked by the selected
% binary image and the corresponding subject's individual first-level mask.
% -------------------------------------------------------------------------
% (*) - The local maximum is determined using the omnibus F-test with an
%       uncorrected threshold of 0.005 (by default).
%
%
% FORMAT [ROI_set] = tmfc_select_ROIs_GUI(tmfc)
%
% Input:
%   tmfc.subjects.path    - Paths to individual SPM.mat files
%   tmfc.subjects.name    - Subject names within the TMFC project
%   tmfc.project_path     - The path where all results will be saved
%
% Output:
%   ROI_set               - Structure with information about selected ROIs
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% Initial checks
if ~isfield(tmfc,'subjects')
    error('Select subjects.');
elseif strcmp(tmfc.subjects(1).path, '')
    error('Select subjects.');
elseif ~exist(tmfc.subjects(1).path,'file')
    error('SPM.mat file for the first subject does not exist.')
elseif ~isfield(tmfc,'project_path')
    error('Select TMFC project folder.');
end

% Check subject names
if ~isfield(tmfc.subjects,'name')
    for iSub = 1:length(tmfc.subjects)
        tmfc.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
    end
end

% Check session mode
if ~isfield(tmfc,'session_mode')
    session_mode = 'strict';
else
    session_mode = tmfc.session_mode;
end

% Specify ROI set name
ROI_set_name = ROI_set_name_GUI();

if isempty(ROI_set_name)
    ROI_set = [];
    warning('ROIs not selected.'); return;
end

% Check ROI set name uniqueness
existing_set_names = {};
if isfield(tmfc,'ROI_set') && ~isempty(tmfc.ROI_set)
    existing_set_names = [existing_set_names {tmfc.ROI_set.set_name}];
end
if isfield(tmfc,'ROI_set_legacy') && ~isempty(tmfc.ROI_set_legacy)
    existing_set_names = [existing_set_names {tmfc.ROI_set_legacy.set_name}];
end
if any(strcmpi(ROI_set_name,existing_set_names))
    ROI_set = [];
    warning('ROI set name "%s" already exists. Select a different name.',ROI_set_name);
    return;
end

% Specify ROI type
ROI_type = ROI_type_GUI();

if isempty(ROI_type)
    ROI_set = [];
    warning('ROIs not selected.'); return;
end

% Define ROI set
ROI_definition.set_name = ROI_set_name;
ROI_definition.type = ROI_type;
ROI_definition.crop_threshold = [];
ROI_definition.GUI = 1;

switch ROI_type
    % ---------------------------------------------------------------------
    case 'binary_images'
        ROI_paths = spm_select(inf,'image','Select ROI masks',{},pwd);
        if isempty(ROI_paths)
            ROI_set = [];
            warning('ROIs not selected.'); return;
        end

        for iROI = 1:size(ROI_paths,1)
            ROI_path = regexprep(deblank(ROI_paths(iROI,:)),',\d+$','');
            [~, ROI_definition.ROIs(iROI).name, ~] = fileparts(ROI_path);
            ROI_definition.ROIs(iROI).path = ROI_path;
        end

    % ---------------------------------------------------------------------
    case 'subject_specific_binary_images'
        ROI_paths = tmfc_select_subject_ROIs_GUI(tmfc);
        if isempty(ROI_paths)
            ROI_set = [];
            warning('ROIs not selected.'); return;
        end

        for iROI = 1:size(ROI_paths,2)
            ROI_names = cell(size(ROI_paths,1),1);
            for jSub = 1:size(ROI_paths,1)
                [~, ROI_names{jSub}, ~] = fileparts(ROI_paths{jSub,iROI});
                ROI_definition.ROIs(iROI).path(jSub).subjects = ROI_paths{jSub,iROI};
            end
            % Use common filename if it is identical across subjects
            if all(strcmp(ROI_names,ROI_names{1}))
                ROI_definition.ROIs(iROI).name = ROI_names{1};
            else
                ROI_definition.ROIs(iROI).name = ['ROI_' num2str(iROI)];
            end          
        end
    
    % ---------------------------------------------------------------------
    case 'fixed_spheres'
        ROI_FS = select_ROIs_case_2();
        if isempty(ROI_FS)
            ROI_set = [];
            warning('ROIs not selected.'); return;
        end

        for iROI = 1:size(ROI_FS,2)
            ROI_definition.ROIs(iROI).name = ROI_FS(iROI).ROI_name;
            ROI_definition.ROIs(iROI).X = ROI_FS(iROI).X;
            ROI_definition.ROIs(iROI).Y = ROI_FS(iROI).Y;
            ROI_definition.ROIs(iROI).Z = ROI_FS(iROI).Z;
            ROI_definition.ROIs(iROI).radius = ROI_FS(iROI).radius;
        end

    % ---------------------------------------------------------------------
    case 'moving_spheres_inside_fixed_spheres'
        ROI_MS = select_ROIs_case_3();
        if isempty(ROI_MS)
            ROI_set = [];
            warning('ROIs not selected.'); return;
        end

        for iROI = 1:size(ROI_MS,2)
            ROI_definition.ROIs(iROI).name = ROI_MS(iROI).ROI_name;
            ROI_definition.ROIs(iROI).X = ROI_MS(iROI).X;
            ROI_definition.ROIs(iROI).Y = ROI_MS(iROI).Y;
            ROI_definition.ROIs(iROI).Z = ROI_MS(iROI).Z;
            ROI_definition.ROIs(iROI).moving_radius = ROI_MS(iROI).moving_radius;
            ROI_definition.ROIs(iROI).fixed_radius = ROI_MS(iROI).fixed_radius;
        end

    % ---------------------------------------------------------------------
    case 'moving_spheres_inside_binary_images'
        ROI_paths = spm_select(inf,'image','Select ROI masks',{},pwd);
        if isempty(ROI_paths)
            ROI_set = [];
            warning('ROIs not selected.'); return;
        end

        radius_vector = select_ROIs_case_4(size(ROI_paths,1));
        if isempty(radius_vector)
            ROI_set = [];
            warning('ROIs not selected.'); return;
        end

        for iROI = 1:size(ROI_paths,1)
            ROI_path = regexprep(deblank(ROI_paths(iROI,:)),',\d+$','');
            [~, ROI_definition.ROIs(iROI).name, ~] = fileparts(ROI_path);
            ROI_definition.ROIs(iROI).path = ROI_path;
            ROI_definition.ROIs(iROI).radius = radius_vector(iROI);
        end
end

% Check names before creating any directories or NIfTI files.
% This also catches ROI names imported from MAT/CSV/XLSX/TXT tables.
for iROI = 1:length(ROI_definition.ROIs)
    if ~valid_TMFC_output_name(ROI_definition.ROIs(iROI).name,'ROI')
        ROI_set = [];
        return;
    end
end

% Check ROI name uniqueness
ROI_names = {ROI_definition.ROIs.name};
for iROI = 1:length(ROI_names)-1
    if any(strcmpi(ROI_names{iROI},ROI_names(iROI+1:end)))
        ROI_set = [];
        warning('ROI name "%s" is duplicated. ROI names within an ROI set must be unique.',ROI_names{iROI});
        return;
    end
end

% Specify F-contrast
if strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images')

    [Fthresh, Fmask] = tmfc_F_contrast_GUI();

    if isempty(Fthresh)
        ROI_set = [];
        warning('ROIs not selected.'); return;
    end

    [conditions] = tmfc_conditions_GUI(tmfc.subjects(1).path,1,session_mode);

    if ~isstruct(conditions)
        ROI_set = [];
        warning('ROIs not selected.'); return;
    end

    ROI_definition.F.conditions = conditions;
    ROI_definition.F.threshold = Fthresh;
    ROI_definition.F.mask = Fmask;
end

% Create ROI set
try
    [ROI_set,empty_ROI_list] = tmfc_create_ROI_set(tmfc,ROI_definition);
catch ME
    ROI_set = [];
    h = findall(0,'Type','figure','Tag','TMWWaitbar');
    for iH = 1:numel(h)
        if ishghandle(h(iH))
            delete(h(iH));
        end
    end
    fprintf(2,'\n%s\n',repmat('=',1,30));
    fprintf(2,'    ROI set creation failed\n');
    fprintf(2,'%s\n',repmat('=',1,30));
    fprintf(2,'%s\n\n',getReport(ME,'extended','hyperlinks','off'));
    warning('TMFC:ROICreationFailed','ROI set creation failed: %s',ME.message);
    return;
end

% Display empty ROIs
if ~isempty(empty_ROI_list)
    disp_empty_ROI_list = {};
    for iROI = 1:size(empty_ROI_list,1)
        ROI_string = horzcat('No ',num2str(empty_ROI_list{iROI,1}),': ',empty_ROI_list{iROI,2});
        disp_empty_ROI_list = vertcat(disp_empty_ROI_list, ROI_string);
    end
    remove_empty_ROIs_GUI(disp_empty_ROI_list);
end

% Remove heavily cropped ROIs
if isempty(ROI_set)
    warning('All ROIs are empty. Select different ROIs.');
else
    ROI_set = remove_cropped_ROIs_GUI(ROI_set);
end

% Final check
if ~isstruct(ROI_set) || ~isfield(ROI_set,'set_name') || ~isfield(ROI_set,'ROIs')
    ROI_set = [];
end

end

%% ====================[ Specify ROI set name GUI ]========================
function [ROI_set_name] = ROI_set_name_GUI(~,~)
    
    ROI_set_name = '';

    ROI_set_name_MW = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.62 0.50 0.16 0.14],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none','WindowStyle', 'modal','CloseRequestFcn', @ROI_set_name_MW_EXIT);    
    ROI_set_name_MW_S = uicontrol(ROI_set_name_MW,'Style','text','String', 'Enter a name for the ROI set','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.40,'backgroundcolor',get(ROI_set_name_MW,'color'),'Position',[0.14 0.60 0.700 0.230]);
    ROI_set_name_MW_E = uicontrol(ROI_set_name_MW,'Style','edit','String','','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45,'HorizontalAlignment','left','Position',[0.10 0.44 0.800 0.190]);
    ROI_set_name_MW_OK = uicontrol(ROI_set_name_MW,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45,'Position',[0.10 0.16 0.310 0.180],'callback', @check_ROI_set_name);
    ROI_set_name_MW_HELP = uicontrol(ROI_set_name_MW,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45,'Position',[0.59 0.16 0.310 0.180], 'callback', @ROI_set_name_HW);    
    movegui(ROI_set_name_MW,'center');

    %----------------------------------------------------------------------
    % Close ROI set name GUI
    %----------------------------------------------------------------------
    function ROI_set_name_MW_EXIT(~,~)
    	ROI_set_name = '';
        uiresume(ROI_set_name_MW);
    end
    
    %----------------------------------------------------------------------
    % Check ROI set name
    %----------------------------------------------------------------------
    function check_ROI_set_name(~,~)
        tmp_name = get(ROI_set_name_MW_E, 'String');
        tmp_name = strrep(tmp_name,' ','');
        if ~isempty(tmp_name)
            if ~valid_TMFC_output_name(tmp_name,'ROI set')
                return;
            end
            fprintf('Name of ROI set: %s.\n', tmp_name);
            ROI_set_name = tmp_name; 
            uiresume(ROI_set_name_MW);
        else
            fprintf(2,'Name not entered or invalid, please re-enter.\n');
        end
    end

    %----------------------------------------------------------------------
    % ROI set name: Help window
    %----------------------------------------------------------------------
    function ROI_set_name_HW(~,~)

        help_string = {'First, define a name for the set of ROIs. TMFC results for this ROI set will be stored in:','','"TMFC_project_name\ROI_sets\ROI_set_name"','',...
        'Second, select the ROI type and define one or more ROIs. Each ROI will be masked separately by each subject''s individual first-level mask (see SPM.VM). Empty ROIs will be excluded from further analysis. For binary ROI images, the dimensions, orientation, and voxel sizes will be adjusted according to the corresponding individual first-level masks. Masked ROI images will be stored in subject-specific subfolders within "Masked_ROIs".', ...
        '','Third, exclude heavily cropped ROIs from further analysis, if necessary.','','Note: You can define several ROI sets and switch between them. Push the "ROI_set" button and then push "Add new ROI set". Each time you need to switch between ROI sets push the "ROI_set" button.'};

        if isunix; fontscale = 0.85; else; fontscale = 1; end

        ROI_set_name_HW_MW = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.67 0.31 0.2 0.45],'Resize','off','color','w','MenuBar', 'none','ToolBar','none','Windowstyle','Modal');
        ROI_set_name_HW_MW_S = uicontrol(ROI_set_name_HW_MW,'Style','text','String', help_string,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.0356*fontscale,'HorizontalAlignment', 'left', 'Position',[0.05 0.14 0.89 0.82],'backgroundcolor',get(ROI_set_name_HW_MW,'color'));
        ROI_set_name_HW_MW_OK = uicontrol(ROI_set_name_HW_MW,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45,'Position',[0.34 0.06 0.30 0.06],'callback', @ROI_set_name_HW_MW_close);
        movegui(ROI_set_name_HW_MW,'center');

        function ROI_set_name_HW_MW_close(~,~)
            close(ROI_set_name_HW_MW);
        end
    end

    uiwait(ROI_set_name_MW);
    delete(ROI_set_name_MW);
end

%% ======================[ Select ROI type GUI ]===========================
function [ROI_type] = ROI_type_GUI(~,~)

    select_ROI_type_GUI = figure('Name', 'Select ROIs','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.20 0.300 0.600], 'color', 'w', 'Tag', 'TMFC_Select_ROIs','resize', 'on','WindowStyle','modal', 'CloseRequestFcn', @close_ROI_type);

    sel_ROI_MP1 = uipanel(select_ROI_type_GUI ,'Units', 'normalized','Position',[0.03 0.805 0.94 0.17],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    sel_ROI_MP2 = uipanel(select_ROI_type_GUI ,'Units', 'normalized','Position',[0.03 0.615 0.94 0.17],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    sel_ROI_MP3 = uipanel(select_ROI_type_GUI ,'Units', 'normalized','Position',[0.03 0.425 0.94 0.17],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    sel_ROI_MP4 = uipanel(select_ROI_type_GUI ,'Units', 'normalized','Position',[0.03 0.235 0.94 0.17],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    sel_ROI_MP5 = uipanel(select_ROI_type_GUI ,'Units', 'normalized','Position',[0.03 0.045 0.94 0.17],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');

    txt_1 = {'Use binary ROI images that are the same for all subjects. Each ROI will be masked separately by each subject''s individual first-level mask.'};
    txt_2 = {'Use subject-specific binary ROI images. Each ROI will be masked by the corresponding subject''s individual first-level mask.'};
    txt_3 = {'Create spheres that are the same for all subjects. The sphere center is fixed. Each sphere will be masked separately by each subject''s individual first-level mask.'};
    txt_4 = {'Create subject-specific spheres. The sphere center moves to the local maximum inside a fixed sphere of larger radius. Each sphere will be masked by the corresponding subject''s individual first-level mask.'};
    txt_5 = {'Create subject-specific spheres. The sphere center moves to the local maximum inside a binary image. Each sphere will be masked by the selected binary image and the corresponding subject''s individual first-level mask.'};

    sel_ROI_B1 = uicontrol(select_ROI_type_GUI,'Style', 'pushbutton', 'String', 'ROI binary images (same for all subjects)', 'Units', 'normalized', 'Position', [0.05 0.900 0.90 0.055],'FontUnits','normalized','FontSize',0.33, 'callback', @binary_images);
    sel_ROI_B2 = uicontrol(select_ROI_type_GUI,'Style', 'pushbutton', 'String', 'Subject-specific ROI binary images', 'Units', 'normalized', 'Position', [0.05 0.710 0.90 0.055],'FontUnits','normalized','FontSize',0.33, 'callback', @subject_specific_binary_images);
    sel_ROI_B3 = uicontrol(select_ROI_type_GUI,'Style', 'pushbutton', 'String', 'Fixed spheres', 'Units', 'normalized', 'Position', [0.05 0.520 0.90 0.055],'FontUnits','normalized','FontSize',0.33, 'callback', @fixed_spheres);
    sel_ROI_B4 = uicontrol(select_ROI_type_GUI,'Style', 'pushbutton', 'String', 'Moving spheres inside fixed spheres', 'Units', 'normalized', 'Position', [0.05 0.330 0.90 0.055],'FontUnits','normalized','FontSize',0.33, 'callback', @moving_inside_fixed_spheres);
    sel_ROI_B5 = uicontrol(select_ROI_type_GUI,'Style', 'pushbutton', 'String', 'Moving spheres inside ROI binary images', 'Units', 'normalized', 'Position', [0.05 0.140 0.90 0.055],'FontUnits','normalized','FontSize',0.33, 'callback', @moving_inside_binary_images);
    
    if isunix; fontscale = 0.9; else; fontscale = 1; end

    sel_ROI_txt_1 = uicontrol(select_ROI_type_GUI, 'Style', 'text','String', txt_1,'Units', 'normalized', 'Position',[0.05 0.815 0.90 0.075],'fontunits','normalized', 'fontSize', 0.24*fontscale, 'HorizontalAlignment','left','backgroundcolor','w');
    sel_ROI_txt_2 = uicontrol(select_ROI_type_GUI, 'Style', 'text','String', txt_2,'Units', 'normalized', 'Position',[0.05 0.625 0.90 0.075],'fontunits','normalized', 'fontSize', 0.24*fontscale, 'HorizontalAlignment','left','backgroundcolor','w');
    sel_ROI_txt_3 = uicontrol(select_ROI_type_GUI, 'Style', 'text','String', txt_3,'Units', 'normalized', 'Position',[0.05 0.435 0.90 0.075],'fontunits','normalized', 'fontSize', 0.24*fontscale, 'HorizontalAlignment','left','backgroundcolor','w');
    sel_ROI_txt_4 = uicontrol(select_ROI_type_GUI, 'Style', 'text','String', txt_4,'Units', 'normalized', 'Position',[0.05 0.245 0.90 0.075],'fontunits','normalized', 'fontSize', 0.24*fontscale, 'HorizontalAlignment','left','backgroundcolor','w');
    sel_ROI_txt_5 = uicontrol(select_ROI_type_GUI, 'Style', 'text','String', txt_5,'Units', 'normalized', 'Position',[0.05 0.055 0.90 0.075],'fontunits','normalized', 'fontSize', 0.24*fontscale, 'HorizontalAlignment','left','backgroundcolor','w');
    movegui(select_ROI_type_GUI,'center');
    
    function binary_images(~,~)
        ROI_type = 'binary_images';
        uiresume(select_ROI_type_GUI);
    end

    function subject_specific_binary_images(~,~)
        ROI_type = 'subject_specific_binary_images';
        uiresume(select_ROI_type_GUI);
    end

    function fixed_spheres(~,~)
        ROI_type = 'fixed_spheres';
        uiresume(select_ROI_type_GUI);
    end

    function moving_inside_fixed_spheres(~,~)
        ROI_type = 'moving_spheres_inside_fixed_spheres';
        uiresume(select_ROI_type_GUI);
    end

    function moving_inside_binary_images(~,~)
        ROI_type = 'moving_spheres_inside_binary_images';
        uiresume(select_ROI_type_GUI);
    end

    function close_ROI_type(~,~)
        ROI_type = '';
        uiresume(select_ROI_type_GUI);
    end
    
    uiwait(select_ROI_type_GUI);
    delete(select_ROI_type_GUI);
end

%% =====================[ Remove empty ROIs GUI ]==========================
function remove_empty_ROIs_GUI(empty_ROI_list)

    ROI_remove_string = {'Warning, the following ROIs do not',...
                         'contain data for at least one subject and',...
                         'will be excluded from the analysis:'};

    ROI_remove_MW = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.28 0.35],'Resize','on','color','w','MenuBar', 'none','ToolBar', 'none','CloseRequestFcn',@ROI_remove_MW_close);
    
    if isunix; fontscale = 0.9; else; fontscale = 1; end

    ROI_remove_MW_list = uicontrol(ROI_remove_MW , 'Style', 'listbox', 'String', empty_ROI_list,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.22 0.91 0.40],'fontunits','points', 'fontSize', 12*fontscale,'Value', []);
    ROI_remove_MW_S1 = uicontrol(ROI_remove_MW,'Style','text','String',ROI_remove_string,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.22*fontscale,'backgroundcolor',get(ROI_remove_MW,'color'), 'Position',[0.20 0.73 0.600 0.2]);
    ROI_remove_MW_S2 = uicontrol(ROI_remove_MW,'Style','text','String', 'Empty ROIs:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.55*fontscale,'backgroundcolor',get(ROI_remove_MW,'color'), 'Position',[0.04 0.62 0.200 0.08]);    
    ROI_remove_MW_OK = uicontrol(ROI_remove_MW,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4, 'Position',[0.38 0.07 0.28 0.10],'callback', @ROI_remove_MW_close);
    movegui(ROI_remove_MW,'center');

    function ROI_remove_MW_close(~,~)
        uiresume(ROI_remove_MW);
    end

    disp(['Removed ' num2str(length(empty_ROI_list)) ' ROI(s) from the ROI set.']);
    uiwait(ROI_remove_MW);  
    delete(ROI_remove_MW);
end

%% ================[ Remove heavily cropped ROIs GUI ]=====================
function [ROI_set_crop] = remove_cropped_ROIs_GUI(ROI_set)

    ROI_string = {};
    ROI_set_crop = []; 

    for iROI = 1:length(ROI_set.ROIs)
        full_string = {iROI,horzcat('No ',num2str(iROI),': ',ROI_set.ROIs(iROI).name, ' :: ', ...
            num2str(ROI_set.ROIs(iROI).raw_size),' voxels', ' :: ' , num2str(ROI_set.ROIs(iROI).masked_size), ...
            ' voxels ' , ':: ',num2str(ROI_set.ROIs(iROI).masked_size_percents), ' %'), ROI_set.ROIs(iROI).masked_size_percents};
        ROI_string = vertcat(ROI_string, full_string);
    end

    ROI_crop_MW_L1 = ROI_string;
    ROI_crop_MW_L2 = {};
    ROI_crop_MW_INFO1 = {'Remove heavily cropped ROIs with insufficient data, if necessary.'};
    ROI_crop_MW_INFO2 = {'No # :: ROI name :: Voxels before masking :: Voxels after masking :: Percent left'};    
    ROI_crop_MW_IND1 = {};          
    ROI_crop_MW_IND2 = {};         

    ROI_crop_MW = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.32 0.55],'Resize','on','color','w','MenuBar', 'none','ToolBar', 'none','Windowstyle', 'Modal','CloseRequestFcn', @ROI_crop_MW_EXIT);
    ROI_crop_MW_LB1 = uicontrol(ROI_crop_MW , 'Style', 'listbox', 'String', ROI_crop_MW_L1(:,2,1),'Max', 100,'Units', 'normalized', 'Position',[0.048 0.565 0.91 0.30],'fontunits','points', 'fontSize', 11, 'Value', [], 'callback', @LB1_SEL);
    ROI_crop_MW_LB2 = uicontrol(ROI_crop_MW , 'Style', 'listbox', 'String', ROI_crop_MW_L2,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.14 0.91 0.25],'fontunits','points', 'fontSize', 11, 'Value', [], 'callback', @LB2_SEL);
    
    if isunix; fontscale = 0.9; else; fontscale = 1; end

    ROI_crop_MW_S1 = uicontrol(ROI_crop_MW,'Style','text','String', ROI_crop_MW_INFO1,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.54*fontscale,'Position',[0.10 0.92 0.8 0.05],'backgroundcolor',get(ROI_crop_MW,'color'));
    ROI_crop_MW_S2 = uicontrol(ROI_crop_MW,'Style','text','String', ROI_crop_MW_INFO2,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.64*fontscale,'HorizontalAlignment', 'left','Position',[0.048 0.87 0.91 0.040],'backgroundcolor',get(ROI_crop_MW,'color'));
    ROI_crop_MW_S3 = uicontrol(ROI_crop_MW,'Style','text','String', '% threshold','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.44*fontscale,'HorizontalAlignment', 'left','Position',[0.84 0.475 0.13 0.055],'backgroundcolor',get(ROI_crop_MW,'color'));
    ROI_crop_MW_S4 = uicontrol(ROI_crop_MW,'Style','text','String', 'Removed ROIs:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'left','Position',[0.05 0.395 0.2 0.05],'backgroundcolor',get(ROI_crop_MW,'color'));

    ROI_crop_MW_remove_selected = uicontrol(ROI_crop_MW,'Style','pushbutton', 'String', 'Remove selected','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.047 0.48 0.24 0.063], 'callback', @remove_selected);
    ROI_crop_MW_remove_thresholded = uicontrol(ROI_crop_MW,'Style','pushbutton', 'String', 'Remove ROIs under % threshold','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.32 0.48 0.40 0.063], 'callback', @remove_thresholded);
    ROI_crop_MW_OK = uicontrol(ROI_crop_MW,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.047 0.056 0.24 0.063], 'callback', @confirm_selection);

    ROI_crop_MW_return_selected = uicontrol(ROI_crop_MW,'Style','pushbutton', 'String', 'Return selected','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.39 0.056 0.24 0.063], 'callback', @return_selected);
    ROI_crop_MW_return_all = uicontrol(ROI_crop_MW,'Style','pushbutton', 'String', 'Return all','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.72 0.056 0.24 0.063], 'callback', @return_all);
    ROI_crop_MW_thr = uicontrol(ROI_crop_MW,'Style','edit','String',[],'Units', 'normalized','fontunits','normalized', 'fontSize', 0.42,'HorizontalAlignment','center','Position',[0.74 0.48 0.1 0.06]);
    movegui(ROI_crop_MW,'center');    

    %----------------------------------------------------------------------
    function ROI_crop_MW_EXIT(~,~)
    	disp('ROIs not selected.');
        uiresume(ROI_crop_MW);
    end

    %----------------------------------------------------------------------
    function LB1_SEL(~,~)
    	index = get(ROI_crop_MW_LB1, 'Value');  
        ROI_crop_MW_IND1 = index;      
    end

    %----------------------------------------------------------------------
    function LB2_SEL(~,~)
        index = get(ROI_crop_MW_LB2, 'Value');  
        ROI_crop_MW_IND2 = index;             
    end

    %----------------------------------------------------------------------
    function remove_selected(~,~)
        if isempty(ROI_crop_MW_IND1)
            fprintf(2,'No ROIs selected for removal.\n');
        else
            updated_ROIs = {};  
            new_ROIs_flag = 0;

            % Create list of selected ROIs
            updated_ROIs = vertcat(updated_ROIs, ROI_crop_MW_L1(ROI_crop_MW_IND1,:,:)); 

            if ~isempty(ROI_crop_MW_L2)
                % Condition 1: if ROIs have been previously selected, execute after checking for duplicates 
                if size(updated_ROIs,1) >= 2 
                    % Case, when more than 2 ROIs are selected
                    temp_ROI_list = []; 
                    ROI_index = 1; 
                    for iROI = 1:size(updated_ROIs,1) 
                        for jROI = 1:size(ROI_crop_MW_L2,1)
                            if strcmp(updated_ROIs(iROI,2,1), ROI_crop_MW_L2(jROI,2,1))
                               temp_ROI_list(ROI_index) = iROI;
                               ROI_index = ROI_index+1;
                            end
                        end
                    end            
                else
                    % Case, when only 1 ROI is selected
                    temp_ROI_list = [];
                    ROI_index = 1;
                    for iROI = 1:size(ROI_crop_MW_L2,1)
                        if strcmp(updated_ROIs(1,2,1),ROI_crop_MW_L2(iROI,2,1))
                            temp_ROI_list(ROI_index) = iROI;
                            ROI_index = ROI_index+1;
                        end
                    end                 
                end

                % Remove the respective ROIs in the main ROI list for GUI
                if length(temp_ROI_list)>=2
                    % Case, when more than 2 ROIs are selected
                    set_index = 0;                   
                    for iROI = 1:length(temp_ROI_list)
                        updated_ROIs(temp_ROI_list(iROI)-set_index,:,:) = [];
                        set_index = set_index + 1;
                    end
                    new_ROIs_flag = size(updated_ROIs,1);  
                else
                    % Case, when only 1 ROI is selected
                    for iROI = 1:size(updated_ROIs,1)
                        if updated_ROIs{iROI,1,1} == temp_ROI_list
                            updated_ROIs(iROI,:,:) = [];
                        end
                    end
                    new_ROIs_flag = size(updated_ROIs,1);
                end
                ROI_crop_MW_L2 = sortrows(vertcat(ROI_crop_MW_L2, updated_ROIs),1);              
            else
                % Condition 2: if ROIs have not been previously selected, directly add to list
                ROI_crop_MW_L2 = vertcat(ROI_crop_MW_L2, updated_ROIs); 
                new_ROIs_flag = 2;
            end

            % Check if newly selected ROIs for removal have been added
            if new_ROIs_flag == 2
                    fprintf('ROIs selected for removal: %d. \n', size(ROI_crop_MW_L2,1));
            elseif new_ROIs_flag == 0
                    fprintf(2,'Selected ROIs are already present in the removal list, no new ROIs to remove.\n');
            else
                    fprintf('New selected ROIs for removal: %d. \n', new_ROIs_flag); 
            end 

            % Update sorted list of ROIs into GUI
            set(ROI_crop_MW_LB2, 'String', ROI_crop_MW_L2(:,2,1));
        end
    end

    %----------------------------------------------------------------------
    function remove_thresholded(~,~)

        updated_ROIs = {}; 
        new_ROIs_flag = 0;  

        ROI_crop_thr = get(ROI_crop_MW_thr, 'String'); % Get threshold

        if ~isempty(ROI_crop_thr)

            threshold = str2double(ROI_crop_thr); 

            if isnan(threshold)
                fprintf(2,'Please enter a threshold between 0 and 100.\n');

            elseif (threshold<0) || (threshold>100)
                fprintf(2,'Please enter a threshold between 0 and 100.\n');

            else
                temp_ROI_list = [];
                ROI_index = 1;
                for iROI = 1:size(ROI_crop_MW_L1,1)
                    if ROI_crop_MW_L1{iROI,3,1} <= threshold
                        temp_ROI_list(ROI_index) = iROI;
                        ROI_index = ROI_index + 1;
                    end
                end
                updated_ROIs = ROI_crop_MW_L1(temp_ROI_list,:,:);

                % Compiling the list of ROIs to remove
                if isempty(ROI_crop_MW_L2)
                    % If List is exported for the firt time
                    ROI_crop_MW_L2 = vertcat(ROI_crop_MW_L2, updated_ROIs); 
                    new_ROIs_flag = 2;
                else
                    % Check for duplicates
                    if size(updated_ROIs,1) >= 2
                        % Case, when more than 2 ROIs are present under threshold
                        temp_ROI_list = []; 
                        ROI_index = 1;      
                        for iROI = 1:size(updated_ROIs,1)
                            for jSet = 1:size(ROI_crop_MW_L2,1)
                                if strcmp(updated_ROIs(iROI,2,1), ROI_crop_MW_L2(jSet,2,1))
                                   temp_ROI_list(ROI_index) = iROI;
                                   ROI_index = ROI_index+1;
                                end
                            end
                        end
                    else
                        % Case, when only 1 ROI is present under threshold
                        temp_ROI_list = []; 
                        ROI_index = 1;
                        for iROI = 1:size(ROI_crop_MW_L2,1)
                            if strcmp(updated_ROIs(1,2,1),ROI_crop_MW_L2(iROI,2,1))
                                temp_ROI_list(ROI_index) = iROI;
                                ROI_index = ROI_index+1;
                            end
                        end
                    end

                    % Remove the respective ROIs in the main ROI list for GUI
                    if length(temp_ROI_list)>=2
                        % Case, when more than 2 ROIs are selected
                        ROI_index = 0;      
                        for c = 1:length(temp_ROI_list)
                            updated_ROIs(temp_ROI_list(c)-ROI_index,:,:) = [];
                            ROI_index = ROI_index + 1;
                        end
                        new_ROIs_flag = size(updated_ROIs,1);
                    else
                        % Case, when only 1 ROI is selected
                        updated_ROIs(temp_ROI_list,:,:) = [];
                        new_ROIs_flag = size(updated_ROIs,1);
                    end
                    ROI_crop_MW_L2 = sortrows(vertcat(ROI_crop_MW_L2, updated_ROIs),1);
                end

                % Check if newly selected ROIs have been added
                if new_ROIs_flag == 2 && size(ROI_crop_MW_L2,1) ~= 0
                        fprintf('ROIs selected for removal: %d. \n', size(ROI_crop_MW_L2,1));

                elseif new_ROIs_flag(1) == 2 && size(ROI_crop_MW_L2,1) == 0
                        fprintf(2,'ROIs below this threshold do not exist.\n');

                    elseif new_ROIs_flag(1) == 0
                        fprintf(2,'All ROIs below this threshold have already been removed.\n');

                    else
                        fprintf('%d ROIs selected for removal at threshold %d percents. \n', new_ROIs_flag(1),threshold);     
                end    

                % Update sorted list of ROIs into GUI
                set(ROI_crop_MW_LB2, 'String', ROI_crop_MW_L2(:,2,1));

            end

        else            
            fprintf(2,'The entered threshold is empty or invalid, please re-enter.\n');
        end
    end

    %----------------------------------------------------------------------
    function return_selected(~,~)
        if isempty(ROI_crop_MW_L2)
            fprintf(2,'No ROIs present to return.\n');
        elseif isempty(ROI_crop_MW_IND2)
            fprintf(2,'No ROIs selected to return.\n');
        else
            if length(ROI_crop_MW_IND2) >= 2
                set_index = 0;
                for c = 1:length(ROI_crop_MW_IND2)
                    ROI_crop_MW_L2(ROI_crop_MW_IND2(c)-set_index,:,:) = [];
                    set_index = set_index + 1;
                end
                fprintf('Number of ROIs removed are %d. \n', set_index);
            else
                ROI_crop_MW_L2(ROI_crop_MW_IND2,:,:) = [];
                disp('Selected ROI has been returned.');
            end

            if isempty(ROI_crop_MW_L2)
                ROI_crop_MW_L2 = {};
                set(ROI_crop_MW_LB2, 'String', ROI_crop_MW_L2); 
            else
                set(ROI_crop_MW_LB2, 'String', ROI_crop_MW_L2(:,2,1));
                set(ROI_crop_MW_LB2, 'Value', []);
            end
        end
    end

    %----------------------------------------------------------------------
    function return_all(~,~)
        if isempty(ROI_crop_MW_L2)
            fprintf(2,'No ROIs present to return.\n');
        else
            ROI_crop_MW_L2 = {};
            set(ROI_crop_MW_LB2, 'String', ROI_crop_MW_L2);
            set(ROI_crop_MW_LB2, 'Value', []);
            fprintf('%d ROIs have been returned. \n',size(ROI_crop_MW_L2,1));
        end
    end
    
    %----------------------------------------------------------------------
    function confirm_selection(~,~)
        if isempty(ROI_crop_MW_L2)
            disp('New ROI set has been defined. All selected ROIs have been saved.');
            uiresume(ROI_crop_MW);
        else
            if length(ROI_crop_MW_L1) == length(ROI_crop_MW_L2)
                fprintf(2,'All ROIs have been removed, please try again.\n');
            else
                disp('New ROI set has been defined. Highly cropped ROIs have been removed.');
                ROI_index = 0;
                for jROI = 1:size(ROI_crop_MW_L2,1)
                    ROI_set.ROIs(ROI_crop_MW_L2{jROI,1,1} - ROI_index) = [];
                    ROI_index = ROI_index + 1;
                end
                uiresume(ROI_crop_MW);
            end
        end
        ROI_set_crop = ROI_set;    
    end

    uiwait(ROI_crop_MW);
    delete(ROI_crop_MW);
end

%% =========================[Fixed spheres GUI]============================
function [ROI_select] = select_ROIs_case_2()

    ROI_string = {}; % variable to show ROIs via GUI
    ROI_select = []; % variable to export ROIs to ROI selection window
    ROI_index = {};  % variable to select ROIs from list index
        
    FS_GUI = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.34 0.24 0.32 0.5],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','on','CloseRequestFcn', @no_select_exit);
    FS_txt_1 = uicontrol(FS_GUI,'Style','text','String', 'Define fixed spheres','Units', 'normalized', 'Position',[0.270 0.925 0.450 0.05],'fontunits','normalized', 'fontSize', 0.65,'backgroundcolor','w');
    FS_txt_2 = uicontrol(FS_GUI , 'Style', 'text', 'String', 'No # :: ROI name :: Center coordinates [x y z] :: Radius ','Units', 'normalized', 'Position',[0.045 0.855 0.900 0.045],'fontunits','normalized', 'fontSize', 0.64,'HorizontalAlignment','left','backgroundcolor','w');  
    FS_lst = uicontrol(FS_GUI , 'Style', 'listbox', 'String', '','Value', [],'Max', 100000,'Units', 'normalized', 'Position',[0.045 0.40 0.910 0.450],'fontunits','points', 'fontSize', 12,'Enable','inactive', 'callback', @list_select);
    
    FS_add = uicontrol(FS_GUI,'Style','pushbutton','String', 'Add new','Units', 'normalized','Position',[0.044 0.3 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @add_ROI);
    FS_rem = uicontrol(FS_GUI,'Style','pushbutton','String', 'Remove selected','Units', 'normalized','Position',[0.355 0.3 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36, 'callback', @remove);
    FS_rem_all = uicontrol(FS_GUI,'Style','pushbutton','String', 'Remove all','Units', 'normalized','Position',[0.667 0.3 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @remove_all);
    FS_sel = uicontrol(FS_GUI,'Style','pushbutton','String', 'Select from (*.mat, *.xlsx, *.csv, *.txt) file','Units', 'normalized','Position',[0.044 0.2 0.912 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @select_ROI);
    FS_conf = uicontrol(FS_GUI,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.045 0.05 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @export);
    FS_help = uicontrol(FS_GUI,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.667 0.05 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @help_window);    
    movegui(FS_GUI,'center');
    
    function no_select_exit(~,~)
        ROI_select = [];
        disp('ROIs not selected');
        uiresume(FS_GUI);
    end

    function list_select(~,~)
        index = get(FS_lst, 'Value');  
        ROI_index = index;      
    end

    function add_ROI(~,~)
        
        [ROI_name, coord, radius] = add_fixed_sphere_GUI();
        
        if ~isempty(ROI_name)
            
            new_index = size(ROI_string,1)+1;

            full_string = horzcat('No ',num2str(new_index),': ', char(ROI_name), ' :: ',...
                            '[',num2str(coord{1}),' ', num2str(coord{2}), ' ',num2str(coord{3}),...
                            '] :: ', num2str(radius), ' mm');

            ROI_string = vertcat(ROI_string, full_string);
            ROI_select(new_index).ROI_name = char(ROI_name);
            ROI_select(new_index).X = coord{1};
            ROI_select(new_index).Y = coord{2};
            ROI_select(new_index).Z = coord{3};
            ROI_select(new_index).radius = radius;
            
            fprintf('Custom ROI added to list. Number of ROIs present are: %d \n',new_index);
            set(FS_lst, 'String', ROI_string);
            set(FS_lst, 'Enable', 'On');           
        else
            disp('Custom ROI not added.');
        end
    end

    function select_ROI(~,~) 
        
        ROI_path = spm_select(1,{'.csv','.txt','.mat','.xlsx'},'Select ROI masks',{},pwd);
        
        if ~isempty(ROI_path)
            
            if strfind(ROI_path, '.mat') > 0

                try
                    temp_var = load(ROI_path);
                    var_names=fieldnames(temp_var);
                    sub_var_name=var_names{1};
                    values = temp_var.(sub_var_name);
                    
                    % Condition if there are existing ROIs in list
                    if isempty(ROI_string)
                        ROI_string = {};
                        ROI_select = struct;
                        extend_index = 0;
                    else
                        extend_index = size(ROI_string, 1);
                    end
                    
                    % Cell Type
                    if iscell(values)
                        for iROI = 1:size(values, 1)
                            full_string = horzcat('No ',num2str(iROI+extend_index),': ', char(values{iROI, 1}), ' :: ',...
                            '[',num2str(values{iROI, 2}),' ', num2str(values{iROI, 3}), ' ',num2str(values{iROI, 4}),...
                            '] :: ', num2str(values{iROI, 5}), ' mm');
                            ROI_string = vertcat(ROI_string, full_string);
                            ROI_select(iROI+extend_index).ROI_name = char(values{iROI, 1});
                            ROI_select(iROI+extend_index).X = values{iROI, 2};
                            ROI_select(iROI+extend_index).Y = values{iROI, 3};
                            ROI_select(iROI+extend_index).Z = values{iROI, 4};
                            ROI_select(iROI+extend_index).radius = values{iROI, 5};
                        end
                        
                    % Struct type
                    elseif isstruct(values)
                        
                        list_fields = fieldnames(values);                        
                        for iROI = 1:size(values,2)
                            full_string = horzcat('No ',num2str(iROI+extend_index),': ', char(values(iROI).(list_fields{1})), ' :: ',...
                            '[',num2str(values(iROI).(list_fields{2})),' ', num2str(values(iROI).(list_fields{3})), ' ',...
                            num2str(values(iROI).(list_fields{4})),'] :: ', num2str(values(iROI).(list_fields{5})), ' mm');
                            ROI_string = vertcat(ROI_string, full_string);
                            ROI_select(iROI+extend_index).ROI_name = char(values(iROI).(list_fields{1}));
                            ROI_select(iROI+extend_index).X = values(iROI).(list_fields{2});
                            ROI_select(iROI+extend_index).Y = values(iROI).(list_fields{3});
                            ROI_select(iROI+extend_index).Z = values(iROI).(list_fields{4});
                            ROI_select(iROI+extend_index).radius = values(iROI).(list_fields{5});
                        end
                        
                    % table type
                    else
                        for iROI = 1:size(values, 1)
                            full_string = horzcat('No ',num2str(iROI+extend_index),': ', char(values{iROI, 1}), ' :: ',...
                            '[',num2str(values{iROI, 2}),' ', num2str(values{iROI, 3}), ' ',num2str(values{iROI, 4}),...
                            '] :: ', num2str(values{iROI, 5}), ' mm');
                            ROI_string = vertcat(ROI_string, full_string);
                            ROI_select(iROI+extend_index).ROI_name = char(values{iROI, 1});
                            ROI_select(iROI+extend_index).X = values{iROI, 2};
                            ROI_select(iROI+extend_index).Y = values{iROI, 3};
                            ROI_select(iROI+extend_index).Z = values{iROI, 4};
                            ROI_select(iROI+extend_index).radius = values{iROI, 5};
                        end                        
                    end
                
                catch 
                    error('The selected .mat file is not in format, please try again');
                end

            else
                % Reading .csv , .xlsx, .txt files with ROIs
                % NOT WORKING FOR .csv and .txt in 2014a version
                temp_table = readtable(ROI_path);
                
                % Condition if there are existing ROIs in list
                if isempty(ROI_string)
                    ROI_string = {};
                    ROI_select = struct;
                    extend_index = 0;
                else
                    extend_index = size(ROI_string, 1);
                end
                
                for iROI = 1:size(temp_table, 1)
                    full_string = horzcat('No ',num2str(iROI+extend_index),': ', char(temp_table{iROI, 1}), ' :: ',...
                        '[',num2str(temp_table{iROI, 2}),' ', num2str(temp_table{iROI, 3}), ' ',num2str(temp_table{iROI, 4}),...
                        '] :: ', num2str(temp_table{iROI, 5}), ' mm');
                    ROI_string = vertcat(ROI_string, full_string);
                    ROI_select(iROI+extend_index).ROI_name = char(temp_table{iROI, 1});
                    ROI_select(iROI+extend_index).X = temp_table{iROI, 2};
                    ROI_select(iROI+extend_index).Y = temp_table{iROI, 3};
                    ROI_select(iROI+extend_index).Z = temp_table{iROI, 4};
                    ROI_select(iROI+extend_index).radius = temp_table{iROI, 5};
                    
                end
                
            end                
            
            fprintf('Number of ROIs added: %d \n', size(ROI_string, 1));
            clear temp_table iROI jROI full_string temp_var
            set(FS_lst, 'String', ROI_string);
            set(FS_lst, 'Enable', 'On');
        else
            disp('ROIs not selected');
        end
        
    end
    
    function remove_all(~,~)
        if isempty(ROI_string)
            fprintf(2,'No ROIs present to remove.\n');
        else
            ROI_string = {};
            ROI_select = [];
            ROI_index = {};
            set(FS_lst, 'String', ROI_string);
            set(FS_lst, 'Enable', 'inactive');
            set(FS_lst, 'value', []);
            disp('All ROIs have been removed');
        end
    end

    function remove(~,~)
        
        if isempty(ROI_string)
            fprintf(2,'No ROIs present to remove.\n');
            
        elseif isempty(ROI_index)
            fprintf(2,'No ROIs selected to remove.\n');
            
        else   
            ROI_string = {};
            len_ROI_removed = length(ROI_index);
            ROI_select(ROI_index) = [];
            ROI_index = {};
            
            % Reset display list string
            for iROI = 1:size(ROI_select, 2)
                full_string = horzcat('No ',num2str(iROI),': ', ROI_select(iROI).ROI_name, ' :: ',...
                            '[',num2str(ROI_select(iROI).X),' ', num2str(ROI_select(iROI).Y), ' ',num2str(ROI_select(iROI).Z),...
                            '] :: ', num2str(ROI_select(iROI).radius), ' mm');
                ROI_string = vertcat(ROI_string, full_string);
            end
            
            % Remove selected ROIs
            set(FS_lst, 'String', ROI_string);
            set(FS_lst,'Value',[]);
            fprintf('Number of ROIs removed: %d \n', len_ROI_removed);            
        end
    end

    function help_window(~,~)
        FS_ROI_HW = figure('Name', 'Define fixed spheres: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.35 0.28 0.28],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','on', 'WindowStyle', 'modal', 'CloseRequestFcn',@close_GUI);
        
        FS_str_1 = {'Define fixed spheres manually or select them from the coordinate table (*.mat, *.xlsx, *.csv, *.txt file). The coordinate table must contain the following columns:',...
            '','1) ROI name', '2) Fixed center coordinate: X','3) Fixed center coordinate: Y','4) Fixed center coordinate: Z', '5) Fixed sphere radius (inner radius)','',...
            'For examples of coordinate tables, see the TMFC_toolbox folder.'};
        movegui(FS_ROI_HW, 'center');

        if isunix; fontscale = 0.8; else; fontscale = 1; end
        
        FS_ROI_HW_txt_1 = uicontrol(FS_ROI_HW,'Style','text','String', FS_str_1,'Units', 'normalized', 'Position',[0.05 0.22 0.90 0.75],'fontunits','normalized', 'fontSize', 0.075*fontscale, 'HorizontalAlignment', 'left','backgroundcolor','w');
        FS_ROI_HW_OK = uicontrol(FS_ROI_HW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.36 0.08 0.250 0.11],'fontunits','normalized', 'fontSize', 0.40,'callback', @close_GUI);
        
        function close_GUI(~,~)
            uiresume(FS_ROI_HW); 
        end

        uiwait(FS_ROI_HW);
        delete(FS_ROI_HW);
    end
        
    function export(~,~)
        if ~isempty(ROI_select)
            fprintf('\n Number of ROIs exported are: %d\n', size(ROI_select,2));
            uiresume(FS_GUI);
        else
            fprintf('No ROIs added to export\n');
        end
    end
 
    uiwait(FS_GUI);
    delete(FS_GUI);
end

%% ==================[Add custom fixed sphere GUI]-========================
function [ROI_name, center_coordinates, radius] = add_fixed_sphere_GUI(~,~)

    % Variables to store new ROI from user
    ROI_name = '';
    center_coordinates = '';
    radius = '';
    
    % GUI to add fixed sphere ROI from user
    add_NS_GUI = figure('Name', 'Add new sphere', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.30 0.22 0.25],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','on','CloseRequestFcn', @close_new_ROI, 'WindowStyle', 'modal');
    add_NS_txt_1 = uicontrol(add_NS_GUI,'Style','text','String', 'Define fixed sphere','Units', 'normalized', 'Position',[0.272 0.88 0.450 0.1],'fontunits','normalized', 'fontSize', 0.66,'backgroundcolor','w');
    add_NS_txt_2 = uicontrol(add_NS_GUI , 'Style', 'text', 'String', 'ROI name','Units', 'normalized', 'Position',[0.272 0.76 0.450 0.08],'fontunits','normalized', 'fontSize', 0.68,'HorizontalAlignment','center','backgroundcolor','w');
    add_NS_txt_3 = uicontrol(add_NS_GUI , 'Style', 'text', 'String', 'Center coordinates, mm','Units', 'normalized', 'Position',[0.095 0.52 0.550 0.08],'fontunits','normalized', 'fontSize', 0.68,'HorizontalAlignment','center','backgroundcolor','w');
    add_NS_txt_X = uicontrol(add_NS_GUI , 'Style', 'text', 'String', 'X','Units', 'normalized', 'Position',[0.125 0.44 0.1 0.08],'fontunits','normalized', 'fontSize', 0.68,'HorizontalAlignment','center','backgroundcolor','w');
    add_NS_txt_Y = uicontrol(add_NS_GUI , 'Style', 'text', 'String', 'Y','Units', 'normalized', 'Position',[0.32 0.44 0.1 0.08],'fontunits','normalized', 'fontSize', 0.68,'HorizontalAlignment','center','backgroundcolor','w');
    add_NS_txt_Z = uicontrol(add_NS_GUI , 'Style', 'text', 'String', 'Z','Units', 'normalized', 'Position',[0.515 0.44 0.1 0.08],'fontunits','normalized', 'fontSize', 0.68,'HorizontalAlignment','center','backgroundcolor','w');
    add_NS_txt_4 = uicontrol(add_NS_GUI , 'Style', 'text', 'String', 'Radius, mm','Units', 'normalized', 'Position',[0.68 0.44 0.22 0.08],'fontunits','normalized', 'fontSize', 0.68,'HorizontalAlignment','center','backgroundcolor','w');
    
%     FS_name_info = uicontrol(add_NS_GUI, 'Style','text', 'String','Not allowed: < > : " / \ | ? *', ...
%         'Units','normalized','Position',[0.095 0.604 0.80 0.045], ...
%         'FontUnits','normalized','FontSize',0.65, 'ForegroundColor',[0.65 0 0], ...
%         'BackgroundColor','w','HorizontalAlignment','left');

    FS_E1 = uicontrol(add_NS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.0955 0.65 0.800 0.115],'fontunits','normalized', 'fontSize', 0.45);
    FS_E2_X = uicontrol(add_NS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.0955 0.32 0.16 0.115],'fontunits','normalized', 'fontSize', 0.45);
    FS_E2_Y = uicontrol(add_NS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.29 0.32 0.16 0.115],'fontunits','normalized', 'fontSize', 0.45);
    FS_E2_Z = uicontrol(add_NS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.485 0.32 0.16 0.115],'fontunits','normalized', 'fontSize', 0.45);
    FS_E3 = uicontrol(add_NS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.695 0.32 0.20 0.115],'fontunits','normalized', 'fontSize', 0.45);
    FS_OK = uicontrol(add_NS_GUI,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.31 0.08 0.35 0.13],'fontunits','normalized', 'fontSize', 0.36,'callback', @ok_data);
    movegui(add_NS_GUI,'center');
    
    % Function to close GUI when ROI is not entered
    function close_new_ROI(~,~)
        ROI_name = '';
        center_coordinates = '';
        radius = '';
        uiresume(add_NS_GUI);
    end
    
    % Function to check and export created ROI
    function ok_data(~,~)
        
        % Extracting ROI name
        tmp_name = get(FS_E1, 'String');
        
        % Checking if name is empty
        if ~strcmp(tmp_name,'') && ~strcmp(tmp_name(1),' ')
            % Reject invalid filesystem characters before creating the ROI.
            if ~valid_TMFC_output_name(tmp_name,'ROI')
                return;
            end

            % Set ROI name
            ROI_name = tmp_name;
            
            % Extracting Center Coordinates [X Y Z]
            tmp_center_X = str2double(get(FS_E2_X, 'String'));
            tmp_center_Y = str2double(get(FS_E2_Y, 'String'));
            tmp_center_Z = str2double(get(FS_E2_Z, 'String'));           
            
            % Check for empty coordinates
            if ~isnan(tmp_center_X) && ~isnan(tmp_center_Y) && ~isnan(tmp_center_Z)
                
                % Check if coordinates are real numbers
                if (isreal(tmp_center_X)) && (isreal(tmp_center_Y)) && (isreal(tmp_center_Z))
                    
                    center_coordinates = {tmp_center_X, tmp_center_Y, tmp_center_Z};
                    
                    % Extracting Radius of Fixed Sphere
                    tmp_rad = str2double(get(FS_E3, 'String'));
                    
                    % Check for empty Radius value
                    if ~isnan(tmp_rad)
                        
                        % Check if radius is a non-negative real number
                        if ~(isreal(tmp_rad))
                            fprintf(2,'Please enter non-negative real number for the radius of spheres.\n');
                        elseif tmp_rad <= 0 
                            fprintf(2,'Please enter non-negative real number for the radius of spheres.\n');
                        else
                            % Exporting selected variables
                            radius = tmp_rad;     
                            fprintf('Name of ROI: %s.\n', ROI_name);   
                            fprintf('Coordinates (X, Y, Z) %d %d %d\n', center_coordinates{1}, center_coordinates{2}, center_coordinates{3});
                            fprintf('Radius of Fixed sphere: %d.\n', radius);
                            uiresume(add_NS_GUI);
                        end
                    else
                        fprintf(2,'Fixed sphere radius not entered or is invalid, please re-enter.\n'); 
                    end
                else
                    fprintf(2,'Please enter a real number for coordinates.\n');
                end
            else 
                fprintf(2,'Coordinates are not entered or is invalid, please re-enter.\n');                
            end
        else
            fprintf(2,'ROI Name not entered or is invalid, please re-enter.\n');
        end
    end

    uiwait(add_NS_GUI);
    delete(add_NS_GUI);
end

%% ===============[Moving spheres inside fixed spheres GUI]================
function [ROI_select] = select_ROIs_case_3()

    ROI_string = {}; % variable to show ROIs via GUI
    ROI_select = []; % variable to export ROIs to ROI selection window
    ROI_index = {};  % variable to select ROIs from list index
    
    MS_GUI = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.29 0.29 0.40 0.5],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','on','CloseRequestFcn', @no_select_exit);
    MS_txt_1 = uicontrol(MS_GUI,'Style','text','String', 'Define moving spheres','Units', 'normalized', 'Position',[0.270 0.925 0.450 0.05],'fontunits','normalized', 'fontSize', 0.65,'backgroundcolor','w');
    MS_txt_2 = uicontrol(MS_GUI , 'Style', 'text', 'String', 'No. :: ROI name :: Fixed center coordinates [x y z] :: Moving sphere radius :: Fixed sphere radius','Units', 'normalized', 'Position',[0.045 0.855 0.900 0.045],'fontunits','normalized', 'fontSize', 0.64,'HorizontalAlignment','left','backgroundcolor','w');
    MS_lst = uicontrol(MS_GUI , 'Style', 'listbox', 'String', '','Value', [],'Max', 100000,'Units', 'normalized', 'Position',[0.045 0.40 0.910 0.450],'fontunits','points', 'fontSize', 12,'Enable','inactive', 'callback', @list_select);
    
    MS_add = uicontrol(MS_GUI,'Style','pushbutton','String', 'Add new','Units', 'normalized','Position',[0.044 0.3 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @add_ROI);
    MS_rem = uicontrol(MS_GUI,'Style','pushbutton','String', 'Remove selected','Units', 'normalized','Position',[0.355 0.3 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36, 'callback', @remove);
    MS_rem_all = uicontrol(MS_GUI,'Style','pushbutton','String', 'Remove all','Units', 'normalized','Position',[0.667 0.3 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @remove_all);
    MS_sel = uicontrol(MS_GUI,'Style','pushbutton','String', 'Select from (*.mat, *.xlsx, *.csv, *.txt) file','Units', 'normalized','Position',[0.044 0.2 0.912 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @select_ROI);
    MS_conf = uicontrol(MS_GUI,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.045 0.05 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @export);
    MS_help = uicontrol(MS_GUI,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.667 0.05 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @help_window);    
    movegui(MS_GUI,'center');
    
    function no_select_exit(~,~)
        ROI_select = [];
        disp('ROIs not selected');
        uiresume(MS_GUI);
    end
    
    function list_select(~,~)
        index = get(MS_lst, 'Value');  
        ROI_index = index;      
    end

    function add_ROI(~,~)
        
        [ROI_name, coord, radius] = add_moving_sphere_GUI();
        
        if ~isempty(ROI_name)
            
            new_index = size(ROI_string,1)+1;

            full_string = horzcat('No ',num2str(new_index),': ', char(ROI_name), ' :: ',...
                            '[',num2str(coord{1}),' ', num2str(coord{2}), ' ',num2str(coord{3}),...
                            '] :: ', num2str(radius{1}), ' mm :: ', num2str(radius{2}), ' mm');

            ROI_string = vertcat(ROI_string, full_string);
            ROI_select(new_index).ROI_name = char(ROI_name);
            ROI_select(new_index).X = coord{1};
            ROI_select(new_index).Y = coord{2};
            ROI_select(new_index).Z = coord{3};
            ROI_select(new_index).moving_radius = radius{1};
            ROI_select(new_index).fixed_radius = radius{2};
            
            fprintf('Custom ROI added to list. Number of ROIs present are: %d \n',new_index);
            set(MS_lst, 'String', ROI_string);
            set(MS_lst, 'Enable', 'On');           
        else
            disp('Custom ROI not added.');
        end
    end

    function select_ROI(~,~) 
        
        ROI_path = spm_select(1,{'.csv','.txt','.mat','.xlsx'},'Select ROI masks',{},pwd);
        
        if ~isempty(ROI_path)
            
            if strfind(ROI_path, '.mat') > 0
                
                % Loading data into workspace
                try
                    temp_var = load(ROI_path);
                    var_names=fieldnames(temp_var);
                    sub_var_name=var_names{1};
                    values = temp_var.(sub_var_name);
                    
                    % Condition if there are existing ROIs in list
                    if isempty(ROI_string)
                        ROI_string = {};
                        ROI_select = struct;
                        extend_index = 0;
                    else
                        extend_index = size(ROI_string, 1);
                    end
                    
                    % Cell Type
                    if iscell(values)
                        for iROI = 1:size(values, 1)
                            full_string = horzcat('No ',num2str(iROI+extend_index),': ', char(values{iROI, 1}), ' :: ',...
                            '[',num2str(values{iROI, 2}),' ', num2str(values{iROI, 3}), ' ',num2str(values{iROI, 4}),...
                            '] :: ', num2str(values{iROI, 5}), ' mm :: ', num2str(values{iROI, 6}), ' mm');
                            ROI_string = vertcat(ROI_string, full_string);
                            ROI_select(iROI+extend_index).ROI_name = char(values{iROI, 1});
                            ROI_select(iROI+extend_index).X = values{iROI, 2};
                            ROI_select(iROI+extend_index).Y = values{iROI, 3};
                            ROI_select(iROI+extend_index).Z = values{iROI, 4};
                            ROI_select(iROI+extend_index).moving_radius = values{iROI, 5};
                            ROI_select(iROI+extend_index).fixed_radius = values{iROI, 6};
                        end
                        
                    % Struct type
                    elseif isstruct(values)
                        
                        list_fields = fieldnames(values);                        
                        for iROI = 1:size(values,2)
                            full_string = horzcat('No ',num2str(iROI+extend_index),': ', char(values(iROI).(list_fields{1})), ' :: ',...
                            '[',num2str(values(iROI).(list_fields{2})),' ', num2str(values(iROI).(list_fields{3})), ' ',...
                            num2str(values(iROI).(list_fields{4})),'] :: ', num2str(values(iROI).(list_fields{5})), ' mm :: ',...
                            num2str(values(iROI).(list_fields{6})), ' mm');
                            ROI_string = vertcat(ROI_string, full_string);
                            ROI_select(iROI+extend_index).ROI_name = char(values(iROI).(list_fields{1}));
                            ROI_select(iROI+extend_index).X = values(iROI).(list_fields{2});
                            ROI_select(iROI+extend_index).Y = values(iROI).(list_fields{3});
                            ROI_select(iROI+extend_index).Z = values(iROI).(list_fields{4});
                            ROI_select(iROI+extend_index).moving_radius = values(iROI).(list_fields{5});
                            ROI_select(iROI+extend_index).fixed_radius = values(iROI).(list_fields{6});
                        end
                        
                    % table type
                    else
                        for iROI = 1:size(values, 1)
                            full_string = horzcat('No ',num2str(iROI+extend_index),': ', char(values{iROI, 1}), ' :: ',...
                            '[',num2str(values{iROI, 2}),' ', num2str(values{iROI, 3}), ' ',num2str(values{iROI, 4}),...
                            '] :: ', num2str(values{iROI, 5}), ' mm :: ', num2str(values{iROI, 6}), ' mm');
                            ROI_string = vertcat(ROI_string, full_string);
                            ROI_select(iROI+extend_index).ROI_name = char(values{iROI, 1});
                            ROI_select(iROI+extend_index).X = values{iROI, 2};
                            ROI_select(iROI+extend_index).Y = values{iROI, 3};
                            ROI_select(iROI+extend_index).Z = values{iROI, 4};
                            ROI_select(iROI+extend_index).moving_radius = values{iROI, 5};
                            ROI_select(iROI+extend_index).fixed_radius = values{iROI, 6};
                        end                        
                    end
                
                catch 
                    error('The selected .mat file is not in the correct format, please try again');
                end

            else
                % Reading .csv , .xlsx, .txt files with ROIs
                temp_table = readtable(ROI_path);
                % Condition if there are existing ROIs in list
                if isempty(ROI_string)
                    ROI_string = {};
                    ROI_select = struct;
                    extend_index = 0;
                else
                    extend_index = size(ROI_string, 1);
                end
                
                for iROI = 1:size(temp_table, 1)
                    full_string = horzcat('No ',num2str(iROI+extend_index),': ', char(temp_table{iROI, 1}), ' :: ',...
                        '[',num2str(temp_table{iROI, 2}),' ', num2str(temp_table{iROI, 3}), ' ',num2str(temp_table{iROI, 4}),...
                        '] :: ', num2str(temp_table{iROI, 5}), ' mm :: ', num2str(temp_table{iROI, 6}), ' mm');
                    ROI_string = vertcat(ROI_string, full_string);
                    ROI_select(iROI+extend_index).ROI_name = char(temp_table{iROI, 1});
                    ROI_select(iROI+extend_index).X = temp_table{iROI, 2};
                    ROI_select(iROI+extend_index).Y = temp_table{iROI, 3};
                    ROI_select(iROI+extend_index).Z = temp_table{iROI, 4};
                    ROI_select(iROI+extend_index).moving_radius = temp_table{iROI, 5};
                    ROI_select(iROI+extend_index).fixed_radius = temp_table{iROI, 6};

                end
                
            end                
            
            fprintf('Number of ROIs present: %d \n', size(ROI_string, 1));
            clear temp_table iROI jROI full_string temp_var
            set(MS_lst, 'String', ROI_string);
            set(MS_lst, 'Enable', 'On');
        else
            disp('ROIs not selected');
        end
        
    end
    
    function remove_all(~,~)
        if isempty(ROI_string)
            fprintf(2,'No ROIs present to remove.\n');
        else
            ROI_string = {};
            ROI_select = [];
            ROI_index = {};
            set(MS_lst, 'String', ROI_string);
            set(MS_lst, 'Enable', 'inactive');
            set(MS_lst, 'value', []);
            disp('All ROIs have been removed');
        end
    end

    function remove(~,~)
        
        if isempty(ROI_string)
            fprintf(2,'No ROIs present to remove.\n');
            
        elseif isempty(ROI_index)
            fprintf(2,'No ROIs selected to remove.\n');
            
        else
            ROI_string = {};
            len_ROI_removed = length(ROI_index);
            ROI_select(ROI_index) = [];
            ROI_index = {};
            
            for iROI = 1:size(ROI_select, 2)
                full_string = horzcat('No ',num2str(iROI),': ', ROI_select(iROI).ROI_name, ' :: ',...
                            '[', num2str(ROI_select(iROI).X),' ', num2str(ROI_select(iROI).Y), ' ',num2str(ROI_select(iROI).Z),...
                            '] :: ', num2str(ROI_select(iROI).moving_radius), ' mm :: ', num2str(ROI_select(iROI).fixed_radius), ' mm');        
                ROI_string = vertcat(ROI_string, full_string);
            end

            set(MS_lst, 'String', ROI_string);
            set(MS_lst,'Value',[]);
            fprintf('Number of ROIs removed: %d \n', len_ROI_removed);        
        end
    end

    function help_window(~,~)
        string_info = {'Define moving spheres manually or select them from the coordinate table (*.mat, *.xlsx, *.csv, *.txt file). The coordinate table must contain the following columns:',...
                    '','1) ROI name','2) Fixed center coordinate: X','3) Fixed center coordinate: Y','4) Fixed center coordinate: Z','5) Moving sphere radius (inner radius)','6) Fixed sphere radius (outer radius)',...
                    '','For examples of coordinate tables, see the TMFC_toolbox folder.','','The sphere center will be moved to the local maximum inside a fixed sphere of larger radius. Each sphere will be masked by the corresponding subject''s individual first-level mask.',...
                    '','Local maxima are determined using the omnibus F-contrast for the selected conditions of interest. ','','Additionally, moving spheres can be masked by the thresholded F-map of an individual subject. This can significantly reduce ROI size.'};
        
        MS_ROI_HW = figure('Name', 'Define moving spheres: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.67 0.31 0.22 0.50],'MenuBar','none','ToolBar','none','color','w','Resize','off','WindowStyle','Modal');
        
        if isunix; fontscale = 0.8; else; fontscale = 1; end

        MS_HW_txt = uicontrol(MS_ROI_HW,'Style','text','String',string_info ,'Units', 'normalized', 'Position', [0.05 0.16 0.89 0.80], 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.0351*fontscale,'backgroundcolor','w');
        MS_HW_OK = uicontrol(MS_ROI_HW,'Style','pushbutton','String', 'OK','Units', 'normalized', 'Position', [0.34 0.06 0.30 0.06],'callback', @MS_HW_close,'fontunits','normalized', 'fontSize', 0.35);
        movegui(MS_ROI_HW,'center');
        
        function MS_HW_close(~,~)
            close(MS_ROI_HW);
        end      
    end

    function export(~,~)
        if ~isempty(ROI_select)
            fprintf('\n Number of ROIs exported are: %d\n', size(ROI_select,2));
            uiresume(MS_GUI);
        else
            fprintf('No ROIs added to export\n');
        end
    end

    uiwait(MS_GUI);
    delete(MS_GUI);
end

%% ===================[Add custom moving sphere GUI]=======================
function [ROI_name, center_coordinates, radius] = add_moving_sphere_GUI()

    % Variables to store new ROI info from user
    ROI_name = '';
    center_coordinates = '';
    radius = '';
        
    add_NMS_GUI = figure('Name', 'Add new sphere', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.27 0.32 0.28],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','on','CloseRequestFcn', @close_new_ROI, 'WindowStyle', 'modal');
    add_NMS_txt_1 = uicontrol(add_NMS_GUI,'Style','text','String', 'Define moving sphere inside fixed sphere','Units', 'normalized', 'Position',[0.08 0.84 0.85 0.1],'fontunits','normalized', 'fontSize', 0.55,'backgroundcolor','w');
    add_NMS_txt_2 = uicontrol(add_NMS_GUI , 'Style', 'text', 'String', 'ROI name','Units', 'normalized', 'Position',[0.272 0.74 0.450 0.08],'fontunits','normalized', 'fontSize', 0.65,'HorizontalAlignment','center','backgroundcolor','w');
    add_NMS_txt_3 = uicontrol(add_NMS_GUI , 'Style', 'text', 'String', {'Center coordinates of fixed sphere', ''},'Units', 'normalized', 'Position',[0.07 0.395 0.450 0.14],'fontunits','normalized', 'fontSize', 0.35,'HorizontalAlignment','center','backgroundcolor','w');
    add_NMS_txt_3_X = uicontrol(add_NMS_GUI , 'Style', 'text', 'String', 'X','Units', 'normalized', 'Position',[0.1 0.385 0.05 0.08],'fontunits','normalized', 'fontSize', 0.63,'HorizontalAlignment','center','backgroundcolor','w');
    add_NMS_txt_3_Y = uicontrol(add_NMS_GUI , 'Style', 'text', 'String', 'Y','Units', 'normalized', 'Position',[0.265 0.385 0.05 0.08],'fontunits','normalized', 'fontSize', 0.63,'HorizontalAlignment','center','backgroundcolor','w');
    add_NMS_txt_3_Z = uicontrol(add_NMS_GUI , 'Style', 'text', 'String', 'Z','Units', 'normalized', 'Position',[0.44 0.385 0.05 0.08],'fontunits','normalized', 'fontSize', 0.63,'HorizontalAlignment','center','backgroundcolor','w');
    add_NMS_txt_4 = uicontrol(add_NMS_GUI , 'Style', 'text', 'String', {'Moving sphere', 'radius, mm'},'Units', 'normalized', 'Position',[0.549 0.395 0.20 0.14],'fontunits','normalized', 'fontSize', 0.35,'HorizontalAlignment','center','backgroundcolor','w');
    add_NMS_txt_5 = uicontrol(add_NMS_GUI , 'Style', 'text', 'String', {'Fixed sphere', 'radius, mm'},'Units', 'normalized', 'Position',[0.753 0.395 0.20 0.14],'fontunits','normalized', 'fontSize', 0.35,'HorizontalAlignment','center','backgroundcolor','w');
    
%     MS_name_info = uicontrol(add_NMS_GUI, 'Style','text', 'String','Not allowed: < > : " / \ | ? *', ...
%         'Units','normalized','Position',[0.048 0.55 0.90 0.07], ...
%         'FontUnits','normalized','FontSize',0.47, 'ForegroundColor',[0.65 0 0], ...
%         'BackgroundColor','w','HorizontalAlignment','left');

    MS_E1 = uicontrol(add_NMS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.048 0.63 0.90 0.115],'fontunits','normalized', 'fontSize', 0.45);
    MS_E2_X = uicontrol(add_NMS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.049 0.28 0.15 0.115],'fontunits','normalized', 'fontSize', 0.45);
    MS_E2_Y = uicontrol(add_NMS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.219 0.28 0.15 0.115],'fontunits','normalized', 'fontSize', 0.45);
    MS_E2_Z = uicontrol(add_NMS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.39 0.28 0.15 0.115],'fontunits','normalized', 'fontSize', 0.45);
    MS_E3 = uicontrol(add_NMS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.563 0.28 0.180 0.115],'fontunits','normalized', 'fontSize', 0.45);
    MS_E4 = uicontrol(add_NMS_GUI , 'Style', 'edit', 'String', '','Units', 'normalized', 'Position',[0.768 0.28 0.180 0.115],'fontunits','normalized', 'fontSize', 0.45);
    MS_OK = uicontrol(add_NMS_GUI,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.36 0.06 0.30 0.13],'fontunits','normalized', 'fontSize', 0.36,'callback', @ok_data);
    movegui(add_NMS_GUI,'center');

        
    % Function to close GUI when ROI is not entered
    function close_new_ROI(~,~)
        ROI_name = '';
        center_coordinates = '';
        radius = '';
        uiresume(add_NMS_GUI);
    end

    % Function to check and export created ROI
    function ok_data(~,~)
        
        % Extracting ROI name
        tmp_name = get(MS_E1, 'String');
        
        % Checking if name is empty
        if ~strcmp(tmp_name,'') && ~strcmp(tmp_name(1),' ')
            % Reject invalid filesystem characters before creating the ROI.
            if ~valid_TMFC_output_name(tmp_name,'ROI')
                return;
            end

            % Set ROI name
            ROI_name = tmp_name;
            
            % Extracting Center Coordinates [X Y Z]
            tmp_center_X = str2double(get(MS_E2_X, 'String'));
            tmp_center_Y = str2double(get(MS_E2_Y, 'String'));
            tmp_center_Z = str2double(get(MS_E2_Z, 'String'));           
            
            % Check for empty coordinates
            if ~isnan(tmp_center_X) && ~isnan(tmp_center_Y) && ~isnan(tmp_center_Z)
                
                % Check if coordinates are real numbers
                if (isreal(tmp_center_X)) && (isreal(tmp_center_Y)) && (isreal(tmp_center_Z))
                    
                    center_coordinates = {tmp_center_X, tmp_center_Y, tmp_center_Z};
                    
                    % Extracting Radius of Fixed Sphere
                    tmp_rad_m = str2double(get(MS_E3, 'String'));
                    tmp_rad_f = str2double(get(MS_E4, 'String'));
                    
                    % Check for empty Radius value
                    if isnan(tmp_rad_m)
                        fprintf(2,'Moving sphere radius not entered or is invalid, please re-enter.\n'); 
                    elseif isnan(tmp_rad_f)
                        fprintf(2,'Fixed sphere radius not entered or is invalid, please re-enter.\n'); 
                    else                        
                        % Check if radius is a non-negative real number
                        if ~(isreal(tmp_rad_m))
                            fprintf(2,'Please enter a non-negative real number for radius of (inner) moving spheres.\n');
                        elseif tmp_rad_m <= 0 
                            fprintf(2,'Please enter a non-negative real number for radius of (inner) moving spheres.\n');
                        elseif ~(isreal(tmp_rad_f))
                            fprintf(2,'Please enter a non-negative real number for radius of (outer) fixed spheres.\n');
                        elseif tmp_rad_f <= 0 
                            fprintf(2,'Please enter a non-negative real number for radius of (outer) fixed spheres.\n');
                        elseif tmp_rad_m >= tmp_rad_f
                            fprintf(2,'The radius of (inner) moving spheres cannot be smaller or equal to the radius of (outer) fixed spheres, please re-enter.\n'); 
                        else                     
                            % Exporting selected variables
                            radius = {tmp_rad_m, tmp_rad_f};     
                            fprintf('Name of ROI: %s.\n', ROI_name);   
                            fprintf('Coordinates (X, Y, Z) %d %d %d\n', center_coordinates{1}, center_coordinates{2}, center_coordinates{3});
                            fprintf('Radius of Moving sphere: %d.\n', radius{1});
                            fprintf('Radius of Fixed sphere: %d.\n', radius{2});
                            uiresume(add_NMS_GUI);
                        end
                    end
                else
                    fprintf(2,'Please enter a real number for coordinates.\n');
                end
            else 
                fprintf(2,'Coordinates are not entered or is invalid, please re-enter.\n');                
            end
        else
            fprintf(2,'ROI Name not entered or is invalid, please re-enter.\n');
        end
    end

    uiwait(add_NMS_GUI);
    delete(add_NMS_GUI);
end

%% ============[Moving spheres inside ROI binary images GUI]===============
function [radius_vector] = select_ROIs_case_4(nROI)

radius_vector = {};

if isunix; fontscale = 0.8; else; fontscale = 1; end

vec_rad_GUI = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.30 0.22 0.18],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','on','CloseRequestFcn',@exit);
vec_rad_txt = uicontrol(vec_rad_GUI,'Style','text','String', 'Enter vector for radii of moving spheres','Units', 'normalized', 'Position',[0.075 0.64 0.85 0.18],'fontunits','normalized', 'fontSize', 0.54*fontscale,'HorizontalAlignment', 'center','backgroundcolor','w');
vec_rad_edit = uicontrol(vec_rad_GUI,'Style','edit','String', '','Units', 'normalized', 'Position',[0.075 0.44 0.85 0.2],'fontunits','normalized', 'fontSize', 0.46,'backgroundcolor','w');
vec_rad_OK = uicontrol(vec_rad_GUI,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.074 0.12 0.35 0.19],'fontunits','normalized', 'fontSize', 0.36,'callback', @extract_vector);
vec_rad_help = uicontrol(vec_rad_GUI,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.575 0.12 0.35 0.19],'fontunits','normalized', 'fontSize', 0.36,'callback', @help_win);
movegui(vec_rad_GUI,'center');

    function extract_vector(~,~)
        tmp_vector = get(vec_rad_edit, 'String');
        
        if isnan(tmp_vector) 
            fprintf(2,'Vector contain NaNs, please try again.\n');            
        else
            try
                radius_vector = str2num(tmp_vector);
                if length(radius_vector) == nROI
                    uiresume(vec_rad_GUI);
                else
                    fprintf(2,'The length of the radius vector must be equal to the number of selected ROI binary images.\n');
                end
            catch
                fprintf(2,'Entered vector is incorrect or invalid, please try again.\n');
            end
        end
    end

    function exit(~,~)
        radius_vector = {};
        uiresume(vec_rad_GUI);
    end

    function help_win(~,~)
        help_text = {'Suppose you select 100 ROI masks. You need to define the radius of moving spheres inside each of these 100 ROI masks.',...
            '','If you want to use the same radii for all spheres (e.g. 5 mm), enter the vector [5*ones(1,100)] or enter the scalar [5].',...
            '','If you want to use 5 mm radii for the first 50 ROIs and 4 mm radii for the last 50 ROIs, enter the vector: [5*ones(1,50) 4*ones(1,50)].',...
            '','You can also copy and paste the radius vector from an external file (*.mat, *.xlsx, *.csv, *.txt).',...
            '','The length of the vector should be equal to the number of selected ROI masks.'};

        if isunix; fontscale = 0.9; else; fontscale = 1; end
        
        vr_help = figure('Name', 'Define moving spheres: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.25 0.22 0.45],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle','modal');
        vr_help_txt = uicontrol(vr_help,'Style','text','String', help_text,'Units', 'normalized', 'Position',[0.07 0.18 0.86 0.75],'fontunits','normalized', 'fontSize', 0.045*fontscale,'HorizontalAlignment', 'left','backgroundcolor','w');
        vr_help_ok = uicontrol(vr_help,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.29 0.08 0.40 0.08],'fontunits','normalized', 'fontSize', 0.36,'callback',@close_help);
        movegui(vr_help,'center');
        function close_help(~,~)
            close(vr_help);
        end
    end

uiwait(vec_rad_GUI);
delete(vec_rad_GUI);

end

%% ===============[ Validate filesystem-safe ROI names ]==================
function ok = valid_TMFC_output_name(name,name_type)

% Validate names used as folder names or NIfTI filename stems.
% The restrictions apply on all platforms for cross-platform projects.
ok = false;

if ~ischar(name) || isempty(name) || isempty(strtrim(name))
    fprintf(2,'%s name must not be empty.\n',name_type);
    return;
end

forbidden = '<>:"/\|?*';
if any(ismember(name,forbidden)) || any(double(name) < 32)
    fprintf(2,'Invalid %s name "%s". Characters not allowed: %s\n', ...
        name_type,name,'< > : " / \ | ? *');
    return;
end

if name(1) == ' ' || name(end) == ' ' || name(end) == '.'
    fprintf(2,'Invalid %s name "%s". Names must not begin or end with a space or end with a period.\n', ...
        name_type,name);
    return;
end

% Windows reserves these device names, also when followed by a suffix.
reserved = {'CON','PRN','AUX','NUL', ...
    'COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9', ...
    'LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9'};
name_base = regexp(name,'^[^.]+','match','once');
if any(strcmpi(name_base,reserved))
    fprintf(2,'Invalid %s name "%s". This name is reserved by Windows.\n', ...
        name_type,name);
    return;
end

ok = true;
end
