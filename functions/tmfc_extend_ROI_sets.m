function [tmfc] = tmfc_extend_ROI_sets(tmfc)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Extends existing ROI sets by creating or recreating subject-specific ROI masks.
% The function can be safely rerun after an interrupted ROI extension.
%
% FORMAT tmfc = tmfc_extend_ROI_sets(tmfc)
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% Nothing to extend
if ~isfield(tmfc,'ROI_set') || isempty(tmfc.ROI_set)
    return;
end

if ~isfield(tmfc,'subjects') || isempty(tmfc.subjects)
    error('No subjects are present in the TMFC project.');
end

nSub = length(tmfc.subjects);

% Backward compatibility: subject names
if ~isfield(tmfc.subjects,'name')
    for iSub = 1:nSub
        tmfc.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
    end
end

if ~isfield(tmfc,'session_mode') || isempty(tmfc.session_mode)
    session_mode = 'strict';
else
    session_mode = tmfc.session_mode;
end

if ~isfield(tmfc,'defaults') || ~isfield(tmfc.defaults,'parallel') || isempty(tmfc.defaults.parallel)
    parallel = 0;
else
    parallel = tmfc.defaults.parallel;
end


for iSet = 1:length(tmfc.ROI_set)

    ROI_set = tmfc.ROI_set(iSet);
    ROI_set_name = ROI_set.set_name;
    nROI = length(ROI_set.ROIs);
    
    % ---------------------------------------------------------------------
    % Backward compatibility: infer ROI type
    if ~isfield(ROI_set,'type') || isempty(ROI_set.type)
        if isfield(ROI_set.ROIs,'path') && ~isfield(ROI_set.ROIs,'radius')
            ROI_set.type = 'binary_images';
        elseif ~isfield(ROI_set.ROIs,'path') && isfield(ROI_set.ROIs,'radius')
            ROI_set.type = 'fixed_spheres';
        elseif isfield(ROI_set.ROIs,'moving_radius')
            ROI_set.type = 'moving_spheres_inside_fixed_spheres';
        else
            ROI_set.type = 'moving_spheres_inside_binary_images';
        end
    end

    ROI_type = ROI_set.type;

    % ---------------------------------------------------------------------
    % Backward compatibility: legacy ROI sets are preserved unchanged
    legacy_ROI_set = false;

    % Legacy binary images / fixed spheres: one common group-masked ROI image for all subjects
    if isfield(ROI_set,'ROIs') && ~isempty(ROI_set.ROIs) && isfield(ROI_set.ROIs(1),'path_masked') && ischar(ROI_set.ROIs(1).path_masked)
        legacy_ROI_set = true;
    end
    
    % Legacy moving ROIs: subject-specific masks existed, but reusable F settings and per-subject ROI-size metadata were not stored
    if ~legacy_ROI_set && (strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images'))
        has_F = isfield(ROI_set,'F') && ...
            isstruct(ROI_set.F) && ~isempty(ROI_set.F) && ...
            isfield(ROI_set.F,'conditions') && ~isempty(ROI_set.F.conditions) && ...
            isfield(ROI_set.F,'threshold') && ~isempty(ROI_set.F.threshold) && ...
            isfield(ROI_set.F,'mask') && ~isempty(ROI_set.F.mask);
        has_subject_sizes = ...
            isfield(ROI_set.ROIs(1),'raw_size_subjects') && ...
            isfield(ROI_set.ROIs(1),'masked_size_subjects') && ...
            isfield(ROI_set.ROIs(1),'masked_size_percents_subjects');
        if ~has_F && ~has_subject_sizes
            legacy_ROI_set = true;
        end
    end

    if legacy_ROI_set
        continue;
    end
    
    % ---------------------------------------------------------------------
    % Reference space
    SPM_ref = load(tmfc.subjects(1).path).SPM;
    XYZ = SPM_ref.xVol.XYZ;
    XYZmm = SPM_ref.xVol.M(1:3,:)*[XYZ; ones(1,size(XYZ,2))];
    
    % =====================================================================
    % Check subject-specific ROI paths
    % =====================================================================
    if strcmp(ROI_type,'subject_specific_binary_images')
        for iROI = 1:nROI
            for iSub = 1:nSub
                if length(ROI_set.ROIs(iROI).path) < iSub || ~isfield(ROI_set.ROIs(iROI).path(iSub),'subjects') || isempty(ROI_set.ROIs(iROI).path(iSub).subjects) || ~exist(ROI_set.ROIs(iROI).path(iSub).subjects,'file')
                    error('Subject-specific ROI path is missing for ROI "%s", subject "%s".',ROI_set.ROIs(iROI).name,tmfc.subjects(iSub).name);
                end
            end
        end
    end

    % =====================================================================
    % Moving ROIs require stored F-contrast settings
    % =====================================================================
    if strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
        has_F = isfield(ROI_set,'F') && ...
            isstruct(ROI_set.F) && ~isempty(ROI_set.F) && ...
            isfield(ROI_set.F,'conditions') && ~isempty(ROI_set.F.conditions) && ...
            isfield(ROI_set.F,'threshold') && ~isempty(ROI_set.F.threshold) && ...
            isfield(ROI_set.F,'mask') && ~isempty(ROI_set.F.mask);
        if ~has_F
            error('F-contrast settings are missing for ROI set "%s".',ROI_set_name);
        end
        conditions = ROI_set.F.conditions;
        Fthresh = ROI_set.F.threshold;
        Fmask = ROI_set.F.mask;
    end

    % ---------------------------------------------------------------------
    % Detect missing ROI masks
    needs_mask = false(nROI,nSub);

    for iSub = 1:nSub
        subject_ROI_dir = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name);
        if ~isdir(subject_ROI_dir)
            mkdir(subject_ROI_dir);
        end

        for iROI = 1:nROI
            expected_path = fullfile(subject_ROI_dir,[ROI_set.ROIs(iROI).name '_masked.nii']);
            current_path = '';

            if isfield(ROI_set.ROIs(iROI),'path_masked') && isstruct(ROI_set.ROIs(iROI).path_masked) && length(ROI_set.ROIs(iROI).path_masked) >= iSub && isfield(ROI_set.ROIs(iROI).path_masked(iSub),'subjects')
                current_path = ROI_set.ROIs(iROI).path_masked(iSub).subjects;
            end

            % Reuse an existing mask only if its path and valid subject-specific
            % ROI size metadata are stored in the project
            has_size = isfield(ROI_set.ROIs(iROI),'raw_size_subjects') && ...
                isfield(ROI_set.ROIs(iROI),'masked_size_subjects') && ...
                isfield(ROI_set.ROIs(iROI),'masked_size_percents_subjects') && ...
                numel(ROI_set.ROIs(iROI).raw_size_subjects) >= iSub && ...
                numel(ROI_set.ROIs(iROI).masked_size_subjects) >= iSub && ...
                numel(ROI_set.ROIs(iROI).masked_size_percents_subjects) >= iSub;
            if has_size
                has_size = isfinite(ROI_set.ROIs(iROI).raw_size_subjects(iSub)) && ...
                    isfinite(ROI_set.ROIs(iROI).masked_size_subjects(iSub)) && ...
                    ROI_set.ROIs(iROI).masked_size_subjects(iSub) > 0 && ...
                    isfinite(ROI_set.ROIs(iROI).masked_size_percents_subjects(iSub));
            end

            % Keep an existing valid path
            if ~isempty(current_path) && exist(current_path,'file') && has_size
                continue;
            end

            % Recreate the ROI mask for a new subject, even if the file already exists
            ROI_set.ROIs(iROI).path_masked(iSub).subjects = expected_path;
            needs_mask(iROI,iSub) = true;
        end
    end

    % ---------------------------------------------------------------------
    % Detect missing ROI size metadata
    needs_process = needs_mask;

    for iROI = 1:nROI
        has_subject_sizes = isfield(ROI_set.ROIs(iROI),'raw_size_subjects') && isfield(ROI_set.ROIs(iROI),'masked_size_subjects') && isfield(ROI_set.ROIs(iROI),'masked_size_percents_subjects');
        if has_subject_sizes
            for iSub = 1:nSub
                missing_size = ...
                    length(ROI_set.ROIs(iROI).raw_size_subjects) < iSub || ...
                    length(ROI_set.ROIs(iROI).masked_size_subjects) < iSub || ...
                    length(ROI_set.ROIs(iROI).masked_size_percents_subjects) < iSub;

                if ~missing_size
                    missing_size = ...
                        ~isfinite(ROI_set.ROIs(iROI).raw_size_subjects(iSub)) || ...
                        ~isfinite(ROI_set.ROIs(iROI).masked_size_subjects(iSub)) || ...
                        ~isfinite(ROI_set.ROIs(iROI).masked_size_percents_subjects(iSub));
                end

                if missing_size
                    needs_process(iROI,iSub) = true;
                end
            end
        else
            % Missing per-subject metadata: reconstruct it
            needs_process(iROI,:) = true;
        end
    end

    subjects_to_extend = find(any(needs_process,1));

    if isempty(subjects_to_extend)
        tmfc.ROI_set(iSet) = ROI_set;
        continue;
    end

    % ---------------------------------------------------------------------
    % Get individual first-level masks
    sub_mask = cell(nSub,1);

    for iSub = subjects_to_extend
        sub_mask{iSub} = fullfile(fileparts(tmfc.subjects(iSub).path),'mask.nii');
        if ~exist(sub_mask{iSub},'file')
            error('First-level mask does not exist: %s',sub_mask{iSub});
        end
    end

    % =====================================================================
    % Calculate F contrasts for moving ROIs
    % =====================================================================
    if strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images')

        contrast_idx = nan(nSub,1);

        for iSub = subjects_to_extend
            SPM = load(tmfc.subjects(iSub).path).SPM;
            cond_col = tmfc_get_F_contrast_columns(SPM,conditions,session_mode);
            weights = zeros(length(cond_col),size(SPM.xX.X,2));

            for iCond = 1:length(cond_col)
                weights(iCond,cond_col(iCond)) = 1;
            end

            % Check whether the same F contrast already exists
            idx = [];

            if isfield(SPM,'xCon') && ~isempty(SPM.xCon)
                idx = find(arrayfun(@(c) isequal(c.c,weights') && isfield(c,'STAT') && strcmpi(c.STAT,'F'), SPM.xCon),1,'first');
                nCon = numel(SPM.xCon);
            else
                nCon = 0;
            end

            % Create F contrast only if missing
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
        end
    end

    % =====================================================================
    % Fixed spheres: create temporary common sphere images
    % =====================================================================
    if strcmp(ROI_type,'fixed_spheres')
        fixed_raw_size = nan(nROI,1);
        for iROI = 1:nROI
            sphere_path = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_set.ROIs(iROI).name '.nii']);
            if exist(sphere_path,'file')
                delete(sphere_path);
            end
            job.spmmat = {tmfc.subjects(1).path};
            job.name = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',ROI_set.ROIs(iROI).name);
            job.roi{1}.sphere.centre = [ROI_set.ROIs(iROI).X ROI_set.ROIs(iROI).Y ROI_set.ROIs(iROI).Z];
            job.roi{1}.sphere.radius = ROI_set.ROIs(iROI).radius;
            job.roi{1}.sphere.move.fixed = 1;
            job.expression = 'i1';
            tmfc_create_spheres(job);
            binary_mask = spm_data_read(sphere_path,'xyz',XYZ);
            fixed_raw_size(iROI) = nnz(binary_mask);
            clear job
        end
    end

    % =====================================================================
    % Centroids of binary masks used as initial centers for moving spheres
    % =====================================================================
    if strcmp(ROI_type,'moving_spheres_inside_binary_images')
        centre = struct;
        for iROI = 1:nROI
            binary_mask = spm_data_read(ROI_set.ROIs(iROI).path,'xyz',XYZ);
            coord = XYZmm(:,binary_mask ~= 0);
            centre(iROI).X = mean(coord(1,:));
            centre(iROI).Y = mean(coord(2,:));
            centre(iROI).Z = mean(coord(3,:));
        end
    end

    % =====================================================================
    % Extend ROI set for each subject requiring processing
    % =====================================================================
    new_raw_size = nan(nROI,length(subjects_to_extend));
    new_masked_size = nan(nROI,length(subjects_to_extend));
    new_percent = nan(nROI,length(subjects_to_extend));

    if strcmp(ROI_type,'fixed_spheres')
        new_raw_size(:,:) = repmat(fixed_raw_size,1,length(subjects_to_extend));
    end

    for iNew = 1:length(subjects_to_extend)
        iSub = subjects_to_extend(iNew);
        input_images = cell(2,1);
        input_images{1} = sub_mask{iSub};

        % Remove existing ROI masks scheduled for recreation
        for iROI = 1:nROI
            if needs_mask(iROI,iSub)
                stale_mask = ROI_set.ROIs(iROI).path_masked(iSub).subjects;
                if exist(stale_mask,'file')
                    fprintf('TMFC: Recreating ROI mask: %s\n',stale_mask);
                    delete(stale_mask);
                end
            end
        end

        switch ROI_type
            % =============================================================
            case {'binary_images','subject_specific_binary_images'}
                for iROI = 1:nROI
                    if ~needs_process(iROI,iSub)
                        continue;
                    end
                    if strcmp(ROI_type,'subject_specific_binary_images')
                        ROI_path = ROI_set.ROIs(iROI).path(iSub).subjects;
                    else
                        ROI_path = ROI_set.ROIs(iROI).path;
                    end
                    ROI_mask = ROI_set.ROIs(iROI).path_masked(iSub).subjects;
                    % Calculate ROI size before masking
                    new_raw_size(iROI,iNew) = tmfc_resliced_ROI_size(ROI_path,sub_mask{iSub});
                    % Mask ROI by individual subject mask
                    if needs_mask(iROI,iSub)
                        input_images{2} = ROI_path;
                        spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
                    end
                    % Calculate ROI size after masking
                    binary_mask = spm_data_read(ROI_mask,'xyz',XYZ);
                    new_masked_size(iROI,iNew) = nnz(binary_mask);
                end

            % =============================================================
            case 'fixed_spheres'
                for iROI = 1:nROI
                    if ~needs_process(iROI,iSub)
                        continue;
                    end
                    sphere_path = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_set.ROIs(iROI).name '.nii']);
                    ROI_mask = ROI_set.ROIs(iROI).path_masked(iSub).subjects;
                    % Mask ROI by individual subject mask
                    if needs_mask(iROI,iSub)
                        input_images{2} = sphere_path;
                        spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
                    end
                    % Calculate ROI size after masking
                    binary_mask = spm_data_read(ROI_mask,'xyz',XYZ);
                    new_masked_size(iROI,iNew) = nnz(binary_mask);
                end

            % =============================================================
            case 'moving_spheres_inside_fixed_spheres'
                jobs = cell(1,nROI);
                for iROI = 1:nROI
                    if ~needs_process(iROI,iSub)
                        continue;
                    end
                    job.spmmat = {tmfc.subjects(iSub).path};
                    job.name = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,ROI_set.ROIs(iROI).name);
                    job.roi{1}.spm.spmmat = {tmfc.subjects(iSub).path};
                    job.roi{1}.spm.contrast = contrast_idx(iSub);
                    job.roi{1}.spm.conjunction = 1;
                    job.roi{1}.spm.threshdesc = 'none';
                    job.roi{1}.spm.thresh = Fthresh;
                    job.roi{1}.spm.extent = 0;
                    job.roi{1}.spm.mask = struct('contrast',{},'thresh',{},'mtype',{});
                    job.roi{2}.sphere.centre = [ROI_set.ROIs(iROI).X ROI_set.ROIs(iROI).Y ROI_set.ROIs(iROI).Z];
                    job.roi{2}.sphere.radius = ROI_set.ROIs(iROI).fixed_radius;
                    job.roi{2}.sphere.move.fixed = 1;
                    job.roi{3}.sphere.centre = [ROI_set.ROIs(iROI).X ROI_set.ROIs(iROI).Y ROI_set.ROIs(iROI).Z];
                    job.roi{3}.sphere.radius = ROI_set.ROIs(iROI).moving_radius;
                    job.roi{3}.sphere.move.global.spm = 1;
                    job.roi{3}.sphere.move.global.mask = 'i2';
                    if Fmask == 0
                        job.expression = 'i3';
                    else
                        job.expression = 'i1&i3';
                    end
                    jobs{iROI} = job;
                    clear job
                end

                if parallel == 0
                    for iROI = 1:nROI
                        if ~isempty(jobs{iROI})
                            tmfc_create_spheres(jobs{iROI});
                        end
                    end
                else
                    parfor iROI = 1:nROI
                        if ~isempty(jobs{iROI})
                            tmfc_create_spheres(jobs{iROI});
                        end
                    end
                end

                for iROI = 1:nROI
                    if ~needs_process(iROI,iSub)
                        continue;
                    end
                    sphere_path = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,[ROI_set.ROIs(iROI).name '.nii']);
                    ROI_mask = ROI_set.ROIs(iROI).path_masked(iSub).subjects;
                    % Calculate ROI size before masking
                    binary_mask = spm_data_read(sphere_path,'xyz',XYZ);
                    new_raw_size(iROI,iNew) = nnz(binary_mask);
                    % Mask ROI by individual subject mask
                    if needs_mask(iROI,iSub)
                        input_images{2} = sphere_path;
                        spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
                    end
                    delete(sphere_path);
                    % Calculate ROI size after masking
                    binary_mask = spm_data_read(ROI_mask,'xyz',XYZ);
                    new_masked_size(iROI,iNew) = nnz(binary_mask);
                end

                clear jobs

            % =============================================================
            case 'moving_spheres_inside_binary_images'
                jobs = cell(1,nROI);
                for iROI = 1:nROI
                    if ~needs_process(iROI,iSub)
                        continue;
                    end
                    job.spmmat = {tmfc.subjects(iSub).path};
                    job.name = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,ROI_set.ROIs(iROI).name);
                    job.roi{1}.spm.spmmat = {''};
                    job.roi{1}.spm.contrast = contrast_idx(iSub);
                    job.roi{1}.spm.conjunction = 1;
                    job.roi{1}.spm.threshdesc = 'none';
                    job.roi{1}.spm.thresh = Fthresh;
                    job.roi{1}.spm.extent = 0;
                    job.roi{1}.spm.mask = struct('contrast',{},'thresh',{},'mtype',{});
                    job.roi{2}.mask.image = {ROI_set.ROIs(iROI).path};
                    job.roi{2}.mask.threshold = 0.1;
                    job.roi{3}.sphere.centre = [centre(iROI).X centre(iROI).Y centre(iROI).Z];
                    job.roi{3}.sphere.radius = ROI_set.ROIs(iROI).radius;
                    job.roi{3}.sphere.move.global.spm = 1;
                    job.roi{3}.sphere.move.global.mask = 'i2';
                    if Fmask == 0
                        job.expression = 'i2&i3';
                    else
                        job.expression = 'i1&i2&i3';
                    end
                    jobs{iROI} = job;
                    clear job
                end

                if parallel == 0
                    for iROI = 1:nROI
                        if ~isempty(jobs{iROI})
                            tmfc_create_spheres(jobs{iROI});
                        end
                    end
                else
                    parfor iROI = 1:nROI
                        if ~isempty(jobs{iROI})
                            tmfc_create_spheres(jobs{iROI});
                        end
                    end
                end
                
                for iROI = 1:nROI
                    if ~needs_process(iROI,iSub)
                        continue;
                    end
                    sphere_path = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,[ROI_set.ROIs(iROI).name '.nii']);
                    ROI_mask = ROI_set.ROIs(iROI).path_masked(iSub).subjects;
                    % Calculate ROI size before masking
                    binary_mask = spm_data_read(sphere_path,'xyz',XYZ);
                    new_raw_size(iROI,iNew) = nnz(binary_mask);
                    % Mask ROI by individual subject mask
                    if needs_mask(iROI,iSub)
                        input_images{2} = sphere_path;
                        spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
                    end
                    delete(sphere_path);
                    % Calculate ROI size after masking
                    binary_mask = spm_data_read(ROI_mask,'xyz',XYZ);
                    new_masked_size(iROI,iNew) = nnz(binary_mask);
                end

                clear jobs

            otherwise
                error('Unknown ROI type: %s',ROI_type);
        end

        % Calculate proportional ROI size
        for iROI = 1:nROI
            if ~needs_process(iROI,iSub)
                continue;
            end
            if new_raw_size(iROI,iNew) > 0
                new_percent(iROI,iNew) = 100*new_masked_size(iROI,iNew)/new_raw_size(iROI,iNew);
            else
                new_percent(iROI,iNew) = 0;
            end

            % Existing ROI sets cannot silently lose an ROI after adding subjects
            if new_masked_size(iROI,iNew) == 0
                ROI_mask = ROI_set.ROIs(iROI).path_masked(iSub).subjects;
                if exist(ROI_mask,'file')
                    delete(ROI_mask);
                end
                error(['ROI "%s" is empty after masking for subject "%s". ' ...
                    'The subject cannot be added to the "%s" ROI set automatically.'], ...
                    ROI_set.ROIs(iROI).name,tmfc.subjects(iSub).name,ROI_set_name);
            end
        end
    end

    % ---------------------------------------------------------------------
    % Delete temporary fixed sphere images
    if strcmp(ROI_type,'fixed_spheres')
        for iROI = 1:nROI
            sphere_path = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_set.ROIs(iROI).name '.nii']);
            if exist(sphere_path,'file')
                delete(sphere_path);
            end
        end
    end

    % =====================================================================
    % Update ROI summary metadata
    % =====================================================================
    for iROI = 1:nROI

        % Update ROI size information
        has_subject_sizes = ...
            isfield(ROI_set.ROIs(iROI),'raw_size_subjects') && ...
            isfield(ROI_set.ROIs(iROI),'masked_size_subjects') && ...
            isfield(ROI_set.ROIs(iROI),'masked_size_percents_subjects');

        % Initialize per-subject metadata
        if ~has_subject_sizes
            ROI_set.ROIs(iROI).raw_size_subjects = nan(1,nSub);
            ROI_set.ROIs(iROI).masked_size_subjects = nan(1,nSub);
            ROI_set.ROIs(iROI).masked_size_percents_subjects = nan(1,nSub);
        end

        processed_idx = find(needs_process(iROI,subjects_to_extend));

        % Store processed subject metadata
        for k = processed_idx
            iSub = subjects_to_extend(k);
            ROI_set.ROIs(iROI).raw_size_subjects(iSub) = new_raw_size(iROI,k);
            ROI_set.ROIs(iROI).masked_size_subjects(iSub) = new_masked_size(iROI,k);
            ROI_set.ROIs(iROI).masked_size_percents_subjects(iSub) = new_percent(iROI,k);
        end

        % Recalculate summary from all current subjects
        [ROI_set.ROIs(iROI).masked_size_percents,worst_sub] = min(ROI_set.ROIs(iROI).masked_size_percents_subjects(1:nSub));
        ROI_set.ROIs(iROI).raw_size = ROI_set.ROIs(iROI).raw_size_subjects(worst_sub);
        ROI_set.ROIs(iROI).masked_size = ROI_set.ROIs(iROI).masked_size_subjects(worst_sub);

        % Update mean centroid for binary ROI types
        if strcmp(ROI_type,'binary_images') || strcmp(ROI_type,'subject_specific_binary_images') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
            sub_X = nan(nSub,1);
            sub_Y = nan(nSub,1);
            sub_Z = nan(nSub,1);

            for jSub = 1:nSub
                binary_mask = spm_data_read(ROI_set.ROIs(iROI).path_masked(jSub).subjects,'xyz',XYZ);
                coord = XYZmm(:,binary_mask ~= 0);
                if ~isempty(coord)
                    sub_X(jSub) = mean(coord(1,:));
                    sub_Y(jSub) = mean(coord(2,:));
                    sub_Z(jSub) = mean(coord(3,:));
                end
            end

            ROI_set.ROIs(iROI).X = mean(sub_X(isfinite(sub_X)));
            ROI_set.ROIs(iROI).Y = mean(sub_Y(isfinite(sub_Y)));
            ROI_set.ROIs(iROI).Z = mean(sub_Z(isfinite(sub_Z)));
            clear sub_X sub_Y sub_Z
        end
    end
    tmfc.ROI_set(iSet) = ROI_set;
end

end


% =========================================================================
%                               Subfunctions
% =========================================================================

%% Calculate number of non-zero voxels after reslicing ROI to subject mask
function nVoxel = tmfc_resliced_ROI_size(ROI_path,subject_mask_path)

subject_mask = spm_vol(subject_mask_path);
ROI_mask = spm_vol(ROI_path);
Y = zeros(subject_mask.dim(1:3));

for p = 1:subject_mask.dim(3)
    B = spm_matrix([0 0 -p 0 0 0 1 1 1]);
    X = zeros(1,prod(subject_mask.dim(1:2)));
    M = inv(B * inv(subject_mask.mat) * ROI_mask.mat);
    d = spm_slice_vol(ROI_mask,M,subject_mask.dim(1:2),1);
    d(isnan(d)) = 0;
    X(1,:) = d(:)';
    Y(:,:,p) = reshape(X,subject_mask.dim(1:2));
end

nVoxel = nnz(Y);

end

%% Get design-matrix columns used for omnibus F contrast
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

        % Parametric modulators
        if isfield(SPM.Sess(sess).Fc(cond),'p')
            FCp = SPM.Sess(sess).Fc(cond).p;
            FCi = FCi(FCp == pmod);
        end

        % HRF derivatives
        if isfield(conditions,'bf') && ...
                ~isempty(conditions(iCond).bf)

            bf = conditions(iCond).bf;

            if bf > numel(FCi)
                error('Basis function %d does not exist for condition "%s".', ...
                    bf,conditions(iCond).name);
            end

            FCi = FCi(bf);
        end

        cond_col = [cond_col,SPM.Sess(sess).col(FCi)];
    end
end

cond_col = sort(unique(cond_col));

end