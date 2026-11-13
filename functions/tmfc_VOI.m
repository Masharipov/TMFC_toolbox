function [sub_check] = tmfc_VOI(tmfc,ROI_set_number,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Extracts contrast-adjusted, whitened and filtered VOI time series for
% PPI calculation, and contrast-adjusted, unfiltered and unwhitened VOI
% time series for the PHYS regressor.
%
% FORMAT [sub_check] = tmfc_VOI(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path            - Paths to individual SPM.mat files
%   tmfc.subjects.name            - Subject names within the TMFC project
%   tmfc.project_path             - Path where all results will be saved
%   tmfc.defaults.parallel        - 0 or 1 (sequential/parallel computing)
%   tmfc.session_mode             - 'strict' or 'repeated'
%                                   'strict' - use the selected runs/conditions
%                                   'repeated' - process all runs for each subject
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.type             - Type of the ROI set
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to ROI images masked by
%                                   individual first-level masks
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions        - List of conditions of interest
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.sess   - Run number (SPM session, as specified in SPM.Sess)
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.number - Condition number (as specified in SPM.Sess.U)
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.pmod   - Parametric/Time modulator number (see SPM.Sess.U.P)
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.bf     - Basis function:
%                                                         1 = canonical HRF
%                                                         2 = time derivative
%                                                         3 = dispersion derivative
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.name   - Condition name (as specified in SPM.Sess.U.name(kPmod))
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.file_name - Condition-specific file names:
%
%   Canonical HRF file name:
%
%   ['[Run_' num2str(iSess) ']_[Cond_' num2str(jCond) ']_[' ...
%   regexprep(char(SPM.Sess(iSess).U(jCond).name(kPmod)),' ','_') ']']
%
%   Derivative file name:
%
%   ['[Run_' num2str(iSess) ']_[Cond_' num2str(jCond) ']_[' ...
%   regexprep(char(SPM.Sess(iSess).U(jCond).name(kPmod)),' ','_') ']_[' ...
%   bf_file{kBF} ']']
%
%   where bf_file{kBF} is:
%   'TimeDeriv' - time derivative
%   'DispDeriv' - dispersion derivative
%
% Run number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two runs (SPM sessions). Both runs 
% contain three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified (see tmfc_conditions_GUI and tmfc_get_conditions):
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).sess   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).number = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).bf     = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).name = 'Cond_A';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).file_name = '[Run_1]_[Cond_1]_[Cond_A]';
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).sess   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).bf     = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).name = 'Cond_B';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).file_name = '[Run_1]_[Cond_2]_[Cond_B]';
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).number = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).bf     = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).name = 'Cond_A';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).file_name = '[Run_2]_[Cond_1]_[Cond_A]';
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).bf     = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).name = 'Cond_B';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).file_name = '[Run_2]_[Cond_2]_[Cond_B]';
%
% If you also want to include time and dispersion derivatives for Cond_B
% in run 2, add:
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).bf     = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).name = 'Cond_B';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).file_name = '[Run_2]_[Cond_2]_[Cond_B]_[TimeDeriv]';
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).bf     = 3;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).name = 'Cond_B';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).file_name = '[Run_2]_[Cond_2]_[Cond_B]_[DispDeriv]';
%
% If GLMs contain parametric modulators, pmod selects the main condition or
% the parametric modulator, and bf selects the basis function:
%
%   pmod = 1  main condition
%   pmod = 2  first parametric modulator
%   pmod = 3  second parametric modulator
%
% Example: first parametric modulator for Cond_B, canonical HRF:
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(7).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(7).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(7).pmod   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(7).bf     = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(7).name = 'Cond_BxModulator1^1';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(7).file_name = '[Run_2]_[Cond_2]_[Cond_BxModulator1^1]_[HRF]';
%
% Example: first parametric modulator for Cond_B, time derivative:
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).pmod   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).bf     = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).name = 'Cond_BxModulator1^1';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).file_name = '[Run_2]_[Cond_2]_[Cond_BxModulator1^1]_[TimeDeriv]';
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
% FORMAT [sub_check] = tmfc_VOI(tmfc,ROI_set_number,start_sub)
% Run the function starting from a specific subject in the path list for
% the selected ROI set.
%
%   tmfc           - As above
%   ROI_set_number - Number of the ROI set in the tmfc structure
%   start_sub      - Subject number in the list to start computations from
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin == 1
   ROI_set_number = 1;
   start_sub = 1;
elseif nargin == 2
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

try
    main_GUI = guidata(findobj('Tag','TMFC_GUI'));                           
    set(main_GUI.TMFC_GUI_S3,'String', 'Updating...','ForegroundColor',[0.772, 0.353, 0.067]);       
end

nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(ROI_set_number).ROIs);
cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;
nCond = length(cond_list);

sub_check = zeros(1,nSub);
if start_sub > 1
    sub_check(1:start_sub) = 1;
end

% Initialize SPM
spm('defaults','fmri');
spm_jobman('initcfg');
spm_get_defaults('cmdline',true);

% Initialize parfor
useParROI = false;
useParSub = false;
hasPCT = (exist('parfor','builtin')==5) && license('test','Distrib_Computing_Toolbox');
if tmfc.defaults.parallel==1 && hasPCT
    p = gcp('nocreate');
    if isempty(p)
        parpool;
        p = gcp('nocreate');
    end
    nW = p.NumWorkers;
    nSubRun = nSub - start_sub + 1;

    % Single ROI, many subjects - parallelize over subjects.
    % Many ROIs - parallelize over ROIs
    if (nSubRun >= nW) && (nROI < nW)
        useParSub = true;
    else
        useParROI  = (nROI >= nW) && (nROI >= 4);
    end
end

try, figure(findobj('Tag','TMFC_GUI')); end

% -------------------------------------------------------------------------
% Subject loop
% -------------------------------------------------------------------------
if ~useParSub

    % Initialize waitbar
    w = waitbar(0,'Please wait...','Name','VOI time-series extraction','Tag','tmfc_waitbar');
    start_time = tic;
    count_sub = 1;
    cleanupObj = onCleanup(@unfreeze_after_ctrl_c);

    % ===================== Subjects: sequential ==========================
    for iSub = start_sub:nSub

        % Load SPM
        SPM = load(tmfc.subjects(iSub).path).SPM;

        if strcmp(session_mode,'repeated')
            sess_num = 1:length(SPM.Sess);
        else
            sess_num = unique([cond_list.sess]);
        end

        % Calculate F-contrast for all conditions of interest
        cond_col = tmfc_get_F_contrast_columns(SPM,cond_list,session_mode);

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

        % Estimate contrasts only if missing
        if isempty(idx)
            matlabbatch = [];
            matlabbatch{1}.spm.stats.con.spmmat = {tmfc.subjects(iSub).path};
            matlabbatch{1}.spm.stats.con.consess{1}.fcon.name = 'F_conditions_of_interest';
            matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights = weights;
            matlabbatch{1}.spm.stats.con.consess{1}.fcon.sessrep = 'none';
            matlabbatch{1}.spm.stats.con.delete = 0;
            spm_jobman('run',matlabbatch);
            idx = nCon + 1;
            % Reload SPM.mat to update SPM.xCon
            SPM = load(tmfc.subjects(iSub).path).SPM;
        end

        % Remove existing VOI folder for this subject
        outPath = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'VOIs',tmfc.subjects(iSub).name);
        if isdir(outPath)
            rmdir(outPath,'s'); pause(0.1);
        end

        % Create a clean VOI output folder for the current subject
        if ~isdir(outPath)
            mkdir(outPath);
        end

        % Build reduced SPM struct for tmfc_regions
        SPMr = struct();
        SPMr.xY  = struct('VY', SPM.xY.VY);
        SPMr.xX  = struct();
        SPMr.xX.X    = SPM.xX.X;
        SPMr.xX.K    = SPM.xX.K;
        SPMr.xX.W    = SPM.xX.W;
        SPMr.xX.xKXs = SPM.xX.xKXs;
        SPMr.swd   = SPM.swd;
        SPMr.Vbeta = SPM.Vbeta;
        SPMr.Sess = struct('row', []);
        for ss = 1:numel(SPM.Sess)
            SPMr.Sess(ss).row = SPM.Sess(ss).row;
        end
        SPMr.xCon = SPM.xCon(idx);

        % ====================== ROIs: sequential =========================
        if ~useParROI
            for kROI = 1:nROI
                roiName = tmfc.ROI_set(ROI_set_number).ROIs(kROI).name;

                fprintf('[VOI] Sub %02d/%02d | ROI %03d/%03d (%s)\n', ...
                    iSub, nSub, kROI, nROI, roiName);

                path_masked = tmfc.ROI_set(ROI_set_number).ROIs(kROI).path_masked;

                % Backward compatibility with old ROI sets
                if ischar(path_masked)
                    maskPath = path_masked;
                else
                    maskPath = path_masked(iSub).subjects;
                end

                tmfc_regions(SPMr, roiName, maskPath, outPath, 1, sess_num, 0.1);
            end
        % ======================= ROIs: parallel ==========================            
        else 
            SPMrc = parallel.pool.Constant(SPMr);
            parfor kROI = 1:nROI
                roiName = tmfc.ROI_set(ROI_set_number).ROIs(kROI).name;
    
                fprintf('[VOI] Sub %02d/%02d | ROI %03d/%03d (%s)\n', ...
                    iSub, nSub, kROI, nROI, roiName);

                path_masked = tmfc.ROI_set(ROI_set_number).ROIs(kROI).path_masked;

                % Backward compatibility with old ROI sets
                if ischar(path_masked)
                    maskPath = path_masked;
                else
                    maskPath = path_masked(iSub).subjects;
                end
    
                tmfc_regions(SPMrc.Value, roiName, maskPath, outPath, 1, sess_num, 0.1);
            end
        end

        sub_check(iSub) = 1;

        % Update main TMFC GUI
        try
            main_GUI = guidata(findobj('Tag','TMFC_GUI'));
            set(main_GUI.TMFC_GUI_S3,'String', strcat(num2str(iSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);
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

        clear SPM SPMr SPMrc
    end
    
    % Close waitbar
    try
        delete(w);
    end
else
    % ====================== Subjects: parallel ===========================
    try % Waitbar for MATLAB R2017a and higher
        D = parallel.pool.DataQueue;            
        w = waitbar(0,'Please wait...','Name','VOI time-series extraction','Tag','tmfc_waitbar');
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

    parfor iSub = start_sub:nSub
        ok = tmfc_VOI_one_sub(tmfc,ROI_set_number,iSub,cond_list,session_mode,nSub,nROI);
        sub_check(iSub) = ok;
        try
            send(D,[]);
        end
    end

    % Update TMFC GUI window
    try
        set(main_GUI.TMFC_GUI_S3,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);
    end

    % Close waitbar
    try
        delete(w);
    end
end 

%==========================================================================
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
function ok = tmfc_VOI_one_sub(tmfc,ROI_set_number,iSub,cond_list,session_mode,nSub,nROI)
    ok = 0;

    % Load SPM
    SPM = load(tmfc.subjects(iSub).path).SPM;

    if strcmp(session_mode,'repeated')
        sess_num = 1:length(SPM.Sess);
    else
        sess_num = unique([cond_list.sess]);
    end

    % Calculate F-contrast for all conditions of interest
    cond_col = tmfc_get_F_contrast_columns(SPM,cond_list,session_mode);

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

    % Estimate contrasts only if missing
    if isempty(idx)
        matlabbatch = [];
        matlabbatch{1}.spm.stats.con.spmmat = {tmfc.subjects(iSub).path};
        matlabbatch{1}.spm.stats.con.consess{1}.fcon.name = 'F_conditions_of_interest';
        matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights = weights;
        matlabbatch{1}.spm.stats.con.consess{1}.fcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.delete = 0;
        spm('defaults','fmri');
        spm_jobman('initcfg');
        spm_get_defaults('cmdline',true);
        spm_jobman('run',matlabbatch);
        idx = nCon + 1;
        % Reload SPM.mat to update SPM.xCon
        SPM = load(tmfc.subjects(iSub).path).SPM;
    end

    % Remove existing VOI folder for this subject 
    outPath = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'VOIs',tmfc.subjects(iSub).name);
    if isdir(outPath)
        rmdir(outPath,'s'); pause(0.1);
    end

    % Create a clean VOI output folder for the current subject
    if ~isdir(outPath)
        mkdir(outPath);
    end

    % Build reduced SPM struct for tmfc_regions
    SPMr = struct();
    SPMr.xY  = struct('VY', SPM.xY.VY);
    SPMr.xX  = struct();
    SPMr.xX.X    = SPM.xX.X;
    SPMr.xX.K    = SPM.xX.K;
    SPMr.xX.W    = SPM.xX.W;
    SPMr.xX.xKXs = SPM.xX.xKXs;
    SPMr.swd   = SPM.swd;
    SPMr.Vbeta = SPM.Vbeta;
    SPMr.Sess = struct('row', []);
    for ss = 1:numel(SPM.Sess)
        SPMr.Sess(ss).row = SPM.Sess(ss).row;
    end
    SPMr.xCon = SPM.xCon(idx);

    % ROI loop (only sequential)
    for kROI = 1:nROI
        roiName = tmfc.ROI_set(ROI_set_number).ROIs(kROI).name;

        fprintf('[VOI] Sub %02d/%02d | ROI %03d/%03d (%s)\n', ...
                iSub, nSub, kROI, nROI, roiName);

        path_masked = tmfc.ROI_set(ROI_set_number).ROIs(kROI).path_masked;

        % Backward compatibility with old ROI sets
        if ischar(path_masked)
            maskPath = path_masked;
        else
            maskPath = path_masked(iSub).subjects;
        end

        tmfc_regions(SPMr, roiName, maskPath, outPath, 1, sess_num, 0.1);
    end

    ok = 1;
end

% Specify F-contrast
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

