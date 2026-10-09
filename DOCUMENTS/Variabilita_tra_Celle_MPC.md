# Variabilità tra le Celle nella Simulazione MPC

Questo documento spiega come è impostata la differenza tra le celle del pacco nel codice di `SIMULATION/MPC_Range_Extension/`. È questa differenza a creare lo sbilanciamento che l'MPC deve gestire: con celle identiche le correnti di bilanciamento restano nulle.

---

## 1. Cosa dice il paper

Nella Sez. IV il paper riporta soltanto:

> all cells are initialized to be fully charged. The cell parameters $V_{oc}^n$, $R_o^n$, $R_p^n$, and $C_p^n$ are randomly generated to be within 10% deviation from the nominal values.

Non specifica la distribuzione, se la deviazione agisce su tutta la curva in funzione del SOC, né i valori estratti. La capacità $C^n$ non è tra i parametri variati.

---

## 2. Come è impostata nel codice

La funzione è [`genera_pacco.m`](../SIMULATION/MPC_Range_Extension/modello/genera_pacco.m); le deviazioni e il seme sono nella sezione 2 di [`init_parametri.m`](../SIMULATION/MPC_Range_Extension/init_parametri.m).

Per ogni cella $n$ e ogni parametro $X \in \{V_{oc}, R_o, R_p, C_p, Q\}$ si estrae un fattore di scala:

$$k_X^n = 1 + \delta_X \,(2\,r - 1), \qquad r \sim \mathcal{U}(0,1)$$

quindi $k_X^n$ è uniforme in $[1-\delta_X,\; 1+\delta_X]$. Il fattore moltiplica l'intera curva nominale:

$$X^n(s) = k_X^n \cdot X_{\text{nom}}(s)$$

La forma della curva in funzione del SOC resta quella nominale; cambia solo il livello.

| Parametro | Simbolo | Deviazione $\delta_X$ | Nel paper |
|---|:---:|:---:|:---:|
| Tensione a vuoto | $V_{oc}$ | **1 %** | 10 % |
| Resistenza serie | $R_o$ | 10 % | 10 % |
| Resistenza di polarizzazione | $R_p$ | 10 % | 10 % |
| Capacità di polarizzazione | $C_p$ | 10 % | 10 % |
| Capacità della cella | $Q$ | **0** | non variata |

Altre scelte:

- **Seme fisso** (`par.pacco.seme_casuale = 1`, generatore `twister`). Il pacco è identico a ogni esecuzione, per tutti i controllori e per entrambi gli scenari: il confronto è a parità di celle.
- **Ordine di estrazione fisso** ($V_{oc}$, $R_o$, $R_p$, $C_p$, $Q$, cinque numeri ciascuno). Cambiare una deviazione non altera i fattori degli altri parametri.
- **SOC iniziale uguale** per tutte le celle (`par.pacco.SOC_iniziale = 1`), come nel paper.
- **Cella nominale** con tutti i fattori a 1: è il riferimento inseguito da $J_t$.

---

## 3. Perché $V_{oc}$ ha solo l'1 %

Un ±10 % sulla tensione a vuoto significa fino a ±0.42 V a cella carica (4.19 V), cioè fino a 0.8 V tra due celle allo stesso SOC. Tre motivi per non usarlo:

1. **Non è fisico.** Celle della stessa chimica hanno curve $V_{oc}(SOC)$ quasi coincidenti; le differenze di produzione stanno in resistenza e capacità.
2. **Non è coerente con la Fig. 2a del paper**, dove le cinque tensioni partono dallo stesso punto e si aprono a ventaglio gradualmente.
3. **Renderebbe lo scenario banale.** Con questa cella la curva è piatta a basso SOC (circa 0.45 V per unità di SOC tra 0.1 e 0.25): la cella con $V_{oc}$ più basso toccherebbe $y_{\min}$ a pacco ancora mezzo carico, e ±2 A di bilanciamento non potrebbero compensarlo.

Con l'1 % lo scarto è di circa ±40 mV, dello stesso ordine di quello prodotto da $R_o$.

Per il ±10 % letterale del paper basta `par.pacco.deviazione.V_vuoto = 0.10`.

---

## 4. Perché la capacità è uguale

Il paper non la varia, e il codice lo rispetta di default. Nella realtà è la causa principale di sbilanciamento: a pari corrente, una cella con meno capacità si scarica più in fretta. Per attivarla: `par.pacco.deviazione.capacita = 0.05` (o altro valore).

---

## 5. Il pacco usato nelle simulazioni

Fattori estratti con i valori di default (seme 1, $N = 5$), letti dall'esecuzione di `genera_pacco`:

| Cella | $k_{V_{oc}}$ | $k_{R_o}$ | $k_{R_p}$ | $k_{C_p}$ | $k_Q$ |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 0.9983 | 0.9185 | 0.9838 | 1.0341 | 1 |
| 2 | 1.0044 | 0.9373 | 1.0370 | 0.9835 | 1 |
| 3 | 0.9900 | 0.9691 | 0.9409 | 1.0117 | 1 |
| 4 | 0.9960 | 0.9794 | 1.0756 | 0.9281 | 1 |
| 5 | 0.9929 | 1.0078 | 0.9055 | 0.9396 | 1 |

Con questo seme tutti i fattori di $R_o$ tranne uno cadono sotto 1: è l'esito dell'estrazione, non una scelta.

### Effetto sulla tensione

La tensione di cella a regime è $y \approx V_{oc}(s) - i\,(R_o + R_p)$. Lo scarto massimo che ciascuna deviazione può produrre, per la cella nominale a $i = 35$ A:

| SOC | $\delta V_{oc}$ = 1 % | $\delta R_o$ = 10 % | $\delta R_p$ = 10 % |
|:---:|:---:|:---:|:---:|
| 0.90 | ±40.8 mV | ±29.8 mV | ±6.3 mV |
| 0.50 | ±37.1 mV | ±28.7 mV | ±5.6 mV |
| 0.15 | ±35.9 mV | ±30.0 mV | ±8.6 mV |

$C_p$ non cambia la tensione a regime: modifica solo la costante di tempo $R_p C_p$ dei transitori.

Per il pacco estratto, a SOC 0.5 e 35 A a regime, lo scarto di ogni cella dalla media è:

| Cella | 1 | 2 | 3 | 4 | 5 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| Scarto | +20.3 mV | +34.4 mV | −22.8 mV | −10.9 mV | −21.0 mV |

La cella 3 è la più debole ed è quella che fa cedere il pacco senza bilanciamento; la cella 2 è la più forte. Nello scenario A senza bilanciamento la differenza tra cella più alta e più bassa è di 57 mV a 1200 s. Coerentemente, l'MPC scarica di più le celle 1 e 2 ($u > 0$) e alleggerisce le celle 3, 4 e 5 ($u < 0$).

---

## 6. Come cambiarla

In `init_parametri.m`, sezione 2:

```matlab
par.pacco.numero_celle        = 5;       % numero di celle
par.pacco.deviazione.V_vuoto  = 0.01;    % deviazioni massime relative
par.pacco.deviazione.R_serie  = 0.10;
par.pacco.deviazione.R_pol    = 0.10;
par.pacco.deviazione.C_pol    = 0.10;
par.pacco.deviazione.capacita = 0;
par.pacco.seme_casuale        = 1;       % un altro seme = un altro pacco
```

I risultati dipendono dal pacco estratto: con un altro seme cambiano la cella più debole e l'estensione ottenuta. I numeri di questo documento valgono per i valori qui sopra; per rileggerli dopo una modifica:

```matlab
init_parametri;  pacco = genera_pacco(par);
f = pacco.fattore;
[f.V_vuoto, f.R_serie, f.R_pol, f.C_pol, f.capacita]
```
