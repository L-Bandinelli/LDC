function [A, Bmv] = jacobiano_stato(x, u, dati)
%JACOBIANO_STATO  Jacobiani della funzione di stato stato_pacco (Remark 3 del paper).
%
% A = d(x+)/dx (2N x 2N), Bmv = d(x+)/d(mv) (2N x numero di variabili manipolate).

pacco = dati.pacco;
Ts = dati.par.mpc.Ts;
N  = pacco.numero_celle;
s  = x(1:N);
Vp = x(N+1:2*N);
ic = u(end) + u(1:N);
[~, ~, R_pol, C_pol, derivata] = parametri_cella(pacco, s);

% (2a): s+ = min(s - kappa*i, 1)
kappa  = pacco.rendimento .* Ts ./ (3600*pacco.capacita_Ah) .* ones(N, 1);
libero = (s - kappa.*ic) < 1;                 % derivata nulla se il SOC satura a 1

% (2b): Vp+ = Vp - Ts*g(s)*Vp + Ts*h(s)*i,  g = 1/(Rp*Cp),  h = 1/Cp
g  = 1 ./ (R_pol.*C_pol);
h  = 1 ./ C_pol;
dg = -(derivata.R_pol.*C_pol + R_pol.*derivata.C_pol) ./ (R_pol.*C_pol).^2;
dh = -derivata.C_pol ./ C_pol.^2;

A = [diag(double(libero)),             zeros(N);
     diag(Ts.*(-dg.*Vp + dh.*ic)),     diag(1 - Ts.*g)];

Bmv = zeros(2*N, numel(u) - 1);
Bmv(1:N, 1:N)     = diag(-kappa.*libero);
Bmv(N+1:2*N, 1:N) = diag(Ts.*h);

end
