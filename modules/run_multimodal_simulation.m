function trial_data = run_multimodal_simulation(params)
    % Main function for multimodal perception detection simulation system
    % Inputs:
    %   params: Structure containing all parameters
    % Outputs:
    %   trial_data: Array of experimental data structures
    
    % Create results directory if it doesn't exist
    if ~exist('results', 'dir')
        mkdir('results');
    end
    
    % Generate timestamp for file naming
    timestamp = string(datetime('now', 'Format', 'yyyyMMddHHmmss'));
    
    % Choose different processing flows based on modality type
    switch params.modality
        case {'vibration', 'auditory'}
            trial_data = simulate_unimodal(params.stim_levels, params.n_trials, ...
                params.(params.modality), upper(params.modality), ...
                params.randomize_trials, params.n_sessions);
            
        case 'multimodal'
            % Use separately set stimulus intensity ranges
            [V, A] = meshgrid(params.vib_levels, params.aud_levels);
            stim_pairs = [V(:), A(:)];
            n_conditions = size(stim_pairs, 1);
            
            % Initialize trial order
            trial_order = repmat(1:n_conditions, 1, params.n_trials);
            if params.randomize_trials
                trial_order = trial_order(randperm(length(trial_order)));
            end
            
            % Initialize data structure
            total_trials = n_conditions * params.n_trials * length(params.selected_models);
            trial_data(total_trials) = struct(...
                'Stimulus', [], ...
                'SOA', [], ...            
                'ModelType', [], ...      
                'Response', [], ...       
                'DetectionProb', [], ...
                'Session', 1);  % Add Session field with default value 1
            
            % Run simulation
            trial_idx = 1;
            tic
            for t = 1:length(trial_order)
                stim_idx = trial_order(t);
                current_stim = stim_pairs(stim_idx,:);
                
                for m = 1:length(params.selected_models)
                    [response, p_response] = simulate_trial(current_stim, ...
                        params.selected_models{m}, params);
                    
                    trial_data(trial_idx).Stimulus = current_stim;
                    trial_data(trial_idx).ModelType = params.selected_models{m};
                    trial_data(trial_idx).Response = response;
                    trial_data(trial_idx).DetectionProb = p_response;
                    trial_data(trial_idx).Session = 1;  % Set session to 1 for multimodal
                    trial_idx = trial_idx + 1;
                end
            end
            toc
    end
    
    % Save results
    save_results(trial_data, params, timestamp);
end

function trial_data = simulate_unimodal(stim_levels, n_trials, modality_params, modality_name, randomize, n_sessions)
    % Calculate total size for preallocation
    trials_per_session = length(stim_levels) * n_trials;
    all_sessions_data = repmat(struct(...
        'Stimulus', [], ...
        'Response', [], ...
        'Modality', modality_name, ...
        'ModelType', [lower(modality_name) '_only'], ...  % Create model type from modality name
        'DetectionProb', [], ...
        'Session', 1), ...
        trials_per_session * n_sessions, 1);
    
    % Initialize a structure to store all fit parameters
    fit_parameters = struct(...
        'alpha', zeros(1, n_sessions), ...
        'beta', zeros(1, n_sessions), ...
        'gamma', zeros(1, n_sessions), ...
        'lambda', zeros(1, n_sessions), ...
        'rsquare', zeros(1, n_sessions));
    
    % Track current index for filling data
    current_idx = 1;
    
    % Pre-initialize fit_results structure array
    empty_fit_result = struct(...
        'model', '', ...
        'fixed_modality', 'none', ...
        'fixed_intensity', NaN, ...
        'varied_modality', lower(modality_name), ...
        'alpha', NaN, ...
        'beta', NaN, ...
        'gamma', NaN, ...
        'lambda', NaN, ...
        'rsquare', NaN, ...
        'valid_points', 0, ...
        'fit_success', false, ...
        'slope', modality_params.slope, ...
        'threshold', modality_params.threshold, ...
        'detection_rates', [], ...
        'stim_levels', []);
    
    % Use repmat to pre-allocate space
    fit_results = repmat(empty_fit_result, 1, n_sessions);
    
    % Run experiment for each session
    for session = 1:n_sessions
        % Create trial order
        n_conditions = length(stim_levels);
        all_trials = repmat(1:n_conditions, 1, n_trials);
        if randomize
            all_trials = all_trials(randperm(length(all_trials)));
        end
        
        % Initialize trial data for this session
        trial_data = repmat(struct(...
            'Stimulus', [], ...
            'Response', [], ...
            'Modality', modality_name, ...
            'ModelType', [lower(modality_name) '_only'], ...  % Create model type from modality name
            'DetectionProb', [], ...
            'Session', session), n_conditions * n_trials, 1);
        
        trial_idx = 1;
        for t = 1:length(all_trials)
            % Get current stimulus level index
            i = all_trials(t);
            
            % Simulate trial using the appropriate model type
            [response, p_response] = simulate_trial(stim_levels(i), ...
                [lower(modality_name) '_only'], ...
                modality_params);  % Pass modality_params directly
            
            % Record data
            trial_data(trial_idx).Stimulus = stim_levels(i);
            trial_data(trial_idx).Response = response;
            trial_data(trial_idx).DetectionProb = p_response;
            
            trial_idx = trial_idx + 1;
        end
        
        % Calculate detection rates for each intensity
        unique_stims = unique(stim_levels);
        detection_rates = zeros(size(unique_stims));
        valid_points = zeros(size(unique_stims));
        
        for i = 1:length(unique_stims)
            stim_idx = [trial_data.Stimulus] == unique_stims(i);
            detection_rates(i) = mean([trial_data(stim_idx).Response]);
            valid_points(i) = sum(stim_idx);
        end
        
        % Fit psychometric function using the new fit_psychometric_curve function
        [fit_result, ~] = fit_psychometric_curve(unique_stims, detection_rates, modality_params, []);
        
        % Update fit_results structure with additional fields
        fit_results(session) = struct(...
            'model', [lower(modality_name) '_only'], ...
            'fixed_modality', 'none', ...
            'fixed_intensity', NaN, ...
            'varied_modality', lower(modality_name), ...
            'alpha', fit_result.alpha, ...
            'beta', fit_result.beta, ...
            'gamma', fit_result.gamma, ...
            'lambda', fit_result.lambda, ...
            'rsquare', fit_result.rsquare, ...
            'valid_points', sum(valid_points), ...
            'fit_success', fit_result.fit_success, ...
            'slope', modality_params.slope, ...
            'threshold', modality_params.threshold, ...
            'detection_rates', detection_rates, ...
            'stim_levels', unique_stims);
        
        % After fitting, store parameters in the fit_parameters structure
        fit_parameters.alpha(session) = fit_result.alpha;
        fit_parameters.beta(session) = fit_result.beta;
        fit_parameters.gamma(session) = fit_result.gamma;
        fit_parameters.lambda(session) = fit_result.lambda;
        fit_parameters.rsquare(session) = fit_result.rsquare;
        
        % Update session data at correct indices
        idx_range = current_idx:(current_idx + trials_per_session - 1);
        all_sessions_data(idx_range) = trial_data;
        current_idx = current_idx + trials_per_session;
    end
    
    % Add fit_results and fit_parameters to each trial data
    for i = 1:length(all_sessions_data)
        all_sessions_data(i).fit_results = fit_results(all_sessions_data(i).Session);
        all_sessions_data(i).fit_parameters = fit_parameters;
    end

    % Return all sessions data
    trial_data = all_sessions_data;
end


function save_results(trial_data, params, timestamp)
    % Prepare directory
    results_dir = fullfile(pwd, 'results');
    if ~exist(results_dir, 'dir')
        mkdir(results_dir);
    end
    
    % Get file prefix based on modality
    modality_prefix = struct('multimodal', 'Multi', ...
                           'vibration', 'Vib', ...
                           'auditory', 'Sound');
    prefix = modality_prefix.(params.modality);
    
    % Create filename
    filename = fullfile(results_dir, ...
        sprintf('%s_simulation_data_%s.mat', prefix, timestamp));
    
    % Extract fit results if available
    fit_results = [];
    if isfield(trial_data, 'fit_results')
        fit_results = trial_data(1).fit_results;
    end
    
    % Extract fit parameters if available
    fit_parameters = [];
    if isfield(trial_data, 'fit_parameters')
        fit_parameters = trial_data(1).fit_parameters;
    end
    
    % Create experiment info structure with fit parameters
    experiment_info = struct(...
        'params', params, ...
        'trial_data', trial_data, ...
        'timestamp', timestamp, ...
        'fit_results', fit_results, ...
        'fit_parameters', fit_parameters, ...  % Add fit parameters
        'n_sessions', params.n_sessions);
    
    % Add GUI settings if available
    if isfield(params, 'gui_settings')
        experiment_info.gui_settings = params.gui_settings;
    end
    
    % Get conditions
    if strcmp(params.modality, 'multimodal')
        conditions = unique({trial_data.ModelType});
    else
        conditions = {[params.modality '_only']};
    end
    
    % Add summary
    experiment_info.simulation_summary = struct(...
        'total_trials', length(trial_data), ...
        'conditions', {conditions}, ...
        'stim_levels', {unique([trial_data.Stimulus])}, ...
        'response_rate', mean([trial_data.Response]), ...
        'params_used', params);
    
    % Save to file
    save(filename, 'experiment_info');
    fprintf('Results saved to: %s\n', filename);
end