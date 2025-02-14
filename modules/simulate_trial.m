function [response, p_response] = simulate_trial(stim, model_type, params)
    % Generate behavioral response for a single trial
    % Inputs:
    %   stim: stimulus intensity or [vibrotactile intensity, auditory intensity]
    %   model_type: integration model type
    %   params: parameter structure
    
    % Handle single modality case
    if isscalar(stim)
        if strcmp(model_type, 'vibration_only')
            p_response = params.guess_rate + ...
                (1 - params.guess_rate - params.lapse_rate) * ...
                unimodal_prob(stim, params);
        elseif strcmp(model_type, 'auditory_only')
            p_response = params.guess_rate + ...
                (1 - params.guess_rate - params.lapse_rate) * ...
                unimodal_prob(stim, params);
        else
            error('Invalid model type for single modality: %s', model_type);
        end
    else
        % Multimodal case
        % Calculate unimodal detection probabilities (without guess/lapse rates)
        P_vib = unimodal_prob(stim(1), params.vibration);
        P_aud = unimodal_prob(stim(2), params.auditory);
        
        % Create parameter subset for integration model
        model_params = struct(...
            'integration_weights', params.integration_weights, ...
            'temporal', params.temporal, ...
            'guess_rate', params.vibration.guess_rate, ...
            'lapse_rate', params.vibration.lapse_rate ...
        );
        
        % Calculate multimodal integration probability
        p_response = integration_models(P_vib, P_aud, model_type, model_params);
    end
    
    % Ensure probability is within [0,1] range
    p_response = min(max(p_response, 0), 1);
    
    % Generate binary response
    response = binornd(1, p_response);
end 