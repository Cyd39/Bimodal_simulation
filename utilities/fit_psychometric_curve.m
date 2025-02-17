function [fit_result] = fit_psychometric_curve(x_data, y_data)
    % Fit psychometric function to data and return fit results
    % Inputs:
    %   x_data: stimulus levels
    %   y_data: response rates
    % Outputs:
    %   fit_result: structure containing fit parameters and statistics
    
    % Initialize fit result structure
    fit_result = struct(...
        'function_type', 'logistic', ...
        'alpha', NaN, ...
        'beta', NaN, ...
        'gamma', NaN, ...
        'lambda', NaN, ...
        'rsquare', 0, ...
        'fit_success', false);
    
    try
        % Set up fitting options
        ft = fittype('gamma + (1-gamma-lambda)/(1 + exp(-beta*(x-alpha)))', ...
            'independent', 'x', ...
            'coefficients', {'alpha', 'beta', 'gamma', 'lambda'});
        
        opts = fitoptions(ft);
        min_y = min(y_data);
        opts.StartPoint = [mean(x_data), 1, max(0.05,min_y), 0.02];
        opts.Lower = [min(x_data), 0.1, max(0, min_y-0.1), 0];
        opts.Upper = [max(x_data), 10, min(1, min_y+0.3), 0.2];
        
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
                
        y_fit = [];

    end
end 