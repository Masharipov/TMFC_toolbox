function tmfc_LSS_GUI

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for LSS regression. Allows to choose conditions of
% interest for LSS regression.
%
% Designed to run only via the main GUI window.
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


% Generate All conditions using function
all_cond = generate_LSS_conditions();

% Local Variables that work throughout the RunTime upto checking stage
% Variable to store all conditions possible 
try
if ~isempty(all_cond)
    LST_1 = {};
    for i = 1:length(all_cond)
        LST_1 = vertcat(LST_1, all_cond(i).list_name);        
    end
    ALL_CONDS_COPY = all_cond;
end 
catch
LST_1 = {};
end


LST_2 = {};
selection_1 = {};          % Variable to store the selected list of areas in BOX 1(as INDEX)
selection_2 = {};          % Variable to store the selected list of areas in BOX 2(as INDEX)

    
LSS_GUI = figure('Name', 'LSS regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.65 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off');

% Initializing Elements of the UI
LSS_E0  = uicontrol(LSS_GUI,'Style','text','String', 'Select conditions of interest','Units', 'normalized', 'Position',[0.270 0.93 0.450 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');

LSS_E1  = uicontrol(LSS_GUI,'Style','text','String', 'All conditions:','Units', 'normalized', 'Position',[0.045 0.88 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
LSS_E1_lst = uicontrol(LSS_GUI , 'Style', 'listbox', 'String', LST_1,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.59 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07);

LSS_ADD = uicontrol(LSS_GUI,'Style','pushbutton','String', 'Add selected','Units', 'normalized','Position',[0.045 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
LSS_ADA = uicontrol(LSS_GUI,'Style','pushbutton','String', 'Add all','Units', 'normalized','Position',[0.360 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
LSS_HELP = uicontrol(LSS_GUI,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.680 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);

LSS_E2  = uicontrol(LSS_GUI,'Style','text','String', 'Conditions of interest:','Units', 'normalized', 'Position',[0.045 0.425 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
LSS_E2_lst = uicontrol(LSS_GUI , 'Style', 'listbox', 'String', LST_2,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.135 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07);

LSS_OK = uicontrol(LSS_GUI,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.045 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
LSS_REV = uicontrol(LSS_GUI,'Style','pushbutton','String', 'Remove selected','Units', 'normalized','Position',[0.360 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
LSS_REVA = uicontrol(LSS_GUI,'Style','pushbutton','String', 'Remove all','Units', 'normalized','Position',[0.680 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);


set(LSS_E1_lst, 'Value', []);
set(LSS_E1_lst, 'callback', @action_select_1)

set(LSS_E2_lst, 'Value', []);
set(LSS_E2_lst, 'callback', @action_select_2)
%set(LSS_E2_lst, 'Enable', 'off'); % Initially will remain off



set(LSS_ADD, 'callback', @action_3)
set(LSS_ADA, 'callback', @action_4)
set(LSS_HELP, 'callback', @LSS_H);

set(LSS_OK, 'callback', @action_5)
set(LSS_REV, 'callback', @action_6)
set(LSS_REVA, 'callback', @action_7)


function action_5(~,~)
   
   if isempty(LST_2)
       warning('Please select areas to export');
   else
       LS_GR = evalin('base', 'tmfc');
       EXPORT = struct;
       for kgb = 1:length(ALL_CONDS_COPY)
           for fsb = 1:length(LST_2)
               
               MATCH = strcmp(ALL_CONDS_COPY(kgb).list_name, LST_2(fsb));
               if MATCH == 1
                   EXPORT(kgb).sess = ALL_CONDS_COPY(kgb).sess;
                   EXPORT(kgb).number = ALL_CONDS_COPY(kgb).number;
                   EXPORT(kgb).name = ALL_CONDS_COPY(kgb).name;
                   EXPORT(kgb).list_name = ALL_CONDS_COPY(kgb).list_name;
               end
           end
       end
       
       
       LS_GR.LSS_after_FIR.conditions = EXPORT;
       close(LSS_GUI);
       assignin('base', 'tmfc', LS_GR);
       disp(strcat(num2str(length(LST_2)),' areas successfully selected'));
   end
   
   GDR = evalin('base', 'tmfc');
   if isstruct(GDR.LSS_after_FIR.conditions)
        warning('Initiating LSS regression');
        
        try
        FDR_FREZ = findobj('Tag','MAIN_WINDOWS');
        FR_data = guidata(FDR_FREZ); 
        set([FR_data.SUB,FR_data.FIR_TR, FR_data.LSS_R, FR_data.ROI, FR_data.BSC, FR_data.gppi,FR_data.save_p, FR_data.open_p, FR_data.change_p, FR_data.settings,FR_data.bgrd],'Enable', 'off');
        end
        
        disp('LSS REGRESSION YET TO BE Connected');
        disp(GDR.LSS_after_FIR.conditions);
        %RES_LSS = LSS_regress_resid_ts(GDR, 1);
        %RES_LSS = LSS_regress_resid_worker(GDR, 1);
        

        D = size(RES_LSS);

        trial = [];
        I = [];

        for i_STO = 1:D(1) % Subject number

            for j_STO = 1:D(2) % session (COLUMNS)

                for k_STO = 1:D(3) % trials [ROWS}

                    trial(k_STO) = RES_LSS(i_STO,j_STO,k_STO);

                end

                if j_STO ~= 1
                    I = [I, trial]';
                else
                    I = [trial]';
                end
                trial = [];
            end

            Ringer = evalin('base', 'tmfc');
            Ringer.subjects(i_STO).LSS_after_FIR = I;
            assignin('base', 'tmfc', Ringer);
        end


   end
   
   try
    FDR_FREZ_2 = findobj('Tag','MAIN_WINDOWS');
    FR2_data = guidata(FDR_FREZ_2); 
    set([FR2_data.SUB,FR2_data.FIR_TR, FR2_data.LSS_R, FR2_data.ROI, FR2_data.BSC, FR2_data.gppi,FR2_data.save_p, FR2_data.open_p, FR2_data.change_p, FR2_data.settings,FR2_data.bgrd],'Enable', 'on');
   end
   
end



function action_6(~,~)
   
    if isempty(LST_2)
        warning('No areas present to remove, please add areas');
    elseif isempty(selection_2)
        warning('No areas selected to remove');
    else
       LST_2(selection_2,:) = [];
       sizer = length(selection_2);
       fprintf('Number of areas removed are: %d \n', sizer);
       set(LSS_E2_lst, 'Value', []);
       set(LSS_E2_lst, 'String', LST_2);
       selection_2 = {};
    end
        
    
end

function action_7(~,~) % Add ll
    
    if isempty(LST_2)
        warning('No areas present to remove');
    else
    LST_2 = {};                                             % Creation of empty array
    set(LSS_E2_lst, 'String', []);
    selection_2 = {};
    warning('All selected areas have been removed');
    end
    
end



function action_4(~,~) % Add ll
    
    if length(LST_2) == length(LST_1)
        warning('All areas are already selected');
    else
        len_exst_4 = length(LST_2);
        NEW_paths_4 = {};                                             % Creation of empty array
        for k = 1:length(LST_1)
            NEW_paths_4 = vertcat(NEW_paths_4, LST_1(k));                                 % Nullifying the Indexs selected as per the user
        end
       
        LST_2 = vertcat(LST_2, NEW_paths_4);
        new_ones_4 = length(unique(LST_2)) - len_exst_4;
        LST_2 = unique(LST_2);
        
        % Warning & logical Condition (Iteration ii)
        if new_ones_4 == 0
            warning('Newly selected areas are already present in the list, no new subjects added');
        else
            fprintf('New subjects selected are: %d \n', new_ones_4(1)); 
        end 
        set(LSS_E2_lst, 'String', LST_2);
    end
    
end

function action_3(~,~)
    
    if isempty(selection_1)
        warning('No Areas selected');
    else
        
        len_exst = length(LST_2);                              % Size of existing subjects
        
        NEW_paths = {};                                             % Creation of empty array
        for j = 1:length(selection_1)
            NEW_paths = vertcat(NEW_paths, LST_1(selection_1));                                 % Nullifying the Indexs selected as per the user
        end
       
        LST_2 = vertcat(LST_2, NEW_paths);
        new_ones = length(unique(LST_2)) - len_exst;
        LST_2 = unique(LST_2);
        
        % Warning & logical Condition (Iteration ii)
        if new_ones == 0
            warning('Newly selected areas are already present in the list, no new subjects added');
        else
            fprintf('New subjects selected are: %d \n', new_ones(1)); 
        end 
        set(LSS_E2_lst, 'String', LST_2);
        
        
    end
    
end

    

% Execution function for Main Subject Selection
function action_select_1(~,~)
    index = get(LSS_E1_lst, 'Value');                                          % Retrieves the users selection LIVE
    selection_1 = index;      
end

function action_select_2(~,~)
    index = get(LSS_E2_lst, 'Value');                                          % Retrieves the users selection LIVE
    selection_2 = index;             
end





    % Function to select the respective item from the user via index
function action_select(~,~)
    index = get(lst, 'Value');                                          % Retrieves the users selection LIVE
    selection = index;                                                  % variable for full selection
end







% Clear Function: To Clear all existing subjects & .FILE extensions
function action_clr(~,~)
    
    % Logical & Warning condition
    if isempty(main_subjects) | strcmp(file_address,'')
        warning('No subjects present to clear');
    else
        main_subjects = {};
        file_address = {};
        mm_add = {};
        set(lst, 'String', '');                                         % Clearing Display
        disp('All selected subjects have been cleared');
        set(b1_Stat,'String', 'None selected','ForegroundColor','red');
        set(b2_Stat,'String', 'None selected','ForegroundColor','red');
    end 
    
    
end






function LSS_H(~,~)

    LSS_H_W = figure('Name', 'LSS regression: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.65 0.15 0.22 0.50],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off');

    Data_1 = {'Suppose you have two separate sessions.','','Both sessions contains task regressors for', '“Cond A”, “Cond B” and “Errors”', '','If you are only interested in “Cond A” and “Cond B” comparison, the following conditions should be selected:',...
        '','1)  Cond A (Sess1)','2)  Cond B (Sess1)','3)  Cond A (Sess2)','4)  Cond B (Sess2)','','For all selected conditions of interest, the TMFC toolbox will calculate individual trial’s beta-images using Least-Squares Separate (LSS) approach.',...
        '','For each individual trial (event), the LSS approach estimates a separate general linear model (GLM) with two regressors. The first regressor models the expected BOLD response to the current trial of interest, and the second (nuisance) regressor models the BOLD response to all other trials (of interest and no interest).',...
        '','For trials of no interest (here, “Errors”), separate GLMs will not be estimated. Trials of no interest will be used only for the second (nuisance) regressor.'};

    LSS_W1 = uicontrol(LSS_H_W,'Style','text','String',Data_1 ,'Units', 'normalized', 'Position', [0.05 0.12 0.89 0.85], 'HorizontalAlignment', 'left','backgroundcolor','w','fontunits','normalized', 'fontSize', 0.0301);
    LSS_H_OK = uicontrol(LSS_H_W,'Style','pushbutton','String', 'OK','Units', 'normalized', 'Position', [0.34 0.06 0.30 0.06]);%,'fontunits','normalized', 'fontSize', 0.35

    set(LSS_H_OK, 'callback', @LSS_H_close);
    


    function LSS_H_close(~,~);
        close(LSS_H_W);
    end
end
   
end


function [cond_list] = generate_LSS_conditions()
    try
    LG_C = evalin('base', 'tmfc');
    
        try
        load(LG_C.subjects(1).path);
        
        k = 1;
        for i = 1:length(SPM.Sess)
            for j = 1:length({SPM.Sess(i).U(:).name})
                cond_list(k).sess = i;
                cond_list(k).number = j;
                cond_list(k).name = char(SPM.Sess(i).U(j).name);
                %cond_list(k).list_name = [char(SPM.Sess(i).U(j).name) ' (Sess' num2str(i) ')'];
                cond_list(k).list_name = [char(SPM.Sess(i).U(j).name) ' (Sess' num2str(i) ', Cond' num2str(j) ')'];
                k = k + 1;
            end 
        end
        catch 
            warning('Subjects, not selected, please select subjects & try again');
        end
    catch
        warning('TMFC varaible doesn''t exist, Please launch TMFC Toolbox');
    end
end