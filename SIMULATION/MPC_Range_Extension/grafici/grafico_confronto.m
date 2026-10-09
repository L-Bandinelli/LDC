function fig = grafico_confronto(risultati, par, titolo, finestra)
%GRAFICO_CONFRONTO  Controllori a confronto (stile Fig. 3 e Fig. 5 del paper).
%
% risultati e' un cell array di uscite di simula_pacco. Pannelli: tensione
% della cella piu' bassa e sforzo di bilanciamento e_k = u_k'*u_k.
% finestra = [t1 t2] limita l'asse dei tempi (facoltativo).

st  = stile_grafici();
fig = figure('Color', st.sfondo, 'Position', [80 60 900 600]);
tl  = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, titolo, 'FontWeight', 'bold');

ax1 = pannello(tl, st, 'Tensione minima min_n y^n [V]');
ax2 = pannello(tl, st, 'Sforzo e [A^2]');
xlabel(ax2, 'Tempo [s]');

nomi = cell(1, numel(risultati));
for c = 1:numel(risultati)
    ris    = risultati{c};
    colore = st.controllo.(ris.tipo);
    nomi{c} = st.nome.(ris.tipo);
    plot(ax1, ris.t, min(ris.y, [], 2), 'Color', colore, 'LineWidth', 1.2);
    if ~strcmp(ris.tipo, 'nessuno')
        plot(ax2, ris.t, ris.sforzo, 'Color', colore, 'LineWidth', 1.2);
    end
end
yline(ax1, par.mpc.y_min, '--', 'y_{min}', 'Color', st.limite, ...
    'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
legend(ax1, nomi, 'Location', 'northeast', 'Box', 'off', 'NumColumns', numel(nomi));

if nargin > 3
    xlim([ax1 ax2], finestra);
end
linkaxes([ax1 ax2], 'x');

end

function ax = pannello(tl, st, etichetta)
ax = nexttile(tl);
hold(ax, 'on');
grid(ax, 'on');
box(ax, 'off');
ax.Toolbar.Visible = 'off';
set(ax, 'Color', st.sfondo, 'GridColor', st.griglia, 'GridAlpha', 1, ...
    'XColor', st.assi, 'YColor', st.assi);
ylabel(ax, etichetta);
end
