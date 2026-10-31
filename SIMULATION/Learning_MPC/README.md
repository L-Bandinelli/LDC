# Learning MPC per sistemi lineari: l'esempio del paper

Riproduzione in MATLAB della sezione 4 di

*U. Rosolia, F. Borrelli, "Learning Model Predictive Control for Iterative Tasks: A Computationally Efficient Approach for Linear System", IFAC PapersOnLine 50-1 (2017) 3142–3147*
(`DOCUMENTS/LEARNING MPC/Learning Model Predictive Control for.pdf`).

La teoria, con le dimostrazioni passo per passo, è in `DOCUMENTS/LEARNING MPC/Learning_MPC_spiegazione.pdf`: simboli e nomi del codice sono quelli di quel documento, e `[P-n]` nei commenti è l'equazione n del paper. Qui **N è l'orizzonte di predizione** ($\bar N$ nel paper), non il numero di celle come in `DOCUMENTS/Notazione.md`.

Serve l'Optimization Toolbox (`quadprog`). Il paper usa YALMIP; qui il QP è scritto direttamente per `quadprog`.

## Come si esegue

Aprire `main_lmpc.m` ed eseguirlo. La prova principale dura un paio di secondi. Per ripetere anche la Tabella 2 del paper (12 prove, circa 20 s) porre `esegui_tabella_2 = true` nella sezione 1. Le figure vanno in `risultati/`.

Lo script non cancella il workspace e crea solo variabili con nomi propri (`par_lmpc`, `result`, `ottimo`, `tabella_1`, `tabella_2`, …).

## Che cosa fa

| Sezione dello script | Contenuto | Paper |
|---|---|---|
| 1 | Problema CLQR: doppio integratore $x_{t+1} = Ax_t + Bu_t$, costo $h(x,u) = \|x\|^2 + \|u\|^2$, vincoli $\|x\|_\infty \le 4$, $\|u\| \le 1$, $x_S = [-3.95;\,-0.05]$, $N = 4$ | eq. (33) |
| 2 | Iterazione 0, poi iterazioni LMPC fino alla traiettoria stazionaria | eq. (18)–(20), (34), (35), Tabella 1 |
| 3 | Soluzione ottima a orizzonte infinito e confronto con l'LMPC | eq. (36)–(39) |
| 4 | Figure: traiettorie nel piano degli stati, costo per iterazione, errore $\sigma_t$ | — |
| 5 | (facoltativa) Altri stati iniziali e orizzonti | Tabella 2 |

Funzioni locali in fondo al file:

| Funzione | Contenuto | Paper |
|---|---|---|
| `esegui_lmpc` | Algoritmo completo: iterazione 0, iterazioni $j = 1, 2, \dots$, aggiornamento dei dati $D$ (stati memorizzati) e $c$ (costi realizzati), controllo di convergenza | riquadro "Algoritmo LMPC" del documento |
| `risolvi_lmpc` | Il QP risolto a ogni istante: incognite $z = [x_0; \dots; x_N; u_0; \dots; u_{N-1}; \lambda]$, vincolo terminale $x_N = D\lambda$, $\lambda \ge 0$, $\mathbf{1}^\top\lambda = 1$, costo terminale $c^\top\lambda$ | eq. (18), (10), (15), (17) |
| `traiettoria_iniziale` | Iterazione 0 | Assumption 1 |
| `costi_realizzati` | Costo pagato da ogni stato memorizzato in poi, calcolato a ritroso | eq. (12), (17) |
| `clqr_ottimo` | Soluzione ottima del problema a orizzonte infinito | eq. (33), (36) |
| `confronto_ottimo` | $\sigma_t$, $\sigma_{\max}$, $\Delta J$ | eq. (37)–(39) |

## Risultati (R2026b)

### Prova principale (Tabella 1 ed eq. 35–39)

| | Questo codice | Paper |
|---|---|---|
| Costo dell'iterazione 0, $J^0$ | 74.2402662287 | 57.1959612235 |
| Costo stazionario, $J^\infty$ | 49.9163600488 | 49.9163600464 |
| Costo ottimo del CLQR, $J^*$ | 49.9163600440 | — |
| Traiettoria stazionaria | $x^\infty = x^5$ | $x^\infty = x^8$ |
| $\sigma_{\max}$, eq. (38) | $3.0\cdot10^{-5}$ | $8.6\cdot10^{-6}$ |
| $\Delta J$, eq. (39) | $9.7\cdot10^{-9}$ % | $1.8\cdot10^{-20}$ % |
| Tempo di calcolo | circa 2 s | 40 s |

Il costo non cresce mai da un'iterazione all'altra (Teorema 2) e converge al costo ottimo a orizzonte infinito (Teorema 3).

### Tabella 2

| $x_S$ | $N$ | $\sigma_{\max}$ | $\Delta J$ [%] | Iterazioni | Paper: $\sigma_{\max}$, $\Delta J$, iterazioni |
|---|---|---|---|---|---|
| $[-3.95, -0.05]$ | 2 | $5.2\cdot10^{-2}$ | $3.3\cdot10^{-2}$ | 2 | $2.6\cdot10^{-1}$, $1.3\cdot10^{-1}$, 44 |
| | 3 | $2.9\cdot10^{-4}$ | $7.7\cdot10^{-7}$ | 15 | $1.9\cdot10^{-5}$, $1.7\cdot10^{-17}$, 26 |
| | 4 | $3.0\cdot10^{-5}$ | $9.7\cdot10^{-9}$ | 5 | $8.6\cdot10^{-6}$, $1.8\cdot10^{-20}$, 8 |
| $[-4, 0]$ | 2 | $4.6\cdot10^{-2}$ | $3.7\cdot10^{-2}$ | 2 | $3.6\cdot10^{-1}$, $4.2\cdot10^{-1}$, 74 |
| | 3 | $2.7\cdot10^{-4}$ | $6.7\cdot10^{-7}$ | 15 | $1.6\cdot10^{-5}$, $5.9\cdot10^{-18}$, 26 |
| | 4 | $2.8\cdot10^{-5}$ | $8.7\cdot10^{-9}$ | 5 | $5.2\cdot10^{-6}$, $1.2\cdot10^{-20}$, 8 |
| $[-2, 2]$ | 2 | $4.3\cdot10^{-2}$ | $7.4\cdot10^{-2}$ | 3 | $7.8\cdot10^{-2}$, $5.1\cdot10^{-3}$, 80 |
| | 3 | $3.1\cdot10^{-4}$ | $2.5\cdot10^{-6}$ | 14 | $1.7\cdot10^{-5}$, $3.4\cdot10^{-17}$, 22 |
| | 4 | $1.1\cdot10^{-4}$ | $3.6\cdot10^{-7}$ | 4 | $7.3\cdot10^{-6}$, $5.7\cdot10^{-20}$, 8 |
| $[0, 1.5]$ | 2 | $5.3\cdot10^{-2}$ | $1.3\cdot10^{-1}$ | 3 | $1.0\cdot10^{-1}$, $1.5\cdot10^{-2}$, 45 |
| | 3 | $2.8\cdot10^{-4}$ | $2.4\cdot10^{-6}$ | 15 | $1.8\cdot10^{-5}$, $3.4\cdot10^{-17}$, 27 |
| | 4 | $1.0\cdot10^{-4}$ | $3.1\cdot10^{-7}$ | 4 | $6.6\cdot10^{-6}$, $2.0\cdot10^{-19}$, 8 |

Le conclusioni del paper si ritrovano: con $N = 3$ e $N = 4$ l'LMPC arriva al costo ottimo a orizzonte infinito (a meno della precisione numerica), e con l'orizzonte più lungo servono meno iterazioni. Con $N = 2$ si ferma sopra l'ottimo, di qualche centesimo di punto percentuale, come nel paper. Il numero di iterazioni è più basso di quello del paper perché la soglia $\gamma$ è più alta (vedi sotto). Tutta la Tabella 2 richiede circa 20 s.

## Differenze dal paper e scelte numeriche

- **Iterazione 0.** Il paper non dice come è ottenuta la prima traiettoria. Qui la genera un LQR saturato con peso sull'ingresso $R_0 = 100$: lento e conservativo, ammissibile ma lontano dall'ottimo. Per questo $J^0$ è diverso da quello della Tabella 1.
- **Soglia di convergenza $\gamma$.** Il paper usa $\gamma = 10^{-10}$ nell'eq. (35); qui $\gamma = 10^{-4}$. Vicino all'ottimo il costo cresce col quadrato dello scarto ($J(u^* + \Delta u) - J(u^*) \approx R\,\Delta u^2$), quindi un errore di $10^{-10}$–$10^{-8}$ sul costo, dovuto alle tolleranze di `quadprog`, lascia un'incertezza di $10^{-5}$–$10^{-4}$ sugli ingressi. Nelle prove la distanza tra due iterazioni consecutive scende fino a $10^{-6}$–$10^{-5}$ e poi oscilla, mentre il costo è già fermo alla nona cifra. Per lo stesso motivo $\Delta J$ resta tra $10^{-9}$ e $10^{-6}$ %: i valori di $10^{-17}$–$10^{-20}$ % del paper sono sotto la precisione della doppia precisione rispetto a un costo di circa 50.
- **Fine delle traiettorie e costo residuo.** Le traiettorie del paper sono infinite. Qui un'iterazione finisce al primo istante $t_j$ in cui il costo ottimo predetto scende sotto $\varepsilon = 10^{-8}$ (eq. 34). Al suo ultimo stato si assegna come costo residuo proprio quel costo predetto, che è il costo di una continuazione ammissibile; per l'iterazione 0 si usa il costo dell'LQR da $x_{t_0}$. Con costo residuo nullo, come si potrebbe leggere nell'eq. (17), i punti vicino a $x_F$ dichiarerebbero un costo più basso del vero e il costo terminale potrebbe sottostimare l'ottimo. Ai dati si aggiunge una volta l'equilibrio $x_F$ con costo nullo.
- **Iterazioni non riuscite.** Se un'iterazione non arriva in $x_F$ entro `t_max` passi non entra nei dati, come prescrive l'insieme $\mathcal M^j$ dell'eq. (9). Il Teorema 1 garantisce che non succeda; il controllo resta per gli errori numerici.
- **Soluzione del QP in due passi.** Il paper usa YALMIP con `quadprog`. Qui il metodo a punto interno risolve il QP completo (veloce anche con centinaia di pesi $\lambda$, ma con una precisione assoluta sul costo di circa $10^{-8}$). Poi l'algoritmo active-set risolve di nuovo il QP tenendo solo i pesi non nulli, e aggiunge un peso escluso se il suo costo ridotto (condizione KKT) è negativo. Senza questa rifinitura, vicino a $x_F$ il costo predetto non scende mai sotto $\varepsilon$ e con $N = 2$ lo stato resta in un piccolo ciclo attorno all'origine.
- **Soluzione ottima di riferimento.** Il paper la calcola con l'algoritmo di Borrelli (2003). Qui si risolve un QP con orizzonte di 60 passi e costo terminale $x_N^\top P_{lqr} x_N$ (Riccati): ha la stessa soluzione del problema a orizzonte infinito se da $x_N$ la legge LQR non satura mai i vincoli, e lo script lo controlla.
- **Tabella 2.** Nel paper la prima riga per $x_S = [-2, 2]$ riporta $\bar N = 3$, ma dovrebbe essere $\bar N = 2$ (refuso): lo script prova $N = 2, 3, 4$ per ogni stato iniziale.
