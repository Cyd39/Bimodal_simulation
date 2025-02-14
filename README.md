# Multimodal Detection Simulation System

A MATLAB-based simulation system for studying multimodal perception and integration, focusing on vibrotactile and auditory detection.

## Features

- Unimodal detection simulation (vibrotactile and auditory)
- Multimodal integration with multiple models
- Psychometric function fitting
- Interactive GUI interface
- Comprehensive data visualization
- Multi-session support for unimodal experiments

## Quick Start

1. Set parameters in the GUI or programmatically:
```matlab 
params.vibration.threshold = 2.5;  % Vibrotactile threshold θ
params.vibration.slope = 1.2;      % Vibrotactile slope k
params.auditory.threshold = 1.8;   % Auditory threshold θ
params.auditory.slope = 0.9;       % Auditory slope k
```

2. Run the simulation:
```matlab
main_simulation
```

3. View results in the generated figures and saved data files in the `results` directory  

## Project Structure
```
/project_root

│ main_simulation.m % Main entry point
│ README.md % Documentation
│
├───modules/
│ run_multimodal_simulation.m % Core simulation engine
│ unimodal_prob.m % Unimodal probability calculation
│ integration_models.m % Multimodal integration algorithms
│ simulate_trial.m % Single trial simulation
│
└───utilities/
plot_results.m % Results visualization
gui_interface.m % GUI implementation
```

## Testing

Run `test_simulation.m` to execute unit tests covering:
- Baseline response rates
- Strong stimulus detection
- Temporal integration effects
- Dynamic weight symmetry
- Lapse rate verification

## Requirements

- MATLAB R2019b or later
- Statistics and Machine Learning Toolbox
- Curve Fitting Toolbox

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.