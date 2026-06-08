function [ROI_set] = tmfc_select_ROIs_GUI(tmfc)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for selecting ROI masks. Creates a group mean binary 
% mask based on first-level masks (see SPM.VM) and applies it to all selected
% ROIs. Empty ROIs will be removed. Masked ROIs will be limited to only
% voxels that have data for all subjects. The dimensions, orientation, and
% voxel sizes of the masked ROI images will be adjusted according to the
% group mean binary mask.
%
% -------------------------------------------------------------------------
% Case 1: Select ROI binary images
% Use binary images that are the same for all subjects. These images will 
% be masked by the group mean binary image.
% -------------------------------------------------------------------------
% Case 2: Fixed spheres
% Create spheres that are the same for all subjects. The sphere center 
% is fixed. These spheres will be masked by the group mean binary image.
% -------------------------------------------------------------------------
% Case 3: Moving spheres inside fixed spheres
% Create subject-specific spheres. The sphere center is 
% moved to the local maximum* inside a fixed sphere of larger radius. These 
% spheres will be masked by the group mean binary image.
% -------------------------------------------------------------------------
% Case 4: Moving spheres inside ROI binary images
% Create subject-specific spheres. The sphere center is
% moved to the local maximum* inside a binary image. These spheres will be 
% masked by selected binary images and the group mean binary image.
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
%                           ('Subject_XXXX' naming will be used by default)
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

% Specify ROI set name
ROI_set_name = ROI_set_name_GUI();

% Specify ROI set structure   
if ~isempty(ROI_set_name) 
    ROI_type = ROI_type_GUI();
    if ~isempty(ROI_type)
        try
            ROI_set = ROI_set_generation(ROI_set_name,ROI_type);
        catch
            ROI_set = [];
            h = findall(0,'Type','figure','Tag','TMWWaitbar');
            if ~isempty(h) && isvalid(h)
                close(h)
            end
            warning('ROIs not selected.'); return;
        end
    else
        ROI_set = [];
        warning('ROIs not selected.');  return;
    end
else
    ROI_set = [];
    warning('ROIs not selected.');  return;
end
   
% -------------------------------------------------------------------------
% Select ROIs, create ROI masks and remove heavily cropped ROIs
function [ROI_set] = ROI_set_generation(ROI_set_name,ROI_type)
    
    swd = pwd;
    nSub = length(tmfc.subjects);

    ROI_set.set_name = ROI_set_name;
    ROI_set.type = ROI_type;

    SPM = load(tmfc.subjects(1).path).SPM;
    XYZ   = SPM.xVol.XYZ;
    XYZmm = SPM.xVol.M(1:3,:)*[XYZ; ones(1,size(XYZ,2))];
    
    switch ROI_type
        % -----------------------------------------------------------------
        case 'binary_images'
            ROI_paths = spm_select(inf,'image','Select ROI masks',{},pwd);
            if ~isempty(ROI_paths)
                for iROI = 1:size(ROI_paths,1)
                    [~, ROI_set.ROIs(iROI).name, ~] = fileparts(deblank(ROI_paths(iROI,:)));
                    ROI_set.ROIs(iROI).path = deblank(ROI_paths(iROI,:));
                    ROI_set.ROIs(iROI).path_masked = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_set.ROIs(iROI).name '_masked.nii']);
                end
            else
                ROI_set = [];
                warning('ROIs not selected.');  return;
            end     
        % -----------------------------------------------------------------
        case 'fixed_spheres'
            ROI_FS = select_ROIs_case_2();
            if ~isempty(ROI_FS)
                for iROI = 1:size(ROI_FS,2)
                    ROI_set.ROIs(iROI).name = ROI_FS(iROI).ROI_name;
                    ROI_set.ROIs(iROI).path_masked = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_set.ROIs(iROI).name '_masked.nii']);
                    ROI_set.ROIs(iROI).X = ROI_FS(iROI).X;
                    ROI_set.ROIs(iROI).Y = ROI_FS(iROI).Y;
                    ROI_set.ROIs(iROI).Z = ROI_FS(iROI).Z;
                    ROI_set.ROIs(iROI).radius = ROI_FS(iROI).radius;    
                end
            else
                ROI_set = [];
                warning('ROIs not selected.');  return;
            end
        % -----------------------------------------------------------------
        case 'moving_spheres_inside_fixed_spheres'
            ROI_MS = select_ROIs_case_3();
            if ~isempty(ROI_MS)                
                for iROI = 1:size(ROI_MS,2)
                    ROI_set.ROIs(iROI).name = ROI_MS(iROI).ROI_name;
                    for iSub = 1:nSub
                        ROI_set.ROIs(iROI).path_masked(iSub).subjects = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',...
                            tmfc.subjects(iSub).name,[ROI_set.ROIs(iROI).name '_masked.nii']);
                    end
                    ROI_set.ROIs(iROI).X = ROI_MS(iROI).X;
                    ROI_set.ROIs(iROI).Y = ROI_MS(iROI).Y;
                    ROI_set.ROIs(iROI).Z = ROI_MS(iROI).Z;
                    ROI_set.ROIs(iROI).moving_radius = ROI_MS(iROI).moving_radius;    
                    ROI_set.ROIs(iROI).fixed_radius = ROI_MS(iROI).fixed_radius;    
                end
            else
                ROI_set = [];
                warning('ROIs not selected.');  return;
            end
        % -----------------------------------------------------------------
        case 'moving_spheres_inside_binary_images'
            ROI_paths = spm_select(inf,'image','Select ROI masks',{},pwd);
            if ~isempty(ROI_paths)
                for iROI = 1:size(ROI_paths,1)
                    [~, ROI_set.ROIs(iROI).name, ~] = fileparts(deblank(ROI_paths(iROI,:)));
                    ROI_set.ROIs(iROI).path = deblank(ROI_paths(iROI,:));
                    for iSub = 1:nSub
                        ROI_set.ROIs(iROI).path_masked(iSub).subjects = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',...
                            tmfc.subjects(iSub).name,[ROI_set.ROIs(iROI).name '_masked.nii']);
                    end
                end
            else
                ROI_set = [];
                warning('ROIs not selected.');  return;
            end
            radius_vector = select_ROIs_case_4(size(ROI_paths,1));
            if ~isempty(radius_vector)
                for iROI = 1:size(ROI_paths,1)
                    ROI_set.ROIs(iROI).radius = radius_vector(iROI);
                end
            else
                ROI_set = [];
                warning('ROIs not selected.');  return;
            end
    end

    % ---------------------------------------------------------------------
    % Select omnibus F-contrast threshold
    if strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
        [Fthresh, Fmask] = F_contrast_GUI();
        if isempty(Fthresh)
            ROI_set = [];
            warning('ROIs not selected.');  return;
        end
    end

    % ---------------------------------------------------------------------
    % Clear & create 'Masked_ROIs' folder
    if isdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name))
        rmdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name),'s');
        pause(0.1);
    end
    
    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs'))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs'));
    end

    if strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
        for iSub = 1:nSub
            mkdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name));
        end
    end

    % ---------------------------------------------------------------------    
    % Create group mean binary mask
    for iSub = 1:nSub
        sub_mask{iSub,1} = [tmfc.subjects(iSub).path(1:end-7) 'mask.nii'];
    end
    group_mask_path = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs','Group_mask.nii');
        
    if nSub == 1
        copyfile(sub_mask{1,1},group_mask_path);
    else
        spm_imcalc(sub_mask,group_mask_path,'prod(X)',{1,0,1,2});
    end

    % ---------------------------------------------------------------------
    % Calculate F-contrast for all conditions of interest
    if strcmp(ROI_type,'moving_spheres_inside_fixed_spheres') || strcmp(ROI_type,'moving_spheres_inside_binary_images')
        % Contrast weights
        [conditions] = tmfc_conditions_GUI(tmfc.subjects(1).path,1);
        if isstruct(conditions)
            w = waitbar(0,'Please wait...','Name','Calculating F-contrasts');
            contrast_idx = nan(nSub,1);
            for iSub = 1:nSub
                cond_col = [];
                SPM = load(tmfc.subjects(iSub).path).SPM;
                cond_col = tmfc_get_F_contrast_columns(SPM,conditions);
                weights = zeros(length(cond_col),size(SPM.xX.X,2));
                for iCond = 1:length(cond_col)
                    weights(iCond,cond_col(iCond)) = 1;
                end

                % Check if contrast already exists
                idx = [];
                if isfield(SPM,'xCon') && ~isempty(SPM.xCon)
                    idx = find(arrayfun(@(c) isequal(c.c, weights'), SPM.xCon), 1, 'first');
                    nCon = numel(SPM.xCon);
                else
                    nCon = 0;
                end

                % Estimate contrasts only if missing
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
                try
                    waitbar(iSub/nSub,w,['Subject No ' num2str(iSub,'%.f')]);
                end
            end
            try
                close(w);
            end
        else
            fprintf(2,'ROI set not selected.\n');
            ROI_set = []; return;
        end
    end

    % ---------------------------------------------------------------------
    % Create spheres
    if ~strcmp(ROI_type,'binary_images')
        w = waitbar(0,'Please wait...','Name','Creating spherical masks');
    end

    switch ROI_type
        %------------------------------------------------------------------
        case 'fixed_spheres' 
            for iROI = 1:size(ROI_FS,2)
                job.spmmat = {tmfc.subjects(1).path};
                job.name = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',ROI_FS(iROI).ROI_name);
                job.roi{1}.sphere.centre = [ROI_FS(iROI).X ROI_FS(iROI).Y ROI_FS(iROI).Z];
                job.roi{1}.sphere.radius = ROI_FS(iROI).radius;
                job.roi{1}.sphere.move.fixed = 1;
                job.expression = 'i1';
                tmfc_create_spheres(job);
                clear job
                try
                    waitbar(iROI/size(ROI_FS,2),w,['ROI No ' num2str(iROI,'%.f')]);
                end
            end
        %------------------------------------------------------------------  
        case 'moving_spheres_inside_fixed_spheres'
            start_time = tic;
            count_sub = 1;
            cleanupObj = onCleanup(@unfreeze_after_ctrl_c);
            for iSub = 1:nSub
                SPM = load(tmfc.subjects(iSub).path).SPM;
                for jROI = 1:size(ROI_MS,2)
                    job.spmmat = {tmfc.subjects(iSub).path};
                    job.name = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,ROI_MS(jROI).ROI_name);
                    job.roi{1}.spm.spmmat = {tmfc.subjects(iSub).path};
                    job.roi{1}.spm.contrast = contrast_idx(iSub);
                    job.roi{1}.spm.conjunction = 1;
                    job.roi{1}.spm.threshdesc = 'none';
                    job.roi{1}.spm.thresh = Fthresh;
                    job.roi{1}.spm.extent = 0;
                    job.roi{1}.spm.mask = struct('contrast', {}, 'thresh', {}, 'mtype', {});
                    job.roi{2}.sphere.centre =  [ROI_MS(jROI).X ROI_MS(jROI).Y ROI_MS(jROI).Z];
                    job.roi{2}.sphere.radius = ROI_MS(jROI).fixed_radius;
                    job.roi{2}.sphere.move.fixed = 1;
                    job.roi{3}.sphere.centre = [ROI_MS(jROI).X ROI_MS(jROI).Y ROI_MS(jROI).Z];
                    job.roi{3}.sphere.radius = ROI_MS(jROI).moving_radius;
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
                % Generate spheres
                switch tmfc.defaults.parallel
                    case 0 % Sequential
                        for jROI = 1:size(ROI_MS,2)
                            tmfc_create_spheres(jobs{jROI});
                        end
                    case 1 % Parallel
                        parfor jROI = 1:size(ROI_MS,2)
                            tmfc_create_spheres(jobs{jROI});
                        end
                end
                % Update waitbar
                elapsed_time = toc(start_time);
                time_per_sub = elapsed_time/count_sub;
                count_sub = count_sub + 1;
                time_remaining = (nSub-iSub)*time_per_sub;
                hms = fix(mod((time_remaining), [0, 3600, 60]) ./ [3600, 60, 1]);
                try
                    waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec] remaining']);
                end
                clear SPM jobs
            end
        %-----------------------------------------------------------------
        case 'moving_spheres_inside_binary_images'
            start_time = tic;
            count_sub = 1;
            cleanupObj = onCleanup(@unfreeze_after_ctrl_c);
            % Calculate centroid coordinates before masking
            for iROI = 1:size(ROI_paths,1)
                binary_mask = [];
                coord = [];
                binary_mask = spm_data_read(ROI_set.ROIs(iROI).path,'xyz',XYZ);
                coord = XYZmm(:,(binary_mask ~= 0));
                centre(iROI).X = mean(coord(1,:));
                centre(iROI).Y = mean(coord(2,:));
                centre(iROI).Z = mean(coord(3,:));
            end
            for iSub = 1:nSub
                SPM = load(tmfc.subjects(iSub).path).SPM;
                for jROI = 1:size(ROI_paths,1)   
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
                    job.roi{3}.sphere.radius = radius_vector(jROI);
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
                % Generate spheres
                switch tmfc.defaults.parallel
                    case 0 % Sequential
                        for jROI = 1:size(ROI_paths,1)
                            tmfc_create_spheres(jobs{jROI});
                        end
                    case 1 % Parallel
                        parfor jROI = 1:size(ROI_paths,1)
                            tmfc_create_spheres(jobs{jROI});
                        end
                end
                % Update waitbar
                elapsed_time = toc(start_time);
                time_per_sub = elapsed_time/count_sub;
                count_sub = count_sub + 1;
                time_remaining = (nSub-iSub)*time_per_sub;
                hms = fix(mod((time_remaining), [0, 3600, 60]) ./ [3600, 60, 1]);
                try
                    waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec] remaining']);
                end
                clear SPM jobs
            end
    end

    try
        close(w);
    end

    % ---------------------------------------------------------------------
    % Calculate ROI size before masking
    w = waitbar(0,'Please wait...','Name','Calculating raw ROI sizes');
    group_mask = spm_vol(group_mask_path);
    nROI = numel(ROI_set.ROIs);
    for iROI = 1:nROI
        switch ROI_type
            case 'binary_images'
                ROI_mask = spm_vol(ROI_set.ROIs(iROI).path);
                Y = zeros(group_mask.dim(1:3));
                % Loop through slices
                for p = 1:group_mask.dim(3)
                    % Adjust dimensions, orientation, and voxel sizes to group mask
                    B = spm_matrix([0 0 -p 0 0 0 1 1 1]);
                    X = zeros(1,prod(group_mask.dim(1:2)));
                    M = inv(B * inv(group_mask.mat) * ROI_mask.mat);
                    d = spm_slice_vol(ROI_mask, M, group_mask.dim(1:2), 1);
                    d(isnan(d)) = 0;
                    X(1,:) = d(:)';
                    Y(:,:,p) = reshape(X,group_mask.dim(1:2));
                end
                % Raw ROI size (in voxels)
                ROI_set.ROIs(iROI).raw_size = nnz(Y);
            case 'fixed_spheres'
                binary_mask = [];
                binary_mask = spm_data_read(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_FS(iROI).ROI_name '.nii']),'xyz',XYZ);
                ROI_set.ROIs(iROI).raw_size = nnz(binary_mask);
            otherwise
                for jSub = 1:nSub
                    binary_mask = [];
                    binary_mask = spm_data_read(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(jSub).name,[ROI_set.ROIs(iROI).name '.nii']),'xyz',XYZ);
                    sub_size(jSub) = nnz(binary_mask);
                end
                ROI_set.ROIs(iROI).raw_size = min(sub_size);
                clear sub_size
        end
        try
            waitbar(iROI/nROI,w,['ROI No ' num2str(iROI,'%.f')]);
        end
    end
    
    try
        close(w);
    end
        
    % ---------------------------------------------------------------------
    % Mask ROI images by the group mean binary mask
    w = waitbar(0,'Please wait...','Name','Masking ROIs by group mean mask');
    input_images{1,1} = group_mask.fname;
    
    switch ROI_type
        case 'binary_images'
            for iROI = 1:nROI
                input_images{2,1} = ROI_set.ROIs(iROI).path;
                ROI_mask = ROI_set.ROIs(iROI).path_masked;
                spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
                try
                    waitbar(iROI/nROI,w,['ROI No ' num2str(iROI,'%.f')]);
                end
            end
        case 'fixed_spheres'
            for iROI = 1:nROI
                input_images{2,1} = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_FS(iROI).ROI_name '.nii']);
                ROI_mask = ROI_set.ROIs(iROI).path_masked;
                spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
                delete(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',[ROI_FS(iROI).ROI_name '.nii']));
                try
                    waitbar(iROI/nROI,w,['ROI No ' num2str(iROI,'%.f')]);
                end
            end
        otherwise
            start_time = tic;
            count_sub = 1;
            cleanupObj = onCleanup(@unfreeze_after_ctrl_c);
            for iSub = 1:nSub
                switch tmfc.defaults.parallel
                    case 0 % Sequential
                        for jROI = 1:nROI
                            tmfc_mask_moving_spheres(input_images,tmfc,ROI_set_name,iSub,ROI_set,jROI);
                        end
                    case 1 % Parallel
                        parfor jROI = 1:nROI
                            tmfc_mask_moving_spheres(input_images,tmfc,ROI_set_name,iSub,ROI_set,jROI);
                        end
                end
                % Update waitbar
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
   
    try
        close(w)
    end
    
    % ---------------------------------------------------------------------
    % Calculate ROI size after masking
    w = waitbar(0,'Please wait...','Name','Calculating masked ROI sizes');
    for iROI = 1:nROI
        switch ROI_type
            case 'binary_images'
                binary_mask = [];
                coord = [];
                binary_mask = spm_data_read(ROI_set.ROIs(iROI).path_masked,'xyz',XYZ);
                ROI_set.ROIs(iROI).masked_size = nnz(binary_mask);
                ROI_set.ROIs(iROI).masked_size_percents = 100*ROI_set.ROIs(iROI).masked_size/ROI_set.ROIs(iROI).raw_size;
                % Calculate centroid coordinates
                coord = XYZmm(:,(binary_mask ~= 0));
                ROI_set.ROIs(iROI).X = mean(coord(1,:));
                ROI_set.ROIs(iROI).Y = mean(coord(2,:));
                ROI_set.ROIs(iROI).Z = mean(coord(3,:));
            case 'fixed_spheres'
                binary_mask = [];
                binary_mask = spm_data_read(ROI_set.ROIs(iROI).path_masked,'xyz',XYZ);
                ROI_set.ROIs(iROI).masked_size = nnz(binary_mask);
                ROI_set.ROIs(iROI).masked_size_percents = 100*ROI_set.ROIs(iROI).masked_size/ROI_set.ROIs(iROI).raw_size;
            case 'moving_spheres_inside_fixed_spheres'
                for jSub = 1:nSub
                    binary_mask = [];
                    binary_mask = spm_data_read(ROI_set.ROIs(iROI).path_masked(jSub).subjects,'xyz',XYZ);
                    sub_size(jSub) = nnz(binary_mask);
                end
                sub_size(isnan(sub_size)) = 0;
                ROI_set.ROIs(iROI).masked_size = min(sub_size);
                ROI_set.ROIs(iROI).masked_size_percents = 100*ROI_set.ROIs(iROI).masked_size/ROI_set.ROIs(iROI).raw_size;
                clear sub_size
            case 'moving_spheres_inside_binary_images'
                for jSub = 1:nSub
                    binary_mask = [];
                    coord = [];
                    binary_mask = spm_data_read(ROI_set.ROIs(iROI).path_masked(jSub).subjects,'xyz',XYZ);
                    sub_size(jSub) = nnz(binary_mask);
                    coord = XYZmm(:,(binary_mask ~= 0));
                    sub_X(jSub) = mean(coord(1,:));
                    sub_Y(jSub) = mean(coord(2,:));
                    sub_Z(jSub) = mean(coord(3,:));
                end
                sub_size(isnan(sub_size)) = 0;
                ROI_set.ROIs(iROI).masked_size = min(sub_size);
                ROI_set.ROIs(iROI).masked_size_percents = 100*ROI_set.ROIs(iROI).masked_size/ROI_set.ROIs(iROI).raw_size;
                ROI_set.ROIs(iROI).X = mean(sub_X);
                ROI_set.ROIs(iROI).Y = mean(sub_Y);
                ROI_set.ROIs(iROI).Z = mean(sub_Z);
                clear sub_size sub_X sub_Y sub_Z
        end
        if isnan(ROI_set.ROIs(iROI).masked_size_percents)
            ROI_set.ROIs(iROI).masked_size_percents = 0;
        end
        try
            waitbar(iROI/nROI,w,['ROI No ' num2str(iROI,'%.f')]);
        end
    end
    
    try
        close(w)
    end
        
    % ---------------------------------------------------------------------
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
        
    % ---------------------------------------------------------------------
    % GUI interface for removing heavily cropped ROIs
    if ~isempty(empty_ROI_list)
        disp_empty_ROI_list = {};
        for iROI = 1:size(empty_ROI_list,1)
            ROI_string = horzcat('No ',num2str(empty_ROI_list{iROI,1}),': ',empty_ROI_list{iROI,2});
            disp_empty_ROI_list = vertcat(disp_empty_ROI_list, ROI_string);
        end
        
        % Display empty ROIs
        remove_empty_ROIs_GUI(disp_empty_ROI_list);

        % If all ROIs are empty
        if size(empty_ROI_list,1) == length(ROI_set.ROIs)
            warning('All ROIs are empty. Select different ROIs.');
            ROI_set = []; cd(swd); return;
        end
        
        % Remove empty ROIs
        ROI_index = 0;
        for iROI = 1:size(empty_ROI_list,1)
            ROI_set.ROIs(empty_ROI_list{iROI,1}-ROI_index) = [];
            ROI_index = ROI_index +1;
        end
        
        % Ask user to remove heavily cropped ROIs
        if isempty(ROI_set.ROIs)
            warning('All ROIs are empty. Select different ROIs.');
        else
            ROI_set = remove_cropped_ROIs_GUI(ROI_set);
        end
    else
        ROI_set = remove_cropped_ROIs_GUI(ROI_set);
    end

    % ---------------------------------------------------------------------
    if ~isfield(ROI_set,'set_name') || ~isfield(ROI_set,'ROIs')
        ROI_set = [];
    end

    cd(swd)

    % ---------------------------------------------------------------------
    function unfreeze_after_ctrl_c()    
        try
            delete(findall(0,'type','figure','Tag', 'tmfc_waitbar'));
            GUI = guidata(findobj('Tag','TMFC_GUI')); 
            set([GUI.TMFC_GUI_B1, GUI.TMFC_GUI_B2, GUI.TMFC_GUI_B3, GUI.TMFC_GUI_B4,...
               GUI.TMFC_GUI_B5a, GUI.TMFC_GUI_B5b, GUI.TMFC_GUI_B6, GUI.TMFC_GUI_B7,...
               GUI.TMFC_GUI_B8, GUI.TMFC_GUI_B9, GUI.TMFC_GUI_B10, GUI.TMFC_GUI_B11,...
               GUI.TMFC_GUI_B12a,GUI.TMFC_GUI_B12b,GUI.TMFC_GUI_B13a,GUI.TMFC_GUI_B13b,...
               GUI.TMFC_GUI_B14a, GUI.TMFC_GUI_B14b], 'Enable', 'on');
        end
    end
end
end

% -------------------------------------------------------------------------
function tmfc_mask_moving_spheres(input_images,tmfc,ROI_set_name,iSub,ROI_set,jROI)
    input_images{2,1} = fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,[ROI_set.ROIs(jROI).name '.nii']);
    individual_ROI_mask = ROI_set.ROIs(jROI).path_masked(iSub).subjects;
    spm_imcalc(input_images,individual_ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
    delete(fullfile(tmfc.project_path,'ROI_sets',ROI_set_name,'Masked_ROIs',tmfc.subjects(iSub).name,[ROI_set.ROIs(jROI).name '.nii']));
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
        'Second, select one or more ROI masks (*.nii files). TMFC toolbox will create a group mean binary mask based on individual subjects 1st-level masks (see SPM.VM) and apply it to all selected ROIs. Empty ROIs will be excluded from further analysis. Masked ROIs will be limited to only voxels which have data for all subjects. The dimensions, orientation, and voxel sizes of the masked ROI images will be adjusted according to the group mean binary mask. These files will be stored in "Masked_ROIs"',...
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

    select_ROI_type_GUI = figure('Name', 'Select ROIs','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.30 0.300 0.500], 'color', 'w', 'Tag', 'TMFC_Select_ROIs','resize', 'on','WindowStyle','modal', 'CloseRequestFcn', @close_ROI_type);

    sel_ROI_MP1 = uipanel(select_ROI_type_GUI ,'Units', 'normalized','Position',[0.03 0.775 0.94 0.195],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    sel_ROI_MP2 = uipanel(select_ROI_type_GUI ,'Units', 'normalized','Position',[0.03 0.55 0.94 0.195],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    sel_ROI_MP3 = uipanel(select_ROI_type_GUI ,'Units', 'normalized','Position',[0.03 0.315 0.94 0.205],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');
    sel_ROI_MP4 = uipanel(select_ROI_type_GUI ,'Units', 'normalized','Position',[0.03 0.082 0.94 0.21],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType', 'line');

    txt_1 = {'Use binary images that are the same for all subjects. These images will be masked by the group mean binary image.'};
    txt_2 = {'Create spheres that are the same for all subjects. The sphere center is fixed. These spheres will be masked by the group mean binary image.'};
    txt_3 = {'Create subject-specific spheres. The sphere center moves to the local maximum inside a fixed sphere of larger radius. These spheres will be masked by the group mean binary image.'};
    txt_4 = {'Create subject-specific spheres. The sphere center moves to the local maximum inside a binary image. These spheres will be masked by selected binary images and the group mean binary image.'};

    sel_ROI_B1 = uicontrol(select_ROI_type_GUI,'Style', 'pushbutton', 'String', 'Select ROI binary images', 'Units', 'normalized', 'Position', [0.05 0.875 0.90 0.074],'FontUnits','normalized','FontSize',0.33, 'callback', @binary_images);
    sel_ROI_B2 = uicontrol(select_ROI_type_GUI,'Style', 'pushbutton', 'String', 'Fixed spheres', 'Units', 'normalized', 'Position', [0.05 0.648 0.90 .074],'FontUnits','normalized','FontSize',0.33, 'callback', @fixed_spheres);
    sel_ROI_B3 = uicontrol(select_ROI_type_GUI,'Style', 'pushbutton', 'String', 'Moving spheres inside fixed spheres', 'Units', 'normalized', 'Position', [0.05 0.428 0.90 .074],'FontUnits','normalized','FontSize',0.33, 'callback', @moving_inside_fixed_spheres);
    sel_ROI_B4 = uicontrol(select_ROI_type_GUI,'Style', 'pushbutton', 'String', 'Moving spheres inside ROI binary images', 'Units', 'normalized', 'Position', [0.05 0.195 0.90 .074],'FontUnits','normalized','FontSize',0.33, 'callback', @moving_inside_binary_images);
    
    if isunix; fontscale = 0.9; else; fontscale = 1; end

    sel_ROI_txt_1 = uicontrol(select_ROI_type_GUI, 'Style', 'text','String', txt_1,'Units', 'normalized', 'Position',[0.05 0.78 0.90 0.08],'fontunits','normalized', 'fontSize', 0.33*fontscale, 'HorizontalAlignment','left','backgroundcolor','w');
    sel_ROI_txt_2 = uicontrol(select_ROI_type_GUI, 'Style', 'text','String', txt_2,'Units', 'normalized', 'Position',[0.05 0.555 0.90 0.08],'fontunits','normalized', 'fontSize', 0.33*fontscale, 'HorizontalAlignment','left','backgroundcolor','w');
    sel_ROI_txt_3 = uicontrol(select_ROI_type_GUI, 'Style', 'text','String', txt_3,'Units', 'normalized', 'Position',[0.05 0.32 0.90 0.1],'fontunits','normalized', 'fontSize', 0.24*fontscale, 'HorizontalAlignment','left','backgroundcolor','w');
    sel_ROI_txt_4 = uicontrol(select_ROI_type_GUI, 'Style', 'text','String', txt_4,'Units', 'normalized', 'Position',[0.05 0.085 0.90 0.1],'fontunits','normalized', 'fontSize', 0.24*fontscale, 'HorizontalAlignment','left','backgroundcolor','w');
    movegui(select_ROI_type_GUI,'center');
    
    function binary_images(~,~)
        ROI_type = 'binary_images';
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
                    '','For examples of coordinate tables, see the TMFC_toolbox folder.','','The sphere center will be moved to the local maximum inside a fixed sphere of larger radius. These spheres will be masked by the group mean binary image.',...
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

%% ===================[ F-contrast threshold GUI ]=========================
function [threshold, mask_status] = F_contrast_GUI

threshold = 0.05;
mask_status = 0;

F_contrast_MW = figure('Name', 'Select ROIs: F-contrast', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.28 0.2],'Resize','on','MenuBar', 'none', 'ToolBar', 'none','Tag','tmfc_F_contrast_GUI', 'color', 'w','WindowStyle','modal','CloseRequestFcn', @exit_MW); 

MW_txt_1 = uicontrol(F_contrast_MW,'Style','text','String', 'Omnibus F-Contrast will be used to move spheres to local maxima','Units', 'normalized', 'Position',[0.02 0.8 0.95 0.12],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w');
MW_txt_2 = uicontrol(F_contrast_MW,'Style','text','String', 'Enter a threshold for F-contrast:','Units' ,'normalized', 'Position',[0.150 0.58 0.55 0.12],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w');
MW_txt_3 = uicontrol(F_contrast_MW,'Style','text','String', 'Mask ROI images by thresholded F-map:','Units', 'normalized', 'Position',[0.03 0.37 0.68 0.12],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w');

MW_E1 = uicontrol(F_contrast_MW , 'Style', 'edit', 'String', threshold,'Units', 'normalized', 'Position',[0.7 0.59 0.180 0.115],'fontunits','normalized', 'fontSize', 0.58);
MW_E2 = uicontrol(F_contrast_MW , 'Style', 'popupmenu', 'String', {'No', 'Yes'},'Units', 'normalized', 'Position',[0.7 0.35 0.180 0.15],'fontunits','normalized', 'fontSize', 0.45);
    
MW_OK = uicontrol(F_contrast_MW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.2 0.1 0.25 0.15],'fontunits','normalized', 'fontSize', 0.4,'callback', @read_data);
MW_HELP = uicontrol(F_contrast_MW,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.55 0.1 0.25 0.15],'fontunits','normalized', 'fontSize', 0.4,'callback', @help_window);
movegui(F_contrast_MW, 'center');

    % Read and exit data
    function read_data(~,~)
        tmp_thresh = str2double(get(MW_E1, 'String'));
        tmp_mask = get(MW_E2, 'value');
        
        if ~isnan(tmp_thresh) && isreal(tmp_thresh) && tmp_thresh >= 0 && tmp_thresh <= 1
            
            if ~strcmp(tmp_thresh, 0.005)
                threshold = tmp_thresh;
            end
            
            if tmp_mask == 2
                mask_status = 1;
            end
            
            fprintf('Selected threshold for F-contrast: %f \n', threshold);
            
            uiresume(F_contrast_MW);
            
        else
            fprintf(2,'Please enter a threshold value between 0.0 and 1.0 \n');
        end        
        
    end

    function help_window(~,~)
        F_contrast_HW = figure('Name', 'F-contrast: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.30 0.44 0.28 0.25],'Resize','off','MenuBar', 'none', 'ToolBar', 'none', 'color', 'w','WindowStyle','modal'); 
        
        string_help = {'The center of the moving sphere will be moved to the local maximum inside a fixed sphere of larger radius.','',...
            'Local maxima are determined using the omnibus F-contrast for the selected conditions of interest.','',...
            'Additionally, moving spheres can be masked by the thresholded F-map of an individual subject. This can significantly reduce ROI size.',''};

        if isunix; fontscale = 0.8; else; fontscale = 1; end
        
        FC_HW_txt = uicontrol(F_contrast_HW,'Style','text','String', string_help,'Units', 'normalized', 'Position',[0.055 0.2 0.9 0.75],'fontunits','normalized', 'fontSize', 0.087*fontscale, 'horizontalAlignment', 'left','backgroundcolor','w');
        FC_HW_OK = uicontrol(F_contrast_HW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.37 0.05 0.25 0.14],'fontunits','normalized', 'fontSize', 0.4,'callback', @close_HW);
        movegui(F_contrast_HW, 'center');
    
        function close_HW(~,~)
            close(F_contrast_HW);
        end
    end

    % If exit, do we return default values or ''
    function exit_MW(~,~)
        threshold = '';
        mask_status = '';
        uiresume(F_contrast_MW);
    end

uiwait(F_contrast_MW);
delete(F_contrast_MW);
end

%% ====================[ Specify F-contrast ]==============================
function cond_col = tmfc_get_F_contrast_columns(SPM,conditions)

    cond_col = [];

    for iCond = 1:numel(conditions)

        sess = conditions(iCond).sess;
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

    % Prevent duplicated rows if the same column was selected twice
    cond_col = unique(cond_col,'stable');

end

