function [options,paths] = specifyOptions



[paths,dataSet] = getDataSpecs();
options.dataSet = dataSet;
paths.group.modelingDir = '/Users/kwellste/projects/Toolboxes/tapas-6.0.1/';
paths.group.spmDir = '/Users/kwellste/projects/Toolboxes/spm/';
% options = getQuestionnaireDetails(paths);

options.task(1).inputs = load('/Users/kwellste/projects/SEPAB/tasks/social_affective_prediction_task/task/+eventCreator/input_sequence.csv');
options.task(2).inputs = load('/Users/kwellste/projects/SEPAB/tasks/social_affective_prediction_task/control_task/+eventCreator/input_sequence.csv');
options.task(3).inputs = load('/Users/kwellste/projects/SEPAB/tasks/approach_avoid_task/task/+eventCreator/input_sequence.csv');

% optimization algorithm
addpath(genpath(paths.group.modelingDir));
options.hgf.opt_config = eval('tapas_quasinewton_optim_config');

% seed for random number generator
options.rng.idx        = 1; % Set counter for random number states
options.rng.settings   = rng(123, 'twister');
options.rng.nRandInit  = 100;

%% SPECIFY MODELS and related functions
options.setupModels       = [];
options.model.space       = {'HGF_3L','HGF_2L','RW'}; % all models in modelspace
options.model.prc         = {'tapas_ehgf_binary','tapas_ehgf_binary','tapas_rw_binary'};
options.model.prc_config  = {'tapas_ehgf_binary_config_3L','tapas_ehgf_binary_config_2L','tapas_rw_binary_config'};
options.model.obs	      = {'tapas_unitsq_sgm'};
options.model.obs_config  = {'tapas_unitsq_sgm_config'};
options.model.opt_config  = {'tapas_quasinewton_optim_config'};
options.plot(1).plot_fits = @tapas_ehgf_binary_plotTraj;
options.plot(2).plot_fits = @tapas_ehgf_binary_plotTraj;
options.plot(3).plot_fits = @tapas_rw_binary_plotTraj;
end