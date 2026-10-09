%% codice_unico.m
% Tutto in un solo file. Per ora contiene:
%   1) parametri della batteria
%   2) modello della batteria (funzioni in fondo al file)
%
% Riferimento: J. Chen, A. Behal, C. Li, "Active Cell Balancing by Model
% Predictive Control for Real Time Range Extension", IEEE CDC 2021.
%
% -------------------------------------------------------------------------
% CIRCUITO EQUIVALENTE DI UNA CELLA (un ramo RC)
%
%        R_serie          R_pol
%   +---/\/\/\---+-------/\/\/\-------+
%   |            |                    |
%   |            +--------||----------+        V_cella = V_vuoto - V_pol - R_serie*I_cella
%  V_cella              C_pol         |
%   |          <------ V_pol ------>  (+)
%   |                               V_vuoto
%   +---------------------------------+
%
% GLOSSARIO (nome nel codice = simbolo del paper)
%   SOC          = s     stato di carica della cella, da 0 (scarica) a 1 (carica)   [-]
%   V_vuoto      = V_oc  tensione a vuoto (a circuito aperto), dipende dal SOC      [V]
%   R_serie      = R_o   resistenza serie: caduta di tensione immediata             [Ohm]
%   R_pol        = R_p   resistenza del ramo RC di polarizzazione                   [Ohm]
%   C_pol        = C_p   capacita' del ramo RC di polarizzazione                    [F]
%   V_pol        = V_p   tensione sul ramo RC: caduta lenta, sale e scende in       [V]
%                        decine di secondi dopo una variazione di corrente
%   V_cella      = y     tensione ai morsetti della cella                           [V]
%   I_cella      = i     corrente della cella, POSITIVA IN SCARICA                  [A]
%   capacita_Ah  = C     carica che la cella puo' erogare                           [Ah]
%   passo        = T_s   passo di tempo del modello                                 [s]
%
% Ogni grandezza "di cella" e' un vettore colonna con un valore per cella:
% SOC(3) e' lo stato di carica della cella 3.
% -------------------------------------------------------------------------

clear; clc

%% 1) Parametri della batteria

% --- Cella nominale, unica temperatura di funzionamento: 20 °C -------------
% Cella Li-ion di Huria, Ceraolo, Gazzarri, Jackey (IEVC 2012): sono i valori
% a 20 °C delle tabelle di SIMULATION/init.m. Ogni tabella da' il parametro
% nei 7 punti di SOC elencati in tabella_SOC; tra un punto e l'altro si
% interpola linearmente.
cella.tabella_SOC     = [0      0.1    0.25   0.5    0.75   0.9    1     ]';  % [-]
cella.tabella_V_vuoto = [3.5057 3.5660 3.6337 3.7127 3.9259 4.0777 4.1928]';  % [V]   (Em_LUT in init.m)
cella.tabella_R_serie = [0.0085 0.0085 0.0087 0.0082 0.0083 0.0085 0.0085]';  % [Ohm] (R0_LUT in init.m)
cella.tabella_R_pol   = [0.0029 0.0024 0.0026 0.0016 0.0023 0.0018 0.0017]';  % [Ohm] (R1_LUT in init.m)
cella.tabella_C_pol   = [12447  18872  40764  18721  33630  18360  23394 ]';  % [F]   (C1_LUT in init.m)
cella.capacita_Ah     = 27.6250;   % [Ah] carica erogabile dalla cella
cella.rendimento      = 1;         % [-]  rendimento coulombico (1 = nessuna perdita di carica)

% --- Pacco: celle in serie, tutte un po' diverse tra loro -------------------
numero_celle = 5;        % celle collegate in serie
SOC_iniziale = 1;        % [-] tutte le celle partono cariche

% Le celle reali non sono identiche. Ogni parametro di ogni cella vale
%   (valore nominale) x (fattore casuale tra 1 - deviazione e 1 + deviazione)
% Esempio: deviazione.R_serie = 0.10 -> la R_serie di una cella sta tra il
% 90 % e il 110 % di quella nominale.
deviazione.V_vuoto  = 0.01;   % [-] 1 %
deviazione.R_serie  = 0.10;   % [-] 10 %
deviazione.R_pol    = 0.10;   % [-] 10 %
deviazione.C_pol    = 0.10;   % [-] 10 %
deviazione.capacita = 0;      % [-] 0: tutte le celle hanno la stessa capacita'
seme_casuale        = 1;      % stesso seme = stesse celle a ogni esecuzione

passo = 1;                    % [s] passo di tempo del modello

pacco = genera_pacco(cella, numero_celle, deviazione, seme_casuale);

% Stato iniziale del pacco (un valore per cella)
SOC   = SOC_iniziale * ones(numero_celle, 1);   % [-] stato di carica
V_pol = zeros(numero_celle, 1);                 % [V] celle a riposo: ramo RC scarico

%% 2) Modello della batteria
% Le funzioni sono in fondo al file. Uso tipico, data la corrente I_cella
% (un valore per cella, positiva in scarica):
%
%   [V_cella, SOC, V_pol] = modello_cella(pacco, SOC, V_pol, I_cella, passo);
%
% V_cella e' la tensione di adesso; SOC e V_pol in uscita sono lo stato dopo
% un passo e sostituiscono quelli in ingresso.

%% 3) Grafici: come cambiano i parametri al variare del SOC
% Per ogni parametro: la curva di ciascuna cella del pacco e, tratteggiata,
% quella della cella nominale con i 7 punti della tabella.

griglia_SOC = linspace(0, 1, 201)';
punti       = numel(griglia_SOC);

V_vuoto_celle = zeros(punti, numero_celle);   % riga = valore di SOC, colonna = cella
R_serie_celle = zeros(punti, numero_celle);
R_pol_celle   = zeros(punti, numero_celle);
C_pol_celle   = zeros(punti, numero_celle);
for k = 1:punti
    SOC_di_prova = griglia_SOC(k) * ones(numero_celle, 1);
    [V_vuoto_k, R_serie_k, R_pol_k, C_pol_k] = parametri_cella(pacco, SOC_di_prova);
    V_vuoto_celle(k, :) = V_vuoto_k';
    R_serie_celle(k, :) = R_serie_k';
    R_pol_celle(k, :)   = R_pol_k';
    C_pol_celle(k, :)   = C_pol_k';
end

figure('Color', 'w', 'Position', [80 60 1100 950]);
riquadri = tiledlayout(3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(riquadri, 'Parametri delle celle in funzione del SOC (20 °C)', 'FontWeight', 'bold');

disegna_parametro(griglia_SOC, V_vuoto_celle, cella.tabella_SOC, cella.tabella_V_vuoto, ...
    1, 'Tensione a vuoto V_{vuoto} [V]', true, '--o');
disegna_parametro(griglia_SOC, 1e3*R_serie_celle, cella.tabella_SOC, 1e3*cella.tabella_R_serie, ...
    1, 'Resistenza serie R_{serie} [m\Omega]', false, '--o');
disegna_parametro(griglia_SOC, 1e3*R_pol_celle, cella.tabella_SOC, 1e3*cella.tabella_R_pol, ...
    1, 'Resistenza di polarizzazione R_{pol} [m\Omega]', false, '--o');
disegna_parametro(griglia_SOC, 1e-3*C_pol_celle, cella.tabella_SOC, 1e-3*cella.tabella_C_pol, ...
    1, 'Capacita'' di polarizzazione C_{pol} [kF]', false, '--o');
% Costante di tempo del ramo RC: quanto impiega V_pol ad assestarsi. E' un
% prodotto di due tabelle, quindi tra un punto e l'altro non e' una retta:
% della cella nominale si disegnano solo i punti.
disegna_parametro(griglia_SOC, R_pol_celle.*C_pol_celle, cella.tabella_SOC, ...
    cella.tabella_R_pol.*cella.tabella_C_pol, 2, 'Costante di tempo R_{pol}\cdotC_{pol} [s]', false, 'o');


%% 4) Esempio di utilizzo di modello_cella
% Si scarica il pacco a 30 A per 10 minuti e poi lo si lascia a riposo per
% 5 minuti. A ogni passo:
% modello_cella restituisce:
%   - la tensione delle celle in quell'istante
%   - SOC e V_pol al passo successivo
% SOC e V_pol restituiti da modello_cella vanno rimessi in ingresso alla
% chiamata successiva: e' cosi' che lo stato avanza nel tempo.

durata_scarica = 600;                           % [s]
durata_riposo  = 300;                           % [s]
numero_passi   = (durata_scarica + durata_riposo) / passo;
tempo          = (0:numero_passi - 1)' * passo; % [s]

% Stato di partenza: celle cariche e a riposo
SOC   = SOC_iniziale * ones(numero_celle, 1);
V_pol = zeros(numero_celle, 1);

% Storie temporali da disegnare: riga = istante, colonna = cella
storia_SOC     = zeros(numero_passi, numero_celle);
storia_V_pol   = zeros(numero_passi, numero_celle);
storia_V_cella = zeros(numero_passi, numero_celle);
storia_I       = zeros(numero_passi, 1);

for k = 1:numero_passi
    % Corrente di questo passo: le celle sono in serie, quindi e' la stessa
    % per tutte. Positiva = scarica.
    if tempo(k) < durata_scarica
        I_pacco = 30;                           % [A]
    else
        I_pacco = 0;                            % [A] riposo
    end
    I_cella = I_pacco * ones(numero_celle, 1);

    % Tensione di adesso e stato al passo successivo
    [V_cella, SOC_dopo, V_pol_dopo] = modello_cella(pacco, SOC, V_pol, I_cella, passo);

    % Si registra lo stato attuale
    storia_SOC(k, :)     = SOC';
    storia_V_pol(k, :)   = V_pol';
    storia_V_cella(k, :) = V_cella';
    storia_I(k)          = I_pacco;

    % Si avanza di un passo: lo stato nuovo sostituisce quello vecchio
    SOC   = SOC_dopo;
    V_pol = V_pol_dopo;
end

fprintf('Dopo %d s a 30 A il SOC e'' sceso da %.3f a %.3f (atteso %.3f).\n', durata_scarica, ...
    SOC_iniziale, storia_SOC(end, 1), SOC_iniziale - 30*durata_scarica/(3600*cella.capacita_Ah));

figure('Color', 'w', 'Position', [120 60 900 900]);
riquadri = tiledlayout(4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(riquadri, 'Esempio: scarica a 30 A per 600 s, poi riposo', 'FontWeight', 'bold');

disegna_storia(tempo, storia_I,       'Corrente I_{cella} [A]', false);
disegna_storia(tempo, storia_SOC,     'SOC [-]', false);
disegna_storia(tempo, 1e3*storia_V_pol, 'V_{pol} [mV]', false);
disegna_storia(tempo, storia_V_cella, 'V_{cella} [V]', true);
xlabel('Tempo [s]');


%% ===================== Funzioni =====================

function pacco = genera_pacco(cella, numero_celle, deviazione, seme_casuale)
% Crea il pacco: le tabelle della cella nominale piu', per ogni cella, un
% fattore di scala casuale per ciascun parametro.
% pacco.fattore.R_serie(3) = 0.97 significa: la cella 3 ha una resistenza
% serie pari al 97 % di quella nominale, a qualunque SOC.

rng(seme_casuale, 'twister');
casuale = @() 2*rand(numero_celle, 1) - 1;      % numeri uniformi tra -1 e 1, uno per cella

pacco.fattore.V_vuoto  = 1 + deviazione.V_vuoto  * casuale();
pacco.fattore.R_serie  = 1 + deviazione.R_serie  * casuale();
pacco.fattore.R_pol    = 1 + deviazione.R_pol    * casuale();
pacco.fattore.C_pol    = 1 + deviazione.C_pol    * casuale();
fattore_capacita       = 1 + deviazione.capacita * casuale();

pacco.numero_celle    = numero_celle;
pacco.tabella_SOC     = cella.tabella_SOC;
pacco.tabella_V_vuoto = cella.tabella_V_vuoto;
pacco.tabella_R_serie = cella.tabella_R_serie;
pacco.tabella_R_pol   = cella.tabella_R_pol;
pacco.tabella_C_pol   = cella.tabella_C_pol;
pacco.capacita_Ah     = cella.capacita_Ah * fattore_capacita;   % [Ah], un valore per cella
pacco.rendimento      = cella.rendimento;
end

function [V_vuoto, R_serie, R_pol, C_pol] = parametri_cella(pacco, SOC)
% Parametri di ogni cella al suo SOC attuale: si legge la tabella nominale
% (interpolazione lineare) e si moltiplica per il fattore della cella.
% Fuori tabella (SOC < 0 o > 1) si usa il valore dell'estremo.

SOC = min(max(SOC, pacco.tabella_SOC(1)), pacco.tabella_SOC(end));

V_vuoto = pacco.fattore.V_vuoto .* interp1(pacco.tabella_SOC, pacco.tabella_V_vuoto, SOC);
R_serie = pacco.fattore.R_serie .* interp1(pacco.tabella_SOC, pacco.tabella_R_serie, SOC);
R_pol   = pacco.fattore.R_pol   .* interp1(pacco.tabella_SOC, pacco.tabella_R_pol,   SOC);
C_pol   = pacco.fattore.C_pol   .* interp1(pacco.tabella_SOC, pacco.tabella_C_pol,   SOC);
end

function [V_cella, SOC_dopo, V_pol_dopo] = modello_cella(pacco, SOC, V_pol, I_cella, passo)
% Modello completo di ogni cella, eq. (2a)-(2c) del paper. Dati lo stato
% attuale (SOC, V_pol) e la corrente I_cella, restituisce:
%   V_cella     tensione ai morsetti ADESSO, con questo stato e questa corrente
%   SOC_dopo    stato di carica dopo un passo di tempo
%   V_pol_dopo  tensione del ramo RC dopo un passo di tempo
% Se serve solo la tensione si puo' chiamare con una sola uscita.

[V_vuoto, R_serie, R_pol, C_pol] = parametri_cella(pacco, SOC);

% (2c) Uscita: tensione a vuoto meno la caduta sul ramo RC e meno la caduta
% sulla resistenza serie.
V_cella = V_vuoto - V_pol - R_serie .* I_cella;

% (2a) Conteggio della carica: in un passo la cella eroga I_cella*passo
% coulomb, su una capacita' di 3600*capacita_Ah coulomb.
carica_erogata = pacco.rendimento .* I_cella .* passo ./ (3600 * pacco.capacita_Ah);
SOC_dopo       = SOC - carica_erogata;
SOC_dopo       = min(SOC_dopo, 1);          % una cella piena non si carica oltre

% (2b) Ramo RC, discretizzato con Eulero in avanti: V_pol tende a
% R_pol*I_cella con costante di tempo R_pol*C_pol.
costante_di_tempo = R_pol .* C_pol;                                   % [s]
V_pol_dopo = V_pol + passo .* (-V_pol ./ costante_di_tempo + I_cella ./ C_pol);
end

function disegna_parametro(griglia_SOC, valori_celle, tabella_SOC, tabella_nominale, larghezza, etichetta, con_legenda, stile_nominale)
% Un riquadro: una curva per cella (colonne di valori_celle) e la cella
% nominale con i punti della tabella. larghezza = numero di colonne occupate
% dal riquadro; stile_nominale = '--o' (punti uniti) oppure 'o' (solo punti).

colori = [ 42 120 214;  235 104  52;   27 175 122;  237 161   0; ...
          232 123 164;    0 131   0;   74  58 167;  227  73  72] / 255;
grigio = [82 81 78] / 255;

assi = nexttile([1 larghezza]);
hold(assi, 'on');  grid(assi, 'on');  box(assi, 'off');
numero_celle = size(valori_celle, 2);
nomi = cell(1, numero_celle + 1);
for n = 1:numero_celle
    plot(assi, griglia_SOC, valori_celle(:, n), 'Color', colori(n, :), 'LineWidth', 1.3);
    nomi{n} = sprintf('Cella %d', n);
end
plot(assi, tabella_SOC, tabella_nominale, stile_nominale, 'Color', grigio, 'LineWidth', 1.1, ...
    'MarkerSize', 5, 'MarkerFaceColor', 'w');
nomi{end} = 'Nominale (punti della tabella)';

xlim(assi, [0 1]);
xlabel(assi, 'SOC [-]');
ylabel(assi, etichetta);
if con_legenda
    legend(assi, nomi, 'Location', 'northwest', 'Box', 'off');
end
end

function disegna_storia(tempo, valori, etichetta, con_legenda)
% Un riquadro con l'andamento nel tempo: una curva per colonna di valori
% (una per cella), oppure una sola curva grigia se valori ha una colonna.

colori = [ 42 120 214;  235 104  52;   27 175 122;  237 161   0; ...
          232 123 164;    0 131   0;   74  58 167;  227  73  72] / 255;
grigio = [82 81 78] / 255;

assi = nexttile;
hold(assi, 'on');  grid(assi, 'on');  box(assi, 'off');
numero_curve = size(valori, 2);
nomi = cell(1, numero_curve);
for n = 1:numero_curve
    if numero_curve == 1
        colore = grigio;
    else
        colore = colori(n, :);
    end
    plot(assi, tempo, valori(:, n), 'Color', colore, 'LineWidth', 1.3);
    nomi{n} = sprintf('Cella %d', n);
end
ylabel(assi, etichetta);
if con_legenda
    legend(assi, nomi, 'Location', 'northeast', 'Box', 'off', 'NumColumns', numero_curve);
end
end
