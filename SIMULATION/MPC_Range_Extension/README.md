# MPC di bilanciamento attivo con il costo J_t — modello Simulink

Simulazione del problema del paper
*J. Chen, A. Behal, C. Li, "Active Cell Balancing by Model Predictive Control for Real Time Range Extension", IEEE CDC 2021*
(`DOCUMENTS/BMS/`), con la cella dei modelli Simulink di `SIMULATION/`.

Il modello principale è `Bilanciamento_MPC_Jt.slx` (salvato con R2026b). Servono Simulink e Optimization Toolbox (`quadprog`).

Simboli e nomi delle variabili seguono [`DOCUMENTS/Notazione.md`](../../DOCUMENTS/Notazione.md): un solo nome per grandezza, nel paper, nei documenti, nel codice e nel modello Simulink.

## Struttura della cartella

| Cartella / file | Contenuto |
|---|---|
| `Bilanciamento_MPC_Jt.slx` | Modello principale, R2026b |
| `avvio_simulink.m`, `main_simulink.m`, `simula_simulink.m`, `parametri_simulazione.m`, `verifica_simulink.m` | Script e funzioni del modello principale (sezione [Come si esegue](#come-si-esegue)) |
| `init_parametri.m` | Tutti i parametri: cella a 20 °C, pacco, MPC, carico, scenari, passi di tempo |
| `modello/`, `mpc/`, `simulazione/`, `grafici/` | Funzioni comuni a tutte le versioni (sezione [Funzioni comuni](#funzioni-comuni)) |
| `risultati/` | Figure e dati: `Jt_*` dal modello principale, `A_*`, `B_*`, `throughput.mat` dal codice `nlmpc`, `SL_*` da `versioni_precedenti/v2.0` |
| `copia_R2025b/` | Copia del modello principale per MATLAB più vecchio di R2026b (sezione [Versioni di MATLAB](#versioni-di-matlab)) |
| `matlab_nlmpc/` | La stessa simulazione in MATLAB puro, con `nlmpc` e i tre costi J_t, J_m, J_Δ: è il riferimento di `verifica_simulink`. Vedi il suo [README](matlab_nlmpc/README.md) |
| `versioni_precedenti/` | Modelli precedenti `v1.0` e `v2.0` (`Bilanciamento_MPC.slx`, con i tre costi). Vedi il suo [README](versioni_precedenti/README.md) |

## Il modello

`Bilanciamento_MPC_Jt.slx` è lo stesso anello chiuso di `versioni_precedenti/v2.0`, ridotto al problema con la funzione obiettivo J_t (eq. 7 del paper) e con la tensione ai morsetti `y` come grandezza inseguita (σ = y). Le celle inseguono la tensione `y0` di una cella nominale:

J_t = Σ_j Σ_n (y^n_{k+j} − y^0_{k+j})² + ρ Σ_n (u^n_k)²,  più W·ε_y² per il vincolo di tensione rilassato (eq. 17).

Il modello ha un nome diverso da quello di v1.0 e v2.0, quindi si può aprire insieme a loro.

### Che cosa cambia rispetto a v2.0

| | v2.0 | Jt |
|---|---|---|
| Costi | J_t, J_m, J_Δ, scelti con `par_sim.n_J` | solo J_t |
| Grandezza inseguita | tensione o SOC (`par_sim.sigma_tensione`) | solo la tensione `y` |
| Incognite del QP | `z = [u; ε; ε_y]`, da N+1 a N+2p+1 | `z = [u; ε_y]`, N+1 |
| `Cella_nominale` | uscita `sigma0` | uscita `y0` |
| `Predizione_linearizzata` | uscite `Y_bar`, `S_bar`, `d`, `alfa` | uscite `Y_bar`, `d` (SOC e `alfa` restano calcoli interni) |
| `Problema_QP` | sei blocchi di vincoli, passi 1–5 del costo | vincolo di tensione, limiti di corrente, segno di ε_y; passi 1–3 del costo. In più la variante con il vincolo rigido (sezione seguente) |
| Segnale registrato | `sigma0` | `y0` |

Resta il caso senza bilanciamento (`tipo = 'nessuno'`, guadagno `par_sim.attivo = 0`), che serve per misurare l'estensione della durata.

Con gli stessi parametri le simulazioni coincidono con quelle di v2.0 per J_t e per il caso senza bilanciamento.

### Vincolo di tensione morbido o rigido

`Problema_QP` è un Variant Subsystem con due scelte, che hanno gli stessi ingressi e le stesse uscite:

| Scelta (etichetta) | Vincolo di tensione minima | Incognite | `tipo` negli script |
|---|---|---|---|
| `Problema_QP_morbido` (`morbido`) | y + ε_y ≥ y_min, con W·ε_y² nel costo (eq. 17) | `z = [u; ε_y]`, N+1 | `'Jt'` |
| `Problema_QP_rigido` (`rigido`) | y ≥ y_min, così com'è (eq. 6e) | `z = u`, N | `'Jt_rigido'` |

Con il vincolo rigido, verso fine scarica può non esistere nessuna corrente che rispetti tutti i vincoli: `quadprog` restituisce esito −2 e `Solutore_QP` mantiene la mossa del passo precedente. `Solutore_QP` riconosce la scelta dal numero di incognite e, con il vincolo rigido, restituisce ε_y = 0.

La scelta attiva è scritta sotto il blocco. Si cambia dal menu del blocco (Variant > Label Mode Active Choice), con `avvio_simulink` (`tipo = 'Jt_rigido'`) o, per una sola simulazione, con `simula_simulink('Jt_rigido', ...)`, che non modifica il modello.

Prove del 20-10-2026 (N = 3, p = 30, scenari A e B): le due scelte danno gli stessi risultati, perché il vincolo di tensione non entra mai in gioco. Con 5 celle (circa 37 A) il vincolo rigido non ha soluzione in 9 passi di controllo su 100, tra 1820 e 1980 s, mentre quello morbido usa ε_y > 0 da 1800 s.

## Come si esegue

| Cosa | Come |
|---|---|
| Aprire e simulare a mano | Aprire `Bilanciamento_MPC_Jt.slx` (con MATLAB più vecchio di R2026b `copia_R2025b/Bilanciamento_MPC_Jt_2024b.slx`) e premere Run: all'apertura il modello crea `par_sim` se manca |
| Cambiare scenario, orizzonte, vincolo, o spegnere il bilanciamento | Modificare le prime righe di `avvio_simulink.m` ed eseguirlo, poi Run |
| Confronto senza bilanciamento / J_t morbido / J_t rigido | `main_simulink`: tabella a schermo (con i passi senza soluzione), figure `risultati/Jt_*.png` |
| Controllo contro il codice MATLAB (`nlmpc`) | `verifica_simulink`: casi `nessuno` e `Jt` di `risultati/A_risultati.mat` (scritto da `matlab_nlmpc/main_E_costante`) |

`simula_simulink(tipo, pacco, par, scen, p)` ha gli stessi ingressi e la stessa uscita di `simula_pacco`: le funzioni in `grafici/` funzionano con entrambe.

`par_sim` contiene i numeri di una sola simulazione (un controllo, uno scenario, un orizzonte), ricavati da `par`: sono parametri, non variabili della simulazione, e i blocchi li leggono come `par_sim.Tc`, `par_sim.rho`, `par_sim.pacco.phi.Ro`. Dopo una modifica a `init_parametri.m` basta rieseguire `avvio_simulink`, che la ricrea. Se `par_sim` è rimasta nel workspace da un'altra versione del modello, va ricreata con `avvio_simulink` (oppure con `clear par_sim` prima di aprire il modello).

### Passi di tempo

Il modello ha due passi, entrambi in `init_parametri.m`:

| Parametro | Valore | Cosa regola |
|---|---|---|
| `par.tempi.Tint` | 1 s | Passo di integrazione `T_int`: passo con cui avanza il modello fisico (celle e carico) e con cui si controlla il cedimento |
| `par.mpc.Tc` | 20 s | Passo di controllo `T_c`: l'MPC campiona le misure, predice su `p` di questi passi e sceglie le correnti di bilanciamento, che restano costanti fino al passo successivo |

`par.mpc.Tc` deve essere un multiplo intero di `par.tempi.Tint`. Nel modello i due passi sono `par_sim.Tint` e `par_sim.Tc`. Il codice MATLAB (`simula_pacco`) usa un solo passo, `par.mpc.Tc`, per entrambe le cose: per riprodurlo esattamente in Simulink basta porre `par.tempi.Tint = par.mpc.Tc` (lo fa `verifica_simulink`).

## Versioni di MATLAB

`Bilanciamento_MPC_Jt.slx` è salvato con R2026b. `copia_R2025b/Bilanciamento_MPC_Jt_2024b.slx` è lo stesso modello per le versioni precedenti: nonostante il nome, è salvato con R2025b (si apre in R2025b, non in R2024b). Con MATLAB più vecchio di R2026b, `avvio_simulink` e `simula_simulink` (e quindi `main_simulink` e `verifica_simulink`) aggiungono da soli `copia_R2025b/` al path e usano la copia.

Le funzioni di apertura e di avvio dei due modelli (`PostLoadFcn`, `InitFcn`) trovano la cartella del modello con `bdroot`, cioè con il nome del modello che le esegue, e da lì le cartelle del progetto: la cartella stessa per il modello principale, quella sopra per la copia. Se si esporta di nuovo la copia, va rimessa in `copia_R2025b/` e la riga `cartella_progetto = cartella_modello;` delle due funzioni va cambiata in `cartella_progetto = fileparts(cartella_modello);`.

## Dove si trovano le formule

- `Cella_nominale` e `Predizione_linearizzata`: `DOCUMENTS/Linearizzazione_MPC.pdf`, citato nei commenti come [L].
- `Problema_QP`: `DOCUMENTS/Problema_QP_MPC.pdf`, citato come [Q]; la procedura è quella della sua sezione 8 con n_J = 1.

Il codice di ogni blocco è tutto dentro il blocco: doppio clic per leggerlo (per `Problema_QP`, doppio clic sul Variant Subsystem e poi sulla scelta).

## Funzioni comuni

Usate dal modello principale, da `matlab_nlmpc/` e da `versioni_precedenti/`.

| File | Contenuto | Paper |
|---|---|---|
| `init_parametri.m` | Tutti i parametri: cella a 20 °C, pacco, MPC, carico, scenari | — |
| `modello/genera_pacco.m` | N celle con parametri deviati casualmente | Sez. IV |
| `modello/parametri_cella.m` | `Voc`, `Ro`, `Rp`, `Cp` al SOC corrente, con le derivate rispetto al SOC (`ds.Voc`, …) | — |
| `modello/modello_cella.m` | Tensione di cella `y` e stato (`s`, `Vp`) dopo un passo | eq. (2a)-(2c) |
| `modello/carico_rle.m` | Corrente di pacco `i_pacco` con carico R–L–E | — |
| `mpc/crea_mpc.m` | Oggetto `nlmpc` per `Jt`, `Jm`, `Jdelta`: stati, variabili manipolate, limiti, costo e vincoli | eq. (6) |
| `mpc/mpc_bilanciamento.m` | Un passo di controllo con `nlmpcmove` | eq. (6) |
| `mpc/zeta_next.m` | Funzione di stato del modello di predizione: lo stato del pacco `ζ = [s; Vp]` dopo un passo | eq. (4a), (6b) |
| `mpc/predizione_uscite.m` | Tensioni e SOC predetti sull'orizzonte | eq. (6c) |
| `mpc/costo_bilanciamento.m` | Funzione di costo delle tre formulazioni | eq. (7), (9), (12), (17) |
| `mpc/vincoli_disuguaglianza.m` | Vincolo di tensione e vincoli sulle variabili ausiliarie `ε` | eq. (6e), (10), (13), (17) |
| `mpc/vincolo_somma.m` | Somma nulla delle correnti di bilanciamento | eq. (6f) |
| `mpc/jacobiano_stato.m` | Derivate della funzione di stato | Remark 3 |
| `mpc/cella_nominale.m` | Riferimento `σ⁰` della cella nominale | eq. (7) |
| `simulazione/simula_pacco.m` | Anello chiuso fino al cedimento, con `nlmpc` | eq. (5) |
| `simulazione/profilo_E.m` | F.e.m. del carico nel tempo | — |
| `grafici/` | Figure e colori | Fig. 2–5 |

Il modello principale usa `init_parametri.m`, `modello/genera_pacco.m` e `grafici/`; `mpc/` e `simulazione/` servono al codice `nlmpc` e a v1.0.

## Modello fisico

- **Cella**: circuito equivalente a un ramo RC, stato `ζ = [s; Vp]` (SOC e tensione di polarizzazione), parametri funzione del SOC. Corrente positiva = scarica.
- **Bilanciatore**: ideale, una corrente `u^n` per cella con `Σ u^n = 0` e `|u^n| ≤ 2 A`. La corrente della cella `n` è `I^n = i + u^n` (nel codice `I_cella = i_pacco + u`). Rispetto a `Modello_semplificato.slx`, `u^n = −I_bal,n`.
- **Carico**: `R`, `L` e f.e.m. `E(t)` in serie al pacco, `L·di/dt = V_pacco − R·i − E`. Con `E > V_pacco` la corrente è negativa e ricarica il pacco. L'MPC misura la corrente di pacco `i` (nel codice `i_pacco`) e la tiene costante sull'orizzonte.
- **Cedimento**: la simulazione si ferma quando una cella scende sotto `y_min`.

## Differenze rispetto al paper

- Il paper impone la corrente di pacco (costante, poi dal ciclo FTP). Qui la corrente nasce dal carico R–L–E; lo scenario dinamico usa una f.e.m. periodica e la metrica è la durata, con l'energia ceduta alla f.e.m. al posto della distanza.
- Il paper non riporta i valori di cella, limiti, pesi e `y_min`: quelli in `init_parametri.m` sono scelti qui. I risultati numerici non sono quindi confrontabili uno a uno con le Tabelle I–III.
- Il modello Simulink segue il Remark 3 del paper: linearizza la predizione attorno alla mossa precedente e risolve un QP con `quadprog`. Il QP è in forma condensata (stati eliminati): N+1 incognite per J_t con il vincolo morbido, contro `(2p+1)N` e oltre del paper. La soluzione è la stessa, i tempi di calcolo sono più bassi.
- Nell'eq. (7) del paper `σ⁰_{k+1}` è letto come `σ⁰_{k+j}`.
- La variabilità tra le celle è descritta in `DOCUMENTS/Variabilita_tra_Celle_MPC.md`.
