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
%          Ro                Rp
%   +---/\/\/\---+-------/\/\/\-------+
%   |            |                    |
%   |            +--------||----------+        y = Voc - Vp - Ro*I_cella
%   y                     Cp          |
%   |          <-------- Vp ------->  (+)
%   |                                 Voc
%   +---------------------------------+
%
% GLOSSARIO (nome nel codice = simbolo, come in DOCUMENTS/Notazione.md)
%   s        = s     stato di carica (SOC) della cella, da 0 (scarica) a 1 (carica)  [-]
%   Voc      = V_oc  tensione a vuoto, dipende dal SOC                               [V]
%   Ro       = R_o   resistenza serie: caduta di tensione immediata                  [Ohm]
%   Rp       = R_p   resistenza di polarizzazione del ramo RC                        [Ohm]
%   Cp       = C_p   capacita' di polarizzazione del ramo RC                         [F]
%   Vp       = V_p   tensione di polarizzazione, sul ramo RC: caduta lenta, sale e   [V]
%                    scende in decine di secondi dopo una variazione di corrente
%   y        = y     tensione ai morsetti della cella                                [V]
%   I_cella  = I     corrente della cella, POSITIVA IN SCARICA                       [A]
%   i_pacco  = i     corrente di pacco, la stessa per tutte le celle in serie        [A]
%   C        = C     capacita' della cella: carica che puo' erogare                  [Ah]
%   eta      = eta   rendimento coulombico                                           [-]
%   Tint     = T_int passo di tempo del modello                                      [s]
%
% Ogni grandezza "di cella" e' un vettore colonna con un valore per cella:
% s(3) e' lo stato di carica della cella 3.
% -------------------------------------------------------------------------

clear; clc

%% 1) Parametri della batteria

% --- Cella nominale, unica temperatura di funzionamento: 20 °C -------------
% Cella Li-ion di Huria, Ceraolo, Gazzarri, Jackey (IEVC 2012): sono i valori
% a 20 °C delle tabelle di SIMULATION/init.m. Ogni tabella da' il parametro
% nei 7 punti di SOC elencati in s_tab; tra un punto e l'altro si
% interpola linearmente.
cella.s_tab   = [0      0.1    0.25   0.5    0.75   0.9    1     ]';  % [-]
cella.Voc_tab = [3.5057 3.5660 3.6337 3.7127 3.9259 4.0777 4.1928]';  % [V]   (Em_LUT in init.m)
cella.Ro_tab  = [0.0085 0.0085 0.0087 0.0082 0.0083 0.0085 0.0085]';  % [Ohm] (R0_LUT in init.m)
cella.Rp_tab  = [0.0029 0.0024 0.0026 0.0016 0.0023 0.0018 0.0017]';  % [Ohm] (R1_LUT in init.m)
cella.Cp_tab  = [12447  18872  40764  18721  33630  18360  23394 ]';  % [F]   (C1_LUT in init.m)
cella.C       = 27.6250;   % [Ah] capacita' della cella: carica erogabile
cella.eta     = 1;         % [-]  rendimento coulombico (1 = nessuna perdita di carica)

% --- Pacco: celle in serie, tutte un po' diverse tra loro -------------------
N          = 5;          % numero di celle collegate in serie
s_iniziale = 1;          % [-] tutte le celle partono cariche

% Le celle reali non sono identiche. Ogni parametro P di ogni cella vale
%   (valore nominale) x phi_P,   phi_P casuale tra 1 - delta_P e 1 + delta_P
% Esempio: delta.Ro = 0.10 -> la Ro di una cella sta tra il 90 % e il 110 %
% di quella nominale.
delta.Voc    = 0.01;     % [-] 1 %
delta.Ro     = 0.10;     % [-] 10 %
delta.Rp     = 0.10;     % [-] 10 %
delta.Cp     = 0.10;     % [-] 10 %
delta.C      = 0;        % [-] 0: tutte le celle hanno la stessa capacita'
seme_casuale = 1;        % stesso seme = stesse celle a ogni esecuzione

Tint = 1;                % [s] passo di tempo del modello

pacco = genera_pacco(cella, N, delta, seme_casuale);

% Stato iniziale del pacco (un valore per cella)
s  = s_iniziale * ones(N, 1);   % [-] stato di carica
Vp = zeros(N, 1);               % [V] celle a riposo: ramo RC scarico

%% 2) Modello della batteria
% Le funzioni sono in fondo al file. Uso tipico, data la corrente I_cella
% (un valore per cella, positiva in scarica):
%
%   [y, s, Vp] = modello_cella(pacco, s, Vp, I_cella, Tint);
%
% y e' la tensione di adesso; s e Vp in uscita sono lo stato dopo un passo e
% sostituiscono quelli in ingresso.

%% 3) Grafici: come cambiano i parametri al variare del SOC
% Per ogni parametro: la curva di ciascuna cella del pacco e, tratteggiata,
% quella della cella nominale con i 7 punti della tabella.

griglia_s = linspace(0, 1, 201)';
punti     = numel(griglia_s);

Voc_celle = zeros(punti, N);   % riga = valore di SOC, colonna = cella
Ro_celle  = zeros(punti, N);
Rp_celle  = zeros(punti, N);
Cp_celle  = zeros(punti, N);
for indice_griglia = 1:punti
    s_prova = griglia_s(indice_griglia) * ones(N, 1);
    [Voc_prova, Ro_prova, Rp_prova, Cp_prova] = parametri_cella(pacco, s_prova);
    Voc_celle(indice_griglia, :) = Voc_prova';
    Ro_celle(indice_griglia, :)  = Ro_prova';
    Rp_celle(indice_griglia, :)  = Rp_prova';
    Cp_celle(indice_griglia, :)  = Cp_prova';
end

figure('Color', 'w', 'Position', [80 60 1100 950]);
riquadri = tiledlayout(3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(riquadri, 'Parametri delle celle in funzione del SOC (20 °C)', 'FontWeight', 'bold');

disegna_parametro(griglia_s, Voc_celle, cella.s_tab, cella.Voc_tab, ...
    1, 'Tensione a vuoto V_{oc} [V]', true, '--o');
disegna_parametro(griglia_s, 1e3*Ro_celle, cella.s_tab, 1e3*cella.Ro_tab, ...
    1, 'Resistenza serie R_o [m\Omega]', false, '--o');
disegna_parametro(griglia_s, 1e3*Rp_celle, cella.s_tab, 1e3*cella.Rp_tab, ...
    1, 'Resistenza di polarizzazione R_p [m\Omega]', false, '--o');
disegna_parametro(griglia_s, 1e-3*Cp_celle, cella.s_tab, 1e-3*cella.Cp_tab, ...
    1, 'Capacita'' di polarizzazione C_p [kF]', false, '--o');
% Costante di tempo del ramo RC: quanto impiega Vp ad assestarsi. E' un
% prodotto di due tabelle, quindi tra un punto e l'altro non e' una retta:
% della cella nominale si disegnano solo i punti.
disegna_parametro(griglia_s, Rp_celle.*Cp_celle, cella.s_tab, ...
    cella.Rp_tab.*cella.Cp_tab, 2, 'Costante di tempo \tau = R_p C_p [s]', false, 'o');


%% 4) Esempio di utilizzo di modello_cella
% Si scarica il pacco a 30 A per 10 minuti e poi lo si lascia a riposo per
% 5 minuti. A ogni passo:
% modello_cella restituisce:
%   - la tensione delle celle in quell'istante
%   - s e Vp al passo successivo
% s e Vp restituiti da modello_cella vanno rimessi in ingresso alla
% chiamata successiva: e' cosi' che lo stato avanza nel tempo.

durata_scarica = 600;                           % [s]
durata_riposo  = 300;                           % [s]
numero_passi   = (durata_scarica + durata_riposo) / Tint;
tempo          = (0:numero_passi - 1)' * Tint;  % [s]

% Stato di partenza: celle cariche e a riposo
s  = s_iniziale * ones(N, 1);
Vp = zeros(N, 1);

% Storie temporali da disegnare: riga = istante, colonna = cella
storia_s       = zeros(numero_passi, N);
storia_Vp      = zeros(numero_passi, N);
storia_y       = zeros(numero_passi, N);
storia_i_pacco = zeros(numero_passi, 1);

for k = 1:numero_passi
    % Corrente di questo passo: le celle sono in serie, quindi e' la stessa
    % per tutte. Positiva = scarica.
    if tempo(k) < durata_scarica
        i_pacco = 30;                           % [A]
    else
        i_pacco = 0;                            % [A] riposo
    end
    I_cella = i_pacco * ones(N, 1);

    % Tensione di adesso e stato al passo successivo
    [y, s_next, Vp_next] = modello_cella(pacco, s, Vp, I_cella, Tint);

    % Si registra lo stato attuale
    storia_s(k, :)    = s';
    storia_Vp(k, :)   = Vp';
    storia_y(k, :)    = y';
    storia_i_pacco(k) = i_pacco;

    % Si avanza di un passo: lo stato nuovo sostituisce quello vecchio
    s  = s_next;
    Vp = Vp_next;
end

fprintf('Dopo %d s a 30 A il SOC e'' sceso da %.3f a %.3f (atteso %.3f).\n', durata_scarica, ...
    s_iniziale, storia_s(end, 1), s_iniziale - 30*durata_scarica/(3600*cella.C));

figure('Color', 'w', 'Position', [120 60 900 900]);
riquadri = tiledlayout(4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(riquadri, 'Esempio: scarica a 30 A per 600 s, poi riposo', 'FontWeight', 'bold');

disegna_storia(tempo, storia_i_pacco, 'Corrente di pacco i_{pacco} [A]', false);
disegna_storia(tempo, storia_s,       'SOC s [-]', false);
disegna_storia(tempo, 1e3*storia_Vp,  'Tensione di polarizzazione V_p [mV]', false);
disegna_storia(tempo, storia_y,       'Tensione ai morsetti y [V]', true);
xlabel('Tempo [s]');


%% ===================== Funzioni =====================

function pacco = genera_pacco(cella, N, delta, seme_casuale)
% Crea il pacco: le tabelle della cella nominale piu', per ogni cella, un
% fattore di deviazione phi casuale per ciascun parametro.
% pacco.phi.Ro(3) = 0.97 significa: la cella 3 ha una resistenza serie pari
% al 97 % di quella nominale, a qualunque SOC.

rng(seme_casuale, 'twister');
casuale = @() 2*rand(N, 1) - 1;      % numeri uniformi tra -1 e 1, uno per cella

pacco.phi.Voc = 1 + delta.Voc * casuale();
pacco.phi.Ro  = 1 + delta.Ro  * casuale();
pacco.phi.Rp  = 1 + delta.Rp  * casuale();
pacco.phi.Cp  = 1 + delta.Cp  * casuale();
phi_C         = 1 + delta.C   * casuale();

pacco.N       = N;
pacco.s_tab   = cella.s_tab;
pacco.Voc_tab = cella.Voc_tab;
pacco.Ro_tab  = cella.Ro_tab;
pacco.Rp_tab  = cella.Rp_tab;
pacco.Cp_tab  = cella.Cp_tab;
pacco.C       = cella.C * phi_C;     % [Ah], un valore per cella
pacco.eta     = cella.eta;
end

function [Voc, Ro, Rp, Cp] = parametri_cella(pacco, s)
% Parametri di ogni cella al suo SOC attuale: si legge la tabella nominale
% (interpolazione lineare) e si moltiplica per il fattore phi della cella.
% Fuori tabella (SOC < 0 o > 1) si usa il valore dell'estremo.

s = min(max(s, pacco.s_tab(1)), pacco.s_tab(end));

Voc = pacco.phi.Voc .* interp1(pacco.s_tab, pacco.Voc_tab, s);
Ro  = pacco.phi.Ro  .* interp1(pacco.s_tab, pacco.Ro_tab,  s);
Rp  = pacco.phi.Rp  .* interp1(pacco.s_tab, pacco.Rp_tab,  s);
Cp  = pacco.phi.Cp  .* interp1(pacco.s_tab, pacco.Cp_tab,  s);
end

function [y, s_next, Vp_next] = modello_cella(pacco, s, Vp, I_cella, Tint)
% Modello completo di ogni cella, eq. (2a)-(2c) del paper. Dati lo stato
% attuale (s, Vp) e la corrente I_cella, restituisce:
%   y        tensione ai morsetti ADESSO, con questo stato e questa corrente
%   s_next   SOC dopo un passo di tempo Tint
%   Vp_next  tensione di polarizzazione dopo un passo di tempo Tint
% Se serve solo la tensione si puo' chiamare con una sola uscita.

[Voc, Ro, Rp, Cp] = parametri_cella(pacco, s);

% (2c) Uscita: tensione a vuoto meno la caduta sul ramo RC e meno la caduta
% sulla resistenza serie.
y = Voc - Vp - Ro .* I_cella;

% (2a) Conteggio della carica: in un passo la cella eroga I_cella*Tint
% coulomb, su una capacita' di 3600*C coulomb (C in Ah).
consumed_soc = pacco.eta .* I_cella .* Tint ./ (3600 * pacco.C);
s_next       = s - consumed_soc;
s_next       = min(s_next, 1);          % una cella piena non si carica oltre

% (2b) Ramo RC, discretizzato con Eulero in avanti: Vp tende a
% Rp*I_cella con costante di tempo tau = Rp*Cp.
tau     = Rp .* Cp;                                                   % [s]
Vp_next = Vp + Tint .* (-Vp ./ tau + I_cella ./ Cp);
end

function disegna_parametro(griglia_s, valori_celle, s_tab, P_tab, larghezza, etichetta, con_legenda, stile_nominale)
% Un riquadro: una curva per cella (colonne di valori_celle) e la cella
% nominale con i punti della tabella. larghezza = numero di colonne occupate
% dal riquadro; stile_nominale = '--o' (punti uniti) oppure 'o' (solo punti).

colori = [ 42 120 214;  235 104  52;   27 175 122;  237 161   0; ...
          232 123 164;    0 131   0;   74  58 167;  227  73  72] / 255;
grigio = [82 81 78] / 255;

assi = nexttile([1 larghezza]);
hold(assi, 'on');  grid(assi, 'on');  box(assi, 'off');
N = size(valori_celle, 2);
nomi = cell(1, N + 1);
for n = 1:N
    plot(assi, griglia_s, valori_celle(:, n), 'Color', colori(n, :), 'LineWidth', 1.3);
    nomi{n} = sprintf('Cella %d', n);
end
plot(assi, s_tab, P_tab, stile_nominale, 'Color', grigio, 'LineWidth', 1.1, ...
    'MarkerSize', 5, 'MarkerFaceColor', 'w');
nomi{end} = 'Nominale (punti della tabella)';

xlim(assi, [0 1]);
xlabel(assi, 'SOC s [-]');
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
