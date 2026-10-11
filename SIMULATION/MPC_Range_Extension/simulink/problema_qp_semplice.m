function [H, f, A, b, Aeq, beq, z0] = problema_qp_semplice(sl, r, Y, S, D, E, u_bar)
%PROBLEMA_QP_SEMPLICE  Il problema (6) del paper scritto come QP (Remark 3).
%
%   min  1/2*z'*H*z + f'*z     con  A*z <= b,  Aeq*z = beq
%
% Versione da leggere del blocco Problema_QP (qp_problema.m): stesse matrici,
% ma riempite un elemento alla volta, con numeri singoli, per una cella e un
% passo per volta. Ingressi e uscite sono gli stessi di qp_problema.m, nello
% stesso ordine: nel blocco le due funzioni sono intercambiabili.
%
% Il codice e' diviso nelle stesse parti di DOCUMENTS/Problema_QP_MPC.pdf e
% ne usa la notazione: i titoli riportano numero e nome della sezione,
% "doc. (9)" indica l'equazione (9) di quel documento e le variabili hanno il
% nome dei simboli:
%   u(n), epsilon(j), e    incognite, raccolte in z = [u; epsilon; e]
%   Y, D                   tensione predetta con u_bar e suo coefficiente di sensibilita'
%   Y0                     risposta libera: tensione predetta per u = 0
%   r(j)                   riferimento della cella nominale al passo j
%   rho, W                 pesi sulle correnti di bilanciamento e sulla variabile e
%   y_min, u_min, u_max    tensione minima di cella e limiti di corrente
%   q                      numero della riga di A che si sta scrivendo
%
% La sezione 8 del documento riassume la stessa costruzione come procedura:
% i "passi" da 1 a 5 riempiono H e f (sezione 8.2), i "blocchi" da 1 a 6
% riempiono A e b (sezione 8.3). I commenti ne riportano il numero.
%
%   sl        parametri del modello (da init_simulink)
%   r         riferimento per J_t, p x 1 (uscita del blocco Cella_nominale)
%   Y, S      tensione e SOC predetti con u_bar, p x N
%   D, E      loro derivate rispetto alla corrente di bilanciamento, p x N
%   u_bar     correnti di bilanciamento del passo precedente, una per cella
%   H, f, A, b, Aeq, beq   matrici del QP
%   z0        punto di partenza ammissibile per il solutore
%
% In tutte le matrici p x N: riga j <-> istante k+j, colonna n <-> cella n.

%% 4. Incognite e predizione linearizzata
N     = sl.N;                       % numero di celle
p     = sl.p;                       % numero di passi dell'orizzonte
tipo  = sl.tipo;                    % formulazione: 1 = J_t, 2 = J_m, 3 = J_Delta
rho   = sl.r;                       % peso sulle correnti di bilanciamento
W     = sl.W;                       % peso sulla variabile e
y_min = sl.y_min;                   % [V] tensione minima di cella
u_min = sl.u_min;                   % [A] limiti della corrente di bilanciamento
u_max = sl.u_max;                   % [A]

% Incognite z = [u; epsilon; e], doc. (10).
% Posizione in z:  u(n) -> n,   epsilon(j) -> N + j,   epsilon(p+j) -> N + p + j,
% e -> l'ultima.
n_eps = (tipo - 1) * p;             % epsilon: nessuna per J_t, p per J_m, 2p per J_Delta
n_z   = N + n_eps + 1;              % numero di incognite
i_e   = n_z;                        % posizione di e

% Risposta libera, doc. (9): la parte della predizione che non dipende da
% u. Con questa la tensione predetta e'  y(j,n) = Y0(j,n) + D(j,n)*u(n).
Y0 = zeros(p, N);
for n = 1:N
    for j = 1:p
        Y0(j, n) = Y(j, n) - D(j, n) * u_bar(n);
    end
end

% Grandezza bilanciata. Il documento e' scritto per il caso in cui si bilancia
% la tensione: allora Yb, Db, Yb0 sono uguali a Y, D, Y0. Se si bilancia il
% SOC diventano S, E, S0 (sezione 11). Li usano il costo e i vincoli sulle
% epsilon; il vincolo di tensione minima usa sempre Y0 e D.
Yb  = zeros(p, N);
Db  = zeros(p, N);
Yb0 = zeros(p, N);
for n = 1:N
    for j = 1:p
        if sl.sigma_tensione == 1
            Yb(j, n) = Y(j, n);     Db(j, n) = D(j, n);
        else
            Yb(j, n) = S(j, n);     Db(j, n) = E(j, n);
        end
        Yb0(j, n) = Yb(j, n) - Db(j, n) * u_bar(n);
    end
end

% Matrici del QP, per ora vuote. Il numero di righe di A e' doc. (25): un
% blocco di p*N vincoli per J_t, due per J_m, tre per J_Delta, piu' i limiti
% di corrente e il segno di e.
n_dis = tipo * p * N + 2 * N + 1;
H = zeros(n_z, n_z);
f = zeros(n_z, 1);
A = zeros(n_dis, n_z);
b = zeros(n_dis, 1);
q = 0;                              % righe di A gia' scritte: ogni vincolo ne aggiunge una

%% 5. Il vincolo di tensione minima
% Blocco 1 di A. Per ogni cella e ogni passo, doc. (12):
%   -D(j,n)*u(n) - e <= Y0(j,n) - y_min
for n = 1:N
    for j = 1:p
        q = q + 1;
        A(q, n)   = -D(j, n);               % coefficiente di u(n)
        A(q, i_e) = -1;                     % coefficiente di e
        b(q)      = Y0(j, n) - y_min;       % margine della risposta libera
    end
end

% Passo 1 di H. Penalita' W*e^2 nel costo, doc. (13)
H(i_e, i_e) = 2 * W;

%% 6. Il costo
% 6.1 Termine sulle correnti, rho*u(n)^2 per ogni cella: doc. (14)
% Passo 2 di H.
for n = 1:N
    H(n, n) = 2 * rho;
end

% 6.2 J_t, inseguimento della cella nominale: doc. (15)
% Passo 3 di H e f: le due somme sui passi dell'orizzonte.
if tipo == 1
    for n = 1:N
        somma_D2 = 0;               % somma su j di D(j,n)^2
        somma_Dc = 0;               % somma su j di D(j,n)*(Y0(j,n) - r(j))
        for j = 1:p
            somma_D2 = somma_D2 + Db(j, n)^2;
            somma_Dc = somma_Dc + Db(j, n) * (Yb0(j, n) - r(j));
        end
        H(n, n) = H(n, n) + 2 * somma_D2;
        f(n)    = 2 * somma_Dc;
    end
end

% 6.3 J_m, massimizzazione della cella piu' bassa: doc. (16)
% epsilon(j) e' un minorante delle tensioni al passo j. Serve anche a J_Delta.
if tipo >= 2
    % Passo 4 di f
    for j = 1:p
        f(N + j) = -1;                      % costo: -epsilon(j), doc. (18)
    end
    % Blocco 2 di A. Per ogni cella e ogni passo, doc. (17):
    %   epsilon(j) - D(j,n)*u(n) <= Y0(j,n)
    for n = 1:N
        for j = 1:p
            q = q + 1;
            A(q, n)     = -Db(j, n);        % coefficiente di u(n)
            A(q, N + j) = 1;                % coefficiente di epsilon(j)
            b(q)        = Yb0(j, n);
        end
    end
end

% 6.4 J_Delta, minima differenza tra le celle: doc. (19)
% epsilon(p+j) e' un maggiorante delle tensioni al passo j.
if tipo == 3
    % Passo 5 di f
    for j = 1:p
        f(N + p + j) = 1;                   % costo: +epsilon(p+j), doc. (21)
    end
    % Blocco 3 di A. Per ogni cella e ogni passo, doc. (20):
    %   D(j,n)*u(n) - epsilon(p+j) <= -Y0(j,n)
    for n = 1:N
        for j = 1:p
            q = q + 1;
            A(q, n)         = Db(j, n);     % coefficiente di u(n)
            A(q, N + p + j) = -1;           % coefficiente di epsilon(p+j)
            b(q)            = -Yb0(j, n);
        end
    end
end

%% 7. I vincoli rimanenti
% Limiti della corrente di bilanciamento, doc. (22):
%   u(n) <= u_max   e   -u(n) <= -u_min
for n = 1:N                         % blocco 4 di A: limite superiore
    q = q + 1;
    A(q, n) = 1;
    b(q)    = u_max;
end
for n = 1:N                         % blocco 5 di A: limite inferiore
    q = q + 1;
    A(q, n) = -1;
    b(q)    = -u_min;
end

% Blocco 6 di A. La variabile e non e' negativa, doc. (23):  -e <= 0
q = q + 1;
A(q, i_e) = -1;
b(q)      = 0;

% Somma nulla delle correnti di bilanciamento, doc. (24)
Aeq = zeros(1, n_z);
for n = 1:N
    Aeq(n) = 1;
end
beq = 0;

%% 9. Il punto di partenza
% La mossa del passo precedente, completata in modo da rispettare tutti i
% vincoli: doc. (26). In u_bar la predizione linearizzata vale Y.
z0 = zeros(n_z, 1);
for n = 1:N
    z0(n) = u_bar(n);
end
if tipo >= 2
    for j = 1:p
        z0(N + j) = min(Yb(j, :));          % cella piu' bassa al passo j
    end
end
if tipo == 3
    for j = 1:p
        z0(N + p + j) = max(Yb(j, :));      % cella piu' alta al passo j
    end
end
z0(i_e) = max(0, y_min - min(Y(:)));        % di quanto la predizione scende sotto y_min

end
