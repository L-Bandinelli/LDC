function [H, f, A, b, Aeq, beq, z_iniziale] = problema_qp_semplice(par_sim, sigma0, Y_bar, S_bar, d, alfa, u_bar)
%PROBLEMA_QP_SEMPLICE  Il problema (6) del paper scritto come QP (Remark 3).
%
%   min  1/2*z'*H*z + f'*z     con  A*z <= b,  Aeq*z = beq
%
% Versione da leggere del blocco Problema_QP (qp_problema.m): stesse matrici,
% ma riempite un elemento alla volta, con numeri singoli, per una cella e un
% passo per volta. Ingressi e uscite sono gli stessi di qp_problema.m, nello
% stesso ordine e con gli stessi nomi: nel blocco le due funzioni sono
% intercambiabili.
%
% Il codice e' diviso nelle stesse parti di DOCUMENTS/Problema_QP_MPC.pdf e
% ne usa la notazione: i titoli riportano numero e nome della sezione,
% "doc. (9)" indica l'equazione (9) di quel documento e le variabili hanno il
% nome dei simboli:
%   u(n), epsilon(j), epsilon_y   incognite, raccolte in z = [u; epsilon; epsilon_y]
%   Y_bar, d                      tensione predetta con u_bar e suo coefficiente di sensibilita'
%   Y_lib                         risposta libera: tensione predetta per u = 0
%   sigma0(j)                     riferimento della cella nominale al passo j
%   rho, W                        pesi sulle correnti di bilanciamento e su epsilon_y
%   y_min, u_min, u_max           tensione minima di cella e limiti di corrente
%   q                             numero della riga di A che si sta scrivendo
%
% La sezione 8 del documento riassume la stessa costruzione come procedura:
% i "passi" da 1 a 5 riempiono H e f (sezione 8.2), i "blocchi" da 1 a 6
% riempiono A e b (sezione 8.3). I commenti ne riportano il numero.
%
%   par_sim       parametri della simulazione (da parametri_simulazione)
%   sigma0        riferimento per J_t, p x 1 (uscita del blocco Cella_nominale)
%   Y_bar, S_bar  tensione e SOC predetti con u_bar, p x N
%   d, alfa       coefficienti di sensibilita': derivate di Y_bar e S_bar
%                 rispetto alla corrente di bilanciamento, p x N
%   u_bar         correnti di bilanciamento del passo precedente, una per cella
%   H, f, A, b, Aeq, beq   matrici del QP
%   z_iniziale    punto di partenza ammissibile per il solutore
%
% In tutte le matrici p x N: riga j <-> istante k+j, colonna n <-> cella n.

%% 4. Incognite e predizione linearizzata
N     = par_sim.N;                  % numero di celle
p     = par_sim.p;                  % numero di passi dell'orizzonte
n_J   = par_sim.n_J;                % formulazione: 1 = J_t, 2 = J_m, 3 = J_Delta
rho   = par_sim.rho;                % peso sulle correnti di bilanciamento
W     = par_sim.W;                  % peso sulla variabile epsilon_y
y_min = par_sim.y_min;              % [V] tensione minima di cella
u_min = par_sim.u_min;              % [A] limiti della corrente di bilanciamento
u_max = par_sim.u_max;              % [A]

% Incognite z = [u; epsilon; epsilon_y], doc. (10).
% Posizione in z:  u(n) -> n,   epsilon(j) -> N + j,   epsilon(p+j) -> N + p + j,
% epsilon_y -> l'ultima.
n_epsilon     = (n_J - 1) * p;      % epsilon: nessuna per J_t, p per J_m, 2p per J_Delta
n_z           = N + n_epsilon + 1;  % numero di incognite
pos_epsilon_y = n_z;                % posizione di epsilon_y

% Risposta libera, doc. (9): la parte della predizione che non dipende da
% u. Con questa la tensione predetta e'  y(j,n) = Y_lib(j,n) + d(j,n)*u(n).
Y_lib = zeros(p, N);
for n = 1:N
    for j = 1:p
        Y_lib(j, n) = Y_bar(j, n) - d(j, n) * u_bar(n);
    end
end

% Grandezza bilanciata. Il documento e' scritto per il caso in cui si bilancia
% la tensione: allora Sigma_bar, d_sigma, Sigma_lib sono uguali a Y_bar, d,
% Y_lib. Se si bilancia il SOC diventano S_bar, alfa, S_lib (sezione 11). Li
% usano il costo e i vincoli sulle epsilon; il vincolo di tensione minima usa
% sempre Y_lib e d.
Sigma_bar = zeros(p, N);
d_sigma   = zeros(p, N);
Sigma_lib = zeros(p, N);
for n = 1:N
    for j = 1:p
        if par_sim.sigma_tensione == 1
            Sigma_bar(j, n) = Y_bar(j, n);     d_sigma(j, n) = d(j, n);
        else
            Sigma_bar(j, n) = S_bar(j, n);     d_sigma(j, n) = alfa(j, n);
        end
        Sigma_lib(j, n) = Sigma_bar(j, n) - d_sigma(j, n) * u_bar(n);
    end
end

% Matrici del QP, per ora vuote. Il numero di righe di A e' doc. (25): un
% blocco di p*N vincoli per J_t, due per J_m, tre per J_Delta, piu' i limiti
% di corrente e il segno di epsilon_y.
n_dis = n_J * p * N + 2 * N + 1;
H = zeros(n_z, n_z);
f = zeros(n_z, 1);
A = zeros(n_dis, n_z);
b = zeros(n_dis, 1);
q = 0;                              % righe di A gia' scritte: ogni vincolo ne aggiunge una

%% 5. Il vincolo di tensione minima
% Blocco 1 di A. Per ogni cella e ogni passo, doc. (12):
%   -d(j,n)*u(n) - epsilon_y <= Y_lib(j,n) - y_min
for n = 1:N
    for j = 1:p
        q = q + 1;
        A(q, n)             = -d(j, n);              % coefficiente di u(n)
        A(q, pos_epsilon_y) = -1;                    % coefficiente di epsilon_y
        b(q)                = Y_lib(j, n) - y_min;   % margine della risposta libera
    end
end

% Passo 1 di H. Penalita' W*epsilon_y^2 nel costo, doc. (13)
H(pos_epsilon_y, pos_epsilon_y) = 2 * W;

%% 6. Il costo
% 6.1 Termine sulle correnti, rho*u(n)^2 per ogni cella: doc. (14)
% Passo 2 di H.
for n = 1:N
    H(n, n) = 2 * rho;
end

% 6.2 J_t, inseguimento della cella nominale: doc. (15)
% Passo 3 di H e f: le due somme sui passi dell'orizzonte.
if n_J == 1
    for n = 1:N
        somma_d2 = 0;               % somma su j di d(j,n)^2
        somma_dc = 0;               % somma su j di d(j,n)*(Y_lib(j,n) - sigma0(j))
        for j = 1:p
            somma_d2 = somma_d2 + d_sigma(j, n)^2;
            somma_dc = somma_dc + d_sigma(j, n) * (Sigma_lib(j, n) - sigma0(j));
        end
        H(n, n) = H(n, n) + 2 * somma_d2;
        f(n)    = 2 * somma_dc;
    end
end

% 6.3 J_m, massimizzazione della cella piu' bassa: doc. (16)
% epsilon(j) e' un minorante delle tensioni al passo j. Serve anche a J_Delta.
if n_J >= 2
    % Passo 4 di f
    for j = 1:p
        f(N + j) = -1;                      % costo: -epsilon(j), doc. (18)
    end
    % Blocco 2 di A. Per ogni cella e ogni passo, doc. (17):
    %   epsilon(j) - d(j,n)*u(n) <= Y_lib(j,n)
    for n = 1:N
        for j = 1:p
            q = q + 1;
            A(q, n)     = -d_sigma(j, n);   % coefficiente di u(n)
            A(q, N + j) = 1;                % coefficiente di epsilon(j)
            b(q)        = Sigma_lib(j, n);
        end
    end
end

% 6.4 J_Delta, minima differenza tra le celle: doc. (19)
% epsilon(p+j) e' un maggiorante delle tensioni al passo j.
if n_J == 3
    % Passo 5 di f
    for j = 1:p
        f(N + p + j) = 1;                   % costo: +epsilon(p+j), doc. (21)
    end
    % Blocco 3 di A. Per ogni cella e ogni passo, doc. (20):
    %   d(j,n)*u(n) - epsilon(p+j) <= -Y_lib(j,n)
    for n = 1:N
        for j = 1:p
            q = q + 1;
            A(q, n)         = d_sigma(j, n);   % coefficiente di u(n)
            A(q, N + p + j) = -1;              % coefficiente di epsilon(p+j)
            b(q)            = -Sigma_lib(j, n);
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

% Blocco 6 di A. La variabile epsilon_y non e' negativa, doc. (23):  -epsilon_y <= 0
q = q + 1;
A(q, pos_epsilon_y) = -1;
b(q)                = 0;

% Somma nulla delle correnti di bilanciamento, doc. (24)
Aeq = zeros(1, n_z);
for n = 1:N
    Aeq(n) = 1;
end
beq = 0;

%% 9. Il punto di partenza
% La mossa del passo precedente, completata in modo da rispettare tutti i
% vincoli: doc. (26). In u_bar la predizione linearizzata vale Y_bar.
z_iniziale = zeros(n_z, 1);
for n = 1:N
    z_iniziale(n) = u_bar(n);
end
if n_J >= 2
    for j = 1:p
        z_iniziale(N + j) = min(Sigma_bar(j, :));          % cella piu' bassa al passo j
    end
end
if n_J == 3
    for j = 1:p
        z_iniziale(N + p + j) = max(Sigma_bar(j, :));      % cella piu' alta al passo j
    end
end
z_iniziale(pos_epsilon_y) = max(0, y_min - min(Y_bar(:)));  % di quanto la predizione scende sotto y_min

end
