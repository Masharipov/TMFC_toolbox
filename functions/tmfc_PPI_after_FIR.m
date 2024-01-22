function [sub_check] = tmfc_PPI_after_FIR(tmfc,ROI_set,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates psycho-physiological interactions (PPIs). Uses psychological
% regressors from the standard model. Uses physiological regressors 
% obtained via FIR model (residuals).
%
% FORMAT [sub_check] = tmfc_PPI_after_FIR(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path     - List of paths to SPM.mat files for N subjects
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.defaults.maxmem   - e.g. 2^31 = 2GB (how much RAM can be used)
%   tmfc.defaults.resmem   - true or false (store temporaty files in RAM)
%
%   tmfc.ROI_set           - List of selected ROIs
%   tmfc.ROI_set.set_name  - Name of the ROI set
%   tmfc.ROI_set.ROIs.name - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path - Path to the selected ROI image
%
%   tmfc.gPPI_after_FIR.conditions        - List of conditions of interest
%   tmfc.gPPI_after_FIR.conditions.sess   - Session number
%                                          (as specified in SPM.Sess)
%   tmfc.gPPI_after_FIR.conditions.number - Condition number
%                                          (as specified in SPM.Sess.U)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified:
%
%   tmfc.gPPI_after_FIR.conditions(1).sess   = 1;   
%   tmfc.gPPI_after_FIR.conditions(1).number = 1; - "Cond A", 1st session
%   tmfc.gPPI_after_FIR.conditions(2).sess   = 1;
%   tmfc.gPPI_after_FIR.conditions(2).number = 2; - "Cond B", 1st session
%   tmfc.gPPI_after_FIR.conditions(3).sess   = 2;
%   tmfc.gPPI_after_FIR.conditions(3).number = 1; - "Cond A", 2nd session
%   tmfc.gPPI_after_FIR.conditions(4).sess   = 2;
%   tmfc.gPPI_after_FIR.conditions(4).number = 2; - "Cond B", 2nd session
%
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path = 'C:\ROI_set\two_ROIs\ROI_2.nii';
%
% FORMAT [sub_check] = tmfc_PPI_after_FIR(tmfc,ROI_set,start_sub)
% Run the function starting from a specific subject in the path list for
% the selected ROI set.
%
%   tmfc                   - As above
%   ROI_set                - Number of the ROI set in the tmfc structure
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
   ROI_set = 1;
   start_sub = 1;
elseif nargin == 2
   start_sub = 1;
end

N = length(tmfc.subjects);
R = length(tmfc.ROI_set(ROI_set).ROIs);

if isfolder([tmfc.project_path filesep 'gPPI_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name])
    rmdir([tmfc.project_path filesep 'gPPI_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name],'s');
end

if ~isfolder([tmfc.project_path filesep 'gPPI_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name])
    for ROI_number = 1:R
        mkdir([tmfc.project_path filesep 'gPPI_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep ...
                'PPIs' filesep tmfc.ROI_set(ROI_set).ROIs(ROI_number).name]);
    end
end

% Initialize waitbar for parallel or sequential computing
switch tmfc.defaults.parallel
    case 0                                      % Sequential
        w = waitbar(0,'Please wait...','Name','PPI regressors calculation');
    case 1                                      % Parallel
        w = waitbar(0,'Please wait...','Name','PPI regressors calculation');
        D = parallel.pool.DataQueue;            % Creation of parallel pool 
        afterEach(D, @tmfc_parfor_waitbar);     % Command to update waitbar
        tmfc_parfor_waitbar(w,N);     
end

for i = start_sub:N
    SPM = load(tmfc.subjects(i).path);
    tic
    % Conditions of interest
    for j = 1:length(tmfc.gPPI_after_FIR.conditions)
        for k = 1:R
            matlabbatch{1}.spm.stats.ppi.spmmat = {tmfc.subjects(i).path};
            matlabbatch{1}.spm.stats.ppi.type.ppi.voi = {[tmfc.project_path filesep 'FIR_regression' filesep 'Subject_' num2str(i,'%04.f') filesep ...
                'VOI_' tmfc.ROI_set(ROI_set).set_name '_' tmfc.ROI_set(ROI_set).ROIs(k).name '_' num2str(tmfc.gPPI_after_FIR.conditions(j).sess) '.mat']};
            matlabbatch{1}.spm.stats.ppi.type.ppi.u = [tmfc.gPPI_after_FIR.conditions(j).number 1 1];
            matlabbatch{1}.spm.stats.ppi.name = ['Sess_' num2str(tmfc.gPPI_after_FIR.conditions(j).sess) '_Cond_' num2str(tmfc.gPPI_after_FIR.conditions(j).number) ...
                '_' num2str(tmfc.ROI_set(ROI_set).ROIs(k).name)];
            matlabbatch{1}.spm.stats.ppi.disp = 0;
            batch{k} = matlabbatch;
            clear matlabbatch
        end
        
        switch tmfc.defaults.parallel
            case 0                              % Sequential
                for k = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_jobman('run',batch{k});
                    movefile([SPM.SPM.swd filesep 'PPI_Sess_' num2str(tmfc.gPPI_after_FIR.conditions(j).sess) '_Cond_' ...
                        num2str(tmfc.gPPI_after_FIR.conditions(j).number) '_' num2str(tmfc.ROI_set(ROI_set).ROIs(k).name) '.mat'],...
                        [tmfc.project_path filesep 'gPPI_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep ...
                        'PPIs' filesep tmfc.ROI_set(ROI_set).ROIs(k).name filesep 'Subject_' num2str(i,'%04.f') '_PPI_Sess_' ...
                        num2str(tmfc.gPPI_after_FIR.conditions(j).sess) '_Cond_' num2str(tmfc.gPPI_after_FIR.conditions(j).number) '.mat']);
                end
                
            case 1                              % Parallel
                parfor k = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_get_defaults('stats.resmem',tmfc.defaults.resmem);
                    spm_get_defaults('stats.maxmem',tmfc.defaults.maxmem);
                    spm_jobman('run',batch{k});
                    movefile([SPM.SPM.swd filesep 'PPI_Sess_' num2str(tmfc.gPPI_after_FIR.conditions(j).sess) '_Cond_' ...
                        num2str(tmfc.gPPI_after_FIR.conditions(j).number) '_' num2str(tmfc.ROI_set(ROI_set).ROIs(k).name) '.mat'],...
                        [tmfc.project_path filesep 'gPPI_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep ...
                        'PPIs' filesep tmfc.ROI_set(ROI_set).ROIs(k).name filesep 'Subject_' num2str(i,'%04.f') '_PPI_Sess_' ...
                        num2str(tmfc.gPPI_after_FIR.conditions(j).sess) '_Cond_' num2str(tmfc.gPPI_after_FIR.conditions(j).number) '.mat']);
                end
        end

        clear batch
    end
    
    clear SPM
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