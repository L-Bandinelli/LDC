# Piano di unificazione della notazione e dei nomi

Proposta del 17-10-2026, applicata lo stesso giorno (fasi 0–5): l'esito, le verifiche e le poche differenze rispetto al piano sono nella [sezione 11](#11-esito). Il dizionario definitivo è [`Notazione.md`](Notazione.md); questo file resta come storia della rinomina e come tabella di corrispondenza tra i nomi vecchi e quelli nuovi.

---

## 0. In breve

- **Il problema.** La stessa grandezza ha fino a sei nomi diversi tra paper, documenti, codice MATLAB e modello Simulink. Per esempio il SOC è `s`, `SOC`, `soc`, `SoC_i`, `x_i` e `SOC_celle`, e la tensione a vuoto è $V_{oc}$, $E_m$, `V_vuoto`, `Voc` ed `Em_LUT`. In più alcuni simboli hanno due o tre significati: `e` è sia la variabile che rilassa il vincolo di tensione sia lo sforzo di bilanciamento $e_k$ del paper, `E` è sia la f.e.m. del carico sia il coefficiente di sensibilità del SOC $E_{j,n}$, e $\sigma$ è sia la grandezza bilanciata sia il nome dei punti delle tabelle.
- **La regola.** Fa fede la notazione del paper, con le precisazioni già scritte in `Linearizzazione_MPC.tex`. Ogni simbolo ha **un solo significato** in tutto il repository, e da ogni simbolo si ricavano con regole fisse il nome nel codice ($V_{oc}$ → `Voc`, $\bar u$ → `u_bar`, $\alpha$ → `alfa`) e l'etichetta Simulink (`tensioni_a_vuoto`, in italiano snake_case come già richiesto per i Goto).
- **La tecnica.** Si cambiano solo i nomi, mai i calcoli: le simulazioni devono quindi dare risultati **identici bit per bit** a quelli di prima, ed è questo il controllo principale. Il codice MATLAB si rinomina con l'analizzatore sintattico di MATLAB (`mtree`), che distingue una variabile da una parola uguale in un commento o in una stringa; il modello Simulink con uno script `set_param`, senza riordino automatico dei blocchi; i documenti LaTeX a mano, controllando dal file `.aux` che i numeri di equazioni e sezioni non cambino.
- **I parametri della simulazione.** La struct `sl` diventa `par_sim` e la funzione che la crea, `init_simulink.m`, diventa `parametri_simulazione.m`: leggendo `par_sim.Tc` si capisce subito che è un parametro, non una variabile della simulazione ([sezione 5.4](#54-la-struct-dei-parametri-della-simulazione-oggi-sl)).
- **Decisioni:** le quattro scelte della [sezione 10](#10-decisioni-da-confermare) sono state applicate secondo la raccomandazione.

---

## 1. Che cosa ho letto

| Gruppo | File |
|---|---|
| Paper | `DOCUMENTS/BMS/Active_Cell_Balancing_by_Model_Predictive_Control_for_Real_Time_Range_Extension.pdf` (Chen, Behal, Li, IEEE CDC 2021) |
| Documenti MPC | `Linearizzazione_MPC.tex` (citato [L]), `Problema_QP_MPC.tex` ([Q]), `Passaggi_formulazione_MPC.tex` ([P]), `Variabilita_tra_Celle_MPC.md` |
| Documenti sui condensatori commutati | `01_…` – `07_…`, `Guida_Modello_Equivalente_Switched_Capacitors.md`, `Analisi_Modello_Simulink_e_Parametri.md` |
| Codice MATLAB | tutta `SIMULATION/MPC_Range_Extension/` (39 file `.m`), `SIMULATION/init.m` |
| Simulink | `Bilanciamento_MPC.slx` (R2026b, aperto in sola lettura: 240 blocchi, 33 Goto, 62 From, 4 blocchi MATLAB Function), `Bilanciamento_MPC_2024b.slx` (la sua esportazione in R2024b); `Balancing_Attivo.slx` e `Modello_semplificato.slx` (R2025b con Simscape, letti dall'XML interno perché questa sessione non ha Simscape) |
| README | `README.md`, `SIMULATION/MPC_Range_Extension/README.md` |

---

## 2. Che cosa non va

### 2.1 Una grandezza, molti nomi

| Grandezza | Paper | Documenti | Codice MATLAB | Simulink |
|---|---|---|---|---|
| SOC | $s^n$ | $s$, SOC, $SoC_i$, $x_i$ | `SOC`, `s`, `SOC_iniziale`, `tabella_SOC` | `SOC_celle`, `SOC`, `s`, nota `soc(k)` |
| Tensione di polarizzazione | $V_p^n$ | $V_p$, $v_{C1}$ | `V_pol`, `Vp`, `dv` (sua derivata) | `tensioni_polarizzazione`, blocco `V_pol`, segnale `Vp` |
| Tensione di cella | $y^n$ | $y$, $V_{cell}$ | `V_cella`, `y` | `tensioni_celle`, `tensione_cella`, `y`, nota `V_{cella}` |
| Corrente di cella | $i^n$ | $I^n$, $I(t)$ | `I_cella`, `i_cella`, `ic`, `I` | `corrente_celle`, `i_cella` |
| Corrente di pacco | $i_k$ | $i_k$, $I_{load}$ | `I_pacco`, `i_pacco`, `i`, `i_k` | `corrente_pacco`, `i`, nota `i_{pacco}` |
| Corrente di bilanciamento | $u^n_k$ | $u^n_k$, $u^n$, $I_{bal}$ (segno opposto) | `u`, `u_bil`, `I_bilanciamento` | `correnti_bilanciamento`, `u`, nota `i_{balance}` |
| Tensione a vuoto | $V_{oc}$ | $V_{oc}$, $E_m$, OCV | `V_vuoto`, `Voc`, `Em_LUT` | `Tabella_V_vuoto`, `tensione_a_vuoto` |
| Resistenza serie | $R_o$ | $R_o$, $R_0$ | `R_serie`, `Ro`, `R0_LUT` | `R_serie`, `resistenze_serie`, `Resistenza_serie`, nota `R_0` |
| Resistenza di polarizzazione | $R_p$ | $R_p$, $R_1$ | `R_pol`, `Rp`, `R1_LUT` | `R_pol`, `Resistenza_polarizzazione` |
| Capacità di polarizzazione | $C_p$ | $C_p$, $C_1$ | `C_pol`, `Cp`, `C1_LUT` | `C_pol`, `Capacita_polarizzazione` |
| Capacità della cella | $C^n$ | $C^n$, $Q$, $Q_{nom}$ | `capacita_Ah`, `Capacity_LUT` | nota `C` |
| Rendimento coulombico | $\eta^n$ | $\eta$, $\eta_{coulomb}$ | `rendimento` | nota `\eta_{coul}` |
| Passo di controllo | $T_s$ | $T_c$, $\Delta t$ | `Ts`, `par.mpc.Ts`, `Ts_controllo`, `Tc`, `passo` | `sl.Ts_controllo`, nota `T_s` |
| Passo di integrazione | — | — | `Ts_integrazione`, `passo` | `sl.Ts_integrazione` |
| Costante di tempo $R_pC_p$ | — | $\tau$, $\tau_1$ | `tau`, `costante_di_tempo`, `g` (= $1/\tau$) | `Costante_di_tempo`, `tau_polarizzazione` |
| Fattore di deviazione | — | $f^n_P$ ([L], [P]), $k^n_X$ (Variabilità) | `fattore.V_vuoto`, `f_V_vuoto`, `f_Ro` | `Fattore_V_vuoto` |
| Riferimento della cella nominale | $\sigma^0$ | $y^0$ ([L]), $r_j$ ([Q]) | `sigma0`, `y0`, `r` | `Traiettoria_nominale`, `riferimento_nominale`, `sigma0` |
| Mossa precedente | $u_{k-1}$ | $\bar u$ | `u_prec`, `u_bar` | `u_precedente`, `bilanciamento_passo_precedente` |
| Traiettoria di linearizzazione | — | $\bar Y$, $\bar S$ | `Y`, `S` | `Y`, `S` |
| Coefficienti di sensibilità | — | $D$, $E$ | `dY`, `dS`, `D`, `E`, `dsigma`, `Db` | `dY`, `dS` |
| Derivate parametriche | — | $\alpha$, $\beta$ | `alfa`, `beta`, `ds`, `dv` | — |
| Risposta libera | — | $Y^{lib}$ ([L]), $Y^0$ ([Q]) | `Y0`, `y_0`, `sigma_0`, `Yb0` | — |
| Rilassamento del vincolo di tensione | $\varepsilon_y$ | $e$ | `e` | `slack_tensione`, `e` |
| Peso sulle correnti | $R$ | $\rho$, $R = \rho I_N$ | `r`, `sl.r`, `rho`, `par.mpc.r` | — |
| Formulazione | $J_t, J_m, J_\Delta$ | $t = 1,2,3$ ([Q]) | `tipo` (testo), `sl.tipo` (numero) | `sl.tipo` |
| Esito del solutore | — | — | `flag`, `esito`, `info.flag` | `esito`, `esito_solutore` |

### 2.2 Un nome, più significati

| Nome | Significati | Dove |
|---|---|---|
| $e$, `e` | variabile che rilassa il vincolo di tensione · sforzo di bilanciamento $e_k = u_k^\top u_k$ del paper | [L], [Q], [P], `qp_*`, segnale `e` · README, `grafico_confronto.m` |
| $E$, `E` | f.e.m. del carico · coefficiente di sensibilità del SOC $E_{j,n}$ | simulazione, Simulink · [L], [P], [Q], `problema_qp_semplice.m` |
| $\sigma$ | grandezza bilanciata, $\sigma \in \{s, y\}$ · punti di SOC delle tabelle $\sigma_1,\dots,\sigma_7$ | paper, [Q] · [L] (T), [P] H2 |
| $f$, `f` | funzione di stato $f(x, I)$ · termine lineare del QP · fattore di deviazione $f_P$ | [L] (C4) · `quadprog` · [L] (T), `f_Ro` |
| $i$, `i` | corrente di pacco · indice del tratto di tabella · indice di componente ($z_i$, $H_{il}$) · prefisso "posizione di" (`i_u`, `i_e`) | ovunque · [L] (T) · [Q] sez. 2 · `qp_problema.m` |
| $r$, `r` | peso `par.mpc.r` · riferimento $r_j$ della cella nominale · un risultato (`r = ris{h, c}`) | [L], codice · [Q], `problema_qp_semplice.m` · `main_E_variabile.m` |
| $t$ | tempo · indice della formulazione | ovunque · [Q] sez. 8.1, eq. (25) |
| $m$, `m` | numero di vincoli · pendenza del tratto $m_i$ | [Q] sez. 2.1, `m = p*N` · [L] (T) |
| $Y^0$, $y^0$, `y_0`, `y0` | risposta libera · tensione della cella nominale · vettore delle risposte libere | [Q], `qp_problema.m` · [L], `qp_cella_nominale.m` · [Q] sez. 8.4 |
| `D` | coefficiente di sensibilità della tensione · struct di derivate | documenti, `*_semplice.m` · `predizione_uscite.m` |
| `A` | matrice dei vincoli del QP · jacobiana di stato | [Q], `qp_problema.m` · `jacobiano_stato.m` |
| `g`, `h` | funzione di uscita $g$ del paper · $1/\tau$ e $1/C_p$ · indice degli orizzonti | paper · `qp_predizione.m`, `jacobiano_stato.m` · `main_*.m` |
| `c` | scarto $c_{j,n}$ · vettore dei vincoli `nlmpc` · indice di cella · indice di controllore | [L], [Q] · `vincoli_disuguaglianza.m` · `qp_tabella.m` · `main_*.m` |
| `k` | istante · fattore $k^n_X$ · indice di scenario | ovunque · `Variabilita_tra_Celle_MPC.md` · `main_confronto_scarica.m` |
| $T_s$ | passo di campionamento · periodo di commutazione dei condensatori | paper, note Simulink · doc. 02, Guida, Analisi |
| $u$ | corrente di bilanciamento di una cella · corrente su un arco della rete $u_e$ | documenti MPC · doc. 03–06 |
| $\rho$ | peso sulle correnti · penalità dell'ADMM | documenti MPC · doc. 06 |
| $C$, `Capacity` | capacità della cella (Ah) · condensatore volante (F) | paper · doc. 02, Guida, `init.m` (`Capacity = .01` accanto a `Capacity_LUT`) |
| $x$, `x` | stato $(s, V_p)$ di una cella · vettore dei SOC · SOC limitato alla tabella | [L] · doc. 04–05 · `qp_tabella.m`, `leggi_tabella` |
| `eps`, `matlab` | variabili che oscurano la funzione `eps` e il pacchetto `matlab.*` di MATLAB | `mpc/*.m` · `verifica_simulink.m` |
| "traiettoria nominale" | traiettoria della cella nominale · vecchio nome della traiettoria di linearizzazione | note Simulink, `mpc/traiettoria_nominale.m` |

### 2.3 Nomi generici o sbagliati nel modello Simulink

- **Blocchi con il nome predefinito:** `From`, `From1` … `From9`, `Goto`, `Goto1` … `Goto5`, `Add`, `0 - 1`, `Demux`, `Mux1`, `Square`, `Sum of Elements`, `Scope`; `Campionamento ingressi` contiene uno spazio.
- **Nomi che dicono il falso:** `Modello_fisico/Goto_tensioni_celle1` porta le tensioni di polarizzazione; `From_tensioni_pacco` e `From_tensioni_pacco1` portano le tensioni delle celle; `Cella_piu_bassa` calcola la tensione minima, non sceglie una cella.
- **Etichette Goto in stili diversi:** `Traiettoria_nominale`, `Resistenza_serie`, `Resistenza_polarizzazione`, `Capacita_polarizzazione` hanno l'iniziale maiuscola, le altre no; `tensione_cella` è al singolare e `tensioni_celle` al plurale per lo stesso segnale; lo stesso segnale ha due etichette (`Traiettoria_nominale` e `riferimento_nominale`; `SOC` e `SOC_celle`; `Resistenza_serie` e `resistenze_serie`).
- **Porte in due stili:** `Controllo` e `Modello_fisico` usano nomi descrittivi (`SOC_celle`), mentre `Carico_RLE`, `Modello_cella` e `Parametri_cella` usano simboli (`V_pacco`, `R_serie`, `E`, `i`, `i_cella`, `y`, `s`, `Vp`).
- **Note con una terza notazione:** `soc(k)`, `\eta_{coul}`, `T_s`, `C`, `i_{cella}`, `V_{cella}`, `R_0`, `i_{pacco}`, `i_{balance}`, `L_{load}`, `R_{load}`, `y_n`. La nota del modello fisico elenca un blocco `Pacco_batteria` che non esiste più (ora è `Modello_cella`), e in una delle due formule del SOC manca il fattore 3600.

### 2.4 Altre incoerenze trovate leggendo

Non sono solo questioni di nomi. Le segnalo perché la rinomina le tocca, ma le correggo solo se lo decidi (vedi [sezione 9](#9-fuori-perimetro-e-rischi)).

- [Q] non è stato allineato alle correzioni di notazione fatte in [L] ($Y^0$, $r_j$, $u^n$ senza istante); [P] lo dichiara in una nota.
- `qp_problema.m` e `problema_qp_semplice.m` sono dichiarate intercambiabili ma hanno ingressi con nomi diversi (`sigma0, Y, S, dY, dS, u_prec` contro `r, Y, S, D, E, u_bar`).
- Il blocco `Cella_nominale` dice nel commento `Codice: qp_cella_nominale.m` ma chiama `cella_nominale_semplice`.
- Il README di `MPC_Range_Extension` descrive blocchi (`Pacco_batteria`, `Pacco_batteria/Parametri_cella`) che oggi si chiamano diversamente.
- Sono sotto controllo di versione due file di cache, `SIMULATION/MPC_Range_Extension/Bilanciamento_MPC.slxc` e `Predizione_linearizzata_blocchi.slxc`; il secondo appartiene a un modello che non esiste più.
- I documenti 02 e 07 citano figure (`fig_circuito_puro.png`, …) e codice Python che non sono nel repository; `Analisi_Modello_Simulink_e_Parametri.md` collega `init.m` e `Balancing_Attivo.slx` con percorsi relativi sbagliati.

---

## 3. Le regole

### 3.1 Che cosa fa fede

1. **Il paper** per tutti i simboli che definisce.
2. **[L] `Linearizzazione_MPC.tex`** dove precisa o corregge il paper: è il documento più rivisto e quello a cui il codice rimanda con "doc. (7)".
3. **Questo piano**, per i simboli che il paper e [L] non definiscono o che oggi sono in conflitto.

Approvato il piano, il dizionario della [sezione 4](#4-il-dizionario) diventa un documento permanente, `DOCUMENTS/Notazione.md`, citato dai README: è l'unico posto in cui un simbolo viene definito.

### 3.2 Tre livelli, con regole di traduzione fisse

**(a) Simbolo matematico** — nei documenti e nelle note Simulink. Come nel paper, salvo le deviazioni della [sezione 3.4](#34-deviazioni-consapevoli-dal-paper). Ogni simbolo ha un solo significato in tutto il repository; gli indici muti (di somma, di ciclo) non usano le lettere riservate della [sezione 3.3](#33-lettere-riservate-e-indici). Nei file LaTeX la lettera epsilon si scrive sempre `\varepsilon`, mai `\epsilon`, sia per le variabili ausiliarie $\varepsilon_j$ sia per $\varepsilon_y$; i documenti lo fanno già per le $\varepsilon_j$.

**(b) Nome nel codice MATLAB** — vale per variabili, argomenti delle funzioni e dei blocchi MATLAB Function, campi delle struct e nomi delle linee di segnale Simulink. Si ricava dal simbolo così:

| Regola | Esempi |
|---|---|
| Lettera latina: invariata | $s$ → `s`, $y$ → `y`, $u$ → `u`, $N$ → `N`, $W$ → `W`, $H$ → `H` |
| Correnti: nome per esteso | $i$ → `i_pacco`, $I^n$ → `I_cella`. Le due correnti differiscono solo per la maiuscola: per esteso non si confondono, e `i` non oscura più l'unità immaginaria di MATLAB |
| Pedice che fa parte del nome: attaccato | $V_{oc}$ → `Voc`, $R_o$ → `Ro`, $V_p$ → `Vp`, $T_c$ → `Tc`, $T_{int}$ → `Tint` |
| Pedice descrittivo o di istante: con `_` | $y_{\min}$ → `y_min`, $u_{\max}$ → `u_max`, $i_k$ → `i_pacco_k`, $V_{p,k}$ → `Vp_k`, $\kappa_{int}$ → `kappa_int` |
| Lettera greca: per esteso | $\alpha$ → `alfa`, $\beta$ → `beta`, $\tau$ → `tau`, $\kappa$ → `kappa`, $\eta$ → `eta`, $\rho$ → `rho`, $\sigma$ → `sigma`, $\varphi$ → `phi`, $\delta$ → `delta`, $\varepsilon$ → `epsilon` (mai `eps`) |
| Barra (punto di linearizzazione): `_bar` | $\bar u$ → `u_bar`, $\bar Y$ → `Y_bar` |
| Apice descrittivo: `_` + apice | $Y^{lib}$ (risposta libera) → `Y_lib`; $s^{tab}$ (punti delle tabelle) → `s_tab`, e allo stesso modo i valori delle tabelle `Voc_tab`, `Ro_tab`, `Rp_tab`, `Cp_tab` |
| Apice 0 (cella nominale): `0` attaccato | $y^0$ → `y0`, $s^0$ → `s0`, $\sigma^0$ → `sigma0` |
| Derivata: `d` + variabile di derivazione + `_` + grandezza derivata. La variabile si scrive con il suo nome nel codice, maiuscole comprese | rispetto al SOC: $C_p' = dC_p/ds$ → `ds_Cp`, $\tau'$ → `ds_tau`, $V_{oc}'$ → `ds_Voc`; rispetto al tempo: $\dot V_p = dV_p/dt$ → `dt_Vp`; rispetto alla corrente di bilanciamento: $\partial y/\partial u$ → `du_y`; rispetto alla corrente di cella: $\partial y/\partial I$ → `dI_cella_y` (caso raro: le derivate rispetto alla corrente hanno già i simboli $\alpha$, $\beta$, $d$) |
| Matrice $p \times N$ e suo elemento a un passo | $d_{j,n}$ → `d(j, n)`; il valore di una cella al passo $j$ → `d_j` (allo stesso modo `alfa(j, n)` e `alfa_j`) |
| Grandezza senza simbolo proprio nei documenti, o indicata da un'espressione | italiano snake_case per esteso: `durata`, `energia`, `motivo`, `esito`, `t_calcolo`; $\min_n y^n$ → `tensione_minima` |

Suffissi riservati: `0` solo per la cella nominale; `_iniziale` per i valori iniziali; `_next` per lo stato a fine passo; `pos_` per la posizione di un'incognita nel vettore $z$. Restano come sono i nomi imposti da MATLAB e dai toolbox (`nlobj.Ts`, gli argomenti `X`, `U`, `data` delle funzioni `nlmpc`, gli argomenti di `quadprog`).

**(c) Etichetta Simulink** — etichette Goto/From e nomi delle porte dei sottosistemi. È la regola che hai già fissato per i Goto: descrizione in italiano, snake_case minuscolo (le sigle restano maiuscole: `SOC`), niente camelCase. In più:

- plurale per i vettori con un valore per cella (`tensioni_celle`), singolare per le grandezze del pacco (`corrente_pacco`);
- una sola etichetta per segnale in tutto il modello, e la porta di un sottosistema ha lo stesso nome dell'etichetta del segnale che la attraversa;
- **nomi dei blocchi**: descrizione italiana con l'iniziale maiuscola (`Tensione_cella`, `Memoria_SOC`), mai nomi predefiniti; i Goto si chiamano `Goto_<etichetta>`, i From `From_<etichetta>`, oppure `From_<etichetta>_<uso>` se nello stesso sottosistema ce n'è più d'uno.

In pratica in Simulink il nome descrittivo sta sulle etichette e sulle porte, il simbolo sulle linee di segnale e negli argomenti dei blocchi MATLAB Function, che sono codice. È lo schema che il modello segue già in gran parte; va solo reso uniforme.

### 3.3 Lettere riservate e indici

| Lettera | Significato unico | Non usare per |
|---|---|---|
| $n = 1,\dots,N$ | cella | — |
| $k$ | istante di controllo attuale; $K$ numero di passi | indici di ciclo su scenari, griglie, costanti fisiche |
| $j = 1,\dots,p$ | passo lungo l'orizzonte | indici di campi o di ciclo generici |
| $i$ | corrente di pacco | indici di tratto o di componente |
| $t$ | tempo continuo | indice della formulazione |
| $w$ | sforzo di bilanciamento $w_k = u_k^\top u_k$ | correnti sugli archi della rete (doc. sui condensatori: $u^{arco}_e$) |
| $e$ | nessun significato: non si usa né per il rilassamento ($\varepsilon_y$) né per lo sforzo ($w_k$) | — |
| $E$ | f.e.m. del carico | coefficienti di sensibilità |
| $R$ | resistenza del carico (la matrice di peso $R$ del paper è $\rho I_N$, sezione 3.4) | — |
| $\alpha$ | derivata del SOC rispetto alla corrente, che è anche il coefficiente di sensibilità del SOC | — |
| $\ell$ | tratto di una tabella; indice di componente nei richiami sul QP | — |
| $q$ | riga della matrice $A$ | — |

### 3.4 Deviazioni consapevoli dal paper

Sono le sole differenze ammesse tra il paper e il progetto; ognuna va dichiarata una volta in `Notazione.md` e richiamata dove serve.

| Paper | Progetto | Perché |
|---|---|---|
| $T_s$ | $T_c$ (passo di controllo) e $T_{int}$ (passo di integrazione) | il modello Simulink ha due passi; $T_s$ è anche il periodo di commutazione nei documenti sui condensatori |
| $i^n$ (corrente della cella) | $I^n = i + u^n$ | $i^n_k$ e $i_k$ si confondono; già adottato in [L] |
| $y_k = \sum_n y^n_k$ (tensione di pacco) | $V_{pacco}$ | $y$ resta la tensione di una cella |
| $\underline{y}$ | $y_{\min}$ | già usato ovunque |
| $e_k = u_k^\top u_k$, $\bar e$ (sforzo di bilanciamento) | $w_k$, $\bar w$ | $e$ si confonde con $\varepsilon_y$ e con la costante di Nepero |
| $R$ (matrice di peso) | $\rho\, I_N$ | il progetto usa un peso unico, già in [L]; $R$ resta così libero per la resistenza del carico |
| $\sigma^0_{k+1}$ nell'eq. 7 | $\sigma^0_{k+j}$ | refuso del paper, già segnalato in [L] |
| $f^n$, $g^n$ | $f$, $g$ con l'indice di cella sottinteso | come in [L] |

Eccezione accettata: $f$ indica sia la funzione di stato $f(\zeta, I)$ sia il termine lineare del QP. Il secondo è la convenzione di `quadprog`, la funzione compare sempre con gli argomenti e [L] lo dichiara già nella sezione 6.

### 3.5 Le parole

| Usare | Al posto di |
|---|---|
| SOC | SoC, soc |
| tensione a vuoto | OCV, tensione a circuito aperto, $E_m$ |
| resistenza serie; resistenza e capacità di polarizzazione; ramo RC di polarizzazione | $R_0$, $R_1$, $C_1$, "condensatore del ramo RC" |
| corrente di pacco, corrente di cella, corrente di bilanciamento | $I_{load}$, `i_balance`, "corrente comune" |
| passo di controllo, passo di integrazione | "passo", "passo di campionamento" senza specificare |
| cella nominale; traiettoria della cella nominale ($\sigma^0$) | "traiettoria nominale", "riferimento $r$" |
| traiettoria di linearizzazione ($\bar Y$, $\bar S$) | "traiettoria nominale" (vecchio significato) |
| mossa precedente ($\bar u = u_{k-1}$) | `u_prec`, "bilanciamento al passo precedente" |
| coefficienti di sensibilità, sempre in minuscolo: $\alpha$ (SOC), $\beta$ (tensione di polarizzazione), $d$ (tensione ai morsetti); sono le derivate parametriche rispetto alla corrente | "pendenze", `dY`, `dS`, $D_{j,n}$, $E_{j,n}$ |
| risposta libera, risposta forzata | $Y^0$, "parte che non dipende da $u$" |
| variabili ausiliarie del costo (minoranti, maggioranti) | slack del costo |
| variabile di rilassamento del vincolo di tensione ($\varepsilon_y$) | slack, "variabile $e$" |
| sforzo di bilanciamento ($w_k = u_k^\top u_k$), sforzo medio ($\bar w$) | "sforzo $e$", $e_k$ |
| fattore di deviazione ($\varphi$), deviazione massima ($\delta$) | fattore $f$, fattore $k$ |
| f.e.m. del carico | "E" senza specificare |
| formulazione ($J_t$, $J_m$, $J_\Delta$) | tipo, $t$ |
| esito del solutore | flag, exitflag |

---

## 4. Il dizionario

Colonne: simbolo, significato, nome nel codice, etichetta Simulink, nomi attuali che sostituisce. Le righe senza nomi da sostituire sono già coerenti e restano come sono.

### 4.1 Indici, dimensioni e tempi

| Simbolo | Significato | Codice | Simulink | Sostituisce |
|---|---|---|---|---|
| $n$, $N$ | cella, numero di celle | `n`, `N` | — | `numero_celle` (in `par.pacco` e `pacco`) |
| $k$, $K$ | istante attuale, numero di passi | `k`, `K` | — | `k` usato come indice di scenario |
| $j$, $p$ | passo lungo l'orizzonte, orizzonte | `j`, `p` | — | $H_p$ (doc. 05–06) |
| $p_{rif}$ | orizzonte a cui si riferiscono i pesi | `p_rif` | — | — |
| $T_c$ | passo di controllo [s] (= $T_s$ del paper) | `Tc`, `par.mpc.Tc`, `par_sim.Tc` | — | `par.mpc.Ts`, `sl.Ts_controllo`, `Ts`, `passo`, $\Delta t$ |
| $T_{int}$ | passo di integrazione del modello fisico [s] | `Tint`, `par.tempi.Tint`, `par_sim.Tint` | — | `par.sim.Ts_integrazione`, `sl.Ts_integrazione` |
| $t$ | tempo [s] | `t` | — | — |
| $n_z$, $n_\varepsilon$, $n_{dis}$ | numero di incognite, di variabili ausiliarie, di vincoli di disuguaglianza | `n_z`, `n_epsilon`, `n_dis` | — | `n_eps`, $m$ e `m` (numero di vincoli) |
| $pN$ | righe di un blocco di vincoli | `n_blocco` | — | `m = p*N` |
| $n_J$ | formulazione: 1 = $J_t$, 2 = $J_m$, 3 = $J_\Delta$ | `par_sim.n_J` | — | $t$ in [Q], `sl.tipo` |
| — | formulazione o assenza di controllo, come testo | `tipo` (`'nessuno'`, `'Jt'`, `'Jm'`, `'Jdelta'`) | — | — |

### 4.2 Cella

| Simbolo | Significato | Codice | Simulink | Sostituisce |
|---|---|---|---|---|
| $s^n$ | SOC [-] | `s` | `SOC_celle` | `SOC`, `soc`, $SoC_i$, $x_i$, etichetta `SOC` |
| $V^n_p$ | tensione di polarizzazione [V] | `Vp` | `tensioni_polarizzazione` | `V_pol`, $v_{C1}$ |
| $\zeta^n = (s^n, V^n_p)$; $\zeta$ per tutto il pacco | stato della cella e del pacco, come nel paper (eq. 3–4) | `zeta`; nel codice il vettore del pacco è `[s; Vp]`, prima tutti i SOC e poi tutte le $V_p$ | — | $x$ ([L], [P]), `x` |
| $y^n$ | tensione ai morsetti [V] | `y` | `tensioni_celle` | `V_cella`, $V_{cell}$, `tensione_cella` |
| $I^n = i + u^n$ | corrente della cella, positiva in scarica [A] | `I_cella` | `correnti_celle` | `i_cella`, `ic`, `I`, `corrente_celle` |
| $V_{oc}(s)$ | tensione a vuoto [V] | `Voc` | `tensioni_a_vuoto` | `V_vuoto`, $E_m$, `tensione_a_vuoto` |
| $R_o(s)$ | resistenza serie [Ω] | `Ro` | `resistenze_serie` | `R_serie`, $R_0$, `Resistenza_serie` |
| $R_p(s)$ | resistenza di polarizzazione [Ω] | `Rp` | `resistenze_polarizzazione` | `R_pol`, $R_1$, `Resistenza_polarizzazione` |
| $C_p(s)$ | capacità di polarizzazione [F] | `Cp` | `capacita_polarizzazione` | `C_pol`, $C_1$, `Capacita_polarizzazione` |
| $\tau = R_p C_p$ | costante di tempo del ramo RC [s] | `tau` | `costanti_di_tempo` | `costante_di_tempo`, $\tau_1$, `tau_polarizzazione` |
| $C^n$ | capacità della cella [Ah] | `C` | — | `capacita_Ah`, $Q$, $Q_{nom}$ |
| $\eta$ | rendimento coulombico [-] | `eta` | — | `rendimento`, $\eta_{coul}$ |
| $\kappa^n = \eta T_c / (3600\, C^n)$ | SOC perso in un passo di controllo per ampere [1/A] | `kappa` | — | $d_q$ (doc. 04) |
| $\kappa^n_{int} = \eta T_{int} / (3600\, C^n)$ | lo stesso, sul passo di integrazione | `kappa_int` | — | `sl.kappa_integrazione` |
| $P' = dP/ds$ | derivata di un parametro rispetto al SOC | `ds_Voc`, `ds_Ro`, `ds_Rp`, `ds_Cp`, `ds_tau`; in una struct `ds.Voc`, `ds.Ro`, … | — | `dVoc`, `dRo`, `dRp`, `dCp`, `dtau`, `derivata.V_vuoto`, `dV_vuoto`, `dR_pol`, `pendenza` |
| $s^{tab}_\ell$, $\ell = 1,\dots,7$ | punti di SOC delle tabelle | `s_tab` | — | $\sigma_i$ ([L] (T)), `tabella_SOC`, `tabella_s`, `SOC_LUT` |
| $P^{nom}_\ell$ | valori nominali del parametro $P$ nei punti $s^{tab}_\ell$ | `Voc_tab`, `Ro_tab`, `Rp_tab`, `Cp_tab`; per un parametro generico `P_tab` | — | `tabella_V_vuoto`, `tabella_R_serie`, `tabella_R_pol`, `tabella_C_pol`, `tabella_Voc`, …, `tabella` |
| $m_\ell$ | pendenza del tratto $\ell$ della tabella nominale | `m` (locale, dove serve) | — | $m_i$ |
| $\varphi^n_P$ | fattore di deviazione del parametro $P$ della cella $n$ | `phi.Voc`, `phi.Ro`, `phi.Rp`, `phi.Cp`, `phi.C` | — | $f^n_P$, $k^n_X$, `fattore.*`, `f_*` |
| $\delta_P$ | deviazione massima relativa di $P$ | `delta.Voc`, … , `delta.C` | — | `deviazione.*`, $\delta_X$ |

### 4.3 Pacco, carico e simulazione

| Simbolo | Significato | Codice | Simulink | Sostituisce |
|---|---|---|---|---|
| $i$, $i_k$ | corrente di pacco, positiva in scarica [A] | `i_pacco` (`i_pacco_k` nel codice da leggere) | `corrente_pacco` | `I_pacco`, `i`, `i_k`, $I_{load}$ |
| $u^n_k$, $u_k$ | corrente di bilanciamento della cella $n$, positiva se il bilanciatore preleva carica [A] | `u` | `correnti_bilanciamento` | `I_bilanciamento`, `u_bil`, `i_balance`, $I_{bal}$ (= $-u$) |
| $V_{pacco} = \sum_n y^n$ | tensione di pacco [V] | `V_pacco` | `tensione_pacco` | $y_k$ (paper, eq. 4b) |
| $\min_n y^n$ | tensione della cella più bassa [V] | `tensione_minima` | `tensione_minima` | — |
| $y_{\min}$ | tensione minima ammessa [V] | `y_min` | — | $\underline{y}$ |
| $R$, $L$, $E(t)$ | resistenza, induttanza, f.e.m. del carico | `R`, `L` (in `par.carico`), `E` | `fem_carico` (per $E$) | $R_{load}$, $L_{load}$ nelle note del modello |
| — | istanti della tabella di $E$ | `t_E` | — | — |
| $R_{tot}$ | resistenza totale della maglia del carico | `R_tot` | — | `R_totale` |
| $V_{int}$ | tensione di pacco a corrente di carico nulla | `V_int` | — | `V_interna` |
| $i_{regime}$ | corrente di pacco di regime | `i_pacco_regime` | — | `I_regime` |
| — | valori iniziali | `s_iniziale`, `Vp_iniziale`, `i_pacco_iniziale` | — | `SOC_iniziale`, `par.carico.i0`, `sl.SOC_iniziale`, `sl.i_iniziale` |
| — | parametri numerici di una simulazione (una formulazione, uno scenario, un orizzonte) | `par_sim` | — | `sl` |
| — | stato a fine passo | `s_next`, `Vp_next`, `i_pacco_next`, `zeta_next` | — | `SOC_dopo`, `V_pol_dopo`, `s_succ`, `Vp_succ`, `I_pacco_dopo`, `x_succ` |

### 4.4 Predizione e linearizzazione

| Simbolo | Significato | Codice | Simulink | Sostituisce |
|---|---|---|---|---|
| $\sigma \in \{s, y\}$ | grandezza bilanciata | `par.mpc.sigma` (`'y'`/`'s'`), `par_sim.sigma_tensione` | — | — |
| $y^0_{k+j}$, $s^0_{k+j}$, $V^0_{p}$ | tensione, SOC e polarizzazione della cella nominale | `y0`, `s0`, `Vp0` | — | `V_cella`, `SOC`, `V_pol` in `cella_nominale_semplice.m` |
| $\sigma^0_{k+j}$ | riferimento di $J_t$: la grandezza bilanciata della cella nominale | `sigma0` | `riferimento_nominale` | $r_j$, `r`, `Traiettoria_nominale` |
| $\bar u^n = u^n_{k-1}$ | mossa precedente = punto di linearizzazione | `u_bar` | `correnti_bilanciamento_precedenti` | `u_prec`, `bilanciamento_passo_precedente` |
| $y^n_{k+j}$, $s^n_{k+j}$ | tensione e SOC predetti; matrici $p \times N$ | `Y`, `S` (in `nlmpc`) | — | — |
| $\bar Y_{j,n}$, $\bar S_{j,n}$ | traiettoria di linearizzazione | `Y_bar`, `S_bar` | segnali `Y_bar`, `S_bar` | `Y`, `S` (in `qp_*`) |
| $\alpha_{j,n}$, $\beta_{j,n}$, $d_{j,n}$ | coefficienti di sensibilità di SOC, tensione di polarizzazione e tensione ai morsetti: derivate rispetto alla corrente della cella $n$ al passo $j$; a tempo continuo $\alpha(t)$, $\beta(t)$, $d(t)$, come già nella (C11) di [L] | matrici `alfa`, `d` ($\beta$ non esce dalla predizione); a un passo `alfa_j`, `beta_j`, `d_j` | segnali `alfa`, `d` | $E_{j,n}$, $D_{j,n}$, `dS`, `dY`, `E`, `D`, `ds`, `dv`, `alfa`, `beta` (scalari) |
| $d^\sigma$, $\bar\Sigma$, $\Sigma^{lib}$ | quantità della grandezza bilanciata ($d$ o $\alpha$, $\bar Y$ o $\bar S$, …) | `d_sigma`, `Sigma_bar`, `Sigma_lib` | — | `dsigma`, `sigma`, `sigma_0`, `Db`, `Yb`, `Yb0` |
| $1/\tau$, $1/C_p$ e derivate | grandezze di comodo di `qp_predizione.m` | `inv_tau`, `inv_Cp`, `ds_inv_tau`, `ds_inv_Cp` | — | `g`, `h`, `dg`, `dh` |
| $Y^{lib}_{j,n}$, $S^{lib}_{j,n}$ | risposta libera | `Y_lib`, `S_lib` | — | $Y^0$, $S^0$ ([Q]), `Y0`, `y_0` |
| $c_{j,n}$ | scarto dal riferimento | `c` | — | `scarto` |

### 4.5 Problema quadratico

| Simbolo | Significato | Codice | Simulink | Sostituisce |
|---|---|---|---|---|
| $J_t$, $J_m$, $J_\Delta$ | i tre costi | `'Jt'`, `'Jm'`, `'Jdelta'` | — | — |
| $\rho$ | peso sulle correnti ($R = \rho I_N$) | `rho`, `par_sim.rho` | — | `r`, `sl.r` |
| $\rho_{rif}$ | peso riferito a $p = p_{rif}$, uno per formulazione: $\rho = \rho_{rif}\, p / p_{rif}$ | `par.mpc.Jt`, `par.mpc.Jm`, `par.mpc.Jdelta` (il campo ha il nome della formulazione a cui si applica) | — | `par.mpc.r.Jt`, `.Jm`, `.Jdelta` |
| $W$ | peso su $\varepsilon_y$ | `W` | — | — |
| $\varepsilon_j$ | variabili ausiliarie del costo: minoranti ($j \le p$), maggioranti ($p < j \le 2p$) | `epsilon` | — | `eps`, `eps0` |
| $\varepsilon_y$ | variabile di rilassamento del vincolo di tensione (eq. 17) | `epsilon_y` | `rilassamento_tensione`, segnale `epsilon_y` | $e$, `e`, `slack_tensione` |
| $z = [u_k;\ \varepsilon;\ \varepsilon_y]$ | incognite del QP | `z` | — | — |
| $H$, $f$, $A$, $b$, $A_{eq}$, $b_{eq}$ | dati del QP | `H`, `f`, `A`, `b`, `Aeq`, `beq` | — | — |
| $z_{iniz}$ | punto di partenza del solutore | `z_iniziale` | segnale `z_iniziale` | $z_0$, `z0` |
| — | posizione di un'incognita in $z$ | `pos_u`, `pos_epsilon_y` | — | `i_u`, `i_e` |
| $\mathcal{D}$, $\mathcal{P}$ | blocchi della matrice $A$ ([Q] sez. 8.4) | — | — | — |
| $y^{lib}$ | vettore delle risposte libere messe in colonna | — | — | $y^0$ in [Q] sez. 8.4 |
| $\ell$, $\ell'$ | indici di componente nei richiami sul QP | — | — | $i$, $l$ in [Q] sez. 2 |

### 4.6 Risultati (struct `ris`)

| Simbolo | Significato | Campo | Simulink (segnale registrato) | Sostituisce |
|---|---|---|---|---|
| $t$, $s$, $V_p$, $y$, $u$, $E$ | storie temporali | `t`, `s`, `Vp`, `y`, `u`, `E` | `s`, `Vp`, `y`, `u`, `E` | — |
| $i$ | corrente di pacco | `i_pacco` | `i_pacco` | `i` |
| $w_k = u_k^\top u_k = \sum_n (u^n_k)^2$ | sforzo di bilanciamento [A²] | `w` | `w` | `sforzo`, $e_k$ |
| $\bar w = \frac1K \sum_k w_k$ | sforzo medio [A²] | `w_medio` | — | `sforzo_medio`, $\bar e$ |
| $\sigma^0$ | riferimento della cella nominale | `sigma0` | `sigma0` | — |
| $\varepsilon_y > 0$ | vincolo di tensione rilassato | `morbido` | da `epsilon_y` | da `e` |
| — | esito del solutore | `esito` | `esito` | `flag`, `info.flag` |
| — | `durata`, `energia`, `motivo`, `tipo`, `p`, `t_calcolo` | invariati | — | — |

**Dove si scrive la definizione dello sforzo.** Oggi la formula compare solo in quattro commenti. Dopo la rinomina $w_k = u_k^\top u_k = \sum_n (u^n_k)^2$, in A², si legge per esteso in ognuno di questi punti:

| Dove | Che cosa si scrive |
|---|---|
| `DOCUMENTS/Notazione.md` | definizione di $w_k$ e $\bar w$, con il rimando al paper ($e_k$ nella Sez. IV) |
| `simula_pacco.m`, `simula_simulink.m` | commento sulla riga che calcola `ris.w = sum(ris.u.^2, 2)` e su quella di `ris.w_medio` |
| `grafico_confronto.m` | commento in testa ed etichetta dell'asse: `'Sforzo w_k = u_k^T u_k [A^2]'` |
| `main_E_costante.m`, `main_E_variabile.m`, `main_simulink.m`, `verifica_simulink.m` | intestazione della colonna stampata: `'Sforzo medio w [A^2]'` invece di `'Sforzo [A^2]'` |
| modello Simulink | nota accanto ai blocchi `Quadrato_u` e `Sforzo_bilanciamento`, che lo calcolano: $w_k = u_k^\top u_k$ |
| README di `MPC_Range_Extension` | riga di `Confronto_Fig3` e paragrafo sul confronto con `nlmpc` ("lo sforzo medio $\bar w$ differisce di meno dello 0,2 %") |
| [L], tabella di confronto della sez. 8 | intestazione "Sforzo medio $\bar w$ [A$^2$]" e una riga nella didascalia con la definizione |

### 4.7 Documenti sui condensatori commutati

Riguardano un altro filone (rete bipartita, DMPC, modelli Simscape). Dove la grandezza è la stessa dell'MPC si usa il dizionario qui sopra; dove è diversa serve un simbolo proprio, che non si sovrapponga.

| Simbolo | Significato | Sostituisce |
|---|---|---|
| $s_k = (s^1_k, \dots, s^N_k)$ | vettore dei SOC (modello a solo SOC) | $x(k)$, $SoC_i(k)$ |
| $T_c$, $p$, $C^n$, $i$, $\kappa$ | come nel dizionario | $\Delta t$, $H_p$, $Q_{nom}$, $I_{load}$, $d_q$ |
| $u^n$ | corrente netta di bilanciamento della cella, positiva se prelevata | $I_{bal,i}$ (che ha il segno opposto: $I_{bal,i} = -u^i$) |
| $u^{arco}_e$, $u^{arco}$ | corrente sull'arco $e$ della rete; $u = B_{cell}\, u^{arco}$ | $u_e$, $u_1, \dots, u_4$ |
| $C_{vol}$ | capacità del condensatore volante [F] | $C$, `Capacity` in `init.m` |
| $f_{sw}$, $T_{sw}$ | frequenza e periodo di commutazione | $f_s$, $T_s$, `Fs` |
| $R_{on}$, $R_{eq}$, $B_{cell}$, $B_{cap}$ | come oggi | — |
| $\rho_{ADMM}$ | penalità dell'ADMM | $\rho$ (doc. 06) |
| $V_{oc}$, $R_o$, $R_p$, $C_p$, $V_p$, $y$ | parametri e grandezze della cella, come nel dizionario | $E_m$, $R_0$, $R_1$, $C_1$, $v_{C1}$, $V_{cell}$ |

---

## 5. Rinomina nel codice MATLAB

### 5.1 Campi delle struct

Le struct attraversano più file (`par` e `pacco` vanno da `init_parametri.m` a `simula_pacco.m` e a `init_simulink.m`; `sl` va da `init_simulink.m` al modello Simulink), quindi i loro campi si rinominano tutti insieme. Il nome della struct `sl`, e quello di `par.sim`, cambiano anch'essi: vedi la [sezione 5.4](#54-la-struct-dei-parametri-della-simulazione-oggi-sl).

| Struct | Campo attuale | Campo nuovo |
|---|---|---|
| `par.cella` | `tabella_SOC`, `tabella_V_vuoto`, `tabella_R_serie`, `tabella_R_pol`, `tabella_C_pol` | `s_tab`, `Voc_tab`, `Ro_tab`, `Rp_tab`, `Cp_tab` |
| | `capacita_Ah`, `rendimento` | `C`, `eta` |
| `par.pacco` | `numero_celle`, `SOC_iniziale` | `N`, `s_iniziale` |
| | `deviazione.V_vuoto`, `.R_serie`, `.R_pol`, `.C_pol`, `.capacita` | `delta.Voc`, `.Ro`, `.Rp`, `.Cp`, `.C` |
| `par.mpc` | `Ts` | `Tc` |
| | `r.Jt`, `r.Jm`, `r.Jdelta` | `Jt`, `Jm`, `Jdelta` (cioè `par.mpc.Jt`, …) |
| `par.carico` | `i0` | `i_pacco_iniziale` |
| `par.sim` → `par.tempi` | `t_max`, `Ts_integrazione` | `t_max`, `Tint` |
| `pacco`, `pacco.nominale` | `numero_celle`, `capacita_Ah`, `rendimento`, `tabella_*` | `N`, `C`, `eta`, come `par.cella` |
| | `fattore.V_vuoto`, `.R_serie`, `.R_pol`, `.C_pol`, `.capacita` | `phi.Voc`, `.Ro`, `.Rp`, `.Cp`, `.C` |
| `sl` → `par_sim` | `tipo` (1, 2, 3), `r`, `n_eps` | `n_J`, `rho`, `n_epsilon` |
| | `Ts_controllo`, `Ts_integrazione`, `kappa_integrazione` | `Tc`, `Tint`, `kappa_int` |
| | `SOC_iniziale`, `i_iniziale` | `s_iniziale`, `i_pacco_iniziale` |
| `par_sim.pacco`, `par_sim.nominale` | `tabella_*` | come `par.cella` |
| | `f_V_vuoto`, `f_R_serie`, `f_R_pol`, `f_C_pol` | `phi.Voc`, `phi.Ro`, `phi.Rp`, `phi.Cp` |
| `ris` | `i`, `sforzo`, `sforzo_medio`, `flag` | `i_pacco`, `w`, `w_medio`, `esito` |
| `info` (`mpc_bilanciamento.m`) | `flag` | `esito` |

Restano invariati, perché già coerenti: `par.cella.temperatura`, `par.pacco.seme_casuale`, `par.mpc.p`, `.sigma`, `.u_min`, `.u_max`, `.y_min`, `.p_rif`, `.W`, `par.carico.R`, `par.carico.L`, `par.scenarioA.E`, `.t_E` (e lo stesso in `scenarioB`), `par.scenarioB.orizzonti`, `par.throughput.*`; in `par_sim` i campi `attivo`, `N`, `p`, `sigma_tensione`, `u_min`, `u_max`, `y_min`, `W`, `n_z`, `n_dis`, `pacco.kappa`, `Vp_iniziale`, `carico.R`, `carico.L`, `carico.E`, `carico.t_E`, `carico.periodo`, `t_fine`; `ris.E`; `dati.*`, `ctrl.*`.

### 5.2 Variabili dentro i file

Questa sezione dice come cambiano le variabili all'interno delle funzioni e degli script. I campi delle struct sono nella [sezione 5.1](#51-campi-delle-struct); i commenti si riscrivono a mano con il dizionario.

La maggior parte delle rinomine è la stessa in tutti i file: viene dal dizionario della sezione 4. Le eccezioni sono poche, e sono il motivo per cui la rinomina non si può fare con un "cerca e sostituisci" sull'intero progetto. La sezione è divisa così:

- **A.** le rinomine che valgono in tutti i file in cui il nome compare;
- **B.** i nomi che cambiano in modo diverso secondo il file;
- **C.** i nomi che compaiono in un solo file;
- **D.** come cambiano le firme delle funzioni, cioè ingressi e uscite.

#### A. Rinomine uguali in tutti i file

**Grandezze della cella e del pacco**

| Nome attuale | Nome nuovo | Che cosa indica |
|---|---|---|
| `SOC` | `s` | stato di carica |
| `V_pol` | `Vp` | tensione di polarizzazione |
| `V_cella` | `y` | tensione ai morsetti |
| `i_cella`, `ic`, `I` | `I_cella` | corrente della cella, $I = i + u$ |
| `I_pacco`, `i` | `i_pacco` | corrente di pacco |
| `i_k` | `i_pacco_k` | corrente di pacco misurata all'istante $k$ |
| `I_bilanciamento` | `u` | corrente di bilanciamento |
| `V_vuoto`, `R_serie`, `R_pol`, `C_pol` | `Voc`, `Ro`, `Rp`, `Cp` | parametri della cella |
| `costante_di_tempo` | `tau` | $\tau = R_p C_p$ |
| `SOC_dopo`, `s_succ` | `s_next` | SOC a fine passo |
| `V_pol_dopo`, `Vp_succ` | `Vp_next` | tensione di polarizzazione a fine passo |
| `numero_celle` | `N` | numero di celle |
| `deviazione`, `fattore` | `delta`, `phi` | deviazioni massime e fattori di deviazione |

**Tempi**

| Nome attuale | Nome nuovo | Che cosa indica |
|---|---|---|
| `passo`, `Ts` | `Tc` | passo di controllo (fa eccezione `codice_unico.m`, tabella B) |
| `Ts_controllo`, `Ts_integrazione` | `Tc`, `Tint` | i due passi del modello Simulink |

**Tabelle e derivate rispetto al SOC**

| Nome attuale | Nome nuovo | Che cosa indica |
|---|---|---|
| `tabella_SOC`, `tabella_s` | `s_tab` | punti di SOC delle tabelle |
| `tabella_V_vuoto`, `tabella_Voc` e simili | `Voc_tab`, `Ro_tab`, `Rp_tab`, `Cp_tab` | valori delle tabelle |
| `tabella` (argomento generico) | `P_tab` | la tabella di un parametro qualsiasi |
| `SOC_limitato`, `SOC_in_tabella` | `s_limitato` | SOC riportato dentro la tabella |
| `f_Voc`, `f_Ro`, `f_Rp`, `f_Cp` | `phi_Voc`, `phi_Ro`, `phi_Rp`, `phi_Cp` | fattori di deviazione di una cella |
| `dV_vuoto`, `dR_serie`, `dR_pol`, `dC_pol`, `dVoc`, `dRo`, `dRp`, `dCp`, `dtau` | `ds_Voc`, `ds_Ro`, `ds_Rp`, `ds_Cp`, `ds_tau` | derivate rispetto al SOC, $V_{oc}'$, … |
| `derivata` (struct) | `ds` | struct delle derivate rispetto al SOC: `ds.Cp` è $C_p'$ |
| `pendenza`, `derivata` (uscita di una lettura di tabella) | `ds_valore` | derivata del valore letto |

**Controllo predittivo e QP**

| Nome attuale | Nome nuovo | Che cosa indica |
|---|---|---|
| `sl` | `par_sim` | parametri della simulazione (sezione 5.4) |
| `u_prec` | `u_bar` | mossa precedente, punto di linearizzazione |
| `Y`, `S` (nelle funzioni `qp_*` e `*_semplice`) | `Y_bar`, `S_bar` | traiettoria di linearizzazione |
| `dY` | `d` | coefficiente di sensibilità della tensione |
| `dS` | `alfa` | coefficiente di sensibilità del SOC |
| `y_0`, `Y0` | `Y_lib` | risposta libera |
| `z0` | `z_iniziale` | punto di partenza del solutore |
| `eps` | `epsilon` | variabili ausiliarie del costo; `eps` oscurava la funzione di MATLAB |
| `eps0` | `epsilon_iniziale` | loro valore iniziale |
| `e` | `epsilon_y` | variabile di rilassamento del vincolo di tensione |
| `n_eps` | `n_epsilon` | numero di variabili ausiliarie |
| `i_u`, `i_e` | `pos_u`, `pos_epsilon_y` | posizione delle incognite nel vettore $z$ |
| `m` (vale `p*N`) | `n_blocco` | righe di un blocco di vincoli |

#### B. Nomi che cambiano in modo diverso secondo il file

Lo stesso nome indica oggi cose diverse in file diversi, quindi riceve nomi nuovi diversi.

| Nome attuale | File | Nome nuovo | Perché |
|---|---|---|---|
| `r` | `costo_bilanciamento.m`, `qp_problema.m` | `rho` | è il peso sulle correnti |
| `r` | `problema_qp_semplice.m` | `sigma0` | è il riferimento della cella nominale |
| `r` | `main_E_variabile.m` | `result` | è un risultato, `ris{h, c}` |
| `E` | `simula_pacco.m`, `carico_rle.m`, `profilo_E.m` | `E`, invariato | è la f.e.m. del carico |
| `E` | `problema_qp_semplice.m` | `alfa` | è il coefficiente di sensibilità del SOC |
| `E` | `predizione_linearizzata_semplice.m` | scompare | era solo una copia di `alfa` |
| `D` | `problema_qp_semplice.m` | `d` | è la matrice dei coefficienti di sensibilità della tensione |
| `D` | `predizione_linearizzata_semplice.m` | `d_j` | è lo stesso coefficiente, a un solo passo |
| `D` | `predizione_uscite.m`, `costo_bilanciamento.m`, `vincoli_disuguaglianza.m` | `der` | è una struct di derivate; i suoi campi `y_s`, `y_v`, `y_u`, `sig_s`, `sig_v`, `sig_u` diventano `ds_y`, `dVp_y`, `du_y`, `ds_sigma`, `dVp_sigma`, `du_sigma` |
| `alfa`, `beta` | `predizione_linearizzata_semplice.m` | `alfa_j`, `beta_j` | sono i valori al passo $j$; `alfa` è ora la matrice di tutti i passi |
| `ds`, `dv` | `qp_predizione.m` | `alfa_j`, `beta_j` | come sopra |
| `sigma`, `dsigma`, `sigma_0` | `qp_problema.m` | `Sigma_bar`, `d_sigma`, `Sigma_lib` | sono le quantità della grandezza bilanciata |
| `Yb`, `Db`, `Yb0` | `problema_qp_semplice.m` | `Sigma_bar`, `d_sigma`, `Sigma_lib` | le stesse quantità, con i nomi di `qp_problema.m` |
| `c` | `vincoli_disuguaglianza.m` | `cineq` | è il vettore dei vincoli di `nlmpc`; $c_{j,n}$ è lo scarto |
| `c` | `qp_tabella.m` | `n` | è l'indice di cella |
| `scarto` | `qp_problema.m` | `c` | è proprio lo scarto $c_{j,n}$ |
| `u` | `jacobiano_stato.m`, `stato_pacco.m` (→ `zeta_next.m`) | `ingressi` | non è la corrente di bilanciamento ma il vettore $[u;\ \varepsilon;\ i]$ che `nlmpc` passa alla funzione |
| `x` | `qp_tabella.m`, `leggi_tabella` (in `predizione_linearizzata_semplice.m`) | `s_limitato` | è il SOC riportato dentro la tabella |
| `x` | `stato_pacco.m` (→ `zeta_next.m`), `jacobiano_stato.m` | `zeta` | è lo stato del pacco, $\zeta$ nel paper |
| `k` | `main_confronto_scarica.m` | `indice_scenario` | $k$ è riservato all'istante |
| `k` | `codice_unico.m` | `indice_griglia` | come sopra |
| `j` | `simula_pacco.m` | `indice_campo` | $j$ è riservato al passo dell'orizzonte |
| `SOC`, `V_pol`, `V_cella` | `cella_nominale_semplice.m` | `s0`, `Vp0`, `y0` | sono della cella nominale, che ha l'apice 0 |
| `passo` | `codice_unico.m` | `Tint` | lì è il passo del modello, non quello del controllo |
| `tipo` | `problema_qp_semplice.m` | `n_J` | è il numero della formulazione, 1, 2 o 3 |

#### C. Nomi che compaiono in un solo file

| File | Nome attuale | Nome nuovo | Nota |
|---|---|---|---|
| `carico_rle.m` | `I_pacco_dopo`, `V_interna`, `R_totale`, `I_regime` | `i_pacco_next`, `V_int`, `R_tot`, `i_pacco_regime` | |
| `modello_cella.m` | `carica_erogata` | `consumed_soc` | è la frazione di SOC consumata nel passo, non una carica |
| `jacobiano_stato.m` | `A`, `Bmv` | `dzeta_zeta_next`, `dmv_zeta_next` | sono le derivate di $\zeta_{k+1}$ rispetto a $\zeta_k$ e agli ingressi; `A` è già la matrice dei vincoli del QP |
| `jacobiano_stato.m`, `qp_predizione.m` | `g`, `h`, `dg`, `dh` | `inv_tau`, `inv_Cp`, `ds_inv_tau`, `ds_inv_Cp` | $g$ è la funzione di uscita del paper; il calcolo resta identico (sezione 8.1) |
| `costo_bilanciamento.m` | `Ge` | `G_epsilon_y` | |
| `stato_pacco.m` (→ `zeta_next.m`) | `x_succ` | `zeta_next` | |
| `traiettoria_nominale.m` | `nom` | `nominale` | |
| `init_simulink.m` | `nome_r` | `nome_rho` | |
| `verifica_simulink.m` | `matlab` | `rif_matlab` | oscurava il pacchetto `matlab.*` |
| `main_confronto_scarica.m` | `mpc`, `base` | `ris_mpc`, `ris_base` | |
| `codice_unico.m` | `storia_SOC`, `storia_V_pol`, `storia_V_cella`, `storia_I` | `storia_s`, `storia_Vp`, `storia_y`, `storia_i_pacco` | |
| `codice_unico.m` | `griglia_SOC`, `V_vuoto_k` e simili, `fattore_capacita`, `tabella_nominale` | `griglia_s`, `Voc_prova` e simili, `phi_C`, `P_tab` | il glossario in testa si riscrive con il dizionario |
| `esempio_sensibilita_ode45.m` | `xdot`, `Sdot`, `zdot` | `dt_x`, `dt_S`, `dt_z` | regola delle derivate; il resto della notazione dell'esempio (`x1`, `x2`) resta |
| `esempio_sensibilita_ode45.m` | `df_dx`, `df_dF`, `dc_dx1` | `dx_f`, `dF_f`, `dx1_c` | |
| `esempio_sensibilita_ode45.m` | `dF` | `delta_F` | è un incremento, non una derivata |
| `grafico_confronto.m` | etichetta `'Sforzo e [A^2]'` | `'Sforzo w_k = u_k^T u_k [A^2]'` | |
| `simula_simulink.m` | segnali `'e'`, `'i'`; `setVariable('sl', sl)` | `'epsilon_y'`, `'i_pacco'`; `setVariable('par_sim', par_sim)` | |

Non hanno variabili da rinominare, ma solo campi di struct: `init_parametri.m`, `genera_pacco.m` (a parte `numero_celle`, `deviazione`, `fattore` della tabella A), `main_E_costante.m`, `main_E_variabile.m`, `main_throughput.m`, `main_simulink.m`, `grafico_celle.m`, `grafico_scarica.m`. Non cambiano affatto: `profilo_E.m`, `vincolo_somma.m`, `stile_grafici.m`.

#### D. Firme delle funzioni

Il riassunto più compatto delle tabelle A–C: ingressi e uscite di ogni funzione prima e dopo. Le funzioni non elencate mantengono la firma.

| Funzione | Oggi | Dopo |
|---|---|---|
| `modello_cella` | `[V_cella, SOC_dopo, V_pol_dopo] = modello_cella(pacco, SOC, V_pol, I_cella, passo)` | `[y, s_next, Vp_next] = modello_cella(pacco, s, Vp, I_cella, Tc)` |
| `parametri_cella` | `[V_vuoto, R_serie, R_pol, C_pol, derivata] = parametri_cella(pacco, SOC)` | `[Voc, Ro, Rp, Cp, ds] = parametri_cella(pacco, s)` |
| `carico_rle` | `I_pacco_dopo = carico_rle(pacco, par, SOC, V_pol, I_bilanciamento, I_pacco, E, passo)` | `i_pacco_next = carico_rle(pacco, par, s, Vp, u, i_pacco, E, Tc)` |
| `stato_pacco` → `zeta_next` | `x_succ = stato_pacco(x, u, dati)` | `zeta_next = zeta_next(zeta, ingressi, dati)` |
| `jacobiano_stato` | `[A, Bmv] = jacobiano_stato(x, u, dati)` | `[dzeta_zeta_next, dmv_zeta_next] = jacobiano_stato(zeta, ingressi, dati)` |
| `predizione_uscite` | `[Y, S, u, eps, D] = predizione_uscite(X, U, dati)` | `[Y, S, u, epsilon, der] = predizione_uscite(X, U, dati)` |
| `traiettoria_nominale` → `cella_nominale` | `sigma0 = traiettoria_nominale(pacco, s, Vp, i_pacco, p, Ts, sigma)` | `sigma0 = cella_nominale(pacco, s, Vp, i_pacco, p, Tc, sigma)` |
| `init_simulink` → `parametri_simulazione` | `sl = init_simulink(par, pacco, tipo, scen, p)` | `par_sim = parametri_simulazione(par, pacco, tipo, scen, p)` |
| `qp_tabella` | `[valore, pendenza] = qp_tabella(tabella_SOC, tabella, fattore, SOC)` | `[valore, ds_valore] = qp_tabella(s_tab, P_tab, phi, s)` |
| `qp_cella_nominale` | `sigma0 = qp_cella_nominale(sl, s, Vp, i_pacco)` | `sigma0 = qp_cella_nominale(par_sim, s, Vp, i_pacco)` |
| `cella_nominale_semplice` | `sigma0 = cella_nominale_semplice(sl, s, Vp, i_pacco)` | `sigma0 = cella_nominale_semplice(par_sim, s, Vp, i_pacco)` |
| `qp_predizione` | `[Y, S, dY, dS] = qp_predizione(celle, s, Vp, i_cella, p, Ts)` | `[Y_bar, S_bar, d, alfa] = qp_predizione(celle, s, Vp, I_cella, p, Tc)` |
| `predizione_linearizzata_semplice` | `[Y, S, dY, dS] = predizione_linearizzata_semplice(sl, s_k, Vp_k, i_k, u_bar)` | `[Y_bar, S_bar, d, alfa] = predizione_linearizzata_semplice(par_sim, s_k, Vp_k, i_pacco_k, u_bar)` |
| `leggi_tabella` (dentro il file precedente) | `[valore, derivata] = leggi_tabella(tabella_s, tabella, f, s)` | `[valore, ds_valore] = leggi_tabella(s_tab, P_tab, phi, s)` |
| `qp_problema` | `[H, f, A, b, Aeq, beq, z0] = qp_problema(sl, sigma0, Y, S, dY, dS, u_prec)` | `[H, f, A, b, Aeq, beq, z_iniziale] = qp_problema(par_sim, sigma0, Y_bar, S_bar, d, alfa, u_bar)` |
| `problema_qp_semplice` | `[H, f, A, b, Aeq, beq, z0] = problema_qp_semplice(sl, r, Y, S, D, E, u_bar)` | come `qp_problema`: le due versioni hanno finalmente gli stessi nomi |
| `qp_solutore` | `[z, esito] = qp_solutore(H, f, A, b, Aeq, beq, z0)` | `[z, esito] = qp_solutore(H, f, A, b, Aeq, beq, z_iniziale)` |

### 5.3 Nomi dei file

I nomi dei file sono già in italiano snake_case e sono citati nei documenti, quindi si cambiano solo quelli che contraddicono il dizionario:

| Attuale | Nuovo | Motivo |
|---|---|---|
| `mpc/traiettoria_nominale.m` | `mpc/cella_nominale.m` | "traiettoria nominale" non si usa più |
| `simulink/init_simulink.m` | `simulink/parametri_simulazione.m` | crea `par_sim` (sezione 5.4) |
| `mpc/stato_pacco.m` | `mpc/zeta_next.m` | calcola $\zeta_{k+1}$, lo stato del pacco al passo successivo, con la notazione del paper; si aggiornano `crea_mpc.m` (`nlobj.Model.StateFcn = @zeta_next`) e la tabella dei file del README |

`profilo_E.m`, `main_E_costante.m` e `main_E_variabile.m` restano: $E$ è la f.e.m. del carico.

Le funzioni `qp_*` e `*_semplice` mantengono il nome: `qp_` indica "funzione chiamata dal controllo a QP", ed è citato in [L], [Q] e nelle note del modello.

### 5.4 La struct dei parametri della simulazione (oggi `sl`)

**Che cos'è.** `sl` contiene i numeri di **una** simulazione: la formulazione scelta, lo scenario di carico, l'orizzonte, le celle del pacco generato e le grandezze derivate ($\kappa$, $\rho$ scalato con $p$, $n_z$, $n_{dis}$, …). La crea `init_simulink(par, pacco, tipo, scen, p)` a partire da `par`, che invece raccoglie tutti i parametri liberi del progetto (entrambi gli scenari, i pesi di tutte e tre le formulazioni). La leggono i blocchi del modello e i blocchi MATLAB Function.

**Perché cambiare nome.** `sl` dice solo "Simulink", e leggendo `sl.Tint` o `sl.N` non si capisce che si tratta di parametri e non di grandezze calcolate dalla simulazione. Il nome deve dire *parametri* e *di una simulazione*; che poi la simulazione giri in Simulink non è importante.

**Proposta: `par_sim`**, creata da una funzione che si chiama come ciò che restituisce:

```matlab
par_sim = parametri_simulazione(par, pacco, 'Jt', par.scenarioA, 30);
```

- Il prefisso `par` la lega a `par` e ne dichiara la natura: `par` sono i parametri del progetto, `par_sim` quelli di una simulazione ricavati da `par`.
- Resta breve, quindi comoda nei parametri dei blocchi: `par_sim.Tint`, `-par_sim.Tint/par_sim.carico.L`, `par_sim.pacco.phi.Voc`.
- `parametri_simulazione.m` segue lo schema di `parametri_cella.m`, che restituisce i parametri di una cella.

**Una conseguenza.** Oggi `par` ha un campo `par.sim` (`t_max`, `Ts_integrazione`). Accanto a `par_sim`, scritture come `par.sim.Tint` e `par_sim.Tint` differirebbero per un solo carattere e verrebbero confuse. Per questo `par.sim` diventa `par.tempi`: contiene la durata massima e il passo di integrazione, cioè i tempi della simulazione.

**Che cosa cambia.** Oltre ai file `.m` della [sezione 5.2](#52-variabili-dentro-i-file):
- nel modello, i 36 parametri dei blocchi che leggono `sl.` e il tempo di fine della simulazione nella configurazione (`sl.t_fine`) (sezione [6.6](#66-parametri-dei-blocchi-che-leggono-sl)), l'argomento `sl` dei quattro blocchi MATLAB Function (sezione [6.4](#64-blocchi-matlab-function)) e le due funzioni di avvio del modello, `PostLoadFcn` e `InitFcn`, che cercano e creano la variabile nel workspace;
- nei documenti, la sez. 13 di [Q] e il README.

Ho provato la rinomina dell'argomento su una copia del modello, chiusa poi senza salvare: in tutti e quattro i blocchi MATLAB Function l'argomento rinominato `par_sim` resta di tipo "parametro", cioè letto dal workspace come prima, e il modello si aggiorna senza errori.

Un effetto utile: dopo la rinomina il modello cerca `par_sim`, quindi una `sl` vecchia rimasta nel workspace viene semplicemente ignorata e non può più far fallire la simulazione con i campi vecchi.

**Alternative**, se `par_sim` non convince:

| Nome | Pro | Contro |
|---|---|---|
| `par_caso` | sottolinea che vale per un solo caso (formulazione, scenario, orizzonte); non serve rinominare `par.sim` | "caso" è meno immediato di "simulazione" |
| `parametri` | il più esplicito | lungo nei parametri dei blocchi; non distingue da `par` |
| `ps` | il più breve | ha lo stesso difetto di `sl`: non si legge |

---

## 6. Rinomina nel modello Simulink

Riguarda `Bilanciamento_MPC.slx`; alla fine si riesporta `Bilanciamento_MPC_2024b.slx`. La disposizione dei blocchi non cambia.

### 6.1 Etichette Goto/From

Tutte le etichette hanno visibilità locale: ogni rinomina riguarda un Goto e i From del suo sottosistema.

| Sottosistema | Etichetta attuale | Etichetta nuova |
|---|---|---|
| `Modello_fisico/Modello_cella/Parametri_cella` | `SOC` | `SOC_celle` |
| `Modello_fisico/Modello_cella` | `tensione_cella` | `tensioni_celle` |
| | `corrente_celle` | `correnti_celle` |
| | `tensione_a_vuoto` | `tensioni_a_vuoto` |
| | `Resistenza_serie` | `resistenze_serie` |
| | `Resistenza_polarizzazione` | `resistenze_polarizzazione` |
| | `Capacita_polarizzazione` | `capacita_polarizzazione` |
| | `tau_polarizzazione` | `costanti_di_tempo` |
| `Controllo` | `Traiettoria_nominale` | `riferimento_nominale` |
| | `bilanciamento_passo_precedente` | `correnti_bilanciamento_precedenti` |
| livello principale | `slack_tensione` | `rilassamento_tensione` |

Restano invariate: `SOC_celle`, `tensioni_celle`, `tensioni_polarizzazione`, `corrente_pacco`, `correnti_bilanciamento`, `tensione_pacco`, `tensione_minima`, `resistenze_serie` (in `Modello_fisico`), `riferimento_nominale`, `esito_solutore`.

### 6.2 Porte dei sottosistemi

| Sottosistema | Porte attuali | Porte nuove |
|---|---|---|
| `Controllo` | uscita `slack_tensione` | `rilassamento_tensione` (le altre sono già coerenti) |
| `Modello_cella` | in `i_cella`; out `y`, `s`, `Vp`, `R_serie` | in `correnti_celle`; out `tensioni_celle`, `SOC_celle`, `tensioni_polarizzazione`, `resistenze_serie` |
| `Parametri_cella` | in `s`; out `V_vuoto`, `R_serie`, `R_pol`, `C_pol` | in `SOC_celle`; out `tensioni_a_vuoto`, `resistenze_serie`, `resistenze_polarizzazione`, `capacita_polarizzazione` |
| `Carico_RLE` | in `V_pacco`, `R_serie`, `E`; out `i` | in `tensione_pacco`, `resistenze_serie`, `fem_carico`; out `corrente_pacco` |
| `Profilo_E` | out `E` | out `fem_carico` |

### 6.3 Nomi delle linee di segnale

I nomi delle linee seguono il codice; i segnali registrati in `logsout` sono letti da `simula_simulink.m`, che si aggiorna insieme.

| Attuale | Nuovo | Registrato |
|---|---|---|
| `e` | `epsilon_y` | sì |
| `sforzo` | `w` | no |
| `i` | `i_pacco` | sì |
| `i_cella` | `I_cella` | no |
| `R_serie` | `Ro` | no |
| `Y`, `S`, `dY`, `dS` | `Y_bar`, `S_bar`, `d`, `alfa` | no |
| `z0` | `z_iniziale` | no |

Invariati: `s`, `Vp`, `y`, `u`, `E`, `V_pacco`, `sigma0`, `esito` (registrati) e `H`, `f`, `A`, `b`, `Aeq`, `beq`.

### 6.4 Blocchi MATLAB Function

Cambiano firma e commenti; il calcolo resta nelle funzioni `qp_*`.

| Blocco | Firma attuale | Firma nuova |
|---|---|---|
| `Cella_nominale` | `sigma0 = Cella_nominale(s, Vp, i, sl)` | `sigma0 = Cella_nominale(s, Vp, i_pacco, par_sim)`; il commento passa a `Codice: cella_nominale_semplice.m`, cioè la funzione che il blocco chiama davvero |
| `Predizione_linearizzata` | `[Y, S, dY, dS] = …(s, Vp, i, u_prec, sl)` | `[Y_bar, S_bar, d, alfa] = …(s, Vp, i_pacco, u_bar, par_sim)` |
| `Problema_QP` | `[H, f, A, b, Aeq, beq, z0] = …(sigma0, Y, S, dY, dS, u_prec, sl)` | `[H, f, A, b, Aeq, beq, z_iniziale] = …(sigma0, Y_bar, S_bar, d, alfa, u_bar, par_sim)` |
| `Solutore_QP` | `[u, e, esito] = …(H, f, A, b, Aeq, beq, z0, sl)` | `[u, epsilon_y, esito] = …(H, f, A, b, Aeq, beq, z_iniziale, par_sim)` |

In tutti e quattro l'argomento `par_sim` resta di tipo "parametro" (provato su una copia, sezione 5.4).

### 6.5 Nomi dei blocchi

| Dove | Attuale → nuovo |
|---|---|
| livello principale | `Campionamento ingressi` → `Campionamento_misure`; `Mux1` → `Raccolta_misure`; `Demux` → `Separazione_misure`; `Scope` → `Vista_corrente_pacco`; `Square` → `Quadrato_u`; `Sum of Elements` → `Sforzo_bilanciamento`; `Goto_slack_tensione` → `Goto_rilassamento_tensione`; `From_slack_tensione` → `From_rilassamento_tensione`; `From` → `From_corrente_pacco_vista`; gli altri From secondo la regola `From_<etichetta>_<uso>` (es. `From_bilanciamento_vista2` → `From_correnti_bilanciamento_somma`, `From_SOC_controllo` → `From_SOC_celle_controllo`) |
| `Controllo` | `Goto` → `Goto_riferimento_nominale`; `From`, `From1` → `From_riferimento_nominale_uscita`, `From_riferimento_nominale_QP`; `Goto_bilanciamento_precedente` → `Goto_correnti_bilanciamento_precedenti`; `From_precedente_QP`, `From_precedente_predizione` → `From_correnti_bilanciamento_precedenti_QP`, `…_predizione`; `u_precedente` → `Mossa_precedente`; gli altri From con l'etichetta completa (es. `From_polarizzazione_nominale` → `From_tensioni_polarizzazione_nominale`) |
| `Modello_fisico` | `Goto1` → `Goto_tensione_minima`; `Goto_tensioni_celle1` → `Goto_tensioni_polarizzazione`; `From`, `From1`, `From2`, `From3`, `From5` → `From_corrente_pacco_uscita`, `From_tensione_minima_uscita`, `From_SOC_celle_uscita`, `From_tensioni_polarizzazione_uscita`, `From_tensione_minima_cedimento`; `From_SOC_cedimento1` → `From_SOC_celle_cedimento`; `From_tensioni_cedimento1` → `From_tensioni_celle_cedimento`; `From_tensioni_pacco`, `From_tensioni_pacco1` → `From_tensioni_celle_somma`, `From_tensioni_celle_uscita`; `Cella_piu_bassa` → `Tensione_minima`; `SOC_piu_basso` → `SOC_minimo` |
| `Carico_RLE` | `Corrente_pacco` (ritardo) → `Memoria_corrente_pacco`; `I_regime` → `Corrente_regime`; `Corrente_dopo` → `Corrente_pacco_next`; `Meno_Ts_su_L` → `Meno_Tint_su_L`; `R_carico` → `Resistenza_carico`; `R_serie_pacco` → `Somma_resistenze_serie`; `R_totale` → `Resistenza_totale`; `V_interna` → `Tensione_interna`; `V_meno_E` → `Tensione_interna_meno_E`; i tre From → `From_corrente_pacco_uscita`, `_caduta`, `_scarto` |
| `Modello_cella` | `0 - 1` → `Limiti_SOC`; `Add` → `SOC_next`; `Vp_dopo` → `Vp_next`; `Carica_erogata` → `SOC_perso`; `Caduta_R_serie` → `Caduta_Ro`; `I_su_C_pol` → `I_su_Cp`; `Derivata_Vp` → `Derivata_tempo_Vp` (calcola $dV_p/dt$); `Passo_Ts` → `Passo_Tint`; `SOC` (ritardo) → `Memoria_SOC`; `V_pol` (ritardo) → `Memoria_Vp`; `Goto` … `Goto5` → `Goto_capacita_polarizzazione`, `Goto_resistenze_polarizzazione`, `Goto_resistenze_serie`, `Goto_tensioni_a_vuoto`, `Goto_costanti_di_tempo`, `Goto_tensioni_celle`; `Goto_corrente_celle` → `Goto_correnti_celle`; `From` … `From9` secondo etichetta e uso (es. `From5`, `From6` → `From_capacita_polarizzazione_tau`, `From_capacita_polarizzazione_ramo_RC`) |
| `Parametri_cella` | `Tabella_V_vuoto`, `Tabella_R_serie`, `Tabella_R_pol`, `Tabella_C_pol` → `Tabella_Voc`, `Tabella_Ro`, `Tabella_Rp`, `Tabella_Cp`; `Fattore_*` allo stesso modo; `Goto` → `Goto_SOC_celle`; `From` … `From3` → `From_SOC_celle_Rp`, `_Cp`, `_Voc`, `_Ro` |

Restano invariati i nomi già descrittivi (`Controllo`, `Modello_fisico`, `Carico_RLE`, `Modello_cella`, `Profilo_E`, `Tabella_E`, `Bilanciamento_attivo`, `Mantieni_bilanciamento`, `Corrente_cella`, `Tensione_pacco`, `Arresto`, `Pacco_ceduto`, `Sotto_y_min`, `SOC_esaurito`, gli scope `Celle_Fig2`, `Confronto_Fig3`, `MPC_interno`, …).

### 6.6 Parametri dei blocchi che leggono `sl`

In tutti i 36 parametri dei blocchi che leggono `sl.`, e nel tempo di fine della configurazione (`sl.t_fine`), `sl` diventa `par_sim`; insieme cambiano i campi: `sl.Ts_controllo` → `par_sim.Tc` (`Campionamento_misure`, `Mossa_precedente`); `sl.Ts_integrazione` → `par_sim.Tint` (nove blocchi del modello fisico); `sl.kappa_integrazione` → `par_sim.kappa_int`; `sl.pacco.f_*` → `par_sim.pacco.phi.*`; `sl.pacco.tabella_*` → nuovi nomi; `sl.SOC_iniziale` → `par_sim.s_iniziale`; i campi del carico (`carico.R`, `.L`, `.E`, `.t_E`, `.periodo`) restano.

Le due funzioni di avvio del modello, `PostLoadFcn` e `InitFcn`, cercano `par_sim` nel workspace e, se manca, la creano con `parametri_simulazione()` invece di `init_simulink()`.

### 6.7 Note

Le note si riscrivono con la notazione del dizionario, per esempio:

| Nota attuale | Nota nuova |
|---|---|
| `soc(k+1) = soc(k) - \eta_{coul} T_s/(3600 C) i_{cella}(k)` | $s^n_{k+1} = s^n_k - \kappa_{int}\, I^n_k$, con $\kappa_{int} = \eta\, T_{int} / (3600\, C^n)$ |
| `V_p(k+1) = V_p(k) + T_s(-V_p(k)/(R_p C_p) + i(k)/C_p)` | $V^n_{p,k+1} = V^n_{p,k} + T_{int}\bigl(-V^n_{p,k}/\tau(s^n_k) + I^n_k / C_p(s^n_k)\bigr)$ |
| `V_{cella}(k) = V_{oc}(k) - V_p(k) - R_0 i(k)` | $y^n_k = V_{oc}(s^n_k) - V^n_{p,k} - R_o(s^n_k)\, I^n_k$ |
| `i_{cella}(k) = i_{pacco}(k) + i_{balance}(k)` | $I^n_k = i_k + u^n_k$ (positiva in scarica) |
| `L_{load} di_{pacco}/dt = V_{pacco} - R_{load} i_{pacco} - E` | $L\, di/dt = V_{pacco} - R\, i - E$ |
| `vincolo y_n \geq y_{min}` | vincolo $y^n_k \ge y_{\min}$ |

Nelle note di testo: `Pacco_batteria` → `Modello_cella`; "Parametri nella struct 'sl' (avvio_simulink.m)" → "Parametri della simulazione nella struct `par_sim` (avvio_simulink.m)"; `sl.Ts_*` → `par_sim.Tc`, `par_sim.Tint`; `sl.tipo` → `par_sim.n_J`; `sigma0`, `u_prec`, `eps`, `e` → $\sigma^0$, $\bar u$, $\varepsilon$, $\varepsilon_y$; "traiettoria nominale" → "traiettoria della cella nominale".

---

## 7. Documenti

### 7.1 LaTeX

I numeri di equazione e di sezione di [L] e [Q] sono citati dal codice e non devono cambiare: si sostituiscono simboli dentro formule già esistenti, senza aggiungere equazioni numerate. Epsilon si scrive sempre `\varepsilon`: la nuova $\varepsilon_y$ è `\varepsilon_y`, come le $\varepsilon_j$ già presenti.

**[L] `Linearizzazione_MPC.tex`**
- Stato della cella: $x = (s, V_p)$ → $\zeta = (s, V_p)$, come nel paper, dove è lo stato della cella (sez. 2.1 e (C4), Eulero della sez. 2.3, applicazione alla cella e (C5) nella sez. 5.1, "due strade" nella sez. 5.3). Resta $x$ solo nell'"Espressione generale" della sez. 5.1, che parla di un sistema qualsiasi con parametri $\theta$.
- Sez. 2.2 e (T): $\sigma_i$ → $s^{tab}_\ell$; indice del tratto $i$ → $\ell$ ($P^{nom}_\ell$, $m_\ell$); fattore $f_P$, $f^n_{R_o}$, $f_{R_p}$ → $\varphi_P$, $\varphi^n_{R_o}$, $\varphi_{R_p}$.
- Coefficienti di sensibilità tutti in minuscolo, $\alpha$, $\beta$, $d$, in tutto il documento:
  - $D_{j,n}$, $D_j$ → $d_{j,n}$, $d_j$: il valore discreto della $d(t)$ che la (C11) scrive già in minuscolo, come $\alpha_j$ lo è di $\alpha(t)$;
  - $E_{j,n}$, $E_j$ → $\alpha_{j,n}$, $\alpha_j$: nella (6) la seconda riga diventa $s^n_{k+j}(u^n_k) \simeq \bar S_{j,n} + \alpha_{j,n}(u^n_k - \bar u^n)$; nella (9) la riga $E_j = \alpha_j$ si toglie (resta una frase nel testo), senza cambiare il numero dell'equazione, che è uno solo per tutto il blocco;
  - la tabella della sez. 5 "Coefficienti di sensibilità: $d(t_j)$, $\alpha(t_j)$ → $D_j$, $E_j$" diventa "$d(t_j)$, $\alpha(t_j)$ → $d_j$, $\alpha_j$", e $\alpha$, $\beta$, $d$ si presentano insieme come i coefficienti di sensibilità di $s$, $V_p$ e $y$ (le derivate parametriche rispetto alla corrente).
- Sez. 4 e 5: nomi nel codice `Y`, `S`, `dY`, `dS` → `Y_bar`, `S_bar`, `d`, `alfa`; righe di codice citate: `beta = beta + Tc*( -beta/tau + Vp*dtau*alfa/tau^2 + 1/Cp - I*dCp*alfa/Cp^2 )` → `beta_j = beta_j + Tc*( -beta_j/tau + Vp*ds_tau*alfa_j/tau^2 + 1/Cp - I_cella*ds_Cp*alfa_j/Cp^2 )`, e `D = dVoc*alfa - beta - dRo*alfa*I - Ro` → `d_j = ds_Voc*alfa_j - beta_j - ds_Ro*alfa_j*I_cella - Ro`. Nelle formule la derivata rispetto al SOC resta l'apice ($C_p'$), che il testo definisce già come $dC_p/ds$.
- Sez. 6: $e$ → $\varepsilon_y$ (incognite, costo $W\varepsilon_y^2$, vincoli (12) e (16), punto di partenza); "$\rho$ è `par.mpc.r` moltiplicato per $p/p_{rif}$" → $\rho = \rho_{rif}\, p / p_{rif}$, con $\rho_{rif}$ = `par.mpc.Jt`, `par.mpc.Jm` o `par.mpc.Jdelta` secondo la formulazione; nell'esempio numerico `par.mpc.r.Jt` → `par.mpc.Jt`.
- Sez. 8, tabella di confronto: "Sforzo medio [A$^2$]" → "Sforzo medio $\bar w$ [A$^2$]", e nella didascalia la definizione $w_k = u_k^\top u_k$, $\bar w = \frac1K \sum_k w_k$.
- Sez. 9, tabella dei nomi nel codice: `i_k`, `I` → `i_pacco_k`, `I_cella`; `f_Ro`, `tabella_Ro` → `phi_Ro`, `Ro_tab` (e nella frase che segue `f_Voc`, `tabella_Voc` → `phi_Voc`, `Voc_tab`); `dVoc`, `dRo`, `dRp`, `dCp`, `dtau` → `ds_Voc`, `ds_Ro`, `ds_Rp`, `ds_Cp`, `ds_tau`, e la frase "la derivata rispetto a $s$ … nel codice ha il prefisso `d`" → "… ha il prefisso `ds_`, che nomina anche la variabile di derivazione"; $\alpha_j$, $\beta_j$ → `alfa_j`, `beta_j`; `y`, `D`, `E` → `y`, `d_j` (e `E` sparisce, perché è $\alpha_j$); matrici `Y`, `S`, `dY`, `dS` → `Y_bar`, `S_bar`, `d`, `alfa`.

**[Q] `Problema_QP_MPC.tex`** (allineamento a [L], già annunciato in [P])
- $r_j$ → $y^0_{k+j}$ ($\sigma^0_{k+j}$ dove si parla di $\sigma$ in generale); $Y^0_{j,n}$, $S^0_{j,n}$ → $Y^{lib}_{j,n}$, $S^{lib}_{j,n}$; vettore $y^0$ della sez. 8.4 → $y^{lib}$; si aggiunge al preambolo `\newcommand{\lib}{\mathrm{lib}}` come in [L].
- $u^n$ → $u^n_k$ e $u$ → $u_k$ in tutto il documento.
- $D_{j,n}$ → $d_{j,n}$ ovunque (costo, vincoli, esempio numerico); $E$ → $\alpha$ nella sez. 11; la matrice a blocchi $\mathcal{D}$ della sez. 8.4 mantiene il nome, ma raccoglie le $d_{j,n}$.
- $e$ → $\varepsilon_y$ (anche "segno di $e$", $H_{ee}$, tabella delle posizioni).
- $t$ (formulazione) → $n_J$ nella sez. 8.1, eq. (25) e tabella delle righe.
- $m$ (numero di vincoli, sez. 2.1) → $n_{dis}$.
- Indici di componente $z_i$, $H_{il}$, $A_{qi}$ → $z_\ell$, $H_{\ell\ell'}$, $A_{q\ell}$.
- $z_0$ → $z_{iniz}$.
- Sez. 13: chiamata `problema_qp_semplice(par_sim, sigma0, Y_bar, S_bar, d, alfa, u_bar)` e tabella dei nomi nel codice aggiornate; "I parametri arrivano dalla struttura `sl`, creata da `init_simulink.m`: $\rho$ è `sl.r`, la formulazione è `sl.tipo`" → "… dalla struct dei parametri della simulazione `par_sim`, creata da `parametri_simulazione.m`: $\rho$ è `par_sim.rho`, la formulazione è `par_sim.n_J`".

**[P] `Passaggi_formulazione_MPC.tex`**
- Tolta la nota "[Q] usa ancora $Y^0_{j,n}$, $r_j$ e $u^n$", che non sarà più vera.
- H1 "Lo stato è $x = (s, V_p)$" → $\zeta = (s, V_p)$.
- $f^n_P$ → $\varphi^n_P$; $\sigma_1, \dots, \sigma_7$ → $s^{tab}_1, \dots, s^{tab}_7$, indice $i$ → $\ell$.
- $D_{j,n}$, $D_j$ → $d_{j,n}$, $d_j$; $E_{j,n}$, $E_j$ → $\alpha_{j,n}$, $\alpha_j$ (sviluppo al primo ordine, [L, (9)], tabella delle ipotesi).
- $e$ → $\varepsilon_y$, $H_{ee}$ di conseguenza; $z_0$ → $z_{iniz}$; $\rho = r\, p/p_{rif}$ → $\rho = \rho_{rif}\, p / p_{rif}$, e "dove $r$ è `par.mpc.r`" (ipotesi H10) → "dove $\rho_{rif}$ è `par.mpc.Jt`, `par.mpc.Jm` o `par.mpc.Jdelta`".

### 7.2 Markdown

- `Variabilita_tra_Celle_MPC.md`: $k^n_X$ → $\varphi^n_P$, $X$ → $P$, $\delta_X$ → $\delta_P$, $Q$ → $C$; blocchi di codice con `par.pacco.delta.*` e `pacco.phi.*`; intestazioni della tabella dei fattori.
- `SIMULATION/MPC_Range_Extension/README.md`: nomi di file, campi di `par`, `sl` → `par_sim` ("All'apertura il modello crea da solo la struct `par_sim` con i parametri della simulazione"), etichette, blocchi (`Pacco_batteria` → `Modello_cella`), sforzo $e_k$ → $w_k = u_k^\top u_k$, `par.mpc.Tc`, `par.tempi.Tint`; collegamento a `DOCUMENTS/Notazione.md`.
- `README.md` principale: collegamento a `DOCUMENTS/Notazione.md`.

### 7.3 Documenti sui condensatori commutati (fase facoltativa)

`01_…` – `07_…`, `Guida_Modello_Equivalente_Switched_Capacitors.md` e `Analisi_Modello_Simulink_e_Parametri.md` si allineano con la tabella [4.7](#47-documenti-sui-condensatori-commutati). In `Analisi_…` i nomi del modello di Huria (`Em_LUT`, `R0_LUT`, `R1_LUT`, `C1_LUT`) restano citati, una volta, come nomi delle variabili di `init.m`, accanto ai simboli del dizionario.

---

## 8. Approccio e tecnica

### 8.1 Principio: cambiare i nomi, non i calcoli

La rinomina è **pura**: nessuna espressione aritmetica cambia, nemmeno dove una riscrittura sarebbe più leggibile. Per esempio in `qp_predizione.m` `g = 1 ./ (R_pol .* C_pol)` diventa `inv_tau = 1 ./ (Rp .* Cp)`, non `1 ./ tau`: l'ordine delle operazioni resta quello di prima, e con lui l'arrotondamento.

Ne segue il criterio di verifica più forte possibile: **ogni simulazione deve dare risultati identici bit per bit** (`isequal`) a quelli di prima della rinomina. Basta una differenza di $10^{-16}$ per segnalare che qualcosa, oltre ai nomi, è cambiato.

Ogni miglioria che non è una rinomina va in un passo separato, dopo questo: riscrivere `qp_predizione.m` nella forma della (7) di [L], aggiungere il 3600 mancante nella nota del modello, scegliere quale funzione chiama il blocco `Cella_nominale`.

### 8.2 Una tabella di corrispondenza, letta da script

Le sezioni 4–6 diventano un file di testo, `rinomina.csv`, con una riga per rinomina:

```
ambito;tipo;vecchio;nuovo
SIMULATION/MPC_Range_Extension/modello/carico_rle.m;ID;I_pacco;i
*;FIELD;tabella_V_vuoto;Voc_tab
Bilanciamento_MPC/Modello_fisico/Modello_cella;TAG;Resistenza_serie;resistenze_serie
Bilanciamento_MPC/Controllo/Solutore_QP;MLFB;e;epsilon_y
```

`ID` sono le variabili di un file, `FIELD` i campi di una struct (validi ovunque, perché le struct attraversano i file), `TAG`, `PORTA`, `SEGNALE`, `BLOCCO`, `MLFB` gli oggetti Simulink. Gli script della sezione 8.3 e 8.4 leggono solo questa tabella: una rinomina si decide in un posto e si applica ovunque allo stesso modo.

### 8.3 Codice MATLAB: analisi sintattica con `mtree`

Una sostituzione di testo (anche con i confini di parola) non basta, per tre motivi:

1. lo stesso nome vecchio ha destinazioni diverse in file diversi (`E`, `r`, `D`, `c`, `i_e`);
2. un nome uguale compare nei commenti con un altro significato ("e" congiunzione, "E" iniziale di frase);
3. alcuni nomi stanno dentro stringhe che il codice usa come nomi (`registro.get('E')`, `campi = {'s', 'Vp', …}`, `par.(['scenario' scenario])`).

`mtree` è l'analizzatore sintattico che MATLAB usa per `checkcode`. Divide il file in nodi e dice di ognuno il tipo (`ID` per una variabile o una funzione, `FIELD` per un campo di struct, `STRING` per una stringa) e la posizione. L'ho provato in questa sessione su tutti i 40 file `.m` di `SIMULATION/`: l'inventario completo di variabili e campi da cui viene la [sezione 5](#5-rinomina-nel-codice-matlab) è stato ricavato così.

Lo script `applica_rinomina.m`:
1. per ogni file legge con `mtree(file, '-file')` i nodi `ID` e `FIELD`;
2. sostituisce quelli che compaiono nella tabella, partendo dal fondo del file perché le posizioni dei nodi precedenti restino valide;
3. elenca, senza toccarle, le stringhe uguali a un nome vecchio: le correggo a mano una per una;
4. non tocca i commenti: li riscrivo a mano, perché contengono formule e frasi che vanno riformulate con la terminologia nuova, non solo sostituite.

Controlli dopo l'applicazione:
- `checkcode` su ogni file: nessun avviso nuovo, in particolare nessun nome che oscura una funzione (`eps`, `matlab`);
- una seconda passata di `mtree`: nessun nodo `ID` o `FIELD` con un nome vecchio;
- ricerca dei nomi vecchi nei commenti, con revisione di ogni occorrenza rimasta.

I file si rinominano con `git mv`, così la storia del file resta collegata.

### 8.4 Simulink: script `set_param` su una copia di sicurezza

Le tue indicazioni sul modello valgono anche qui: copia prima di modificare, nessun riordino dei blocchi, etichette italiane snake_case. Per questo non uso `model_edit`, che dopo ogni chiamata può riordinare il diagramma, ma uno script `rinomina_simulink.m` che cambia solo proprietà di testo:

| Oggetto | Come si rinomina |
|---|---|
| Nome di un blocco | `set_param(blocco, 'Name', nuovo)` |
| Etichetta Goto/From | `set_param(…, 'GotoTag', nuovo)` sul Goto e, nella stessa passata, su tutti i From del suo sottosistema (le etichette sono tutte locali) |
| Porta di un sottosistema | `set_param` sul blocco `Inport`/`Outport` |
| Nome di una linea | `set_param(linea, 'Name', nuovo)`; la registrazione usa il nome del segnale, quindi `logsout` segue da solo |
| Parametri che leggono `sl` | sostituzione dei soli campi interi (`\<sl\.Ts_controllo\>` → `par_sim.Tc`) nei parametri dei blocchi e nel tempo di fine della configurazione |
| Funzioni di avvio del modello | `set_param(modello, 'PostLoadFcn', …)` e `'InitFcn'`, con `par_sim` e `parametri_simulazione()` |
| Blocco MATLAB Function | si modifica il codice (`Stateflow.EMChart`, proprietà `Script`); le porte prendono i nomi della firma e restano collegate, perché Simulink le collega per posizione |
| Note | `Simulink.Annotation`, proprietà `Text`, riscritte a mano come in [6.7](#67-note) |

Prova fatta su una copia del modello nella cartella temporanea, chiusa poi senza salvare: rinominata l'uscita `e` di `Solutore_QP` in `epsilon_y` e l'etichetta `Traiettoria_nominale` in `riferimento_nominale` con i suoi due From. Risultato: le tre uscite di `Solutore_QP` restano collegate, l'aggiornamento del diagramma riesce senza errori e le posizioni di tutti i 240 blocchi sono identiche a prima. Una seconda prova, sempre su una copia, ha rinominato l'argomento `sl` in `par_sim` nei quattro blocchi MATLAB Function: resta di tipo "parametro" e il diagramma si aggiorna senza errori.

Passi:
1. commit dello stato attuale e copia `Bilanciamento_MPC_copia_prima_di_rinomina.slx` (già esclusa da `.gitignore`);
2. fotografia delle posizioni di tutti i blocchi e di tutte le linee;
3. esecuzione dello script;
4. confronto con la fotografia: le posizioni devono essere identiche;
5. aggiornamento del diagramma e controllo di porte e linee scollegate: un From senza Goto o una porta senza linea lo fanno fallire;
6. riesportazione della copia R2024b con `Simulink.exportToVersion('Bilanciamento_MPC', 'Bilanciamento_MPC_2024b.slx', 'R2024b')`.

Un dettaglio pratico: il modello, quando si apre, crea la struct dei parametri solo se nel workspace non c'è già. Dopo la rinomina cerca `par_sim`, quindi la `sl` vecchia oggi presente nel workspace viene ignorata (si può cancellare con `clear sl`). Lo stesso rischio si ripresenterebbe se in futuro cambiassero i campi di `par_sim`: in quel caso basta rieseguire `avvio_simulink`.

La seconda prova ha mostrato anche un difetto attuale: le funzioni di avvio cercano il modello per nome (`get_param('Bilanciamento_MPC', 'FileName')`). Se si apre da sola la copia `Bilanciamento_MPC_2024b.slx`, quel modello non è caricato, la funzione fallisce e i parametri non vengono creati. Riscrivendo le due funzioni per `par_sim` conviene leggere il percorso del modello aperto (`get_param(bdroot, 'FileName')`), da verificare su entrambe le versioni.

### 8.5 Documenti LaTeX: modifiche a mano, numerazione controllata dal `.aux`

1. Prima: compilo i tre `.tex` con `pdflatex` in una cartella temporanea e conservo i file `.aux`, che contengono, per ogni `\label`, il numero assegnato a equazioni e sezioni.
2. Modifiche a mano, documento per documento, con l'elenco della [sezione 7.1](#71-latex). Nessuna nuova equazione numerata.
3. Dopo: ricompilo e confronto le righe `\newlabel` dei due `.aux`. Devono essere identiche: è la prova che "doc. (7)" e "sezione 5.3" nel codice rimandano ancora alla stessa formula.
4. Copio in `DOCUMENTS/` solo i `.pdf`.

Facoltativo, e lo consiglio: un file comune `DOCUMENTS/notazione.tex` con un comando per ogni simbolo che cambia (`\epsy` per $\varepsilon_y$, `\Ecar`, `\stab` per $s^{tab}$, `\fatt` per $\varphi$, `\rhorif`), incluso dai tre documenti con `\input`. Una futura modifica di un simbolo si farebbe allora in una riga.

### 8.6 Ordine delle fasi

| Fase | Contenuto | Verifica | Commit |
|---|---|---|---|
| 0 | Ramo `unificazione-notazione`; risultati di riferimento: `main_E_costante`, `main_simulink`, `verifica_simulink` e le funzioni `qp_*` e `*_semplice` su ingressi salvati, eseguiti in batch su una copia della cartella; `.aux` dei documenti | — | — |
| 1 | Approvazione di questo piano e delle decisioni della [sezione 10](#10-decisioni-da-confermare) | — | questo file |
| 2 | Codice MATLAB e modello Simulink insieme: sono legati da `par_sim` (oggi `sl`) e dai nomi dei segnali registrati | `checkcode`, `mtree`, aggiornamento del diagramma, posizioni invariate | sì |
| 3 | Confronto con i risultati di riferimento, bit per bit; poi rigenerazione di `risultati/*.mat` e `*.png` (le `.mat` contengono `par`, `pacco` e `ris` con i campi vecchi, e `verifica_simulink` le legge) | `isequal` su tutte le storie temporali | sì |
| 4 | Documenti LaTeX e PDF | `.aux` identici | sì |
| 5 | README, `Variabilita_tra_Celle_MPC.md`, `DOCUMENTS/Notazione.md` | rilettura | sì |
| 6 | Facoltativa: documenti sui condensatori commutati; `init.m` e modelli Simscape | rilettura; per i modelli, simulazione breve in R2025b | sì |

Le simulazioni lunghe (gli script con `nlmpc` durano minuti, lo scenario B decine di minuti) girano in batch R2026b su una copia della cartella, non nella sessione MATLAB che vedi.

### 8.7 Lista di controllo finale

- [x] Nessun nome vecchio nel codice (seconda passata di `mtree`) e nei commenti (ricerca testuale rivista a mano).
- [x] `checkcode` senza avvisi nuovi.
- [x] Modello: nessun blocco con nome predefinito; ogni Goto con almeno un From e ogni From con il suo Goto; posizioni dei blocchi invariate; aggiornamento del diagramma senza errori.
- [x] Simulazioni MATLAB e Simulink identiche bit per bit a quelle di riferimento, per `nessuno`, `Jt`, `Jm`, `Jdelta`.
- [x] `verifica_simulink` stampa gli stessi numeri di prima.
- [x] `.aux` dei documenti identici prima e dopo; PDF ricompilati.
- [x] `Bilanciamento_MPC_2024b.slx` riesportato.
- [x] `DOCUMENTS/Notazione.md` creato e citato dai README.

---

## 9. Fuori perimetro e rischi

- **Comportamento.** Nessun cambiamento di calcolo, di parametri o di struttura. In particolare il controllo continua a predire con i parametri deviati noti di ogni cella (`par_sim.pacco`, oggi `sl.pacco`), come deciso il 12-10.
- **Nomi imposti.** Restano i nomi dei toolbox (`nlobj.Ts`, `X`, `U`, `mv`, argomenti di `quadprog`) e i numeri di equazioni e sezioni dei documenti.
- **Modelli Simscape e `init.m`.** `Balancing_Attivo.slx` e `Modello_semplificato.slx` vengono dall'esempio MathWorks: i nomi `Em_LUT`, `R0_LUT`, `R1_LUT`, `C1_LUT` sono letti dai parametri dei blocchi della libreria `LiBatteryElements`. Rinominarli richiede R2025b con Simscape (non disponibile nella sessione R2026b) e serve a poco; propongo solo un commento di corrispondenza in `init.m` con i simboli del dizionario. Fanno eccezione `Capacity` (che è il condensatore volante, accanto a `Capacity_LUT` che è la cella) e `Fs`, da rinominare in `C_vol` e `f_sw` insieme al blocco `1/(Fs*Capacity)` di `Modello_semplificato.slx`, nella fase 6.
- **Risultati salvati.** Le `.mat` in `risultati/` non saranno più leggibili con i nomi nuovi: si rigenerano nella fase 3, e quelle vecchie restano nella storia di git.
- **Workspace.** Con il nuovo nome una `sl` vecchia rimasta nel workspace viene ignorata; una `par_sim` con campi superati, dopo future modifiche, si rinnova rieseguendo `avvio_simulink` (sezione 8.4).
- **Correzioni di contenuto** emerse leggendo (3600 mancante in una nota, commento del blocco `Cella_nominale`, README con blocchi che non esistono più, `.slxc` sotto controllo di versione, collegamenti rotti in `Analisi_…`, funzioni di avvio che cercano il modello per nome e quindi non funzionano nella copia R2024b): le faccio in commit separati, se le vuoi.

---

## 10. Decisioni da confermare

**Già decise (17-10-2026)**
- **Epsilon nei LaTeX:** sempre `\varepsilon`, anche per $\varepsilon_y$.
- **Nomi delle derivate nel codice:** `d` + variabile di derivazione + `_` + grandezza (`ds_Cp`, `dt_Vp`, `du_y`).
- **$E$ è la f.e.m. del carico** (con $R$ e $L$, e i nomi attuali `E`, `profilo_E.m`, `Profilo_E`). Il coefficiente di sensibilità del SOC diventa $\alpha_{j,n}$, che per la (9) di [L] è la stessa grandezza ($E_j = \alpha_j$).
- **Correnti e fine passo nel codice:** `i_pacco` (corrente di pacco) e `I_cella` (corrente di cella) per esteso; lo stato a fine passo ha il suffisso `_next` (`s_next`, `Vp_next`, `i_pacco_next`).
- **Stato del pacco:** $\zeta$ come nel paper, nel codice `zeta`; la funzione `stato_pacco.m` diventa `zeta_next.m`, perché calcola $\zeta_{k+1}$.
- **Sforzo di bilanciamento:** $w_k = u_k^\top u_k$ (nel paper $e_k$), codice `w`, `w_medio`, con la definizione scritta per esteso nei punti elencati nella sezione 4.6.
- **Coefficienti di sensibilità tutti in minuscolo:** $\alpha$ (SOC), $\beta$ (tensione di polarizzazione), $d$ (tensione ai morsetti, prima $D$); nel codice `alfa`, `beta_j`, `d`.

**Applicate secondo la raccomandazione (17-10-2026)**

| | Decisione | Raccomandazione (applicata) | Alternativa |
|---|---|---|---|
| D1 | Rilassamento del vincolo di tensione | $\varepsilon_y$ (`epsilon_y`), come nel paper | tenere $e$ come oggi: meno modifiche a [L], [Q] e [P], e ora che lo sforzo è $w_k$ non ci sarebbe più conflitto; ma ci si allontana dal paper |
| D3 | Nomi nelle struct di configurazione | simboli anche lì (`par.cella.Voc_tab`, `pacco.phi.Voc`, `par.pacco.N`): un solo nome per grandezza | lasciare i nomi descrittivi in `par` (`tabella_V_vuoto`) e usare i simboli solo nel codice di calcolo: `par` resta più leggibile da solo, ma ogni grandezza continua ad avere due nomi |
| D4 | Perimetro | fasi 0–5, con i due file rinominati della sezione 5.3 | aggiungere la fase 6 (documenti sui condensatori commutati, `init.m`, modelli Simscape) |
| D5 | Nome della struct dei parametri della simulazione (oggi `sl`) | `par_sim`, creata da `parametri_simulazione.m`; `par.sim` diventa `par.tempi` (sezione 5.4) | `par_caso`, senza toccare `par.sim`; oppure `parametri` |

---

## 11. Esito

Fasi 0–5 applicate il 17-10-2026 sul ramo `unificazione-notazione`, senza commit.

### 11.1 Verifiche

| Che cosa | Come | Esito |
|---|---|---|
| Codice MATLAB: pura rinomina | `mtree` sui 39 file, vecchio contro nuovo: stessa sequenza di nodi, ogni nome vecchio sempre con lo stesso nome nuovo | solo le differenze previste |
| Codice MATLAB: stessi numeri | funzioni del modello, dell'`nlmpc` e `qp_*`/`*_semplice` su due insiemi di ingressi (uno con una cella satura a SOC 1), più le simulazioni complete con `nlmpc` dello scenario A e dello scenario B (troncato a 1500 s, $p = 5$), per `nessuno`, `Jt`, `Jm`, `Jdelta` | 348 confronti, tutti identici bit per bit (`isequal`) |
| Modello Simulink: stessi numeri | le stesse funzioni e le simulazioni Simulink degli scenari A e B per i quattro casi, in batch R2026b | 182 confronti, tutti identici bit per bit |
| `checkcode` | tutti i file, vecchio contro nuovo | stessi 2 avvisi di prima, nessuno nuovo |
| Nomi vecchi | ricerca testuale nel codice, commenti compresi | restano solo `Em_LUT`, `R0_LUT`, … citati come nomi di `init.m` e la notazione dell'esempio indipendente `esempio_sensibilita_ode45.m` |
| Modello | blocchi con nome predefinito; Goto/From; posizioni; aggiornamento del diagramma | nessun nome predefinito su 240 blocchi; 33 Goto e 62 From tutti accoppiati e locali; posizioni di blocchi e linee invariate; aggiornamento senza errori |
| Documenti LaTeX | sequenza di tutti i numeri assegnati (equazioni, sezioni, tabelle) e numeri delle etichette del `.aux`, prima e dopo | identici nei tre documenti; cambia solo la pagina di alcune etichette di [L]; nessun riferimento indefinito, nessuna riga troppo larga |
| `risultati/` | rigenerati in batch su una copia del progetto (`main_E_costante`, `main_simulink`, `verifica_simulink`, `main_confronto_scarica`, `main_E_variabile`); le nuove `A_risultati.mat` e `SL_risultati.mat` confrontate con le simulazioni del codice vecchio | 8 casi su 8 identici bit per bit; sostituiti 3 `.mat` e 13 PNG, con le stesse dimensioni di prima |
| `verifica_simulink` | stampa del codice vecchio (eseguito in batch su una copia, dopo il suo `main_E_costante`) contro quella del codice nuovo | stessi numeri in tutte le colonne; cambiano solo le intestazioni (`Ts` → `Tc`, "Sforzo" → "Sforzo medio w") |

### 11.2 Differenze rispetto al piano

- **`vincoli_disuguaglianza.m`**: gli argomenti della funzione interna che assembla le derivate dei vincoli si chiamano `ds_cineq`, `dVp_cineq`, `du_cineq` e non `ds_sigma`, …: sono derivate dei vincoli, non della grandezza bilanciata. Segue la regola delle derivate della sezione 3.2.
- **`mpc_bilanciamento.m`**: la struct restituita da `nlmpcmove` si chiama `info_nlmpc`, per distinguerla dalla `info` che la funzione restituisce.
- **Tabelle stampate** dagli script `main_*` e da `verifica_simulink`: la colonna `'Sforzo medio w [A^2]'` è più larga (`%20s`), perché l'intestazione è più lunga.
- **Configurazione del modello**: oltre al tempo di fine, anche il passo fisso del solutore leggeva `sl` (`sl.Ts_integrazione`); ora è `par_sim.Tint`. La sezione 6.6 non lo elencava: l'ha trovato la verifica in batch, dove `sl` non esiste.
- **Note del modello**: tre testi sono stati accorciati (per esempio "L di/dt = V_pacco - R i - E") perché le note non si allargassero; alcune note di formule sono un po' più strette e due un po' più alte (3 e 13 px), come la nota principale (13 px). Gli angoli in alto a sinistra delle note, i blocchi e le linee non si sono spostati.
- **[L]**: la grandezza generica della regola di Eulero, $z$, è diventata $\xi$, perché $z$ è riservata alle incognite del QP; la tabella delle grandezze discrete ha una riga per le sensibilità di $s$ e $V_p$ e una per quella di $y$; l'istruzione di $d_j$ è un blocco a sé, come quella di $\beta_j$; due tabelle sono in corpo più piccolo per non uscire dal margine. Nella tabella della sezione 9 il blocco `Cella_nominale` rimanda a `cella_nominale_semplice.m`, la funzione che chiama davvero, come il commento del blocco (sezione 6.4).
- **[Q]**: il vincolo doppio d'esempio $l \le z_i \le h$ è diventato $z_{\min} \le z_\ell \le z_{\max}$, per non avere $l$ accanto a $\ell$; $H_{ee}$ è $H_{\varepsilon_y\varepsilon_y}$; $z_{iniz}$ è scritto $z_{\mathrm{iniz}}$.
- **[P]**: anche la "regola di lettura" usa gli indici $\ell$, come [Q].
- **README di `MPC_Range_Extension`**: oltre ai nomi, descrive i blocchi che esistono oggi (`Modello_cella`, `Campionamento_misure`, `Mossa_precedente`, i blocchi di arresto, `Vista_corrente_pacco`) al posto di `Pacco_batteria`, `Campiona_*` e `Cedimento`, che non esistevano più.
- **`risultati/throughput.mat`** non è stato rigenerato: contiene solo `t_ms`, `orizzonti` e `tipi`, nomi che non cambiano, e una nuova misura dei tempi di calcolo darebbe numeri diversi.
- **Scenari A e B in `risultati/`**: le `.mat` e i PNG salvati prima della rinomina venivano da una configurazione superata ($N = 5$, $T_c = 1$ s, $p = 5$; 2378 s senza controllo nello scenario A), non da quella di `init_parametri.m` ($N = 3$, $T_c = 20$ s, $p = 30$), a cui già si riferiva il README. Rigenerati, mostrano i risultati della configurazione attuale, e per questo cambiano numeri e curve, non per la rinomina: scenario A 8640 s senza controllo e 8120 s con l'MPC ($-6\%$, come nella tabella del README); scenario B fermo al tempo massimo, 21580 s, in tutti i casi. `SL_risultati.mat` era già della configurazione attuale: differisce dalla vecchia per poco (SOC fino a $9\cdot10^{-5}$, $u$ fino a $10^{-13}$ A), ma le stesse differenze ci sono tra la vecchia e il codice vecchio rieseguito oggi, quindi vengono da prima della rinomina.
- **Figure rigenerate in batch**: nella sessione batch `exportgraphics` si blocca (graphics timeout). Le figure sono state salvate come `.fig` ed esportate in PNG nella sessione MATLAB, con le opzioni degli script (150 dpi) e alla dimensione scritta in `grafico_celle`, `grafico_scarica` e `grafico_confronto`, perché lo schermo (864 px di altezza) le aveva tagliate. I PNG di Simulink sono uguali ai vecchi salvo le etichette rinominate (per esempio "Corrente di pacco $i_{pacco}$").

### 11.3 Rimasto fuori

- **Fase 6** (documenti sui condensatori commutati, `init.m`, modelli Simscape), come deciso in D4.
- **Correzioni di contenuto** della sezione 9, da fare a parte se servono:
  - le funzioni di avvio del modello cercano ancora `Bilanciamento_MPC` per nome, quindi la copia R2024b aperta da sola non crea `par_sim`;
  - [L] cita `Predizione_linearizzata_blocchi.slx`, che non esiste più, e sono sotto controllo di versione la sua cache (`Predizione_linearizzata_blocchi.slxc` e `slprj/sim/varcache/Predizione_linearizzata_blocchi/`) e `Bilanciamento_MPC.slxc`;
  - `Variabilita_tra_Celle_MPC.md` riporta numeri e codice per $N = 5$, mentre `init_parametri.m` ha $N = 3$ (anche prima della rinomina);
  - i collegamenti di `Analisi_Modello_Simulink_e_Parametri.md` verso `init.m` e `Balancing_Attivo.slx`.
- **Copia di sicurezza** del modello prima della rinomina: `simulink/Bilanciamento_MPC_copia_prima_di_rinomina.slx` (esclusa da git).
