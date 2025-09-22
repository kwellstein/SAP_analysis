function groupTable = getGroups(paths,options)

if nargin==0
    [paths,options] = getDataSpecs([],'main');
    options = getQuestionnaireDetails(options);
end

options = getQuestionnaireDetails(options);

%% LOAD REDCap datafile
file = dir([paths.group.DBExport,'*.csv']);
data = readtable([paths.group.DBExport,file(2).name]);
%% EXTRACT data

% get row numbers of experiment event entries
exp_rows = find(~isnat(data.date_exp));
exp_rows = intersect(exp_rows,find(data.pid<1500));

% get REDCap IDs
recordIDs = data.record_id(exp_rows);

% loop through REDCap IDs
for n = 1:numel(exp_rows)

    spq_rows  = intersect(find(data.record_id==recordIDs(n)),find(strcmp(data.redcap_repeat_instrument,'spq')));
    if numel(spq_rows)>1
        spq1_rows = intersect(spq_rows,find(data.redcap_repeat_instance==1));
    else
        spq1_rows = spq_rows;
    end

    ConstrictedAffect  = data{spq1_rows,options.quest(1).constrictedAffect};
    if nanmean(ConstrictedAffect)>1.8
        group(n,:) = {'highScorer'};
    elseif nanmean(ConstrictedAffect)<0.51
        group(n,:) = {'lowScorer'};
    end

end
groupTable = table(data.pid(exp_rows),group,'VariableNames',{'PID','group'});
end