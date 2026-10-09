%% main_throughput.m
% Tempo di calcolo di un passo MPC per le tre formulazioni e per piu' orizzonti
% p (stile Tabella II del paper). Gli stati su cui si misura sono campionati da
% una simulazione dello scenario A con J_t.

clear; close all; clc
cartella = fileparts(mfilename('fullpath'));
addpath(genpath(cartella));

init_parametri;
pacco = genera_pacco(par);

%% Stati di prova
rif = simula_pacco('Jt', pacco, par, par.scenarioA, par.mpc.p);
K   = numel(rif.t);
k   = round(linspace(2, K - 1, par.throughput.campioni));

%% Misura
tipi      = {'Jt', 'Jm', 'Jdelta'};
orizzonti = par.throughput.orizzonti;
t_ms      = zeros(numel(orizzonti), numel(tipi));

for h = 1:numel(orizzonti)
    for c = 1:numel(tipi)
        ctrl  = crea_mpc(tipi{c}, pacco, par, orizzonti(h));
        tempi = zeros(numel(k), 1);
        for m = 1:numel(k)
            tic
            [~, ctrl] = mpc_bilanciamento(ctrl, rif.s(k(m), :).', rif.Vp(k(m), :).', rif.i(k(m)));
            tempi(m) = toc;
        end
        t_ms(h, c) = 1e3 * median(tempi);
    end
end

%% Tabella (stile Tabella II)
fprintf('\nTempo mediano di un passo MPC [ms], N = %d celle\n', pacco.numero_celle);
fprintf('%4s %10s %10s %10s\n', 'p', tipi{:});
for h = 1:numel(orizzonti)
    fprintf('%4d %10.2f %10.2f %10.2f\n', orizzonti(h), t_ms(h, :));
end

uscita = fullfile(cartella, 'risultati');
if ~exist(uscita, 'dir'), mkdir(uscita); end
save(fullfile(uscita, 'throughput.mat'), 't_ms', 'orizzonti', 'tipi');
