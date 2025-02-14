function plot_results(trial_data, params)
    % Check if input parameters are from a loaded file
    if isstruct(trial_data) && isfield(trial_data, 'experiment_info')
        % If loaded from file, extract relevant data
        params = trial_data.experiment_info.params;
        trial_data = trial_data.experiment_info.trial_data;
    end
    
    % Get number of sessions
    n_sessions = params.n_sessions;
    
    % Generate colors for different sessions - limit to maximum 10 colors
    MAX_COLORS = 10;
    session_colors = distinguishable_colors(MAX_COLORS);  % Always generate 10 colors
    
    switch params.modality
        case {'vibration', 'auditory'}
            % Create new figure window
            figure('Name', sprintf('%s Detection - All Sessions', upper(params.modality)), ...
                   'Position', [50 50 1400 900]);
            
            % Adjust subplot layout
            if n_sessions <= 2
                n_rows = 2;
                n_cols = 2;
                summary_pos = [3 4];  % summary position in bottom left
            elseif n_sessions == 3
                n_rows = 2;
                n_cols = 3;
                summary_pos = [4 5];  % summary position in bottom right
            else  % n_sessions == 4
                n_rows = 2;
                n_cols = 4;  % 2 rows 4 columns layout
                summary_pos = [6 8];  % summary position in middle two grids of second row
            end
            
            % Set subplot spacing and margins
            set(gcf, 'Units', 'normalized');
            if n_sessions == 4
                % Reduce left/right margins, increase subplot spacing
                left_margin = 0.04;   % Reduce left margin
                right_margin = 0.04;  % Reduce right margin
                h_spacing = 0.02;     % Horizontal spacing between subplots
                
                % Calculate width for each subplot
                subplot_width = (1 - left_margin - right_margin - 3*h_spacing) / 4;
                
                % Create subplots for each session
                for i = 1:4
                    x_pos = left_margin + (i-1)*(subplot_width + h_spacing);
                    subplot('Position', [x_pos 0.55 subplot_width 0.35]);
                    session_data = trial_data([trial_data.Session] == i);
                    if isfield(session_data, 'fit_results')
                        fit_result = session_data(1).fit_results;
                    else
                        fit_result = [];
                    end
                    plot_unimodal_session(session_data, params, i, fit_result, session_colors(i,:));
                end
                
                % Create summary subplot
                x_pos = left_margin + subplot_width + h_spacing + (subplot_width + h_spacing);
                subplot('Position', [x_pos 0.1 subplot_width*2 0.35]);
                plot_unimodal_summary(trial_data, params, session_colors);
            else
                % Create subplots for each session
                for i = 1:min(n_sessions, 4)
                    subplot_pos = i;  % Position is always i for first row
                    
                    subplot(n_rows, n_cols, subplot_pos);
                    session_data = trial_data([trial_data.Session] == i);
                    if isfield(session_data, 'fit_results')
                        fit_result = session_data(1).fit_results;
                    else
                        fit_result = [];
                    end
                    plot_unimodal_session(session_data, params, i, fit_result, session_colors(i,:));
                end
                
                % Create summary plot
                if n_sessions == 4
                    % Create subplot spanning middle two grids
                    subplot(n_rows, n_cols, [6 7]);  % Use middle two grids in second row
                    plot_unimodal_summary(trial_data, params, session_colors);
                else
                    subplot(n_rows, n_cols, summary_pos);
                    plot_unimodal_summary(trial_data, params, session_colors);
                end
            end
            
            % Add main title
            sgtitle(sprintf('%s Detection - Sampled Sessions', upper(params.modality)), 'FontSize', 14);
            
            % Add fit parameters analysis plot if multiple sessions
            if n_sessions > 1 && isfield(trial_data, 'fit_parameters')
                plot_fit_parameters(trial_data(1).fit_parameters, params.modality);
            end
            
        case 'multimodal'
            % For multimodal experiment with single session, call original function
            plot_multimodal_results(trial_data, params);
    end
end

function plot_unimodal_session(trial_data, params, session_num, fit_result, color)
    % Extract data points
    stim_levels = unique([trial_data.Stimulus]);
    detection_rates = zeros(size(stim_levels));
    
    % Get modality-specific parameters
    if strcmp(params.modality, 'vibration')
        modal_params = params.vibration;
    else  % auditory
        modal_params = params.auditory;
    end
    
    for i = 1:length(stim_levels)
        idx = [trial_data.Stimulus] == stim_levels(i);
        detection_rates(i) = mean([trial_data(idx).Response]);
    end
    
    % Plot data points
    plot(stim_levels, detection_rates, 'o', 'MarkerSize', 8, 'Color', color);
    hold on;
    
    % Plot theoretical curve with guess rate and lapse rate
    x_theory = linspace(min(stim_levels), max(stim_levels), 100);
    y_theory_core = arrayfun(@(x) unimodal_prob(x, modal_params), x_theory);
    % Apply guess rate and lapse rate
    y_theory = modal_params.guess_rate + ...
        (1 - modal_params.guess_rate - modal_params.lapse_rate) * y_theory_core;
    plot(x_theory, y_theory, '--k', 'LineWidth', 1.5);
    
    % If fit results exist and fitting was successful, plot fitted curve
    if ~isempty(fit_result) && isfield(fit_result, 'fit_success') && fit_result.fit_success
        x_fine = linspace(min(stim_levels), max(stim_levels), 100);
        y_fit = psychometric_function(x_fine, fit_result.alpha, fit_result.beta, ...
            modal_params.guess_rate, modal_params.lapse_rate, modal_params.function_type);
        plot(x_fine, y_fit, '-', 'Color', color, 'LineWidth', 2);
        
        % Update title to include alpha and beta values
        title(sprintf('Session %d (α=%.2f, β=%.2f, R²=%.3f)', ...
            session_num, fit_result.alpha, fit_result.beta, fit_result.rsquare));
        legend('Data', 'Theoretical', 'Fitted', 'Location', 'southeast');
    else
        title(sprintf('Session %d', session_num));
        legend('Data', 'Theoretical', 'Location', 'southeast');
    end
    
    % Set figure properties
    xlabel('Stimulus Intensity');
    ylabel('Response Rate');
    grid on;
    ylim([0 1]);
end

function plot_unimodal_summary(trial_data, params, session_colors)
    % Create figure
    hold on;
    
    % Get unique sessions
    all_sessions = unique([trial_data.Session]);
    
    % Limit the number of sessions to display
    MAX_SESSIONS_TO_PLOT = 10;
    if length(all_sessions) > MAX_SESSIONS_TO_PLOT
        % Select sessions evenly across the range
        session_indices = round(linspace(1, length(all_sessions), MAX_SESSIONS_TO_PLOT));
        sessions = all_sessions(session_indices);
    else
        sessions = all_sessions;
    end
    
    % Initialize legend entries
    legend_entries = cell(1, length(sessions) + 1);  % +1 for theoretical curve
    legend_entries{1} = 'Theoretical';
    
    % Get modality-specific parameters
    if strcmp(params.modality, 'vibration')
        modal_params = params.vibration;
    else  % auditory
        modal_params = params.auditory;
    end
    
    % Plot theoretical curve first
    x_theory = linspace(min([trial_data.Stimulus]), max([trial_data.Stimulus]), 100);
    y_theory_core = arrayfun(@(x) unimodal_prob(x, modal_params), x_theory);
    % Apply guess rate and lapse rate
    y_theory = modal_params.guess_rate + ...
        (1 - modal_params.guess_rate - modal_params.lapse_rate) * y_theory_core;
    plot(x_theory, y_theory, '--k', 'LineWidth', 2);
    
    % Plot data for selected sessions
    for i = 1:length(sessions)
        session_data = trial_data([trial_data.Session] == sessions(i));
        stim_levels = unique([session_data.Stimulus]);
        response_rates = zeros(size(stim_levels));
        
        % Calculate response rates
        for j = 1:length(stim_levels)
            trials = session_data([session_data.Stimulus] == stim_levels(j));
            response_rates(j) = mean([trials.Response]);
        end
        
        % Get fit results from session data if available
        if isfield(session_data, 'fit_results')
            fit_result = session_data(1).fit_results;
        else
            % If no fit results available, perform fitting
            fit_result = fit_psychometric(stim_levels, response_rates, modal_params);
        end
        
        % Generate fitted curve points
        x_fit = linspace(min(stim_levels), max(stim_levels), 100);
        y_fit = psychometric_function(x_fit, fit_result.alpha, fit_result.beta, ...
            modal_params.guess_rate, modal_params.lapse_rate, modal_params.function_type);
        
        % Plot fitted curve only (no data points)
        plot(x_fit, y_fit, '-', 'Color', session_colors(i,:), 'LineWidth', 1.5);
        
        % Create legend entry with fit parameters
        legend_entries{i+1} = sprintf('Session %d (α=%.2f, β=%.2f, R²=%.3f)', ...
            sessions(i), fit_result.alpha, fit_result.beta, fit_result.rsquare);
    end
    
    % Add note about session selection if some were omitted
    if length(unique([trial_data.Session])) > MAX_SESSIONS_TO_PLOT
        note_text = sprintf('Note: Showing %d of %d sessions', ...
            MAX_SESSIONS_TO_PLOT, length(unique([trial_data.Session])));
        text(0.98, 0.02, note_text, ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 9, ...
            'Color', [0.5 0.5 0.5]);
    end
    
    % Convert any non-char entries in legend_entries to char
    for i = 1:length(legend_entries)
        if ~ischar(legend_entries{i}) && ~isstring(legend_entries{i})
            legend_entries{i} = char(legend_entries{i});
        end
    end
    
    % Add parameter information
    if strcmp(params.modality, 'vibration')
        param_text = sprintf('Vibration Parameters:\nThreshold: %.2f\nSlope: %.2f\nGuess Rate: %.2f\nLapse Rate: %.2f', ...
            params.vibration.threshold, params.vibration.slope, ...
            params.vibration.guess_rate, params.vibration.lapse_rate);
    else
        param_text = sprintf('Auditory Parameters:\nThreshold: %.2f\nSlope: %.2f\nGuess Rate: %.2f\nLapse Rate: %.2f', ...
            params.auditory.threshold, params.auditory.slope, ...
            params.auditory.guess_rate, params.auditory.lapse_rate);
    end
    
    text(0.02, 0.98, param_text, ...
        'Units', 'normalized', ...
        'VerticalAlignment', 'top', ...
        'FontSize', 10);
    
    % Set figure properties
    xlabel('Stimulus Intensity');
    ylabel('Response Rate');
    title('Summary of Sampled Sessions');
    grid on;
    legend(legend_entries, 'Location', 'eastoutside');
    ylim([0 1]);
end

function colors = distinguishable_colors(n)
    % Generate n distinguishable colors
    % Base color set
    base_colors = [
        0.8500 0.3250 0.0980;  % Orange
        0.0000 0.4470 0.7410;  % Blue
        0.4940 0.1840 0.5560;  % Purple
        0.4660 0.6740 0.1880;  % Green
        0.9290 0.6940 0.1250;  % Yellow
        0.6350 0.0780 0.1840;  % Brown
        0.3010 0.7450 0.9330;  % Light Blue
        0.8000 0.8000 0.8000;  % Gray
        0.7500 0.2500 0.2500;  % Dark Red
        0.2500 0.7500 0.2500;  % Dark Green
        0.2500 0.2500 0.7500;  % Dark Blue
        0.7500 0.7500 0.2500;  % Dark Yellow
    ];
    
    if n <= size(base_colors, 1)
        % If the required number of colors is less than or equal to the base color count
        colors = base_colors(1:n, :);
    else
        % If more colors are needed, generate by interpolation
        colors = zeros(n, 3);
        colors(1:size(base_colors,1), :) = base_colors;
        
        % Generate additional colors
        for i = (size(base_colors,1)+1):n
            % Generate a new random color and ensure it has enough distinction
            while true
                new_color = rand(1, 3);
                min_dist = inf;
                
                % Calculate minimum distance to existing colors
                for j = 1:(i-1)
                    dist = sqrt(sum((new_color - colors(j,:)).^2));
                    min_dist = min(min_dist, dist);
                end
                
                % Accept if minimum distance is large enough
                if min_dist > 0.3
                    colors(i,:) = new_color;
                    break;
                end
            end
        end
    end
end

function plot_multimodal_results(trial_data, params)
    % Get stimulus intensity range and model type
    stim_matrix = cell2mat({trial_data.Stimulus}');
    vib_levels = unique(stim_matrix(:,1));
    aud_levels = unique(stim_matrix(:,2));
    model_types = unique({trial_data.ModelType});
    
    % 1. Plot heatmap and 3D surface
    plot_heatmaps_and_surfaces(trial_data, params, vib_levels, aud_levels, model_types);
    
    % 2. Plot cross-modal psychometric functions
    plot_cross_modal_curves(trial_data, params, vib_levels, aud_levels, model_types);
end

function plot_cross_modal_curves(trial_data, params, vib_levels, aud_levels, model_types)
    % Create a large figure to accommodate all model cross-modal curves
    figure('Name', 'Cross-Modal Functions - All Models', ...
           'Position', [50 50 1200 800], ...  % Reduce overall size
           'Units', 'pixels');
    
    % Calculate row count (one row per model)
    n_models = length(model_types);
    
    % Set layout parameters
    left_margin = 0.06;     % Keep left margin
    right_margin = 0.06;    % Reduce right margin
    bottom_margin = 0.1;    % Keep bottom margin
    top_margin = 0.1;       % Keep top margin
    h_space = 0.1;          % Keep horizontal spacing
    v_space = 0.15;         % Keep vertical spacing
    
    % Calculate subplot height and width
    subplot_height = (1 - top_margin - bottom_margin - (n_models-1)*v_space) / n_models;
    subplot_width = (1 - left_margin - right_margin - h_space) / 2;
    
    % Add main title
    sgtitle('Cross-Modal Psychometric Functions by Model', 'FontSize', 12);
    
    % Create subplots for each model
    for model_idx = 1:n_models
        % Calculate current row vertical position
        row_pos = 1 - top_margin - model_idx * subplot_height - (model_idx-1)*v_space;
        
        % 1. Left subplot: Fixed auditory intensity, change vibration intensity
        subplot('Position', [left_margin, row_pos, subplot_width*0.95, subplot_height]);
        hold on;
        
        % Plot theoretical curve, considering gamma and lambda
        x_theory = linspace(min(vib_levels), max(vib_levels), 100);
        y_theory_core = arrayfun(@(x) unimodal_prob(x, params.vibration), x_theory);
        % Apply guess rate and lapse rate
        gamma = params.vibration.guess_rate;
        lambda = params.vibration.lapse_rate;
        y_theory = gamma + (1 - gamma - lambda) * y_theory_core;
        h_theory = plot(x_theory, y_theory, '--k', 'LineWidth', 1.5);
        
        % Initialize legend entries and plot handles
        n_levels = min([5, length(aud_levels)]);
        legend_entries = cell(n_levels + 1, 1);  % +1 for unimodal curve
        legend_entries{1} = 'Vib Unimodal';
        h_plots = zeros(n_levels + 1, 1);  % Preallocate plot handles array
        h_plots(1) = h_theory;
        
        % Select fixed auditory intensity levels
        fixed_aud = aud_levels(round(linspace(1, length(aud_levels), n_levels)));
        
        % Use different colors to plot curves for each fixed auditory intensity
        colors = distinguishable_colors(n_levels);
        for i = 1:n_levels
            [h_new, legend_new] = plot_fixed_intensity_curve(trial_data, vib_levels, ...
                fixed_aud(i), model_types{model_idx}, colors(i,:), 'auditory');
            if ~isempty(h_new)
                h_plots(i+1) = h_new(end);
                legend_entries{i+1} = legend_new;
            end
        end
        
        % Set left subplot properties
        xlabel('Vibrotactile Intensity');
        ylabel('Response Rate');
        title(sprintf('%s - Fixed Auditory', strrep(model_types{model_idx}, '_', ' ')), 'FontSize', 10);
        grid on;
        legend(h_plots, legend_entries, 'Location', 'eastoutside', 'FontSize', 8, 'Box', 'off');
        ylim([0 1]);
        
        % 2. Right subplot: Fixed vibration intensity, change auditory intensity
        subplot('Position', [left_margin + subplot_width + h_space, row_pos, subplot_width*0.95, subplot_height]);
        hold on;
        
        % Plot theoretical curve, considering gamma and lambda
        x_theory = linspace(min(aud_levels), max(aud_levels), 100);
        y_theory_core = arrayfun(@(x) unimodal_prob(x, params.auditory), x_theory);
        % Apply guess rate and lapse rate
        gamma = params.auditory.guess_rate;
        lambda = params.auditory.lapse_rate;
        y_theory = gamma + (1 - gamma - lambda) * y_theory_core;
        h_theory = plot(x_theory, y_theory, '--k', 'LineWidth', 1.5);
        
        % Initialize legend entries and plot handles
        n_levels = min([5, length(vib_levels)]);
        legend_entries = cell(n_levels + 1, 1);  % +1 for unimodal curve
        legend_entries{1} = 'Aud Unimodal';
        h_plots = zeros(n_levels + 1, 1);  % Preallocate plot handles array
        h_plots(1) = h_theory;
        
        % Select fixed vibration intensity levels
        fixed_vib = vib_levels(round(linspace(1, length(vib_levels), n_levels)));
        
        % Use different colors to plot curves for each fixed vibration intensity
        for i = 1:n_levels
            [h_new, legend_new] = plot_fixed_intensity_curve(trial_data, aud_levels, ...
                fixed_vib(i), model_types{model_idx}, colors(i,:), 'vibrotactile');
            if ~isempty(h_new)
                h_plots(i+1) = h_new(end);
                legend_entries{i+1} = legend_new;
            end
        end
        
        % Set right subplot properties
        xlabel('Auditory Intensity');
        ylabel('Response Rate');
        title(sprintf('%s - Fixed Vibrotactile', strrep(model_types{model_idx}, '_', ' ')), 'FontSize', 10);
        grid on;
        legend(h_plots, legend_entries, 'Location', 'eastoutside', 'FontSize', 8, 'Box', 'off');
        ylim([0 1]);
    end
    
    % Adjust overall layout
    set(gcf, 'Color', 'white');
    set(findall(gcf, 'type', 'axes'), ...
        'Box', 'off', ...
        'TickDir', 'out', ...
        'FontSize', 9);  % Reduce axis font size
    
    % Check and adjust figure size to fit screen
    screen_size = get(0, 'ScreenSize');
    if 800 > screen_size(4) * 0.8
        fig_pos = get(gcf, 'Position');
        new_height = screen_size(4) * 0.8;
        new_y = screen_size(4) - new_height - 50;
        set(gcf, 'Position', [fig_pos(1) new_y 1200 new_height]);
    end
end

function [h_plot, legend_entry] = plot_fixed_intensity_curve(trial_data, varied_levels, ...
    fixed_intensity, model_type, color, fixed_modality)
    
    % Initialize return value
    h_plot = [];
    legend_entry = '';
    
    % Get data points
    detection_rates = zeros(size(varied_levels));
    valid_idx = false(size(varied_levels));
    
    for i = 1:length(varied_levels)
        if strcmp(fixed_modality, 'auditory')
            stim = [varied_levels(i), fixed_intensity];
        else
            stim = [fixed_intensity, varied_levels(i)];
        end
        
        idx = find(cellfun(@(x) isequal(x, stim), {trial_data.Stimulus}) & ...
                  strcmp({trial_data.ModelType}, model_type));
        
        if ~isempty(idx)
            detection_rates(i) = mean([trial_data(idx).Response]);
            valid_idx(i) = true;
        end
    end
    
    if sum(valid_idx) > 2
        try
            % Fit psychometric function
            [x_fit, y_fit, gof, fitted_params] = fit_psychometric_curve(varied_levels(valid_idx), detection_rates(valid_idx));
            
            % Check fit quality
            if gof.rsquare < 0.6  % If R² is less than 0.6, consider fit unsatisfactory
                % Use line connection
                [sorted_x, sort_idx] = sort(varied_levels(valid_idx));
                sorted_y = detection_rates(valid_idx(sort_idx));
                h_plot = plot(sorted_x, sorted_y, '-o', ...
                    'Color', color, 'LineWidth', 1.5, 'MarkerSize', 6);
                
                legend_entry = sprintf('%s = %.1f (poor fit, R²=%.2f)', ...
                    upper(fixed_modality(1)), fixed_intensity, gof.rsquare);
            else
                % Plot data points and fitted curve
                h_data = plot(varied_levels(valid_idx), detection_rates(valid_idx), ...
                    'o', 'Color', color, 'MarkerSize', 6);
                h_fit = plot(x_fit, y_fit, '-', 'Color', color, 'LineWidth', 2);
                
                h_plot = [h_data; h_fit];
                legend_entry = sprintf('%s = %.1f (α=%.2f, R²=%.3f)', ...
                    upper(fixed_modality(1)), fixed_intensity, ...
                    fitted_params.alpha, gof.rsquare);
            end
        catch ME
            warning(ME.identifier, '%s', ME.message);
            % If fitting fails, use line connection
            [sorted_x, sort_idx] = sort(varied_levels(valid_idx));
            sorted_y = detection_rates(valid_idx(sort_idx));
            h_plot = plot(sorted_x, sorted_y, '-o', ...
                'Color', color, 'LineWidth', 1.5, 'MarkerSize', 6);
            
            legend_entry = sprintf('%s = %.1f', ...
                upper(fixed_modality(1)), fixed_intensity);
        end
    end
end

function [x_fit, y_fit, gof, fitted_params] = fit_psychometric_curve(x_data, y_data)
    % Prepare for fitting
    ft = fittype('gamma + (1-gamma-lambda)/(1 + exp(-beta*(x-alpha)))', ...
        'independent', 'x', ...
        'coefficients', {'alpha', 'beta', 'gamma', 'lambda'});
    
    % Set fitting options
    opts = fitoptions(ft);
    opts.StartPoint = [mean(x_data), 1, 0.1, 0.02];
    min_y = min(y_data);
    opts.Lower = [min(x_data), 0.1, max(0, min_y-0.1), 0];
    opts.Upper = [max(x_data), 10, min(1, min_y+0.3), 0.2];
    
    % Execute fitting
    [fitted_curve, gof] = fit(x_data(:), y_data(:), ft, opts);
    
    % Get fitting parameters
    fitted_params = coeffvalues(fitted_curve);
    fitted_params = struct(...
        'alpha', fitted_params(1), ...
        'beta', fitted_params(2), ...
        'gamma', fitted_params(3), ...
        'lambda', fitted_params(4));
    
    % Generate fitted curve points
    x_fit = linspace(min(x_data), max(x_data), 100);
    y_fit = fitted_curve(x_fit);
end

function plot_heatmaps_and_surfaces(trial_data, params, vib_levels, aud_levels, model_types)
    % Multimodal experiment plotting logic
    % Define RdBu colormap base points
    RdBu = define_colormap();
    
    % Create a large figure to display all model heatmaps and 3D surfaces
    figure('Name', 'Multimodal Integration - All Models', ...
           'Position', [50 150 1500 700], ...  % Reduce height and adjust vertical position
           'Units', 'pixels', ...
           'WindowStyle', 'normal', ...
           'Resize', 'on');
           
    % Set layout parameters
    left_margin = 0.08;    
    right_margin = 0.15;   
    bottom_margin = 0.12;  % Increase bottom margin
    top_margin = 0.12;     % Increase top margin
    h_space = 0.08;       
    v_space = 0.15;       % Increase vertical spacing
    
    % Calculate subplot size
    subplot_width = (1 - left_margin - right_margin - h_space) / 2;
    subplot_height = (1 - top_margin - bottom_margin - (length(model_types)-1)*v_space) / length(model_types);
    
    % Add main title
    sgtitle('Multimodal Integration Analysis by Model', 'FontSize', 12);
    
    % Create grid for plotting
    [X, Y] = meshgrid(vib_levels, aud_levels);
    Z = zeros(length(aud_levels), length(vib_levels));  % Preallocate Z matrix
    
    % Check trial count
    if params.n_trials < 20
        warning('Low trial count may affect fitting reliability');
    end
    
    for m = 1:length(model_types)
        % Calculate current row vertical position
        row_pos = 1 - top_margin - m * subplot_height - (m-1)*v_space;
        
        % 1. Left subplot: Heatmap
        subplot('Position', [left_margin, row_pos, subplot_width, subplot_height]);
        
        % Get current model data
        model_data = trial_data(strcmp({trial_data.ModelType}, model_types{m}));
        
        % Calculate detection rate for each stimulus combination
        for i = 1:length(aud_levels)
            for j = 1:length(vib_levels)
                stim = [vib_levels(j), aud_levels(i)];
                idx = find(cellfun(@(x) isequal(x, stim), {model_data.Stimulus}));
                if ~isempty(idx)
                    Z(i,j) = mean([model_data(idx).Response]);
                end
            end
        end
        
        % Plot heatmap
        imagesc(vib_levels, aud_levels, Z);
        colormap(RdBu);
        colorbar;
        axis xy;
        xlabel('Vibrotactile Intensity');
        ylabel('Auditory Intensity');
        title(sprintf('%s - Response Rate', strrep(model_types{m}, '_', ' ')));
        
        % 2. Right subplot: 3D surface
        subplot('Position', [left_margin + subplot_width + h_space, row_pos, subplot_width, subplot_height]);
        
        % Create denser grid for smooth interpolation
        [Xq, Yq] = meshgrid(linspace(min(vib_levels), max(vib_levels), 50), ...
                           linspace(min(aud_levels), max(aud_levels), 50));
        
        % Use interpolation to generate smooth surface data
        Zq = interp2(X, Y, Z, Xq, Yq, 'cubic');
        
        % Plot smooth 3D surface
        surf(Xq, Yq, Zq);
        colormap(RdBu);
        colorbar;
        
        % Set 3D surface display properties
        shading interp;  % Use interpolated coloring
        lighting gouraud;  % Use Gouraud lighting model
        material([0.6 0.9 0.2]);  % Adjust material properties
        camlight('headlight');  % Add light source
        
        % Set figure properties
        xlabel('Vibrotactile Intensity');
        ylabel('Auditory Intensity');
        zlabel('Response Rate');
        title(sprintf('%s - 3D View', strrep(model_types{m}, '_', ' ')));
        view(45, 30);
        grid on;
        
        % Set axis range
        xlim([min(vib_levels) max(vib_levels)]);
        ylim([min(aud_levels) max(aud_levels)]);
        zlim([0 1.2]);  % Modify z-axis upper limit to 1.2
    end
end

function RdBu = define_colormap()
    % Define RdBu colormap base points
    RdBu_base = [
        0.019608 0.188235 0.380392  % Deep blue
        0.129412 0.400000 0.674510
        0.262745 0.576471 0.764706
        0.572549 0.772549 0.870588
        0.819608 0.898039 0.941176
        0.968627 0.968627 0.968627  % White midpoint
        0.992157 0.858824 0.780392
        0.956863 0.647059 0.509804
        0.839216 0.376471 0.301961
        0.698039 0.094118 0.168627
        0.403922 0.000000 0.121569  % Deep red
    ];
    
    % Generate smoother color transitions
    x_old = linspace(0, 1, size(RdBu_base, 1));
    x_new = linspace(0, 1, 64);
    RdBu = zeros(64, 3);
    for i = 1:3
        RdBu(:,i) = interp1(x_old, RdBu_base(:,i), x_new, 'pchip');
    end
end

function fit_result = fit_psychometric(x_data, y_data, modal_params)
    % Initialize fit result structure
    fit_result = struct(...
        'alpha', NaN, ...
        'beta', NaN, ...
        'gamma', modal_params.guess_rate, ...
        'lambda', modal_params.lapse_rate, ...
        'rsquare', 0, ...
        'fit_success', false);
    
    try
        % Set up fitting options
        ft = fittype('gamma + (1-gamma-lambda)/(1 + exp(-beta*(x-alpha)))', ...
            'independent', 'x', ...
            'coefficients', {'alpha', 'beta', 'gamma', 'lambda'});
        
        opts = fitoptions(ft);
        opts.StartPoint = [mean(x_data), 1, modal_params.guess_rate, modal_params.lapse_rate];
        opts.Lower = [min(x_data), 0.1, 0, 0];
        opts.Upper = [max(x_data), 10, 1, 0.2];
        
        % Perform the fit
        [fitted_curve, gof] = fit(x_data(:), y_data(:), ft, opts);
        
        % Extract parameters
        coeffs = coeffvalues(fitted_curve);
        fit_result.alpha = coeffs(1);  % threshold
        fit_result.beta = coeffs(2);   % slope
        fit_result.gamma = coeffs(3);  % guess rate
        fit_result.lambda = coeffs(4); % lapse rate
        fit_result.rsquare = gof.rsquare;
        fit_result.fit_success = true;
        
    catch ME
        warning('PsychometricFit:FitFailed', '%s. Using simple estimates.', ME.message);
        
        % Estimate threshold as the stimulus level where response rate is closest to 0.5
        [~, thresh_idx] = min(abs(y_data - 0.5));
        fit_result.alpha = x_data(thresh_idx);
        
        % Estimate slope using difference around threshold
        if thresh_idx > 1 && thresh_idx < length(x_data)
            slope_est = (y_data(thresh_idx+1) - y_data(thresh_idx-1)) / ...
                (x_data(thresh_idx+1) - x_data(thresh_idx-1));
            fit_result.beta = max(0.1, min(10, slope_est * 4));
        else
            fit_result.beta = 1;
        end
    end
end

function y = psychometric_function(x, alpha, beta, gamma, lambda, func_type)
    % Compute psychometric function value
    switch func_type
        case 'logistic'
            y = gamma + (1-gamma-lambda) ./ (1 + exp(-beta*(x-alpha)));
        case 'weibull'
            y = gamma + (1-gamma-lambda) .* (1 - exp(-(x./alpha).^beta));
        case 'gaussian'
            y = gamma + (1-gamma-lambda) .* normcdf(x, alpha, 1/beta);
        otherwise
            error('Unknown function type: %s', func_type);
    end
end