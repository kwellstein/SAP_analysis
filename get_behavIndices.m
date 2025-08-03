function behavIDs = get_behavIndices(n,PID,t,currTask,paths)

if strcmp(currTask,'AAA')
    stimRandTable = readtable('/Users/kwellste/projects/SEPAB/tasks/approach_avoid_task/task/+eventCreator/randomisation.xlsx','Sheet','stimuli');
    inputs = readmatrix('/Users/kwellste/projects/SEPAB/tasks/approach_avoid_task/task/+eventCreator/input_sequence.csv');

    nAvatars = 2;
else
    stimRandTable = readtable(['/Users/kwellste/projects/SEPAB/tasks/social_affective_prediction_task/task',filesep,'+eventCreator',filesep,'randomisation.xlsx'],'Sheet','stimuli');
    inputs = readmatrix('/Users/kwellste/projects/SEPAB/tasks/social_affective_prediction_task/task/+eventCreator/input_sequence.csv');

    nAvatars = 3;
end


predictField = [currTask,'Prediction']; 
f = dir(paths.participant(1,n).task(t,1).dataFile);
        if ~isempty(f)
load(paths.participant(1,n).task(t,1).dataFile);
missedIds = find(dataFile.events.exp_missedTrial==1);
incongr = dataFile.(predictField).congruent;
incongr(incongr==1)=0;  incongr(incongr==-1)=1;
behavIDs.part_positiveIds = find(dataFile.(predictField).response(:,1)==1);
behavIDs.part_negativeIds = find(dataFile.(predictField).response(:,1)==0);
behavIDs.stim_positiveIds = find(inputs(:,2)==1);
behavIDs.stim_negativeIds = find(inputs(:,2)==0);

rowIdx        = find(stimRandTable.PID==PID);
avatars       = stimRandTable(rowIdx,:);
avatarArray = string(inputs(:,1));
cellName  = 'experiment_a';

for iAvatar = 1:nAvatars
    avatarArray(strcmp(avatarArray,num2str(iAvatar))) = string(avatars.([cellName,num2str(iAvatar)]));
end

if ~isempty(missedIds)
    incongr(missedIds)=[];
    inputs(missedIds,:)=[];
    avatarArray(missedIds)=[];

    % stimulus positive or negative responses
    missedPositives = intersect(behavIDs.stim_positiveIds,missedIds);
    if ~isempty(missedPositives)
        for j=1:numel(missedPositives)
            behavIDs.stim_positiveIds(behavIDs.stim_positiveIds==missedPositives(j))=[];
        end
    end

    missedNegatives = intersect(behavIDs.stim_negativeIds,missedIds);
    if ~isempty(missedNegatives)
        for i=1:numel(missedNegatives)
            behavIDs.stim_negativeIds(behavIDs.stim_negativeIds==missedNegatives(i))=[];
        end
    end
end

missedPartPositives = intersect(behavIDs.part_positiveIds,missedIds);
if ~isempty(missedPartPositives)
    for j=1:numel(missedPartPositives)
        behavIDs.part_positiveIds(behavIDs.part_positiveIds==missedPartPositives(j))=[];
    end
end

missedPartNegatives = intersect(behavIDs.part_negativeIds,missedIds);
if ~isempty(missedPartPositives)
    for j=1:numel(missedPartNegatives)
        behavIDs.part_negativeIds(behavIDs.part_negativeIds==missedPartNegatives(j))=[];
    end
end

behavIDs.face1 = find(inputs(:,1)==1);
behavIDs.face1stimulus = avatarArray{behavIDs.face1(1)};
behavIDs.face2 = find(inputs(:,1)==2);
behavIDs.face2stimulus = avatarArray{behavIDs.face2(1)};
if ~strcmp(currTask,'AAA')
    behavIDs.face3 = find(inputs(:,1)==3);
    behavIDs.face3stimulus = avatarArray{behavIDs.face3(1)};
end

behavIDs.incongrIds = find(incongr==1);
behavIDs.congrIds   = find(incongr==0);
behavIDs.surprisePositive = intersect(behavIDs.stim_positiveIds,behavIDs.incongrIds);
behavIDs.surpriseNegative = intersect(behavIDs.stim_negativeIds,behavIDs.incongrIds);
        else
     behavIDs=[];   
        end
end