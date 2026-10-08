# Capitolo 4: Modello Dinamico a Spazio di Stato

## L'Equazione di Stato a Tempo Discreto
Lo stato del nostro pacco batteria all'istante di campionamento $k$ (con passo $\Delta t$, ad esempio $\Delta t = 10\text{ s}$) è il vettore dei SoC di tutte le $N$ celle:

$$
x(k) = \begin{bmatrix} SoC_1(k) \\ SoC_2(k) \\ \vdots \\ SoC_N(k) \end{bmatrix} \in [0, 1]^N
$$

---

## Il Metodo del Coulomb Counting: Come Funziona
Il **Coulomb Counting** (conteggio dei Coulomb) è il metodo cardine utilizzato nei BMS per tracciare lo stato di carica ($SoC$). Si basa su una legge fisica elementare: la carica elettrica $q(t)$ è l'integrale nel tempo della corrente che attraversa la cella:

$$
q(t) = \int_{t_0}^t I(\tau) d\tau
$$

Definendo il $SoC$ come la frazione di carica residua rispetto alla capacità nominale massima $Q_{nom}$, la relazione continua è:

$$
SoC(t) = SoC(t_0) - \frac{1}{Q_{nom}} \int_{t_0}^t I(\tau) d\tau
$$

*(Convenzione di segno: $I > 0$ per corrente di scarica in uscita, $I < 0$ per corrente di ricarica in ingresso).*

### Discretizzazione a Tempo Campionato ($\Delta t$)
Nel controllore digitale il tempo scorre a passi discreti $\Delta t$ (es. $10\text{ s}$). Assumendo la corrente approssimativamente costante nell'intervallo $[k, k+1]$, l'integrale diventa un semplice prodotto:

$$
SoC(k+1) = SoC(k) - \frac{I(k) \cdot \Delta t}{Q_{nom, Coulomb}}
$$

Poiché sui datasheet dei costruttori la capacità delle celle è espressa in **Ampere-ora ($Ah$)** e non in Coulomb, ricordando che $1\text{ Ah} = 3600\text{ A}\cdot\text{s} = 3600\text{ Coulomb}$, otteniamo la formula operativa usata dal codice:

$$
SoC(k+1) = SoC(k) - \frac{\Delta t}{3600 \cdot Q_{nom, Ah}} \cdot I(k)
$$

### Pregi e Limiti Pratici nel Mondo Reale:
- **Perché è perfetto per il nostro DMPC**: È una relazione puramente **lineare**, computazionalmente a costo zero per la CPU, ed esatta sull'orizzonte di predizione dell'MPC ($H_p \cdot \Delta t \approx 30 - 60\text{ s}$).
- **Il limite pratico (Deriva / Drift)**: Sul lungo periodo (ore o giorni), l'integrazione accumula l'eventuale errore di offset o rumore del sensore di corrente. Nei BMS commerciali viene perciò periodicamente riallineato a veicolo fermo tramite la tensione a circuito aperto ($OCV$) o accoppiato a un filtro di Kalman (EKF). Nel nostro orizzonte di controllo rapido, questo effetto è trascurabile.

---

## L'Equazione di Stato Matriciale a Tempo Discreto
Estendendo il Coulomb Counting all'intero pacco di $N$ celle collegate in serie:

$$
x(k+1) = x(k) - D_Q B_{cell} u(k) - D_Q \mathbf{1}_N I_{load}(k)
$$

### Analisi dei singoli pezzi:
1. **$x(k)$**: il punto di partenza (il SoC attuale misurato/stimato).
2. **$- D_Q \mathbf{1}_N I_{load}(k)$**: l'effetto della corrente di carico esterna serie $I_{load}(k)$.  
   Tutte le celle in serie portano la stessa corrente $I_{load}$: se il veicolo o il carico assorbe $2\text{ A}$, tutte le celle si scaricano insieme.
3. **$- D_Q B_{cell} u(k)$**: l'azione di controllo del bilanciamento attivo.  
   È il flusso di corrente che estraiamo dalle celle cariche e riversiamo nelle celle scariche tramite i condensatori.
4. **$D_Q$**: matrice diagonale dei fattori di scala:
   $$D_Q = \text{diag}\left( \frac{\Delta t}{3600 \cdot Q_{nom, 1}}, \dots, \frac{\Delta t}{3600 \cdot Q_{nom, N}} \right)$$
   Questo coefficiente trasforma gli Ampere in variazione di frazione di SoC nell'intervallo $\Delta t$.

---

### Esempio Matriciale Completo: 3 Celle e 2 Condensatori

Vediamo l'equazione scritta per esteso, elemento per elemento, sul caso a **3 celle in serie ($C_1, C_2, C_3$) e 2 condensatori volanti ($K_1, K_2$)**:

1. **Il vettore di stato $x(k)$**:
   $$x(k) = \begin{bmatrix} SoC_1(k) \\ SoC_2(k) \\ SoC_3(k) \end{bmatrix}$$

2. **Il prodotto $B_{cell} \cdot u(k)$**:
   Ricordando la matrice di incidenza delle celle ($3 \times 4$) e il vettore delle 4 correnti d'arco:
   $$
   B_{cell} \cdot u(k) =
   \begin{bmatrix}
   1 & 0 & 0 & 0 \\
   0 & 1 & 1 & 0 \\
   0 & 0 & 0 & 1
   \end{bmatrix}
   \begin{bmatrix}
   u_1(k) \\ u_2(k) \\ u_3(k) \\ u_4(k)
   \end{bmatrix}
   =
   \begin{bmatrix}
   u_1(k) \\
   u_2(k) + u_3(k) \\
   u_4(k)
   \end{bmatrix}
   $$

   > **Fisica immediata**:  
   > - La Cella 1 tocca solo il Condensatore 1 $\implies$ corrente netta $u_1$.  
   > - La Cella 2 tocca sia il Condensatore 1 (arco $e_2$) sia il Condensatore 2 (arco $e_3$) $\implies$ corrente netta **$u_2 + u_3$**!  
   > - La Cella 3 tocca solo il Condensatore 2 $\implies$ corrente netta $u_4$.

3. **Applicazione del vincolo di conservazione di carica ($B_{cap} u = 0$)**:  
   Per il Condensatore 1: $u_2 = -u_1$.  
   Per il Condensatore 2: $u_4 = -u_3$.  
   Il termine di bilanciamento diventa:
   $$
   B_{cell} \cdot u(k) = \begin{bmatrix} u_1 \\ -u_1 + u_3 \\ -u_3 \end{bmatrix}
   $$

4. **Sostituzione con numeri reali**:  
   Supponiamo celle con $d_q = 0.000868$, corrente di carico $I_{load} = 2.0\text{ A}$, e correnti di bilanciamento:
   - Da Cella 1 a Cap 1: $u_1 = +1.5\text{ A}$ (e quindi $u_2 = -1.5\text{ A}$ verso Cella 2).
   - Da Cella 2 a Cap 2: $u_3 = +0.5\text{ A}$ (e quindi $u_4 = -0.5\text{ A}$ verso Cella 3).

   L'equazione matriciale diventa:
   $$
   \begin{bmatrix} SoC_1(k+1) \\ SoC_2(k+1) \\ SoC_3(k+1) \end{bmatrix}
   =
   \begin{bmatrix} SoC_1(k) \\ SoC_2(k) \\ SoC_3(k) \end{bmatrix}
   - d_q
   \begin{bmatrix}
   1 & 0 & 0 & 0 \\
   0 & 1 & 1 & 0 \\
   0 & 0 & 0 & 1
   \end{bmatrix}
   \begin{bmatrix}
   +1.5 \\ -1.5 \\ +0.5 \\ -0.5
   \end{bmatrix}
   - d_q
   \begin{bmatrix} 1 \\ 1 \\ 1 \end{bmatrix} \cdot 2.0
   $$

   Sviluppando i prodotti matrice-vettore:
   $$
   \begin{bmatrix} SoC_1(k+1) \\ SoC_2(k+1) \\ SoC_3(k+1) \end{bmatrix}
   =
   \begin{bmatrix} SoC_1(k) \\ SoC_2(k) \\ SoC_3(k) \end{bmatrix}
   - d_q
   \begin{bmatrix}
   +1.5 \\
   -1.5 + 0.5 \\
   -0.5
   \end{bmatrix}
   - d_q
   \begin{bmatrix} 2.0 \\ 2.0 \\ 2.0 \end{bmatrix}
   $$

   Sommando le correnti su ciascuna riga:
   $$
   \begin{bmatrix} SoC_1(k+1) \\ SoC_2(k+1) \\ SoC_3(k+1) \end{bmatrix}
   =
   \begin{bmatrix} SoC_1(k) \\ SoC_2(k) \\ SoC_3(k) \end{bmatrix}
   - d_q
   \begin{bmatrix}
   3.5\text{ A} \quad (\text{Cella 1: scarica accelerata}) \\
   1.0\text{ A} \quad (\text{Cella 2: scarica dimezzata da 2A a 1A}) \\
   1.5\text{ A} \quad (\text{Cella 3: scarica ridotta da 2A a 1.5A})
   \end{bmatrix}
   $$

   In un solo passaggio matriciale è evidente come i flussi bilancino le tre celle durante la normale scarica del pacco!

---

## Esempio Numerico Reale: Quanto Sposta 1 Ampere?
Prendiamo i dati delle celle usate nel progetto:
- Capacità nominale: $Q_{nom} = 3.2\text{ Ah} = 3.2 \cdot 3600 = 11520\text{ Coulomb}$
- Passo di controllo: $\Delta t = 10\text{ secondi}$

Calcoliamo il coefficiente $d_q$:
$$d_q = \frac{10}{11520} \approx 0.000868 \quad (\text{ovvero } 0.0868\% \text{ di SoC per ogni Ampere in 10 s})$$

### Facciamo un test pratico di scarica:
Supponiamo che il pacco stia erogando una corrente di carico $I_{load} = 2.0\text{ A}$.
- **Senza bilanciamento** ($u = 0$):  
  Ogni cella perde a ogni passo:
  $$\Delta SoC = 2.0\text{ A} \cdot 0.0868\% = 0.1736\%$$
  Tutte le celle calano alla stessa velocità. Lo sbilanciamento rimane identico per sempre.

- **Con bilanciamento attivo** ($u_1 = +1.5\text{ A}$ da Cella 1 a Cella 2):
  - Corrente totale Cella 1: $I_{tot, 1} = I_{load} + u_1 = 2.0 + 1.5 = 3.5\text{ A}$.  
    Calo SoC Cella 1 in 10 s: $3.5 \cdot 0.0868\% = \mathbf{0.3038\%}$.
  - Corrente totale Cella 2: $I_{tot, 2} = I_{load} - u_1 = 2.0 - 1.5 = 0.5\text{ A}$.  
    Calo SoC Cella 2 in 10 s: $0.5 \cdot 0.0868\% = \mathbf{0.0434\%}$.

Cella 1 si scarica **7 volte più velocemente** di Cella 2!  
In pochi minuti di funzionamento, il divario di carica tra le due celle si colma completamente.

---

## I Vincoli Fisici del Sistema
Nel dimensionare il controllore, dobbiamo imporre che non vengano mai violati i limiti fisici dei componenti:

1. **Limite termico e di saturazione dei MOSFET**:
   $$-I_{max} \le u_e(k) \le I_{max}, \quad \forall e \in \mathcal{E} \quad (\text{es. } I_{max} = 2.5\text{ A})$$
2. **Neutralità dei condensatori (KCL)**:
   $$B_{cap} u(k) = \mathbf{0}$$
3. **Limiti operativi di sicurezza del SoC**:
   $$SoC_{min} \le x_i(k) \le SoC_{max} \quad (\text{es. tra il } 10\% \text{ e il } 90\%)$$
