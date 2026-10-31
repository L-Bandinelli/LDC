# Versioni precedenti del modello Simulink

Modelli precedenti a `../Bilanciamento_MPC_Jt.slx`. Entrambi si chiamano `Bilanciamento_MPC.slx`, risolvono i tre costi J_t, J_m, J_Δ e sono salvati con R2026b, con una copia `Bilanciamento_MPC_2024b.slx` per le versioni precedenti di MATLAB.

| Cartella | Differenza |
|---|---|
| `v1.0` | Il codice dei blocchi MATLAB Function chiama i file `qp_*.m` e `*_semplice.m` della cartella |
| `v2.0` | Il codice di ogni blocco è tutto dentro il blocco, con i rimandi ai documenti [L] e [Q] |

Avendo lo stesso nome, v1.0 e v2.0 non si possono aprire insieme; si aprono insieme al modello principale, che ha un nome diverso. Gli script di ciascuna versione (`avvio_simulink`, `main_simulink`, `verifica_simulink`) aggiungono al path le funzioni comuni del progetto (due livelli sopra) e per ultima la propria cartella, e scrivono in `../risultati/`. Prima di aprire una versione conviene eseguire il suo `avvio_simulink`, che ricrea `par_sim`.

## Il modello v2.0

`Bilanciamento_MPC.slx` è lo stesso anello chiuso di `simula_pacco.m`, disegnato a blocchi: ogni blocco porta sotto il nome l'equazione del paper che realizza. È diviso in tre parti (modello fisico, controllo, visualizzazione) e i segnali viaggiano con coppie Goto/From dai nomi descrittivi.

### Come si esegue

| Cosa | Come |
|---|---|
| Aprire e simulare a mano | Eseguire `avvio_simulink` nella cartella della versione, poi aprire `Bilanciamento_MPC.slx` e premere Run |
| Cambiare formulazione, scenario o orizzonte | Modificare le prime righe di `avvio_simulink.m` ed eseguirlo, poi Run |
| Confronto dei quattro casi (stile Tabella I) | `main_simulink`: tabella a schermo, figure `../risultati/SL_*.png` |
| Controllo contro il codice MATLAB | `verifica_simulink`: riesegue i casi di `../risultati/A_risultati.mat` e stampa le differenze |

### Struttura

Il livello principale ha tre parti, collegate solo da Goto/From: due sottosistemi e, accanto, i blocchi di visualizzazione.

| Parte | Contenuto | Legge | Fornisce |
|---|---|---|---|
| `Modello_fisico` | Carico, celle in serie, cedimento del pacco: eq. (1)-(5) | `correnti_bilanciamento` | `corrente_pacco`, `SOC_celle`, `tensioni_polarizzazione`, `tensioni_celle`, `tensione_minima` |
| `Controllo` | MPC di bilanciamento: eq. (6)-(17) | `SOC_celle`, `tensioni_polarizzazione`, `corrente_pacco`, campionati da `Campionamento_misure` | `correnti_bilanciamento`, `rilassamento_tensione`, `riferimento_nominale`, `esito_solutore` |
| Visualizzazione (blocchi al livello principale) | Scope e grandezze derivate, senza effetto sulla simulazione | tutti i segnali sopra tranne `tensioni_polarizzazione` | — |

**`Modello_fisico`**

| Blocco | Cosa fa | Paper | File MATLAB corrispondente |
|---|---|---|---|
| `Profilo_E`, `Carico_RLE` | F.e.m. del carico `E` (segnale `fem_carico`) e corrente di pacco `i` | — | `profilo_E.m`, `carico_rle.m` |
| `Mantieni_bilanciamento` | Tiene costanti le correnti di bilanciamento tra due passi di controllo | — | — |
| `Corrente_cella` | Corrente di ogni cella, `I^n = i + u^n` (segnale `correnti_celle`) | eq. (3) | — |
| `Modello_cella` | Le N celle: SOC, ramo RC, tensione, fatti con blocchi elementari | eq. (2a)-(2c), (4a) | `modello_cella.m` |
| `Modello_cella/Parametri_cella` | Tabelle di `V_oc`, `R_o`, `R_p`, `C_p` in funzione del SOC, per il fattore di deviazione `φ` di ogni cella | — | `parametri_cella.m` |
| `Tensione_pacco` | Somma delle tensioni di cella | eq. (4b) | — |
| `Tensione_minima`, `Sotto_y_min`, `SOC_minimo`, `SOC_esaurito`, `Pacco_ceduto`, `Arresto` | Fermano la simulazione quando una cella scende sotto `y_min` (o il SOC si esaurisce) | eq. (5) | `simula_pacco.m` |

**`Controllo`**: un passo dell'MPC è la catena

| Blocco | Cosa fa | Paper | Codice in v1.0 |
|---|---|---|---|
| `Campionamento_misure` (livello principale, tra `Raccolta_misure` e `Separazione_misure`) | Campiona SOC, tensioni di polarizzazione e corrente di pacco a ogni passo di controllo `par_sim.Tc` | — | — |
| `Mossa_precedente` | Memoria della mossa precedente `ū = u_{k-1}`, punto di linearizzazione | Remark 3 | — |
| `Cella_nominale` | Riferimento `σ⁰`: la cella nominale integrata su `p` passi dalla media degli stati | eq. (7) | `cella_nominale_semplice.m` |
| `Predizione_linearizzata` | Traiettoria di linearizzazione `Y_bar`, `S_bar` su `p` passi con `u = ū`, e coefficienti di sensibilità `d`, `alfa` (derivate rispetto a `u`) | eq. (6b)-(6c), Remark 3 | `qp_predizione.m`, `qp_tabella.m` |
| `Problema_QP` | Matrici `H`, `f`, `A`, `b`, `Aeq`, `beq` del QP nelle incognite `z = [u; ε; ε_y]` e punto di partenza `z_iniziale` | eq. (7), (9), (12); (6d)-(6f), (10), (13), (17) | `qp_problema.m` |
| `Solutore_QP` | `quadprog`; al pacco vanno solo le `N` correnti `u` | Sez. IV-A | `qp_solutore.m` |
| `Bilanciamento_attivo` | Guadagno 0 o 1 (`par_sim.attivo`): con 0 il pacco lavora senza bilanciamento | — | `tipo = 'nessuno'` |

**Visualizzazione**

| Blocco | Cosa mostra | Paper |
|---|---|---|
| `Celle_Fig2` | Tensioni, SOC e correnti di bilanciamento di ogni cella | Fig. 2 |
| `Confronto_Fig3` | Tensione della cella più bassa e sforzo di bilanciamento `w_k = u_kᵀ·u_k = Σ_n (u^n_k)²`, calcolato da `Quadrato_u` e `Sforzo_bilanciamento` (nel paper `e_k`) | Fig. 3 |
| `MPC_interno` | Variabile di rilassamento `ε_y` del vincolo di tensione, esito di `quadprog`, riferimento `σ⁰` | eq. (17), (7) |
| `Somma_u`, `Somma_u_nulla` | Verifica che la somma delle `u` resti nulla | eq. (6f) |
| `Vista_corrente_pacco` | Corrente di pacco `i` | — |

### Durate con i due passi di tempo

Scenario A con i parametri attuali (N = 3, p = 30, passo di controllo 20 s), durate in secondi:

| | Integrazione 20 s | Integrazione 1 s |
|---|---|---|
| nessuno | 8640 | 8635 |
| `J_t` | 8120 | 8115 |
| `J_m` | 8120 | 8117 |
| `J_Δ` | 8120 | 8102 |

### Differenza rispetto al codice MATLAB

Il codice MATLAB (`../matlab_nlmpc/`) risolve a ogni passo il problema non lineare con `nlmpc`. Il modello Simulink segue il Remark 3 del paper: linearizza la predizione attorno alla mossa precedente e risolve un QP con `quadprog`. Modello, costo e vincoli sono gli stessi. Il QP ha `N`, `N+p`, `N+2p` variabili per `J_t`, `J_m`, `J_Δ` (più `ε_y`).

Confronto sullo scenario A con un solo passo (`Tint = Tc`), durate in secondi:

| | `nlmpc` | Simulink | `nlmpc` | Simulink |
|---|---|---|---|---|
| | N = 5, Tc = 1 s, p = 5 | | N = 3, Tc = 20 s, p = 30 | |
| nessuno | 2378 | 2378 | 8640 | 8640 |
| `J_t` | 2529 | 2529 | 8120 | 8120 |
| `J_m` | 2478 | 2478 | 8120 | 8120 |
| `J_Δ` | 2488 | 2488 | 8120 | 8120 |

Senza bilanciamento le due simulazioni coincidono alla precisione di macchina. Con l'MPC le correnti `u` differiscono al più di 4·10⁻³ A nel primo caso e di 0.3 A, in pochi passi isolati, nel secondo (orizzonte di 600 s: la linearizzazione pesa di più); lo sforzo medio `w̄`, cioè la media sui passi dello sforzo di bilanciamento `w_k = u_kᵀ·u_k`, differisce di meno dello 0.2 %.
