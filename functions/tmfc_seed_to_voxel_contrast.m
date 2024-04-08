function [sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,contrast_number,ROI_set_number)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates linear contrasts of seed-to-voxel FC images.
%
% FORMAT [sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,con)
%
%   type                   - TMFC analysis type
%                            1: gPPI
%                            2: gPPI-FIR
%                            3: BSC-LSS
%                            4: BSC-LSS after FIR
%
%   contrast_number        - Numbers of contrasts to compute in tmfc struct
%    
%   tmfc.subjects.path            - Paths to individual SPM.mat files
%   tmfc.project_path             - Path where all results will be saved
%   tmfc.defaults.parallel        - 0 or 1 (sequential/parallel computing)
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to the ROI images masked by group
%                                   mean binary mask 
%
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions        - List of conditions of interest for gPPI
%                                 and gPPI-FIR analyses
%                                 (rename the gPPI field to BSC_LSS or
%                                 BSC_after_FIR to perform the
%                                 corresponsing TMFC analysis)
%    
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions.sess   - Session number
%                                          (as specified in SPM.Sess)
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions.number - Condition number
%                                          (as specified in SPM.Sess.U)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified:
%
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions(1).sess   = 1;   
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions(1).number = 1; - "Cond A", 1st session
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions(2).sess   = 1;
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions(2).number = 2; - "Cond B", 1st session
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions(3).sess   = 2;
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions(3).number = 1; - "Cond A", 2nd session
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions(4).sess   = 2;
%   tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions(4).number = 2; - "Cond B", 2nd session
%
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path_masked = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path_masked = 'C:\ROI_set\two_ROIs\ROI_2.nii';                             
%
% FORMAT [sub_check] = tmfc_seed_to_voxel_contrast(tmfc,type,con,ROI_set)
% Run the function for the selected ROI set
%
%   tmfc                   - As above
%   ROI_set_number         - Number of the ROI set in the tmfc structure
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


if nargin < 4
   ROI_set_number = 1;
end

SPM = load(tmfc.subjects(1).path);
XYZ  = SPM.SPM.xVol.XYZ;
iXYZ = cumprod([1,SPM.SPM.xVol.DIM(1:2)'])*XYZ - sum(cumprod(SPM.SPM.xVol.DIM(1:2)'));
hdr.dim = SPM.SPM.Vbeta(1).dim;
hdr.dt = SPM.SPM.Vbeta(1).dt;
hdr.pinfo = SPM.SPM.Vbeta(1).pinfo;
hdr.mat = SPM.SPM.Vbeta(1).mat;

w = waitbar(0,'Please wait...','Name','Compute contrasts');
N = length(tmfc.subjects);
R = length(tmfc.ROI_set(ROI_set_number).ROIs);

switch type
    %================================gPPI==================================
    case 1
        for i = 1:N
            tic
            % Load default contrasts for conditions of interest
            cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
            for j = 1:length(cond_list)
                cond_name = [];
                cond_name = ['[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                    regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']']; 
                for ROI_number = 1:R
                    images(ROI_number).seed(j,:) = spm_data_read(spm_data_hdr_read(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                        'gPPI','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name, ...
                        ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.nii'])),'xyz',XYZ);
                end
            end
            % Calculate and save contrasts
            for j = 1:length(contrast_number)
                for ROI_number = 1:R
                    contrast = tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).weights*images(ROI_number).seed;

                    hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI', ...
                        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name, ...
                        ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') '_[' ...
                        regexprep(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).title,' ','_') '].nii']);
                    hdr.descrip = ['Linear contrast of PPI beta maps: ' tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).title];    
                    image = NaN(SPM.SPM.xVol.DIM');
                    image(iXYZ) = contrast;
                    spm_write_vol(hdr,image);
                    clear contrast
                end
            end
            % Update waitbar
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
            try
                waitbar(i/N,w,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
            end       
            sub_check(i) = 1;
            clear images
        end

    %=============================gPPI-FIR=================================
    case 2
        for i = 1:N
            tic
            % Load default contrasts for conditions of interest
            cond_list = tmfc.ROI_set(tmfc.ROI_set_number).gPPI.conditions;
            for j = 1:length(cond_list)
                cond_name = [];
                cond_name = ['[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                    regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']']; 
                for ROI_number = 1:R
                    images(ROI_number).seed(j,:) = spm_data_read(spm_data_hdr_read(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                        'gPPI_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name, ...
                        ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.nii'])),'xyz',XYZ);
                end
            end
            % Calculate and save contrasts
            for j = 1:length(contrast_number)
                for ROI_number = 1:R
                    contrast = tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).weights*images(ROI_number).seed;

                    hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR', ...
                        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name, ...
                        ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') '_[' ...
                        regexprep(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).title,' ','_') '].nii']);
                    hdr.descrip = ['Linear contrast of PPI beta maps: ' tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).title];    
                    image = NaN(SPM.SPM.xVol.DIM');
                    image(iXYZ) = contrast;
                    spm_write_vol(hdr,image);
                    clear contrast
                end
            end
            % Update waitbar
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
            try
                waitbar(i/N,w,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
            end       
            sub_check(i) = 1;
            clear images
        end

    %===============================BSC-LSS================================
    case 3
        for i = 1:N
            tic
            % Load default contrasts for conditions of interest
            cond_list = tmfc.LSS.conditions;
            for j = 1:length(cond_list)
                cond_name = [];
                cond_name = ['[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                    regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']']; 
                for ROI_number = 1:R
                    images(ROI_number).seed(j,:) = spm_data_read(spm_data_hdr_read(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                        'BSC_LSS','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name, ...
                        ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.nii'])),'xyz',XYZ);
                end
            end
            % Calculate and save contrasts
            for j = 1:length(contrast_number)
                for ROI_number = 1:R
                    contrast = tmfc.ROI_set(ROI_set_number).contrasts.BSC(contrast_number(j)).weights*images(ROI_number).seed;

                    hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS', ...
                        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name, ...
                        ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') '_[' ...
                        regexprep(tmfc.ROI_set(ROI_set_number).contrasts.BSC(contrast_number(j)).title,' ','_') '].nii']);
                    hdr.descrip = ['Linear contrast of z-value maps: ' tmfc.ROI_set(ROI_set_number).contrasts.BSC(contrast_number(j)).title];    
                    image = NaN(SPM.SPM.xVol.DIM');
                    image(iXYZ) = contrast;
                    spm_write_vol(hdr,image);
                    clear contrast
                end
            end
            % Update waitbar
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
            try
                waitbar(i/N,w,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
            end       
            sub_check(i) = 1;
            clear images
        end

    %==========================BSC-LSS after FIR===========================
    case 4
        for i = 1:N
            tic
            % Load default contrasts for conditions of interest
            cond_list = tmfc.LSS_after_FIR.conditions;
            for j = 1:length(cond_list)
                cond_name = [];
                cond_name = ['[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                    regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']']; 
                for ROI_number = 1:R
                    images(ROI_number).seed(j,:) = spm_data_read(spm_data_hdr_read(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name, ...
                        'BSC_LSS_after_FIR','Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name, ...
                        ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.nii'])),'xyz',XYZ);
                end
            end
            % Calculate and save contrasts
            for j = 1:length(contrast_number)
                for ROI_number = 1:R
                    contrast = tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(contrast_number(j)).weights*images(ROI_number).seed;

                    hdr.fname = fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR', ...
                        'Seed_to_voxel',tmfc.ROI_set(ROI_set_number).ROIs(ROI_number).name, ...
                        ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') '_[' ...
                        regexprep(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(contrast_number(j)).title,' ','_') '].nii']);
                    hdr.descrip = ['Linear contrast of z-value maps: ' tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(contrast_number(j)).title];    
                    image = NaN(SPM.SPM.xVol.DIM');
                    image(iXYZ) = contrast;
                    spm_write_vol(hdr,image);
                    clear contrast
                end
            end
            % Update waitbar
            t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
            try
                waitbar(i/N,w,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
            end       
            sub_check(i) = 1;
            clear images
        end
end

% Close waitbar
try
    delete(w)
end