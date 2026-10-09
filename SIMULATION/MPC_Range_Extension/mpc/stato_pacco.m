function x_succ = stato_pacco(x, u, dati)
%STATO_PACCO  Funzione di stato del modello di predizione dell'nlmpc.
%
% x = [s; Vp] (2N), u = [u_bil; eps; i_pacco]. La corrente della cella n e'
% i_pacco + u_bil(n), eq. (4a) del paper.

N = dati.pacco.numero_celle;
[~, s, Vp] = modello_cella(dati.pacco, x(1:N), x(N+1:2*N), u(end) + u(1:N), dati.par.mpc.Ts);
x_succ  = [s; Vp];

end
