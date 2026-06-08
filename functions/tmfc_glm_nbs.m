function [thresholded,pval,tval,conval,components] = tmfc_glm_nbs(matrices,design,contrast,alpha,primary_p,nperm,nbs_stat,exchange,use_parfor)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs non-parametric GLM-based network based statistics (NBS)
% for symmetric connectivity matrices using a single t-contrast.
%
% Family-wise error (FWE) is controlled at the component level
% using either extent- or intensity-based thresholding.
%
% FORMAT
%   [thresholded,pval,tval,conval,components] = tmfc_glm_nbs( ...
%       matrices,design,contrast,alpha,primary_p,nperm,nbs_stat)
%
%   [thresholded,pval,tval,conval,components] = tmfc_glm_nbs( ...
%       matrices,design,contrast,alpha,primary_p,nperm,nbs_stat,exchange)
%
%   [thresholded,pval,tval,conval,components] = tmfc_glm_nbs( ...
%       matrices,design,contrast,alpha,primary_p,nperm,nbs_stat,exchange,use_parfor)
%
% INPUTS:
%
% matrices    - functional connectivity matrices (ROI x ROI x Observations)
% design      - design matrix (Observations x Predictors)
% contrast    - t-contrast vector (1 x Predictors) or (Predictors x 1)
% alpha       - FWE alpha level for component significance
% primary_p   - primary edge-forming threshold in p-values
% nperm       - number of permutations
% nbs_stat    - 'NBS_extent' or 'NBS_intensity'
% exchange    - optional exchange-block vector (Observations x 1)
%               Permutations are restricted within each block.
% use_parfor  - true to use parfor in permutation loop (default: false)
%
% OUTPUTS:
%
% thresholded - matrix of significant NBS components:
%               0 = non-significant edge
%               1 = first significant component
%               2 = second significant component
%               ...
% pval        - component-level corrected p-values assigned to edges
% tval        - observed t-value matrix
% conval      - contrast estimate matrix (c' * beta for each edge)
% components  - struct array describing observed NBS components:
%               .pvalue         corrected component-level p-value
%               .n_connections  number of suprathreshold edges in component
%               .pairs          K x 2 array of ROI index pairs
%               .statistic      component statistic (extent or intensity)
%               .matrix         ROI x ROI binary matrix of edges in component
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
if nargin < 7
    error('tmfc_glm_nbs requires at least 7 inputs: matrices, design, contrast, alpha, primary_p, nperm, nbs_stat.');
end
if nargin < 8
    exchange = [];
end
if nargin < 9
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

if ~isscalar(primary_p) || ~isfinite(primary_p) || primary_p <= 0 || primary_p >= 1
    error('primary_p must be a scalar in (0,1).');
end

if ~isscalar(nperm) || ~isfinite(nperm) || nperm <= 0 || mod(nperm,1) ~= 0
    error('nperm must be a positive integer.');
end

if ~ischar(nbs_stat) && ~isstring(nbs_stat)
    error('nbs_stat must be a string: ''NBS_extent'' or ''NBS_intensity''.');
end
nbs_stat = char(nbs_stat);

if ~any(strcmp(nbs_stat, {'NBS_extent','NBS_intensity'}))
    error('nbs_stat must be ''NBS_extent'' or ''NBS_intensity''.');
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

% Primary threshold
t_thr = tmfc_tinv(1 - primary_p, df);

% Observed full t matrix
tval = zeros(nROI);
tval(ind_upper) = t_obs;
tval = tval + tval.';
tval(1:1+nROI:end) = 0;

% Observed suprathreshold adjacency
obs_supra = false(nROI,nROI);
obs_supra(ind_upper) = (t_obs > t_thr);
obs_supra = obs_supra | obs_supra.';

% -------------------------------------------------------------------------
% Find observed components and their statistic
% -------------------------------------------------------------------------
[obs_labels, obs_sizes] = get_components(obs_supra);
obs_idx = find(obs_sizes > 1);

thresholded = zeros(nROI,nROI);
pval = ones(nROI,nROI);

components = struct('pvalue', {}, ...
                    'n_connections', {}, ...
                    'pairs', {}, ...
                    'statistic', {}, ...
                    'matrix', {});

if ~any(obs_sizes > 1)
    return;
end

obs_stat = [];
obs_edge_masks = {};
obs_pairs = {};
obs_nconn = [];

for k = 1:numel(obs_idx)
    nodes = find(obs_labels == obs_idx(k));

    edge_mask_full = false(nROI,nROI);
    edge_mask_full(nodes,nodes) = obs_supra(nodes,nodes);
    edge_mask_ut = triu(edge_mask_full,1);

    if ~any(edge_mask_ut(:))
        continue;
    end

    [r,c2] = find(edge_mask_ut);
    pairs = [r c2];
    n_conn = size(pairs,1);

    switch nbs_stat
        case 'NBS_extent'
            comp_stat = nnz(edge_mask_ut);

        case 'NBS_intensity'
            comp_stat = sum(tval(edge_mask_ut) - t_thr);
    end

    obs_stat(end+1) = comp_stat;
    obs_edge_masks{end+1} = edge_mask_ut;
    obs_pairs{end+1} = pairs;
    obs_nconn(end+1) = n_conn;
end

if isempty(obs_stat)
    return;
end

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
% Permutation null: max component statistic
% -------------------------------------------------------------------------
null_max = zeros(nperm,1);

if use_parfor

    h = helpdlg('Please wait...', 'TMFC GLM NBS');
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

        supra = false(nROI,nROI);
        supra(ind_upper) = (t_perm > t_thr);
        supra = supra | supra.';

        if strcmp(nbs_stat,'NBS_intensity')
            t_perm_mat = zeros(nROI,nROI);
            t_perm_mat(ind_upper) = t_perm;
            t_perm_mat = t_perm_mat + t_perm_mat.';
        else
            t_perm_mat = [];
        end

        [perm_labels, perm_sizes] = get_components(supra);
        perm_idx_comp = find(perm_sizes > 1);

        max_stat = 0;
        for cidx = 1:numel(perm_idx_comp)
            nodes = find(perm_labels == perm_idx_comp(cidx));

            edge_mask_full = false(nROI,nROI);
            edge_mask_full(nodes,nodes) = supra(nodes,nodes);
            edge_mask_ut = triu(edge_mask_full,1);

            if ~any(edge_mask_ut(:))
                continue;
            end

            if strcmp(nbs_stat,'NBS_extent')
                stat_c = nnz(edge_mask_ut);
            else
                stat_c = sum(t_perm_mat(edge_mask_ut) - t_thr);
            end

            if stat_c > max_stat
                max_stat = stat_c;
            end
        end

        null_max(iPerm) = max_stat;
    end

else

    wb = waitbar(0,'Running GLM NBS permutation test...','Name','TMFC GLM NBS');
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

        supra = false(nROI,nROI);
        supra(ind_upper) = (t_perm > t_thr);
        supra = supra | supra.';

        if strcmp(nbs_stat,'NBS_intensity')
            t_perm_mat = zeros(nROI,nROI);
            t_perm_mat(ind_upper) = t_perm;
            t_perm_mat = t_perm_mat + t_perm_mat.';
        end

        [perm_labels, perm_sizes] = get_components(supra);
        perm_idx_comp = find(perm_sizes > 1);

        max_stat = 0;
        for cidx = 1:numel(perm_idx_comp)
            nodes = find(perm_labels == perm_idx_comp(cidx));

            edge_mask_full = false(nROI,nROI);
            edge_mask_full(nodes,nodes) = supra(nodes,nodes);
            edge_mask_ut = triu(edge_mask_full,1);

            if ~any(edge_mask_ut(:))
                continue;
            end

            switch nbs_stat
                case 'NBS_extent'
                    stat_c = nnz(edge_mask_ut);

                case 'NBS_intensity'
                    stat_c = sum(t_perm_mat(edge_mask_ut) - t_thr);
            end

            if stat_c > max_stat
                max_stat = stat_c;
            end
        end

        null_max(iPerm) = max_stat;

        if mod(iPerm,50)==0 || iPerm==nperm
            try
                waitbar(iPerm/nperm, wb, sprintf('Permutation %d of %d', iPerm, nperm));
            end
        end
    end
end

% -------------------------------------------------------------------------
% Component p-values and thresholded output
% -------------------------------------------------------------------------
sig_count = 0;

for k = 1:numel(obs_stat)
    comp_p = sum(null_max >= obs_stat(k)) / nperm;

    edge_mask = obs_edge_masks{k};
    pval(edge_mask) = comp_p;
    pval = min(pval, pval.');

    if comp_p <= alpha
        sig_count = sig_count + 1;
        thresholded(edge_mask | edge_mask.') = sig_count;

        components(sig_count).pvalue = comp_p;
        components(sig_count).n_connections = obs_nconn(k);
        components(sig_count).pairs = obs_pairs{k};
        components(sig_count).statistic = obs_stat(k);
        components(sig_count).matrix = edge_mask | edge_mask.';
    end
end

thresholded(1:1+nROI:end) = 0;
pval(1:1+nROI:end) = 1;

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
function [comps,comp_sizes] = get_components(adj)
% Connected components for an undirected adjacency matrix

if size(adj,1) ~= size(adj,2)
    error('this adjacency matrix is not square');
end

if ~any(any(adj - triu(adj)))
    adj = adj | adj';
end

if sum(diag(adj)) ~= size(adj,1)
    adj = adj | speye(size(adj));
end

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