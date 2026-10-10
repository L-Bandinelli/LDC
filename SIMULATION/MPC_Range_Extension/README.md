# MPC per il bilanciamento attivo — simulazione MATLAB

Codice MATLAB che simula il problema del paper
*J. Chen, A. Behal, C. Li, "Active Cell Balancing by Model Predictive Control for Real Time Range Extension", IEEE CDC 2021*
(`DOCUMENTS/BMS/`), con la cella dei modelli Simulink di `SIMULATION/`.

Servono MATLAB, Model Predictive Control Toolbox (`nlmpc`) e Optimization Toolbox (`fmincon`, usato da `nlmpc`). Simulink non serve.

La stessa simulazione esiste anche come modello Simulink, in `simulink/`: vedi [Modello Simulink](#modello-simulink). Lì bastano Simulink e Optimization Toolbox (`quadprog`).

## Come si esegue

Dalla cartella `MPC_Range_Extension`:

| Script | Cosa fa | Durata |
|---|---|---|
| `main_E_costante` | Scenario A: f.e.m. costante. Tabella delle durate, figure di celle e confronto | ~15 s |
| `main_E_variabile` | Scenario B: f.e.m. a gradini. Tabella per `p = 5, 10, 15`, figure | ~20 s |
| `main_throughput` | Tempo di calcolo di un passo MPC per `p = 5, 35` | ~10 s |

Tabelle a schermo; figure e dati in `risultati/`. Tutti i parametri sono in `init_parametri.m`.

## File

| File | Contenuto | Paper |
|---|---|---|
| `init_parametri.m` | Tutti i parametri: cella a 20 °C, pacco, MPC, carico, scenari | — |
| `modello/genera_pacco.m` | N celle con parametri deviati casualmente | Sez. IV |
| `modello/parametri_cella.m` | `V_vuoto`, `R_serie`, `R_pol`, `C_pol` al SOC corrente, con derivate | — |
| `modello/modello_cella.m` | Tensione di cella e stato (SOC, `V_pol`) dopo un passo | eq. (2a)-(2c) |
| `modello/carico_rle.m` | Corrente di pacco con carico R–L–E | — |
| `mpc/crea_mpc.m` | Oggetto `nlmpc` per `Jt`, `Jm`, `Jdelta`: stati, variabili manipolate, limiti, costo e vincoli | eq. (6) |
| `mpc/mpc_bilanciamento.m` | Un passo di controllo con `nlmpcmove` | eq. (6) |
| `mpc/stato_pacco.m` | Funzione di stato del modello di predizione | eq. (4a), (6b) |
| `mpc/predizione_uscite.m` | Tensioni e SOC predetti sull'orizzonte | eq. (6c) |
| `mpc/costo_bilanciamento.m` | Funzione di costo delle tre formulazioni | eq. (7), (9), (12), (17) |
| `mpc/vincoli_disuguaglianza.m` | Vincolo di tensione e vincoli sulle slack | eq. (6e), (10), (13), (17) |
| `mpc/vincolo_somma.m` | Somma nulla delle correnti di bilanciamento | eq. (6f) |
| `mpc/jacobiano_stato.m` | Derivate della funzione di stato | Remark 3 |
| `mpc/traiettoria_nominale.m` | Riferimento della cella nominale | eq. (7) |
| `simulazione/simula_pacco.m` | Anello chiuso fino al cedimento | eq. (5) |
| `simulazione/profilo_E.m` | F.e.m. del carico nel tempo | — |
| `grafici/` | Figure e colori | Fig. 2–5 |

## Modello

- **Cella**: circuito equivalente a un ramo RC, stato `[s; V_p]`, parametri funzione del SOC. Corrente positiva = scarica.
- **Bilanciatore**: ideale, una corrente `u^n` per cella con `Σ u^n = 0` e `|u^n| ≤ 2 A`. La corrente della cella `n` è `i + u^n`. Rispetto a `Modello_semplificato.slx`, `u^n = −I_bal,n`.
- **Carico**: `R`, `L` e f.e.m. `E(t)` in serie al pacco, `L·di/dt = V_pacco − R·i − E`. Con `E > V_pacco` la corrente è negativa e ricarica il pacco. L'MPC misura `i` e la tiene costante sull'orizzonte.
- **Cedimento**: la simulazione si ferma quando una cella scende sotto `y_min`.

## Modello Simulink

`simulink/Bilanciamento_MPC.slx` è lo stesso anello chiuso di `simula_pacco.m`, disegnato a blocchi: ogni blocco porta sotto il nome l'equazione del paper che realizza. È diviso in tre parti (modello fisico, controllo, visualizzazione) e i segnali viaggiano con coppie Goto/From dai nomi descrittivi. Salvato con R2026b.

### Come si esegue

| Cosa | Come |
|---|---|
| Aprire e simulare a mano | Aprire `Bilanciamento_MPC.slx` e premere Run. All'apertura il modello crea da solo la struct `sl` con i parametri di `init_parametri.m`, `J_t` e scenario A |
| Cambiare formulazione, scenario o orizzonte | Modificare le prime righe di `avvio_simulink.m` ed eseguirlo, poi Run |
| Confronto dei quattro casi (stile Tabella I) | `main_simulink`: tabella a schermo, figure `risultati/SL_*.png` |
| Controllo contro il codice MATLAB | `verifica_simulink`: riesegue i casi di `risultati/A_risultati.mat` e stampa le differenze |

`simula_simulink(tipo, pacco, par, scen, p)` ha gli stessi ingressi e la stessa uscita di `simula_pacco`: le funzioni in `grafici/` funzionano con entrambe.

### Struttura

Il livello principale ha tre parti, collegate solo da Goto/From: due sottosistemi e, accanto, i blocchi di visualizzazione.

| Parte | Contenuto | Legge | Fornisce |
|---|---|---|---|
| `Modello_fisico` | Carico, celle in serie, cedimento del pacco: eq. (1)-(5) | `correnti_bilanciamento` | `corrente_pacco`, `SOC_celle`, `tensioni_polarizzazione`, `tensioni_celle`, `tensione_minima` |
| `Controllo` | MPC di bilanciamento: eq. (6)-(17) | `SOC_celle`, `tensioni_polarizzazione`, `corrente_pacco` | `correnti_bilanciamento`, `slack_tensione`, `riferimento_nominale`, `esito_solutore` |
| Visualizzazione (blocchi al livello principale) | Scope e grandezze derivate, senza effetto sulla simulazione | tutti i segnali sopra tranne `tensioni_polarizzazione` e `corrente_pacco` | — |

**`Modello_fisico`**

| Blocco | Cosa fa | Paper | File MATLAB corrispondente |
|---|---|---|---|
| `Profilo_E`, `Carico_RLE` | F.e.m. del carico e corrente di pacco `i` | — | `profilo_E.m`, `carico_rle.m` |
| `Mantieni_bilanciamento` | Tiene costanti le correnti di bilanciamento tra due passi di controllo | — | — |
| `Corrente_cella` | Corrente di ogni cella, `i + u^n` | eq. (3) | — |
| `Pacco_batteria` | Le N celle: SOC, ramo RC, tensione, fatti con blocchi elementari | eq. (2a)-(2c), (4a) | `modello_cella.m` |
| `Pacco_batteria/Parametri_cella` | Tabelle di `V_oc`, `R_o`, `R_p`, `C_p` in funzione del SOC, per il fattore di ogni cella | — | `parametri_cella.m` |
| `Tensione_pacco` | Somma delle tensioni di cella | eq. (4b) | — |
| `Cedimento` | Ferma la simulazione quando una cella scende sotto `y_min` (o il SOC si esaurisce) | eq. (5) | `simula_pacco.m` |

**`Controllo`**: un passo dell'MPC è la catena

| Blocco | Cosa fa | Paper | Codice |
|---|---|---|---|
| `Campiona_SOC`, `Campiona_polarizzazione`, `Campiona_corrente` | Leggono le misure a ogni passo di controllo | — | — |
| `Cella_nominale` | Riferimento `σ⁰`: la cella nominale integrata su `p` passi dalla media degli stati | eq. (7) | `qp_cella_nominale.m` |
| `Predizione_linearizzata` | Tensioni e SOC delle celle su `p` passi con `u = u_{k-1}`, e loro derivate rispetto a `u` | eq. (6b)-(6c), Remark 3 | `qp_predizione.m`, `qp_tabella.m` |
| `Problema_QP` | Matrici `H`, `f`, `A`, `b`, `Aeq`, `beq` del QP nelle incognite `z = [u; ε; e]` | eq. (7), (9), (12); (6d)-(6f), (10), (13), (17) | `qp_problema.m` |
| `Solutore_QP` | `quadprog`; al pacco vanno solo le `N` correnti `u` | Sez. IV-A | `qp_solutore.m` |
| `Bilanciamento_attivo` | Guadagno 0 o 1 (`sl.attivo`): con 0 il pacco lavora senza bilanciamento | — | `tipo = 'nessuno'` |

**Visualizzazione**

| Blocco | Cosa mostra | Paper |
|---|---|---|
| `Celle_Fig2` | Tensioni, SOC e correnti di bilanciamento di ogni cella | Fig. 2 |
| `Confronto_Fig3` | Tensione della cella più bassa e sforzo `e_k = u_k'·u_k` (quadrato e somma degli elementi) | Fig. 3 |
| `MPC_interno` | Slack del vincolo di tensione, esito di `quadprog`, riferimento `σ⁰` | eq. (17), (7) |
| `Somma_u`, `Somma_u_nulla` | Verifica che la somma delle `u` resti nulla | eq. (6f) |

### Passi di tempo

Il modello ha due passi, entrambi in `init_parametri.m`:

| Parametro | Valore | Cosa regola |
|---|---|---|
| `par.sim.Ts_integrazione` | 1 s | Passo con cui avanza il modello fisico (celle e carico) e con cui si controlla il cedimento |
| `par.mpc.Ts` | 20 s | Passo di controllo: l'MPC campiona le misure, predice su `p` di questi passi e sceglie le correnti di bilanciamento, che restano costanti fino al passo successivo |

`par.mpc.Ts` deve essere un multiplo intero di `par.sim.Ts_integrazione`. Il codice MATLAB (`simula_pacco`) usa un solo passo, `par.mpc.Ts`, per entrambe le cose: per riprodurlo esattamente in Simulink basta porre `par.sim.Ts_integrazione = par.mpc.Ts`.

Scenario A con i parametri attuali (N = 3, p = 30, passo di controllo 20 s), durate in secondi:

| | Integrazione 20 s | Integrazione 1 s |
|---|---|---|
| nessuno | 8640 | 8635 |
| `J_t` | 8120 | 8115 |
| `J_m` | 8120 | 8117 |
| `J_Δ` | 8120 | 8102 |

### Differenza rispetto al codice MATLAB

Il codice MATLAB risolve a ogni passo il problema non lineare con `nlmpc`. Il modello Simulink segue il Remark 3 del paper: linearizza la predizione attorno alla mossa precedente e risolve un QP con `quadprog`. Modello, costo e vincoli sono gli stessi.

Confronto sullo scenario A con un solo passo (`Ts_integrazione = Ts`), durate in secondi:

| | `nlmpc` | Simulink | `nlmpc` | Simulink |
|---|---|---|---|---|
| | N = 5, Ts = 1 s, p = 5 | | N = 3, Ts = 20 s, p = 30 | |
| nessuno | 2378 | 2378 | 8640 | 8640 |
| `J_t` | 2529 | 2529 | 8120 | 8120 |
| `J_m` | 2478 | 2478 | 8120 | 8120 |
| `J_Δ` | 2488 | 2488 | 8120 | 8120 |

Senza bilanciamento le due simulazioni coincidono alla precisione di macchina. Con l'MPC le correnti `u` differiscono al più di 4·10⁻³ A nel primo caso e di 0.3 A, in pochi passi isolati, nel secondo (orizzonte di 600 s: la linearizzazione pesa di più); lo sforzo medio differisce di meno dello 0.2 %.

## Differenze rispetto al paper

- Il paper impone la corrente di pacco (costante, poi dal ciclo FTP). Qui la corrente nasce dal carico R–L–E; lo scenario dinamico usa una f.e.m. periodica e la metrica è la durata, con l'energia ceduta alla f.e.m. al posto della distanza.
- Il paper non riporta i valori di cella, limiti, pesi e `y_min`: quelli in `init_parametri.m` sono scelti qui. I risultati numerici non sono quindi confrontabili uno a uno con le Tabelle I–III.
- Il QP è in forma condensata (stati eliminati): `N`, `N+p`, `N+2p` variabili per `J_t`, `J_m`, `J_Δ`, contro `(2p+1)N` e oltre del paper. La soluzione è la stessa, i tempi di calcolo sono più bassi.
- Nell'eq. (7) del paper `σ⁰_{k+1}` è letto come `σ⁰_{k+j}`.
- La variabilità tra le celle è descritta in `DOCUMENTS/Variabilita_tra_Celle_MPC.md`.
