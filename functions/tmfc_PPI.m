function [sub_check] = tmfc_PPI(tmfc,ROI_set_number,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Calculates psycho-physiological interactions (PPIs).
%
% FORMAT [sub_check] = tmfc_PPI_after_FIR(tmfc)
% Run a function starting from the first subject in the list.
%
%   tmfc.subjects.path            - Paths to individual SPM.mat files
%   tmfc.project_path             - Path where all results will be saved
%   tmfc.defaults.parallel        - 0 or 1 (sequential/parallel computing)
%
%   tmfc.ROI_set                  - List of selected ROIs
%   tmfc.ROI_set.type             - Type of the ROI set
%   tmfc.ROI_set.set_name         - Name of the ROI set
%   tmfc.ROI_set.ROIs.name        - Name of the selected ROI
%   tmfc.ROI_set.ROIs.path_masked - Paths to the ROI images masked by group
%                                   mean binary mask 
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions        - List of conditions of interest
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.sess   - Session number (as specified in SPM.Sess)
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions.number - Condition number (as specified in SPM.Sess.U)
%
% Session number and condition number must match the original SPM.mat file.
% Consider, for example, a task design with two sessions. Both sessions 
% contains three task regressors for "Cond A", "Cond B" and "Errors". If
% you are only interested in comparing "Cond A" and "Cond B", the following
% structure must be specified (see tmfc_conditions_GUI):
%
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(1).sess   = 1;   
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(1).number = 1; - "Cond A", 1st session
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(2).sess   = 1;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(2).number = 2; - "Cond B", 1st session
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(3).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(3).number = 1; - "Cond A", 2nd session
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(4).sess   = 2;
%   tmfc.ROI_set(ROI_set_number).gPPI.conditions;(4).number = 2; - "Cond B", 2nd session
%
% Example of the ROI set (see tmfc_select_ROIs_GUI):
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
%   tmfc.ROI_set(1).type = 'binary_images';
%   tmfc.ROI_set(1).ROIs(1).name = 'ROI_1';
%   tmfc.ROI_set(1).ROIs(2).name = 'ROI_2';
%   tmfc.ROI_set(1).ROIs(1).path_masked = 'C:\ROI_set\two_ROIs\ROI_1.nii';
%   tmfc.ROI_set(1).ROIs(2).path_masked = 'C:\ROI_set\two_ROIs\ROI_2.nii';
%
% FORMAT [sub_check] = tmfc_PPI(tmfc,ROI_set_number,start_sub)
% Run the function starting from a specific subject in the path list for
% the selected ROI set.
%
%   tmfc                   - As above
%   ROI_set_number         - Number of the ROI set in the tmfc structure
%   start_sub              - Subject number on the path list to start with
%
% =========================================================================
%
% Copyright (C) 2025 Ruslan Masharipov
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
   start_sub = 1;
elseif nargin == 2
   start_sub = 1;
end

try
    main_GUI = guidata(findobj('Tag','TMFC_GUI'));                           
    set(main_GUI.TMFC_GUI_S4,'String', 'Updating...','ForegroundColor',[0.772, 0.353, 0.067]);       
end

nSub = length(tmfc.subjects);
nROI = length(tmfc.ROI_set(ROI_set_number).ROIs);
cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;
sub_check = zeros(1,nSub);
if start_sub > 1
    sub_check(1:start_sub) = 1;
end

% Initialize waitbar
w = waitbar(0,'Please wait...','Name','PPI regressors calculation','Tag','tmfc_waitbar');
start_time = tic;
count_sub = 1;
cleanupObj = onCleanup(@unfreeze_after_ctrl_c);

spm('defaults','fmri');
spm_jobman('initcfg');

for iSub = start_sub:nSub
    SPM = load(tmfc.subjects(iSub).path);

    if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(iSub,'%04.f')]))
        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(iSub,'%04.f')]),'s');
    end

    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(iSub,'%04.f')]))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(iSub,'%04.f')]));
    end

    % Conditions of interest
    for jCond = 1:length(cond_list)
        for kROI = 1:nROI
            matlabbatch{1}.spm.stats.ppi.spmmat = {tmfc.subjects(iSub).path};
            matlabbatch{1}.spm.stats.ppi.type.ppi.voi = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'VOIs', ... 
                ['Subject_' num2str(iSub,'%04.f')],['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(kROI).name '_' num2str(cond_list(jCond).sess) '.mat'])};
            matlabbatch{1}.spm.stats.ppi.type.ppi.u = [cond_list(jCond).number 1 1];
            matlabbatch{1}.spm.stats.ppi.name = ['[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(kROI).name,' ','_') ']_' cond_list(jCond).file_name];
            matlabbatch{1}.spm.stats.ppi.disp = 0;
            batch{kROI} = matlabbatch;
            clear matlabbatch
        end
        
        switch tmfc.defaults.parallel
            case 0  % Sequential
                for kROI = 1:nROI
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_jobman('run',batch{kROI});
                    movefile(fullfile(SPM.SPM.swd,['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(kROI).name,' ','_') ']_' cond_list(jCond).file_name '.mat']),...
                        fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(iSub,'%04.f')], ...
                        ['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(kROI).name,' ','_') ']_' cond_list(jCond).file_name '.mat']));
                end
                
            case 1  % Parallel
                try
                    parpool;
                    figure(findobj('Tag','TMFC_GUI'));
                end

                parfor kROI = 1:nROI
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_jobman('run',batch{kROI});
                    movefile(fullfile(SPM.SPM.swd,['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(kROI).name,' ','_') ']_' cond_list(jCond).file_name '.mat']), ...
                        fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(iSub,'%04.f')], ...
                        ['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(kROI).name,' ','_') ']_' cond_list(jCond).file_name '.mat']));
                end
        end

        clear batch
    end
    
    sub_check(iSub) = 1;

    % Update main TMFC GUI
    try  
        main_GUI = guidata(findobj('Tag','TMFC_GUI'));                        
        set(main_GUI.TMFC_GUI_S4,'String', strcat(num2str(iSub), '/', num2str(nSub), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);    
    end
    
    % Update waitbar
    elapsed_time = toc(start_time);
    time_per_sub = elapsed_time/count_sub;
    count_sub = count_sub + 1;
    time_remaining = (nSub-iSub)*time_per_sub;
    hms = fix(mod((time_remaining), [0, 3600, 60]) ./ [3600, 60, 1]);
    try
        waitbar(iSub/nSub, w, [num2str(iSub/nSub*100,'%.f') '%, ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec] remaining']);
    end

    clear SPM
end

% Close waitbar
try
    delete(w)
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
