function p = tmfc_tcdf(x, v)
% TMFC_TCDF Lower-tail CDF of Student's t distribution.
%
% p = tmfc_tcdf(x, v)
%
% INPUTS
% x - scalar, vector, or matrix of t values
% v - degrees of freedom (positive scalar or same size as x)
%
% OUTPUT
% p - lower-tail cumulative probability P(T <= x)
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later

    if nargin ~= 2
        error('tmfc_tcdf requires exactly 2 inputs: x and v.');
    end

    if ~isnumeric(x) || ~isnumeric(v)
        error('Inputs x and v must be numeric.');
    end

    if isscalar(v)
        v = repmat(v, size(x));
    elseif ~isequal(size(x), size(v))
        error('v must be either a scalar or the same size as x.');
    end

    p = NaN(size(x));

    valid = isfinite(x) & isfinite(v) & (v > 0);
    if ~any(valid(:))
        return;
    end

    xv = x(valid);
    vv = v(valid);

    z = vv ./ (vv + xv.^2);
    ib = betainc(z, vv/2, 1/2);

    pv = zeros(size(xv));

    neg = xv < 0;
    zer = xv == 0;
    pos = xv > 0;

    pv(neg) = 0.5 .* ib(neg);
    pv(zer) = 0.5;
    pv(pos) = 1 - 0.5 .* ib(pos);

    p(valid) = pv;

    p(x == -Inf & isfinite(v) & v > 0) = 0;
    p(x ==  Inf & isfinite(v) & v > 0) = 1;
end