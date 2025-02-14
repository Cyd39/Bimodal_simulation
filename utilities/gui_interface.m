function gui_interface()
    % Create main window with increased size
    fig = uifigure('Name', 'Multimodal Detection Simulation', 'Position', [100 100 1400 900]);
    
    % Create main grid layout
    grid = uigridlayout(fig, [2 2]);
    grid.RowHeight = {'10x', '1x'};  % Increase upper section height ratio
    grid.ColumnWidth = {'1.2x', '1x'};  % Increase left parameter area width
    
    % Left parameter settings panel
    param_panel = uipanel(grid, 'Title', 'Parameters');
    param_panel.Layout.Row = 1;
    param_panel.Layout.Column = 1;
    
    % Right model selection panel
    right_panel = uipanel(grid);  % Create right main panel
    right_panel.Layout.Row = 1;
    right_panel.Layout.Column = 2;
    
    % Create right panel grid layout
    right_grid = uigridlayout(right_panel, [2 1]);  % 2 rows 1 column layout
    right_grid.RowHeight = {'1.2x', '0.8x'};  % Adjust row proportions
    right_grid.Padding = [5 5 5 5];  % Add some padding
    right_grid.RowSpacing = 5;  % Row spacing
    
    % Create panels using absolute positioning
    model_panel = uipanel('Parent', right_grid, 'Title', 'Integration Models');
    model_panel.Layout.Row = 1;
    model_panel.Layout.Column = 1;
    
    progress_panel = uipanel('Parent', right_grid, 'Title', 'Progress');
    progress_panel.Layout.Row = 2;
    progress_panel.Layout.Column = 1;
    
    % Create progress text label
    progress_text = uicontrol(progress_panel, ...
        'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.05 0.1 0.9 0.85], ...  % Adjust position and size, leave more top space
        'String', 'Ready to simulate...', ...
        'FontSize', 13, ...  % Increase font size
        'ForegroundColor', [0.2 0.4 0.7], ...
        'BackgroundColor', get(progress_panel, 'BackgroundColor'), ...
        'HorizontalAlignment', 'left', ...
        'Max', 2);  % Enable multiline display
    
    % Parameter panel grid layout
    param_grid = uigridlayout(param_panel, [16 2]);  % Increase to 16 rows to accommodate new buttons
    param_grid.RowHeight = repmat({'fit'}, 1, 16);
    param_grid.ColumnWidth = {'1x', '3x'};  % Increase right control width ratio
    
    % Modality selection
    uilabel(param_grid, 'Text', 'Modality', 'FontSize', 13);
    modality_dd = uidropdown(param_grid, ...
        'Items', {'Multimodal', 'Vibration', 'Auditory'}, ...
        'ValueChangedFcn', @updatePanels, ...
        'FontSize', 13);
    modality_dd.Layout.Column = 2;
    
    % Vibrotactile parameters
    vib_params = struct();
    vib_label = uilabel(param_grid, 'Text', 'Vibrotactile Parameters', ...
        'FontWeight', 'bold', 'FontSize', 14);
    vib_label.Layout.Column = [1 2];
    
    uilabel(param_grid, 'Text', '  Threshold', 'FontSize', 13);
    vib_params.threshold = uislider(param_grid, 'Limits', [0 10], 'Value', 5);
    vib_params.threshold.Layout.Column = 2;
    
    uilabel(param_grid, 'Text', '  Slope', 'FontSize', 13);
    vib_params.slope = uislider(param_grid, 'Limits', [0.1 3], 'Value', 1.2);
    vib_params.slope.Layout.Column = 2;
    
    % Auditory parameters
    aud_params = struct();
    aud_label = uilabel(param_grid, 'Text', 'Auditory Parameters', ...
        'FontWeight', 'bold', 'FontSize', 14);
    aud_label.Layout.Column = [1 2];
    
    uilabel(param_grid, 'Text', '  Threshold', 'FontSize', 13);
    aud_params.threshold = uislider(param_grid, 'Limits', [0 10], 'Value', 5);
    aud_params.threshold.Layout.Column = 2;
    
    uilabel(param_grid, 'Text', '  Slope', 'FontSize', 13);
    aud_params.slope = uislider(param_grid, 'Limits', [0.1 3], 'Value', 0.9);
    aud_params.slope.Layout.Column = 2;
    
    % Common parameters
    common_label = uilabel(param_grid, 'Text', 'Common Parameters', ...
        'FontWeight', 'bold', 'FontSize', 14);
    common_label.Layout.Column = [1 2];
    
    uilabel(param_grid, 'Text', '  Guess Rate', 'FontSize', 13);
    guess_spinner = uispinner(param_grid, 'Limits', [0 1], 'Value', 0.1, ...
        'Step', 0.02, 'FontSize', 13);
    guess_spinner.Layout.Column = 2;
    
    uilabel(param_grid, 'Text', '  Lapse Rate', 'FontSize', 13);
    lapse_spinner = uispinner(param_grid, 'Limits', [0 0.2], 'Value', 0.02, ...
        'Step', 0.01, 'FontSize', 13);
    lapse_spinner.Layout.Column = 2;
    
    uilabel(param_grid, 'Text', '  Function Type', 'FontSize', 13);
    function_dd = uidropdown(param_grid, ...
        'Items', {'logistic', 'weibull', 'gaussian'}, ...
        'FontSize', 13);
    function_dd.Layout.Column = 2;
    
    % Experimental parameters
    exp_label = uilabel(param_grid, 'Text', 'Experimental Parameters', ...
        'FontWeight', 'bold', 'FontSize', 14);
    exp_label.Layout.Column = [1 2];
    
    % Vibrotactile intensity range
    vib_range_label = uilabel(param_grid, 'Text', '  Vibrotactile Intensity Range', ...
        'FontSize', 13);
    vib_range_grid = uigridlayout(param_grid, [1 4]);
    vib_range_grid.Layout.Column = 2;
    vib_range_grid.ColumnWidth = {'fit', '1x', 'fit', '1x'};
    
    uilabel(vib_range_grid, 'Text', 'Min', 'FontSize', 13);
    vib_min = uispinner(vib_range_grid, ...
        'Value', 0, ...
        'Limits', [0 10], ...
        'Step', 0.1, ...
        'ValueChangedFcn', @validateRanges, ...
        'FontSize', 13);
    
    uilabel(vib_range_grid, 'Text', 'Max', 'FontSize', 13);
    vib_max = uispinner(vib_range_grid, ...
        'Value', 10, ...
        'Limits', [0 10], ...
        'Step', 0.1, ...
        'ValueChangedFcn', @validateRanges, ...
        'FontSize', 13);
    
    % Auditory intensity range
    aud_range_label = uilabel(param_grid, 'Text', '  Auditory Intensity Range', ...
        'FontSize', 13);
    aud_range_grid = uigridlayout(param_grid, [1 4]);
    aud_range_grid.Layout.Column = 2;
    aud_range_grid.ColumnWidth = {'fit', '1x', 'fit', '1x'};
    
    uilabel(aud_range_grid, 'Text', 'Min', 'FontSize', 13);
    aud_min = uispinner(aud_range_grid, ...
        'Value', 0, ...
        'Limits', [0 10], ...
        'Step', 0.1, ...
        'ValueChangedFcn', @validateRanges, ...
        'FontSize', 13);
    
    uilabel(aud_range_grid, 'Text', 'Max', 'FontSize', 13);
    aud_max = uispinner(aud_range_grid, ...
        'Value', 10, ...
        'Limits', [0 10], ...
        'Step', 0.1, ...
        'ValueChangedFcn', @validateRanges, ...
        'FontSize', 13);
    
    % Number of intensity levels
    uilabel(param_grid, 'Text', '  Number of Intensity Levels', 'FontSize', 13);
    n_levels = uispinner(param_grid, ...
        'Value', 10, ...
        'Limits', [2 50], ...
        'Step', 1, ...
        'FontSize', 13);
    n_levels.Layout.Column = 2;
    
    % Trials per intensity
    uilabel(param_grid, 'Text', '  Trials per Intensity', 'FontSize', 13);
    n_trials = uispinner(param_grid, ...
        'Value', 15, ...
        'Limits', [1 1000], ...
        'Step', 5, ...
        'FontSize', 13);
    n_trials.Layout.Column = 2;
    
    % Create randomization controls
    uilabel(param_grid, 'Text', '  Randomize Trials', 'FontSize', 13);
    
    % Create button group for radio buttons
    random_bg = uibuttongroup(param_grid, ...
        'BorderType', 'none', ...
        'BackgroundColor', get(param_panel, 'BackgroundColor'), ...
        'SelectionChangedFcn', @(~,~) drawnow);
    random_bg.Layout.Column = 2;
    
    % Create radio buttons in the button group
    uiradiobutton(random_bg, ...
        'Position', [10 0 100 20], ...
        'Text', 'Random', ...
        'FontSize', 13, ...
        'Tag', 'random');
    
    uiradiobutton(random_bg, ...
        'Position', [120 0 100 20], ...
        'Text', 'Sequential', ...
        'FontSize', 13, ...
        'Tag', 'sequential');
    
    % Add Load Conditions and Plot Results buttons
    uilabel(param_grid, 'Text', 'Results', ...
        'FontWeight', 'bold', 'FontSize', 14);  % Add title label
    results_panel = uigridlayout(param_grid, [1 2]);
    results_panel.Layout.Column = [1 2];
    results_panel.ColumnWidth = {'1x', '1x'};
    results_panel.Padding = [0 5 0 5];  % Add some padding
    
    % Create Load Conditions button
    uibutton(results_panel, 'Text', 'Load Conditions', ...
        'ButtonPushedFcn', @loadConditions, ...
        'FontSize', 18, ...  % Increase font size
        'FontWeight', 'bold');  % Bold font
    
    % Create Plot from Result button
    uibutton(results_panel, 'Text', 'Plot from Result', ...
        'ButtonPushedFcn', @plotFromResult, ...
        'FontSize', 18, ...  % Increase font size
        'FontWeight', 'bold');  % Bold font
    
    % Multi-session experiment
    uilabel(param_grid, 'Text', 'Multi-session experiment', 'FontSize', 13);
    n_sessions_spinner = uispinner(param_grid, ...
        'Value', 1, ...
        'Limits', [1 Inf], ...
        'Step', 1, ...
        'ValueChangedFcn', @(~,~) updatePanels(), ...
        'FontSize', 13);
    n_sessions_spinner.Layout.Column = 2;
    
    % In right panel create model selection grid
    model_grid = uigridlayout(model_panel, [3 2]);  % Change to 3 rows 2 column layout
    model_grid.RowHeight = repmat({'fit'}, 1, 3);
    model_grid.ColumnWidth = {'1x', '1x'};
    model_grid.Padding = [20 30 20 20];  % Add padding [left top right bottom]
    model_grid.RowSpacing = 15;  % Add row spacing
    
    % Define all available integration models
    model_types = {...
        'linear_sum', 'Linear Sum', ...
        'probability_sum', 'Probability Sum', ...
        'bayesian_optimal', 'Bayesian Optimal', ...
        'winner_take_all', 'Winner Take All', ...
        'dynamic_weight', 'Dynamic Weight', ...
        'temporal_integration', 'Temporal Integration'};
    
    % Create model selection checkboxes
    model_checkboxes = struct();
    n_models = length(model_types)/2;
    for idx = 1:n_models
        model_name = model_types{2*idx-1};
        display_name = model_types{2*idx};
        model_checkboxes.(genvarname(model_name)) = uicheckbox(model_grid, ...
            'Text', display_name, ...
            'Value', false, ...
            'FontSize', 14, ...  % Increase font size
            'FontWeight', 'bold', ...  % Bold display
            'WordWrap', 'on');   % Allow text wrap
    end
    
    % In bottom create Simulate button
    simulate_button = uibutton(grid, ...
        'Text', 'Start Simulation', ...
        'FontSize', 24, ...
        'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,event) runSimulation(getParameters()));
    
    % Set button position at bottom middle
    simulate_button.Layout.Row = 2;
    simulate_button.Layout.Column = [1 2];  % Cross two columns
    
    % Validate range callback function
    function validateRanges(src, ~)
        if src == vib_min && src.Value >= vib_max.Value
            src.Value = vib_max.Value - 0.1;
        elseif src == vib_max && src.Value <= vib_min.Value
            src.Value = vib_min.Value + 0.1;
        elseif src == aud_min && src.Value >= aud_max.Value
            src.Value = aud_max.Value - 0.1;
        elseif src == aud_max && src.Value <= aud_min.Value
            src.Value = aud_min.Value + 0.1;
        end
    end
    
    % Modify run simulation callback function
    function runSimulation(params)
        % Check if parameters are valid
        if isempty(params)
            return;
        end
        
        % Update progress text
        progress_text.String = 'Preparing simulation...';
        drawnow
        
        % Update progress text
        progress_text.String = sprintf('✓ Results directory created\nRunning simulation...');
        drawnow
        
        try
            % Update progress text
            progress_text.String = sprintf('✓ Results directory created\n✓ Simulation running...');
            drawnow
            
            % Run simulation
            trial_data = run_multimodal_simulation(params);
            
            % Update progress text
            progress_text.String = sprintf('✓ Results directory created\n✓ Simulation completed\nProcessing data...');
            drawnow
            
            % Create simulation info structure
            sim_info = struct();
            switch params.modality
                case 'multimodal'
                    sim_info.stim_ranges = struct(...
                        'vibration', params.vib_levels, ...
                        'auditory', params.aud_levels ...
                    );
                    
                case {'vibration', 'auditory'}
                    sim_info.stim_levels = params.stim_levels;
            end
            
            % Add simulation_info to params
            params.simulation_info = sim_info;
            
            % Update progress text
            progress_text.String = sprintf('✓ Results directory created\n✓ Simulation completed\n✓ Data processed\nPreparing plots...');
            drawnow
            
            % Display results
            try
                % Force all new figures to be created invisible initially
                set(0, 'DefaultFigureVisible', 'off');
                
                % Bring GUI to front first
                figure(fig);
                drawnow;
                
                plot_results(trial_data, params);
                
                % Move all plot figures behind the GUI
                all_figs = findall(0, 'Type', 'figure');
                gui_fig = fig;  % Store GUI figure handle
                for f = 1:length(all_figs)
                    if all_figs(f) ~= gui_fig  % Don't modify GUI window
                        uistack(all_figs(f), 'bottom');
                        % Now make the figure visible
                        set(all_figs(f), 'Visible', 'on');
                    end
                end
                
                % Reset default figure visibility
                set(0, 'DefaultFigureVisible', 'on');
                
                % Bring GUI back to front
                figure(fig);
                
                % Update progress text
                progress_text.String = sprintf('✓ Results directory created\n✓ Simulation completed\n✓ Data processed\n✓ Plots generated\n\nSimulation completed successfully!');
                drawnow
                
                % Show completion message at top of screen
                screen_size = get(0, 'ScreenSize');
                dialog_pos = [
                    screen_size(3)/2 - 200;  % Center horizontally
                    screen_size(4)/2 - 75;   % Center vertically (dialog height is 150)
                    400;                     % Dialog width
                    150;                      % Dialog height
                ];
                
                % Create custom dialog figure
                msg_dlg = uifigure('Position', dialog_pos, ...
                    'Name', 'Simulation Complete', ...
                    'WindowStyle', 'modal', ...
                    'Resize', 'off');
                
                % Create message text
                uilabel(msg_dlg, ...
                    'Position', [20 60 360 70], ...
                    'Text', sprintf(['Simulation completed successfully!\n\n', ...
                                   '✓ Data generated\n', ...
                                   '✓ Results saved\n', ...
                                   '✓ Figures plotted']), ...
                    'HorizontalAlignment', 'center');
                
                % Create OK button
                uibutton(msg_dlg, ...
                    'Position', [160 20 80 30], ...
                    'Text', 'OK', ...
                    'ButtonPushedFcn', @(btn,event) close(msg_dlg));
                
                % Bring all figures to front
                all_figs = findall(0, 'Type', 'figure');
                for f = 1:length(all_figs)
                    figure(all_figs(f));
                end
                drawnow;
                
            catch ME
                errordlg(sprintf('Error plotting results: %s', ME.message), 'Plot Error');
                rethrow(ME);
            end
        catch ME
            errordlg(sprintf('Error running simulation: %s', ME.message), 'Simulation Error');
            rethrow(ME);
        end
    end
    
    % Modify get parameters function
    function params = getParameters()
        params = struct();
        
        % Get common parameters
        common_params = struct(...
            'guess_rate', get(guess_spinner, 'Value'), ...
            'lapse_rate', get(lapse_spinner, 'Value'), ...
            'function_type', get(function_dd, 'Value') ...
        );
        
        % Add randomization parameter by checking selected button's tag
        selected_button = random_bg.SelectedObject;
        params.randomize_trials = strcmp(selected_button.Tag, 'random');
        
        % Set modality
        params.modality = lower(get(modality_dd, 'Value'));
        
        % Set parameters based on modality
        switch params.modality
            case 'vibration'
                % Vibrotactile parameters setting
                params.stim_levels = linspace(...
                    vib_min.Value, ...
                    vib_max.Value, ...
                    get(n_levels, 'Value'));
                
                params.vibration = struct(...
                    'threshold', vib_params.threshold.Value, ...
                    'slope', vib_params.slope.Value, ...
                    'guess_rate', common_params.guess_rate, ...
                    'lapse_rate', common_params.lapse_rate, ...
                    'function_type', common_params.function_type ...
                );
                
            case 'auditory'
                % Auditory parameters setting
                params.stim_levels = linspace(...
                    aud_min.Value, ...
                    aud_max.Value, ...
                    get(n_levels, 'Value'));
                
                params.auditory = struct(...
                    'threshold', aud_params.threshold.Value, ...
                    'slope', aud_params.slope.Value, ...
                    'guess_rate', common_params.guess_rate, ...
                    'lapse_rate', common_params.lapse_rate, ...
                    'function_type', common_params.function_type ...
                );
                
            case 'multimodal'
                % Multimodal parameters setting
                params.vib_levels = linspace(...
                    vib_min.Value, ...
                    vib_max.Value, ...
                    get(n_levels, 'Value'));
                
                params.aud_levels = linspace(...
                    aud_min.Value, ...
                    aud_max.Value, ...
                    get(n_levels, 'Value'));
                
                % Set each modality parameters
                params.vibration = struct(...
                    'threshold', vib_params.threshold.Value, ...
                    'slope', vib_params.slope.Value, ...
                    'guess_rate', common_params.guess_rate, ...
                    'lapse_rate', common_params.lapse_rate, ...
                    'function_type', common_params.function_type ...
                );
                
                params.auditory = struct(...
                    'threshold', aud_params.threshold.Value, ...
                    'slope', aud_params.slope.Value, ...
                    'guess_rate', common_params.guess_rate, ...
                    'lapse_rate', common_params.lapse_rate, ...
                    'function_type', common_params.function_type ...
                );
                
                % Get selected models
                fields = fieldnames(model_checkboxes);
                selected_models = cell(length(fields), 1);  % Preallocate
                model_count = 0;
                for i = 1:length(fields)
                    if model_checkboxes.(fields{i}).Value
                        model_count = model_count + 1;
                        selected_models{model_count} = fields{i};
                    end
                end
                selected_models = selected_models(1:model_count);  % Trim unused space
                
                % Check if any model is selected
                if isempty(selected_models)
                    uiconfirm(fig, ...
                        'Please select at least one integration model', ...
                        'No Model Selected', ...
                        'Icon', 'warning', ...
                        'Options', {'OK'});
                    
                    % Return empty parameters to prevent further execution
                    params = [];
                    return;
                end
                
                params.selected_models = selected_models;
                params.integration_weights = [0.6, 0.4];
                params.temporal = struct('soa', 0, 'window', 0.1);
        end
        
        % Add trial count
        params.n_trials = get(n_trials, 'Value');
        
        % Add multi-session parameter
        params.n_sessions = get(n_sessions_spinner, 'Value');
    end
    
    % Initialize panel status
    updatePanels();
    
    % Nested function definitions
    function updatePanels(~,~)
        modality = get(modality_dd, 'Value');
        
        % Show/hide vibrotactile parameters
        vib_visible = strcmp(modality, 'Vibration') || strcmp(modality, 'Multimodal');
        vib_label.Visible = vib_visible;
        vib_params.threshold.Visible = vib_visible;
        vib_params.slope.Visible = vib_visible;
        vib_range_label.Visible = vib_visible;
        vib_range_grid.Visible = vib_visible;
        
        % Show/hide auditory parameters
        aud_visible = strcmp(modality, 'Auditory') || strcmp(modality, 'Multimodal');
        aud_label.Visible = aud_visible;
        aud_params.threshold.Visible = aud_visible;
        aud_params.slope.Visible = aud_visible;
        aud_range_label.Visible = aud_visible;
        aud_range_grid.Visible = aud_visible;
        
        % Show/hide integration model selection panel
        model_panel.Visible = strcmp(modality, 'Multimodal');
        
        % Control multi-session option availability
        if strcmpi(modality, 'multimodal')
            set(n_sessions_spinner, 'Enable', 'off');
            set(n_sessions_spinner, 'Value', 1);
        else
            set(n_sessions_spinner, 'Enable', 'on');
        end
    end
    
    function loadConditions(~, ~)
        % Open file dialog to select .mat file
        [filename, pathname] = uigetfile('results/*simulation_data*.mat', 'Select simulation data file');
        if isequal(filename, 0)
            return;
        end
        
        % Check if filename contains 'simulation_data'
        if ~contains(filename, 'simulation_data')
            uialert(fig, 'Please select a file containing "simulation_data" in its name', 'Invalid File', ...
                'Icon', 'warning');
            return;
        end
        
        % Load the data
        data = load(fullfile(pathname, filename));
        if ~isfield(data, 'experiment_info')
            uialert(fig, 'Invalid result file format', 'Error');
            return;
        end
        
        % Update GUI with loaded parameters
        params = data.experiment_info.params;
        updateGUIFromParams(params);
        
        % Show confirmation dialog
        uiconfirm(fig, 'Stimulus conditions loaded', 'Success', ...
            'Options', {'OK'}, ...
            'Icon', 'success');
    end
    
    function plotFromResult(~, ~)
        % Open file dialog to select .mat file
        [filename, pathname] = uigetfile('results/*simulation_data*.mat', 'Select simulation data file');
        if isequal(filename, 0)
            return;
        end
        
        % Check if filename contains 'simulation_data'
        if ~contains(filename, 'simulation_data')
            uialert(fig, 'Please select a file containing "simulation_data" in its name', 'Invalid File', ...
                'Icon', 'warning');
            return;
        end
        
        % Load the data
        data = load(fullfile(pathname, filename));
        if ~isfield(data, 'experiment_info')
            uialert(fig, 'Invalid result file format', 'Error');
            return;
        end
        
        % Plot results using the same plotting function
        plot_results(data.experiment_info.trial_data, data.experiment_info.params);
    end
    
    function updateGUIFromParams(params)
        % Convert modality to proper case for GUI
        switch lower(params.modality)
            case 'multimodal'
                gui_modality = 'Multimodal';
            case 'vibration'
                gui_modality = 'Vibration';
            case 'auditory'
                gui_modality = 'Auditory';
        end
        
        % Update modality dropdown with correct case
        modality_dd.Value = gui_modality;
        
        % Update parameter fields based on modality (using lowercase for comparison)
        switch lower(params.modality)
            case 'multimodal'
                % Update vibration parameters
                vib_params.threshold.Value = params.vibration.threshold;
                vib_params.slope.Value = params.vibration.slope;
                
                % Update auditory parameters
                aud_params.threshold.Value = params.auditory.threshold;
                aud_params.slope.Value = params.auditory.slope;
                
                % Update model selections
                for i = 1:length(params.selected_models)
                    model_name = params.selected_models{i};
                    if isfield(model_checkboxes, genvarname(model_name))
                        model_checkboxes.(genvarname(model_name)).Value = true;
                    end
                end
                
            case {'vibration', 'auditory'}
                % Update unimodal parameters
                if strcmpi(params.modality, 'vibration')
                    vib_params.threshold.Value = params.vibration.threshold;
                    vib_params.slope.Value = params.vibration.slope;
                else
                    aud_params.threshold.Value = params.auditory.threshold;
                    aud_params.slope.Value = params.auditory.slope;
                end
        end
        
        % Update trial count
        n_trials.Value = params.n_trials;
        
        % Update panels visibility
        updatePanels();
    end
end 