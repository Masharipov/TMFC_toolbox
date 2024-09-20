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
    start_sub = 1;
end

% Update main TMFC GUI 
try              
    main_GUI = guidata(findobj('Tag','TMFC_GUI'));                           
    set(main_GUI.TMFC_GUI_S8,'String', 'Updating...','ForegroundColor',[0.772, 0.353, 0.067]);       
end

spm('defaults','fmri');
spm_jobman('initcfg');

nSub = length(tmfc.subjects);

for iSub = start_sub:nSub
    
    SPM = load(tmfc.subjects(iSub).path);

    if isdir(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(iSub,'%04.f')]))
        rmdir(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(iSub,'%04.f')]),'s');
    end
    
    mkdir(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(iSub,'%04.f')]));
    matlabbatch{1}.spm.stats.fmri_spec.dir = {fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(iSub,'%04.f')])};
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
    
    if strcmp(SPM.SPM.xVi.form,'i.i.d')
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'None';
    elseif strcmp(SPM.SPM.xVi.form,'AR(0.2)')
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    else
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'FAST';
    end

    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = {fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(iSub,'%04.f')],'SPM.mat')};
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    batch{iSub} = matlabbatch;
    clear matlabbatch SPM; 
end

% Sequential or parallel computing
switch tmfc.defaults.parallel
    % ----------------------- Sequential Computing ------------------------
    case 0
        % Variable to Exit FIR regression during execution
        exit_status = 0;
        
        % Creation of Waitbar Figure
        w = waitbar(0,'Please wait...','Name','FIR task regression','Tag', 'tmfc_waitbar');                                   
        cleanupObj = onCleanup(@cleanMeUp);
        
        % Serial Execution of FIR Regression
        for iSub = start_sub:nSub   
            tic
            if exit_status ~= 1   % IF Cancel/X button has NOT been pressed, contiune execution   
                try
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_get_defaults('stats.fmri.ufp',1);
                    spm_jobman('run', batch{iSub});
                    tmfc_write_residuals(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(iSub,'%04.f')],'SPM.mat'),NaN);
                    tmfc_parsave(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(iSub,'%04.f')],'GLM_batch.mat'),batch{iSub});
                    sub_check(iSub) = 1;
                catch
                    sub_check(iSub) = 0;
                end
            else
                waitbar(nSub,w,sprintf('Cancelling Operation'));      % Else condition if Cancel button is pressed
                delete(w);
                
                try  % Updating the TMFC GUI window with the progress
                    main_GUI = guidata(findobj('Tag','TMFC_GUI'));          
                    set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(iSub-1), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);    
                end

                break;
            end
            
            try  % Updating the TMFC GUI window with the progress                      
                main_GUI = guidata(findobj('Tag','TMFC_GUI'));                                 
                set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(iSub), '/', num2str(nSub), ' done'), 'ForegroundColor', [0.219, 0.341, 0.137]);    
            end
            
            % Update waitbar
            hms = fix(mod(((nSub-iSub)*toc/iSub), [0, 3600, 60]) ./ [3600, 60, 1]);
            try
                waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
            end
        end
        
        try                                                                
            delete(w);
        end
    
    % ------------------------ Parallel Computing -------------------------
    case 1
        try % Waitbar for MATLAB R2017a and higher
            D = parallel.pool.DataQueue;            % Creation of parallel pool 
            w = waitbar(0,'Please wait...','Name','FIR task regression','Tag','tmfc_waitbar');
            afterEach(D, @tmfc_parfor_waitbar);     % Command to update waitbar
            tmfc_parfor_waitbar(w,nSub);     
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
        
        cleanupObj = onCleanup(@cleanMeUp);
        
        disp('Processing... please wait');

        try % Bring TMFC main window to the front 
            figure(findobj('Tag','TMFC_GUI'));
        end

        % Parallel Loop
        parfor iSub = start_sub:nSub
            try
                spm('defaults','fmri');
                spm_jobman('initcfg');
                spm_get_defaults('cmdline',true);
                spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                spm_get_defaults('stats.fmri.ufp',1);
                spm_jobman('run',batch{iSub});
                tmfc_write_residuals(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(iSub,'%04.f')],'SPM.mat'),NaN);
                tmfc_parsave(fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(iSub,'%04.f')],'GLM_batch.mat'),batch{iSub});
                sub_check(iSub) = 1;
            catch
                sub_check(iSub) = 0;
            end
            try
                send(D,[]); 
            end
            try 
                % Updating the TMFC GUI with the progress (within the loop)                
                main_GUI = guidata(findobj('Tag','TMFC_GUI'));                             
                set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(iSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
            end    
        end
        
        try
            % Updating the TMFC GUI with the progress (after loop completion)               
            main_GUI = guidata(findobj('Tag','TMFC_GUI'));                                 
            set(main_GUI.TMFC_GUI_S8,'String', strcat(num2str(nSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);       
        end 

        % Closing the Waitbar after execution
        try                                                                
            delete(w);
        end
        
end

% Function that changes the state of execution when CANCEL is pressed
function quitter(~,~)                                              
    exit_status = 1;
end
 
function cleanMeUp()
    try
        GUI = guidata(findobj('Tag','TMFC_GUI')); 
        set([GUI.TMFC_GUI_B1, GUI.TMFC_GUI_B2, GUI.TMFC_GUI_B3, GUI.TMFC_GUI_B4,...
           GUI.TMFC_GUI_B5a, GUI.TMFC_GUI_B5b, GUI.TMFC_GUI_B6, GUI.TMFC_GUI_B7,...
           GUI.TMFC_GUI_B8, GUI.TMFC_GUI_B9, GUI.TMFC_GUI_B10, GUI.TMFC_GUI_B11,...
           GUI.TMFC_GUI_B12a,GUI.TMFC_GUI_B12b,GUI.TMFC_GUI_B13a,GUI.TMFC_GUI_B13b,...
           GUI.TMFC_GUI_B14a, GUI.TMFC_GUI_B14b], 'Enable', 'on');
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
    persistent count h nSub start

    if nargin == 2
        count = 0;
        h = waitbarHandle;
        nSub = iterations;
        start = tic;
        
    else
        if isvalid(h)         
            count = count + 1;
            time = toc(start);
            hms = fix(mod(((nSub-count)*time/count), [0, 3600, 60]) ./ [3600, 60, 1]);
            waitbar(count/nSub, h, [num2str(count/nSub*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
        end
    end
end
