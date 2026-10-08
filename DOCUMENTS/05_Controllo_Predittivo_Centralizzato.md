# Capitolo 5: Controllo Predittivo Centralizzato (MPC)

## Perché Usare l'MPC e non un Semplice Controllo Proporzionale?
Un controllo banale tipo proporzionale ($u = K \cdot \Delta V$) ha gravi difetti:
- Non guarda avanti nel tempo: non sa se la corrente di carico $I_{load}$ sta aumentando o diminuendo.
- Sbatte continuamente contro i limiti di corrente $I_{max}$, generando oscillazioni (*chattering*) o instabilità.
- Non considera l'accoppiamento topologico: se Cella 1 dà carica a Cella 2, Cella 2 può contemporaneamente cederla a Cella 3.

L'**MPC (Model Predictive Control)** risolve questo alla radice: a ogni passo temporale guarda un orizzonte futuro di $H_p$ passi (es. $H_p = 4$, cioè 40 secondi nel futuro), simula l'evoluzione del pacco e calcola la sequenza di correnti ottimale che minimizza lo sbilanciamento e rispetta rigidamente tutti i vincoli.

---

## La Funzione di Costo del Problema Centralizzato
Vogliamo fare due cose contrastanti:
1. **Azzerare lo sbilanciamento** il più in fretta possibile.
2. **Minimizzare le perdite di energia** nei semiconduttori ($I^2 R$).

La funzione di costo quadratica su orizzonte $H_p$ è formalizzata così:

$$
J = \sum_{t=1}^{H_p} q_{bal} \sum_{i=1}^N \left( SoC_i(t) - \overline{SoC}(t) \right)^2 + \sum_{t=0}^{H_p-1} \left( \sum_{e \in \mathcal{E}} r_e u_e(t)^2 + s \sum_{e \in \mathcal{E}} \Delta u_e(t)^2 \right)
$$

### Significato dei tre pesi:
- **$q_{bal} \cdot \|x - \overline{SoC}\|^2$**: penalizza la varianza del SoC rispetto alla media del pacco $\overline{SoC}$.  
  Usando la matrice di centratura $M_{cent} = I_N - \frac{1}{N}\mathbf{1}\mathbf{1}^T$, si scrive in forma matriciale compatta:
  $$\sum_{i=1}^N (SoC_i - \overline{SoC})^2 = x(t)^T M_{cent} x(t)$$
- **$r_e \cdot u_e^2$**: penalizza l'energia dissipata per effetto Joule nelle resistenze equivalenti $R_{eq}$ dei switched-capacitors.
- **$s \cdot \Delta u_e^2$**: penalizza variazioni brusche di corrente $\Delta u = u(t) - u(t-1)$, rendendo il controllo fluido.

---

## Esempio Pratico con Calcolo Esplicito (2 Celle, Orizzonte 1)
Per vedere la matematica in azione, facciamo i conti a mano su un caso elementare a 2 celle con orizzonte $H_p = 1$:

- Stato iniziale: $SoC_1 = 0.80$ ($80\%$), $SoC_2 = 0.60$ ($60\%$).  
  Sbilanciamento iniziale: $\Delta SoC = 20\%$.  
  Media target: $\overline{SoC} = \frac{0.80 + 0.60}{2} = 0.70$ ($70\%$).
- Fattore di conversione: $d_q = 0.001$ per Ampere in 10 s.
- Variabile di decisione: la corrente $u$ da Cella 1 a Cella 2.

All'istante futuro $t=1$:
$$SoC_1(1) = 0.80 - d_q u$$
$$SoC_2(1) = 0.60 + d_q u$$

Gli scostamenti dalla media ($0.70$) sono:
$$e_1 = (0.80 - d_q u) - 0.70 = 0.10 - d_q u$$
$$e_2 = (0.60 + d_q u) - 0.70 = -0.10 + d_q u$$

La funzione di costo da minimizzare rispetto a $u$ è:
$$J(u) = q_{bal} \left( e_1^2 + e_2^2 \right) + r \cdot u^2 = 2 q_{bal} (0.10 - d_q u)^2 + r u^2$$

Calcoliamo la derivata prima rispetto a $u$ e poniamola a zero:
$$\frac{dJ}{du} = -4 q_{bal} d_q (0.10 - d_q u) + 2 r u = 0$$

Risolvendo per $u$:
$$u^* = \frac{0.4 \cdot q_{bal} \cdot d_q}{4 q_{bal} d_q^2 + 2 r}$$

### Mettiamo i numeri reali ($q_{bal} = 1000$, $r = 0.20$, $d_q = 0.001$):
- Numeratore: $0.4 \cdot 1000 \cdot 0.001 = 0.40$
- Denominatore: $4 \cdot 1000 \cdot (10^{-6}) + 2 \cdot 0.20 = 0.004 + 0.40 = 0.404$
$$u^* = \frac{0.40}{0.404} \approx \mathbf{0.99\text{ A}}$$

Il controllore predittivo sceglie di iniettare esattamente **$0.99\text{ A}$**!  
Se alziamo il peso dello sbilanciamento $q_{bal}$, la corrente sale fino a toccare il vincolo di saturazione $I_{max} = 2.5\text{ A}$.

---

## Sistema a Ciclo Aperto vs Sistema a Ciclo Chiuso

Mettiamo ora a confronto l'espressione formale del sistema a **ciclo aperto** (senza controllo o con correnti di bilanciamento nulle) e a **ciclo chiuso** (sotto retroazione MPC).

### 1. Espressione del Sistema a Ciclo Aperto (Open-Loop)

Nel modello dinamico a tempo discreto ricavato nel Capitolo 4:

$$
x(k+1) = A \, x(k) + B \, u(k) + E \, d(k)
$$

dove:
- $x(k) = [SoC_1(k), \dots, SoC_N(k)]^T \in \mathbb{R}^N$
- $A = I_N$ (matrice identità di dimensione $N \times N$)
- $B = - D_Q B_{cell} \in \mathbb{R}^{N \times |\mathcal{E}|}$ con $D_Q = \text{diag}\left(\frac{\Delta t}{3600 Q_{nom,i}}\right)$
- $E = - D_Q \mathbf{1}_N$ e il disturbo esogeno è la corrente di carico $d(k) = I_{load}(k)$

A **ciclo aperto**, il BMS non commuta i condensatori per trasferire carica tra le celle, quindi le correnti di bilanciamento sono nulle: $u(k) \equiv 0$.

L'equazione a **ciclo aperto** diventa semplicemente:

$$
x_{ol}(k+1) = I_N \, x(k) - D_Q \mathbf{1}_N \, I_{load}(k)
$$

#### Proprietà fisiche del ciclo aperto:
- **Autovalori**: Tutti gli autovalori di $A_{ol} = I_N$ sono $\lambda_i = 1$. Il sistema è puramente integrativo.
- **Sbilanciamento invariante**: Sottraendo lo stato di due celle $i$ e $j$ (con uguale capacità nominale):
  $$SoC_i(k+1) - SoC_j(k+1) = SoC_i(k) - SoC_j(k)$$
  Senza commutazione attiva, le celle non hanno alcuna tendenza naturale all'auto-bilanciamento. Lo sbilanciamento iniziale rimane congelato nel tempo (o peggiora a causa delle tolleranze di fabbricazione).

---

### 2. Espressione del Sistema a Ciclo Chiuso (Closed-Loop sotto MPC)

In un controllo predittivo a orizzonte recessivo (*Receding Horizon Control*), a ogni istante di campionamento $k$ il risolutore calcola la sequenza di controllo ottima su $H_p$ passi e applica all'hardware solo il primo campione:

$$
u(k) = \kappa_{MPC}(x(k)) = u^*(0 \mid k)
$$

#### A) Zona Lineare Non Satura (Unconstrained MPC)
Quando le correnti calcolate sono entro i limiti fisici ($|u_e(k)| < I_{max}$), la minimizzazione della funzione di costo quadratica rispetto allo sbilanciamento produce una legge di controllo a retroazione di stato lineare:

$$
u(k) = - K_{MPC} \cdot M_{cent} \, x(k)
$$

dove:
- $M_{cent} = \left( I_N - \frac{1}{N} \mathbf{1}_N \mathbf{1}_N^T \right)$ è la matrice di proiezione che estrae la deviazione di ciascuna cella dalla media del pacco: $M_{cent} x(k) = x(k) - \overline{SoC}(k) \mathbf{1}$.
- $K_{MPC} \in \mathbb{R}^{|\mathcal{E}| \times N}$ è la matrice di guadagno ottima calcolata offline o online dal QP.

Sostituendo la legge di controllo nell'equazione di stato:

$$
x(k+1) = x(k) - D_Q B_{cell} \left( - K_{MPC} M_{cent} x(k) \right) - D_Q \mathbf{1}_N I_{load}(k)
$$

Raccogliendo lo stato $x(k)$, otteniamo l'**equazione di stato a ciclo chiuso**:

$$
\mathbf{x(k+1) = A_{cl} \, x(k) + E \, d(k)}
$$

con la matrice di transizione a ciclo chiuso:

$$
A_{cl} = I_N + D_Q B_{cell} K_{MPC} M_{cent}
$$

#### B) Zona Satura (con Vincoli di Corrente Attivi)
Quando lo sbilanciamento è elevato e richiede una corrente che supera la capacità termica dei MOSFET, interviene l'operatore di saturazione componente per componente $\text{sat}_{[-I_{max}, I_{max}]}(\cdot)$:

$$
x(k+1) = x(k) - D_Q B_{cell} \, \text{sat}_{[-I_{max}, I_{max}]} \left( - K_{MPC} M_{cent} x(k) \right) - D_Q \mathbf{1}_N I_{load}(k)
$$

---

### 3. Proprietà Spettrali e Stabilità del Ciclo Chiuso

La bellezza matematica della matrice a ciclo chiuso $A_{cl}$ risiede nella separazione dei due sottospazi:

1. **Sottospazio Medio (Conservazione della Carica)**:
   Poiché i condensatori scambiano carica senza disperderla a massa ($\mathbf{1}^T B_{cell} = \mathbf{0}^T$), si ha:
   $$\mathbf{1}^T A_{cl} = \mathbf{1}^T I_N + D_Q (\mathbf{1}^T B_{cell}) K_{MPC} M_{cent} = \mathbf{1}^T$$
   Dunque il vettore $\mathbf{1}$ è un autovettore sinistro con autovalore:
   $$\lambda_{media} = 1$$
   La carica media del pacco $\overline{SoC}(k)$ non viene alterata dal bilanciamento, ma risponde unicamente alla corrente di carico $I_{load}$.

2. **Sottospazio dello Sbilanciamento (Convergenza Asintotica)**:
   Per qualsiasi vettore di sbilanciamento ortogonale alla media ($v \in \mathbf{1}^\perp$), il termine $+ D_Q B_{cell} K_{MPC}$ introduce uno smorzamento negativo che sposta gli autovalori rimanenti **strettamente dentro il cerchio unitario nel piano complesso**:
   $$|\lambda_i| < 1 \quad \forall i = 2, \dots, N$$
   Ciò garantisce che lo sbilanciamento $e(k) = M_{cent} x(k)$ segua una dinamica asintoticamente stabile:
   $$e(k+1) = A_{cl} \, e(k) \implies \lim_{k \to \infty} \|e(k)\| = 0$$

---

### 4. Esempio Numerico: Matrice $A_{cl}$ a 2 Celle

Prendiamo i dati del nostro esempio ($d_q = 0.001$, $B_{cell} = [1, -1]^T$):
Dalla derivata precedente, per uno sbilanciamento $e_1 - e_2 = 0.20$, la corrente ottima era $u^* = 0.99\text{ A}$.  
Il guadagno equivalente è $k_{eq} = \frac{0.99}{0.20} = 4.95\text{ A}$.  
In forma matriciale: $u^* = 4.95 \begin{bmatrix} 1 & -1 \end{bmatrix} x = 4.95 \cdot (SoC_1 - SoC_2)$.

Calcoliamo il termine di retroazione:
$$
B u^* = - d_q \begin{bmatrix} 1 \\ -1 \end{bmatrix} \left( 4.95 \begin{bmatrix} 1 & -1 \end{bmatrix} x \right) = - 0.001 \cdot 4.95 \begin{bmatrix} 1 & -1 \\ -1 & 1 \end{bmatrix} x = - \begin{bmatrix} 0.00495 & -0.00495 \\ -0.00495 & 0.00495 \end{bmatrix} x
$$

La matrice a ciclo chiuso risulta:
$$
A_{cl} = \begin{bmatrix} 1 & 0 \\ 0 & 1 \end{bmatrix} - \begin{bmatrix} 0.00495 & -0.00495 \\ -0.00495 & 0.00495 \end{bmatrix} = \begin{bmatrix} 0.99505 & 0.00495 \\ 0.00495 & 0.99505 \end{bmatrix}
$$

Verifichiamo gli autovalori di $A_{cl}$:
- **Autovalore $\lambda_1$ (media)** con autovettore $[1, 1]^T$:
  $$A_{cl} \begin{bmatrix} 1 \\ 1 \end{bmatrix} = \begin{bmatrix} 0.99505 + 0.00495 \\ 0.00495 + 0.99505 \end{bmatrix} = \begin{bmatrix} 1 \\ 1 \end{bmatrix} \implies \mathbf{\lambda_1 = 1.0}$$
- **Autovalore $\lambda_2$ (sbilanciamento)** con autovettore $[1, -1]^T$:
  $$A_{cl} \begin{bmatrix} 1 \\ -1 \end{bmatrix} = \begin{bmatrix} 0.99505 - 0.00495 \\ 0.00495 - 0.99505 \end{bmatrix} = \begin{bmatrix} 0.9901 \\ -0.9901 \end{bmatrix} \implies \mathbf{\lambda_2 = 0.9901 < 1}$$

A ogni passo di controllo $\Delta t = 10\text{ s}$, lo sbilanciamento residuo viene moltiplicato per **$0.9901$** (decade esponenzialmente verso zero)!

---

## Il Limite del Centralizzato: Perché Serve il DMPC?
Nel nostro benchmark con 6 celle, il centralizzato risolve in pochi millisecondi.  
Ma cosa succede in un pacco reale di un'auto elettrica con **96 o 192 celle in serie**?
1. **Complessità quadratica/cubica**: Il solutore centrale QP deve elaborare matrici enormi con migliaia di variabili accoppiate. Su una normale MCU automotive non gira in tempo reale.
2. **Cablaggio mostruoso**: Bisogna portare i fili di 192 celle e di centinaia di switch a un unico computer centrale.
3. **Single Point of Failure**: Se il processore centrale si blocca, salta l'intero sistema di gestione termica e di carica della batteria.
