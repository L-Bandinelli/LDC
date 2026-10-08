# Capitolo 3: La Rete Bipartita

## Perché una Rete Bipartita?
In un pacco batteria con switched-capacitors:
- Le celle **non si toccano mai direttamente**.
- Tutto lo scambio di carica avviene transitando attraverso i condensatori volanti.

Questo si traduce in una struttura matematica nota come **Grafo Bipartito** $\mathcal{G} = (\mathcal{V}, \mathcal{E})$:

```
    PARTIZIONE CELLE (V_cells)          PARTIZIONE CAPACITORI (V_caps)
         [ Cella C₁ ] ------ Arco e₁ ------> [ Capacitore K₁ ]
         [ Cella C₂ ] <----- Arco e₂ -------+
         [ Cella C₂ ] ------ Arco e₃ ------> [ Capacitore K₂ ]
         [ Cella C₃ ] <----- Arco e₄ -------+
```

### Le Regole del Gioco:
1. I nodi sono divisi in due gruppi disgiunti:
   - **Celle** $\mathcal{V}_{cell} = \{C_1, C_2, \dots, C_N\}$
   - **Capacitori** $\mathcal{V}_{cap} = \{K_1, K_2, \dots, K_M\}$
2. **Nessun arco unisce due celle tra loro**.
3. **Nessun arco unisce due condensatori tra loro**.
4. Ogni arco orientato $e = (C_i, K_j)$ rappresenta una via di corrente controllata tra la cella $i$ e il condensatore $j$:
   - $u_e > 0$: corrente estratta dalla cella verso il condensatore (scarica).
   - $u_e < 0$: corrente iniettata dal condensatore nella cella (carica).

---

## Le Matrici di Incidenza $B_{cell}$ e $B_{cap}$
La matrice di incidenza complessiva $B \in \mathbb{R}^{(N+M) \times P}$ si scompone nei due blocchi:

$$
B = \begin{bmatrix} B_{cell} \\ B_{cap} \end{bmatrix}
$$

- $B_{cell} \in \mathbb{R}^{N \times P}$: dice quali archi toccano ciascuna cella.
- $B_{cap} \in \mathbb{R}^{M \times P}$: dice quali archi toccano ciascun condensatore.

La corrente netta estratta da ciascuna cella è:
$$I_{bal, cell} = B_{cell} \cdot u$$

La corrente netta che entra in ciascun condensatore è:
$$I_{cap} = - B_{cap} \cdot u$$

---

## Esempio Pratico Numerico: 3 Celle e 2 Condensatori
Prendiamo un mini-pacco da $N = 3$ celle ($C_1, C_2, C_3$) con $M = 2$ condensatori di scambio ($K_1$ tra C1-C2, $K_2$ tra C2-C3).

Gli archi sono $P = 4$:
- $e_1$: da Cella 1 a Cap 1 (corrente $u_1$)
- $e_2$: da Cella 2 a Cap 1 (corrente $u_2$)
- $e_3$: da Cella 2 a Cap 2 (corrente $u_3$)
- $e_4$: da Cella 3 a Cap 2 (corrente $u_4$)

### Come sono fatte le matrici numero per numero:

$$
B_{cell} = \begin{bmatrix}
1 & 0 & 0 & 0 \\
0 & 1 & 1 & 0 \\
0 & 0 & 0 & 1
\end{bmatrix} \quad (\text{Dimensione: } 3 \text{ celle} \times 4 \text{ archi})
$$

$$
B_{cap} = \begin{bmatrix}
-1 & -1 & 0 & 0 \\
0 & 0 & -1 & -1
\end{bmatrix} \quad (\text{Dimensione: } 2 \text{ condensatori} \times 4 \text{ archi})
$$

---

## Il Vincolo Fisico Fondamentale: $B_{cap} \cdot u = 0$
I condensatori volanti sono piccoli (es. $100\,\mu\text{F}$). Non possono fare da "serbatoio a lungo termine": non possono accumulare una corrente continua netta senza andare in sovratensione istantanea.

Quindi, a ogni passo di controllo, la somma delle cariche che entrano ed escono da un condensatore **deve essere rigorosamente zero**:

$$
B_{cap} \cdot u = \mathbf{0}
$$

Vediamo cosa significa esplicitamente nel nostro esempio:

$$
\begin{bmatrix}
-1 & -1 & 0 & 0 \\
0 & 0 & -1 & -1
\end{bmatrix}
\begin{bmatrix} u_1 \\ u_2 \\ u_3 \\ u_4 \end{bmatrix}
= \begin{bmatrix} 0 \\ 0 \end{bmatrix}
\iff
\begin{cases}
-u_1 - u_2 = 0 \implies u_2 = -u_1 \\
-u_3 - u_4 = 0 \implies u_4 = -u_3
\end{cases}
$$

### Facciamo un test numerico con numeri veri:
Supponiamo che il controllore decida di estrarre $1.5\text{ A}$ dalla Cella 1 ($u_1 = +1.5\text{ A}$) per passarla alla Cella 2:
- Il vincolo impone subito: $u_2 = -u_1 = -1.5\text{ A}$.
- Supponiamo che al momento $K_2$ sia fermo ($u_3 = 0, u_4 = 0$).

Calcoliamo le correnti nette sulle 3 celle:
$$
I_{bal} = B_{cell} \cdot u =
\begin{bmatrix}
1 & 0 & 0 & 0 \\
0 & 1 & 1 & 0 \\
0 & 0 & 0 & 1
\end{bmatrix}
\begin{bmatrix} +1.5 \\ -1.5 \\ 0 \\ 0 \end{bmatrix}
= \begin{bmatrix} +1.5\text{ A} \\ -1.5\text{ A} \\ 0.0\text{ A} \end{bmatrix}
$$

- Cella 1: $+1.5\text{ A}$ (si scarica).
- Cella 2: $-1.5\text{ A}$ (si ricarica).
- Cella 3: $0\text{ A}$ (invariata).

Tutto torna alla perfezione. La conservazione della carica è garantita a priori dalla struttura della matrice.
