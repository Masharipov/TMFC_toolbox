function [thresholded,pval,tval,conval] = tmfc_ttest(matrices,contrast,alpha,correction)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performes one-sample and paired-sample t-test for symmetrical
% connectivity matrices.
%
% FORMAT [thresholded,pval,tval,conval] = tmfc_ttest(matrices,contrast,alpha,correction)
%
% INPUTS:
%
% matrices    - functional connectivity matrices
%
%            1) one-sample: 3-D array (ROI x ROI x Subjects)
%
%            2) paired-sample (cell array):
%               matrices{1} - 1st measure, 3-D array (ROI x ROI x Subjects)
%               matrices{2} - 2nd measure, 3-D array (ROI x ROI x Subjects)
%
% contrast    - contrast weight
% alpha       - alpha level
% correction  - correction for multiple comparisons:
%               'uncorr' - uncorrected
%               'FDR'    - False Discovery Rate correction (BH procedure)
%               'Bonf'   - Bonferroni correction
%
% OUTPUTS:
%
% thresholded - thresholded binary matrix 
%               (1 - significant connection, 0 - n.s.)
% pval        - uncorrected p-value matrix
% tval        - t-value matrix
% conval      - group mean contrast value 
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

if iscell(matrices)
    matrices = contrast(1)*matrices{1} + contrast(2)*matrices{2};
else
    matrices = contrast.*matrices;
end

nROI = size(matrices,1);
conval = mean(matrices,3);

for iROI = 1:nROI
    for jROI = iROI+1:nROI
        [~,pval(iROI,jROI),~,stat] = ttest(shiftdim(matrices(iROI,jROI,:)),[],'tail','right');
        tval(iROI,jROI) = stat.tstat;
        pval(jROI,iROI) = pval(iROI,jROI);
        tval(jROI,iROI) = tval(iROI,jROI);
    end
end

switch correction
    case 'uncorr'
        thresholded = double(pval<alpha);
        thresholded(1:1+nROI:end) = 0;

    case 'FDR'
        [alpha_FDR] = FDR(lower_triangle(pval),alpha);
        thresholded = double(pval<alpha_FDR);
        thresholded(1:1+nROI:end) = 0;

    case 'Bonf'
        alpha_Bonf = alpha/(nROI*(nROI-1)/2);
        thresholded = double(pval<alpha_Bonf);
        thresholded(1:1+nROI:end) = 0;

    otherwise
        thresholded = [];
        pval = [];
        tval = [];
        conval = [];
        warning('Work in progress. Please wait for future updates');
end
end

function low = lower_triangle(matrix)

matrix(1:1+size(matrix,1):end) = NaN;
low = matrix(tril(true(size(matrix)))).';
low(isnan(low)) = [];

end

function [pID] = FDR(p,q)

p = p(isfinite(p));
p = sort(p(:));
V = length(p);
I = (1:V)';
cVID = 1;

pID = p(max(find(p<=I/V*q/cVID)));
if isempty(pID), pID=0; end

end