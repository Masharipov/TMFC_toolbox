function [conditions] = tmfc_LSS_GUI(SPM_path)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for LSS regression. Allows to choose conditions of
% interest for LSS regression.
% 
% FORMAT [conditions] = tmfc_LSS_GUI(SPM)
%   SPM          - Path to individual subject SPM.mat file
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

% Get all conditions from the SPM.mat file
all_cond = generate_LSS_conditions(SPM_path);

% Check if SPM.mat is not empty
if isempty(all_cond)
    error('Selected .mat file is empty or invalid');
else
    % GUI based selection of conditions for user
    conditions = LSS_conditions_GUI(all_cond);
end

end
%% Function to select conditions of interest for LSS analysis via GUI 
function [conditions] = LSS_conditions_GUI(all_cond) 

cond_L1 = {};      % Variable to store All conditions in GUI 
cond_L2 = {};      % Variable to store Selected conditions in GUI 
LSS_MW_SE1 = {};   % Variable to store the selected list of conditions in BOX 1(as INDEX)
LSS_MW_SE2 = {};   % Variable to store the selected list of conditions in BOX 2(as INDEX)

for iCond = 1:length(all_cond)
    cond_L1 = vertcat(cond_L1, all_cond(iCond).list_name);        
end

% Creation of GUI & its elements
LSS_MW = figure('Name', 'LSS Conditions Selection', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.45 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle','modal','CloseRequestFcn', @MW_exit);

LSS_MW_S1  = uicontrol(LSS_MW,'Style','text','String', 'Select conditions of interest','Units', 'normalized', 'Position',[0.270 0.93 0.460 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
LSS_MW_S2  = uicontrol(LSS_MW,'Style','text','String', 'All conditions:','Units', 'normalized', 'Position',[0.045 0.88 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
LSS_MW_S3  = uicontrol(LSS_MW,'Style','text','String', 'Conditions of interest:','Units', 'normalized', 'Position',[0.045 0.425 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
LSS_MW_LB1 = uicontrol(LSS_MW , 'Style', 'listbox', 'String', cond_L1,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.59 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07,'Value', [],'callback', @MW_LB1_select);
LSS_MW_LB2 = uicontrol(LSS_MW , 'Style', 'listbox', 'String', cond_L2,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.135 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07,'Value', [],'callback', @MW_LB2_select);

LSS_MW_add = uicontrol(LSS_MW,'Style','pushbutton','String', 'Add selected','Units', 'normalized','Position',[0.045 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_add);
LSS_MW_add_all = uicontrol(LSS_MW,'Style','pushbutton','String', 'Add all','Units', 'normalized','Position',[0.360 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_add_all); 
LSS_MW_help = uicontrol(LSS_MW,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.680 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_help); 

LSS_MW_confirm = uicontrol(LSS_MW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.045 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_confirm); 
LSS_MW_remove = uicontrol(LSS_MW,'Style','pushbutton','String', 'Remove selected','Units', 'normalized','Position',[0.360 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_remove); 
LSS_MW_remove_all = uicontrol(LSS_MW,'Style','pushbutton','String', 'Remove all','Units', 'normalized','Position',[0.680 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_remove_all);
movegui(LSS_MW,'center');

%--------------------------------------------------------------------------
% Function to close gPPI GUI without selection of conditions
function MW_exit(~,~)
    delete(LSS_MW);
    conditions = NaN;
end

%--------------------------------------------------------------------------
function MW_LB1_select(~,~)
    index = get(LSS_MW_LB1, 'Value');  % Retrieves the users selection from list
    LSS_MW_SE1 = index;      
end

%--------------------------------------------------------------------------
function MW_LB2_select(~,~)
    index = get(LSS_MW_LB2, 'Value');  % Retrieves the users selection from list
    LSS_MW_SE2 = index;             
end

%--------------------------------------------------------------------------
% Function to add single condition
function MW_add(~,~)

    % Checking if there is a selection from the user
    if isempty(LSS_MW_SE1)
        warning('No conditions selected.');
    else
        % Else continue to add selected condition to selected list
        len_exist = length(cond_L2);   % Find length of selected condition
        new_conds = {};                % Creation of empty array to store new paths

        % Based on the selection add variables to a selected list 
        new_conds = vertcat(new_conds,cond_L1(LSS_MW_SE1));

        % Addition & extraction of unique selected conditions
        cond_L2 = vertcat(cond_L2,new_conds);
        new_cond_count = length(unique(cond_L2)) - len_exist;
        cond_L2 = unique(cond_L2);

        % Logical condition to check if newly selected conditions have been added
        if new_cond_count == 0
            warning('Newly selected conditions are already present in the list, no new conditions added.');
        else
            fprintf('Conditions selected: %d. \n', new_cond_count(1)); 
            % Sorting of elements as per SESS & NUMBER
            cond_L2 = sort_selected_conditions(cond_L2,all_cond);
        end 

        % Set sorted list of conditions into GUI
        set(LSS_MW_LB2,'String',cond_L2);
    end
end

%--------------------------------------------------------------------------
% Function to add all conditions 
function MW_add_all(~,~) 

    % Logical condition to check if all elements are already present
    if length(cond_L2) == length(cond_L1)
        warning('All conditions are already selected.');
    else
        % Selection of all elements
        len_exist = length(cond_L2);    % Find length of selected condition
        new_conds = {};                 % Creation of empty array to store new paths                            
        new_conds = vertcat(new_conds, cond_L1);             

       % Addition & extraction of unique selected conditions
        cond_L2 = vertcat(cond_L2, new_conds);
        new_cond_count = length(unique(cond_L2)) - len_exist;
        cond_L2 = unique(cond_L2);

        % Logical condition to check if newly selected conditions have been added
        if new_cond_count == 0
            warning('Newly selected conditions are already present in the list, no new conditions added.');
        else
            fprintf('New conditions selected: %d. \n', new_cond_count(1)); 
            % Sorting of elements as per SESS & NUMBER
            cond_L2 = sort_selected_conditions(cond_L2, all_cond);
        end 

        % Set sorted list of conditions into GUI
        set(LSS_MW_LB2, 'String', cond_L2);
    end
end

%--------------------------------------------------------------------------
% Function to export list of LSS conditions
function MW_confirm(~,~)

   % Logical condition to Check if there are elements selected for Export
   if isempty(cond_L2)
       warning('Please select conditions.');
   else
       % Create sorted conditions structure
       cond = struct;
       n_cond = 1;
       for jCond = 1:length(all_cond)
           for kCond = 1:length(cond_L2)
               MATCH = strcmp(all_cond(jCond).list_name, cond_L2(kCond));
               if MATCH == 1
                   cond(n_cond).sess = all_cond(jCond).sess;
                   cond(n_cond).number = all_cond(jCond).number;
                   cond(n_cond).name = all_cond(jCond).name;
                   cond(n_cond).list_name = all_cond(jCond).list_name;
                   cond(n_cond).file_name = all_cond(jCond).file_name;
                   n_cond = n_cond + 1;
               end
           end
       end
       delete(LSS_MW);
       disp(strcat(num2str(length(cond_L2)),' conditions successfully selected.'));
       conditions = cond;
       clear cond n_cond jCond kCond MATCH;
   end
end

%--------------------------------------------------------------------------
% Function to remove single condition
function MW_remove(~,~)
    % Logical condition to check if there are conditions present to remove
    if isempty(cond_L2)
        warning('No conditions present to remove.');
    % Logical condition if no conditions are selected by the user for removal
    elseif isempty(LSS_MW_SE2)
        warning('No conditions selected to remove.');
    else
       % Listing the number of conditions removed 
       cond_L2(LSS_MW_SE2,:) = [];
       fprintf('Number of conditions removed: %d. \n', length(LSS_MW_SE2));
       set(LSS_MW_LB2, 'Value', []);
       set(LSS_MW_LB2, 'String', cond_L2);
       LSS_MW_SE2 = {};
    end
end

%--------------------------------------------------------------------------
% Function to remove all conditions
function MW_remove_all(~,~) 
    % Logical condition to check if there are selected condition
    if isempty(cond_L2)
        warning('No conditions present to remove.');
    else
        % Remove & Clear all conditions
        cond_L2 = {};                                             
        set(LSS_MW_LB2, 'String', []);
        LSS_MW_SE2 = {};
        warning('All selected conditions have been removed.');
    end
end

%--------------------------------------------------------------------------
% Function to launch help window for LSS conditions
function MW_help(~,~)

    % Creation of GUI window for Help description
    LSS_HW = figure('Name', 'LSS regression: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.67 0.31 0.22 0.50],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off', 'WindowStyle', 'Modal');

    string_info = {'Suppose you have two separate sessions.','','Both sessions contains task regressors for', '"Cond A"?, "Cond B"? and "Errors"?', '','If you are only interested in "Cond A"? and "Cond B"? comparison, the following conditions should be selected:',...
    '','1)  Cond A (Sess1)','2)  Cond B (Sess1)','3)  Cond A (Sess2)','4)  Cond B (Sess2)','','For all selected conditions of interest, the TMFC toolbox will calculate individual trial"s beta-images using Least-Squares Separate (LSS) approach.',...
    '','For each individual trial (event), the LSS approach estimates a separate general linear model (GLM) with two regressors. The first regressor models the expected BOLD response to the current trial of interest, and the second (nuisance) regressor models the BOLD response to all other trials (of interest and no interest).',...
    '','For trials of no interest (here, "Errors"?), separate GLMs will not be estimated. Trials of no interest will be used only for the second (nuisance) regressor.'};

    LSS_HW_S1 = uicontrol(LSS_HW,'Style','text','String',string_info ,'Units', 'normalized', 'Position', [0.05 0.12 0.89 0.85], 'HorizontalAlignment', 'left','backgroundcolor','w','fontunits','normalized', 'fontSize', 0.0301);
    LSS_HW_OK = uicontrol(LSS_HW,'Style','pushbutton','String', 'OK','Units', 'normalized', 'Position', [0.34 0.06 0.30 0.06],'callback', @LSS_HW_close,'fontunits','normalized', 'fontSize', 0.35);
    movegui(LSS_HW,'center');

    function LSS_HW_close(~,~)
        close(LSS_HW);
    end
end

uiwait(LSS_MW);

end   

%% Function to get information about conditions ===========================
function [cond_list] = generate_LSS_conditions(SPM_path)
    cond_list = {}; 
    try         
        load(SPM_path);
        n_cond = 1; 
        for iSess = 1:length(SPM.Sess)
            for jCond = 1:length({SPM.Sess(iSess).U(:).name})
                cond_list(n_cond).sess = iSess;
                cond_list(n_cond).number = jCond;
                cond_list(n_cond).name = char(SPM.Sess(iSess).U(jCond).name);
                cond_list(n_cond).list_name = [char(SPM.Sess(iSess).U(jCond).name) ' (Sess' num2str(iSess) ', Cond' num2str(jCond) ')'];
                cond_list(n_cond).file_name = ['[Sess_' num2str(iSess) ']_[Cond_' num2str(jCond) ']_[' ...
                                          regexprep(char(SPM.Sess(iSess).U(jCond).name),' ','_') ']'];
                n_cond = n_cond + 1;
            end 
        end
        clear SPM n_cond; 
        
    catch   
        disp('Selected SPM.mat file does not exist.');
        cond_list = {};
    end   
end

%% Function to perform sorting of selected conditions =====================
function [sorted_list] = sort_selected_conditions(selected_cond,all_cond)

temp = {};
sort_index = 1;

for iCond = 1:length(selected_cond)
    for jCond = 1:length(all_cond)
        if strcmp(selected_cond(iCond),all_cond(jCond).list_name)
            if sort_index == 1
                temp = all_cond(jCond);
                sort_index = sort_index + 1;
            else 
                temp(sort_index) = all_cond(jCond);
                sort_index = sort_index + 1;
            end
        end
    end
end

[~,index] = sortrows([temp.sess; temp.number]');
reindexed_list = temp(index); 

sorted_list = {};
for iCond = 1:length(reindexed_list) 
    sorted_list = vertcat(sorted_list, reindexed_list(iCond).list_name);
end

clear index temp sort_index iCond jCond reindexed_list

end