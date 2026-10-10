function [Y, S, dY, dS] = predizione_linearizzata_semplice(sl, s, Vp, i_pacco, u_prec)
%PREDIZIONE_LINEARIZZATA_SEMPLICE  Predizione delle celle su p passi, eq. (6b)-(6c).
%
% Versione da leggere del blocco Predizione_linearizzata (qp_predizione.m):
% tutto il calcolo e' scritto qui, senza passare da altre funzioni del
% progetto (solo min, max e interp1 di MATLAB). Il modello Simulink non la usa.
%
% Risponde a due domande, per ogni cella e per ogni passo dell'orizzonte:
%   1) dove va la cella se la corrente di bilanciamento resta u_prec?
%      -> Y (tensione) e S (SOC)
%   2) di quanto si sposta se la corrente di bilanciamento aumenta di 1 A?
%      -> dY e dS (Remark 3 del paper)
% Con queste l'MPC approssima la predizione per una u qualsiasi:
%   tensione(j, n) ~= Y(j, n) + dY(j, n) * (u(n) - u_prec(n))
%
% Differenza rispetto a qp_predizione.m: li' dY e dS sono calcolate con le
% formule delle derivate; qui si ripete la predizione con un po' di corrente
% in piu' e si guarda di quanto cambia il risultato. Y e S sono identiche,
% dY e dS coincidono a meno di circa una parte su un milione.
%
%   sl        parametri del modello (da init_simulink)
%   s, Vp     SOC e tensione di polarizzazione di ogni cella, adesso
%   i_pacco   corrente di pacco, positiva in scarica
%   u_prec    correnti di bilanciamento del passo precedente, una per cella
%   Y, S, dY, dS   p x N: riga j <-> tra j passi di controllo, colonna n <-> cella n

%% Dati
N  = sl.N;                          % numero di celle
p  = sl.p;                          % numero di passi dell'orizzonte
Ts = sl.Ts_controllo;               % [s] durata di un passo

% Tabelle della cella nominale: ogni parametro in 7 punti di SOC
tabella_SOC     = sl.pacco.tabella_SOC;
tabella_V_vuoto = sl.pacco.tabella_V_vuoto;         % [V]
tabella_R_serie = sl.pacco.tabella_R_serie;         % [Ohm]
tabella_R_pol   = sl.pacco.tabella_R_pol;           % [Ohm]
tabella_C_pol   = sl.pacco.tabella_C_pol;           % [F]

piccolo_aumento = 1e-4;             % [A] corrente in piu' usata per la domanda 2

%% Predizione
Y     = zeros(p, N);   S     = zeros(p, N);         % con la corrente attuale
Y_piu = zeros(p, N);   S_piu = zeros(p, N);         % con un po' di corrente in piu'

for n = 1:N                                         % una cella alla volta

    % Ogni cella vera differisce dalla nominale per un fattore su ogni parametro
    fattore_V_vuoto = sl.pacco.f_V_vuoto(n);
    fattore_R_serie = sl.pacco.f_R_serie(n);
    fattore_R_pol   = sl.pacco.f_R_pol(n);
    fattore_C_pol   = sl.pacco.f_C_pol(n);

    % SOC perso in un passo per ogni ampere: rendimento*Ts/(3600*capacita_Ah)
    kappa = sl.pacco.kappa(n);

    for prova = 1:2                                 % 1: corrente attuale, 2: un po' di piu'

        % eq. (3): corrente della cella = corrente di pacco + bilanciamento
        if prova == 1
            corrente = i_pacco + u_prec(n);
        else
            corrente = i_pacco + u_prec(n) + piccolo_aumento;
        end

        % Stato di partenza: quello misurato adesso
        SOC   = s(n);
        V_pol = Vp(n);

        for j = 1:p                                 % un passo alla volta

            % Parametri del ramo RC al SOC di inizio passo.
            % Le tabelle vanno da SOC = 0 a SOC = 1: fuori si usa il valore dell'estremo.
            SOC_in_tabella = min(max(SOC, tabella_SOC(1)), tabella_SOC(end));
            R_pol = fattore_R_pol * interp1(tabella_SOC, tabella_R_pol, SOC_in_tabella);
            C_pol = fattore_C_pol * interp1(tabella_SOC, tabella_C_pol, SOC_in_tabella);

            % (2b) tensione di polarizzazione dopo un passo
            V_pol = V_pol + Ts * (-V_pol / (R_pol * C_pol) + corrente / C_pol);

            % (2a) SOC dopo un passo; una cella piena non si carica oltre
            SOC = SOC - kappa * corrente;
            if SOC > 1
                SOC = 1;
            end

            % (2c) tensione ai morsetti con il nuovo stato
            SOC_in_tabella = min(max(SOC, tabella_SOC(1)), tabella_SOC(end));
            V_vuoto = fattore_V_vuoto * interp1(tabella_SOC, tabella_V_vuoto, SOC_in_tabella);
            R_serie = fattore_R_serie * interp1(tabella_SOC, tabella_R_serie, SOC_in_tabella);
            V_cella = V_vuoto - V_pol - R_serie * corrente;

            if prova == 1
                Y(j, n) = V_cella;
                S(j, n) = SOC;
            else
                Y_piu(j, n) = V_cella;
                S_piu(j, n) = SOC;
            end

        end
    end
end

%% Di quanto si sposta la predizione per ogni ampere in piu'
dY = (Y_piu - Y) / piccolo_aumento;                 % [V/A]
dS = (S_piu - S) / piccolo_aumento;                 % [1/A]

end
