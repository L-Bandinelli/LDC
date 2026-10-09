function st = stile_grafici()
%STILE_GRAFICI  Colori e nomi usati da tutte le figure.
%
% Ogni cella e ogni controllore ha sempre lo stesso colore.

st.celle = [ 42 120 214;      % cella 1
            235 104  52;      % cella 2
             27 175 122;      % cella 3
            237 161   0;      % cella 4
            232 123 164;      % cella 5
              0 131   0;      % cella 6
             74  58 167;      % cella 7
            227  73  72] / 255;   % cella 8

st.controllo.nessuno = [137 135 129] / 255;
st.controllo.Jt      = st.celle(1, :);
st.controllo.Jm      = st.celle(2, :);
st.controllo.Jdelta  = st.celle(3, :);

st.nome.nessuno = 'Senza bilanciamento';
st.nome.Jt      = 'J_t';
st.nome.Jm      = 'J_m';
st.nome.Jdelta  = 'J_\Delta';

st.sfondo  = [252 252 251] / 255;
st.griglia = [225 224 217] / 255;
st.assi    = [ 82  81  78] / 255;
st.limite  = [137 135 129] / 255;    % linea di y_min

end
