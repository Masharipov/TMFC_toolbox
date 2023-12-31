function [sub_check] = tmfc_LSS_after_FIR(tmfc, start_sub)

% For each individual trial, the Least-Squares Separate (LSS) approach
% estimates a separate GLM with two regressors. The first regressor models
% the expected BOLD response to the current trial of interest, and the 
% second (nuisance) regressor models the BOLD response to all other trials
% (of interest and no interest). For trials of no interest (e.g., errors),
% individual GLMs are not estimated. Trials of no interest are used only
% for the second (nuisance) regressor.

% This function uses SPM.mat file (which contains the specification of the
% 1st-level GLM with canonical HRF) to specify and estimate 1st-level GLMs
% for each individual trial of interest (LSS approach).

% It uses residual time-series created after the FIR task regression
% ("resid_ts" in the name of this function refers to residual time-series).
% Residual time-series (Res_*.nii images stored in FIR_GLM subfolders) are
% free of (1) co-activations and (2) confounds specified in the original
% SPM.mat file (e.g., motion, physiological noise, etc). Using residual
% time-series, we control for spurious inflation of functional connectivity
% estimates due to co-activations. This function does not add confounds
% (e.g., motion, physiological noise, etc) to the LSS models since they
% have already been regressed out during the FIR task regression.

% FORMAT [sub_check] = LSS_regress_resid_ts(tmfc)
% Run a function starting from the first subject in the list
% tmfc.subjects.paths{N} - List of paths to SPM.mat files for N subjects
% tmfc.parallel          - 0 or 1 (sequential or parallel computing)
% tmfc.LSS_resid_ts.cond - List of conditions of interest.
% The "tmfc.LSS_resid_ts.cond" structure consist of two fields:
% tmfc.LSS_resid_ts.cond.sess   - Session number
% tmfc.LSS_resid_ts.cond.number - Condition number
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified:
% tmfc.LSS_resid_ts.cond(1).sess   = 1;   
% tmfc.LSS_resid_ts.cond(1).number = 1; - "Cond A" in the first session
% tmfc.LSS_resid_ts.cond(2).sess   = 1;
% tmfc.LSS_resid_ts.cond(2).number = 2; - "Cond B" in the first session
% tmfc.LSS_resid_ts.cond(3).sess   = 2;
% tmfc.LSS_resid_ts.cond(3).number = 1; - "Cond A" in the second session
% tmfc.LSS_resid_ts.cond(4).sess   = 2;
% tmfc.LSS_resid_ts.cond(4).number = 2; - "Cond B" in the second session

% FORMAT [sub_check] = LSS_regress_resid_ts(tmfc, start_sub, start_trial)
% Run the function starting from а specific subject in the path list.
% tmfc                   - As above
% start_sub              - Subject number on the path list to start with

%==========================================================================
% Ruslan Masharipov, october, 2023
% email: ruslan.s.masharipov@gmail.com

if nargin == 1
   start_sub = 1;
else
   %sub_check(1:length(tmfc.subjects)) = 0;
   sub_check = NaN(1, length(tmfc.subjects));
   sub_check(1:start_sub-1) = 1;
   SS1_LSS = findobj('Tag','MAIN_WINDOWS');                    % Finding the GUI's object via the handle
   g7data = guidata(SS1_LSS);                                  % Creating a local refernce of the GUI's object 
   set(g7data.LSS_R_stat,"String", "Updating...","ForegroundColor","#C55A11")       % Assigning the status to the TMFC variable
end
%paths = "";
   
for i_2 = 1:length(tmfc.subjects)
    paths(i_2,:) = tmfc.subjects(i_2).paths;
end
N = length(paths);


cond_list = tmfc.LSS_residual_ts.conditions;

[~,index] = sortrows([cond_list.sess; cond_list.number]');
cond_list = cond_list(index); clear index

%w = waitbar(0,'Please wait...','Name','LSS regression');

% Loop through subjects
for i = start_sub:N % this loops the whole content in Parallel or serial computing
    tic
    SPM = load(paths(i));
    cd(SPM.SPM.swd)
    
    if ~isfolder('LSS_after_FIR_task_regression')
        mkdir(['LSS_after_FIR_task_regression' filesep 'Betas'])
        mkdir(['LSS_after_FIR_task_regression' filesep 'GLM_batches'])
        mkdir(['LSS_after_FIR_task_regression' filesep 'SPM_files'])
    end

    % Loop through sessions
    for j = 1:length(SPM.SPM.Sess)       
        
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

            if isfolder([SPM.SPM.swd filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k)])
                rmdir([SPM.SPM.swd filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k)],'s');
            end
                   
            matlabbatch{1}.spm.stats.fmri_spec.dir = {[SPM.SPM.swd filesep 'LSS_Sess_' num2str(j) '_Trial_' num2str(k)]};
            matlabbatch{1}.spm.stats.fmri_spec.timing.units = SPM.SPM.xBF.UNITS;
            matlabbatch{1}.spm.stats.fmri_spec.timing.RT = SPM.SPM.xY.RT;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = SPM.SPM.xBF.T;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = SPM.SPM.xBF.T0;
                        
            % Functional images
            for image = 1:SPM.SPM.nscan(j)
                matlabbatch{1}.spm.stats.fmri_spec.sess.scans{image,1} = [SPM.SPM.swd filesep 'FIR_GLM' filesep 'Res_' num2str(SPM.SPM.Sess(j).row(image),'%.4d') '.nii,1'];
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
    EXIT_STATUS_LSS = 0;       
        
        
    
    % Switch case to select Parallel computing or Serial computing
        switch tmfc.defaults.parallel
            
        
    % ------------------------ Parallel Computing ------------------------        
            case 1
                disp("IN PROGRESS");
                
                N_p = length(tmfc.subjects);                                          % Threshold of elements to run FIR regression
                D = parallel.pool.DataQueue;                                        % Creation of Parallel Pool 
                afterEach(D, @parfor_waitbar);                                      % Command to update Waitbar
                %parfor_waitbar(handles.wp,N_p);     
                
                
                for k_P = start_sub:N_p
                    
                    f(N_p) = parfeval(@Worker, 1, tmfc, batch, i, j, N_p, paths); 
                    
                    try %STOPs Minimimizing of the Window
                    DG = guidata(findobj("Tag", "MAIN_WINDOWS"));
                    set(DG.MAIN_F, "Position", [0.18 0.26 0.205 0.575])
                    figure(DG.MAIN_F);
                    end
                end
                
                
            % ------------------------ Serial Computing ------------------------
            case 0
                
                handles.L_ws = waitbar(0,'Please wait...','Name','LSS regression',"Tag", "LS_Serial", 'CreateCancelBtn', @quitter);
        
                for k_s = 1:E
                    tic
                    if EXIT_STATUS_LSS ~= 1                                             % IF Cancel/X button has NOT been pressed, then contiune execution
                        try
                            spm('defaults','fmri');
                            spm_jobman('initcfg');
                            spm_get_defaults('cmdline',true);
                            spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                            spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                            spm_get_defaults('stats.fmri.ufp',1);
                            spm_jobman('run',batch{k_s});

                            % Save individual trial beta image
                            copyfile([paths{i,1}(1:end-7) 'LSS_Sess_' num2str(j) '_Trial_' num2str(k_s) filesep 'beta_0001.nii'],...
                                [paths{i,1}(1:end-7) 'LSS_after_FIR_task_regression' filesep 'Betas' filesep ...
                                'Beta_Sess_' num2str(j) '_Cond_' num2str(trial.cond(k_s)) '_Trial_' num2str(trial.number(k_s)) '.nii']);

                            % Save SPM.mat file
                            copyfile([paths{i,1}(1:end-7) 'LSS_Sess_' num2str(j) '_Trial_' num2str(k_s) filesep 'SPM.mat'],...
                                [paths{i,1}(1:end-7) 'LSS_after_FIR_task_regression' filesep 'SPM_files' filesep ...
                                'SPM_Sess_' num2str(j) '_Cond_' num2str(trial.cond(k_s)) '_Trial_' num2str(trial.number(k_s)) '.mat']);

                            % Save GLM_bactch.mat files
                            parsave([paths{i,1}(1:end-7) 'LSS_after_FIR_task_regression' filesep 'GLM_batches' filesep ...
                                'GLM_Sess_' num2str(j) '_Cond_' num2str(trial.cond(k_s)) '_Trial_' num2str(trial.number(k_s)) '.mat'],batch{k_s});

                            % Remove temporal LSS directory
                            rmdir([paths{i,1}(1:end-7) 'LSS_Sess_' num2str(j) '_Trial_' num2str(k_s)],'s');

                            sub_check(i,j,k_s) = 1;
                        catch
                            sub_check(i,j,k_s) = 0;
                        end
                    else
                        waitbar(N,handles.L_ws, sprintf("Cancelling Operation"));
                        delete(handles.L_ws);
                        try                                                             % Updating the TMFC GUI window with the progress
                            HBC_LSS = findobj('Tag','MAIN_WINDOWS');                        % Finding the GUI's object via handle
                            g1data = guidata(HBC_LSS);                                      % Creating a local reference of the GUI's object
                            set(g1data.LSS_R_stat,"String", i-1+"/"+N+" done","ForegroundColor","#385723");    % Assigning the status to the TMFC varaible
                        end
                        break;
                    end
                    try                                                             % Updating the TMFC GUI window with the progress
                        HBC_LSS = findobj('Tag','MAIN_WINDOWS');                        % Finding the GUI's object via handle
                        g1data = guidata(HBC_LSS);                                      % Creating a local reference of the GUI's object
                        set(g1data.LSS_R_stat,"String", i-1+"/"+N+" done","ForegroundColor","#385723");    % Assigning the status to the TMFC varaible
                    end
                    
                    t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
                    
                    try
                        waitbar(i/N,handles.L_ws,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
                    end
                    
                end 
        
        end
        
        clear E ons* dur* cond_of_int cond_of_no_int trial all_trials_number
        
    end
    
    clear SPM batch
    
end


                results = cell(N_p,1);
                
                % Loop to fetch results using the parallel Pool
                for gin = start_sub:N_p

                    %if EXIT_STATUS ~= 1                                             % If Cancel/X button has NOT been pressed, then continue execution

                       [completedIdx, result] = fetchNext(f);                       % Fetching results 
                       results{completedIdx} = result;
                       %disp(result); % Printing results for temporary confirmation

                        if results{completedIdx} == 1                               % Assigning Status of completion after execution of subject
                            sub_check(gin) = 1;
                        else
                            sub_check(gin) = 0;
                        end
                        send(D,[]);                                                 % Variable for persistent count assigned to the TMFC variable in the end


                        try                                                         % Updating the TMFC GUI with the progress
                        HBC_LSS = findobj('Tag','MAIN_WINDOWS');                    % Finding the GUI's object via the handle
                        g1data = guidata(HBC_LSS);                                  % Creating a local refernce of the GUI's object 
                        set(g1data.LSS_R_stat,"String", gin+"/"+N_p+" done","ForegroundColor","#385723");       % Assigning the status to the TMFC variable
                        end


                    end




    try
        delete(handles.L_ws);
    end


    function quitter(~,~)                                                   % Function that changes the state of execution when CANCEL is pressed
        EXIT_STATUS_LSS = 1;
    end

    

    % Function adapted for parallel computing
    function [status] = Worker_LS(tmfc, batch, idi, idj, idk, paths)
    % idi=i , idj = j, idk = k

        try
                spm('defaults','fmri');
                spm_jobman('initcfg');
                spm_get_defaults('cmdline',true);
                spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                spm_get_defaults('stats.fmri.ufp',1);
                spm_jobman('run',batch{idk});

                % Save individual trial beta image
                copyfile([paths{idi,1}(1:end-7) 'LSS_Sess_' num2str(idj) '_Trial_' num2str(idk) filesep 'beta_0001.nii'],...
                    [paths{idi,1}(1:end-7) 'LSS_after_FIR_task_regression' filesep 'Betas' filesep ...
                    'Beta_Sess_' num2str(idj) '_Cond_' num2str(trial.cond(idk)) '_Trial_' num2str(trial.number(idk)) '.nii']);

                % Save SPM.mat file
                copyfile([paths{idi,1}(1:end-7) 'LSS_Sess_' num2str(idj) '_Trial_' num2str(idk) filesep 'SPM.mat'],...
                    [paths{idi,1}(1:end-7) 'LSS_after_FIR_task_regression' filesep 'SPM_files' filesep ...
                    'SPM_Sess_' num2str(idj) '_Cond_' num2str(trial.cond(idk)) '_Trial_' num2str(trial.number(idk)) '.mat']);

                % Save GLM_bactch.mat files
                parsave([paths{idi,1}(1:end-7) 'LSS_after_FIR_task_regression' filesep 'GLM_batches' filesep ...
                    'GLM_Sess_' num2str(idj) '_Cond_' num2str(trial.cond(idk)) '_Trial_' num2str(trial.number(idk)) '.mat'],batch{idk});

                % Remove temporal LSS directory
                rmdir([paths{idi,1}(1:end-7) 'LSS_Sess_' num2str(idj) '_Trial_' num2str(idk)],'s');

                status(idi,idj,idk) = 1;
            catch
                status(idi,idj,idk) = 0;
        end
    end




end



% Function to monitor the counting of the Parallel Loops
   function setter(X, Y, F)

        persistent count GDS; 

        if nargin == 3                                                      % Intialization in the first iteration
            count = 0;                                                      % Reset Count to zero
            GDS = Y;                                                        % Dummy variable to store elements in the start
            G = F;
        else
            count = count + 1;
            HLL = findobj('Tag','MAIN_WINDOWS');
            gLdata = guidata(HLL);
            set(gLdata.LSS_R_stat,"String", count+" Completed","ForegroundColor","#385723");
        end
  
   end

