function [sub_check] = tmfc_FIR_regress(tmfc,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% FIR task regression task regression are used to remove co-activations 
% from BOLD time-series. Co-activations are simultaneous (de)activations 
% without communication between brain regions. 
%
% This function uses SPM.mat file (which contains the specification of the
% 1st-level GLM with canonical HRF) to specify and estimate 1st-level GLM
% with FIR basis functions. FIR model regress out: (1) co-activations with
% any possible hemodynamic response shape and (2) confounds specified in 
% the original SPM.mat file (e.g., motion, physiological noise, etc).
% Residual time-series (Res_*.nii images stored in FIR_GLM subfolders) can
% be further used for TMFC analysis to control for spurious inflation of
% functional connectivity estimates1 due to co-activations.
%
% FORMAT [sub_check] = FIR_regress(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path     - List of paths to SPM.mat files for N subjects
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.FIR_window        - FIR window length (in seconds)
%   tmfc.FIR_bins          - Number of FIR time bins
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^31 = 2GB (how much RAM can be used at
%                            the same time during GLM estimation)
%   tmfc.defaults.resmem   - true or false (store temporaty files during
%                            GLM estimation in RAM or on disk)
%
% FORMAT [sub_check] = FIR_regress(tmfc,start_sub)
% Run the function starting from a specific subject in the path list.
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
       SS1_FIR = findobj('Tag','MAIN_WINDOW');                    % Finding the GUI's object via the handle
       g6data = guidata(SS1_FIR);                                 % Creating a local refernce of the GUI's object 
       set(g6data.FIR_TR_stat,'String', 'Updating...','ForegroundColor',[0.772, 0.353, 0.067])       % Assigning the status to the TMFC variable
       set([g6data.SUB, g6data.FIR_TR, g6data.LSS_R, g6data.LSS_RW, g6data.BSC, g6data.gPPI, g6data.save_p, g6data.open_p, g6data.change_p, g6data.settings, g6data.BGFC],'Enable', 'off');
   end
end

spm('defaults','fmri');
spm_jobman('initcfg');

for i = start_sub:length(tmfc.subjects)
    
    SPM = load(tmfc.subjects(i).path);

    if isfolder([tmfc.project_path filesep 'FIR_regression' filesep 'Subject_' num2str(i,'%04.f')])
        rmdir([tmfc.project_path filesep 'FIR_regression' filesep 'Subject_' num2str(i,'%04.f')],'s');
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.dir = {[tmfc.project_path filesep 'FIR_regression' filesep 'Subject_' num2str(i,'%04.f')]};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = SPM.SPM.xBF.UNITS;
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = SPM.SPM.xY.RT;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = SPM.SPM.xBF.T;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = SPM.SPM.xBF.T0;
    
    for j = 1:length(SPM.SPM.Sess)
        
        % Functional images
        for image = 1:SPM.SPM.nscan(j)
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).scans{image,1} = SPM.SPM.xY.VY(SPM.SPM.Sess(j).row(image)).fname;
        end
        
        % Conditions
        for cond = 1:length(SPM.SPM.Sess(j).U)
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(cond).name = SPM.SPM.Sess(j).U(cond).name{1};
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(cond).onset = SPM.SPM.Sess(j).U(cond).ons;
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(cond).duration = SPM.SPM.Sess(j).U(cond).dur;
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(cond).tmod = 0;
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(cond).pmod = struct('name', {}, 'param', {}, 'poly', {});
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(cond).orth = 1;
        end
        
        % Confounds       
        for conf = 1:length(SPM.SPM.Sess(j).C.name)
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(conf).name = SPM.SPM.Sess(j).C.name{1,conf};
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(conf).val = SPM.SPM.Sess(j).C.C(:,conf);
        end
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).multi = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).multi_reg = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).hpf = SPM.SPM.xX.K(j).HParam;
    end

    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.fir.length = tmfc.FIR_window;
    matlabbatch{1}.spm.stats.fmri_spec.bases.fir.order = tmfc.FIR_bins;
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = SPM.SPM.xM.gMT;

    try
        matlabbatch{1}.spm.stats.fmri_spec.mask = {SPM.SPM.xM.VM.fname};
    catch
        matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    end

    matlabbatch{1}.spm.stats.fmri_spec.cvi = SPM.SPM.xVi.form;
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    batch{i} = matlabbatch;
    clear matlabbatch SPM; 
end


% Variable to Exit FIR regression during execution
EXIT_STATUS = 0;
FLAG_PAR = 0;


% Parallel or sequential computing
switch tmfc.defaults.parallel   
    
    % ------------------------ Parallel Computing ------------------------
    case 1
        
        % Creation of Waitbar Figure
        handles.wp = waitbar(0,'Please wait...','Name','FIR task regression', 'Tag', 'W_Parallel');       
        N = length(tmfc.subjects);                                          % Threshold of elements to run FIR regression
        D = parallel.pool.DataQueue;                                        % Creation of Parallel Pool 
        afterEach(D, @tmfc_parfor_waitbar);                                 % Command to update Waitbar
        tmfc_parfor_waitbar(handles.wp, N);                                 % Custom function to update waitbar
       
        cleanupObj = onCleanup(@cleanMeUp);

        disp('Processing... please wait');
        % Possible Addition: Condition to create parallel pool if not
        % running or non-existent (i.e disabled via preferences)
        % Parallel loop that creates Futures for result generation
        try
            DG = guidata(findobj('Tag', 'MAIN_WINDOW'));    
            set(DG.MAIN_F, 'Position', [0.18 0.26 0.205 0.575])
            figure(DG.MAIN_F);
        end
       
        parfor i = start_sub:N
            try
                spm('defaults','fmri');
                spm_jobman('initcfg');
                spm_get_defaults('cmdline',true);
                spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                spm_get_defaults('stats.fmri.ufp',1);
                spm_jobman('run',batch{i});
                tmfc_write_residuals([tmfc.project_path filesep 'FIR_regression' filesep 'Subject_' num2str(i,'%04.f') filesep 'SPM.mat'],NaN);
                tmfc_parsave([tmfc.project_path filesep 'FIR_regression' filesep 'Subject_' num2str(i,'%04.f') filesep 'GLM_batch.mat'],batch{i});
                sub_check(i) = 1;
            catch
                sub_check(i) = 0;
            end
            send(D,[]); 
            
            try 
                % Updating the TMFC GUI with the progress
                HBC_FIR = findobj('Tag','MAIN_WINDOW');                    % Finding the GUI's object via the handle
                g1data = guidata(HBC_FIR);                                 % Creating a local refernce of the GUI's object 
                set(g1data.FIR_TR_stat,'String', strcat(num2str(i), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       % Assigning the status to the TMFC variable
            end    
        end

        try                                                                 % Closing the Waitbar after Sucessful execution
            delete(handles.wp);
            FLAG_PAR = 1;
        end       
        
    % ----------------------- Sequential Computing ------------------------
    case 0
        
        % Creation of Waitbar Figure
        handles.ws = waitbar(0,'Please wait...','Name','FIR task regression','Tag', 'W_Serial', 'CreateCancelBtn', @quitter);
        N = length(tmfc.subjects);                                          % Threshold of elements to run FIR Regression

        % Serial Execution of FIR Regression
        for i = start_sub:N
            tic
            if EXIT_STATUS ~= 1                                             % IF Cancel/X button has NOT been pressed, then contiune execution
                
                try
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    spm_jobman('run', batch{i});
                    tmfc_write_residuals([tmfc.project_path filesep 'FIR_regression' filesep 'Subject_' num2str(i,'%04.f') filesep 'SPM.mat'],NaN);
                    tmfc_parsave([tmfc.project_path filesep 'FIR_regression' filesep 'Subject_' num2str(i,'%04.f') filesep 'GLM_batch.mat'],batch{i});
                    sub_check(i) = 1;
                catch
                    sub_check(i) = 0;
                end
            else
                waitbar(N,handles.ws,sprintf('Cancelling Operation'));      % Else condition if Cancel button is pressed
                delete(handles.ws);
                try                                                             % Updating the TMFC GUI window with the progress
                    HBC_FIR = findobj('Tag','MAIN_WINDOW');                        % Finding the GUI's object via handle
                    g1data = guidata(HBC_FIR);                                      % Creating a local reference of the GUI's object
                    set(g1data.FIR_TR_stat,'String', strcat(num2str(i-1), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);    % Assigning the status to the TMFC varaible
                end
                break;
            end
            
            try                                                             % Updating the TMFC GUI window with the progress
                HBC_FIR = findobj('Tag','MAIN_WINDOW');                        % Finding the GUI's object via handle
                g1data = guidata(HBC_FIR);                                      % Creating a local reference of the GUI's object
                set(g1data.FIR_TR_stat,'String', strcat(num2str(i), '/', num2str(N), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);    % Assigning the status to the TMFC varaible
            end
            
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';                  % Time calculation for the wait bar
            
            try
                waitbar(double(i)/double(N), handles.ws, [num2str(double(i)/double(N)*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']); % Updating the Wait bar
            end
        end
        
        try                                                                 % Closing the Waitbar after Sucessful execution
            delete(handles.ws);
        end
end

% Retriving the TMFC variable from the workspace 
FIR_E = evalin('base', 'tmfc');                                         % Creation of local copy
for k = start_sub:N                                                     % Updating the status of the FIR per subject
    FIR_E.subjects(k).FIR = sub_check(k);
end
assignin('base', 'tmfc', FIR_E);                                        % Assinging the Updated TMFC variable back to the Base workspace      

if FLAG_PAR == 1
    try
        % Find the last processed subject (i.e. not NaN)
        N_index = 0;
        SUB_EXT_3 = evalin('base', 'tmfc');
        DG = length(SUB_EXT_3.subjects);

        for i = 1:DG   
            if isnan(SUB_EXT_3.subjects(i).FIR) == 1
                N_index = i; % INDEX of last processed subject is found
                break;
            else
                N_index = DG;
            end 
        end
    end

    try 
        HBC_FIR = findobj('Tag','MAIN_WINDOW');                    % Finding the GUI's object via the handle
        g1data = guidata(HBC_FIR);                                 % Creating a local refernce of the GUI's object 
        set(g1data.FIR_TR_stat,'String', strcat(num2str(N_index), '/', num2str(N_index), ' done'), 'ForegroundColor',[0.219, 0.341, 0.137]);       % Assigning the status to the TMFC variable
    end
end


function quitter(~,~)                                              % Function that changes the state of execution when CANCEL is pressed
    EXIT_STATUS = 1;
end


function cleanMeUp()
    try
        h_FREZ_U = findobj('Tag','MAIN_WINDOW');
        FZ_data = guidata(h_FREZ_U); 
        set([FZ_data.SUB, FZ_data.FIR_TR, FZ_data.LSS_R, FZ_data.LSS_RW, FZ_data.BSC, FZ_data.gPPI, FZ_data.save_p, FZ_data.open_p, FZ_data.change_p, FZ_data.settings, FZ_data.BGFC],'Enable', 'on');
        delete(findall(0,'Tag', 'W_Parallel','type', 'Figure'));

        try                                                                 % Closing the Waitbar after Sucessful execution
            del_wp = findall(0,'type','figure','Tag', 'W_Parallel');
            delete(del_wp);
        end

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
