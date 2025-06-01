function [paths,options] = getDataSpecs()

paths.group.dataPath    = '/Volumes/Samsung_T5/SNG/projects/SAPS/data/';
paths.group.resultsPath = '/Volumes/Samsung_T5/SNG/projects/SAPS/data/';
paths.group.modelingDir = '/Users/kwellste/projects/Toolboxes/tapas-6.0.1/';
paths.group.spmDir      = '/Users/kwellste/projects/Toolboxes/spm/';

d = dir('/Volumes/Samsung_T5/SNG/projects/SAPS/data/SAPS_*');
options.dataSet.acronym = 'SAPS';
options.dataSet.tasks = {'SAP','SAPC'};
options.dataSet.nTasks = numel(options.dataSet.tasks);
options.dataSet.nParticipants = size(d,1);
options.dataSet.PIDs = zeros(options.dataSet.nParticipants,1);

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
options.plot(1).plot_fits = @tapas_ehgf_plotTraj_mod;
options.plot(2).plot_fits = @tapas_ehgf_plotTraj_mod;
options.plot(3).plot_fits = @tapas_rw_binary_plotTraj;


for i = 1:options.dataSet.nParticipants
    digits = regexp(d(i).name, '[0-9]');
    PID = str2double(d(i).name(digits));
    options.dataSet.PIDs(i) = PID;
    paths.participant(i).behavDir  = [paths.group.dataPath,d(i).name,filesep,'experiment',filesep];
    paths.participant(i).periphDir = [paths.group.dataPath,d(i).name,filesep,'peripheral',filesep];
    paths.participant(i).neuroDir  = [paths.group.dataPath,d(i).name,filesep,'neuro',filesep];
    paths.participant(i).questDir  = [paths.group.dataPath,d(i).name,filesep,'questionnaires',filesep];
    paths.participant(i).modelDir  = [paths.group.dataPath,d(i).name,filesep,'modeling',filesep];
    paths.participant(i).resultsDir  = [paths.group.dataPath,d(i).name,filesep,'results',filesep];

    for t = 1:options.dataSet.nTasks
        task = options.dataSet.tasks{t};
        paths.participant(i).task(t,1).optsFile = [paths.participant(i).behavDir,'SNG_',task,'_',char(string(PID)),'_fmri_optionsFile.mat'];
        paths.participant(i).task(t,1).dataFile = [paths.participant(i).behavDir,'SNG_',task,'_',char(string(PID)),'_fmri_dataFile.mat'];
        for m = 1:numel(options.model.space)
            paths.participant(i).task(t,m).modelFile    = [paths.participant(i).modelDir,'SNG_',options.model.space{m},'_',task,'_',options.dataSet.acronym,'_',char(string(PID)),'_est.mat'];
            paths.participant(i).task(t,m).modelFigFile = [paths.participant(i).modelDir,'SNG_',options.model.space{m},'_',task,'_',options.dataSet.acronym,'_',char(string(PID)),'.fig'];
        end
    end
end

end