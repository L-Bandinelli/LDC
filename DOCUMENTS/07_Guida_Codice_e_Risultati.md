# Capitolo 7: Guida al Codice Python e Risultati

## Mappa dei File di Codice
Tutti i file sono nella cartella principale:

1. **`bms_bipartite_core.py`**:
   - `BatteryCell`: modello elettrochimico con Coulomb counting, resistenza interna $R_0$ e curva OCV-SoC realistica per celle Li-Ion NMC ($3.0\text{V} - 4.2\text{V}$).
   - `SwitchedCapacitor`: calcola la resistenza equivalente $R_{eq} = \frac{1}{f_s C} + 2 R_{on}$.
   - `BipartiteBMSNetwork`: genera automaticamente le matrici $B_{cell}$ e $B_{cap}$ per varie topologie (catena adiacente, anello, stella, gerarchica).

2. **`dmpc_bms_solver.py`**:
   - `CentralizedBMSMPC`: formula e risolve il problema QP globale su orizzonte $H_p$ con vincolo $B_{cap} u = 0$.
   - `DistributedADMM_BMSMPC`: implementa il DMPC a 3 passi ADMM (QP locali per cella + proiezione analitica per condensatore + aggiornamento duale).

3. **`simulate_bms_dmpc.py`**:
   - Esegue la simulazione comparativa completa su 100 passi da $\Delta t = 10\text{ s}$ (circa 16.6 minuti di funzionamento) sotto profilo di scarica dinamico $I_{load}(t)$.
   - Confronta i 3 scenari: Senza Bilanciamento, Centralized MPC, Distributed DMPC.
   - Salva i grafici analitici.

4. **`draw_pure_schematic.py`**:
   - Genera gli schemi circuitali vettoriali puri (senza testo) per la cella elementare (`fig_circuito_puro.png`) e per la catena a 3 celle (`fig_circuito_catena_pura.png`).

---

## Risultati della Simulazione a Confronto
Parametri del testbench:
- $6$ celle NMC da $3.2\text{ Ah}$ in serie.
- SoC iniziale volutamente sbilanciato: `[85%, 72%, 90%, 65%, 78%, 68%]`.
- Sbilanciamento iniziale (Spread Max-Min SoC): **$25.00\%$**.
- Limite di corrente di bilanciamento: $I_{max} = 2.5\text{ A}$.

### I Numeri Finali (dopo 16.6 minuti di scarica):
| Metrica | Senza Bilanciamento | Centralized MPC | Distributed DMPC |
|---|---|---|---|
| **Spread Finale (Max - Min)** | **$25.00\%$** | **$10.83\%$** | **$10.68\%$** |
| **Energia Recuperata** | $0\%$ | $\sim 57\%$ | $\sim 57\%$ |
| **Residuo KCL Condensatori** | — | $0.0\text{ A}$ | $10^{-15}\text{ A}$ |
| **Differenza Centralizzato vs DMPC** | — | — | **$< 0.24\%$** |
| **Iterazioni ADMM a Convergenza** | — | — | **$3$ iterazioni** |

---

## Interpretazione dei Grafici Generati

### 1. Evoluzione del SoC ([fig2_soc_balancing.png](../fig2_soc_balancing.png))
- Nel grafico non controllato (a), le celle scendono parallele: la cella 4 (la più scarica) tocca il fondo prematuramente e blocca tutto.
- Nel grafico DMPC (b), le celle convergono rapidamente verso la stessa curva media.
- Nel pannello (c), la curva verde (DMPC) e la curva blu (Centralizzato) sono praticamente sovrapposte, a dimostrazione che il controllo distribuito è equivalente all'ottimo globale.

### 2. Correnti e Neutralità dei Condensatori ([fig3_balancing_currents.png](../fig3_balancing_currents.png))
- I pannelli (a) e (b) mostrano che le correnti partono decise (intorno a $1.5 - 2.5\text{ A}$) per riallineare le celle più sbilanciate, e poi calano gradualmente man mano che il pacco si equilibra.
- Il pannello (c) conferma che la neutralità di carica dei condensatori $\max |B_{cap} u|$ è rispettata a $10^{-15}\text{ A}$ (precisione di macchina floating point).

### 3. Convergenza dei Residui ADMM ([fig4_dmpc_admm_convergence.png](../fig4_dmpc_admm_convergence.png))
- Il residuo primale $\|u - z\|_2$ crolla sotto la soglia di tolleranza $10^{-3}\text{ A}$ in appena **3 iterazioni**.  
  Questo rende l'algoritmo pronto per l'esecuzione in real-time su microcontrollori automotive a basso costo (es. STM32G4 o TI C2000).

---

## Come Eseguire la Simulazione da Terminale
Per rilanciare la simulazione e rigenerare i grafici:
```bash
python3 simulate_bms_dmpc.py
```
Per rigenerare gli schemi circuitali puri:
```bash
python3 draw_pure_schematic.py
```
