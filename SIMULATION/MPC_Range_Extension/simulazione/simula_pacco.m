function ris = simula_pacco(tipo, pacco, par, scen, p)
%SIMULA_PACCO  Simulazione ad anello chiuso fino al cedimento del pacco.
%
%   tipo = 'nessuno' (senza bilanciamento) | 'Jt' | 'Jm' | 'Jdelta'
%   scen = scenario di carico (par.scenarioA oppure par.scenarioB)
%   p    = orizzonte di predizione
%
% Il pacco cede quando la tensione di una cella scende sotto y_min, eq. (5).
% ris contiene le storie temporali (una riga per passo) e le metriche.
% Un solo passo, par.mpc.Tc, sia per il controllo sia per il modello fisico.

Tc = par.mpc.Tc;
N  = pacco.N;
K  = ceil(par.tempi.t_max / Tc);

s       = par.pacco.s_iniziale * ones(N, 1);
Vp      = zeros(N, 1);
i_pacco = par.carico.i_pacco_iniziale;
u       = zeros(N, 1);

controllo = ~strcmp(tipo, 'nessuno');
if controllo
    ctrl = crea_mpc(tipo, pacco, par, p);
end

ris.s = zeros(K, N);  ris.y = zeros(K, N);  ris.u = zeros(K, N);
ris.i_pacco = zeros(K, 1);  ris.E = zeros(K, 1);
ris.Vp = zeros(K, N);
ris.t_calcolo = zeros(K, 1);  ris.esito = ones(K, 1);  ris.morbido = false(K, 1);
ris.motivo = 'tempo massimo';

for k = 1:K
    E = profilo_E(scen, (k-1)*Tc);

    if controllo
        tic
        [u, ctrl, info] = mpc_bilanciamento(ctrl, s, Vp, i_pacco);
        ris.t_calcolo(k) = toc;
        ris.esito(k)     = info.esito;
        ris.morbido(k)   = info.morbido;
    end

    [y, s_next, Vp_next] = modello_cella(pacco, s, Vp, i_pacco + u, Tc);

    ris.s(k, :) = s.';  ris.Vp(k, :) = Vp.';  ris.y(k, :) = y.';  ris.u(k, :) = u.';
    ris.i_pacco(k) = i_pacco;       ris.E(k) = E;

    if min(y) < par.mpc.y_min
        ris.motivo = 'tensione minima';
        break
    elseif min(s) <= 0
        ris.motivo = 'SOC esaurito';
        break
    end

    i_pacco = carico_rle(pacco, par, s, Vp, u, i_pacco, E, Tc);
    s       = s_next;
    Vp      = Vp_next;
end

campi = {'s', 'Vp', 'y', 'u', 'i_pacco', 'E', 't_calcolo', 'esito', 'morbido'};
for indice_campo = 1:numel(campi)
    ris.(campi{indice_campo}) = ris.(campi{indice_campo})(1:k, :);
end

ris.tipo    = tipo;
ris.p       = p;
ris.t       = (0:k-1).' * Tc;
ris.durata  = ris.t(end);                         % [s] tempo di funzionamento
ris.w       = sum(ris.u.^2, 2);                   % [A^2] sforzo di bilanciamento w_k = u_k'*u_k
ris.w_medio = mean(ris.w);                        % [A^2] sforzo medio, media di w_k sui passi
ris.energia = sum(ris.E .* ris.i_pacco) * Tc / 3600;    % [Wh] energia ceduta alla f.e.m.

end
