function [thresholded,pval,tval,conval] = tmfc_ttest2(matrices,contrast,alpha,correction)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs two-sample t-test for symmetric connectivity matrices.
% Assumes unequal variances (Welch's t-test).
%
% FORMAT [thresholded,pval,tval,conval] = tmfc_ttest2(matrices,contrast,alpha,correction)
%
% INPUTS:
%
% matrices    - functional connectivity matrices (cell array):
%               matrices{1} - 1st group, 3-D array (ROI x ROI x Subjects)
%               matrices{2} - 2nd group, 3-D array (ROI x ROI x Subjects)    
% contrast    - contrast weight(s)
% alpha       - alpha level
% correction  - correction for multiple comparisons:
%               'uncorr' - uncorrected
%               'FDR'    - False Discovery Rate correction (BH procedure)
%               'Bonf'   - Bonferroni correction
%
% OUTPUTS:
%
% thresholded - thresholded binary matrix 
%               (1 = significant connection, 0 = not significant)
% pval        - uncorrected p-value matrix
% tval        - t-value matrix
% conval      - group mean contrast value 
%
% =========================================================================
% Copyright (C) 2025 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if ~iscell(matrices) || numel(matrices) ~= 2
    error('Input "matrices" must be a 1x2 cell array for two-sample t-test.');
end

if numel(contrast) ~= 2
    error('Input "contrast" must contain exactly two weights.');
end

group1 = matrices{1};
group2 = matrices{2};

nROI = size(group1,1);

if size(group1,1) ~= size(group1,2) || size(group2,1) ~= size(group2,2)
    error('Connectivity matrices must be square.');
end

if size(group1,1) ~= size(group2,1)
    error('Group 1 and Group 2 matrices must have the same number of ROIs.');
end

if ~(isequal(contrast,[1 -1]) || isequal(contrast,[-1 1]))
    error('For two-sample tests, contrast must be [1 -1] or [-1 1].');
end

pval = ones(nROI);
tval = zeros(nROI);

conval = contrast(1)*mean(group1,3) + contrast(2)*mean(group2,3);

% Contrast defines direction only:
% [1 -1]  -> test group1 > group2
% [-1 1]  -> test group2 > group1
if contrast(1) > contrast(2)
    first_group  = group1;
    second_group = group2;
elseif contrast(1) < contrast(2)
    first_group  = group2;
    second_group = group1;
else
    error('Two-sample contrast weights must define direction, e.g. [1 -1] or [-1 1].');
end

for iROI = 1:nROI
    for jROI = iROI+1:nROI
        [pval(iROI,jROI), tval(iROI,jROI)] = tmfc_twosample_ttest( ...
            shiftdim(first_group(iROI,jROI,:)), ...
            shiftdim(second_group(iROI,jROI,:))); % Assume unequal variances

        pval(jROI,iROI) = pval(iROI,jROI);
        tval(jROI,iROI) = tval(iROI,jROI);
    end
end

switch correction
    case 'uncorr'
        thresholded = double(pval<alpha);
        thresholded(1:1+nROI:end) = 0;

    case 'FDR'
        alpha_FDR = FDR(lower_triangle(pval),alpha);
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
        warning('Unsupported correction type for tmfc_ttest2.');    
end
end

%--------------------------------------------------------------------------
function low = lower_triangle(matrix)

matrix(1:1+size(matrix,1):end) = NaN;
low = matrix(tril(true(size(matrix)))).';
low(isnan(low)) = [];

end

%--------------------------------------------------------------------------
function [pID] = FDR(p,q)

p = p(isfinite(p));
p = sort(p(:));
V = length(p);
I = (1:V)';
cVID = 1;

pID = p(max(find(p<=I/V*q/cVID)));
if isempty(pID), pID = 0; end

end

%--------------------------------------------------------------------------
function [p, tval] = tmfc_twosample_ttest(X, Y)
% Two-sample (independent) right-tailed t-test.
% Assumes unequal variances (Welch's t-test)

if size(X,2) ~= size(Y,2)
    error('X and Y must have the same number of columns (variables).');
end

nX = size(X,1);
nY = size(Y,1);

% Means and variances
mx = mean(X,1);
my = mean(Y,1);
vx = var(X,0,1);
vy = var(Y,0,1);

% Welch's t-statistic
tval = (mx - my) ./ sqrt(vx./nX + vy./nY);

% Welch-Satterthwaite df
df = (vx./nX + vy./nY).^2 ./ ...
    ((vx.^2)./(nX^2*(nX-1)) + (vy.^2)./(nY^2*(nY-1)));

% Right-tailed p-value
p = 1 - tmfc_tcdf(tval, df);

end