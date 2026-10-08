# Capitolo 6: Controllo Predittivo Distribuito (DMPC) basato su ADMM

## L'Idea Chiave del DMPC
Nel DMPC non esiste un super-computer centrale che controlla tutto il pacco.  
Il controllo viene distribuito sui nodi della nostra **Rete Bipartita**:
1. **Ogni Cella è un Agente**: misura solo il proprio SoC locale, conosce la propria capacità e decide quanta corrente estrarre/iniettare sui propri archi incidenti ($u_{ie}$).
2. **Ogni Condensatore è un Coordinatore**: riceve le richieste delle celle collegate e impone la conservazione esatta della carica ($\sum z = 0$).
3. **I Moltiplicatori di Lagrange $\lambda_e$**: viaggiano lungo gli archi della rete per allineare le decisioni locali delle celle con i vincoli fisici dei condensatori.

Il ponte matematico che fa convergere questo sistema distribuito all'ottimo globale si chiama **ADMM** (*Alternating Direction Method of Multipliers*).

---

## Formulazione Matematica delle Variabili
Per ciascun arco della rete bipartita $e = (C_i, K_j)$:
- $u_e$: la corrente proposta dalla **Cella $i$**.
- $z_e$: la corrente validata dal **Condensatore $j$**.

Il vincolo di consenso fisico è:
$$u_e(t) - z_e(t) = 0, \quad \forall e \in \mathcal{E}, \quad \forall t \in \{0, \dots, H_p-1\}$$

Il Lagrangiano aumentato del problema è:
$$
\mathcal{L}_\rho = \sum_{i \in \mathcal{V}_{cell}} J_i(u_i) + \sum_{j \in \mathcal{V}_{cap}} \mathbb{I}_{\{\sum z_e = 0\}} + \sum_{e \in \mathcal{E}} \left[ \lambda_e (u_e - z_e) + \frac{\rho}{2} (u_e - z_e)^2 \right]
$$
dove $\rho > 0$ è il parametro di penalità aumentata (es. $\rho = 5.0$).

---

## I Tre Passi dell'Algoritmo ADMM

Ad ogni passo di campionamento del BMS ($k$), l'algoritmo esegue pochi cicli di iterazione ($\nu = 0, 1, 2, \dots$):

### Passo 1: Ottimizzazione Locale delle Celle (Parallelizzabile)
Ciascuna cella $i$ risolve un micro-problema quadratico indipendente per le correnti uscenti dai suoi soli archi $\mathcal{E}_i$:

$$
\min_{u_i} \sum_{t=1}^{H_p} q_i (SoC_i(t) - \overline{SoC}_{target})^2 + \sum_{t=0}^{H_p-1} \sum_{e \in \mathcal{E}_i} \left[ r_e u_e(t)^2 + \lambda_e^{(\nu)} u_e(t) + \frac{\rho}{2}(u_e(t) - z_e^{(\nu)})^2 \right]
$$
soggetto alla sola dinamica locale della cella $i$ e ai limiti $-I_{max} \le u_e \le I_{max}$.

> **Perché è velocissimo**: Per una catena adiacente, ogni cella ha solo 1 o 2 variabili decisionali. La soluzione richiede meno di 0.5 millisecondi su un microcontrollore standard Cortex-M4!

---

### Passo 2: Proiezione Analitica dei Condensatori (Zero Solutori Numerici!)
Ciascun condensatore $j$ deve coordinare le correnti dei suoi archi incidenti $\mathcal{E}_j$ in modo che la somma sia rigorosamente zero:

$$
\min_{\{z_e\}} \sum_{e \in \mathcal{E}_j} \left[ -\lambda_e^{(\nu)} z_e + \frac{\rho}{2}(u_e^{(\nu+1)} - z_e)^2 \right] \quad \text{s.t.} \quad \sum_{e \in \mathcal{E}_j} z_e = 0
$$

Definendo la quantità $v_e = u_e^{(\nu+1)} + \frac{\lambda_e^{(\nu)}}{\rho}$, questo problema è una **proiezione euclidea ortogonale su un iperpiano**.  
La soluzione ha una **formula chiusa esatta analitica**:

$$
z_e^* = v_e - \frac{1}{|\mathcal{E}_j|} \sum_{m \in \mathcal{E}_j} v_m
$$

> **Zero calcoli iterativi sul condensatore**: Si calcola la media aritmetica dei $v_e$ e la si sottrae a ciascun elemento! Il vincolo $\sum z_e = 0$ è rispettato al $100\%$ a livello di precisione di macchina.

---

### Passo 3: Aggiornamento dei Moltiplicatori Duali
Lungo ciascun arco $e$:
$$
\lambda_e^{(\nu+1)} = \lambda_e^{(\nu)} + \rho \left( u_e^{(\nu+1)} - z_e^{(\nu+1)} \right)
$$

---

## Esempio Pratico Numerico Passo-Passo (2 Celle, 1 Condensatore)
Vediamo concretamente come convergono i numeri in una singola iterazione ADMM.

Supponiamo che:
- Cella 1 propone una corrente uscente: $u_1 = +1.00\text{ A}$ (vuole scaricarsi forte).
- Cella 2 propone una corrente entrante: $u_2 = -0.40\text{ A}$ (vuole caricarsi piano).
- Moltiplicatori iniziali: $\lambda_1 = 0, \lambda_2 = 0$.
- Peso penalità: $\rho = 2.0$.

Notiamo subito il disaccordo: $u_1 + u_2 = 1.00 - 0.40 = +0.60\text{ A} \neq 0$.  
Il condensatore accumulerebbe carica, violando la KCL!

### Intervento del Condensatore $K_1$ (Passo 2):
1. Calcolo dei vettori ausiliari $v_e = u_e + \lambda_e / \rho$:
   $$v_1 = 1.00 + \frac{0}{2.0} = 1.00$$
   $$v_2 = -0.40 + \frac{0}{2.0} = -0.40$$

2. Calcolo della media:
   $$\text{media}(v) = \frac{v_1 + v_2}{2} = \frac{1.00 - 0.40}{2} = \frac{0.60}{2} = 0.30$$

3. Calcolo delle correnti coordinate $z_e^* = v_e - \text{media}(v)$:
   $$z_1^* = 1.00 - 0.30 = \mathbf{+0.70\text{ A}}$$
   $$z_2^* = -0.40 - 0.30 = \mathbf{-0.70\text{ A}}$$

Verifica immediata del vincolo:
$$z_1^* + z_2^* = +0.70 - 0.70 = \mathbf{0.00\text{ A}}$$
Il bilancio di carica del condensatore è perfetto!

### Aggiornamento Duale (Passo 3):
Calcoliamo i nuovi moltiplicatori $\lambda$:
$$\lambda_1 \leftarrow \lambda_1 + \rho (u_1 - z_1) = 0 + 2.0 \cdot (1.00 - 0.70) = \mathbf{+0.60}$$
$$\lambda_2 \leftarrow \lambda_2 + \rho (u_2 - z_2) = 0 + 2.0 \cdot (-0.40 - (-0.70)) = \mathbf{+0.60}$$

### Cosa succede all'iterazione successiva?
- Nella funzione di costo di Cella 1, compare il termine $+ \lambda_1 u_1 = +0.60 u_1$: questo penalizza $u_1$ e la costringe a scendere verso $0.70\text{ A}$.
- Nella funzione di costo di Cella 2, la penalità incoraggia $u_2$ a diventare più negativa verso $-0.70\text{ A}$.

In appena **3 iterazioni**, $u$ e $z$ coincidono a meno di $10^{-3}\text{ A}$.  
L'algoritmo distribuito trova esattamente lo stesso identico ottimo del centralizzato, ma senza alcun computer centrale!
