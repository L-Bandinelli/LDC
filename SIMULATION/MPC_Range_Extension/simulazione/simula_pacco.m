function ris = simula_pacco(tipo, pacco, par, scen, p)
%SIMULA_PACCO  Simulazione ad anello chiuso fino al cedimento del pacco.
%
%   tipo = 'nessuno' (senza bilanciamento) | 'Jt' | 'Jm' | 'Jdelta'
%   scen = scenario di carico (par.scenarioA oppure par.scenarioB)
%   p    = orizzonte di predizione
%
% Il pacco cede quando la tensione di una cella scende sotto y_min, eq. (5).
% ris contiene le storie temporali (una riga per passo) e le metriche.

Ts = par.mpc.Ts;
N  = pacco.numero_celle;
K  = ceil(par.sim.t_max / Ts);

s  = par.pacco.SOC_iniziale * ones(N, 1);
Vp = zeros(N, 1);
i  = par.carico.i0;
u  = zeros(N, 1);

controllo = ~strcmp(tipo, 'nessuno');
if controllo
    ctrl = crea_mpc(tipo, pacco, par, p);
end

ris.s = zeros(K, N);  ris.y = zeros(K, N);  ris.u = zeros(K, N);
ris.i = zeros(K, 1);  ris.E = zeros(K, 1);
ris.Vp = zeros(K, N);
ris.t_calcolo = zeros(K, 1);  ris.flag = ones(K, 1);  ris.morbido = false(K, 1);
ris.motivo = 'tempo massimo';

for k = 1:K
    E = profilo_E(scen, (k-1)*Ts);

    if controllo
        tic
        [u, ctrl, info] = mpc_bilanciamento(ctrl, s, Vp, i);
        ris.t_calcolo(k) = toc;
        ris.flag(k)      = info.flag;
        ris.morbido(k)   = info.morbido;
    end

    [y, s_succ, Vp_succ] = modello_cella(pacco, s, Vp, i + u, Ts);

    ris.s(k, :) = s.';  ris.Vp(k, :) = Vp.';  ris.y(k, :) = y.';  ris.u(k, :) = u.';
    ris.i(k) = i;       ris.E(k) = E;

    if min(y) < par.mpc.y_min
        ris.motivo = 'tensione minima';
        break
    elseif min(s) <= 0
        ris.motivo = 'SOC esaurito';
        break
    end

    i  = carico_rle(pacco, par, s, Vp, u, i, E, Ts);
    s  = s_succ;
    Vp = Vp_succ;
end

campi = {'s', 'Vp', 'y', 'u', 'i', 'E', 't_calcolo', 'flag', 'morbido'};
for j = 1:numel(campi)
    ris.(campi{j}) = ris.(campi{j})(1:k, :);
end

ris.tipo    = tipo;
ris.p       = p;
ris.t       = (0:k-1).' * Ts;
ris.durata  = ris.t(end);                         % [s] tempo di funzionamento
ris.sforzo  = sum(ris.u.^2, 2);                   % [A^2] e_k = u_k'*u_k
ris.sforzo_medio = mean(ris.sforzo);
ris.energia = sum(ris.E .* ris.i) * Ts / 3600;    % [Wh] energia ceduta alla f.e.m.

end
