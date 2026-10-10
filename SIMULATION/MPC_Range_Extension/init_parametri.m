%% init_parametri.m
% Parametri della simulazione del paper
%   J. Chen, A. Behal, C. Li, "Active Cell Balancing by Model Predictive
%   Control for Real Time Range Extension", IEEE CDC 2021.
%
% Lo script crea la struct 'par'. Tutti i valori liberi stanno qui.
% Convenzione di segno del paper: corrente positiva = scarica della cella.

par = struct();

%% 1) Cella nominale - unica temperatura di funzionamento: 20 °C
% Cella Li-ion a un ramo RC di Huria, Ceraolo, Gazzarri, Jackey (IEVC 2012).
% I valori sono la colonna a 20 °C delle tabelle di SIMULATION/init.m.

par.cella.temperatura     = 20;                                                   % [°C]
par.cella.tabella_SOC     = [0      0.1    0.25   0.5    0.75   0.9    1     ]';  % [-]
par.cella.tabella_V_vuoto = [3.5057 3.5660 3.6337 3.7127 3.9259 4.0777 4.1928]';  % [V]   tensione a vuoto V_oc (Em_LUT in init.m)
par.cella.tabella_R_serie = [0.0085 0.0085 0.0087 0.0082 0.0083 0.0085 0.0085]';  % [Ohm] resistenza serie R_o (R0_LUT in init.m)
par.cella.tabella_R_pol   = [0.0029 0.0024 0.0026 0.0016 0.0023 0.0018 0.0017]';  % [Ohm] resistenza del ramo RC R_p (R1_LUT in init.m)
par.cella.tabella_C_pol   = [12447  18872  40764  18721  33630  18360  23394 ]';  % [F]   capacita' del ramo RC C_p (C1_LUT in init.m)
par.cella.capacita_Ah     = 27.6250;                                              % [Ah]  carica erogabile dalla cella
par.cella.rendimento      = 1;                                                    % [-]   rendimento coulombico

%% 2) Pacco e variabilita' tra le celle
% Ogni parametro di ogni cella vale
%   (valore nominale) x (fattore casuale tra 1 - deviazione e 1 + deviazione)
% Vedi DOCUMENTS/Variabilita_tra_Celle_MPC.md.

par.pacco.numero_celle        = 3;       % celle in serie
par.pacco.SOC_iniziale        = 1;       % [-] uguale per tutte le celle
par.pacco.deviazione.V_vuoto  = 0.01;    % [-] deviazione massima relativa della tensione a vuoto
par.pacco.deviazione.R_serie  = 0.10;    % [-] della resistenza serie
par.pacco.deviazione.R_pol    = 0.10;    % [-] della resistenza del ramo RC
par.pacco.deviazione.C_pol    = 0.10;    % [-] della capacita' del ramo RC
par.pacco.deviazione.capacita = 0;       % [-] della capacita' della cella
par.pacco.seme_casuale        = 1;       % stesso seme = stesse celle a ogni esecuzione

%% 3) Bilanciatore e MPC

par.mpc.Ts    = 20;           % [s] passo di campionamento
par.mpc.p     = 30;           % orizzonte di predizione [passi]
par.mpc.sigma = 'y';         % grandezza bilanciata: 'y' tensione, 's' SOC
par.mpc.u_min = -2;          % [A] limiti della corrente di bilanciamento, eq. (6d)
par.mpc.u_max =  2;          % [A]
par.mpc.y_min = 3.2;         % [V] tensione minima di cella, eq. (5)

% Peso R = r*(p/p_rif)*I sulla corrente di bilanciamento, uno per formulazione.
par.mpc.r.Jt     = 2e-4;     % inseguimento della cella nominale, eq. (7)
par.mpc.r.Jm     = 1e-2;     % massimizzazione della cella piu' bassa, eq. (9)
par.mpc.r.Jdelta = 2e-2;     % minimizzazione della differenza max-min, eq. (12)
par.mpc.p_rif    = 5;        % orizzonte a cui sono riferiti i pesi r
par.mpc.W        = 1e3;      % peso della slack sul vincolo di tensione, eq. (17)

%% 4) Carico R-L-E in serie al pacco (stile motore DC)
% L*di/dt = V_pacco - R*i - E(t)

par.carico.R  = 0.25;        % [Ohm]
par.carico.L  = 5e-3;        % [H]
par.carico.i0 = 0;           % [A] corrente di pacco iniziale

%% 5) Scenario A - f.e.m. costante

par.scenarioA.t_E = 0;       % [s]
par.scenarioA.E   = 8;       % [V]

%% 6) Scenario B - f.e.m. periodica a gradini e rampe
% Punti (t_E, E) di un periodo, interpolati linearmente; E(0) = E(fine).

par.scenarioB.t_E = [0  60  65 150 155 240 245 290 295 360 365 420];   % [s]
par.scenarioB.E   = [13 13   6   6  11  11  21  21   9   9  13  13];   % [V]
par.scenarioB.orizzonti = [5 10 15];   % orizzonti p da confrontare

%% 7) Simulazione e tempi di calcolo

par.sim.t_max = 6*3600;                % [s] durata massima di una simulazione
par.sim.Ts_integrazione = 1;           % [s] passo di integrazione del modello fisico in Simulink (sottomultiplo di par.mpc.Ts)
par.throughput.orizzonti = [5 35];     % orizzonti p per la misura dei tempi
par.throughput.campioni  = 40;         % stati su cui si misura il tempo
