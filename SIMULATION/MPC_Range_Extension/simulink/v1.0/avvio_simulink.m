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

addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));

init_parametri;
pacco = genera_pacco(par);
if isempty(orizzonte)
    orizzonte = par.mpc.p;
end
par_sim = parametri_simulazione(par, pacco, formulazione, par.(['scenario' scenario]), orizzonte);
