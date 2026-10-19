# Notazione

Dizionario dei simboli e dei nomi dell'MPC di bilanciamento attivo. Vale per:

- il paper di Chen, Behal e Li, *Active Cell Balancing by Model Predictive Control for Real Time Range Extension*, IEEE CDC 2021 (`BMS/`);
- i documenti [`Linearizzazione_MPC.pdf`](Linearizzazione_MPC.pdf) [L], [`Problema_QP_MPC.pdf`](Problema_QP_MPC.pdf) [Q], [`Passaggi_formulazione_MPC.pdf`](Passaggi_formulazione_MPC.pdf) [P] e [`Variabilita_tra_Celle_MPC.md`](Variabilita_tra_Celle_MPC.md);
- il codice MATLAB di [`SIMULATION/MPC_Range_Extension/`](../SIMULATION/MPC_Range_Extension/) e il modello `simulink/Bilanciamento_MPC.slx`.

È l'unico posto in cui un simbolo è definito, e ogni simbolo ha **un solo significato**. I documenti sui condensatori commutati (`01_…`–`07_…`, `Guida_…`, `Analisi_…`) non sono ancora allineati: la proposta per loro è nella sezione 4.7 di [`Piano_Unificazione_Notazione.md`](Piano_Unificazione_Notazione.md), che contiene anche la corrispondenza con i nomi usati fino al 17-10-2026.

---

## 1. Regole

### 1.1 Che cosa fa fede

1. Il paper, per tutti i simboli che definisce.
2. [L], dove precisa o corregge il paper.
3. Questo file, per i simboli che il paper e [L] non definiscono.

### 1.2 Dal simbolo al nome nel codice

Vale per variabili, argomenti delle funzioni e dei blocchi MATLAB Function, campi delle struct e nomi delle linee di segnale Simulink.

| Regola | Esempi |
|---|---|
| Lettera latina: invariata | $s$ → `s`, $y$ → `y`, $u$ → `u`, $N$ → `N`, $H$ → `H` |
| Correnti: nome per esteso | $i$ → `i_pacco`, $I^n$ → `I_cella` |
| Pedice che fa parte del nome: attaccato | $V_{oc}$ → `Voc`, $R_o$ → `Ro`, $V_p$ → `Vp`, $T_c$ → `Tc`, $T_{int}$ → `Tint` |
| Pedice descrittivo o di istante: con `_` | $y_{\min}$ → `y_min`, $u_{\max}$ → `u_max`, $i_k$ → `i_pacco_k`, $\kappa_{int}$ → `kappa_int` |
| Lettera greca: per esteso | $\alpha$ → `alfa`, $\beta$ → `beta`, $\zeta$ → `zeta`, $\tau$ → `tau`, $\kappa$ → `kappa`, $\eta$ → `eta`, $\rho$ → `rho`, $\sigma$ → `sigma`, $\varphi$ → `phi`, $\delta$ → `delta`, $\varepsilon$ → `epsilon` (mai `eps`, che è una funzione di MATLAB) |
| Barra (punto di linearizzazione): `_bar` | $\bar u$ → `u_bar`, $\bar Y$ → `Y_bar` |
| Apice descrittivo: `_` + apice | $Y^{lib}$ → `Y_lib`; $s^{tab}$ → `s_tab`, e allo stesso modo `Voc_tab`, `Ro_tab`, `Rp_tab`, `Cp_tab` |
| Apice 0 (cella nominale): `0` attaccato | $y^0$ → `y0`, $s^0$ → `s0`, $\sigma^0$ → `sigma0` |
| Derivata: `d` + variabile di derivazione + `_` + grandezza | rispetto al SOC $C_p' = dC_p/ds$ → `ds_Cp`; rispetto al tempo $\dot V_p$ → `dt_Vp`; rispetto alla corrente di bilanciamento $\partial y/\partial u$ → `du_y` |
| Matrice $p \times N$ e suo valore a un passo | $d_{j,n}$ → `d(j, n)`; per una cella al passo $j$ → `d_j` (allo stesso modo `alfa(j, n)`, `alfa_j`) |
| Grandezza senza simbolo: italiano snake_case | `durata`, `energia`, `motivo`, `esito`, `t_calcolo`; $\min_n y^n$ → `tensione_minima` |

Suffissi riservati: `0` solo per la cella nominale; `_iniziale` per i valori iniziali; `_next` per lo stato a fine passo; `pos_` per la posizione di un'incognita nel vettore $z$. Restano i nomi imposti da MATLAB e dai toolbox (`nlobj.Ts`, gli argomenti `X`, `U`, `data` delle funzioni `nlmpc`, gli argomenti di `quadprog`).

### 1.3 Etichette e blocchi Simulink

- Etichette Goto/From e porte dei sottosistemi: descrizione in italiano, snake_case minuscolo (le sigle restano maiuscole, `SOC`), niente camelCase.
- Plurale per i vettori con un valore per cella (`tensioni_celle`), singolare per le grandezze del pacco (`corrente_pacco`).
- Una sola etichetta per segnale in tutto il modello; la porta di un sottosistema ha lo stesso nome dell'etichetta del segnale che la attraversa.
- Blocchi: descrizione italiana con l'iniziale maiuscola (`Tensione_cella`, `Memoria_SOC`), mai nomi predefiniti. I Goto si chiamano `Goto_<etichetta>`, i From `From_<etichetta>` o `From_<etichetta>_<uso>`.
- Il nome descrittivo sta sulle etichette e sulle porte; il simbolo sulle linee di segnale e negli argomenti dei blocchi MATLAB Function, che sono codice.

### 1.4 Lettere riservate

| Lettera | Significato unico | Da non usare per |
|---|---|---|
| $n = 1,\dots,N$ | cella | — |
| $k$ | istante di controllo attuale; $K$ numero di passi di una simulazione | indici di scenari o di griglie |
| $j = 1,\dots,p$ | passo lungo l'orizzonte | indici generici |
| $i$ | corrente di pacco | indici di tratto o di componente |
| $t$ | tempo | indice della formulazione (si usa $n_J$) |
| $\zeta$ | stato della cella o del pacco | — |
| $w$ | sforzo di bilanciamento | — |
| $e$ | nessun significato: né il rilassamento ($\varepsilon_y$) né lo sforzo ($w_k$) | — |
| $E$ | f.e.m. del carico | coefficienti di sensibilità |
| $R$ | resistenza del carico | matrice di peso (è $\rho I_N$) |
| $\alpha$, $\beta$, $d$ | coefficienti di sensibilità di $s$, $V_p$, $y$ | — |
| $\ell$ | tratto di una tabella; indice di componente nei richiami sul QP | — |
| $q$ | riga della matrice $A$ | — |

### 1.5 Differenze dal paper

| Paper | Progetto | Perché |
|---|---|---|
| $T_s$ | $T_c$ (passo di controllo) e $T_{int}$ (passo di integrazione) | il modello Simulink ha due passi |
| $i^n$ (corrente della cella) | $I^n = i + u^n$ | $i^n_k$ e $i_k$ si confondono |
| $y_k = \sum_n y^n_k$ (tensione di pacco) | $V_{pacco}$ | $y$ resta la tensione di una cella |
| $\underline{y}$ | $y_{\min}$ | — |
| $e_k = u_k^\top u_k$, $\bar e$ (sforzo) | $w_k$, $\bar w$ | $e$ si confonde con $\varepsilon_y$ e con la costante di Nepero |
| $R$ (matrice di peso) | $\rho\, I_N$ | un peso unico; $R$ resta la resistenza del carico |
| $\sigma^0_{k+1}$ nell'eq. 7 | $\sigma^0_{k+j}$ | refuso del paper |
| $f^n$, $g^n$ | $f$, $g$ con l'indice di cella sottinteso | come in [L] |

Eccezione accettata: $f$ è sia la funzione di stato $f(\zeta, I)$ sia il termine lineare del QP (convenzione di `quadprog`); la funzione compare sempre con gli argomenti.

---

## 2. Dizionario

### 2.1 Indici, dimensioni e tempi

| Simbolo | Significato | Codice | Simulink |
|---|---|---|---|
| $n$, $N$ | cella, numero di celle | `n`, `N`, `par.pacco.N`, `pacco.N` | — |
| $k$, $K$ | istante attuale, numero di passi | `k`, `K` | — |
| $j$, $p$ | passo lungo l'orizzonte, orizzonte | `j`, `p`, `par.mpc.p` | — |
| $p_{rif}$ | orizzonte a cui sono riferiti i pesi | `par.mpc.p_rif` | — |
| $T_c$ | passo di controllo [s] (= $T_s$ del paper) | `Tc`, `par.mpc.Tc`, `par_sim.Tc` | — |
| $T_{int}$ | passo di integrazione del modello fisico [s] | `Tint`, `par.tempi.Tint`, `par_sim.Tint` | — |
| $t$ | tempo [s] | `t` | — |
| $n_z$, $n_\varepsilon$, $n_{dis}$ | numero di incognite, di variabili ausiliarie, di vincoli di disuguaglianza del QP | `n_z`, `n_epsilon`, `n_dis` | — |
| $pN$ | righe di un blocco di vincoli | `n_blocco` | — |
| $n_J$ | formulazione: 1 = $J_t$, 2 = $J_m$, 3 = $J_\Delta$ | `n_J`, `par_sim.n_J` | — |
| — | formulazione o assenza di controllo, come testo | `tipo`: `'nessuno'`, `'Jt'`, `'Jm'`, `'Jdelta'` | — |

### 2.2 Cella

| Simbolo | Significato | Codice | Simulink |
|---|---|---|---|
| $s^n$ | stato di carica (SOC) [-] | `s` | `SOC_celle` |
| $V^n_p$ | tensione di polarizzazione [V] | `Vp` | `tensioni_polarizzazione` |
| $\zeta^n = (s^n, V^n_p)$; $\zeta$ per il pacco | stato della cella e del pacco (eq. 3–4) | `zeta`; il vettore del pacco è `[s; Vp]`, prima tutti i SOC e poi tutte le $V_p$ | — |
| $y^n$ | tensione ai morsetti [V] | `y` | `tensioni_celle` |
| $I^n = i + u^n$ | corrente della cella, positiva in scarica [A] | `I_cella` | `correnti_celle`, linea `I_cella` |
| $V_{oc}(s)$ | tensione a vuoto [V] | `Voc` | `tensioni_a_vuoto` |
| $R_o(s)$ | resistenza serie [Ω] | `Ro` | `resistenze_serie`, linea `Ro` |
| $R_p(s)$ | resistenza di polarizzazione [Ω] | `Rp` | `resistenze_polarizzazione` |
| $C_p(s)$ | capacità di polarizzazione [F] | `Cp` | `capacita_polarizzazione` |
| $\tau = R_p C_p$ | costante di tempo del ramo RC [s] | `tau` | `costanti_di_tempo` |
| $C^n$ | capacità della cella [Ah] | `C` | — |
| $\eta$ | rendimento coulombico [-] | `eta` | — |
| $\kappa^n = \eta T_c / (3600\, C^n)$ | SOC perso in un passo di controllo per ampere [1/A] | `kappa` | — |
| $\kappa^n_{int} = \eta T_{int} / (3600\, C^n)$ | lo stesso sul passo di integrazione | `kappa_int` | — |
| $P' = dP/ds$ | derivata di un parametro rispetto al SOC | `ds_Voc`, `ds_Ro`, `ds_Rp`, `ds_Cp`, `ds_tau`; in una struct `ds.Voc`, `ds.Ro`, … | — |
| $s^{tab}_\ell$, $\ell = 1,\dots,7$ | punti di SOC delle tabelle | `s_tab` | — |
| $P^{nom}_\ell$ | valori nominali del parametro $P$ nei punti $s^{tab}_\ell$ | `Voc_tab`, `Ro_tab`, `Rp_tab`, `Cp_tab`; generico `P_tab` | — |
| $m_\ell$ | pendenza del tratto $\ell$ della tabella nominale | `m` | — |
| $\varphi^n_P$ | fattore di deviazione del parametro $P$ della cella $n$: $P^n(s) = \varphi^n_P\, P^{nom}(s)$ | `phi.Voc`, `phi.Ro`, `phi.Rp`, `phi.Cp`, `phi.C` | — |
| $\delta_P$ | deviazione massima relativa di $P$: $\varphi^n_P \in [1-\delta_P,\ 1+\delta_P]$ | `delta.Voc`, … , `delta.C` | — |

### 2.3 Pacco, carico e simulazione

| Simbolo | Significato | Codice | Simulink |
|---|---|---|---|
| $i$, $i_k$ | corrente di pacco, positiva in scarica [A] | `i_pacco` (`i_pacco_k` nel codice da leggere) | `corrente_pacco`, linea `i_pacco` |
| $u^n_k$, $u_k$ | corrente di bilanciamento della cella $n$ scelta all'istante $k$, positiva se il bilanciatore preleva carica [A]; vettore delle $N$ correnti | `u` | `correnti_bilanciamento`, linea `u` |
| $V_{pacco} = \sum_n y^n$ | tensione di pacco [V] | `V_pacco` | `tensione_pacco`, linea `V_pacco` |
| $\min_n y^n$ | tensione della cella più bassa [V] | `tensione_minima` | `tensione_minima` |
| $y_{\min}$ | tensione minima ammessa [V] | `y_min` | — |
| $u_{\min}$, $u_{\max}$ | limiti della corrente di bilanciamento [A] | `u_min`, `u_max` | — |
| $R$, $L$, $E(t)$ | resistenza, induttanza, f.e.m. del carico | `R`, `L` (in `par.carico`), `E` | `fem_carico`, linea `E` |
| — | istanti della tabella di $E$ | `t_E` | — |
| $R_{tot}$, $V_{int}$, $i_{regime}$ | resistenza della maglia, tensione di pacco a corrente nulla, corrente di regime | `R_tot`, `V_int`, `i_pacco_regime` | — |
| — | valori iniziali | `s_iniziale`, `Vp_iniziale`, `i_pacco_iniziale` | — |
| — | stato a fine passo | `s_next`, `Vp_next`, `i_pacco_next`, `zeta_next` | — |
| — | SOC perso in un passo | `consumed_soc` | — |

### 2.4 Predizione e linearizzazione

| Simbolo | Significato | Codice | Simulink |
|---|---|---|---|
| $\sigma \in \{s, y\}$ | grandezza bilanciata | `par.mpc.sigma` (`'y'` o `'s'`), `par_sim.sigma_tensione` | — |
| $y^0_{k+j}$, $s^0_{k+j}$, $V^0_p$ | tensione, SOC e polarizzazione della cella nominale | `y0`, `s0`, `Vp0` | — |
| $\sigma^0_{k+j}$ | riferimento di $J_t$: la grandezza bilanciata della cella nominale | `sigma0` | `riferimento_nominale`, linea `sigma0` |
| $\bar u^n = u^n_{k-1}$ | mossa precedente, punto di linearizzazione | `u_bar` | `correnti_bilanciamento_precedenti` |
| $y^n_{k+j}$, $s^n_{k+j}$ | tensione e SOC predetti; matrici $p \times N$ | `Y`, `S` (in `nlmpc`) | — |
| $\bar Y_{j,n}$, $\bar S_{j,n}$ | traiettoria di linearizzazione | `Y_bar`, `S_bar` | — |
| $\alpha_{j,n}$, $\beta_{j,n}$, $d_{j,n}$ | coefficienti di sensibilità di SOC, tensione di polarizzazione e tensione ai morsetti: derivate rispetto alla corrente della cella $n$ al passo $j$; a tempo continuo $\alpha(t)$, $\beta(t)$, $d(t)$ | matrici `alfa`, `d`; a un passo `alfa_j`, `beta_j`, `d_j` | — |
| $d^\sigma$, $\bar\Sigma$, $\Sigma^{lib}$ | le stesse quantità per la grandezza bilanciata ($d$ o $\alpha$, $\bar Y$ o $\bar S$, …) | `d_sigma`, `Sigma_bar`, `Sigma_lib` | — |
| $1/\tau$, $1/C_p$ e derivate | grandezze di comodo di `qp_predizione.m` | `inv_tau`, `inv_Cp`, `ds_inv_tau`, `ds_inv_Cp` | — |
| $Y^{lib}_{j,n}$, $S^{lib}_{j,n}$ | risposta libera: la retta in $u^n_k = 0$ | `Y_lib`, `S_lib` | — |
| $c_{j,n} = Y^{lib}_{j,n} - y^0_{k+j}$ | scarto dal riferimento | `c` | — |

### 2.5 Problema quadratico

| Simbolo | Significato | Codice | Simulink |
|---|---|---|---|
| $J_t$, $J_m$, $J_\Delta$ | i tre costi (eq. 7, 8, 11) | `'Jt'`, `'Jm'`, `'Jdelta'` | — |
| $\rho$ | peso sulle correnti ($R = \rho I_N$), $\rho = \rho_{rif}\, p / p_{rif}$ | `rho`, `par_sim.rho` | — |
| $\rho_{rif}$ | peso riferito a $p_{rif}$, uno per formulazione | `par.mpc.Jt`, `par.mpc.Jm`, `par.mpc.Jdelta` | — |
| $W$ | peso su $\varepsilon_y$ | `W`, `par.mpc.W` | — |
| $\varepsilon_j$ | variabili ausiliarie del costo: minoranti ($j \le p$), maggioranti ($p < j \le 2p$) | `epsilon` | — |
| $\varepsilon_y$ | variabile di rilassamento del vincolo di tensione (eq. 17) | `epsilon_y` | `rilassamento_tensione`, linea `epsilon_y` |
| $z = [u_k;\ \varepsilon;\ \varepsilon_y]$ | incognite del QP | `z` | — |
| $H$, $f$, $A$, $b$, $A_{eq}$, $b_{eq}$ | dati del QP | `H`, `f`, `A`, `b`, `Aeq`, `beq` | — |
| $z_{iniz}$ | punto di partenza del solutore | `z_iniziale` | — |
| — | posizione di un'incognita in $z$ | `pos_u`, `pos_epsilon_y` | — |
| — | esito del solutore | `esito` | `esito_solutore`, linea `esito` |
| $\mathcal{D}$, $\mathcal{P}$, $y^{lib}$ | blocchi della matrice $A$ e risposte libere in colonna ([Q] sez. 8.4) | — | — |
| $\ell$, $\ell'$ | indici di componente nei richiami sul QP | — | — |

### 2.6 Risultati di una simulazione (struct `ris`)

| Simbolo | Significato | Campo | Linea registrata in Simulink |
|---|---|---|---|
| $t$, $s$, $V_p$, $y$, $u$, $E$ | storie temporali | `t`, `s`, `Vp`, `y`, `u`, `E` | `s`, `Vp`, `y`, `u`, `E` |
| $i$ | corrente di pacco | `i_pacco` | `i_pacco` |
| $w_k = u_k^\top u_k = \sum_n (u^n_k)^2$ | sforzo di bilanciamento [A²] (nel paper $e_k$) | `w` | `w` |
| $\bar w = \frac1K \sum_k w_k$ | sforzo medio [A²] | `w_medio` | — |
| $\sigma^0$ | riferimento della cella nominale | `sigma0` | `sigma0` |
| $\varepsilon_y > 0$ | vincolo di tensione rilassato | `morbido` | da `epsilon_y` |
| — | esito del solutore, durata, energia ceduta alla f.e.m., motivo dell'arresto, formulazione, orizzonte, tempo di calcolo | `esito`, `durata`, `energia`, `motivo`, `tipo`, `p`, `t_calcolo` | `esito` |

### 2.7 Struct dei parametri

| Struct | Che cos'è | Campi |
|---|---|---|
| `par` | tutti i parametri liberi del progetto (`init_parametri.m`) | `cella`, `pacco`, `mpc`, `carico`, `scenarioA`, `scenarioB`, `tempi`, `throughput` |
| `par.cella` | cella nominale | `temperatura`, `s_tab`, `Voc_tab`, `Ro_tab`, `Rp_tab`, `Cp_tab`, `C`, `eta` |
| `par.pacco` | pacco e variabilità tra le celle | `N`, `s_iniziale`, `delta.{Voc, Ro, Rp, Cp, C}`, `seme_casuale` |
| `par.mpc` | bilanciatore e MPC | `Tc`, `p`, `sigma`, `u_min`, `u_max`, `y_min`, `Jt`, `Jm`, `Jdelta`, `p_rif`, `W` |
| `par.carico` | carico R–L–E | `R`, `L`, `i_pacco_iniziale` |
| `par.scenarioA`, `par.scenarioB` | f.e.m. del carico | `t_E`, `E` (`orizzonti` nello scenario B) |
| `par.tempi` | tempi della simulazione | `t_max`, `Tint` |
| `pacco` | le celle estratte (`genera_pacco.m`) | `N`, `phi.{Voc, Ro, Rp, Cp, C}`, `s_tab`, `Voc_tab`, `Ro_tab`, `Rp_tab`, `Cp_tab`, `C`, `eta`, `nominale` |
| `par_sim` | i numeri di **una** simulazione del modello Simulink (una formulazione, uno scenario, un orizzonte), ricavati da `par` (`parametri_simulazione.m`): sono parametri, non variabili della simulazione | `N`, `p`, `Tc`, `Tint`, `n_J`, `attivo`, `sigma_tensione`, `u_min`, `u_max`, `y_min`, `rho`, `W`, `n_epsilon`, `n_z`, `n_dis`, `pacco` e `nominale` (`s_tab`, `*_tab`, `phi`, `kappa`), `kappa_int`, `s_iniziale`, `Vp_iniziale`, `i_pacco_iniziale`, `carico.{R, L, t_E, E, periodo}`, `t_fine` |

---

## 3. Le parole

| Usare | Al posto di |
|---|---|
| SOC | SoC, soc |
| tensione a vuoto | OCV, tensione a circuito aperto |
| resistenza serie; resistenza e capacità di polarizzazione; ramo RC di polarizzazione | $R_0$, $R_1$, $C_1$ |
| corrente di pacco, corrente di cella, corrente di bilanciamento | $I_{load}$, "corrente comune" |
| passo di controllo, passo di integrazione | "passo" senza specificare |
| cella nominale; traiettoria della cella nominale ($\sigma^0$) | "traiettoria nominale" |
| traiettoria di linearizzazione ($\bar Y$, $\bar S$) | "traiettoria nominale" |
| mossa precedente ($\bar u = u_{k-1}$) | "bilanciamento al passo precedente" |
| coefficienti di sensibilità $\alpha$, $\beta$, $d$ | "pendenze" |
| risposta libera, risposta forzata | "parte che non dipende da $u$" |
| variabili ausiliarie del costo (minoranti, maggioranti) | slack del costo |
| variabile di rilassamento del vincolo di tensione ($\varepsilon_y$) | slack |
| sforzo di bilanciamento ($w_k$), sforzo medio ($\bar w$) | "sforzo $e$" |
| fattore di deviazione ($\varphi$), deviazione massima ($\delta$) | fattore $f$, fattore $k$ |
| f.e.m. del carico | "E" senza specificare |
| formulazione ($J_t$, $J_m$, $J_\Delta$; $n_J$) | tipo |
| esito del solutore | flag, exitflag |
