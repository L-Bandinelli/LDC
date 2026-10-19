%% avvio_simulink.m
% Prepara il workspace per aprire ed eseguire a mano Bilanciamento_MPC.slx.
% Crea tre struct:
%   par      tutti i parametri del progetto (init_parametri.m)
%   pacco    le celle del pacco, con le loro deviazioni (genera_pacco.m)
%   par_sim  i parametri della simulazione che il modello legge
%            (parametri_simulazione.m)
% Il modello crea da solo par_sim all'apertura, se manca.
%
% Per cambiare prova si modificano le tre righe qui sotto (oppure
% init_parametri.m) e si riesegue lo script.

formulazione = 'Jt';            % 'nessuno' | 'Jt' | 'Jm' | 'Jdelta'
scenario     = 'A';             % 'A' f.e.m. costante | 'B' f.e.m. a gradini
orizzonte    = [];              % [] = par.mpc.p

% Path: la cartella di questo script (quella del modello) e le cartelle del
% progetto MPC_Range_Extension, due livelli sopra. La cartella del modello
% si aggiunge per ultima, cosi' ha la precedenza su altre versioni (v1.0).
cartella_modello  = fileparts(mfilename('fullpath'));
cartella_progetto = fileparts(fileparts(cartella_modello));
addpath(cartella_progetto, fullfile(cartella_progetto, 'modello'), fullfile(cartella_progetto, 'mpc'), ...
    fullfile(cartella_progetto, 'simulazione'), fullfile(cartella_progetto, 'grafici'));
addpath(cartella_modello);

init_parametri;
pacco = genera_pacco(par);
if isempty(orizzonte)
    orizzonte = par.mpc.p;
end
par_sim = parametri_simulazione(par, pacco, formulazione, par.(['scenario' scenario]), orizzonte);
