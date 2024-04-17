function [conditions] = tmfc_gPPI_GUI(SPM)


try
    all_cond = generate_gPPI_conditions(SPM);
    gPPI_Cond_GUI();
catch
    warning('Incorrect format of subject path');
end


%% Function that extracts & produces Conditions for user selection via GUI
    function gPPI_Cond_GUI(~,~)

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

        gPPI_GUI = figure('Name', 'gPPI', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.45 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle','modal','CloseRequestFcn', @gPPI_stable_Exit);

        % Initializing Elements of the UI
        gPPI_E0  = uicontrol(gPPI_GUI,'Style','text','String', 'Select conditions of interest','Units', 'normalized', 'Position',[0.270 0.93 0.460 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');

        gPPI_E1  = uicontrol(gPPI_GUI,'Style','text','String', 'All conditions:','Units', 'normalized', 'Position',[0.045 0.88 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
        gPPI_E1_lst = uicontrol(gPPI_GUI , 'Style', 'listbox', 'String', LST_1,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.59 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07);

        gPPI_ADD = uicontrol(gPPI_GUI,'Style','pushbutton','String', 'Add selected','Units', 'normalized','Position',[0.045 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
        gPPI_ADA = uicontrol(gPPI_GUI,'Style','pushbutton','String', 'Add all','Units', 'normalized','Position',[0.360 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
        gPPI_HELP = uicontrol(gPPI_GUI,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.680 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);

        gPPI_E2  = uicontrol(gPPI_GUI,'Style','text','String', 'Conditions of interest:','Units', 'normalized', 'Position',[0.045 0.425 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
        gPPI_E2_lst = uicontrol(gPPI_GUI , 'Style', 'listbox', 'String', LST_2,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.135 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07);

        gPPI_OK = uicontrol(gPPI_GUI,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.045 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
        gPPI_REV = uicontrol(gPPI_GUI,'Style','pushbutton','String', 'Remove selected','Units', 'normalized','Position',[0.360 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
        gPPI_REVA = uicontrol(gPPI_GUI,'Style','pushbutton','String', 'Remove all','Units', 'normalized','Position',[0.680 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);

        % Assignig actions of buttons of GUI 
        set(gPPI_E1_lst, 'Value', []);
        set(gPPI_E1_lst, 'callback', @action_select_1)
        set(gPPI_E2_lst, 'Value', []);
        set(gPPI_E2_lst, 'callback', @action_select_2)

        set(gPPI_ADD, 'callback', @action_3)
        set(gPPI_ADA, 'callback', @action_4)
        set(gPPI_HELP, 'callback', @gPPI_H);

        set(gPPI_OK, 'callback', @action_5)
        set(gPPI_REV, 'callback', @action_6)
        set(gPPI_REVA, 'callback', @action_7)

        movegui(gPPI_GUI,'center');

        %% Function to reuturn user's selection 
        
        function gPPI_stable_Exit(~,~)

            delete(gPPI_GUI);
            conditions = NaN;
        end
        
        function action_select_1(~,~)
            index = get(gPPI_E1_lst, 'Value');  % Retrieves the users selection LIVE
            selection_1 = index;      
        end

        function action_select_2(~,~)
            index = get(gPPI_E2_lst, 'Value');  % Retrieves the users selection LIVE
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
                set(gPPI_E2_lst, 'String', LST_2);

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
                set(gPPI_E2_lst, 'String', LST_2);
            end

        end

        %% Function to continue performing gPPI related operations
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


               delete(gPPI_GUI);

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
               set(gPPI_E2_lst, 'Value', []);
               set(gPPI_E2_lst, 'String', LST_2);
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
                set(gPPI_E2_lst, 'String', []);
                selection_2 = {};
                warning('All selected conditions have been removed');
            end

        end

        %% Function to launch help window for Selection of conditions
        function gPPI_H(~,~)

            % Creation of GUI window for Help description
            gPPI_H_W = figure('Name', 'gPPI: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.67 0.31 0.22 0.50],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off', 'WindowStyle', 'Modal');

            Data_1 = {'Suppose you have two separate sessions.','','Both sessions contains task regressors for', '“Cond A”, “Cond B” and “Errors”', '','If you are only interested in “Cond A” and “Cond B” comparison, the following conditions should be selected:',...
            '','1)  Cond A (Sess1)','2)  Cond B (Sess1)','3)  Cond A (Sess2)','4)  Cond B (Sess2)','','For all selected conditions of interest, the TMFC toolbox will create psycho-physiological (PPI) regressors. Thus, for each condition of interest, the generalized PPI (gPPI) model will contain two regressors: (1) psychological regressor and (2) PPI regressor.'...
            '','For trials of no interest (here, “Errors”), the gPPI model will contain only the psychological regressor.'};

            gPPI_W1 = uicontrol(gPPI_H_W,'Style','text','String',Data_1 ,'Units', 'normalized', 'Position', [0.05 0.12 0.89 0.85], 'HorizontalAlignment', 'left','backgroundcolor','w','fontunits','normalized', 'fontSize', 0.0301);
            gPPI_H_OK = uicontrol(gPPI_H_W,'Style','pushbutton','String', 'OK','Units', 'normalized', 'Position', [0.34 0.06 0.30 0.06]);%,'fontunits','normalized', 'fontSize', 0.35

            set(gPPI_H_OK, 'callback', @gPPI_H_close);
            movegui(gPPI_H_W,'center');

            function gPPI_H_close(~,~)
                close(gPPI_H_W);
            end
        end

       uiwait(gPPI_GUI);
       return;
    end


end


%%
% Function to create & generate gPPI conditions for selection via GUI interface
    function [cond_list] = generate_gPPI_conditions(SPM)
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

%%
% Function to perform intial sorting of gPPI conditions
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