function [ROI_set,empty_ROI_list] = tmfc_create_ROI_set(tmfc,ROI_definition)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Creates an ROI set without GUI input. Each ROI is masked separately for
% each subject using the individual first-level mask.nii located in the same
% folder as the subject's SPM.mat file. Empty ROIs are always removed.
% Heavily cropped ROIs can be removed using the optional crop_threshold
% field.
%
% FORMAT [ROI_set,empty_ROI_list] = tmfc_create_ROI_set(tmfc,ROI_definition)
%
% Common inputs:
%   ROI_definition.set_name
%   ROI_definition.type             - 'binary_images'
%                                   - 'subject_specific_binary_images'        
%                                   - 'fixed_spheres'
%                                   - 'moving_spheres_inside_fixed_spheres'
%                                   - 'moving_spheres_inside_binary_images'
%   ROI_definition.ROIs
%   ROI_definition.crop_threshold   - Percentage threshold (0-100), optional
%
% Case 1: binary_images
% Same binary ROI images are used for all subjects.
%   ROI_definition.ROIs(iROI).name
%   ROI_definition.ROIs(iROI).path
%
% Case 2: subject_specific_binary_images
% A corresponding individual binary ROI image is specified for each subject.
% All subjects must have the same number and ordering of ROIs.
%   ROI_definition.ROIs(iROI).name
%   ROI_definition.ROIs(iROI).path(iSub).subjects
%
% Case 3: fixed_spheres
%   ROI_definition.ROIs(iROI).name
%   ROI_definition.ROIs(iROI).X
%   ROI_definition.ROIs(iROI).Y
%   ROI_definition.ROIs(iROI).Z
%   ROI_definition.ROIs(iROI).radius
%
% Case 4: moving_spheres_inside_fixed_spheres
%   ROI_definition.ROIs(iROI).name
%   ROI_definition.ROIs(iROI).X
%   ROI_definition.ROIs(iROI).Y
%   ROI_definition.ROIs(iROI).Z
%   ROI_definition.ROIs(iROI).moving_radius
%   ROI_definition.ROIs(iROI).fixed_radius
%   ROI_definition.F.conditions     - Conditions used to create the omnibus
%                                     F-contrast. Use the structure returned
%                                     by tmfc_get_conditions or tmfc_conditions_GUI.
%   ROI_definition.F.threshold      - Uncorrected voxel-level threshold for
%                                     the F-contrast (e.g. 0.005).
%   ROI_definition.F.mask           - Mask moving spheres by the thresholded
%                                     F-map: 0 = No, 1 = Yes.
%
% Case 5: moving_spheres_inside_binary_images
%   ROI_definition.ROIs(iROI).name
%   ROI_definition.ROIs(iROI).path
%   ROI_definition.ROIs(iROI).radius
%   ROI_definition.F.conditions
%   ROI_definition.F.threshold
%   ROI_definition.F.mask
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
elseif ~isfield(ROI_definition,'set_name') || isempty(ROI_definition.set_name)
    error('ROI set name is not specified.');
elseif ~isfield(ROI_definition,'type') || isempty(ROI_definition.type)
    error('ROI type is not specified.');
elseif ~isfield(ROI_definition,'ROIs') || isempty(ROI_definition.ROIs)
    error('ROIs are not specified.');
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

% Optional settings
if ~isfield(ROI_definition,'crop_threshold')
    ROI_definition.crop_threshold = [];
end

if ~isempty(ROI_definition.crop_threshold)
    if ~isnumeric(ROI_definition.crop_threshold) || length(ROI_definition.crop_threshold) ~= 1 || ...
            ROI_definition.crop_threshold < 0 || ROI_definition.crop_threshold > 100
        error('ROI crop threshold must be between 0 and 100.');
    end
end

if ~isfield(ROI_definition,'GUI')
    ROI_definition.GUI = 0;
end

GUI = ROI_definition.GUI;
ROI_set_name = ROI_definition.set_name;
ROI_type = ROI_definition.type;
nSub = length(tmfc.subjects);
nROI = length(ROI_definition.ROIs);

% Check ROI set name uniqueness
existing_set_names = {};
if isfield(tmfc,'ROI_set') && ~isempty(tmfc.ROI_set)
    existing_set_names = [existing_set_names {tmfc.ROI_set.set_name}];
end
if isfield(tmfc,'ROI_set_legacy') && ~isempty(tmfc.ROI_set_legacy)
    existing_set_names = [existing_set_names {tmfc.ROI_set_legacy.set_name}];
end
if any(strcmpi(ROI_set_name,existing_set_names))
    error('ROI set name "%s" already exists. ROI set names must be unique.',ROI_set_name);
end

% Check ROI name uniqueness
ROI_names = cell(1,nROI);
for iROI = 1:nROI
    check_fields(ROI_definition.ROIs(iROI),{'name'},iROI);
    ROI_names{iROI} = ROI_definition.ROIs(iROI).name;
end
for iROI = 1:nROI-1
    if any(strcmpi(ROI_names{iROI},ROI_names(iROI+1:end)))
        error('ROI name "%s" is duplicated. ROI names within an ROI set must be unique.',ROI_names{iROI});
    end
end

valid_types = {'binary_images','subject_specific_binary_images','fixed_spheres', ...
    'moving_spheres_inside_fixed_spheres','moving_spheres_inside_binary_images'};
if ~any(strcmp(ROI_type,valid_types))
    error('Invalid ROI type.');
end

% Check F-contrast settings
if strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
    if ~isfield(ROI_definition,'F') || ...
        ~isstruct(ROI_definition.F) || isempty(ROI_definition.F) || ...
        ~isfield(ROI_definition.F,'conditions') || ...
        ~isfield(ROI_definition.F,'threshold') || ...
        ~isfield(ROI_definition.F,'mask')
        error('F-contrast settings are not specified.');
    end

    conditions = ROI_definition.F.conditions;
    Fthresh = ROI_definition.F.threshold;
    Fmask = ROI_definition.F.mask;

    if ~isstruct(conditions)
        error('F-contrast conditions are invalid.');
    elseif ~isnumeric(Fthresh) || length(Fthresh) ~= 1 || Fthresh < 0 || Fthresh > 1
        error('F-contrast threshold must be between 0 and 1.');
    elseif ~ismember(Fmask,[0 1])
        error('F-contrast mask status must be 0 or 1.');
    end
end

% Reference space
SPM   = load(tmfc.subjects(1).path).SPM;
XYZ   = SPM.xVol.XYZ;
XYZmm = SPM.xVol.M(1:3,:)*[XYZ; ones(1,size(XYZ,2))];

% Define ROI set structure
ROI_set.set_name = ROI_set_name;
ROI_set.type = ROI_type;

% Store F-contrast settings for moving ROIs
if strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
    ROI_set.F.conditions = conditions;
    ROI_set.F.threshold = Fthresh;
    ROI_set.F.mask = Fmask;
end

switch ROI_type
    % ---------------------------------------------------------------------
    case 'binary_images'
        for iROI = 1:nROI
            check_fields(ROI_definition.ROIs(iROI),{'name','path'},iROI);
            ROI_set.ROIs(iROI).name = ROI_definition.ROIs(iROI).name;
            ROI_set.ROIs(iROI).path = ROI_definition.ROIs(iROI).path;       
            for jSub = 1:nSub
                ROI_set.ROIs(iROI).path_masked(jSub).subjects = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs', ...
                    tmfc.subjects(jSub).name,[ROI_set.ROIs(iROI).name '_masked.nii']);
            end
            if ~exist(ROI_set.ROIs(iROI).path,'file')
                error('ROI mask does not exist: %s',ROI_set.ROIs(iROI).path);
            end
        end

    % ---------------------------------------------------------------------
    case 'subject_specific_binary_images'
        for iROI = 1:nROI
            check_fields(ROI_definition.ROIs(iROI),{'name','path'},iROI);
            ROI_set.ROIs(iROI).name = ROI_definition.ROIs(iROI).name;

            if length(ROI_definition.ROIs(iROI).path) ~= nSub
                error('ROI No %d: number of subject-specific ROI paths must match the number of subjects.',iROI);
            end

            for jSub = 1:nSub
                if ~isfield(ROI_definition.ROIs(iROI).path(jSub),'subjects') || ...
                        isempty(ROI_definition.ROIs(iROI).path(jSub).subjects)
                    error('ROI No %d: subject-specific ROI path is not specified for subject %d.',iROI,jSub);
                end

                ROI_set.ROIs(iROI).path(jSub).subjects = ROI_definition.ROIs(iROI).path(jSub).subjects;

                ROI_set.ROIs(iROI).path_masked(jSub).subjects = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs', ...
                    tmfc.subjects(jSub).name,[ROI_set.ROIs(iROI).name '_masked.nii']);

                if ~exist(ROI_set.ROIs(iROI).path(jSub).subjects,'file')
                    error('ROI mask does not exist: %s',ROI_set.ROIs(iROI).path(jSub).subjects);
                end
            end
        end    

    % ---------------------------------------------------------------------
    case 'fixed_spheres'
        for iROI = 1:nROI
            check_fields(ROI_definition.ROIs(iROI),{'name','X','Y','Z','radius'},iROI);
            ROI_set.ROIs(iROI).name = ROI_definition.ROIs(iROI).name;
            for jSub = 1:nSub
                ROI_set.ROIs(iROI).path_masked(jSub).subjects = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs', ...
                    tmfc.subjects(jSub).name,[ROI_set.ROIs(iROI).name '_masked.nii']);
            end
            ROI_set.ROIs(iROI).X = ROI_definition.ROIs(iROI).X;
            ROI_set.ROIs(iROI).Y = ROI_definition.ROIs(iROI).Y;
            ROI_set.ROIs(iROI).Z = ROI_definition.ROIs(iROI).Z;
            ROI_set.ROIs(iROI).radius = ROI_definition.ROIs(iROI).radius;
        end

    % ---------------------------------------------------------------------
    case 'moving_spheres_inside_fixed_spheres'
        for iROI = 1:nROI
            check_fields(ROI_definition.ROIs(iROI),{'name','X','Y','Z','moving_radius','fixed_radius'},iROI);
            ROI_set.ROIs(iROI).name = ROI_definition.ROIs(iROI).name;
            for jSub = 1:nSub
                ROI_set.ROIs(iROI).path_masked(jSub).subjects = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs', ...
                    tmfc.subjects(jSub).name,[ROI_set.ROIs(iROI).name '_masked.nii']);
            end
            ROI_set.ROIs(iROI).X = ROI_definition.ROIs(iROI).X;
            ROI_set.ROIs(iROI).Y = ROI_definition.ROIs(iROI).Y;
            ROI_set.ROIs(iROI).Z = ROI_definition.ROIs(iROI).Z;
            ROI_set.ROIs(iROI).moving_radius = ROI_definition.ROIs(iROI).moving_radius;
            ROI_set.ROIs(iROI).fixed_radius = ROI_definition.ROIs(iROI).fixed_radius;
        end

    % ---------------------------------------------------------------------
    case 'moving_spheres_inside_binary_images'
        for iROI = 1:nROI
            check_fields(ROI_definition.ROIs(iROI),{'name','path','radius'},iROI);
            ROI_set.ROIs(iROI).name = ROI_definition.ROIs(iROI).name;
            ROI_set.ROIs(iROI).path = ROI_definition.ROIs(iROI).path;
            for jSub = 1:nSub
                ROI_set.ROIs(iROI).path_masked(jSub).subjects = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs', ...
                    tmfc.subjects(jSub).name,[ROI_set.ROIs(iROI).name '_masked.nii']);
            end
            ROI_set.ROIs(iROI).radius = ROI_definition.ROIs(iROI).radius;

            if ~exist(ROI_set.ROIs(iROI).path,'file')
                error('ROI mask does not exist: %s',ROI_set.ROIs(iROI).path);
            end
        end
end

% -------------------------------------------------------------------------
% Clear & create 'Masked_ROIs' folder
if isdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name))
    rmdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name),'s');
    pause(0.1);
end

if ~isdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs'))
    mkdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs'));
end


for iSub = 1:nSub
    mkdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name));
end

% -------------------------------------------------------------------------
% Get individual subject masks
sub_mask = cell(nSub,1);

for iSub = 1:nSub
    sub_mask{iSub,1} = fullfile(fileparts(tmfc.subjects(iSub).path),'mask.nii');

    if ~exist(sub_mask{iSub,1},'file')
        error('First-level mask does not exist: %s',sub_mask{iSub,1});
    end
end

% -------------------------------------------------------------------------
% Calculate F-contrast
if strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images')

    if GUI
        w = waitbar(0,'Please wait...','Name','Calculating F-contrasts');
    end

    contrast_idx = nan(nSub,1);

    for iSub = 1:nSub
        SPM = load(tmfc.subjects(iSub).path).SPM;
        cond_col = tmfc_get_F_contrast_columns(SPM,conditions,session_mode);
        weights = zeros(length(cond_col),size(SPM.xX.X,2));

        for iCond = 1:length(cond_col)
            weights(iCond,cond_col(iCond)) = 1;
        end

        % Check if contrast already exists
        idx = [];
        if isfield(SPM,'xCon') && ~isempty(SPM.xCon)
            idx = find(arrayfun(@(c) isequal(c.c, weights') && isfield(c,'STAT') && strcmpi(c.STAT,'F'), SPM.xCon), 1, 'first');
            nCon = numel(SPM.xCon);
        else
            nCon = 0;
        end

        % Estimate contrast only if missing
        if isempty(idx)
            matlabbatch = [];
            matlabbatch{1}.spm.stats.con.spmmat = {tmfc.subjects(iSub).path};
            matlabbatch{1}.spm.stats.con.consess{1}.fcon.name = 'F_omnibus';
            matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights = weights;
            matlabbatch{1}.spm.stats.con.consess{1}.fcon.sessrep = 'none';
            matlabbatch{1}.spm.stats.con.delete = 0;
            spm_get_defaults('cmdline',true);
            spm_jobman('run',matlabbatch);
            idx = nCon + 1;
        end

        contrast_idx(iSub) = idx;

        if GUI
            try
                waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
            end
        end
    end

    if GUI
        try
            close(w);
        end
    end
end

% -------------------------------------------------------------------------
% Create spheres
if ~strcmp(ROI_type,'binary_images') && ~strcmp(ROI_type,'subject_specific_binary_images')

    if GUI
        w = waitbar(0,'Please wait...','Name','Creating spherical masks');
    end

    switch ROI_type
        % -----------------------------------------------------------------
        case 'fixed_spheres'
            for iROI = 1:nROI
                job.spmmat = {tmfc.subjects(1).path};
                job.name = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',ROI_set.ROIs(iROI).name);
                job.roi{1}.sphere.centre = [ROI_set.ROIs(iROI).X ROI_set.ROIs(iROI).Y ROI_set.ROIs(iROI).Z];
                job.roi{1}.sphere.radius = ROI_set.ROIs(iROI).radius;
                job.roi{1}.sphere.move.fixed = 1;
                job.expression = 'i1';
                tmfc_create_spheres(job);
                clear job

                if GUI
                    try
                        waitbar(iROI/nROI,w,['ROI No ' num2str(iROI,'%.f')]);
                    end
                end
            end

        % -----------------------------------------------------------------
        case 'moving_spheres_inside_fixed_spheres'
            if GUI
                start_time = tic;
                count_sub = 1;
                cleanupObj = onCleanup(@unfreeze_after_ctrl_c);
            end

            for iSub = 1:nSub
                SPM = load(tmfc.subjects(iSub).path).SPM;

                for jROI = 1:nROI
                    job.spmmat = {tmfc.subjects(iSub).path};
                    job.name = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,ROI_set.ROIs(jROI).name);
                    job.roi{1}.spm.spmmat = {tmfc.subjects(iSub).path};
                    job.roi{1}.spm.contrast = contrast_idx(iSub);
                    job.roi{1}.spm.conjunction = 1;
                    job.roi{1}.spm.threshdesc = 'none';
                    job.roi{1}.spm.thresh = Fthresh;
                    job.roi{1}.spm.extent = 0;
                    job.roi{1}.spm.mask = struct('contrast', {}, 'thresh', {}, 'mtype', {});
                    job.roi{2}.sphere.centre = [ROI_set.ROIs(jROI).X ROI_set.ROIs(jROI).Y ROI_set.ROIs(jROI).Z];
                    job.roi{2}.sphere.radius = ROI_set.ROIs(jROI).fixed_radius;
                    job.roi{2}.sphere.move.fixed = 1;
                    job.roi{3}.sphere.centre = [ROI_set.ROIs(jROI).X ROI_set.ROIs(jROI).Y ROI_set.ROIs(jROI).Z];
                    job.roi{3}.sphere.radius = ROI_set.ROIs(jROI).moving_radius;
                    job.roi{3}.sphere.move.global.spm = 1;
                    job.roi{3}.sphere.move.global.mask = 'i2';

                    if Fmask == 0
                        job.expression = 'i3';
                    elseif Fmask == 1
                        job.expression = 'i1&i3';
                    end

                    jobs{jROI} = job;
                    clear job
                end
                
                % Create spheres
                switch tmfc.defaults.parallel
                    case 0 % Sequential
                        for jROI = 1:nROI
                            tmfc_create_spheres(jobs{jROI});
                        end
                    case 1 % Parallel
                        parfor jROI = 1:nROI
                            tmfc_create_spheres(jobs{jROI});
                        end
                end
                
                % Update waitbar
                if GUI
                    elapsed_time = toc(start_time);
                    time_per_sub = elapsed_time/count_sub;
                    count_sub = count_sub + 1;
                    time_remaining = (nSub-iSub)*time_per_sub;
                    hms = fix(mod((time_remaining), [0, 3600, 60]) ./ [3600, 60, 1]);
                    try
                        waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec] remaining']);
                    end
                end

                clear SPM jobs
            end

        % -----------------------------------------------------------------
        case 'moving_spheres_inside_binary_images'
            centre = struct;

            % Calculate centroid coordinates before masking
            for iROI = 1:nROI
                binary_mask = spm_data_read(ROI_set.ROIs(iROI).path,'xyz',XYZ);
                coord = XYZmm(:,(binary_mask ~= 0));
                centre(iROI).X = mean(coord(1,:));
                centre(iROI).Y = mean(coord(2,:));
                centre(iROI).Z = mean(coord(3,:));
            end

            if GUI
                start_time = tic;
                count_sub = 1;
                cleanupObj = onCleanup(@unfreeze_after_ctrl_c);
            end

            for iSub = 1:nSub
                SPM = load(tmfc.subjects(iSub).path).SPM;

                for jROI = 1:nROI
                    job.spmmat = {tmfc.subjects(iSub).path};
                    job.name = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,ROI_set.ROIs(jROI).name);
                    job.roi{1}.spm.spmmat = {''};
                    job.roi{1}.spm.contrast = contrast_idx(iSub);
                    job.roi{1}.spm.conjunction = 1;
                    job.roi{1}.spm.threshdesc = 'none';
                    job.roi{1}.spm.thresh = Fthresh;
                    job.roi{1}.spm.extent = 0;
                    job.roi{1}.spm.mask = struct('contrast', {}, 'thresh', {}, 'mtype', {});
                    job.roi{2}.mask.image = {ROI_set.ROIs(jROI).path};
                    job.roi{2}.mask.threshold = 0.1;
                    job.roi{3}.sphere.centre = [centre(jROI).X centre(jROI).Y centre(jROI).Z];
                    job.roi{3}.sphere.radius = ROI_set.ROIs(jROI).radius;
                    job.roi{3}.sphere.move.global.spm = 1;
                    job.roi{3}.sphere.move.global.mask = 'i2';

                    if Fmask == 0
                        job.expression = 'i2&i3';
                    elseif Fmask == 1
                        job.expression = 'i1&i2&i3';
                    end

                    jobs{jROI} = job;
                    clear job
                end
                
                % Create spheres
                switch tmfc.defaults.parallel
                    case 0 % Sequential
                        for jROI = 1:nROI
                            tmfc_create_spheres(jobs{jROI});
                        end
                    case 1 % Parallel
                        parfor jROI = 1:nROI
                            tmfc_create_spheres(jobs{jROI});
                        end
                end

                % Update waitbar
                if GUI
                    elapsed_time = toc(start_time);
                    time_per_sub = elapsed_time/count_sub;
                    count_sub = count_sub + 1;
                    time_remaining = (nSub-iSub)*time_per_sub;
                    hms = fix(mod((time_remaining), [0, 3600, 60]) ./ [3600, 60, 1]);
                    try
                        waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec] remaining']);
                    end
                end

                clear SPM jobs
            end
    end

    if GUI
        try
            close(w);
        end
    end
end

% -------------------------------------------------------------------------
% Calculate ROI size before masking
if GUI
    w = waitbar(0,'Please wait...','Name','Calculating raw ROI sizes');
end

raw_size = nan(nROI,nSub);

for iROI = 1:nROI

    switch ROI_type
        %------------------------------------------------------------------
        case 'binary_images'
            ROI_mask = spm_vol(ROI_set.ROIs(iROI).path);
            for jSub = 1:nSub
                subject_mask = spm_vol(sub_mask{jSub});
                Y = zeros(subject_mask.dim(1:3));           
                % Adjust dimensions, orientation, and voxel sizes
                for p = 1:subject_mask.dim(3)
                    B = spm_matrix([0 0 -p 0 0 0 1 1 1]);
                    X = zeros(1,prod(subject_mask.dim(1:2)));
                    M = inv(B * inv(subject_mask.mat) * ROI_mask.mat);
                    d = spm_slice_vol(ROI_mask, M, subject_mask.dim(1:2), 1);
                    d(isnan(d)) = 0;
                    X(1,:) = d(:)';
                    Y(:,:,p) = reshape(X,subject_mask.dim(1:2));
                end
                raw_size(iROI,jSub) = nnz(Y);
            end

        % -----------------------------------------------------------------
        case 'subject_specific_binary_images'
            for jSub = 1:nSub
                subject_mask = spm_vol(sub_mask{jSub});
                ROI_mask = spm_vol(ROI_set.ROIs(iROI).path(jSub).subjects);
                Y = zeros(subject_mask.dim(1:3));
                % Adjust dimensions, orientation, and voxel sizes
                for p = 1:subject_mask.dim(3)
                    B = spm_matrix([0 0 -p 0 0 0 1 1 1]);
                    X = zeros(1,prod(subject_mask.dim(1:2)));
                    M = inv(B * inv(subject_mask.mat) * ROI_mask.mat);
                    d = spm_slice_vol(ROI_mask,M,subject_mask.dim(1:2),1);
                    d(isnan(d)) = 0;
                    X(1,:) = d(:)';
                    Y(:,:,p) = reshape(X,subject_mask.dim(1:2));
                end
                raw_size(iROI,jSub) = nnz(Y);
            end

        % -----------------------------------------------------------------
        case 'fixed_spheres'
            binary_mask = spm_data_read(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_set.ROIs(iROI).name '.nii']),'xyz',XYZ);
            raw_size(iROI,:) = nnz(binary_mask);

        % -----------------------------------------------------------------    
        otherwise
            for jSub = 1:nSub
                binary_mask = spm_data_read(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(jSub).name,[ROI_set.ROIs(iROI).name '.nii']),'xyz',XYZ);
                raw_size(iROI,jSub) = nnz(binary_mask);
            end
    end

    if GUI
        try
            waitbar(iROI/nROI,w,['ROI No ' num2str(iROI,'%.f')]);
        end
    end
end

if GUI
    try
        close(w);
    end
end

% -------------------------------------------------------------------------
% Mask ROI images by individual subject masks
if GUI
    w = waitbar(0,'Please wait...','Name','Masking ROIs by individual subject masks');
    start_time = tic;
    count_sub = 1;
    cleanupObj = onCleanup(@unfreeze_after_ctrl_c);
end

for iSub = 1:nSub

    input_images = cell(2,1);
    input_images{1,1} = sub_mask{iSub};

    switch ROI_type
        % -----------------------------------------------------------------
        case 'binary_images'
            for jROI = 1:nROI
                input_images{2,1} = ROI_set.ROIs(jROI).path;
                ROI_mask = ROI_set.ROIs(jROI).path_masked(iSub).subjects;
                spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
            end
        % -----------------------------------------------------------------
        case 'subject_specific_binary_images'
            for jROI = 1:nROI
                input_images{2,1} = ROI_set.ROIs(jROI).path(iSub).subjects;
                ROI_mask = ROI_set.ROIs(jROI).path_masked(iSub).subjects;
                spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
            end  
        % -----------------------------------------------------------------
        case 'fixed_spheres'
            for jROI = 1:nROI
                input_images{2,1} = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_set.ROIs(jROI).name '.nii']);
                ROI_mask = ROI_set.ROIs(jROI).path_masked(iSub).subjects;
                spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
            end
        % -----------------------------------------------------------------
        otherwise
            switch tmfc.defaults.parallel
                case 0 % Sequential
                    for jROI = 1:nROI
                        tmfc_mask_moving_spheres(sub_mask{iSub},tmfc,ROI_set_name,iSub,ROI_set,jROI);
                    end
                case 1 % Parallel
                    parfor jROI = 1:nROI
                        tmfc_mask_moving_spheres(sub_mask{iSub},tmfc,ROI_set_name,iSub,ROI_set,jROI);
                    end
            end
    end

    % Update waitbar
    if GUI
        elapsed_time = toc(start_time);
        time_per_sub = elapsed_time/count_sub;
        count_sub = count_sub + 1;
        time_remaining = (nSub-iSub)*time_per_sub;
        hms = fix(mod((time_remaining), [0, 3600, 60]) ./ [3600, 60, 1]);
        try
            waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec] remaining']);
        end
    end
end

% Delete temporary fixed sphere images
if strcmp(ROI_type,'fixed_spheres')
    for iROI = 1:nROI
        sphere_path = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name, ...
            'Masked_ROIs',[ROI_set.ROIs(iROI).name '.nii']);
        if exist(sphere_path,'file')
            delete(sphere_path);
        end
    end
end

if GUI
    try
        close(w);
    end
end

% -------------------------------------------------------------------------
% Calculate ROI size after masking
if GUI
    w = waitbar(0,'Please wait...','Name','Calculating masked ROI sizes');
end

for iROI = 1:nROI
    sub_size = nan(nSub,1);
    sub_percent = nan(nSub,1);

    if strcmp(ROI_type,'binary_images') || strcmp(ROI_type,'subject_specific_binary_images') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
        sub_X = nan(nSub,1);
        sub_Y = nan(nSub,1);
        sub_Z = nan(nSub,1);
    end

    for jSub = 1:nSub
        binary_mask = spm_data_read(ROI_set.ROIs(iROI).path_masked(jSub).subjects,'xyz',XYZ);
        sub_size(jSub) = nnz(binary_mask);

        if raw_size(iROI,jSub) > 0
            sub_percent(jSub) = 100*sub_size(jSub)/raw_size(iROI,jSub);
        else
            sub_percent(jSub) = 0;
        end

        % Calculate centroid coordinates
        if strcmp(ROI_type,'binary_images') || strcmp(ROI_type,'subject_specific_binary_images') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
            coord = XYZmm(:,(binary_mask ~= 0));
            if ~isempty(coord)
                sub_X(jSub) = mean(coord(1,:));
                sub_Y(jSub) = mean(coord(2,:));
                sub_Z(jSub) = mean(coord(3,:));
            end
        end
    end

    sub_size(isnan(sub_size)) = 0;
    sub_percent(isnan(sub_percent)) = 0;
    
    % Store ROI size information for each subject
    ROI_set.ROIs(iROI).raw_size_subjects = raw_size(iROI,:);
    ROI_set.ROIs(iROI).masked_size_subjects = sub_size(:)';
    ROI_set.ROIs(iROI).masked_size_percents_subjects = sub_percent(:)';

    % Use the subject with the greatest proportional ROI cropping
    [ROI_set.ROIs(iROI).masked_size_percents,worst_sub] = min(sub_percent);

    ROI_set.ROIs(iROI).raw_size = raw_size(iROI,worst_sub);
    ROI_set.ROIs(iROI).masked_size = sub_size(worst_sub);

    if strcmp(ROI_type,'binary_images') || strcmp(ROI_type,'subject_specific_binary_images') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
        ROI_set.ROIs(iROI).X = mean(sub_X(isfinite(sub_X)));
        ROI_set.ROIs(iROI).Y = mean(sub_Y(isfinite(sub_Y)));
        ROI_set.ROIs(iROI).Z = mean(sub_Z(isfinite(sub_Z)));
        clear sub_X sub_Y sub_Z
    end

    if GUI
        try
            waitbar(iROI/nROI,w,['ROI No ' num2str(iROI,'%.f')]);
        end
    end

    clear sub_size sub_percent
end

if GUI
    try
        close(w);
    end
end

% -------------------------------------------------------------------------
% Check for empty ROIs
empty_ROI_list = {};
empty_ROI_index = 1;

for iROI = 1:length(ROI_set.ROIs)
    if ROI_set.ROIs(iROI).masked_size_percents == 0
        empty_ROI_list{empty_ROI_index,1} = iROI;
        empty_ROI_list{empty_ROI_index,2} = ROI_set.ROIs(iROI).name;
        empty_ROI_index = empty_ROI_index + 1;
    end
end

% Print empty ROIs in command-line mode
if ~GUI && ~isempty(empty_ROI_list)
    fprintf(2,'\nEmpty ROIs removed:\n');
    for iROI = 1:size(empty_ROI_list,1)
        fprintf(2,'No %d: %s\n',empty_ROI_list{iROI,1},empty_ROI_list{iROI,2});
    end
end

% Remove empty ROIs
if ~isempty(empty_ROI_list)

    if size(empty_ROI_list,1) == length(ROI_set.ROIs)
        warning('All ROIs are empty. Select different ROIs.');
        ROI_set = []; return;
    end

    ROI_index = 0;
    for iROI = 1:size(empty_ROI_list,1)
        ROI_set.ROIs(empty_ROI_list{iROI,1}-ROI_index) = [];
        ROI_index = ROI_index + 1;
    end
end

% Remove heavily cropped ROIs
if ~isempty(ROI_definition.crop_threshold)

    crop_ROI_list = {};
    crop_ROI_index = 1;

    for iROI = 1:length(ROI_set.ROIs)
        if ROI_set.ROIs(iROI).masked_size_percents <= ROI_definition.crop_threshold
            crop_ROI_list{crop_ROI_index,1} = iROI;
            crop_ROI_list{crop_ROI_index,2} = ROI_set.ROIs(iROI).name;
            crop_ROI_list{crop_ROI_index,3} = ROI_set.ROIs(iROI).raw_size;
            crop_ROI_list{crop_ROI_index,4} = ROI_set.ROIs(iROI).masked_size;
            crop_ROI_list{crop_ROI_index,5} = ROI_set.ROIs(iROI).masked_size_percents;
            crop_ROI_index = crop_ROI_index + 1;
        end
    end

    if ~isempty(crop_ROI_list)

        fprintf(2,'\nROIs removed at crop threshold <= %g%%:\n',ROI_definition.crop_threshold);

        for iROI = 1:size(crop_ROI_list,1)
            fprintf(2,'No %d: %s :: %d voxels :: %d voxels :: %g %%\n',...
                crop_ROI_list{iROI,1},crop_ROI_list{iROI,2},crop_ROI_list{iROI,3},...
                crop_ROI_list{iROI,4},crop_ROI_list{iROI,5});
        end

        if size(crop_ROI_list,1) == length(ROI_set.ROIs)
            warning('All ROIs have been removed by crop threshold.');
            ROI_set = []; return;
        end

        ROI_index = 0;
        for iROI = 1:size(crop_ROI_list,1)
            ROI_set.ROIs(crop_ROI_list{iROI,1}-ROI_index) = [];
            ROI_index = ROI_index + 1;
        end
    end
end

% Final check
if ~isstruct(ROI_set) || ~isfield(ROI_set,'set_name') || ~isfield(ROI_set,'ROIs')
    ROI_set = [];
end

end

% -------------------------------------------------------------------------
function tmfc_mask_moving_spheres(subject_mask,tmfc,ROI_set_name,iSub,ROI_set,jROI)

input_images = cell(2,1);
input_images{1,1} = subject_mask;
input_images{2,1} = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,[ROI_set.ROIs(jROI).name '.nii']);
individual_ROI_mask = ROI_set.ROIs(jROI).path_masked(iSub).subjects;
spm_imcalc(input_images,individual_ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
delete(input_images{2,1});

end

% -------------------------------------------------------------------------
function cond_col = tmfc_get_F_contrast_columns(SPM,conditions,session_mode)

cond_col = [];

for iCond = 1:numel(conditions)

    if strcmp(session_mode,'repeated')
        sess_list = 1:length(SPM.Sess);
    else
        sess_list = conditions(iCond).sess;
    end

    for sess = sess_list
        cond = conditions(iCond).number;
        pmod = conditions(iCond).pmod;
    
        FCi = SPM.Sess(sess).Fc(cond).i;
    
        % PMs
        if isfield(SPM.Sess(sess).Fc(cond),'p')
            FCp = SPM.Sess(sess).Fc(cond).p;
            FCi = FCi(FCp == pmod);
        end
    
        % Derivatives
        if isfield(conditions,'bf') && ~isempty(conditions(iCond).bf)
    
            bf = conditions(iCond).bf;
    
            if bf > numel(FCi)
                error('Basis function %d does not exist for condition "%s".', ...
                    bf, conditions(iCond).name);
            end
    
            FCi = FCi(bf);
        end
    
        % FCi is local session index. Convert to full design-matrix column
        cond_col = [cond_col, SPM.Sess(sess).col(FCi)];
    end
end

% Prevent duplicated rows if the same column was selected twice
cond_col = sort(unique(cond_col));

end

% -------------------------------------------------------------------------
function check_fields(ROI,fields,iROI)

for iField = 1:length(fields)
    if ~isfield(ROI,fields{iField}) || isempty(ROI.(fields{iField}))
        error('ROI No %d: field "%s" is not specified.',iROI,fields{iField});
    end
end

end

% -------------------------------------------------------------------------
function unfreeze_after_ctrl_c

try
    delete(findall(0,'type','figure','Tag','tmfc_waitbar'));
    GUI = guidata(findobj('Tag','TMFC_GUI'));
    set([GUI.TMFC_GUI_B1, GUI.TMFC_GUI_B2, GUI.TMFC_GUI_B3, GUI.TMFC_GUI_B4,...
       GUI.TMFC_GUI_B5a, GUI.TMFC_GUI_B5b, GUI.TMFC_GUI_B6, GUI.TMFC_GUI_B7,...
       GUI.TMFC_GUI_B8, GUI.TMFC_GUI_B9, GUI.TMFC_GUI_B10, GUI.TMFC_GUI_B11,...
       GUI.TMFC_GUI_B12a,GUI.TMFC_GUI_B12b,GUI.TMFC_GUI_B13a,GUI.TMFC_GUI_B13b,...
       GUI.TMFC_GUI_B14a, GUI.TMFC_GUI_B14b], 'Enable', 'on');
end

end
