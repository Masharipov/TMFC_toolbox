function tmfc = tmfc_append_subjects(tmfc,SPM_paths,subject_paths,add_type)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% FORMAT tmfc = tmfc_append_subjects(tmfc,SPM_paths,subject_paths)
% FORMAT tmfc = tmfc_append_subjects(tmfc,SPM_paths,subject_paths,add_type)
%
%   Inputs:
%   tmfc            - TMFC project structure
%   SPM_paths       - Full paths to new subject SPM.mat files
%   subject_paths   - Paths to new subject folders
%   add_type        - Subject addition type:
%                     1 - compatible with current session mode
%                     2 - requires strict -> repeated conversion
%
%   Output:
%   tmfc            - Updated TMFC project structure
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin < 4 || isempty(add_type)
    add_type = ones(length(SPM_paths),1);
end

if length(add_type) ~= length(SPM_paths)
    error('add_type must contain one value for each new subject.');
end

if any(~ismember(add_type,[1 2]))
    error('add_type must contain only 1 or 2.');
end

if ~isfield(tmfc,'subjects') || isempty(tmfc.subjects)
    error('No subjects are present in the TMFC project.');
end

if length(SPM_paths) ~= length(subject_paths)
    error('SPM_paths and subject_paths must contain the same number of subjects.');
end

nSub_old = length(tmfc.subjects);

% -------------------------------------------------------------------------
% Backward compatibility: session mode
if ~isfield(tmfc,'session_mode') || isempty(tmfc.session_mode)
    tmfc.session_mode = 'strict';
end

% -------------------------------------------------------------------------
% Backward compatibility: subject names
if ~isfield(tmfc.subjects,'name')
    for iSub = 1:nSub_old
        tmfc.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
    end
end

% -------------------------------------------------------------------------
% Backward compatibility: infer subject naming convention
if ~isfield(tmfc,'subject_naming') || isempty(tmfc.subject_naming)
    standard_names = true;
    for iSub = 1:nSub_old
        if isempty(regexp(tmfc.subjects(iSub).name,'^Subject_\d{4}$','once'))
            standard_names = false;
            break;
        end
    end
    if standard_names
        tmfc.subject_naming = 'standard';
    else
        tmfc.subject_naming = 'original';
    end
end

% -------------------------------------------------------------------------
% Backward compatibility: define next standard subject number
if strcmp(tmfc.subject_naming,'standard') && (~isfield(tmfc,'next_subject') || isempty(tmfc.next_subject))
    subject_numbers = zeros(1,nSub_old);
    for iSub = 1:nSub_old
        token = regexp(tmfc.subjects(iSub).name,'^Subject_(\d+)$','tokens','once');
        if ~isempty(token)
            subject_numbers(iSub) = str2double(token{1});
        end
    end
    tmfc.next_subject = max(subject_numbers) + 1;
end

% -------------------------------------------------------------------------
% Backward compatibility: preserve legacy ROI sets when the cohort changes
if isfield(tmfc,'ROI_set') && ~isempty(tmfc.ROI_set)
    legacy_idx = false(1,length(tmfc.ROI_set));

    for iSet = 1:length(tmfc.ROI_set)
        ROI_set = tmfc.ROI_set(iSet);

        if ~isfield(ROI_set,'ROIs') || isempty(ROI_set.ROIs)
            continue;
        end

        % Legacy binary images / fixed spheres:
        % one common group-masked ROI image for all subjects
        if isfield(ROI_set.ROIs(1),'path_masked') && ischar(ROI_set.ROIs(1).path_masked)
            legacy_idx(iSet) = true;
            continue;
        end

        % Legacy moving ROIs:
        % subject-specific masks already existed, but the F-contrast
        % definition required for extending the ROI set was not stored
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

        % Store the cohort for which these ROI sets were created
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

        % Remove legacy sets from the active ROI-set list
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

% -------------------------------------------------------------------------
% Convert strict project to repeated-run mode if required
if any(add_type == 2)

    if ~strcmp(tmfc.session_mode,'strict')
        error('Strict-to-repeated conversion can only be performed for a strict project.');
    end

    % Note:
    % add_type == 2 is returned by tmfc_validate_new_subjects only when
    % the existing project, new subjects and stored condition selections
    % are compatible with repeated-run mode.

    % ---------------------------------------------------------------------
    % Convert LSS conditions
    if isfield(tmfc,'LSS') && isfield(tmfc.LSS,'conditions') && ~isempty(tmfc.LSS.conditions)
        tmfc.LSS.conditions([tmfc.LSS.conditions.sess] ~= 1) = [];
        if isfield(tmfc.LSS.conditions,'list_name')
            for iCond = 1:length(tmfc.LSS.conditions)
                tmfc.LSS.conditions(iCond).list_name = strrep(tmfc.LSS.conditions(iCond).list_name,'(Run1,','(All runs,');
                tmfc.LSS.conditions(iCond).list_name = strrep(tmfc.LSS.conditions(iCond).list_name,'(Sess1,','(All runs,');
            end
        end
    end

    % ---------------------------------------------------------------------
    % Convert LSS-after-FIR conditions
    if isfield(tmfc,'LSS_after_FIR') && isfield(tmfc.LSS_after_FIR,'conditions') && ~isempty(tmfc.LSS_after_FIR.conditions)
        tmfc.LSS_after_FIR.conditions([tmfc.LSS_after_FIR.conditions.sess] ~= 1) = [];
        if isfield(tmfc.LSS_after_FIR.conditions,'list_name')
            for iCond = 1:length(tmfc.LSS_after_FIR.conditions)
                tmfc.LSS_after_FIR.conditions(iCond).list_name = strrep(tmfc.LSS_after_FIR.conditions(iCond).list_name,'(Run1,','(All runs,');
                tmfc.LSS_after_FIR.conditions(iCond).list_name = strrep(tmfc.LSS_after_FIR.conditions(iCond).list_name,'(Sess1,','(All runs,');
            end
        end
    end

    % ---------------------------------------------------------------------
    % Convert ROI-set condition definitions
    if isfield(tmfc,'ROI_set')      
        for iSet = 1:length(tmfc.ROI_set)
            ROI_set = tmfc.ROI_set(iSet);

            % gPPI conditions
            if isfield(ROI_set,'gPPI') && isstruct(ROI_set.gPPI) && ~isempty(ROI_set.gPPI) && isfield(ROI_set.gPPI,'conditions') && ~isempty(ROI_set.gPPI.conditions)
                tmfc.ROI_set(iSet).gPPI.conditions([tmfc.ROI_set(iSet).gPPI.conditions.sess] ~= 1) = [];
                if isfield(tmfc.ROI_set(iSet).gPPI.conditions,'list_name')
                    for iCond = 1:length(tmfc.ROI_set(iSet).gPPI.conditions)
                        tmfc.ROI_set(iSet).gPPI.conditions(iCond).list_name = strrep(tmfc.ROI_set(iSet).gPPI.conditions(iCond).list_name,'(Run1,','(All runs,');
                        tmfc.ROI_set(iSet).gPPI.conditions(iCond).list_name = strrep(tmfc.ROI_set(iSet).gPPI.conditions(iCond).list_name,'(Sess1,','(All runs,');
                    end
                end
            end

            % Moving-ROI F-contrast conditions
            if isfield(ROI_set,'F') && isstruct(ROI_set.F) && ~isempty(ROI_set.F) && isfield(ROI_set.F,'conditions') && ~isempty(ROI_set.F.conditions)
                tmfc.ROI_set(iSet).F.conditions([tmfc.ROI_set(iSet).F.conditions.sess] ~= 1) = [];
                if isfield(tmfc.ROI_set(iSet).F.conditions,'list_name')
                    for iCond = 1:length(tmfc.ROI_set(iSet).F.conditions)
                        tmfc.ROI_set(iSet).F.conditions(iCond).list_name = strrep(tmfc.ROI_set(iSet).F.conditions(iCond).list_name,'(Run1,','(All runs,');
                        tmfc.ROI_set(iSet).F.conditions(iCond).list_name = strrep(tmfc.ROI_set(iSet).F.conditions(iCond).list_name,'(Sess1,','(All runs,');
                    end
                end
            end
        end
    end

    % ---------------------------------------------------------------------
    % Switch session mode
    tmfc.session_mode = 'repeated';

    % ---------------------------------------------------------------------
    % Reset analyses that require repeated-mode outputs
    if isfield(tmfc,'ROI_set')
        for iSet = 1:length(tmfc.ROI_set)
            if isfield(tmfc.ROI_set(iSet),'subjects')
                for iSub = 1:min(nSub_old,length(tmfc.ROI_set(iSet).subjects))
                    tmfc.ROI_set(iSet).subjects(iSub).BGFC = 0;
                    tmfc.ROI_set(iSet).subjects(iSub).BSC = 0;
                    tmfc.ROI_set(iSet).subjects(iSub).BSC_after_FIR = 0;
                    tmfc.ROI_set(iSet).subjects(iSub).gPPI = 0;
                    tmfc.ROI_set(iSet).subjects(iSub).gPPI_FIR = 0;
                end
            end
        end
    end

    % ---------------------------------------------------------------------
    % Reset strict-mode contrasts.
    % Existing analysis functions will generate repeated-mode defaults.
    if isfield(tmfc,'ROI_set')
        for iSet = 1:length(tmfc.ROI_set)
            if isfield(tmfc.ROI_set(iSet),'contrasts') && isstruct(tmfc.ROI_set(iSet).contrasts) && ~isempty(tmfc.ROI_set(iSet).contrasts)
                if isfield(tmfc.ROI_set(iSet).contrasts,'gPPI')
                    tmfc.ROI_set(iSet).contrasts = rmfield(tmfc.ROI_set(iSet).contrasts,'gPPI');
                end

                if isfield(tmfc.ROI_set(iSet).contrasts,'gPPI_FIR')
                    tmfc.ROI_set(iSet).contrasts = rmfield(tmfc.ROI_set(iSet).contrasts,'gPPI_FIR');
                end

                if isfield(tmfc.ROI_set(iSet).contrasts,'BSC')
                    tmfc.ROI_set(iSet).contrasts = rmfield(tmfc.ROI_set(iSet).contrasts,'BSC');
                end

                if isfield(tmfc.ROI_set(iSet).contrasts,'BSC_after_FIR')
                    tmfc.ROI_set(iSet).contrasts = rmfield(tmfc.ROI_set(iSet).contrasts,'BSC_after_FIR');
                end
            else
                tmfc.ROI_set(iSet).contrasts = struct;
            end

            tmfc.ROI_set(iSet).contrasts.gPPI.title = [];
            tmfc.ROI_set(iSet).contrasts.gPPI.weights = [];

            tmfc.ROI_set(iSet).contrasts.gPPI_FIR.title = [];
            tmfc.ROI_set(iSet).contrasts.gPPI_FIR.weights = [];

            tmfc.ROI_set(iSet).contrasts.BSC.title = [];
            tmfc.ROI_set(iSet).contrasts.BSC.weights = [];

            tmfc.ROI_set(iSet).contrasts.BSC_after_FIR.title = [];
            tmfc.ROI_set(iSet).contrasts.BSC_after_FIR.weights = [];
        end
    end
end

% -------------------------------------------------------------------------
% Reserve standard subject names already present in the project or on disk.
% An old saved project can have a stale next_subject counter while newer
% results still exist in the same project output directory.
if strcmp(tmfc.subject_naming,'standard')
    if ~isfield(tmfc,'project_path') || isempty(tmfc.project_path) || ~isdir(tmfc.project_path)
        error('TMFC project output folder is missing. Cannot allocate a safe subject name.');
    end
    names_on_disk = tmfc_standard_names_on_disk(tmfc.project_path);
    reserved_subject_names = [{tmfc.subjects.name} names_on_disk(:)'];
end

% -------------------------------------------------------------------------
% Add new subjects
for iSub = 1:length(SPM_paths)
    iNew = nSub_old + iSub;

    % Subject path
    tmfc.subjects(iNew).path = SPM_paths{iSub};

    % Subject name
    if strcmp(tmfc.subject_naming,'original')
        subject_path = subject_paths{iSub};
        if ~isempty(subject_path) && subject_path(end) == filesep
            subject_path(end) = [];
        end
        [~,subject_name] = fileparts(subject_path);
        tmfc.subjects(iNew).name = subject_name;
    else
        % Never reassign a standard name if files/folders already use it,
        % even when next_subject came from an older project checkpoint
        while true
            subject_name = ['Subject_' num2str(tmfc.next_subject,'%04.f')];
            if ~any(strcmpi(subject_name,reserved_subject_names))
                break;
            end
            fprintf('TMFC: %s is already in use or has output files. Skipping.\n',subject_name);
            tmfc.next_subject = tmfc.next_subject + 1;
        end
        tmfc.subjects(iNew).name = subject_name;
        reserved_subject_names{end+1} = subject_name;
        tmfc.next_subject = tmfc.next_subject + 1;
    end

    % Existing subject-level analyses become incomplete for the new subject
    if isfield(tmfc.subjects,'FIR')
        tmfc.subjects(iNew).FIR = 0;
    end

    if isfield(tmfc.subjects,'LSS')
        tmfc.subjects(iNew).LSS = [];
    end

    if isfield(tmfc.subjects,'LSS_after_FIR')
        tmfc.subjects(iNew).LSS_after_FIR = [];
    end

    % Initialize progress for existing ROI sets
    if isfield(tmfc,'ROI_set')
        for iSet = 1:length(tmfc.ROI_set)
            tmfc.ROI_set(iSet).subjects(iNew).BGFC = 0;
            tmfc.ROI_set(iSet).subjects(iNew).BSC = 0;
            tmfc.ROI_set(iSet).subjects(iNew).BSC_after_FIR = 0;
            tmfc.ROI_set(iSet).subjects(iNew).VOI = 0;
            tmfc.ROI_set(iSet).subjects(iNew).PPI = 0;
            tmfc.ROI_set(iSet).subjects(iNew).gPPI = 0;
            tmfc.ROI_set(iSet).subjects(iNew).gPPI_FIR = 0;
        end
    end
end
end

% =========================================================================
% Discover occupied standard subject names in existing TMFC output folders
function names = tmfc_standard_names_on_disk(project_path)

    roots = {'LSS_regression','FIR_regression','LSS_regression_after_FIR','ROI_sets'};
    names = {};

    for iRoot = 1:numel(roots)
        root_dir = fullfile(project_path, roots{iRoot});
        if ~isdir(root_dir)
            continue;
        end

        % Traverse all ROI sets on disk
        pending = {root_dir};
        while ~isempty(pending)
            current_dir = pending{end};
            pending(end) = [];
            entries = dir(current_dir);

            for iEntry = 1:numel(entries)
                entry = entries(iEntry);
                item_name = entry.name;
                if strcmp(item_name,'.') || strcmp(item_name,'..')
                    continue;
                end

                % Match a complete Subject_XXXX identifier
                token = regexp(item_name,'^(Subject_[0-9]{4,})(?:$|[_.])','tokens','once');
                if ~isempty(token)
                    names{end+1} = token{1};
                end

                if entry.isdir
                    if ~isempty(regexp(item_name,'^Subject_[0-9]{4,}$','once'))
                        continue;
                    end
                    pending{end+1} = fullfile(current_dir,item_name);
                end
            end
        end
    end

    names = unique(names);
    names = names(:)';
end
