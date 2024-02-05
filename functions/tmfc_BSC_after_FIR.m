function [sub_check] = tmfc_BSC_after_FIR(tmfc,ROI_set)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Extracts mean beta series from selected ROIs. Correlates beta series for
% conditions of interest. Saves individual correlational matrices 
% (ROI-to-ROI analysis) and correlational images (seed-to-voxel analysis)
% for each condition of interest.
%
% FORMAT [sub_check] = tmfc_BSC_after_FIR(tmfc)
%
%   tmfc.subjects.path     - List of paths to SPM.mat files for N subjects
%   tmfc.project_path      - Path where all results will be saved
%   tmfc.defaults.parallel - 0 or 1 (sequential or parallel computing)
%   tmfc.ROI_set           - List of selected ROIs
%   tmfc.ROI_set.set_name  - Name of the ROI set
%   tmfc.ROI_set.ROIs.name - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path - Path to the selected ROI image
%
%   tmfc.LSS_after_FIR.conditions        - List of conditions of interest
%   tmfc.LSS_after_FIR.conditions.sess   - Session number
%                                          (as specified in SPM.Sess)
%   tmfc.LSS_after_FIR.conditions.number - Condition number
%                                          (as specified in SPM.Sess.U)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified:
%
%   tmfc.LSS_after_FIR.conditions(1).sess   = 1;   
%   tmfc.LSS_after_FIR.conditions(1).number = 1; - "Cond A", 1st session
%   tmfc.LSS_after_FIR.conditions(2).sess   = 1;
%   tmfc.LSS_after_FIR.conditions(2).number = 2; - "Cond B", 1st session
%   tmfc.LSS_after_FIR.conditions(3).sess   = 2;
%   tmfc.LSS_after_FIR.conditions(3).number = 1; - "Cond A", 2nd session
%   tmfc.LSS_after_FIR.conditions(4).sess   = 2;
%   tmfc.LSS_after_FIR.conditions(4).number = 2; - "Cond B", 2nd session
%
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path = 'C:\ROI_set\two_ROIs\ROI_2.nii';
%
% FORMAT [sub_check] = tmfc_BSC_after_FIR(tmfc,ROI_set)
% Run the function for the selected ROI set.
%
%   tmfc                   - As above
%   ROI_set                - Number of the ROI set in the tmfc structure
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
    
% 
% if nargin == 1
%    ROI_set = 1;
% end

R = length(tmfc.ROI_set(ROI_set).ROIs);



if isfolder([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name])
    rmdir([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name],'s');
end

if ~isfolder([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name])
    for ROI_number = 1:R
        mkdir([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep ...
                'Seed_to_voxel' filesep tmfc.ROI_set(ROI_set).ROIs(ROI_number).name]);
    end
    mkdir([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep 'ROI_to_ROI']);
    mkdir([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep 'Beta_series']);
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
    ROIs(i).mask = spm_data_read(spm_data_hdr_read([tmfc.project_path filesep 'Masked_ROIs' filesep ...
        tmfc.ROI_set(ROI_set).set_name filesep tmfc.ROI_set(ROI_set).ROIs(i).name '_masked.nii']),'xyz',XYZ);
    ROIs(i).mask(ROIs(i).mask == 0) = NaN;
    try
        waitbar(i/R,w,['ROI № ' num2str(i,'%.f')]);
    end
end

try
    delete(w)
end

% Number of trials per condition
E_C = [];                       
for i = 1:length(SPM.SPM.Sess)
    for j = 1:length(tmfc.LSS_after_FIR.conditions)
        if tmfc.LSS_after_FIR.conditions(j).sess == i
            E_C(j) =  length(SPM.SPM.Sess(i).U(tmfc.LSS_after_FIR.conditions(j).number).ons);
        end
    end
end

% Extract and correlate mean beta series from ROIs
w = waitbar(0,'Please wait...','Name','Extract and correlate mean beta series');
N = length(tmfc.subjects);

for i = 1:N
    tic
    % Conditions of interest
    for j = 1:length(tmfc.LSS_after_FIR.conditions)
        beta_series(j).condition = ['Sess_' num2str(tmfc.LSS_after_FIR.conditions(j).sess) '_Cond_' num2str(tmfc.LSS_after_FIR.conditions(j).number)];

        % Extract mean beta series from ROIs
        for k = 1:E_C(j)
            betas(k,:) = spm_data_read(spm_data_hdr_read([tmfc.project_path filesep 'LSS_after_FIR' filesep 'Subject_' num2str(i,'%04.f') filesep 'Betas' filesep ...
                'Beta_Sess_' num2str(tmfc.LSS_after_FIR.conditions(j).sess) '_Cond_' num2str(tmfc.LSS_after_FIR.conditions(j).number) '_Trial_' num2str(k) '.nii']),'xyz',XYZ);
            for ROI_number = 1:R
                beta_series(j).ROI_mean(k,ROI_number) = nanmean(ROIs(ROI_number).mask.*betas(k,:));
            end
        end

        % Seed-to-voxel correlation
        for ROI_number = 1:R
            BSC_image(ROI_number).z_value = atanh(corr(beta_series(j).ROI_mean(:,ROI_number),betas));
        end

        % ROI-to-ROI correlation
        z_value_matrix = atanh(corr(beta_series(j).ROI_mean));
        
        % Save BSC images
        for ROI_number = 1:R
            hdr.fname = [tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep ...
                'Seed_to_voxel' filesep tmfc.ROI_set(ROI_set).ROIs(ROI_number).name filesep ...
                'Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' beta_series(j).condition '.nii'];
            hdr.descrip = ['z-value map: ' beta_series(j).condition];    
            image = NaN(SPM.SPM.xVol.DIM');
            image(iXYZ) = BSC_image(ROI_number).z_value;
            spm_write_vol(hdr,image);
        end

        % Save BSC matrices
        save([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep 'ROI_to_ROI' filesep ...
            'Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' beta_series(j).condition '.mat'],'z_value_matrix');

        clear betas BSC_image z_value_matrix
    end

    % Save mean beta-series
    save([tmfc.project_path filesep 'BSC_LSS_after_FIR' filesep tmfc.ROI_set(ROI_set).set_name filesep ...
        'Beta_series' filesep 'Subject_' num2str(i,'%04.f') '_seed_ROI_beta_series.mat'],'beta_series');

    % Update waitbar
    t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
    try
        waitbar(i/N,w,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
    end

    sub_check(i) = 1;

    clear beta_series
end

% Close waitbar
try
    delete(w)
end


           