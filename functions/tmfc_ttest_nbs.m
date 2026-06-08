function [thresholded,pval,tval,conval,components] = tmfc_ttest_nbs(matrices,contrast,alpha,primary_p,nperm,nbs_stat,use_parfor)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs one-sample and paired-sample network based statistics (NBS)
% permutation test for symmetric connectivity matrices using sign-flipping.
%
% Family-wise error (FWE) is controlled at the component level
% using either extent- or intensity-based thresholding.
%
% FORMAT
%   [thresholded,pval,tval,conval] = tmfc_ttest_nbs(matrices,contrast,alpha,primary_p,nperm,nbs_stat)
%   [thresholded,pval,tval,conval,components] = tmfc_ttest_nbs(matrices,contrast,alpha,primary_p,nperm,nbs_stat,use_parfor)
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
    error('tmfc_ttest_nbs requires 6 inputs: matrices, contrast, alpha, primary_p, nperm, nbs_stat.');
end

if nargin < 7
    use_parfor = false;
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

% Group mean contrast value
conval = mean(matrices,3);

% -------------------------------------------------------------------------
% Convert upper triangle to [Subjects x Edges]
% -------------------------------------------------------------------------
mask_ut = triu(true(nROI),1);

X = reshape(matrices, nROI*nROI, nSub);
X = X(mask_ut,:).';   % [nSub x nEdges]

% -------------------------------------------------------------------------
% Observed t-statistics and primary threshold
% -------------------------------------------------------------------------
sum_obs = sum(X,1);
sumsq_all = sum(X.^2,1);
t_obs = tmfc_onesample_tstat_from_sums(sum_obs, sumsq_all, nSub);
df = nSub - 1;

% Right-tailed p -> t threshold
t_thr = tmfc_tinv(1 - primary_p, df);

% Build observed suprathreshold adjacency
obs_supra = false(nROI,nROI);
obs_supra(mask_ut) = (t_obs > t_thr);
obs_supra = obs_supra | obs_supra.';

% Observed full t matrix
tval = zeros(nROI,nROI);
tval(mask_ut) = t_obs;
tval = tval + tval.';

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

    % Suprathreshold edges within this connected component
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
null_max = zeros(nperm,1);

if use_parfor

    h = helpdlg('Please wait...', 'TMFC NBS');
    cleanupObj = onCleanup(@() close_waitbar_safe(h));
    
    parfor iPerm = 1:nperm
        s = 2*(rand(nSub,1) > 0.5) - 1;
        sum1p = s' * X;
        t_perm = tmfc_onesample_tstat_from_sums(sum1p, sumsq_all, nSub);

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
        perm_idx = find(perm_sizes > 1);

        max_stat = 0;
        for c = 1:numel(perm_idx)
            nodes = find(perm_labels == perm_idx(c));

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
    
    sign_mat = rand(nSub,nperm);
    sign_mat = 2*(sign_mat > 0.5) - 1;  
    
    for iPerm = 1:nperm
        s = sign_mat(:,iPerm);
        sum1p = s' * X;
        t_perm = tmfc_onesample_tstat_from_sums(sum1p, sumsq_all, nSub);
    
        supra = false(nROI,nROI);
        supra(mask_ut) = (t_perm > t_thr);
        supra = supra | supra.';
    
        % Full symmetric t matrix for intensity mode
        if strcmp(nbs_stat,'NBS_intensity')
            t_perm_mat = zeros(nROI,nROI);
            t_perm_mat(mask_ut) = t_perm;
            t_perm_mat = t_perm_mat + t_perm_mat.';
        end
    
        [perm_labels, perm_sizes] = get_components(supra);
        perm_idx = find(perm_sizes > 1);
    
        max_stat = 0;
        for c = 1:numel(perm_idx)
            nodes = find(perm_labels == perm_idx(c));
    
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
    comp_p = sum(null_max >= obs_stat(c))/nperm;

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

        comp_mat = edge_mask | edge_mask.';
        components(sig_count).matrix = comp_mat;
    end
end

thresholded(1:1+nROI:end) = 0;

pval(1:1+nROI:end) = 1;

end

% -------------------------------------------------------------------------
function tval = tmfc_onesample_tstat_from_sums(sum1, sumsq_all, n)
% Fast one-sample t-statistic from signed sums and fixed sums of squares.

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
function [comps,comp_sizes] = get_components(adj)
% Connected components for an undirected adjacency matrix
%
% Outputs:
%   comps      - component label for each node
%   comp_sizes - size of each component

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