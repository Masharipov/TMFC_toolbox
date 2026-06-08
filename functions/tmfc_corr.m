function R = tmfc_corr(X,Y)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
% 
% Fast linear correlation (x2–x29 faster than CORR), no p-values.
% Uses all rows, matching CORR’s default 'rows','all' option:
% if a column contains any NaN, all correlations involving that column
% are returned as NaN (no pairwise NaN handling).
%
% R = tmfc_corr(X)   - returns a P-by-P matrix of pairwise correlations
%                      between columns of X (N-by-P).
% R = tmfc_corr(X,Y) - returns  P1-by-P2 matrix of pairwise correlations
%                      between columns of X (N-by-P1) and Y (N-by-P2).
%
% =========================================================================
% Copyright (C) 2025 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

    
% detect symmetric mode
if nargin < 2 || isempty(Y)
    Y = X;
    symXX = true;
else
    symXX = false;
    if size(X,1) ~= size(Y,1)
        error('X and Y must have the same number of rows.');
    end
end

[n, p] = size(X);
q      = size(Y,2);

if n < 2
    R = NaN(p, q, 'like', X);
    return
end

% Mark columns with any NaN
badX = any(isnan(X), 1);
badY = any(isnan(Y), 1);
goodX = ~badX;
goodY = ~badY;

% Preallocate output as NaN
R = NaN(p, q, 'like', X);

if any(goodX) && any(goodY)
    Xg = X(:, goodX);
    Yg = Y(:, goodY);

    % Means over all rows (no NaNs in Xg/Yg by construction)
    mx = mean(Xg, 1);
    my = mean(Yg, 1);

    % Centered
    X0 = bsxfun(@minus, Xg, mx);
    Y0 = bsxfun(@minus, Yg, my);

    % Sample std (N-1)
    sx = std(X0, 0, 1);
    sy = std(Y0, 0, 1);

    % Zero-variance columns -> invalid
    zx = (sx == 0);
    zy = (sy == 0);

    % Guard zeros to avoid division by zero
    sx(zx) = NaN; % mark invalid; we'll NaN out their rows/cols
    sy(zy) = NaN;

    if symXX && (p == q) && isequal(Xg, Yg)
        % === Upper-triangle-only path for symmetric X–X ===
        % Work only on valid (non-NaN, non-const) columns
        validX = ~zx;               % among goodX
        gIdx = find(goodX);         % map to full indices
        vIdx = find(validX);        % indices into X0 columns that are valid
        pv   = numel(vIdx);

        if pv > 0
            % Blocked upper triangle to control memory
            BLK = 1024; % tune as needed (512–2048 reasonable)
            Rgg = NaN(sum(goodX), sum(goodY), 'like', X);

            for i1 = 1:BLK:pv
                i2 = min(pv, i1+BLK-1);
                Xi = X0(:, vIdx(i1:i2));
                sxi = sx(vIdx(i1:i2));  % 1-by-Bi

                for j1 = i1:BLK:pv   % start at i1 to cover upper triangle only
                    j2 = min(pv, j1+BLK-1);
                    Xj = X0(:, vIdx(j1:j2));
                    syj = sx(vIdx(j1:j2));  % 1-by-Bj

                    % Cov block (sample): (Xi' * Xj) / (n-1)
                    Cblk = (Xi.' * Xj) ./ (n-1);

                    % Denominator block: sx_i' * sx_j
                    denom = (sxi.' * syj);
                    denom = max(denom, eps(class(denom)));

                    Rblk = Cblk ./ denom;

                    % Place into valid-valid submatrix (upper block)
                    Rgg(vIdx(i1:i2), vIdx(j1:j2)) = Rblk;

                    % Mirror to lower block if off-diagonal
                    if j1 > i1
                        Rgg(vIdx(j1:j2), vIdx(i1:i2)) = Rblk.'; 
                    end
                end
            end

            % Put Rgg into full R on good-good positions
            R(goodX, goodY) = Rgg;
        end

        % Invalidate rows/cols for zero-variance among good columns
        if any(zx)
            rows_zero = false(1,p); rows_zero(goodX) = zx;
            R(rows_zero, :) = NaN;
            R(:, rows_zero) = NaN;
        end

    else
        % === General X–Y (or non-identical X–X) full GEMM path ===
        % Covariance and scaling in one go
        C = (X0.' * Y0) ./ (n - 1);
        denom = (sx.' * sy);
        denom = max(denom, eps(class(denom)));
        Rgg = C ./ denom;

        % Place into full matrix
        R(goodX, goodY) = Rgg;

        % Invalidate zero-variance
        if any(zx)
            rows_zero = false(1,p); rows_zero(goodX) = zx;
            R(rows_zero, :) = NaN;
        end
        if any(zy)
            cols_zero = false(1,q); cols_zero(goodY) = zy;
            R(:, cols_zero) = NaN;
        end
    end
end

% Invalidate NaN columns from original inputs
if any(badX), R(badX, :) = NaN; end
if any(badY), R(:, badY) = NaN; end

% For symmetric X–X, set exact diagonal = 1 for valid, non-constant columns
if symXX && (p == q)
    valid_diag = (~badX) & (var(X, 0, 1) > 0);
    d = 1:p; di = d(valid_diag);
    R(sub2ind([p p], di, di)) = 1;
end
    
end