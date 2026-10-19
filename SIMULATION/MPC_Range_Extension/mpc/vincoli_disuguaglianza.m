function [cineq, G, Gmv, G_epsilon_y] = vincoli_disuguaglianza(X, U, epsilon_y, ~, dati)
%VINCOLI_DISUGUAGLIANZA  Vincoli cineq <= 0 dell'nlmpc.
%
%   y_min <= y_{k+j} + epsilon_y        eq. (6e) rilassata con la variabile epsilon_y, eq. (17)
%   epsilon_j <= sigma_{k+j}            eq. (10) e (13a), per Jm e Jdelta
%   epsilon_{p+j} >= sigma_{k+j}        eq. (13b), per Jdelta
%
% Ogni blocco ha p*N righe, ordinate per cella: riga (n-1)*p + j <-> cella n,
% passo j. G, Gmv, G_epsilon_y sono le derivate rispetto a X(2:p+1,:),
% U(1:p,:) ed epsilon_y.

par = dati.par;
p   = dati.p;
N   = dati.pacco.N;
[Y, ~, ~, epsilon, der] = predizione_uscite(X, U, dati);
n_mv     = N + numel(epsilon);
n_blocco = p*N;

% Vincolo di tensione
cineq = par.mpc.y_min - Y(:) - epsilon_y;
[G, Gmv] = derivate(-der.ds_y, -der.dVp_y, -der.du_y, n_mv);
G_epsilon_y = -ones(n_blocco, 1);

if ~strcmp(dati.tipo, 'Jt')
    % epsilon_j - sigma <= 0
    cineq = [cineq; reshape(epsilon(1:p) - der.sigma, [], 1)];
    [G2, Gmv2] = derivate(-der.ds_sigma, -der.dVp_sigma, -der.du_sigma, n_mv);
    for q = 1:n_blocco
        Gmv2(1, N + mod(q - 1, p) + 1, q) = 1;
    end
    G = cat(3, G, G2);  Gmv = cat(3, Gmv, Gmv2);  G_epsilon_y = [G_epsilon_y; zeros(n_blocco, 1)];
end
if strcmp(dati.tipo, 'Jdelta')
    % sigma - epsilon_{p+j} <= 0
    cineq = [cineq; reshape(der.sigma - epsilon(p+1:2*p), [], 1)];
    [G3, Gmv3] = derivate(der.ds_sigma, der.dVp_sigma, der.du_sigma, n_mv);
    for q = 1:n_blocco
        Gmv3(1, N + p + mod(q - 1, p) + 1, q) = -1;
    end
    G = cat(3, G, G3);  Gmv = cat(3, Gmv, Gmv3);  G_epsilon_y = [G_epsilon_y; zeros(n_blocco, 1)];
end

end

function [G, Gmv] = derivate(ds_cineq, dVp_cineq, du_cineq, n_mv)
% Jacobiani di un blocco di p*N vincoli, ciascuno funzione di SOC, Vp e u di
% una sola cella a un solo passo. ds_cineq, dVp_cineq, du_cineq sono le
% derivate p x N del vincolo rispetto a s, Vp e u.
[p, N] = size(ds_cineq);
G   = zeros(p, 2*N, p*N);
Gmv = zeros(p, n_mv, p*N);
for n = 1:N
    for j = 1:p
        q = (n - 1)*p + j;
        G(j, n, q)     = ds_cineq(j, n);
        G(j, N + n, q) = dVp_cineq(j, n);
        Gmv(1, n, q)   = du_cineq(j, n);
    end
end
end
