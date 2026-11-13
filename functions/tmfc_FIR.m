function [sub_check] = tmfc_FIR(tmfc,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Estimates FIR GLM and saves residual time-series images in Float32 format
% instead of Float64 to save disk space and reduce computation time.
%
% FIR task regression is used to remove co-activations from BOLD time series.
% Co-activations are simultaneous (de)activations without communication
% between brain regions. 
%
% This function uses SPM.mat file (which contains the specification of the
% 1st-level GLM) to specify and estimate 1st-level GLM with FIR basis
% functions.
% 
% FIR model regresses out: (1) co-activations with arbitrary hemodynamic
% response shapes and (2) confounds specified in the original SPM.mat file
% (e.g., motion, physiological noise, etc).
%
% Residual time series (Res_*.nii images stored in FIR_regression folder)
% can be further used for FC analysis to control for spurious inflation of
% FC estimates due to co-activations. TMFC toolbox uses residual images in
% two cases: (1) to calculate background connectivity (BGFC), (2) to
% calculate LSS GLMs after FIR regression and use them for BSC after FIR.
%
% Note: Parametric or time modulators present in the original GLMs will be
% removed from the FIR GLMs.
%
% FORMAT [sub_check] = tmfc_FIR(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path     - Paths to individual SPM.mat files
%   tmfc.subjects.name     - Subject names within the TMFC project
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^31 = 2GB (how much RAM can be used at
%                            the same time during GLM estimation)
%   tmfc.defaults.resmem   - true or false (store temporary files during
%                            GLM estimation in RAM or on disk)
%   tmfc.FIR.window        - FIR window length (in seconds)
%   tmfc.FIR.bins          - Number of FIR time bins
%
% FORMAT [sub_check] = tmfc_FIR(tmfc,start_sub)
% Run the function starting from a specific subject in the path list.
%
%   tmfc           - As above
%   start_sub      - Subject number in the list to start computations from
%
% =========================================================================
% Copyright (C) 2025 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru
    

if nargin == 1
    start_sub = 1;
end

% Check subject names
if ~isfield(tmfc.subjects,'name')
    for iSub = 1:length(tmfc.subjects)
        tmfc.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
    end
end

% Update main TMFC GUI 
try              
    main_GUI = guidata(findobj('Tag','TMFC_GUI'));                           
    set(main_GUI.TMFC_GUI_S8,'String', 'Updating...','ForegroundColor',[0.772, 0.353, 0.067]);       
end

spm('defaults','fmri');
spm_jobman('initcfg');
spm_get_defaults('cmdline',true);
spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
spm_get_defaults('stats.fmri.ufp',1);

nSub = length(tmfc.subjects);
sub_check = zeros(1,nSub);
if start_sub > 1
    sub_check(1:start_sub) = 1;
end

for iSub = start_sub:nSub
    
    SPM = load(tmfc.subjects(iSub).path).SPM;

    % Check if SPM.mat has concatenated sessions 
    % (if spm_fmri_concatenate.m script was used)
    if size(SPM.nscan,2) == size(SPM.Sess,2)
        SPM_concat(iSub) = 0;
    else
        SPM_concat(iSub) = 1;
    end
    concat(iSub).scans = SPM.nscan;

    if isdir(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name))
        rmdir(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name),'s');
        pause(0.1);
    end
    
    mkdir(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name));
    matlabbatch{1}.spm.stats.fmri_spec.dir = {fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name)};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = SPM.xBF.UNITS;
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = SPM.xY.RT;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = SPM.xBF.T;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = SPM.xBF.T0;
    
    for jSess = 1:length(SPM.Sess)
        
        % Functional images
        if SPM_concat(iSub) == 0
            for kImage = 1:SPM.nscan(jSess)
                matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).scans{kImage,1} = [SPM.xY.VY(SPM.Sess(jSess).row(kImage)).fname ',' ...
                                                                                  num2str(SPM.xY.VY(SPM.Sess(jSess).row(kImage)).n(1))];
            end
        else
            for kImage = 1:size(SPM.xY.VY,1)
                matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).scans{kImage,1} = [SPM.xY.VY(SPM.Sess(jSess).row(kImage)).fname ',' ...
                                                                                  num2str(SPM.xY.VY(SPM.Sess(jSess).row(kImage)).n(1))];
            end
        end
        
        % Conditions (skip conditions that would generate all-zero FIR regressors)
        kCond2 = 0;
        RT   = SPM.xY.RT;
        tEnd = (SPM.nscan(jSess)-1) * RT;
        tMax = tEnd - tmfc.FIR.window;

        for kCond = 1:length(SPM.Sess(jSess).U)

            ons = SPM.Sess(jSess).U(kCond).ons;

            % Convert to seconds for filtering
            if strcmpi(SPM.xBF.UNITS,'scans')
                ons_sec = ons * RT;
            else
                ons_sec = ons;
            end

            % Keep only onsets that allow the full FIR window inside the session
            keep = ons_sec >= 0 & ons_sec <= tMax;
            if ~any(keep)
                continue
            end

            kCond2 = kCond2 + 1;

            % Keep original units in the batch (scans or seconds), but filtered
            matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).cond(kCond2).name = SPM.Sess(jSess).U(kCond).name{1};
            matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).cond(kCond2).onset = ons(keep);
            matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).cond(kCond2).duration = 0;
            matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).cond(kCond2).tmod = 0;
            matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).cond(kCond2).pmod = struct('name', {}, 'param', {}, 'poly', {});
            matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).cond(kCond2).orth = 1;
        end

        clear kCond2 RT tEnd tMax ons ons_sec keep
        
        % Confounds       
        for kConf = 1:length(SPM.Sess(jSess).C.name)
            matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).regress(kConf).name = SPM.Sess(jSess).C.name{1,kConf};
            matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).regress(kConf).val = SPM.Sess(jSess).C.C(:,kConf);
        end
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).multi = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).multi_reg = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess(jSess).hpf = SPM.xX.K(jSess).HParam;
    end

    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.fir.length = tmfc.FIR.window;
    matlabbatch{1}.spm.stats.fmri_spec.bases.fir.order = tmfc.FIR.bins;
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = SPM.xGX.iGXcalc;
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = SPM.xM.gMT;

    try
        matlabbatch{1}.spm.stats.fmri_spec.mask = {SPM.xM.VM.fname};
    catch
        matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    end
    
    if strcmp(SPM.xVi.form,'i.i.d') || strcmp(SPM.xVi.form,'none')
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'None';
    elseif strcmp(SPM.xVi.form,'fast') || strcmp(SPM.xVi.form,'FAST')
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'FAST';
    else
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    end

    if strcmp(SPM.xVi.form,'wls')
        rWLS(iSub) = 1;
    else
        rWLS(iSub) = 0;
    end

    matlabbatch_2{1}.spm.stats.fmri_est.spmmat(1) = {fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'SPM.mat')};
    matlabbatch_2{1}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch_2{1}.spm.stats.fmri_est.method.Classical = 1;
    
    batch{iSub} = matlabbatch;
    batch_2{iSub} = matlabbatch_2;

    clear matlabbatch matlabbatch_2 SPM; 
end

% Sequential or parallel computing
switch tmfc.defaults.parallel
    % ----------------------- Sequential Computing ------------------------
    case 0

        % Initialize waitbar
        w = waitbar(0,'Please wait...','Name','FIR task regression','Tag', 'tmfc_waitbar');
        start_time = tic;
        count_sub = 1;
        cleanupObj = onCleanup(@unfreeze_after_ctrl_c);
        
        % Sequential computing
        for iSub = start_sub:nSub              
            spm_jobman('run', batch{iSub});
            % Concatenated sessions
            if SPM_concat(iSub) == 1
                spm_fmri_concatenate(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'SPM.mat'),concat(iSub).scans);
            end
            % Check for rWLS
            if rWLS(iSub) == 0
                spm_jobman('run', batch_2{iSub});
            else
                tmfc_rwls_FIR(tmfc,iSub);
            end
            tmfc_write_residuals(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'SPM.mat'),NaN);
            tmfc_parsave(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'GLM_batch.mat'),batch{iSub});
            sub_check(iSub) = 1;

            % Update TMFC GUI window
            try                                
                set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(iSub), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]); 
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
        
        % Close waitbar
        try                                                                
            delete(w);
        end
    
    % ------------------------ Parallel Computing -------------------------
    case 1
        try % Waitbar for MATLAB R2017a and higher
            D = parallel.pool.DataQueue;            % Creation of parallel pool 
            w = waitbar(0,'Please wait...','Name','FIR task regression','Tag','tmfc_waitbar');
            afterEach(D, @tmfc_parfor_waitbar);     % Command to update waitbar
            tmfc_parfor_waitbar(w,nSub,start_sub);     
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

        % Parallel Loop
        try
            if isempty(gcp('nocreate')), parpool; end
            figure(findobj('Tag','TMFC_GUI'));
        end

        parfor iSub = start_sub:nSub
            spm('defaults','fmri');
            spm_jobman('initcfg');
            spm_get_defaults('cmdline',true);
            spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
            spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
            spm_get_defaults('stats.fmri.ufp',1);
            spm_jobman('run',batch{iSub});
            % Concatenated sessions
            if SPM_concat(iSub) == 1
                spm_fmri_concatenate(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'SPM.mat'),concat(iSub).scans);
            end
            % Check for rWLS
            if rWLS(iSub) == 0
                spm_jobman('run', batch_2{iSub});
            else
                SPM = load(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'SPM.mat')).SPM;
                SPM.xVi.form = 'wls';
                nScan = sum(SPM.nscan);
                for jScan = 1:nScan
                    SPM.xVi.Vi{jScan} = sparse(nScan,nScan);
                    SPM.xVi.Vi{jScan}(jScan,jScan) = 1;
                end
                original_dir = pwd;
                cd(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name));
                tmfc_spm_rwls_spm(SPM);
                cd(original_dir);
            end
            tmfc_write_residuals(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'SPM.mat'),NaN);
            tmfc_parsave(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'GLM_batch.mat'),batch{iSub});
            sub_check(iSub) = 1;

            % Update waitbar 
            try
                send(D,[]); 
            end 
        end

        % Update TMFC GUI window
        try                                
            set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]); 
        end

        % Close waitbar
        try                                                                
            delete(w);
        end       
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

% Save batches in parallel mode
function tmfc_parsave(fname,matlabbatch)
	save(fname, 'matlabbatch')
end

% Estimate rWLS FIR model
function tmfc_rwls_FIR(tmfc,iSub)
    SPM = load(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'SPM.mat')).SPM;
    SPM.xVi.form = 'wls';
    nScan = sum(SPM.nscan);
    for jScan = 1:nScan
        SPM.xVi.Vi{jScan} = sparse(nScan,nScan);
        SPM.xVi.Vi{jScan}(jScan,jScan) = 1;
    end
    original_dir = pwd;
    cd(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name));
    tmfc_spm_rwls_spm(SPM);
    cd(original_dir);
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
