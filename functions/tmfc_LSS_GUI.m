function [conditions] = tmfc_LSS_GUI(SPM,start_case,start_sub)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for LSS regression. Allows to choose conditions of
% interest for LSS regression.
% 
% FORMAT [conditions] = tmfc_LSS_GUI(SPM)
%   SPM          - Path to individual subject SPM.mat file
%
% FORMAT [conditions] = tmfc_LSS_GUI(SPM,start_case,start_sub)
% To run this function from main TMFC GUI
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

start_check = findobj('Tag', 'MAIN_WINDOW');

if isempty(start_check)
    try
        all_cond = generate_LSS_conditions();
        LSS_Cond_GUI();
    catch
        warning('Incorrect format of subject path');
    end
else    
    switch (start_case)

        % GUI window to ask for LSS regression conditions 
        case 1
            try
            % Generate All conditions using function
                all_cond = generate_LSS_conditions();
                LSS_Cond_GUI();
            catch
                warning('Incorrect format of subject path');
            end


        % GUI window to ask if user wants to Restart computation for all subs
        case 2
            LSS_restart_GUI();

        % GUI window to ask if user wants to continue from last processed or 
        % Full restart
        case 3
            LSS_continue_GUI(start_sub);

    end
end

% Function that extracts & produces Conditions for user selection via GUI
    function LSS_Cond_GUI(~,~)




        % Local Variables that work throughout the RunTime upto checking stage
        % Variable to store all conditions possible 
        try
            if ~isempty(all_cond)

                main_cond = sorter_1(all_cond);
                LST_1 = {};
                for i = 1:length(main_cond)
                    LST_1 = vertcat(LST_1, main_cond(i).list_name);        
                end
                all_cond_copy = main_cond;
            end 
        catch
            LST_1 = {};
        end


        LST_2 = {};
        selection_1 = {};          % Variable to store the selected list of conditions in BOX 1(as INDEX)
        selection_2 = {};          % Variable to store the selected list of conditions in BOX 2(as INDEX)

        full_1 = main_cond;

        %% Creation of GUI & its elements

        LSS_GUI = figure('Name', 'LSS regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.65 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle','modal','CloseRequestFcn', @LSS_stable_Exit);

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

        % Assignig actions of buttons of GUI 
        set(LSS_E1_lst, 'Value', []);
        set(LSS_E1_lst, 'callback', @action_select_1)
        set(LSS_E2_lst, 'Value', []);
        set(LSS_E2_lst, 'callback', @action_select_2)

        set(LSS_ADD, 'callback', @action_3)
        set(LSS_ADA, 'callback', @action_4)
        set(LSS_HELP, 'callback', @LSS_H);

        set(LSS_OK, 'callback', @action_5)
        set(LSS_REV, 'callback', @action_6)
        set(LSS_REVA, 'callback', @action_7)

        %% Function to reuturn user's selection 
        
        function LSS_stable_Exit(~,~)
            try
               h88 = findobj('Tag', 'MAIN_WINDOW');
               setappdata(h88, 'LSS_NO_COND', 1); 
            end
            delete(LSS_GUI);
        end
        
        function action_select_1(~,~)
            index = get(LSS_E1_lst, 'Value');  % Retrieves the users selection LIVE
            selection_1 = index;      
        end

        function action_select_2(~,~)
            index = get(LSS_E2_lst, 'Value');  % Retrieves the users selection LIVE
            selection_2 = index;             
        end
        %% Function to Add single condition

        function action_3(~,~)

            % Checking if there is a selection from the user
            if isempty(selection_1)

                % if no selection, raise warning 
                warning('No conditions selected');

            else

                % Else continue to add selected condition to selected list

                len_exst = length(LST_2);     % Find length of existing subjects in selected condition
                NEW_paths = {};               % Creation of empty array to store new paths

                % Based on the selection add variables to a selected list
                for j = 1:length(selection_1) 
                    NEW_paths = vertcat(NEW_paths, LST_1(selection_1));
                end

                % Addition & extraction of unique selected conditions
                LST_2 = vertcat(LST_2, NEW_paths);
                new_ones = length(unique(LST_2)) - len_exst;
                LST_2 = unique(LST_2);

                % Logical condition to check if newly selected conditions have been added
                if new_ones == 0
                    warning('Newly selected conditions are already present in the list, no new conditions added');
                else
                    fprintf('Conditions selected: %d \n', new_ones(1)); 
                    % Sorting of elements as per SESS & NUMBER
                    LST_2 = sorter_2(LST_2, full_1);
                end 

                % Set sorted list of conditions into GUI
                set(LSS_E2_lst, 'String', LST_2);

            end

        end

        %% Function to add all conditions 

        function action_4(~,~) % Add ll

            % Logical condition to check if all elements are already present
            if length(LST_2) == length(LST_1)
                warning('All conditions are already selected');
            else

                % Selection of all elements
                len_exst_4 = length(LST_2);
                NEW_paths_4 = {};                                             
                for k = 1:length(LST_1)
                    NEW_paths_4 = vertcat(NEW_paths_4, LST_1(k));             
                end

               % Addition & extraction of unique selected conditions
                LST_2 = vertcat(LST_2, NEW_paths_4);
                new_ones_4 = length(unique(LST_2)) - len_exst_4;
                LST_2 = unique(LST_2);

                % Logical condition to check if newly selected conditions have been added
                if new_ones_4 == 0
                    warning('Newly selected conditions are already present in the list, no new conditions added');
                else
                    fprintf('New conditions selected: %d \n', new_ones_4(1)); 
                    % Sorting of elements as per SESS & NUMBER
                    LST_2 = sorter_2(LST_2, full_1);
                end 

                % Set sorted list of conditions into GUI
                set(LSS_E2_lst, 'String', LST_2);
            end

        end

        %% Function to continue performing LSS regression
        function action_5(~,~)

            % Logical condition to Check if there are elements selected for Export
           if isempty(LST_2)
               warning('Please select conditions');
           else


                      cond = struct;
               ctr = 1;
               for kgb = 1:length(all_cond_copy)
                   for fsb = 1:length(LST_2)

                       MATCH = strcmp(all_cond_copy(kgb).list_name, LST_2(fsb));
                       if MATCH == 1
                           cond(ctr).sess = all_cond_copy(kgb).sess;
                           cond(ctr).number = all_cond_copy(kgb).number;
                           cond(ctr).name = all_cond_copy(kgb).name;
                           cond(ctr).list_name = all_cond_copy(kgb).list_name;
                           ctr = ctr + 1;
                       end
                   end
               end

                try 
                    % import tmfc
                    LS_GR = evalin('base', 'tmfc');
                    % Assign conditions to TMFC variable in workspace
                    LS_GR.LSS_after_FIR.conditions = cond;
                    assignin('base', 'tmfc', LS_GR);
                end
               close(LSS_GUI);

               disp(strcat(num2str(length(LST_2)),' conditions successfully selected'));
               conditions = cond;
           end
            
        end
        %% Function to perform removal of indiviudual conditon

        function action_6(~,~)

            % Logical condition to check if there are conditions present to remove
            if isempty(LST_2)
                warning('No conditions present to remove');

            % Logical condition if no conditions are selected by the user for removal
            elseif isempty(selection_2)
                warning('No conditions selected to remove');

            else

               % Listing the number of conditions removed 
               LST_2(selection_2,:) = [];
               sizer = length(selection_2);
               fprintf('Number of conditions removed: %d \n', sizer);
               set(LSS_E2_lst, 'Value', []);
               set(LSS_E2_lst, 'String', LST_2);
               selection_2 = {};

            end

        end

        %% Function to perform removal of all conditions

        function action_7(~,~) 

            % Logical condition to check if there are selected condition
            if isempty(LST_2)
                warning('No conditions present to remove');
            else
                LST_2 = {};                                             
                set(LSS_E2_lst, 'String', []);
                selection_2 = {};
                warning('All selected conditions have been removed');
            end

        end

        %% Function to launch help window for Selection of conditions
        function LSS_H(~,~)

            % Creation of GUI window for Help description
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

       uiwait(LSS_GUI);
       return;
    end


% Function to create & generate LSS conditions for selection via GUI interface
    function [cond_list] = generate_LSS_conditions()
            try
                load(SPM);

                k = 1;
                for i = 1:length(SPM.Sess)
                    for j = 1:length({SPM.Sess(i).U(:).name})
                        cond_list(k).sess = i;
                        cond_list(k).number = j;
                        cond_list(k).name = char(SPM.Sess(i).U(j).name);
                        cond_list(k).list_name = [char(SPM.Sess(i).U(j).name) ' (Sess' num2str(i) ', Cond' num2str(j) ')'];
                        k = k + 1;
                    end 
                end
            catch 
                disp('Conditions not selected or incorrect format');
            end
    end

    %% Function to generate GUI window asking user to Restart computation of all subs
    function LSS_restart_GUI()

        LSS_RECOMP = figure('Name', 'LSS task regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.16 0.16],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Restart_LSS'); %X Y W H

        LSS_D1 = uicontrol(LSS_RECOMP,'Style','text','String', {'Recompute LSS task','regression for all subjects.?'},'Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);

        LSS_OK = uicontrol(LSS_RECOMP,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.48);
        LSS_CCL = uicontrol(LSS_RECOMP,'Style','pushbutton', 'String', 'Cancel','Units', 'normalized','fontunits','normalized', 'fontSize', 0.48);

        LSS_D1.Position = [0.10 0.55 0.80 0.260];
        set(LSS_D1,'backgroundcolor',get(LSS_RECOMP,'color'));

        LSS_OK.Position = [0.14 0.25 0.320 0.170];
        LSS_CCL.Position = [0.52 0.25 0.320 0.170];

        set(LSS_CCL, 'callback', @CANCEL);
        set(LSS_OK, 'callback', @ACC);

        % Function to close the Window
        function CANCEL(~,~)
            close(LSS_RECOMP);
        end

        % Function to set state of Restart in APP Data of main Window
        function ACC(~,~)
            h3 = findobj('Tag', 'MAIN_WINDOW');
            setappdata(h3, 'RESTART_LSS', 1);
            close(LSS_RECOMP);
        end

    end

    %% Function to generate GUI window asking to Continue from a last processed subject
    function LSS_continue_GUI(INDEX)

        LSS_MIDCOMP = figure('Name', 'LSS task regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.20 0.20],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Contd_LSS'); %X Y W H

        LSS_Q1 = uicontrol(LSS_MIDCOMP,'Style','text','String', 'Start FIR task regression from','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);
        LSS_Q2 = uicontrol(LSS_MIDCOMP,'Style','text','String', strcat('subject №',num2str(INDEX),'?'), 'Units','normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);

        LSS_YES = uicontrol(LSS_MIDCOMP,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.28);
        LSS_RESTART = uicontrol(LSS_MIDCOMP,'Style','pushbutton', 'String', '<html>&#160 No, start from <br>the first subject','Units', 'normalized','fontunits','normalized', 'fontSize', 0.28);

        LSS_Q1.Position = [0.10 0.55 0.80 0.260];
        LSS_Q2.Position = [0.10 0.40 0.80 0.260];

        set([LSS_Q1,LSS_Q2],'backgroundcolor',get(LSS_MIDCOMP,'color'));

        LSS_YES.Position = [0.12 0.15 0.320 0.270];
        LSS_RESTART.Position = [0.56 0.15 0.320 0.270];

        set(LSS_YES, 'callback', @contd);
        set(LSS_RESTART, 'callback', @RESTART);

        % Function to set status in MAIN_WINDOW appdata (To continue from
        % last processed subject) 
        function contd(~,~)
            %h6 = findobj('Tag', 'MAIN_WINDOW');
            %setappdata(h6, 'CONTD_LSS', 1);
            close(LSS_MIDCOMP);
        end
        % Function to set status in MAIN_WINDOW appdata (To Restart from
        % the first subject)
        function RESTART(~,~)
            h96 = findobj('Tag', 'MAIN_WINDOW');
            setappdata(h96, 'CONTD_LSS', 2);
            close(LSS_MIDCOMP);
        end
        
    end

end
%%
% Function to perform intial sorting of LSS conditions
function [out_list] = sorter_1(in_list)
    [~,index] = sortrows([in_list.sess; in_list.number]');
    out_list = in_list(index); 
    clear index
end

%%
% Function to perform selective Sorting after selection of conditions 
function [sorted_list] = sorter_2(disp_set, full_set)

    temp = {};
    k = 1;
    for i = 1:length(disp_set)
        for j = 1:length(full_set)
            if strcmp(disp_set(i),full_set(j).list_name)
                if k == 1
                    temp = full_set(j);
                    k = k + 1;
                else 
                    temp(k) = full_set(j);
                    k = k + 1;
                end
            end
        end
    end

    [~,index] = sortrows([temp.sess; temp.number]');
    out_list = temp(index); 

    sorted_list = {};
    for x = 1:length(out_list) 
        sorted_list = vertcat(sorted_list, out_list(x).list_name);
    end

    clear index

end