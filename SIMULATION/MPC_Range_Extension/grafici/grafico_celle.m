function fig = grafico_celle(ris, par, titolo)
%GRAFICO_CELLE  Storie temporali di una simulazione (stile Fig. 2 del paper).
%
% Pannelli: tensioni di cella, SOC, correnti di bilanciamento, corrente di
% pacco e f.e.m. del carico.

st = stile_grafici();
N  = size(ris.y, 2);
nomi = arrayfun(@(n) sprintf('Cella %d', n), 1:N, 'UniformOutput', false);

fig = figure('Color', st.sfondo, 'Position', [80 60 900 1000]);
tl  = tiledlayout(fig, 5, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, titolo, 'FontWeight', 'bold');

ax = pannello(tl, st, 'Tensione y^n [V]');
linee(ax, ris.t, ris.y, st);
yline(ax, par.mpc.y_min, '--', 'y_{min}', 'Color', st.limite, ...
    'LabelHorizontalAlignment', 'left');
legend(ax, nomi, 'Location', 'northeast', 'Box', 'off', 'NumColumns', N);

ax = pannello(tl, st, 'SOC s^n [-]');
linee(ax, ris.t, ris.s, st);

ax = pannello(tl, st, 'Bilanciamento u^n [A]');
linee(ax, ris.t, ris.u, st);

ax = pannello(tl, st, 'Corrente di pacco i [A]');
plot(ax, ris.t, ris.i, 'Color', st.assi, 'LineWidth', 1.2);

ax = pannello(tl, st, 'F.e.m. del carico E [V]');
plot(ax, ris.t, ris.E, 'Color', st.assi, 'LineWidth', 1.2);
xlabel(ax, 'Tempo [s]');

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

function linee(ax, t, dati, st)
for n = 1:size(dati, 2)
    plot(ax, t, dati(:, n), 'Color', st.celle(n, :), 'LineWidth', 1.2);
end
end
