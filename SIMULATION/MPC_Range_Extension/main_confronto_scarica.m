%% main_confronto_scarica.m
% Confronto tra la scarica del pacco senza controllo e con controllo MPC, in
% entrambi gli scenari di carico. Per ogni scenario produce una figura con
% tensioni, SOC e correnti di bilanciamento affiancati.

clear; close all; clc
cartella = fileparts(mfilename('fullpath'));
addpath(genpath(cartella));

init_parametri;
pacco = genera_pacco(par);

tipo = 'Jt';                 % MPC da confrontare: 'Jt' | 'Jm' | 'Jdelta'
p    = par.mpc.p;

scenari = {par.scenarioA, par.scenarioB};
nomi    = {'A', 'B'};
titoli  = {'Scenario A (E costante)', 'Scenario B (E a gradini)'};

uscita = fullfile(cartella, 'risultati');
if ~exist(uscita, 'dir'), mkdir(uscita); end

for indice_scenario = 1:numel(scenari)
    ris_base = simula_pacco('nessuno', pacco, par, scenari{indice_scenario}, p);
    ris_mpc  = simula_pacco(tipo,      pacco, par, scenari{indice_scenario}, p);

    fprintf('%s: senza controllo %.0f s, con MPC %s %.0f s (+%.2f %%)\n', titoli{indice_scenario}, ...
        ris_base.durata, tipo, ris_mpc.durata, 100*(ris_mpc.durata/ris_base.durata - 1));

    fig = grafico_scarica(ris_base, ris_mpc, par, [titoli{indice_scenario} ': scarica senza controllo e con MPC']);
    exportgraphics(fig, fullfile(uscita, sprintf('%s_scarica_%s.png', nomi{indice_scenario}, tipo)), ...
        'Resolution', 150);
end
