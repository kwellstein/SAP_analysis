function writeModelCSVs(PID, paths, options)


if nargin==0
    [paths,options] = getDataSpecs([],'pilot');
    for n = 1:options.dataSet.nParticipants
        disp(['writing ',num2str(options.dataSet.PIDs(n)),'...']);
        for t = 1:options.dataSet.nTasks
            task = options.dataSet.tasks{t};
            disp(['task ',task,'...']);
            predictField = [task,'Prediction'];
            if ~isempty(dir(paths.participant(n).task(t,2).dataFile))
                load(paths.participant(n).task(t,2).dataFile);
                opts = load(paths.participant(n).task(t,2).optsFile);
                if size(dataFile.(predictField).response,1)==opts.options.task.nTrials
                    modelInputs = array2table(zeros(opts.options.task.nTrials,3),'VariableNames',{'stimulus','input','response'});
                    modelInputs.stimulus = opts.options.task.inputs(:,1);
                    modelInputs.input    = opts.options.task.inputs(:,2);
                    modelInputs.response = dataFile.(predictField).response(:,1);
                    writetable(modelInputs,[paths.participant(n).modelDir,'SAPS_',num2str(options.dataSet.PIDs(n)),'_',task,'_behav.csv'])
                else
                    disp('participant did not complete this task');
                end
            else
                disp('participant did not play this task');
            end
        end
    end

else
    [paths,options] = getDataSpecs(PID);
    for n = 1:options.dataSet.nParticipants
        for t = 1:options.dataSet.nTasks
            load(paths.participant.task(t,1).dataFile);
        end
    end
end

end