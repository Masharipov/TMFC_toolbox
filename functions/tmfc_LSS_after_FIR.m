
function [sub_check] = tmfc_LSS_after_FIR(tmfc,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% For each individual trial, the Least-Squares Separate (LSS) approach
% estimates a separate GLM with two regressors. The first regressor models
% the expected BOLD response to the current trial of interest, and the 
% second (nuisance) regressor models the BOLD response to all other trials
% (of interest and no interest). For trials of no interest (e.g., errors),
% individual GLMs are not estimated. Trials of no interest are used only
% for the second (nuisance) regressor.
%
% This function uses SPM.mat file (which contains the specification of the
% 1st-level GLM with canonical HRF) to specify and estimate 1st-level GLMs
% for each individual trial of interest (LSS approach).
%
% It uses residual time-series created after the FIR task regression.
% Residual time-series (Res_*.nii images) are free of (1) co-activations
% and (2) confounds specified in the original SPM.mat file (e.g., motion,
% physiological noise, etc). Using residual time-series, we control for
% spurious inflation of functional connectivity estimates due to
% co-activations. This function does not add confounds (e.g., motion, 
% physiological noise, etc) to the LSS models since they have already been
% regressed out during the FIR task regression.
%
% FORMAT [sub_check] = tmfc_LSS_after_FIR(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path     - List of paths to SPM.mat files for N subjects
%   tmfc.project_path      - The path where all results will be saved
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^31 = 2GB (how much RAM can be used at
%                            the same time during GLM estimation)
%   tmfc.defaults.resmem   - true or false (store temporaty files during
%                            GLM estimation in RAM or on disk)
%
%   tmfc.LSS_after_FIR.conditions        - List of conditions of interest
%   tmfc.LSS_after_FIR.conditions.sess   - Session number
%                                          (as specified in SPM.Sess)
%   tmfc.LSS_after_FIR.conditions.number - Condition number
%                                          (as specified in SPM.Sess.U)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified:
%
%   tmfc.LSS_after_FIR.conditions(1).sess   = 1;   
%   tmfc.LSS_after_FIR.conditions(1).number = 1; - "Cond A", 1st session
%   tmfc.LSS_after_FIR.conditions(2).sess   = 1;
%   tmfc.LSS_after_FIR.conditions(2).number = 2; - "Cond B", 1st session
%   tmfc.LSS_after_FIR.conditions(3).sess   = 2;
%   tmfc.LSS_after_FIR.conditions(3).number = 1; - "Cond A", 2nd session
%   tmfc.LSS_after_FIR.conditions(4).sess   = 2;
%   tmfc.LSS_after_FIR.conditions(4).number = 2; - "Cond B", 2nd session
%
% FORMAT [sub_check] = tmfc_LSS_after_FIR(tmfc, start_sub)
% Run the function starting from а specific subject in the path list.
%
%   tmfc                   - As above
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
   start_sub = 1;
else
   if start_sub == 1
       sub_check = NaN(length(tmfc.subjects),1);
   else
       sub_check = NaN(length(tmfc.subjects),1);
       sub_check(1:start_sub) = 1;
   end
   try
       SS1_LSS = findobj('Tag','MAIN_WINDOW');                     % Finding the GUI's object via the handle
       g7data = guidata(SS1_LSS);                                  % Creating a local refernce of the GUI's object 
       set(g7data.LSS_R_stat,'String', 'Updating...','ForegroundColor',[0.772, 0.353, 0.067])       % Assigning the status to the TMFC variable
   end
end

spm('defaults','fmri');
spm_jobman('initcfg');
   
N = length(tmfc.subjects);

cond_list = tmfc.LSS_after_FIR.conditions;


EXIT_STATUS_LSS = 0;

% Initialize waitbar for parallel or sequential computing
switch tmfc.defaults.parallel
    case 1
        handles.L_wp = waitbar(0,'Please wait...','Name','LSS regression','Tag','LSS_Parallel');
        D = parallel.pool.DataQueue;                                        % Creation of Parallel Pool 
        afterEach(D, @tmfc_parfor_waitbar);                                 % Command to update Waitbar
        tmfc_parfor_waitbar(handles.L_wp, N);     
        cleanupObj = onCleanup(@cleanMeUp);
    case 0
        handles.L_ws = waitbar(0,'Please wait...','Name','LSS regression','Tag','LSS_Serial','CreateCancelBtn',@quitter);
end

% Loop through subjects
for i = start_sub:N
    % I loop
    if EXIT_STATUS_LSS == 1 
        break;
    end
    
    tic
    SPM = load(tmfc.subjects(i).path);
    
    if ~isfolder([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f')])
        mkdir([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'Betas'])
        mkdir([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'GLM_batches'])
        mkdir([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'SPM_mat_files'])
    end

    % Loop through sessions
    for j = 1:length(SPM.SPM.Sess)       
        
        % J loop
        if EXIT_STATUS_LSS == 1 
            break;
        end
        % Trials of interest
        E = 0;
        ons_of_int = [];
        dur_of_int = [];
        cond_of_int = [];
        trial.cond = [];
        trial.number = [];
        for k = 1:length(cond_list)
            if cond_list(k).sess == j
                E = E + length(SPM.SPM.Sess(j).U(cond_list(k).number).ons);
                ons_of_int = [ons_of_int; SPM.SPM.Sess(j).U(cond_list(k).number).ons];
                dur_of_int = [dur_of_int; SPM.SPM.Sess(j).U(cond_list(k).number).dur];
                cond_of_int = [cond_of_int cond_list(k).number];
                trial.cond = [trial.cond; repmat(cond_list(k).number,length(SPM.SPM.Sess(j).U(cond_list(k).number).ons),1)];
                trial.number = [trial.number; (1:length(SPM.SPM.Sess(j).U(cond_list(k).number).ons))'];
            end
        end

        all_trials_number = (1:E)';  

        % Trials of no interest
        cond_of_no_int = setdiff([1:length(SPM.SPM.Sess(j).U)],cond_of_int);
        ons_of_no_int = [];
        dur_of_no_int = [];
        for k = 1:length(cond_of_no_int)
            ons_of_no_int = [ons_of_no_int; SPM.SPM.Sess(j).U(cond_of_no_int(k)).ons];
            dur_of_no_int = [dur_of_no_int; SPM.SPM.Sess(j).U(cond_of_no_int(k)).dur];
        end
        
        % Loop through trials of interest
        for k = 1:E

            if isfolder([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k)])
                rmdir([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k)],'s');
            end
                   
            matlabbatch{1}.spm.stats.fmri_spec.dir = {[tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k)]};
            matlabbatch{1}.spm.stats.fmri_spec.timing.units = SPM.SPM.xBF.UNITS;
            matlabbatch{1}.spm.stats.fmri_spec.timing.RT = SPM.SPM.xY.RT;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = SPM.SPM.xBF.T;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = SPM.SPM.xBF.T0;
                        
            % Functional images
            for image = 1:SPM.SPM.nscan(j)
                matlabbatch{1}.spm.stats.fmri_spec.sess.scans{image,1} = [tmfc.project_path filesep 'FIR_regression' filesep 'Subject_' num2str(i,'%04.f') filesep 'Res_' num2str(SPM.SPM.Sess(j).row(image),'%.4d') '.nii,1'];
            end
    
            % Current trial vs all other trials (of interest and no interrest)
            current_trial_ons = ons_of_int(k);
            current_trial_dur = dur_of_int(k);
            other_trials = all_trials_number(find(all_trials_number~=k));
            other_trials_ons = [ons_of_int(other_trials); ons_of_no_int];
            other_trials_dur = [dur_of_int(other_trials); dur_of_no_int];
            
            % Conditions
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name = 'Current_trial';
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = current_trial_ons;
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = current_trial_dur;
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).tmod = 0;
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).orth = 1;
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).name = 'Other_trials';
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).onset = other_trials_ons;
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).duration = other_trials_dur;
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).tmod = 0;
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).orth = 1;
    
            % Confounds       
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
            matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''};
            matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {''};
    
            % HPF, HRF, mask 
            matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = SPM.SPM.xX.K(j).HParam;    
            matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
            matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
            matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
            matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
            matlabbatch{1}.spm.stats.fmri_spec.mthresh = -Inf;           
            matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
            matlabbatch{1}.spm.stats.fmri_spec.cvi = SPM.SPM.xVi.form;
            matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
            matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
            matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
            
            batch{k} = matlabbatch;
            clear matlabbatch current* other*
        end

        % Variable to Exit FIR regression during execution
         
        
        % Parallel or sequential computing
        switch tmfc.defaults.parallel    
        %% ASH, CHANGE PARFEVAL TO PARFOR
        % --------------------- Parallel Computing ------------------------        
            case 1
                parfor k = 1:E
                    try
                        spm('defaults','fmri');
                        spm_jobman('initcfg');
                        spm_get_defaults('cmdline',true);
                        spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                        spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                        spm_get_defaults('stats.fmri.ufp',1);
                        spm_jobman('run',batch{k});

                        % Save individual trial beta image
                        copyfile([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k) filesep 'beta_0001.nii'],...
                            [tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'Betas' filesep ...
                            'Beta_Sess_' num2str(j) '_Cond_' num2str(trial.cond(k)) '_Trial_' num2str(trial.number(k)) '.nii']);

                        % Save SPM.mat file
                        copyfile([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k) filesep 'SPM.mat'],...
                            [tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'SPM_mat_files' filesep ...
                            'SPM_Sess_' num2str(j) '_Cond_' num2str(trial.cond(k)) '_Trial_' num2str(trial.number(k)) '.mat']);

                        % Save GLM_bactch.mat files
                        tmfc_parsave([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'GLM_batches' filesep ...
                            'GLM_Sess_' num2str(j) '_Cond_' num2str(trial.cond(k)) '_Trial_' num2str(trial.number(k)) '.mat'],batch{k});

                        % Remove temporal LSS directory
                        rmdir([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k)],'s');

                        sub_check(i,j,k) = 1;
                    catch
                        sub_check(i,j,k) = 0;
                    end
                    
                end
                
%                     try %STOPs Minimimizing of the waitbar
%                     DG = guidata(findobj('Tag', 'MAIN_WINDOW'));
%                     set(DG.MAIN_F, 'Position', [0.18 0.26 0.205 0.575])
%                     figure(DG.MAIN_F);
%                     end                
                 
        % -------------------- Sequential Computing -----------------------
        case 0
            for k = 1:E
                if EXIT_STATUS_LSS ~= 1                                             % IF Cancel/X button has NOT been pressed, then contiune execution
                    try
                        spm('defaults','fmri');
                        spm_jobman('initcfg');
                        spm_get_defaults('cmdline',true);
                        spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                        spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                        spm_get_defaults('stats.fmri.ufp',1);
                        spm_jobman('run',batch{k});

                        % Save individual trial beta image
                        copyfile([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k) filesep 'beta_0001.nii'],...
                            [tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'Betas' filesep ...
                            'Beta_Sess_' num2str(j) '_Cond_' num2str(trial.cond(k)) '_Trial_' num2str(trial.number(k)) '.nii']);

                        % Save SPM.mat file
                        copyfile([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k) filesep 'SPM.mat'],...
                            [tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'SPM_mat_files' filesep ...
                            'SPM_Sess_' num2str(j) '_Cond_' num2str(trial.cond(k)) '_Trial_' num2str(trial.number(k)) '.mat']);

                        % Save GLM_bactch.mat files
                        tmfc_parsave([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'GLM_batches' filesep ...
                            'GLM_Sess_' num2str(j) '_Cond_' num2str(trial.cond(k)) '_Trial_' num2str(trial.number(k)) '.mat'],batch{k});

                        % Remove temporal LSS directory
                        rmdir([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k)],'s');

                        sub_check(i,j,k) = 1;
                    catch
                        sub_check(i,j,k) = 0;
                    end
                else
                    waitbar(N,handles.L_ws, sprintf('Cancelling Operation'));
                    delete(handles.L_ws);
                    try                                                             % Updating the TMFC GUI window with the progress
                        HBC_LSS = findobj('Tag','MAIN_WINDOW');                        % Finding the GUI's object via handle
                        g1data = guidata(HBC_LSS);                                      % Creating a local reference of the GUI's object
                        set(g1data.LSS_R_stat,'String', strcat(num2str(i), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);    % Assigning the status to the TMFC varaible
                    end
                    break;
                end
            end 
        end        
        clear E ons* dur* cond_of_int cond_of_no_int trial all_trials_number

    end
    
    % Update waitbar for sequential and parallel computing
    switch(tmfc.defaults.parallel)
        case 1
            send(D,[]); 
            
            try                                                             % Updating the TMFC GUI window with the progress
                HBC_LSS = findobj('Tag','MAIN_WINDOW');                     % Finding the GUI's object via handle
                g1data = guidata(HBC_LSS);                                  % Creating a local reference of the GUI's object
                set(g1data.LSS_R_stat,'String', strcat(num2str(i), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);    % Assigning the status to the TMFC varaible
            end

        case 0
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
            try
                waitbar(i/N,handles.L_ws,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
            end

            try                                                             % Updating the TMFC GUI window with the progress
                HBC_LSS = findobj('Tag','MAIN_WINDOW');                        % Finding the GUI's object via handle
                g1data = guidata(HBC_LSS);                                      % Creating a local reference of the GUI's object
                set(g1data.LSS_R_stat,'String', strcat(num2str(i), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);    % Assigning the status to the TMFC varaible
            end
    end

    clear SPM batch

end

% Deleting the wait bars after completion of LSS regression
try
    delete(handles.L_wp);
end

try
    delete(handles.L_ws);
end


lss_upd = evalin('base', 'tmfc');                                       % Creation of local copy
for i = start_sub:N                                                     % Updating the status of the FIR per subject
    lss_upd.subjects(i).LSS_after_FIR = squeeze(sub_check(i,:,:));
end
assignin('base', 'tmfc', lss_upd);      



function quitter(~,~)                                                  % Function that changes the state of execution when CANCEL is pressed
    EXIT_STATUS_LSS = 1;
    disp("CHANGED");
end

function cleanMeUp()
    try
        h_FREZ_U = findobj('Tag','MAIN_WINDOW');
        FZ_data = guidata(h_FREZ_U); 
        set([FZ_data.SUB, FZ_data.FIR_TR, FZ_data.LSS_R, FZ_data.LSS_RW, FZ_data.BSC, FZ_data.gPPI, FZ_data.save_p, FZ_data.open_p, FZ_data.change_p, FZ_data.settings, FZ_data.BGFC],'Enable', 'on');
        delete(findall(0,'Tag', 'LSS_Parallel','type', 'Figure'));
         
        % FUTURE UPDATE PENDING
        % This is where the piece of code that checks the last
        % processed subjects should be inserted
         
    end
end
end

% Save batches in parallel mode
function tmfc_parsave(fname,matlabbatch)
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
    
%% ASH, DELETE IF UNUSED:
%     % Function adapted for parallel computing
%     function [status] = Worker_LS(tmfc, batch, idi, idj, idk, paths)
%     % idi=i , idj = j, idk = k
% 
%         try
%                 spm('defaults','fmri');
%                 spm_jobman('initcfg');
%                 spm_get_defaults('cmdline',true);
%                 spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
%                 spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
%                 spm_get_defaults('stats.fmri.ufp',1);
%                 spm_jobman('run',batch{idk});
% 
%                 % Save individual trial beta image
%                 copyfile([paths{idi,1}(1:end-7) 'LSS_Sess_' num2str(idj) '_Trial_' num2str(idk) filesep 'beta_0001.nii'],...
%                     [paths{idi,1}(1:end-7) 'LSS_after_FIR_task_regression' filesep 'Betas' filesep ...
%                     'Beta_Sess_' num2str(idj) '_Cond_' num2str(trial.cond(idk)) '_Trial_' num2str(trial.number(idk)) '.nii']);
% 
%                 % Save SPM.mat file
%                 copyfile([paths{idi,1}(1:end-7) 'LSS_Sess_' num2str(idj) '_Trial_' num2str(idk) filesep 'SPM.mat'],...
%                     [paths{idi,1}(1:end-7) 'LSS_after_FIR_task_regression' filesep 'SPM_files' filesep ...
%                     'SPM_Sess_' num2str(idj) '_Cond_' num2str(trial.cond(idk)) '_Trial_' num2str(trial.number(idk)) '.mat']);
% 
%                 % Save GLM_bactch.mat files
%                 parsave([paths{idi,1}(1:end-7) 'LSS_after_FIR_task_regression' filesep 'GLM_batches' filesep ...
%                     'GLM_Sess_' num2str(idj) '_Cond_' num2str(trial.cond(idk)) '_Trial_' num2str(trial.number(idk)) '.mat'],batch{idk});
% 
%                 % Remove temporal LSS directory
%                 rmdir([paths{idi,1}(1:end-7) 'LSS_Sess_' num2str(idj) '_Trial_' num2str(idk)],'s');
% 
%                 status(idi,idj,idk) = 1;
%             catch
%                 status(idi,idj,idk) = 0;
%         end
%     end
% 
% 
% 
% 
% end
% 
% 
% 
% % Function to monitor the counting of the Parallel Loops
%    function setter(X, Y, F)
% 
%         persistent count GDS; 
% 
%         if nargin == 3                                                      % Intialization in the first iteration
%             count = 0;                                                      % Reset Count to zero
%             GDS = Y;                                                        % Dummy variable to store elements in the start
%             G = F;
%         else
%             count = count + 1;
%             HLL = findobj('Tag','MAIN_WINDOW');
%             gLdata = guidata(HLL);
%             set(gLdata.LSS_R_stat,"String", count+" Completed","ForegroundColor",[0.219, 0.341, 0.137]);
%         end
%   
%    end