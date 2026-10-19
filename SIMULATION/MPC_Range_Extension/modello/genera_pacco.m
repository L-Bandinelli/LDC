function pacco = genera_pacco(par)
%GENERA_PACCO  Pacco di celle con parametri deviati casualmente dai nominali.
%
% Le tabelle sono quelle della cella nominale; ogni cella ha in piu' un
% fattore di deviazione phi_P casuale per ciascun parametro P, uniforme tra
% 1 - delta_P e 1 + delta_P, che vale a qualunque SOC.
% pacco.phi.Ro(3) = 0.97 significa: la cella 3 ha una resistenza serie pari
% al 97 % di quella nominale.
% Il seme e' fisso: il pacco e' lo stesso a ogni esecuzione.

N     = par.pacco.N;
delta = par.pacco.delta;

rng(par.pacco.seme_casuale, 'twister');
casuale = @() 2*rand(N, 1) - 1;      % numeri uniformi tra -1 e 1, uno per cella

% L'ordine di estrazione e' fisso, cosi' cambiare una deviazione non altera
% i fattori degli altri parametri.
phi.Voc = 1 + delta.Voc * casuale();
phi.Ro  = 1 + delta.Ro  * casuale();
phi.Rp  = 1 + delta.Rp  * casuale();
phi.Cp  = 1 + delta.Cp  * casuale();
phi.C   = 1 + delta.C   * casuale();

pacco = crea_pacco(par.cella, phi);

% Cella nominale (fattori unitari): riferimento per J_t, eq. (7)
unitario = struct('Voc', 1, 'Ro', 1, 'Rp', 1, 'Cp', 1, 'C', 1);
pacco.nominale = crea_pacco(par.cella, unitario);

end

function pacco = crea_pacco(cella, phi)
pacco.N       = numel(phi.Voc);
pacco.phi     = phi;                  % un valore per cella
pacco.s_tab   = cella.s_tab;          % tabelle della cella nominale
pacco.Voc_tab = cella.Voc_tab;
pacco.Ro_tab  = cella.Ro_tab;
pacco.Rp_tab  = cella.Rp_tab;
pacco.Cp_tab  = cella.Cp_tab;
pacco.C       = cella.C * phi.C;      % [Ah], un valore per cella
pacco.eta     = cella.eta;
end
