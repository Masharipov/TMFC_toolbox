function [sub_check] = tmfc_FIR_regress(tmfc,start_sub)

% FIR task regression task regression are used to remove co-activations 
% from BOLD time-series. Co-activations are simultaneous (de)activations 
% without communication between brain regions. 

% This function uses SPM.mat file (which contains the specification of the
% 1st-level GLM with canonical HRF) to specify and estimate 1st-level GLM
% with FIR basis functions. FIR model regress out: (1) co-activations with
% any possible hemodynamic response shape and (2) confounds specified in 
% the original SPM.mat file (e.g., motion, physiological noise, etc).
% Residual time-series (Res_*.nii images stored in FIR_GLM subfolders) can
% be further used for TMFC analysis to control for spurious inflation of
% functional connectivity estimates1 due to co-activations.

% FORMAT [sub_check] = FIR_regress(tmfc)
% Run a function starting from the first subject in the list
% tmfc.subjects(i).paths - List of paths to SPM.mat files for N subjects
% tmfc.FIR_window        - FIR window length (in seconds)
% tmfc.FIR_bins          - Number of FIR time bins
% tmfc.parallel          - 0 or 1 (sequential or parallel computing)

% FORMAT [sub_check] = FIR_regress(tmfc,start_sub)
% Run the function starting from a specific subject in the path list
% tmfc                   - As above
% start_sub              - Subject number on the path list to start with


%==========================================================================
% Ruslan Masharipov, october, 2023
% email: ruslan.s.masharipov@gmail.com

if nargin == 1
   start_sub = 1;
else
   %sub_check(1:length(tmfc.subjects)) = 0;
   if start_sub == 1
       sub_check = NaN(1, length(tmfc.subjects));
       %sub_check(1:start_sub-1) = 1;
   else
       sub_check = NaN(start_sub, length(tmfc.subjects));
       %sub_check(1:start_sub - 1) = 1;
   end
    SS1_FIR = findobj('Tag','MAIN_WINDOWS');                    % Finding the GUI's object via the handle
    g6data = guidata(SS1_FIR);                                  % Creating a local refernce of the GUI's object 
    set(g6data.FIR_TR_stat,"String", "Updating...","ForegroundColor","#C55A11")       % Assigning the status to the TMFC variable
end

spm('defaults','fmri');
spm_jobman('initcfg');


for i = start_sub:length(tmfc.subjects)
    
    SPM = load(tmfc.subjects(i).paths);

    cd(SPM.SPM.swd)

    if isfolder('FIR_GLM')
        rmdir('FIR_GLM','s');
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.dir = {[SPM.SPM.swd filesep 'FIR_GLM']};
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




% Switch case to select Parallel computing or Serial computing
switch tmfc.defaults.parallel
   
    
    
    % ------------------------ Parallel Computing ------------------------
    case 1
        
        % Creation of Waitbar Figure
        handles.wp = waitbar(0,'Please wait...','Name','FIR task regression', 'Tag', "W_Parallel",'CreateCancelBtn', @quitter);        
        N = length(tmfc.subjects);                                          % Threshold of elements to run FIR regression
        D = parallel.pool.DataQueue;                                        % Creation of Parallel Pool 
        afterEach(D, @tmfc_parfor_waitbar);                                      % Command to update Waitbar
        tmfc_parfor_waitbar(handles.wp, N);                                        % Custom function to update waitbar
       

        
        % Possible Addition: Condition to create parallel pool if not
        % running or non-existent (i.e disabled via preferences)
        % Parallel loop that creates Futures for result generation
        for i = start_sub:N
            f(i) = parfeval(@Worker, 1, tmfc, batch, i); 
            try % STOPs Minimimizing of the Window
            DG = guidata(findobj("Tag", "MAIN_WINDOWS"));
            set(DG.MAIN_F, "Position", [0.18 0.26 0.205 0.575])
            figure(DG.MAIN_F);
            end
        end
        disp("Processing... please wait");
        %try
            %disp("CHECK");
            %DG = guidata(findobj("Tag", "MAIN_WINDOWS"));    
            %set(DG.MAIN_F, "Position", [0.18 0.26 0.205 0.575])
            %figure(DG.MAIN_F);
            
%        end
        
        results = cell(N, 1);                                               % Variable to store results & assign to TMFC
        
        % Loop to fetch results using the parallel Pool
        for j = start_sub:N
            
            if EXIT_STATUS ~= 1                                             % If Cancel/X button has NOT been pressed, then continue execution
               
               [completedIdx, result] = fetchNext(f);                       % Fetching results 
               results{completedIdx} = result;
               %disp(result); % Printing results for temporary confirmation
               
                if results{completedIdx} == 1                               % Assigning Status of completion after execution of subject
                    sub_check(j) = 1;
                else
                    sub_check(j) = 0;
                end
                send(D,[]);                                                 % Variable for persistent count assigned to the TMFC variable in the end
                
                
                try                                                         % Updating the TMFC GUI with the progress
                HBC_FIR = findobj('Tag','MAIN_WINDOWS');                    % Finding the GUI's object via the handle
                g1data = guidata(HBC_FIR);                                  % Creating a local refernce of the GUI's object 
                set(g1data.FIR_TR_stat,"String", j+"/"+N+" done","ForegroundColor","#385723");       % Assigning the status to the TMFC variable
                end

               try 
                   waitbar(idx/N,handles.wp,sprintf('Subjects Processed: %d',idx)); % Updating the progress of the Wait bar
               end
                
            else                                                            
                waitbar(N,handles.wp,sprintf('Cancelling Operation'));      % Exit Case for Waitbar when breaking out of the loop via the Cancel/X button
                delete(handles.wp);                                         % Close(GUI) doesn't work here
                break;
            end
            
        end

        try                                                                 % Closing the Waitbar after Sucessful execution
        delete(handles.wp);
        end
    
        
        
        
        
    % ------------------------ Serial Computing ------------------------
    case 0
        
        % Creation of Waitbar Figure
        handles.ws = waitbar(0,'Please wait...','Name','FIR task regression',"Tag", "W_Serial", 'CreateCancelBtn', @quitter);
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
                    spm_jobman('run',batch{i});
                    tmfc_write_residuals([batch{i}{1}.spm.stats.fmri_spec.dir{1}  filesep 'SPM.mat'],NaN);
                    tmfc_parsave([batch{i}{1}.spm.stats.fmri_spec.dir{1}  filesep 'GLM_batch.mat'],batch{i});
                    sub_check(i) = 1;
                catch
                    sub_check(i) = 0;
                end
                
            else
                waitbar(N,handles.ws,sprintf('Cancelling Operation'));      % Else condition if Cancel button is pressed
                delete(handles.ws);
                try                                                             % Updating the TMFC GUI window with the progress
                    HBC_FIR = findobj('Tag','MAIN_WINDOWS');                        % Finding the GUI's object via handle
                    g1data = guidata(HBC_FIR);                                      % Creating a local reference of the GUI's object
                    set(g1data.FIR_TR_stat,"String", i-1+"/"+N+" done","ForegroundColor","#385723");    % Assigning the status to the TMFC varaible
                end
                break;
            end
            

            try                                                             % Updating the TMFC GUI window with the progress
            HBC_FIR = findobj('Tag','MAIN_WINDOWS');                        % Finding the GUI's object via handle
            g1data = guidata(HBC_FIR);                                      % Creating a local reference of the GUI's object
            set(g1data.FIR_TR_stat,"String", i+"/"+N+" done","ForegroundColor","#385723");    % Assigning the status to the TMFC varaible
            end
            
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';                  % Time calculation for the wait bar
            
            try
                waitbar(i/N,handles.ws,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']); % Updating the Wait bar
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
        
        
        
    function quitter(~,~)                                                   % Function that changes the state of execution when CANCEL is pressed
        EXIT_STATUS = 1;
    end

    
    % Function to perform parallel computing
    % The function returns the status of completion as either 1 or 0 
    function [status] = Worker(tmfc, batch, idx)
        try
            spm('defaults','fmri');
            spm_jobman('initcfg');
            spm_get_defaults('cmdline',true);
            spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
            spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
            spm_get_defaults('stats.fmri.ufp',1);
            spm_jobman('run', batch{idx});
            tmfc_write_residuals([batch{idx}{1}.spm.stats.fmri_spec.dir{1}  filesep 'SPM.mat'],NaN);
            tmfc_parsave([batch{idx}{1}.spm.stats.fmri_spec.dir{1}  filesep 'GLM_batch.mat'],batch{idx});
            status = 1;
        catch
            status = 0;
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
            HBC = findobj('Tag','MAIN_WINDOWS');
            g1data = guidata(HBC);
            set(g1data.FIR_TR_stat,"String", count+" Completed","ForegroundColor","#385723");
        end
  
   end
        
function tmfc_parsave(fname,matlabbatch)
  save(fname, 'matlabbatch')
end


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
            waitbar(count / N,h,[num2str(count/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
        end
    end
end

   
