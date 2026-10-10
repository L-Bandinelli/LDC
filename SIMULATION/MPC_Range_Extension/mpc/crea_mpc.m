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

% =========================================================================
% =========================================================================
%
%   ATTENZIONE - PROBLEMA APERTO: L'MPC CON nlmpc E' LENTO
%
% -------------------------------------------------------------------------
% IL PROBLEMA
%
%   Con l'oggetto nlmpc del Model Predictive Control Toolbox un passo di
%   controllo costa tra 15 e 140 ms (misurato con N = 5 celle, p = 5).
%   La versione precedente, con il problema linearizzato e quadprog,
%   costava circa 1 ms a passo.
%
%   Una scarica dura 2500-3000 passi: ogni simulazione passa da pochi
%   secondi a qualche minuto. Lo scenario B (9 simulazioni, orizzonti fino
%   a p = 15) richiede decine di minuti; p = 35 in main_throughput e'
%   ancora piu' pesante.
%
% PERCHE' E' LENTO
%
%   - nlmpc risolve a ogni passo un problema NON lineare con fmincon (SQP),
%     non un QP.
%   - Anche gli stati predetti sono incognite: 2*N*p variabili in piu'
%     rispetto alle sole correnti di bilanciamento (50 con N = 5, p = 5).
%   - nlmpcmove ha un costo fisso di validazione a ogni chiamata.
%   Le derivate analitiche sono gia' fornite (nlobj.Jacobian): senza, il
%   passo costava circa 300 ms.
%
% I RISULTATI NON SONO IN DISCUSSIONE
%
%   Nello scenario A nessun passo fallito, somma delle u nulla, e J_t
%   identico alla versione con quadprog (2529 s, +6.35 %). Il problema e'
%   solo il tempo di calcolo.
%
% ALTERNATIVE (nessuna ancora applicata)
%
%   1) SOLUTORE QP DEL TOOLBOX MPC
%      Tornare al problema linearizzato a ogni passo (Remark 3 del paper)
%      e risolverlo con mpcActiveSetSolver o mpcInteriorPointSolver al
%      posto di quadprog. Atteso circa 1 ms a passo.
%      Contro: si perde l'oggetto nlmpc; entrambi i solutori vogliono un
%      Hessiano definito positivo, quindi per J_m e J_Delta serve una
%      piccola regolarizzazione sulle slack eps.
%
%   2) TENERE nlmpc E COMPILARLO IN MEX
%      Con MATLAB Coder (buildMEX / nlmpcmoveCodeGeneration). Sul PC ci
%      sono sia il Coder sia il compilatore MinGW. Di solito e' alcune
%      volte piu' veloce, ma qui non e' stato misurato.
%      Contro: va ricompilato per ogni formulazione e ogni orizzonte
%      (circa un minuto ciascuno) e il codice va adattato ai limiti del
%      Coder (niente funzioni annidate, niente campi dinamici).
%
%   3) TORNARE A quadprog
%      Ripristinare la versione senza toolbox MPC: circa 1 ms a passo.
%      Attenzione: con quella versione J_m e J_Delta davano circa +6.3 %
%      nello scenario A contro il +4.2 / +4.6 % di adesso; la differenza
%      sta nel modo in cui si rilassa il vincolo di tensione e non e'
%      stata chiarita.
%
%   4) ALLEGGERIRE LE PROVE SENZA CAMBIARE CODICE
%      Ridurre par.scenarioB.orizzonti e par.throughput.orizzonti in
%      init_parametri.m (per esempio solo p = 5).
%
% =========================================================================
% =========================================================================

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
