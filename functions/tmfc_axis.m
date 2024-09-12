function min_max_ax = tmfc_axis(matrix,type)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Defines colobar limits. The color scale will be adjusted based on the
% maximum absolute value and are assured to be positive and negative symmetrical.
%
% min_max_ax = tmfc_axis(matrix,type)
%
% matrix      - connectivity matrix
% type        - defines output:
%               1: [-max_ax max_ax]
%               0: [-max_ax 0 max_ax]
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

matrix(1:1+size(matrix,1):end) = NaN;
max_ax = roundf(max(max(abs(matrix))));

if type == 1
    min_max_ax = [-max_ax max_ax];
elseif type == 0   
    min_max_ax = [-max_ax 0 max_ax];
end
    
end

function y = roundf(x)
y = round(x*10000)/10000;
end