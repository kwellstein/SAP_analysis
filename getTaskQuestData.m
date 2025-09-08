function getTaskQuestData

[paths,options] = getDataSpecs([],'main');

%% LOAD REDCap datafile
file = dir([paths.group.DBExport,'*.csv']);
data = readtable([paths.group.DBExport,file(2).name]);
% get rid of pilot data and excluded data
PID_rows  = find(~isnan(data.pid));
for n = 1:numel(PID_rows)
    if data.pid(PID_rows(n))>1099
        deleteIdx(n) = n;
    end
end
deleteIdx = deleteIdx';
deleteIdx(deleteIdx==0)=[];
PID_rows(deleteIdx)=[];

for n = 1:numel(PID_rows)
    expdataRow = PID_rows(n);
    questRow = PID_rows(n)-1;
    currPID = data.pid(expdataRow);
    recordID = data.record_id(expdataRow);
    recordIDrows   = find(data.record_id==data.record_id(expdataRow));
    spq1Row  = intersect(recordIDrows,find(strcmp(data.redcap_repeat_instrument,'spq')));
    demogrRow = (intersect(recordIDrows,find(data.agree_participate==1)));



end