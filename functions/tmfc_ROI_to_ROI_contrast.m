function [sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,con,ROI_set)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates linear contrasts of FC matrices.
%
% FORMAT [sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,con)
%
%   type                   - TMFC analysis type
%                            1: BSC-LSS after FIR
%                            2: BSC-LSS without FIR
%                            3: gPPI after FIR
%                            4: gPPI without FIR
%
%   con                    - Numbers of contrasts to compute (see tmfc)
%    
%   tmfc.subjects.path     - List of paths to SPM.mat files for N subjects
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.ROI_set           - List of selected ROIs
%   tmfc.ROI_set.set_name  - Name of the ROI set
%   tmfc.ROI_set.ROIs.name - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path - Path to the selected ROI image
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
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path = 'C:\ROI_set\two_ROIs\ROI_2.nii';                             
%
% FORMAT [sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,con,ROI_set)
% Run the function for the selected ROI set
%
%   tmfc                   - As above
%   ROI_set                - Number of the ROI set in the tmfc structure
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


if nargin < 4
   ROI_set = 1;
end

w = waitbar(0,'Please wait...','Name','Compute contrasts');
N = length(tmfc.subjects);
R = length(tmfc.ROI_set(ROI_set).ROIs);

switch type
    case 1
        for i = 1:N
            tic
            % Load default contrasts for conditions of interest
            for j = 1:length(tmfc.LSS_after_FIR.conditions)
                load([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep ...
                    'ROI_to_ROI' filesep 'Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') ...
                    '_Sess_' num2str(tmfc.LSS_after_FIR.conditions(j).sess) '_Cond_' num2str(tmfc.LSS_after_FIR.conditions(j).number) '.mat']);
                matrices(j,:) = z_matrix(:)';
                clear z_matrix
            end
            % Calculate and save contrasts
            for j = 1:length(con)
                z_matrix = reshape(tmfc.ROI_set(ROI_set).contrasts.BSC_after_FIR(con(j)).weights*matrices,[R,R]);
                save([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep ...
                    'ROI_to_ROI' filesep 'Subject_' num2str(i,'%04.f') '_Contrast_' num2str(con(j),'%04.f') ...
                    '_' tmfc.ROI_set(ROI_set).contrasts.BSC_after_FIR(con(j)).title '.mat'],'z_matrix');
                clear z_matrix
            end
            % Update waitbar
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
            try
                waitbar(i/N,w,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
            end       
            sub_check(i) = 1;
            clear matrices
        end
        % Close waitbar
        try
            delete(w)
        end
end
