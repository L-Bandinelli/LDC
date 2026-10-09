%% main_E_costante.m
% Scenario A: carico R-L-E con f.e.m. costante (condizione di regime, Sez. IV-A
% del paper). Confronta il pacco senza bilanciamento con i tre MPC J_t, J_m,
% J_Delta e produce la tabella delle durate e le figure stile Fig. 2 e Fig. 3.

clear; close all; clc
cartella = fileparts(mfilename('fullpath'));
addpath(genpath(cartella));

init_parametri;
pacco = genera_pacco(par);
scen  = par.scenarioA;
p     = par.mpc.p;

%% Simulazioni
tipi = {'nessuno', 'Jt', 'Jm', 'Jdelta'};
ris  = cell(1, numel(tipi));
for c = 1:numel(tipi)
    ris{c} = simula_pacco(tipi{c}, pacco, par, scen, p);
end

%% Tabella (stile Tabella I)
fprintf('\nScenario A - E = %g V costante, p = %d\n', scen.E, p);
fprintf('%-20s %10s %11s %14s  %s\n', 'Controllo', 'Durata [s]', 'Estensione', 'Sforzo [A^2]', 'Arresto');
for c = 1:numel(tipi)
    est = 100 * (ris{c}.durata / ris{1}.durata - 1);
    fprintf('%-20s %10.0f %10.2f%% %14.2f  %s\n', tipi{c}, ris{c}.durata, est, ...
        ris{c}.sforzo_medio, ris{c}.motivo);
end

%% Figure
uscita = fullfile(cartella, 'risultati');
if ~exist(uscita, 'dir'), mkdir(uscita); end

fig = grafico_celle(ris{2}, par, sprintf('Scenario A, J_t (p = %d)', p));
exportgraphics(fig, fullfile(uscita, 'A_celle_Jt.png'), 'Resolution', 150);

fig = grafico_confronto(ris, par, 'Scenario A: tensione minima e sforzo di bilanciamento');
exportgraphics(fig, fullfile(uscita, 'A_confronto.png'), 'Resolution', 150);

fig = grafico_confronto(ris, par, 'Scenario A: ultimi 300 s', ...
    [ris{1}.durata - 150, max(cellfun(@(r) r.durata, ris))]);
exportgraphics(fig, fullfile(uscita, 'A_confronto_finale.png'), 'Resolution', 150);

save(fullfile(uscita, 'A_risultati.mat'), 'ris', 'par', 'pacco');
