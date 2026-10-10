function sigma0 = cella_nominale_semplice(sl, s, Vp, i_pacco)
%CELLA_NOMINALE_SEMPLICE  Riferimento della cella nominale per J_t, eq. (7).
%
% Idea: si prende una cella "ideale" (parametri nominali, senza deviazioni),
% la si fa partire dallo stato medio del pacco e la si fa scaricare per p
% passi di controllo con la sola corrente di pacco, senza bilanciamento.
% La sua tensione a ogni passo e' il riferimento che le celle vere devono
% inseguire.
%
%   sl        parametri del modello (da init_simulink)
%   s, Vp     SOC e tensione di polarizzazione di ogni cella, adesso
%   i_pacco   corrente di pacco, positiva in scarica
%   sigma0    riferimento, p x 1: la riga j vale tra j passi di controllo

%% Dati
p  = sl.p;                          % numero di passi dell'orizzonte
Ts = sl.Ts_controllo;               % [s] durata di un passo

% Tabelle della cella nominale: ogni parametro in 7 punti di SOC
tabella_SOC     = sl.nominale.tabella_SOC;
tabella_V_vuoto = sl.nominale.tabella_V_vuoto;      % [V]
tabella_R_serie = sl.nominale.tabella_R_serie;      % [Ohm]
tabella_R_pol   = sl.nominale.tabella_R_pol;        % [Ohm]
tabella_C_pol   = sl.nominale.tabella_C_pol;        % [F]

% SOC perso in un passo per ogni ampere: rendimento*Ts/(3600*capacita_Ah)
kappa = sl.nominale.kappa;

%% Stato di partenza: la media delle celle del pacco
SOC   = mean(s);
V_pol = mean(Vp);

%% Scarica della cella nominale, un passo alla volta
sigma0 = zeros(p, 1);

for j = 1:p

    % Parametri del ramo RC al SOC di inizio passo.
    % Le tabelle vanno da SOC = 0 a SOC = 1: fuori si usa il valore dell'estremo.
    SOC_in_tabella = min(max(SOC, tabella_SOC(1)), tabella_SOC(end));
    R_pol = interp1(tabella_SOC, tabella_R_pol, SOC_in_tabella);
    C_pol = interp1(tabella_SOC, tabella_C_pol, SOC_in_tabella);

    % (2b) tensione di polarizzazione dopo un passo
    V_pol = V_pol + Ts * (-V_pol / (R_pol * C_pol) + i_pacco / C_pol);

    % (2a) SOC dopo un passo; una cella piena non si carica oltre
    SOC = SOC - kappa * i_pacco;
    if SOC > 1
        SOC = 1;
    end

    % (2c) tensione ai morsetti con il nuovo stato
    SOC_in_tabella = min(max(SOC, tabella_SOC(1)), tabella_SOC(end));
    V_vuoto = interp1(tabella_SOC, tabella_V_vuoto, SOC_in_tabella);
    R_serie = interp1(tabella_SOC, tabella_R_serie, SOC_in_tabella);

    V_cella = V_vuoto - V_pol - R_serie * i_pacco;

    % Grandezza inseguita dall'MPC: la tensione oppure il SOC
    if sl.sigma_tensione == 1
        sigma0(j) = V_cella;
    else
        sigma0(j) = SOC;
    end

end

end
