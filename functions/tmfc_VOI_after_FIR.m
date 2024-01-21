function [sub_check] = tmfc_VOI_after_FIR(tmfc,ROI_set,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Extract time-series from volumes of interest (VOIs).
%
% FORMAT [sub_check] = tmfc_VOI_after_FIR(tmfc)
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