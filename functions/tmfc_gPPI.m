function [sub_check,contrasts] = tmfc_gPPI(tmfc,ROI_set_number,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Estimates gPPI GLMs. Saves individual connectivity matrices
% (ROI-to-ROI analysis) and connectivity images (seed-to-voxel analysis)
% for each condition of interest.
%
% Note: If the original GLMs contain parametric modulators, temporal
% derivatives, or dispersion derivatives, these will be included in the
% gPPI GLMs. PPI regressors are added only for explicitly selected
% condition/basis-function pairs.
%
% FORMAT [sub_check,contrasts] = tmfc_gPPI(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path     - Paths to individual SPM.mat files
%   tmfc.subjects.name     - Subject names within the TMFC project
%                           ('Subject_XXXX' naming will be used by default)
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^31 = 2GB (how much RAM can be used)
%   tmfc.defaults.resmem   - true or false (store temporary files in RAM)
%   tmfc.defaults.analysis - 1 (Seed-to-voxel and ROI-to-ROI analyses)
%                          - 2 (ROI-to-ROI analysis only)
%                          - 3 (Seed-to-voxel analysis only)
%
%   tmfc.ROI_set                  - List of selected ROIs
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
% FORMAT [sub_check,contrasts] = tmfc_gPPI(tmfc,ROI_set_number,start_sub)
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

nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(ROI_set_number).ROIs);
cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;
nCond = length(cond_list);
sess = []; sess_num = []; nSess = []; PPI_num = []; PPI_sess = [];
for cond_PPI = 1:nCond
    sess(cond_PPI) = cond_list(cond_PPI).sess;
end
sess_num = unique(sess);
nSess = length(sess_num);
for iSess = 1:nSess
    PPI_num = [PPI_num, 1:sum(sess == sess_num(iSess))];
    PPI_sess = [PPI_sess, iSess*ones(1,sum(sess == sess_num(iSess)))];
end

% Initialize waitbar 
w = waitbar(0,'Please wait...','Name','gPPI GLM estimation','Tag', 'tmfc_waitbar');
start_time = tic;
count_sub = 1;
cleanupObj = onCleanup(@unfreeze_after_ctrl_c);

if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI'))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','asymmetrical'));
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','symmetrical'));
    end
end

if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
    for iROI = 1:nROI
        if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(iROI).name))
            mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(iROI).name));
        end
    end
end

for iROI = 1:nROI
    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','GLM_batches',tmfc.ROI_set(ROI_set_number).ROIs(iROI).name))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','GLM_batches',tmfc.ROI_set(ROI_set_number).ROIs(iROI).name));
    end
end

spm('defaults','fmri');
spm_jobman('initcfg');

% Loop through subjects
for iSub = start_sub:nSub
    %=======================[ Specify gPPI GLM ]===========================
    SPM = load(tmfc.subjects(iSub).path).SPM;

    % Check if SPM.mat has concatenated sessions 
    % (if spm_fmri_concatenate.m script was used)
    if size(SPM.nscan,2) == size(SPM.Sess,2)
        SPM_concat(iSub) = 0;
    else
        SPM_concat(iSub) = 1;
    end
    concat(iSub).scans = SPM.nscan;

    % Loop through ROIs
    for jROI = 1:nROI
        if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name))
            rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name),'s');
            pause(0.1);
        end
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name));
        % Loop through conditions of interest
        for cond_PPI = 1:nCond
            PPI(cond_PPI) = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',tmfc.subjects(iSub).name, ...
                            ['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,' ','_') ']_' cond_list(cond_PPI).file_name '.mat']));
        end
        % gPPI GLM batch
        matlabbatch{1}.spm.stats.fmri_spec.dir = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name)};
        matlabbatch{1}.spm.stats.fmri_spec.timing.units = SPM.xBF.UNITS;
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = SPM.xY.RT;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = SPM.xBF.T;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = SPM.xBF.T0;
        % Loop through sessions
        for kSess = 1:nSess
            % Functional images
            if SPM_concat(iSub) == 0
                for image = 1:SPM.nscan(sess_num(kSess))
                    matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).scans{image,1} = [SPM.xY.VY(SPM.Sess(sess_num(kSess)).row(image)).fname ',' ...
                                                                                     num2str(SPM.xY.VY(SPM.Sess(sess_num(kSess)).row(image)).n(1))];
                end
            else
                for image = 1:size(SPM.xY.VY,1)
                    matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).scans{image,1} = [SPM.xY.VY(SPM.Sess(kSess).row(image)).fname ',' ...
                                                                                     num2str(SPM.xY.VY(SPM.Sess(kSess).row(image)).n(1))];
                end
            end
            
            % Conditions (including PSY regressors)
            for cond = 1:length(SPM.Sess(sess_num(kSess)).U)
                matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).cond(cond).name = SPM.Sess(sess_num(kSess)).U(cond).name{1};
                matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).cond(cond).onset = SPM.Sess(sess_num(kSess)).U(cond).ons;
                matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).cond(cond).duration = SPM.Sess(sess_num(kSess)).U(cond).dur;
                matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).cond(cond).tmod = 0;
                if length(SPM.Sess(sess_num(kSess)).U(cond).name)>1
                    for PM_number = 1:length(SPM.Sess(sess_num(kSess)).U(cond).P)
                        matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).cond(cond).pmod(PM_number).name = SPM.Sess(sess_num(kSess)).U(cond).P(PM_number).name;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).cond(cond).pmod(PM_number).param = SPM.Sess(sess_num(kSess)).U(cond).P(PM_number).P;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).cond(cond).pmod(PM_number).poly = SPM.Sess(sess_num(kSess)).U(cond).P(PM_number).h;
                    end
                else
                    matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).cond(cond).pmod = struct('name', {}, 'param', {}, 'poly', {});
                end
                matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).cond(cond).orth = SPM.Sess(sess_num(kSess)).U(cond).orth;
            end

            % Add PPI regressors          
            for cond_PPI = 1:nCond
                if cond_list(cond_PPI).sess == sess_num(kSess)
                    matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).regress(PPI_num(cond_PPI)).name = ['PPI_' PPI(cond_PPI).PPI.name];
                    matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).regress(PPI_num(cond_PPI)).val = PPI(cond_PPI).PPI.ppi;
                end
            end

            % Add PHYS regressors
            VOI = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'VOIs', ...
                  tmfc.subjects(iSub).name, ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(jROI).name '_' num2str(sess_num(kSess)) '.mat']);
            tmp = load(VOI);
            matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).regress(sum(sess==sess_num(kSess))+1).name = ['Seed_' tmfc.ROI_set(ROI_set_number).ROIs(jROI).name];
            if isfield(tmp,'Yraw')
                matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).regress(sum(sess==sess_num(kSess))+1).val = tmp.Yraw;  % Use raw (unwhitened) demeanted VOI time series
            else
                matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).regress(sum(sess==sess_num(kSess))+1).val = tmp.Y;     % Backward compatibility: old VOI files contain only Y
            end
            clear VOI tmp

            % Confounds       
            for conf = 1:length(SPM.Sess(sess_num(kSess)).C.name)
                matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).regress(conf+sum(sess == sess_num(kSess))+1).name = SPM.Sess(sess_num(kSess)).C.name{1,conf};
                matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).regress(conf+sum(sess == sess_num(kSess))+1).val = SPM.Sess(sess_num(kSess)).C.C(:,conf);
            end
            
            matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).multi = {''};
            matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).multi_reg = {''};
            matlabbatch{1}.spm.stats.fmri_spec.sess(kSess).hpf = SPM.xX.K(sess_num(kSess)).HParam;            
        end

        matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = tmfc_get_hrf_derivs(SPM);
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

        batch{jROI} = matlabbatch;
        clear matlabbatch PPI   
    end

    switch tmfc.defaults.parallel
        case 0  % Sequential
            for jROI = 1:nROI
                spm('defaults','fmri');
                spm_jobman('initcfg');
                spm_get_defaults('cmdline',true);
                spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                spm_get_defaults('stats.fmri.ufp',1);
                spm_jobman('run',batch{jROI});
                % Concatenated sessions
                if SPM_concat(iSub) == 1
                    spm_fmri_concatenate(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
                        tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,'SPM.mat'),concat(iSub).scans);
                end
    
                % Save GLM_batch.mat file
                tmfc_parsave_batch(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','GLM_batches',tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,...
                    [tmfc.subjects(iSub).name '_gPPI_GLM.mat']),batch{jROI});
            end
            
        case 1  % Parallel
            try
                if isempty(gcp('nocreate')), parpool; end
                figure(findobj('Tag','TMFC_GUI'));
            end

            parfor jROI = 1:nROI
                spm('defaults','fmri');
                spm_jobman('initcfg');
                spm_get_defaults('cmdline',true);
                spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                spm_get_defaults('stats.fmri.ufp',1);
                spm_jobman('run',batch{jROI});
                % Concatenated sessions
                if SPM_concat(iSub) == 1
                    spm_fmri_concatenate(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
                        tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,'SPM.mat'),concat(iSub).scans);
                end

                % Save GLM_batch.mat file
                tmfc_parsave_batch(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','GLM_batches',tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,...
                    [tmfc.subjects(iSub).name '_gPPI_GLM.mat']),batch{jROI});
            end
    end

    clear batch

    %=======================[ Estimate gPPI GLM ]==========================
    
    % Seed-to-voxel and ROI-to-ROI analyses
    if tmfc.defaults.analysis == 1

        % Seed-to-voxel
        for jROI = 1:nROI
            matlabbatch{1}.spm.stats.fmri_est.spmmat(1) = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,'SPM.mat')};
            matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
            matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
            batch{jROI} = matlabbatch;
            clear matlabbatch
        end

        SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(1).name,'SPM.mat')).SPM;

        switch tmfc.defaults.parallel
            case 0  % Sequential
                for jROI = 1:nROI
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    % Check for rWLS
                    if rWLS(iSub) == 0
                        spm_jobman('run',batch{jROI});
                    else
                        tmfc_rwls_gPPI(tmfc,ROI_set_number,iSub,jROI);
                    end
                  
                    % Save PPI beta images
                    for cond_PPI = 1:nCond
                        tmfc_save_gPPI_betas(tmfc,ROI_set_number,iSub,jROI,cond_PPI,PPI_num,PPI_sess,cond_list,SPM);
                    end
                end
                
            case 1  % Parallel
                parfor jROI = 1:nROI
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    % Check for rWLS
                    if rWLS(iSub) == 0
                        spm_jobman('run',batch{jROI});
                    else
                        tmfc_rwls_gPPI(tmfc,ROI_set_number,iSub,jROI);
                    end

                    % Save PPI beta images
                    for cond_PPI = 1:nCond
                        tmfc_save_gPPI_betas(tmfc,ROI_set_number,iSub,jROI,cond_PPI,PPI_num,PPI_sess,cond_list,SPM);
                    end
                end
        end

        % ROI-to-ROI
        Y = [];
        for kSess = 1:nSess
            for jROI = 1:nROI
                VOI = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'VOIs', ... 
                      tmfc.subjects(iSub).name,['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(jROI).name '_' num2str(sess_num(kSess)) '.mat']);
                KWY(:,jROI) = load(deblank(VOI(1,:))).Y; % Filtered and whitened data
                clear VOI
            end
            Y = [Y; KWY];
            clear KWY
        end

        beta = [];

        switch tmfc.defaults.parallel
            case 0  % Sequential
                for jROI = 1:nROI
                    SPM = [];
                    SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,'SPM.mat')).SPM;
                    beta(:,:,jROI) = SPM.xX.pKX*Y;                    
                end
            case 1  % Parallel
                parfor jROI = 1:nROI
                    SPM = [];
                    SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,'SPM.mat')).SPM;
                    beta(:,:,jROI) = SPM.xX.pKX*Y;                     
                end
        end
        
        % Save PPI beta matrices
        SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(1).name,'SPM.mat')).SPM;
        for cond_PPI = 1:nCond
            ppi_matrix = squeeze(beta(PPI_num(cond_PPI) - 1 + SPM.Sess(PPI_sess(cond_PPI)).col(1) + SPM.Sess(PPI_sess(cond_PPI)).Fc(end).i(end),:,:));
            ppi_matrix(1:size(ppi_matrix,1)+1:end) = nan;
            symm_ppi_matrix =(ppi_matrix + ppi_matrix')/2;
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','asymmetrical', ...
                [tmfc.subjects(iSub).name '_Contrast_' num2str(cond_PPI,'%04.f') '_' cond_list(cond_PPI).file_name '.mat']),'ppi_matrix');
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','symmetrical', ...
                [tmfc.subjects(iSub).name '_Contrast_' num2str(cond_PPI,'%04.f') '_' cond_list(cond_PPI).file_name '.mat']),'symm_ppi_matrix');
            clear ppi_matrix symm_ppi_matrix
        end
    end

    % ROI-to-ROI analysis only
    if tmfc.defaults.analysis == 2
        Y = [];
        for kSess = 1:nSess
            for jROI = 1:nROI
                VOI = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'VOIs', ... 
                      tmfc.subjects(iSub).name,['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(jROI).name '_' num2str(sess_num(kSess)) '.mat']);
                KWY(:,jROI) = load(deblank(VOI(1,:))).Y;
                clear VOI
            end
            Y = [Y; KWY];
            clear KWY
        end       
        
        beta = [];

        switch tmfc.defaults.parallel
            case 0  % Sequential
                for jROI = 1:nROI
                    SPM = []; xX = []; xVi = []; W = []; xKXs = []; pKX = [];
                    SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,'SPM.mat')).SPM;
                    xX = SPM.xX;
                    if isfield(SPM.xX,'W')
                        SPM.xX  = rmfield(SPM.xX,'W');
                    end
                    if isfield(SPM.xVi,'V')
                        SPM.xVi = rmfield(SPM.xVi,'V');
                    end
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    % Check for rWLS
                    if rWLS(iSub) == 0
                        xVi = spm_est_non_sphericity(SPM);
                    else
                        xVi = tmfc_spm_rwls_est_non_sphericity(SPM);
                    end
                    W           = spm_sqrtm(spm_inv(xVi.V));
                    W           = W.*(abs(W) > 1e-6);
                    xKXs        = spm_sp('Set',spm_filter(xX.K,W*xX.X));
                    xKXs.X      = full(xKXs.X);
                    pKX         = spm_sp('x-',xKXs);
                    beta(:,:,jROI)        = pKX*Y;
                end
            case 1  % Parallel
                parfor jROI = 1:nROI
                    SPM = []; xX = []; xVi = []; W = []; xKXs = []; pKX = [];
                    SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,'SPM.mat')).SPM;
                    xX = SPM.xX;
                    if isfield(SPM.xX,'W')
                        SPM.xX  = rmfield(SPM.xX,'W');
                    end
                    if isfield(SPM.xVi,'V')
                        SPM.xVi = rmfield(SPM.xVi,'V');
                    end
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    % Check for rWLS
                    if rWLS(iSub) == 0
                        xVi = spm_est_non_sphericity(SPM);
                    else
                        xVi = tmfc_spm_rwls_est_non_sphericity(SPM);
                    end
                    W           = spm_sqrtm(spm_inv(xVi.V));
                    W           = W.*(abs(W) > 1e-6);
                    xKXs        = spm_sp('Set',spm_filter(xX.K,W*xX.X));
                    xKXs.X      = full(xKXs.X);
                    pKX         = spm_sp('x-',xKXs);
                    beta(:,:,jROI)        = pKX*Y;                    
                end
        end

        % Save PPI beta matrices
        SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(1).name,'SPM.mat')).SPM;
        for cond_PPI = 1:nCond
            ppi_matrix = squeeze(beta(PPI_num(cond_PPI) - 1 + SPM.Sess(PPI_sess(cond_PPI)).col(1) + SPM.Sess(PPI_sess(cond_PPI)).Fc(end).i(end),:,:));
            ppi_matrix(1:size(ppi_matrix,1)+1:end) = nan;
            symm_ppi_matrix =(ppi_matrix + ppi_matrix')/2;
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','asymmetrical', ...
                [tmfc.subjects(iSub).name '_Contrast_' num2str(cond_PPI,'%04.f') '_' cond_list(cond_PPI).file_name '.mat']),'ppi_matrix');
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','symmetrical', ...
                [tmfc.subjects(iSub).name '_Contrast_' num2str(cond_PPI,'%04.f') '_' cond_list(cond_PPI).file_name '.mat']),'symm_ppi_matrix');
            clear ppi_matrix symm_ppi_matrix
        end
    end

    % Seed-to-voxel analysis only
    if tmfc.defaults.analysis == 3
        for jROI = 1:nROI
            matlabbatch{1}.spm.stats.fmri_est.spmmat(1) = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,'SPM.mat')};
            matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
            matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
            batch{jROI} = matlabbatch;
            clear matlabbatch
        end

        SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(1).name,'SPM.mat')).SPM;

        switch tmfc.defaults.parallel
            case 0  % Sequential
                for jROI = 1:nROI
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    % Check for rWLS
                    if rWLS(iSub) == 0
                        spm_jobman('run',batch{jROI});
                    else
                        tmfc_rwls_gPPI(tmfc,ROI_set_number,iSub,jROI);
                    end    

                    % Save PPI beta images
                    for cond_PPI = 1:nCond
                        tmfc_save_gPPI_betas(tmfc,ROI_set_number,iSub,jROI,cond_PPI,PPI_num,PPI_sess,cond_list,SPM);
                    end
                end
                
            case 1  % Parallel
                parfor jROI = 1:nROI
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    % Check for rWLS
                    if rWLS(iSub) == 0
                        spm_jobman('run',batch{jROI});
                    else
                        tmfc_rwls_gPPI(tmfc,ROI_set_number,iSub,jROI);
                    end

                    % Save PPI beta images
                    for cond_PPI = 1:nCond
                        tmfc_save_gPPI_betas(tmfc,ROI_set_number,iSub,jROI,cond_PPI,PPI_num,PPI_sess,cond_list,SPM);
                    end
                end
        end 
    end
    
    % Remove temporary gPPI directories
    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name),'s');

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

    clear SPM
end

% Default contrasts info
for cond_PPI = 1:nCond
    contrasts(cond_PPI).title = cond_list(cond_PPI).file_name;
    contrasts(cond_PPI).weights = zeros(1,nCond);
    contrasts(cond_PPI).weights(1,cond_PPI) = 1;
end

% Close waitbar
try
    delete(w);
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

% Get HRF derivative settings from original SPM
function derivs = tmfc_get_hrf_derivs(SPM)
    switch lower(strtrim(SPM.xBF.name))
        case 'hrf'
            derivs = [0 0];
        case 'hrf (with time derivative)'
            derivs = [1 0];
        case 'hrf (with time and dispersion derivatives)'
            derivs = [1 1];
        otherwise
            error('TMFC supports only canonical HRF, time derivative, and dispersion derivative.');
    end
end

% Save batches in parallel mode
function tmfc_parsave_batch(fname,matlabbatch)
    save(fname, 'matlabbatch')
end

% Estimate rWLS gPPI model
function tmfc_rwls_gPPI(tmfc,ROI_set_number,iSub,jROI)
    SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name,'SPM.mat')).SPM;
    SPM.xVi.form = 'wls';
    nScan = sum(SPM.nscan);
    for jScan = 1:nScan
        SPM.xVi.Vi{jScan} = sparse(nScan,nScan);
        SPM.xVi.Vi{jScan}(jScan,jScan) = 1;
    end
    original_dir = pwd;
    cd(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',tmfc.subjects(iSub).name,tmfc.ROI_set(ROI_set_number).ROIs(jROI).name));
    tmfc_spm_rwls_spm(SPM);
    cd(original_dir);
end

% Save gPPI beta files
function tmfc_save_gPPI_betas(tmfc,ROI_set_number,iSub,jROI,cond_PPI,PPI_num,PPI_sess,cond_list,SPM)
    gPPI_path = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI');
    ROI_name = tmfc.ROI_set(ROI_set_number).ROIs(jROI).name;
    beta_number = PPI_num(cond_PPI) - 1 + SPM.Sess(PPI_sess(cond_PPI)).col(1) + SPM.Sess(PPI_sess(cond_PPI)).Fc(end).i(end);
    orig_path = fullfile(gPPI_path,tmfc.subjects(iSub).name,ROI_name,['beta_' num2str(beta_number,'%04.f') '.nii']);
    new_path =  fullfile(gPPI_path,'Seed_to_voxel',ROI_name,[tmfc.subjects(iSub).name '_Contrast_' num2str(cond_PPI,'%04.f') '_' cond_list(cond_PPI).file_name '.nii']);
    copyfile(orig_path,new_path);
end
