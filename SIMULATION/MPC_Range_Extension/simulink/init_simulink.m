function sl = init_simulink(par, pacco, tipo, scen, p)
%INIT_SIMULINK  Parametri del modello Simulink Bilanciamento_MPC.slx.
%
%   sl = init_simulink(par, pacco, tipo, scen, p)
%
%   par, pacco  da init_parametri e genera_pacco
%   tipo        'nessuno' | 'Jt' | 'Jm' | 'Jdelta'
%   scen        scenario di carico (par.scenarioA oppure par.scenarioB)
%   p           orizzonte di predizione (facoltativo, default par.mpc.p)
%
% sl contiene solo numeri: i blocchi del modello e le funzioni qp_* leggono
% tutto da qui. Va messa nel workspace di base con il nome 'sl'.
%
% Senza argomenti usa init_parametri.m, J_t e lo scenario A: e' quello che fa
% il modello all'apertura se 'sl' non esiste ancora.

if nargin == 0
    init_parametri;
    pacco = genera_pacco(par);
    tipo  = 'Jt';
    scen  = par.scenarioA;
end
if nargin < 5
    p = par.mpc.p;
end
N  = pacco.numero_celle;

%% Passi di tempo
% Il modello fisico avanza con il passo di integrazione; il controllo campiona
% le misure, predice e decide con il passo di controllo, e tra una decisione
% e l'altra le correnti di bilanciamento restano costanti.
Ts_controllo = par.mpc.Ts;
if isfield(par.sim, 'Ts_integrazione')
    Ts_integrazione = par.sim.Ts_integrazione;
else
    Ts_integrazione = Ts_controllo;         % un solo passo, come simula_pacco
end
rapporto = Ts_controllo / Ts_integrazione;
if rapporto < 1 || abs(rapporto - round(rapporto)) > 1e-9
    error('par.mpc.Ts (%g s) deve essere un multiplo intero di par.sim.Ts_integrazione (%g s).', ...
        Ts_controllo, Ts_integrazione);
end

%% Formulazione dell'MPC
switch tipo
    case 'nessuno', sl.tipo = 1;  sl.attivo = 0;  nome_r = 'Jt';
    case 'Jt',      sl.tipo = 1;  sl.attivo = 1;  nome_r = 'Jt';
    case 'Jm',      sl.tipo = 2;  sl.attivo = 1;  nome_r = 'Jm';
    case 'Jdelta',  sl.tipo = 3;  sl.attivo = 1;  nome_r = 'Jdelta';
    otherwise,      error('Formulazione sconosciuta: %s', tipo);
end

sl.N  = N;
sl.p  = p;
sl.Ts_integrazione = Ts_integrazione;       % [s] modello fisico
sl.Ts_controllo    = Ts_controllo;          % [s] MPC: campionamento e passo della predizione
sl.sigma_tensione = double(par.mpc.sigma == 'y');            % 1 tensione, 0 SOC
sl.u_min = par.mpc.u_min;
sl.u_max = par.mpc.u_max;
sl.y_min = par.mpc.y_min;
sl.r     = par.mpc.r.(nome_r) * p / par.mpc.p_rif;           % R = r*I, scalato con p
sl.W     = par.mpc.W;

% Dimensioni del QP: z = [u; eps; e]
sl.n_eps = (sl.tipo - 1) * p;                                % 0, p, 2p
sl.n_z   = N + sl.n_eps + 1;
sl.n_dis = sl.tipo * p * N + 2*N + 1;                        % righe di A

%% Celle del pacco e cella nominale
% kappa dentro sl.pacco e sl.nominale vale per un passo di controllo: e' quello
% del modello di predizione dell'MPC. Il modello fisico usa kappa_integrazione.
sl.pacco    = celle(pacco, Ts_controllo, N);
sl.nominale = celle(pacco.nominale, Ts_controllo, 1);
sl.kappa_integrazione = pacco.rendimento .* Ts_integrazione ./ (3600 * pacco.capacita_Ah) .* ones(N, 1);

%% Condizioni iniziali
sl.SOC_iniziale = par.pacco.SOC_iniziale * ones(N, 1);
sl.Vp_iniziale  = zeros(N, 1);
sl.i_iniziale   = par.carico.i0;

%% Carico R-L-E
sl.carico.R = par.carico.R;
sl.carico.L = par.carico.L;
if isscalar(scen.E)
    % f.e.m. costante: tabella di due punti uguali
    sl.carico.t_E     = [0 1];
    sl.carico.E       = [scen.E scen.E];
    sl.carico.periodo = 1;
else
    sl.carico.t_E     = scen.t_E(:).';
    sl.carico.E       = scen.E(:).';
    sl.carico.periodo = scen.t_E(end);
end

%% Durata massima: istanti t = 0, Ts_integrazione, ..., (K-1)*Ts_integrazione
sl.t_fine = (ceil(par.sim.t_max / Ts_integrazione) - 1) * Ts_integrazione;

end

function c = celle(pacco, Ts, N)
c.tabella_SOC     = pacco.tabella_SOC;
c.tabella_V_vuoto = pacco.tabella_V_vuoto;
c.tabella_R_serie = pacco.tabella_R_serie;
c.tabella_R_pol   = pacco.tabella_R_pol;
c.tabella_C_pol   = pacco.tabella_C_pol;
c.f_V_vuoto = pacco.fattore.V_vuoto .* ones(N, 1);
c.f_R_serie = pacco.fattore.R_serie .* ones(N, 1);
c.f_R_pol   = pacco.fattore.R_pol   .* ones(N, 1);
c.f_C_pol   = pacco.fattore.C_pol   .* ones(N, 1);
% (2a): in un passo il SOC scende di kappa*corrente
c.kappa = pacco.rendimento .* Ts ./ (3600 * pacco.capacita_Ah) .* ones(N, 1);
end
