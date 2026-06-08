function [thresholded,pval,tval,conval] = tmfc_ttest2_perm(matrices,contrast,alpha,correction,nperm)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs two-sample non-parametric permutation t-test
% for symmetric connectivity matrices using group-label permutation.
%
% FORMAT
%   [thresholded,pval,tval,conval] = tmfc_ttest2_perm(matrices,contrast,alpha,correction,nperm)
%
% INPUTS
%
% matrices    - functional connectivity matrices (cell array):
%               matrices{1} - 1st group, 3-D array (ROI x ROI x Subjects)
%               matrices{2} - 2nd group, 3-D array (ROI x ROI x Subjects)
% contrast    - contrast weights
% alpha       - alpha level
% correction  - correction for multiple comparisons:
%               'perm_uncorr' - uncorrected permutation p-values
%               'perm_FDR'    - FDR correction of permutation p-values
% nperm       - number of permutations
%
% OUTPUTS
%
% thresholded - thresholded binary matrix
% pval        - uncorrected permutation p-value matrix
% tval        - observed t-value matrix
% conval      - group mean contrast value
%
% Notes
%   - One-sided right-tailed test, consistent with current tmfc_ttest2.
%   - Uses Welch t-statistic within each permutation.
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% -------------------------------------------------------------------------
% Prepare data
% -------------------------------------------------------------------------
if nargin < 5
    error('tmfc_ttest2_perm requires 5 inputs: matrices, contrast, alpha, correction, nperm.');
end

if ~iscell(matrices) || numel(matrices) ~= 2
    error('matrices must be a cell array with two groups.');
end

if numel(contrast) ~= 2
    error('contrast must contain two weights.');
end

if ~isscalar(nperm) || ~isfinite(nperm) || nperm <= 0 || mod(nperm,1) ~= 0
    error('nperm must be a positive integer.');
end

group1 = matrices{1};
group2 = matrices{2};

if ndims(group1) ~= 3 || ndims(group2) ~= 3
    error('Both groups must be ROI x ROI x Subjects.');
end

if ~(isequal(contrast,[1 -1]) || isequal(contrast,[-1 1]))
    error('For two-sample tests, contrast must be [1 -1] or [-1 1].');
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
idx = find(triu(true(nROI),1));
nEdges = numel(idx);

X1 = reshape(first_group, nROI*nROI, nSub1);
X1 = X1(idx,:).';   % [nSub1 x nEdges]

X2 = reshape(second_group, nROI*nROI, nSub2);
X2 = X2(idx,:).';   % [nSub2 x nEdges]

% Observed statistic
sum1_obs   = sum(X1,1);
sumsq1_obs = sum(X1.^2,1);

sum2_obs   = sum(X2,1);
sumsq2_obs = sum(X2.^2,1);

t_obs = tmfc_twosample_tstat_from_sums(sum1_obs, sumsq1_obs, nSub1, ...
                                       sum2_obs, sumsq2_obs, nSub2);

% Pool data once
Xall  = [X1; X2];
Xall2 = Xall.^2;
nAll  = nSub1 + nSub2;

sum_all   = sum(Xall,1);
sumsq_all = sum(Xall2,1);

counts = zeros(1,nEdges,'uint32');

wb = waitbar(0,'Running permutation test...','Name','TMFC permutation test');
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

    % Right-tailed exceedance count
    counts = counts + uint32(t_perm >= t_obs);

    if mod(iPerm,50) == 0 || iPerm == nperm
        try
            waitbar(iPerm/nperm, wb, sprintf('Permutation %d of %d', iPerm, nperm));
        end
    end
end

% Permutation p-values
p_perm = double(counts + 1) ./ double(nperm + 1);

% -------------------------------------------------------------------------
% Rebuild symmetric matrices
% -------------------------------------------------------------------------
pval = zeros(nROI,nROI);
tval = zeros(nROI,nROI);

pval(idx) = p_perm;
pval = pval + pval.';
pval(1:1+nROI:end) = 1;

tval(idx) = t_obs;
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
        warning('Unsupported correction type for tmfc_ttest2_perm.');
end

end

% -------------------------------------------------------------------------
function tval = tmfc_twosample_tstat_from_sums(sum1, sumsq1, n1, sum2, sumsq2, n2)
% Fast two-sample Welch t-statistic from sums and sums of squares.
% All inputs are row vectors [1 x Variables], except n1,n2 scalars.

mx = sum1 ./ n1;
my = sum2 ./ n2;

% sample variances (unbiased, ddof = 1)
vx = (sumsq1 - (sum1.^2)./n1) ./ (n1 - 1);
vy = (sumsq2 - (sum2.^2)./n2) ./ (n2 - 1);

% numerical guard
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
function low = lower_triangle(matrix)
matrix(1:1+size(matrix,1):end) = NaN;
low = matrix(tril(true(size(matrix)))).';
low(isnan(low)) = [];
end

% -------------------------------------------------------------------------
function pID = FDR(p,q)
p = p(isfinite(p));
p = sort(p(:));
V = length(p);
I = (1:V)';
cVID = 1;

pID = p(max(find(p<=I/V*q/cVID)));
if isempty(pID), pID=0; end
end

% -------------------------------------------------------------------------
function close_waitbar_safe(wb)
if ~isempty(wb) && isgraphics(wb)
    close(wb);
end
end