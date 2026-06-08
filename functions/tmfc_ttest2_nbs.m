function [thresholded,pval,tval,conval,components] = tmfc_ttest2_nbs(matrices,contrast,alpha,primary_p,nperm,nbs_stat,use_parfor)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs two-sample network based statistics (NBS) permutation test 
% for symmetric connectivity matrices using group-label permutation.
%
% Family-wise error (FWE) is controlled at the component level
% using either extent- or intensity-based thresholding.
%
% FORMAT
%   [thresholded,pval,tval,conval,components] = tmfc_ttest2_nbs(matrices,contrast,alpha,primary_p,nperm,nbs_stat)
%   [thresholded,pval,tval,conval,components] = tmfc_ttest2_nbs(matrices,contrast,alpha,primary_p,nperm,nbs_stat,use_parfor)
%
% INPUTS
%
% matrices    - functional connectivity matrices (cell array):
%               matrices{1} - 1st group, 3-D array (ROI x ROI x Subjects)
%               matrices{2} - 2nd group, 3-D array (ROI x ROI x Subjects)
%
% contrast    - contrast weights
% alpha       - FWE alpha level for component significance
% primary_p   - primary edge-forming threshold in p-values
% nperm       - number of permutations
% nbs_stat    - 'NBS_extent' or 'NBS_intensity'
% use_parfor  - true to use parfor in permutation loop (default: false)
%
% OUTPUTS
%
% thresholded - matrix of significant NBS components:
%               0 = non-significant edge
%               1 = first significant component
%               2 = second significant component
%               ...
% pval        - component-level corrected p-values assigned to edges
% tval        - observed t-value matrix
% conval      - group mean contrast value
% components  - struct array describing observed NBS components:
%               .pvalue         corrected component-level p-value
%               .n_connections  number of suprathreshold edges in component
%               .pairs          K x 2 array of ROI index pairs
%               .statistic      component statistic (extent or intensity)
%               .matrix         ROI x ROI binary matrix of edges in component
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% -------------------------------------------------------------------------
% Input checks / data preparation
% -------------------------------------------------------------------------
if nargin < 6
    error('tmfc_ttest2_nbs requires 6 inputs: matrices, contrast, alpha, primary_p, nperm, nbs_stat.');
end

if nargin < 7
    use_parfor = false;
end

if ~iscell(matrices) || numel(matrices) ~= 2
    error('matrices must be a cell array with two groups.');
end

if numel(contrast) ~= 2
    error('contrast must contain two weights.');
end

if ~(isequal(contrast,[1 -1]) || isequal(contrast,[-1 1]))
    error('For two-sample NBS, contrast must be [1 -1] or [-1 1].');
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
% Observed t-statistics and primary threshold
% -------------------------------------------------------------------------
sum1_obs   = sum(X1,1);
sumsq1_obs = sum(X1.^2,1);

sum2_obs   = sum(X2,1);
sumsq2_obs = sum(X2.^2,1);

t_obs = tmfc_twosample_tstat_from_sums(sum1_obs, sumsq1_obs, nSub1, ...
                                       sum2_obs, sumsq2_obs, nSub2);

% Convert user-specified p-threshold to one common t-threshold
% using pooled-variance df as an approximation (right-tailed)
df_pooled = nSub1 + nSub2 - 2;
t_thr = tmfc_tinv(1 - primary_p, df_pooled);

% Build observed suprathreshold adjacency
obs_supra = false(nROI,nROI);
obs_supra(mask_ut) = (t_obs > t_thr);
obs_supra = obs_supra | obs_supra.';

% Observed full t matrix
tval = zeros(nROI,nROI);
tval(mask_ut) = t_obs;
tval = tval + tval.';
tval(1:1+nROI:end) = 0;

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

for c = 1:numel(obs_idx)
    nodes = find(obs_labels == obs_idx(c));

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
% Permutation null: max component statistic
% -------------------------------------------------------------------------
Xall = [X1; X2];
Xall2 = Xall.^2;
nAll = nSub1 + nSub2;
sum_all   = sum(Xall,1);
sumsq_all = sum(Xall2,1);
null_max = zeros(nperm,1);

if use_parfor

    h = helpdlg('Please wait...', 'TMFC NBS');
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

        supra = false(nROI,nROI);
        supra(mask_ut) = (t_perm > t_thr);
        supra = supra | supra.';

        if strcmp(nbs_stat,'NBS_intensity')
            t_perm_mat = zeros(nROI,nROI);
            t_perm_mat(mask_ut) = t_perm;
            t_perm_mat = t_perm_mat + t_perm_mat.';
        else
            t_perm_mat = [];
        end

        [perm_labels, perm_sizes] = get_components(supra);
        perm_idx_comp = find(perm_sizes > 1);

        max_stat = 0;
        for c = 1:numel(perm_idx_comp)
            nodes = find(perm_labels == perm_idx_comp(c));

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

    wb = waitbar(0,'Running NBS permutation test...','Name','TMFC NBS');
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

        supra = false(nROI,nROI);
        supra(mask_ut) = (t_perm > t_thr);
        supra = supra | supra.';

        if strcmp(nbs_stat,'NBS_intensity')
            t_perm_mat = zeros(nROI,nROI);
            t_perm_mat(mask_ut) = t_perm;
            t_perm_mat = t_perm_mat + t_perm_mat.';
        end

        [perm_labels, perm_sizes] = get_components(supra);
        perm_idx_comp = find(perm_sizes > 1);

        max_stat = 0;
        for c = 1:numel(perm_idx_comp)
            nodes = find(perm_labels == perm_idx_comp(c));

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

for c = 1:numel(obs_stat)
    comp_p = sum(null_max >= obs_stat(c)) / nperm;

    edge_mask = obs_edge_masks{c};
    pval(edge_mask) = comp_p;
    pval = min(pval, pval.');

    if comp_p <= alpha
        sig_count = sig_count + 1;
        thresholded(edge_mask | edge_mask.') = sig_count;

        components(sig_count).pvalue = comp_p;
        components(sig_count).n_connections = obs_nconn(c);
        components(sig_count).pairs = obs_pairs{c};
        components(sig_count).statistic = obs_stat(c);
        components(sig_count).matrix = edge_mask | edge_mask.';
    end
end

thresholded(1:1+nROI:end) = 0;
pval(1:1+nROI:end) = 1;

end

% -------------------------------------------------------------------------
function tval = tmfc_twosample_tstat_from_sums(sum1, sumsq1, n1, sum2, sumsq2, n2)
% Fast two-sample Welch t-statistic from sums and sums of squares.
% All inputs are row vectors [1 x Variables], except n1,n2 scalars.

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

% -------------------------------------------------------------------------
function close_waitbar_safe(wb)
if ~isempty(wb) && isgraphics(wb)
    close(wb);
end
end