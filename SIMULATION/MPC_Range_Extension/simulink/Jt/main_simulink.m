%% main_simulink.m
% Scenario A (f.e.m. costante, Sez. IV-A del paper) eseguito con il modello
% Simulink Bilanciamento_MPC_Jt.slx. Confronta il pacco senza bilanciamento
% con l'MPC J_t, con il vincolo di tensione morbido (con epsilon_y) e
% rigido (senza): tabella delle durate (stile Tabella I) e figure stile
% Fig. 2 e Fig. 3, salvate in risultati/ con il prefisso Jt_.
%
% Per lo scenario B: scen = par.scenarioB.

clear; close all; clc

% Path: la cartella del modello (questa) e le cartelle del progetto
% MPC_Range_Extension, due livelli sopra. La cartella del modello si
% aggiunge per ultima, cosi' ha la precedenza su altre versioni.
cartella_modello = fileparts(mfilename('fullpath'));
cartella = fileparts(fileparts(cartella_modello));          % MPC_Range_Extension
addpath(cartella, fullfile(cartella, 'modello'), fullfile(cartella, 'mpc'), ...
    fullfile(cartella, 'simulazione'), fullfile(cartella, 'grafici'));
addpath(cartella_modello);

init_parametri;
pacco = genera_pacco(par);
scen  = par.scenarioA;
p     = par.mpc.p;

%% Simulazioni
tipi = {'nessuno', 'Jt', 'Jt_rigido'};
ris  = cell(1, numel(tipi));
for c = 1:numel(tipi)
    ris{c} = simula_simulink(tipi{c}, pacco, par, scen, p);
end

%% Tabella (stile Tabella I)
% L'ultima colonna conta i passi di controllo in cui quadprog non ha trovato
% una soluzione (con il vincolo rigido puo' non esisterne nessuna)
fprintf('\nSimulink J_t - integrazione %g s, controllo %g s, p = %d, N = %d celle\n', ...
    par.tempi.Tint, par.mpc.Tc, p, pacco.N);
fprintf('%-20s %10s %11s %20s  %-16s %s\n', 'Controllo', 'Durata [s]', 'Estensione', ...
    'Sforzo medio w [A^2]', 'Arresto', 'Passi senza soluzione');
for c = 1:numel(tipi)
    est = 100 * (ris{c}.durata / ris{1}.durata - 1);
    passi_falliti = sum(ris{c}.esito(1:round(par.mpc.Tc / par.tempi.Tint):end) <= 0);
    fprintf('%-20s %10.0f %10.2f%% %20.2f  %-16s %d\n', tipi{c}, ris{c}.durata, est, ...
        ris{c}.w_medio, ris{c}.motivo, passi_falliti);
end

%% Figure
uscita = fullfile(cartella, 'risultati');
if ~exist(uscita, 'dir'), mkdir(uscita); end

fig = grafico_celle(ris{2}, par, sprintf('Simulink, J_t (p = %d)', p));
exportgraphics(fig, fullfile(uscita, 'Jt_celle.png'), 'Resolution', 150);

fig = grafico_confronto(ris, par, 'Simulink J_t: tensione minima e sforzo di bilanciamento');
exportgraphics(fig, fullfile(uscita, 'Jt_confronto.png'), 'Resolution', 150);

fig = grafico_scarica(ris{1}, ris{2}, par, 'Simulink J_t: scarica senza controllo e con MPC');
exportgraphics(fig, fullfile(uscita, 'Jt_scarica.png'), 'Resolution', 150);

save(fullfile(uscita, 'Jt_risultati.mat'), 'ris', 'par', 'pacco');
