function [thresholded,pval,tval,conval] = tmfc_glm(matrices,design,contrast,alpha,correction)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs classical GLM-based edgewise inference for symmetric
% connectivity matrices using a single t-contrast.
%
% FORMAT
% [thresholded,pval,tval,conval] = tmfc_glm(matrices,design,contrast,alpha,correction)
%
% INPUTS:
%
% matrices    - functional connectivity matrices (ROI x ROI x Observations)
% design      - design matrix (Observations x Predictors)
% contrast    - t-contrast vector (1 x Predictors) or (Predictors x 1)
% alpha       - alpha level
%
% correction  - correction for multiple comparisons:
%               'uncorr' - uncorrected
%               'FDR'    - False Discovery Rate correction (BH procedure)
%               'Bonf'   - Bonferroni correction
%
% OUTPUTS:
%
% thresholded - thresholded binary matrix
%               (1 = significant connection, 0 = not significant)
% pval        - uncorrected right-tailed p-value matrix
% tval        - t-value matrix
% conval      - contrast estimate matrix (c' * beta for each edge)
%
% NOTES:
%
% 1) This function performs classical OLS GLM inference with a single
%    right-tailed t-test for each edge.
% 2) For two-sample designs, this is a standard GLM with pooled residual
%    variance. It is not Welch’s unequal-variance t-test.
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% -------------------------------------------------------------------------
% Check matrices
% -------------------------------------------------------------------------
if ~isnumeric(matrices) || ndims(matrices) ~= 3
    error('matrices must be a numeric 3-D array: ROI x ROI x Observations.');
end

[nROI,nROI2,nObs] = size(matrices);

if nROI ~= nROI2
    error('Connectivity matrices must be square (ROI x ROI x Observations).');
end

if nROI < 2
    error('At least 2 ROIs are required.');
end

% -------------------------------------------------------------------------
% Check design and contrast
% -------------------------------------------------------------------------
if ~isnumeric(design) || ~ismatrix(design) || isempty(design)
    error('design must be a non-empty numeric 2-D matrix.');
end

if size(design,1) ~= nObs
    error('Number of rows in design (%d) must match number of observations in matrices (%d).', ...
        size(design,1), nObs);
end

contrast = contrast(:);

if ~isnumeric(contrast) || isempty(contrast)
    error('contrast must be a numeric vector.');
end

if length(contrast) ~= size(design,2)
    error('Length of contrast (%d) must match number of design columns (%d).', ...
        length(contrast), size(design,2));
end

if all(contrast == 0)
    error('contrast must contain at least one non-zero value.');
end

if ~isscalar(alpha) || ~isfinite(alpha) || alpha <= 0 || alpha >= 1
    error('alpha must be a finite scalar between 0 and 1.');
end

if ~ischar(correction) && ~isstring(correction)
    error('correction must be a character vector or string.');
end
correction = char(correction);

% -------------------------------------------------------------------------
% Build edgewise data matrix Y
% Y = Observations x Edges
% -------------------------------------------------------------------------
ind_upper = find(triu(true(nROI),1));

Yfull = reshape(matrices, nROI*nROI, nObs).';
Y = Yfull(:,ind_upper);

% -------------------------------------------------------------------------
% GLM fit
% -------------------------------------------------------------------------
X = double(design);
c = double(contrast);

rankX = rank(X);
df = nObs - rankX;

if df <= 0
    error('Degrees of freedom must be positive. Check design matrix rank.');
end

XtX_inv = pinv(X' * X);
cvar = c' * XtX_inv * c;

if ~isfinite(cvar) || cvar <= 0
    error('Invalid contrast variance. Check design matrix and contrast.');
end

beta = X \ Y;                 % Predictors x Edges
con_est = c' * beta;          % 1 x Edges
resid = Y - X * beta;         % Observations x Edges
mse = sum(resid.^2,1) ./ df;  % 1 x Edges
se = sqrt(mse .* cvar);       % 1 x Edges

t_edge = con_est ./ se;

% Handle zero-variance edges
zv = (se == 0);
t_edge(zv & con_est == 0) = 0;
t_edge(zv & con_est ~= 0) = sign(con_est(zv & con_est ~= 0)) .* Inf;

% Right-tailed p-value
p_edge = 1 - tmfc_tcdf(t_edge, df);

% -------------------------------------------------------------------------
% Reconstruct full symmetric matrices
% -------------------------------------------------------------------------
pval = zeros(nROI);
tval = zeros(nROI);
conval = zeros(nROI);

pval(ind_upper) = p_edge;
tval(ind_upper) = t_edge;
conval(ind_upper) = con_est;

pval = pval + pval.';
tval = tval + tval.';
conval = conval + conval.';

pval(1:1+nROI:end) = 1;
tval(1:1+nROI:end) = 0;
conval(1:1+nROI:end) = 0;

% -------------------------------------------------------------------------
% Multiple-comparison correction
% -------------------------------------------------------------------------
switch correction
    case 'uncorr'
        thresholded = double(pval <= alpha);
        thresholded(1:1+nROI:end) = 0;

    case 'FDR'
        alpha_FDR = FDR(lower_triangle(pval),alpha);
        thresholded = double(pval <= alpha_FDR);
        thresholded(1:1+nROI:end) = 0;

    case 'Bonf'
        alpha_Bonf = alpha / (nROI*(nROI-1)/2);
        thresholded = double(pval <= alpha_Bonf);
        thresholded(1:1+nROI:end) = 0;

    otherwise
        thresholded = [];
        pval = [];
        tval = [];
        conval = [];
        warning('Unsupported correction type. Use ''uncorr'', ''FDR'', or ''Bonf''.');
end

end

% =========================================================================
function low = lower_triangle(matrix)

matrix(1:1+size(matrix,1):end) = NaN;
low = matrix(tril(true(size(matrix)))).';
low(isnan(low)) = [];

end

% =========================================================================
function pID = FDR(p,q)

p = p(isfinite(p));
p = sort(p(:));
V = length(p);
I = (1:V)';
cVID = 1;

pID = p(max(find(p<=I/V*q/cVID)));
if isempty(pID), pID=0; end

end