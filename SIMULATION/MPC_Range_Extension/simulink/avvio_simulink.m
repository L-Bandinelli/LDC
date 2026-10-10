%% avvio_simulink.m
% Prepara il workspace per aprire ed eseguire a mano Bilanciamento_MPC.slx:
% crea par, pacco e sl. Il modello lo esegue da solo all'apertura se sl manca.
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
sl = init_simulink(par, pacco, formulazione, par.(['scenario' scenario]), orizzonte);
