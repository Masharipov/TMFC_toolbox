function [thresholded,pval,tval,conval,score] = tmfc_glm_tfnbs(matrices,design,contrast,alpha,nperm,E,H,nSteps,start_t,exchange,use_parfor)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs non-parametric GLM-based threshold-free network-based statistics
% (TFNBS) for symmetric connectivity matrices using a single t-contrast.
%
% TFNBS is a threshold-free component-based procedure that produces
% edge-wise significance values. Whole-connectome family-wise error (FWE)
% corrected p-values are obtained by comparing each edge's TFNBS score to
% the null distribution of the maximum connectome-wide TFNBS score across
% permutations.
%
% FORMAT
%   [thresholded,pval,tval,conval,score] = tmfc_glm_tfnbs( ...
%       matrices,design,contrast,alpha,nperm)
%
%   [thresholded,pval,tval,conval,score] = tmfc_glm_tfnbs( ...
%       matrices,design,contrast,alpha,nperm,E,H,nSteps,start_t)
%
%   [thresholded,pval,tval,conval,score] = tmfc_glm_tfnbs( ...
%       matrices,design,contrast,alpha,nperm,E,H,nSteps,start_t,exchange)
%
%   [thresholded,pval,tval,conval,score] = tmfc_glm_tfnbs( ...
%       matrices,design,contrast,alpha,nperm,E,H,nSteps,start_t,exchange,use_parfor)
%
% INPUTS:
%
% matrices    - functional connectivity matrices (ROI x ROI x Observations)
% design      - design matrix (Observations x Predictors)
% contrast    - t-contrast vector (1 x Predictors) or (Predictors x 1)
% alpha       - FWE alpha level
% nperm       - number of permutations
% E           - extent enhancement parameter (default = 0.4)
% H           - height enhancement parameter (default = 3.0)
% nSteps      - number of thresholds (default = 100)
% start_t     - starting t-threshold (default = 0)
% exchange    - optional exchange-block vector (Observations x 1)
%               Permutations are restricted within each block.
% use_parfor  - true to use parfor in permutation loop (default: false)
%
% OUTPUTS:
%
% thresholded - binary significant edge matrix
% pval        - FWE-corrected p-value matrix
% tval        - observed t-value matrix
% conval      - contrast estimate matrix (c' * beta for each edge)
% score       - observed TFNBS score matrix
%
% NOTES:
%
% 1) This function performs GLM-based non-parametric inference using a
%    single right-tailed t-test for each edge.
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
% Defaults
% -------------------------------------------------------------------------
if nargin < 5
    error('tmfc_glm_tfnbs requires at least 5 inputs: matrices, design, contrast, alpha, nperm.');
end
if nargin < 6 || isempty(E),          E = 0.4;       end
if nargin < 7 || isempty(H),          H = 3.0;       end
if nargin < 8 || isempty(nSteps),     nSteps = 100;  end
if nargin < 9 || isempty(start_t),    start_t = 0;   end
if nargin < 10
    exchange = [];
end
if nargin < 11 || isempty(use_parfor)
    use_parfor = false;
end

% -------------------------------------------------------------------------
% Check inputs
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
    error('alpha must be a scalar in (0,1).');
end

if ~isscalar(nperm) || ~isfinite(nperm) || nperm <= 0 || mod(nperm,1) ~= 0
    error('nperm must be a positive integer.');
end

if ~isscalar(E) || ~isfinite(E) || E < 0
    error('E must be a non-negative scalar.');
end

if ~isscalar(H) || ~isfinite(H) || H < 0
    error('H must be a non-negative scalar.');
end

if ~isscalar(nSteps) || ~isfinite(nSteps) || nSteps < 2 || mod(nSteps,1) ~= 0
    error('nSteps must be an integer >= 2.');
end

if ~isscalar(start_t) || ~isfinite(start_t) || start_t < 0
    error('start_t must be a non-negative scalar.');
end

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
mask_ut = triu(true(nROI),1);
ind_upper = find(mask_ut);

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

% Observed full t matrix
tval = zeros(nROI);
tval(ind_upper) = t_obs;
tval = tval + tval.';
tval(1:1+nROI:end) = 0;

% -------------------------------------------------------------------------
% Observed TFNBS score
% -------------------------------------------------------------------------
score = tmfc_compute_tfnbs_score(tval, E, H, nSteps, start_t);

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

% Detect intercept-only tested effect
is_intercept_col = all(abs(X(:,1) - 1) < 1e-12);
is_intercept_test = is_intercept_col && c(1) ~= 0 && nnz(c) == 1;

% -------------------------------------------------------------------------
% Permutation null: max TFNBS score
% -------------------------------------------------------------------------
null_max = zeros(nperm,1);

if use_parfor

    h = helpdlg('Please wait...', 'TMFC GLM TFNBS');
    cleanupObj = onCleanup(@() close_waitbar_safe(h));

    parfor iPerm = 1:nperm

        if is_intercept_test
            s = tmfc_make_signflip(nObs, exchange);
            Yperm = fitted0 + resid0 .* s;
        else
            perm_idx = tmfc_make_permutation(nObs, exchange);
            Yperm = fitted0 + resid0(perm_idx,:);
        end

        t_perm = tmfc_glm_tstat_only(Yperm, X, c, df);

        t_perm_mat = zeros(nROI,nROI);
        t_perm_mat(ind_upper) = t_perm;
        t_perm_mat = t_perm_mat + t_perm_mat.';
        t_perm_mat(1:1+nROI:end) = 0;

        score_perm = tmfc_compute_tfnbs_score(t_perm_mat, E, H, nSteps, start_t);
        null_max(iPerm) = max(score_perm(:));
    end

else

    wb = waitbar(0,'Running GLM TFNBS permutation test...','Name','TMFC GLM TFNBS');
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

        t_perm_mat = zeros(nROI,nROI);
        t_perm_mat(ind_upper) = t_perm;
        t_perm_mat = t_perm_mat + t_perm_mat.';
        t_perm_mat(1:1+nROI:end) = 0;

        score_perm = tmfc_compute_tfnbs_score(t_perm_mat, E, H, nSteps, start_t);
        null_max(iPerm) = max(score_perm(:));

        if mod(iPerm,50)==0 || iPerm==nperm
            try
                waitbar(iPerm/nperm, wb, sprintf('Permutation %d of %d', iPerm, nperm));
            end
        end
    end
end

% -------------------------------------------------------------------------
% Edgewise FWE-corrected p-values
% -------------------------------------------------------------------------
score_ut = score(mask_ut);

[score_unique,~,ic] = unique(score_ut);
p_unique = zeros(size(score_unique));

for k = 1:numel(score_unique)
    p_unique(k) = sum(null_max >= score_unique(k)) / nperm;
end

p_ut = p_unique(ic);

pval = zeros(nROI,nROI);
pval(mask_ut) = p_ut;
pval = pval + pval.';
pval(1:1+nROI:end) = 1;

thresholded = double(pval <= alpha);
thresholded(1:1+nROI:end) = 0;

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
function score = tmfc_compute_tfnbs_score(tmat, E, H, nSteps, start_t)
% Compute TFNBS score by integrating component support across thresholds.
%
%   score(edge) = integral over thresholds of:
%                 [component_size(thr)^E * thr^H]
%
% for all thresholds at which the edge belongs to a suprathreshold component.

nROI = size(tmat,1);
score = zeros(nROI,nROI);

% Only positive suprathreshold statistics contribute
tmax = max(tmat(:));
if tmax <= start_t
    return;
end

dt = (tmax - start_t) / nSteps;
thr_vec = linspace(start_t + dt, tmax, nSteps);

% Work in upper-triangle edge space
mask_ut = triu(true(nROI),1);
[row_ut,col_ut] = find(mask_ut);
t_ut = tmat(mask_ut);
score_ut = zeros(size(t_ut));

I = speye(nROI);

for k = 1:numel(thr_vec)
    thr = thr_vec(k);

    supra_idx = find(t_ut >= thr);
    if isempty(supra_idx)
        continue;
    end

    ii = row_ut(supra_idx);
    jj = col_ut(supra_idx);

    % Sparse undirected adjacency with diagonal added once per threshold
    adj = sparse([ii; jj], [jj; ii], true, nROI, nROI);
    adj = adj | I;

    [labels, comp_sizes] = get_components_fast(adj);

    % Assign each suprathreshold edge to its node component
    edge_comp = labels(ii).';

    % Count edges per component directly in edge space
    edge_counts = accumarray(edge_comp, 1, [numel(comp_sizes), 1]);

    valid_comp = edge_counts > 0;
    if ~any(valid_comp)
        continue;
    end

    increment_comp = zeros(numel(comp_sizes),1);
    increment_comp(valid_comp) = (edge_counts(valid_comp).^E) * (thr.^H) * dt;

    score_ut(supra_idx) = score_ut(supra_idx) + increment_comp(edge_comp);
end

score(mask_ut) = score_ut;
score = score + score.';
end

% =========================================================================
function [comps,comp_sizes] = get_components_fast(adj)
% Fast connected components for an undirected adjacency matrix.
% Assumes:
%   - adj is square
%   - adj is already symmetric
%   - diagonal already contains ones

[~,p,~,r] = dmperm(adj);

comp_sizes = diff(r);
num_comps = numel(comp_sizes);

comps = zeros(1,size(adj,1));
comps(r(1:num_comps)) = 1;
comps = cumsum(comps);
comps(p) = comps;
end

% =========================================================================
function close_waitbar_safe(wb)
if ~isempty(wb) && isgraphics(wb)
    close(wb);
end
end