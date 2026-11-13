function tmfc = tmfc_remove_subjects(tmfc,subject_idx,delete_files)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Removes selected subjects from an existing TMFC project.
%
% FORMAT tmfc = tmfc_remove_subjects(tmfc,subject_idx,delete_files)
%
%   tmfc          - TMFC project structure
%   subject_idx   - Indices of subjects to remove
%   delete_files  - 0: keep existing TMFC output files
%                   1: delete TMFC output files for removed subjects
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin < 3
    delete_files = 0;
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

% Check subject indices
subject_idx = unique(subject_idx(:)');

if isempty(subject_idx) || ...
        any(subject_idx < 1) || ...
        any(subject_idx > nSub) || ...
        any(subject_idx ~= round(subject_idx))
    error('Invalid subject indices.');
end

% Removing all subjects should use the dedicated remove-all workflow
if length(subject_idx) == nSub
    error('Use the remove-all-subjects workflow to remove all subjects.');
end

if ~ismember(delete_files,[0 1])
    error('delete_files must be 0 or 1.');
end

% Store names before modifying the structure
subject_names = cell(length(subject_idx),1);

for iSub = 1:length(subject_idx)
    subject_names{iSub} = tmfc.subjects(subject_idx(iSub)).name;
end

% Backward compatibility: preserve legacy ROI sets when the cohort changes
if isfield(tmfc,'ROI_set') && ~isempty(tmfc.ROI_set)
    legacy_idx = false(1,length(tmfc.ROI_set));

    for iSet = 1:length(tmfc.ROI_set)
        ROI_set = tmfc.ROI_set(iSet);

        if ~isfield(ROI_set,'ROIs') || isempty(ROI_set.ROIs)
            continue;
        end

        % Legacy binary images / fixed spheres: one common group-masked ROI image for all subjects
        if isfield(ROI_set.ROIs(1),'path_masked') && ischar(ROI_set.ROIs(1).path_masked)
            legacy_idx(iSet) = true;
            continue;
        end

        % Legacy moving ROIs: subject-specific masks existed, but F-contrast settings required for ROI-set extension were not stored
        if isfield(ROI_set,'type') && (strcmp(ROI_set.type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_set.type,'moving_spheres_inside_binary_images'))
            has_F = isfield(ROI_set,'F') && ...
                    isstruct(ROI_set.F) && ~isempty(ROI_set.F) && ...
                    isfield(ROI_set.F,'conditions') && ~isempty(ROI_set.F.conditions) && ...
                    isfield(ROI_set.F,'threshold') && ~isempty(ROI_set.F.threshold) && ...
                    isfield(ROI_set.F,'mask') && ~isempty(ROI_set.F.mask);
            if ~has_F
                legacy_idx(iSet) = true;
            end
        end
    end

    % Archive legacy ROI sets
    if any(legacy_idx)
        legacy_sets = tmfc.ROI_set(legacy_idx);

        % Store the original cohort
        for iSet = 1:length(legacy_sets)
            legacy_sets(iSet).original_subject_names = {tmfc.subjects.name};
            legacy_sets(iSet).original_subject_paths = {tmfc.subjects.path};
        end

        if isfield(tmfc,'ROI_set_legacy') && ~isempty(tmfc.ROI_set_legacy)

            % Make archived and newly archived ROI sets structurally compatible
            old_fields = fieldnames(tmfc.ROI_set_legacy);
            new_fields = fieldnames(legacy_sets);

            missing_old = setdiff(new_fields,old_fields);
            for iField = 1:length(missing_old)
                for iSet = 1:length(tmfc.ROI_set_legacy)
                    tmfc.ROI_set_legacy(iSet).(missing_old{iField}) = [];
                end
            end

            missing_new = setdiff(old_fields,new_fields);
            for iField = 1:length(missing_new)
                for iSet = 1:length(legacy_sets)
                    legacy_sets(iSet).(missing_new{iField}) = [];
                end
            end

            % Match field order before concatenation
            legacy_sets = orderfields(legacy_sets,tmfc.ROI_set_legacy);
            tmfc.ROI_set_legacy = [tmfc.ROI_set_legacy legacy_sets];
        else
            tmfc.ROI_set_legacy = legacy_sets;
        end

        % Preserve current ROI-set selection if possible
        active_idx = find(~legacy_idx);
        if isfield(tmfc,'ROI_set_number')
            old_ROI_set_number = tmfc.ROI_set_number;
        else
            old_ROI_set_number = [];
        end

        % Remove legacy sets from active ROI sets
        tmfc.ROI_set(legacy_idx) = [];
        if isempty(tmfc.ROI_set)
            tmfc = rmfield(tmfc,'ROI_set');
            if isfield(tmfc,'ROI_set_number')
                tmfc = rmfield(tmfc,'ROI_set_number');
            end
        else
            if ~isempty(old_ROI_set_number)
                new_ROI_set_number = find(active_idx == old_ROI_set_number,1);
                if isempty(new_ROI_set_number)
                    tmfc.ROI_set_number = 1;
                else
                    tmfc.ROI_set_number = new_ROI_set_number;
                end
            else
                tmfc.ROI_set_number = 1;
            end
        end
        fprintf('TMFC: %d legacy ROI set(s) preserved for the original subject cohort. Create a new ROI set for the updated cohort.\n',sum(legacy_idx));
    end
end

% =========================================================================
% Delete subject output files
% =========================================================================
if delete_files == 1

    % Project-level subject folders
    project_folders = { ...
        'LSS_regression', ...
        'FIR_regression', ...
        'LSS_regression_after_FIR'};

    for iSub = 1:length(subject_names)
        sub_name = subject_names{iSub};
        for iFolder = 1:length(project_folders)
            sub_folder = fullfile(tmfc.project_path,project_folders{iFolder},sub_name);
            if isdir(sub_folder)
                rmdir(sub_folder,'s');
            end
        end
    end

    % All subject-specific files/folders inside every ROI set
    if isfield(tmfc,'ROI_set')
        for iSet = 1:length(tmfc.ROI_set)
            ROI_set_path = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(iSet).set_name);
            for iSub = 1:length(subject_names)
                delete_subject_ROI_outputs(ROI_set_path,tmfc.ROI_set(iSet),subject_names{iSub});
            end
        end
    end
end

% =========================================================================
% Remove subject-indexed ROI information
% =========================================================================

size_fields = {'raw_size_subjects', ...
               'masked_size_subjects', ...
               'masked_size_percents_subjects'};


if isfield(tmfc,'ROI_set')
    for iSet = 1:length(tmfc.ROI_set)
        % Analysis progress
        if isfield(tmfc.ROI_set(iSet),'subjects')
            idx = subject_idx(subject_idx <= length(tmfc.ROI_set(iSet).subjects));
            tmfc.ROI_set(iSet).subjects(idx) = [];
        end
        if ~isfield(tmfc.ROI_set(iSet),'ROIs')
            continue;
        end

        for iROI = 1:length(tmfc.ROI_set(iSet).ROIs)
            % Subject-specific masked ROI paths
            if isfield(tmfc.ROI_set(iSet).ROIs(iROI),'path_masked')
                path_masked = tmfc.ROI_set(iSet).ROIs(iROI).path_masked;
                % New subject-specific representation
                if isstruct(path_masked)
                    idx = subject_idx(subject_idx <= length(path_masked));
                    tmfc.ROI_set(iSet).ROIs(iROI).path_masked(idx) = [];
                end
            end

            % Original subject-specific binary ROI paths
            if isfield(tmfc.ROI_set(iSet).ROIs(iROI),'path')
                ROI_path = tmfc.ROI_set(iSet).ROIs(iROI).path;
                if isstruct(ROI_path) && isfield(ROI_path,'subjects')
                    idx = subject_idx(subject_idx <= length(ROI_path));
                    tmfc.ROI_set(iSet).ROIs(iROI).path(idx) = [];
                end
            end
            
            % Subject-specific ROI size information
            for iField = 1:length(size_fields)
                field_name = size_fields{iField};
                if isfield(tmfc.ROI_set(iSet).ROIs(iROI),field_name)
                    values = tmfc.ROI_set(iSet).ROIs(iROI).(field_name);
                    % Some deferred/incomplete ROI sets may not yet contain
                    % information for all current subjects
                    idx = subject_idx(subject_idx <= length(values));
                    values(idx) = [];
                    tmfc.ROI_set(iSet).ROIs(iROI).(field_name) = values;
                end
            end
        end
    end
end

% =========================================================================
% Remove subjects from TMFC structure
% =========================================================================
tmfc.subjects(subject_idx) = [];

% =========================================================================
% Update ROI summary metadata
% =========================================================================
if isfield(tmfc,'ROI_set')

    nSub_remaining = length(tmfc.subjects);

    % Reference space
    SPM_ref = load(tmfc.subjects(1).path).SPM;
    XYZ = SPM_ref.xVol.XYZ;
    XYZmm = SPM_ref.xVol.M(1:3,:)*[XYZ; ones(1,size(XYZ,2))];

    for iSet = 1:length(tmfc.ROI_set)

        if ~isfield(tmfc.ROI_set(iSet),'ROIs')
            continue;
        end

        ROI_set = tmfc.ROI_set(iSet);

        % Backward compatibility: infer ROI type
        if isfield(ROI_set,'type') && ~isempty(ROI_set.type)
            ROI_type = ROI_set.type;
        elseif isfield(ROI_set.ROIs,'path') && ~isfield(ROI_set.ROIs,'radius')
            ROI_type = 'binary_images';
        elseif ~isfield(ROI_set.ROIs,'path') && isfield(ROI_set.ROIs,'radius')
            ROI_type = 'fixed_spheres';
        elseif isfield(ROI_set.ROIs,'moving_radius')
            ROI_type = 'moving_spheres_inside_fixed_spheres';
        else
            ROI_type = 'moving_spheres_inside_binary_images';
        end

        for iROI = 1:length(ROI_set.ROIs)

            % -------------------------------------------------------------
            % Recalculate ROI-size summary when per-subject information
            % is available for all remaining subjects
            has_subject_sizes = ...
                isfield(ROI_set.ROIs(iROI),'raw_size_subjects') && ...
                isfield(ROI_set.ROIs(iROI),'masked_size_subjects') && ...
                isfield(ROI_set.ROIs(iROI),'masked_size_percents_subjects') && ...
                length(ROI_set.ROIs(iROI).raw_size_subjects) == nSub_remaining && ...
                length(ROI_set.ROIs(iROI).masked_size_subjects) == nSub_remaining && ...
                length(ROI_set.ROIs(iROI).masked_size_percents_subjects) == nSub_remaining;

            if has_subject_sizes
                [ROI_set.ROIs(iROI).masked_size_percents,worst_sub] = min(ROI_set.ROIs(iROI).masked_size_percents_subjects);
                ROI_set.ROIs(iROI).raw_size = ROI_set.ROIs(iROI).raw_size_subjects(worst_sub);
                ROI_set.ROIs(iROI).masked_size = ROI_set.ROIs(iROI).masked_size_subjects(worst_sub);
            end

            % -------------------------------------------------------------
            % Recalculate mean centroid from remaining subjects
            if strcmp(ROI_type,'binary_images') || ...
                    strcmp(ROI_type,'subject_specific_binary_images') || ...
                    strcmp(ROI_type,'moving_spheres_inside_binary_images')

                can_recalculate = ...
                    isfield(ROI_set.ROIs(iROI),'path_masked') && ...
                    isstruct(ROI_set.ROIs(iROI).path_masked) && ...
                    length(ROI_set.ROIs(iROI).path_masked) >= nSub_remaining;

                if can_recalculate
                    sub_X = nan(nSub_remaining,1);
                    sub_Y = nan(nSub_remaining,1);
                    sub_Z = nan(nSub_remaining,1);

                    for jSub = 1:nSub_remaining
                        ROI_mask = ROI_set.ROIs(iROI).path_masked(jSub).subjects;

                        if isempty(ROI_mask) || ~exist(ROI_mask,'file')
                            can_recalculate = false;
                            break;
                        end

                        binary_mask = spm_data_read(ROI_mask,'xyz',XYZ);
                        coord = XYZmm(:,binary_mask ~= 0);

                        if ~isempty(coord)
                            sub_X(jSub) = mean(coord(1,:));
                            sub_Y(jSub) = mean(coord(2,:));
                            sub_Z(jSub) = mean(coord(3,:));
                        end
                    end

                    if can_recalculate
                        ROI_set.ROIs(iROI).X = mean(sub_X(isfinite(sub_X)));
                        ROI_set.ROIs(iROI).Y = mean(sub_Y(isfinite(sub_Y)));
                        ROI_set.ROIs(iROI).Z = mean(sub_Z(isfinite(sub_Z)));
                    end
                end
            end
        end
        tmfc.ROI_set(iSet) = ROI_set;
    end
end
end

% =========================================================================
% Delete subject-specific outputs within one ROI set
function delete_subject_ROI_outputs(ROI_set_path,ROI_set,subject_name)

if ~isdir(ROI_set_path)
    return;
end

% -------------------------------------------------------------------------
% Subject-specific folders
subject_folders = { ...
    fullfile(ROI_set_path,'Masked_ROIs',subject_name), ...
    fullfile(ROI_set_path,'VOIs',subject_name), ...
    fullfile(ROI_set_path,'PPIs',subject_name), ...
    fullfile(ROI_set_path,'gPPI',subject_name), ...
    fullfile(ROI_set_path,'gPPI_FIR',subject_name), ...
    fullfile(ROI_set_path,'BGFC','FIR_VOIs',subject_name)};

for iFolder = 1:length(subject_folders)
    if isdir(subject_folders{iFolder})
        rmdir(subject_folders{iFolder},'s');
    end
end

% -------------------------------------------------------------------------
% Subject-specific files in common folders
file_folders = { ...
    fullfile(ROI_set_path,'gPPI','ROI_to_ROI','asymmetrical'), ...
    fullfile(ROI_set_path,'gPPI','ROI_to_ROI','symmetrical'), ...
    fullfile(ROI_set_path,'gPPI_FIR','ROI_to_ROI','asymmetrical'), ...
    fullfile(ROI_set_path,'gPPI_FIR','ROI_to_ROI','symmetrical'), ...
    fullfile(ROI_set_path,'BSC_LSS','Beta_series'), ...
    fullfile(ROI_set_path,'BSC_LSS','ROI_to_ROI'), ...
    fullfile(ROI_set_path,'BSC_LSS_after_FIR','Beta_series'), ...
    fullfile(ROI_set_path,'BSC_LSS_after_FIR','ROI_to_ROI'), ...
    fullfile(ROI_set_path,'BGFC','ROI_to_ROI')};

for iFolder = 1:length(file_folders)
    delete_subject_files(file_folders{iFolder},subject_name);
end

% -------------------------------------------------------------------------
% ROI-specific common folders
if isfield(ROI_set,'ROIs')
    for iROI = 1:length(ROI_set.ROIs)

        ROI_name = ROI_set.ROIs(iROI).name;

        ROI_folders = { ...
            fullfile(ROI_set_path,'gPPI','Seed_to_voxel',ROI_name), ...
            fullfile(ROI_set_path,'gPPI','GLM_batches',ROI_name), ...
            fullfile(ROI_set_path,'gPPI_FIR','Seed_to_voxel',ROI_name), ...
            fullfile(ROI_set_path,'gPPI_FIR','GLM_batches',ROI_name), ...
            fullfile(ROI_set_path,'BSC_LSS','Seed_to_voxel',ROI_name), ...
            fullfile(ROI_set_path,'BSC_LSS_after_FIR','Seed_to_voxel',ROI_name)};

        for iFolder = 1:length(ROI_folders)
            delete_subject_files(ROI_folders{iFolder},subject_name);
        end
    end
end
end

% =========================================================================
% Delete subject-specific files from one specific folder
function delete_subject_files(folder_path,subject_name)

if ~isdir(folder_path)
    return;
end

exact_names = { ...
    [subject_name '_beta_series.mat'], ...
    [subject_name '_gPPI_GLM.mat'], ...
    [subject_name '_gPPI_FIR_GLM.mat'], ...
    [subject_name '_All_Runs.mat']};

prefixes = { ...
    [subject_name '_Contrast_'], ...
    [subject_name '_Run_'], ...
    [subject_name '_Session_']};

items = dir(folder_path);

for iItem = 1:length(items)

    if items(iItem).isdir
        continue;
    end

    item_name = items(iItem).name;

    delete_file = any(strcmp(item_name,exact_names));

    if ~delete_file
        for iPrefix = 1:length(prefixes)
            prefix = prefixes{iPrefix};

            if length(item_name) >= length(prefix) && strncmp(item_name,prefix,length(prefix))
                delete_file = true;
                break;
            end
        end
    end

    if delete_file
        delete(fullfile(folder_path,item_name));
    end
end
end