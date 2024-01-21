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

SPM = load(tmfc.subjects(1).path);
XYZ  = SPM.SPM.xVol.XYZ;
iXYZ = cumprod([1,SPM.SPM.xVol.DIM(1:2)'])*XYZ - sum(cumprod(SPM.SPM.xVol.DIM(1:2)'));
hdr.dim = SPM.SPM.Vbeta(1).dim;
hdr.dt = SPM.SPM.Vbeta(1).dt;
hdr.pinfo = SPM.SPM.Vbeta(1).pinfo;
hdr.mat = SPM.SPM.Vbeta(1).mat;

% im1 = [1 1 1 1 1 1];
% im2 = [3 3 3 6 6 6];
% im3 = [10 10 10 2 2 2];
% im4 = [-50 -50 -50 -1 -1 -1];
% 
% c1 = [1 0 0 0];
% c2 = [0 1 0 0];
% c3 = [0 0 1 0];
% c4 = [0 0 0 1];
% c5 = [1 -1 0 0];
% c6 = [1 1 0 -1];
% c7 = [0.5 -0.5 0.5 -0.5];
% 
% images = [im1;im2;im3;im4];
% 
% con1 = c1*images;
% con2 = c2*images;
% con3 = c3*images;
% con4 = c4*images;
% con5 = c5*images;
% con6 = c6*images;
% con7 = c7*images;

% m1 = [inf 2 3; 1 inf 3; 1 2 inf];
% m2 = [inf 3 3; 6 inf 6; 9 9 inf];
% m3 = [inf 10 10; 2 inf 2; 0 0 inf];
% m4 = [inf -50 -50; -1 inf -1; -20 -20 inf];
% 
% R = 3;
% 
% matrices = [m1(:)';m2(:)';m3(:)';m4(:)'];
% 
% mcon1 = reshape(c1*matrices,[R,R]);
% mcon2 = reshape(c2*matrices,[R,R]);
% mcon3 = reshape(c3*matrices,[R,R]);
% mcon4 = reshape(c4*matrices,[R,R]);
% mcon5 = reshape(c5*matrices,[R,R]);
% mcon6 = reshape(c6*matrices,[R,R]);
% mcon7 = reshape(c7*matrices,[R,R]);
