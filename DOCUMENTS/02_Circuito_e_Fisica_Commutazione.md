# Capitolo 2: Circuito e Fisica della Commutazione

## Il Circuito Elettrico di Potenza
Per capire come funziona il bilanciamento, basta guardare l'unità elementare tra due celle in serie.  
Lo schema circuitale puro (senza testo) è mostrato in figura:

![fig_circuito_puro.png](../fig_circuito_puro.png)

### Da cosa è composto:
- Due celle in serie a sinistra: Cella 1 ($V_1$, in alto) e Cella 2 ($V_2$, in basso), separate da un nodo centrale comune $V_{mid}$.
- Un unico **condensatore volante** $C$ sulla destra.
- **4 interruttori MOSFET bidirezionali** disposti a ponte:
  - $S_1$: collega il polo superiore del condensatore a $V_1^+$.
  - $S_2$: collega il polo inferiore del condensatore a $V_{mid}$.
  - $S_3$: collega il polo superiore del condensatore a $V_{mid}$.
  - $S_4$: collega il polo inferiore del condensatore a $V_2^-$.

---

## Le Due Fasi di Commutazione (La "Navetta")

Il sistema lavora commutando ad alta frequenza ($f_s = 50\text{ kHz}$, periodo $T_s = 20\,\mu\text{s}$) tra due stati:

### Fase $\Phi_1$: Prelievo di carica (S1 e S2 ON, S3 e S4 OFF)
- Il condensatore viene messo **in parallelo alla Cella 1**.
- Se la Cella 1 è a tensione maggiore rispetto al condensatore, fluisce una corrente che carica $C$:
  $$\Delta Q = C \cdot (V_1 - V_C)$$

### Dead-Time (Tutti gli interruttori OFF)
- Dura tipicamente $100 - 300\text{ ns}$.
- È vitale per la sicurezza: garantisce che $S_1$ e $S_3$ non siano mai accesi contemporaneamente. Se lo fossero, metterebbero in corto-circuito netto la Cella 1 con conseguenze distruttive (*shoot-through*).

### Fase $\Phi_2$: Rilascio di carica (S3 e S4 ON, S1 e S2 OFF)
- Il condensatore carico viene staccato dalla Cella 1 e messo **in parallelo alla Cella 2**.
- Poiché la Cella 2 è a tensione inferiore ($V_2 < V_1$), il condensatore si scarica nella Cella 2:
  $$\Delta Q = C \cdot (V_1 - V_2)$$

Il risultato netto è che la carica è passata da Cella 1 a Cella 2 come un secchio che attinge acqua dal pozzo pieno e la versa nel pozzo vuoto.

---

## Dalla Commutazione al Modello Continuo: La Resistenza Equivalente $R_{eq}$

A $50\text{ kHz}$, il controllore di livello superiore (il nostro DMPC) non deve preoccuparsi di ogni singolo ciclo di $20\,\mu\text{s}$.  
A livello medio, il processo di carica/scarica continuo si comporta esattamente come una **resistenza equivalente virtuale**:

$$
R_{eq} \approx \frac{1}{f_s \cdot C} + 2 R_{on}
$$

dove:
- $\frac{1}{f_s C}$ è la resistenza di commutazione ideale.
- $2 R_{on}$ è la resistenza serie dei due MOSFET attraversati dalla corrente ad ogni fase.

### Esempio Pratico Numerico
Prendiamo i valori reali usati nel nostro progetto:
- Capacità volante: $C = 100\,\mu\text{F}$
- Frequenza: $f_s = 50\,\text{kHz}$
- Resistenza MOSFET: $R_{on} = 50\,\text{m}\Omega = 0.05\,\Omega$

Calcolo immediato:
$$R_{eq} = \frac{1}{(50 \cdot 10^3) \cdot (100 \cdot 10^{-6})} + 2 \cdot 0.05 = \frac{1}{5} + 0.10 = 0.20 + 0.10 = 0.30\,\Omega$$

Supponiamo che Cella 1 sia all'$85\%$ ($V_1 = 4.10\text{ V}$) e Cella 2 al $65\%$ ($V_2 = 3.65\text{ V}$):
$$\Delta V = 4.10 - 3.65 = 0.45\text{ V}$$

La corrente media massima di bilanciamento che fluisce a duty-cycle pieno ($d = 1$) è:
$$I_{bal, max} = \frac{\Delta V}{R_{eq}} = \frac{0.45\text{ V}}{0.30\,\Omega} = 1.50\text{ A}$$

Modulando il duty-cycle $d(t) \in [0, 1]$ o abilitando/disabilitando i pacchetti di impulsi, il DMPC può decidere **esattamente quanta corrente media far fluire**, fino a $1.50\text{ A}$.

---

## Estensione a Pacco Multi-Cella (Catena)
Se abbiamo 3, 4, 6 o più celle in serie, la struttura si replica a gradini, come mostrato nello schema a catena pura:

![fig_circuito_catena_pura.png](../fig_circuito_catena_pura.png)

Ogni coppia di celle adiacenti ha il suo condensatore volante di scambio.
