function [J, G, Gmv, Ge] = costo_bilanciamento(X, U, e, ~, dati)
%COSTO_BILANCIAMENTO  Funzione di costo dell'nlmpc per le tre formulazioni del paper.
%
%   Jt      sum_j ||sigma_{k+j} - sigma0_{k+j}||^2 + u'*R*u          eq. (7)
%   Jm      -sum_j eps_j + u'*R*u                                    eq. (9)
%   Jdelta  sum_j eps_{p+j} - sum_j eps_j + u'*R*u                   eq. (12)
% piu' W*e^2 sulla slack del vincolo di tensione, eq. (17).
%
% G, Gmv, Ge sono le derivate rispetto a X(2:p+1,:), U(1:p,:) ed e.

par = dati.par;
p   = dati.p;
N   = dati.pacco.numero_celle;
[~, ~, u, eps, D] = predizione_uscite(X, U, dati);

r = par.mpc.r.(dati.tipo) * p / par.mpc.p_rif;       % R = r*I

G   = zeros(p, 2*N);
Gmv = zeros(p, N + numel(eps));
Gmv(1, 1:N) = 2*r*u.';
switch dati.tipo
    case 'Jt'
        err = D.sigma - dati.sigma0;
        J   = sum(err.^2, 'all');
        G   = [2*err.*D.sig_s, 2*err.*D.sig_v];
        Gmv(1, 1:N) = Gmv(1, 1:N) + sum(2*err.*D.sig_u, 1);
    case 'Jm'
        J = -sum(eps);
        Gmv(1, N + (1:p)) = -1;
    case 'Jdelta'
        J = sum(eps(p+1:2*p)) - sum(eps(1:p));
        Gmv(1, N + (1:p))     = -1;
        Gmv(1, N + p + (1:p)) =  1;
end
J  = J + r*(u.'*u) + par.mpc.W*e^2;
Ge = 2*par.mpc.W*e;

% Riscalatura per il condizionamento numerico: il minimo non cambia
J = J/r;  G = G/r;  Gmv = Gmv/r;  Ge = Ge/r;

end
