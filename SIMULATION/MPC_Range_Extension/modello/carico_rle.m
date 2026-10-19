function i_pacco_next = carico_rle(pacco, par, s, Vp, u, i_pacco, E, Tc)
%CARICO_RLE  Corrente di pacco dopo un passo, con carico R-L-E in serie.
%
%   L*di_pacco/dt = V_pacco - R*i_pacco - E,   V_pacco = somma delle tensioni di cella
%
% i_pacco e' la corrente comune a tutte le celle (positiva in scarica), u la
% corrente di bilanciamento di ogni cella, E la f.e.m. del carico. Soluzione
% esatta sul passo con E e stati di cella costanti: la corrente tende a quella
% di regime con costante di tempo L/R_tot. E' stabile anche quando L/R_tot e'
% molto minore del passo.

[Voc, Ro] = parametri_cella(pacco, s);

% Tensione di pacco a corrente di carico nulla e resistenza totale della maglia
V_int = sum(Voc - Vp - Ro .* u);
R_tot = par.carico.R + sum(Ro);

% Negativa se E > V_int: il carico ricarica il pacco
i_pacco_regime = (V_int - E) / R_tot;

i_pacco_next = i_pacco_regime + (i_pacco - i_pacco_regime) * exp(-Tc * R_tot / par.carico.L);

end
