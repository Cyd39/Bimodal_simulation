function p_response = integration_models(P_vib, P_aud, model_type, model_params)
    % Calculate detection probability based on different integration models
    % Inputs:
    %   P_vib: vibrotactile detection probability
    %   P_aud: auditory detection probability
    %   model_type: integration model type
    %   model_params: model parameters
    
    % Get parameters
    w_vib = model_params.integration_weights(1);
    w_aud = model_params.integration_weights(2);
    guess_rate = model_params.guess_rate;
    lapse_rate = model_params.lapse_rate;
    
    % Calculate integrated probability based on model type
    switch model_type
        case 'linear_sum'
            % Linear weighted sum
            p_detect = w_vib * P_vib + w_aud * P_aud;
            
        case 'probability_sum'
            % Probability summation
            p_detect = 1 - (1 - P_vib) * (1 - P_aud);
            
        case 'bayesian_optimal'
            % Bayesian optimal integration
            p_detect = (P_vib * P_aud) / (P_vib * P_aud + (1 - P_vib) * (1 - P_aud));
            
        case 'winner_take_all'
            % Winner-take-all
            p_detect = max(P_vib, P_aud);
            
        case 'dynamic_weight'
            % Dynamic weighting based on reliability
            reliability_vib = 1 / (1 + exp(-P_vib));
            reliability_aud = 1 / (1 + exp(-P_aud));
            total_reliability = reliability_vib + reliability_aud;
            
            if total_reliability > 0
                w_vib_dynamic = reliability_vib / total_reliability;
                w_aud_dynamic = reliability_aud / total_reliability;
                p_detect = w_vib_dynamic * P_vib + w_aud_dynamic * P_aud;
            else
                p_detect = 0.5;  % Default to chance level if no reliable input
            end
            
        case 'temporal_integration'
            % Temporal integration with decay
            temporal = model_params.temporal;
            soa = temporal.soa;  % Stimulus onset asynchrony
            window = temporal.window;  % Integration window
            
            % Apply temporal decay based on SOA
            if abs(soa) > window
                % Outside integration window
                p_detect = max(P_vib, P_aud);
            else
                % Within integration window, weight by temporal proximity
                temporal_weight = 1 - (abs(soa) / window);
                p_detect = temporal_weight * (w_vib * P_vib + w_aud * P_aud) + ...
                    (1 - temporal_weight) * max(P_vib, P_aud);
            end
            
        otherwise
            error('Unknown integration model type: %s', model_type);
    end
    
    % Apply guess rate and lapse rate to core probability
    p_response = guess_rate + (1 - guess_rate - lapse_rate) * p_detect;
    
    % Ensure probability is within [0,1] range
    p_response = min(max(p_response, 0), 1);
end 