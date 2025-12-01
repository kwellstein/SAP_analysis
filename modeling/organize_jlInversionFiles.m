function organize_jlInversionFiles
% reads model inversion files created by Julia toolbox and saves in
% appropriate struct

% get data specifications
[paths,options] = getDataSpecs([],'main');
groupTable = getGroups(paths,options);

for t = 1:2 %options.dataSet.nTasks
    currTask = options.dataSet.tasks{t};
    pred_mu_face1(t).data = readtable([paths.jlModel.MainResPath,currTask,filesep,'face1_prediction_mean.csv']);
    pred_mu_face2(t).data = readtable([paths.jlModel.MainResPath,currTask,filesep,'face2_prediction_mean.csv']);
    pred_mu_face3(t).data = readtable([paths.jlModel.MainResPath,currTask,filesep,'face3_prediction_mean.csv']);
    lvl2_PE_face1(t).data = readtable([paths.jlModel.MainResPath,currTask,filesep,'face1_value_prediction_error.csv']);
    lvl2_PE_face2(t).data = readtable([paths.jlModel.MainResPath,currTask,filesep,'face2_value_prediction_error.csv']);
    lvl2_PE_face3(t).data = readtable([paths.jlModel.MainResPath,currTask,filesep,'face3_value_prediction_error.csv']);
    post_mu_face1(t).data = readtable([paths.jlModel.MainResPath,currTask,filesep,'face1_posterior_mean.csv']);
    post_mu_face2(t).data = readtable([paths.jlModel.MainResPath,currTask,filesep,'face2_posterior_mean.csv']);
    post_mu_face3(t).data = readtable([paths.jlModel.MainResPath,currTask,filesep,'face3_posterior_mean.csv']);
end

% initialize struct
for t = 1:2 %options.dataSet.nTasks
    currTask = options.dataSet.tasks{t};
    for n = 1:options.dataSet.nParticipants
        disp(['writing ',num2str(options.dataSet.PIDs(n)),'...']);
        idx = find(pred_mu_face1(t).data.ID==options.dataSet.PIDs(n));
        if ~isempty(idx)
            idx(idx==min(idx))=[];
            est(n,t).pred_mu_face1   = pred_mu_face1(t).data.xbinary1_prediction_mean(idx);
            est(n,t).xprob1_PE_face1 = lvl2_PE_face1(t).data.xprob1_value_prediction_error(idx);
            est(n,t).post_mu_face1   = post_mu_face1(t).data.xprob1_posterior_mean(idx);
            est(n,t).pred_mu_face2   = pred_mu_face2(t).data.xbinary2_prediction_mean(idx);
            est(n,t).xprob1_PE_face2 = lvl2_PE_face2(t).data.xprob2_value_prediction_error(idx);
            est(n,t).post_mu_face2   = post_mu_face2(t).data.xprob2_posterior_mean(idx);
            est(n,t).pred_mu_face3   = pred_mu_face3(t).data.xbinary3_prediction_mean(idx);
            est(n,t).xprob1_PE_face3 = lvl2_PE_face3(t).data.xprob3_value_prediction_error(idx);
            est(n,t).post_mu_face3   = post_mu_face3(t).data.xprob3_posterior_mean(idx);

            face1 =      find(options.task(t).inputs(:,1)==1);
            face2 =      find(options.task(t).inputs(:,1)==2);
            face3 =      find(options.task(t).inputs(:,1)==3);
            xprob1_PE(face1)  =  est(n,t).xprob1_PE_face1(face1);
            xprob1_PE(face2) = est(n,t).xprob1_PE_face2(face2);
            xprob1_PE(face3) = est(n,t).xprob1_PE_face3(face3);
            xprob1_post_mu(face1) = est(n,t).post_mu_face1(face1);
            xprob1_post_mu(face2) = est(n,t).post_mu_face2(face2);
            xprob1_post_mu(face3) = est(n,t).post_mu_face2(face3);
            est(n,t).xprob1_PE       = xprob1_PE;
            est(n,t).xprob1_post_mu   = xprob1_post_mu;

            xprob1_post_mu_md(n,:) = mode(xprob1_post_mu);
            xprob1_PE_md(n,:)      = mode(xprob1_PE);
            xprob1_PE_face1_md(n,:) = mode(est(n,t).xprob1_PE_face1(face1));
            xprob1_PE_face2_md(n,:) = mode(est(n,t).xprob1_PE_face2(face2));
            xprob1_PE_face3_md(n,:) = mode(est(n,t).xprob1_PE_face3(face3));
            xprob1_post_face1_md(n,:) = mode(est(n,t).post_mu_face1(face1));
            xprob1_post_face2_md(n,:) = mode(est(n,t).post_mu_face2(face2));
            xprob1_post_face3_md(n,:) = mode(est(n,t).post_mu_face3(face3));
        else
            xprob1_post_mu_md(n,:)     = NaN;
            xprob1_PE_md(n,:)          = NaN;
            xprob1_PE_face1_md(n,:)    = NaN;
            xprob1_PE_face2_md(n,:)    = NaN;
            xprob1_PE_face3_md(n,:)    = NaN;
            xprob1_post_face1_md(n,:)  = NaN;
            xprob1_post_face2_md(n,:)  = NaN;
            xprob1_post_face3_md(n,:)  = NaN;
        end
    end
    PIDs =  options.dataSet.PIDs;
    xprobTable = array2table([PIDs,xprob1_post_mu_md,xprob1_PE_md,xprob1_PE_face1_md,...
        xprob1_PE_face2_md,xprob1_PE_face3_md,xprob1_post_face1_md,xprob1_post_face2_md,...
        xprob1_post_face3_md],'VariableNames',...
        {'ID',[currTask,'xprob1_post_mu'],[currTask,'xprob1_PE'],[currTask,'xprob1_PE_face1'],...
        [currTask,'xprob1_PE_face2'],[currTask,'xprob1_PE_face3'],[currTask,'xprob1_post_face1'],...
        [currTask,'xprob1_post_face2'],[currTask,'xprob1_post_face3']});

    save([paths.jlModel.MainResPath,currTask,filesep,'xprobTable.mat'],'xprobTable');
    writetable(xprobTable,[paths.jlModel.MainResPath,currTask,filesep,'xprobTable.csv']);
end

save([paths.jlModel.MainResPath,'est.mat'],'est');

%% PLOTTING
for n = 1:options.dataSet.nParticipants
    currPID=options.dataSet.PIDs(n);
    if groupTable(n,:).PID== currPID
        group(n,:) = groupTable.group(n,:);
    else
        groupID = find(groupTable.PID== currPID);
        group(n,:) = groupTable.group(groupID,:);
    end
end

for t = 1:2 %options.dataSet.nTasks
    currTask = options.dataSet.tasks{t};
    % for n = 1:options.dataSet.nParticipants
    %     if strcmp(group(n,:),'lowScorer')
    %         plot(est(n,t).xprob1_post_mu,'Color',[0.0745    0.6235    1.0000])
    %     else
    %         plot(est(n,t).xprob1_post_mu,'Color',[0.7176    0.2745    1.0000])
    %     end
    %     title(options.dataSet.PIDs(n))
    %     figure;
    % end


    figure;
    for n = 1:options.dataSet.nParticipants
        if strcmp(group(n,:),'lowScorer')
            plot(est(n,t).xprob1_PE,'Color',[0.0745    0.6235    1.0000])
        else
            plot(est(n,t).xprob1_PE,'Color',[0.7176    0.2745    1.0000])
        end
        title(currTask)
        hold on
    end

    figure;
    for n = 1:options.dataSet.nParticipants
        plot(est(n,t).xprob1_PE_face1,'Color','r');
        hold on
        plot(est(n,t).xprob1_PE_face2,'Color','b');
        hold on
        plot(est(n,t).xprob1_PE_face3,'Color','g');
        hold on
    end
title(currTask);

    figure;
    for n = 1:options.dataSet.nParticipants
        plot(est(n,t).post_mu_face1,'Color','r');
        hold on
        plot(est(n,t).post_mu_face2,'Color','b');
        hold on
        plot(est(n,t).post_mu_face3,'Color','g');
        hold on
    end
title(currTask);

    figure;
    for n = 1:options.dataSet.nParticipants

        plot(est(n,t).post_mu_face1,'Color','r');
        hold on
        plot(est(n,t).post_mu_face2,'Color','b');
        hold on
        plot(est(n,t).post_mu_face3,'Color','g');
        hold on
    end
title(currTask);

    figure;
    for n = 1:options.dataSet.nParticipants
        if strcmp(group(n,:),'lowScorer')
            plot(est(n,t).pred_mu_face1,'Color',[0.5373    0.8039    0.9804])
            hold on
            plot(est(n,t).pred_mu_face2,'Color',[0.2745    0.6980    0.9804])
            hold on
            plot(est(n,t).pred_mu_face3,'Color',[0.0745    0.6235    1.0000])
            hold on
        else
            plot(est(n,t).pred_mu_face1,'Color',[0.8941    0.7216    1.0000])
            hold on
            plot(est(n,t).pred_mu_face2,'Color',[0.7765    0.4196    1.0000])
            hold on
            plot(est(n,t).pred_mu_face3,'Color',[0.7176    0.2745    1.0000])
            hold on
        end
    end
title(currTask);

    figure;
    for n = 1:options.dataSet.nParticipants
        if strcmp(group(n,:),'lowScorer')
            plot(est(n,t).xprob1_post_mu ,'Color',[0.0745    0.6235    1.0000])
        else
            plot(est(n,t).xprob1_post_mu ,'Color',[0.7176    0.2745    1.0000])
        end
        hold on
    end
    title(currTask);
end
end