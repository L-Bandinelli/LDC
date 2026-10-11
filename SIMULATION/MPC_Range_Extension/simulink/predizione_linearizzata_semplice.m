function [Y, S, dY, dS] = predizione_linearizzata_semplice(sl, s_k, Vp_k, i_k, u_bar)
%PREDIZIONE_LINEARIZZATA_SEMPLICE  Predizione delle celle su p passi, eq. (6b)-(6c).
%
% Versione da leggere del blocco Predizione_linearizzata (qp_predizione.m):
% stesso calcolo e stesse formule, ma scritto per una cella alla volta con
% numeri singoli e senza passare da altri file del progetto. Il modello
% Simulink non la usa.
%
% Il codice e' diviso nelle stesse parti di DOCUMENTS/Linearizzazione_MPC.pdf
% e ne usa la notazione: i titoli riportano numero e nome della sezione,
% "doc. (7)" indica l'equazione (7) di quel documento e le variabili hanno il
% nome dei simboli:
%   s, Vp                       stato della cella: s_{k+j}, V_{p,k+j}
%   I                           corrente della cella, costante sull'orizzonte
%   alfa, beta                  derivate di s e Vp rispetto a I: alfa_j, beta_j
%   Voc, Ro, Rp, Cp, tau        parametri della cella, letti al SOC indicato
%   dVoc, dRo, dRp, dCp, dtau   loro derivate rispetto a s (l'apice del documento)
%   y, D, E                     tensione ai morsetti y_{k+j} e derivate D_j, E_j
%   Tc, kappa                   passo di controllo e SOC perso in un passo per ampere
%
% Per ogni cella n e per ogni passo j dell'orizzonte calcola:
%   Y(j,n),  S(j,n)    tensione e SOC predetti con la corrente i_k + u_bar(n)
%   dY(j,n), dS(j,n)   loro derivate rispetto alla corrente della cella: D ed E
% Con queste l'MPC linearizza la predizione attorno a u_bar (Remark 3), doc. (6):
%   y(j,n) ~= Y(j,n) + dY(j,n) * (u(n) - u_bar(n))
%
%   sl          parametri del modello (da init_simulink)
%   s_k, Vp_k   SOC e tensione di polarizzazione misurati adesso, uno per cella
%   i_k         corrente di pacco misurata, positiva in scarica
%   u_bar       correnti di bilanciamento del passo precedente, una per cella
%   Y, S, dY, dS   p x N: riga j <-> istante k+j, colonna n <-> cella n

%% 2. Modello di predizione
N  = sl.N;                          % numero di celle
p  = sl.p;                          % numero di passi dell'orizzonte
Tc = sl.Ts_controllo;               % [s] passo di controllo

% Tabelle della cella nominale: ogni parametro in 7 punti di SOC
tabella_s   = sl.pacco.tabella_SOC;
tabella_Voc = sl.pacco.tabella_V_vuoto;         % [V]    tensione a vuoto
tabella_Ro  = sl.pacco.tabella_R_serie;         % [Ohm]  resistenza serie
tabella_Rp  = sl.pacco.tabella_R_pol;           % [Ohm]  resistenza del ramo RC
tabella_Cp  = sl.pacco.tabella_C_pol;           % [F]    condensatore del ramo RC

% Risultati: le quattro matrici della sezione 4
Y  = zeros(p, N);   S  = zeros(p, N);
dY = zeros(p, N);   dS = zeros(p, N);

for n = 1:N                                         % una cella alla volta

    % Fattori di deviazione della cella n: ogni parametro e' la tabella
    % nominale per il suo fattore, per esempio Ro(s) = f_Ro * tabella_Ro(s)
    f_Voc = sl.pacco.f_V_vuoto(n);
    f_Ro  = sl.pacco.f_R_serie(n);
    f_Rp  = sl.pacco.f_R_pol(n);
    f_Cp  = sl.pacco.f_C_pol(n);

    % doc. (5): kappa = eta*Tc/(3600*C), SOC perso in un passo per ogni ampere
    kappa = sl.pacco.kappa(n);

    %% 3. Punto di linearizzazione
    % Stato misurato adesso, corrente di pacco misurata e mossa del passo
    % precedente. Da qui parte la traiettoria di linearizzazione, che finisce
    % in Y e S: la cella la percorre con i propri parametri, non con i nominali.
    s  = s_k(n);
    Vp = Vp_k(n);
    I  = i_k + u_bar(n);            % doc. (1): corrente di pacco + bilanciamento

    %% 5.3 Calcolo delle derivate, a tempo discreto
    % Le derivate si propagano insieme allo stato: a ogni passo, accanto a
    % ogni equazione del modello c'e' la sua derivata rispetto a I. La
    % corrente entra in due modi, direttamente e attraverso il SOC, da cui
    % dipendono i parametri letti dalle tabelle.
    % Partono da zero: lo stato misurato non dipende dalla corrente futura.
    alfa = 0;                       % alfa_0
    beta = 0;                       % beta_0

    for j = 1:p                                     % un passo alla volta

        % --- Tensione di polarizzazione: doc. (3) e la sua derivata doc. (7)
        % Parametri del ramo RC e loro derivate nel SOC di inizio passo, s_{k+j-1}
        [Rp, dRp] = leggi_tabella(tabella_s, tabella_Rp, f_Rp, s);
        [Cp, dCp] = leggi_tabella(tabella_s, tabella_Cp, f_Cp, s);

        tau  = Rp * Cp;
        dtau = dRp * Cp + Rp * dCp;

        % Ordine dei calcoli: beta usa Vp e alfa di inizio passo, quindi va
        % aggiornata prima di Vp e di alfa
        beta = beta + Tc * ( -beta / tau ...                    % Vp dipende da I
                             + Vp * dtau * alfa / tau^2 ...     % tau tramite il SOC
                             + 1 / Cp ...                       % I diretta
                             - I * dCp * alfa / Cp^2 );         % Cp tramite il SOC
        Vp   = Vp + Tc * (-Vp / tau + I / Cp);

        % --- Stato di carica: doc. (2) e la sua derivata doc. (8)
        s    = s - kappa * I;
        alfa = alfa - kappa;
        if s >= 1                                   % una cella piena non si carica oltre
            s    = 1;
            alfa = 0;
        end

        % --- Tensione ai morsetti: doc. (4) e la sua derivata doc. (9)
        % Parametri dell'uscita e loro derivate nel SOC di fine passo, s_{k+j}
        [Voc, dVoc] = leggi_tabella(tabella_s, tabella_Voc, f_Voc, s);
        [Ro,  dRo]  = leggi_tabella(tabella_s, tabella_Ro,  f_Ro,  s);

        y = Voc - Vp - Ro * I;
        D = dVoc * alfa ...                         % Voc tramite il SOC
            - beta ...
            - dRo * alfa * I ...                    % Ro tramite il SOC
            - Ro;                                   % I diretta
        E = alfa;

        % --- 4. Sviluppo al primo ordine: doc. (6)
        % Riga j e colonna n delle quattro matrici: traiettoria di
        % linearizzazione (Y, S) e coefficienti di sensibilita' (dY, dS)
        Y(j, n)  = y;       S(j, n)  = s;
        dY(j, n) = D;       dS(j, n) = E;

    end
end

end

function [valore, derivata] = leggi_tabella(tabella_s, tabella, f, s)
% Parametro di una cella al SOC s e sua derivata rispetto a s, doc. (T) della
% sezione 2.2: tabella nominale interpolata linearmente, per il fattore f
% della cella. Un punto della tabella e' assegnato al tratto alla sua destra;
% fuori tabella si usa il valore dell'estremo, con derivata nulla.

s_minimo  = tabella_s(1);
s_massimo = tabella_s(end);

x = min(max(s, s_minimo), s_massimo);
tratto   = sum(tabella_s(1:end-1) <= x);            % x cade tra il punto "tratto" e il successivo
ampiezza = tabella_s(tratto+1) - tabella_s(tratto);
salto    = tabella(tratto+1) - tabella(tratto);

valore = f * (tabella(tratto) + salto * (x - tabella_s(tratto)) / ampiezza);
if s >= s_minimo && s <= s_massimo
    derivata = f * salto / ampiezza;                % pendenza del tratto
else
    derivata = 0;
end

end
