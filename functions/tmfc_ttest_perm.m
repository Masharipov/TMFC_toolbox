function [thresholded,pval,tval,conval] = tmfc_ttest_perm(matrices,contrast,alpha,correction,nperm)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Performs one-sample and paired-sample non-parametric permutation t-test
% for symmetric connectivity matrices using sign-flipping.
%
% FORMAT
%   [thresholded,pval,tval,conval] = tmfc_ttest_perm(matrices,contrast,alpha,correction,nperm)
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
%   - One-sided right-tailed test, consistent with current tmfc_ttest.
%   - Paired test is implemented as sign-flipping on the subject-wise
%     contrast difference matrices.
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% -------------------------------------------------------------------------
% Prepare data
% -------------------------------------------------------------------------
if nargin < 5
    error('tmfc_ttest_perm requires 5 inputs: matrices, contrast, alpha, correction, nperm.');
end

if ~isscalar(nperm) || ~isfinite(nperm) || nperm <= 0 || mod(nperm,1) ~= 0
    error('nperm must be a positive integer.');
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
idx = find(triu(true(nROI),1));
nEdges = numel(idx);

X = reshape(matrices, nROI*nROI, nSub);
X = X(idx,:).';   % [nSub x nEdges]

% -------------------------------------------------------------------------
% Observed t-statistics
% -------------------------------------------------------------------------
sum_obs    = sum(X,1);
sumsq_all  = sum(X.^2,1);
t_obs      = tmfc_onesample_tstat_from_sums(sum_obs, sumsq_all, nSub);

% -------------------------------------------------------------------------
% Permutation null via sign-flipping
% -------------------------------------------------------------------------
counts = zeros(1,nEdges,'uint32');

% Pre-generate sign matrix
sign_mat = rand(nSub,nperm);
sign_mat = 2*(sign_mat > 0.5) - 1;   % +/-1

wb = waitbar(0,'Running permutation test...','Name','TMFC permutation test');
cleanupObj = onCleanup(@() close_waitbar_safe(wb));

for iPerm = 1:nperm
    s = sign_mat(:,iPerm);
    sum_perm = s' * X;
    t_perm   = tmfc_onesample_tstat_from_sums(sum_perm, sumsq_all, nSub);

    % Right-tailed exceedance count
    counts = counts + uint32(t_perm >= t_obs);

    if mod(iPerm,50)==0 || iPerm==nperm
        try
            waitbar(iPerm/nperm, wb, sprintf('Permutation %d of %d', iPerm, nperm));
        end
    end
end

if isgraphics(wb)
    close(wb);
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
pval(1:1+nROI:end) = 1;   % diagonal

tval(idx) = t_obs;
tval = tval + tval.';

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
        warning('Unsupported correction type for tmfc_ttest_perm.');
end

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

