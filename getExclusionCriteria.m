function getExclusionCriteria

[paths,options] = getDataSpecs([],'main');
options = getQuestionnaireDetails(options);

%% LOAD REDCap datafile
file = dir([paths.group.DBExport,'*.csv']);
data = readtable([paths.group.DBExport,file(2).name]);
groupTable = getGroups(paths,options);

%% EXTRACT data
% get row numbers of experiment event entries
exp_rows = find(~isnat(data.date_exp));
exp_rows = intersect(exp_rows,find(data.pid<1500));

for n = 1:numel(exp_rows)
    currPID = data.pid(exp_rows(n));
    disp(['processing participant no ', num2str(n),' ',num2str(currPID)])
    recordIDrows = find(data.record_id==data.record_id(exp_rows(n)));
    inclExclRow  = intersect(recordIDrows,find(strcmp(data.redcap_repeat_instrument,'inclusion_exclusion_criteria_3821')));
    if isempty(inclExclRow)
        inclExclRow  = intersect(recordIDrows,find(strcmp(data.redcap_repeat_instrument,'inclusion_exclusion_criteria')));
    end
    demogrRow    = (intersect(recordIDrows,find(data.agree_participate==1)));

    if ~isempty(inclExclRow)
        neurological_disorder(n,:) = data{inclExclRow(1),'neurological_disorder_v2'};
        brain_injury(n,:)          = data{inclExclRow(1),'brain_injury_v2'};
        brain_surgery(n,:)         = data{inclExclRow(1),'brain_surgery_v2'};
        curr_psychot_disorder(n,:) = data{inclExclRow(1),'curr_psychot_disorder_v2'};
        substance_disorder(n,:) = data{inclExclRow(1),'substance_disorder_v2'};
        curr_med(n,:)           = data{inclExclRow(1),'curr_med_v2'};
        marihuana(n,:)          = data{inclExclRow(1),'marihuana_v2'};
        makeup(n,:)             = data{inclExclRow(1),'makeup_v2'};
        gender(n,:)             = data.gender(demogrRow);
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

        inclExclTable = table(currPID,age(n),gender(n),edu_yrs(n),group(n,:),...
            curr_med(n,:),neurological_disorder(n,:),brain_injury(n,:),brain_surgery(n,:),...
            curr_psychot_disorder(n,:),substance_disorder(n,:),marihuana(n,:),makeup(n,:),...
            {'ID','age','gender','education in years','group','curr medicated','neurological disorder','brain injury',...
            'brain surgery','current psychot disorder','substance use disorder','consuming marihuana',...
            'makeup'});

        if ~isempty(savePath)
            save([savePath,'inclExclTable.mat'],'inclExclTable');
            writetable(inclExclTable,[savePath,'inclExclTable.csv']);
        end
    end
end
PIDs = options.dataSet.PIDs;
        inclExclGroupTable = array2table([PIDs,age,gender,edu_yrs,...
            curr_med,neurological_disorder,brain_injury,brain_surgery,...
            curr_psychot_disorder,substance_disorder,marihuana,makeup],'VariableNames',...
            {'ID','age','gender','education in years','curr medication','neurological disorder','brain injury',...
            'brain surgery','current psychot disorder','substance use disorder','consuming marihuana',...
            'makeup'});

            save([paths.group.questData,'inclExclTable.mat'],'inclExclGroupTable');
            writetable(inclExclGroupTable,[paths.group.questData,'inclExclTable.csv']);
end

