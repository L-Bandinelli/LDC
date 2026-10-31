# MPC per il bilanciamento attivo — simulazione in MATLAB puro (`nlmpc`)

La stessa simulazione del modello Simulink principale (`../Bilanciamento_MPC_Jt.slx`), scritta in MATLAB: a ogni passo risolve il problema non lineare con `nlmpc`, con i tre costi J_t, J_m, J_Δ del paper. È il riferimento con cui `../verifica_simulink.m` controlla il modello Simulink.

Servono MATLAB, Model Predictive Control Toolbox (`nlmpc`) e Optimization Toolbox (`fmincon`, usato da `nlmpc`). Simulink non serve.

Gli script usano le funzioni comuni della cartella sopra (`init_parametri.m`, `modello/`, `mpc/`, `simulazione/`, `grafici/`, descritte nel [README principale](../README.md#funzioni-comuni)) e scrivono figure e dati in `../risultati/`.

## Come si esegue

Da qualsiasi cartella (ogni script aggiunge da solo al path le cartelle del progetto):

| Script | Cosa fa |
|---|---|
| `main_E_costante` | Scenario A: f.e.m. costante. Tabella delle durate, figure di celle e confronto, `risultati/A_risultati.mat` (letto da `verifica_simulink`) |
| `main_E_variabile` | Scenario B: f.e.m. a gradini. Tabella per `p = 5, 10, 15`, figure, `risultati/B_risultati.mat` |
| `main_confronto_scarica` | Scarica senza controllo e con MPC J_t negli scenari A e B: una figura per scenario con tensioni, SOC e correnti di bilanciamento |
| `main_throughput` | Tempo di calcolo di un passo MPC per `p = 5, 35`, `risultati/throughput.mat` |

Con i parametri attuali gli script `main_E_*` durano alcuni minuti. Tabelle a schermo; tutti i parametri sono in `../init_parametri.m`.

## Altri file

| File | Contenuto |
|---|---|
| `codice_unico.m` | Parametri e modello della batteria in un solo file, senza dipendenze |
| `esempio_sensibilita_ode45.m` | Esempio minimo delle derivate parametriche a tempo continuo (sezione 5 di `DOCUMENTS/Linearizzazione_MPC.pdf`) su un sistema massa-molla-smorzatore |

Il confronto tra questo codice e il modello Simulink (stesse durate, differenze sulle correnti `u`) è nel [README delle versioni precedenti](../versioni_precedenti/README.md#differenza-rispetto-al-codice-matlab).
