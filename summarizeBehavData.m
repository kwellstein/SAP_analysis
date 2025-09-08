function summarizeBehavData(PID, paths, options)

summaryTable = array2table(zeros(16,6),'VariableNames',{'PID','group','points','nApproaches','meanRT','maxAmp_negPE'});

if nargin==0
    [paths,options] = getDataSpecs([],'main');
    for t = 1:options.dataSet.nTasks
        task = options.dataSet.tasks{t};
        amps = readtable(['/Volumes/Samsung_T5/SNG/projects/SAPS/data/group/',task,'_AmplitudeTable.csv']);
        disp(['task ',task,'...']);
        predictField = [task,'Prediction'];
        for n = 1:options.dataSet.nParticipants
            disp(['writing ',num2str(options.dataSet.PIDs(n)),'...']);

            if ~isempty(dir(paths.participant(n).task(t,1).dataFile))
                load(paths.participant(n).task(t,1).dataFile);
                opts = load(paths.participant(n).task(t,1).optsFile);
                if size(dataFile.(predictField).response,1)==opts.options.task.nTrials
                    summaryTable.PID(n)    = options.dataSet.PIDs(n);
                    if strcmp(amps.Group{n},'high')
                        summaryTable.group(n)    = 2;
                    else
                        summaryTable.group(n)    = 1;
                    end
                    summaryTable.points(n)  = dataFile.Summary.points;
                    summaryTable.nApproaches(n)  =  nansum(dataFile.(predictField).response(:,1));
                    summaryTable.meanRT(n)       =  nanmean(dataFile.(predictField).rt);
                    summaryTable.maxAmp_negPE(n) =  nanmean(amps.maxAmp_negPE(n));
                    if n==1
                        figure;
                    end
                    if strcmp(amps.Group{n},'high')
                        plot(dataFile.(predictField).rt,'Color',[0.9294    0.6941    0.1255])
                        hold on
                    else
                        plot(dataFile.(predictField).rt,'Color','k')
                        hold on
                    end


                else
                    disp('participant did not complete this task');
                end
            else
                disp('participant did not play this task');
            end

        end
        writetable(summaryTable,[paths.group.resultsPath,'SAPS_',task,'_behavSummary.csv']);
        savefig([paths.group.resultsPath,'SAPS_',task,'_rts.fig']);
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