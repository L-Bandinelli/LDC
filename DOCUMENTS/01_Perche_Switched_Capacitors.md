# Capitolo 1: Perché i Switched Capacitors

## Il Problema Reale: La Cella più Debole Vince Sempre
In un pacco batteria con decine o centinaia di celle Li-Ion collegate in serie:
- La corrente di carico $I_{load}$ attraversa identica tutte le celle.
- Le celle non sono mai identiche: hanno piccole differenze di capacità reale, resistenza interna e auto-scarica.
- In scarica, la prima cella che tocca la tensione minima di cut-off (es. $3.0\text{ V}$) costringe il BMS a staccare il carico.

Se una cella ha il $65\%$ di SoC mentre le altre stanno all'$85\%$, il pacco si ferma quando quella cella è a zero, **lasciando intrappolato il $20\%$ di energia nelle altre celle**. Quell'energia è pagata, trasportata, ma inutilizzabile.

---

## Il Bilanciamento Passivo Tradizionale: Un Bruciatore
Il BMS passivo fa una cosa brutale:
- Quando una cella ha tensione più alta, chiude un piccolo MOSFET che collega una resistenza in parallelo alla cella.
- L'energia in eccesso viene dissipata in calore Joule:
  $$P_{dissipata} = I^2 R = \frac{V_{cell}^2}{R}$$

### Perché non va bene nei sistemi moderni:
1. **Butti via energia**: Invece di aiutare la cella scarica, svuoti quella carica bruciando energia.
2. **Generi calore nel pacco**: Il calore scalda le celle vicine, accelerandone la degradazione chimica.
3. **Sei costretto a correnti ridicole**: Per non cuocere la scheda, la corrente è limitata a $50 - 150\text{ mA}$. Per recuperare uno sbilanciamento di 2 Ah servono $20 - 40$ ore!

---

## La Soluzione Attiva: Switched Capacitors (SC)
Nel bilanciamento attivo a condensatori commutati, le resistenze spariscono.  
Al loro posto ci sono dei **piccoli condensatori volanti (flying capacitors)** montati tra celle adiacenti.

```
                  [ Condensatore Volante C ]
                       ^             |
         (preleva carica)     (scarica nella vicina)
                       |             v
                 [ Cella 1 ] ---> [ Cella 2 ]
                   (Carica)        (Scarica)
```

### Perché proprio i condensatori e non gli induttori?
Nel bilanciamento attivo esistono due grandi famiglie:
1. **Basati su Induttori / Trasformatori (DC-DC Buck-Boost, Flyback)**:
   - Ottimi per grandi potenze, ma ingombranti: richiedono nuclei magnetici pesanti, costosi e che irradiano disturbi elettromagnetici (EMI).
2. **Basati su Condensatori Commutati (Switched Capacitors)**:
   - **Zero nuclei magnetici**: servono solo condensatori ceramici SMD compatti ed economici (es. $100\,\mu\text{F}$ in package 1210).
   - **Zero calore statico**: l'energia viene solo traghettata, non bruciata. Le uniche perdite sono la resistenza di conduzione $R_{on}$ dei MOSFET durante il transitorio.
   - **Bidirezionalità intrinseca**: la carica fluisce naturalmente da chi ha potenziale più alto verso chi lo ha più basso.
