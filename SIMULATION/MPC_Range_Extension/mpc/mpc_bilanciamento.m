function [u, ctrl, info] = mpc_bilanciamento(ctrl, s, Vp, i_pacco)
%MPC_BILANCIAMENTO  Un passo dell'MPC: correnti di bilanciamento u (N x 1).
%
% ctrl viene da crea_mpc e va ripassato al passo successivo: contiene l'ultima
% mossa e i valori iniziali per l'ottimizzatore. La mossa e' calcolata da
% nlmpcmove sullo stato misurato [s; Vp], con la corrente di pacco misurata
% tenuta costante sull'orizzonte (nessuna preview).
%
% info.flag e' l'ExitFlag di nlmpcmove (positivo o nullo: soluzione valida),
% info.morbido dice se il vincolo di tensione e' stato rilassato, eq. (17).

dati = ctrl.dati;
N    = dati.pacco.numero_celle;
p    = dati.p;

if strcmp(dati.tipo, 'Jt')
    dati.sigma0 = traiettoria_nominale(dati.pacco, s, Vp, i_pacco, p, ...
        dati.par.mpc.Ts, dati.par.mpc.sigma);
end

if isempty(ctrl.mv)
    % Primo passo: u nulla, eps al valore attuale di sigma
    if dati.par.mpc.sigma == 'y'
        sigma = modello_cella(dati.pacco, s, Vp, i_pacco);
    else
        sigma = s;
    end
    switch dati.tipo
        case 'Jt',     eps0 = [];
        case 'Jm',     eps0 = min(sigma)*ones(p, 1);
        case 'Jdelta', eps0 = [min(sigma)*ones(p, 1); max(sigma)*ones(p, 1)];
    end
    ctrl.mv = [zeros(N, 1); eps0];
end

ctrl.opt.Parameters = {dati};
[mv, ctrl.opt, esito] = nlmpcmove(ctrl.nlobj, [s; Vp], ctrl.mv, [], i_pacco, ctrl.opt);

info.flag    = esito.ExitFlag;
info.morbido = esito.Slack > 1e-6;
if info.flag >= 0
    ctrl.mv = mv;               % altrimenti si mantiene la mossa precedente
end
u = ctrl.mv(1:N);

end
