function [ceq, G, Gmv] = vincolo_somma(X, U, ~, dati)
%VINCOLO_SOMMA  Vincolo di uguaglianza dell'nlmpc: somma delle u nulla, eq. (6f).
%
% Il bilanciatore sposta carica tra le celle, non ne aggiunge e non ne toglie.
% G, Gmv sono le derivate rispetto a X(2:p+1,:) e U(1:p,:).

N = dati.pacco.numero_celle;
p = dati.p;
ceq = sum(U(1, 1:N));

G   = zeros(p, size(X, 2));
Gmv = zeros(p, size(U, 2) - 1);
Gmv(1, 1:N) = 1;

end
