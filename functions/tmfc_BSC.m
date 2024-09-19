function [sub_check,contrasts] = tmfc_BSC(tmfc,ROI_set_number,clear_BSC)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Extracts mean beta series from selected ROIs. Correlates beta series for
% conditions of interest. Saves individual correlational matrices 
% (ROI-to-ROI analysis) and correlational images (seed-to-voxel analysis)
% for each condition of interest. These refer to default contrasts, which 
% can then be multiplied by linear contrast weights.
%
% FORMAT [sub_check,contrasts] = tmfc_BSC(tmfc)
%
%   tmfc.subjects.path     - Paths to individual SPM.mat files
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.analysis - 1 (Seed-to-voxel and ROI-to-ROI analyses)
%                          - 2 (ROI-to-ROI analysis only)
%                          - 3 (Seed-to-voxel analysis only)
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to the ROI images masked by group
%                                   mean binary mask 
%
%   tmfc.LSS.conditions                  - List of conditions of interest
%   tmfc.LSS.conditions.sess             - Session number
%                                          (as specified in SPM.Sess)
%   tmfc.LSS.conditions.number           - Condition number
%                                          (as specified in SPM.Sess.U)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified:
%
%   tmfc.LSS.conditions(1).sess   = 1;   
%   tmfc.LSS.conditions(1).number = 1; - "Cond A", 1st session
%   tmfc.LSS.conditions(2).sess   = 1;
%   tmfc.LSS.conditions(2).number = 2; - "Cond B", 1st session
%   tmfc.LSS.conditions(3).sess   = 2;
%   tmfc.LSS.conditions(3).number = 1; - "Cond A", 2nd session
%   tmfc.LSS.conditions(4).sess   = 2;
%   tmfc.LSS.conditions(4).number = 2; - "Cond B", 2nd session
%
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path_masked = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path_masked = 'C:\ROI_set\two_ROIs\ROI_2.nii';
%
% FORMAT [sub_check,contrasts] = tmfc_BSC(tmfc,ROI_set_number)
% Run the function for the selected ROI set.
%
%   tmfc                   - As above
%   ROI_set_number         - Number of the ROI set in the tmfc structure
%                            (by default, ROI_set_number = 1)
%
% FORMAT [sub_check,contrasts] = tmfc_BSC(tmfc,ROI_set_number,clear_BSC)
% Run the function for the selected ROI set.
%
%   clear_BSC              - Clear previosly created BSC folders
%                            (0 - do not clear, 1 - clear)
%                            (by default, clear_BSC = 1)
%
% =========================================================================
%
% Copyright (C) 2024 Ruslan Masharipov
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.
%
% Contact email: masharipov@ihb.spb.ru
    
if nargin == 1
   ROI_set_number = 1;
   clear_BSC = 1;
elseif nargin == 2
   clear_BSC = 1;
end

nROI = length(tmfc.ROI_set(ROI_set_number).ROIs);
nSub = length(tmfc.subjects);
cond_list = tmfc.LSS.conditions;
nCond = length(cond_list);

% Clear previosly created BSC folders
if clear_BSC == 1
    if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS'))
        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS'),'s');
    end
end

% Create BSC folders
if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','Beta_series'))
    mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','Beta_series'));
end

if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','ROI_to_ROI'))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','ROI_to_ROI'));
    end
end

if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
    for iROI = 1:nROI
        if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(iROI).name))
            mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(iROI).name));
        end
    end
end

SPM = load(tmfc.subjects(1).path);
XYZ  = SPM.SPM.xVol.XYZ;
iXYZ = cumprod([1,SPM.SPM.xVol.DIM(1:2)'])*XYZ - sum(cumprod(SPM.SPM.xVol.DIM(1:2)'));
hdr.dim = SPM.SPM.Vbeta(1).dim;
hdr.dt = SPM.SPM.Vbeta(1).dt;
hdr.pinfo = SPM.SPM.Vbeta(1).pinfo;
hdr.mat = SPM.SPM.Vbeta(1).mat;

% Loading ROIs
w = waitbar(0,'Please wait...','Name','Loading ROIs');

for iROI = 1:nROI
    ROIs(iROI).mask = spm_data_read(spm_data_hdr_read(tmfc.ROI_set(ROI_set_number).ROIs(iROI).path_masked),'xyz',XYZ);
    ROIs(iROI).mask(ROIs(iROI).mask == 0) = NaN;
    try
        waitbar(iROI/nROI,w,['ROI No ' num2str(iROI,'%.f')]);
    end
end

try
    delete(w)
end

% Extract and correlate mean beta series from ROIs
w = waitbar(0,'Please wait...','Name','Extract and correlate mean beta series');

for iSub = 1:nSub
    tic
    SPM = load(tmfc.subjects(iSub).path); 

    % Number of trials per condition
    nTrialCond = [];
    for jCond = 1:nCond
        nTrialCond(jCond) = length(SPM.SPM.Sess(cond_list(jCond).sess).U(cond_list(jCond).number).ons);
    end
    
    % Conditions of interest
    for jCond = 1:nCond

        % Extract mean beta series from ROIs
        for kTrial = 1:nTrialCond(jCond)
            betas(kTrial,:) = spm_data_read(spm_data_hdr_read(fullfile(tmfc.project_path,'LSS_regression',['Subject_' num2str(iSub,'%04.f')],'Betas', ...
                ['Beta_' cond_list(jCond).file_name '_[Trial_' num2str(kTrial) '].nii'])),'xyz',XYZ);
            for kROI = 1:nROI
                beta_series(jCond).ROI_mean(kTrial,kROI) = nanmean(ROIs(kROI).mask.*betas(kTrial,:));
            end
        end

        % ROI-to-ROI correlation
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
            z_matrix = atanh(corr(beta_series(jCond).ROI_mean));
            z_matrix(1:size(z_matrix,1)+1:end) = nan;     

            % Save BSC matrices
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','ROI_to_ROI', ...
                ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.mat']),'z_matrix');

            clear z_matrix
        end

        % Seed-to-voxel correlation
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
            for kROI = 1:nROI
                BSC_image(kROI).z_value = atanh(corr(beta_series(jCond).ROI_mean(:,kROI),betas));
            end

            % Save BSC images
            for kROI = 1:nROI
                hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS', ...
                    'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(kROI).name, ...
                    ['Subject_' num2str(iSub,'%04.f') '_Contrast_' num2str(jCond,'%04.f') '_' cond_list(jCond).file_name '.nii']);
                hdr.descrip = ['z-value map: ' cond_list(jCond).file_name];    
                image = NaN(SPM.SPM.xVol.DIM');
                image(iXYZ) = BSC_image(kROI).z_value;
                spm_write_vol(hdr,image);
            end

            clear BSC_image
        end

        clear betas  
    end

    % Save mean beta-series
    save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','Beta_series', ...
        ['Subject_' num2str(iSub,'%04.f') '_beta_series.mat']),'beta_series');

    % Update waitbar
    hms = fix(mod(((nSub-iSub)*toc/iSub), [0, 3600, 60]) ./ [3600, 60, 1]);
    try
        waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
    end

    sub_check(iSub) = 1;

    clear beta_series E_C SPM
end

% Default contrasts info
for iCond = 1:nCond
    contrasts(iCond).title = cond_list(iCond).file_name;
    contrasts(iCond).weights = zeros(1,nCond);
    contrasts(iCond).weights(1,iCond) = 1;
end

% Close waitbar
try
    delete(w)
end


           