function par_sim = parametri_simulazione(par, pacco, tipo, scen, p)
%PARAMETRI_SIMULAZIONE  Parametri di una simulazione del modello Bilanciamento_MPC_Jt.slx.
%
%   par_sim = parametri_simulazione(par, pacco, tipo, scen, p)
%
%   par, pacco  da init_parametri e genera_pacco
%   tipo        'Jt'         MPC con il costo J_t, eq. (7) del paper, vincolo di
%                            tensione morbido (con epsilon_y, eq. (17))
%               'Jt_rigido'  lo stesso MPC con il vincolo di tensione rigido
%                            (senza epsilon_y): la variante si sceglie nel
%                            blocco Problema_QP, qui non cambia nulla
%               'nessuno'    stesso modello, con le correnti di bilanciamento azzerate
%   scen        scenario di carico (par.scenarioA oppure par.scenarioB)
%   p           orizzonte di predizione (facoltativo, default par.mpc.p)
%
% Questa versione del modello risolve solo il problema con il costo J_t e
% insegue la tensione ai morsetti y: il valore di par.mpc.sigma non conta.
%
% par raccoglie tutti i parametri liberi del progetto; par_sim contiene i
% numeri di UNA simulazione, ricavati da par. Sono parametri, non variabili
% della simulazione: i blocchi del modello li leggono da qui. Va messa nel
% workspace di base con il nome 'par_sim'.
%
% Senza argomenti usa init_parametri.m, J_t e lo scenario A: e' quello che fa
% il modello all'apertura se 'par_sim' non esiste ancora.

if nargin == 0
    init_parametri;
    pacco = genera_pacco(par);
    tipo  = 'Jt';
    scen  = par.scenarioA;
end
if nargin < 5
    p = par.mpc.p;
end
N  = pacco.N;

%% Passi di tempo
% Il modello fisico avanza con il passo di integrazione Tint; il controllo
% campiona le misure, predice e decide con il passo di controllo Tc, e tra una
% decisione e l'altra le correnti di bilanciamento restano costanti.
Tc = par.mpc.Tc;
if isfield(par.tempi, 'Tint')
    Tint = par.tempi.Tint;
else
    Tint = Tc;         % un solo passo, come simula_pacco
end
rapporto = Tc / Tint;
if rapporto < 1 || abs(rapporto - round(rapporto)) > 1e-9
    error('par.mpc.Tc (%g s) deve essere un multiplo intero di par.tempi.Tint (%g s).', ...
        Tc, Tint);
end

%% Bilanciamento acceso o spento
% Il blocco Bilanciamento_attivo moltiplica le correnti scelte dall'MPC per
% par_sim.attivo: con 0 il pacco lavora senza bilanciamento.
switch tipo
    case {'Jt', 'Jt_rigido'}, par_sim.attivo = 1;
    case 'nessuno',           par_sim.attivo = 0;
    otherwise
        error('Questo modello risolve solo J_t: tipo deve essere ''Jt'', ''Jt_rigido'' oppure ''nessuno'', non ''%s''.', tipo);
end

par_sim.N    = N;
par_sim.p    = p;
par_sim.Tint = Tint;                                         % [s] modello fisico
par_sim.Tc   = Tc;                                           % [s] MPC: campionamento e passo della predizione
par_sim.u_min = par.mpc.u_min;
par_sim.u_max = par.mpc.u_max;
par_sim.y_min = par.mpc.y_min;
par_sim.rho   = par.mpc.Jt * p / par.mpc.p_rif;              % rho = rho_rif*p/p_rif (R = rho*I)
par_sim.W     = par.mpc.W;

%% Celle del pacco e cella nominale
% kappa dentro par_sim.pacco e par_sim.nominale vale per un passo di
% controllo: e' quello del modello di predizione dell'MPC. Il modello fisico
% usa kappa_int.
par_sim.pacco    = celle(pacco, Tc, N);
par_sim.nominale = celle(pacco.nominale, Tc, 1);
par_sim.kappa_int = pacco.eta .* Tint ./ (3600 * pacco.C) .* ones(N, 1);

%% Condizioni iniziali
par_sim.s_iniziale       = par.pacco.s_iniziale * ones(N, 1);
par_sim.Vp_iniziale      = zeros(N, 1);
par_sim.i_pacco_iniziale = par.carico.i_pacco_iniziale;

%% Carico R-L-E
par_sim.carico.R = par.carico.R;
par_sim.carico.L = par.carico.L;
if isscalar(scen.E)
    % f.e.m. costante: tabella di due punti uguali
    par_sim.carico.t_E     = [0 1];
    par_sim.carico.E       = [scen.E scen.E];
    par_sim.carico.periodo = 1;
else
    par_sim.carico.t_E     = scen.t_E(:).';
    par_sim.carico.E       = scen.E(:).';
    par_sim.carico.periodo = scen.t_E(end);
end

%% Durata massima: istanti t = 0, Tint, ..., (K-1)*Tint
par_sim.t_fine = (ceil(par.tempi.t_max / Tint) - 1) * Tint;

end

function c = celle(pacco, Tc, N)
c.s_tab   = pacco.s_tab;
c.Voc_tab = pacco.Voc_tab;
c.Ro_tab  = pacco.Ro_tab;
c.Rp_tab  = pacco.Rp_tab;
c.Cp_tab  = pacco.Cp_tab;
c.phi.Voc = pacco.phi.Voc .* ones(N, 1);
c.phi.Ro  = pacco.phi.Ro  .* ones(N, 1);
c.phi.Rp  = pacco.phi.Rp  .* ones(N, 1);
c.phi.Cp  = pacco.phi.Cp  .* ones(N, 1);
% (2a): in un passo il SOC scende di kappa*I_cella
c.kappa = pacco.eta .* Tc ./ (3600 * pacco.C) .* ones(N, 1);
end
