function [V_cella, SOC_dopo, V_pol_dopo] = modello_cella(pacco, SOC, V_pol, I_cella, passo)
%MODELLO_CELLA  Modello completo di ogni cella, eq. (2a)-(2c) del paper.
%
% Dati lo stato attuale (SOC, V_pol) e la corrente I_cella (positiva in
% scarica), restituisce:
%   V_cella     tensione ai morsetti ADESSO, con questo stato e questa corrente
%   SOC_dopo    stato di carica dopo un passo di tempo
%   V_pol_dopo  tensione del ramo RC dopo un passo di tempo
% Tutte le grandezze sono vettori colonna con un valore per cella. Se serve
% solo la tensione si puo' chiamare con una sola uscita (passo non serve).

[V_vuoto, R_serie, R_pol, C_pol] = parametri_cella(pacco, SOC);

% (2c) Uscita: tensione a vuoto meno la caduta sul ramo RC e meno la caduta
% sulla resistenza serie.
V_cella = V_vuoto - V_pol - R_serie .* I_cella;

if nargout > 1
    % (2a) Conteggio della carica: in un passo la cella eroga I_cella*passo
    % coulomb, su una capacita' di 3600*capacita_Ah coulomb.
    carica_erogata = pacco.rendimento .* I_cella .* passo ./ (3600 * pacco.capacita_Ah);
    SOC_dopo       = SOC - carica_erogata;
    SOC_dopo       = min(SOC_dopo, 1);          % una cella piena non si carica oltre

    % (2b) Ramo RC, discretizzato con Eulero in avanti: V_pol tende a
    % R_pol*I_cella con costante di tempo R_pol*C_pol.
    costante_di_tempo = R_pol .* C_pol;                                   % [s]
    V_pol_dopo = V_pol + passo .* (-V_pol ./ costante_di_tempo + I_cella ./ C_pol);
end

end
