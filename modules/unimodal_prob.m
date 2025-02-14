function P = unimodal_prob(x, modality_params)
    % Calculate unimodal detection probability without guess/lapse rates
    % Inputs:
    %   x: Stimulus intensity
    %   modality_params: Structure containing parameters for specific modality
    
    % Core psychophysical function calculation
    switch modality_params.function_type
        case 'logistic'
            P = 1 ./ (1 + exp(-modality_params.slope * (x - modality_params.threshold)));
        case 'weibull'
            P = 1 - exp(-(x/modality_params.threshold).^modality_params.slope);
        case 'gaussian'
            P = 0.5 * (1 + erf((x - modality_params.threshold)/(modality_params.slope * sqrt(2))));
    end
end 