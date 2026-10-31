%% main_lmpc.m
% Learning Model Predictive Control (LMPC) per sistemi lineari: l'esempio
% della sezione 4 del paper
%   U. Rosolia, F. Borrelli, "Learning Model Predictive Control for Iterative
%   Tasks: A Computationally Efficient Approach for Linear System",
%   IFAC PapersOnLine 50-1 (2017) 3142-3147.
%   (DOCUMENTS/LEARNING MPC/Learning Model Predictive Control for.pdf)
%
% La spiegazione passo per passo e' DOCUMENTS/LEARNING MPC/Learning_MPC_spiegazione.pdf:
% simboli e nomi seguono quel documento. [P-n] e' l'equazione n del paper.
% Attenzione: qui N e' l'orizzonte di predizione (N barrato nel paper), non il
% numero di celle come in DOCUMENTS/Notazione.md.
%
% Che cosa fa lo script:
%   1) definisce il problema CLQR [P-33]: doppio integratore, costo
%      h(x,u) = ||x||^2 + ||u||^2, vincoli |x| <= 4, |u| <= 1;
%   2) esegue l'LMPC [P-18] dall'iterazione 0 fino alla traiettoria
%      stazionaria (Tabella 1, eq. [P-35]);
%   3) calcola la soluzione ottima a orizzonte infinito e la confronta con
%      la traiettoria stazionaria dell'LMPC (eq. [P-36]-[P-39]);
%   4) disegna traiettorie, costi di iterazione ed errore sigma_t;
%   5) (facoltativo) ripete la prova per gli stati iniziali e gli orizzonti
%      della Tabella 2.
%
% Serve l'Optimization Toolbox (quadprog). Lo script non cancella il
% workspace: crea solo le variabili par_lmpc, result, ottimo, tabella_1,
% tabella_2 e poche altre di servizio.

%% 1) Problema CLQR [P-33]

par_lmpc = struct();

% Sistema x_{t+1} = A x_t + B u_t [P-1], [P-33b]: doppio integratore
% (x(1) posizione, x(2) velocita', u accelerazione)
par_lmpc.A = [1 1; 0 1];
par_lmpc.B = [0; 1];

% Costo di stadio h(x,u) = x'*Q*x + u'*R*u [P-33a], con Q = I e R = 1
par_lmpc.Q = eye(2);
par_lmpc.R = 1;

% Vincoli [P-33d], [P-33e]: scatole su stato e ingresso
par_lmpc.x_min = [-4; -4];
par_lmpc.x_max = [ 4;  4];
par_lmpc.u_min = -1;
par_lmpc.u_max =  1;

% Equilibrio finale x_F = A x_F [P-7]
par_lmpc.x_F = [0; 0];

% Fine di un'iterazione [P-34]: t_j = min{t : J^{LMPC,j}_{0->N}(x_t) <= epsilon}
par_lmpc.epsilon = 1e-8;

% Convergenza [P-35]: la traiettoria e' stazionaria quando due iterazioni
% consecutive distano meno di gamma (gamma e' anche una funzione di MATLAB,
% da qui il nome lungo).
% Il paper usa gamma = 1e-10, che con quadprog non si raggiunge: vicino
% all'ottimo il costo cresce col quadrato dello scarto,
% J(u* + Delta_u) - J(u*) ~ R*Delta_u^2, quindi un errore di 1e-10..1e-8 sul
% costo (tolleranze del solutore) lascia Delta_u ~ 1e-5..1e-4. Nelle prove
% la distanza tra due iterazioni scende fino a 1e-6..1e-5 e poi oscilla
% (con N = 3 fino a 1e-4), mentre il costo e' gia' fermo alla nona cifra.
% Si usa quindi gamma = 1e-4.
par_lmpc.gamma_convergenza = 1e-4;

% Limiti di sicurezza dei cicli
par_lmpc.j_max = 150;        % numero massimo di iterazioni LMPC
par_lmpc.t_max = 300;        % numero massimo di passi in un'iterazione

% Iterazione 0 (Assumption 1): il paper non dice come e' ottenuta. Qui la
% genera un LQR saturato con un peso sull'ingresso grande, R_0 = 100: lento e
% conservativo, quindi ammissibile ma lontano dall'ottimo.
par_lmpc.R_0 = 100;

% Opzioni di quadprog. Il QP si risolve in due passi (funzione risolvi_lmpc):
% punto interno sul problema completo, poi rifinitura active-set sui soli
% pesi lambda piu' grandi di soglia_lambda, con il controllo KKT sui pesi
% esclusi. La rifinitura serve vicino a x_F, dove il costo e' piu' piccolo
% della precisione del punto interno.
par_lmpc.opzioni_qp = optimoptions('quadprog', 'Display', 'off', ...
    'OptimalityTolerance', 1e-12, 'ConstraintTolerance', 1e-12, 'StepTolerance', 1e-15);
par_lmpc.opzioni_rifinitura = optimoptions('quadprog', 'Display', 'off', 'Algorithm', 'active-set');
par_lmpc.soglia_lambda = 1e-9;

% Prova principale del paper
x_S = [-3.95; -0.05];        % stato iniziale x_S [P-4]
N   = 4;                     % orizzonte N

% Tabella 2: metterlo a true per ripetere la prova su altri x_S e N (qualche minuto)
esegui_tabella_2 = false;

%% 2) LMPC dall'iterazione 0 alla traiettoria stazionaria (Tabella 1, [P-35])

fprintf('\n=== LMPC, x_S = [%g; %g], N = %d ===\n', x_S(1), x_S(2), N);
result = esegui_lmpc(par_lmpc, x_S, N);

tabella_1 = table((0:result.n_iterazioni_eseguite).', result.J_iterazione.', ...
    'VariableNames', {'iterazione_j', 'costo_iterazione_J'});
fprintf('\nTabella 1 - costo di ogni iterazione J^j_{0->inf}(x_S) [P-13]\n');
fprintf('   j     J^j\n');
for j = 0:result.n_iterazioni_eseguite
    fprintf('  %2d   %.10f\n', j, result.J_iterazione(j + 1));
end
if result.convergenza
    fprintf('\nTraiettoria stazionaria x^inf = x^%d: max_t ||x^%d_t - x^%d_t|| = %.1e < gamma = %.0e [P-35]\n', ...
        result.j_stazionaria, result.j_stazionaria + 1, result.j_stazionaria, ...
        result.distanza_finale, par_lmpc.gamma_convergenza);
else
    fprintf('\nNessuna convergenza entro %d iterazioni (ultima distanza %.1e)\n', ...
        par_lmpc.j_max, result.distanza_finale);
end
% Teorema 2: il costo non cresce. Si ammette una crescita di 1e-8, il rumore
% numerico del solutore sul costo (vedi gamma_convergenza)
fprintf('Il costo non cresce mai, a meno di 1e-8 (Teorema 2): %s\n', ...
    mat2str(all(diff(result.J_iterazione) <= 1e-8)));
fprintf('Tempo di calcolo totale: %.1f s (%d QP, %.1f ms per QP in media)\n', ...
    result.t_calcolo, result.n_qp, 1000*result.t_calcolo/result.n_qp);

%% 3) Confronto con la soluzione ottima a orizzonte infinito ([P-36]-[P-39])

ottimo = clqr_ottimo(par_lmpc, x_S);
[sigma, sigma_max, Delta_J] = confronto_ottimo(result, ottimo);

fprintf('\nSoluzione ottima del CLQR: J*_{0->inf}(x_S) = %.10f\n', ottimo.J);
fprintf('Errore massimo sulla traiettoria  sigma_max = %.1e  [P-38]\n', sigma_max);
fprintf('Errore relativo sul costo        Delta_J   = %.1e %%  [P-39]\n', Delta_J);

%% 4) Figure

cartella_risultati = fullfile(fileparts(mfilename('fullpath')), 'risultati');
if ~exist(cartella_risultati, 'dir')
    mkdir(cartella_risultati);
end

% Traiettorie nel piano degli stati, una per iterazione
figura_traiettorie = figure('Name', 'LMPC - traiettorie');
hold on; grid on; box on;
colori = parula(result.n_iterazioni_eseguite + 2);
for j = 0:result.n_iterazioni_eseguite
    x_j = result.x{j + 1};
    if j == 0
        plot(x_j(1, :), x_j(2, :), 'k--o', 'MarkerSize', 4, 'DisplayName', 'iterazione 0');
    else
        plot(x_j(1, :), x_j(2, :), '-o', 'Color', colori(j + 1, :), 'MarkerSize', 3, ...
            'HandleVisibility', 'off');
    end
end
plot(ottimo.x(1, :), ottimo.x(2, :), 'r-', 'LineWidth', 1.5, 'DisplayName', 'ottimo CLQR x^*');
plot(x_S(1), x_S(2), 'ks', 'MarkerFaceColor', 'k', 'DisplayName', 'x_S');
plot(par_lmpc.x_F(1), par_lmpc.x_F(2), 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 10, 'DisplayName', 'x_F');
xlabel('x_1 (posizione)'); ylabel('x_2 (velocita'')');
title(sprintf('Traiettorie dell''LMPC, N = %d (colore: iterazione 1 \\rightarrow %d)', N, result.n_iterazioni_eseguite));
legend('Location', 'best');
saveas(figura_traiettorie, fullfile(cartella_risultati, 'traiettorie.png'));

% Costo di iterazione ed errore dalla traiettoria ottima
figura_costi = figure('Name', 'LMPC - costi ed errore', 'Position', [100 100 700 750]);
subplot(3, 1, 1);
plot(0:result.n_iterazioni_eseguite, result.J_iterazione, 'o-'); hold on; grid on;
yline(ottimo.J, 'r--', 'J^*_{0\rightarrow\infty}(x_S)');
xlabel('iterazione j'); ylabel('J^j_{0\rightarrow\infty}(x_S)');
title('Costo di iterazione (Tabella 1)');
% Scarto dall'ottimo in scala logaritmica: dopo la prima iterazione il
% miglioramento non si vede in scala lineare. Il valore assoluto copre gli
% scarti negativi dell'ordine del rumore numerico.
subplot(3, 1, 2);
semilogy(0:result.n_iterazioni_eseguite, max(abs(result.J_iterazione - ottimo.J), 1e-16), 'o-'); grid on;
xlabel('iterazione j'); ylabel('|J^j_{0\rightarrow\infty}(x_S) - J^*_{0\rightarrow\infty}(x_S)|');
title('Scarto dal costo ottimo');
subplot(3, 1, 3);
semilogy(0:numel(sigma) - 1, max(sigma, 1e-16), 'o-'); grid on;
xlabel('passo t'); ylabel('\sigma_t = ||x^\infty_t - x^*_t||_2');
title('Distanza dalla traiettoria ottima [P-37]');
saveas(figura_costi, fullfile(cartella_risultati, 'costi_ed_errore.png'));

%% 5) Tabella 2 (facoltativa): altri stati iniziali e orizzonti

if esegui_tabella_2
    stati_iniziali = [-3.95 -0.05; -4 0; -2 2; 0 1.5].';
    orizzonti      = [2 3 4];
    righe = {};
    for q = 1:size(stati_iniziali, 2)
        ottimo_q = clqr_ottimo(par_lmpc, stati_iniziali(:, q));
        for N_q = orizzonti
            result_q = esegui_lmpc(par_lmpc, stati_iniziali(:, q), N_q);
            [~, sigma_max_q, Delta_J_q] = confronto_ottimo(result_q, ottimo_q);
            righe(end + 1, :) = {mat2str(stati_iniziali(:, q).'), N_q, sigma_max_q, ...
                Delta_J_q, result_q.j_stazionaria, result_q.t_calcolo};
            fprintf('x_S = %-12s N = %d: sigma_max = %.1e, Delta_J = %.1e %%, iterazioni = %d\n', ...
                righe{end, 1}, N_q, sigma_max_q, Delta_J_q, result_q.j_stazionaria);
        end
    end
    tabella_2 = cell2table(righe, 'VariableNames', ...
        {'x_S', 'N', 'sigma_max', 'Delta_J_percento', 'iterazioni', 't_calcolo_s'});
    disp(tabella_2);
end


%% ========================================================================
%  Funzioni locali
%  ========================================================================

function result = esegui_lmpc(par_lmpc, x_S, N)
%ESEGUI_LMPC  Algoritmo LMPC completo (riquadro "Algoritmo LMPC" del documento).
%
% Iterazione 0 con un controllore qualsiasi, poi iterazioni j = 1, 2, ...:
% ogni iterazione parte da x_S, risolve il QP [P-18] a ogni passo con i dati
% delle iterazioni 0..j-1 e si ferma secondo [P-34]. A fine iterazione i
% suoi stati e i suoi costi realizzati entrano nei dati.
%
% result.x{j+1}, result.u{j+1}  stati e ingressi realizzati dell'iterazione j
% result.J_iterazione(j+1)      costo dell'iterazione j, J^j_{0->inf}(x_S) [P-13]

A = par_lmpc.A;
B = par_lmpc.B;

% --- Iterazione 0 (Assumption 1) ---
[x_0, u_0, costo_finale_0] = traiettoria_iniziale(par_lmpc, x_S);
c_0 = costi_realizzati(par_lmpc, x_0, u_0, costo_finale_0);

result.x            = {x_0};
result.u            = {u_0};
result.J_iterazione = c_0(1);

% Dati delle iterazioni passate: matrice dei dati D (colonne = stati
% memorizzati x^i_s) e vettore c dei costi realizzati J^i_{s->inf}(x^i_s).
% Si aggiunge una volta l'equilibrio x_F con costo 0: e' il punto a cui
% converge ogni traiettoria riuscita, quindi appartiene alla chiusura del
% safe set (le traiettorie del paper sono infinite, qui sono troncate).
D = [par_lmpc.x_F, x_0];
c = [0, c_0];

result.convergenza     = false;
result.distanza_finale = inf;
result.j_stazionaria   = NaN;
result.n_qp            = 0;
tic_totale = tic;

for j = 1:par_lmpc.j_max
    % --- Iterazione j: anello chiuso con l'LMPC [P-18], [P-20] ---
    x_j = x_S;                 % stati realizzati x^j_0, x^j_1, ... (colonne)
    u_j = zeros(size(B, 2), 0);
    x_t = x_S;                 % x^j_0 = x_S [P-4]
    riuscita = false;          % diventa vera quando lo stato arriva in x_F
    for t = 0:par_lmpc.t_max
        [u_t, J_lmpc, esito] = risolvi_lmpc(par_lmpc, x_t, N, D, c);
        result.n_qp = result.n_qp + 1;
        if esito ~= 1
            error('esegui_lmpc:qp', 'QP non risolto (esito %d) all''iterazione %d, passo %d', esito, j, t);
        end
        % Fine dell'iterazione [P-34]: lo stato e' arrivato in x_F
        if J_lmpc <= par_lmpc.epsilon
            riuscita = true;
            break
        end
        % Si applica il primo ingresso [P-20] e il sistema avanza [P-1]
        x_t = A*x_t + B*u_t;
        x_j = [x_j, x_t];      %#ok<AGROW>
        u_j = [u_j, u_t];      %#ok<AGROW>
    end

    % --- Aggiornamento dei dati con l'iterazione j ---
    % Solo le iterazioni riuscite entrano nel safe set (insieme M^j, [P-9]).
    % Il teorema 1 garantisce che lo siano tutte; il controllo resta per
    % gli errori numerici.
    % Costo residuo dell'ultimo stato x_{t_j}: il costo ottimo predetto
    % J_lmpc(x_{t_j}) <= epsilon, cioe' il costo di una continuazione
    % ammissibile (vedi costi_realizzati)
    c_j = costi_realizzati(par_lmpc, x_j, u_j, J_lmpc);
    result.x{j + 1}         = x_j;
    result.u{j + 1}         = u_j;
    result.J_iterazione(j + 1) = c_j(1);
    if riuscita
        D = [D, x_j];          %#ok<AGROW>
        c = [c, c_j];          %#ok<AGROW>
    else
        fprintf('  iterazione %3d: non arriva in x_F entro t_max = %d passi, non entra nei dati\n', ...
            j, par_lmpc.t_max);
    end

    % --- Convergenza [P-35]: distanza dall'iterazione precedente ---
    distanza = distanza_traiettorie(result.x{j}, x_j, par_lmpc.x_F);
    result.distanza_finale = distanza;
    fprintf('  iterazione %3d: J^j = %.10f, t_j = %2d, stati memorizzati M = %4d, distanza da j-1 = %.1e (%.1f s)\n', ...
        j, c_j(1), size(u_j, 2), size(D, 2), distanza, toc(tic_totale));
    if distanza < par_lmpc.gamma_convergenza
        result.convergenza   = true;
        result.j_stazionaria = j - 1;     % x^inf = x^{j-1}, come x^8 nel paper
        break
    end
end

result.n_iterazioni_eseguite = numel(result.x) - 1;
if ~result.convergenza
    result.j_stazionaria = result.n_iterazioni_eseguite;
end
result.x_stazionaria = result.x{result.j_stazionaria + 1};
result.J_stazionaria = result.J_iterazione(result.j_stazionaria + 1);
result.t_calcolo     = toc(tic_totale);

end


function [u_t, J_lmpc, esito] = risolvi_lmpc(par_lmpc, x_t, N, D, c)
%RISOLVI_LMPC  Problema LMPC all'istante t, nella forma con i pesi lambda (QP).
%
%   min   sum_{k=0}^{N-1} h(x_k, u_k) + c'*lambda
%   s.t.  x_0 = x_t                                [P-18c]
%         x_{k+1} = A x_k + B u_k                  [P-18b]
%         x_min <= x_k <= x_max, u_min <= u_k <= u_max   [P-18d]
%         x_N = D*lambda, lambda >= 0, sum(lambda) = 1   [P-18e], [P-15]
%
% Il termine c'*lambda, minimizzato insieme agli ingressi, e' il costo
% terminale P^{j-1}(x_N) [P-15], [P-17]; il vincolo x_N = D*lambda e'
% x_N in CS^{j-1} [P-10]. Il pedice k conta i passi della predizione: x_k
% sta per x_{t+k|t}.
%
% Incognite: z = [x_0; x_1; ...; x_N; u_0; ...; u_{N-1}; lambda]
% J_lmpc e' il costo ottimo J^{LMPC,j}_{t->t+N}(x_t).

A = par_lmpc.A;
B = par_lmpc.B;
n = size(A, 1);            % dimensione dello stato
m = size(B, 2);            % dimensione dell'ingresso
M = size(D, 2);            % numero di stati memorizzati

n_x = (N + 1)*n;           % incognite di stato
n_u = N*m;                 % incognite di ingresso
n_z = n_x + n_u + M;       % incognite totali

% Posizione delle incognite in z
pos_x      = @(k) k*n + (1:n);           % x_k, k = 0..N
pos_u      = @(k) n_x + k*m + (1:m);     % u_k, k = 0..N-1
pos_lambda = n_x + n_u + (1:M);

% Costo 1/2 z'*H*z + f'*z: H porta i termini quadratici di h, f i costi realizzati
% (blocchi diagonali: 2Q per x_0..x_{N-1}, 0 per x_N, 2R per u_0..u_{N-1}, 0 per lambda)
H = blkdiag(kron(speye(N), 2*par_lmpc.Q), sparse(n, n), ...
            kron(speye(N), 2*par_lmpc.R), sparse(M, M));
f = zeros(n_z, 1);
f(pos_lambda) = c(:);

% Vincoli di uguaglianza Aeq*z = beq
n_eq = n + N*n + n + 1;
Aeq  = zeros(n_eq, n_z);
beq  = zeros(n_eq, 1);
riga = 0;
% stato iniziale x_0 = x_t
Aeq(riga + (1:n), pos_x(0)) = eye(n);
beq(riga + (1:n))           = x_t;
riga = riga + n;
% dinamica x_{k+1} - A x_k - B u_k = 0
for k = 0:N-1
    Aeq(riga + (1:n), pos_x(k + 1)) = eye(n);
    Aeq(riga + (1:n), pos_x(k))     = -A;
    Aeq(riga + (1:n), pos_u(k))     = -B;
    riga = riga + n;
end
% vincolo terminale x_N - D*lambda = 0
Aeq(riga + (1:n), pos_x(N))   = eye(n);
Aeq(riga + (1:n), pos_lambda) = -D;
riga = riga + n;
% somma dei pesi uguale a 1
Aeq(riga + 1, pos_lambda) = 1;
beq(riga + 1)             = 1;
Aeq = sparse(Aeq);

% Limiti sulle incognite
lb = -inf(n_z, 1);
ub =  inf(n_z, 1);
for k = 0:N
    lb(pos_x(k)) = par_lmpc.x_min;
    ub(pos_x(k)) = par_lmpc.x_max;
end
for k = 0:N-1
    lb(pos_u(k)) = par_lmpc.u_min;
    ub(pos_u(k)) = par_lmpc.u_max;
end
lb(pos_lambda) = 0;

% Passo 1: QP completo con il metodo a punto interno. E' veloce anche con
% migliaia di pesi lambda, ma la sua precisione assoluta sul costo e' circa
% 1e-8: vicino a x_F, dove il costo vale meno di epsilon = 1e-8, non basta
% a decidere la fine dell'iterazione [P-34].
[z, J_lmpc, esito] = quadprog(H, f, [], [], Aeq, beq, lb, ub, [], par_lmpc.opzioni_qp);
if esito ~= 1
    u_t = zeros(m, 1);
    return
end

% Passo 2: rifinitura. All'ottimo quasi tutti i pesi lambda sono nulli: si
% risolve di nuovo lo stesso QP tenendo solo i pesi non nulli trovati al
% passo 1 (gli altri fissati a 0), con l'algoritmo active-set, che trova il
% vertice ottimo esatto del problema ridotto.
% Un peso escluso lambda_i converrebbe se il suo costo ridotto
%   c_i - D(:,i)'*mu_x + mu_1
% fosse negativo. mu_x e mu_1 sono i moltiplicatori di quadprog del vincolo
% terminale x_N - D*lambda = 0 e della somma dei pesi; il costo ridotto e'
% il moltiplicatore del limite lambda_i >= 0, che all'ottimo non puo' essere
% negativo (condizioni KKT). I pesi con costo ridotto negativo si aggiungono
% e si risolve di nuovo, finche' non ce ne sono piu': a quel punto la
% soluzione ridotta e' anche quella del QP completo.
righe_terminale = n + N*n + (1:n);       % righe di Aeq di x_N - D*lambda = 0
riga_somma      = n + N*n + n + 1;       % riga di Aeq della somma dei pesi
lambda_inclusi  = find(z(pos_lambda) > par_lmpc.soglia_lambda);
for ripetizione = 1:20
    pos_ridotte = [1:(n_x + n_u), n_x + n_u + lambda_inclusi.'];
    [z_ridotta, J_ridotto, esito_ridotto, ~, moltiplicatori] = quadprog( ...
        full(H(pos_ridotte, pos_ridotte)), f(pos_ridotte), [], [], ...
        full(Aeq(:, pos_ridotte)), beq, lb(pos_ridotte), ub(pos_ridotte), ...
        z(pos_ridotte), par_lmpc.opzioni_rifinitura);
    if esito_ridotto ~= 1
        break                            % resta la soluzione del passo 1
    end
    z = zeros(n_z, 1);
    z(pos_ridotte) = z_ridotta;
    J_lmpc = J_ridotto;

    mu_x = moltiplicatori.eqlin(righe_terminale);
    mu_1 = moltiplicatori.eqlin(riga_somma);
    costo_ridotto = c(:) - D.'*mu_x + mu_1;
    da_aggiungere = setdiff(find(costo_ridotto < -1e-12), lambda_inclusi);
    if isempty(da_aggiungere)
        break
    end
    lambda_inclusi = [lambda_inclusi; da_aggiungere(:)];   %#ok<AGROW>
end
u_t = z(pos_u(0));

end


function [x, u, costo_finale] = traiettoria_iniziale(par_lmpc, x_S)
%TRAIETTORIA_INIZIALE  Iterazione 0 (Assumption 1): LQR saturato e lento.
%
% u_t = sat(-K_0 x_t), con K_0 guadagno LQR per i pesi Q e R_0 = 100. Ci si
% ferma quando ||x_t||^2 <= epsilon (stato arrivato in x_F). La traiettoria
% deve rispettare i vincoli: se non li rispetta lo script si ferma.
%
% costo_finale e' il costo che la stessa legge pagherebbe da x_{t_0} in poi.
% Vicino a x_F la legge non satura (|K_0 x| << 1), quindi e' lineare,
% u = -K_0 x, e il costo vale x'*P_0*x, con P_0 soluzione dell'equazione di
% Lyapunov P_0 = (A - B K_0)'*P_0*(A - B K_0) + Q + K_0'*R*K_0.

A = par_lmpc.A;
B = par_lmpc.B;
K_0 = dlqr(A, B, par_lmpc.Q, par_lmpc.R_0);

x   = x_S;
u   = zeros(size(B, 2), 0);
x_t = x_S;
for t = 0:par_lmpc.t_max
    if x_t.'*x_t <= par_lmpc.epsilon
        break
    end
    u_t = min(max(-K_0*x_t, par_lmpc.u_min), par_lmpc.u_max);
    x_t = A*x_t + B*u_t;
    x   = [x, x_t];        %#ok<AGROW>
    u   = [u, u_t];        %#ok<AGROW>
end

if any(x < par_lmpc.x_min - 1e-12, 'all') || any(x > par_lmpc.x_max + 1e-12, 'all')
    error('traiettoria_iniziale:vincoli', ...
        'L''iterazione 0 da x_S = %s viola i vincoli di stato: cambiare R_0', mat2str(x_S.'));
end
if x_t.'*x_t > par_lmpc.epsilon
    error('traiettoria_iniziale:durata', 'L''iterazione 0 non arriva in x_F entro t_max passi');
end

A_chiuso = A - B*K_0;
P_0 = dlyap(A_chiuso.', par_lmpc.Q + K_0.'*par_lmpc.R*K_0);
costo_finale = x_t.'*P_0*x_t;

end


function c = costi_realizzati(par_lmpc, x, u, costo_finale)
%COSTI_REALIZZATI  Costo pagato da ogni stato memorizzato in poi [P-12], [P-17].
%
% x ha t_j + 1 colonne (x_0 ... x_{t_j}), u ne ha t_j. Ricorsione a ritroso
%   J_{s->inf}(x_s) = h(x_s, u_s) + J_{s+1->inf}(x_{s+1}),
% partendo da J_{t_j->inf}(x_{t_j}) = costo_finale.
% Le traiettorie del paper sono infinite; qui si fermano in x_{t_j}, vicino
% a x_F ma non in x_F. Il costo residuo costo_finale (dell'ordine di epsilon) e'
% quello di una continuazione ammissibile da x_{t_j}: cosi' ogni costo
% memorizzato resta una stima per eccesso del costo ottimo, come richiede
% la teoria. Con costo residuo 0 i punti vicino a x_F dichiarerebbero un
% costo piu' basso del vero, e il costo terminale potrebbe sottostimare
% l'ottimo di circa epsilon.

t_j = size(u, 2);
c   = zeros(1, t_j + 1);
c(t_j + 1) = costo_finale;
for s = t_j:-1:1           % indice MATLAB s <-> istante s-1
    c(s) = costo_stadio(par_lmpc, x(:, s), u(:, s)) + c(s + 1);
end

end


function h = costo_stadio(par_lmpc, x, u)
%COSTO_STADIO  h(x,u) = x'*Q*x + u'*R*u = ||x||^2 + ||u||^2 [P-33a].
h = x.'*par_lmpc.Q*x + u.'*par_lmpc.R*u;
end


function distanza = distanza_traiettorie(x_a, x_b, x_F)
%DISTANZA_TRAIETTORIE  max_t ||x_b(:,t) - x_a(:,t)||_2, come in [P-35].
% Le due traiettorie possono avere lunghezze diverse: la piu' corta si
% prolunga con x_F, dove lo stato resta.
lunghezza = max(size(x_a, 2), size(x_b, 2));
x_a = [x_a, repmat(x_F, 1, lunghezza - size(x_a, 2))];
x_b = [x_b, repmat(x_F, 1, lunghezza - size(x_b, 2))];
distanza = max(vecnorm(x_b - x_a, 2, 1));
end


function ottimo = clqr_ottimo(par_lmpc, x_S)
%CLQR_OTTIMO  Soluzione ottima del CLQR a orizzonte infinito [P-33], [P-36].
%
% Il paper usa l'algoritmo di Borrelli (2003). Qui si usa un risultato
% equivalente per questo problema: un QP a orizzonte finito lungo N_lungo,
% con costo terminale x_N'*P_lqr*x_N (P_lqr dalla Riccati), ha la stessa
% soluzione del problema a orizzonte infinito se da x_N la legge LQR
% non satura nessun vincolo per sempre (Borrelli, Bemporad, Morari, cap. 12).
% La condizione si controlla simulando l'LQR da x_N.

A = par_lmpc.A;
B = par_lmpc.B;
n = size(A, 1);
m = size(B, 2);
N_lungo = 60;
[K_lqr, P_lqr] = dlqr(A, B, par_lmpc.Q, par_lmpc.R);

% Forma condensata: X = S_x*x_S + S_u*U, X = [x_1; ...; x_N], U = [u_0; ...; u_{N-1}]
S_x = zeros(N_lungo*n, n);
S_u = zeros(N_lungo*n, N_lungo*m);
for k = 1:N_lungo
    S_x((k-1)*n + (1:n), :) = A^k;
    for l = 1:k
        S_u((k-1)*n + (1:n), (l-1)*m + (1:m)) = A^(k-l)*B;
    end
end
Q_barra = blkdiag(kron(eye(N_lungo - 1), par_lmpc.Q), P_lqr);   % pesi su x_1..x_N
R_barra = kron(eye(N_lungo), par_lmpc.R);
H = 2*(S_u.'*Q_barra*S_u + R_barra);
H = (H + H.')/2;
f = 2*S_u.'*Q_barra*S_x*x_S;
A_dis = [S_u; -S_u];
b_dis = [repmat(par_lmpc.x_max, N_lungo, 1) - S_x*x_S; -repmat(par_lmpc.x_min, N_lungo, 1) + S_x*x_S];
lb = repmat(par_lmpc.u_min, N_lungo, 1);
ub = repmat(par_lmpc.u_max, N_lungo, 1);
[U, ~, esito] = quadprog(H, f, A_dis, b_dis, [], [], lb, ub, [], par_lmpc.opzioni_qp);
if esito ~= 1
    error('clqr_ottimo:qp', 'QP del CLQR non risolto (esito %d)', esito);
end

% Traiettoria ottima: N_lungo passi del QP, poi la legge LQR fino a x_F
ottimo.x = [x_S, reshape(S_x*x_S + S_u*U, n, N_lungo)];
ottimo.u = reshape(U, m, N_lungo);
x_t = ottimo.x(:, end);
for t = 1:200
    u_t = -K_lqr*x_t;
    if any(u_t < par_lmpc.u_min | u_t > par_lmpc.u_max) || any(x_t < par_lmpc.x_min | x_t > par_lmpc.x_max)
        error('clqr_ottimo:lqr', 'Da x_N la legge LQR satura un vincolo: aumentare N_lungo');
    end
    x_t = A*x_t + B*u_t;
    ottimo.u = [ottimo.u, u_t];
    ottimo.x = [ottimo.x, x_t];
end

% Costo ottimo J*_{0->inf}(x_S)
ottimo.J = 0;
for t = 1:size(ottimo.u, 2)
    ottimo.J = ottimo.J + costo_stadio(par_lmpc, ottimo.x(:, t), ottimo.u(:, t));
end

end


function [sigma, sigma_max, Delta_J] = confronto_ottimo(result, ottimo)
%CONFRONTO_OTTIMO  Errori della traiettoria stazionaria dell'LMPC [P-37]-[P-39].
%
% sigma_t   = ||x^inf_t - x^*_t||_2                         [P-37]
% sigma_max = max_t sigma_t                                 [P-38]
% Delta_J   = |J* - J^inf| / J* * 100  (in percento)        [P-39]

% Si confrontano i passi 0..t_inf dell'iterazione stazionaria (l'ottima e'
% piu' lunga: prosegue con la legge LQR fino a x_F)
x_inf = result.x_stazionaria;
lunghezza = size(x_inf, 2);
sigma = vecnorm(x_inf - ottimo.x(:, 1:lunghezza), 2, 1);
sigma_max = max(sigma);
Delta_J = abs(ottimo.J - result.J_stazionaria)/ottimo.J*100;

end
