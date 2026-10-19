function [Voc, Ro, Rp, Cp, ds] = parametri_cella(pacco, s)
%PARAMETRI_CELLA  Parametri di ogni cella al suo SOC attuale.
%
% Si legge la tabella nominale (interpolazione lineare) e si moltiplica per il
% fattore di deviazione phi della cella. Fuori tabella (SOC < 0 o > 1) si usa
% il valore dell'estremo, come i blocchi Em_table, R_table, C_table della
% libreria Simscape LiBatteryElements.
%
% s e le uscite sono vettori colonna con un valore per cella. ds e' una struct
% con le derivate rispetto al SOC (campi Voc, Ro, Rp, Cp: ds.Cp e' C_p' =
% dC_p/ds): servono solo agli jacobiani dell'MPC.

s_tab          = pacco.s_tab;
s_limitato     = min(max(s, s_tab(1)), s_tab(end));
dentro_tabella = (s >= s_tab(1)) & (s <= s_tab(end));   % fuori, derivata nulla

% Tratto della tabella in cui cade ogni SOC e posizione al suo interno (0..1)
tratto    = sum(s_limitato >= s_tab(1:end-1).', 2);
ampiezza  = s_tab(tratto + 1) - s_tab(tratto);
posizione = (s_limitato - s_tab(tratto)) ./ ampiezza;

[Voc, ds.Voc] = interpola(pacco.Voc_tab, pacco.phi.Voc);
[Ro,  ds.Ro]  = interpola(pacco.Ro_tab,  pacco.phi.Ro);
[Rp,  ds.Rp]  = interpola(pacco.Rp_tab,  pacco.phi.Rp);
[Cp,  ds.Cp]  = interpola(pacco.Cp_tab,  pacco.phi.Cp);

    function [valore, ds_valore] = interpola(P_tab, phi)
        inizio    = P_tab(tratto);
        fine      = P_tab(tratto + 1);
        valore    = phi .* (inizio + (fine - inizio) .* posizione);
        ds_valore = phi .* (fine - inizio) ./ ampiezza .* dentro_tabella;
    end

end
