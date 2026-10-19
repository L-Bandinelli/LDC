function [H, f, A, b, Aeq, beq, z_iniziale] = qp_problema(par_sim, sigma0, Y_bar, S_bar, d, alfa, u_bar)
%QP_PROBLEMA  Il problema (6) del paper scritto come QP (Remark 3).
%
%   min  1/2*z'*H*z + f'*z     con  A*z <= b,  Aeq*z = beq
%
% Incognite z = [u; epsilon; epsilon_y]:
%   u          N correnti di bilanciamento, costanti sull'orizzonte
%   epsilon    variabili ausiliarie del costo: nessuna per Jt, p per Jm, 2p per Jdelta
%   epsilon_y  variabile di rilassamento del vincolo di tensione, eq. (17)
%
% Y_bar, S_bar, d, alfa vengono da qp_predizione calcolata in u_bar (la mossa
% precedente): la predizione linearizzata e'
%   y_{k+j}     = Y_bar(j,:)     + d(j,:)       .* (u - u_bar) = Y_lib     + d       .* u
%   sigma_{k+j} = Sigma_bar(j,:) + d_sigma(j,:) .* (u - u_bar) = Sigma_lib + d_sigma .* u
% con Y_lib e Sigma_lib le risposte libere.
%
% par_sim.n_J: 1 = Jt, eq. (7);  2 = Jm, eq. (9)-(10);  3 = Jdelta, eq. (12)-(13).
%
% z_iniziale e' la mossa del passo precedente scritta come punto ammissibile
% del QP: il solutore parte da li'.

N   = par_sim.N;
p   = par_sim.p;
rho = par_sim.rho;                  % peso sulle correnti: R = rho*I
W   = par_sim.W;

% Grandezza bilanciata: tensione oppure SOC
if par_sim.sigma_tensione
    Sigma_bar = Y_bar;   d_sigma = d;
else
    Sigma_bar = S_bar;   d_sigma = alfa;
end
Y_lib     = Y_bar     - d       .* u_bar.';     % risposta libera: la parte della predizione che non dipende da u
Sigma_lib = Sigma_bar - d_sigma .* u_bar.';

% Posizione delle incognite dentro z
n_z = par_sim.n_z;
pos_u = 1:N;
pos_epsilon_y = n_z;

%% Costo
H = zeros(n_z, n_z);
f = zeros(n_z, 1);

% rho*u'*u, comune alle tre formulazioni, e W*epsilon_y^2 dell'eq. (17)
H(pos_u, pos_u) = 2 * rho * eye(N);
H(pos_epsilon_y, pos_epsilon_y) = 2 * W;

switch par_sim.n_J
    case 1
        % (7)  sum_j ||sigma_{k+j} - sigma0_{k+j}||^2: ogni cella insegue la nominale
        c = Sigma_lib - sigma0;                          % p x N, scarto con u = 0
        H(pos_u, pos_u) = H(pos_u, pos_u) + 2 * diag(sum(d_sigma.^2, 1));
        f(pos_u)        = 2 * sum(d_sigma .* c, 1).';
    case 2
        % (9)  -sum_j epsilon_j: epsilon_j e' la sigma della cella piu' bassa al passo j
        f(N + (1:p)) = -1;
    otherwise
        % (12) sum_j epsilon_{p+j} - sum_j epsilon_j: differenza tra la cella piu' alta e la piu' bassa
        f(N + (1:p))     = -1;
        f(N + p + (1:p)) =  1;
end

%% Vincoli di disuguaglianza A*z <= b
% Riga (n-1)*p + j di ogni blocco <-> cella n, passo j.
A = zeros(par_sim.n_dis, n_z);
b = zeros(par_sim.n_dis, 1);
n_blocco = p * N;

% (6e) rilassata con epsilon_y, eq. (17):  y_min <= y_{k+j} + epsilon_y
for n = 1:N
    righe = (n - 1)*p + (1:p);
    A(righe, n)             = -d(:, n);
    A(righe, pos_epsilon_y) = -1;
    b(righe)                = Y_lib(:, n) - par_sim.y_min;
end
riga = n_blocco;

if par_sim.n_J >= 2
    % (10) e (13a):  epsilon_j <= sigma_{k+j}
    for n = 1:N
        for j = 1:p
            q = riga + (n - 1)*p + j;
            A(q, n)     = -d_sigma(j, n);
            A(q, N + j) = 1;
            b(q)        = Sigma_lib(j, n);
        end
    end
    riga = riga + n_blocco;
end
if par_sim.n_J == 3
    % (13b):  epsilon_{p+j} >= sigma_{k+j}
    for n = 1:N
        for j = 1:p
            q = riga + (n - 1)*p + j;
            A(q, n)         = d_sigma(j, n);
            A(q, N + p + j) = -1;
            b(q)            = -Sigma_lib(j, n);
        end
    end
    riga = riga + n_blocco;
end

% (6d)  u_min <= u <= u_max
A(riga + (1:N), pos_u)     =  eye(N);     b(riga + (1:N))     =  par_sim.u_max;
A(riga + N + (1:N), pos_u) = -eye(N);     b(riga + N + (1:N)) = -par_sim.u_min;
riga = riga + 2*N;

% epsilon_y >= 0
A(riga + 1, pos_epsilon_y) = -1;

%% Vincolo di uguaglianza
% (6f)  somma delle u nulla: il bilanciatore sposta carica, non ne crea
Aeq = zeros(1, n_z);
Aeq(pos_u) = 1;
beq = 0;

%% Punto di partenza: u del passo precedente
% In u_bar la predizione linearizzata coincide con Y_bar e Sigma_bar, quindi
% le variabili ausiliarie che rendono ammissibile il punto si leggono
% direttamente dalla predizione.
z_iniziale = zeros(n_z, 1);
z_iniziale(pos_u) = u_bar;
if par_sim.n_J >= 2
    z_iniziale(N + (1:p)) = min(Sigma_bar, [], 2);          % cella piu' bassa a ogni passo
end
if par_sim.n_J == 3
    z_iniziale(N + p + (1:p)) = max(Sigma_bar, [], 2);      % cella piu' alta a ogni passo
end
z_iniziale(pos_epsilon_y) = max(0, par_sim.y_min - min(Y_bar(:)));   % quanto la predizione scende sotto y_min

end
