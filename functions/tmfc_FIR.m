function [sub_check] = tmfc_FIR(tmfc,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Estimates FIR GLM and saves residual time-series images in Float32 format
% instead of Float64 to save disk space and reduce computation time.
%
% FIR task regression task regression are used to remove co-activations 
% from BOLD time-series. Co-activations are simultaneous (de)activations 
% without communication between brain regions. 
%
% This function uses SPM.mat file (which contains the specification of the
% 1st-level GLM) to specify and estimate 1st-level GLM with FIR basis
% functions.
% 
% FIR model regress out: (1) co-activations with any possible hemodynamic
% response shape and (2) confounds specified in the original SPM.mat file
% (e.g., motion, physiological noise, etc).
%
% Residual time-series (Res_*.nii images stored in FIR_regression folder)
% can be further used for FC analysis to control for spurious inflation of
% FC estimates due to co-activations. TMFC toolbox uses residual images in
% two cases: (1) to calculate background connectivity (BGFC), (2) to
% calculate LSS GLMs after FIR regression and use them for BSC after FIR.
%
% FORMAT [sub_check] = FIR_regress(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path     - Paths to individual SPM.mat files
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^31 = 2GB (how much RAM can be used at
%                            the same time during GLM estimation)
%   tmfc.defaults.resmem   - true or false (store temporaty files during
%                            GLM estimation in RAM or on disk)
%   tmfc.FIR.window        - FIR window length (in seconds)
%   tmfc.FIR.bins          - Number of FIR time bins
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
% else
%     % Initialize sub_check 
%     if start_sub == 1
%        sub_check = NaN(length(tmfc.subjects),1);
%     else
%        sub_check = NaN(length(tmfc.subjects),1);
%        sub_check(1:start_sub) = 1;
%     end   
end

% Updating Main GUI 
try              
    main_GUI = guidata(findobj('Tag','TMFC_GUI'));                           
    set(main_GUI.TMFC_GUI_S8,'String', 'Updating...','ForegroundColor',[0.772, 0.353, 0.067]);       
end

spm('defaults','fmri');
spm_jobman('initcfg');

for i = start_sub:length(tmfc.subjects)
    
    SPM = load(tmfc.subjects(i).path);

    if isfolder(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(i,'%04.f')]))
        rmdir(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(i,'%04.f')]),'s');
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.dir = {fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(i,'%04.f')])};
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
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(cond).duration = 0;
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
    matlabbatch{1}.spm.stats.fmri_spec.bases.fir.length = tmfc.FIR.window;
    matlabbatch{1}.spm.stats.fmri_spec.bases.fir.order = tmfc.FIR.bins;
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = SPM.SPM.xGX.iGXcalc;
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

% Parallel or sequential computing
switch tmfc.defaults.parallel
    % ----------------------- Sequential Computing ------------------------
    case 0
        % Variable to Exit FIR regression during execution
        exit_status = 0;
        
        % Creation of Waitbar Figure
        handles = waitbar(0,'Please wait...','Name','FIR task regression','Tag', 'tmfc_waitbar', CloseRequestFcn = '');
        N = length(tmfc.subjects);                                          
        cleanupObj = onCleanup(@cleanMeUp);
        
        % Serial Execution of FIR Regression
        for i = start_sub:N   
            tic
            if exit_status ~= 1   % IF Cancel/X button has NOT been pressed, contiune execution
                
                try
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    spm_jobman('run', batch{i});
                    tmfc_write_residuals(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(i,'%04.f')],'SPM.mat'),NaN);
                    tmfc_parsave(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(i,'%04.f')],'GLM_batch.mat'),batch{i});
                    sub_check(i) = 1;
                catch
                    sub_check(i) = 0;
                end
            else
                waitbar(N,handles,sprintf('Cancelling Operation'));      % Else condition if Cancel button is pressed
                delete(handles);
                
                try  % Updating the TMFC GUI window with the progress
                    main_GUI = guidata(findobj('Tag','TMFC_GUI'));          
                    set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(i-1), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);    
                end

                break;
            end
            
            try  % Updating the TMFC GUI window with the progress                      
                main_GUI = guidata(findobj('Tag','TMFC_GUI'));                                 
                set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(i), '/', num2str(N), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);    
            end
            
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss'; % Time calculation for the wait bar
            
            try
                % Updating the Wait bar
                waitbar(double(i)/double(N), handles, [num2str(double(i)/double(N)*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
            end
        end
        
        try                                                                
            delete(handles);
        end
    
    % ------------------------ Parallel Computing -------------------------
    case 1
        
        % Creation of Waitbar Figure
        handles = waitbar(0,'Please wait...','Name','FIR task regression', 'Tag', 'tmfc_waitbar');       
        N = length(tmfc.subjects);             % Threshold of elements to run FIR regression
        D = parallel.pool.DataQueue;           % Creation of Parallel Pool 
        afterEach(D, @tmfc_parfor_waitbar);    % Command to update Waitbar
        tmfc_parfor_waitbar(handles, N);    % Custom function to update waitbar
       
        cleanupObj = onCleanup(@cleanMeUp);    % Initialize Ctrl + C action

        disp('Processing... please wait');
        
        try % Bring TMFC main window to the front 
            main_GUI = guidata(findobj('Tag','TMFC_GUI'));    
            set(main_GUI.TMFC_GUI, 'Position',  [0.115 0.0875 0.250 0.850])
            figure(main_GUI.TMFC_GUI);
        end
       
        % Parallel Loop
        parfor i = start_sub:N
            try
                spm('defaults','fmri');
                spm_jobman('initcfg');
                spm_get_defaults('cmdline',true);
                spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                spm_get_defaults('stats.fmri.ufp',1);
                spm_jobman('run',batch{i});
                tmfc_write_residuals(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(i,'%04.f')],'SPM.mat'),NaN);
                tmfc_parsave(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(i,'%04.f')],'GLM_batch.mat'),batch{i});
                sub_check(i) = 1;
            catch
                sub_check(i) = 0;
            end
            send(D,[]); 
            
            try 
                % Updating the TMFC GUI with the progress (within the loop)                
                main_GUI = guidata(findobj('Tag','TMFC_GUI'));                             
                set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(i), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end    
        end
        
        try
            % Updating the TMFC GUI with the progress (after loop completion)               
            main_GUI = guidata(findobj('Tag','TMFC_GUI'));                                 
            set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(N), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
        end 
        
        % Closing the Waitbar after execution
        try                                                                
            delete(handles);
        end              
end

% Function that changes the state of execution when CANCEL is pressed
function quitter(~,~)                                              
    exit_status = 1;
end

% CTRL + C breakout function 
function cleanMeUp()
    try
        GUI = guidata(findobj('Tag','TMFC_GUI')); 
        set([GUI.TMFC_GUI_B1, GUI.TMFC_GUI_B2, GUI.TMFC_GUI_B3, GUI.TMFC_GUI_B4,...
            GUI.TMFC_GUI_B5a, GUI.TMFC_GUI_B5b, GUI.TMFC_GUI_B6, GUI.TMFC_GUI_B7,...
            GUI.TMFC_GUI_B8, GUI.TMFC_GUI_B9, GUI.TMFC_GUI_B10, GUI.TMFC_GUI_B11,...
            GUI.TMFC_GUI_B12,GUI.TMFC_GUI_B13a,GUI.TMFC_GUI_B13b,GUI.TMFC_GUI_B14a...
            GUI.TMFC_GUI_B14b], 'Enable', 'on');
        delete(findall(0,'Tag', 'tmfc_waitbar','type', 'Figure'));
    end    
    try                                                                 
        delete(findall(0,'type','figure','Tag', 'tmfc_waitbar'));
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
