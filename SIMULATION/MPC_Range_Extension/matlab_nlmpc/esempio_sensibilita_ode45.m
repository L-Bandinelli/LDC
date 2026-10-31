function esempio_sensibilita_ode45
%ESEMPIO_SENSIBILITA_ODE45  Derivate parametriche a tempo continuo, con ode45.
%
% Esempio minimo dei concetti della sezione 5 di DOCUMENTS/Linearizzazione_MPC.pdf
% (paragrafo "Espressione generale"), su un sistema massa-molla-smorzatore.
%
% Sistema, con stato x = (x1, x2) = (posizione, velocita') e forza F costante:
%   dx1/dt = x2
%   dx2/dt = ( F - k*x1 - c(x1)*x2 ) / m
% Il coefficiente che dipende dallo stato e' lo smorzamento, con relazione nota:
%   c(x1) = c0 + c1*x1^2
% La forza F e' il parametro rispetto a cui si deriva.
%
% Derivate parametriche dello stato, S = dx/dF = (S1, S2):
%   dS/dt = (df/dx)*S + df/dF,      S(0) = 0
% con le due jacobiane del secondo membro f
%   df/dx = [          0                    1     ]      df/dF = [  0  ]
%           [ -(k + 2*c1*x1*x2)/m      -c(x1)/m   ]              [ 1/m ]
%
% Lo script:
%   1) integra insieme stato e derivate con la forza F
%   2) con S predice la traiettoria che si avrebbe con un'altra forza,
%      senza integrare di nuovo:  x(t) + S(t)*delta_F
%   3) la confronta con la traiettoria vera, integrata con la nuova forza

%% Coefficienti del sistema
m  = 1;                 % massa
k  = 4;                 % molla
c0 = 0.4;               % smorzatore: c(x1) = c0 + c1*x1^2
c1 = 2;

%% Punto attorno a cui si linearizza
x0 = [0; 0];                        % stato iniziale, noto
F  = 2;                             % forza, costante nel tempo
t  = linspace(0, 15, 301)';         % istanti in cui leggere la soluzione

opzioni = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);

%% 1) Stato e derivate parametriche, integrati insieme
% z = [x1; x2; S1; S2]. S(0) = 0: lo stato iniziale non dipende da F.
z0 = [x0; 0; 0];
[~, z] = ode45(@(t, z) stato_e_derivate(z, F, m, k, c0, c1), t, z0, opzioni);
x1 = z(:, 1);       x2 = z(:, 2);
S1 = z(:, 3);       S2 = z(:, 4);

%% 2) Predizione al primo ordine con un'altra forza, F + delta_F
delta_F = 3;
x1_predetto = x1 + S1*delta_F;
x2_predetto = x2 + S2*delta_F;

%% 3) Traiettoria vera con la nuova forza
[~, z] = ode45(@(t, z) stato_e_derivate(z, F + delta_F, m, k, c0, c1), t, z0, opzioni);
x1_vero = z(:, 1);
x2_vero = z(:, 2);

fprintf('Con delta_F = %.2f, scarto massimo tra predizione al primo ordine e traiettoria vera:\n', delta_F);
fprintf('   x1  %.2e      x2  %.2e\n', max(abs(x1_predetto - x1_vero)), max(abs(x2_predetto - x2_vero)));

% La retta vale vicino al punto di linearizzazione: lo scarto cresce con delta_F
fprintf('\n     delta_F      scarto massimo su x1\n');
for prova = [0.1 0.5 1 2]
    [~, z] = ode45(@(t, z) stato_e_derivate(z, F + prova, m, k, c0, c1), t, z0, opzioni);
    fprintf('   %5.2f      %.2e\n', prova, max(abs(x1 + S1*prova - z(:, 1))));
end

%% Grafici
figure('Name', 'Derivate parametriche a tempo continuo', 'Color', 'w');

subplot(2, 2, 1)
plot(t, S1, 'LineWidth', 1.2), grid on
xlabel('t'), ylabel('S_1 = dx_1/dF')
title('Derivata parametrica della posizione')

subplot(2, 2, 2)
plot(t, S2, 'LineWidth', 1.2), grid on
xlabel('t'), ylabel('S_2 = dx_2/dF')
title('Derivata parametrica della velocita''')

subplot(2, 2, 3)
plot(t, x1, 'k', t, x1_vero, 'b', t, x1_predetto, 'r--', 'LineWidth', 1.2), grid on
xlabel('t'), ylabel('x_1')
legend(sprintf('con F = %g', F), sprintf('vera con F = %g', F + delta_F), ...
    'predetta con S_1', 'Location', 'southeast')
title('Posizione')

subplot(2, 2, 4)
plot(t, x2, 'k', t, x2_vero, 'b', t, x2_predetto, 'r--', 'LineWidth', 1.2), grid on
xlabel('t'), ylabel('x_2')
legend(sprintf('con F = %g', F), sprintf('vera con F = %g', F + delta_F), ...
    'predetta con S_2', 'Location', 'northeast')
title('Velocita''')

end

function dt_z = stato_e_derivate(z, F, m, k, c0, c1)
% Secondo membro del sistema aumentato: stato x e derivate parametriche S.
x = z(1:2);
S = z(3:4);

% Coefficiente che dipende dallo stato, e sua derivata rispetto a x1
c      = c0 + c1*x(1)^2;
dx1_c = 2*c1*x(1);

% Stato: dx/dt = f(x, F) 
dt_x = [x(2); ...
     (F - k*x(1) - c*x(2)) / m];

% Jacobiane di f, valutate nello stato attuale
dx_f = [ 0,                        1; ...
         -(k + dx1_c*x(2)) / m,   -c / m];
dF_f = [0; ...
         1 / m];

% Derivate parametriche: dS/dt = (df/dx)*S + df/dF
dt_S = dx_f*S + dF_f;

dt_z = [dt_x; dt_S];
end
