function [  ] = SAP_1stlevel_glm(PID, options)

%% -------------------------------------------------------

% Get options if not specified
if nargin < 2
[paths,options] = getDataSpecs(PID);
%     options = SAP_analysis_options();
end


% % Check that the analysis folder is empty, otherwise delete everything
% if ~isempty(dir(fullfile(path.firstlevel.design, '*')))
%     delete(fullfile(options.path.firstlevel.design, '*'));
% end

% Return regressors for the design matrix
reg = SAP_get_regressors(PID, paths, options);

% Set up and compute the GLM
spm('defaults', 'fmri');

matlabbatch = [];

% Load functional file
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = {options.path.firstlevel.root};
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name = options.analysis;
matlabbatch{2}.spm.util.exp_frames.files = {options.file.swrafile};
matlabbatch{2}.spm.util.exp_frames.frames = Inf;

%--- Model specification -------------------------------------------------%
switch options.analysis
    case 'insula'
        matlabbatch{3}.spm.stats.fmri_spec.dir(1) = cfg_dep('Make Directory: Make Directory ''insula''', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','dir'));
    case 'midbrain'
        matlabbatch{3}.spm.stats.fmri_spec.dir(1) = cfg_dep('Make Directory: Make Directory ''midbrain''', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','dir'));
    case {'wholebrain', 'posthoc'}
        matlabbatch{3}.spm.stats.fmri_spec.dir(1) = cfg_dep('Make Directory: Make Directory ''wholebrain''', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','dir'));
end
matlabbatch{3}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{3}.spm.stats.fmri_spec.timing.RT     = 1;
matlabbatch{3}.spm.stats.fmri_spec.timing.fmri_t = 15;
matlabbatch{3}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
matlabbatch{3}.spm.stats.fmri_spec.sess.scans(1) = cfg_dep('Expand image frames: Expanded filename list.', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
% Task regressors
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(1).name = 'cue';
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(1).onset = reg.cue_onset(reg.pred_warm~=0);
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(1).duration = 0;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(1).tmod = 0;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(1).pmod(1).name = 'pred_warm';
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(1).pmod(1).param = reg.pred_warm(reg.pred_warm~=0);
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(1).pmod(1).poly = 1;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(1).orth = 1;

matlabbatch{3}.spm.stats.fmri_spec.sess.cond(2).name = 'cue';
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(2).onset = reg.cue_onset(reg.pred_cool~=0);
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(2).duration = 0;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(2).tmod = 0;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(2).pmod(1).name = 'pred_cool';
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(2).pmod(1).param = reg.pred_cool(reg.pred_cool~=0);
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(2).pmod(1).poly = 1;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(2).orth = 1;

matlabbatch{3}.spm.stats.fmri_spec.sess.cond(3).name = 'stim_warm';
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(3).onset = reg.stim_onset(reg.pe_warm~=0);
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(3).duration = 0;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(3).tmod = 0;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(3).pmod(1).name = 'pe_warm';
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(3).pmod(1).param = reg.pe_warm(reg.pe_warm~=0);
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(3).pmod(1).poly = 1;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(3).orth = 1;

matlabbatch{3}.spm.stats.fmri_spec.sess.cond(4).name = 'stim_cool';
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(4).onset = reg.stim_onset(reg.pe_cool~=0);
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(4).duration = 0;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(4).tmod = 0;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(4).pmod(1).name = 'pe_cool';
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(4).pmod(1).param = reg.pe_cool(reg.pe_cool~=0);
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(4).pmod(1).poly = 1;
matlabbatch{3}.spm.stats.fmri_spec.sess.cond(4).orth = 1;

if isfield(reg, 'missed')
    matlabbatch{3}.spm.stats.fmri_spec.sess.cond(5).name = 'no_response';
    matlabbatch{3}.spm.stats.fmri_spec.sess.cond(5).onset = reg.cue_onset(reg.missed==1) + 2.7;
    matlabbatch{3}.spm.stats.fmri_spec.sess.cond(5).duration = 0;
    matlabbatch{3}.spm.stats.fmri_spec.sess.cond(5).tmod = 0;
    matlabbatch{3}.spm.stats.fmri_spec.sess.cond(5).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{3}.spm.stats.fmri_spec.sess.cond(5).orth = 0;
end

% Physiological noise and motion regressors
matlabbatch{3}.spm.stats.fmri_spec.sess.multi = {''};
matlabbatch{3}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
switch details.flag.fmri
    case 'normal'
        matlabbatch{3}.spm.stats.fmri_spec.sess.multi_reg = {details.file.physio_glm};
    case 'artefact'
        matlabbatch{3}.spm.stats.fmri_spec.sess.multi_reg = {details.file.physio_artefact_glm};
end
matlabbatch{3}.spm.stats.fmri_spec.sess.hpf = 128;
matlabbatch{3}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{3}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{3}.spm.stats.fmri_spec.volt = 1;
matlabbatch{3}.spm.stats.fmri_spec.global = 'None';
% matlabbatch{3}.spm.stats.fmri_spec.mthresh = 0.8;
switch options.analysis
    case 'insula'
        matlabbatch{3}.spm.stats.fmri_spec.mthresh = 0.2;
        matlabbatch{3}.spm.stats.fmri_spec.mask = {details.path.insula};
    case 'midbrain'
        matlabbatch{3}.spm.stats.fmri_spec.mthresh = 0.2;
        matlabbatch{3}.spm.stats.fmri_spec.mask = {details.path.midbrain};
    case {'wholebrain', 'posthoc'}
        matlabbatch{3}.spm.stats.fmri_spec.mthresh = 0.8;
        matlabbatch{3}.spm.stats.fmri_spec.mask = {''};
end
matlabbatch{3}.spm.stats.fmri_spec.cvi = 'AR(1)';

%--- Model estimation ----------------------------------------------------%
matlabbatch{4}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{4}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{4}.spm.stats.fmri_est.method.Classical = 1;

spm_jobman('run', matlabbatch);

save(fullfile(details.path.firstlevel.design, [details.name.id '_1stlevel_glm_event_related_' options.analysis '_' datestr(now, 30) '_batch.mat']), 'matlabbatch');

clear matlabbatch

%--- Contrast manager ----------------------------------------------------%
switch options.analysis
    case 'posthoc'
        matlabbatch{1}.spm.stats.con.spmmat = {fullfile(details.path.firstlevel.design, 'SPM.mat')};
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'warm > cool';
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [0 0 0 0 1 0 -1 0 0];
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'warm < cool';
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 0 0 0 -1 0 1 0 0];
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
    otherwise
        matlabbatch{1}.spm.stats.con.spmmat = {fullfile(details.path.firstlevel.design, 'SPM.mat')};
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'pred_warm > 0';
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [0 1 0 0 0 0 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'pred_warm < 0';
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 -1 0 0 0 0 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = 'pred_cool > 0';
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [0 0 0 1 0 0 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{4}.tcon.name = 'pred_cool < 0';
        matlabbatch{1}.spm.stats.con.consess{4}.tcon.weights = [0 0 0 -1 0 0 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{4}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{5}.tcon.name = 'PE_warm > 0';
        matlabbatch{1}.spm.stats.con.consess{5}.tcon.weights = [0 0 0 0 0 1 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{5}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{6}.tcon.name = 'PE_warm < 0';
        matlabbatch{1}.spm.stats.con.consess{6}.tcon.weights = [0 0 0 0 0 -1 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{6}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{7}.tcon.name = 'PE_cool > 0';
        matlabbatch{1}.spm.stats.con.consess{7}.tcon.weights = [0 0 0 0 0 0 0 1 0];
        matlabbatch{1}.spm.stats.con.consess{7}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{8}.tcon.name = 'PE_cool < 0';
        matlabbatch{1}.spm.stats.con.consess{8}.tcon.weights = [0 0 0 0 0 0 0 -1 0];
        matlabbatch{1}.spm.stats.con.consess{8}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{9}.tcon.name = 'ave pred > 0';
        matlabbatch{1}.spm.stats.con.consess{9}.tcon.weights = [0 1 0 1 0 0 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{9}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{10}.tcon.name = 'ave pred < 0';
        matlabbatch{1}.spm.stats.con.consess{10}.tcon.weights = [0 -1 0 -1 0 0 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{10}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{11}.tcon.name = 'ave PE > 0';
        matlabbatch{1}.spm.stats.con.consess{11}.tcon.weights = [0 0 0 0 0 1 0 1 0];
        matlabbatch{1}.spm.stats.con.consess{11}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{12}.tcon.name = 'ave PE < 0';
        matlabbatch{1}.spm.stats.con.consess{12}.tcon.weights = [0 0 0 0 0 -1 0 -1 0];
        matlabbatch{1}.spm.stats.con.consess{12}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{13}.tcon.name = 'pred_warm > pred_cool';
        matlabbatch{1}.spm.stats.con.consess{13}.tcon.weights = [0 1 0 -1 0 0 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{13}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{14}.tcon.name = 'pred_warm < pred_cool';
        matlabbatch{1}.spm.stats.con.consess{14}.tcon.weights = [0 -1 0 1 0 0 0 0 0];
        matlabbatch{1}.spm.stats.con.consess{14}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{15}.tcon.name = 'PE_warm > PE_cool';
        matlabbatch{1}.spm.stats.con.consess{15}.tcon.weights = [0 0 0 0 0 1 0 -1 0];
        matlabbatch{1}.spm.stats.con.consess{15}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{16}.tcon.name = 'PE_warm < PE_cool';
        matlabbatch{1}.spm.stats.con.consess{16}.tcon.weights = [0 0 0 0 0 -1 0 1 0];
        matlabbatch{1}.spm.stats.con.consess{16}.tcon.sessrep = 'none';
end

matlabbatch{1}.spm.stats.con.delete = 0;

spm_jobman('run', matlabbatch);
