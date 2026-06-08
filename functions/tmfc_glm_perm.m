function [thresholded,pval,tval,conval] = tmfc_glm_perm(matrices,design,contrast,alpha,correction,nperm,exchange)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs non-parametric GLM-based edgewise inference for symmetric
% connectivity matrices using a single t-contrast and permutation testing.
%
% FORMAT
% [thresholded,pval,tval,conval] = tmfc_glm_perm(matrices,design,contrast,alpha,correction,nperm)
% [thresholded,pval,tval,conval] = tmfc_glm_perm(matrices,design,contrast,alpha,correction,nperm,exchange)
%
% INPUTS:
%
% matrices    - functional connectivity matrices (ROI x ROI x Observations)
% design      - design matrix (Observations x Predictors)
% contrast    - t-contrast vector (1 x Predictors) or (Predictors x 1)
% alpha       - alpha level
% correction  - correction for multiple comparisons:
%               'perm_uncorr' - uncorrected permutation p-values
%               'perm_FDR'    - FDR correction of permutation p-values
% nperm       - number of permutations
% exchange    - optional exchange-block vector (Observations x 1)
%               Permutations are restricted within each block.
%
% OUTPUTS:
%
% thresholded - thresholded binary matrix
% pval        - uncorrected permutation p-value matrix
% tval        - observed t-value matrix
% conval      - contrast estimate matrix (c' * beta for each edge)
%
% NOTES:
%
% 1) This function performs GLM-based non-parametric inference with a single
%    right-tailed t-test for each edge.
% 2) For two-sample designs, this is a standard GLM with pooled residual
%    variance. It is not Welch's unequal-variance t-test.
% 3) Permutation testing follows the Freedman-Lane procedure applied to
%    reduced-model residuals. For intercept tests in one-sample / paired-
%    difference designs, sign-flipping is used instead of row permutation.
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% -------------------------------------------------------------------------
% Check inputs
% -------------------------------------------------------------------------
if nargin < 6
    error('tmfc_glm_perm requires at least 6 inputs: matrices, design, contrast, alpha, correction, nperm.');
end

if nargin < 7
    exchange = [];
end

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

if ~isscalar(nperm) || ~isfinite(nperm) || nperm <= 0 || mod(nperm,1) ~= 0
    error('nperm must be a positive integer.');
end

if ~ischar(correction) && ~isstring(correction)
    error('correction must be a character vector or string.');
end
correction = char(correction);

if ~isempty(exchange)
    if ~isnumeric(exchange) || ~isvector(exchange) || length(exchange) ~= nObs
        error('exchange must be a numeric vector with one element per observation.');
    end
    exchange = exchange(:);
end

% -------------------------------------------------------------------------
% Build edgewise data matrix Y
% Y = Observations x Edges
% -------------------------------------------------------------------------
ind_upper = find(triu(true(nROI),1));
nEdges = numel(ind_upper);

Yfull = reshape(matrices, nROI*nROI, nObs).';
Y = Yfull(:,ind_upper);

% -------------------------------------------------------------------------
% Observed GLM fit
% -------------------------------------------------------------------------
X = double(design);
c = double(contrast);

[t_obs, con_est, df] = tmfc_glm_tstat(Y, X, c);

% Contrast estimate matrix
conval = zeros(nROI);
conval(ind_upper) = con_est;
conval = conval + conval.';
conval(1:1+nROI:end) = 0;

% -------------------------------------------------------------------------
% Reduced-model setup
% -------------------------------------------------------------------------
ind_nuisance = find(c == 0);

if isempty(ind_nuisance)
    fitted0 = zeros(size(Y));
    resid0  = Y;
else
    X0 = X(:,ind_nuisance);
    beta0 = X0 \ Y;
    fitted0 = X0 * beta0;
    resid0  = Y - fitted0;
end

% Detect intercept-only tested effect:
% first column is intercept and the contrast tests only that column
is_intercept_col = all(abs(X(:,1) - 1) < 1e-12);
is_intercept_test = is_intercept_col && c(1) ~= 0 && nnz(c) == 1;

% -------------------------------------------------------------------------
% Permutation test
% -------------------------------------------------------------------------
counts = zeros(1,nEdges,'uint32');

wb = waitbar(0,'Running permutation test...','Name','TMFC permutation test');
cleanupObj = onCleanup(@() close_waitbar_safe(wb));

for iPerm = 1:nperm

    if is_intercept_test
        s = tmfc_make_signflip(nObs, exchange);
        Yperm = fitted0 + resid0 .* s;
    else
        perm_idx = tmfc_make_permutation(nObs, exchange);
        Yperm = fitted0 + resid0(perm_idx,:);
    end

    t_perm = tmfc_glm_tstat_only(Yperm, X, c, df);

    % Right-tailed exceedance count
    counts = counts + uint32(t_perm >= t_obs);

    if mod(iPerm,50) == 0 || iPerm == nperm
        try
            waitbar(iPerm/nperm, wb, sprintf('Permutation %d of %d', iPerm, nperm));
        end
    end
end

p_perm = double(counts + 1) ./ double(nperm + 1);

% -------------------------------------------------------------------------
% Rebuild symmetric matrices
% -------------------------------------------------------------------------
pval = zeros(nROI);
tval = zeros(nROI);

pval(ind_upper) = p_perm;
pval = pval + pval.';
pval(1:1+nROI:end) = 1;

tval(ind_upper) = t_obs;
tval = tval + tval.';
tval(1:1+nROI:end) = 0;

% -------------------------------------------------------------------------
% Threshold
% -------------------------------------------------------------------------
switch correction
    case 'perm_uncorr'
        thresholded = double(pval <= alpha);
        thresholded(1:1+nROI:end) = 0;

    case 'perm_FDR'
        alpha_FDR = FDR(lower_triangle(pval), alpha);
        thresholded = double(pval <= alpha_FDR);
        thresholded(1:1+nROI:end) = 0;

    otherwise
        thresholded = [];
        pval = [];
        tval = [];
        conval = [];
        warning('Unsupported correction type for tmfc_glm_perm.');
end

end

% =========================================================================
function [t_edge, con_est, df] = tmfc_glm_tstat(Y, X, c)

rankX = rank(X);
df = size(X,1) - rankX;

if df <= 0
    error('Degrees of freedom must be positive. Check design matrix rank.');
end

XtX_inv = pinv(X' * X);
cvar = c' * XtX_inv * c;

if ~isfinite(cvar) || cvar <= 0
    error('Invalid contrast variance. Check design matrix and contrast.');
end

beta = X \ Y;
con_est = c' * beta;
resid = Y - X * beta;
mse = sum(resid.^2,1) ./ df;
se = sqrt(mse .* cvar);

t_edge = con_est ./ se;

zv = (se == 0);
t_edge(zv & con_est == 0) = 0;
t_edge(zv & con_est ~= 0) = sign(con_est(zv & con_est ~= 0)) .* Inf;

end

% =========================================================================
function t_edge = tmfc_glm_tstat_only(Y, X, c, df)

XtX_inv = pinv(X' * X);
cvar = c' * XtX_inv * c;

beta = X \ Y;
con_est = c' * beta;
resid = Y - X * beta;
mse = sum(resid.^2,1) ./ df;
se = sqrt(mse .* cvar);

t_edge = con_est ./ se;

zv = (se == 0);
t_edge(zv & con_est == 0) = 0;
t_edge(zv & con_est ~= 0) = sign(con_est(zv & con_est ~= 0)) .* Inf;

end

% =========================================================================
function perm_idx = tmfc_make_permutation(nObs, exchange)

if isempty(exchange)
    perm_idx = randperm(nObs).';
else
    perm_idx = zeros(nObs,1);
    blks = unique(exchange);

    for iBlk = 1:numel(blks)
        ind = find(exchange == blks(iBlk));
        perm_idx(ind) = ind(randperm(numel(ind)));
    end
end

end

% =========================================================================
function s = tmfc_make_signflip(nObs, exchange)

if isempty(exchange)
    s = 2*(rand(nObs,1) > 0.5) - 1;
else
    s = zeros(nObs,1);
    blks = unique(exchange);

    for iBlk = 1:numel(blks)
        ind = find(exchange == blks(iBlk));
        s(ind) = 2*(rand(numel(ind),1) > 0.5) - 1;
    end
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

pID = p(max(find(p <= I/V*q/cVID)));
if isempty(pID), pID = 0; end

end

% =========================================================================
function close_waitbar_safe(wb)

if ~isempty(wb) && isgraphics(wb)
    close(wb);
end

end