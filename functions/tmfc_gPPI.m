function [sub_check] = tmfc_gPPI(tmfc,ROI_set_number,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Estimates gPPI GLMs. Saves individual connectivity matrices
% (ROI-to-ROI analysis) and connectivity images (seed-to-voxel analysis)
% for each condition of interest.
%
% FORMAT [sub_check] = tmfc_gPPI(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path     - Paths to individual SPM.mat files
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^31 = 2GB (how much RAM can be used)
%   tmfc.defaults.resmem   - true or false (store temporaty files in RAM)
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to the ROI images masked by group
%                                   mean binary mask 
%
%   tmfc.gPPI.conditions          - List of conditions of interest
%   tmfc.gPPI.conditions.sess     - Session number
%                                   (as specified in SPM.Sess)
%   tmfc.gPPI.conditions.number   - Condition number
%                                   (as specified in SPM.Sess.U)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified:
%
%   tmfc.gPPI.conditions(1).sess   = 1;   
%   tmfc.gPPI.conditions(1).number = 1; - "Cond A", 1st session
%   tmfc.gPPI.conditions(2).sess   = 1;
%   tmfc.gPPI.conditions(2).number = 2; - "Cond B", 1st session
%   tmfc.gPPI.conditions(3).sess   = 2;
%   tmfc.gPPI.conditions(3).number = 1; - "Cond A", 2nd session
%   tmfc.gPPI.conditions(4).sess   = 2;
%   tmfc.gPPI.conditions(4).number = 2; - "Cond B", 2nd session
%
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path = 'C:\ROI_set\two_ROIs\ROI_2.nii';
%
% FORMAT [sub_check] = tmfc_gPPI(tmfc,ROI_set_number,start_sub)
% Run the function starting from a specific subject in the path list for
% the selected ROI set.
%
%   tmfc                   - As above
%   ROI_set_number         - Number of the ROI set in the tmfc structure
%   start_sub              - Subject number on the path list to start with
%
% =========================================================================
%
% Copyright (C) 2023 Ruslan Masharipov
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
cond_list = tmfc.gPPI.conditions;
sess = []; sess_num = []; N_sess = [];
for i = 1:length(cond_list)
    sess(i) = cond_list(i).sess;
end
sess_num = unique(sess);
N_sess = length(sess_num);

% Initialize waitbar for parallel or sequential computing
switch tmfc.defaults.parallel
    case 0                                      % Sequential
        w = waitbar(0,'Please wait...','Name','gPPI GLM estimation');
    case 1                                      % Parallel
        w = waitbar(0,'Please wait...','Name','gPPI GLM estimation');
        D = parallel.pool.DataQueue;            % Creation of parallel pool 
        afterEach(D, @tmfc_parfor_waitbar);     % Command to update waitbar
        tmfc_parfor_waitbar(w,N);     
end

if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI'))
    mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','GLM_batches'));
    mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI'));
    mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','Seed_to_voxel'));
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
        if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name))
            rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name),'s');
        end
        % Loop through conditions of interest
        for condi = 1:length(cond_list)
            PPI(condi) = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(i,'%04.f')], ...
                            ['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(j).name,' ','_') ...
                            ']_[Sess_' num2str(cond_list(condi).sess) ']_[Cond_' num2str(cond_list(condi).number) ']_[' ...
                            regexprep(char(SPM.SPM.Sess(cond_list(condi).sess).U(cond_list(condi).number).name),' ','_') '].mat']));
        end
        % gPPI GLM batch
        matlabbatch{1}.spm.stats.fmri_spec.dir = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name)};
        matlabbatch{1}.spm.stats.fmri_spec.timing.units = SPM.SPM.xBF.UNITS;
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = SPM.SPM.xY.RT;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = SPM.SPM.xBF.T;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = SPM.SPM.xBF.T0;
        % Loop throuph sessions
        for sessi = 1:N_sess
            % Functional images
            for image = 1:SPM.SPM.nscan(sess_num(sessi))
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).scans{image,1} = SPM.SPM.xY.VY(SPM.SPM.Sess(sess_num(sessi)).row(image)).fname;
            end
            
            % Conditions (including PSY regressors)
            for cond = 1:length(SPM.SPM.Sess(sess_num(sessi)).U)
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).cond(cond).name = SPM.SPM.Sess(sess_num(sessi)).U(cond).name{1};
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).cond(cond).onset = SPM.SPM.Sess(sess_num(sessi)).U(cond).ons;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).cond(cond).duration = 0;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).cond(cond).tmod = 0;
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).cond(cond).pmod = struct('name', {}, 'param', {}, 'poly', {});
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).cond(cond).orth = 1;
            end

            % Add PPI regressors
            for condi = 1:length(cond_list)
                if cond_list(condi).sess == sess_num(sessi)
                    matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).regress(condi).name = ['PPI_' PPI(condi).PPI.name];
                    matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).regress(condi).val = PPI(condi).PPI.ppi;
                end
            end

            % Add PHYS regressors
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).regress(length(cond_list)+1).name = ['Seed_' tmfc.ROI_set(ROI_set_number).ROIs(j).name];
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).regress(length(cond_list)+1).val = PPI(find(sess == sess_num(sessi),1)).PPI.Y;
            
            % Confounds       
            for conf = 1:length(SPM.SPM.Sess(sess_num(sessi)).C.name)
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).regress(conf+length(find(sess == sess_num(sessi)))+1).name = SPM.SPM.Sess(sess_num(sessi)).C.name{1,conf};
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).regress(conf+length(find(sess == sess_num(sessi)))+1).val = SPM.SPM.Sess(sess_num(sessi)).C.C(:,conf);
            end
            
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).multi = {''};
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).multi_reg = {''};
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess_num(sessi)).hpf = SPM.SPM.xX.K(sess_num(sessi)).HParam;            
        end

        matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global = SPM.SPM.xGX.iGXcalc;
        matlabbatch{1}.spm.stats.fmri_spec.mthresh = SPM.SPM.xM.gMT;
    
        try
            matlabbatch{1}.spm.stats.fmri_spec.mask = {SPM.SPM.xM.VM.fname};
        catch
            matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
        end
    
        matlabbatch{1}.spm.stats.fmri_spec.cvi = SPM.SPM.xVi.form;

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
            end
    end

    clear batch

    %=======================[ Estimate gPPI GLM ]==========================
    
    % ROI-to-ROI analysis
    if tmfc.defaults.analysis == 1 || 2
     
    end

    % Seed-to-voxel analysis
    if tmfc.defaults.analysis == 1 || 3
        for j = 1:R
            matlabbatch{1}.spm.stats.fmri_est.spmmat(1) = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI',['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(j).name),'SPM.mat'};
            matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
            matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
            batch{j} = matlabbatch;
            clear matlabbatch
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

                    % Save PPI beta images
                    copyfile(fullfile(tmfc.project_path,'LSS_regression_after_FIR',['Subject_' num2str(i,'%04.f')],['LSS_Sess_' num2str(sess_num(j)) '_Trial_' num2str(k)],'beta_0001.nii'),...
                        fullfile(tmfc.project_path,'LSS_regression_after_FIR',['Subject_' num2str(i,'%04.f')],'Betas', ...
                        ['Beta_[Sess_' num2str(sess_num(j)) ']_[Cond_' num2str(trial.cond(k)) ']_[' regexprep(char(SPM.SPM.Sess(sess_num(j)).U(trial.cond(k)).name),' ','_') ']_[Trial_' num2str(trial.number(k)) '].nii']));

                    % Save GLM_batch.mat file
                    tmfc_parsave_batch(fullfile(tmfc.project_path,'LSS_regression_after_FIR',['Subject_' num2str(i,'%04.f')],'GLM_batches',...
                        ['GLM_[Sess_' num2str(sess_num(j)) ']_[Cond_' num2str(trial.cond(k)) ']_[' regexprep(char(SPM.SPM.Sess(sess_num(j)).U(trial.cond(k)).name),' ','_') ']_[Trial_' num2str(trial.number(k)) '].mat']),batch{k});

                    % Remove temporal gPPI directory
                    rmdir(fullfile(tmfc.project_path,'LSS_regression_after_FIR',['Subject_' num2str(i,'%04.f')],['LSS_Sess_' num2str(sess_num(j)) '_Trial_' num2str(k)]),'s');

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
                end
        end 
    end
    
    sub_check(i) = 1;
    
    % Update waitbar
    switch tmfc.defaults.parallel
        case 0                              % Sequential
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
            try
                waitbar(i/N,w,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
            end
        case 1                              % Parallel
            send(D,[]);
    end
end
try
    close(w)
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
            t = seconds((N-count)*time/count); t.Format = 'hh:mm:ss';
            waitbar(count / N, h, [num2str(count/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
        end
    end
end
