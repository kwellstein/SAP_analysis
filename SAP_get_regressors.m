function reg = SAP_get_regressors(PID, paths, options)

if nargin==0
[paths,options] = getDataSpecs(PID);

for n = 1:options.dataSet.nParticipants
    for t = 1:options.dataSet.nTasks
        est = load(paths.participant(n).task(t,1).modelFile);
        load(paths.participant(n).task(t,1).dataFile)
        reg.model(n,t).pe(:) = est.traj.epsi(:,2);
        outcomeTime = dataFile.events.outcome_startTimeStp-dataFile.events.exp_startTime;
        reg.timings(n,t).outcomeTime(:) = outcomeTime/60;
    end
end

elseif nargin < 2
    [paths,options] = getDataSpecs(PID);
    
    for t = 1:options.dataSet.nTasks
        est = load(paths.participant.task(t,1).modelFile);
        load(paths.participant.task(t,1).dataFile)
        reg.model(t).pe(:) = est.traj.epsi(:,2);
        outcomeTime = dataFile.events.outcome_startTimeStp-dataFile.events.exp_startTime;
        reg.timings(t).outcomeTime(:) = outcomeTime/60;
    end
end

end