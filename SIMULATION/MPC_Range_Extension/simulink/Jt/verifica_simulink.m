%% verifica_simulink.m
% Controlla che il modello Simulink J_t dia gli stessi risultati del codice
% MATLAB.
%
% Legge risultati/A_risultati.mat (scritto da main_E_costante, cioe' da
% simula_pacco con nlmpc), riesegue con il modello Simulink i casi 'nessuno'
% e 'Jt' usando i parametri salvati nel file e stampa le differenze.
% L'ultima colonna e' lo sforzo medio w (media di w_k = u_k'*u_k), MATLAB / Simulink.

clear; clc

% Path: la cartella del modello (questa) e le cartelle del progetto
% MPC_Range_Extension, due livelli sopra. La cartella del modello si
% aggiunge per ultima, cosi' ha la precedenza su altre versioni.
cartella_modello = fileparts(mfilename('fullpath'));
cartella = fileparts(fileparts(cartella_modello));          % MPC_Range_Extension
addpath(cartella, fullfile(cartella, 'modello'), fullfile(cartella, 'mpc'), ...
    fullfile(cartella, 'simulazione'), fullfile(cartella, 'grafici'));
addpath(cartella_modello);

rif_matlab = load(fullfile(cartella, 'risultati', 'A_risultati.mat'));
par        = rif_matlab.par;
pacco      = rif_matlab.pacco;

% simula_pacco usa un solo passo, par.mpc.Tc, anche per integrare il modello
% fisico: per confrontare le due simulazioni istante per istante il modello
% Simulink deve integrare con lo stesso passo
par.tempi.Tint = par.mpc.Tc;

fprintf('Tc = %g s, N = %d celle\n', par.mpc.Tc, pacco.N);
fprintf('%-10s %3s %12s %12s %12s %12s %20s\n', 'Controllo', 'p', 'MATLAB [s]', ...
    'Simulink [s]', 'max|du| [A]', 'max|dy| [V]', 'Sforzo medio w [A^2]');
for c = 1:numel(rif_matlab.ris)
    rif = rif_matlab.ris{c};
    if ~any(strcmp(rif.tipo, {'nessuno', 'Jt'}))
        continue                    % questo modello risolve solo J_t
    end
    ris = simula_simulink(rif.tipo, pacco, par, par.scenarioA, rif.p);

    K = min(numel(rif.t), numel(ris.t));          % passi in comune
    fprintf('%-10s %3d %12.0f %12.0f %12.1e %12.1e %9.3f / %8.3f\n', rif.tipo, rif.p, ...
        rif.durata, ris.durata, ...
        max(abs(ris.u(1:K, :) - rif.u(1:K, :)), [], 'all'), ...
        max(abs(ris.y(1:K, :) - rif.y(1:K, :)), [], 'all'), ...
        rif.w_medio, ris.w_medio);
end
