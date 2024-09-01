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
% structure must be specified:
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
% Example of the ROI set:
%
%   tmfc.ROI_set(1).set_name = 'two_ROIs';
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
   start_sub = 1;
elseif nargin == 2
   start_sub = 1;
end
try
    main_GUI = guidata(findobj('Tag','TMFC_GUI'));                           
    set(main_GUI.TMFC_GUI_S4,'String', 'Updating...','ForegroundColor',[0.772, 0.353, 0.067]);       
end

N = length(tmfc.subjects);
R = length(tmfc.ROI_set(ROI_set_number).ROIs);
cond_list = tmfc.ROI_set(ROI_set_number).gPPI.conditions;

% Initialize waitbar for parallel or sequential computing
switch tmfc.defaults.parallel
    case 0                                      % Sequential
        w = waitbar(0,'Please wait...','Name','PPI regressors calculation','Tag','tmfc_waitbar');
        cleanupObj = onCleanup(@cleanMeUp);
    case 1                                      % Parallel
        try % Pathway for >2016a Versions
            D = parallel.pool.DataQueue;            % Creation of parallel pool 
            w = waitbar(0,'Please wait...','Name','PPI regressors calculation','Tag','tmfc_waitbar');
            afterEach(D, @tmfc_parfor_waitbar);     % Command to update waitbar
            tmfc_parfor_waitbar(w,N);     
        catch % Pathway for Legacy Versions
            legacy_warning();
        end
        try % Bring TMFC main window to the front 
            figure(findobj('Tag','TMFC_GUI'));
        end
end

spm('defaults','fmri');
spm_jobman('initcfg');

for i = start_sub:N
    SPM = load(tmfc.subjects(i).path);
    tic

    if isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(i,'%04.f')]))
        rmdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(i,'%04.f')]),'s');
    end

    if ~isdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(i,'%04.f')]))
        mkdir(fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(i,'%04.f')]));
    end

    % Conditions of interest
    for j = 1:length(cond_list)
        for k = 1:R
            matlabbatch{1}.spm.stats.ppi.spmmat = {tmfc.subjects(i).path};
            matlabbatch{1}.spm.stats.ppi.type.ppi.voi = {fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'VOIs', ... 
                ['Subject_' num2str(i,'%04.f')],['VOI_' tmfc.ROI_set(ROI_set_number).ROIs(k).name '_' num2str(cond_list(j).sess) '.mat'])};
            matlabbatch{1}.spm.stats.ppi.type.ppi.u = [cond_list(j).number 1 1];
            matlabbatch{1}.spm.stats.ppi.name = ['[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(k).name,' ','_') ']_[Sess_' num2str(cond_list(j).sess) ...
                ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') ']'];
     
            matlabbatch{1}.spm.stats.ppi.disp = 0;
            batch{k} = matlabbatch;
            clear matlabbatch
        end
        
        switch tmfc.defaults.parallel
            case 0                              % Sequential
                for k = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_jobman('run',batch{k});
                    movefile(fullfile(SPM.SPM.swd,['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(k).name,' ','_') ...
                        ']_[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                        regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') '].mat']),...
                        fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(i,'%04.f')], ...
                        ['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(k).name,' ','_') ...
                        ']_[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                        regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') '].mat']));
                end
                
            case 1                              % Parallel
                parfor k = 1:R
                    spm('defaults','fmri');
                    spm_jobman('initcfg');
                    spm_get_defaults('cmdline',true);
                    spm_jobman('run',batch{k});
                    movefile(fullfile(SPM.SPM.swd,['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(k).name,' ','_') ...
                        ']_[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                        regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') '].mat']),...
                        fullfile(tmfc.project_path,'ROI_sets',tmfc.ROI_set(ROI_set_number).set_name,'PPIs',['Subject_' num2str(i,'%04.f')], ...
                        ['PPI_[' regexprep(tmfc.ROI_set(ROI_set_number).ROIs(k).name,' ','_') ...
                        ']_[Sess_' num2str(cond_list(j).sess) ']_[Cond_' num2str(cond_list(j).number) ']_[' ...
                        regexprep(char(SPM.SPM.Sess(cond_list(j).sess).U(cond_list(j).number).name),' ','_') '].mat']));
                end
        end

        clear batch
    end
    
    sub_check(i) = 1;
    
    % Update waitbar
    switch tmfc.defaults.parallel
        case 0                              % Sequential
            %t = seconds(toc*(N-i)); t.Format = 'hh:mm:ss';
            hms = fix(mod(((N-i)*toc/i), [0, 3600, 60]) ./ [3600, 60, 1]);
            try
                %waitbar(i/N,w,[num2str(i/N*100,'%.f') '%, ' char(t) ' [hr:min:sec] remaining']);
                waitbar(i / N, handles, [num2str(i/N*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
            end
            try                                                             % Updating the TMFC GUI window with the progress
                main_GUI = guidata(findobj('Tag','TMFC_GUI'));                         % Finding the GUI's object via handle
                set(main_GUI.TMFC_GUI_S4,'String', strcat(num2str(i), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);    % Assigning the status to the TMFC varaible
            end
        case 1                              % Parallel
            try 
                send(D,[]);
            end
            try                                                             % Updating the TMFC GUI window with the progress
                main_GUI = guidata(findobj('Tag','TMFC_GUI'));                         % Finding the GUI's object via handle
                set(main_GUI.TMFC_GUI_S4,'String', strcat(num2str(i), '/', num2str(N), ' done'),'ForegroundColor',[0.219, 0.341, 0.137]);    % Assigning the status to the TMFC varaible
            end
    end

   clear SPM
end

try
    delete(w)
end

function cleanMeUp()
    
    try
        GUI = guidata(findobj('Tag','TMFC_GUI')); 
        set([GUI.TMFC_GUI_B1, GUI.TMFC_GUI_B2, GUI.TMFC_GUI_B3, GUI.TMFC_GUI_B4,...
            GUI.TMFC_GUI_B5a, GUI.TMFC_GUI_B5b, GUI.TMFC_GUI_B6, GUI.TMFC_GUI_B7,...
            GUI.TMFC_GUI_B8, GUI.TMFC_GUI_B9, GUI.TMFC_GUI_B10, GUI.TMFC_GUI_B11,...
            GUI.TMFC_GUI_B12a,GUI.TMFC_GUI_B12b,GUI.TMFC_GUI_B13a,GUI.TMFC_GUI_B13b,...
            GUI.TMFC_GUI_B14a,GUI.TMFC_GUI_B14b], 'Enable', 'on');
        delete(findall(0,'type', 'Figure','Tag', 'tmfc_waitbar'));
    end
    try                                                                 
        delete(findall(0,'type','Figure','Tag', 'tmfc_waitbar'));
    end
end

end

% Waitbar for parallel mode
function tmfc_parfor_waitbar(waitbarHandle,iterations)
    persistent count h N start

    if nargin == 2
        count = 0;
        h = waitbarHandle;
        N = iterations;
        start = tic;
        
    else
        if isvalid(h)         
            count = count + 1;
            time = toc(start);
            %t = seconds((N-count)*time/count); t.Format = 'hh:mm:ss';
            hms = fix(mod(((N-count)*time/count), [0, 3600, 60]) ./ [3600, 60, 1]);
            waitbar(count / N, h, [num2str(count/N*100,'%.f') '%, ' num2str(hms(1)) ':' num2str(hms(2)) ':' num2str(hms(3)) ' [hr:min:sec] remaining']);
        end
    end
end

function legacy_warning()

Warn_Window = figure('Name', 'Please wait', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.22 0.18],'Resize','off','MenuBar', 'none', 'ToolBar', 'none','Tag','TMFC_WB_NUM', 'WindowStyle','modal', 'color', 'w');         
Warn_Window_txt_1= uicontrol(Warn_Window,'Style','text','String', {'Waitbar progress update is not available for parallel computations','in MATLAB R2016b and earlier.'},'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.26, 'Position',[0.1 0.55 0.8 0.400],'backgroundcolor',get(Warn_Window,'color'));
Warn_Window_txt_2= uicontrol(Warn_Window,'Style','text','String', {'Please wait as computations are processed....'},'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.41, 'Position',[0.1 0.28 0.8 0.240],'backgroundcolor',get(Warn_Window,'color'));
Warn_Close_btn = uicontrol(Warn_Window, 'Style', 'pushbutton', 'String', 'Close', 'Units', 'normalized','fontunits','normalized', 'fontSize', 0.48, 'Position',[0.38 0.08 0.25 0.170], 'callback', @Close_warn_window);

    function Close_warn_window(~,~)
        delete(Warn_Window);
    end
        
end