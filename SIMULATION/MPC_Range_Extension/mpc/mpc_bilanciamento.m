function [u, ctrl, info] = mpc_bilanciamento(ctrl, s, Vp, i_pacco)
%MPC_BILANCIAMENTO  Un passo dell'MPC: correnti di bilanciamento u (N x 1).
%
% ctrl viene da crea_mpc e va ripassato al passo successivo: contiene l'ultima
% mossa e i valori iniziali per l'ottimizzatore. La mossa e' calcolata da
% nlmpcmove sullo stato misurato zeta = [s; Vp], con la corrente di pacco
% misurata i_pacco tenuta costante sull'orizzonte (nessuna preview).
%
% info.esito e' l'ExitFlag di nlmpcmove (positivo o nullo: soluzione valida),
% info.morbido dice se il vincolo di tensione e' stato rilassato, eq. (17).

dati = ctrl.dati;
N    = dati.pacco.N;
p    = dati.p;

if strcmp(dati.tipo, 'Jt')
    dati.sigma0 = cella_nominale(dati.pacco, s, Vp, i_pacco, p, ...
        dati.par.mpc.Tc, dati.par.mpc.sigma);
end

if isempty(ctrl.mv)
    % Primo passo: u nulla, epsilon al valore attuale di sigma
    if dati.par.mpc.sigma == 'y'
        sigma = modello_cella(dati.pacco, s, Vp, i_pacco);
    else
        sigma = s;
    end
    switch dati.tipo
        case 'Jt',     epsilon_iniziale = [];
        case 'Jm',     epsilon_iniziale = min(sigma)*ones(p, 1);
        case 'Jdelta', epsilon_iniziale = [min(sigma)*ones(p, 1); max(sigma)*ones(p, 1)];
    end
    ctrl.mv = [zeros(N, 1); epsilon_iniziale];
end

ctrl.opt.Parameters = {dati};
[mv, ctrl.opt, info_nlmpc] = nlmpcmove(ctrl.nlobj, [s; Vp], ctrl.mv, [], i_pacco, ctrl.opt);

info.esito   = info_nlmpc.ExitFlag;
info.morbido = info_nlmpc.Slack > 1e-6;
if info.esito >= 0
    ctrl.mv = mv;               % altrimenti si mantiene la mossa precedente
end
u = ctrl.mv(1:N);

end
