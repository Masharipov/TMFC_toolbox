function [conditions] = tmfc_gPPI_GUI(SPM_path)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for gPPI analysis. Allows to choose conditions of
% interest for gPPI analysis.
% 
% FORMAT [conditions] = tmfc_gPPI_GUI(SPM_path)
%   SPM_path          - Path to individual subject SPM.mat file
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
all_cond = generate_gPPI_conditions(SPM_path);

% Check if is not empty
if isempty(all_cond)
    error('Selected SPM.mat file is empty.');
else
    % GUI based selection of conditions
    conditions = gPPI_conditions_GUI(all_cond);
end

end

%% Function to select conditions of interest for gPPI analysis via GUI
function [conditions] = gPPI_conditions_GUI(all_cond)

cond_L1 = {};       % Variable to store All conditions in GUI 
cond_L2 = {};       % Variable to store Selected conditions in GUI 
gPPI_MW_SE1 = {};   % Variable to store the selected list of conditions in BOX 1(as INDEX)
gPPI_MW_SE2 = {};   % Variable to store the selected list of conditions in BOX 2(as INDEX)

for iCond = 1:length(all_cond)
    cond_L1 = vertcat(cond_L1, all_cond(iCond).list_name);        
end

% Creation of GUI & its elements
gPPI_MW = figure('Name', 'gPPI: Select conditions', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.45 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle','modal','CloseRequestFcn', @MW_exit);

gPPI_MW_S1  = uicontrol(gPPI_MW,'Style','text','String', 'Select conditions of interest','Units', 'normalized', 'Position',[0.270 0.93 0.460 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
gPPI_MW_S2  = uicontrol(gPPI_MW,'Style','text','String', 'All conditions:','Units', 'normalized', 'Position',[0.045 0.88 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
gPPI_MW_S3  = uicontrol(gPPI_MW,'Style','text','String', 'Conditions of interest:','Units', 'normalized', 'Position',[0.045 0.425 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
gPPI_MW_LB1 = uicontrol(gPPI_MW , 'Style', 'listbox', 'String', cond_L1,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.59 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07,'Value', [],'callback', @MW_LB1_select);
gPPI_MW_LB2 = uicontrol(gPPI_MW , 'Style', 'listbox', 'String', cond_L2,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.135 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07,'Value', [],'callback', @MW_LB2_select);

gPPI_MW_add = uicontrol(gPPI_MW,'Style','pushbutton','String', 'Add selected','Units', 'normalized','Position',[0.045 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_add);
gPPI_MW_add_all = uicontrol(gPPI_MW,'Style','pushbutton','String', 'Add all','Units', 'normalized','Position',[0.360 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_add_all); 
gPPI_MW_help = uicontrol(gPPI_MW,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.680 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_help); 

gPPI_MW_confirm = uicontrol(gPPI_MW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.045 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_confirm); 
gPPI_MW_remove = uicontrol(gPPI_MW,'Style','pushbutton','String', 'Remove selected','Units', 'normalized','Position',[0.360 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_remove); 
gPPI_MW_remove_all = uicontrol(gPPI_MW,'Style','pushbutton','String', 'Remove all','Units', 'normalized','Position',[0.680 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_remove_all);
movegui(gPPI_MW,'center');

%--------------------------------------------------------------------------
% Function to close gPPI GUI without selection of conditions
function MW_exit(~,~)
	delete(gPPI_MW);
    conditions = NaN;
end

%--------------------------------------------------------------------------
function MW_LB1_select(~,~)
    index = get(gPPI_MW_LB1, 'Value');  % Retrieves the users selection LIVE
    gPPI_MW_SE1 = index;      
end

%--------------------------------------------------------------------------
function MW_LB2_select(~,~)
    index = get(gPPI_MW_LB2, 'Value');  % Retrieves the users selection LIVE
    gPPI_MW_SE2 = index;             
end

%--------------------------------------------------------------------------
% Function to add single condition
function MW_add(~,~)
    
	% Checking if there is a selection from the user
    if isempty(gPPI_MW_SE1)
        warning('No conditions selected.');
    else
        % Else continue to add selected condition to selected list
        len_exist = length(cond_L2);     % Find length of existing subjects in selected condition
        new_conds = {};                  % Creation of empty array to store new conditions

        % Based on the selection add variables to a selected list
        new_conds = vertcat(new_conds,cond_L1(gPPI_MW_SE1)); 
        
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
        set(gPPI_MW_LB2,'String',cond_L2);
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
        len_exist = length(cond_L2);
        new_conds = {};                                             
        new_conds = vertcat(new_conds,cond_L1(k));             

       % Addition & extraction of unique selected conditions
        cond_L2 = vertcat(cond_L2,new_conds);
        new_cond_count = length(unique(cond_L2)) - len_exist;
        cond_L2 = unique(cond_L2);

        % Logical condition to check if newly selected conditions have been added
        if new_cond_count == 0
            warning('Newly selected conditions are already present in the list, no new conditions added.');
        else
            fprintf('New conditions selected: %d. \n', new_cond_count(1)); 
            % Sorting of elements as per SESS & NUMBER
            cond_L2 = sort_selected_conditions(cond_L2,all_cond);
        end 

        % Set sorted list of conditions into GUI
        set(gPPI_MW_LB2,'String',cond_L2);
    end
end

%--------------------------------------------------------------------------
% Function to export list of gPPI conditions
function MW_confirm(~,~)
    
   % Logical condition to Check if there are elements selected for Export
   if isempty(cond_L2)
       warning('Please select conditions.');
   else
       cond = struct;
       n_cond = 1;
       for jCond = 1:length(all_cond)
           for kCond = 1:length(cond_L2)
               match = strcmp(all_cond(jCond).list_name,cond_L2(kCond));
               if match == 1
                   cond(n_cond).sess = all_cond(jCond).sess;
                   cond(n_cond).number = all_cond(jCond).number;
                   cond(n_cond).name = all_cond(jCond).name;
                   cond(n_cond).list_name = all_cond(jCond).list_name;
                   cond(n_cond).file_name = all_cond(jCond).file_name;
                   n_cond = n_cond + 1;
               end
           end
       end

       delete(gPPI_MW);
       disp(strcat(num2str(length(cond_L2)),' conditions successfully selected.'));
       conditions = cond;
       clear cond n_cond jCond kCond match
   end
end

%--------------------------------------------------------------------------
% Function to remove single condition
function MW_remove(~,~)
    % Logical condition to check if there are conditions present to remove
    if isempty(cond_L2)
        warning('No conditions present to remove.');
    % Logical condition if no conditions are selected by the user for removal
    elseif isempty(gPPI_MW_SE2)
        warning('No conditions selected to remove.');
    else
       % Listing the number of conditions removed 
       cond_L2(gPPI_MW_SE2,:) = [];
       fprintf('Number of conditions removed: %d. \n', length(gPPI_MW_SE2));
       set(gPPI_MW_LB2, 'Value', []);
       set(gPPI_MW_LB2, 'String', cond_L2);
       gPPI_MW_SE2 = {};
    end
end

%--------------------------------------------------------------------------
% Function to remove all conditions
function MW_remove_all(~,~) 
    % Logical condition to check if there are selected condition
    if isempty(cond_L2)
        warning('No conditions present to remove.');
    else
        cond_L2 = {};                                             
        set(gPPI_MW_LB2, 'String', []);
        gPPI_MW_SE2 = {};
        warning('All selected conditions have been removed.');
    end
end

%--------------------------------------------------------------------------
% Function to launch help window for gPPI conditions
function MW_help(~,~)

    % Creation of GUI window for Help description
    gPPI_HW = figure('Name', 'gPPI: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.67 0.31 0.22 0.50],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off', 'WindowStyle', 'Modal');

    string_info = {'Suppose you have two separate sessions.','','Both sessions contains task regressors for', '"Cond A", "Cond B" and "Errors"', '','If you are only interested in "Cond A" and "Cond B" comparison, the following conditions should be selected:',...
    '','1)  Cond A (Sess1)','2)  Cond B (Sess1)','3)  Cond A (Sess2)','4)  Cond B (Sess2)','','For all selected conditions of interest, the TMFC toolbox will create psycho-physiological (PPI) regressors. Thus, for each condition of interest, the generalized PPI (gPPI) model will contain two regressors: (1) psychological regressor and (2) PPI regressor.'...
    '','For trials of no interest (here, "Errors"), the gPPI model will contain only the psychological regressor.'};

    gPPI_HW_S1 = uicontrol(gPPI_HW,'Style','text','String',string_info ,'Units', 'normalized', 'Position', [0.05 0.12 0.89 0.85], 'HorizontalAlignment', 'left','backgroundcolor','w','fontunits','normalized', 'fontSize', 0.0301);
    gPPI_HW_OK = uicontrol(gPPI_HW,'Style','pushbutton','String', 'OK','Units', 'normalized', 'Position', [0.34 0.06 0.30 0.06],'callback', @gPPI_HW_close,'fontunits','normalized', 'fontSize', 0.35);
    movegui(gPPI_HW,'center');

    function gPPI_HW_close(~,~)
        close(gPPI_HW);
    end
end

uiwait(gPPI_MW);

end

%% Function to get information about conditions ===========================
function [cond_list] = generate_gPPI_conditions(SPM_path)

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
    disp('Selected SPM.mat file does not exist or is invalid.');
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