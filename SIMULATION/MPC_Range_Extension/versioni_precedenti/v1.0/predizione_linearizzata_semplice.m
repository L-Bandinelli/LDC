function [Y_bar, S_bar, d, alfa] = predizione_linearizzata_semplice(par_sim, s_k, Vp_k, i_pacco_k, u_bar)
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
%   s, Vp                            stato della cella: s_{k+j}, V_{p,k+j}
%   I_cella                          corrente della cella, costante sull'orizzonte
%   alfa_j, beta_j, d_j              coefficienti di sensibilita' di s, Vp e y al passo j:
%                                    derivate rispetto a I_cella
%   Voc, Ro, Rp, Cp, tau             parametri della cella, letti al SOC indicato
%   ds_Voc, ds_Ro, ds_Rp, ds_Cp, ds_tau   loro derivate rispetto a s (l'apice del documento)
%   y                                tensione ai morsetti y_{k+j}
%   Tc, kappa                        passo di controllo e SOC perso in un passo per ampere
%
% Per ogni cella n e per ogni passo j dell'orizzonte calcola:
%   Y_bar(j,n), S_bar(j,n)   tensione e SOC predetti con la corrente i_pacco_k + u_bar(n)
%   d(j,n), alfa(j,n)        coefficienti di sensibilita' di tensione e SOC
% Con questi l'MPC linearizza la predizione attorno a u_bar (Remark 3), doc. (6):
%   y(j,n) ~= Y_bar(j,n) + d(j,n) * (u(n) - u_bar(n))
%
%   par_sim     parametri della simulazione (da parametri_simulazione)
%   s_k, Vp_k   SOC e tensione di polarizzazione misurati adesso, uno per cella
%   i_pacco_k   corrente di pacco misurata, positiva in scarica
%   u_bar       correnti di bilanciamento del passo precedente, una per cella
%   Y_bar, S_bar, d, alfa   p x N: riga j <-> istante k+j, colonna n <-> cella n

%% 2. Modello di predizione
N  = par_sim.N;                     % numero di celle
p  = par_sim.p;                     % numero di passi dell'orizzonte
Tc = par_sim.Tc;                    % [s] passo di controllo

% Tabelle della cella nominale: ogni parametro in 7 punti di SOC
s_tab   = par_sim.pacco.s_tab;
Voc_tab = par_sim.pacco.Voc_tab;             % [V]    tensione a vuoto
Ro_tab  = par_sim.pacco.Ro_tab;              % [Ohm]  resistenza serie
Rp_tab  = par_sim.pacco.Rp_tab;              % [Ohm]  resistenza di polarizzazione
Cp_tab  = par_sim.pacco.Cp_tab;              % [F]    capacita' di polarizzazione

% Risultati: le quattro matrici della sezione 4
Y_bar = zeros(p, N);   S_bar = zeros(p, N);
d     = zeros(p, N);   alfa  = zeros(p, N);

for n = 1:N                                         % una cella alla volta

    % Fattori di deviazione della cella n: ogni parametro e' la tabella
    % nominale per il suo fattore, per esempio Ro(s) = phi_Ro * Ro_tab(s)
    phi_Voc = par_sim.pacco.phi.Voc(n);
    phi_Ro  = par_sim.pacco.phi.Ro(n);
    phi_Rp  = par_sim.pacco.phi.Rp(n);
    phi_Cp  = par_sim.pacco.phi.Cp(n);

    % doc. (5): kappa = eta*Tc/(3600*C), SOC perso in un passo per ogni ampere
    kappa = par_sim.pacco.kappa(n);

    %% 3. Punto di linearizzazione
    % Stato misurato adesso, corrente di pacco misurata e mossa del passo
    % precedente. Da qui parte la traiettoria di linearizzazione, che finisce
    % in Y_bar e S_bar: la cella la percorre con i propri parametri, non con i
    % nominali.
    s       = s_k(n);
    Vp      = Vp_k(n);
    I_cella = i_pacco_k + u_bar(n);  % doc. (1): corrente di pacco + bilanciamento

    %% 5.3 Calcolo delle derivate, a tempo discreto
    % Le derivate si propagano insieme allo stato: a ogni passo, accanto a
    % ogni equazione del modello c'e' la sua derivata rispetto a I_cella. La
    % corrente entra in due modi, direttamente e attraverso il SOC, da cui
    % dipendono i parametri letti dalle tabelle.
    % Partono da zero: lo stato misurato non dipende dalla corrente futura.
    alfa_j = 0;                     % alfa_0
    beta_j = 0;                     % beta_0

    for j = 1:p                                     % un passo alla volta

        % --- Tensione di polarizzazione: doc. (3) e la sua derivata doc. (7)
        % Parametri del ramo RC e loro derivate nel SOC di inizio passo, s_{k+j-1}
        [Rp, ds_Rp] = leggi_tabella(s_tab, Rp_tab, phi_Rp, s);
        [Cp, ds_Cp] = leggi_tabella(s_tab, Cp_tab, phi_Cp, s);

        tau    = Rp * Cp;
        ds_tau = ds_Rp * Cp + Rp * ds_Cp;

        % Ordine dei calcoli: beta_j usa Vp e alfa_j di inizio passo, quindi
        % va aggiornata prima di Vp e di alfa_j
        beta_j = beta_j + Tc * ( -beta_j / tau ...                      % Vp dipende da I_cella
                                 + Vp * ds_tau * alfa_j / tau^2 ...     % tau tramite il SOC
                                 + 1 / Cp ...                           % I_cella diretta
                                 - I_cella * ds_Cp * alfa_j / Cp^2 );   % Cp tramite il SOC
        Vp     = Vp + Tc * (-Vp / tau + I_cella / Cp);

        % --- Stato di carica: doc. (2) e la sua derivata doc. (8)
        s      = s - kappa * I_cella;
        alfa_j = alfa_j - kappa;
        if s >= 1                                   % una cella piena non si carica oltre
            s      = 1;
            alfa_j = 0;
        end

        % --- Tensione ai morsetti: doc. (4) e la sua derivata doc. (9)
        % Parametri dell'uscita e loro derivate nel SOC di fine passo, s_{k+j}
        [Voc, ds_Voc] = leggi_tabella(s_tab, Voc_tab, phi_Voc, s);
        [Ro,  ds_Ro]  = leggi_tabella(s_tab, Ro_tab,  phi_Ro,  s);

        y   = Voc - Vp - Ro * I_cella;
        d_j = ds_Voc * alfa_j ...                   % Voc tramite il SOC
              - beta_j ...
              - ds_Ro * alfa_j * I_cella ...        % Ro tramite il SOC
              - Ro;                                 % I_cella diretta

        % --- 4. Sviluppo al primo ordine: doc. (6)
        % Riga j e colonna n delle quattro matrici: traiettoria di
        % linearizzazione (Y_bar, S_bar) e coefficienti di sensibilita' (d, alfa)
        Y_bar(j, n) = y;       S_bar(j, n) = s;
        d(j, n)     = d_j;     alfa(j, n)  = alfa_j;

    end
end

end

function [valore, ds_valore] = leggi_tabella(s_tab, P_tab, phi, s)
% Parametro di una cella al SOC s e sua derivata rispetto a s, doc. (T) della
% sezione 2.2: tabella nominale P_tab interpolata linearmente, per il fattore
% di deviazione phi della cella. Un punto della tabella e' assegnato al tratto
% alla sua destra; fuori tabella si usa il valore dell'estremo, con derivata
% nulla.

s_minimo  = s_tab(1);
s_massimo = s_tab(end);

s_limitato = min(max(s, s_minimo), s_massimo);
tratto   = sum(s_tab(1:end-1) <= s_limitato);       % s_limitato cade tra il punto "tratto" e il successivo
ampiezza = s_tab(tratto+1) - s_tab(tratto);
salto    = P_tab(tratto+1) - P_tab(tratto);

valore = phi * (P_tab(tratto) + salto * (s_limitato - s_tab(tratto)) / ampiezza);
if s >= s_minimo && s <= s_massimo
    ds_valore = phi * salto / ampiezza;             % pendenza del tratto
else
    ds_valore = 0;
end

end
