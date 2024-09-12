function [sub_check,contrasts] = tmfc_gPPI_FIR(tmfc,ROI_set_number,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Estimates gPPI-FIR GLMs. Saves individual connectivity matrices
% (ROI-to-ROI analysis) and connectivity images (seed-to-voxel analysis)
% for each condition of interest.
%
% The difference between classic gPPI GLM and gPPI-FIR GLM is that the
% latter uses finite impulse response (FIR) functions (instead of canonical
% HRF function) to model activations for conditions of interst and
% conditions of no interest. The FIR model allows to model activations
% with any possible hemodynamic response shape.
%
% FORMAT [sub_check,contrasts] = tmfc_gPPI_FIR(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path     - Paths to individual SPM.mat files
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^31 = 2GB (how much RAM can be used)
%   tmfc.defaults.resmem   - true or false (store temporaty files in RAM)
%   tmfc.defaults.analysis - 1 (Seed-to-voxel and ROI-to-ROI analyses)
%                          - 2 (ROI-to-ROI analysis only)
%                          - 3 (Seed-to-voxel analysis only)
%
%   tmfc.ROI_set(ROI_set_number).gPPI_FIR.window - FIR window length (in seconds)
%   tmfc.ROI_set(ROI_set_number).gPPI_FIR.bins   - Number of FIR time bins
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to the ROI images masked by group
%                                   mean binary mask 
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions        - List of conditions of interest
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.sess   - Session number (as specified in SPM.Sess)
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.number - Condition number (as specified in SPM.Sess.U)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified:
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(1).sess   = 1;   
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(1).number = 1; - "Cond A", 1st session
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(2).sess   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(2).number = 2; - "Cond B", 1st session
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(3).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(3).number = 1; - "Cond A", 2nd session
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(4).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(4).number = 2; - "Cond B", 2nd session
%
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path_masked = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path_masked = 'C:\ROI_set\two_ROIs\ROI_2.nii';
%
% FORMAT [sub_check,contrasts] = tmfc_gPPI_FIR(tmfc,ROI_set_number,start_sub)
% Run the function starting from a specific subject in the path list for
% the selected ROI set.
%
%   tmfc                   - As above
%   ROI_set_number         - Number of the ROI set in the tmfc structure
%   start_sub              - Subject number on the path list to start with
%
% =========================================================================
%
% Copyright (C) 2024 Ruslan Masharipov
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.
%
% Contact email: masharipov@ihb.spb.ru


if nargin == 1
   ROI_set_number = 1;
   start_sub = 1;
elseif nargin == 2
   start_sub = 1;
end

N = length(tmfc.subjects);
R = length(tmfc.ROI_set(ROI_set_number).ROIs);
cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;
SPM = load(tmfc.subjects(1).path);
sess = []; sess_num = []; N_sess = []; PPI_num = []; PPI_sess = [];
for i = 1:length(cond_list)
    sess(i) = cond_list(i).sess;
    condition(i).name = ['[Sess_' num2str(cond_list(i).sess) ']_[Cond_' num2str(cond_list(i).number) ']_[' ...
                regexprep(char(SPM.SPM.Sess(cond_list(i).sess).U(cond_list(i).number).name),' ','_') ']'];
end
sess_num = unique(sess);
N_sess = length(sess_num);
for i = 1:N_sess
    PPI_num = [PPI_num, 1:sum(sess == sess_num(i))];
    PPI_sess = [PPI_sess, i*ones(1,sum(sess == sess_num(i)))];
end

% Initialize waitbar for sequential or parallel computations
switch tmfc.defaults.parallel
    case 0                                      % Sequential
        w = waitbar(0,'Please wait...','Name','gPPI-FIR GLM estimation','Tag', 'tmfc_waitbar');
        cleanupObj = onCleanup(@cleanMeUp);
    case 1                                      % Parallel
        try % Waitbar for MATLAB R2017a and higher
            D = parallel.pool.DataQueue;            % Creation of parallel pool 
            w = waitbar(0,'Please wait...','Name','gPPI-FIR GLM estimation','Tag','tmfc_waitbar');
            afterEach(D, @tmfc_parfor_waitbar);     % Command to update waitbar
            tmfc_parfor_waitbar(w,N);     
        catch % No waitbar for MATLAB R2016b and earlie
            opts = struct('WindowStyle','non-modal','Interpreter','tex');
            w = warndlg({'\fontsize{12}Sorry, waitbar progress update is not available for parallel computations in MATLAB R2016b and earlier.',[],...
                'Please wait until all computations are completed.',[],...
                'If you want to interrupt computations:',...
                '   1) Do not close this window;',...
                '   2) Select MATLAB main window;',...
                '   3) Press Ctrl+C.'},'Please wait...',opts);
        end
        
        cleanupObj = onCleanup(@cleanMeUp);
        
        try % Bring TMFC main window to the front 
            figure(findobj('Tag','TMFC_GUI'));
        end
end

if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI'))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','asymmetrical'));
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','symmetrical'));
    end
end

if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
    for i = 1:R
        if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(i).name))
            mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(i).name));
        end
    end
end

for i = 1:R
    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','GLM_batches',tmfc.ROI_set(ROI_set_number).ROIs(i).name))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','GLM_batches',tmfc.ROI_set(ROI_set_number).ROIs(i).name));
    end
end

spm('defaults','fmri');
spm_jobman('initcfg');

% Loop through subjects
for i = start_sub:N
    tic
    %=======================[ Specify gPPI GLM ]===========================
    SPM = load(tmfc.subjects(i).path);
    % Loop through ROIs
    for j = 1:R
        if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name))
            rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name),'s');
        end
        % Loop through conditions of interest
        for condi = 1:length(cond_list)
            PPI(condi) = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(i,'%04.f')], ...
                            ['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(j).name,' ','_') ']_' condition(condi).name '.mat']));
        end
        % gPPI GLM batch
        matlabbatch{1}.spm.stats.fmri_spec.dir = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name)};
        matlabbatch{1}.spm.stats.fmri_spec.timing.units = SPM.SPM.xBF.UNITS;
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = SPM.SPM.xY.RT;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = SPM.SPM.xBF.T;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = SPM.SPM.xBF.T0;
        % Loop throuph sessions
        for sessi = 1:N_sess
            % Functional images
            for image = 1:SPM.SPM.nscan(sess_num(sessi))
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).scans{image,1} = SPM.SPM.xY.VY(SPM.SPM.Sess(sess_num(sessi)).row(image)).fname;
            end
            
            % Conditions (including PSY regressors)
            for cond = 1:length(SPM.SPM.Sess(sess_num(sessi)).U)
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).cond(cond).name = SPM.SPM.Sess(sess_num(sessi)).U(cond).name{1};
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).cond(cond).onset = SPM.SPM.Sess(sess_num(sessi)).U(cond).ons;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).cond(cond).duration = SPM.SPM.Sess(sess_num(sessi)).U(cond).dur;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).cond(cond).tmod = 0;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).cond(cond).pmod = struct('name', {}, 'param', {}, 'poly', {});
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).cond(cond).orth = 1;
            end

            % Add PPI regressors          
            for condi = 1:length(cond_list)
                if cond_list(condi).sess == sess_num(sessi)
                    matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).regress(PPI_num(condi)).name = ['PPI_' PPI(condi).PPI.name];
                    matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).regress(PPI_num(condi)).val = PPI(condi).PPI.ppi;
                end
            end

            % Add PHYS regressors
            matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).regress(sum(sess==sess_num(sessi))+1).name = ['Seed_' tmfc.ROI_set(ROI_set_number).ROIs(j).name];
            matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).regress(sum(sess==sess_num(sessi))+1).val = PPI(find(sess == sess_num(sessi),1)).PPI.Y;
            VOI.sess(sessi).Y(:,j) = PPI(find(sess == sess_num(sessi),1)).PPI.Y;
            
            % Confounds       
            for conf = 1:length(SPM.SPM.Sess(sess_num(sessi)).C.name)
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).regress(conf+sum(sess == sess_num(sessi))+1).name = SPM.SPM.Sess(sess_num(sessi)).C.name{1,conf};
                matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).regress(conf+sum(sess == sess_num(sessi))+1).val = SPM.SPM.Sess(sess_num(sessi)).C.C(:,conf);
            end
            
            matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).multi = {''};
            matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).multi_reg = {''};
            matlabbatch{1}.spm.stats.fmri_spec.sess(sessi).hpf = SPM.SPM.xX.K(sess_num(sessi)).HParam;            
        end

        matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
        matlabbatch{1}.spm.stats.fmri_spec.bases.fir.length =  tmfc.ROI_set(ROI_set_number).gPPI_FIR.window;
        matlabbatch{1}.spm.stats.fmri_spec.bases.fir.order = tmfc.ROI_set(ROI_set_number).gPPI_FIR.bins;
        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global = SPM.SPM.xGX.iGXcalc;
        matlabbatch{1}.spm.stats.fmri_spec.mthresh = SPM.SPM.xM.gMT;
    
        try
            matlabbatch{1}.spm.stats.fmri_spec.mask = {SPM.SPM.xM.VM.fname};
        catch
            matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
        end
    
        if strcmp(SPM.SPM.xVi.form,'i.i.d')
            matlabbatch{1}.spm.stats.fmri_spec.cvi = 'None';
        elseif strcmp(SPM.SPM.xVi.form,'AR(0.2)')
            matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
        else
            matlabbatch{1}.spm.stats.fmri_spec.cvi = 'FAST';
        end

        batch{j} = matlabbatch;
        clear matlabbatch PPI   
    end

    switch tmfc.defaults.parallel
        case 0                              % Sequential
            for j = 1:R
                spm('defaults','fmri');
                spm_jobman('initcfg');
                spm_get_defaults('cmdline',true);
                spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                spm_get_defaults('stats.fmri.ufp',1);
                spm_jobman('run',batch{j});
    
                % Save GLM_batch.mat file
                tmfc_parsave_batch(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','GLM_batches',tmfc.ROI_set(ROI_set_number).ROIs(j).name,...
                    ['Subject_' num2str(i,'%04.f') '_gPPI_FIR_GLM.mat']),batch{j});
            end
            
        case 1                              % Parallel
            parfor j = 1:R
                spm('defaults','fmri');
                spm_jobman('initcfg');
                spm_get_defaults('cmdline',true);
                spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                spm_get_defaults('stats.fmri.ufp',1);
                spm_jobman('run',batch{j});

                % Save GLM_batch.mat file
                tmfc_parsave_batch(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','GLM_batches',tmfc.ROI_set(ROI_set_number).ROIs(j).name,...
                    ['Subject_' num2str(i,'%04.f') '_gPPI_FIR_GLM.mat']),batch{j});
            end
    end

    clear batch
    pause(0.0001)

    %=======================[ Estimate gPPI GLM ]==========================
    
    % Seed-to-voxel and ROI-to-ROI analyses
    if tmfc.defaults.analysis == 1

        % Seed-to-voxel
        for j = 1:R
            matlabbatch{1}.spm.stats.fmri_est.spmmat(1) = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name,'SPM.mat')};
            matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
            matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
            batch{j} = matlabbatch;
            clear matlabbatch
        end

        SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(1).name,'SPM.mat'));

        switch tmfc.defaults.parallel
            case 0                              % Sequential
                for j = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    spm_jobman('run',batch{j});

                    % Save PPI beta images
                    for condi = 1:length(cond_list)
                        copyfile(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')], ... 
                            tmfc.ROI_set(ROI_set_number).ROIs(j).name,['beta_' num2str(PPI_num(condi) - 1 + SPM.SPM.Sess(PPI_sess(condi)).col(1) + tmfc.ROI_set(ROI_set_number).gPPI_FIR.bins*length(SPM.SPM.Sess(PPI_sess(condi)).U),'%04.f') '.nii']), ...
                            fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(j).name, ...
                            ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(condi,'%04.f') '_' condition(condi).name '.nii']));
                    end
                end
                
            case 1                              % Parallel
                parfor j = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    spm_jobman('run',batch{j});

                    % Save PPI beta images
                    for condi = 1:length(cond_list)
                        copyfile(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')], ... 
                            tmfc.ROI_set(ROI_set_number).ROIs(j).name,['beta_' num2str(PPI_num(condi) - 1 + SPM.SPM.Sess(PPI_sess(condi)).col(1) + tmfc.ROI_set(ROI_set_number).gPPI_FIR.bins*length(SPM.SPM.Sess(PPI_sess(condi)).U),'%04.f') '.nii']), ...
                            fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(j).name, ...
                            ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(condi,'%04.f') '_' condition(condi).name '.nii']));
                    end
                end
        end

        % ROI-to_ROI
        Y = [];
        for j = 1:N_sess
            Y = [Y; VOI.sess(j).Y];
        end

        switch tmfc.defaults.parallel
            case 0                              % Sequential
                for j = 1:R
                    SPM = [];
                    SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name,'SPM.mat'));
                    beta(:,:,j) = SPM.SPM.xX.pKX*Y;                    
                end
            case 1                              % Parallel
                parfor j = 1:R
                    SPM = [];
                    SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name,'SPM.mat'));
                    beta(:,:,j) = SPM.SPM.xX.pKX*Y;                     
                end
        end
        
        % Save PPI beta matrices
        for condi = 1:length(cond_list)
            ppi_matrix = squeeze(beta(PPI_num(condi) - 1 + SPM.SPM.Sess(PPI_sess(condi)).col(1) + tmfc.ROI_set(ROI_set_number).gPPI_FIR.bins*length(SPM.SPM.Sess(PPI_sess(condi)).U),:,:));
            ppi_matrix(1:size(ppi_matrix,1)+1:end) = nan;
            symm_ppi_matrix =(ppi_matrix + ppi_matrix')/2;
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','asymmetrical', ...
                ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(condi,'%04.f') '_' condition(condi).name '.mat']),'ppi_matrix');
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','symmetrical', ...
                ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(condi,'%04.f') '_' condition(condi).name '.mat']),'symm_ppi_matrix');
            clear ppi_matrix symm_ppi_matrix
        end
    end

    % ROI-to-ROI analysis only
    if tmfc.defaults.analysis == 2
        Y = [];
        for j = 1:N_sess
            Y = [Y; VOI.sess(j).Y];
        end       

        switch tmfc.defaults.parallel
            case 0                              % Sequential
                for j = 1:R
                    SPM = [];
                    SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name,'SPM.mat'));
                    xX = SPM.SPM.xX;
                    if isfield(SPM.SPM.xX,'W')
                        SPM.SPM.xX  = rmfield(SPM.SPM.xX,'W');
                    end
                    if isfield(SPM.SPM.xVi,'V')
                        SPM.SPM.xVi = rmfield(SPM.SPM.xVi,'V');
                    end
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    xVi         = spm_est_non_sphericity(SPM.SPM);
                    W           = spm_sqrtm(spm_inv(xVi.V));
                    W           = W.*(abs(W) > 1e-6);
                    xKXs        = spm_sp('Set',spm_filter(xX.K,W*xX.X));
                    xKXs.X      = full(xKXs.X);
                    pKX         = spm_sp('x-',xKXs);
                    beta(:,:,j)        = pKX*Y;                    
                end
            case 1                              % Parallel
                parfor j = 1:R
                    SPM = []; xX = []; xVi = []; W = []; xKXs = []; pKX = [];
                    SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name,'SPM.mat'));
                    xX = SPM.SPM.xX;
                    if isfield(SPM.SPM.xX,'W')
                        SPM.SPM.xX  = rmfield(SPM.SPM.xX,'W');
                    end
                    if isfield(SPM.SPM.xVi,'V')
                        SPM.SPM.xVi = rmfield(SPM.SPM.xVi,'V');
                    end
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    xVi         = spm_est_non_sphericity(SPM.SPM);
                    W           = spm_sqrtm(spm_inv(xVi.V));
                    W           = W.*(abs(W) > 1e-6);
                    xKXs        = spm_sp('Set',spm_filter(xX.K,W*xX.X));
                    xKXs.X      = full(xKXs.X);
                    pKX         = spm_sp('x-',xKXs);
                    beta(:,:,j)        = pKX*Y;                    
                end
        end

        % Save PPI beta matrices
        for condi = 1:length(cond_list)
            ppi_matrix = squeeze(beta(PPI_num(condi) - 1 + SPM.SPM.Sess(PPI_sess(condi)).col(1) + tmfc.ROI_set(ROI_set_number).gPPI_FIR.bins*length(SPM.SPM.Sess(PPI_sess(condi)).U),:,:));
            ppi_matrix(1:size(ppi_matrix,1)+1:end) = nan;
            symm_ppi_matrix =(ppi_matrix + ppi_matrix')/2;
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','asymmetrical', ...
                ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(condi,'%04.f') '_' condition(condi).name '.mat']),'ppi_matrix');
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','symmetrical', ...
                ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(condi,'%04.f') '_' condition(condi).name '.mat']),'symm_ppi_matrix');
            clear ppi_matrix symm_ppi_matrix
        end
    end

    % Seed-to-voxel analysis only
    if tmfc.defaults.analysis == 3
        for j = 1:R
            matlabbatch{1}.spm.stats.fmri_est.spmmat(1) = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name,'SPM.mat')};
            matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
            matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
            batch{j} = matlabbatch;
            clear matlabbatch
        end

        SPM = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(1).name,'SPM.mat'));

        switch tmfc.defaults.parallel
            case 0                              % Sequential
                for j = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    spm_jobman('run',batch{j});

                    % Save PPI beta images
                    for condi = 1:length(cond_list)
                        copyfile(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')], ... 
                            tmfc.ROI_set(ROI_set_number).ROIs(j).name,['beta_' num2str(PPI_num(condi) - 1 + SPM.SPM.Sess(PPI_sess(condi)).col(1) + tmfc.ROI_set(ROI_set_number).gPPI_FIR.bins*length(SPM.SPM.Sess(PPI_sess(condi)).U),'%04.f') '.nii']), ...
                            fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(j).name, ...
                            ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(condi,'%04.f') '_' condition(condi).name '.nii']));
                    end
                end
                
            case 1                              % Parallel
                parfor j = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    spm_jobman('run',batch{j});

                    % Save PPI beta images
                    for condi = 1:length(cond_list)
                        copyfile(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')], ... 
                            tmfc.ROI_set(ROI_set_number).ROIs(j).name,['beta_' num2str(PPI_num(condi) - 1 + SPM.SPM.Sess(PPI_sess(condi)).col(1) + tmfc.ROI_set(ROI_set_number).gPPI_FIR.bins*length(SPM.SPM.Sess(PPI_sess(condi)).U),'%04.f') '.nii']), ...
                            fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(j).name, ...
                            ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(condi,'%04.f') '_' condition(condi).name '.nii']));
                    end
                end
        end 
    end
    
    % Remove temporal gPPI directories
    rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR',['Subject_' num2str(i,'%04.f')]),'s');

    sub_check(i) = 1;
    pause(0.0001)
    
    % Update waitbar
    switch tmfc.defaults.parallel
        case 0                              % Sequential
            hms = fix(mod(((N-i)*toc/i), [0, 3600, 60]) ./ [3600, 60, 1]);
            try
                waitbar(i/N, handles, [num2str(i/N*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
            end
        case 1                              % Parallel
            try
                send(D,[]);
            end
    end

    clear SPM
end

% Default contrasts info
SPM = load(tmfc.subjects(1).path);
for j = 1:length(cond_list)
    contrasts(j).title = ['[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']'];
    contrasts(j).weights = zeros(1,length(cond_list));
    contrasts(j).weights(1,j) = 1;
end

% Close waitbar
try
    delete(w);
end

function cleanMeUp()    
    try
        GUI = guidata(findobj('Tag','TMFC_GUI')); 
        set([GUI.TMFC_GUI_B1, GUI.TMFC_GUI_B2, GUI.TMFC_GUI_B3, GUI.TMFC_GUI_B4,...
            GUI.TMFC_GUI_B5a, GUI.TMFC_GUI_B5b, GUI.TMFC_GUI_B6, GUI.TMFC_GUI_B7,...
            GUI.TMFC_GUI_B8, GUI.TMFC_GUI_B9, GUI.TMFC_GUI_B10, GUI.TMFC_GUI_B11,...
            GUI.TMFC_GUI_B12a,GUI.TMFC_GUI_B12b,GUI.TMFC_GUI_B13a,GUI.TMFC_GUI_B13b,...
            GUI.TMFC_GUI_B14a,GUI.TMFC_GUI_B14b], 'Enable', 'on');
        delete(findall(0,'type', 'Figure','Tag', 'tmfc_waitbar'));
    end
    try                                                                 
        delete(findall(0,'type','Figure','Tag', 'tmfc_waitbar'));
    end
end


end

% Save batches in parallel mode
function tmfc_parsave_batch(fname,matlabbatch)
	save(fname, 'matlabbatch')
end

% Waitbar for parallel mode
function tmfc_parfor_waitbar(waitbarHandle,iterations)
    persistent count h N start

    if nargin == 2
        count = 0;
        h = waitbarHandle;
        N = iterations;
        start = tic;
        
    else
        if isvalid(h)         
            count = count + 1;
            time = toc(start);
            hms = fix(mod(((N-count)*time/count), [0, 3600, 60]) ./ [3600, 60, 1]);
            waitbar(count / N, h, [num2str(count/N*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
        end
    end
end
