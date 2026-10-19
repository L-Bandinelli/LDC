# MPC di bilanciamento con il solo costo J_t

Modello Simulink `Bilanciamento_MPC_Jt.slx`: lo stesso anello chiuso di `../v2.0`, ridotto al problema con la funzione obiettivo J_t (eq. 7 del paper) e con la tensione ai morsetti `y` come grandezza inseguita (σ = y). Le celle inseguono la tensione `y0` di una cella nominale:

J_t = Σ_j Σ_n (y^n_{k+j} − y^0_{k+j})² + ρ Σ_n (u^n_k)²,  più W·ε_y² per il vincolo di tensione rilassato (eq. 17).

Il modello ha un nome diverso da quello di v1.0 e v2.0, quindi si può aprire insieme a loro.

## Che cosa cambia rispetto a v2.0

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

## Vincolo di tensione morbido o rigido

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
| Aprire e simulare a mano | Aprire `Bilanciamento_MPC_Jt.slx` e premere Run: all'apertura il modello crea `par_sim` se manca |
| Cambiare scenario, orizzonte, vincolo, o spegnere il bilanciamento | Modificare le prime righe di `avvio_simulink.m` ed eseguirlo, poi Run |
| Confronto senza bilanciamento / J_t morbido / J_t rigido | `main_simulink`: tabella a schermo (con i passi senza soluzione), figure `../../risultati/Jt_*.png` |
| Controllo contro il codice MATLAB (`nlmpc`) | `verifica_simulink`: casi `nessuno` e `Jt` di `risultati/A_risultati.mat` |

Se `par_sim` è rimasta nel workspace da un'altra versione del modello, va ricreata con `avvio_simulink` (oppure con `clear par_sim` prima di aprire il modello).

## Dove si trovano le formule

- `Cella_nominale` e `Predizione_linearizzata`: `DOCUMENTS/Linearizzazione_MPC.pdf`, citato nei commenti come [L].
- `Problema_QP`: `DOCUMENTS/Problema_QP_MPC.pdf`, citato come [Q]; la procedura è quella della sua sezione 8 con n_J = 1.

Il codice di ogni blocco è tutto dentro il blocco: doppio clic per leggerlo (per `Problema_QP`, doppio clic sul Variant Subsystem e poi sulla scelta).
