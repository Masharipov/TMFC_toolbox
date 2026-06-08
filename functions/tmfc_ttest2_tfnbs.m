function [thresholded,pval,tval,conval,score] = tmfc_ttest2_tfnbs(matrices,contrast,alpha,nperm,E,H,nSteps,start_t,use_parfor)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs two-sample threshold-free network-based statistics (TFNBS)
% permutation test for symmetric connectivity matrices using group-label
% permutation.
%
% TFNBS is a threshold-free component-based procedure that produces
% edge-wise significance values. Whole-connectome family-wise error (FWE)
% corrected p-values are obtained by comparing each edge's TFNBS score to
% the null distribution of the maximum connectome-wide TFNBS score across
% permutations.
%
% FORMAT
%   [thresholded,pval,tval,conval,score] = tmfc_ttest2_tfnbs(matrices,contrast,alpha,nperm,E,H,nSteps,start_t)
%   [thresholded,pval,tval,conval,score] = tmfc_ttest2_tfnbs(matrices,contrast,alpha,nperm,E,H,nSteps,start_t,use_parfor)
%
% INPUTS
%
% matrices    - functional connectivity matrices (cell array):
%               matrices{1} - 1st group, 3-D array (ROI x ROI x Subjects)
%               matrices{2} - 2nd group, 3-D array (ROI x ROI x Subjects)
%
% contrast    - contrast weights
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
% Defaults / checks
% -------------------------------------------------------------------------
if nargin < 4
    error('tmfc_ttest2_tfnbs requires at least 4 inputs: matrices, contrast, alpha, nperm.');
end
if nargin < 5 || isempty(E),          E = 0.4;       end
if nargin < 6 || isempty(H),          H = 3.0;       end
if nargin < 7 || isempty(nSteps),     nSteps = 100;  end
if nargin < 8 || isempty(start_t),    start_t = 0;   end
if nargin < 9 || isempty(use_parfor), use_parfor = false; end

if ~iscell(matrices) || numel(matrices) ~= 2
    error('matrices must be a cell array with two groups.');
end

if numel(contrast) ~= 2
    error('contrast must contain two weights.');
end

if ~(isequal(contrast,[1 -1]) || isequal(contrast,[-1 1]))
    error('For two-sample TFNBS, contrast must be [1 -1] or [-1 1].');
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

% -------------------------------------------------------------------------
% Prepare data
% -------------------------------------------------------------------------
group1 = matrices{1};
group2 = matrices{2};

if ndims(group1) ~= 3 || ndims(group2) ~= 3
    error('Both groups must be ROI x ROI x Subjects.');
end

conval = contrast(1)*mean(group1,3) + contrast(2)*mean(group2,3);

if contrast(1) > contrast(2)
    first_group  = group1;
    second_group = group2;
elseif contrast(1) < contrast(2)
    first_group  = group2;
    second_group = group1;
else
    error('Two-sample contrast weights must define direction, e.g. [1 -1] or [-1 1].');
end

[nROI,nROI2,nSub1] = size(first_group);
[nROIb,nROI2b,nSub2] = size(second_group);

if nROI ~= nROI2 || nROIb ~= nROI2b
    error('Matrices must be square in the first two dimensions.');
end
if nROI ~= nROIb
    error('The two groups must have the same number of ROIs.');
end
if nROI < 2
    error('At least 2 ROIs are required.');
end
if nSub1 < 2 || nSub2 < 2
    error('Each group must contain at least 2 subjects.');
end

% -------------------------------------------------------------------------
% Convert upper triangle to [Subjects x Edges]
% -------------------------------------------------------------------------
mask_ut = triu(true(nROI),1);

X1 = reshape(first_group, nROI*nROI, nSub1);
X1 = X1(mask_ut,:).';   % [nSub1 x nEdges]

X2 = reshape(second_group, nROI*nROI, nSub2);
X2 = X2(mask_ut,:).';   % [nSub2 x nEdges]

% -------------------------------------------------------------------------
% Observed t-statistics
% -------------------------------------------------------------------------
sum1_obs   = sum(X1,1);
sumsq1_obs = sum(X1.^2,1);

sum2_obs   = sum(X2,1);
sumsq2_obs = sum(X2.^2,1);

t_obs = tmfc_twosample_tstat_from_sums(sum1_obs, sumsq1_obs, nSub1, ...
                                       sum2_obs, sumsq2_obs, nSub2);

tval = zeros(nROI,nROI);
tval(mask_ut) = t_obs;
tval = tval + tval.';
tval(1:1+nROI:end) = 0;

% -------------------------------------------------------------------------
% Observed TFNBS score
% -------------------------------------------------------------------------
score = tmfc_compute_tfnbs_score(tval, E, H, nSteps, start_t);

% -------------------------------------------------------------------------
% Permutation null: max TFNBS score
% -------------------------------------------------------------------------
Xall = [X1; X2];
Xall2 = Xall.^2;
nAll = nSub1 + nSub2;
sum_all   = sum(Xall,1);
sumsq_all = sum(Xall2,1);

null_max = zeros(nperm,1);

if use_parfor

    h = helpdlg('Please wait...', 'TMFC TFNBS');
    cleanupObj = onCleanup(@() close_waitbar_safe(h)); 

    parfor iPerm = 1:nperm
        perm_idx = randperm(nAll);
        idx1 = perm_idx(1:nSub1);

        g = false(nAll,1);
        g(idx1) = true;
        g = double(g);

        sum1p   = g' * Xall;
        sumsq1p = g' * Xall2;

        sum2p   = sum_all - sum1p;
        sumsq2p = sumsq_all - sumsq1p;

        t_perm = tmfc_twosample_tstat_from_sums(sum1p, sumsq1p, nSub1, ...
            sum2p, sumsq2p, nSub2);

        t_perm_mat = zeros(nROI,nROI);
        t_perm_mat(mask_ut) = t_perm;
        t_perm_mat = t_perm_mat + t_perm_mat.';
        t_perm_mat(1:1+nROI:end) = 0;

        score_perm = tmfc_compute_tfnbs_score(t_perm_mat, E, H, nSteps, start_t);
        null_max(iPerm) = max(score_perm(:));
    end

else

    wb = waitbar(0,'Running TFNBS permutation test...','Name','TMFC TFNBS');
    cleanupObj = onCleanup(@() close_waitbar_safe(wb)); 

    for iPerm = 1:nperm
        perm_idx = randperm(nAll);
        idx1 = perm_idx(1:nSub1);

        g = false(nAll,1);
        g(idx1) = true;
        g = double(g);

        sum1p   = g' * Xall;
        sumsq1p = g' * Xall2;

        sum2p   = sum_all - sum1p;
        sumsq2p = sumsq_all - sumsq1p;

        t_perm = tmfc_twosample_tstat_from_sums(sum1p, sumsq1p, nSub1, ...
            sum2p, sumsq2p, nSub2);

        t_perm_mat = zeros(nROI,nROI);
        t_perm_mat(mask_ut) = t_perm;
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

tmax = max(tmat(:));
if tmax <= start_t
    return;
end

dt = (tmax - start_t) / nSteps;
thr_vec = linspace(start_t + dt, tmax, nSteps);

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

    adj = sparse([ii; jj], [jj; ii], true, nROI, nROI);
    adj = adj | I;

    [labels, comp_sizes] = get_components_fast(adj);

    edge_comp = labels(ii).';
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

% -------------------------------------------------------------------------
function tval = tmfc_twosample_tstat_from_sums(sum1, sumsq1, n1, sum2, sumsq2, n2)
% Fast two-sample Welch t-statistic from sums and sums of squares.

mx = sum1 ./ n1;
my = sum2 ./ n2;

vx = (sumsq1 - (sum1.^2)./n1) ./ (n1 - 1);
vy = (sumsq2 - (sum2.^2)./n2) ./ (n2 - 1);

vx(vx < 0) = 0;
vy(vy < 0) = 0;

den = sqrt(vx./n1 + vy./n2);
tval = (mx - my) ./ den;

zv = (den == 0);
diffm = mx - my;

tval(zv & diffm == 0) = 0;
tval(zv & diffm > 0)  = Inf;
tval(zv & diffm < 0)  = -Inf;
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