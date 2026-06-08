function [thresholded,pval,tval,conval,score] = tmfc_ttest_tfnbs(matrices,contrast,alpha,nperm,E,H,nSteps,start_t,use_parfor)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs one-sample and paired-sample threshold-free network-based
% statistics (TFNBS) permutation test for symmetric connectivity matrices
% using sign-flipping.
%
% TFNBS is a threshold-free component-based procedure that produces
% edge-wise significance values. Whole-connectome family-wise error (FWE)
% corrected p-values are obtained by comparing each edge's TFNBS score to
% the null distribution of the maximum connectome-wide TFNBS score across
% permutations.
%
% FORMAT
%   [thresholded,pval,tval,conval,score] = tmfc_ttest_tfnbs(matrices,contrast,alpha,nperm,E,H,nSteps,start_t)
%   [thresholded,pval,tval,conval,score] = tmfc_ttest_tfnbs(matrices,contrast,alpha,nperm,E,H,nSteps,start_t,use_parfor)
%
% INPUTS
%
% matrices    - functional connectivity matrices
%
%            1) one-sample: 3-D array (ROI x ROI x Subjects)
%
%            2) paired-sample (cell array):
%               matrices{1} - 1st measure, 3-D array (ROI x ROI x Subjects)
%               matrices{2} - 2nd measure, 3-D array (ROI x ROI x Subjects)
%
% contrast    - contrast weight(s)
% alpha       - FWE alpha level
% nperm       - number of permutations
% E           - extent enhancement parameter (default = 0.4)
% H           - height enhancement parameter (default = 3.0)
% nSteps      - number of thresholds (default = 100)
% start_t     - starting t-threshold (default = 0)
% use_parfor  - true to use parfor in permutation loop (default: false)
%
% OUTPUTS
%
% thresholded - binary significant edge matrix
% pval        - FWE-corrected p-value matrix
% tval        - observed t-value matrix
% conval      - group mean contrast value
% score       - observed TFNBS score matrix
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% -------------------------------------------------------------------------
% Defaults
% -------------------------------------------------------------------------
if nargin < 4
    error('tmfc_ttest_tfnbs requires at least 4 inputs: matrices, contrast, alpha, nperm.');
end
if nargin < 5 || isempty(E),       E = 0.4;      end
if nargin < 6 || isempty(H),       H = 3.0;      end
if nargin < 7 || isempty(nSteps),  nSteps = 100; end
if nargin < 8 || isempty(start_t), start_t = 0;  end
if nargin < 9 || isempty(use_parfor), use_parfor = false; end

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

% -------------------------------------------------------------------------
% Prepare data
% -------------------------------------------------------------------------
if iscell(matrices)
    if numel(matrices) ~= 2
        error('For paired test, matrices must be a cell array with two elements.');
    end
    if numel(contrast) ~= 2
        error('For paired test, contrast must contain two weights.');
    end
    matrices = contrast(1)*matrices{1} + contrast(2)*matrices{2};
else
    if numel(contrast) ~= 1
        error('For one-sample test, contrast must be a scalar.');
    end
    matrices = contrast .* matrices;
end

if ndims(matrices) ~= 3
    error('Input matrices must be ROI x ROI x Subjects.');
end

[nROI,nROI2,nSub] = size(matrices);
if nROI ~= nROI2
    error('Matrices must be square in the first two dimensions.');
end
if nROI < 2
    error('At least 2 ROIs are required.');
end
if nSub < 2
    error('At least 2 subjects are required.');
end

conval = mean(matrices,3);

% -------------------------------------------------------------------------
% Convert upper triangle to [Subjects x Edges]
% -------------------------------------------------------------------------
mask_ut = triu(true(nROI),1);

X = reshape(matrices, nROI*nROI, nSub);
X = X(mask_ut,:).';   % [nSub x nEdges]

% -------------------------------------------------------------------------
% Observed t-statistics
% -------------------------------------------------------------------------
sum_obs   = sum(X,1);
sumsq_all = sum(X.^2,1);
t_obs     = tmfc_onesample_tstat_from_sums(sum_obs, sumsq_all, nSub);

tval = zeros(nROI,nROI);
tval(mask_ut) = t_obs;
tval = tval + tval.';

% -------------------------------------------------------------------------
% Observed TFNBS score
% -------------------------------------------------------------------------
score = tmfc_compute_tfnbs_score(tval, E, H, nSteps, start_t);

% -------------------------------------------------------------------------
% Permutation null: max TFNBS score
% -------------------------------------------------------------------------
null_max = zeros(nperm,1);

if use_parfor

    h = helpdlg('Please wait...', 'TMFC TFNBS');
    cleanupObj = onCleanup(@() close_waitbar_safe(h));

    parfor iPerm = 1:nperm
        s = 2*(rand(nSub,1) > 0.5) - 1;
        sum_perm = s' * X;
        t_perm   = tmfc_onesample_tstat_from_sums(sum_perm, sumsq_all, nSub);

        t_perm_mat = zeros(nROI,nROI);
        t_perm_mat(mask_ut) = t_perm;
        t_perm_mat = t_perm_mat + t_perm_mat.';

        score_perm = tmfc_compute_tfnbs_score(t_perm_mat, E, H, nSteps, start_t);
        null_max(iPerm) = max(score_perm(:));
    end

else

    sign_mat = rand(nSub,nperm);
    sign_mat = 2*(sign_mat > 0.5) - 1;
    
    wb = waitbar(0,'Running TFNBS permutation test...','Name','TMFC TFNBS');
    cleanupObj = onCleanup(@() close_waitbar_safe(wb));
    
    for iPerm = 1:nperm
        s = sign_mat(:,iPerm);
        sum_perm = s' * X;
        t_perm   = tmfc_onesample_tstat_from_sums(sum_perm, sumsq_all, nSub);
    
        t_perm_mat = zeros(nROI,nROI);
        t_perm_mat(mask_ut) = t_perm;
        t_perm_mat = t_perm_mat + t_perm_mat.';
    
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
p_ut = ones(size(score_ut));

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

% -------------------------------------------------------------------------
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

    % Components of size 1 are isolated nodes only, so they get 0 edges
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

% -------------------------------------------------------------------------
function tval = tmfc_onesample_tstat_from_sums(sum1, sumsq_all, n)
% Fast one-sample t-statistic from sums and sums of squares.

m = sum1 ./ n;

% sample variance (unbiased)
v = (sumsq_all - (sum1.^2)./n) ./ (n - 1);
v(v < 0) = 0;

se = sqrt(v ./ n);
tval = m ./ se;

zv = (se == 0);
tval(zv & m == 0) = 0;
tval(zv & m > 0)  = Inf;
tval(zv & m < 0)  = -Inf;
end

% -------------------------------------------------------------------------
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

% -------------------------------------------------------------------------
function close_waitbar_safe(wb)
if ~isempty(wb) && isgraphics(wb)
    close(wb);
end
end