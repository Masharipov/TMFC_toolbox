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
%   tmfc                   - As above
%   ROI_set_number         - Number of the ROI set in the tmfc structure
%   clear_BSC              - Clear previosly created BSC folders
%                            (0 - do not clear, 1 - clear)
%                            (by default, clear_BSC = 1)
%
% =========================================================================
%
% Copyright (C) 2023 Ruslan Masharipov
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

R = length(tmfc.ROI_set(ROI_set_number).ROIs);

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
    for ROI_number = 1:R
        if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name))
            mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name));
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

for i = 1:R
    ROIs(i).mask = spm_data_read(spm_data_hdr_read(tmfc.ROI_set(ROI_set_number).ROIs(i).path_masked),'xyz',XYZ);
    ROIs(i).mask(ROIs(i).mask == 0) = NaN;
    try
        waitbar(i/R,w,['ROI No ' num2str(i,'%.f')]);
    end
end

try
    delete(w)
end

% Extract and correlate mean beta series from ROIs
w = waitbar(0,'Please wait...','Name','Extract and correlate mean beta series');
N = length(tmfc.subjects);

cond_list = tmfc.LSS.conditions;

for i = 1:N
    tic
    SPM = load(tmfc.subjects(i).path); 

    % Number of trials per condition
    E_C = [];
    for j = 1:length(cond_list)
        E_C(j) = length(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).ons);
        beta_series(j).condition = ['[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']'];
    end
    

    % Conditions of interest
    for j = 1:length(cond_list)

        % Extract mean beta series from ROIs
        for k = 1:E_C(j)
            betas(k,:) = spm_data_read(spm_data_hdr_read(fullfile(tmfc.project_path,'LSS_regression',['Subject_' num2str(i,'%04.f')],'Betas', ...
                ['Beta_' beta_series(j).condition '_[Trial_' num2str(k) '].nii'])),'xyz',XYZ);
            for ROI_number = 1:R
                beta_series(j).ROI_mean(k,ROI_number) = nanmean(ROIs(ROI_number).mask.*betas(k,:));
            end
        end

        % ROI-to-ROI correlation
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 2
            z_matrix = atanh(corr(beta_series(j).ROI_mean));
            z_matrix(1:size(z_matrix,1)+1:end) = nan;     

            % Save BSC matrices
            save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','ROI_to_ROI', ...
                ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' beta_series(j).condition '.mat']),'z_matrix');

            clear z_matrix
        end

        % Seed-to-voxel correlation
        if tmfc.defaults.analysis == 1 || tmfc.defaults.analysis == 3
            for ROI_number = 1:R
                BSC_image(ROI_number).z_value = atanh(corr(beta_series(j).ROI_mean(:,ROI_number),betas));
            end

            % Save BSC images
            for ROI_number = 1:R
                hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS', ...
                    'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name, ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' beta_series(j).condition '.nii']);
                hdr.descrip = ['z-value map: ' beta_series(j).condition];    
                image = NaN(SPM.SPM.xVol.DIM');
                image(iXYZ) = BSC_image(ROI_number).z_value;
                spm_write_vol(hdr,image);
            end

            clear BSC_image
        end

        clear betas  
    end

    % Save mean beta-series
    save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','Beta_series', ...
        ['Subject_' num2str(i,'%04.f') '_beta_series.mat']),'beta_series');

    % Update waitbar
    hms = fix(mod(((N-i)*toc/i), [0, 3600, 60]) ./ [3600, 60, 1]);
    try
        waitbar(i/N, w, [num2str(i/N*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
    end

    sub_check(i) = 1;

    clear beta_series E_C SPM
end

% Default contrasts info
SPM = load(tmfc.subjects(1).path);
for j = 1:length(cond_list)
    contrasts(j).title = ['[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']'];
    contrasts(j).weights = zeros(1,length(cond_list));
    contrasts(j).weights(1,j) = 1;
end

% Close waitbar
try
    delete(w)
end


           