function tmfc_results_simulation()

%% GUI Initialization
RES_GUI = figure('Name', 'TMFC: Results', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.45 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w','WindowStyle','modal');%,'Resize','off');%,'WindowStyle','modal');%,'CloseRequestFcn', @LSS_stable_Exit);
    
% Initializing Elements of the UI
RES_T1  = uicontrol(RES_GUI,'Style','text','String', 'TMFC Results Synopsis','Units', 'normalized', 'Position',[0.270 0.93 0.460 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w', 'FontWeight', 'bold');

% Pop up menu to select type of Test
RES_POP_1  = uicontrol(RES_GUI,'Style','popupmenu','String', {'Paired T - Test', 'One Sampled T - Test', 'Two Sampled T - Test'},'Units', 'normalized', 'Position',[0.045 0.87 0.91 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
 
% List boxes to show (.mat) file selection
RES_lst_0 = uicontrol(RES_GUI , 'Style', 'listbox', 'String', '','Max', 100,'Units', 'normalized', 'Position',[0.045 0.56 0.91 0.300],'fontunits','normalized', 'fontSize', 0.07,'visible','off');
RES_lst_1 = uicontrol(RES_GUI , 'Style', 'listbox', 'String', '','Max', 100,'Units', 'normalized', 'Position',[0.045 0.56 0.440 0.300],'fontunits','normalized', 'fontSize', 0.07);
RES_lst_2 = uicontrol(RES_GUI , 'Style', 'listbox', 'String', '','Max', 100,'Units', 'normalized', 'Position',[0.52 0.56 0.440 0.300],'fontunits','normalized', 'fontSize', 0.07);

%strcat(num2str(len_subs_A1(1))
% orange = [0.773, 0.353, 0.067]
% green = [0.219, 0.341, 0.137]
% Counter of subjects selected
RES_L0_CTR = uicontrol(RES_GUI, 'Style', 'text','String', '0 ROIs x 0 subjects','Units', 'normalized', 'Position',[0.295 0.51 0.44 0.04],'fontunits','normalized', 'fontSize', 0.57, 'HorizontalAlignment','center','backgroundcolor','w','ForegroundColor',[0.773, 0.353, 0.067],'visible', 'off');
RES_L1_CTR = uicontrol(RES_GUI, 'Style', 'text','String', '0 ROIs x 0 subjects','Units', 'normalized', 'Position',[0.045 0.51 0.44 0.04],'fontunits','normalized', 'fontSize', 0.57, 'HorizontalAlignment','center','backgroundcolor','w','ForegroundColor',[0.773, 0.353, 0.067]);
RES_L2_CTR = uicontrol(RES_GUI, 'Style', 'text','String', '0 ROIs x 0 subjects','Units', 'normalized', 'Position',[0.52 0.51 0.44 0.04],'fontunits','normalized', 'fontSize', 0.57, 'HorizontalAlignment','center','backgroundcolor','w','ForegroundColor',[0.773, 0.353, 0.067]);

% "Select & Remove" file buttons for each case
RES_L0_SEL = uicontrol(RES_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized','Position',[0.045 0.45 0.445 0.054],'fontunits','normalized', 'fontSize', 0.36, 'visible', 'off');
RES_L0_REM = uicontrol(RES_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized','Position',[0.52 0.45 0.445 0.054],'fontunits','normalized', 'fontSize', 0.36, 'visible', 'off');
RES_L1_SEL = uicontrol(RES_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized','Position',[0.045 0.45 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);
RES_L1_REM = uicontrol(RES_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized','Position',[0.275 0.45 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);
RES_L2_SEL = uicontrol(RES_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized','Position',[0.52 0.45 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);
RES_L2_REM = uicontrol(RES_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized','Position',[0.75 0.45 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);

% Boxes & Layout for Alpha & threshold values
RES_CONT = uipanel(RES_GUI,'Units', 'normalized','Position',[0.046 0.37 0.44 0.07],'HighLightColor',[0.78 0.78 0.78],'BorderType', 'line','BackgroundColor','w');
RES_CONT_txt  = uicontrol(RES_GUI,'Style','text','String', 'Contrast: ','Units', 'normalized', 'Position',[0.095 0.38 0.38 0.04],'fontunits','normalized', 'fontSize', 0.55, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_CONT_val  = uicontrol(RES_GUI,'Style','edit','String', '','Units', 'normalized', 'Position',[0.278 0.382 0.18 0.045],'fontunits','normalized', 'fontSize', 0.50);
RES_ALP = uipanel(RES_GUI,'Units', 'normalized','Position',[0.52 0.37 0.44 0.07],'HighLightColor',[0.78 0.78 0.78],'BorderType', 'line','BackgroundColor','w');
RES_ALP_txt  = uicontrol(RES_GUI,'Style','text','String', 'Alpha: ','Units', 'normalized', 'Position',[0.583 0.38 0.35 0.04],'fontunits','normalized', 'fontSize', 0.55, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_ALP_val  = uicontrol(RES_GUI,'Style','edit','String', '','Units', 'normalized', 'Position',[0.755 0.382 0.18 0.045],'fontunits','normalized', 'fontSize', 0.50);

% Type of Threshold selection Pop Up menu and conditional value
RES_THRES_TXT = uicontrol(RES_GUI,'Style','text','String', 'Threshold type: ','Units', 'normalized', 'Position',[0.098 0.298 0.38 0.04],'fontunits','normalized', 'fontSize', 0.58, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_THRES_POP = uicontrol(RES_GUI,'Style','popupmenu','String', {'Uncorrected (Parametric)', 'FDR (Parametric)', 'Uncorrected (Non-Parametric)','FDR (Non-Parametric)','NBS FWE(Non-Parametric)','NBS TFCE(Non-Parametric)'},'Units', 'normalized', 'Position',[0.358 0.295 0.6 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
RES_THRES_VAL_TXT = uicontrol(RES_GUI,'Style','text','String', 'Primary Threshold Value (Pval): ','Units', 'normalized', 'Position',[0.098 0.23 0.5 0.04],'fontunits','normalized', 'fontSize', 0.58, 'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
RES_THRES_VAL_UNI = uicontrol(RES_GUI,'Style','edit','String', '','Units', 'normalized', 'Position',[0.76 0.234 0.2 0.04],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w', 'enable', 'off');
RES_PERM_TXT = uicontrol(RES_GUI,'Style','text','String', 'Permutations: ','Units', 'normalized', 'Position',[0.098 0.165 0.38 0.04],'fontunits','normalized', 'fontSize', 0.58, 'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
RES_PERM_VAL = uicontrol(RES_GUI,'Style','edit','String', '','Units', 'normalized', 'Position',[0.76 0.169 0.2 0.04],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w','enable', 'off');

% The Almighty Run
RES_RUN = uicontrol(RES_GUI, 'Style', 'pushbutton', 'String', 'Run!','Units', 'normalized','Position',[0.4 0.05 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);

% Callback actions
set(RES_POP_1, 'callback', @test_type);
set(RES_THRES_POP, 'callback', @threshold_type);
set(RES_L0_SEL, 'callback', @action_subjects_S0);
set(RES_L1_SEL, 'callback', @action_subjects_S1);
set(RES_L2_SEL, 'callback', @action_subjects_S2);
set(RES_L0_REM, 'callback', @action_remove_0);
set(RES_L1_REM, 'callback', @action_remove_1);
set(RES_L2_REM, 'callback', @action_remove_2);
set(RES_lst_0, 'callback', @live_select_0)
set(RES_lst_1, 'callback', @live_select_1)
set(RES_lst_2, 'callback', @live_select_2)
set(RES_RUN, 'callback', @run);

M0 = {}; % variable to store the matrices for One Sampled T Test
M1 = {}; % variable to store the matrices set 1 Paired & Two sampled test
M2 = {}; % variable to store the matrices set 2 Paired & Two sampled test

% Variables to store present selection of matrices from list
selection_0 = '';
selection_1 = '';
selection_2 = '';


% Selection button for "One Sampled T-Test" 
function action_subjects_S0(~,~)
    
    % Primary case: First time selection of (,mat) files
    if isempty(M0)
        
        %Checking if there exist pre-selected (.mat) files
        
        M0 = selector();    % Select (.mat) files
        M0 = unique(M0);    % Remove duplicates

        % If (.mat) files has been selected, perform, multiple variable, dimension and ROI checks
        if ~isempty(M0)
            
            F1 = multi_check(M0);  % Check if (.mat) file consists of multiple variables
            
            % If there are no multiple variables (F1 = 0), then continue
            % with verification of Dimensionality
            if F1 ~= 1 

                % Check for consistent dimensions (2D vs 3D) accross all
                % selected files (Selection of 2D or 3D is based on the
                % first selected file)
                F2 = dimension_check(M0);

                % If the selected files are of consistent dimensions then
                % proceed
                if F2 ~= 1

                    % Check if the selected files have consistent ROIs
                    % (Internally for selection)
                    F3 = ROI_check(M0,1,[]);

                   % If all files have consistent dimensions, add files to
                   % main list for full usage
                   if F3 == 0 
                       len_files = size(M0);
                   else
                       % Raise warning ROI dimensions are NOT EQUAL 
                       M0 = {};
                       warning('The selected matrices have inconsistent ROI x ROI dimensions, please select again')
                   end
                   
                else
                    % Raise warning if 2D - 3D dimensions are NOT EQUAL 
                    M0 = {};
                    warning('The Selected matrics have inconsistent dimensions, Please select matrices with consistent dimensions');
                end
                
            else
                % Raise warning if file has MULTIPLE VARIABLES within
                M0 = {};
                warning('The .mat files selected consists of multiple variables. Please select .mat files with individual variables');
            end 
        end
        
        
        % Updating the GUI 
        if isempty(M0)
            % If all files selection was rejected during checks, reset GUI
            disp('No (.mat) file(s) selected');
            set(RES_L0_CTR, 'String', '0 ROIs x 0 subjects');
            set(RES_L0_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]);
        
        else
            % Show the number of (.mat) files selected & update GUI
            fprintf('Number of (.mat) files selected are: %d \n', len_files(1));
            set(RES_lst_0,'String', M0);
            set(RES_lst_0,'Value', []);

            % Update the ROI x ROI x Subjects counter under each case
            % Partial load the first file to update 
            matObj = matfile(M0{1,:});
            S = whos(matObj);
            dims = S.size;
            roi_sub = [];

            % Update ROI x Subjects, for 2D case (ROI x ROI):
            if length(dims) == 2
                M0_ss_size = size(M0);                  % Size of selected list
                roi_sub = [dims(1), M0_ss_size(1)];     % Store dimensions as ROI x Subjects
                set(RES_L0_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(RES_L0_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 

            elseif length(dims) == 3
            % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
                subs = 0;                               % variable to store size of subs
                for i = 1:length(M0)                    % loop accross all files
                    matObj = matfile(M0{i,:});          % Extract size of each variable per iteration
                    temp = whos(matObj);
                    temp_dim = temp.size;
                    subs = subs + temp.size(3);
                end
                
                roi_sub = [dims(1), subs];              % Store ROI and subjects lengths
                set(RES_L0_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(RES_L0_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI

            else
                % Unlikely event, if this occurs, then there is an issue
                % with the type of files uploaded (mostly, it may not be
                % 2D or 3D formats. 
                disp('You are sick, the files must be ROI x ROI x Subjects format & dimensions');
            end        
        end
 
    else
        
    % Secondary case: Post - intialization selection of (,mat) files
        
        %M0_copy = M0;
        M0_size = size(M0);         % Store existing size of files
        
        
        new_add = selector();       % Select new files via function
        
        % If new files are selected then proceed 
        if ~isempty(new_add)
            
            new_add = unique(new_add);          % Filter newly added files to remove duplicates
            size_new_add = size(new_add);       % Store size of the newly added files
            
            F_in_1 = multi_check(new_add);        % Check for multiple variables within selected files
            
            % Proceed if there are no multiple files present in selection
            if F_in_1 ~= 1                       
                
                % Check for consistent dimensions in the selected files
                F_in_2 = dimension_check(new_add);
                
                % Proceed if the files have consistent dimensions
                if F_in_2 ~= 1
                    
                    % Check for consistent ROI x ROI dimensions in the 
                    % newly selected files (Internally)
                    F_in_3a = ROI_check(new_add,1,[]);
                    
                    
                    % Proceed if the ROI x ROI files have consistent
                    % dimensions
                    if F_in_3a == 0
                    
                        % Check for consistent ROI x ROI dimensions between
                        % Primary Selection & New Selection
                        F_in_3b = ROI_check(M0,2,new_add);
                    
                        % If they are consistent proceed with concatination
                        if F_in_3b == 0

                            % if F_in_3b == 0 - execute the rest

                            % This block checks if the Primary selection of
                            % files have consistent dimensions with Secondary
                            % selection of files

                            % Extract dimensions of Primary selection of files
                            matObj = matfile(M0{1,:});
                            M0_S1 = whos(matObj);
                            s1 = M0_S1.size;

                            % Extract dimensions for Secondary selection of
                            % files
                            matObj = matfile(new_add{1,:});
                            M0_S2 = whos(matObj);
                            s2 = M0_S2.size;

                            % If Primary and Secondary Selections are equal
                            % then proceed

                            if length(s1) == length(s2)


                               M0 = vertcat(M0, new_add);                   % Concatenate files 
                               new_ones = size(unique(M0)) - M0_size(1);    % Calcualte newly added size (after removing duplicates ~if any)
                               M0 = unique(M0);

                               % If No newly added files then show message
                               if new_ones(1) == 0
                                   warning('Newly Selected .mat files are already present in the list, no new files added');

                               else

                               % If there exist New additions, then show message 
                                    fprintf('\nNumber of newly added (.mat) files: %d \n', new_ones(1));

                                    % Extract dimension
                                    matObj = matfile(M0{1,:});
                                    S = whos(matObj);
                                    dims = S.size;

                                    roi_sub = [];   % Variable to store dimensions for each case

                                    % Update ROI x Subjects, for 2D case (ROI x ROI):
                                    if length(dims) == 2
                                        M0_ss_size = size(M0);                  % Size of selected list
                                        roi_sub = [dims(1), M0_ss_size(1)];     % Store dimensions as ROI x Subjects
                                        set(RES_L0_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                                        set(RES_L0_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]);   % Update GUI 

                                    elseif length(dims) == 3
                                        % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
                                        subs = 0;                           % Variable to store size of subs
                                        for i = 1:length(M0)                % loop accross all files
                                            matObj = matfile(M0{i,:});      % Extract size of each variable per iteration
                                            temp = whos(matObj);
                                            temp_dim = temp.size;
                                            subs = subs + temp.size(3);
                                        end
                                        roi_sub = [dims(1), subs];          % Store ROI and subjects lengths
                                        set(RES_L0_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                                        set(RES_L0_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]);   % Update GUI
                                    else
                                         % Unlikely event, if this occurs, then there is an issue
                                         % with the type of files uploaded (mostly, it may not be
                                         % 2D or 3D formats. 
                                         disp('You are sick, the files must be ROI x ROI x Subjects format & dimensions');
                                    end     

                                    % Update Results GUI
                                   set(RES_lst_0,'String', M0);
                                   set(RES_lst_0,'Value', []);
                               end
                            else
                                warning('Select .mat files are of incompatible dimensions');
                            end
                        else
                            warning('Selected (.mat) file(s) have inconsistent ROI x ROI dimensions, please select (.mat) files with consistent dimensions');
                        end
                    else
                        warning('Selected (.mat) file(s) have inconsistent ROI x ROI dimensions, please select (.mat) files with consistent dimensions');
                    end
                    
                else
                    warning('Selected (.mat) file(s) are of inconsistent dimensions, please select (.mat) with consistent dimensions');
                end
            else
                warning('Selected (.mat) file(s) consists of multiple variables within, please select (.mat) files with individual variables');

            end
            
        else
           % If no new files are selected, show statement & no updates
           disp('No new (.mat) files added');
           
        end
    end
end

% Selection button for "Paired /Two sampled T-Test" - Set 1 Matrices
function action_subjects_S1(~,~)
    
    % Primary case: First time selection of (,mat) files
    if isempty(M1)
        
        %Checking if there exist pre-selected (.mat) files
        
        M1 = selector();    % Select (.mat) files
        M1 = unique(M1);    % Remove duplicates

        % If (.mat) files has been selected, perform, multiple variable, dimension and ROI checks
        if ~isempty(M1)
            
            F1 = multi_check(M1);  % Check if (.mat) file consists of multiple variables
            
            % If there are no multiple variables (F1 = 0), then continue
            % with verification of Dimensionality
            if F1 ~= 1 

                % Check for consistent dimensions (2D vs 3D) accross all
                % selected files (Selection of 2D or 3D is based on the
                % first selected file)
                F2 = dimension_check(M1);

                % If the selected files are of consistent dimensions then
                % proceed
                if F2 ~= 1

                    % Check if the selected files have consistent ROIs
                    % (Internally for selection)
                    F3 = ROI_check(M1,1,[]);

                   % If all files have consistent dimensions, add files to
                   % main list for full usage
                   if F3 == 0 
                       len_files = size(M1);
                   else
                       % Raise warning ROI dimensions are NOT EQUAL 
                       M1 = {};
                       warning('The selected matrices have inconsistent ROI x ROI dimensions, please select again')
                   end
                   
                else
                    % Raise warning if 2D - 3D dimensions are NOT EQUAL 
                    M1 = {};
                    warning('The Selected matrics have inconsistent dimensions, Please select matrices with consistent dimensions');
                end
                
            else
                % Raise warning if file has MULTIPLE VARIABLES within
                M1 = {};
                warning('The .mat files selected consists of multiple variables. Please select .mat files with individual variables');
            end 
        end
        
        
        % Updating the GUI 
        if isempty(M1)
            % If all files selection was rejected during checks, reset GUI
            disp('No (.mat) file(s) selected');
            set(RES_L1_CTR, 'String', '0 ROIs x 0 subjects');
            set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]);
        
        else
            % Show the number of (.mat) files selected & update GUI
            fprintf('Number of (.mat) files selected are: %d \n', len_files(1));
            set(RES_lst_1,'String', M1);
            set(RES_lst_1,'Value', []);

            % Update the ROI x ROI x Subjects counter under each case
            % Partial load the first file to update 
            matObj = matfile(M1{1,:});
            S = whos(matObj);
            dims = S.size;
            roi_sub = [];

            % Update ROI x Subjects, for 2D case (ROI x ROI):
            if length(dims) == 2
                M1_ss_size = size(M1);                  % Size of selected list
                roi_sub = [dims(1), M1_ss_size(1)];     % Store dimensions as ROI x Subjects
                set(RES_L1_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(RES_L1_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 

            elseif length(dims) == 3
            % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
                subs = 0;                               % variable to store size of subs
                for i = 1:length(M1)                    % loop accross all files
                    matObj = matfile(M1{i,:});          % Extract size of each variable per iteration
                    temp = whos(matObj);
                    temp_dim = temp.size;
                    subs = subs + temp.size(3);
                end
                
                roi_sub = [dims(1), subs];              % Store ROI and subjects lengths
                set(RES_L1_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(RES_L1_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI

            else
                % Unlikely event, if this occurs, then there is an issue
                % with the type of files uploaded (mostly, it may not be
                % 2D or 3D formats. 
                disp('You are sick, the files must be ROI x ROI x Subjects format & dimensions');
            end        
        end
 
    else
        
    % Secondary case: Post - intialization selection of (,mat) files
        
        %M1_copy = M1;
        M1_size = size(M1);         % Store existing size of files
        
        
        new_add = selector();       % Select new files via function
        
        % If new files are selected then proceed 
        if ~isempty(new_add)
            
            new_add = unique(new_add);          % Filter newly added files to remove duplicates
            size_new_add = size(new_add);       % Store size of the newly added files
            
            F_in_1 = multi_check(new_add);        % Check for multiple variables within selected files
            
            % Proceed if there are no multiple files present in selection
            if F_in_1 ~= 1                       
                
                % Check for consistent dimensions in the selected files
                F_in_2 = dimension_check(new_add);
                
                % Proceed if the files have consistent dimensions
                if F_in_2 ~= 1
                    
                    % Check for consistent ROI x ROI dimensions in the 
                    % newly selected files (Internally)
                    F_in_3a = ROI_check(new_add,1,[]);
                    
                    
                    % Proceed if the ROI x ROI files have consistent
                    % dimensions
                    if F_in_3a == 0
                    
                        % Check for consistent ROI x ROI dimensions between
                        % Primary Selection & New Selection
                        F_in_3b = ROI_check(M1,2,new_add);
                    
                        % If they are consistent proceed with concatination
                        if F_in_3b == 0

                            % if F_in_3b == 0 - execute the rest

                            % This block checks if the Primary selection of
                            % files have consistent dimensions with Secondary
                            % selection of files

                            % Extract dimensions of Primary selection of files
                            matObj = matfile(M1{1,:});
                            M1_S1 = whos(matObj);
                            s1 = M1_S1.size;

                            % Extract dimensions for Secondary selection of
                            % files
                            matObj = matfile(new_add{1,:});
                            M1_S2 = whos(matObj);
                            s2 = M1_S2.size;

                            % If Primary and Secondary Selections are equal
                            % then proceed

                            if length(s1) == length(s2)


                               M1 = vertcat(M1, new_add);                   % Concatenate files 
                               new_ones = size(unique(M1)) - M1_size(1);    % Calcualte newly added size (after removing duplicates ~if any)
                               M1 = unique(M1);

                               % If No newly added files then show message
                               if new_ones(1) == 0
                                   warning('Newly Selected .mat files are already present in the list, no new files added');

                               else

                               % If there exist New additions, then show message 
                                    fprintf('\nNumber of newly added (.mat) files: %d \n', new_ones(1));

                                    % Extract dimension
                                    matObj = matfile(M1{1,:});
                                    S = whos(matObj);
                                    dims = S.size;

                                    roi_sub = [];   % Variable to store dimensions for each case

                                    % Update ROI x Subjects, for 2D case (ROI x ROI):
                                    if length(dims) == 2
                                        M1_ss_size = size(M1);                  % Size of selected list
                                        roi_sub = [dims(1), M1_ss_size(1)];     % Store dimensions as ROI x Subjects
                                        set(RES_L1_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                                        set(RES_L1_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]);   % Update GUI 

                                    elseif length(dims) == 3
                                        % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
                                        subs = 0;                           % Variable to store size of subs
                                        for i = 1:length(M1)                % loop accross all files
                                            matObj = matfile(M1{i,:});      % Extract size of each variable per iteration
                                            temp = whos(matObj);
                                            temp_dim = temp.size;
                                            subs = subs + temp.size(3);
                                        end
                                        roi_sub = [dims(1), subs];          % Store ROI and subjects lengths
                                        set(RES_L1_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                                        set(RES_L1_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]);   % Update GUI
                                    else
                                         % Unlikely event, if this occurs, then there is an issue
                                         % with the type of files uploaded (mostly, it may not be
                                         % 2D or 3D formats. 
                                         disp('You are sick, the files must be ROI x ROI x Subjects format & dimensions');
                                    end     

                                    % Update Results GUI
                                   set(RES_lst_1,'String', M1);
                                   set(RES_lst_1,'Value', []);
                               end
                            else
                                warning('Select .mat files are of incompatible dimensions');
                            end
                        else
                            warning('Selected (.mat) file(s) have inconsistent ROI x ROI dimensions, please select (.mat) files with consistent dimensions');
                        end
                    else
                        warning('Selected (.mat) file(s) have inconsistent ROI x ROI dimensions, please select (.mat) files with consistent dimensions');
                    end
                    
                else
                    warning('Selected (.mat) file(s) are of inconsistent dimensions, please select (.mat) with consistent dimensions');
                end
            else
                warning('Selected (.mat) file(s) consists of multiple variables within, please select (.mat) files with individual variables');

            end
            
        else
           % If no new files are selected, show statement & no updates
           disp('No new (.mat) files added');
           
        end
    end
end

% Selection button for "Paired /Two sampled T-Test" - Set 2 Matrices
function action_subjects_S2(~,~)
    
    % Primary case: First time selection of (,mat) files
    if isempty(M2)
        
        %Checking if there exist pre-selected (.mat) files
        
        M2 = selector();    % Select (.mat) files
        M2 = unique(M2);    % Remove duplicates

        % If (.mat) files has been selected, perform, multiple variable, dimension and ROI checks
        if ~isempty(M2)
            
            F1 = multi_check(M2);  % Check if (.mat) file consists of multiple variables
            
            % If there are no multiple variables (F1 = 0), then continue
            % with verification of Dimensionality
            if F1 ~= 1 

                % Check for consistent dimensions (2D vs 3D) accross all
                % selected files (Selection of 2D or 3D is based on the
                % first selected file)
                F2 = dimension_check(M2);

                % If the selected files are of consistent dimensions then
                % proceed
                if F2 ~= 1

                    % Check if the selected files have consistent ROIs
                    % (Internally for selection)
                    F3 = ROI_check(M2,1,[]);

                   % If all files have consistent dimensions, add files to
                   % main list for full usage
                   if F3 == 0 
                       len_files = size(M2);
                   else
                       % Raise warning ROI dimensions are NOT EQUAL 
                       M2 = {};
                       warning('The selected matrices have inconsistent ROI x ROI dimensions, please select again')
                   end
                   
                else
                    % Raise warning if 2D - 3D dimensions are NOT EQUAL 
                    M2 = {};
                    warning('The Selected matrics have inconsistent dimensions, Please select matrices with consistent dimensions');
                end
                
            else
                % Raise warning if file has MULTIPLE VARIABLES within
                M2 = {};
                warning('The .mat files selected consists of multiple variables. Please select .mat files with individual variables');
            end 
        end
        
        
        % Updating the GUI 
        if isempty(M2)
            % If all files selection was rejected during checks, reset GUI
            disp('No (.mat) file(s) selected');
            set(RES_L2_CTR, 'String', '0 ROIs x 0 subjects');
            set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]);
        
        else
            % Show the number of (.mat) files selected & update GUI
            fprintf('Number of (.mat) files selected are: %d \n', len_files(1));
            set(RES_lst_2,'String', M2);
            set(RES_lst_2,'Value', []);

            % Update the ROI x ROI x Subjects counter under each case
            % Partial load the first file to update 
            matObj = matfile(M2{1,:});
            S = whos(matObj);
            dims = S.size;
            roi_sub = [];

            % Update ROI x Subjects, for 2D case (ROI x ROI):
            if length(dims) == 2
                M2_ss_size = size(M2);                  % Size of selected list
                roi_sub = [dims(1), M2_ss_size(1)];     % Store dimensions as ROI x Subjects
                set(RES_L2_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(RES_L2_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 

            elseif length(dims) == 3
            % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
                subs = 0;                               % variable to store size of subs
                for i = 1:length(M2)                    % loop accross all files
                    matObj = matfile(M2{i,:});          % Extract size of each variable per iteration
                    temp = whos(matObj);
                    temp_dim = temp.size;
                    subs = subs + temp.size(3);
                end
                
                roi_sub = [dims(1), subs];              % Store ROI and subjects lengths
                set(RES_L2_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(RES_L2_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI

            else
                % Unlikely event, if this occurs, then there is an issue
                % with the type of files uploaded (mostly, it may not be
                % 2D or 3D formats. 
                disp('You are sick, the files must be ROI x ROI x Subjects format & dimensions');
            end        
        end
 
    else
        
    % Secondary case: Post - intialization selection of (,mat) files
        
        %M2_copy = M2;
        M2_size = size(M2);         % Store existing size of files
        
        
        new_add = selector();       % Select new files via function
        
        % If new files are selected then proceed 
        if ~isempty(new_add)
            
            new_add = unique(new_add);          % Filter newly added files to remove duplicates
            size_new_add = size(new_add);       % Store size of the newly added files
            
            F_in_1 = multi_check(new_add);        % Check for multiple variables within selected files
            
            % Proceed if there are no multiple files present in selection
            if F_in_1 ~= 1                       
                
                % Check for consistent dimensions in the selected files
                F_in_2 = dimension_check(new_add);
                
                % Proceed if the files have consistent dimensions
                if F_in_2 ~= 1
                    
                    % Check for consistent ROI x ROI dimensions in the 
                    % newly selected files (Internally)
                    F_in_3a = ROI_check(new_add,1,[]);
                    
                    
                    % Proceed if the ROI x ROI files have consistent
                    % dimensions
                    if F_in_3a == 0
                    
                        % Check for consistent ROI x ROI dimensions between
                        % Primary Selection & New Selection
                        F_in_3b = ROI_check(M2,2,new_add);
                    
                        % If they are consistent proceed with concatination
                        if F_in_3b == 0

                            % if F_in_3b == 0 - execute the rest

                            % This block checks if the Primary selection of
                            % files have consistent dimensions with Secondary
                            % selection of files

                            % Extract dimensions of Primary selection of files
                            matObj = matfile(M2{1,:});
                            M2_S1 = whos(matObj);
                            s1 = M2_S1.size;

                            % Extract dimensions for Secondary selection of
                            % files
                            matObj = matfile(new_add{1,:});
                            M2_S2 = whos(matObj);
                            s2 = M2_S2.size;

                            % If Primary and Secondary Selections are equal
                            % then proceed

                            if length(s1) == length(s2)


                               M2 = vertcat(M2, new_add);                   % Concatenate files 
                               new_ones = size(unique(M2)) - M2_size(1);    % Calcualte newly added size (after removing duplicates ~if any)
                               M2 = unique(M2);

                               % If No newly added files then show message
                               if new_ones(1) == 0
                                   warning('Newly Selected .mat files are already present in the list, no new files added');

                               else

                               % If there exist New additions, then show message 
                                    fprintf('\nNumber of newly added (.mat) files: %d \n', new_ones(1));

                                    % Extract dimension
                                    matObj = matfile(M2{1,:});
                                    S = whos(matObj);
                                    dims = S.size;

                                    roi_sub = [];   % Variable to store dimensions for each case

                                    % Update ROI x Subjects, for 2D case (ROI x ROI):
                                    if length(dims) == 2
                                        M2_ss_size = size(M2);                  % Size of selected list
                                        roi_sub = [dims(1), M2_ss_size(1)];     % Store dimensions as ROI x Subjects
                                        set(RES_L2_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                                        set(RES_L2_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]);   % Update GUI 

                                    elseif length(dims) == 3
                                        % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
                                        subs = 0;                           % Variable to store size of subs
                                        for i = 1:length(M2)                % loop accross all files
                                            matObj = matfile(M2{i,:});      % Extract size of each variable per iteration
                                            temp = whos(matObj);
                                            temp_dim = temp.size;
                                            subs = subs + temp.size(3);
                                        end
                                        roi_sub = [dims(1), subs];          % Store ROI and subjects lengths
                                        set(RES_L2_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                                        set(RES_L2_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]);   % Update GUI
                                    else
                                         % Unlikely event, if this occurs, then there is an issue
                                         % with the type of files uploaded (mostly, it may not be
                                         % 2D or 3D formats. 
                                         disp('You are sick, the files must be ROI x ROI x Subjects format & dimensions');
                                    end     

                                    % Update Results GUI
                                   set(RES_lst_2,'String', M2);
                                   set(RES_lst_2,'Value', []);
                               end
                            else
                                warning('Select .mat files are of incompatible dimensions');
                            end
                        else
                            warning('Selected (.mat) file(s) have inconsistent ROI x ROI dimensions, please select (.mat) files with consistent dimensions');
                        end
                    else
                        warning('Selected (.mat) file(s) have inconsistent ROI x ROI dimensions, please select (.mat) files with consistent dimensions');
                    end
                    
                else
                    warning('Selected (.mat) file(s) are of inconsistent dimensions, please select (.mat) with consistent dimensions');
                end
            else
                warning('Selected (.mat) file(s) consists of multiple variables within, please select (.mat) files with individual variables');

            end
            
        else
           % If no new files are selected, show statement & no updates
           disp('No new (.mat) files added');
           
        end
    end
end


% Remove button for "One Sampled T-Test" 
function action_remove_0(~,~)
   if isempty(selection_0) && isempty(M0)
       warning('There are no files present to remove, please select .mat files to perform Results analysis');
   elseif isempty(selection_0) && ~isempty(M0)
        warning('There are no selected matrices to remove from the list, please select matrices once again');
   else
       M0(selection_0,:) = [];
       holder = size(selection_0);
       fprintf('Number of (.mat) files removed are: %d \n', holder(2));
              
       set(RES_lst_0,'Value', []);
       set(RES_lst_0,'String', M0);
       selection_0 = {};
       
       if ~isempty(M0)           
            % Update the ROI x ROI x Subjects counter under each case
            % Partial load the first file to update 
            matObj = matfile(M0{1,:});
            S = whos(matObj);
            dims = S.size;
            roi_sub = [];
           
            % Update ROI x Subjects, for 2D case (ROI x ROI):
            if length(dims) == 2
                M0_ss_size = size(M0);                  % Size of selected list
                roi_sub = [dims(1), M0_ss_size(1)];     % Store dimensions as ROI x Subjects
                set(RES_L0_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(RES_L0_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 

            elseif length(dims) == 3
            % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
                subs = 0;                               % variable to store size of subs
                for i = 1:length(M0)                    % loop accross all files
                    matObj = matfile(M0{i,:});          % Extract size of each variable per iteration
                    temp = whos(matObj);
                    temp_dim = temp.size;
                    subs = subs + temp.size(3);
                end

                roi_sub = [dims(1), subs];              % Store ROI and subjects lengths
                set(RES_L0_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(RES_L0_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI

            else
                % Unlikely event, if this occurs, then there is an issue
                % with the type of files uploaded (mostly, it may not be
                % 2D or 3D formats. 
                disp('You are sick, the files must be ROI x ROI x Subjects format & dimensions');
            end   
       end
   end
  if isempty(M0)
        set(RES_L0_CTR, 'String', '0 ROIs x 0 subjects');
        set(RES_L0_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]);
   end
   
   
end

% Remove button for "Paired /Two sampled T-Test" - Set 1 Matrices
function action_remove_1(~,~)
   if isempty(selection_1) && isempty(M1)
       warning('There are no files present to remove, please select .mat files to perform Results analysis');
   elseif isempty(selection_1) && ~isempty(M1)
        warning('There are no selected files to remove, please select files once again');
   else
       M1(selection_1,:) = [];
       holder = size(selection_1);
       fprintf('Number of (.mat) files removed are: %d \n', holder(2));
       
       set(RES_lst_1,'Value',[]);    
       set(RES_lst_1,'String', M1);
       selection_1 = {};
              
       if ~isempty(M1)
        % Update the ROI x ROI x Subjects counter under each case
        % Partial load the first file to update 
        matObj = matfile(M1{1,:});
        S = whos(matObj);
        dims = S.size;
        roi_sub = [];

        % Update ROI x Subjects, for 2D case (ROI x ROI):
        if length(dims) == 2
            M1_ss_size = size(M1);                  % Size of selected list
            roi_sub = [dims(1), M1_ss_size(1)];     % Store dimensions as ROI x Subjects
            set(RES_L1_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
            set(RES_L1_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 

        elseif length(dims) == 3
        % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
            subs = 0;                               % variable to store size of subs
            for i = 1:length(M1)                    % loop accross all files
                matObj = matfile(M1{i,:});          % Extract size of each variable per iteration
                temp = whos(matObj);
                temp_dim = temp.size;
                subs = subs + temp.size(3);
            end

            roi_sub = [dims(1), subs];              % Store ROI and subjects lengths
            set(RES_L1_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
            set(RES_L1_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI

        else
            % Unlikely event, if this occurs, then there is an issue
            % with the type of files uploaded (mostly, it may not be
            % 2D or 3D formats. 
            disp('You are sick, the files must be ROI x ROI x Subjects format & dimensions');
        end              
       end
   end
   
   if isempty(M1)
        set(RES_L1_CTR, 'String', '0 ROIs x 0 subjects');
        set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]);
   end
   
end

% Remove button for "Paired /Two sampled T-Test" - Set 2 Matrices
function action_remove_2(~,~)
   if isempty(selection_2) && isempty(M2)
       warning('There are no files present to remove, please select .mat files to perform Results analysis');
   elseif isempty(selection_2) && ~isempty(M2)
        warning('There are no selected matrices to remove from the list, please select matrices once again');
   else
       M2(selection_2,:) = [];   
       holder = size(selection_2);
       fprintf('Number of (.mat) files removed are: %d \n', holder(2));
       
       set(RES_lst_2, 'Value', []);
       set(RES_lst_2,'String', M2);
       selection_2 = {};
       
       
       if ~isempty(M2)
           % Update the ROI x ROI x Subjects counter under each case
        % Partial load the first file to update 
        matObj = matfile(M2{1,:});
        S = whos(matObj);
        dims = S.size;
        roi_sub = [];

        % Update ROI x Subjects, for 2D case (ROI x ROI):
        if length(dims) == 2
            M2_ss_size = size(M2);                  % Size of selected list
            roi_sub = [dims(1), M2_ss_size(1)];     % Store dimensions as ROI x Subjects
            set(RES_L2_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
            set(RES_L2_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 

        elseif length(dims) == 3
        % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
            subs = 0;                               % variable to store size of subs
            for i = 1:length(M2)                    % loop accross all files
                matObj = matfile(M2{i,:});          % Extract size of each variable per iteration
                temp = whos(matObj);
                temp_dim = temp.size;
                subs = subs + temp.size(3);
            end

            roi_sub = [dims(1), subs];              % Store ROI and subjects lengths
            set(RES_L2_CTR, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
            set(RES_L2_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI

        else
            % Unlikely event, if this occurs, then there is an issue
            % with the type of files uploaded (mostly, it may not be
            % 2D or 3D formats. 
            disp('You are sick, the files must be ROI x ROI x Subjects format & dimensions');
        end 
       end
   end
   
   if isempty(M2)
        set(RES_L2_CTR, 'String', '0 ROIs x 0 subjects');
        set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]);
   end
   
end


% Variable to store Live selection from lists
function live_select_0(~,~)
    index = get(RES_lst_0, 'Value');% Retrieves the users selection LIVE
    selection_0 = index;                % Variable for full selection
end
function live_select_1(~,~)
    index = get(RES_lst_1, 'Value');% Retrieves the users selection LIVE
    selection_1 = index;                % Variable for full selection
    %internal_freeze(1);
end
function live_select_2(~,~)
    index = get(RES_lst_2, 'Value');% Retrieves the users selection LIVE
    selection_2 = index;                % Variable for full selection
end


% Function to choose & Configure GUI based on Test Type 
function test_type(~,~)
    
    % Extract the current Test mode selected by user
    contender = (RES_POP_1.String{RES_POP_1.Value});

    % Action relative to test type
    if strcmp(contender, 'Paired T - Test')
        
        % If Paired T Test is selected
        disp('Selected Test Type: Paired T - Test');
        
        % Reset GUI 
        set([RES_lst_0,RES_L0_CTR],'visible', 'off');        
        set([RES_lst_1,RES_lst_2,RES_L1_CTR,RES_L2_CTR],'visible', 'on');
        set([RES_L0_SEL,RES_L0_REM],'visible', 'off');
        set([RES_L1_SEL,RES_L1_REM,RES_L2_SEL,RES_L2_REM],'visible', 'on');               
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'String', '0 ROIs x 0 subjects');
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'ForegroundColor',[0.773, 0.353, 0.067]);
        set([RES_CONT_val, RES_ALP_val], 'String', []);
        set([RES_PERM_VAL, RES_THRES_VAL_UNI], 'String', []);

        % Reset Variables 
        M0 = {};
        M1 = {};
        M2 = {};
        selection_0 = '';
        selection_1 = '';
        selection_2 = '';
        set(RES_lst_0,'String', M0);
        set(RES_lst_0,'Value', []);
        set(RES_lst_1,'String', M1);
        set(RES_lst_1,'Value', []);
        set(RES_lst_2,'String', M2);
        set(RES_lst_2,'Value', []);
        
    elseif strcmp(contender, 'One Sampled T - Test')
        
        % If One Sampled T Test is selected
        disp('Selected Test Type: One Sampled T - Test');
        
        % Reset GUI
        set([RES_lst_0,RES_L0_CTR],'visible', 'on');        
        set([RES_L0_SEL,RES_L0_REM],'visible', 'on');
        set([RES_lst_1,RES_lst_2,RES_L1_CTR,RES_L2_CTR],'visible', 'off');
        set([RES_L1_SEL,RES_L1_REM,RES_L2_SEL,RES_L2_REM],'visible', 'off');
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'String', '0 ROIs x 0 subjects');
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'ForegroundColor',[0.773, 0.353, 0.067]);
        set([RES_CONT_val, RES_ALP_val], 'String', []);
        set([RES_PERM_VAL, RES_THRES_VAL_UNI], 'String', []);

        %  Reset Varaibles
        M0 = {};
        M1 = {};
        M2 = {};
        selection_0 = '';
        selection_1 = '';
        selection_2 = '';
        set(RES_lst_0,'String', M0);
        set(RES_lst_0,'Value', []);
        set(RES_lst_1,'String', M1);
        set(RES_lst_1,'Value', []);
        set(RES_lst_2,'String', M2);
        set(RES_lst_2,'Value', []);
                
    elseif strcmp(contender, 'Two Sampled T - Test')
        
        % If Two sampled T Test is selected
        disp('Selected Test Type: Two Sampled T - Test');
        
        % Reset GUI 
        set([RES_lst_0,RES_L0_CTR],'visible', 'off');        
        set([RES_lst_1,RES_lst_2,RES_L1_CTR,RES_L2_CTR],'visible', 'on');
        set([RES_L0_SEL,RES_L0_REM],'visible', 'off');
        set([RES_L1_SEL,RES_L1_REM,RES_L2_SEL,RES_L2_REM],'visible', 'on');               
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'String', '0 ROIs x 0 subjects');
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'ForegroundColor',[0.773, 0.353, 0.067]);
        set([RES_CONT_val, RES_ALP_val], 'String', []);
        set([RES_PERM_VAL, RES_THRES_VAL_UNI], 'String', []);
        
        % Reset Variables
        M0 = {};
        M1 = {};
        M2 = {};
        selection_0 = '';
        selection_1 = '';
        selection_2 = '';
        set(RES_lst_0,'String', M0);
        set(RES_lst_0,'Value', []);
        set(RES_lst_1,'String', M1);
        set(RES_lst_1,'Value', []);
        set(RES_lst_2,'String', M2);
        set(RES_lst_2,'Value', []);

    end    
end

% Type of Parameter
function threshold_type(~,~)
    
    approach = (RES_THRES_POP.String{RES_THRES_POP.Value});
    
    if strcmp(approach, 'Uncorrected (Parametric)') || strcmp(approach, 'FDR (Parametric)')
        set(RES_PERM_TXT, 'enable', 'off');
        set(RES_PERM_VAL, 'enable', 'off');
        set(RES_PERM_VAL, 'String', []);
    elseif strcmp(approach, 'Uncorrected (Non-Parametric)') || strcmp(approach, 'FDR (Non-Parametric)') || strcmp(approach, 'NBS FWE(Non-Parametric)') || strcmp(approach, 'NBS TFCE(Non-Parametric)') 
        set(RES_PERM_TXT, 'enable', 'on');
        set(RES_PERM_VAL, 'enable', 'on');
        set(RES_PERM_VAL, 'String', []);
    end
    
    if strcmp(approach, 'Uncorrected (Parametric)') || strcmp(approach, 'FDR (Parametric)') || strcmp(approach, 'Uncorrected (Non-Parametric)') || strcmp(approach, 'FDR (Non-Parametric)')
        set(RES_THRES_VAL_TXT, 'enable', 'off');
        set(RES_THRES_VAL_UNI, 'enable', 'off');
        set(RES_THRES_VAL_UNI, 'String', []);
    elseif strcmp(approach, 'NBS FWE(Non-Parametric)') || strcmp(approach, 'NBS TFCE(Non-Parametric)') 
        set(RES_THRES_VAL_TXT, 'enable', 'on');
        set(RES_THRES_VAL_UNI, 'enable', 'on');
        set(RES_THRES_VAL_UNI, 'String', []);
    end
    
    
end


% Running function
function run(~,~)

    G1 = (RES_POP_1.String{RES_POP_1.Value}); % Type of Test - paried, one , two 
    

    if strcmp(G1, 'Paired T - Test')          
    
        if ~isempty(M1) && ~isempty(M2)
        
             % ROI size calculation for Set 1 
            matObj = matfile(M1{1,:});
            S1 = whos(matObj);
            dims_L1 = S1.size;

            % ROI size calculation for Set 1 
            matObj = matfile(M2{1,:});
            S2 = whos(matObj);
            dims_L2 = S2.size;

            if dims_L1(1) == dims_L2(1) && dims_L1(2) == dims_L2(2)

                % Compare the number of subjects across values

                if length(dims_L1) == 2 && length(dims_L2) == 2
                    if length(M1) == length(M2)
                        % continue with contrast and alpha
                        %disp('sucess');
                        CA_0 = CA_controller();
                        if CA_0 == 1
                            TP_0 = TP_check();
                            if TP_0 == 1
                                disp('continue with computation');
                            end
                        end
                    else
                        warning('The number of selected (.mat) files are inconsistent to perform Paired T Test \n Matrice(s) List 1: %d \n Matrice(s) List 2: %d \n, please select consistent number of files', length(M1), length(M2));
                        set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                        set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                    end

                elseif length(dims_L1) == 2 && length(dims_L2) == 3
                    if length(M1) == dims_L2(3)
                        %disp('sucess');
                        CA_0 = CA_controller();
                        if CA_0 == 1
                            TP_0 = TP_check();
                            if TP_0 == 1
                                disp('continue with computation');
                            end
                        end
                    else
                        warning('The number of selected (.mat) files are inconsistent to perform Paired T Test \n Matrice(s) List 1: %d \n Matrice(s) List 2: %d \n, please select consistent number of files', length(M1), dims_L2(3));
                        set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                        set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                    end

                elseif length(dims_L1) == 3 && length(dims_L2) == 2
                    if dims_L1(3) == length(M2)
                        %disp('sucess');
                        CA_0 = CA_controller();
                        if CA_0 == 1
                            TP_0 = TP_check();
                            if TP_0 == 1
                                disp('continue with computation');
                            end
                        end
                    else
                        warning('The number of selected (.mat) files are inconsistent to perform Paired T Test \n Matrice(s) List 1: %d \n Matrice(s) List 2: %d \n, please select consistent number of files', dims_L1(3), length(M2));
                        set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                        set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                    end

                elseif length(dims_L1) == 3 && length(dims_L2) == 3
                    if dims_L1(3) == dims_L2(3)
                        %disp('sucess');
                        CA_0 = CA_controller();
                        if CA_0 == 1
                            TP_0 = TP_check();
                            if TP_0 == 1
                                disp('continue with computation');
                            end
                        end
                    else
                        warning('The number of selected (.mat) files are inconsistent to perform Paired T Test \n Matrice(s) List 1: %d \n Matrice(s) List 2: %d \n, please select consistent number of files', dims_L1(3), dims_L2(3));
                        set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                        set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                    end

                else 
                    warning('damn error');
                end

            else
               warning('The number of ROI x ROIs between the selections are inconsistent, please select matrices with consistent ROIs');
               set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
               set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 

            end

        elseif ~isempty(M1) && isempty(M2)
            warning('Please select SECOND set of Matrices to perform Paired T - Test result evaluation');

        elseif isempty(M1) && ~isempty(M2)
            warning('Please select FIRST set of Matrices to perform Paired T - Test result evaluation');
            
        else
            warning('Please select matrices files to perform Paired T - Test result evaulation');
        end

    
    elseif strcmp(G1, 'One Sampled T - Test')
        
        if ~isempty(M0)
            
            CA_1 = CA_controller();
            if CA_1 == 1
                TP_1 = TP_check();
                if TP_1 == 1
                    disp('continue with computation');
                end
            end
            
        else
            warning('Please select matrices files to perform One Sampled T - Test result evaulation');
        end
        

    elseif strcmp(G1, 'Two Sampled T - Test')

        if ~isempty(M1) && ~isempty(M2)
        
             % ROI size calculation for Set 1 
            matObj = matfile(M1{1,:});
            S1 = whos(matObj);
            dims_L1 = S1.size;

            % ROI size calculation for Set 1 
            matObj = matfile(M2{1,:});
            S2 = whos(matObj);
            dims_L2 = S2.size;

            if dims_L1(1) == dims_L2(1) && dims_L1(2) == dims_L2(2)
                disp('Continue with contrast and shit');
                CA_2 = CA_controller();
                if CA_2 == 1
                    TP_2 = TP_check();
                    if TP_2 == 1
                        disp('continue with computation');
                    end
                end
                
                
            else
               warning('The number of ROI x ROIs between the selections are inconsistent, please select matrices with consistent ROIs');
               set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
               set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
            end

        elseif ~isempty(M1) && isempty(M2)
            warning('Please select SECOND set of Matrices to perform Paired T - Test result evaluation');

        elseif isempty(M1) && ~isempty(M2)
            warning('Please select FIRST set of Matrices to perform Paired T - Test result evaluation');
            
        else
            warning('Please select matrices files to perform Paired T - Test result evaulation');
        end
        
    else
        warning('goddamn error');
    end
    

end


function flag = CA_controller(~,~)
        
    flag = 0;
    G1 = (RES_POP_1.String{RES_POP_1.Value}); % Type of Test - paried, one , two 
    G2 = str2num(RES_CONT_val.String);        % Contrast
    G3 = str2double(RES_ALP_val.String);      % Alpha   
        
     if isempty(G2)
         warning('Please enter numeric values for contrasts');
     else
         if strcmp(G1, 'Paired T - Test') || strcmp(G1, 'Two Sampled T - Test')
             if length(G2) < 2
                 warning('Please enter TWO contrast values for computation');
             elseif length(G2) > 2
                 warning('Number of Contrast values cannot be greater than TWO, Please re-enter contrast values for computation');
             else
                 fprintf('\nContrast values [%d , %d] accepted for computation\n',G2(1, 1), G2(1,2));
                 
                 % CONTD with Alpha verification
                  if isnan(G3)
                     warning('Please enter a numeric Alpha value for computation');
                  else
                    if G3 > 1 || G3 < 0
                        warning('Please re-enter Alpha value between (0.0, 1.0]');
                    else
                        fprintf('\nAlpha value of [%d] is accepted for computation\n', G3);
                        flag = 1;
                    end
                 end
            end
        elseif strcmp(G1, 'One Sampled T - Test')
            if length(G2) >=2
                warning('Number of Contrast values cannot exceed ONE, Please re-enter contrast value for computation');
            else
                fprintf('\nContrast values [%d] accepted for computation\n',G2(1,1));
                
                % CONTD with Alpha verification
                 if isnan(G3)
                    warning('Please enter Alpha value for computation');
                 else
                    if (G3 > 1) || (G3 < 0)
                        warning('Please re-enter Alpha value between (0.0, 1.0]');
                    else
                        fprintf('\nAlpha value of [%d] is accepted for computation', G3);
                        flag = 1;
                    end
                 end
                
            end
        end
    end

end 


function flag = TP_check(~,~)

    flag = 0;
    approach = (RES_THRES_POP.String{RES_THRES_POP.Value});

     if strcmp(approach, 'Uncorrected (Non-Parametric)') || strcmp(approach, 'FDR (Non-Parametric)') 
         % check if permutations is a number and not a floating point value
         P_1 = str2num(RES_PERM_VAL.String);
         if ~isempty(P_1) && P_1 > 0
             flag = 1;
         elseif P_1 <= 0
             warning('Please enter a Postive numeric value for Number of Permutations');
         else
             warning('Please enter a numeric value for Number of Permutations');
         end         
         
     elseif strcmp(approach, 'NBS FWE(Non-Parametric)') || strcmp(approach, 'NBS TFCE(Non-Parametric)') 
         P_1 = str2num(RES_PERM_VAL.String);
         P_2 = str2double(RES_THRES_VAL_UNI.String);
         if ~isnan(P_2) && P_2 > 0 && P_2 <=1.0
             if ~isempty(P_1)                
                 flag = 1;
             else
                warning('Please enter a numeric value for Number of Permutations');
             end
         elseif P_2 <= 0 || P_2 > 1.0
             warning('Please enter a Primary Threshold value between (0.0, 1.0] for computation');
         else
             warning('Please enter a Primary Threshold value for computation');
         end       
         
     end

end


end
%%
% Function to select (.mat) files from the user via spm_select
function list_sel = selector(~,~)
    
    files = spm_select(inf,'.mat','Select matrices for computation',{},pwd,'..');
    
    list_sel = {};
    len_files = size(files);
    
    for i = 1:len_files(1)
        list_sel = vertcat(list_sel, files(i,:));
    end
    
    list_sel = strtrim(list_sel); % Remove blank spaces
end
%%
% Function to check if the selecte (.mat) files consists of multiple
% variables - Returns Binary Flag where, 
% 0 = no multiple variables in selected (.mat) files 
% 1 = Multiple variables EXIST in selected (.mat) files 
function flag = multi_check(D)
    
    main_size = size(D);    % Store size
    holder = [];            % variable to store list of multiple vars
    j = 1;                  % Counter the number of files present
    flag = 0;               % Binary Flag to indicate status of multiple vars
    
    % Loop to iterate through all possible (.mat) files 
    for i = 1:main_size(1)
        
        var = who('-file', D{i,:});   % Listing the variable into temp Workspace - Cell Datatype
        %var = who('-file', D(i,:));  % Listing the variable into temp Workspace - Standalone Datatype
        A = size(var);
        
        % If there exists files with multiple variables within, then disp
        if A(1) > 1
            fprintf('MULTIPLE VARIABLES in the file :%s \n', D{i,:})
            holder(j) = i;
            j = j+1;
            flag = 1;
        end        
    end
end
%%
% Function to check selected files are of same dimension or not
% i.e. 2D = ROI x ROI 
% i.e. 3D = ROI x ROI x Subjects

% The selection of 2D or 3D is based on the first selected file i.e. if the 
% first file is of 2D dimensions then the code will check if all remaining 
% files are of 2D dimensions else it will not select the files.

% Similarly if a 3D file is selected as the first file, then it will check 
% if all files are in 3D format. 

% Function returns Binary Flag 
% if flag = 1, selected files HAVE INCONSISTENT dimensions
% if flag = 0, selected files have CONSISTENT dimensions
function flag = dimension_check(B)

    j = 1;              % Counter to store number of files 
    holder = [];        % variable to store file addresses
    sizer = size(B);    % Size of input list of files
    flag = 0;           % Final Flag to indicate accpet or reject dimension check
    
    % Run the loop for given list of selected files
    for i = 1:sizer(1)
        
        % Intializing the comparison format (2D or 3D)
        % The file to compare against the rest of the file
        if i == 1
            
            % Format to load OBJECT parts of the file without data
            matObj = matfile(B{1,:});
            S = whos(matObj);           % Get characteristics of the data
            s1 = S.size;                % Extract Size
        else
            
        % For all other iterations, directly extract the dimension of files
            
            % Extraction of dimension of the variables from (.mat) files
            matObj = matfile(B{i,:});
            S = whos(matObj);
            s2 = S.size;
            
            
        % Checking if the dimensions of FIRST file is same against the rest
            if length(s1) ~= length(s2)
                
                % Print the Dimension & Path to the files that are inconsistent
                fprintf('\n The Dimensions of following files are not equal, please re-select files with consistent dimensions:')
                fprintf('\nFile 1: %s', B{1,:});
                fprintf('\nDimensions: %s ', num2str(s1));
                
                fprintf('\nFile %d: %s has been excluded from the selection',i, B{i,:});
                fprintf('\nDimensions: %s \n', num2str(s2));
                holder(j) = i;
                j = j+1;   
                flag = 1;                
            end            
        end
    end
end

%% 
% Function to check if the selected files have consistent & same ROIs 
% The function works EXCLUSIVELY for either 2D or 3D dimensional files 
% The function checks if the files have consistent ROI x ROIs based on the
% ROI of the first file (i.e. if the first file has 100*100, then it will
% compare the same against the rest of the files and so on) 
%
% This function can only be used after removing files with Multiple
% variables via (multi_check()) and dimensional checks via
% (dimensional_check) functions. 

% The function returns a flag indicating 
% flag = 1 : files have INCONSISTENT ROI x ROI dimensions
% flag = 0 : files have CONSISTENT ROI x ROI dimensions

% C = source list of files - Primary Selection 
% ralpher = case (1) or (2) 
%  Case 1 = Verification if any list of given files have consistent ROIs
%  Case 2 = Comparison of existing list of files vs new list of files
% new_files = new list of files to add to the Primary selection

function flag = ROI_check(C, ralpher, new_files)
    
    flag = 0;               % Flag to store result
    sizer_C = size(C);      % Size of files
    sizer_new_files = size(new_files);
    m = 1;                  % Counter of inconsistent files
    holder_2 = [];          % Variable to store files
   
    switch(ralpher)
        
        % Verification of ROI x ROI for any selection 
        case 1

            % Loop to iterate through all files
            for k = 1:sizer_C(1)

               % For the first iteration store the ROI dimensions to be compared
               if k == 1

                   % Extracting the size of the files via partial loading
                   matObj = matfile(C{1,:});
                   S = whos(matObj);
                   s3 = S.size;

               else
               % For other iterations 

                   % Extracting the size of the files via partial loading
                   matObj = matfile(C{k,:});
                   S = whos(matObj);
                   s4 = S.size;

                   % For 2D or 3D cases of Dimensionality
                   if length(s3) == 2
                       if (s3(1) == s4(1) && s3(2) == s4(2)) == 0
                           fprintf('\n ROI x ROI dimensions of following files are not equal, please re-select files with consistent ROI dimensions:');
                           fprintf('\n File 1: %s ',C{1,:});
                           fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s3));

                           fprintf('\n File 2: %s has been excluded from the selection', k, C{k,:});
                           fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s4));
                           holder_2(m) = k;
                           m = m+1;
                           flag = 1;
                       end 

                   elseif length(s3) == 3
                       % Compare dimensions, if inconsistent, files that are
                       % inconsistent
                       if (s3(1) == s4(1) && s3(2) == s4(2) && s3(3) == s4(3)) == 0
                           fprintf('\n ROI x ROI dimensions of following files are not equal, please re-select files with consistent ROI dimensions:');
                           fprintf('\n File 1: %s ',C{1,:});
                           fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s3));

                           fprintf('\n File 2: %s has been excluded from the selection', k, C{k,:});
                           fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s4));
                           holder_2(m) = k;
                           m = m+1;
                           flag = 1;
                       end
                   else
                       warning('Something isn''t right here');
                   end

               end

            end
           
% Case for comparing Primary Selection of files vs Secondary Selection of files
        
        case 2
            
            % Storing the dimensions of Primary selected files
            matObj = matfile(C{1,:});
            S = whos(matObj);
            s3 = S.size;
            
            % Select verification based on number of new files to be added
            if sizer_new_files(1) == 1
            
                % For ONE new file addition 
                
                % Store & calculate the size
                matObj = matfile(new_files{1,:});
                S = whos(matObj);
                s4 = S.size;
                
                % For 2D or 3D cases of Dimensionality
                if length(s3) == 2
                   if (s3(1) == s4(1) && s3(2) == s4(2)) == 0
                       fprintf('\n ROI x ROI dimensions of following files are not equal, please re-select files with consistent ROI dimensions:');
                       fprintf('\n File 1: %s ',C{1,:});
                       fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s3));

                       fprintf('\n File 2: %s has been excluded from the selection', new_files{1,:});
                       fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s4));
                       holder_2(m) = 1;
                       m = m+1;
                       flag = 1;
                   end 

                elseif length(s3) == 3
                       % Compare dimensions, if inconsistent, files that are
                       % inconsistent
                       if (s3(1) == s4(1) && s3(2) == s4(2) && s3(3) == s4(3)) == 0
                           fprintf('\n ROI x ROI dimensions of following files are not equal, please re-select files with consistent ROI dimensions:');
                           fprintf('\n File 1: %s ',C{1,:});
                           fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s3));

                           fprintf('\n File 2: %s has been excluded from the selection', new_files{1,:});
                           fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s4));
                           holder_2(m) = 1;
                           m = m+1;
                           flag = 1;
                       end
                else
                       warning('Something isn''t right here');
                end
                
                
                
            else
                % For MULTIPLE new file addition 
                
                % Iterate through all newly selected files
                for k = 1:sizer_new_files(1)

                    % Store & calculate the size
                    matObj = matfile(new_files{k,:});
                    S = whos(matObj);
                    s4 = S.size;
                    
                     % For 2D or 3D cases of Dimensionality
                    if length(s3) == 2
                           if (s3(1) == s4(1) && s3(2) == s4(2)) == 0
                               fprintf('\n ROI x ROI dimensions of following files are not equal, please re-select files with consistent ROI dimensions:');
                               fprintf('\n File 1: %s ',C{1,:});
                               fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s3));

                               fprintf('\n File 2: %s has been excluded from the selection', k, new_files{k,:});
                               fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s4));
                               holder_2(m) = k;
                               m = m+1;
                               flag = 1;
                           end 

                   elseif length(s3) == 3
                           % Compare dimensions, if inconsistent, files that are
                           % inconsistent
                           if (s3(1) == s4(1) && s3(2) == s4(2) && s3(3) == s4(3)) == 0
                               fprintf('\n ROI x ROI dimensions of following files are not equal, please re-select files with consistent ROI dimensions:');
                               fprintf('\n File 1: %s ',C{1,:});
                               fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s3));

                               fprintf('\n File 2: %s has been excluded from the selection', k, new_files{k,:});
                               fprintf('\n Dimensiosn (ROI x ROI) %s \n', num2str(s4));
                               holder_2(m) = k;
                               m = m+1;
                               flag = 1;
                           end
                   else
                       warning('Something isn''t right here');
                   end                     
                end  
           end
     end
end