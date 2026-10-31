function sigma0 = cella_nominale_semplice(par_sim, s, Vp, i_pacco)
%CELLA_NOMINALE_SEMPLICE  Riferimento della cella nominale per J_t, eq. (7).
%
% Idea: si prende una cella "ideale" (parametri nominali, senza deviazioni),
% la si fa partire dallo stato medio del pacco e la si fa scaricare per p
% passi di controllo con la sola corrente di pacco, senza bilanciamento.
% La sua tensione a ogni passo e' il riferimento che le celle vere devono
% inseguire. Le grandezze della cella nominale hanno il suffisso 0, come
% l'apice 0 del paper: s0, Vp0, y0.
%
%   par_sim   parametri della simulazione (da parametri_simulazione)
%   s, Vp     SOC e tensione di polarizzazione di ogni cella, adesso
%   i_pacco   corrente di pacco, positiva in scarica
%   sigma0    riferimento, p x 1: la riga j vale tra j passi di controllo

%% Dati
p  = par_sim.p;                     % numero di passi dell'orizzonte
Tc = par_sim.Tc;                    % [s] durata di un passo di controllo

% Tabelle della cella nominale: ogni parametro in 7 punti di SOC
s_tab   = par_sim.nominale.s_tab;
Voc_tab = par_sim.nominale.Voc_tab;      % [V]
Ro_tab  = par_sim.nominale.Ro_tab;       % [Ohm]
Rp_tab  = par_sim.nominale.Rp_tab;       % [Ohm]
Cp_tab  = par_sim.nominale.Cp_tab;       % [F]

% SOC perso in un passo per ogni ampere: kappa = eta*Tc/(3600*C)
kappa = par_sim.nominale.kappa;

%% Stato di partenza: la media delle celle del pacco
s0  = mean(s);
Vp0 = mean(Vp);

%% Scarica della cella nominale, un passo alla volta
sigma0 = zeros(p, 1);

for j = 1:p

    % Parametri del ramo RC al SOC di inizio passo.
    % Le tabelle vanno da SOC = 0 a SOC = 1: fuori si usa il valore dell'estremo.
    s_limitato = min(max(s0, s_tab(1)), s_tab(end));
    Rp = interp1(s_tab, Rp_tab, s_limitato);
    Cp = interp1(s_tab, Cp_tab, s_limitato);

    % (2b) tensione di polarizzazione dopo un passo
    Vp0 = Vp0 + Tc * (-Vp0 / (Rp * Cp) + i_pacco / Cp);

    % (2a) SOC dopo un passo; una cella piena non si carica oltre
    s0 = s0 - kappa * i_pacco;
    if s0 > 1
        s0 = 1;
    end

    % (2c) tensione ai morsetti con il nuovo stato
    s_limitato = min(max(s0, s_tab(1)), s_tab(end));
    Voc = interp1(s_tab, Voc_tab, s_limitato);
    Ro  = interp1(s_tab, Ro_tab,  s_limitato);

    y0 = Voc - Vp0 - Ro * i_pacco;

    % Grandezza inseguita dall'MPC: la tensione oppure il SOC
    if par_sim.sigma_tensione == 1
        sigma0(j) = y0;
    else
        sigma0(j) = s0;
    end

end

end
