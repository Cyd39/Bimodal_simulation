% Startup script: Add required directories to MATLAB path
% Get current directory as project root
project_root = pwd;

% Add subdirectories to path
addpath(fullfile(project_root, 'modules'));
addpath(fullfile(project_root, 'utilities'));

% Confirm successful addition
disp('Added following directories to MATLAB path:');
disp(['- ' fullfile(project_root, 'modules')]);
disp(['- ' fullfile(project_root, 'utilities')]); 