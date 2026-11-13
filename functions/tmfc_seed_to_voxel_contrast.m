function [sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,contrast_number,ROI_set_number,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates linear contrasts of seed-to-voxel FC images.
%
% FORMAT [sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,contrast_number)
%
%   type                   - TMFC analysis type
%                            1: gPPI
%                            2: gPPI-FIR
%                            3: BSC-LSS
%                            4: BSC-LSS after FIR
%
%   contrast_number        - Indices of contrasts to compute in tmfc struct
%    
%   tmfc.subjects.path            - Paths to individual SPM.mat files
%   tmfc.subjects.name            - Subject names within the TMFC project
%   tmfc.project_path             - Path where all results will be saved
%   tmfc.defaults.parallel        - 0 or 1 (sequential/parallel computing)
%   tmfc.session_mode             - 'strict' or 'repeated'
%                                   In repeated mode, contrasts are calculated
%                                   using across-run averaged estimates
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.type             - Type of the ROI set
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to ROI images masked by
%                                   individual first-level masks
%
% -------------------------------------------------------------------------
% For gPPI and gPPI-FIR analyses:
% tmfc.ROI_set(ROI_set_number).gPPI.conditions - List of conditions of
%                                                interest for gPPI and
%                                                gPPI-FIR analyses
%                                                (see tmfc_PPI)
% For BSC analyses:
% tmfc.LSS.conditions           - List of conditions of interest
%                                 for BSC-LSS analysis
%                                 (see tmfc_LSS)
% tmfc.LSS_after_FIR.conditions - List of conditions of interest
%                                 for BSC-LSS (after FIR) analysis
%                                 (see tmfc_LSS_after_FIR)
% -------------------------------------------------------------------------
%
% Example of the ROI set (see tmfc_select_ROIs_GUI and tmfc_create_ROI_set):
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).type = 'binary_images';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path_masked(1).subjects = '...\Subject_0001\ROI_1_masked.nii';
%   tmfc.ROI_set(1).ROIs(1).path_masked(2).subjects = '...\Subject_0002\ROI_1_masked.nii';                             
%
% FORMAT [sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,contrast_number,ROI_set_number)
% Run the function for the selected ROI set
%
%   tmfc                   - As above
%   ROI_set_number         - Number of the ROI set in the tmfc structure
%                            (by default, ROI_set_number = 1)
%
% FORMAT [sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,contrast_number,ROI_set_number,start_sub)
% Calculate contrasts starting from the specified subject.
%
%   start_sub              - Index of the first subject to process
%                            (by default, start_sub = 1)
%   
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin < 4 || isempty(ROI_set_number)
    ROI_set_number = 1;
end

if nargin < 5 || isempty(start_sub)
    start_sub = 1;
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

w = waitbar(0,'Please wait...','Name','Compute seed-to-voxel contrasts');
start_time = tic;
count_sub = 1;
cleanupObj = onCleanup(@unfreeze_after_ctrl_c);

nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(ROI_set_number).ROIs);
nCon = length(contrast_number);
sub_check = zeros(1,nSub);

switch type
    %================================gPPI==================================
    case 1
        for iSub = start_sub:nSub
            SPM = load(tmfc.subjects(iSub).path).SPM;
            XYZ  = SPM.xVol.XYZ;
            iXYZ = cumprod([1,SPM.xVol.DIM(1:2)'])*XYZ - sum(cumprod(SPM.xVol.DIM(1:2)'));
            hdr.dim   = SPM.Vbeta(1).dim;
            hdr.dt    = SPM.Vbeta(1).dt;
            hdr.pinfo = SPM.Vbeta(1).pinfo;
            hdr.mat   = SPM.Vbeta(1).mat;

            % Load default contrasts for conditions of interest
            cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;
            
            for jCond = 1:length(cond_list)
                
                % Repeated runs
                if strcmp(session_mode,'repeated')

                    file_name = ...
                        ['[All_Runs]_[Cond_' num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];

                    if isfield(cond_list,'bf') && ~isempty(cond_list(jCond).bf)
                        if cond_list(jCond).bf == 2
                            file_name = [file_name '_[TimeDeriv]'];
                        elseif cond_list(jCond).bf == 3
                            file_name = [file_name '_[DispDeriv]'];
                        end
                    end

                    file_name_old = '';

                % Strict mode
                else
                    file_name = strrep(cond_list(jCond).file_name,'[Sess_','[Run_');
                    file_name_old = strrep(file_name,'[Run_','[Sess_');
                end

                file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                    tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
                    'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(nROI).name, ...
                    [tmfc.subjects(iSub).name '_Contrast_' ...
                    num2str(jCond,'%04.f') '_' file_name '.nii']);

                if ~isempty(file_name_old)
                    file_old = fullfile(tmfc.project_path,'ROI_sets', ...
                        tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
                        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(nROI).name, ...
                        [tmfc.subjects(iSub).name '_Contrast_' ...
                        num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                else
                    file_old = '';
                end

                % If seed-to-voxel analysis has not been performed for the default contrasts
                if ~exist(file_new,'file') && (isempty(file_old) || ~exist(file_old,'file'))
                    disp('Seed-to-voxel analysis has not been performed previously. Performing seed-to-voxel gPPI analysis, please wait...');
                    analysis = tmfc.defaults.analysis;
                    tmfc.defaults.analysis = 3;
                    tmfc_gPPI(tmfc,ROI_set_number,1);
                    tmfc.defaults.analysis = analysis;
                end
                
                switch tmfc.defaults.parallel
                    case 0  % Sequential
                        for kROI = 1:nROI
                            file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
                                'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.nii']);

                            if ~isempty(file_name_old)
                                file_old = fullfile(tmfc.project_path,'ROI_sets', ...
                                    tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
                                    'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' ...
                                    num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                            else
                                file_old = '';
                            end

                            if exist(file_new,'file')
                                beta_file = file_new;
                            else
                                beta_file = file_old;
                            end

                            images(kROI).seed(jCond,:) = spm_data_read(spm_data_hdr_read(beta_file),'xyz',XYZ);
                        end
                    case 1  % Parallel
                        try
                            if isempty(gcp('nocreate')), parpool; end
                            figure(findobj('Tag','TMFC_GUI'));
                        end
                        parfor kROI = 1:nROI
                            file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
                                'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.nii']);

                            if ~isempty(file_name_old)
                                file_old = fullfile(tmfc.project_path,'ROI_sets', ...
                                    tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
                                    'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' ...
                                    num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                            else
                                file_old = '';
                            end

                            if exist(file_new,'file')
                                beta_file = file_new;
                            else
                                beta_file = file_old;
                            end

                            images(kROI).seed(jCond,:) = spm_data_read(spm_data_hdr_read(beta_file),'xyz',XYZ);
                        end
                end
            end
            % Calculate and save contrasts
            for jCon = 1:nCon
                switch tmfc.defaults.parallel
                    case 0  % Sequential
                        for kROI = 1:nROI
                            tmfc_gPPI_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ);
                        end
                    case 1  % Parallel
                        parfor kROI = 1:nROI
                            tmfc_gPPI_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ);
                        end
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
            sub_check(iSub) = 1;
            clear images
        end

    %=============================gPPI-FIR=================================
    case 2
        for iSub = start_sub:nSub
            SPM = load(tmfc.subjects(iSub).path).SPM;
            XYZ  = SPM.xVol.XYZ;
            iXYZ = cumprod([1,SPM.xVol.DIM(1:2)'])*XYZ - sum(cumprod(SPM.xVol.DIM(1:2)'));
            hdr.dim   = SPM.Vbeta(1).dim;
            hdr.dt    = SPM.Vbeta(1).dt;
            hdr.pinfo = SPM.Vbeta(1).pinfo;
            hdr.mat   = SPM.Vbeta(1).mat;

            % Load default contrasts for conditions of interest
            cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;

            for jCond = 1:length(cond_list)
                % Repeated runs
                if strcmp(session_mode,'repeated')

                    file_name = ...
                        ['[All_Runs]_[Cond_' num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];

                    if isfield(cond_list,'bf') && ~isempty(cond_list(jCond).bf)
                        if cond_list(jCond).bf == 2
                            file_name = [file_name '_[TimeDeriv]'];
                        elseif cond_list(jCond).bf == 3
                            file_name = [file_name '_[DispDeriv]'];
                        end
                    end

                    file_name_old = '';

                % Strict mode
                else
                    file_name = strrep(cond_list(jCond).file_name,'[Sess_','[Run_');
                    file_name_old = strrep(file_name,'[Run_','[Sess_');
                end

                file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                    tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR', ...
                    'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(nROI).name, ...
                    [tmfc.subjects(iSub).name '_Contrast_' ...
                    num2str(jCond,'%04.f') '_' file_name '.nii']);

                if ~isempty(file_name_old)
                    file_old = fullfile(tmfc.project_path,'ROI_sets', ...
                        tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR', ...
                        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(nROI).name, ...
                        [tmfc.subjects(iSub).name '_Contrast_' ...
                        num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                else
                    file_old = '';
                end

                % If seed-to-voxel analysis has not been performed for the default contrasts
                if ~exist(file_new,'file') && (isempty(file_old) || ~exist(file_old,'file'))
                    disp('Seed-to-voxel analysis has not been performed previously. Performing seed-to-voxel gPPI-FIR analysis, please wait...');
                    analysis = tmfc.defaults.analysis;
                    tmfc.defaults.analysis = 3;
                    tmfc_gPPI_FIR(tmfc,ROI_set_number,1);
                    tmfc.defaults.analysis = analysis;
                end
                
                switch tmfc.defaults.parallel
                    case 0  % Sequential
                        for kROI = 1:nROI
                            file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR', ...
                                'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.nii']);

                            if ~isempty(file_name_old)
                                file_old = fullfile(tmfc.project_path,'ROI_sets', ...
                                    tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR', ...
                                    'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' ...
                                    num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                            else
                                file_old = '';
                            end

                            if exist(file_new,'file')
                                beta_file = file_new;
                            else
                                beta_file = file_old;
                            end

                            images(kROI).seed(jCond,:) = spm_data_read(spm_data_hdr_read(beta_file),'xyz',XYZ);
                        end
                    case 1  % Parallel
                        try
                            if isempty(gcp('nocreate')), parpool; end
                            figure(findobj('Tag','TMFC_GUI'));
                        end
                        parfor kROI = 1:nROI
                            file_new = fullfile(tmfc.project_path,'ROI_sets', ...
                                tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR', ...
                                'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' ...
                                num2str(jCond,'%04.f') '_' file_name '.nii']);

                            if ~isempty(file_name_old)
                                file_old = fullfile(tmfc.project_path,'ROI_sets', ...
                                    tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR', ...
                                    'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' ...
                                    num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                            else
                                file_old = '';
                            end

                            if exist(file_new,'file')
                                beta_file = file_new;
                            else
                                beta_file = file_old;
                            end

                            images(kROI).seed(jCond,:) = spm_data_read(spm_data_hdr_read(beta_file),'xyz',XYZ);
                        end
                end
            end
            % Calculate and save contrasts
            for jCon = 1:nCon
                switch tmfc.defaults.parallel
                    case 0  % Sequential
                        for kROI = 1:nROI
                            tmfc_gPPI_FIR_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ);
                        end
                    case 1  % Parallel
                        parfor kROI = 1:nROI
                            tmfc_gPPI_FIR_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ);
                        end
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
            sub_check(iSub) = 1;
            clear images
        end

    %===============================BSC-LSS================================
    case 3
        for iSub = start_sub:nSub
            SPM = load(tmfc.subjects(iSub).path).SPM;
            XYZ  = SPM.xVol.XYZ;
            iXYZ = cumprod([1,SPM.xVol.DIM(1:2)'])*XYZ - sum(cumprod(SPM.xVol.DIM(1:2)'));
            hdr.dim   = SPM.Vbeta(1).dim;
            hdr.dt    = SPM.Vbeta(1).dt;
            hdr.pinfo = SPM.Vbeta(1).pinfo;
            hdr.mat   = SPM.Vbeta(1).mat;

            % Load default contrasts for conditions of interest
            cond_list = tmfc.LSS.conditions;
            for jCond = 1:length(cond_list)
                if strcmp(session_mode,'repeated')
                    file_name = ['[All_Runs]_[Cond_' num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];
                    file_name_old = '';
                else
                    file_name = ['[Run_' num2str(cond_list(jCond).sess) ']_[Cond_' ...
                        num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];
                    file_name_old = ['[Sess_' num2str(cond_list(jCond).sess) ']_[Cond_' ...
                        num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];
                end

                % If seed-to-voxel analysis has not been performed for the default contrasts
                file_new = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                    'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(nROI).name, ...
                    [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name '.nii']);

                if ~isempty(file_name_old)
                    file_old = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                        'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(nROI).name, ...
                        [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                else
                    file_old = '';
                end

                if ~exist(file_new,'file') && (isempty(file_old) || ~exist(file_old,'file'))
                    disp('Seed-to-voxel analysis has not been performed previously. Performing seed-to-voxel BSC-LSS analysis, please wait...');
                    analysis = tmfc.defaults.analysis;
                    tmfc.defaults.analysis = 3;
                    tmfc_BSC(tmfc,ROI_set_number,0);
                    tmfc.defaults.analysis = analysis;
                end
                
                switch tmfc.defaults.parallel
                    case 0  % Sequential
                        for kROI = 1:nROI
                            file_new = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                                'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name '.nii']);

                            if ~isempty(file_name_old)
                                file_old = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                                    'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                            else
                                file_old = '';
                            end

                            if exist(file_new,'file')
                                beta_file = file_new;
                            else
                                beta_file = file_old;
                            end

                            images(kROI).seed(jCond,:) = spm_data_read(spm_data_hdr_read(beta_file),'xyz',XYZ);
                        end
                    case 1  % Parallel
                        try
                            if isempty(gcp('nocreate')), parpool; end
                            figure(findobj('Tag','TMFC_GUI'));
                        end
                        parfor kROI = 1:nROI
                            file_new = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                                'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name '.nii']);

                            if ~isempty(file_name_old)
                                file_old = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                                    'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                            else
                                file_old = '';
                            end

                            if exist(file_new,'file')
                                beta_file = file_new;
                            else
                                beta_file = file_old;
                            end

                            images(kROI).seed(jCond,:) = spm_data_read(spm_data_hdr_read(beta_file),'xyz',XYZ);
                        end
                end
            end
            % Calculate and save contrasts
            for jCon = 1:nCon
                switch tmfc.defaults.parallel
                    case 0  % Sequential
                        for kROI = 1:nROI
                            tmfc_BSC_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ);
                        end
                    case 1  % Parallel
                        parfor kROI = 1:nROI
                            tmfc_BSC_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ);
                        end
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
            sub_check(iSub) = 1;
            clear images
        end

    %==========================BSC-LSS after FIR===========================
    case 4
        for iSub = start_sub:nSub
            SPM = load(tmfc.subjects(iSub).path).SPM;
            XYZ  = SPM.xVol.XYZ;
            iXYZ = cumprod([1,SPM.xVol.DIM(1:2)'])*XYZ - sum(cumprod(SPM.xVol.DIM(1:2)'));
            hdr.dim   = SPM.Vbeta(1).dim;
            hdr.dt    = SPM.Vbeta(1).dt;
            hdr.pinfo = SPM.Vbeta(1).pinfo;
            hdr.mat   = SPM.Vbeta(1).mat;

            % Load default contrasts for conditions of interest
            cond_list = tmfc.LSS_after_FIR.conditions;
            for jCond = 1:length(cond_list)
                if strcmp(session_mode,'repeated')
                    file_name = ['[All_Runs]_[Cond_' num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];
                    file_name_old = '';
                else
                    file_name = ['[Run_' num2str(cond_list(jCond).sess) ']_[Cond_' ...
                        num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];

                    file_name_old = ['[Sess_' num2str(cond_list(jCond).sess) ']_[Cond_' ...
                        num2str(cond_list(jCond).number) ']_[' ...
                        regexprep(cond_list(jCond).name,' ','_') ']'];
                end

                % If seed-to-voxel analysis has not been performed for the default contrasts
                file_new = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                    'BSC_LSS_after_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(nROI).name, ...
                    [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name '.nii']);

                if ~isempty(file_name_old)
                    file_old = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                        'BSC_LSS_after_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(nROI).name, ...
                        [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                else
                    file_old = '';
                end

                if ~exist(file_new,'file') && (isempty(file_old) || ~exist(file_old,'file'))
                    disp('Seed-to-voxel analysis has not been performed previously. Performing seed-to-voxel BSC-LSS after FIR analysis, please wait...');
                    analysis = tmfc.defaults.analysis;
                    tmfc.defaults.analysis = 3;
                    tmfc_BSC_after_FIR(tmfc,ROI_set_number,0);
                    tmfc.defaults.analysis = analysis;
                end
                
                switch tmfc.defaults.parallel
                    case 0  % Sequential
                        for kROI = 1:nROI
                            file_new = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                                'BSC_LSS_after_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name '.nii']);

                            if ~isempty(file_name_old)
                                file_old = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                                    'BSC_LSS_after_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                            else
                                file_old = '';
                            end

                            if exist(file_new,'file')
                                beta_file = file_new;
                            else
                                beta_file = file_old;
                            end

                            images(kROI).seed(jCond,:) = spm_data_read(spm_data_hdr_read(beta_file),'xyz',XYZ);
                        end
                    case 1  % Parallel
                        try
                            if isempty(gcp('nocreate')), parpool; end
                            figure(findobj('Tag','TMFC_GUI'));
                        end
                        parfor kROI = 1:nROI
                            file_new = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                                'BSC_LSS_after_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name '.nii']);

                            if ~isempty(file_name_old)
                                file_old = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                                    'BSC_LSS_after_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                                    [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' file_name_old '.nii']);
                            else
                                file_old = '';
                            end

                            if exist(file_new,'file')
                                beta_file = file_new;
                            else
                                beta_file = file_old;
                            end

                            images(kROI).seed(jCond,:) = spm_data_read(spm_data_hdr_read(beta_file),'xyz',XYZ);
                        end
                end
            end
            % Calculate and save contrasts
            for jCon = 1:nCon
                switch tmfc.defaults.parallel
                    case 0  % Sequential
                        for kROI = 1:nROI
                            tmfc_BSC_after_FIR_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ);
                        end
                    case 1  % Parallel
                        parfor kROI = 1:nROI
                            tmfc_BSC_after_FIR_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ);
                        end
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
            sub_check(iSub) = 1;
            clear images
        end
end

% Close waitbar
try
    delete(w)
end

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

%% ========================================================================

function tmfc_gPPI_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ)
    contrast = tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(jCon)).weights*images(kROI).seed;
    hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
        [tmfc.subjects(iSub).name '_Contrast_' num2str(contrast_number(jCon),'%04.f') '_[' ...
        regexprep(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(jCon)).title,' ','_') '].nii']);
    hdr.descrip = ['Linear contrast of PPI beta maps: ' tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(jCon)).title];    
    image = NaN(SPM.xVol.DIM');
    image(iXYZ) = contrast;
    spm_write_vol(hdr,image);
end

function tmfc_gPPI_FIR_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ)
    contrast = tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(contrast_number(jCon)).weights*images(kROI).seed;
    hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR', ...
        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
        [tmfc.subjects(iSub).name '_Contrast_' num2str(contrast_number(jCon),'%04.f') '_[' ...
        regexprep(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(contrast_number(jCon)).title,' ','_') '].nii']);
    hdr.descrip = ['Linear contrast of PPI beta maps: ' tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(contrast_number(jCon)).title];    
    image = NaN(SPM.xVol.DIM');
    image(iXYZ) = contrast;
    spm_write_vol(hdr,image);
end

function tmfc_BSC_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ)
    contrast = tmfc.ROI_set(ROI_set_number).contrasts.BSC(contrast_number(jCon)).weights*images(kROI).seed;
    hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS', ...
        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
        [tmfc.subjects(iSub).name '_Contrast_' num2str(contrast_number(jCon),'%04.f') '_[' ...
        regexprep(tmfc.ROI_set(ROI_set_number).contrasts.BSC(contrast_number(jCon)).title,' ','_') '].nii']);
    hdr.descrip = ['Linear contrast of z-value maps: ' tmfc.ROI_set(ROI_set_number).contrasts.BSC(contrast_number(jCon)).title];    
    image = NaN(SPM.xVol.DIM');
    image(iXYZ) = contrast;
    spm_write_vol(hdr,image);    
end

function tmfc_BSC_after_FIR_contrast(tmfc,ROI_set_number,contrast_number,jCon,images,kROI,hdr,iSub,SPM,iXYZ)
    contrast = tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(contrast_number(jCon)).weights*images(kROI).seed;
    hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR', ...
        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
        [tmfc.subjects(iSub).name '_Contrast_' num2str(contrast_number(jCon),'%04.f') '_[' ...
        regexprep(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(contrast_number(jCon)).title,' ','_') '].nii']);
    hdr.descrip = ['Linear contrast of z-value maps: ' tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(contrast_number(jCon)).title];    
    image = NaN(SPM.xVol.DIM');
    image(iXYZ) = contrast;
    spm_write_vol(hdr,image); 
end