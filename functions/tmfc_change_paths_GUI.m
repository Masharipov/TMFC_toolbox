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

tmfc_CP_MW = figure('Name', 'Change paths', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.30 0.40 0.35 0.26],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

tmfc_CP_MW_S1 = uicontrol(tmfc_CP_MW,'Style','text','String', 'Change paths in SPM.mat files','Units', 'normalized','fontunits','normalized', 'fontSize', 0.20, 'Position', [0.18 0.66 0.660 0.300],'backgroundcolor',get(tmfc_CP_MW,'color'));
tmfc_CP_MW_S2 = uicontrol(tmfc_CP_MW,'Style','text','String', 'Old pattern (e.g., C:\Project_folder\Subjects):','Units', 'normalized','fontunits','normalized', 'fontSize', 0.20, 'Position', [0.05 0.55 0.450 0.260],'backgroundcolor',get(tmfc_CP_MW,'color'));
tmfc_CP_MW_E1 = uicontrol(tmfc_CP_MW,'Style','edit','String', '','Units', 'normalized','fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'left', 'Position', [0.05 0.60 0.880 0.110]);

tmfc_CP_MW_S3 = uicontrol(tmfc_CP_MW,'Style','text','String', 'New pattern (e.g., E:\All_Projects\Project_folder\Subjects):','Units', 'normalized','fontunits','normalized', 'fontSize', 0.20, 'Position', [0.048 0.29 0.590 0.260],'backgroundcolor',get(tmfc_CP_MW,'color'));
tmfc_CP_MW_E2 = uicontrol(tmfc_CP_MW,'Style','edit','String', '','Units', 'normalized','fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'left', 'Position', [0.05 0.35 0.880 0.110]);

tmfc_CP_MW_S4 = uicontrol(tmfc_CP_MW,'Style','text','String', 'Backups of original SPM.mat files are made with the ''.old'' suffix','Units', 'normalized','fontunits','normalized', 'fontSize', 0.20, 'Position', [0.048 0.06 0.640 0.260],'backgroundcolor',get(tmfc_CP_MW,'color'));

tmfc_CP_MW_OK = uicontrol(tmfc_CP_MW,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35, 'Position', [0.26 0.05 0.180 0.130],'callback', @execute_change);
tmfc_CP_MW_Help = uicontrol(tmfc_CP_MW,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35, 'Position', [0.54 0.05 0.180 0.130],'callback', @help_window);
movegui(tmfc_CP_MW,'center');

function execute_change(~,~)
    old_path = get(tmfc_CP_MW_E1, 'String');
    new_path = get(tmfc_CP_MW_E2, 'String');
    try   
        spm_changepath(char(paths),char(old_path),char(new_path));        
        disp('Paths have been changed.');
    catch 
        disp('Paths have not been changed.');
    end
    close(tmfc_CP_MW);
end


function help_window(~,~)
    tmfc_CP_HW = figure('Name', 'Change paths: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.60 0.40 0.35 0.45],'Resize','off','MenuBar', 'none','ToolBar', 'none','color','w');

    help_S1 = {'Suppose you moved the project folder after fist-level model specification and/or estimation.','',...
        'Original SPM.mat file contains old paths to the model directory, functional images, etc.',...
        '',...
        'The TMFC toolbox uses paths recorded in SPM.mat files. To get access to functional files, you need to change paths in SPM.mat files.'};
    help_S3 = {'Old pattern: C:\Project_folder\Subjects','New pattern: E:\All_Projects\Project_folder\Subjects','',...
        'Old path for the first functional image: ','C:\Project_folder\Subjects\Sub_01\func\swar_001.nii','',...
        'New path for the first functional image: ','E:\All_Projects\Project_folder\Subjects\Sub_01\func\swar_001.nii'};

    tmfc_CP_HW_S1 = uicontrol(tmfc_CP_HW,'Style','text','String', help_S1,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.09,'backgroundcolor',get(tmfc_CP_HW,'color'), 'Position', [0.04 0.56 0.900 0.400]);
    tmfc_CP_HW_S2 = uicontrol(tmfc_CP_HW,'Style','text','String', 'Example:','Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.35,'fontweight', 'bold','backgroundcolor',get(tmfc_CP_HW,'color'), 'Position', [0.04 0.48 0.200 0.100]);
    tmfc_CP_HW_S3 = uicontrol(tmfc_CP_HW,'Style','text','String', help_S3,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.09,'backgroundcolor',get(tmfc_CP_HW,'color'), 'Position', [0.04 0.08 0.900 0.400]);
    tmfc_CP_HW_OK = uicontrol(tmfc_CP_HW,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35, 'Position', [0.45 0.04 0.140 0.090],'callback', @close_tmfc_CP_HW);
    movegui(tmfc_CP_HW,'center');
    
    function close_tmfc_CP_HW(~,~)
        close(tmfc_CP_HW);
    end
end
uiwait(tmfc_CP_MW);
end
