function plotTrajs

[paths,options] = getDataSpecs([],'main');
options    = getQuestionnaireDetails(options);
groupTable = getGroups(paths,options);

face1PE = readtable('/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results/main/noKappa/SAP/xprob_face1_value_prediction_error.csv');
face2PE = readtable('/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results/main/noKappa/SAP/xprob_face2_value_prediction_error.csv');
face3PE = readtable('/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results/main/noKappa/SAP/xprob_face3_value_prediction_error.csv');
xvol = readtable('/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results/main/noKappa/SAP/xvol_posterior_mean.csv');
PEs = face1PE.xprob1_value_prediction_error;
PEs(face1PE.xprob1_value_prediction_error==0)= face2PE.xprob2_value_prediction_error(face1PE.xprob1_value_prediction_error==0);
PEs(PEs==0)=face3PE.xprob3_value_prediction_error(PEs==0);
xprob1 = xvol.xprob1_value_prediction_error;

figure;
for n = 1:options.dataSet.nParticipants
    currPID = options.dataSet.PIDs(n);
    % check if current participant is the same as participant in
    % groupTable

    groupID = find(groupTable.PID== currPID);
    group = groupTable.group(groupID,:);
    if strcmp(group,'highScorer')
        colour = [0.7176    0.2745    1.0000];
    else
        colour = [0.0745    0.6235    1.0000];
    end

    IDrows = find(xvol.ID==currPID);
    plot(xprob1(IDrows),'Color',colour);
    hold on;

end
figure;
for n = 1:options.dataSet.nParticipants
    currPID = options.dataSet.PIDs(n);
    % check if current participant is the same as participant in
    % groupTable

    groupID = find(groupTable.PID== currPID);
    group = groupTable.group(groupID,:);
    if strcmp(group,'highScorer')
        colour = [0.7176    0.2745    1.0000];
    else
        colour = [0.0745    0.6235    1.0000];
    end

    IDrows = find(face1PE.ID==currPID);
    plot(PEs(IDrows),'Color',colour);
    hold on;

end

face1Pred = readtable('/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results/main/noKappa/SAP/binary_face1_prediction_mean.csv');
face2Pred = readtable('/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results/main/noKappa/SAP/binary_face2_prediction_mean.csv');
face3Pred = readtable('/Volumes/Samsung_T5/SNG/projects/SAPS/data/modeling/results/main/noKappa/SAP/binary_face3_prediction_mean.csv');
Predictions = face1Pred.xbinary1_prediction_mean;
Predictions(face1Pred.xbinary1_prediction_mean==0)= face2Pred.xbinary2_prediction_mean(face1Pred.xbinary1_prediction_mean==0);
Predictions(Predictions==0)=face3Pred.xbinary3_prediction_mean(Predictions==0);

figure;
for n = 1:options.dataSet.nParticipants
    currPID = options.dataSet.PIDs(n);
    % check if current participant is the same as participant in
    % groupTable

    groupID = find(groupTable.PID== currPID);
    group = groupTable.group(groupID,:);
    if strcmp(group,'highScorer')
        colour = [0.7176    0.2745    1.0000];
    else
        colour = [0.0745    0.6235    1.0000];
    end

    IDrows = find(face1Pred.ID==currPID);
    plot(Predictions(IDrows),'Color',colour);
    hold on;

end
end
