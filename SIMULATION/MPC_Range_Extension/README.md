# MPC per il bilanciamento attivo — simulazione MATLAB

Codice MATLAB che simula il problema del paper
*J. Chen, A. Behal, C. Li, "Active Cell Balancing by Model Predictive Control for Real Time Range Extension", IEEE CDC 2021*
(`DOCUMENTS/BMS/`), con la cella dei modelli Simulink di `SIMULATION/`.

Servono MATLAB, Model Predictive Control Toolbox (`nlmpc`) e Optimization Toolbox (`fmincon`, usato da `nlmpc`). Simulink non serve.

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

## Differenze rispetto al paper

- Il paper impone la corrente di pacco (costante, poi dal ciclo FTP). Qui la corrente nasce dal carico R–L–E; lo scenario dinamico usa una f.e.m. periodica e la metrica è la durata, con l'energia ceduta alla f.e.m. al posto della distanza.
- Il paper non riporta i valori di cella, limiti, pesi e `y_min`: quelli in `init_parametri.m` sono scelti qui. I risultati numerici non sono quindi confrontabili uno a uno con le Tabelle I–III.
- Il QP è in forma condensata (stati eliminati): `N`, `N+p`, `N+2p` variabili per `J_t`, `J_m`, `J_Δ`, contro `(2p+1)N` e oltre del paper. La soluzione è la stessa, i tempi di calcolo sono più bassi.
- Nell'eq. (7) del paper `σ⁰_{k+1}` è letto come `σ⁰_{k+j}`.
- La variabilità tra le celle è descritta in `DOCUMENTS/Variabilita_tra_Celle_MPC.md`.
