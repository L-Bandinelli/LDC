%% verifica_simulink.m
% Controlla che il modello Simulink dia gli stessi risultati del codice MATLAB.
%
% Legge risultati/A_risultati.mat (scritto da main_E_costante, cioe' da
% simula_pacco con nlmpc), riesegue gli stessi quattro casi con il modello
% Simulink usando i parametri salvati nel file e stampa le differenze.

clear; clc
cartella = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(cartella));

matlab = load(fullfile(cartella, 'risultati', 'A_risultati.mat'));
par    = matlab.par;
pacco  = matlab.pacco;

fprintf('Ts = %g s, N = %d celle\n', par.mpc.Ts, pacco.numero_celle);
fprintf('%-10s %3s %12s %12s %12s %12s %14s\n', 'Controllo', 'p', 'MATLAB [s]', ...
    'Simulink [s]', 'max|du| [A]', 'max|dy| [V]', 'Sforzo [A^2]');
for c = 1:numel(matlab.ris)
    rif = matlab.ris{c};
    ris = simula_simulink(rif.tipo, pacco, par, par.scenarioA, rif.p);

    K = min(numel(rif.t), numel(ris.t));          % passi in comune
    fprintf('%-10s %3d %12.0f %12.0f %12.1e %12.1e %6.3f / %.3f\n', rif.tipo, rif.p, ...
        rif.durata, ris.durata, ...
        max(abs(ris.u(1:K, :) - rif.u(1:K, :)), [], 'all'), ...
        max(abs(ris.y(1:K, :) - rif.y(1:K, :)), [], 'all'), ...
        rif.sforzo_medio, ris.sforzo_medio);
end
