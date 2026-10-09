%% main_E_variabile.m
% Scenario B: carico R-L-E con f.e.m. periodica a gradini e rampe (condizione
% dinamica, al posto del ciclo FTP della Sez. IV-B del paper). Confronta il
% pacco senza bilanciamento con i tre MPC per piu' orizzonti p e produce la
% tabella stile Tabella III e le figure stile Fig. 4 e Fig. 5.

clear; close all; clc
cartella = fileparts(mfilename('fullpath'));
addpath(genpath(cartella));

init_parametri;
pacco = genera_pacco(par);
scen  = par.scenarioB;
orizzonti = scen.orizzonti;

%% Simulazioni
tipi = {'Jt', 'Jm', 'Jdelta'};
base = simula_pacco('nessuno', pacco, par, scen, orizzonti(1));
ris  = cell(numel(orizzonti), numel(tipi));
for h = 1:numel(orizzonti)
    for c = 1:numel(tipi)
        ris{h, c} = simula_pacco(tipi{c}, pacco, par, scen, orizzonti(h));
    end
end

%% Tabella (stile Tabella III)
fprintf('\nScenario B - E(t) periodica, periodo %g s\n', scen.t_E(end));
fprintf('%-10s %3s %10s %11s %13s %14s  %s\n', 'Controllo', 'p', 'Durata [s]', ...
    'Estensione', 'Energia [Wh]', 'Sforzo [A^2]', 'Arresto');
fprintf('%-10s %3s %10.0f %11s %13.1f %14s  %s\n', 'nessuno', '-', base.durata, '-', ...
    base.energia, '-', base.motivo);
for h = 1:numel(orizzonti)
    for c = 1:numel(tipi)
        r = ris{h, c};
        fprintf('%-10s %3d %10.0f %10.2f%% %13.1f %14.2f  %s\n', r.tipo, r.p, r.durata, ...
            100*(r.durata/base.durata - 1), r.energia, r.sforzo_medio, r.motivo);
    end
end

%% Figure (orizzonte piu' corto)
uscita = fullfile(cartella, 'risultati');
if ~exist(uscita, 'dir'), mkdir(uscita); end

st = stile_grafici();
for c = 1:numel(tipi)
    fig = grafico_celle(ris{1, c}, par, ...
        sprintf('Scenario B, %s (p = %d)', st.nome.(tipi{c}), orizzonti(1)));
    exportgraphics(fig, fullfile(uscita, ['B_celle_' tipi{c} '.png']), 'Resolution', 150);
end

confronto = [{base}, ris(1, :)];
fig = grafico_confronto(confronto, par, 'Scenario B: tensione minima e sforzo di bilanciamento');
exportgraphics(fig, fullfile(uscita, 'B_confronto.png'), 'Resolution', 150);

fig = grafico_confronto(confronto, par, 'Scenario B: ultimi periodi', ...
    [base.durata - 1.5*scen.t_E(end), max(cellfun(@(r) r.durata, confronto))]);
exportgraphics(fig, fullfile(uscita, 'B_confronto_finale.png'), 'Resolution', 150);

save(fullfile(uscita, 'B_risultati.mat'), 'ris', 'base', 'par', 'pacco');
