function getOnlineQuestData

[paths,options] = getDataSpecs([],'main');
options = getQuestionnaireDetails(options);

%% LOAD REDCap datafile
file = dir([paths.group.DBExport,'*.csv']);
data = readtable([paths.group.DBExport,file(2).name]);

nQuest      = size(options.quest,2);
nQuestDims = numel(fieldnames(options.quest(1,1)));
questDimIds  = [1:nQuestDims]';


groupTable = getGroups(paths,options);

%% EXTRACT data
% get row numbers of experiment event entries
exp_rows = find(~isnat(data.date_exp));
exp_rows = intersect(exp_rows,find(data.pid<1500));

for n = 1:numel(exp_rows)
    currPID = data.pid(exp_rows(n));
    disp(['processing participant no ', num2str(n),' ',num2str(currPID)])
    recordIDrows   = find(data.record_id==data.record_id(exp_rows(n)));
    questRow = intersect(recordIDrows,find(strcmp(data.redcap_event_name,'online_questionnai_arm_1')));
    spq1Row  = intersect(recordIDrows,find(strcmp(data.redcap_repeat_instrument,'spq')));
    demogrRow = (intersect(recordIDrows,find(data.agree_participate==1)));

    if ~isempty(spq1Row)
        % >>>>>>>>>>> SPQ T1
        IdeasOfReference_t1(n,:)             = data{spq1Row(1),options.quest(1,1).ideasOfReference};
        ExcessiveSocialAnxiety_t1(n,:)       = data{spq1Row(1),options.quest(1,1).excessiveSocialAnxiety};
        MagicalThinking_t1(n,:)              = data{spq1Row(1),options.quest(1,1).magicalThinking};
        UnusualPerceptualExperiences_t1(n,:) = data{spq1Row(1),options.quest(1,1).unusualPerceptualExperiences};
        EccentricBehaviour_t1(n,:) = data{spq1Row(1),options.quest(1,1).eccentricBehaviour};
        NoCloseFriends_t1(n,:)     = data{spq1Row(1),options.quest(1,1).noCloseFriends};
        OddSpeech_t1(n,:)          = data{spq1Row(1),options.quest(1,1).oddSpeech};
        ConstrictedAffect_t1(n,:)  = data{spq1Row(1),options.quest(1,1).constrictedAffect};
        Suspiciousness_t1(n,:)     = data{spq1Row(1),options.quest(1,1).suspiciousness};

        IdeasOfReference_t2(n,:)             = data{questRow,options.quest(2,1).ideasOfReference};
        ExcessiveSocialAnxiety_t2(n,:)       = data{questRow,options.quest(2,1).excessiveSocialAnxiety};
        MagicalThinking_t2(n,:)              = data{questRow,options.quest(2,1).magicalThinking};
        UnusualPerceptualExperiences_t2(n,:) = data{questRow,options.quest(2,1).unusualPerceptualExperiences};
        EccentricBehaviour_t2(n,:) = data{questRow,options.quest(2,1).eccentricBehaviour};
        NoCloseFriends_t2(n,:)     = data{questRow,options.quest(2,1).noCloseFriends};
        OddSpeech_t2(n,:)          = data{questRow,options.quest(2,1).oddSpeech};
        ConstrictedAffect_t2(n,:)  = data{questRow,options.quest(2,1).constrictedAffect};
        Suspiciousness_t2(n,:)     = data{questRow,options.quest(2,1).suspiciousness};


        % >>>> CAPE
        positiveSymptoms_freq(n,:)    = data{questRow,options.quest(3,1).positiveSymptoms_freq};
        positiveSymptoms_distr(n,:)   = data{questRow,options.quest(3,1).positiveSymptoms_distr};
        negativeSymptoms_freq(n,:)    = data{questRow,options.quest(3,1).negativeSymptoms_freq};
        negativeSymptoms_distr(n,:)   = data{questRow,options.quest(3,1).negativeSymptoms_distr};
        depressiveSymptoms_freq(n,:)  = data{questRow,options.quest(3,1).depressiveSymptoms_freq};
        depressiveSymptoms_distr(n,:) = data{questRow,options.quest(3,1).depressiveSymptoms_distr};

        %  >>>> BIS BAS

        % reverse-coded items
        bisbas02 = data.bisbas02(questRow);
        bisbas22 = data.bisbas22(questRow);

        if bisbas02 == 1
            data.bisbas02(questRow) = 4;
        elseif bisbas02 == 2
            data.bisbas02(questRow) = 3;
        elseif bisbas02 == 3
            data.bisbas02(questRow) = 2;
        elseif bisbas02 == 4
            data.bisbas02(questRow) = 1;
        end

        if bisbas22 == 1
            data.bisbas22(questRow) = 4;
        elseif bisbas22 == 2
            data.bisbas22(questRow) = 3;
        elseif bisbas22 == 3
            data.bisbas22(questRow) = 2;
        elseif bisbas22 == 4
            data.bisbas22(questRow) = 1;
        end

        activation_drive(n,:)      = data{questRow,options.quest(4,1).activation_drive};
        activation_funSeek(n,:)    = data{questRow,options.quest(4,1).activation_funSeek};
        activation_rewardResp(n,:) = data{questRow,options.quest(4,1).activation_rewardResp};
        activation(n,:)  = data{questRow,options.quest(4,1).activation};
        inhibition(n,:)  = data{questRow,options.quest(4,1).inhibition};

        %  >>>> MAIA % 11,12,15 reverse coded

        % reverse-coded items
        maia11 = data.maia11(questRow);
        maia12 = data.maia12(questRow);
        maia15 = data.maia15(questRow);

        if maia11 == 0
            data.maia11(questRow) = 5;
        elseif maia11 == 1
            data.maia11(questRow) = 4;
        elseif maia11 == 2
            data.maia11(questRow) = 3;
        elseif maia11 == 3
            data.maia11(questRow) = 2;
        elseif maia11 == 4
            data.maia11(questRow) = 1;
        elseif maia11 == 5
            data.maia11(questRow) = 0;
        end

        if maia12 == 0
            data.maia12(questRow) = 5;
        elseif maia12 == 1
            data.maia12(questRow) = 4;
        elseif maia12 == 2
            data.maia12(questRow) = 3;
        elseif maia12 == 3
            data.maia12(questRow) = 2;
        elseif maia12 == 4
            data.maia12(questRow) = 1;
        elseif maia12 == 5
            data.maia12(questRow) = 0;
        end
        if maia15 == 0
            data.maia15(questRow) = 5;
        elseif maia15 == 1
            data.maia15(questRow) = 4;
        elseif maia15 == 2
            data.maia15(questRow) = 3;
        elseif maia15 == 3
            data.maia15(questRow) = 2;
        elseif maia15 == 4
            data.maia15(questRow) = 1;
        elseif maia15 == 5
            data.maia15(questRow) = 0;
        end

        notDistr = data{questRow,options.quest(5,1).notDistracting};
        for i = 1:numel(notDistr)
            if notDistr(i) == 0
                data{questRow,options.quest(5,1).notDistracting(i)} = 5;
            elseif notDistr(i) == 1
                data{questRow,options.quest(5,1).notDistracting(i)} = 4;
            elseif notDistr(i) == 2
                data{questRow,options.quest(5,1).notDistracting(i)} = 3;
            elseif notDistr(i) == 3
                data{questRow,options.quest(5,1).notDistracting(i)} = 2;
            elseif notDistr(i) == 4
                data{questRow,options.quest(5,1).notDistracting(i)} = 1;
            elseif notDistr(i) == 5
                data{questRow,options.quest(5,1).notDistracting(i)} = 0;
            end
        end

        noticing(n,:)       = data{questRow,options.quest(5,1).noticing};
        notDistracting(n,:) = data{questRow,options.quest(5,1).notDistracting};
        notWorrying(n,:)    = data{questRow,options.quest(5,1).notWorrying};
        attentionReg(n,:)   = data{questRow,options.quest(5,1).attentionReg};
        emotAwareness(n,:)  = data{questRow,options.quest(5,1).emotAwareness};
        selfRegulation(n,:) = data{questRow,options.quest(5,1).selfRegulation};
        bodyListening(n,:)  = data{questRow,options.quest(5,1).bodyListening};
        trusting(n,:)       = data{questRow,options.quest(5,1).trusting};

        %  >>>> BPQ SF
        bodyAwareness(n,:) = data{questRow,options.quest(6,1).bodyAwareness};
        ansReactivity(n,:) = data{questRow,options.quest(6,1).ansReactivity};

        gender(n,:)  = data.gender(demogrRow);
        age(n,:)     = data.age(demogrRow);
        edu_yrs(n,:) = data.edu_yrs(demogrRow);
        
        
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

        SPQTable = table(currPID,age(n),gender(n),edu_yrs(n),group(n,:),nanmean(IdeasOfReference_t1(n,:),2),nanmean(IdeasOfReference_t2(n,:),2),nanmean(ExcessiveSocialAnxiety_t1(n,:),2),nanmean(ExcessiveSocialAnxiety_t2(n,:),2),nanmean(MagicalThinking_t1(n,:),2),...
            nanmean(MagicalThinking_t2(n,:),2),nanmean(UnusualPerceptualExperiences_t1(n,:),2),nanmean(UnusualPerceptualExperiences_t2(n,:),2),nanmean(EccentricBehaviour_t1(n,:),2),...
            nanmean(EccentricBehaviour_t2(n,:),2),nanmean(NoCloseFriends_t1(n,:),2),nanmean(NoCloseFriends_t2(n,:),2),nanmean(OddSpeech_t1(n,:),2),nanmean(OddSpeech_t2(n,:),2),...
            nanmean(ConstrictedAffect_t1(n,:),2),nanmean(ConstrictedAffect_t2(n,:),2),nanmean(Suspiciousness_t1(n,:),2),nanmean(Suspiciousness_t2(n,:),2),'VariableNames',...
            {'ID','age','gender','education in years','group','IdeasOfReference T1','IdeasOfReference T2','ExcessiveSocialAnxiety T1','ExcessiveSocialAnxiety T2','MagicalThinking T1','MagicalThinking T2',...
            'UnusualPerceptualExperiences T1','UnusualPerceptualExperiences T2','EccentricBehaviour T1','EccentricBehaviour T2','NoCloseFriends T1','NoCloseFriends T2',...
            'OddSpeech T1','OddSpeech T2','ConstrictedAffect T1','ConstrictedAffect T2','Suspiciousness T1','Suspiciousness T2'});

        if ~isempty(savePath)
            save([savePath,'SPQTable.mat'],'SPQTable');
            writetable(SPQTable,[savePath,'SPQTable.csv']);
        end

        CAPETable = table(currPID,age(n),gender(n),edu_yrs(n),group(n,:),nanmean(positiveSymptoms_freq(n,:),2),nanmean(positiveSymptoms_distr(n,:),2),nanmean(negativeSymptoms_freq(n,:),2),...
            nanmean(negativeSymptoms_distr(n,:),2),nanmean(depressiveSymptoms_freq(n,:),2),nanmean(depressiveSymptoms_distr(n,:),2),'VariableNames',...
            {'ID','age','gender','education in years','group','positiveSymptoms freq','positiveSymptoms distr','negativeSymptoms freq','negativeSymptoms distr',...
            'depressiveSymptoms freq','depressiveSymptoms distr'});
        if ~isempty(savePath)
            save([savePath,'CAPETable.mat'],'CAPETable');
            writetable(CAPETable,[savePath,'CAPETable.csv']);
        end

        InteroceptionTable = table(currPID,age(n),gender(n),edu_yrs(n),group(n,:),nanmean(noticing(n,:),2),nanmean(notDistracting(n,:),2),nanmean(notWorrying(n,:),2),...
            nanmean(attentionReg(n,:),2),nanmean(emotAwareness(n,:),2),nanmean(selfRegulation(n,:),2),nanmean(bodyListening(n,:),2),nanmean(trusting(n,:),2),...
            nanmean(bodyAwareness(n,:),2),nanmean(ansReactivity(n,:),2),'VariableNames',...
            {'ID','age','gender','education in years','group','MAIA noticing','MAIA notDistracting','MAIA notWorrying','MAIA attentionRegulation','MAIA emotAwareness'...
            'MAIA selfRegulatrion','MAIA bodyListening','MAIA trusting','BOQ bodyAwareness','BPQ ansReactivity'});
        if ~isempty(savePath)
            save([savePath,'InteroceptionTable.mat'],'InteroceptionTable');
            writetable(InteroceptionTable,[savePath,'InteroceptionTable.csv']);
        end
    end
end

PIDs = data.pid(exp_rows);

SPQmeansTable = table(PIDs,age,gender,edu_yrs,group,nanmean(IdeasOfReference_t1,2),nanmean(IdeasOfReference_t2,2),nanmean(ExcessiveSocialAnxiety_t1,2),nanmean(ExcessiveSocialAnxiety_t2,2),nanmean(MagicalThinking_t1,2),...
    nanmean(MagicalThinking_t2,2),nanmean(UnusualPerceptualExperiences_t1,2),nanmean(UnusualPerceptualExperiences_t2,2),nanmean(EccentricBehaviour_t1,2),...
    nanmean(EccentricBehaviour_t2,2),nanmean(NoCloseFriends_t1,2),nanmean(NoCloseFriends_t2,2),nanmean(OddSpeech_t1,2),nanmean(OddSpeech_t2,2),...
    nanmean(ConstrictedAffect_t1,2),nanmean(ConstrictedAffect_t2,2),nanmean(Suspiciousness_t1,2),nanmean(Suspiciousness_t2,2),'VariableNames',...
    {'ID','age','gender','education in years','group','IdeasOfReference T1','IdeasOfReference T2','ExcessiveSocialAnxiety T1','ExcessiveSocialAnxiety T2','MagicalThinking T1','MagicalThinking T2',...
    'UnusualPerceptualExperiences T1','UnusualPerceptualExperiences T2','EccentricBehaviour T1','EccentricBehaviour T2','NoCloseFriends T1','NoCloseFriends T2',...
    'OddSpeech T1','OddSpeech T2','ConstrictedAffect T1','ConstrictedAffect T2','Suspiciousness T1','Suspiciousness T2'});
save([paths.group.questData ,'SPQnanmeansTable.mat'],'SPQmeansTable');
writetable(SPQmeansTable,[paths.group.questData,'SPQmeansTable.csv']);

CAPEMeansTable = table(PIDs,age,gender,edu_yrs,group,nanmean(positiveSymptoms_freq,2),nanmean(positiveSymptoms_distr,2),nanmean(negativeSymptoms_freq,2),...
    nanmean(negativeSymptoms_distr,2),nanmean(depressiveSymptoms_freq,2),nanmean(depressiveSymptoms_distr,2),'VariableNames',...
    {'ID','age','gender','education in years','group','positiveSymptoms freq','positiveSymptoms distr','negativeSymptoms freq','negativeSymptoms distr',...
    'depressiveSymptoms freq','depressiveSymptoms distr'});
save([paths.group.questData ,'CAPEMeansTable.mat'],'CAPEMeansTable');
writetable(CAPEMeansTable,[paths.group.questData,'CAPEMeansTable.csv']);

InteroceptionMeansTable = table(PIDs,age,gender,edu_yrs,group,nanmean(noticing,2),nanmean(notDistracting,2),nanmean(notWorrying,2),...
    nanmean(attentionReg,2),nanmean(emotAwareness,2),nanmean(selfRegulation,2),nanmean(bodyListening,2),nanmean(trusting,2),...
    nanmean(bodyAwareness,2),nanmean(ansReactivity,2),'VariableNames',...
    {'ID','age','gender','education in years','group','MAIA noticing','MAIA notDistracting','MAIA notWorrying','MAIA attentionRegulation','MAIA emotAwareness'...
    'MAIA selfRegulatrion','MAIA bodyListening','MAIA trusting','BOQ bodyAwareness','BPQ ansReactivity'});
save([paths.group.questData ,'InteroceptionMeansTable.mat'],'InteroceptionMeansTable');
writetable(InteroceptionMeansTable,[paths.group.questData,'InteroceptionMeansTable.csv']);
end

