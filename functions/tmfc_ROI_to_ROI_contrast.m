function [sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,contrast_number,ROI_set_number)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates linear contrasts of FC matrices.
%
% FORMAT [sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,con)
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
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions - List of conditions of interest for gPPI and gPPI-FIR analyses
%                                                  (rename the gPPI field to BSC_LSS or BSC_after_FIR to perform the corresponsing TMFC analysis)
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.sess   - Session number (as specified in SPM.Sess)
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.number - Condition number (as specified in SPM.Sess.U)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified:
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).sess   = 1;   
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(1).number = 1; - "Cond A", 1st session
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).sess   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(2).number = 2; - "Cond B", 1st session
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(3).number = 1; - "Cond A", 2nd session
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions(4).number = 2; - "Cond B", 2nd session
%
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path_masked = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path_masked = 'C:\ROI_set\two_ROIs\ROI_2.nii';                             
%
% FORMAT [sub_check] = tmfc_ROI_to_ROI_contrast(tmfc,type,con,ROI_set)
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

w = waitbar(0,'Please wait...','Name','Compute contrasts');
N = length(tmfc.subjects);
R = length(tmfc.ROI_set(ROI_set_number).ROIs);
SPM = load(tmfc.subjects(1).path); 

switch type
    %================================gPPI==================================
    case 1
        for i = 1:N
            tic
            % Load default contrasts for conditions of interest
            cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;
            for j = 1:length(cond_list)               
                cond_name = [];
                cond_name = ['[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                    regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']'];
                
                % If ROI-to-ROI analysis has not been performed for the default contrasts
                if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','asymmetrical', ...
                         ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']),'file')
                    disp('ROI-to-ROI analysis has not been performed previously. Performing ROI-to-ROI gPPI analysis, please wait...');
                    analysis = tmfc.defaults.analysis;
                    tmfc.defaults.analysis = 2;
                    tmfc_gPPI(tmfc,tmfc.ROI_set_number,1);
                    tmfc.defaults.analysis = analysis;
                end
                
                load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','asymmetrical', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']));
                load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','symmetrical', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']));
    
                matrices(j,:) = ppi_matrix(:)';
                symm_matrices(j,:) = symm_ppi_matrix(:)';
                clear ppi_matrix symm_ppi_matrix
            end
            % Calculate and save contrasts
            for j = 1:length(contrast_number)
                ppi_matrix = reshape(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).weights*matrices,[R,R]);
                symm_ppi_matrix = reshape(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).weights*symm_matrices,[R,R]);
                save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','asymmetrical', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') ...
                    '_[' regexprep(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).title,' ','_') '].mat']),'ppi_matrix');
                save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI','ROI_to_ROI','symmetrical', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') ...
                    '_[' regexprep(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(contrast_number(j)).title,' ','_') '].mat']),'symm_ppi_matrix');
                clear ppi_matrix symm_ppi_matrix
            end
            % Update waitbar
            hms = fix(mod(((N-i)*toc/i), [0, 3600, 60]) ./ [3600, 60, 1]);
            try
                waitbar(i/N, w, [num2str(i/N*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
            end       
            sub_check(i) = 1;
            clear matrices
        end 

    %==============================gPPI-FIR================================
    case 2
        for i = 1:N
            tic
            % Load default contrasts for conditions of interest
            cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;
            for j = 1:length(cond_list)               
                cond_name = [];
                cond_name = ['[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                    regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']'];
                
                % If ROI-to-ROI analysis has not been performed for the default contrasts
                if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','asymmetrical', ...
                                  ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']),'file')
                    disp('ROI-to-ROI analysis has not been performed previously. Performing ROI-to-ROI gPPI-FIR analysis, please wait...');
                    analysis = tmfc.defaults.analysis;
                    tmfc.defaults.analysis = 2;
                    tmfc_gPPI_FIR(tmfc,tmfc.ROI_set_number,1);
                    tmfc.defaults.analysis = analysis;
                end
    
                load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','asymmetrical', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']));
                load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','symmetrical', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']));
    
                matrices(j,:) = ppi_matrix(:)';
                symm_matrices(j,:) = symm_ppi_matrix(:)';
                clear ppi_matrix symm_ppi_matrix
            end
            % Calculate and save contrasts
            for j = 1:length(contrast_number)
                ppi_matrix = reshape(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(contrast_number(j)).weights*matrices,[R,R]);
                symm_ppi_matrix = reshape(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(contrast_number(j)).weights*symm_matrices,[R,R]);
                save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','asymmetrical', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') ...
                    '_[' regexprep(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(contrast_number(j)).title,' ','_') '].mat']),'ppi_matrix');
                save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'gPPI_FIR','ROI_to_ROI','symmetrical', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') ...
                    '_[' regexprep(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(contrast_number(j)).title,' ','_') '].mat']),'symm_ppi_matrix');
                clear ppi_matrix symm_ppi_matrix
            end
            % Update waitbar
            hms = fix(mod(((N-i)*toc/i), [0, 3600, 60]) ./ [3600, 60, 1]);
            try
                waitbar(i/N, w, [num2str(i/N*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
            end       
            sub_check(i) = 1;
            clear matrices
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
    
                % If ROI-to-ROI analysis has not been performed for the default contrasts
                if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','ROI_to_ROI', ...
                         ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']),'file')
                    disp('ROI-to-ROI analysis has not been performed previously. Performing ROI-to-ROI BSC-LSS analysis, please wait...');
                    analysis = tmfc.defaults.analysis;
                    tmfc.defaults.analysis = 2;
                    tmfc_BSC(tmfc,tmfc.ROI_set_number);
                    tmfc.defaults.analysis = analysis;
                end
                
                load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','ROI_to_ROI', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']));
    
                matrices(j,:) = z_matrix(:)';
                clear z_matrix
            end
            % Calculate and save contrasts
            for j = 1:length(contrast_number)
                z_matrix = reshape(tmfc.ROI_set(ROI_set_number).contrasts.BSC(contrast_number(j)).weights*matrices,[R,R]);
                save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS','ROI_to_ROI', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') ...
                    '_[' regexprep(tmfc.ROI_set(ROI_set_number).contrasts.BSC(contrast_number(j)).title,' ','_') '].mat']),'z_matrix');
                clear z_matrix
            end
            % Update waitbar
            hms = fix(mod(((N-i)*toc/i), [0, 3600, 60]) ./ [3600, 60, 1]);
            try
                waitbar(i/N, w, [num2str(i/N*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
            end       
            sub_check(i) = 1;
            clear matrices
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

                % If ROI-to-ROI analysis has not been performed for the default contrasts
                if ~exist(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','ROI_to_ROI', ...
                         ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']),'file')
                    disp('ROI-to-ROI analysis has not been performed previously. Performing ROI-to-ROI BSC-LSS (after FIR) analysis, please wait...');
                    analysis = tmfc.defaults.analysis;
                    tmfc.defaults.analysis = 2;
                    tmfc_BSC_after_FIR(tmfc,tmfc.ROI_set_number);
                    tmfc.defaults.analysis = analysis;
                end
                
                load(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','ROI_to_ROI', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(j,'%04.f') '_' cond_name '.mat']));

                matrices(j,:) = z_matrix(:)';
                clear z_matrix
            end
            % Calculate and save contrasts
            for j = 1:length(contrast_number)
                z_matrix = reshape(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(contrast_number(j)).weights*matrices,[R,R]);
                save(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'BSC_LSS_after_FIR','ROI_to_ROI', ...
                    ['Subject_' num2str(i,'%04.f') '_Contrast_' num2str(contrast_number(j),'%04.f') ...
                    '_[' regexprep(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(contrast_number(j)).title,' ','_') '].mat']),'z_matrix');
                clear z_matrix
            end
            % Update waitbar
            hms = fix(mod(((N-i)*toc/i), [0, 3600, 60]) ./ [3600, 60, 1]);
            try
                waitbar(i/N, w, [num2str(i/N*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
            end       
            sub_check(i) = 1;
            clear matrices
        end    
end

% Close waitbar
try
    delete(w)
end
