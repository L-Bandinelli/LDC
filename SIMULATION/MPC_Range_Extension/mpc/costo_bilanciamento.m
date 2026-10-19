function [J, G, Gmv, G_epsilon_y] = costo_bilanciamento(X, U, epsilon_y, ~, dati)
%COSTO_BILANCIAMENTO  Funzione di costo dell'nlmpc per le tre formulazioni del paper.
%
%   Jt      sum_j ||sigma_{k+j} - sigma0_{k+j}||^2 + rho*u'*u                eq. (7)
%   Jm      -sum_j epsilon_j + rho*u'*u                                     eq. (9)
%   Jdelta  sum_j epsilon_{p+j} - sum_j epsilon_j + rho*u'*u                eq. (12)
% piu' W*epsilon_y^2 sulla variabile di rilassamento del vincolo di tensione,
% eq. (17). rho = rho_rif*p/p_rif, con rho_rif = par.mpc.Jt, .Jm o .Jdelta.
%
% G, Gmv, G_epsilon_y sono le derivate rispetto a X(2:p+1,:), U(1:p,:) ed
% epsilon_y.

par = dati.par;
p   = dati.p;
N   = dati.pacco.N;
[~, ~, u, epsilon, der] = predizione_uscite(X, U, dati);

rho = par.mpc.(dati.tipo) * p / par.mpc.p_rif;       % la matrice R del paper e' rho*I

G   = zeros(p, 2*N);
Gmv = zeros(p, N + numel(epsilon));
Gmv(1, 1:N) = 2*rho*u.';
switch dati.tipo
    case 'Jt'
        err = der.sigma - dati.sigma0;
        J   = sum(err.^2, 'all');
        G   = [2*err.*der.ds_sigma, 2*err.*der.dVp_sigma];
        Gmv(1, 1:N) = Gmv(1, 1:N) + sum(2*err.*der.du_sigma, 1);
    case 'Jm'
        J = -sum(epsilon);
        Gmv(1, N + (1:p)) = -1;
    case 'Jdelta'
        J = sum(epsilon(p+1:2*p)) - sum(epsilon(1:p));
        Gmv(1, N + (1:p))     = -1;
        Gmv(1, N + p + (1:p)) =  1;
end
J           = J + rho*(u.'*u) + par.mpc.W*epsilon_y^2;
G_epsilon_y = 2*par.mpc.W*epsilon_y;

% Riscalatura per il condizionamento numerico: il minimo non cambia
J = J/rho;  G = G/rho;  Gmv = Gmv/rho;  G_epsilon_y = G_epsilon_y/rho;

end
