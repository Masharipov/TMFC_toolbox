function x = tmfc_tinv(p, v)
% TMFC_TINV Inverse lower-tail CDF of Student's t distribution.
%
% x = tmfc_tinv(p, v)
%
% INPUTS
% p - scalar, vector, or matrix of probabilities in [0,1]
% v - degrees of freedom (positive scalar or same size as p)
%
% OUTPUT
% x - t value such that P(T <= x) = p
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later

    if nargin ~= 2
        error('tmfc_tinv requires exactly 2 inputs: p and v.');
    end

    if ~isnumeric(p) || ~isnumeric(v)
        error('Inputs p and v must be numeric.');
    end

    if isscalar(v)
        v = repmat(v, size(p));
    elseif ~isequal(size(p), size(v))
        error('v must be either a scalar or the same size as p.');
    end

    x = NaN(size(p));

    valid = isfinite(p) & isfinite(v) & (v > 0) & (p >= 0) & (p <= 1);
    if ~any(valid(:))
        return;
    end

    pv = p(valid);
    vv = v(valid);

    xv = zeros(size(pv));

    is0 = (pv == 0);
    is1 = (pv == 1);
    isc = (pv == 0.5);
    ilo = (pv > 0) & (pv < 0.5);
    ihi = (pv > 0.5) & (pv < 1);

    xv(is0) = -Inf;
    xv(is1) =  Inf;
    xv(isc) = 0;

    if any(ilo)
        y = betaincinv(2*pv(ilo), vv(ilo)/2, 1/2);
        xv(ilo) = -sqrt(vv(ilo) .* (1 - y) ./ y);
    end

    if any(ihi)
        y = betaincinv(2*(1 - pv(ihi)), vv(ihi)/2, 1/2);
        xv(ihi) = sqrt(vv(ihi) .* (1 - y) ./ y);
    end

    x(valid) = xv;
end