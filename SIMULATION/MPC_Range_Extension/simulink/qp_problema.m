function [H, f, A, b, Aeq, beq, z0] = qp_problema(sl, sigma0, Y, S, dY, dS, u_prec)
%QP_PROBLEMA  Il problema (6) del paper scritto come QP (Remark 3).
%
%   min  1/2*z'*H*z + f'*z     con  A*z <= b,  Aeq*z = beq
%
% Incognite z = [u; eps; e]:
%   u    N correnti di bilanciamento, costanti sull'orizzonte
%   eps  slack del costo: nessuna per Jt, p per Jm, 2p per Jdelta
%   e    slack del vincolo di tensione, eq. (17)
%
% Y, S, dY, dS vengono da qp_predizione calcolata in u_prec: la predizione
% linearizzata e'
%   y_{k+j}     = Y(j,:)     + dY(j,:)     .* (u - u_prec) = y_0     + dY     .* u
%   sigma_{k+j} = sigma(j,:) + dsigma(j,:) .* (u - u_prec) = sigma_0 + dsigma .* u
%
% sl.tipo: 1 = Jt, eq. (7);  2 = Jm, eq. (9)-(10);  3 = Jdelta, eq. (12)-(13).
%
% z0 e' la mossa del passo precedente scritta come punto ammissibile del QP:
% il solutore parte da li'.

N = sl.N;
p = sl.p;
r = sl.r;                           % R = r*I
W = sl.W;

% Grandezza bilanciata: tensione oppure SOC
if sl.sigma_tensione
    sigma = Y;   dsigma = dY;
else
    sigma = S;   dsigma = dS;
end
y_0     = Y     - dY     .* u_prec.';       % parte della predizione che non dipende da u
sigma_0 = sigma - dsigma .* u_prec.';

% Posizione delle incognite dentro z
n_z = sl.n_z;
i_u = 1:N;
i_e = n_z;

%% Costo
H = zeros(n_z, n_z);
f = zeros(n_z, 1);

% u'*R*u, comune alle tre formulazioni, e W*e^2 dell'eq. (17)
H(i_u, i_u) = 2 * r * eye(N);
H(i_e, i_e) = 2 * W;

switch sl.tipo
    case 1
        % (7)  sum_j ||sigma_{k+j} - sigma0_{k+j}||^2: ogni cella insegue la nominale
        scarto = sigma_0 - sigma0;                       % p x N, scarto con u = 0
        H(i_u, i_u) = H(i_u, i_u) + 2 * diag(sum(dsigma.^2, 1));
        f(i_u)      = 2 * sum(dsigma .* scarto, 1).';
    case 2
        % (9)  -sum_j eps_j: eps_j e' la sigma della cella piu' bassa al passo j
        f(N + (1:p)) = -1;
    otherwise
        % (12) sum_j eps_{p+j} - sum_j eps_j: differenza tra la cella piu' alta e la piu' bassa
        f(N + (1:p))     = -1;
        f(N + p + (1:p)) =  1;
end

%% Vincoli di disuguaglianza A*z <= b
% Riga (n-1)*p + j di ogni blocco <-> cella n, passo j.
A = zeros(sl.n_dis, n_z);
b = zeros(sl.n_dis, 1);
m = p * N;

% (6e) rilassata con e, eq. (17):  y_min <= y_{k+j} + e
for n = 1:N
    righe = (n - 1)*p + (1:p);
    A(righe, n)   = -dY(:, n);
    A(righe, i_e) = -1;
    b(righe)      = y_0(:, n) - sl.y_min;
end
riga = m;

if sl.tipo >= 2
    % (10) e (13a):  eps_j <= sigma_{k+j}
    for n = 1:N
        for j = 1:p
            q = riga + (n - 1)*p + j;
            A(q, n)     = -dsigma(j, n);
            A(q, N + j) = 1;
            b(q)        = sigma_0(j, n);
        end
    end
    riga = riga + m;
end
if sl.tipo == 3
    % (13b):  eps_{p+j} >= sigma_{k+j}
    for n = 1:N
        for j = 1:p
            q = riga + (n - 1)*p + j;
            A(q, n)         = dsigma(j, n);
            A(q, N + p + j) = -1;
            b(q)            = -sigma_0(j, n);
        end
    end
    riga = riga + m;
end

% (6d)  u_min <= u <= u_max
A(riga + (1:N), i_u)     =  eye(N);     b(riga + (1:N))     =  sl.u_max;
A(riga + N + (1:N), i_u) = -eye(N);     b(riga + N + (1:N)) = -sl.u_min;
riga = riga + 2*N;

% e >= 0
A(riga + 1, i_e) = -1;

%% Vincolo di uguaglianza
% (6f)  somma delle u nulla: il bilanciatore sposta carica, non ne crea
Aeq = zeros(1, n_z);
Aeq(i_u) = 1;
beq = 0;

%% Punto di partenza: u del passo precedente
% In u_prec la predizione linearizzata coincide con Y e sigma, quindi le slack
% che rendono ammissibile il punto si leggono direttamente dalla predizione.
z0 = zeros(n_z, 1);
z0(i_u) = u_prec;
if sl.tipo >= 2
    z0(N + (1:p)) = min(sigma, [], 2);              % cella piu' bassa a ogni passo
end
if sl.tipo == 3
    z0(N + p + (1:p)) = max(sigma, [], 2);          % cella piu' alta a ogni passo
end
z0(i_e) = max(0, sl.y_min - min(Y(:)));             % quanto la predizione scende sotto y_min

end
