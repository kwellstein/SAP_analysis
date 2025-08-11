function reg = SAP_get_regressors(PID, paths, options)

inputs = readmatrix('/Users/kwellste/projects/SEPAB/tasks/social_affective_prediction_task/task/+eventCreator/input_sequence.csv');

if nargin==0
    [paths,options] = getDataSpecs();
    load([paths.jlModel.MainResPath,'est.mat']);
    for n = 1:options.dataSet.nParticipants

        for t = 1:2%options.dataSet.nTasks

            if t == 2
                if ~isempty(dir(paths.participant(n).task(t,1).optsFile))
                opts = load(paths.participant(n).task(t,1).optsFile);
                j = 1;
                d = dir([paths.participant(n).neuroDir,options.dataSet.tasks{1},filesep,'*txt']);
                for i = 1:size(d,1)
                    if ~startsWith(d(i).name,'._')
                        neuro(j).y = load([paths.participant(n).neuroDir,options.dataSet.tasks{1},filesep,d(i).name]);
                        j = j+1;
                    end
                end
                j = j-1;
                if opts.options.task.sequenceIdx==1
                    reg.neuro(n).neuroReg = [neuro(2).y (neuro(2).y).^2;neuro(1).y (neuro(1).y).^2];

                else
                    reg.neuro(n).neuroReg = [neuro(1).y (neuro(1).y).^2;neuro(2).y (neuro(2).y).^2];
                end
                end
            else

            end
            if ~isempty(est(n,t).xprob1_PE)
                predictField = [options.dataSet.tasks{t},'Prediction'];
                load(paths.participant(1,n).task(t,1).dataFile);
                missedIds = find(dataFile.events.exp_missedTrial==1);
                if any(dataFile.events.outcome_startTimeStp==0)
                    outcomeTime = (dataFile.events.iti_startTimeStp-(dataFile.events.task_startTime-10));
                    outcomeTime = (outcomeTime-0.5);
                    predictionTime = (dataFile.events.stimulus_startTimeStp-(dataFile.events.task_startTime-10));
                    predictionTime = (predictionTime-0.5);
                    itiTime = (dataFile.events.iti_startTimeStp-(dataFile.events.task_startTime-10));
                    itiTime = (itiTime-0.5);
                else
                    outcomeTime    = (dataFile.events.outcome_startTimeStp-(dataFile.events.task_startTime-10));
                    predictionTime = (dataFile.events.stimulus_startTimeStp-(dataFile.events.task_startTime-10));
                    itiTime        = (dataFile.events.iti_startTimeStp-(dataFile.events.task_startTime-10));
                end

                PEs = est(n,t).xprob1_PE';
                incongr = dataFile.(predictField).congruent;
                incongr(incongr==1)=0;  incongr(incongr==-1)=1;
                positiveIds = find(inputs(:,2)==1);
                negativeIds = find(inputs(:,2)==0);
                if ~isempty(missedIds)
                    PEs(missedIds)=0;
                    incongr(missedIds)=[];

                    missedPositives = intersect(positiveIds,missedIds);
                    if ~isempty(missedPositives)
                        for j=1:numel(missedPositives)
                            positiveIds(positiveIds==missedPositives(j))=[];
                        end
                    end

                    missedNegatives = intersect(negativeIds,missedIds);
                    if ~isempty(missedNegatives)
                        for i=1:numel(missedNegatives)
                            negativeIds(negativeIds==missedNegatives(i))=[];
                        end
                    end
                    outcomeTime(missedIds)=[];
                end
                incongrIds = find(incongr==1);
                surprisePositive = intersect(positiveIds,incongrIds);
                surpriseNegative = intersect(negativeIds,incongrIds);
                reg.model(n,t).pwPE   = PEs;
                reg.model(n,t).pwPE_pos = PEs(surprisePositive);
                reg.model(n,t).pwPE_neg = PEs(surpriseNegative);
                reg.model(n,t).pwPE_none = PEs(~logical(incongr));
                reg.behav(n,t).incongr = incongr;
                reg.timings(n,t).outcomeTime    = double(outcomeTime);
                reg.timings(n,t).predictionTime = double(predictionTime);
                reg.timings(n,t).itiTime   = double(itiTime);
                reg.timings(n,t).PEtimes   = double(outcomeTime(logical(incongr)));
                reg.timings(n,t).noPEtimes = double(outcomeTime(~logical(incongr)));
                reg.timings(n,t).surprisePositiveTimes = double(outcomeTime(surprisePositive));
                reg.timings(n,t).surpriseNegativeTimes = double(outcomeTime(surpriseNegative));
            end
        end
    end
elseif nargin < 2
    [paths,options] = getDataSpecs(PID);

    for t = 1:2%options.dataSet.nTasks
        predictField = [options.dataSet.tasks{t},'Prediction'];
        load(paths.participant.task(t,1).dataFile)
        reg.model(t).pe(:) = est(1,t).xprob1_PE;
        incongr = dataFile.(predictField).congruent;
        incongr(incongr==1)=0;  incongr(incongr==-1)=1;
        reg.behav(t).incongr(:) = incongr;
        outcomeTime = (dataFile.events.outcome_startTimeStp-dataFile.events.exp_startTime)/60;
        reg.timings(t).outcomeTime(:) = outcomeTime;
        reg.timings(t).PEtimes(:) = outcomeTime(incongr);
        reg.timings(t).surpriseSmileTimes(:) = outcomeTime(incongr);
    end

else
    for t = 1:2%options.dataSet.nTasks
        predictField = [options.dataSet.tasks{t},'Prediction'];
        est = load(paths.participant.task(t,1).modelFile);
        load(paths.participant.task(t,1).dataFile)
        reg.model(t).pe(:) = est.traj.epsi(:,2);
        incongr = dataFile.(predictField).congruent;
        incongr(incongr==1)=0;  incongr(incongr==-1)=1;
        reg.behav(t).incongr(:) = incongr;
        outcomeTime = (dataFile.events.outcome_startTimeStp-dataFile.events.exp_startTime)/60;
        reg.timings(t).outcomeTime(:) = outcomeTime;
        reg.timings(t).PEtimes(:) = outcomeTime(incongr);
        reg.timings(t).surpriseSmileTimes(:) = outcomeTime(incongr);
    end
end

save([paths.group.resultsPath,'regressors.mat'],'reg');

end