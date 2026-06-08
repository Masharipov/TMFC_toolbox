function [sub_check,contrasts,beta_scrubbing_summary] = tmfc_BSC_after_FIR(tmfc,ROI_set_number,clear_BSC,perform_beta_scrubbing,beta_scrubbing_options)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Extracts average (mean or first eigenvariate) beta series from selected
% ROIs. Correlates beta series for conditions of interest. Saves individual
% correlational matrices (ROI-to-ROI analysis) and correlational images
% (seed-to-voxel analysis) for each condition of interest. These refer to
% default contrasts, which can then be multiplied by linear contrast weights.
%
% FORMAT [sub_check,contrasts] = tmfc_BSC_after_FIR(tmfc)
%
%   tmfc.subjects.path     - Paths to individual SPM.mat files
%   tmfc.subjects.name     - Subject names within the TMFC project
%                           ('Subject_XXXX' naming will be used by default)
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.analysis - 1 (Seed-to-voxel and ROI-to-ROI analyses)
%                          - 2 (ROI-to-ROI analysis only)
%                          - 3 (Seed-to-voxel analysis only)
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.BSC_after_FIR    - 'mean' or 
%                                   'first_eigenvariate' (default)
%   tmfc.ROI_set.type             - Type of the ROI set
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to the ROI images masked by group
%                                   mean binary mask 
%
%   tmfc.LSS_after_FIR.conditions        - List of conditions of interest
%   tmfc.LSS_after_FIR.conditions.sess   - Session number
%                                          (as specified in SPM.Sess)
%   tmfc.LSS_after_FIR.conditions.number - Condition number 
%                                          (as specified in SPM.Sess.U)
%   tmfc.LSS_after_FIR.conditions.name   - Condition name
%                                          (as specified in SPM.Sess.U.name)
%   tmfc.LSS_after_FIR.conditions.file_name - Condition-specific file names:
%   (['[Sess_' num2str(iSess) ']_[Cond_' num2str(jCond) ']_[' ...
%    regexprep(char(SPM.Sess(iSess).U(jCond).name(1)),' ','_') ']'];)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contain three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified (see tmfc_conditions_GUI, nested function:
% [cond_list] = generate_conditions(SPM_path)):
%
%   tmfc.LSS_after_FIR.conditions(1).sess   = 1;   
%   tmfc.LSS_after_FIR.conditions(1).number = 1; 
%   tmfc.LSS_after_FIR.conditions(1).name = 'Cond_A'; 
%   tmfc.LSS_after_FIR.conditions(1).file_name = '[Sess_1]_[Cond_1]_[Cond_A]';  
%
%   tmfc.LSS_after_FIR.conditions(2).sess   = 1;
%   tmfc.LSS_after_FIR.conditions(2).number = 2;
%   tmfc.LSS_after_FIR.conditions(2).name = 'Cond_B';
%   tmfc.LSS_after_FIR.conditions(2).file_name = '[Sess_1]_[Cond_2]_[Cond_B]';  
%
%   tmfc.LSS_after_FIR.conditions(3).sess   = 2;
%   tmfc.LSS_after_FIR.conditions(3).number = 1;
%   tmfc.LSS_after_FIR.conditions(3).name = 'Cond_A';
%   tmfc.LSS_after_FIR.conditions(3).file_name = '[Sess_2]_[Cond_1]_[Cond_A]';  
%
%   tmfc.LSS_after_FIR.conditions(4).sess   = 2;
%   tmfc.LSS_after_FIR.conditions(4).number = 2;
%   tmfc.LSS_after_FIR.conditions(4).name = 'Cond_B';
%   tmfc.LSS_after_FIR.conditions(4).file_name = '[Sess_2]_[Cond_2]_[Cond_B]';  
%
% Example of the ROI set (see tmfc_select_ROIs_GUI):
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).type = 'binary_images';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path_masked = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path_masked = 'C:\ROI_set\two_ROIs\ROI_2.nii';
%
% FORMAT [sub_check,contrasts] = tmfc_BSC_after_FIR(tmfc,ROI_set_number)
% Run the function for the selected ROI set.
%
%   tmfc                   - As above
%   ROI_set_number         - Number of the ROI set in the tmfc structure
%                            (by default, ROI_set_number = 1)
%
% FORMAT [sub_check,contrasts] = tmfc_BSC_after_FIR(tmfc,ROI_set_number,clear_BSC)
% Run the function for the selected ROI set.
%
%   clear_BSC              - Clear previously created BSC (after FIR) folders
%                            (0 - do not clear, 1 - clear)
%                            (by default, clear_BSC = 1)
%
% FORMAT [sub_check,contrasts,beta_scrubbing_summary] = tmfc_BSC_after_FIR(tmfc,ROI_set_number,clear_BSC, ...
%                                                                                 perform_beta_scrubbing, ...
%                                                                                 beta_scrubbing_options)
%
%   perform_beta_scrubbing - 0 (do not perform beta scrubbing, default)
%                            1 (perform beta scrubbing)
%
%   beta_scrubbing_options - Structure with fields:
%                            .FD_thr          - FD threshold in mm
%                                               (default = 0.5)
%                            .time_window     - Time window in seconds from
%                                               trial onset (default = 12)
%                            .min_flagged_TRs - Minimum number of flagged
%                                               TRs to remove beta value
%                                               (default = 1)
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru
    
if nargin < 2 || isempty(ROI_set_number)
    ROI_set_number = 1;
end

if nargin < 3 || isempty(clear_BSC)
    clear_BSC = 1;
end

if nargin < 4 || isempty(perform_beta_scrubbing)
    perform_beta_scrubbing = 0;
end

if nargin < 5
    beta_scrubbing_options = [];
end

if ~isfield(tmfc.ROI_set(ROI_set_number),'BSC_after_FIR')
    tmfc.ROI_set(ROI_set_number).BSC_after_FIR = 'first_eigenvariate';
elseif isempty(tmfc.ROI_set(ROI_set_number).BSC_after_FIR)
    tmfc.ROI_set(ROI_set_number).BSC_after_FIR = 'first_eigenvariate';
end

% Check subject names
if ~isfield(tmfc.subjects,'name')
    for iSub = 1:length(tmfc.subjects)
        tmfc.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
    end
end

nROI = length(tmfc.ROI_set(ROI_set_number).ROIs);
nSub = length(tmfc.subjects);
sub_check = zeros(1,nSub);
cond_list = tmfc.LSS_after_FIR.conditions;
nCond = length(cond_list);

% Beta scrubbing options
%--------------------------------------------------------------------------
beta_scrubbing_summary = [];

if perform_beta_scrubbing == 1

    user_provided_beta_scrubbing_options = (nargin >= 5 && ~isempty(beta_scrubbing_options));

    if ~user_provided_beta_scrubbing_options
        beta_scrubbing_options = [];
    end
    
    % Default beta-scrubbing options
    if ~isfield(beta_scrubbing_options,'FD_thr') || isempty(beta_scrubbing_options.FD_thr)
        beta_scrubbing_options.FD_thr = 0.5;
    end
    if ~isfield(beta_scrubbing_options,'time_window') || isempty(beta_scrubbing_options.time_window)
        beta_scrubbing_options.time_window = 12;
    end
    if ~isfield(beta_scrubbing_options,'min_flagged_TRs') || isempty(beta_scrubbing_options.min_flagged_TRs)
        beta_scrubbing_options.min_flagged_TRs = 1;
    end
    
    % Load existing FD.mat files 
    disp('Preparing FD time series...');
    FD = repmat(tmfc_empty_FD(), nSub, 1);
    missing_FD = false(nSub,1);

    for iSub = 1:nSub
        [FD_i, ok] = tmfc_load_subject_FD(tmfc.subjects(iSub).path);

        if ok
            FD(iSub) = FD_i;
        else
            missing_FD(iSub) = true;
        end
    end

    % Calculate FD only for subjects without valid FD.mat
    if any(missing_FD)

        % Define motion parameters 
        motion_options = tmfc_motion_definition_GUI;

        % User closed motion-definition GUI
        if isempty(motion_options)
            sub_check = [];
            contrasts = [];
            beta_scrubbing_summary = [];
            disp('BSC LSS after FIR computation not initiated. Motion definition was not specified.');
            return;
        end

        missing_idx = find(missing_FD);

        for ii = 1:numel(missing_idx)
            iSub = missing_idx(ii);
            FD(iSub) = tmfc_calculate_subject_FD(tmfc.subjects(iSub).path,motion_options);
        end
    end

    % If user did not specify beta-scrubbing options, open GUI
    if ~user_provided_beta_scrubbing_options
        beta_scrubbing_options = tmfc_beta_scrubbing_GUI(tmfc,FD,'LSS_after_FIR');

        % User closed beta-scrubbing GUI
        if isempty(beta_scrubbing_options)
            sub_check = [];
            contrasts = [];
            beta_scrubbing_summary = [];
            disp('BSC LSS after FIR computation not initiated. Beta-scrubbing parameters were not specified.');
            return;
        end
    end

    beta_scrubbing_summary.perform = 1;
    beta_scrubbing_summary.FD_thr = beta_scrubbing_options.FD_thr;
    beta_scrubbing_summary.time_window = beta_scrubbing_options.time_window;
    beta_scrubbing_summary.min_flagged_TRs = beta_scrubbing_options.min_flagged_TRs;
else
    FD = struct([]);
    beta_scrubbing_options = [];
    beta_scrubbing_summary.perform = 0;
    beta_scrubbing_summary.FD_thr = [];
    beta_scrubbing_summary.time_window = [];
    beta_scrubbing_summary.min_flagged_TRs = [];
end

% Clear previously created BSC (after FIR) folders
if clear_BSC == 1
    if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR'))
        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR'),'s');
        pause(0.1);
    end
end

% Create BSC (after FIR) folders
if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','Beta_series'))
    mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','Beta_series'));
end

if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','ROI_to_ROI'))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','ROI_to_ROI'));
    end
end

if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
    for iROI = 1:nROI
        if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(iROI).name))
            mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(iROI).name));
        end
    end
end

SPM = load(tmfc.subjects(1).path).SPM;
XYZ  = SPM.xVol.XYZ;
iXYZ = cumprod([1,SPM.xVol.DIM(1:2)'])*XYZ - sum(cumprod(SPM.xVol.DIM(1:2)'));
hdr.dim = SPM.Vbeta(1).dim;
hdr.dt = SPM.Vbeta(1).dt;
hdr.pinfo = SPM.Vbeta(1).pinfo;
hdr.mat = SPM.Vbeta(1).mat;

% Loading ROIs
switch tmfc.ROI_set(ROI_set_number).type
    case {'binary_images','fixed_spheres'}
        w = waitbar(0,'Please wait...','Name','Loading ROIs');
        for iROI = 1:nROI
            ROIs(iROI).mask = spm_data_read(spm_data_hdr_read(tmfc.ROI_set(ROI_set_number).ROIs(iROI).path_masked),'xyz',XYZ);
            ROIs(iROI).mask(ROIs(iROI).mask == 0) = NaN;
            try
                waitbar(iROI/nROI,w,['ROI No ' num2str(iROI,'%.f')]);
            end
        end
        try
            delete(w)
        end
    otherwise
        ROIs = [];
end

% Sequential or parallel computing
switch tmfc.defaults.parallel
    % ----------------------- Sequential Computing ------------------------
    case 0

        % Create waitbar
        w = waitbar(0,'Please wait...','Name','Extract and correlate beta series','Tag','tmfc_waitbar');
        start_time = tic;
        count_sub = 1;
        cleanupObj = onCleanup(@unfreeze_after_ctrl_c);  

        for iSub = 1:nSub
            tmfc_extract_betas_after_FIR(tmfc,ROI_set_number,ROIs,nROI,nCond,cond_list,XYZ,iXYZ,hdr,iSub,FD,perform_beta_scrubbing,beta_scrubbing_options);
            sub_check(iSub) = 1;

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

    % ------------------------ Parallel Computing -------------------------
    case 1
        
        % Create waitbar
        try   % Waitbar for MATLAB R2017a and higher
            D = parallel.pool.DataQueue;            
            w = waitbar(0,'Please wait...','Name','Extract and correlate beta series','Tag','tmfc_waitbar');
            afterEach(D, @tmfc_parfor_waitbar);    
            tmfc_parfor_waitbar(w,nSub,1);     
        catch % No waitbar for MATLAB R2016b and earlier
            D = [];
            opts = struct('WindowStyle','non-modal','Interpreter','tex');
            w = warndlg({'\fontsize{12}Sorry, waitbar progress update is not available for parallel computations in MATLAB R2016b and earlier.',[],...
                'Please wait until all computations are completed.',[],...
                'If you want to interrupt computations:',...
                '   1) Do not close this window;',...
                '   2) Select MATLAB main window;',...
                '   3) Press Ctrl+C.'},'Please wait...',opts);
        end
        
        cleanupObj = onCleanup(@unfreeze_after_ctrl_c);
        
        try
            if isempty(gcp('nocreate')), parpool; end
            figure(findobj('Tag','TMFC_GUI'));
        end

        parfor iSub = 1:nSub
            tmfc_extract_betas_after_FIR(tmfc,ROI_set_number,ROIs,nROI,nCond,cond_list,XYZ,iXYZ,hdr,iSub,FD,perform_beta_scrubbing,beta_scrubbing_options);
            sub_check(iSub) = 1;

            % Update waitbar 
            try
                send(D,[]); 
            end
        end    
end

% Default contrasts info
for iCond = 1:nCond
    contrasts(iCond).title = cond_list(iCond).file_name;
    contrasts(iCond).weights = zeros(1,nCond);
    contrasts(iCond).weights(1,iCond) = 1;
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

% Extract and correlate betas
function tmfc_extract_betas_after_FIR(tmfc,ROI_set_number,ROIs,nROI,nCond,cond_list,XYZ,iXYZ,hdr,iSub,FD,perform_beta_scrubbing,beta_scrubbing_options)
    SPM = load(tmfc.subjects(iSub).path).SPM;

    if perform_beta_scrubbing == 1
        FD_subject = FD(iSub);
    end
    
    clear beta_series
    
    % Load individual ROIs
    if isempty(ROIs)
        for iROI = 1:nROI
            ROIs(iROI).mask = spm_data_read(spm_data_hdr_read(tmfc.ROI_set(ROI_set_number).ROIs(iROI).path_masked(iSub).subjects),'xyz',XYZ);
            ROIs(iROI).mask(ROIs(iROI).mask == 0) = NaN;
        end
    end
    
    % Conditions of interest
    for jCond = 1:nCond

        % Extract average beta series from ROIs
        % -------------------------------------
        disp(['Extracting average beta series: Subject: ' num2str(iSub) ' || Condition: ' num2str(jCond)]);
        
        % Exclude edge trials (onset < 0s or onset > end-8s)
        % -------------------------------------------------------------
        iSess = cond_list(jCond).sess;
        iU    = cond_list(jCond).number;

        RT   = SPM.xY.RT;
        tEnd = (SPM.nscan(iSess)-1)*RT;
        tMax = tEnd - 8;  % seconds before end to exclude

        ons = SPM.Sess(iSess).U(iU).ons;

        % Convert onsets to seconds for filtering
        if strcmpi(SPM.xBF.UNITS,'scans')
            ons_sec = ons * RT;
        else
            ons_sec = ons;
        end

        keep = (ons_sec >= 0) & (ons_sec <= tMax);
        trial_idx = find(keep);
        trial_onsets_sec = ons_sec(keep);

        % If no valid trials 
        if isempty(trial_idx)
            error('Condition has no usable trials: all onsets are too close to session start or end (Sub %d, Sess %d, %s).', ...
                   iSub, iSess, cond_list(jCond).file_name);
        end

        % Load only kept trials BUT keep original trial indices in filenames
        betas = [];
        for kk = 1:length(trial_idx)
            kTrial = trial_idx(kk);
            betas(kk,:) = spm_data_read(spm_data_hdr_read(fullfile(tmfc.project_path,'LSS_regression_after_FIR',tmfc.subjects(iSub).name,'Betas', ...
                ['Beta_' cond_list(jCond).file_name '_[Trial_' num2str(kTrial) '].nii'])),'xyz',XYZ);
        end

        % Beta scrubbing flags for loaded trials
        if perform_beta_scrubbing == 1
            flagged_beta = tmfc_flag_betas_from_FD(FD_subject.Sess(iSess).FD_ts,trial_onsets_sec,RT,beta_scrubbing_options);
        else
            flagged_beta = zeros(length(trial_idx),1);
        end

        clear iSess iU RT tEnd tMax ons ons_sec keep kk kTrial

        % Remove NaN columns (voxels outside brain)
        tmp_betas = betas;
        tmp_betas(:, all(isnan(tmp_betas),1)) = [];

        % Row indices with zeros
        isZeroRow = all(tmp_betas == 0, 2);
        idxZero   = find(isZeroRow);
        
        % Row indices > 2 SD among non-zero rows      
        rowNorm   = sqrt(sum(tmp_betas.^2, 2));
        validRows = ~isZeroRow & isfinite(rowNorm);
        
        % Remove zeros and outliers
        if nnz(validRows) < 3
            badRows = idxZero;  
        else
            mu = mean(rowNorm(validRows));
            sd = std(rowNorm(validRows));
            idxOut2SD = find(validRows & (rowNorm > mu + 2*sd));
            badRows = unique([idxZero; idxOut2SD]);
        end

        betas(badRows,:) = [];
        trial_idx(badRows) = [];
        trial_onsets_sec(badRows) = [];
        flagged_beta(badRows) = [];

        % Save all beta values before scrubbing
        beta_series(jCond).trial_numbers = trial_idx(:);
        beta_series(jCond).trial_onsets_sec = trial_onsets_sec(:);
        beta_series(jCond).beta_flagged = logical(flagged_beta(:));
        beta_series(jCond).FD_thr = [];
        beta_series(jCond).beta_values = [];
        beta_series(jCond).beta_values_thresholded = [];

        % Use all remaining betas before scrubbing
        betas_all = betas;

        % Apply beta scrubbing
        if perform_beta_scrubbing == 1
            keep_beta = ~logical(flagged_beta(:));
            betas_for_corr = betas(keep_beta,:);
            beta_series(jCond).FD_thr = beta_scrubbing_options.FD_thr;
            beta_series(jCond).time_window = beta_scrubbing_options.time_window;
            beta_series(jCond).min_flagged_TRs = beta_scrubbing_options.min_flagged_TRs;
        else
            keep_beta = true(size(betas,1),1);
            betas_for_corr = betas;
        end

        % If too few betas remain after scrubbing
        if size(betas_for_corr,1) < 3
            error('Condition has fewer than 3 usable beta values (Sub %d, Sess %d, %s).', ...
                iSub, cond_list(jCond).sess, cond_list(jCond).file_name);
        end

        for kROI = 1:nROI
            betas_masked_all = betas_all;
            betas_masked_all(:,isnan(ROIs(kROI).mask)) = []; 
            if strcmp(tmfc.ROI_set(ROI_set_number).BSC_after_FIR,'mean')
                beta_series(jCond).beta_values(:,kROI) = mean(betas_masked_all,2);
            elseif strcmp(tmfc.ROI_set(ROI_set_number).BSC_after_FIR,'first_eigenvariate')
                betas_masked_all = betas_masked_all - mean(betas_masked_all,1);
                [m,n]   = size(betas_masked_all);
                if m > n
                    [v,s,v] = svd(betas_masked_all'*betas_masked_all);
                    s       = diag(s);
                    v       = v(:,1);
                    u       = betas_masked_all*v/sqrt(s(1));
                else
                    [u,s,u] = svd(betas_masked_all*betas_masked_all');
                    s       = diag(s);
                    u       = u(:,1);
                    v       = betas_masked_all'*u/sqrt(s(1));
                end
                d       = sign(sum(v));
                u       = u*d;
                beta_series(jCond).beta_values(:,kROI) = (u*sqrt(s(1)/n))';    
                clear betas_masked_all v s u d m n
            end

            betas_masked_thr = betas_for_corr;
            betas_masked_thr(:,isnan(ROIs(kROI).mask)) = [];
            if strcmp(tmfc.ROI_set(ROI_set_number).BSC_after_FIR,'mean')
                beta_series(jCond).beta_values_thresholded(:,kROI) = mean(betas_masked_thr,2);
            elseif strcmp(tmfc.ROI_set(ROI_set_number).BSC_after_FIR,'first_eigenvariate')
                betas_masked_thr = betas_masked_thr - mean(betas_masked_thr,1);
                [m,n] = size(betas_masked_thr);
                if m > n
                    [v,s,v] = svd(betas_masked_thr'*betas_masked_thr);
                    s       = diag(s);
                    v       = v(:,1);
                    u       = betas_masked_thr*v/sqrt(s(1));
                else
                    [u,s,u] = svd(betas_masked_thr*betas_masked_thr');
                    s       = diag(s);
                    u       = u(:,1);
                    v       = betas_masked_thr'*u/sqrt(s(1));
                end
                d = sign(sum(v));
                u = u*d;
                beta_series(jCond).beta_values_thresholded(:,kROI) = (u*sqrt(s(1)/n))';
                clear betas_masked_thr v s u d m n
            end
        end

        % ROI-to-ROI correlation
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
            z_matrix = atanh(tmfc_corr(beta_series(jCond).beta_values_thresholded));
            z_matrix(1:size(z_matrix,1)+1:end) = nan;     

            % Save BSC matrices
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','ROI_to_ROI', ...
                [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.mat']),'z_matrix');

            clear z_matrix
        end

        % Seed-to-voxel correlation
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
            for kROI = 1:nROI
                BSC_image(kROI).z_value = atanh(tmfc_corr(beta_series(jCond).beta_values_thresholded(:,kROI),betas_for_corr));
            end

            % Save BSC images
            for kROI = 1:nROI
                hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR', ...
                    'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                    [tmfc.subjects(iSub).name '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.nii']);
                hdr.descrip = ['z-value map: ' cond_list(jCond).file_name];    
                image = NaN(SPM.xVol.DIM');
                image(iXYZ) = BSC_image(kROI).z_value;
                spm_write_vol(hdr,image);
            end

            clear BSC_image
        end

        clear betas betas_all betas_for_corr keep_beta flagged_beta trial_idx trial_onsets_sec tmp_betas isZeroRow idxZero idxOut2SD rowNorm validRows mu sd badRows
    end

    % Save average beta-series
    save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','Beta_series', ...
        [tmfc.subjects(iSub).name '_beta_series.mat']),'beta_series');
end

% Waitbar for parallel mode
function tmfc_parfor_waitbar(waitbarHandle,iterations,firstsub)
    persistent w nSub start_sub start_time count_sub 
    if nargin == 3
        w = waitbarHandle;
        nSub = iterations;
        start_sub = firstsub - 1;
        start_time = tic;
        count_sub = 1;
    else
        if isvalid(w)         
            elapsed_time = toc(start_time);
            time_per_sub = elapsed_time/count_sub;
            iSub = start_sub + count_sub;
            time_remaining = (nSub-iSub)*time_per_sub;
            hms = fix(mod((time_remaining), [0, 3600, 60]) ./ [3600, 60, 1]);
            waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec] remaining']);
            count_sub = count_sub + 1;
        end
    end
end

% =========================================================================
% Empty FD structure
function FD_subject = tmfc_empty_FD()

    FD_subject = struct;
    FD_subject.Sess = struct([]);
    FD_subject.FD_mean = NaN;
    FD_subject.FD_max = NaN;
end

% =========================================================================
% Load existing FD.mat
function [FD_subject, ok] = tmfc_load_subject_FD(SPM_path)

    FD_subject = tmfc_empty_FD();
    ok = false;

    FD_path = fullfile(tmfc_get_TMFC_denoise_dir(SPM_path),'FD.mat');

    if ~exist(FD_path,'file')
        return
    end

    tmp = load(FD_path);

    if ~isfield(tmp,'FramewiseDisplacement')
        return
    end

    FD_loaded = tmp.FramewiseDisplacement;

    if ~isfield(FD_loaded,'Sess') || isempty(FD_loaded.Sess)
        return
    end

    sub_FD_mean = nan(1,length(FD_loaded.Sess));
    sub_FD_max  = nan(1,length(FD_loaded.Sess));

    for jSess = 1:length(FD_loaded.Sess)

        if ~isfield(FD_loaded.Sess(jSess),'FD_ts') || isempty(FD_loaded.Sess(jSess).FD_ts)
            return
        end

        FD_subject.Sess(jSess).FD_ts = FD_loaded.Sess(jSess).FD_ts(:);
        FD_subject.Sess(jSess).FD_mean = mean(FD_subject.Sess(jSess).FD_ts);
        FD_subject.Sess(jSess).FD_max  = max(FD_subject.Sess(jSess).FD_ts);

        sub_FD_mean(jSess) = FD_subject.Sess(jSess).FD_mean;
        sub_FD_max(jSess)  = FD_subject.Sess(jSess).FD_max;
    end

    FD_subject.FD_mean = mean(sub_FD_mean);
    FD_subject.FD_max  = max(sub_FD_max);

    ok = true;
end

% =========================================================================
% Find TMFC_denoise folder for original or denoised GLM paths
function denoise_dir = tmfc_get_TMFC_denoise_dir(SPM_path)

    glm_dir = fileparts(SPM_path);

    % Case 1:
    % SPM_path is already inside ...\TMFC_denoise\...
    tok = regexpi(glm_dir, '^(.*?[\\/]TMFC_denoise)([\\/].*)?$', 'tokens', 'once');

    if ~isempty(tok)
        denoise_dir = tok{1};
    else
        % Case 2:
        % SPM_path is original GLM path, so FD.mat should be in:
        % original_GLM\TMFC_denoise\FD.mat
        denoise_dir = fullfile(glm_dir,'TMFC_denoise');
    end
end

% =========================================================================
% Calculate FD time series from SPM.mat
function FD_subject = tmfc_calculate_subject_FD(SPM_path,motion_options)

    FD_subject = tmfc_empty_FD();

    options = motion_options;
    options.head_radius = 50;

    SPM = load(SPM_path).SPM;

    sub_FD_mean = nan(1,length(SPM.Sess));
    sub_FD_max  = nan(1,length(SPM.Sess));

    for jSess = 1:length(SPM.Sess)

        if size(SPM.Sess(jSess).C.C,2) < 6
            error('The original model contains fewer than six confound regressors. It must include six head motion regressors. Please check:\n%s',SPM_path);
        end

        HMP = SPM.Sess(jSess).C.C(:,[options.translation_idx options.rotation_idx]);
        HMP_diff = [zeros(1,6); diff(HMP)];

        HMP_diff_xyz = HMP_diff(:,1:3);
        HMP_diff_rot = HMP_diff(:,4:6);

        if strcmpi(options.rotation_unit,'rad')
            HMP_diff_rot = options.head_radius * HMP_diff_rot;
        elseif strcmpi(options.rotation_unit,'deg')
            HMP_diff_rot = options.head_radius * pi/180 * HMP_diff_rot;
        end

        ts_FD = sum(abs(HMP_diff_xyz),2) + sum(abs(HMP_diff_rot),2);

        FD_subject.Sess(jSess).FD_ts = ts_FD;
        FD_subject.Sess(jSess).FD_mean = mean(ts_FD);
        FD_subject.Sess(jSess).FD_max  = max(ts_FD);

        sub_FD_mean(jSess) = FD_subject.Sess(jSess).FD_mean;
        sub_FD_max(jSess)  = FD_subject.Sess(jSess).FD_max;
    end

    FD_subject.FD_mean = mean(sub_FD_mean);
    FD_subject.FD_max  = max(sub_FD_max);
end

% =========================================================================
% Flag beta values based on FD in post-onset time window
function flagged_beta = tmfc_flag_betas_from_FD(FD_ts,trial_onsets_sec,RT,beta_scrubbing_options)

    flagged_beta = zeros(length(trial_onsets_sec),1);
    scan_times = (0:length(FD_ts)-1)' * RT;

    for kTrial = 1:length(trial_onsets_sec)
        t1 = trial_onsets_sec(kTrial);
        t2 = t1 + beta_scrubbing_options.time_window;

        idx = find(scan_times >= t1 & scan_times <= t2);

        if isempty(idx)
            continue
        end

        nFlagged = sum(FD_ts(idx) > beta_scrubbing_options.FD_thr);

        if nFlagged >= beta_scrubbing_options.min_flagged_TRs
            flagged_beta(kTrial) = 1;
        end
    end
end


           