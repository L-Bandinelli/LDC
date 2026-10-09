function ctrl = crea_mpc(tipo, pacco, par, p)
%CREA_MPC  Controllore MPC di bilanciamento con il Model Predictive Control Toolbox.
%
% Costruisce un oggetto nlmpc che risolve il problema (6) del paper sul modello
% non lineare della batteria.
%   tipo = 'Jt'      inseguimento della cella nominale, eq. (7)
%          'Jm'      massimizzazione della cella piu' bassa, eq. (9)-(10)
%          'Jdelta'  minimizzazione della differenza max-min, eq. (12)-(13)
%
% Struttura del controllore:
%   stati               x  = [s; Vp]                 (2N, misurati)
%   variabili manipolate mv = [u; eps]               (N correnti + slack del costo)
%   disturbo misurato   md = corrente di pacco i     (costante sull'orizzonte)
% L'orizzonte di controllo vale 1: u resta costante su tutta la predizione,
% come nel paper. Le eps (p per Jm, 2p per Jdelta) sono una per passo.

N = pacco.numero_celle;
switch tipo
    case 'Jt',     n_eps = 0;
    case 'Jm',     n_eps = p;
    case 'Jdelta', n_eps = 2*p;
end
n_mv = N + n_eps;

nlobj = nlmpc(2*N, 2*N, 'MV', 1:n_mv, 'MD', n_mv + 1);
nlobj.Ts                = par.mpc.Ts;
nlobj.PredictionHorizon = p;
nlobj.ControlHorizon    = 1;

% Modello di predizione: eq. (2a)-(2b) a tempo discreto
nlobj.Model.StateFcn           = @stato_pacco;
nlobj.Model.IsContinuousTime   = false;
nlobj.Model.NumberOfParameters = 1;

% Costo e vincoli del paper
nlobj.Optimization.CustomCostFcn       = @costo_bilanciamento;   % (7), (9), (12)
nlobj.Optimization.ReplaceStandardCost = true;
nlobj.Optimization.CustomIneqConFcn    = @vincoli_disuguaglianza; % (6e)/(17), (10), (13)
nlobj.Optimization.CustomEqConFcn      = @vincolo_somma;          % (6f)
for n = 1:N
    nlobj.MV(n).Min = par.mpc.u_min;                              % (6d)
    nlobj.MV(n).Max = par.mpc.u_max;
end

% Derivate analitiche: senza, l'ottimizzatore le stima per differenze finite
% ed e' molto piu' lento
nlobj.Jacobian.StateFcn         = @jacobiano_stato;
nlobj.Jacobian.CustomCostFcn    = @jacobiano_costo;
nlobj.Jacobian.CustomIneqConFcn = @jacobiano_disuguaglianza;
nlobj.Jacobian.CustomEqConFcn   = @jacobiano_somma;
nlobj.Weights.OutputVariables   = zeros(1, 2*N);     % il costo standard non e' usato

nlobj.Optimization.SolverOptions.Algorithm           = 'sqp';
nlobj.Optimization.SolverOptions.OptimalityTolerance = 1e-7;
nlobj.Optimization.SolverOptions.ConstraintTolerance = 1e-8;
nlobj.Optimization.SolverOptions.StepTolerance       = 1e-10;
nlobj.Optimization.SolverOptions.MaxIterations       = 100;

% Dati passati alle funzioni del modello, del costo e dei vincoli
dati.pacco  = pacco;
dati.par    = par;
dati.tipo   = tipo;
dati.p      = p;
dati.sigma0 = zeros(p, 1);      % riferimento di Jt, aggiornato a ogni passo

ctrl.nlobj = nlobj;
ctrl.dati  = dati;
ctrl.opt   = nlmpcmoveopt;
ctrl.mv    = [];                % ultima mossa [u; eps], vuota al primo passo

end

% Gli jacobiani sono le uscite successive alla prima delle funzioni di costo e
% di vincolo.
function [G, Gmv, Ge] = jacobiano_costo(X, U, e, data, dati)
[~, G, Gmv, Ge] = costo_bilanciamento(X, U, e, data, dati);
end

function [G, Gmv, Ge] = jacobiano_disuguaglianza(X, U, e, data, dati)
[~, G, Gmv, Ge] = vincoli_disuguaglianza(X, U, e, data, dati);
end

function [G, Gmv] = jacobiano_somma(X, U, data, dati)
[~, G, Gmv] = vincolo_somma(X, U, data, dati);
end
