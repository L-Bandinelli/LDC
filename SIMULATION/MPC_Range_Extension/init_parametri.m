%% init_parametri.m
% Parametri del progetto, per la simulazione del paper
%   J. Chen, A. Behal, C. Li, "Active Cell Balancing by Model Predictive
%   Control for Real Time Range Extension", IEEE CDC 2021.
%
% Lo script crea la struct 'par'. Tutti i valori liberi stanno qui.
% I nomi seguono DOCUMENTS/Notazione.md.
% Convenzione di segno del paper: corrente positiva = scarica della cella.

par = struct();

%% 1) Cella nominale - unica temperatura di funzionamento: 20 °C
% Cella Li-ion a un ramo RC di Huria, Ceraolo, Gazzarri, Jackey (IEVC 2012).
% I valori sono la colonna a 20 °C delle tabelle di SIMULATION/init.m.

par.cella.temperatura = 20;                                                   % [°C]
par.cella.s_tab       = [0      0.1    0.25   0.5    0.75   0.9    1     ]';  % [-]   punti di SOC delle tabelle
par.cella.Voc_tab     = [3.5057 3.5660 3.6337 3.7127 3.9259 4.0777 4.1928]';  % [V]   tensione a vuoto V_oc (Em_LUT in init.m)
par.cella.Ro_tab      = [0.0085 0.0085 0.0087 0.0082 0.0083 0.0085 0.0085]';  % [Ohm] resistenza serie R_o (R0_LUT in init.m)
par.cella.Rp_tab      = [0.0029 0.0024 0.0026 0.0016 0.0023 0.0018 0.0017]';  % [Ohm] resistenza di polarizzazione R_p (R1_LUT in init.m)
par.cella.Cp_tab      = [12447  18872  40764  18721  33630  18360  23394 ]';  % [F]   capacita' di polarizzazione C_p (C1_LUT in init.m)
par.cella.C           = 27.6250;                                              % [Ah]  capacita' della cella C: carica erogabile
par.cella.eta         = 1;                                                    % [-]   rendimento coulombico eta

%% 2) Pacco e variabilita' tra le celle
% Ogni parametro P di ogni cella vale
%   (valore nominale) x phi_P,   phi_P casuale tra 1 - delta_P e 1 + delta_P
% Vedi DOCUMENTS/Variabilita_tra_Celle_MPC.md.

par.pacco.N            = 3;       % numero di celle in serie
par.pacco.s_iniziale   = 1;       % [-] SOC iniziale, uguale per tutte le celle
par.pacco.delta.Voc    = 0.01;    % [-] deviazione massima relativa della tensione a vuoto
par.pacco.delta.Ro     = 0.10;    % [-] della resistenza serie
par.pacco.delta.Rp     = 0.10;    % [-] della resistenza di polarizzazione
par.pacco.delta.Cp     = 0.10;    % [-] della capacita' di polarizzazione
par.pacco.delta.C      = 0;       % [-] della capacita' della cella
par.pacco.seme_casuale = 1;       % stesso seme = stesse celle a ogni esecuzione

%% 3) Bilanciatore e MPC

par.mpc.Tc    = 20;           % [s] passo di controllo T_c (T_s nel paper)
par.mpc.p     = 30;           % orizzonte di predizione [passi]
par.mpc.sigma = 'y';         % grandezza bilanciata: 'y' tensione, 's' SOC
par.mpc.u_min = -2;          % [A] limiti della corrente di bilanciamento, eq. (6d)
par.mpc.u_max =  2;          % [A]
par.mpc.y_min = 3.2;         % [V] tensione minima di cella, eq. (5)

% Peso sulle correnti di bilanciamento, uno per formulazione: il campo ha il
% nome della formulazione e contiene rho_rif, il peso riferito all'orizzonte
% p_rif. Il peso usato e' rho = rho_rif*p/p_rif (la matrice R del paper e' rho*I).
par.mpc.Jt     = 2e-4;       % inseguimento della cella nominale, eq. (7)
par.mpc.Jm     = 1e-2;       % massimizzazione della cella piu' bassa, eq. (9)
par.mpc.Jdelta = 2e-2;       % minimizzazione della differenza max-min, eq. (12)
par.mpc.p_rif  = 5;          % orizzonte a cui sono riferiti i pesi
par.mpc.W      = 1e3;        % peso della variabile di rilassamento epsilon_y del vincolo di tensione, eq. (17)

%% 4) Carico R-L-E in serie al pacco (stile motore DC)
% L*di_pacco/dt = V_pacco - R*i_pacco - E(t)

par.carico.R                = 0.25;   % [Ohm] resistenza del carico
par.carico.L                = 5e-3;   % [H]   induttanza del carico
par.carico.i_pacco_iniziale = 0;      % [A]   corrente di pacco iniziale

%% 5) Scenario A - f.e.m. costante

par.scenarioA.t_E = 0;       % [s]
par.scenarioA.E   = 8;       % [V] f.e.m. del carico

%% 6) Scenario B - f.e.m. periodica a gradini e rampe
% Punti (t_E, E) di un periodo, interpolati linearmente; E(0) = E(fine).

par.scenarioB.t_E = [0  60  65 150 155 240 245 290 295 360 365 420];   % [s]
par.scenarioB.E   = [13 13   6   6  11  11  21  21   9   9  13  13];   % [V]
par.scenarioB.orizzonti = [5 10 15];   % orizzonti p da confrontare

%% 7) Tempi della simulazione e tempi di calcolo

par.tempi.t_max = 6*3600;              % [s] durata massima di una simulazione
par.tempi.Tint  = 1;                   % [s] passo di integrazione T_int del modello fisico in Simulink (sottomultiplo di par.mpc.Tc)
par.throughput.orizzonti = [5 35];     % orizzonti p per la misura dei tempi
par.throughput.campioni  = 40;         % stati su cui si misura il tempo
