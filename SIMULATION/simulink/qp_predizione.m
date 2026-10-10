function [Y, S, dY, dS] = qp_predizione(celle, s, Vp, i_cella, p, Ts)
%QP_PREDIZIONE  Predizione su p passi a corrente costante e sua linearizzazione.
%
% Integra il modello di cella, eq. (2a)-(2c), per p passi con la corrente
% i_cella tenuta costante (eq. (6b)-(6c): u non cambia sull'orizzonte e la
% corrente di pacco non ha preview). Insieme alla traiettoria calcola le
% derivate rispetto alla corrente, che servono a linearizzare la predizione
% (Remark 3 del paper):
%
%   y_{k+j}(u) ~= Y(j,:) + dY(j,:) .* (u - u_prec)
%
%   celle     tabelle, fattori e kappa delle celle (sl.pacco oppure sl.nominale)
%   s, Vp     stato attuale, un valore per cella
%   i_cella   corrente di ogni cella, i + u, positiva in scarica
%   Y, S      tensione e SOC predetti, p x N: riga j <-> istante k+j
%   dY, dS    derivate di Y e S rispetto alla corrente della stessa cella
%
% Le celle non si influenzano tra loro: ogni colonna dipende solo dalla
% corrente della propria cella.

N  = numel(s);
Y  = zeros(p, N);   S  = zeros(p, N);
dY = zeros(p, N);   dS = zeros(p, N);

ds = zeros(N, 1);                  % d(s)/d(corrente), nullo all'istante k
dv = zeros(N, 1);                  % d(Vp)/d(corrente)

for j = 1:p
    % Parametri del ramo RC al SOC di inizio passo
    [R_pol, dR_pol] = qp_tabella(celle.tabella_SOC, celle.tabella_R_pol, celle.f_R_pol, s);
    [C_pol, dC_pol] = qp_tabella(celle.tabella_SOC, celle.tabella_C_pol, celle.f_C_pol, s);
    g  = 1 ./ (R_pol .* C_pol);
    h  = 1 ./ C_pol;
    dg = -(dR_pol .* C_pol + R_pol .* dC_pol) ./ (R_pol .* C_pol).^2;
    dh = -dC_pol ./ C_pol.^2;

    % (2b) ramo RC: Vp+ = Vp + Ts*(-g(s)*Vp + h(s)*i)
    dv = (1 - Ts .* g) .* dv + Ts .* (-dg .* Vp + dh .* i_cella) .* ds + Ts .* h;
    Vp = Vp + Ts .* (-g .* Vp + h .* i_cella);

    % (2a) conteggio della carica: s+ = min(s - kappa*i, 1)
    libero = double((s - celle.kappa .* i_cella) < 1);      % 0 se il SOC satura a 1
    ds = libero .* (ds - celle.kappa);
    s  = min(s - celle.kappa .* i_cella, 1);

    % (2c) tensione ai morsetti all'istante k+j
    [V_vuoto, dV_vuoto] = qp_tabella(celle.tabella_SOC, celle.tabella_V_vuoto, celle.f_V_vuoto, s);
    [R_serie, dR_serie] = qp_tabella(celle.tabella_SOC, celle.tabella_R_serie, celle.f_R_serie, s);

    Y(j, :)  = (V_vuoto - Vp - R_serie .* i_cella).';
    S(j, :)  = s.';
    dY(j, :) = ((dV_vuoto - i_cella .* dR_serie) .* ds - dv - R_serie).';
    dS(j, :) = ds.';
end

end
