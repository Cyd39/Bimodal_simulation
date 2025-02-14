% Test script
clear all;

% Load parameters
params = struct();

% Vibrotactile parameters
params.vibration = struct(...
    'threshold', 2.5, ...
    'slope', 1.2, ...
    'guess_rate', 0.5, ...
    'lapse_rate', 0.02, ...
    'function_type', 'logistic' ...
);

% Auditory parameters
params.auditory = struct(...
    'threshold', 1.8, ...
    'slope', 0.9, ...
    'guess_rate', 0.5, ...
    'lapse_rate', 0.02, ...
    'function_type', 'logistic' ...
);

% Multimodal parameters
params.integration_weights = [0.6, 0.4];

% Temporal parameters
params.temporal = struct(...
    'soa', 0, ...
    'window', 0.1 ...
);

% Test case 1: Response should be close to guess rate with no stimulus
n_tests = 1000;
responses = zeros(n_tests, 1);
for i = 1:n_tests
    [resp, ~] = simulate_trial([0,0], 'linear_sum', params);
    responses(i) = resp;
end
assert(abs(mean(responses) - 0.5) < 0.05, 'Test case 1 failed: No-stimulus response rate should be close to 0.5');

% Test case 2: Strong stimulus should approach 100% detection
responses = zeros(n_tests, 1);
for i = 1:n_tests
    [resp, ~] = simulate_trial([10,10], 'linear_sum', params);
    responses(i) = resp;
end
assert(mean(responses) > 0.99, 'Test case 2 failed: Strong stimulus response rate should be close to 1');

%% Test case 3: Temporal integration effect
soa_test = linspace(-0.3, 0.3, 10);
for i = 1:length(soa_test)
    params.soa = soa_test(i);
    [~, p] = simulate_trial([3,3], 'temporal_integration', params);
    assert(p >= 0 && p <= 1, 'Probability values should be in [0,1] range');
end

%% Test case 4: Dynamic weight model
[resp, p] = simulate_trial([5,1], 'dynamic_weight', params);
[resp_rev, p_rev] = simulate_trial([1,5], 'dynamic_weight', params);
assert(abs(p - p_rev) < 0.1, 'Dynamic weight model should be symmetric');

%% Test case 5: Lapse rate verification
params.vibration.lapse_rate = 0.05;
responses = zeros(1000, 1);
for i = 1:1000
    [resp, ~] = simulate_trial([10,10], 'linear_sum', params);
    responses(i) = resp;
end
assert(abs(mean(responses) - 0.95) < 0.02, 'Strong stimulus detection rate should be close to (1-lapse_rate)');

disp('All test cases passed!'); 