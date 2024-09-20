function tmfc_statistics_GUI()

%% GUI Initialization
RES_GUI = figure('Name', 'TMFC: Results', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.45 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w');
    
% Initializing Elements of the UI
RES_T1  = uicontrol(RES_GUI,'Style','text','String', 'TMFC results','Units', 'normalized', 'Position',[0.270 0.93 0.460 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w', 'FontWeight', 'bold');

% Pop up menu to select type of Test
RES_POP_1  = uicontrol(RES_GUI,'Style','popupmenu','String', {'One-sample t-test', 'Paired t-test', 'Two-sample t-test'},'Units', 'normalized', 'Position',[0.045 0.87 0.91 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
 
% List boxes to show (.mat) file selection
RES_lst_0 = uicontrol(RES_GUI , 'Style', 'listbox', 'String', '','Max', 100,'Units', 'normalized', 'Position',[0.045 0.56 0.91 0.300],'fontunits','normalized', 'fontSize', 0.07);
RES_lst_1 = uicontrol(RES_GUI , 'Style', 'listbox', 'String', '','Max', 100,'Units', 'normalized', 'Position',[0.045 0.56 0.440 0.300],'fontunits','normalized', 'fontSize', 0.07,'visible','off');
RES_lst_2 = uicontrol(RES_GUI , 'Style', 'listbox', 'String', '','Max', 100,'Units', 'normalized', 'Position',[0.52 0.56 0.440 0.300],'fontunits','normalized', 'fontSize', 0.07,'visible','off');

%strcat(num2str(len_subs_A1(1))
% orange = [0.773, 0.353, 0.067]
% green = [0.219, 0.341, 0.137]
% Counter of subjects selected
RES_L0_CTR = uicontrol(RES_GUI, 'Style', 'text','String', '0 ROIs x 0 subjects','Units', 'normalized', 'Position',[0.295 0.51 0.44 0.04],'fontunits','normalized', 'fontSize', 0.57, 'HorizontalAlignment','center','backgroundcolor','w','ForegroundColor',[0.773, 0.353, 0.067]);
RES_L1_CTR = uicontrol(RES_GUI, 'Style', 'text','String', '0 ROIs x 0 subjects','Units', 'normalized', 'Position',[0.045 0.51 0.44 0.04],'fontunits','normalized', 'fontSize', 0.57, 'HorizontalAlignment','center','backgroundcolor','w','ForegroundColor',[0.773, 0.353, 0.067],'visible', 'off');
RES_L2_CTR = uicontrol(RES_GUI, 'Style', 'text','String', '0 ROIs x 0 subjects','Units', 'normalized', 'Position',[0.52 0.51 0.44 0.04],'fontunits','normalized', 'fontSize', 0.57, 'HorizontalAlignment','center','backgroundcolor','w','ForegroundColor',[0.773, 0.353, 0.067],'visible', 'off');

% "Select & Remove" file buttons for each case
RES_L0_SEL = uicontrol(RES_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized','Position',[0.045 0.45 0.445 0.054],'fontunits','normalized', 'fontSize', 0.36, 'UserData', struct('select','one_samp_sel'));
RES_L0_REM = uicontrol(RES_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized','Position',[0.52 0.45 0.445 0.054],'fontunits','normalized', 'fontSize', 0.36, 'UserData', struct('remove','one_samp_rem'));
RES_L1_SEL = uicontrol(RES_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized','Position',[0.045 0.45 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36, 'visible', 'off','UserData',struct('select', 'left_samp_sel'));
RES_L1_REM = uicontrol(RES_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized','Position',[0.275 0.45 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36, 'visible', 'off', 'UserData', struct('remove','left_samp_rem'));
RES_L2_SEL = uicontrol(RES_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized','Position',[0.52 0.45 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36, 'visible', 'off','UserData', struct('select','right_samp_sel'));
RES_L2_REM = uicontrol(RES_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized','Position',[0.75 0.45 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36, 'visible', 'off', 'UserData', struct('remove','right_samp_rem'));

% Boxes & Layout for Alpha & threshold values
RES_CONT = uipanel(RES_GUI,'Units', 'normalized','Position',[0.046 0.37 0.44 0.07],'HighLightColor',[0.78 0.78 0.78],'BorderType', 'line','BackgroundColor','w');
RES_CONT_txt  = uicontrol(RES_GUI,'Style','text','String', 'Contrast: ','Units', 'normalized', 'Position',[0.095 0.38 0.38 0.04],'fontunits','normalized', 'fontSize', 0.55, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_CONT_val  = uicontrol(RES_GUI,'Style','edit','String', '','Units', 'normalized', 'Position',[0.278 0.382 0.18 0.045],'fontunits','normalized', 'fontSize', 0.50);
RES_ALP = uipanel(RES_GUI,'Units', 'normalized','Position',[0.52 0.37 0.44 0.07],'HighLightColor',[0.78 0.78 0.78],'BorderType', 'line','BackgroundColor','w');
RES_ALP_txt  = uicontrol(RES_GUI,'Style','text','String', 'Alpha: ','Units', 'normalized', 'Position',[0.583 0.38 0.35 0.04],'fontunits','normalized', 'fontSize', 0.55, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_ALP_val  = uicontrol(RES_GUI,'Style','edit','String', '','Units', 'normalized', 'Position',[0.755 0.382 0.18 0.045],'fontunits','normalized', 'fontSize', 0.50);

% Type of Threshold selection Pop Up menu and conditional value
RES_THRES_TXT = uicontrol(RES_GUI,'Style','text','String', 'Threshold type: ','Units', 'normalized', 'Position',[0.098 0.298 0.38 0.04],'fontunits','normalized', 'fontSize', 0.58, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_THRES_POP = uicontrol(RES_GUI,'Style','popupmenu','String', {'Uncorrected (Parametric)', 'FDR (Parametric)', 'Bonferroni (Parametric)', 'Uncorrected (Non-Parametric)','FDR (Non-Parametric)','NBS FWE(Non-Parametric)','NBS TFCE(Non-Parametric)'},'Units', 'normalized', 'Position',[0.358 0.295 0.6 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
RES_THRES_VAL_TXT = uicontrol(RES_GUI,'Style','text','String', 'Primary Threshold Value (Pval): ','Units', 'normalized', 'Position',[0.098 0.23 0.5 0.04],'fontunits','normalized', 'fontSize', 0.58, 'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
RES_THRES_VAL_UNI = uicontrol(RES_GUI,'Style','edit','String', '','Units', 'normalized', 'Position',[0.76 0.234 0.2 0.04],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w', 'enable', 'off');
RES_PERM_TXT = uicontrol(RES_GUI,'Style','text','String', 'Permutations: ','Units', 'normalized', 'Position',[0.098 0.165 0.38 0.04],'fontunits','normalized', 'fontSize', 0.58, 'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
RES_PERM_VAL = uicontrol(RES_GUI,'Style','edit','String', '','Units', 'normalized', 'Position',[0.76 0.169 0.2 0.04],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w','enable', 'off');

% The Almighty Run
RES_RUN = uicontrol(RES_GUI, 'Style', 'pushbutton', 'String', 'Run','Units', 'normalized','Position',[0.4 0.05 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);

% Callback actions
set(RES_POP_1, 'callback', @test_type);
set(RES_THRES_POP, 'callback', @threshold_type);
set(RES_lst_0, 'callback', @live_select_0)
set(RES_lst_1, 'callback', @live_select_1)
set(RES_lst_2, 'callback', @live_select_2)
set(RES_L0_SEL, 'callback', @(src, event) selection_caller(get(src, 'UserData')));
set(RES_L1_SEL, 'callback', @(src, event) selection_caller(get(src, 'UserData')));
set(RES_L2_SEL, 'callback', @(src, event) selection_caller(get(src, 'UserData')));
set(RES_L0_REM, 'callback', @(src, event) remove_caller(get(src, 'UserData')));
set(RES_L1_REM, 'callback', @(src, event) remove_caller(get(src, 'UserData')));
set(RES_L2_REM, 'callback', @(src, event) remove_caller(get(src, 'UserData')));
set(RES_RUN, 'callback', @run);
warning('off','backtrace')
M0 = {}; % variable to store the matrices for One-sample t-test
M1 = {}; % variable to store the matrices set 1 Paired & Two-sample t-test
M2 = {}; % variable to store the matrices set 2 Paired & Two-sample t-test

% Variables to store present selection of matrices from list
selection_0 = '';
selection_1 = '';
selection_2 = '';
matrices_0 = 0;
matrices_1 = 0;
matrices_2 = 0;

% Function to select respective call button
function selection_caller(data)
% Format: file_selector(M_VAR, matrix, disp_box, disp_str)
    switch (data.select)
        case 'one_samp_sel'
            file_selector(M0, matrices_0, RES_lst_0, RES_L0_CTR,'one_samp_sel');
            
        case 'left_samp_sel'
            file_selector(M1, matrices_1, RES_lst_1, RES_L1_CTR,'left_samp_sel');
            
        case 'right_samp_sel'
            file_selector(M2, matrices_2, RES_lst_2, RES_L2_CTR,'right_samp_sel');
    end
end
% Function to Perform selection Action
function file_selector(M_VAR, matrix, disp_box, disp_str, case_maker)
    
   % First case: First time selection
    if isempty(M_VAR)
        
        % Checking if there exist pre-selected (.mat) files
        
        M_VAR = selector();    % Select (.mat) files
        M_VAR = unique(M_VAR);    % Remove duplicates

        % If (.mat) files have been selected, perform multiple variable and dimension checks
        if ~isempty(M_VAR)          
                            
            if multi_check(M_VAR) == 0   % Check if (.mat) file consists of multiple variables

                % Continue if the selected files do not contain multiple variables
                for i = 1:size(M_VAR,1)
                    M(i).m = struct2array(load(M_VAR{i,:}));
                end
    
                try
                    matrix = cat(3,M(:).m);
                    if size(matrix,1) ~= size(matrix,2)
                        warning('Matrices are not square')
                        clear M matrices   
                        M_VAR = {};
                    end
                catch
                    warning('Matrices have different dimensions')
                    clear M  
                    M_VAR = {};
                end
                
            elseif multi_check(M_VAR) == 1
                % Warning if file has MULTIPLE VARIABLES within 
                M_VAR = {};
                warning('Selected *.mat file(s) consist(s) of multiple variables, please select *.mat files each containing only one variable');
            end 
            
        end
               
        % Updating the GUI 
        if ~exist('M_VAR', 'var') || isempty(M_VAR)
            % If all files selection was rejected during checks, reset GUI
            disp('No (.mat) file(s) selected');
            set(disp_str, 'String', '0 ROIs x 0 subjects');
            set(disp_str, 'ForegroundColor',[0.773, 0.353, 0.067]);     
            M_VAR = {};
        elseif isempty(M_VAR{1}) 
            % If all files selection was rejected during checks, reset GUI
            disp('No (.mat) file(s) selected');
            set(disp_str, 'String', '0 ROIs x 0 subjects');
            set(disp_str, 'ForegroundColor',[0.773, 0.353, 0.067]);     
            M_VAR = {};
        else
            % Show the number of (.mat) files selected & update GUI
            fprintf('Number of (.mat) files selected are: %d \n', size(M_VAR,1));
            set(disp_box,'String', M_VAR);
            set(disp_box,'Value', []);

            % Update the ROI x ROI x Subjects number
            set(disp_str, 'String', strcat(num2str(size(matrix,2)), ' ROIs x',32, num2str(size(matrix,3)),' subjects'));
            set(disp_str, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI       
        end
    
    % Second case: Add new matrices
    else              
        new_M_VAR = selector();        % Select new files via function
        
        % If new files are selected then proceed 
        if ~isempty(new_M_VAR{1})
               
            % Check for multiple variables within selected files   
            if multi_check(new_M_VAR) ~= 1        
                
                % Continue if the selected files do not contain multiple variables
                for i = 1:size(new_M_VAR,1)
                    M(i).m = struct2array(load(new_M_VAR{i,:}));
                end
    
                try
                    new_matrices = cat(3,M(:).m);
                    if size(new_matrices,1) ~= size(new_matrices,2)
                        warning('Matrices are not square')
                        clear M 
                        new_M_VAR = {};
                    end
                catch
                    warning('Matrices have different dimensions')
                    clear M  
                    new_M_VAR = {};
                end
                
                % Concatenate old and new matrices
                try
                    matrix = cat(3,matrix,new_matrices);
                    M_VAR = vertcat(M_VAR, new_M_VAR);
                    %Updating the GUI 
                    fprintf('Number of (.mat) files selected are: %d \n', size(new_M_VAR,1));
                    set(disp_box,'String', M_VAR);
                    set(disp_box,'Value', []);
        
                    % Update the ROI x ROI x Subjects number
                    set(disp_str, 'String', strcat(num2str(size(matrix,2)), ' ROIs x',32, num2str(size(matrix,3)),' subjects'));
                    set(disp_str, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI       
                    clear M new_M_VAR
                catch
                    warning('Matrices have different number of ROIs');
                    clear new_matrices new_M_VAR M
                end
            
            else
                warning('Selected *.mat file(s) consist(s) of multiple variables, please select *.mat files each containing only one variable');
            end
        % If no files are selected
        else          
           disp('No files added');          
        end
    end
    
      switch (case_maker)
      
      case 'one_samp_sel'
          M0 = M_VAR;
          matrices_0 = matrix;

      case 'left_samp_sel'
          M1 = M_VAR;
          matrices_1 = matrix;
          
      case 'right_samp_sel'
          M2 = M_VAR;
          matrices_2 = matrix;
          
      end
       
    
end


% Function to select respective remove button
function remove_caller(data)
    switch (data.remove)
        case 'one_samp_rem'
            file_remove(selection_0, M0, RES_lst_0, RES_L0_CTR,'one_samp_sel');
            
        case 'left_samp_rem'
            file_remove(selection_1, M1, RES_lst_1, RES_L1_CTR,'left_samp_sel');
            
        case 'right_samp_rem'
            file_remove(selection_2, M2, RES_lst_2, RES_L2_CTR,'right_samp_sel');
    end
end
% Function to perform removal of files from Lists
function file_remove(sel_var, M_VAR, disp_box,disp_str,case_maker)


   if isempty(sel_var) && isempty(M_VAR)
       warning('There are no files present to remove, please select .mat files to perform Results analysis');
   elseif isempty(sel_var) && ~isempty(M_VAR)
        warning('There are no selected matrices to remove from the list, please select matrices once again');
   else
       disp(M_VAR);
       disp(sel_var);
       M_VAR(sel_var,:) = [];
       holder = size(sel_var);
       fprintf('Number of (.mat) files removed are: %d \n', holder(2));
              
       set(disp_box,'Value', []);
       set(disp_box,'String', M_VAR);
       sel_var = {};
       
       if ~isempty(M_VAR)           
            % Update the ROI x ROI x Subjects counter under each case
            % Partial load the first file to update 
            matObj = matfile(M_VAR{1,:});
            S = whos(matObj);
            dims = S.size;
            roi_sub = [];
           
            % Update ROI x Subjects, for 2D case (ROI x ROI):
            if length(dims) == 2
                M0_ss_size = size(M_VAR);                  % Size of selected list
                roi_sub = [dims(1), M0_ss_size(1)];     % Store dimensions as ROI x Subjects
                set(disp_str, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(disp_str, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 

            elseif length(dims) == 3
            % Update ROI x Subjects, for 3D case (ROI x ROI x Subjects): 
                subs = 0;                               % variable to store size of subs
                for i = 1:length(M_VAR)                    % loop accross all files
                    matObj = matfile(M_VAR{i,:});          % Extract size of each variable per iteration
                    temp = whos(matObj);
                    temp_dim = temp.size;
                    subs = subs + temp.size(3);
                end

                roi_sub = [dims(1), subs];              % Store ROI and subjects lengths
                set(disp_str, 'String', strcat(num2str(roi_sub(1)), ' ROIs x',32, num2str(roi_sub(2)),' subjects'));
                set(disp_str, 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI

            else
                % Unlikely event, if this occurs, then there is an issue
                % with the type of files uploaded (mostly, it may not be
                % 2D or 3D formats. 
                warning('Fatal Error, the files must be ROI x ROI x Subjects format & dimensions');
            end   
       end
   end
  if isempty(M_VAR)
        set(disp_str, 'String', '0 ROIs x 0 subjects');
        set(disp_str, 'ForegroundColor',[0.773, 0.353, 0.067]);
  end
   
  switch (case_maker)
      
      case 'one_samp_sel'
          M0 = M_VAR;
          
      case 'left_samp_sel'
          M1 = M_VAR;
          
      case 'right_samp_sel'
          M2 = M_VAR;
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
    if strcmp(contender, 'Paired t-test')
        
        % If Paired T Test is selected
        disp('Selected Test Type: Paired t-test');
        
        % Reset GUI 
        set([RES_lst_0,RES_L0_CTR],'visible', 'off');        
        set([RES_lst_1,RES_lst_2,RES_L1_CTR,RES_L2_CTR],'visible', 'on','enable', 'on'); 
        set([RES_L0_SEL,RES_L0_REM],'visible', 'off');
        set([RES_L1_SEL,RES_L1_REM,RES_L2_SEL,RES_L2_REM],'visible', 'on','enable', 'on');  
        set([RES_THRES_POP,RES_THRES_TXT,RES_CONT_txt,RES_CONT_val,RES_ALP_txt,RES_ALP_val,RES_RUN],'enable', 'on');
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
        
    elseif strcmp(contender, 'One-sample t-test')
        
        % If One-sample T Test is selected
        disp('Selected Test Type: One-sample t-test');
        
        % Reset GUI
        set([RES_lst_0,RES_L0_CTR],'visible', 'on');        
        set([RES_L0_SEL,RES_L0_REM],'visible', 'on');
        set([RES_lst_1,RES_lst_2,RES_L1_CTR,RES_L2_CTR],'visible', 'off');
        set([RES_L1_SEL,RES_L1_REM,RES_L2_SEL,RES_L2_REM],'visible', 'off');
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'String', '0 ROIs x 0 subjects');
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'ForegroundColor',[0.773, 0.353, 0.067]);
        set([RES_CONT_val, RES_ALP_val], 'String', []);
        set([RES_PERM_VAL, RES_THRES_VAL_UNI], 'String', []);
        set([RES_THRES_POP,RES_THRES_TXT,RES_CONT_txt,RES_CONT_val,RES_ALP_txt,RES_ALP_val,RES_RUN],'enable', 'on');
        
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
                
    elseif strcmp(contender, 'Two-sample t-test')
        
        % If Two-sample T Test is selected
        disp('Selected Test Type: Two-sample t-test');
        
        % Reset GUI 
        set([RES_lst_0,RES_L0_CTR],'visible', 'off');        
        set([RES_lst_1,RES_lst_2,RES_L1_CTR,RES_L2_CTR],'visible', 'on','enable', 'on'); 
        set([RES_L0_SEL,RES_L0_REM],'visible', 'off');
        set([RES_L1_SEL,RES_L1_REM,RES_L2_SEL,RES_L2_REM],'visible', 'on','enable', 'on');           
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'String', '0 ROIs x 0 subjects');
        set([RES_L0_CTR, RES_L1_CTR,RES_L2_CTR], 'ForegroundColor',[0.773, 0.353, 0.067]);
        set([RES_CONT_val, RES_ALP_val], 'String', []);
        set([RES_PERM_VAL, RES_THRES_VAL_UNI], 'String', []);
        set([RES_THRES_POP,RES_THRES_TXT,RES_CONT_txt,RES_CONT_val,RES_ALP_txt,RES_ALP_val,RES_RUN],'enable', 'on');

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
        clear matrices 

    end    
end

% Type of Parameter
function threshold_type(~,~)
    
    approach = (RES_THRES_POP.String{RES_THRES_POP.Value});
    
    if strcmp(approach, 'Uncorrected (Parametric)') || strcmp(approach, 'FDR (Parametric)') || strcmp(approach, 'Bonferroni (Parametric)') || strcmp(approach, 'NBS FWE(Non-Parametric)') || strcmp(approach, 'NBS TFCE(Non-Parametric)') 
        set(RES_PERM_TXT, 'enable', 'off');
        set(RES_PERM_VAL, 'enable', 'off');
        set(RES_PERM_VAL, 'String', []);
    elseif strcmp(approach, 'Uncorrected (Non-Parametric)') || strcmp(approach, 'FDR (Non-Parametric)') 
        set(RES_PERM_TXT, 'enable', 'on');
        set(RES_PERM_VAL, 'enable', 'on');
        set(RES_PERM_VAL, 'String', []);
    end
    
    if strcmp(approach, 'Uncorrected (Parametric)') || strcmp(approach, 'FDR (Parametric)') || strcmp(approach, 'Bonferroni (Parametric)') || strcmp(approach, 'Uncorrected (Non-Parametric)') || strcmp(approach, 'FDR (Non-Parametric)')
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
    

    if strcmp(G1, 'Paired t-test')          
    
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
                        % Continue with contrast & alpha
                        CA_0 = CA_controller();
                        if CA_0 == 1
                            TP_0 = TP_check();
                            if TP_0 == 1
                                set([RES_L0_CTR,RES_L1_CTR], 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 
                                max{1} = matrices_1;
                                max{2} = matrices_2;
                                [thresholded,pval,tval,conval] = tmfc_ttest(max,str2num(RES_CONT_val.String),eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                                if ~isempty(thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}))
                                    fprintf('Generating Results graph...\n');
                                    tmfc_results_GUI(thresholded,pval,tval,conval,eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                                end
                                clear thresholded pval tval conval max;
                            end
                        end
                    else
                        warning('The number of selected (.mat) files are inconsistent to perform Paired T Test \n Matrice(s) List 1: %d \n Matrice(s) List 2: %d \n, please select consistent number of files', length(M1), length(M2));
                        set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                        set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                    end

                elseif length(dims_L1) == 2 && length(dims_L2) == 3
                    if length(M1) == dims_L2(3)
                        CA_0 = CA_controller();
                        if CA_0 == 1
                            TP_0 = TP_check();
                            if TP_0 == 1
                                set([RES_L0_CTR,RES_L1_CTR], 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 
                                max{1} = matrices_1;
                                max{2} = matrices_2;
                                [thresholded,pval,tval,conval] = tmfc_ttest(max,str2num(RES_CONT_val.String),eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                                if ~isempty(thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}))
                                    fprintf('Generating Results graph...\n');
                                    tmfc_results_GUI(thresholded,pval,tval,conval,eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                                end
                                clear thresholded pval tval conval max;
                            end
                        end
                    else
                        warning('The number of selected (.mat) files are inconsistent to perform Paired T Test \n Matrice(s) List 1: %d \n Matrice(s) List 2: %d \n, please select consistent number of files', length(M1), dims_L2(3));
                        set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                        set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                    end

                elseif length(dims_L1) == 3 && length(dims_L2) == 2
                    if dims_L1(3) == length(M2)
                        CA_0 = CA_controller();
                        if CA_0 == 1
                            TP_0 = TP_check();
                            if TP_0 == 1
                                set([RES_L0_CTR,RES_L1_CTR], 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 
                                max{1} = matrices_1;
                                max{2} = matrices_2;
                                [thresholded,pval,tval,conval] = tmfc_ttest(max,str2num(RES_CONT_val.String),eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                                if ~isempty(thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}))
                                    fprintf('Generating Results graph...\n');
                                    tmfc_results_GUI(thresholded,pval,tval,conval,eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                                end
                                clear thresholded pval tval conval max;
                            end
                        end
                    else
                        warning('The number of selected (.mat) files are inconsistent to perform Paired T Test \n Matrice(s) List 1: %d \n Matrice(s) List 2: %d \n, please select consistent number of files', dims_L1(3), length(M2));
                        set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                        set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                    end

                elseif length(dims_L1) == 3 && length(dims_L2) == 3
                    if dims_L1(3) == dims_L2(3)
                        CA_0 = CA_controller();
                        if CA_0 == 1
                            TP_0 = TP_check();
                            if TP_0 == 1
                                set([RES_L0_CTR,RES_L1_CTR], 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 
                                max{1} = matrices_1;
                                max{2} = matrices_2;
                                [thresholded,pval,tval,conval] = tmfc_ttest(max,str2num(RES_CONT_val.String),eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                                if ~isempty(thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}))
                                    fprintf('Generating Results graph...\n');
                                    tmfc_results_GUI(thresholded,pval,tval,conval,eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                                end
                                clear thresholded pval tval conval max;
                            end
                        end
                    else
                        warning('The number of selected (.mat) files are inconsistent to perform Paired T Test \n Matrice(s) List 1: %d \n Matrice(s) List 2: %d \n, please select consistent number of files', dims_L1(3), dims_L2(3));
                        set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                        set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
                    end

                else 
                    warning('Fatal Error, the files must be ROI x ROI x Subjects format & dimensions');
                end

            else
               warning('The number of ROI x ROIs between the selections are inconsistent, please select matrices with consistent ROIs');
               set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
               set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 

            end

        elseif ~isempty(M1) && isempty(M2)
            warning('Please select SECOND set of Matrices to perform Paired t-test result evaluation');

        elseif isempty(M1) && ~isempty(M2)
            warning('Please select FIRST set of Matrices to perform Paired t-test result evaluation');
            
        else
            warning('Please select matrices files to perform Paired t-test result evaulation');
        end

    
    elseif strcmp(G1, 'One-sample t-test')
        
        if ~isempty(M0)
            
            CA_1 = CA_controller();
            if CA_1 == 1
                TP_1 = TP_check();
                if TP_1 == 1
                    set([RES_L0_CTR,RES_L1_CTR], 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 
                    [thresholded,pval,tval,conval] = tmfc_ttest(matrices_0, str2num(RES_CONT_val.String),eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));                   
                    
                    if ~isempty(thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}))
                        fprintf('Generating Results graph...\n');
                        tmfc_results_GUI(thresholded,pval,tval,conval,eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                    end
                    clear thresholded pval tval conval;
                end
            end
            
        else
            warning('Please select matrices files to perform One-sample t-test result evaulation');
        end
        

    elseif strcmp(G1, 'Two-sample t-test')

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
                CA_2 = CA_controller();
                if CA_2 == 1
                    TP_2 = TP_check();
                    if TP_2 == 1
                        set([RES_L0_CTR,RES_L1_CTR], 'ForegroundColor',[0.219, 0.341, 0.137]); % Update GUI 
                        max{1} = matrices_1;
                        max{2} = matrices_2;
                        [thresholded,pval,tval,conval] = tmfc_ttest2(max,str2num(RES_CONT_val.String),eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                        if ~isempty(thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}))
                            fprintf('Generating Results graph...\n');
                            tmfc_results_GUI(thresholded,pval,tval,conval,eval(get(RES_ALP_val, 'String')),thresh_ttest_adapter(RES_THRES_POP.String{RES_THRES_POP.Value}));
                        end
                        clear thresholded pval tval conval max;
                    end
                end
            else
               warning('The number of ROI x ROIs between the selections are inconsistent, please select matrices with consistent ROIs');
               set(RES_L1_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
               set(RES_L2_CTR, 'ForegroundColor',[0.773, 0.353, 0.067]); % Update GUI 
            end

        elseif ~isempty(M1) && isempty(M2)
            warning('Please select SECOND set of Matrices to perform Paired t-test result evaluation');

        elseif isempty(M1) && ~isempty(M2)
            warning('Please select FIRST set of Matrices to perform Paired t-test result evaluation');
            
        else
            warning('Please select matrices files to perform Paired t-test result evaulation');
        end
        
    else
        warning('Fatal Error, the files must be ROI x ROI x Subjects format & dimensions');
    end
    

end


function flag = CA_controller(~,~)
        
    flag = 0;
    G1 = (RES_POP_1.String{RES_POP_1.Value}); % Type of Test - paried, one , two 
    G2 = str2num(RES_CONT_val.String);        % Contrast
    try
        G3 = eval(get(RES_ALP_val, 'String'));    % Alpha
    catch
        G3 = NaN;
    end
    
     if isempty(G2)
         warning('Please enter numeric values for contrasts');
     else
         if strcmp(G1, 'Paired t-test') || strcmp(G1, 'Two-sample t-test')
             if length(G2) < 2
                 warning('Please enter TWO contrast values for computation');
             elseif length(G2) > 2
                 warning('Number of Contrast values cannot be greater than TWO, Please re-enter contrast values for computation');
             else
                  if isnan(G3)
                     warning('Please enter a numeric Alpha value for computation');
                  else
                    if G3 > 1 || G3 < 0
                        warning('Please re-enter Alpha value between (0.0, 1.0]');
                    else
                        fprintf('\n\nContrast values [%d , %d] & Alpha value of [%d] is accepted for computation\n',G2(1, 1), G2(1,2), G3);
                        flag = 1;
                    end
                 end
            end
        elseif strcmp(G1, 'One-sample t-test')
            if length(G2) >=2
                warning('Number of Contrast values cannot exceed ONE, Please re-enter contrast value for computation');
            else
                 if isnan(G3)
                    warning('Please enter Alpha value for computation');
                 else
                    if (G3 > 1) || (G3 < 0)
                        warning('Please re-enter Alpha value between (0.0, 1.0]');
                    else
                        fprintf('Contrast values [%d] & Alpha value of [%d] is accepted for computation\n',G2(1,1), G3);
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
         % Check if permutations is a number and not a floating point value
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
                 flag = 1;
         elseif P_2 <= 0 || P_2 > 1.0
             warning('Please enter a Primary Threshold value between (0.0, 1.0] for computation');
         else
             warning('Please enter a Primary Threshold value for computation');
         end       
     elseif strcmp(approach, 'Uncorrected (Parametric)') || strcmp(approach, 'FDR (Parametric)') || strcmp(approach, 'Bonferroni (Parametric)' )
         flag = 1;
     end

end

uiwait();
end
%%
% Function to select (.mat) files from the user via spm_select
function list_sel = selector(~,~)  
    files = spm_select(inf,'.mat','Select matrices for computation',{},pwd,'.');
    list_sel = {};
    list_sel = cellstr(files);
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
    
    if ~isempty(D{1})
        % Loop to iterate through all possible (.mat) files 
        for i = 1:main_size(1)

            var = who('-file', D{i,:});   % Listing the variable into temp Workspace - Cell Datatype
            %var = who('-file', D(i,:));  % Listing the variable into temp Workspace - Standalone Datatype
            A = size(var);

            % If there exists files with multiple variables within, then disp
            if A(1) > 1
                fprintf('Multiple variables present in the file :%s \n', D{i,:})
                holder(j) = i;
                j = j+1;
                flag = 1;
            end        
        end
    else
        flag = -1;
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
                    if length(s3) ~= length(s4)
                       flag = 2;
                    elseif length(s3) == 2
                       if (s3(1) == s4(1) && s3(2) == s4(2)) == 0
                           fprintf('\n ROI x ROI dimensions of following files are not equal, please re-select files with consistent ROI dimensions:');
                           fprintf('\n File 1: %s ',C{1,:});
                           fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s3));

                           fprintf('\n File 2: %s has been excluded from the selection', k, C{k,:});
                           fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s4));
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
                           fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s3));

                           fprintf('\n File 2: %s has been excluded from the selection', k, C{k,:});
                           fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s4));
                           holder_2(m) = k;
                           m = m+1;
                           flag = 1;
                       end
                   else
                       warning('Fatal Error, the files must be ROI x ROI x Subjects format & dimensions');
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
                if length(s3) ~= length(s4) 
                    warning('The Previously selected file has different dimensions than the present selection, Please remove the previously selected file with different dimensions and select again');
                elseif length(s3) == 2
                   if (s3(1) == s4(1) && s3(2) == s4(2)) == 0
                       fprintf('\n ROI x ROI dimensions of following files are not equal, please re-select files with consistent ROI dimensions:');
                       fprintf('\n File 1: %s ',C{1,:});
                       fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s3));

                       fprintf('\n File 2: %s has been excluded from the selection', new_files{1,:});
                       fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s4));
                       holder_2(m) = 1;
                       m = m+1;
                       flag = 1;
                   end 

                elseif length(s3) == 3
                       if (s3(1) == s4(1) && s3(2) == s4(2) && s3(3) == s4(3)) == 0
                           fprintf('\n ROI x ROI dimensions of following files are not equal, please re-select files with consistent ROI dimensions:');
                           fprintf('\n File 1: %s ',C{1,:});
                           fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s3));

                           fprintf('\n File 2: %s has been excluded from the selection', new_files{1,:});
                           fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s4));
                           holder_2(m) = 1;
                           m = m+1;
                           flag = 1;
                       end
                else
                       warning('Fatal Error, the files must be ROI x ROI x Subjects format & dimensions');
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
                               fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s3));

                               fprintf('\n File 2: %s has been excluded from the selection', k, new_files{k,:});
                               fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s4));
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
                               fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s3));

                               fprintf('\n File 2: %s has been excluded from the selection', k, new_files{k,:});
                               fprintf('\n Dimensions (ROI x ROI) %s \n', num2str(s4));
                               holder_2(m) = k;
                               m = m+1;
                               flag = 1;
                           end
                   else
                       warning('Fatal Error, the files must be ROI x ROI x Subjects format & dimensions');
                   end                     
                end  
           end
     end
end


function run_test(thresholded,pval,tval,conval,alpha,correction)

% Plot results  
figure('Name','TMFC statistics','NumberTitle', 'off','Units', 'normalized', 'Position', [0.4 0.25 0.50 0.50],'Tag', 'TMFC statistics','WindowStyle', 'modal');
sgtitle('Results');  
subplot(1,2,1); imagesc(conval);        subtitle('Group mean'); axis square; colorbar; caxis(tmfc_axis(conval,1));  
subplot(1,2,2); imagesc(thresholded);   subtitle(['p' correction '<' num2str(alpha)]); axis square; colorbar;  
colormap(subplot(1,2,1),'turbo')  
set(findall(gcf,'-property','FontSize'),'FontSize',16)

save_data_btn = uicontrol('Style','pushbutton','String', 'Save Data','Units', 'normalized','Position',[0.18 0.05 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);
save_plot_btn = uicontrol('Style','pushbutton','String', 'Save Plots','Units', 'normalized','Position',[0.62 0.05 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);
set(save_data_btn,'callback', @int_data_saver)
set(save_plot_btn ,'callback', @int_plot_saver)

tmfc_res.threshold = thresholded;
tmfc_res.pval = pval;
tmfc_res.tval = tval;
tmfc_res.conval = conval;
tmfc_res.alpha = alpha; 

function save_stat = int_data_saver(~,~)
       
    % Ask user for Filename & location name:
    [filename_SO, pathname_SO] = uiputfile('*.mat', 'Save TMFC variable as');
    
    % Set Flag save status to Zero, this flag is used in the future as
    % a reference to check if the Save was successful or not
    save_stat = 0;
    
    % Check if FileName or Path is missing or not available 
    if isequal(filename_SO, 0) || isequal(pathname_SO, 0)
        error('Results not saved. File name or Save Directory not selected.');
    
    else
        % If all data is available
        % Construct full path: PATH + FileName
        % e.g (D:\user\matlab\ + Test.m)
        
        fullpath = fullfile(pathname_SO, filename_SO);
        
        % D receives the save status of the variable in the desingated
        % location
        save_stat = saver(fullpath);
        
        % If the variable was successfully saved then display info
        if save_stat == 1
            fprintf('Results saved successfully in path: %s.\n', fullpath);
        else
            disp('Results not saved.');
        end
    end
          
end % Closing Save project Function

function save_stat = int_plot_saver(~,~)
       
    % Ask user for Filename & location name:
    [filename_SO, pathname_SO] = uiputfile('*.png', 'Save TMFC Plots as');
    
    % Set Flag save status to Zero, this flag is used in the future as
    % a reference to check if the Save was successful or not
    save_stat = 0;
    
    % Check if FileName or Path is missing or not available 
    if isequal(filename_SO, 0) || isequal(pathname_SO, 0)
        error('Result plots not saved. File name or Save Directory not selected.');
    
    else
        % If all data is available
        % Construct full path: PATH + FileName
        % e.g (D:\user\matlab\ + Test.m)
        
        fullpath = fullfile(pathname_SO, filename_SO);
        
        % D receives the save status of the variable in the desingated
        % location
        save_stat = saver_plot(fullpath);
        
        % If the variable was successfully saved then display info
        if save_stat == 1
            fprintf('Plots saved successfully in path: %s.\n', fullpath);
        else
            disp('Plots not saved.');
        end
    end
          
end % Closing Save project Function


function SAVER_STAT =  saver(save_path)
% 0 - Successfull save, 1 - Failed save
    try 
        save(save_path, 'tmfc_res');
        SAVER_STAT = 1;
        % Save Success
    catch 
        SAVER_STAT = 0;
        % Save Fail 
    end
end

function SAVER_STAT =  saver_plot(save_path)
% 0 - Successfull save, 1 - Failed save
    try 
        %save(save_path, 'tmfc_res');
        F = findobj('Type', 'figure', 'Tag', 'TMFC statistics');
        saveas(F, save_path);
        SAVER_STAT = 1;
        % Save Success
    catch 
        SAVER_STAT = 0;
        % Save Fail 
    end
end


end
% Function to convert internal labelling to tmfc_ttest() labelling
function small_string = thresh_ttest_adapter(big_string)

    small_string = '';
    
    switch big_string 
        case 'Uncorrected (Parametric)'
            small_string = 'uncorr';
        
        case 'FDR (Parametric)'
            small_string = 'FDR';
        
        case 'Bonferroni (Parametric)'
            small_string = 'Bonf';
            
    end
end