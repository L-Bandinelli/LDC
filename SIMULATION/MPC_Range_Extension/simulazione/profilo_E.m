function E = profilo_E(scen, t)
%PROFILO_E  F.e.m. del carico all'istante t.
%
% scen.E scalare: costante. Altrimenti scen.t_E, scen.E sono i punti di un
% periodo, interpolati linearmente e ripetuti.

if isscalar(scen.E)
    E = scen.E;
else
    E = interp1(scen.t_E, scen.E, mod(t, scen.t_E(end)));
end

end
