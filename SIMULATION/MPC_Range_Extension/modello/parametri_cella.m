function [V_vuoto, R_serie, R_pol, C_pol, derivata] = parametri_cella(pacco, SOC)
%PARAMETRI_CELLA  Parametri di ogni cella al suo SOC attuale.
%
% Si legge la tabella nominale (interpolazione lineare) e si moltiplica per il
% fattore della cella. Fuori tabella (SOC < 0 o > 1) si usa il valore
% dell'estremo, come i blocchi Em_table, R_table, C_table della libreria
% Simscape LiBatteryElements.
%
% SOC e le uscite sono vettori colonna con un valore per cella. derivata e'
% una struct con le derivate rispetto al SOC (campi V_vuoto, R_serie, R_pol,
% C_pol): servono solo agli jacobiani dell'MPC.

tabella_SOC    = pacco.tabella_SOC;
SOC_limitato   = min(max(SOC, tabella_SOC(1)), tabella_SOC(end));
dentro_tabella = (SOC >= tabella_SOC(1)) & (SOC <= tabella_SOC(end));   % fuori, derivata nulla

% Tratto della tabella in cui cade ogni SOC e posizione al suo interno (0..1)
tratto    = sum(SOC_limitato >= tabella_SOC(1:end-1).', 2);
ampiezza  = tabella_SOC(tratto + 1) - tabella_SOC(tratto);
posizione = (SOC_limitato - tabella_SOC(tratto)) ./ ampiezza;

[V_vuoto, derivata.V_vuoto] = interpola(pacco.tabella_V_vuoto, pacco.fattore.V_vuoto);
[R_serie, derivata.R_serie] = interpola(pacco.tabella_R_serie, pacco.fattore.R_serie);
[R_pol,   derivata.R_pol]   = interpola(pacco.tabella_R_pol,   pacco.fattore.R_pol);
[C_pol,   derivata.C_pol]   = interpola(pacco.tabella_C_pol,   pacco.fattore.C_pol);

    function [valore, pendenza] = interpola(tabella, fattore)
        inizio   = tabella(tratto);
        fine     = tabella(tratto + 1);
        valore   = fattore .* (inizio + (fine - inizio) .* posizione);
        pendenza = fattore .* (fine - inizio) ./ ampiezza .* dentro_tabella;
    end

end
