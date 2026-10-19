function zeta_next = zeta_next(zeta, ingressi, dati)
%ZETA_NEXT  Funzione di stato del modello di predizione dell'nlmpc, eq. (4a).
%
% Dallo stato del pacco zeta = [s; Vp] (2N, prima tutti i SOC e poi tutte le
% tensioni di polarizzazione) calcola lo stato al passo successivo, zeta_{k+1}.
% ingressi = [u; epsilon; i_pacco] e' il vettore che nlmpc passa alla
% funzione: la corrente della cella n e' I_cella(n) = i_pacco + u(n).

N = dati.pacco.N;
[~, s, Vp] = modello_cella(dati.pacco, zeta(1:N), zeta(N+1:2*N), ingressi(end) + ingressi(1:N), dati.par.mpc.Tc);
zeta_next  = [s; Vp];

end
