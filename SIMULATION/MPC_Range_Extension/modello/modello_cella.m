function [y, s_next, Vp_next] = modello_cella(pacco, s, Vp, I_cella, Tc)
%MODELLO_CELLA  Modello completo di ogni cella, eq. (2a)-(2c) del paper.
%
% Dati lo stato attuale (s, Vp) e la corrente I_cella (positiva in scarica),
% restituisce:
%   y        tensione ai morsetti ADESSO, con questo stato e questa corrente
%   s_next   SOC dopo un passo di tempo Tc
%   Vp_next  tensione di polarizzazione dopo un passo di tempo Tc
% Tutte le grandezze sono vettori colonna con un valore per cella. Se serve
% solo la tensione si puo' chiamare con una sola uscita (Tc non serve).

[Voc, Ro, Rp, Cp] = parametri_cella(pacco, s);

% (2c) Uscita: tensione a vuoto meno la caduta sul ramo RC e meno la caduta
% sulla resistenza serie.
y = Voc - Vp - Ro .* I_cella;

if nargout > 1
    % (2a) Conteggio della carica: in un passo la cella eroga I_cella*Tc
    % coulomb, su una capacita' di 3600*C coulomb (C in Ah).
    consumed_soc = pacco.eta .* I_cella .* Tc ./ (3600 * pacco.C);
    s_next       = s - consumed_soc;
    s_next       = min(s_next, 1);          % una cella piena non si carica oltre

    % (2b) Ramo RC, discretizzato con Eulero in avanti: Vp tende a
    % Rp*I_cella con costante di tempo tau = Rp*Cp.
    tau     = Rp .* Cp;                                                   % [s]
    Vp_next = Vp + Tc .* (-Vp ./ tau + I_cella ./ Cp);
end

end
