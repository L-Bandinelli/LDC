function ris = simula_simulink(tipo, pacco, par, scen, p)
%SIMULA_SIMULINK  Come simula_pacco, ma l'anello chiuso e' il modello Simulink.
%
%   tipo = 'nessuno' (senza bilanciamento) | 'Jt' | 'Jm' | 'Jdelta'
%   scen = scenario di carico (par.scenarioA oppure par.scenarioB)
%   p    = orizzonte di predizione
%
% Esegue Bilanciamento_MPC.slx fino al cedimento del pacco e restituisce ris
% con gli stessi campi di simula_pacco: le funzioni in grafici/ funzionano
% con entrambe.

modello = 'Bilanciamento_MPC';
par_sim = parametri_simulazione(par, pacco, tipo, scen, p);

load_system(modello);
ingresso = Simulink.SimulationInput(modello);
ingresso = ingresso.setVariable('par_sim', par_sim);
uscita   = sim(ingresso);

% Una riga per passo di integrazione. I segnali dell'MPC cambiano solo a ogni
% passo di controllo: tra un passo e l'altro vale l'ultimo valore.
registro = uscita.logsout;
ris.t  = uscita.tout;
ris.s  = valori(registro, 's', ris.t);
ris.Vp = valori(registro, 'Vp', ris.t);
ris.y  = valori(registro, 'y', ris.t);
ris.u  = valori(registro, 'u', ris.t);
ris.i_pacco = valori(registro, 'i_pacco', ris.t);
ris.E  = valori(registro, 'E', ris.t);
ris.sigma0  = valori(registro, 'sigma0', ris.t);         % riferimento della cella nominale, p colonne
ris.esito   = valori(registro, 'esito', ris.t);          % exitflag di quadprog
ris.morbido = valori(registro, 'epsilon_y', ris.t) > 1e-6;   % vincolo di tensione rilassato, eq. (17)

if min(ris.y(end, :)) < par.mpc.y_min
    ris.motivo = 'tensione minima';
elseif min(ris.s(end, :)) <= 0
    ris.motivo = 'SOC esaurito';
else
    ris.motivo = 'tempo massimo';
end

ris.tipo    = tipo;
ris.p       = p;
ris.durata  = ris.t(end);                             % [s] tempo di funzionamento
ris.w       = sum(ris.u.^2, 2);                       % [A^2] sforzo di bilanciamento w_k = u_k'*u_k
ris.w_medio = mean(ris.w);                            % [A^2] sforzo medio, media di w_k sui passi
ris.energia = sum(ris.E .* ris.i_pacco) * par_sim.Tint / 3600;    % [Wh] energia ceduta alla f.e.m.

end

function v = valori(registro, nome, t)
% Segnale registrato come matrice con una riga per istante di t
serie = registro.get(nome).Values;
dati  = serie.Data;
if ndims(dati) == 3
    % segnali colonna: Simulink li registra come (righe x 1 x passi)
    dati = permute(dati, [3 1 2]);
end
if size(dati, 1) == numel(t)
    v = dati;
else
    % segnale a passo di controllo: ultimo campione non successivo a ogni istante
    riga = interp1(serie.Time, (1:numel(serie.Time)).', t, 'previous', 'extrap');
    v    = dati(riga, :);
end
end
