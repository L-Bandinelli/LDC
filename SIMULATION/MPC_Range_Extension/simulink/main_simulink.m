%% main_simulink.m
% Scenario A (f.e.m. costante, Sez. IV-A del paper) eseguito con il modello
% Simulink Bilanciamento_MPC.slx. Confronta il pacco senza bilanciamento con
% i tre MPC J_t, J_m, J_Delta: tabella delle durate (stile Tabella I) e figure
% stile Fig. 2 e Fig. 3.
%
% Per lo scenario B: scen = par.scenarioB.

clear; close all; clc
cartella = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(cartella));

init_parametri;
pacco = genera_pacco(par);
scen  = par.scenarioA;
p     = par.mpc.p;

%% Simulazioni
tipi = {'nessuno', 'Jt', 'Jm', 'Jdelta'};
ris  = cell(1, numel(tipi));
for c = 1:numel(tipi)
    ris{c} = simula_simulink(tipi{c}, pacco, par, scen, p);
end

%% Tabella (stile Tabella I)
fprintf('\nSimulink - integrazione %g s, controllo %g s, p = %d, N = %d celle\n', ...
    par.sim.Ts_integrazione, par.mpc.Ts, p, pacco.numero_celle);
fprintf('%-20s %10s %11s %14s  %s\n', 'Controllo', 'Durata [s]', 'Estensione', 'Sforzo [A^2]', 'Arresto');
for c = 1:numel(tipi)
    est = 100 * (ris{c}.durata / ris{1}.durata - 1);
    fprintf('%-20s %10.0f %10.2f%% %14.2f  %s\n', tipi{c}, ris{c}.durata, est, ...
        ris{c}.sforzo_medio, ris{c}.motivo);
end

%% Figure
uscita = fullfile(cartella, 'risultati');
if ~exist(uscita, 'dir'), mkdir(uscita); end

fig = grafico_celle(ris{2}, par, sprintf('Simulink, J_t (p = %d)', p));
exportgraphics(fig, fullfile(uscita, 'SL_celle_Jt.png'), 'Resolution', 150);

fig = grafico_confronto(ris, par, 'Simulink: tensione minima e sforzo di bilanciamento');
exportgraphics(fig, fullfile(uscita, 'SL_confronto.png'), 'Resolution', 150);

fig = grafico_scarica(ris{1}, ris{2}, par, 'Simulink: scarica senza controllo e con MPC');
exportgraphics(fig, fullfile(uscita, 'SL_scarica_Jt.png'), 'Resolution', 150);

save(fullfile(uscita, 'SL_risultati.mat'), 'ris', 'par', 'pacco');
