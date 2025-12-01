function getPhysioPeaks

% get paths, filenames, participant IDs etc.
[paths,dataSetOpts] = getDataSpecs([],'main');
dataSetOpts = getDataInfo(paths,dataSetOpts);

groupTable = getGroups(paths,dataSetOpts);

% initialize empty matrices
ppuOutcome_perTrial    = zeros(10000,120);
ppuPreOutcome_perTrial = zeros(10000,120);
IBIs_perTrial = zeros(7,120);

for t = 3:dataSetOpts.dataSet.nTasks
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

                f = dir([paths.participant(n).task(t,1).periphDir,num2str(currPID),currTask,'_ppu.mat']);
                if ~isempty(f)

                    load([paths.participant(n).task(t,1).periphDir,num2str(currPID),currTask,'_ppu.mat']);

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
                        ids = find(strcmp(dataFile.events.stimulus_startTime(iTime),ppuTime));
                        ppu_newStimIds(iTime) = ids(1);
                    end

                    % baseline time stamps
                    blStop = ppu_newStimIds(1);
                    ids = find(strcmp(dataFile.events.baseline_start,ppuTime));
                    blStart = ids(1);

                    for iTrial = 1:numel(dataFile.events.outcome_startTime)
                        startIdx    = ppu_outcomeIds(iTrial);
                        preStartIdx = ppu_newStimIds(iTrial);
                        if iTrial < numel(dataFile.events.outcome_startTime)
                            stopIdx     = ppu_newStimIds(iTrial+1);
                        else
                            stopIdx     = ppu_newStimIds(iTrial)+1000;
                        end

                        currData    = ppuData(startIdx:stopIdx);
                        preCurrData = ppuData(preStartIdx:startIdx);
                        ppuOutcome_perTrial(:,iTrial) = [currData;zeros(10000-numel(currData),1)];
                        ppuPreOutcome_perTrial(:,iTrial) = [preCurrData;zeros(10000-numel(preCurrData),1)];

                        maxPPUs(iTrial)    = max(currData);
                        outcomePeakIds     = locations(locations>startIdx); outcomePeakIds = outcomePeakIds(outcomePeakIds<stopIdx);
                        preOutcomePeakIds  = locations(locations>preStartIdx); preOutcomePeakIds = preOutcomePeakIds(preOutcomePeakIds<startIdx);
                        trialDurs(iTrial)  = ppu_data.time(stopIdx)-ppu_data.time(startIdx);
                        nPeaks(iTrial)     = numel(outcomePeakIds);
                        timeWindow(iTrial) = ppu_data.time(stopIdx)-ppu_data.time(startIdx);

                        for iIBI = 1:size(IBIs_perTrial,1)

                            if iIBI == 1
                                if ~isempty(preOutcomePeakIds)
                                    if numel(preOutcomePeakIds)>1
                                        IBIs_perTrial(iIBI,iTrial) = preOutcomePeakIds(end)-preOutcomePeakIds(end-1);
                                    else
                                        IBIs_perTrial(iIBI,iTrial) = NaN;
                                    end
                                else
                                    IBIs_perTrial(iIBI,iTrial) = NaN;
                                end

                            elseif iIBI == 2
                                if ~isempty(preOutcomePeakIds)
                                    IBIs_perTrial(iIBI,iTrial) = outcomePeakIds(1)-preOutcomePeakIds(end);
                                else
                                    IBIs_perTrial(iIBI,iTrial) = NaN;
                                end
                           

                            elseif iIBI > numel(outcomePeakIds)
                                IBIs_perTrial(iIBI,iTrial) = NaN;
                            else
                                IBIs_perTrial(iIBI,iTrial) = outcomePeakIds(iIBI)-outcomePeakIds(iIBI-1);
                            end
                        end

                    end

                    % get baseline measures
                    baselineData = ppuData(blStart:blStop);
                    bl_peakIds = locations(locations>blStart); bl_peakIds = bl_peakIds(bl_peakIds<blStop);
                    nBL_Peaks  = numel(bl_peakIds);
                    BL_amp(n,:) = max(baselineData);
                    BL_HR(n,:)  = (nBL_Peaks/10)*60;


                    % get event measures
                    durations = seconds(trialDurs);
                    HR_all = (nPeaks./durations)*60;
                    HR_allTrials_mean(n,:) = mean(HR_all);
                    HR_allTrials_min(n,:)  = min(HR_all);
                    HR_allTrials_max(n,:)  = max(HR_all);
                    amp_allTrials_mean(n,:)= mean(maxPPUs);
                    amp_allTrials_min(n,:) = min(maxPPUs);
                    amp_allTrials_max(n,:) = max(maxPPUs);
                    posOutcome = intersect(behavIDs.part_positiveIds,behavIDs.stim_positiveIds);
                    negOutcome = intersect(behavIDs.part_positiveIds,behavIDs.stim_negativeIds);

                    if strcmp(currTask,'AAA')
                        if ~isempty(posOutcome)
                            HR_posOutcomes_mean(n,:) = mean(HR_all(posOutcome));
                            HR_posOutcomes_min(n,:)  = min(HR_all(posOutcome));
                            HR_posOutcomes_max(n,:)  = max(HR_all(posOutcome));
                            amp_posOutcomes_mean(n,:) = mean(maxPPUs(posOutcome));
                            amp_posOutcomes_min(n,:)  = min(maxPPUs(posOutcome));
                            amp_posOutcomes_max(n,:)  = max(maxPPUs(posOutcome));
                            IBI1_posOutcomes(n,:)     = nanmean(IBIs_perTrial(1,posOutcome));
                            IBI2_posOutcomes(n,:)     = nanmean(IBIs_perTrial(2,posOutcome));
                            IBI3_posOutcomes(n,:)     = nanmean(IBIs_perTrial(3,posOutcome));
                            IBI4_posOutcomes(n,:)     = nanmean(IBIs_perTrial(4,posOutcome));
                            IBI5_posOutcomes(n,:)     = nanmean(IBIs_perTrial(5,posOutcome));
                            IBI6_posOutcomes(n,:)     = nanmean(IBIs_perTrial(6,posOutcome));
                            IBI7_posOutcomes(n,:)     = nanmean(IBIs_perTrial(7,posOutcome));
                        else
                            HR_posOutcomes_mean(n,:) = NaN;
                            HR_posOutcomes_min(n,:)  = NaN;
                            HR_posOutcomes_max(n,:)  = NaN;
                            amp_posOutcomes_mean(n,:) = NaN;
                            amp_posOutcomes_min(n,:)  = NaN;
                            amp_posOutcomes_max(n,:)  = NaN;
                            IBI1_posOutcomes(n,:) = NaN;
                            IBI2_posOutcomes(n,:) = NaN;
                            IBI3_posOutcomes(n,:) = NaN;
                            IBI4_posOutcomes(n,:) = NaN;
                            IBI5_posOutcomes(n,:) = NaN;
                            IBI6_posOutcomes(n,:) = NaN;
                            IBI7_posOutcomes(n,:) = NaN;
                        end

                        if ~isempty(negOutcome)
                            HR_negOutcomes_mean(n,:) = mean(HR_all(negOutcome));
                            HR_negOutcomes_min(n,:)  = min(HR_all(negOutcome));
                            HR_negOutcomes_max(n,:)  = max(HR_all(negOutcome));
                            amp_negOutcomes_mean(n,:) = mean(maxPPUs(negOutcome));
                            amp_negOutcomes_min(n,:)  = min(maxPPUs(negOutcome));
                            amp_negOutcomes_max(n,:)  = max(maxPPUs(negOutcome));
                            IBI1_negOutcomes(n,:)     = nanmean(IBIs_perTrial(1,negOutcome));
                            IBI2_negOutcomes(n,:)     = nanmean(IBIs_perTrial(2,negOutcome));
                            IBI3_negOutcomes(n,:)     = nanmean(IBIs_perTrial(3,negOutcome));
                            IBI4_negOutcomes(n,:)     = nanmean(IBIs_perTrial(4,negOutcome));
                            IBI5_negOutcomes(n,:)     = nanmean(IBIs_perTrial(5,negOutcome));
                            IBI6_negOutcomes(n,:)     = nanmean(IBIs_perTrial(6,negOutcome));
                            IBI7_negOutcomes(n,:)     = nanmean(IBIs_perTrial(7,negOutcome));
                        else
                            HR_negOutcomes_mean(n,:) = NaN;
                            HR_negOutcomes_min(n,:)  = NaN;
                            HR_negOutcomes_max(n,:)  = NaN;
                            amp_negOutcomes_mean(n,:) = NaN;
                            amp_negOutcomes_min(n,:)  = NaN;
                            amp_negOutcomes_max(n,:)  = NaN;
                            IBI1_negOutcomes(n,:)     = NaN;
                            IBI2_negOutcomes(n,:)     = NaN;
                            IBI3_negOutcomes(n,:)     = NaN;
                            IBI4_negOutcomes(n,:)     = NaN;
                            IBI5_negOutcomes(n,:)     = NaN;
                            IBI6_negOutcomes(n,:)     = NaN;
                            IBI7_negOutcomes(n,:)     = NaN;
                        end

                    else
                        posPEs = intersect(behavIDs.stim_positiveIds,behavIDs.incongrIds);
                        negPEs = intersect(behavIDs.stim_negativeIds,behavIDs.incongrIds);
                        HR_PEtrials_mean(n,:)  = mean(HR_all(behavIDs.incongrIds));
                        HR_PEtrials_min(n,:)   = min(HR_all(behavIDs.incongrIds));
                        HR_PEtrials_max(n,:)   = max(HR_all(behavIDs.incongrIds));

                        amp_PEtrials_mean(n,:) = mean(maxPPUs(behavIDs.incongrIds));
                        amp_PEtrials_min(n,:)  = min(maxPPUs(behavIDs.incongrIds));
                        amp_PEtrials_max(n,:)  = max(maxPPUs(behavIDs.incongrIds));

                        IBI1_PEtrials(n,:)     = nanmean(IBIs_perTrial(1,behavIDs.incongrIds));
                        IBI2_PEtrials(n,:)     = nanmean(IBIs_perTrial(2,behavIDs.incongrIds));
                        IBI3_PEtrials(n,:)     = nanmean(IBIs_perTrial(3,behavIDs.incongrIds));
                        IBI4_PEtrials(n,:)     = nanmean(IBIs_perTrial(4,behavIDs.incongrIds));
                        IBI5_PEtrials(n,:)     = nanmean(IBIs_perTrial(5,behavIDs.incongrIds));
                        IBI6_PEtrials(n,:)     = nanmean(IBIs_perTrial(6,behavIDs.incongrIds));
                        IBI7_PEtrials(n,:)     = nanmean(IBIs_perTrial(7,behavIDs.incongrIds));

                        if ~isempty(posPEs)
                            HR_posPEtrials_mean(n,:)  = mean(HR_all(posPEs));
                            HR_posPEtrials_min(n,:)   = min(HR_all(posPEs));
                            HR_posPEtrials_max(n,:)   = max(HR_all(posPEs));
                            amp_posPEtrials_mean(n,:) = mean(maxPPUs(posPEs));
                            amp_posPEtrials_min(n,:)  = min(maxPPUs(posPEs));
                            amp_posPEtrials_max(n,:)  = max(maxPPUs(posPEs));
                            IBI1_posPEtrials(n,:)      = nanmean(IBIs_perTrial(1,posPEs));
                            IBI2_posPEtrials(n,:)      = nanmean(IBIs_perTrial(2,posPEs));
                            IBI3_posPEtrials(n,:)      = nanmean(IBIs_perTrial(3,posPEs));
                            IBI4_posPEtrials(n,:)      = nanmean(IBIs_perTrial(4,posPEs));
                            IBI5_posPEtrials(n,:)      = nanmean(IBIs_perTrial(5,posPEs));
                            IBI6_posPEtrials(n,:)      = nanmean(IBIs_perTrial(6,posPEs));
                            IBI7_posPEtrials(n,:)      = nanmean(IBIs_perTrial(7,posPEs));
                        else
                            HR_posPEtrials_mean(n,:)  = NaN;
                            HR_posPEtrials_min(n,:)   = NaN;
                            HR_posPEtrials_max(n,:)   = NaN;
                            amp_posPEtrials_mean(n,:) = NaN;
                            amp_posPEtrials_min(n,:)  = NaN;
                            amp_posPEtrials_max(n,:)  = NaN;
                            IBI1_posPEtrials(n,:)      = NaN;
                            IBI2_posPEtrials(n,:)      = NaN;
                            IBI3_posPEtrials(n,:)      = NaN;
                            IBI4_posPEtrials(n,:)      = NaN;
                            IBI5_posPEtrials(n,:)      = NaN;
                            IBI6_posPEtrials(n,:)      = NaN;
                            IBI7_posPEtrials(n,:)      = NaN;
                        end

                        if ~isempty(negPEs)
                            HR_negPEtrials_mean(n,:)  = mean(HR_all(negPEs));
                            HR_negPEtrials_min(n,:)   = min(HR_all(negPEs));
                            HR_negPEtrials_max(n,:)   = max(HR_all(negPEs));
                            amp_negPEtrials_mean(n,:) = mean(maxPPUs(negPEs));
                            amp_negPEtrials_min(n,:)  = min(maxPPUs(negPEs));
                            amp_negPEtrials_max(n,:)  = max(maxPPUs(negPEs));
                            IBI1_negPEtrials(n,:)      = nanmean(IBIs_perTrial(1,negPEs));
                            IBI2_negPEtrials(n,:)      = nanmean(IBIs_perTrial(2,negPEs));
                            IBI3_negPEtrials(n,:)      = nanmean(IBIs_perTrial(3,negPEs));
                            IBI4_negPEtrials(n,:)      = nanmean(IBIs_perTrial(4,negPEs));
                            IBI5_negPEtrials(n,:)      = nanmean(IBIs_perTrial(5,negPEs));
                            IBI6_negPEtrials(n,:)      = nanmean(IBIs_perTrial(6,negPEs));
                            IBI7_negPEtrials(n,:)      = nanmean(IBIs_perTrial(7,negPEs));
                        else
                            HR_negPEtrials_mean(n,:)  = NaN;
                            HR_negPEtrials_min(n,:)   = NaN;
                            HR_negPEtrials_max(n,:)   = NaN;
                            amp_negPEtrials_mean(n,:) = NaN;
                            amp_negPEtrials_min(n,:)  = NaN;
                            amp_negPEtrials_max(n,:)  = NaN;
                            IBI1_negPEtrials(n,:)      = NaN;
                            IBI2_negPEtrials(n,:)      = NaN;
                            IBI3_negPEtrials(n,:)      = NaN;
                            IBI4_negPEtrials(n,:)      = NaN;
                            IBI5_negPEtrials(n,:)      = NaN;
                            IBI6_negPEtrials(n,:)      = NaN;
                            IBI7_negPEtrials(n,:)      = NaN;
                        end
                    end
                    if strcmp(currTask,'SAP')
                        HR_StimSmiletrials_mean(n,:) = mean(HR_all(behavIDs.stim_positiveIds));
                        HR_StimSmiletrials_min(n,:)  = min(HR_all(behavIDs.stim_positiveIds));
                        HR_StimSmiletrials_max(n,:)  = max(HR_all(behavIDs.stim_positiveIds));
                        amp_StimSmiletrials_mean(n,:) = mean(maxPPUs(behavIDs.stim_positiveIds));
                        amp_StimSmiletrials_min(n,:)  = min(maxPPUs(behavIDs.stim_positiveIds));
                        amp_StimSmiletrials_max(n,:)  = max(maxPPUs(behavIDs.stim_positiveIds));
                        IBI1_StimSmiletrials(n,:)     = nanmean(IBIs_perTrial(1,behavIDs.stim_positiveIds));
                        IBI2_StimSmiletrials(n,:)     = nanmean(IBIs_perTrial(2,behavIDs.stim_positiveIds));
                        IBI3_StimSmiletrials(n,:)     = nanmean(IBIs_perTrial(3,behavIDs.stim_positiveIds));
                        IBI4_StimSmiletrials(n,:)     = nanmean(IBIs_perTrial(4,behavIDs.stim_positiveIds));
                        IBI5_StimSmiletrials(n,:)     = nanmean(IBIs_perTrial(5,behavIDs.stim_positiveIds));
                        IBI6_StimSmiletrials(n,:)     = nanmean(IBIs_perTrial(6,behavIDs.stim_positiveIds));
                        IBI7_StimSmiletrials(n,:)     = nanmean(IBIs_perTrial(7,behavIDs.stim_positiveIds));

                        HR_partSmiletrials_mean(n,:) = mean(HR_all(behavIDs.part_positiveIds));
                        HR_partSmiletrials_min(n,:)  = min(HR_all(behavIDs.part_positiveIds));
                        HR_partSmiletrials_max(n,:)  = max(HR_all(behavIDs.part_positiveIds));
                        amp_partSmiletrials_mean(n,:) = mean(maxPPUs(behavIDs.part_positiveIds));
                        amp_partSmiletrials_min(n,:)  = min(maxPPUs(behavIDs.part_positiveIds));
                        amp_partSmiletrials_max(n,:)  = max(maxPPUs(behavIDs.part_positiveIds));
                        IBI1_partSmiletrials(n,:)     = nanmean(IBIs_perTrial(1,behavIDs.part_positiveIds));
                        IBI2_partSmiletrials(n,:)     = nanmean(IBIs_perTrial(2,behavIDs.part_positiveIds));
                        IBI3_partSmiletrials(n,:)     = nanmean(IBIs_perTrial(3,behavIDs.part_positiveIds));
                        IBI4_partSmiletrials(n,:)     = nanmean(IBIs_perTrial(4,behavIDs.part_positiveIds));
                        IBI5_partSmiletrials(n,:)     = nanmean(IBIs_perTrial(5,behavIDs.part_positiveIds));
                        IBI6_partSmiletrials(n,:)     = nanmean(IBIs_perTrial(6,behavIDs.part_positiveIds));
                        IBI7_partSmiletrials(n,:)     = nanmean(IBIs_perTrial(7,behavIDs.part_positiveIds));

                    elseif strcmp(currTask,'SAPC')
                        HR_StimGoodtrials_mean(n,:) = mean(HR_all(behavIDs.stim_positiveIds));
                        HR_StimGoodtrials_min(n,:)  = min(HR_all(behavIDs.stim_positiveIds));
                        HR_StimGoodtrials_max(n,:)  = max(HR_all(behavIDs.stim_positiveIds));
                        amp_StimGoodtrials_mean(n,:) = mean(maxPPUs(behavIDs.stim_positiveIds));
                        amp_StimGoodtrials_min(n,:)  = min(maxPPUs(behavIDs.stim_positiveIds));
                        amp_StimGoodtrials_max(n,:)  = max(maxPPUs(behavIDs.stim_positiveIds));
                        IBI1_StimGoodtrials(n,:)    = nanmean(IBIs_perTrial(1,behavIDs.stim_positiveIds));
                        IBI2_StimGoodtrials(n,:)    = nanmean(IBIs_perTrial(2,behavIDs.stim_positiveIds));
                        IBI3_StimGoodtrials(n,:)    = nanmean(IBIs_perTrial(3,behavIDs.stim_positiveIds));
                        IBI4_StimGoodtrials(n,:)    = nanmean(IBIs_perTrial(4,behavIDs.stim_positiveIds));
                        IBI5_StimGoodtrials(n,:)    = nanmean(IBIs_perTrial(5,behavIDs.stim_positiveIds));
                        IBI6_StimGoodtrials(n,:)    = nanmean(IBIs_perTrial(6,behavIDs.stim_positiveIds));
                        IBI7_StimGoodtrials(n,:)    = nanmean(IBIs_perTrial(7,behavIDs.stim_positiveIds));

                        HR_partCollecttrials_mean(n,:) = mean(HR_all(behavIDs.part_positiveIds));
                        HR_partCollecttrials_min(n,:)  = min(HR_all(behavIDs.part_positiveIds));
                        HR_partCollecttrials_max(n,:)   = max(HR_all(behavIDs.part_positiveIds));
                        amp_partCollecttrials_mean(n,:) = mean(maxPPUs(behavIDs.part_positiveIds));
                        amp_partCollecttrials_min(n,:)  = min(maxPPUs(behavIDs.part_positiveIds));
                        amp_partCollecttrials_max(n,:)  = max(maxPPUs(behavIDs.part_positiveIds));
                        IBI1_partCollecttrials(n,:)    = nanmean(IBIs_perTrial(1,behavIDs.part_positiveIds));
                        IBI2_partCollecttrials(n,:)    = nanmean(IBIs_perTrial(2,behavIDs.part_positiveIds));
                        IBI3_partCollecttrials(n,:)    = nanmean(IBIs_perTrial(3,behavIDs.part_positiveIds));
                        IBI4_partCollecttrials(n,:)    = nanmean(IBIs_perTrial(4,behavIDs.part_positiveIds));
                        IBI5_partCollecttrials(n,:)    = nanmean(IBIs_perTrial(5,behavIDs.part_positiveIds));
                        IBI6_partCollecttrials(n,:)    = nanmean(IBIs_perTrial(6,behavIDs.part_positiveIds));
                        IBI7_partCollecttrials(n,:)    = nanmean(IBIs_perTrial(7,behavIDs.part_positiveIds));

                    elseif strcmp(currTask,'AAA')
                        HR_partApproachtrials_mean(n,:) = mean(HR_all(behavIDs.part_positiveIds));
                        HR_partApproachtrials_min(n,:)  = min(HR_all(behavIDs.part_positiveIds));
                        HR_partApproachtrials_max(n,:)  = max(HR_all(behavIDs.part_positiveIds));
                        amp_partApproachtrials_mean(n,:) = mean(maxPPUs(behavIDs.part_positiveIds));
                        amp_partApproachtrials_min(n,:)  = min(maxPPUs(behavIDs.part_positiveIds));
                        amp_partApproachtrials_max(n,:)  = max(maxPPUs(behavIDs.part_positiveIds));
                        IBI1_partApproachtrials(n,:)      = nanmean(IBIs_perTrial(1,behavIDs.part_positiveIds));
                        IBI2_partApproachtrials(n,:)      = nanmean(IBIs_perTrial(2,behavIDs.part_positiveIds));
                        IBI3_partApproachtrials(n,:)      = nanmean(IBIs_perTrial(3,behavIDs.part_positiveIds));
                        IBI4_partApproachtrials(n,:)      = nanmean(IBIs_perTrial(4,behavIDs.part_positiveIds));
                        IBI5_partApproachtrials(n,:)      = nanmean(IBIs_perTrial(5,behavIDs.part_positiveIds));
                        IBI6_partApproachtrials(n,:)      = nanmean(IBIs_perTrial(6,behavIDs.part_positiveIds));
                        IBI7_partApproachtrials(n,:)      = nanmean(IBIs_perTrial(7,behavIDs.part_positiveIds));
                    end
                else

                    if strcmp(currTask,'SAP')
                        HR_StimSmiletrials_mean(n,:) = NaN;
                        HR_StimSmiletrials_min(n,:)  = NaN;
                        HR_StimSmiletrials_max(n,:)  = NaN;
                        amp_StimSmiletrials_mean(n,:) = NaN;
                        amp_StimSmiletrials_min(n,:)  = NaN;
                        amp_StimSmiletrials_max(n,:)  = NaN;
                        IBI1_StimSmiletrials(n,:)     = NaN;
                        IBI2_StimSmiletrials(n,:)     = NaN;
                        IBI3_StimSmiletrials(n,:)     = NaN;
                        IBI4_StimSmiletrials(n,:)     = NaN;
                        IBI5_StimSmiletrials(n,:)     = NaN;
                        IBI6_StimSmiletrials(n,:)     = NaN;
                        IBI7_StimSmiletrials(n,:)     = NaN;

                        HR_partSmiletrials_mean(n,:) = NaN;
                        HR_partSmiletrials_min(n,:)  = NaN;
                        HR_partSmiletrials_max(n,:)  = NaN;
                        amp_partSmiletrials_mean(n,:) = NaN;
                        amp_partSmiletrials_min(n,:)  = NaN;
                        amp_partSmiletrials_max(n,:)  = NaN;
                        IBI1_partSmiletrials(n,:)     = NaN;
                        IBI2_partSmiletrials(n,:)     = NaN;
                        IBI3_partSmiletrials(n,:)     = NaN;
                        IBI4_partSmiletrials(n,:)     = NaN;
                        IBI5_partSmiletrials(n,:)     = NaN;
                        IBI6_partSmiletrials(n,:)     = NaN;
                        IBI7_partSmiletrials(n,:)     = NaN;

                    elseif strcmp(currTask,'SAPC')
                        HR_StimGoodtrials_mean(n,:) = NaN;
                        HR_StimGoodtrials_min(n,:)  = NaN;
                        HR_StimGoodtrials_max(n,:)  = NaN;
                        amp_StimGoodtrials_mean(n,:) = NaN;
                        amp_StimGoodtrials_min(n,:)  = NaN;
                        amp_StimGoodtrials_max(n,:)  = NaN;
                        IBI1_StimGoodtrials(n,:)     = NaN;
                        IBI2_StimGoodtrials(n,:)     = NaN;
                        IBI3_StimGoodtrials(n,:)     = NaN;
                        IBI4_StimGoodtrials(n,:)     = NaN;
                        IBI5_StimGoodtrials(n,:)     = NaN;
                        IBI6_StimGoodtrials(n,:)     = NaN;
                        IBI7_StimGoodtrials(n,:)     = NaN;

                        HR_partCollecttrials_mean(n,:) = NaN;
                        HR_partCollecttrials_min(n,:)  = NaN;
                        HR_partCollecttrials_max(n,:)   = NaN;
                        amp_partCollecttrials_mean(n,:) = NaN;
                        amp_partCollecttrials_min(n,:)  = NaN;
                        amp_partCollecttrials_max(n,:)  = NaN;
                        IBI_partCollecttrials(n,:)      = NaN;
                        IBI1_partCollecttrials(n,:)      = NaN;
                        IBI2_partCollecttrials(n,:)      = NaN;
                        IBI3_partCollecttrials(n,:)      = NaN;
                        IBI4_partCollecttrials(n,:)      = NaN;
                        IBI5_partCollecttrials(n,:)      = NaN;
                        IBI6_partCollecttrials(n,:)      = NaN;
                        IBI7_partCollecttrials(n,:)      = NaN;

                    elseif strcmp(currTask,'AAA')
                        HR_partApproachtrials_mean(n,:) = NaN;
                        HR_partApproachtrials_min(n,:)  = NaN;
                        HR_partApproachtrials_max(n,:)  = NaN;
                        amp_partApproachtrials_mean(n,:) = NaN;
                        amp_partApproachtrials_min(n,:)  = NaN;
                        amp_partApproachtrials_max(n,:)  = NaN;
                        IBI1_partApproachtrials(n,:)     = NaN;
                        IBI2_partApproachtrials(n,:)     = NaN;
                        IBI3_partApproachtrials(n,:)     = NaN;
                        IBI4_partApproachtrials(n,:)     = NaN;
                        IBI5_partApproachtrials(n,:)     = NaN;
                        IBI6_partApproachtrials(n,:)     = NaN;
                        IBI7_partApproachtrials(n,:)     = NaN;
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
                    IBI1_PEtrials(n,:)     = NaN;
                    IBI2_PEtrials(n,:)     = NaN;
                    IBI3_PEtrials(n,:)     = NaN;
                    IBI4_PEtrials(n,:)     = NaN;
                    IBI5_PEtrials(n,:)     = NaN;
                    IBI6_PEtrials(n,:)     = NaN;
                    IBI7_PEtrials(n,:)     = NaN;

                    HR_posPEtrials_mean(n,:)  = NaN;
                    HR_posPEtrials_min(n,:)   = NaN;
                    HR_posPEtrials_max(n,:)   = NaN;
                    amp_posPEtrials_mean(n,:) = NaN;
                    amp_posPEtrials_min(n,:)  = NaN;
                    amp_posPEtrials_max(n,:)  = NaN;
                    IBI1_posPEtrials(n,:)  = NaN;
                    IBI2_posPEtrials(n,:)  = NaN;
                    IBI3_posPEtrials(n,:)  = NaN;
                    IBI4_posPEtrials(n,:)  = NaN;
                    IBI5_posPEtrials(n,:)  = NaN;
                    IBI6_posPEtrials(n,:)  = NaN;
                    IBI7_posPEtrials(n,:)  = NaN;

                    HR_negPEtrials_mean(n,:)  = NaN;
                    HR_negPEtrials_min(n,:)   = NaN;
                    HR_negPEtrials_max(n,:)   = NaN;
                    amp_negPEtrials_mean(n,:) = NaN;
                    amp_negPEtrials_min(n,:)  = NaN;
                    amp_negPEtrials_max(n,:)  = NaN;
                    IBI1_negPEtrials(n,:)  = NaN;
                    IBI2_negPEtrials(n,:)  = NaN;
                    IBI3_negPEtrials(n,:)  = NaN;
                    IBI4_negPEtrials(n,:)  = NaN;
                    IBI5_negPEtrials(n,:)  = NaN;
                    IBI6_negPEtrials(n,:)  = NaN;
                    IBI7_negPEtrials(n,:)  = NaN;
                    IBI8_negPEtrials(n,:)  = NaN;

                    BL_amp(n,:)= NaN;
                    BL_HR(n,:) = NaN;
                    if strcmp(currTask,'AAA')
                        HR_negOutcomes_mean(n,:) = NaN;
                        HR_negOutcomes_min(n,:)  = NaN;
                        HR_negOutcomes_max(n,:)  = NaN;
                        amp_negOutcomes_mean(n,:) = NaN;
                        amp_negOutcomes_min(n,:)  = NaN;
                        amp_negOutcomes_max(n,:)  = NaN;
                        IBI1_negOutcomes(n,:)  = NaN;
                        IBI2_negOutcomes(n,:)  = NaN;
                        IBI3_negOutcomes(n,:)  = NaN;
                        IBI4_negOutcomes(n,:)  = NaN;
                        IBI5_negOutcomes(n,:)  = NaN;
                        IBI6_negOutcomes(n,:)  = NaN;
                        IBI7_negOutcomes(n,:)  = NaN;

                        HR_posOutcomes_mean(n,:) = NaN;
                        HR_posOutcomes_min(n,:)  = NaN;
                        HR_posOutcomes_max(n,:)  = NaN;
                        amp_posOutcomes_mean(n,:) = NaN;
                        amp_posOutcomes_min(n,:)  = NaN;
                        amp_posOutcomes_max(n,:)  = NaN;
                        IBI1_posOutcomes(n,:)  = NaN;
                        IBI2_posOutcomes(n,:)  = NaN;
                        IBI3_posOutcomes(n,:)  = NaN;
                        IBI4_posOutcomes(n,:)  = NaN;
                        IBI5_posOutcomes(n,:)  = NaN;
                        IBI6_posOutcomes(n,:)  = NaN;
                        IBI7_posOutcomes(n,:)  = NaN;
                    end
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
                IBI1_PEtrials(n,:)     = NaN;
                IBI2_PEtrials(n,:)     = NaN;
                IBI3_PEtrials(n,:)     = NaN;
                IBI4_PEtrials(n,:)     = NaN;
                IBI5_PEtrials(n,:)     = NaN;
                IBI6_PEtrials(n,:)     = NaN;
                IBI7_PEtrials(n,:)     = NaN;

                HR_posPEtrials_mean(n,:)  = NaN;
                HR_posPEtrials_min(n,:)   = NaN;
                HR_posPEtrials_max(n,:)   = NaN;
                amp_posPEtrials_mean(n,:) = NaN;
                amp_posPEtrials_min(n,:)  = NaN;
                amp_posPEtrials_max(n,:)  = NaN;
                IBI1_posPEtrials(n,:)  = NaN;
                IBI2_posPEtrials(n,:)  = NaN;
                IBI3_posPEtrials(n,:)  = NaN;
                IBI4_posPEtrials(n,:)  = NaN;
                IBI5_posPEtrials(n,:)  = NaN;
                IBI6_posPEtrials(n,:)  = NaN;
                IBI7_posPEtrials(n,:)  = NaN;

                HR_negPEtrials_mean(n,:)  = NaN;
                HR_negPEtrials_min(n,:)   = NaN;
                HR_negPEtrials_max(n,:)   = NaN;
                amp_negPEtrials_mean(n,:) = NaN;
                amp_negPEtrials_min(n,:)  = NaN;
                amp_negPEtrials_max(n,:)  = NaN;
                IBI1_negPEtrials(n,:)  = NaN;
                IBI2_negPEtrials(n,:)  = NaN;
                IBI3_negPEtrials(n,:)  = NaN;
                IBI4_negPEtrials(n,:)  = NaN;
                IBI5_negPEtrials(n,:)  = NaN;
                IBI6_negPEtrials(n,:)  = NaN;
                IBI7_negPEtrials(n,:)  = NaN;
                IBI8_negPEtrials(n,:)  = NaN;

                BL_amp(n,:)= NaN;
                BL_HR(n,:) = NaN;
                if strcmp(currTask,'AAA')
                    HR_negOutcomes_mean(n,:) = NaN;
                    HR_negOutcomes_min(n,:)  = NaN;
                    HR_negOutcomes_max(n,:)  = NaN;
                    amp_negOutcomes_mean(n,:) = NaN;
                    amp_negOutcomes_min(n,:)  = NaN;
                    amp_negOutcomes_max(n,:)  = NaN;
                    IBI1_negOutcomes(n,:)  = NaN;
                    IBI2_negOutcomes(n,:)  = NaN;
                    IBI3_negOutcomes(n,:)  = NaN;
                    IBI4_negOutcomes(n,:)  = NaN;
                    IBI5_negOutcomes(n,:)  = NaN;
                    IBI6_negOutcomes(n,:)  = NaN;
                    IBI7_negOutcomes(n,:)  = NaN;

                    HR_posOutcomes_mean(n,:) = NaN;
                    HR_posOutcomes_min(n,:)  = NaN;
                    HR_posOutcomes_max(n,:)  = NaN;
                    amp_posOutcomes_mean(n,:) = NaN;
                    amp_posOutcomes_min(n,:)  = NaN;
                    amp_posOutcomes_max(n,:)  = NaN;
                    IBI1_posOutcomes(n,:)  = NaN;
                    IBI2_posOutcomes(n,:)  = NaN;
                    IBI3_posOutcomes(n,:)  = NaN;
                    IBI4_posOutcomes(n,:)  = NaN;
                    IBI5_posOutcomes(n,:)  = NaN;
                    IBI6_posOutcomes(n,:)  = NaN;
                    IBI7_posOutcomes(n,:)  = NaN;
                end
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

        SAP_IBITable = table(dataSetOpts.dataSet.PIDs,group,IBI1_StimSmiletrials,IBI2_StimSmiletrials,IBI3_StimSmiletrials,...
            IBI4_StimSmiletrials,IBI5_StimSmiletrials,IBI6_StimSmiletrials,IBI7_StimSmiletrials,IBI1_partSmiletrials,...
            IBI2_partSmiletrials,IBI3_partSmiletrials,IBI4_partSmiletrials,IBI5_partSmiletrials,IBI6_partSmiletrials,IBI7_partSmiletrials, ...
            IBI1_PEtrials,IBI2_PEtrials,IBI3_PEtrials,IBI4_PEtrials,IBI5_PEtrials,IBI6_PEtrials,IBI7_PEtrials,...
            IBI1_posPEtrials,IBI2_posPEtrials,IBI3_posPEtrials,IBI4_posPEtrials,IBI5_posPEtrials,IBI6_posPEtrials,IBI7_posPEtrials,...
            IBI1_negPEtrials,IBI2_negPEtrials,IBI3_negPEtrials,IBI4_negPEtrials,IBI5_negPEtrials,IBI6_negPEtrials,IBI7_negPEtrials,...
            'VariableNames',...
            {'ID','group','pre stimSmile IBI1','pre stimSmile IBI2','stimSmile IBI3','stimSmile  IBI4', ...
            'stimSmile IBI5','stimSmile IBI6','stimSmile IBI7','pre partSmile IBI1','pre partSmile IBI2','partSmile IBI3',...
            'partSmile IBI4','partSmile IBI5','partSmile IBI6','partSmile IBI7','PEs IBI1','PEs IBI2','PEs IBI3','PEs IBI4',...
            'PEs IBI5','PEs IBI6','PEs IBI7','posPEs IBI1','posPEs IBI2','posPEs IBI3','posPEs IBI4',...
            'posPEs IBI5','posPEs IBI6','posPEs IBI7','negPEs IBI1','negPEs IBI2','negPEs IBI3','negPEs IBI4',...
            'negPEs IBI5','negPEs IBI6','negPEs IBI7'});

        save([paths.group.resultsPath,'SAP_IBITable.mat'],'SAP_IBITable');
        writetable(SAP_IBITable,[paths.group.resultsPath ,'SAP_IBITable.csv']);

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

        SAPC_IBITable = table(dataSetOpts.dataSet.PIDs,group,IBI1_StimGoodtrials,IBI2_StimGoodtrials,IBI3_StimGoodtrials,...
            IBI4_StimGoodtrials,IBI5_StimGoodtrials,IBI6_StimGoodtrials,IBI7_StimGoodtrials,IBI1_partCollecttrials,...
            IBI2_partCollecttrials,IBI3_partCollecttrials,IBI4_partCollecttrials,IBI5_partCollecttrials,IBI6_partCollecttrials,IBI7_partCollecttrials, ...
            IBI1_PEtrials,IBI2_PEtrials,IBI3_PEtrials,IBI4_PEtrials,IBI5_PEtrials,IBI6_PEtrials,IBI7_PEtrials,...
            IBI1_posPEtrials,IBI2_posPEtrials,IBI3_posPEtrials,IBI4_posPEtrials,IBI5_posPEtrials,IBI6_posPEtrials,IBI7_posPEtrials,...
            IBI1_negPEtrials,IBI2_negPEtrials,IBI3_negPEtrials,IBI4_negPEtrials,IBI5_negPEtrials,IBI6_negPEtrials,IBI7_negPEtrials,...
            'VariableNames',...
            {'ID','group','pre stimGood IBI1','pre stimGood IBI2','stimGood IBI3','stimGood  IBI4', ...
            'stimGood IBI5','stimGood IBI6','stimGood IBI7','pre partGood IBI1','pre partCollect IBI2','partCollect IBI3',...
            'partCollect IBI4','partCollect IBI5','partCollect IBI6','partCollect IBI7','PEs IBI1','PEs IBI2','PEs IBI3','PEs IBI4',...
            'PEs IBI5','PEs IBI6','PEs IBI7','posPEs IBI1','posPEs IBI2','posPEs IBI3','posPEs IBI4',...
            'posPEs IBI5','posPEs IBI6','posPEs IBI7','negPEs IBI1','negPEs IBI2','negPEs IBI3','negPEs IBI4',...
            'negPEs IBI5','negPEs IBI6','negPEs IBI7'});

        save([paths.group.resultsPath,'SAPC_IBITable.mat'],'SAPC_IBITable');
        writetable(SAPC_IBITable,[paths.group.resultsPath ,'SAPC_IBITable.csv']);

    elseif strcmp(currTask,'AAA')
        AAA_HRTable = table(dataSetOpts.dataSet.PIDs,group,BL_HR,HR_allTrials_mean,HR_allTrials_min,HR_allTrials_max,...
            HR_posOutcomes_mean, HR_posOutcomes_min, HR_posOutcomes_max, ...
            HR_negOutcomes_mean, HR_negOutcomes_min, HR_negOutcomes_max,HR_partApproachtrials_mean,HR_partApproachtrials_min,...
            HR_partApproachtrials_max,'VariableNames',{'ID','group','HR_baseline','meanHR_all','minHR_all','maxHR_all', ...
            'meanHR_posOutcomes','minHR_posOutcomes','maxHR_posOutcomes','meanHR_negOutcomes','minHR_negOutcomes','maxHR_negOutcomes', ...
            'meanHR_approach','minHR_approach','maxHR_approach'});

        save([paths.group.resultsPath,'AAA_HRTable.mat'],'AAA_HRTable');
        writetable(AAA_HRTable,[paths.group.resultsPath ,'AAA_HRTable.csv']);

        AAA_AmplitudeTable = table(dataSetOpts.dataSet.PIDs,group,BL_amp,amp_allTrials_mean,amp_allTrials_min,amp_allTrials_max,...
            amp_posOutcomes_mean, amp_posOutcomes_min, amp_posOutcomes_max, ...
            amp_negOutcomes_mean, amp_negOutcomes_min, amp_negOutcomes_max,amp_partApproachtrials_mean,amp_partApproachtrials_min,...
            amp_partApproachtrials_max,'VariableNames',...
            {'ID','group','amplitude_baseline','meanAmp_all','minAmp_all','maxAmp_all', ...
            'meanAmp_posOutcomes','minAmp_posOutcomes','maxAmp_posOutcomes','meanAmp_negOutcomes','minAmp_negOutcomes','maxAmp_negOutcomes',...
            'meanAmp_approach','minAmp_approach','maxAmp_approach'});

        save([paths.group.resultsPath,'AAA_AmplitudeTable.mat'],'AAA_AmplitudeTable');
        writetable(AAA_AmplitudeTable,[paths.group.resultsPath ,'AAA_AmplitudeTable.csv']);

        AAA_IBITable = table(dataSetOpts.dataSet.PIDs,group,IBI1_negOutcomes,IBI2_negOutcomes,IBI3_negOutcomes,IBI4_negOutcomes,...
            IBI5_negOutcomes,IBI6_negOutcomes,IBI7_negOutcomes,IBI1_posOutcomes, IBI2_posOutcomes, IBI3_posOutcomes,IBI4_posOutcomes,...
            IBI5_posOutcomes,IBI6_posOutcomes,IBI7_posOutcomes,'VariableNames',...
            {'ID','group','pre negOutcome IBI1','pre negOutcome IBI2','negOutcome IBI3','negOutcome IBI4', ...
            'negOutcome IBI5','negOutcome IBI6','negOutcome IBI7','pre posOutcome IBI1','pre posOutcome IBI2','posOutcome IBI3',...
            'posOutcome IBI4','posOutcome IBI5','posOutcome IBI6','posOutcome IBI7'});

        save([paths.group.resultsPath,'AAA_IBITable.mat'],'AAA_IBITable');
        writetable(AAA_IBITable,[paths.group.resultsPath ,'AAA_IBITable.csv']);
    end
end
