function [Y, S, u, epsilon, der] = predizione_uscite(X, U, dati)
%PREDIZIONE_USCITE  Tensioni e SOC predetti sull'orizzonte, dalle traiettorie dell'nlmpc.
%
% X e' (p+1) x 2N (la riga 1 e' lo stato attuale), U e' (p+1) x (N + n_epsilon + 1).
% Y e S sono p x N: riga j <-> passo k+j, eq. (6c). u e' N x 1, epsilon e' il
% vettore delle variabili ausiliarie del costo.
%
% der contiene la grandezza bilanciata sigma e le derivate (p x N) di sigma e
% della tensione y rispetto a SOC, Vp e u della stessa cella: servono agli
% jacobiani. Nomi delle derivate: ds_y = dy/ds, dVp_y = dy/dVp, du_y = dy/du.

N = dati.pacco.N;
p = dati.p;
u       = U(1, 1:N).';
epsilon = U(1, N+1:end-1).';
i_pacco = U(1:p, end);

S = X(2:p+1, 1:N);
Y = zeros(p, N);
der.ds_y = zeros(p, N);
der.du_y = zeros(p, N);
for j = 1:p
    [Voc, Ro, ~, ~, ds] = parametri_cella(dati.pacco, S(j, :).');
    I_cella = i_pacco(j) + u;
    Y(j, :)        = (Voc - X(j+1, N+1:2*N).' - I_cella.*Ro).';      % (2c)
    der.ds_y(j, :) = (ds.Voc - I_cella.*ds.Ro).';
    der.du_y(j, :) = -Ro.';
end
der.dVp_y = -ones(p, N);

if dati.par.mpc.sigma == 'y'
    der.sigma = Y;  der.ds_sigma = der.ds_y;    der.dVp_sigma = der.dVp_y;    der.du_sigma = der.du_y;
else
    der.sigma = S;  der.ds_sigma = ones(p, N);  der.dVp_sigma = zeros(p, N);  der.du_sigma = zeros(p, N);
end

end
