function [sub_check] = tmfc_PPI(tmfc,ROI_set_number,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates psychophysiological interactions (PPIs).
% Whitening is applied during deconvolution, consistent with SPM PEB assumptions.
% Mean centering of the psychological regressor (PSY) can be enabled or disabled.
% In the subsequent gPPI model estimation, the raw (not whitened) BOLD signal
% is used for the PHYS regressor to avoid double whitening (see He et al., 2025).
%
%
% FORMAT [sub_check] = tmfc_PPI(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path            - Paths to individual SPM.mat files
%   tmfc.subjects.name            - Subject names within the TMFC project
%                                   ('Subject_XXXX' naming will be used by default)
%   tmfc.project_path             - Path where all results will be saved
%   tmfc.defaults.parallel        - 0 or 1 (sequential/parallel computing)
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.PPI_centering    - Apply mean centering of psychological
%                                   regressor (PSY) prior to deconvolution:
%                                   'with_mean_centering' (default)
%                                   or 'no_mean_centering'
%                                   (see Di, Reynolds & Biswal, 2017; Masharipov et al., 2024)
%
%   tmfc.ROI_set.type             - Type of the ROI set
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to the ROI images masked by group
%                                   mean binary mask 
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions        - List of conditions of interest
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.sess   - Session number (as specified in SPM.Sess)
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
%   ['[Sess_' num2str(iSess) ']_[Cond_' num2str(jCond) ']_[' ...
%   regexprep(char(SPM.Sess(iSess).U(jCond).name(kPmod)),' ','_') ']']
%
%   Derivative file name:
%
%   ['[Sess_' num2str(iSess) ']_[Cond_' num2str(jCond) ']_[' ...
%   regexprep(char(SPM.Sess(iSess).U(jCond).name(kPmod)),' ','_') ']_[' ...
%   bf_file{kBF} ']']
%
%   where bf_file{kBF} is:
%   'TimeDeriv' - time derivative
%   'DispDeriv' - dispersion derivative
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contain three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified (see tmfc_conditions_GUI, nested function:
% [cond_list] = generate_conditions(SPM_path)):
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).sess   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).number = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).bf     = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).name = 'Cond_A';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).file_name = '[Sess_1]_[Cond_1]_[Cond_A]';
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).sess   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).bf     = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).name = 'Cond_B';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).file_name = '[Sess_1]_[Cond_2]_[Cond_B]';
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).number = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).bf     = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).name = 'Cond_A';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).file_name = '[Sess_2]_[Cond_1]_[Cond_A]';
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).bf     = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).name = 'Cond_B';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).file_name = '[Sess_2]_[Cond_2]_[Cond_B]';
%
% If you also want to include time and dispersion derivatives for Cond_B
% in session 2, add:
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).bf     = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).name = 'Cond_B';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(5).file_name = '[Sess_2]_[Cond_2]_[Cond_B]_[TimeDeriv]';
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).pmod   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).bf     = 3;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).name = 'Cond_B';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(6).file_name = '[Sess_2]_[Cond_2]_[Cond_B]_[DispDeriv]';
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
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(7).file_name = '[Sess_2]_[Cond_2]_[Cond_BxModulator1^1]_[HRF]';
%
% Example: first parametric modulator for Cond_B, time derivative:
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).number = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).pmod   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).bf     = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).name = 'Cond_BxModulator1^1';
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(8).file_name = '[Sess_2]_[Cond_2]_[Cond_BxModulator1^1]_[TimeDeriv]';
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
% FORMAT [sub_check] = tmfc_PPI(tmfc,ROI_set_number,start_sub)
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

if ~isfield(tmfc.ROI_set(ROI_set_number),'PPI_centering')
    tmfc.ROI_set(ROI_set_number).PPI_centering = 'with_mean_centering';
elseif isempty(tmfc.ROI_set(ROI_set_number).PPI_centering)
    tmfc.ROI_set(ROI_set_number).PPI_centering = 'with_mean_centering';
end

% Check subject names
if ~isfield(tmfc.subjects,'name')
    for iSub = 1:length(tmfc.subjects)
        tmfc.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
    end
end

% Try to update GUI
try
    main_GUI = guidata(findobj('Tag','TMFC_GUI'));                           
    set(main_GUI.TMFC_GUI_S4,'String', 'Updating...','ForegroundColor',[0.772, 0.353, 0.067]);       
end

% -------------------------------------------------------------------------
% Basic setup
% -------------------------------------------------------------------------
nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(ROI_set_number).ROIs);

cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;
nCond = length(cond_list);

sess = []; sess_num = []; 
for iCond = 1:nCond
    sess(iCond) = cond_list(iCond).sess;
end
sess_num = unique(sess);
maxSess  = max(sess_num);

conds_by_sess = cell(1, maxSess);
for jCond = 1:nCond
    s = cond_list(jCond).sess;
    conds_by_sess{s}(end+1) = jCond;
end

sub_check = zeros(1,nSub);
if start_sub > 1
    sub_check(1:start_sub) = 1;
end

% Initialize SPM
spm('defaults','fmri');

cleanupObj = onCleanup(@unfreeze_after_ctrl_c);

% -------------------------------------------------------------------------
% NOTE ABOUT PARFOR (INTENTIONALLY DISABLED BY DEFAULT)
% -------------------------------------------------------------------------
% spm_PEB (used inside tmfc_PEB_PPI) involves inversion/solves of large
% matrices and is already implicitly multithreaded via high-performance
% linear algebra libraries (e.g., BLAS/LAPACK). In many practical cases,
% using parfor here can be slower due to worker overhead and CPU
% oversubscription. If you want to benchmark parfor speed on your machine,
% you can set the flag below to false.

force_disable_parfor = true;   % <-- set to false to test parfor on your PC

% -------------------------------------------------------------------------
% Prepare CACHE
% -------------------------------------------------------------------------
CACHE = struct();
CACHE.project_path = tmfc.project_path;

CACHE.ROI_set_number = ROI_set_number;
CACHE.ROIset         = tmfc.ROI_set(ROI_set_number);

CACHE.conditions.list       = cond_list;
CACHE.conditions.by_session = conds_by_sess;
CACHE.conditions.nCond      = nCond;

CACHE.sessions.list = sess_num;
CACHE.sessions.max  = maxSess;

CACHE.subjects.sublist = tmfc.subjects;
CACHE.subjects.nSub = nSub; 

% -------------------------------------------------------------------------
% Subject loop 
% -------------------------------------------------------------------------

% Sequential computations
% -------------------------------------------------------------------------
if tmfc.defaults.parallel == 0 || force_disable_parfor

    % If user requested parallel mode, notify that parfor is disabled here
    noteH = [];
    if tmfc.defaults.parallel == 1 && force_disable_parfor
        try
            noteH = helpdlg({ ...
                'Parallel mode requested, but parfor is disabled for PPI calculation.', ...
                '', ...
                'spm_PEB is already implicitly multithreaded (BLAS/LAPACK), so parfor is often slower here.', ...
                '', ...
                'Set "force_disable_parfor = false" inside tmfc_PPI if you want to test parfor speed.' ...
                }, 'TMFC note');
        catch
            noteH = [];
        end
    end

    % Initialize waitbar
    w = waitbar(0,'Please wait...','Name','PPI regressors calculation','Tag','tmfc_waitbar');
    start_time = tic;
    count_sub = 1;

    for iSub = start_sub:nSub
        tmfc_PEB_PPI(CACHE,iSub);
        sub_check(iSub) = 1;
        % Update main TMFC GUI
        try
            set(main_GUI.TMFC_GUI_S4,'String', strcat(num2str(iSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);
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
    
    % Close note
    try
        delete(noteH);
    end

% Parallel computations
% -------------------------------------------------------------------------
else
    try % Waitbar for MATLAB R2017a and higher
        D = parallel.pool.DataQueue;            % Creation of parallel pool
        w = waitbar(0,'Please wait...','Name','PPI regressors calculation','Tag','tmfc_waitbar');
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

    % Parallel Loop
    try
        if isempty(gcp('nocreate')), parpool; end
        figure(findobj('Tag','TMFC_GUI'));
    end

    CACHEc = parallel.pool.Constant(CACHE);
    parfor iSub = start_sub:nSub
        tmfc_PEB_PPI(CACHEc.Value, iSub);
        sub_check(iSub) = 1;

        % Update waitbar
        try
            send(D,[]);
        end
    end

    % Update TMFC GUI window
    try                                
        set(main_GUI.TMFC_GUI_S4,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]); 
    end

    % Close waitbar
    try                                                                
        delete(w);
    end
end   

% -------------------------------------------------------------------------
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

%==========================================================================

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




