function organize_jlInversionFiles
% reads model inversion files created by Julia toolbox and saves in
% appropriate struct

% get data specifications
[paths,options] = getDataSpecs();

for t = 1:2 %options.dataSet.nTasks
    task = options.dataSet.tasks{t};
    pred_mu_face1(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'binary_face1_prediction_mean.csv']);
    pred_mu_face2(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'binary_face2_prediction_mean.csv']);
    pred_mu_face3(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'binary_face3_prediction_mean.csv']);
    lvl2_PE_face1(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'xprob_face1_value_prediction_error.csv']);
    lvl2_PE_face2(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'xprob_face2_value_prediction_error.csv']);
    lvl2_PE_face3(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'xprob_face3_value_prediction_error.csv']);
    post_mu_face1(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'xprob_face1_posterior_mean.csv']);
    post_mu_face2(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'xprob_face2_posterior_mean.csv']);
    post_mu_face3(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'xprob_face3_posterior_mean.csv']);

    post_mu_vol(t).data = readtable([paths.jlModel.MainResPath,task,filesep,'xvol_posterior_mean.csv']);
end

% initialize struct
for n = 1:options.dataSet.nParticipants
    disp(['writing ',num2str(options.dataSet.PIDs(n)),'...']);
    for t = 1:2 %options.dataSet.nTasks
        task = options.dataSet.tasks{t};
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

            face1 = find(options.task(t).inputs(:,1)==1);
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
            est(n,t).post_mu_vol     = post_mu_vol(t).data.xvol_posterior_mean(idx);
        end
    end
end

save([paths.jlModel.MainResPath,'est.mat'],'est');

%% PLOTTING
for t = 1:2 %options.dataSet.nTasks
    task = options.dataSet.tasks{t};
    for n = 1:options.dataSet.nParticipants
        plot(est(n,t).post_mu_vol)
        title(options.dataSet.PIDs(n))
        figure;
    end

    figure;
    for n = 1:options.dataSet.nParticipants
        plot(est(n,t).post_mu_vol)
        title(options.dataSet.PIDs(n))
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

    figure;
    for n = 1:options.dataSet.nParticipants
        plot(est(n,t).post_mu_face1,'Color','r');
        hold on
        plot(est(n,t).post_mu_face2,'Color','b');
        hold on
        plot(est(n,t).post_mu_face3,'Color','g');
        hold on
    end

    figure;
    for n = 1:options.dataSet.nParticipants
        plot(est(n,t).xprob1_PE )
        hold on
    end
    figure;
    for n = 1:options.dataSet.nParticipants
        plot(est(n,t).xprob1_post_mu )
        hold on
    end
end
end