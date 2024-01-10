function tmfc_change_paths_GUI(paths)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for changing paths. Calls the spm_changepath function 
% to change all paths specified in SPM.mat files. Overwrites SPM.mat files
% and saves the backup of the original SPM.mat files as SPM.mat.old.
% 
% FORMAT tmfc_change_paths_GUI(paths)
%
% paths - cell array containing paths to SPM.mat files to fix 
%  
% If a tmfc structure containing subject paths is defined:
% tmfc_change_paths_GUI({tmfc.subjects.path})
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


%Creation of BASE OUTLINE for Window                                  
CP_1 = figure('Name', 'Change paths', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.30 0.40 0.35 0.26],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

% Initializing Elements of the UI
CP_T1 = uicontrol(CP_1,'Style','text','String', 'Change paths in SPM.mat files','Units', 'normalized','fontunits','normalized', 'fontSize', 0.20);

CP_T2_Q = uicontrol(CP_1,'Style','text','String', 'Old pattern (e.g., C:\Project_folder\Subjects):','Units', 'normalized','fontunits','normalized', 'fontSize', 0.20);
CP_T2_A = uicontrol(CP_1,'Style','edit','String', '','Units', 'normalized','fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'left');

CP_T3_Q = uicontrol(CP_1,'Style','text','String', 'New pattern (e.g., E:\All_Projects\Project_folder\Subjects):','Units', 'normalized','fontunits','normalized', 'fontSize', 0.20);
CP_T3_A = uicontrol(CP_1,'Style','edit','String', '','Units', 'normalized','fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'left');

CP_T4 = uicontrol(CP_1,'Style','text','String', 'Backups of original SPM.mat files are made with the ''.old'' suffix','Units', 'normalized','fontunits','normalized', 'fontSize', 0.20);

CP_OK = uicontrol(CP_1,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35);
CP_Help = uicontrol(CP_1,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35);

% Assigning Positions of elements
CP_T1.Position = [0.18 0.66 0.660 0.300];
CP_T2_Q.Position = [0.05 0.55 0.450 0.260];
CP_T2_A.Position = [0.05 0.60 0.880 0.110];
CP_T3_Q.Position = [0.048 0.29 0.590 0.260];
CP_T3_A.Position = [0.05 0.35 0.880 0.110];
CP_T4.Position = [0.048 0.06 0.640 0.260];   
CP_OK.Position = [0.26 0.05 0.180 0.130];
CP_Help.Position = [0.54 0.05 0.180 0.130];

set([CP_T1,CP_T2_Q,CP_T3_Q,CP_T4],'backgroundcolor',get(CP_1,'color'));

% Assigning Functions Callbacks for each Element (button, listbox etc)
set(CP_OK, 'callback', @execute_change)
set(CP_Help, 'callback', @help_details)


function execute_change(~,~)
    oldp = get(CP_T2_A, 'String');
    newp = get(CP_T3_A, 'String');
    try   
        spm_changepath(char(paths),char(oldp),char(newp));        
        disp('Paths have been sucessfully modified');
    catch 
        disp('Paths have not been changed');
    end
    close(CP_1);
end


function help_details(~,~)
    CP_H = figure('Name', 'Change paths: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.60 0.40 0.35 0.36],'Resize','off','MenuBar', 'none','ToolBar', 'none','color','w'); %X Y W H

    THE_DETAILS = {'Suppose you moved the project folder after fist-level model specification and/or estimation.','',...
        'Original SPM.mat file contains old paths to the model directory, functional images, etc.',...
        '',...
        'The TMFC toolbox uses paths recorded in SPM.mat files. To get access to functional files, you need to change paths in SPM.mat files.'};
    THE_DETAILS_3 = {'Old pattern: C:\Project_folder\Subjects','New pattern: E:\All_Projects\Project_folder\Subjects','',...
        'Old path for the first functional image: ','C:\Project_folder\Subjects\Sub_01\func\swar_001.nii','',...
        'New path for the first functional image: ','E:\All_Projects\Project_folder\Subjects\Sub_01\func\swar_001.nii'};


    CP_DT_1 = uicontrol(CP_H,'Style','text','String', THE_DETAILS,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.10);
    CP_DT_2 = uicontrol(CP_H,'Style','text','String', 'Example:','Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40,'fontweight', 'bold');
    CP_DT_3 = uicontrol(CP_H,'Style','text','String', THE_DETAILS_3,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.10);
    CP_H_OK = uicontrol(CP_H,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35);

    set([CP_DT_1,CP_DT_2,CP_DT_3],'backgroundcolor',get(CP_H,'color'));
    % X Y W H
    CP_DT_1.Position = [0.04 0.56 0.900 0.400];
    CP_DT_2.Position = [0.04 0.46 0.200 0.100];
    CP_DT_3.Position = [0.04 0.06 0.900 0.400];
    CP_H_OK.Position = [0.80 0.08 0.150 0.090];
    
    set(CP_H_OK, 'callback', @CLOSE_CP_H_OK);
    
    function CLOSE_CP_H_OK(~,~)
        close(CP_H);
    end
end

uiwait(CP_1);
    
end
