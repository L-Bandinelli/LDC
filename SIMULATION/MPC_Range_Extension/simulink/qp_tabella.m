function [valore, pendenza] = qp_tabella(tabella_SOC, tabella, fattore, SOC)
%QP_TABELLA  Parametro di cella al SOC dato e sua derivata rispetto al SOC.
%
% Stessa lettura di modello/parametri_cella.m (interpolazione lineare della
% tabella nominale per il fattore della cella, valore dell'estremo fuori
% tabella), scritta senza funzioni annidate perche' viene usata dentro i
% blocchi MATLAB Function. SOC, fattore e le uscite hanno un valore per cella.

n        = numel(tabella_SOC);
valore   = zeros(size(SOC));
pendenza = zeros(size(SOC));

for c = 1:numel(SOC)
    x = min(max(SOC(c), tabella_SOC(1)), tabella_SOC(n));

    % Tratto della tabella in cui cade x
    tratto = 1;
    for q = 2:n-1
        if x >= tabella_SOC(q)
            tratto = q;
        end
    end
    ampiezza  = tabella_SOC(tratto + 1) - tabella_SOC(tratto);
    posizione = (x - tabella_SOC(tratto)) / ampiezza;

    valore(c) = fattore(c) * (tabella(tratto) + (tabella(tratto + 1) - tabella(tratto)) * posizione);
    if SOC(c) >= tabella_SOC(1) && SOC(c) <= tabella_SOC(n)      % fuori tabella, derivata nulla
        pendenza(c) = fattore(c) * (tabella(tratto + 1) - tabella(tratto)) / ampiezza;
    end
end

end
