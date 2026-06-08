function tmfc_regions(SPM, name, maskPath, outPath, Ic, sess_num, thr)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Fast replacement for spm_run_voi and spm_regions.
% Extracts VOI time series and saves only necessary data.
%
% FORMAT tmfc_regions(SPM, name, maskPath, outPath, Ic, sess_num, thr)
%
% INPUTS:
%   SPM      - SPM structure loaded from SPM.mat
%   name     - ROI name
%   maskPath - Path to ROI mask image
%   outPath  - Output directory for VOI_*.mat files
%   Ic       - Index of F-contrast used for adjustment (as defined in SPM.xCon)
%              (0 = no adjustment, NaN - adjust for everything)
%   sess_num - Session index/indices (as defined in SPM.Sess). Scalar or vector.
%   thr      - Mask threshold (default: 0.1)
%
% OUTPUT:
%   Saves session-specific VOI files:
%     VOI_<name>_<sess>.mat 
%   Each file contains:
%     Y    - first eigenvariate of whitened, filtered, contrast-adjusted VOI time series
%     Yraw - first eigenvariate of raw (demeaned) VOI time series
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin < 7 || isempty(thr), thr = 0.1; end


% Get raw data from ROI mask
% -------------------------------------------------------------------------

% Load mask
Vm  = spm_vol(maskPath);
m   = spm_read_vols(Vm);
idx = find(m > thr);        
[x,y,z] = ind2sub(Vm.dim, idx);
XYZ = [x'; y'; z'];   

% Raw voxel-wise data from functional volumes (all scans)
Yraw_all = spm_data_read(SPM.xY.VY,'xyz',XYZ);     % [nScan x nVox]

if isempty(Yraw_all) || size(Yraw_all,2)==0
    return
end

if any(~isfinite(Yraw_all(:)))
    error('tmfc_regions:NonFiniteData','Data contain NaN or Inf. Check VOI mask / data.');
end

% Whiten and high-pass filter
% -------------------------------------------------------------------------
Y_all = spm_filter(SPM.xX.K,SPM.xX.W*Yraw_all); % [nScan x nVox]

% Get absolute paths for betas
% -------------------------------------------------------------------------
for iBeta = 1:numel(SPM.Vbeta)
    if isempty(strfind(SPM.Vbeta(iBeta).fname, filesep))
        SPM.Vbeta(iBeta).fname = fullfile(SPM.swd, SPM.Vbeta(iBeta).fname);
    end
end

% Remove null space of contrast
% -------------------------------------------------------------------------
if Ic ~= 0
 
    % Parameter estimates: beta = xX.pKX*xX.K*y
    % ---------------------------------------------------------------------
    beta = spm_data_read(SPM.Vbeta,'xyz',XYZ);
 
    % Subtract Y0 = XO*beta,  Y = Yc + Y0 + e
    % ---------------------------------------------------------------------
    if ~isnan(Ic)
        % Adjust w.r.t. null space of F-contrast Ic
        Y_all = Y_all - spm_FcUtil('Y0',SPM.xCon(Ic),SPM.xX.xKXs,beta);
    else
        % Adjust for everything
        Y_all = Y_all - SPM.xX.xKXs.X * beta;
    end
end

% Compute first eigenvariate (session-specific)
% -------------------------------------------------------------------------
sess_num = sess_num(:)';             
nSess     = numel(sess_num);

if ~exist(outPath,'dir'), mkdir(outPath); end

for iSess = 1:nSess
    s = sess_num(iSess);
   
    Yraw = []; Y = [];

    % Session rows
    rows = SPM.Sess(s).row(:);

    % Raw eigenvariate
    Yraw = spm_detrend(Yraw_all(rows,:));
    Yraw = first_eig_scaled(Yraw);

    % Clean eigenvariate
    Y = first_eig_scaled(Y_all(rows,:));

    % Save session-specific VOI_*.mat in outPath
    fname = sprintf('VOI_%s_%d.mat', name, s);
    save(fullfile(outPath,fname), 'Y','Yraw');
end
end


function Y = first_eig_scaled(y)
% Match spm_regions scaling convention: Y = u * sqrt(s1/nVox)
[m,n] = size(y);
if m == 0 || n == 0
    Y = [];
    return;
end
if m > n
    [V,S] = svd(y'*y,'econ');
    s     = diag(S);
    v1    = V(:,1);
    u1    = y*v1 / sqrt(s(1));
else
    [U,S] = svd(y*y','econ');
    s     = diag(S);
    u1    = U(:,1);
    v1    = y'*u1 / sqrt(s(1));
end
d  = sign(sum(v1)); if d == 0, d = 1; end
u1 = u1*d;
Y  = u1 * sqrt(s(1)/n);
end