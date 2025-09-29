function getBehavData


% get paths, filenames, participant IDs etc.
[paths,options] = getDataSpecs([],'main');
groupTable = getGroups(paths,options);

for t = 1:options.dataSet.nTasks
    currTask = options.dataSet.tasks{t};
    predFieldName = [currTask,'Prediction'];

    figure;
    for n = 1:options.dataSet.nParticipants
        currPID = options.dataSet.PIDs(n);
        d = dir(paths.participant(n).task(t,1).dataFile);
        if ~isempty(d)
            load(paths.participant(n).task(t,1).dataFile);
            nGo(n,:)   = nansum(dataFile.(predFieldName).response(:,1));
            nNoGo(n,:) = size(options.task(t).inputs,1)-nansum(dataFile.(predFieldName).response(:,1));
            RTs = dataFile.(predFieldName).rt(:,1);
            meanRTGo(n,:)   = nanmean(RTs(dataFile.(predFieldName).response(:,1)==1));
            meanRTNoGo(n,:) = nanmean(RTs(dataFile.(predFieldName).response(:,1)==0));
            groupID = find(groupTable.PID== currPID);
            group = groupTable.group(groupID,:);
            if strcmp(group,'highScorer')
                colour = [0.7176    0.2745    1.0000];
            else
                colour = [0.0745    0.6235    1.0000];
            end

            plot(dataFile.(predFieldName).response(:,1),'Color',colour);
        else
            nGo(n,:)   = NaN;
            nNoGo(n,:) = NaN;
            meanRTGo(n,:)   = NaN;
            meanRTNoGo(n,:) = NaN;
        end
    end
        % check if current participant is the same as participant in
        % groupTable
        if groupTable(n,:).PID== currPID
            group(n,:) = groupTable.group(n,:);
        else
            groupID = find(groupTable.PID== currPID);
            group(n,:) = groupTable.group(groupID,:);
        end

        savefig([paths.group.resultsPath,predFieldName,'.fig']);

        if strcmp(currTask,'SAP')
            SAP_behavData = table(options.dataSet.PIDs,group,nGo,nNoGo,meanRTGo,meanRTNoGo,'VariableNames',...
                {'ID','group','nSmiles','nNeutrals','meanRTParticipantSmiles','meanRTParticipantNeutral'});

            save([paths.group.resultsPath,'SAP_behavData.mat'],'SAP_behavData');
            writetable(SAP_behavData,[paths.group.resultsPath ,'SAP_behavData.csv']);

        elseif strcmp(currTask,'SAPC')
            SAPC_behavData = table(options.dataSet.PIDs,group,nGo,nNoGo,meanRTGo,meanRTNoGo,'VariableNames',...
                {'ID','group','nCollects','nNoCollects','meanRTParticipantCollects','meanRTNoCollects'});

            save([paths.group.resultsPath,'SAPC_behavData.mat'],'SAPC_behavData');
            writetable(SAPC_behavData,[paths.group.resultsPath ,'SAPC_behavData.csv']);

        elseif strcmp(currTask,'AAA')
            AAA_behavData = table(options.dataSet.PIDs,group,nGo,nNoGo,meanRTGo,meanRTNoGo,'VariableNames',...
                {'ID','group','nApproaches','nAvoids','meanRTParticipantApproaches','meanRTAvoids'});

            save([paths.group.resultsPath,'AAA_behavData.mat'],'AAA_behavData');
            writetable( AAA_behavData,[paths.group.resultsPath ,'AAA_behavData.csv']);

        end

    end
end

