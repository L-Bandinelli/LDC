function [Y_bar, S_bar, d, alfa] = qp_predizione(celle, s, Vp, I_cella, p, Tc)
%QP_PREDIZIONE  Predizione su p passi a corrente costante e sua linearizzazione.
%
% Integra il modello di cella, eq. (2a)-(2c), per p passi con la corrente
% I_cella tenuta costante (eq. (6b)-(6c): u non cambia sull'orizzonte e la
% corrente di pacco non ha preview). Insieme alla traiettoria calcola i
% coefficienti di sensibilita' rispetto alla corrente, che servono a
% linearizzare la predizione (Remark 3 del paper):
%
%   y_{k+j}(u) ~= Y_bar(j,:) + d(j,:) .* (u - u_bar)
%
%   celle         tabelle, fattori e kappa delle celle (par_sim.pacco oppure par_sim.nominale)
%   s, Vp         stato attuale, un valore per cella
%   I_cella       corrente di ogni cella, i_pacco + u, positiva in scarica
%   Y_bar, S_bar  tensione e SOC predetti (traiettoria di linearizzazione),
%                 p x N: riga j <-> istante k+j
%   d, alfa       coefficienti di sensibilita' di tensione e SOC: derivate di
%                 Y_bar e S_bar rispetto alla corrente della stessa cella
%
% Le celle non si influenzano tra loro: ogni colonna dipende solo dalla
% corrente della propria cella.

N     = numel(s);
Y_bar = zeros(p, N);   S_bar = zeros(p, N);
d     = zeros(p, N);   alfa  = zeros(p, N);

alfa_j = zeros(N, 1);              % alfa_j = d(s)/d(corrente), nullo all'istante k
beta_j = zeros(N, 1);              % beta_j = d(Vp)/d(corrente)

for j = 1:p
    % Parametri del ramo RC al SOC di inizio passo
    [Rp, ds_Rp] = qp_tabella(celle.s_tab, celle.Rp_tab, celle.phi.Rp, s);
    [Cp, ds_Cp] = qp_tabella(celle.s_tab, celle.Cp_tab, celle.phi.Cp, s);
    inv_tau    = 1 ./ (Rp .* Cp);
    inv_Cp     = 1 ./ Cp;
    ds_inv_tau = -(ds_Rp .* Cp + Rp .* ds_Cp) ./ (Rp .* Cp).^2;
    ds_inv_Cp  = -ds_Cp ./ Cp.^2;

    % (2b) ramo RC: Vp_next = Vp + Tc*(-inv_tau(s)*Vp + inv_Cp(s)*I_cella)
    beta_j = (1 - Tc .* inv_tau) .* beta_j + Tc .* (-ds_inv_tau .* Vp + ds_inv_Cp .* I_cella) .* alfa_j + Tc .* inv_Cp;
    Vp     = Vp + Tc .* (-inv_tau .* Vp + inv_Cp .* I_cella);

    % (2a) conteggio della carica: s_next = min(s - kappa*I_cella, 1)
    libero = double((s - celle.kappa .* I_cella) < 1);      % 0 se il SOC satura a 1
    alfa_j = libero .* (alfa_j - celle.kappa);
    s      = min(s - celle.kappa .* I_cella, 1);

    % (2c) tensione ai morsetti all'istante k+j
    [Voc, ds_Voc] = qp_tabella(celle.s_tab, celle.Voc_tab, celle.phi.Voc, s);
    [Ro,  ds_Ro]  = qp_tabella(celle.s_tab, celle.Ro_tab,  celle.phi.Ro,  s);

    Y_bar(j, :) = (Voc - Vp - Ro .* I_cella).';
    S_bar(j, :) = s.';
    d(j, :)     = ((ds_Voc - I_cella .* ds_Ro) .* alfa_j - beta_j - Ro).';
    alfa(j, :)  = alfa_j.';
end

end
