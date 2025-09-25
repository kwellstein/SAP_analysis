function getPhysioPeaks

% get paths, filenames, participant IDs etc.
[paths,dataSetOpts] = getDataSpecs([],'main');
dataSetOpts = getDataInfo(paths,dataSetOpts);

groupTable = getGroups(paths,dataSetOpts);

% initialize empty matrix
ppu_perTrial = zeros(10000,120);

for t = 1:dataSetOpts.dataSet.nTasks
    currTask = dataSetOpts.dataSet.tasks{t};
    for n = 1:dataSetOpts.dataSet.nParticipants
        % ppu_outcomeIds = []; blockSize = []; ppu_itiIds = []; ppu_newStimIds = []; ...
        %     maxPPUs=[]; nPeaks =[]; timeWindow = []; BL_amp =[]; BL_HR =[];
        currPID =  dataSetOpts.dataSet.PIDs(n);
        disp(['reading ',num2str(currPID),' ',num2str(currTask)]);
        if dataSetOpts.dataSet.participant(n).task(t).neuroComplete==1 || dataSetOpts.dataSet.participant(n).task(t).physioComplete==1
            behavIDs = get_behavIndices(n,currPID,t,currTask,paths);
            if ~isempty(behavIDs)
                % get dataFile containing participant's responses and event timings
                load(paths.participant(n).task(t,1).dataFile);
                taskOpts = load(paths.participant(n).task(t,1).optsFile);
                taskOpts = taskOpts.options;

                f = dir([paths.participant(n).periphDir,num2str(currPID),currTask,'_ppu.mat']);
                if ~isempty(f)

                    load([paths.participant(n).periphDir,num2str(currPID),currTask,'_ppu.mat']);

                    % smooth data using Savitzy-Golay Filter
                    ppuData = smooth(ppu_data.data,'sgolay');

                    ppuTime = ppu_data.time; % make time strings for stringcomp with task timings
                    ppuTime.Format = 'hh:mm:ss'; ppuTime = string(ppuTime);
                    % get peaks , i.e. maximum value within 50 points on x-axis
                    [~,locations,~,~] = findpeaks(ppuData,'MinPeakDistance',50);

                    % the first few datasets where saved in hh:mm:ss format, thus there
                    % are several instances of the same time in the matrix. Use this to
                    % add miliseconds to the times
                    if strcmp(ppu_data.time.Format,'hh:mm:ss')
                        % find out where a new timestamp starts
                        diffvec = ppu_data.time(2:end)-ppu_data.time(1:end-1);
                        newTime = logical(seconds(diffvec)); % make it a logical array
                        ppu_data.time.Format = 'hh:mm:ss.SSS'; % convert into datetime format containing ms

                        iBlock=1; % iBlock for blocks of the same timestamp recorded
                        for i = 1:numel(newTime) % loop through time vector
                            if newTime(i)==1 % for the first block
                                if iBlock == 1
                                    blockSize(iBlock) = i;
                                    addMS = 1000/blockSize(iBlock);
                                    for j = 1:blockSize(iBlock)
                                        if j ==1
                                            ppu_data.time(j) = ppu_data.time(j)+milliseconds(addMS);
                                        else
                                            ppu_data.time(j) = ppu_data.time(j-1)+milliseconds(addMS);
                                        end
                                    end
                                    iBlock = iBlock+1;
                                else % for all the other blocks
                                    blockSize(iBlock) = i-sum(blockSize);
                                    iNewStart = sum(blockSize(1:iBlock-1))+1;
                                    addMS = 1000/blockSize(iBlock);
                                    for j = iNewStart:i
                                        if j ==iNewStart
                                            ppu_data.time(j) = ppu_data.time(j)+milliseconds(addMS);
                                        else
                                            ppu_data.time(j) = ppu_data.time(j-1)+milliseconds(addMS);
                                        end
                                    end
                                    iBlock = iBlock+1;
                                end
                            end
                        end % END time vector loop
                        clear iBlock;
                        clear blockSize;
                    end % END datetime format exception loop
                % else
                %     % % find peaks in struct
                %     % % find times in physio.ons_secs.t 
                %     % % find raw data in physio.ons_secs.c
                %     % physiOFile = load([paths.participant(n).neuroDir,currTask,filesep,'physio',filesep,'physio.mat']);
                %     % ppuTime = physiOFile.physio.ons_secs.t;
                %     % ppuData = physiOFile.physio.ons_secs.c;
                %     % [~,locations,~,~] = findpeaks(ppuData,'MinPeakDistance',50);
                %     % % ppuTime = downsample(ppuTime,10);
                %     % ppuTime = seconds(ppuTime);
                %     % ppuTime = ppuTime + datetime(dataFile.events.baseline_start);
                %     % ppuTime.Format = 'hh:mm:ss';
                %     % ppuTime = string(ppuTime);
                % end

                % Find ppu vector indices for ppu time windows on each trial
                for iTime = 1:numel(dataFile.events.outcome_startTime)
                    % find ppu time index at the same time the outcome was presented
                    ids = find(strcmp(dataFile.events.outcome_startTime(iTime),ppuTime));
                    if isempty(ids)
                        dataFile.events.outcome_startTime(iTime) = datetime(dataFile.events.iti_startTime(iTime))-milliseconds(taskOpts.dur.showOutcome+taskOpts.dur.ITI(iTime));
                        dataFile.events.outcome_startTime(iTime) = extractAfter(dataFile.events.outcome_startTime(iTime),12);
                        ids = find(strcmp(dataFile.events.outcome_startTime(iTime),ppuTime));
                    end
                    ppu_outcomeIds(iTime) = ids(1);
                    ids = find(strcmp(dataFile.events.iti_startTime(iTime),ppuTime));
                    ppu_itiIds(iTime) = ids(1);

                    if iTime < numel(dataFile.events.outcome_startTime)
                        ids = find(strcmp(dataFile.events.stimulus_startTime(iTime+1),ppuTime));
                        ppu_newStimIds(iTime) = ids(1);
                    else
                        ppu_newStimIds(iTime) = ppu_newStimIds(iTime-1)+1000;
                    end
                end

                for iTrial = 1:numel(dataFile.events.outcome_startTime)
                    startIdx = ppu_outcomeIds(iTrial);
                    stopIdx = ppu_newStimIds(iTrial);
                    currData = ppuData(startIdx:stopIdx);
                    ppu_perTrial(:,iTrial) = [currData;zeros(10000-numel(currData),1)];
                    maxPPUs(iTrial)    = max(currData);
                    peakIds = locations(locations>startIdx); peakIds = peakIds(peakIds<stopIdx);
                    trialDurs(iTrial)  = ppu_data.time(stopIdx )-ppu_data.time(startIdx);
                    nPeaks(iTrial)     = numel(peakIds);
                    timeWindow(iTrial) = ppu_data.time(stopIdx)-ppu_data.time(startIdx);
                end

                % get baseline measures
                ids = find(strcmp(dataFile.events.stimulus_startTime(1),ppuTime));
                blStop = ids(1);
                ids = find(strcmp(dataFile.events.baseline_start,ppuTime));
                blStart = ids(1);
                baselineData = ppuData(blStart:blStop);

                bl_peakIds = locations(locations>blStart); bl_peakIds = bl_peakIds(bl_peakIds<blStop);
                nBL_Peaks  = numel(bl_peakIds);
                BL_amp(n,:) = max(baselineData);
                BL_HR(n,:)  = (nBL_Peaks/10)*60;
                posPEs = intersect(behavIDs.stim_positiveIds,behavIDs.incongrIds);
                negPEs = intersect(behavIDs.stim_negativeIds,behavIDs.incongrIds);

                % get event measures
                durations = seconds(trialDurs);
                HR_all = (nPeaks./durations)*60;
                HR_allTrials_mean(n,:) = mean(HR_all);
                HR_allTrials_min(n,:)  = min(HR_all);
                HR_allTrials_max(n,:)  = max(HR_all);
                HR_PEtrials_mean(n,:)  = mean(HR_all(behavIDs.incongrIds));
                HR_PEtrials_min(n,:)   = min(HR_all(behavIDs.incongrIds));
                HR_PEtrials_max(n,:)   = max(HR_all(behavIDs.incongrIds));
                amp_allTrials_mean(n,:)= mean(maxPPUs);
                amp_allTrials_min(n,:) = min(maxPPUs);
                amp_allTrials_max(n,:) = max(maxPPUs);
                amp_PEtrials_mean(n,:) = mean(maxPPUs(behavIDs.incongrIds));
                amp_PEtrials_min(n,:)  = min(maxPPUs(behavIDs.incongrIds));
                amp_PEtrials_max(n,:)  = max(maxPPUs(behavIDs.incongrIds));

                if ~isempty(posPEs)
                    HR_posPEtrials_mean(n,:)  = mean(HR_all(posPEs));
                    HR_posPEtrials_min(n,:)   = min(HR_all(posPEs));
                    HR_posPEtrials_max(n,:)   = max(HR_all(posPEs));
                    amp_posPEtrials_mean(n,:) = mean(maxPPUs(posPEs));
                    amp_posPEtrials_min(n,:)  = min(maxPPUs(posPEs));
                    amp_posPEtrials_max(n,:)  = max(maxPPUs(posPEs));
                else
                    HR_posPEtrials_mean(n,:)  = NaN;
                    HR_posPEtrials_min(n,:)   = NaN;
                    HR_posPEtrials_max(n,:)   = NaN;
                    amp_posPEtrials_mean(n,:) = NaN;
                    amp_posPEtrials_min(n,:)  = NaN;
                    amp_posPEtrials_max(n,:)  = NaN;
                end

                if ~isempty(negPEs)
                    HR_negPEtrials_mean(n,:)  = mean(HR_all(negPEs));
                    HR_negPEtrials_min(n,:)   = min(HR_all(negPEs));
                    HR_negPEtrials_max(n,:)   = max(HR_all(negPEs));
                    amp_negPEtrials_mean(n,:) = mean(maxPPUs(negPEs));
                    amp_negPEtrials_min(n,:)  = min(maxPPUs(negPEs));
                    amp_negPEtrials_max(n,:)  = max(maxPPUs(negPEs));
                else
                    HR_negPEtrials_mean(n,:)  = NaN;
                    HR_negPEtrials_min(n,:)   = NaN;
                    HR_negPEtrials_max(n,:)   = NaN;
                    amp_negPEtrials_mean(n,:) = NaN;
                    amp_negPEtrials_min(n,:)  = NaN;
                    amp_negPEtrials_max(n,:)  = NaN;
                end

                if strcmp(currTask,'SAP')
                    HR_StimSmiletrials_mean(n,:) = mean(HR_all(behavIDs.stim_positiveIds));
                    HR_StimSmiletrials_min(n,:)  = min(HR_all(behavIDs.stim_positiveIds));
                    HR_StimSmiletrials_max(n,:)  = max(HR_all(behavIDs.stim_positiveIds));
                    amp_StimSmiletrials_mean(n,:) = mean(maxPPUs(behavIDs.stim_positiveIds));
                    amp_StimSmiletrials_min(n,:)  = min(maxPPUs(behavIDs.stim_positiveIds));
                    amp_StimSmiletrials_max(n,:)  = max(maxPPUs(behavIDs.stim_positiveIds));


                    HR_partSmiletrials_mean(n,:) = mean(HR_all(behavIDs.part_positiveIds));
                    HR_partSmiletrials_min(n,:)  = min(HR_all(behavIDs.part_positiveIds));
                    HR_partSmiletrials_max(n,:)  = max(HR_all(behavIDs.part_positiveIds));
                    amp_partSmiletrials_mean(n,:) = mean(maxPPUs(behavIDs.part_positiveIds));
                    amp_partSmiletrials_min(n,:)  = min(maxPPUs(behavIDs.part_positiveIds));
                    amp_partSmiletrials_max(n,:)  = max(maxPPUs(behavIDs.part_positiveIds));

                elseif strcmp(currTask,'SAPC')
                    HR_StimGoodtrials_mean(n,:) = mean(HR_all(behavIDs.stim_positiveIds));
                    HR_StimGoodtrials_min(n,:)  = min(HR_all(behavIDs.stim_positiveIds));
                    HR_StimGoodtrials_max(n,:)  = max(HR_all(behavIDs.stim_positiveIds));
                    amp_StimGoodtrials_mean(n,:) = mean(maxPPUs(behavIDs.stim_positiveIds));
                    amp_StimGoodtrials_min(n,:)  = min(maxPPUs(behavIDs.stim_positiveIds));
                    amp_StimGoodtrials_max(n,:)  = max(maxPPUs(behavIDs.stim_positiveIds));

                    HR_partCollecttrials_mean(n,:) = mean(HR_all(behavIDs.part_positiveIds));
                    HR_partCollecttrials_min(n,:)  = min(HR_all(behavIDs.part_positiveIds));
                    HR_partCollecttrials_max(n,:)   = max(HR_all(behavIDs.part_positiveIds));
                    amp_partCollecttrials_mean(n,:) = mean(maxPPUs(behavIDs.part_positiveIds));
                    amp_partCollecttrials_min(n,:)  = min(maxPPUs(behavIDs.part_positiveIds));
                    amp_partCollecttrials_max(n,:)   = max(maxPPUs(behavIDs.part_positiveIds));

                elseif strcmp(currTask,'AAA')
                    HR_partApproachtrials_mean(n,:) = mean(HR_all(behavIDs.part_positiveIds));
                    HR_partApproachtrials_min(n,:)  = min(HR_all(behavIDs.part_positiveIds));
                    HR_partApproachtrials_max(n,:)  = max(HR_all(behavIDs.part_positiveIds));
                    amp_partApproachtrials_mean(n,:) = mean(maxPPUs(behavIDs.part_positiveIds));
                    amp_partApproachtrials_min(n,:)  = min(maxPPUs(behavIDs.part_positiveIds));
                    amp_partApproachtrials_max(n,:)  = max(maxPPUs(behavIDs.part_positiveIds));
                end
            else

                if strcmp(currTask,'SAP')
                    HR_StimSmiletrials_mean(n,:) = NaN;
                    HR_StimSmiletrials_min(n,:)  = NaN;
                    HR_StimSmiletrials_max(n,:)  = NaN;
                    amp_StimSmiletrials_mean(n,:) = NaN;
                    amp_StimSmiletrials_min(n,:)  = NaN;
                    amp_StimSmiletrials_max(n,:)  = NaN;

                    HR_partSmiletrials_mean(n,:) = NaN;
                    HR_partSmiletrials_min(n,:)  = NaN;
                    HR_partSmiletrials_max(n,:)  = NaN;
                    amp_partSmiletrials_mean(n,:) = NaN;
                    amp_partSmiletrials_min(n,:)  = NaN;
                    amp_partSmiletrials_max(n,:)  = NaN;

                elseif strcmp(currTask,'SAPC')
                    HR_StimGoodtrials_mean(n,:) = NaN;
                    HR_StimGoodtrials_min(n,:)  = NaN;
                    HR_StimGoodtrials_max(n,:)  = NaN;
                    amp_StimGoodtrials_mean(n,:) = NaN;
                    amp_StimGoodtrials_min(n,:)  = NaN;
                    amp_StimGoodtrials_max(n,:)  = NaN;

                    HR_partCollecttrials_mean(n,:) = NaN;
                    HR_partCollecttrials_min(n,:)  = NaN;
                    HR_partCollecttrials_max(n,:)   = NaN;
                    amp_partCollecttrials_mean(n,:) = NaN;
                    amp_partCollecttrials_min(n,:)  = NaN;
                    amp_partCollecttrials_max(n,:)   = NaN;

                elseif strcmp(currTask,'AAA')
                    HR_partApproachtrials_mean(n,:) = NaN;
                    HR_partApproachtrials_min(n,:)  = NaN;
                    HR_partApproachtrials_max(n,:)  = NaN;
                    amp_partApproachtrials_mean(n,:) = NaN;
                    amp_partApproachtrials_min(n,:)  = NaN;
                    amp_partApproachtrials_max(n,:)  = NaN;
                end

                HR_allTrials_mean(n,:) = NaN;
                HR_allTrials_min(n,:)  = NaN;
                HR_allTrials_max(n,:)  = NaN;
                HR_PEtrials_mean(n,:)  = NaN;
                HR_PEtrials_min(n,:)   = NaN;
                HR_PEtrials_max(n,:)   = NaN;
                amp_allTrials_mean(n,:)= NaN;
                amp_allTrials_min(n,:) = NaN;
                amp_allTrials_max(n,:) = NaN;
                amp_PEtrials_mean(n,:) = NaN;
                amp_PEtrials_min(n,:)  = NaN;
                amp_PEtrials_max(n,:)  = NaN;

                HR_posPEtrials_mean(n,:)  = NaN;
                HR_posPEtrials_min(n,:)   = NaN;
                HR_posPEtrials_max(n,:)   = NaN;
                amp_posPEtrials_mean(n,:) = NaN;
                amp_posPEtrials_min(n,:)  = NaN;
                amp_posPEtrials_max(n,:)  = NaN;

                HR_negPEtrials_mean(n,:)  = NaN;
                HR_negPEtrials_min(n,:)   = NaN;
                HR_negPEtrials_max(n,:)   = NaN;
                amp_negPEtrials_mean(n,:) = NaN;
                amp_negPEtrials_min(n,:)  = NaN;
                amp_negPEtrials_max(n,:)  = NaN;
                BL_amp(n,:)= NaN;
                BL_HR(n,:)  = NaN;
            end
        else
            disp('participant''s neuro, behavior, and / or physio data not complete');
            HR_allTrials_mean(n,:) = NaN;
            HR_allTrials_min(n,:)  = NaN;
            HR_allTrials_max(n,:)  = NaN;
            HR_PEtrials_mean(n,:)  = NaN;
            HR_PEtrials_min(n,:)   = NaN;
            HR_PEtrials_max(n,:)   = NaN;
            amp_allTrials_mean(n,:)= NaN;
            amp_allTrials_min(n,:) = NaN;
            amp_allTrials_max(n,:) = NaN;
            amp_PEtrials_mean(n,:) = NaN;
            amp_PEtrials_min(n,:)  = NaN;
            amp_PEtrials_max(n,:)  = NaN;

            HR_posPEtrials_mean(n,:)  = NaN;
            HR_posPEtrials_min(n,:)   = NaN;
            HR_posPEtrials_max(n,:)   = NaN;
            amp_posPEtrials_mean(n,:) = NaN;
            amp_posPEtrials_min(n,:)  = NaN;
            amp_posPEtrials_max(n,:)  = NaN;

            HR_negPEtrials_mean(n,:)  = NaN;
            HR_negPEtrials_min(n,:)   = NaN;
            HR_negPEtrials_max(n,:)   = NaN;
            amp_negPEtrials_mean(n,:) = NaN;
            amp_negPEtrials_min(n,:)  = NaN;
            amp_negPEtrials_max(n,:)  = NaN;
            BL_amp(n,:)= NaN;
            BL_HR(n,:)  = NaN;
        end
        %% save individual participant data

        % find participant specific path
        savePath =[];
        for iDir = 1:numel(paths.participant)
            dirPath = paths.participant(iDir).questDir;
            if contains(dirPath,num2str(currPID))
                savePath = paths.participant(iDir).questDir;
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

    end
    end

if strcmp(currTask,'SAP')
    SAP_HRTable = table(dataSetOpts.dataSet.PIDs,group,BL_HR,HR_allTrials_mean,HR_allTrials_min,HR_allTrials_max,...
        HR_PEtrials_mean, HR_PEtrials_min, HR_PEtrials_max, HR_posPEtrials_mean, HR_posPEtrials_min, HR_posPEtrials_max, ...
        HR_negPEtrials_mean, HR_negPEtrials_min, HR_negPEtrials_max,HR_StimSmiletrials_mean,HR_StimSmiletrials_min,...
        HR_StimSmiletrials_max,HR_partSmiletrials_mean,HR_partSmiletrials_min,HR_partSmiletrials_max,'VariableNames',...
        {'ID','group','HR_baseline','meanHR_all','minHR_all','maxHR_all','meanHR_PE','minHR_PE','maxHR_PE', ...
        'meanHR_posPE','minHR_posPE','maxHR_posPE','meanHR_negPE','minHR_negPE','maxHR_negPE',...
        'meanHR_stimSmile','minHR_stimSmile','maxHR_stimSmile','meanHR_participantSmile',...
        'minHR_participantSmile','maxHR_participantSmile'});

    save([paths.group.resultsPath,'SAP_HRTable.mat'],'SAP_HRTable');
    writetable(SAP_HRTable,[paths.group.resultsPath ,'SAP_HRTable.csv']);

    SAP_AmplitudeTable = table(dataSetOpts.dataSet.PIDs,group,BL_amp,amp_allTrials_mean,amp_allTrials_min,amp_allTrials_max,...
        amp_PEtrials_mean, amp_PEtrials_min, amp_PEtrials_max,amp_posPEtrials_mean, amp_posPEtrials_min, amp_posPEtrials_max, ...
        amp_negPEtrials_mean, amp_negPEtrials_min, amp_negPEtrials_max,amp_StimSmiletrials_mean,amp_StimSmiletrials_min,...
        amp_StimSmiletrials_max,amp_partSmiletrials_mean,amp_partSmiletrials_min,amp_partSmiletrials_max,'VariableNames',...
        {'ID','group','amplitude_baseline','meanAmp_all','minAmp_all','maxAmp_all','meanAmp_PE','minAmp_PE','maxHR_PE',...
        'meanAmp_posPE','minAmp_posPE','maxAmp_posPE','meanAmp_negPE','minAmp_negPE','maxAmp_negPE',...
        'meanAmp_stimSmile','minAmp_stimSmile','maxAmp_stimSmile','meanAmp_participantSmile',...
        'minAmp_participantSmile','maxAmp_participantSmile'});

    save([paths.group.resultsPath,'SAP_AmplitudeTable.mat'],'SAP_AmplitudeTable');
    writetable(SAP_AmplitudeTable,[paths.group.resultsPath ,'SAP_AmplitudeTable.csv']);

elseif strcmp(currTask,'SAPC')
    SAPC_HRTable = table(dataSetOpts.dataSet.PIDs,group,BL_HR,HR_allTrials_mean,HR_allTrials_min,HR_allTrials_max,...
        HR_PEtrials_mean, HR_PEtrials_min, HR_PEtrials_max, HR_posPEtrials_mean, HR_posPEtrials_min, HR_posPEtrials_max, ...
        HR_negPEtrials_mean, HR_negPEtrials_min, HR_negPEtrials_max,HR_StimGoodtrials_mean,HR_StimGoodtrials_min,...
        HR_StimGoodtrials_max,HR_partCollecttrials_mean,HR_partCollecttrials_min,HR_partCollecttrials_max,'VariableNames',...
        {'ID','group','HR_baseline','meanHR_all','minHR_all','maxHR_all','meanHR_PE','minHR_PE','maxHR_PE',...
        'meanHR_posPE','minHR_posPE','maxHR_posPE','meanHR_negPE','minHR_negPE','maxHR_negPE', ...
        'meanHR_stimGood','minHR_stimGood','maxHR_stimGood','meanHR_collect','minHR_collect','maxHR_collect'});

    save([paths.group.resultsPath,'SAPC_HRTable.mat'],'SAPC_HRTable');
    writetable(SAPC_HRTable,[paths.group.resultsPath ,'SAPC_HRTable.csv']);

    SAPC_AmplitudeTable = table(dataSetOpts.dataSet.PIDs,group,BL_amp,amp_allTrials_mean,amp_allTrials_min,amp_allTrials_max,...
        amp_PEtrials_mean, amp_PEtrials_min, amp_PEtrials_max,amp_posPEtrials_mean, amp_posPEtrials_min, amp_posPEtrials_max, ...
        amp_negPEtrials_mean, amp_negPEtrials_min, amp_negPEtrials_max,amp_StimGoodtrials_mean,amp_StimGoodtrials_min,...
        amp_StimGoodtrials_max,amp_partCollecttrials_mean,amp_partCollecttrials_min,amp_partCollecttrials_max,'VariableNames',...
        {'ID','group','amplitude_baseline','meanAmp_all','minAmp_all','maxAmp_all','meanAmp_PE','minAmp_PE','maxAmp_PE', ...
        'meanAmp_posPE','minAmp_posPE','maxAmp_posPE','meanAmp_negPE','minAmp_negPE','maxAmp_negPE',...
        'meanAmp_stimSmile','minAmp_stimGood','maxAmp_stimGood','meanAmp_collect','minAmp_collect','maxAmp_collect'});

    save([paths.group.resultsPath,'SAPC_AmplitudeTable.mat'],'SAPC_AmplitudeTable');
    writetable(SAPC_AmplitudeTable,[paths.group.resultsPath,'SAPC_AmplitudeTable.csv']);

elseif strcmp(currTask,'AAA')
    AAA_HRTable = table(dataSetOpts.dataSet.PIDs,group,BL_HR,HR_allTrials_mean,HR_allTrials_min,HR_allTrials_max,...
        HR_PEtrials_mean, HR_PEtrials_min, HR_PEtrials_max,HR_posPEtrials_mean, HR_posPEtrials_min, HR_posPEtrials_max, ...
        HR_negPEtrials_mean, HR_negPEtrials_min, HR_negPEtrials_max,HR_partApproachtrials_mean,HR_partApproachtrials_min,...
        HR_partApproachtrials_max,'VariableNames',{'ID','group','HR_baseline','meanHR_all','minHR_all','maxHR_all', ...
        'meanHR_posPE','minHR_posPE','maxHR_posPE','meanHR_negPE','minHR_negPE','maxHR_negPE', ...
        'meanHR_PE','minHR_PE','maxHR_PE','meanHR_approach','minHR_approach','maxHR_approach'});

    save([paths.group.resultsPath,'AAA_HRTable.mat'],'AAA_HRTable');
    writetable(AAA_HRTable,[paths.group.resultsPath ,'AAA_HRTable.csv']);

    AAA_AmplitudeTable = table(dataSetOpts.dataSet.PIDs,group,BL_amp,amp_allTrials_mean,amp_allTrials_min,amp_allTrials_max,...
        amp_PEtrials_mean, amp_PEtrials_min, amp_PEtrials_max,amp_posPEtrials_mean, amp_posPEtrials_min, amp_posPEtrials_max, ...
        amp_negPEtrials_mean, amp_negPEtrials_min, amp_negPEtrials_max,amp_partApproachtrials_mean,amp_partApproachtrials_min,...
        amp_partApproachtrials_max,'VariableNames',...
        {'ID','group','amplitude_baseline','meanAmp_all','minAmp_all','maxAmp_all','meanAmp_PE','minAmp_PE','maxAmp_PE', ...
        'meanAmp_posPE','minAmp_posPE','maxAmp_posPE','meanAmp_negPE','minAmp_negPE','maxAmp_negPE',...
        'meanAmp_approach','minAmp_approach','maxAmp_approach'});

    save([paths.group.resultsPath,'AAA_AmplitudeTable.mat'],'AAA_AmplitudeTable');
    writetable(AAA_AmplitudeTable,[paths.group.resultsPath ,'AAA_AmplitudeTable.csv']);
end
end
