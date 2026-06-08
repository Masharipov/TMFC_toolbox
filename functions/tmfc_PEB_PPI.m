function tmfc_PEB_PPI(CACHE, iSub)  

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Subject-level PPI computation (called from tmfc_PPI).
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

subj = CACHE.subjects.sublist(iSub);
nSub   = CACHE.subjects.nSub;

ROIset = CACHE.ROIset;
nROI   = length(ROIset.ROIs);

cond_list      = CACHE.conditions.list;
nCond          = CACHE.conditions.nCond;
conds_by_sess  = CACHE.conditions.by_session;

sess_num = CACHE.sessions.list;
maxSess  = CACHE.sessions.max;

% Subject folder
% -------------------------------------------------------------------------
outPath = fullfile(CACHE.project_path,'ROI_sets', ...
    CACHE.ROIset.set_name,'PPIs',subj.name);

if isdir(outPath)
    rmdir(outPath,'s'); pause(0.1);
end
if ~isdir(outPath)
    mkdir(outPath);
end

voiBasePath = fullfile(CACHE.project_path,'ROI_sets',ROIset.set_name,'VOIs',subj.name);

% Load SPM
% -------------------------------------------------------------------------
SPM = load(subj.path).SPM;

% -------------------------------------------------------------------------
% Subject-level precompute: timing + HRF + PSY per condition (microtime)
% -------------------------------------------------------------------------
RT      = SPM.xY.RT;
dt      = SPM.xBF.dt;
NT      = round(RT/dt);
fMRI_T0 = SPM.xBF.T0;

bf = SPM.xBF.bf;
hrf = bf(:,1);

switch lower(strtrim(SPM.xBF.name))
    case {'hrf', ...
          'hrf (with time derivative)', ...
          'hrf (with time and dispersion derivatives)'}
    otherwise
        error('TMFC supports only canonical HRF, time derivative, and dispersion derivative.');
end

psy_u = cell(1, nCond);
ppi_bf = cell(1, nCond);

for jCond = 1:nCond
    s    = cond_list(jCond).sess;
    Sess = SPM.Sess(s);

    % gPPI mode: Uu is 1x3: [U_index, u_column, weight]
    try
        Uu = [cond_list(jCond).number cond_list(jCond).pmod 1];
    catch
        Uu = [cond_list(jCond).number 1 1];
    end

    PSY = full(Sess.U(Uu(1,1)).u(33:end, Uu(1,2)) * Uu(1,3));

    % Mean centering (optional)
    if strcmp(ROIset.PPI_centering,'with_mean_centering') || ...
       strcmp(ROIset.PPI_centering,'mean_centering')
        PSY = spm_detrend(PSY);
    end

    psy_u{jCond} = PSY;

    % Explicitly selected basis function:
    %   bf = 1  canonical HRF
    %   bf = 2  time derivative
    %   bf = 3  dispersion derivative
    
    % Backward compatibility:
    % old projects do not have .bf, so use canonical HRF.
    if isfield(cond_list,'bf') && ~isempty(cond_list(jCond).bf)
        bf_id = cond_list(jCond).bf;
    else
        bf_id = 1;
    end

    if numel(bf_id) ~= 1 || isnan(bf_id) || bf_id < 1 || bf_id > size(bf,2)
        error('Basis function %d does not exist for condition "%s".', ...
              bf_id, cond_list(jCond).name);
    end
    
    ppi_bf{jCond} = bf(:,bf_id);
end

% -------------------------------------------------------------------------
% Session loop (precompute xb/P once; preload all Y once)
% -------------------------------------------------------------------------
for s = sess_num(:)'

    Sess = SPM.Sess(s);
    rows = Sess.row(:);
    N    = numel(rows);
    k    = 1:NT:N*NT;         % microtime to scan time indice

    % Create convolved explanatory {Hxb} variables in scan time
    %------------------------------------------------------------------
    xb = spm_dctmtx(N*NT + 128, N);
    Hxb = zeros(N, N);
    for i = 1:N
        Hx       = conv(xb(:,i), hrf);
        Hxb(:,i) = Hx(k + 128);
    end
    xb = xb(129:end,:);

    % Get confounds (in scan time) and constant term
    %------------------------------------------------------------------
    X0 = SPM.xX.xKXs.X(:,[SPM.xX.iB SPM.xX.iG]);
    X0 = X0(rows,:);

    if numel(SPM.Sess) == 1 && numel(SPM.xX.K) > 1
        X0 = [X0 blkdiag(SPM.xX.K.X0)]; % concatenated
    else
        X0 = [X0 SPM.xX.K(s).X0];
    end

    X0 = X0(:,any(X0));
    M  = size(X0,2);

    % Specify covariance components; assume neuronal response is white
    % treating confounds as fixed effects
    %------------------------------------------------------------------
    Q = speye(N,N)*N/trace(Hxb'*Hxb);
    Q = blkdiag(Q, speye(M,M) * 1e6);

    % Get whitening matrix (NB: confounds have already been whitened)
    %------------------------------------------------------------------
    W = SPM.xX.W(rows,rows);

    % Create structure for spm_PEB
    %------------------------------------------------------------------
    P = cell(1,2);
    P{1}.X = [W*Hxb X0];        % Design matrix for lowest level
    P{1}.C = speye(N,N)/4;      % i.i.d assumptions
    P{2}.X = sparse(N + M,1);   % Design matrix for parameters (0's)
    P{2}.C = Q;

    %-----------------------------------------------------------------------------------
    % NOTE: SPM PEB assumes i.i.d. errors. Therefore, both the deconvolution
    % matrix and the data must be WHITENED. Applying inverse whitening at this
    % stage would lead to a mismatch between DATA and DECONVOLUTION MATRIX
    % whitening. Later, for the gPPI model, we use the raw (not whitened) BOLD signal
    % for the PHYS regressor to avoid the double-whitening issue (see He et al., 2025).
    %-----------------------------------------------------------------------------------

    % --------------------------------------------------------------
    % Preload all VOI time series for this session
    % --------------------------------------------------------------
    Yall = cell(1, nROI);
    for kROI = 1:nROI
        roiName = ROIset.ROIs(kROI).name;
        voiFile = fullfile(voiBasePath, sprintf('VOI_%s_%d.mat', roiName, s));
        Yall{1,kROI} = load(voiFile).Y;
    end

    % --------------------------------------------------------------
    % Prepare list of conditions in this session
    % --------------------------------------------------------------
    jConds = conds_by_sess{s};
    nCond_s = numel(jConds);

    % --------------------------------------------------------------
    % Compute PPI for each (cond, ROI)
    % --------------------------------------------------------------
    for ii = 1:nCond_s
        jCond = jConds(ii);
        PSY   = psy_u{jCond};

        for kROI = 1:nROI

            roiName = ROIset.ROIs(kROI).name;
            Y = Yall{1,kROI};

            fprintf('[PPI] Sub %02d/%02d | Sess %02d/%02d | Cond %02d/%02d | ROI %03d/%03d (%s)\n', ...
                iSub, nSub, s, maxSess, jCond, nCond, kROI, nROI, roiName);

            % Deconvolution (PEB)
            C  = spm_PEB(Y, P);
            xn = xb * C{2}.E(1:N);
            xn = spm_detrend(xn);

            % Multiply psychological variable by neural signal (microtime)
            PSYxn = PSY .* xn;

            % Convolve, convert to scan time, and account for slice timing shift
            ppi = conv(PSYxn, ppi_bf{jCond});
            ppi = ppi((k-1) + fMRI_T0);
            ppi = spm_detrend(ppi);
            
            % PPI struct
            PPI = struct();
            PPI.name = ['[' regexprep(roiName,' ','_') ']_' cond_list(jCond).file_name];
            PPI.ppi  = ppi;

            % Save
            outFile = fullfile(outPath, ...
            ['PPI_[' regexprep(roiName,' ','_') ']_' cond_list(jCond).file_name '.mat']);
            save(outFile, 'PPI');
        end
    end

    clear xb Hxb X0 Q W P Yall
end
end