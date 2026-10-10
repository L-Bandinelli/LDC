function [z, esito] = qp_solutore(H, f, A, b, Aeq, beq, z0)
%QP_SOLUTORE  Risolve il QP dell'MPC con quadprog, come nel paper (Sez. IV-A).
%
%   min  1/2*z'*H*z + f'*z     con  A*z <= b,  Aeq*z = beq
%
% z0 e' il punto di partenza ammissibile costruito da qp_problema con la mossa
% del passo precedente: se quadprog non trova una soluzione, l'uscita e' z0 e
% la mossa precedente viene mantenuta.
% esito e' l'exitflag di quadprog (1 = soluzione trovata).

persistent opzioni
if isempty(opzioni)
    % 'active-set' si ferma su un vertice esatto: adatto a Jm e Jdelta, che
    % nelle eps sono problemi lineari
    opzioni = optimoptions('quadprog', 'Algorithm', 'active-set', 'Display', 'off');
end

[z, ~, esito] = quadprog(H, f, A, b, Aeq, beq, [], [], z0, opzioni);

if esito <= 0 || isempty(z)
    z = z0;
end

end
