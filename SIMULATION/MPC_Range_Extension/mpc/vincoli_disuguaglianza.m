function [c, G, Gmv, Ge] = vincoli_disuguaglianza(X, U, e, ~, dati)
%VINCOLI_DISUGUAGLIANZA  Vincoli c <= 0 dell'nlmpc.
%
%   y_min <= y_{k+j} + e                    eq. (6e) rilassata con la slack e, eq. (17)
%   eps_j <= sigma_{k+j}                    eq. (10) e (13a), per Jm e Jdelta
%   eps_{p+j} >= sigma_{k+j}                eq. (13b), per Jdelta
%
% Ogni blocco ha p*N righe, ordinate per cella: riga (n-1)*p + j <-> cella n,
% passo j. G, Gmv, Ge sono le derivate rispetto a X(2:p+1,:), U(1:p,:) ed e.

par = dati.par;
p   = dati.p;
N   = dati.pacco.numero_celle;
[Y, ~, ~, eps, D] = predizione_uscite(X, U, dati);
n_mv = N + numel(eps);
m    = p*N;

% Vincolo di tensione
c = par.mpc.y_min - Y(:) - e;
[G, Gmv] = derivate(-D.y_s, -D.y_v, -D.y_u, n_mv);
Ge = -ones(m, 1);

if ~strcmp(dati.tipo, 'Jt')
    % eps_j - sigma <= 0
    c = [c; reshape(eps(1:p) - D.sigma, [], 1)];
    [G2, Gmv2] = derivate(-D.sig_s, -D.sig_v, -D.sig_u, n_mv);
    for q = 1:m
        Gmv2(1, N + mod(q - 1, p) + 1, q) = 1;
    end
    G = cat(3, G, G2);  Gmv = cat(3, Gmv, Gmv2);  Ge = [Ge; zeros(m, 1)];
end
if strcmp(dati.tipo, 'Jdelta')
    % sigma - eps_{p+j} <= 0
    c = [c; reshape(D.sigma - eps(p+1:2*p), [], 1)];
    [G3, Gmv3] = derivate(D.sig_s, D.sig_v, D.sig_u, n_mv);
    for q = 1:m
        Gmv3(1, N + p + mod(q - 1, p) + 1, q) = -1;
    end
    G = cat(3, G, G3);  Gmv = cat(3, Gmv, Gmv3);  Ge = [Ge; zeros(m, 1)];
end

end

function [G, Gmv] = derivate(d_s, d_v, d_u, n_mv)
% Jacobiani di un blocco di p*N vincoli, ciascuno funzione di SOC, Vp e u di
% una sola cella a un solo passo. d_s, d_v, d_u sono p x N.
[p, N] = size(d_s);
G   = zeros(p, 2*N, p*N);
Gmv = zeros(p, n_mv, p*N);
for n = 1:N
    for j = 1:p
        q = (n - 1)*p + j;
        G(j, n, q)     = d_s(j, n);
        G(j, N + n, q) = d_v(j, n);
        Gmv(1, n, q)   = d_u(j, n);
    end
end
end
