function [sub_check] = tmfc_BGFC(tmfc,ROI_set_number,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates background functional connectivity (BGFC).
% 
% Extracts residual time series from volumes of interest (VOIs). Regresses
% out confounds and co-activations using an FIR model. Applies whitening and
% high-pass filtering. Calculates Pearson's correlation between residual
% time-series. Converts Pearson's r to Fisher's z.
%
% FORMAT [sub_check] = tmfc_BGFC(tmfc)
% Run the function starting from the first subject in the list.
%
%   tmfc.subjects.path            - Paths to individual SPM.mat files
%   tmfc.subjects.name            - Subject names within the TMFC project
%   tmfc.project_path             - Path where all results will be saved
%   tmfc.defaults.parallel        - 0 or 1 (sequential/parallel computing)
%   tmfc.session_mode             - 'strict' or 'repeated'
%                                   In repeated mode, run-specific Fisher-z
%                                   matrices are averaged across all runs.
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.type             - Type of the ROI set
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to ROI images masked by
%                                   individual first-level masks
%
% Example of the ROI set (see tmfc_select_ROIs_GUI and tmfc_create_ROI_set):
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).type = 'binary_images';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path_masked(1).subjects = '...\Subject_0001\ROI_1_masked.nii';
%   tmfc.ROI_set(1).ROIs(1).path_masked(2).subjects = '...\Subject_0002\ROI_1_masked.nii';
%
% FORMAT [sub_check] = tmfc_BGFC(tmfc,ROI_set_number,start_sub)
% Run the function starting from a specific subject in the path list for
% the selected ROI set.
%
%   tmfc           - As above
%   ROI_set_number - Number of the ROI set in the tmfc structure
%   start_sub      - Subject number in the list to start computations from
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin == 1
   ROI_set_number = 1;
   start_sub = 1;
elseif nargin == 2
   start_sub = 1;
end

% Check subject names
if ~isfield(tmfc.subjects,'name')
    for iSub = 1:length(tmfc.subjects)
        tmfc.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
    end
end

% Check session mode
if ~isfield(tmfc,'session_mode')
    session_mode = 'strict';
else
    session_mode = tmfc.session_mode;
end

nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(ROI_set_number).ROIs);

sub_check = zeros(1,nSub);
if start_sub > 1
    sub_check(1:start_sub) = 1;
end

% Initialize waitbar
w = waitbar(0,'Please wait...','Name','Calculating residuals and BGFC','Tag','tmfc_waitbar');
start_time = tic;
count_sub = 1;
cleanupObj = onCleanup(@unfreeze_after_ctrl_c);

spm('defaults','fmri');
spm_jobman('initcfg');
spm_get_defaults('cmdline',true);

if tmfc.defaults.parallel==1
    if isempty(gcp('nocreate')), parpool; end
end

if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','ROI_to_ROI'))
    mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','ROI_to_ROI'));
end

for iSub = start_sub:nSub
    SPM = load(tmfc.subjects(iSub).path).SPM;
    nSess = length(SPM.Sess);

    if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs',tmfc.subjects(iSub).name))
        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs',tmfc.subjects(iSub).name),'s');
        pause(0.1);
    end

    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs',tmfc.subjects(iSub).name))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs',tmfc.subjects(iSub).name));
    end

    for jSess = 1:nSess
        for kROI = 1:nROI
            matlabbatch{1}.spm.util.voi.spmmat = {fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name,'SPM.mat')};
            matlabbatch{1}.spm.util.voi.adjust = NaN; % Adjust for everything 
            matlabbatch{1}.spm.util.voi.session = jSess;
            matlabbatch{1}.spm.util.voi.name = tmfc.ROI_set(ROI_set_number).ROIs(kROI).name;
            
            path_masked = tmfc.ROI_set(ROI_set_number).ROIs(kROI).path_masked;

            % Backward compatibility with old ROI sets
            if ischar(path_masked)
                maskPath = path_masked;
            else
                maskPath = path_masked(iSub).subjects;
            end

            matlabbatch{1}.spm.util.voi.roi{1}.mask.image = {maskPath};
            matlabbatch{1}.spm.util.voi.roi{1}.mask.threshold = 0.1;
            matlabbatch{1}.spm.util.voi.expression = 'i1';           
            batch{kROI} = matlabbatch;
            clear matlabbatch
        end
        
        switch tmfc.defaults.parallel
            case 0  % Sequential
                for kROI = 1:nROI
                    spm_jobman('run',batch{kROI});
                    movefile(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(jSess) '.mat']), ...
                             fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs', ... 
                                      tmfc.subjects(iSub).name,['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(jSess) '.mat']));
                    if exist(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(jSess) '_eigen.nii']),'file')
                        delete(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(jSess) '_eigen.nii']));
                    else
                        delete(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_eigen.nii']));
                    end
                    delete(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_mask.nii']));
                end
                
            case 1  % Parallel
                try
                    figure(findobj('Tag','TMFC_GUI'));
                end
                
                parfor kROI = 1:nROI
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_jobman('run',batch{kROI});
                    movefile(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(jSess) '.mat']), ...
                             fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs', ... 
                                      tmfc.subjects(iSub).name,['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(jSess) '.mat']));
                    if exist(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(jSess) '_eigen.nii']),'file')
                        delete(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(jSess) '_eigen.nii']));
                    else
                        delete(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_eigen.nii']));
                    end
                    delete(fullfile(tmfc.project_path,'FIR_regression',tmfc.subjects(iSub).name, ...
                                      ['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_mask.nii']));
                end
        end

        clear batch
    end

    % Calculate run-specific BGFC matrices
    z_matrix_sum = [];

    for jSess = 1:nSess
        for kROI = 1:nROI
            Y(:,kROI) = load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','FIR_VOIs', ... 
                tmfc.subjects(iSub).name,['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(jSess) '.mat'])).Y;
        end

        z_matrix = atanh(tmfc_corr(Y));
        z_matrix(1:size(z_matrix,1)+1:end) = nan;

        save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','ROI_to_ROI', ... 
                [tmfc.subjects(iSub).name '_Run_' num2str(jSess) '.mat']),'z_matrix');

        % Sum run-specific Fisher-z matrices in repeated mode
        if strcmp(session_mode,'repeated')
            if isempty(z_matrix_sum)
                z_matrix_sum = z_matrix;
            else
                z_matrix_sum = z_matrix_sum + z_matrix;
            end
        end

        clear Y z_matrix
    end

    % Equal-weight average across repeated runs
    if strcmp(session_mode,'repeated')
        z_matrix = z_matrix_sum/nSess;

        save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BGFC','ROI_to_ROI', ...
                [tmfc.subjects(iSub).name '_All_Runs.mat']),'z_matrix');

        clear z_matrix
    end

    clear z_matrix_sum
    
    sub_check(iSub) = 1;
    
    % Update waitbar
    elapsed_time = toc(start_time);
    time_per_sub = elapsed_time/count_sub;
    count_sub = count_sub + 1;
    time_remaining = (nSub-iSub)*time_per_sub;
    hms = fix(mod((time_remaining), [0, 3600, 60]) ./ [3600, 60, 1]);
    try
        waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec] remaining']);
    end
end

% Close waitbar
try
    close(w)
end

function unfreeze_after_ctrl_c()
    try
        delete(findall(0,'type','figure','Tag', 'tmfc_waitbar'));
        GUI = guidata(findobj('Tag','TMFC_GUI')); 
        set([GUI.TMFC_GUI_B1, GUI.TMFC_GUI_B2, GUI.TMFC_GUI_B3, GUI.TMFC_GUI_B4,...
           GUI.TMFC_GUI_B5a, GUI.TMFC_GUI_B5b, GUI.TMFC_GUI_B6, GUI.TMFC_GUI_B7,...
           GUI.TMFC_GUI_B8, GUI.TMFC_GUI_B9, GUI.TMFC_GUI_B10, GUI.TMFC_GUI_B11,...
           GUI.TMFC_GUI_B12a,GUI.TMFC_GUI_B12b,GUI.TMFC_GUI_B13a,GUI.TMFC_GUI_B13b,...
           GUI.TMFC_GUI_B14a, GUI.TMFC_GUI_B14b], 'Enable', 'on');
    end 
end
end
