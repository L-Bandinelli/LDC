function [Y, S, u, eps, D] = predizione_uscite(X, U, dati)
%PREDIZIONE_USCITE  Tensioni e SOC predetti sull'orizzonte, dalle traiettorie dell'nlmpc.
%
% X e' (p+1) x 2N (la riga 1 e' lo stato attuale), U e' (p+1) x (N + n_eps + 1).
% Y e S sono p x N: riga j <-> passo k+j, eq. (6c). u e' N x 1, eps e' il
% vettore delle slack del costo.
%
% D contiene le derivate (p x N) della grandezza bilanciata sigma e della
% tensione y rispetto a SOC, Vp e u della stessa cella: servono agli jacobiani.

N = dati.pacco.numero_celle;
p = dati.p;
u       = U(1, 1:N).';
eps     = U(1, N+1:end-1).';
i_pacco = U(1:p, end);

S = X(2:p+1, 1:N);
Y = zeros(p, N);
D.y_s = zeros(p, N);
D.y_u = zeros(p, N);
for j = 1:p
    [V_vuoto, R_serie, ~, ~, derivata] = parametri_cella(dati.pacco, S(j, :).');
    ic = i_pacco(j) + u;
    Y(j, :)     = (V_vuoto - X(j+1, N+1:2*N).' - ic.*R_serie).';      % (2c)
    D.y_s(j, :) = (derivata.V_vuoto - ic.*derivata.R_serie).';
    D.y_u(j, :) = -R_serie.';
end
D.y_v = -ones(p, N);

if dati.par.mpc.sigma == 'y'
    D.sigma = Y;  D.sig_s = D.y_s;       D.sig_v = D.y_v;        D.sig_u = D.y_u;
else
    D.sigma = S;  D.sig_s = ones(p, N);  D.sig_v = zeros(p, N);  D.sig_u = zeros(p, N);
end

end
