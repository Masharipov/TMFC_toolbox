function prepare_example_data(data)

% ========================================================================
% Ruslan Masharipov, August, 2024
% email: ruslan.s.masharipov@gmail.com
% ========================================================================

% Experiment folder
exp_folder = ['Example_data_SF_[' num2str(data.SF,'%.2f') ']_SNR_[' num2str(data.SNR,'%.2f') ']_STP_[' num2str(data.STP_delay,'%.2f') ']_'  data.model];

% Add STP delay
load(data.sots_path);
onsets{1,1} = onsets{1,1} - data.STP_delay;
onsets{1,2} = onsets{1,2} - data.STP_delay;

sots_path = data.sots_path;
sots_path = sots_path(1:end-4);
sots_path = [sots_path '_[' num2str(data.STP_delay,'%.2f') 's_STP].mat'];
[~,sots] = fileparts(sots_path);
sots_path = fullfile(data.stat_path,exp_folder,[sots '.mat']);
save(sots_path,'activations','onsets','durations','names','rest_matrix','task_matrices');

% Generate .nii functional images
fprintf(['Generate *.nii images... \n']);
generate_funct_images(data.stat_path,data.sim_path,exp_folder,data.SF,data.SNR,data.N,data.N_ROIs,data.dummy)

% Generate .nii ROI binary masks 
fprintf(['Generate ROI masks... \n']);
generate_ROI_masks(data.stat_path,exp_folder,data.N_ROIs)

% Estimate GLM
tic
fprintf(['Estimate basic GLMs... \n']);
parallel_estimate_GLM(data.stat_path,sots_path,exp_folder,data.N,data.TR,data.model)
fprintf(['Estimate basic GLMs :: Done in: ' num2str(toc) 's \n']);