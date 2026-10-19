function [dzeta_zeta_next, dmv_zeta_next] = jacobiano_stato(zeta, ingressi, dati)
%JACOBIANO_STATO  Jacobiani della funzione di stato zeta_next (Remark 3 del paper).
%
% zeta = [s; Vp] e' lo stato del pacco, ingressi = [u; epsilon; i_pacco] il
% vettore che nlmpc passa alla funzione di stato.
%   dzeta_zeta_next = d(zeta_{k+1})/d(zeta_k)   (2N x 2N)
%   dmv_zeta_next   = d(zeta_{k+1})/d(mv)       (2N x numero di variabili manipolate)

pacco   = dati.pacco;
Tc      = dati.par.mpc.Tc;
N       = pacco.N;
s       = zeta(1:N);
Vp      = zeta(N+1:2*N);
I_cella = ingressi(end) + ingressi(1:N);
[~, ~, Rp, Cp, ds] = parametri_cella(pacco, s);

% (2a): s_next = min(s - kappa*I_cella, 1)
kappa  = pacco.eta .* Tc ./ (3600*pacco.C) .* ones(N, 1);
libero = (s - kappa.*I_cella) < 1;            % derivata nulla se il SOC satura a 1

% (2b): Vp_next = Vp - Tc*inv_tau(s)*Vp + Tc*inv_Cp(s)*I_cella,  inv_tau = 1/(Rp*Cp),  inv_Cp = 1/Cp
inv_tau    = 1 ./ (Rp.*Cp);
inv_Cp     = 1 ./ Cp;
ds_inv_tau = -(ds.Rp.*Cp + Rp.*ds.Cp) ./ (Rp.*Cp).^2;
ds_inv_Cp  = -ds.Cp ./ Cp.^2;

dzeta_zeta_next = [diag(double(libero)),                         zeros(N);
                   diag(Tc.*(-ds_inv_tau.*Vp + ds_inv_Cp.*I_cella)), diag(1 - Tc.*inv_tau)];

dmv_zeta_next = zeros(2*N, numel(ingressi) - 1);
dmv_zeta_next(1:N, 1:N)     = diag(-kappa.*libero);
dmv_zeta_next(N+1:2*N, 1:N) = diag(Tc.*inv_Cp);

end
