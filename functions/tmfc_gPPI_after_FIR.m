function [sub_check] = tmfc_gPPI_after_FIR(tmfc,ROI_set,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Estimates gPPI GLMs. Saves individual connectivity matrices
% (ROI-to-ROI analysis) and connectivity images (seed-to-voxel analysis)
% for each condition of interest.
%
% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates psycho-physiological interactions (PPIs). Uses psychological
% regressors from the standard model. Uses physiological regressors 
% obtained via FIR model (residuals).
%
% FORMAT [sub_check] = tmfc_gPPI_after_FIR(tmfc)
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
% FORMAT [sub_check] = tmfc_gPPI_after_FIR(tmfc,ROI_set,start_sub)
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

