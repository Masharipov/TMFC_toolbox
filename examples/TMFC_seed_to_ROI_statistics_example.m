%% Seed-to-ROI group-level statistics for asymmetrical gPPI matrices

clear; clc;

% -------------------------------------------------------------------------
% USER SETTINGS
% -------------------------------------------------------------------------

seed_ROI = 1;          % ROI number used as seed (e.g., STN)
target_ROIs = [];      % Target ROI numbers. [] = all ROIs except the seed

% Optional ROI names in the same order as in the TMFC ROI set.
% Leave empty to use ROI numbers in the output.
ROI_names = {};

% Optional covariates: Subjects x Covariates.
% IMPORTANT: rows must correspond exactly to the order of selected files.
% Example:
% covariates = [age sex];
%
% If testing the adjusted group mean with contrast [1 0 ...], continuous
% covariates should usually be centered beforehand if you want the
% intercept to represent the effect at the mean covariate value.
covariates = [];

% Statistical parameters
alpha = 0.05;
correction = 'FDR';    % 'uncorr', 'FDR', or 'Bonf'

% -------------------------------------------------------------------------
% SELECT SUBJECT MATRICES
% -------------------------------------------------------------------------

% Select subject-level contrast matrices from:
% ...\gPPI\ROI_to_ROI\asymmetrical\
matrix_files = spm_select(inf,'mat', ...
    'Select subject asymmetrical gPPI ROI-to-ROI contrast matrices');

if isempty(matrix_files)
    error('No matrices selected.');
end

nSub = size(matrix_files,1);

% -------------------------------------------------------------------------
% LOAD MATRICES AND EXTRACT SEED-TO-ROI CONNECTIONS
% -------------------------------------------------------------------------

for iSub = 1:nSub

    S = load(deblank(matrix_files(iSub,:)));

    if ~isfield(S,'ppi_matrix')
        error(['Selected file does not contain ppi_matrix. ' ...
               'Select gPPI matrices from the asymmetrical folder.']);
    end

    ppi_matrix = S.ppi_matrix;

    if ~isnumeric(ppi_matrix) || ndims(ppi_matrix) ~= 2 || ...
            size(ppi_matrix,1) ~= size(ppi_matrix,2)
        error('Subject %d: ppi_matrix must be a square numeric matrix.',iSub);
    end

    if iSub == 1
        nROI = size(ppi_matrix,1);

        if seed_ROI < 1 || seed_ROI > nROI || mod(seed_ROI,1) ~= 0
            error('seed_ROI must be an integer between 1 and %d.',nROI);
        end

        if isempty(target_ROIs)
            target_ROIs = setdiff(1:nROI,seed_ROI);
        end

        if any(target_ROIs < 1) || any(target_ROIs > nROI) || ...
                any(mod(target_ROIs,1) ~= 0)
            error('target_ROIs contain invalid ROI numbers.');
        end

        if any(target_ROIs == seed_ROI)
            error('target_ROIs must not include the seed ROI.');
        end

        target_ROIs = unique(target_ROIs,'stable');
        seed_data = zeros(nSub,length(target_ROIs));

    elseif size(ppi_matrix,1) ~= nROI
        error('Subject %d: matrix size differs from the first subject.',iSub);
    end

    % In TMFC asymmetrical gPPI matrices:
    %   rows    = target ROIs
    %   columns = seed ROIs
    %
    % Therefore, seed-to-ROI effects for the selected seed are taken from
    % the corresponding column.
    seed_data(iSub,:) = ppi_matrix(target_ROIs,seed_ROI)';

end

if any(~isfinite(seed_data(:)))
    error('Seed-to-ROI data contain NaN or Inf.');
end

% -------------------------------------------------------------------------
% DESIGN MATRIX
% -------------------------------------------------------------------------

if isempty(covariates)
    covariates = zeros(nSub,0);
elseif ~isnumeric(covariates) || size(covariates,1) ~= nSub
    error('Covariates must be a numeric Subjects x Covariates matrix.');
elseif any(~isfinite(covariates(:)))
    error('Covariates must contain only finite numeric values.');
end

% One-sample GLM:
% [intercept covariate_1 covariate_2 ...]
design = [ones(nSub,1), covariates];

% Main group effect adjusted for covariates
contrast = [1 zeros(1,size(covariates,2))];

% Example: effect of the first covariate
% contrast = [0 1 zeros(1,size(covariates,2)-1)];

% -------------------------------------------------------------------------
% GROUP-LEVEL GLM
% -------------------------------------------------------------------------

[thresholded,pval,tval,conval] = seed_to_ROI_glm( ...
    seed_data,design,contrast,alpha,correction);

% -------------------------------------------------------------------------
% DISPLAY RESULTS
% -------------------------------------------------------------------------

fprintf('\nSeed ROI: %d\n',seed_ROI);
fprintf('Number of subjects: %d\n',nSub);
fprintf('Number of tested seed-to-ROI connections: %d\n',length(target_ROIs));
fprintf('Correction: %s, alpha = %.4f\n\n',correction,alpha);

fprintf('%-8s %-25s %-12s %-12s %-12s %-6s\n', ...
    'ROI No','Target ROI','Estimate','t','p','Sig');

for iROI = 1:length(target_ROIs)

    if ~isempty(ROI_names) && length(ROI_names) >= target_ROIs(iROI)
        target_name = ROI_names{target_ROIs(iROI)};
    else
        target_name = ['ROI_' num2str(target_ROIs(iROI))];
    end

    fprintf('%-8d %-25s %-12.5f %-12.5f %-12.6g %-6d\n', ...
        target_ROIs(iROI),target_name,conval(iROI),tval(iROI), ...
        pval(iROI),thresholded(iROI));
end

% NOTE:
% seed_to_ROI_glm performs a right-tailed test, consistent with tmfc_glm.
% To test the opposite direction, use:
% contrast = -contrast;
%
% For a two-sided test following the standard TMFC example logic, run both
% directions separately using alpha/2.
%
% NBS and TFNBS are not applicable here because inference is restricted
% to a predefined set of seed-to-ROI connections rather than a complete
% ROI-to-ROI network.


%% ========================[ Local functions ]==============================

function [thresholded,pval,tval,conval] = seed_to_ROI_glm(data,design,contrast,alpha,correction)

% Classical GLM-based inference for a predefined set of seed-to-ROI edges.
%
% data       - Observations x Connections
% design     - Observations x Predictors
% contrast   - t-contrast vector
% alpha      - alpha level
% correction - 'uncorr', 'FDR', or 'Bonf'

[nObs,nEdges] = size(data);

if size(design,1) ~= nObs
    error('Number of rows in design must match number of observations.');
end

contrast = contrast(:);

if length(contrast) ~= size(design,2)
    error('Length of contrast must match number of design columns.');
end

if all(contrast == 0)
    error('contrast must contain at least one non-zero value.');
end

X = double(design);
Y = double(data);
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

beta = X \ Y;
conval = c' * beta;
resid = Y - X * beta;
mse = sum(resid.^2,1) ./ df;
se = sqrt(mse .* cvar);

tval = conval ./ se;

% Handle zero-variance connections
zv = (se == 0);
tval(zv & conval == 0) = 0;
tval(zv & conval ~= 0) = sign(conval(zv & conval ~= 0)) .* Inf;

% Right-tailed p-values
pval = 1 - tmfc_tcdf(tval,df);

switch correction
    case 'uncorr'
        thresholded = double(pval <= alpha);

    case 'FDR'
        alpha_FDR = FDR(pval,alpha);
        thresholded = double(pval <= alpha_FDR);

    case 'Bonf'
        alpha_Bonf = alpha / nEdges;
        thresholded = double(pval <= alpha_Bonf);

    otherwise
        error('Unsupported correction type. Use ''uncorr'', ''FDR'', or ''Bonf''.');
end

end


function pID = FDR(p,q)

p = p(isfinite(p));
p = sort(p(:));
V = length(p);
I = (1:V)';
cVID = 1;

pID = p(max(find(p <= I/V*q/cVID)));

if isempty(pID)
    pID = 0;
end

end
