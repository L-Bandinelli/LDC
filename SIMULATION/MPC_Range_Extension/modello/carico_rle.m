function I_pacco_dopo = carico_rle(pacco, par, SOC, V_pol, I_bilanciamento, I_pacco, E, passo)
%CARICO_RLE  Corrente di pacco dopo un passo, con carico R-L-E in serie.
%
%   L*dI/dt = V_pacco - R*I - E,   V_pacco = somma delle tensioni di cella
%
% I_pacco e' la corrente comune a tutte le celle (positiva in scarica),
% I_bilanciamento quella aggiunta a ogni cella dal bilanciatore, E la f.e.m.
% del carico. Soluzione esatta sul passo con E e stati di cella costanti: la
% corrente tende a quella di regime con costante di tempo L/R_totale. E'
% stabile anche quando L/R_totale e' molto minore del passo.

[V_vuoto, R_serie] = parametri_cella(pacco, SOC);

% Tensione di pacco a corrente di carico nulla e resistenza totale della maglia
V_interna = sum(V_vuoto - V_pol - R_serie .* I_bilanciamento);
R_totale  = par.carico.R + sum(R_serie);

% Negativa se E > V_interna: il carico ricarica il pacco
I_regime = (V_interna - E) / R_totale;

I_pacco_dopo = I_regime + (I_pacco - I_regime) * exp(-passo * R_totale / par.carico.L);

end
