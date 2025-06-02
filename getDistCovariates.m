function cov = getDistCovariates(PID,paths,options)

if nargin < 1
[paths,options] = getDataSpecs();
%     options = SAP_analysis_options();

for n = 1:options.dataSet.nParticipants
    distParams = readmatrix(paths.participant(n).neuroResultsDir,'*.txt');
end


elseif nargin < 2
    [paths,options] = getDataSpecs(PID);
    d = dir(fullfile(paths.participant.neuroResultsDir,'*txt'));
    distParams = readmatrix(fullfile(paths.participant.neuroResultsDir,d(2).name)); %% FIX hardcoded index
    cov.distCovs   = [distParams.^2 distParams];

else
end

end