function [sub_check] = tmfc_BGFC(tmfc,ROI_set_number,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates background functional connectivity (BGFC).
% 
% Extracts residual time-series from volumes of interest (VOIs). Regresses
% out confounds and co-activations using FIR model. Applies whitening and
% high-pass filtering. Calculates Pearson's correlation between residual
% time-series. Converts Pearson's r to Fisher's Z.
%
% FORMAT [sub_check] = tmfc_BGFC(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path            - Paths to individual SPM.mat files
%   tmfc.project_path             - Path where all results will be saved
%   tmfc.defaults.parallel        - 0 or 1 (sequential/parallel computing)
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to the ROI images masked by group
%                                   mean binary mask 
%
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path_masked = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path_masked = 'C:\ROI_set\two_ROIs\ROI_2.nii';
%
% FORMAT [sub_check] = tmfc_BGFC(tmfc,ROI_set_number,start_sub)
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
SPM = load(tmfc.subjects(1).path);

% Initialize waitbar for parallel or sequential computing
switch tmfc.defaults.parallel
    case 0                                      % Sequential
        w = waitbar(0,'Please wait...','Name','Calculating residuals and BGFC');
    case 1                                      % Parallel
        w = waitbar(0,'Please wait...','Name','Calculating residuals and BGFC');
        D = parallel.pool.DataQueue;            % Creation of parallel pool 
        afterEach(D, @tmfc_parfor_waitbar);     % Command to update waitbar
        tmfc_parfor_waitbar(w,N);     
end

spm('defaults','fmri');
spm_jobman('initcfg');

if ~isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','ROI_to_ROI'))
    mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','ROI_to_ROI'));
end

for i = start_sub:N
    tic
    
    if isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs',['Subject_' num2str(i,'%04.f')]))
        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs',['Subject_' num2str(i,'%04.f')]),'s');
    end

    if ~isfolder(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs',['Subject_' num2str(i,'%04.f')]))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs',['Subject_' num2str(i,'%04.f')]));
    end

    for j = 1:length(SPM.SPM.Sess)
        for k = 1:R
            matlabbatch{1}.spm.util.voi.spmmat = {fullfile(tmfc.project_path,'FIR_regression',['Subject_' num2str(i,'%04.f')],'SPM.mat')};
            matlabbatch{1}.spm.util.voi.adjust = NaN; % Adjust for everything 
            matlabbatch{1}.spm.util.voi.session = j;
            matlabbatch{1}.spm.util.voi.name = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs', ... 
                ['Subject_' num2str(i,'%04.f')],tmfc.ROI_set(ROI_set_number).ROIs(k).name);
            matlabbatch{1}.spm.util.voi.roi{1}.mask.image = {tmfc.ROI_set(ROI_set_number).ROIs(k).path_masked};
            matlabbatch{1}.spm.util.voi.roi{1}.mask.threshold = 0.1;
            matlabbatch{1}.spm.util.voi.expression = 'i1';           
            batch{k} = matlabbatch;
            clear matlabbatch
        end
        
        switch tmfc.defaults.parallel
            case 0                              % Sequential
                for k = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_jobman('run',batch{k});
                end
                
            case 1                              % Parallel
                parfor k = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_jobman('run',batch{k});
                end
        end

        clear batch
    end

    % Calculate BGFC matrix
    for j = 1:length(SPM.SPM.Sess)
        for k = 1:R
            VOI = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs', ... 
                ['Subject_' num2str(i,'%04.f')],['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(k).name '_' num2str(j) '.mat']));
            Y(:,k) = VOI.Y; 
            clear VOI
        end
        z_matrix = atanh(corr(Y));
        z_matrix(1:size(z_matrix,1)+1:end) = nan;
        save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','ROI_to_ROI', ... 
                ['Subject_' num2str(i,'%04.f') '_Session_' num2str(j) '.mat']),'z_matrix');
        clear VOI z_matrix  
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