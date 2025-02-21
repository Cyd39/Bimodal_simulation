function plot_thero_inte_model(experiment_info)
    % Plot theoretical heatmap and surface for integration model
    % Inputs:
    %   experiment_info: Structure containing experiment information
    
    % Extract model parameters and modality name
    model_params = experiment_info.params;  % model_params 从 experiment_info.params 中提取
    modality_name = experiment_info.params.modality;  % modality_name 从 experiment_info.params.modality 中提取
    
    % Add guess_rate and lapse_rate to model_params
    if isfield(experiment_info.params, 'vibration')
        model_params.guess_rate = experiment_info.params.vibration.guess_rate;
        model_params.lapse_rate = experiment_info.params.vibration.lapse_rate;
    elseif isfield(experiment_info.params, 'auditory')
        model_params.guess_rate = experiment_info.params.auditory.guess_rate;
        model_params.lapse_rate = experiment_info.params.auditory.lapse_rate;
    else
        error('Missing required fields: vibration or auditory parameters');
    end

    % Define all available integration models
    model_types = {'linear_sum', 'probability_sum', 'bayesian_optimal', ...
                   'winner_take_all', 'dynamic_weight'};
    
    % Define stimulus intensity range
    stim_levels = linspace(0, 10, 1000);
    
    % Create grid for plotting
    [X, Y] = meshgrid(stim_levels, stim_levels);
    
    % Create a single full-screen figure
    figure('Name', sprintf('Theoretical %s Integration Models', modality_name), ...
           'Units', 'normalized', ...
           'Position', [0.02 0.05 0.96 0.85]);  % Almost full screen

    % Calculate subplot layout
    n_models = length(model_types);
    n_rows = ceil(n_models/2);  % 每两个模型一行
    
    % Loop through each model type
    for k = 1:n_models
        model_type = model_types{k};  % 获取当前模型类型
        Z = zeros(size(X));  % 初始化 Z 矩阵
        
        % Calculate theoretical detection rates using integration_models
        for i = 1:size(X,1)
            for j = 1:size(X,2)
                % Calculate unimodal probabilities
                P_vib = unimodal_prob(X(i,j), experiment_info.params.vibration);
                P_aud = unimodal_prob(Y(i,j), experiment_info.params.auditory);
                
                % Calculate integrated probability using integration_models
                Z(i,j) = integration_models(P_vib, P_aud, model_type, model_params);
            end
        end
        
        % Calculate subplot positions
        row = ceil(k/2);
        col_offset = mod(k-1, 2) * 2;
        
        % 1. Left subplot: Heatmap
        subplot(n_rows, 4, (row-1)*4 + col_offset + 1);
        imagesc(stim_levels, stim_levels, Z);
        colormap(define_colormap());
        colorbar;
        axis xy;
        xlabel('Vibrotactile Intensity');
        ylabel('Auditory Intensity');
        title(sprintf('%s (%s)', modality_name, model_type), 'Interpreter', 'none');
        
        % 2. Right subplot: 3D surface
        subplot(n_rows, 4, (row-1)*4 + col_offset + 2);
        
        % Create denser grid for smooth interpolation
        [Xq, Yq] = meshgrid(linspace(min(stim_levels), max(stim_levels), 50), ...
                           linspace(min(stim_levels), max(stim_levels), 50));
        
        % Use interpolation to generate smooth surface data
        Zq = interp2(X, Y, Z, Xq, Yq, 'cubic');
        
        % Plot smooth 3D surface
        surf(Xq, Yq, Zq);
        colormap(define_colormap());
        colorbar;
        
        % Set 3D surface display properties
        shading interp;
        lighting gouraud;
        material([0.6 0.9 0.2]);
        camlight('headlight');
        
        % Set figure properties
        xlabel('Vibrotactile Intensity');
        ylabel('Auditory Intensity');
        zlabel('Response Rate');
        title(sprintf('%s - Theoretical 3D View (%s)', modality_name, model_type), 'Interpreter', 'none');
        view(45, 30);
        grid on;
        
        % Set axis range
        xlim([min(stim_levels) max(stim_levels)]);
        ylim([min(stim_levels) max(stim_levels)]);
        zlim([0 1.2]);
    end
    
    % Adjust subplot spacing
    set(gcf, 'Units', 'normalized');
    pos = get(gcf, 'Position');
    set(gcf, 'Position', [pos(1) pos(2) pos(3) pos(4)]);
    set(gcf, 'Color', 'white');
    
    % Add more space between subplots
    set(gcf, 'DefaultAxesPosition', [0.1, 0.1, 0.8, 0.8]);
end

% 定义 define_colormap 函数
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