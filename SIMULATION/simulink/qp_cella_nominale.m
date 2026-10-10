function sigma0 = qp_cella_nominale(sl, s, Vp, i_pacco)
%QP_CELLA_NOMINALE  Riferimento della cella nominale per J_t, eq. (7).
%
% La cella nominale (parametri senza deviazione) parte dalla media degli
% stati del pacco e viene integrata su p passi con la sola corrente di pacco,
% senza bilanciamento. sigma0 e' p x 1: riga j <-> istante k+j.
% Stesso calcolo di mpc/traiettoria_nominale.m.

[y0, s0] = qp_predizione(sl.nominale, mean(s), mean(Vp), i_pacco, sl.p, sl.Ts_controllo);

if sl.sigma_tensione
    sigma0 = y0;
else
    sigma0 = s0;
end

end
