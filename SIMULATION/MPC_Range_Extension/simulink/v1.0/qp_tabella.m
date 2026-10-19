function [valore, ds_valore] = qp_tabella(s_tab, P_tab, phi, s)
%QP_TABELLA  Parametro di cella al SOC dato e sua derivata rispetto al SOC.
%
% Stessa lettura di modello/parametri_cella.m (interpolazione lineare della
% tabella nominale P_tab, nei punti s_tab, per il fattore di deviazione phi
% della cella; valore dell'estremo fuori tabella), scritta senza funzioni
% annidate perche' viene usata dentro i blocchi MATLAB Function.
% s, phi e le uscite hanno un valore per cella; ds_valore e' la derivata
% rispetto al SOC.

n_tab     = numel(s_tab);
valore    = zeros(size(s));
ds_valore = zeros(size(s));

for n = 1:numel(s)
    s_limitato = min(max(s(n), s_tab(1)), s_tab(n_tab));

    % Tratto della tabella in cui cade s_limitato
    tratto = 1;
    for q = 2:n_tab-1
        if s_limitato >= s_tab(q)
            tratto = q;
        end
    end
    ampiezza  = s_tab(tratto + 1) - s_tab(tratto);
    posizione = (s_limitato - s_tab(tratto)) / ampiezza;

    valore(n) = phi(n) * (P_tab(tratto) + (P_tab(tratto + 1) - P_tab(tratto)) * posizione);
    if s(n) >= s_tab(1) && s(n) <= s_tab(n_tab)      % fuori tabella, derivata nulla
        ds_valore(n) = phi(n) * (P_tab(tratto + 1) - P_tab(tratto)) / ampiezza;
    end
end

end
