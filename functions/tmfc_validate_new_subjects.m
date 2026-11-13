function [SPM_paths_valid,subject_paths_valid,add_type] = tmfc_validate_new_subjects(tmfc,SPM_paths,subject_paths)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Validates new subjects against an existing TMFC project.
%
% FORMAT [SPM_paths_valid,subject_paths_valid,add_type] = ...
%        tmfc_validate_new_subjects(tmfc,SPM_paths,subject_paths)
%
%   Inputs:
%   tmfc                  - TMFC project structure
%   SPM_paths             - Full paths to candidate subject SPM.mat files
%   subject_paths         - Paths to candidate subject folders
%
%   Outputs:
%   SPM_paths_valid       - Full paths to valid subject SPM.mat files
%   subject_paths_valid   - Paths to valid subject folders
%   add_type              - Subject addition type:
%                           1 - compatible with current session mode
%                           2 - requires strict -> repeated conversion
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

SPM_paths_valid = {};
subject_paths_valid = {};
add_type = [];

% Existing project reference
SPM_ref = load(tmfc.subjects(1).path).SPM;
if isempty(SPM_ref.Sess)
    error('Reference SPM.mat contains no runs.');
end

nSess_ref = length(SPM_ref.Sess);

% Reference condition structures for strict mode
cond_ref = cell(nSess_ref,1);
for iSess = 1:nSess_ref
    cond_ref{iSess} = get_condition_structure(SPM_ref,iSess);
end

% Reference repeated-run structure
cond_repeated_ref = cond_ref{1};

% -------------------------------------------------------------------------
% Backward compatibility: session mode
if ~isfield(tmfc,'session_mode') || isempty(tmfc.session_mode)
    session_mode = 'strict';
else
    session_mode = tmfc.session_mode;
end

% -------------------------------------------------------------------------
% Backward compatibility: infer subject naming convention
if isfield(tmfc,'subject_naming') && ~isempty(tmfc.subject_naming)
    subject_naming = tmfc.subject_naming;
else
    if isfield(tmfc.subjects,'name')
        standard_names = true;
        for iSub = 1:length(tmfc.subjects)
            if isempty(regexp(tmfc.subjects(iSub).name,'^Subject_\d{4}$','once'))
                standard_names = false;
                break;
            end
        end
        if standard_names
            subject_naming = 'standard';
        else
            subject_naming = 'original';
        end
    else
        % Old projects without stored subject names used standard numbering
        subject_naming = 'standard';
    end
end

% -------------------------------------------------------------------------
% Existing paths/names
existing_paths = {tmfc.subjects.path};
if strcmp(subject_naming,'original')
    existing_names = {tmfc.subjects.name};
else
    existing_names = {};
end

% Repeated compatibility of the existing cohort is checked only if needed
existing_repeated_ok = [];

% Repeated compatibility of stored condition selections is checked only if needed
stored_repeated_ok = [];
stored_repeated_label = '';

% -------------------------------------------------------------------------
% Validate candidates individually
for iSub = 1:length(SPM_paths)

    SPM_path = deblank(SPM_paths{iSub});
    subject_path = deblank(subject_paths{iSub});

    % ---------------------------------------------------------------------
    % Duplicate SPM.mat path
    duplicate = false;

    for jSub = 1:length(existing_paths)
        if same_path(SPM_path,existing_paths{jSub})
            duplicate = true;
            break;
        end
    end

    if ~duplicate
        for jSub = 1:length(SPM_paths_valid)
            if same_path(SPM_path,SPM_paths_valid{jSub})
                duplicate = true;
                break;
            end
        end
    end

    if duplicate
        fprintf(2,'TMFC: Subject already exists in project: %s\n',SPM_path);
        continue;
    end

    % ---------------------------------------------------------------------
    % SPM.mat existence
    if ~exist(SPM_path,'file')
        fprintf(2,'TMFC: SPM.mat does not exist: %s\n',SPM_path);
        continue;
    end

    % ---------------------------------------------------------------------
    % Load SPM.mat
    try
        SPM = load(SPM_path).SPM;
    catch
        fprintf(2,'TMFC: Invalid SPM.mat file: %s\n',SPM_path);
        continue;
    end

    if ~isfield(SPM,'Sess') || isempty(SPM.Sess)
        fprintf(2,'TMFC: No runs found in: %s\n',SPM_path);
        continue;
    end

    % ---------------------------------------------------------------------
    % Check SPM.swd
    if ~isfield(SPM,'swd') || ~exist(SPM.swd,'dir')
        fprintf(2,'TMFC: SPM.swd folder does not exist: %s\n',SPM_path);
        continue;
    end

    % ---------------------------------------------------------------------
    % Check functional images
    functional_ok = true;

    if ~isfield(SPM,'xY') || ~isfield(SPM.xY,'VY')
        functional_ok = false;
    else
        for jImage = 1:length(SPM.xY.VY)
            if ~exist(SPM.xY.VY(jImage).fname,'file')
                functional_ok = false;
                break;
            end
        end
    end

    if ~functional_ok
        fprintf(2,'TMFC: Functional files are missing: %s\n',SPM_path);
        continue;
    end

    % ---------------------------------------------------------------------
    % Check subject first-level mask
    mask_path = fullfile(fileparts(SPM_path),'mask.nii');
    if ~exist(mask_path,'file')
        fprintf(2,'TMFC: First-level mask.nii is missing: %s\n',SPM_path);
        continue;
    end

    % ---------------------------------------------------------------------
    % HRF basis must be compatible with the existing project
    if ~isfield(SPM,'xBF') || ~isfield(SPM_ref,'xBF') || ~strcmpi(strtrim(SPM.xBF.name),strtrim(SPM_ref.xBF.name))
        fprintf(2,'TMFC: HRF basis functions differ from the existing project: %s\n',SPM_path);
        continue;
    end

    % ---------------------------------------------------------------------
    % Original subject names must remain unique
    if strcmp(subject_naming,'original')

        subject_path_tmp = subject_path;
        if ~isempty(subject_path_tmp) && subject_path_tmp(end) == filesep
            subject_path_tmp(end) = [];
        end

        [~,subject_name] = fileparts(subject_path_tmp);

        if any(strcmpi(existing_names,subject_name))
            fprintf(2,'TMFC: Subject name already exists in project: %s\n',subject_name);
            continue;
        end
    else
        subject_name = '';
    end

    % ---------------------------------------------------------------------
    % Check strict compatibility
    strict_ok = false;

    if length(SPM.Sess) == nSess_ref
        strict_ok = true;
        for iSess = 1:nSess_ref
            cond = get_condition_structure(SPM,iSess);
            if ~isequaln(cond_ref{iSess},cond)
                strict_ok = false;
                break;
            end
        end
    end

    % ---------------------------------------------------------------------
    % Check repeated compatibility
    repeated_ok = true;
    for iSess = 1:length(SPM.Sess)
        cond = get_condition_structure(SPM,iSess);
        if ~isequaln(cond_repeated_ref,cond)
            repeated_ok = false;
            break;
        end
    end

    % ---------------------------------------------------------------------
    % Decide candidate status
    if strcmp(session_mode,'repeated')
        if ~repeated_ok
            fprintf(2,'TMFC: Subject has incompatible repeated-run conditions: %s\n',SPM_path);
            continue;
        end
        this_add_type = 1;
    elseif strcmp(session_mode,'strict')
        if strict_ok
            this_add_type = 1;
        elseif repeated_ok
            % Check whether the existing strict cohort can be converted
            % to repeated mode only when this is actually required
            if isempty(existing_repeated_ok)
                existing_repeated_ok = true;
                for jSub = 1:length(tmfc.subjects)
                    SPM_existing = load(tmfc.subjects(jSub).path).SPM;
                    for jSess = 1:length(SPM_existing.Sess)
                        cond_existing = get_condition_structure(SPM_existing,jSess);
                        if ~isequaln(cond_repeated_ref,cond_existing)
                            existing_repeated_ok = false;
                            break;
                        end
                    end

                    if ~existing_repeated_ok
                        break;
                    end
                end
            end

            if existing_repeated_ok
                % Check whether existing stored condition selections can be represented in repeated mode
                if isempty(stored_repeated_ok)

                    stored_repeated_ok = true;

                    condition_sets = {};
                    condition_labels = {};

                    if isfield(tmfc,'LSS') && isfield(tmfc.LSS,'conditions') && ~isempty(tmfc.LSS.conditions)
                        condition_sets{end+1} = tmfc.LSS.conditions;
                        condition_labels{end+1} = 'LSS';
                    end

                    if isfield(tmfc,'LSS_after_FIR') && isfield(tmfc.LSS_after_FIR,'conditions') && ~isempty(tmfc.LSS_after_FIR.conditions)
                        condition_sets{end+1} = tmfc.LSS_after_FIR.conditions;
                        condition_labels{end+1} = 'LSS after FIR';
                    end

                    if isfield(tmfc,'ROI_set')
                        for iSet = 1:length(tmfc.ROI_set)
                            ROI_set = tmfc.ROI_set(iSet);
                            legacy_ROI_set = false;

                            % Legacy binary images / fixed spheres: one common group-masked ROI image for all subjects
                            if isfield(ROI_set,'ROIs') && ~isempty(ROI_set.ROIs) && isfield(ROI_set.ROIs(1),'path_masked') && ischar(ROI_set.ROIs(1).path_masked)
                                legacy_ROI_set = true;
                            end

                            % Legacy moving ROIs: subject-specific masks existed, but F-contrast settings required for ROI-set extension were not stored
                            if ~legacy_ROI_set && isfield(ROI_set,'type') && (strcmp(ROI_set.type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_set.type,'moving_spheres_inside_binary_images'))
                                has_F = isfield(ROI_set,'F') && ...
                                    isstruct(ROI_set.F) && ~isempty(ROI_set.F) && ...
                                    isfield(ROI_set.F,'conditions') && ~isempty(ROI_set.F.conditions) && ...
                                    isfield(ROI_set.F,'threshold') && ~isempty(ROI_set.F.threshold) && ...
                                    isfield(ROI_set.F,'mask') && ~isempty(ROI_set.F.mask);
                                if ~has_F
                                    legacy_ROI_set = true;
                                end
                            end

                            % Legacy ROI sets will be archived when the cohort changes, so they must not constrain strict-to-repeated conversion
                            if legacy_ROI_set
                                continue;
                            end

                            if isfield(ROI_set,'gPPI') && isstruct(ROI_set.gPPI) && ~isempty(ROI_set.gPPI) && isfield(ROI_set.gPPI,'conditions') && ~isempty(ROI_set.gPPI.conditions)
                                condition_sets{end+1} = ROI_set.gPPI.conditions;
                                condition_labels{end+1} = ['gPPI, ROI set ' num2str(iSet)];
                            end

                            if isfield(ROI_set,'F') && isstruct(ROI_set.F) && ~isempty(ROI_set.F) && isfield(ROI_set.F,'conditions') && ~isempty(ROI_set.F.conditions)
                                condition_sets{end+1} = ROI_set.F.conditions;
                                condition_labels{end+1} = ['F contrast, ROI set ' num2str(iSet)];
                            end
                        end
                    end

                    for iList = 1:length(condition_sets)
                        conditions = condition_sets{iList};

                        if ~isfield(conditions,'sess')
                            stored_repeated_ok = false;
                            stored_repeated_label = condition_labels{iList};
                            break;
                        end

                        % Ignore fields that are necessarily run-specific
                        remove_fields = intersect({'sess','list_name','file_name'},fieldnames(conditions));

                        conditions_ref = conditions([conditions.sess] == 1);
                        conditions_ref = rmfield(conditions_ref,remove_fields);

                        for jSess = 2:nSess_ref
                            conditions_run = conditions([conditions.sess] == jSess);
                            conditions_run = rmfield(conditions_run,remove_fields);

                            if ~isequaln(conditions_ref,conditions_run)
                                stored_repeated_ok = false;
                                stored_repeated_label = condition_labels{iList};
                                break;
                            end
                        end

                        if ~stored_repeated_ok
                            break;
                        end
                    end
                end

                if stored_repeated_ok
                    this_add_type = 2;
                else
                    fprintf(2,'TMFC: Strict-to-repeated conversion is not possible because selected conditions differ between runs (%s): %s\n',stored_repeated_label,SPM_path);
                    continue;
                end
            else
                fprintf(2,'TMFC: Subject has incompatible runs or conditions: %s\n',SPM_path);
                continue;
            end

        else
            fprintf(2,'TMFC: Subject has incompatible runs or conditions: %s\n',SPM_path);
            continue;
        end
    else
        error('Invalid session mode.');
    end

    % ---------------------------------------------------------------------
    % Candidate accepted
    k = length(SPM_paths_valid) + 1;

    SPM_paths_valid{k,1} = SPM_path;
    subject_paths_valid{k,1} = subject_path;
    add_type(k,1) = this_add_type;

    if strcmp(subject_naming,'original')
        existing_names{end+1} = subject_name;
    end
end
end

% =========================================================================
function cond = get_condition_structure(SPM,iSess)
cond = struct('name',{SPM.Sess(iSess).U(:).name});
end

% =========================================================================
function tf = same_path(path1,path2)
path1 = strtrim(path1);
path2 = strtrim(path2);
if ispc
    tf = strcmpi(path1,path2);
else
    tf = strcmp(path1,path2);
end
end