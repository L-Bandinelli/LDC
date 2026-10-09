function pacco = genera_pacco(par)
%GENERA_PACCO  Pacco di celle con parametri deviati casualmente dai nominali.
%
% Le tabelle sono quelle della cella nominale; ogni cella ha in piu' un
% fattore di scala casuale per ciascun parametro, uniforme tra
% 1 - deviazione e 1 + deviazione, che vale a qualunque SOC.
% pacco.fattore.R_serie(3) = 0.97 significa: la cella 3 ha una resistenza
% serie pari al 97 % di quella nominale.
% Il seme e' fisso: il pacco e' lo stesso a ogni esecuzione.

numero_celle = par.pacco.numero_celle;
deviazione   = par.pacco.deviazione;

rng(par.pacco.seme_casuale, 'twister');
casuale = @() 2*rand(numero_celle, 1) - 1;      % numeri uniformi tra -1 e 1, uno per cella

% L'ordine di estrazione e' fisso, cosi' cambiare una deviazione non altera
% i fattori degli altri parametri.
fattore.V_vuoto  = 1 + deviazione.V_vuoto  * casuale();
fattore.R_serie  = 1 + deviazione.R_serie  * casuale();
fattore.R_pol    = 1 + deviazione.R_pol    * casuale();
fattore.C_pol    = 1 + deviazione.C_pol    * casuale();
fattore.capacita = 1 + deviazione.capacita * casuale();

pacco = crea_pacco(par.cella, fattore);

% Cella nominale (fattori unitari): riferimento per J_t, eq. (7)
unitario = struct('V_vuoto', 1, 'R_serie', 1, 'R_pol', 1, 'C_pol', 1, 'capacita', 1);
pacco.nominale = crea_pacco(par.cella, unitario);

end

function pacco = crea_pacco(cella, fattore)
pacco.numero_celle    = numel(fattore.V_vuoto);
pacco.fattore         = fattore;                % un valore per cella
pacco.tabella_SOC     = cella.tabella_SOC;      % tabelle della cella nominale
pacco.tabella_V_vuoto = cella.tabella_V_vuoto;
pacco.tabella_R_serie = cella.tabella_R_serie;
pacco.tabella_R_pol   = cella.tabella_R_pol;
pacco.tabella_C_pol   = cella.tabella_C_pol;
pacco.capacita_Ah     = cella.capacita_Ah * fattore.capacita;   % [Ah], un valore per cella
pacco.rendimento      = cella.rendimento;
end
