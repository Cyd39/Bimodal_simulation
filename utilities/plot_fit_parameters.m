function plot_fit_parameters(fit_parameters, modality)
    % Plot matrix of fit parameters for unimodal experiments
    % Inputs:
    %   fit_parameters: structure containing arrays of fit parameters
    %   modality: string indicating the modality ('vibration' or 'auditory')
    
    % Extract parameters
    params = [fit_parameters.alpha;
             fit_parameters.beta;
             fit_parameters.gamma;
             fit_parameters.lambda]';
    
    % Parameter names
    param_names = {'Threshold (α)', 'Slope (β)', 'Guess Rate (γ)', 'Lapse Rate (λ)'};
    
    % Define colors
    colors = struct(...
        'scatter', [0.2 0.4 0.8], ...  % Deep blue for scatter points
        'hist', [0.8 0.9 1], ...       % Light blue for histogram
        'mean', [0.8 0.2 0.2], ...     % Red for mean line
        'std', [1 0.6 0.6]);           % Light red for std range
    
    % Create figure with white background
    figure('Name', sprintf('%s Fit Parameters Analysis', upper(modality)), ...
           'Position', [100 100 1000 800], ...
           'Color', 'white');
    
    % Create subplot grid
    n_params = 4;
    for i = 1:n_params
        for j = 1:n_params
            ax = subplot(n_params, n_params, (i-1)*n_params + j);
            
            % Set common properties for all subplots
            set(ax, 'Box', 'on', ...
                'LineWidth', 1.2, ...
                'FontSize', 10, ...
                'TickLength', [0.02 0.02]);
            
            if i == j  % Diagonal - histogram
                % Create histogram with custom style and normalized counts
                h = histogram(params(:,i), 'Orientation', 'horizontal', 'Normalization', 'probability');
                h.FaceColor = colors.hist;
                h.EdgeColor = colors.scatter;
                h.FaceAlpha = 0.7;
                h.NumBins = min(15, round(length(params)/2));
                
                % Add mean and std lines
                hold on;
                mean_val = mean(params(:,i));
                std_val = std(params(:,i));
                xlim_current = xlim;
                
                % Plot mean line
                plot([0 xlim_current(2)], [mean_val mean_val], ...
                    'Color', colors.mean, 'LineWidth', 2, 'LineStyle', '-');
                
                % Plot std range with gradient fill
                y = [mean_val-std_val mean_val+std_val];
                x = [0 0; xlim_current(2) xlim_current(2)];
                patch([x(1,:) fliplr(x(2,:))], [y(1) y(1) y(2) y(2)], ...
                    colors.std, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                
                % Add kernel density estimation curve
                [f, xi] = ksdensity(params(:,i));
                % Scale the density to match histogram height
                f = f * max(h.Values) / max(f);
                % Plot density curve
                plot(f, xi, 'Color', [0.2 0.2 0.2], 'LineWidth', 1.5);
                
                % Update axis limits to accommodate density curve
                xlim([0 max(xlim_current(2), max(f)*1.1)]);
                ylim([min(xi)*0.9, max(xi)*1.1]);
                
            else  % Off-diagonal - scatter plot
                % Create scatter plot with custom style
                scatter(params(:,j), params(:,i), 50, colors.scatter, ...
                    'filled', 'MarkerFaceAlpha', 0.6, ...
                    'MarkerEdgeColor', 'none');
                
                % Add trend line
                hold on;
                p = polyfit(params(:,j), params(:,i), 1);
                x_trend = linspace(min(params(:,j)), max(params(:,j)), 100);
                y_trend = polyval(p, x_trend);
                plot(x_trend, y_trend, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2);
                
                % Add grid with custom style
                grid on;
                set(ax, 'GridAlpha', 0.15, 'GridLineStyle', '-');
            end
            
            % Add labels with improved positioning
            if i == n_params  % Bottom row
                xlabel(param_names{j}, 'Rotation', 20, ...
                    'HorizontalAlignment', 'right', ...
                    'FontWeight', 'bold');
            end
            if j == 1  % Left column
                ylabel(param_names{i}, 'Rotation', 0, ...
                    'HorizontalAlignment', 'right', ...
                    'FontWeight', 'bold');
            end
            
            % Adjust axis limits
            if i == j
                xlim([0 max(get(gca, 'XLim'))]);
            else
                axis tight;
                ax_limits = axis;
                axis_range = [ax_limits(2)-ax_limits(1), ax_limits(4)-ax_limits(3)];
                axis_padding = axis_range * 0.05;
                axis([ax_limits(1)-axis_padding(1), ax_limits(2)+axis_padding(1), ...
                      ax_limits(3)-axis_padding(2), ax_limits(4)+axis_padding(2)]);
            end
        end
    end
    
    % Add title with improved style
    sgtitle(sprintf('%s Parameters Analysis (N=%d sessions)', ...
        upper(modality), length(fit_parameters.alpha)), ...
        'FontSize', 16, 'FontWeight', 'bold');
    
    % Adjust subplot spacing
    set(gcf, 'Units', 'normalized');
    pos = get(gcf, 'Position');
    set(gcf, 'Position', [pos(1) pos(2) pos(3) pos(3)]);  % Make figure square
    
    % Create statistics table with improved style
    stats_data = array2table([
        mean(params);
        std(params);
        median(params);
        min(params);
        max(params)
    ], 'VariableNames', {'Alpha', 'Beta', 'Gamma', 'Lambda'}, ...
       'RowNames', {'Mean', 'Std', 'Median', 'Min', 'Max'});
    
    % Create a new figure for statistics with improved style
    figure('Name', sprintf('%s Fit Parameters Statistics', upper(modality)), ...
           'Position', [1120 100 600 200], ...
           'Color', 'white');
    
    % Create uitable with improved style
    t = uitable('Data', table2cell(stats_data), ...
           'RowName', stats_data.Properties.RowNames, ...
           'ColumnName', param_names, ...
           'Units', 'normalized', ...
           'Position', [0.05 0.05 0.9 0.9], ...
           'FontSize', 12);
    
    % Adjust table style
    t.BackgroundColor = [1 1 1; 0.97 0.97 1];  % Alternate row colors
    t.RowStriping = 'on';
end 