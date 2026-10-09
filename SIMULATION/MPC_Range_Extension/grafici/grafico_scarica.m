function fig = grafico_scarica(base, mpc, par, titolo)
%GRAFICO_SCARICA  Scarica senza controllo e con MPC a confronto.
%
% base, mpc sono uscite di simula_pacco ('nessuno' e un MPC). Colonna sinistra
% senza controllo, colonna destra con MPC: tensioni di cella, SOC e correnti
% di bilanciamento. In basso la tensione della cella piu' bassa nei due casi,
% ingrandita sul tratto finale.

st = stile_grafici();
N  = size(base.y, 2);
nomi  = arrayfun(@(n) sprintf('Cella %d', n), 1:N, 'UniformOutput', false);
casi  = {base, mpc};
testa = {sprintf('Senza controllo: %.0f s', base.durata), ...
         sprintf('Con MPC %s: %.0f s (+%.1f %%)', st.nome.(mpc.tipo), mpc.durata, ...
                 100*(mpc.durata/base.durata - 1))};
t_fine = max(base.durata, mpc.durata);

fig = figure('Color', st.sfondo, 'Position', [60 40 1100 1050]);
tl  = tiledlayout(fig, 4, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, titolo, 'FontWeight', 'bold');

campi     = {'y', 's', 'u'};
etichette = {'Tensione y^n [V]', 'SOC s^n [-]', 'Bilanciamento u^n [A]'};
for riga = 1:3
    ax = gobjects(1, 2);
    for col = 1:2
        ax(col) = pannello(tl, st, etichette{riga});
        dati = casi{col}.(campi{riga});
        for n = 1:N
            plot(ax(col), casi{col}.t, dati(:, n), 'Color', st.celle(n, :), 'LineWidth', 1.2);
        end
        xlim(ax(col), [0 t_fine]);
        if riga == 1
            title(ax(col), testa{col}, 'FontWeight', 'normal');
            yline(ax(col), par.mpc.y_min, '--', 'y_{min}', 'Color', st.limite, ...
                'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
        end
        xline(ax(col), casi{col}.durata, ':', 'Color', st.limite, 'HandleVisibility', 'off');
    end
    linkaxes(ax, 'y');
    if riga == 1
        legend(ax(2), nomi, 'Location', 'northeast', 'Box', 'off', 'NumColumns', 3);
    elseif riga == 3
        ylim(ax, [par.mpc.u_min par.mpc.u_max] * 1.1);
    end
end

% Tratto finale: tensione della cella piu' bassa nei due casi
ax = pannello(tl, st, 'Tensione minima, tratto finale [V]', [1 2]);
plot(ax, base.t, min(base.y, [], 2), 'Color', st.controllo.nessuno, 'LineWidth', 1.6);
plot(ax, mpc.t,  min(mpc.y,  [], 2), 'Color', st.controllo.(mpc.tipo), 'LineWidth', 1.6);
yline(ax, par.mpc.y_min, '--', 'y_{min}', 'Color', st.limite, ...
    'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
xline(ax, base.durata, ':', sprintf('%.0f s', base.durata), 'Color', st.limite, ...
    'LabelVerticalAlignment', 'top', 'LabelOrientation', 'horizontal', ...
    'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
xline(ax, mpc.durata, ':', sprintf('%.0f s', mpc.durata), 'Color', st.limite, ...
    'LabelVerticalAlignment', 'top', 'LabelOrientation', 'horizontal', ...
    'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
t_zoom = max(0, base.durata - 0.25*t_fine);
xlim(ax, [t_zoom, t_fine + 0.03*(t_fine - t_zoom)]);
y_zoom = min(base.y(base.t >= t_zoom, :), [], 2);
ylim(ax, [par.mpc.y_min - 0.02, max(y_zoom) + 0.02]);
legend(ax, {'Senza controllo', ['Con MPC ' st.nome.(mpc.tipo)]}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal', 'Box', 'off');
xlabel(ax, 'Tempo [s]');

end

function ax = pannello(tl, st, etichetta, estensione)
if nargin < 4
    ax = nexttile(tl);
else
    ax = nexttile(tl, estensione);
end
hold(ax, 'on');
grid(ax, 'on');
box(ax, 'off');
ax.Toolbar.Visible = 'off';
set(ax, 'Color', st.sfondo, 'GridColor', st.griglia, 'GridAlpha', 1, ...
    'XColor', st.assi, 'YColor', st.assi);
ylabel(ax, etichetta);
end
