function getTaskQuestData

[paths,options] = getDataSpecs([],'main');
taskQuest = array2table(zeros(22,16),'VariableNames',...
    {'PID','group','SAP_taskDone','SAP_neuroDone','SAPC_taskDone','SAPC_neuroDone','AAA_taskDone','AAA_neuroDone',...
    'f1_change','f2_change','f3_change','f4_change','m1_change','m2_change','m3_change','m4_change'});

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
    if strcmp(data.redcap_event_name{expdataRow},'experiment_day_arm_1')
        currPID = data.pid(expdataRow);
        recordID = data.record_id(expdataRow);
        recordIDrows   = find(data.record_id==data.record_id(expdataRow));
        demogrRow = (intersect(recordIDrows,find(data.agree_participate==1)));
        taskQuest.PIDs(n,:) = currPID;
        taskQuest.SAP_taskDone(n,:)  = data.sapbehav(expdataRow);
        taskQuest.SAP_neuroDone(n,:)  = data.sapscan(expdataRow);
        taskQuest.SAPC_taskDone(n,:)   = data.sapcbehav(expdataRow);
        taskQuest.SAPC_neuroDone(n,:)  = data.sapcscan(expdataRow);
        taskQuest.AAA_taskDone(n,:)   = data.aaabehav(expdataRow);
        taskQuest.AAA_neuroDone(n,:)   = data.aaascan(expdataRow);

        taskQuest.f1_change(n,:) = data.pretask_f1(expdataRow)-data.posttask_f1(expdataRow);
        taskQuest.f2_change(n,:) = data.pretask_f2(expdataRow)-data.posttask_f2(expdataRow);
        taskQuest.f3_change(n,:) = data.pretask_f3(expdataRow)-data.posttask_f3(expdataRow);
        taskQuest.f4_change(n,:) = data.pretask_f4(expdataRow)-data.posttask_f4(expdataRow);

        taskQuest.m1_change(n,:) = data.pretask_m1(expdataRow)-data.posttask_m1(expdataRow);
        taskQuest.m2_change(n,:) = data.pretask_m2(expdataRow)-data.posttask_m2(expdataRow);
        taskQuest.m3_change(n,:) = data.pretask_m3(expdataRow)-data.posttask_m3(expdataRow);
        taskQuest.m4_change(n,:) = data.pretask_m4(expdataRow)-data.posttask_m4(expdataRow);

    end
end

writetable(taskQuest,[paths.group.questData,'taskQuestTable.csv']);
end