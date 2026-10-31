%% avvio_simulink.m
% Prepara il workspace per aprire ed eseguire a mano Bilanciamento_MPC_Jt.slx
% (in MATLAB R2025b la sua copia copia_R2025b/Bilanciamento_MPC_Jt_2024b.slx).
% Crea tre struct:
%   par      tutti i parametri del progetto (init_parametri.m)
%   pacco    le celle del pacco, con le loro deviazioni (genera_pacco.m)
%   par_sim  i parametri della simulazione che il modello legge
%            (parametri_simulazione.m)
% Il modello crea da solo par_sim all'apertura, se manca.
% Carica anche il modello e sceglie la variante del blocco Problema_QP
% (vincolo di tensione morbido o rigido).
%
% Per cambiare prova si modificano le tre righe qui sotto (oppure
% init_parametri.m) e si riesegue lo script.

tipo      = 'Jt';               % 'Jt' MPC J_t, vincolo morbido | 'Jt_rigido' MPC J_t, vincolo rigido | 'nessuno' senza bilanciamento
scenario  = 'A';                % 'A' f.e.m. costante | 'B' f.e.m. a gradini
orizzonte = [];                 % [] = par.mpc.p

% Path: le cartelle del progetto MPC_Range_Extension (questa cartella, che
% contiene il modello, e le sue sottocartelle con le funzioni) e, con MATLAB
% piu' vecchio di R2026b, la cartella della copia del modello. La cartella
% del progetto si aggiunge per ultima, cosi' ha la precedenza su altre
% versioni (versioni_precedenti).
cartella = fileparts(mfilename('fullpath'));                 % MPC_Range_Extension
addpath(fullfile(cartella, 'modello'), fullfile(cartella, 'mpc'), ...
    fullfile(cartella, 'simulazione'), fullfile(cartella, 'grafici'));
if isMATLABReleaseOlderThan('R2026b')
    addpath(fullfile(cartella, 'copia_R2025b'));
end
addpath(cartella);

init_parametri;
pacco = genera_pacco(par);
if isempty(orizzonte)
    orizzonte = par.mpc.p;
end
par_sim = parametri_simulazione(par, pacco, tipo, par.(['scenario' scenario]), orizzonte);

% Variante del blocco Problema_QP. La scelta cambia il modello aperto: se lo
% si salva, resta anche nel file. Si puo' cambiare anche a mano, dal menu
% del blocco (Variant > Label Mode Active Choice).
if strcmp(tipo, 'Jt_rigido')
    vincolo = 'rigido';
else
    vincolo = 'morbido';
end

% Il modello e' salvato con R2026b: nelle versioni precedenti di MATLAB si usa
% la sua copia in copia_R2025b/, che contiene lo stesso modello
modello = 'Bilanciamento_MPC_Jt';
if isMATLABReleaseOlderThan('R2026b')
    modello = 'Bilanciamento_MPC_Jt_2024b';
end
load_system(modello);
set_param([modello '/Controllo/Problema_QP'], 'LabelModeActiveChoice', vincolo);
