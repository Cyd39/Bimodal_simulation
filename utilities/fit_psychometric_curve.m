function [fit_result, y_fit] = fit_psychometric_curve(x_data, y_data, modal_params, x_fit)
    % Fit psychometric function to data and return fit results
    % Inputs:
    %   x_data: stimulus levels
    %   y_data: response rates
    %   modal_params: modality-specific parameters (guess_rate, lapse_rate, etc.)
    %   x_fit: x values for fitted curve (optional)
    % Outputs:
    %   fit_result: structure containing fit parameters and statistics
    %   y_fit: fitted y values (if x_fit is provided)
    
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
        
        % Calculate fitted values if x_fit is provided
        if nargin > 3 && ~isempty(x_fit)
            y_fit = fit_result.gamma + (1-fit_result.gamma-fit_result.lambda) ./ ...
                (1 + exp(-fit_result.beta*(x_fit-fit_result.alpha)));
        else
            y_fit = [];
        end
        
    catch ME
        % Use proper warning format with identifier
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
        
        % Use provided guess and lapse rates
        fit_result.gamma = modal_params.guess_rate;
        fit_result.lambda = modal_params.lapse_rate;
        
        % Calculate fitted values if x_fit is provided
        if nargin > 3 && ~isempty(x_fit)
            y_fit = fit_result.gamma + (1-fit_result.gamma-fit_result.lambda) ./ ...
                (1 + exp(-fit_result.beta*(x_fit-fit_result.alpha)));
        else
            y_fit = [];
        end
    end
end 