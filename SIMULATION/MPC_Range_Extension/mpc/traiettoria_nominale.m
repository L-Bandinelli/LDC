function sigma0 = traiettoria_nominale(pacco, s, Vp, i_pacco, p, Ts, sigma)
%TRAIETTORIA_NOMINALE  Riferimento della cella nominale per J_t, eq. (7).
%
% La cella nominale parte dalla media degli stati del pacco e viene integrata
% su p passi con la sola corrente di pacco. sigma0 e' p x 1.

nom = pacco.nominale;
s0  = mean(s);
Vp0 = mean(Vp);

sigma0 = zeros(p, 1);
for j = 1:p
    [~, s0, Vp0] = modello_cella(nom, s0, Vp0, i_pacco, Ts);
    if sigma == 'y'
        sigma0(j) = modello_cella(nom, s0, Vp0, i_pacco);
    else
        sigma0(j) = s0;
    end
end

end
