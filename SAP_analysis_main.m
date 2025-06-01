%% SAP_analysis_main

%% INITIALIZE options
% specify paths
[paths,dataSet] = getDataSpecs();

%% FIRST LEVEL
for PID = 1: dataSet.nParticipans
% LOAD RAW image data

% LOAD MODELING Data

% PREPROCESSING


% get regressors
reg = SAP_get_regressors(options,paths,PID);
% FIRST-LEVEL GLM


end

%% SECOND LEVEL


%% GROUP Analysis

%%