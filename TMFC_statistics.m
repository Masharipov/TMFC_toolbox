function TMFC_statistics()

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Configure and run group-level tests on TMFC connectivity matrices:
%   • One-sample t-test
%   • Paired t-test
%   • Two-sample t-test 
%
% Supported thresholding options:
%   • Parametric: uncorrected, FDR, Bonferroni
%   • Non-parametric: uncorrected, FDR
%   • Network-based statistics: NBS FWE extent, NBS FWE intensity
%   • Threshold-free NBS FWE
%
% Optional covariates can be added for one-sample, paired, and two-sample
% designs. For non-parametric, NBS, and threshold-free NBS analyses, the
% number of permutations can be specified. Parallel computations are
% available for NBS and threshold-free NBS.
%
% Expected input: user selects *.mat files. Each file must contain exactly
% one numeric variable that is either:
%   • ROI×ROI matrix for one subject, or
%   • ROI×ROI×Subjects matrix for multiple subjects.
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

localVer = 'v.2.0';

% GUI Initialization
stats_GUI = figure('Name', 'TMFC statistics', 'NumberTitle', 'off', 'Units', 'normalized', ...
    'Position', [0.35 0.06 0.3 0.82],'MenuBar', 'none','ToolBar', 'none','color','w', 'Tag','TMFC_STATS_GUI', ...
    'CloseRequestFcn', @on_close);

movegui(stats_GUI, 'center');
RES_T1  = uicontrol(stats_GUI,'Style','text','String',['TMFC statistics ' localVer],'Units', 'normalized', ...
    'Position',[0.270 0.94 0.460 0.04],'FontUnits','normalized', 'FontSize', 0.50,...
    'backgroundcolor','w', 'FontWeight', 'bold');

% Pop-up menu to select type of test
ST_test_type  = uicontrol(stats_GUI,'Style','popupmenu',...
    'String', {'One-sample t-test', 'Paired t-test', 'Two-sample t-test'},...
    'Units', 'normalized', 'Position',[0.045 0.885 0.91 0.045],...
    'FontUnits','normalized', 'FontSize', 0.40,'backgroundcolor','w');

% Listboxes to display *.mat file selection
ST_lst_0 = uicontrol(stats_GUI , 'Style', 'listbox', 'String', '','Max', 100,'value',[],...
    'Units', 'normalized', 'Position',[0.045 0.737 0.91 0.15],'FontUnits','points', 'FontSize',11);
ST_lst_1 = uicontrol(stats_GUI , 'Style', 'listbox', 'String', '','Max', 100,'value',[],...
    'Units', 'normalized', 'Position',[0.045 0.737 0.440 0.15],'FontUnits','points', 'FontSize', 11,'visible','off');
ST_lst_2 = uicontrol(stats_GUI , 'Style', 'listbox', 'String', '','Max', 100,'value',[],...
    'Units', 'normalized', 'Position',[0.515 0.737 0.440 0.15],'FontUnits','points', 'FontSize',11,'visible','off');

% Counter of ROIs × subjects for selected files
ST_L0_CTR = uicontrol(stats_GUI, 'Style', 'text','String', '0 ROIs x 0 subjects',...
    'Units', 'normalized', 'Position',[0.295 0.7 0.44 0.035],'FontUnits','normalized', ...
    'FontSize', 0.5, 'HorizontalAlignment','center','backgroundcolor','w',...
    'ForegroundColor',[0.773, 0.353, 0.067]);
ST_L1_CTR = uicontrol(stats_GUI, 'Style', 'text','String', '0 ROIs x 0 subjects',...
    'Units', 'normalized', 'Position',[0.045 0.7 0.44 0.035],'FontUnits','normalized', ...
    'FontSize', 0.5, 'HorizontalAlignment','center','backgroundcolor','w',...
    'ForegroundColor',[0.773, 0.353, 0.067],'visible', 'off');
ST_L2_CTR = uicontrol(stats_GUI, 'Style', 'text','String', '0 ROIs x 0 subjects',...
    'Units', 'normalized', 'Position',[0.52 0.7 0.44 0.035],'FontUnits','normalized', ...
    'FontSize', 0.5, 'HorizontalAlignment','center','backgroundcolor','w',...
    'ForegroundColor',[0.773, 0.353, 0.067],'visible', 'off');

% "Select & Remove" file buttons for each case
ST_L0_SEL = uicontrol(stats_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized',...
    'Position',[0.045 0.655 0.445 0.048],'FontUnits','normalized', 'FontSize', 0.36, ...
    'UserData', struct('select','one_samp_sel'));
ST_L0_REM = uicontrol(stats_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized',...
    'Position',[0.52 0.655 0.441 0.048],'FontUnits','normalized', 'FontSize', 0.36, ...
    'UserData', struct('remove','one_samp_rem'));
ST_L1_SEL = uicontrol(stats_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized',...
    'Position',[0.045 0.655 0.210 0.048],'FontUnits','normalized', 'FontSize', 0.36, ...
    'visible', 'off','UserData',struct('select', 'left_samp_sel'));
ST_L1_REM = uicontrol(stats_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized',...
    'Position',[0.275 0.655 0.210 0.048],'FontUnits','normalized', 'FontSize', 0.36, ...
    'visible', 'off', 'UserData', struct('remove','left_samp_rem'));
ST_L2_SEL = uicontrol(stats_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized',...
    'Position',[0.52 0.655 0.210 0.048],'FontUnits','normalized', 'FontSize', 0.36, ...
    'visible', 'off','UserData', struct('select','right_samp_sel'));
ST_L2_REM = uicontrol(stats_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized',...
    'Position',[0.75 0.655 0.210 0.048],'FontUnits','normalized', 'FontSize', 0.36, ...
    'visible', 'off', 'UserData', struct('remove','right_samp_rem'));

% Covariates section
ST_COV = uipanel(stats_GUI,'Units', 'normalized','Position',[0.046 0.58 0.914 0.06],...
    'HighLightColor',[0.78 0.78 0.78],'BorderType', 'line','BackgroundColor','w');
ST_COV_BTN = uicontrol(stats_GUI,'Style','pushbutton','String', 'Covariates','Units', 'normalized', ...
    'Position',[0.070 0.589 0.25 0.042],'FontUnits','normalized', 'FontSize', 0.42);
ST_COV_VAL = uicontrol(stats_GUI,'Style','edit','String', '','Units', 'normalized', ...
    'Position',[0.345 0.59 0.590 0.040],'FontUnits','normalized', 'FontSize', 0.42, ...
    'HorizontalAlignment','left','BackgroundColor','w');

% Contrast 
ST_CONT = uipanel(stats_GUI,'Units', 'normalized','Position',[0.046 0.505 0.914 0.06],...
    'HighLightColor',[0.78 0.78 0.78],'BorderType', 'line','BackgroundColor','w');
ST_CONT2 = uipanel(stats_GUI,'Units', 'normalized','Position',[0.0742 0.515 0.246 0.04],...
    'HighLightColor',[0.78 0.78 0.78],'BorderType', 'line','BackgroundColor','w');
ST_CONT_txt  = uicontrol(stats_GUI,'Style','text','String', 'Contrast:','Units', 'normalized', ...
    'Position',[0.12 0.517 0.15 0.03],'FontUnits','normalized', 'FontSize', 0.6, ...
    'HorizontalAlignment','Center','backgroundcolor','w');
ST_CONT_val  = uicontrol(stats_GUI,'Style','edit','String', '','Units', 'normalized', ...
    'Position',[0.345 0.514 0.59 0.040],'FontUnits','normalized', 'FontSize', 0.50);

% Type of threshold selection pop-up menu 
ST_THRES_TXT = uicontrol(stats_GUI,'Style','text','String', 'Threshold type: ','Units', 'normalized', ...
    'Position',[0.060 0.425 0.38 0.035],'FontUnits','normalized', 'FontSize', 0.58, ...
    'HorizontalAlignment','Left','backgroundcolor','w');
ST_THRES_POP = uicontrol(stats_GUI,'Style','popupmenu','String', ...
    {'Uncorrected (Parametric)', 'FDR (Parametric)', 'Bonferroni (Parametric)', ...
    'Uncorrected (Non-parametric)','FDR (Non-parametric)', ...
    'NBS FWE (Extent)', 'NBS FWE (Intensity)', ...
    'Threshold-free NBS FWE'}, ...
    'Units', 'normalized', 'Position',[0.358 0.42 0.6 0.045],...
    'FontUnits','normalized', 'FontSize', 0.45,'backgroundcolor','w');

% Significance (alpha level)
ST_ALP_txt  = uicontrol(stats_GUI,'Style','text','String', 'Significance:','Units', 'normalized', ...
    'Position',[0.06 0.37 0.35 0.035],'FontUnits','normalized', 'FontSize', 0.58, ...
    'HorizontalAlignment','Left','backgroundcolor','w');
ST_ALP_val  = uicontrol(stats_GUI,'Style','edit','String', '','Units', 'normalized', ...
    'Position',[0.76 0.37 0.2 0.040],'FontUnits','normalized', 'FontSize', 0.45);

% Primary threshold
ST_THRES_VAL_TXT = uicontrol(stats_GUI,'Style','text','String', 'Primary threshold (p-value): ','Units', 'normalized', ...
    'Position',[0.060 0.32 0.5 0.035],'FontUnits','normalized', 'FontSize', 0.58, ...
    'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
ST_THRES_VAL_UNI = uicontrol(stats_GUI,'Style','edit','String', '0.001','Units', 'normalized', ...
    'Position',[0.76 0.32 0.2 0.038],'FontUnits','normalized', 'FontSize', 0.50, ...
    'backgroundcolor','w', 'enable', 'off');

% Permutations
ST_PERM_TXT = uicontrol(stats_GUI,'Style','text','String', 'Number of permutations: ','Units', 'normalized', ...
    'Position',[0.060 0.27 0.38 0.035],'FontUnits','normalized', 'FontSize', 0.58, ...
    'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
ST_PERM_VAL = uicontrol(stats_GUI,'Style','edit','String', '5000','Units', 'normalized', ...
    'Position',[0.76 0.27 0.2 0.038],'FontUnits','normalized', 'FontSize', 0.50, ...
    'backgroundcolor','w','enable', 'off');

% Extension parameter (E)
ST_E_TXT = uicontrol(stats_GUI,'Style','text','String', 'Extension parameter (E): ','Units', 'normalized', ...
    'Position',[0.060 0.22 0.38 0.035],'FontUnits','normalized', 'FontSize', 0.58, ...
    'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
ST_E_VAL = uicontrol(stats_GUI,'Style','edit','String', '0.4','Units', 'normalized', ...
    'Position',[0.76 0.22 0.2 0.038],'FontUnits','normalized', 'FontSize', 0.50, ...
    'backgroundcolor','w', 'enable', 'off');

% Height parameter (H)
ST_H_TXT = uicontrol(stats_GUI,'Style','text','String', 'Height parameter (H): ','Units', 'normalized', ...
    'Position',[0.060 0.17 0.38 0.035],'FontUnits','normalized', 'FontSize', 0.58, ...
    'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
ST_H_VAL = uicontrol(stats_GUI,'Style','edit','String', '3','Units', 'normalized', ...
    'Position',[0.76 0.17 0.2 0.038],'FontUnits','normalized', 'FontSize', 0.50, ...
    'backgroundcolor','w', 'enable', 'off');

% Parallel computations
ST_PAR_TXT = uicontrol(stats_GUI,'Style','text','String', 'Parallel computations: ','Units', 'normalized', ...
    'Position',[0.058 0.12 0.45 0.038],'FontUnits','normalized', 'FontSize', 0.54, ...
    'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
ST_PAR_CHK = uicontrol(stats_GUI,'Style','togglebutton','String','Off', ...
    'Units','normalized', ...
    'Position',[0.76 0.12 0.2 0.038], ...
    'FontUnits','normalized', ...
    'FontSize',0.5, ...
    'BackgroundColor','w', ...
    'Enable','off', ...
    'Callback',@toggle_parallel);

% Run button
RES_RUN = uicontrol(stats_GUI, 'Style', 'pushbutton', 'String', 'Run','Units', 'normalized', ...
    'Position',[0.20 0.028 0.210 0.050],'FontUnits','normalized', 'FontSize', 0.36);

% Help button
HELP_BTN = uicontrol(stats_GUI, 'Style', 'pushbutton', 'String', 'Help','Units', 'normalized', ...
    'Position',[0.60 0.028 0.210 0.050],'FontUnits','normalized', 'FontSize', 0.36);


% Callback actions
set(ST_test_type, 'callback', @test_type);
set(ST_COV_BTN, 'callback',   @covariates_button);
set(ST_COV_VAL, 'callback',   @covariates_edit_callback);
set(ST_THRES_POP, 'callback', @threshold_type);
set(ST_lst_0, 'callback', @live_select_0)
set(ST_lst_1, 'callback', @live_select_1)
set(ST_lst_2, 'callback', @live_select_2)
set(ST_L0_SEL, 'callback', @(src, event) select_caller(get(src, 'UserData')));
set(ST_L1_SEL, 'callback', @(src, event) select_caller(get(src, 'UserData')));
set(ST_L2_SEL, 'callback', @(src, event) select_caller(get(src, 'UserData')));
set(ST_L0_REM, 'callback', @(src, event) remove_caller(get(src, 'UserData')));
set(ST_L1_REM, 'callback', @(src, event) remove_caller(get(src, 'UserData')));
set(ST_L2_REM, 'callback', @(src, event) remove_caller(get(src, 'UserData')));
set(RES_RUN, 'callback', @run);

M0 = {}; % variable to store the matrices for One-sample t-test
M1 = {}; % variable to store the matrices set 1 Paired & Two-sample t-test
M2 = {}; % variable to store the matrices set 2 Paired & Two-sample t-test

% Variables to store present selection of matrices from listboxes
selection_0 = '';
selection_1 = '';
selection_2 = '';
matrices_0 = [];
matrices_1 = [];
matrices_2 = [];
covariates_text = '';
covariates_table = [];

% Function to select respective call button
function select_caller(data)
    switch (data.select)
        case 'one_samp_sel'
            file_selector(M0, matrices_0, ST_lst_0, ST_L0_CTR,'one_samp_sel');
            
        case 'left_samp_sel'
            file_selector(M1, matrices_1, ST_lst_1, ST_L1_CTR,'left_samp_sel');
            
        case 'right_samp_sel'
            file_selector(M2, matrices_2, ST_lst_2, ST_L2_CTR,'right_samp_sel');
    end
end

% Function to select respective remove button
function remove_caller(data)
    switch (data.remove)
        case 'one_samp_rem'
            file_remove(ST_lst_0, M0, ST_lst_0, ST_L0_CTR, 'one_samp_sel');            
        case 'left_samp_rem'
            file_remove(ST_lst_1, M1, ST_lst_1, ST_L1_CTR, 'left_samp_sel');
        case 'right_samp_rem'
            file_remove(ST_lst_2, M2, ST_lst_2, ST_L2_CTR, 'right_samp_sel');
    end
end

% Function to select and add files to listboxes
function file_selector(M_VAR, matrix, disp_box, disp_str, case_maker)

    % First case: Initial selection of data--------------------------------
    if isempty(M_VAR)
        
        % Checking if there exist pre-selected *.mat files
        M_VAR = select_mat_file();        % Select *.mat files
        M_VAR = unique(M_VAR);            % Remove duplicates

        % If *.mat files have been selected, perform multiple variable and dimension checks
        if ~isempty(M_VAR)          

            % Check if *.mat file consists of multiple variables
            mv_flag = multi_var_check(M_VAR);
            if mv_flag == 0   

                % Continue if the selected files do not contain multiple variables
                for i = 1:size(M_VAR,1)
                    tmp = load(M_VAR{i,:}); 
                    fn  = fieldnames(tmp); 
                    val = tmp.(fn{1});
                
                    % ---- Strict numeric matrix check ----
                    if ~isnumeric(val)
                        shortwarn(sprintf('File "%s" does not contain a numeric matrix (found %s).', ...
                            M_VAR{i,:}, class(val)));
                        M_VAR = {}; M = []; return;
                    end
                    if ~ismatrix(val) && ndims(val) ~= 3
                        shortwarn(sprintf('File "%s" must be ROI×ROI or ROI×ROI×Subjects (found %d-D array).', ...
                            M_VAR{i,:}, ndims(val)));
                        M_VAR = {}; M = []; return;
                    end

                    if size(val,1) ~= size(val,2)
                        shortwarn(sprintf('File "%s" must be square (ROI×ROI or ROI×ROI×Subjects).', M_VAR{i,:}));
                        M_VAR = {}; M = []; return;
                    end
                    
                    if size(val,1) < 2
                        shortwarn(sprintf('File "%s" has only one ROI. At least 2 ROIs are required for connectivity analyses.', M_VAR{i,:}));
                        M_VAR = {}; M = []; return;
                    end
                    % -------------------------------------
                
                    M(i).m = val;
                end
    
                try
                    matrix = cat(3,M(:).m);
                    if size(matrix,1) ~= size(matrix,2)
                        shortwarn('Matrices are not square.');
                        clear M matrix   
                        M_VAR = {};
                    end
                catch
                    shortwarn('Matrices have different dimensions.');
                    clear M  
                    M_VAR = {};
                end
                
            elseif mv_flag == 1
                M_VAR = {};
                shortwarn('Each selected *.mat file must contain one variable (2D or 3D matrix).');
            end 
        end
               
        % Updating the GUI 
        if ~exist('M_VAR', 'var') || isempty(M_VAR)
            % If all files selection was rejected during checks, reset GUI
            shortwarn('No *.mat file(s) selected');
            set(disp_str, 'String', '0 ROIs x 0 subjects');
            set(disp_str, 'ForegroundColor',[0.773, 0.353, 0.067]);     
            M_VAR = {};
        elseif isempty(M_VAR{1}) 
            % If all files selection was rejected during checks, reset GUI
            shortwarn('No *.mat file(s) selected');
            set(disp_str, 'String', '0 ROIs x 0 subjects');
            set(disp_str, 'ForegroundColor',[0.773, 0.353, 0.067]);     
            M_VAR = {};
        else
            % Show the number of *.mat files selected & update GUI
            fprintf('Number of .mat files selected: %d\n', size(M_VAR,1));
            set(disp_box,'String', M_VAR);
            set(disp_box,'Value', []);

            % Update the ROI x ROI x Subjects number in GUI
            set(disp_str, 'String', strcat(num2str(size(matrix,2)), ' ROIs x',32, num2str(size(matrix,3)),' subjects'));
            set(disp_str, 'ForegroundColor',[0.219, 0.341, 0.137]); 
        end
        
    % Second case: Add new matrices----------------------------------------
    else
        % Select new files via function
        new_M_VAR = select_mat_file();

        % If new files are selected then proceed 
        if ~isempty(new_M_VAR) && numel(new_M_VAR) >= 1 && ~isempty(new_M_VAR{1})
               
            % Check for multiple variables within selected files   
            if multi_var_check(new_M_VAR) ~= 1        
                
                % Validate NEW files only
                for i = 1:size(new_M_VAR,1)
                    tmp = load(new_M_VAR{i,:}); 
                    fn  = fieldnames(tmp); 
                    val = tmp.(fn{1});
                
                    % ---- Strict numeric matrix check ----
                    if ~isnumeric(val)
                        shortwarn(sprintf('File "%s" does not contain a numeric matrix (found %s).', ...
                            new_M_VAR{i,:}, class(val)));
                        return;
                    end
                    if ~ismatrix(val) && ndims(val) ~= 3
                        shortwarn(sprintf('File "%s" must be ROI×ROI or ROI×ROI×Subjects (found %d-D array).', ...
                            new_M_VAR{i,:}, ndims(val)));
                        return;
                    end
                    if size(val,1) ~= size(val,2)
                        shortwarn(sprintf('File "%s" must be square (ROI×ROI or ROI×ROI×Subjects).', new_M_VAR{i,:}));
                        return;
                    end
                    if size(val,1) < 2
                        shortwarn(sprintf('File "%s" has only one ROI. At least 2 ROIs are required for connectivity analyses.', new_M_VAR{i,:}));
                        return;
                    end
                    % -------------------------------------

                    M_new(i).m = val;
                end

                try
                    new_matrices = cat(3,M_new(:).m);
                    if size(new_matrices,1) ~= size(new_matrices,2)
                        shortwarn('Matrices are not square.');
                        return;
                    end

                    % ---- Check consistency with old selection ----
                    if ~isempty(matrix) && size(new_matrices,1) ~= size(matrix,1)
                        shortwarn('New matrices have different number of ROIs than the previously selected ones.');
                        return;
                    end
                    % ----------------------------------------------

                    matrix = cat(3,matrix,new_matrices);
                    M_VAR = vertcat(M_VAR, new_M_VAR);

                    fprintf('Number of .mat files selected: %d\n', size(new_M_VAR,1));
                    set(disp_box,'String', M_VAR);
                    set(disp_box,'Value', []);
                    set(disp_str, 'String', sprintf('%d ROIs x %d subjects', size(matrix,2), size(matrix,3)));
                    set(disp_str, 'ForegroundColor',[0.219, 0.341, 0.137]); 
                    clear M_new new_M_VAR

                catch
                    shortwarn('Matrices have inconsistent dimensions.');
                    clear new_matrices new_M_VAR M_new
                end        
            else
                shortwarn('Selected *.mat file(s) consist(s) of multiple variables, please select *.mat files each containing only one variable.');
            end
        else          
            disp('No files added.');          
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

% Function to perform removal of files from listboxes
function file_remove(sel_box,M_VAR,disp_box,disp_str,case_maker)
    sel_var = get(sel_box,'Value');

    if isempty(sel_var)
        shortwarn('No files selected to remove.');
        return;
    end

    if isempty(M_VAR)
        shortwarn('There are no files to remove.');
        return;
    end
    
    % Remove selected files
    M_VAR(sel_var,:) = [];
    fprintf('Number of .mat files removed: %d\n', numel(sel_var));

    % Rebuild group matrix from remaining files
    matrix = [];
    if ~isempty(M_VAR)
       try
           for i = 1:size(M_VAR,1)
               tmp = load(M_VAR{i,:}); fn = fieldnames(tmp); M(i).m = tmp.(fn{1});
           end
           matrix = cat(3, M(:).m);
           clear M
       catch
           shortwarn('Error rebuilding group matrix after removal.');
           matrix = [];
           clear M
       end
    end
    
    % Update GUI
    set(disp_box,'Value', []);
    set(disp_box,'String', M_VAR);
    
    if isempty(M_VAR)
        set(disp_str, 'String', '0 ROIs x 0 subjects');
        set(disp_str, 'ForegroundColor',[0.773, 0.353, 0.067]);
    else
        nROI = size(matrix,1);
        nSub = size(matrix,3);
        set(disp_str, 'String', sprintf('%d ROIs x %d subjects', nROI, nSub));
        set(disp_str, 'ForegroundColor',[0.219, 0.341, 0.137]);
    end
    
    % Reset current selections
    sel_var = {};
    selection_0 = '';  selection_1 = '';  selection_2 = '';
    
    % Update main variables
    switch (case_maker)
        case 'one_samp_sel'
            M0 = M_VAR;
            matrices_0 = matrix;
        case 'left_samp_sel'
            M1 = M_VAR; if isempty(M1), M1 = {}; end
            matrices_1 = matrix;
        case 'right_samp_sel'
            M2 = M_VAR; if isempty(M2), M2 = {}; end
            matrices_2 = matrix;
    end
end


% Variables to store live selections from lists
function live_select_0(~,~)
    index = get(ST_lst_0, 'Value');% Retrieves the users selection LIVE
    selection_0 = index;                % Variable for full selection
end
function live_select_1(~,~)
    index = get(ST_lst_1, 'Value');% Retrieves the users selection LIVE
    selection_1 = index;                % Variable for full selection
end
function live_select_2(~,~)
    index = get(ST_lst_2, 'Value');% Retrieves the users selection LIVE
    selection_2 = index;                % Variable for full selection
end


% Function to configure GUI based on selected test-type 
function test_type(~,~)
    
    % Extract the current Test mode selected by user
    contender = (ST_test_type.String{ST_test_type.Value});

    % Action relative to test type
    if strcmpi(contender, 'Paired t-test')
        
        % If Paired T Test is selected
        disp('Paired t-test selected.');
        
        % Reset GUI 
        set([ST_lst_0,ST_L0_CTR,ST_L0_SEL,ST_L0_REM],'visible', 'off');        
        set([ST_lst_1,ST_lst_2,ST_L1_CTR,ST_L2_CTR,...
            ST_L1_SEL,ST_L1_REM,ST_L2_SEL,ST_L2_REM],'visible', 'on','enable', 'on'); 
        set([ST_THRES_POP,ST_THRES_TXT,ST_CONT_txt,...
            ST_CONT_val,ST_ALP_txt,ST_ALP_val,RES_RUN],'enable', 'on');
        set([ST_L0_CTR, ST_L1_CTR,ST_L2_CTR], 'String', '0 ROIs x 0 subjects',...
            'ForegroundColor',[0.773, 0.353, 0.067]);
        set([ST_CONT_val, ST_ALP_val], 'String', []);
        
        % Reset Variables 
        M0 = {};
        M1 = {};
        M2 = {};
        selection_0 = '';
        selection_1 = '';
        selection_2 = '';
        covariates_text = '';
        covariates_table = [];
        
        % Reset GUI elements
        set(ST_lst_0,'String', M0,'Value', []);
        set(ST_lst_1,'String', M1,'Value', []);
        set(ST_lst_2,'String', M2,'Value', []);
        set(ST_COV_VAL,'String','');
       
    elseif strcmpi(contender, 'One-sample t-test')
        
        % If One-sample T Test is selected
        disp('One-sample t-test selected.');
        
        % Reset GUI
        set([ST_lst_0,ST_L0_CTR,ST_L0_SEL,ST_L0_REM],'visible', 'on');        
        set([ST_lst_1,ST_lst_2,ST_L1_CTR,ST_L2_CTR,...
            ST_L1_SEL,ST_L1_REM,ST_L2_SEL,ST_L2_REM],'visible', 'off');
        set([ST_L0_CTR, ST_L1_CTR,ST_L2_CTR], 'String', '0 ROIs x 0 subjects',...
            'ForegroundColor',[0.773, 0.353, 0.067]);
        set([ST_CONT_val, ST_ALP_val], 'String', []);
        set([ST_THRES_POP,ST_THRES_TXT,ST_CONT_txt,ST_CONT_val,...
            ST_ALP_txt,ST_ALP_val,RES_RUN],'enable', 'on');
        
        % Reset variables
        M0 = {};
        M1 = {};
        M2 = {};
        selection_0 = '';
        selection_1 = '';
        selection_2 = '';
        covariates_text = '';
        covariates_table = [];
        
        % Reset GUI elements
        set(ST_lst_0,'String', M0,'Value', []);
        set(ST_lst_1,'String', M1,'Value', []);
        set(ST_lst_2,'String', M2,'Value', []);
        set(ST_COV_VAL,'String','');
                
    elseif strcmpi(contender, 'Two-sample t-test')
        
        % If Two-sample T Test is selected
        disp('Two-sample t-test selected.');
        
        % Reset GUI 
        set([ST_lst_0,ST_L0_CTR,ST_L0_SEL,ST_L0_REM],'visible', 'off');    
        set([ST_lst_1,ST_lst_2,ST_L1_CTR,ST_L2_CTR,...
            ST_L1_SEL,ST_L1_REM,ST_L2_SEL,ST_L2_REM],'visible', 'on','enable', 'on');        
        set([ST_L0_CTR, ST_L1_CTR,ST_L2_CTR], 'String', '0 ROIs x 0 subjects',...
            'ForegroundColor',[0.773, 0.353, 0.067]);       
        set([ST_CONT_val, ST_ALP_val], 'String', []);        
        set([ST_THRES_POP,ST_THRES_TXT,ST_CONT_txt,ST_CONT_val,ST_ALP_txt,ST_ALP_val,RES_RUN],'enable', 'on');

        % Reset Variables
        M0 = {};
        M1 = {};
        M2 = {};
        selection_0 = '';
        selection_1 = '';
        selection_2 = '';
        covariates_text = '';
        covariates_table = [];
        
        % Reset GUI elements
        set(ST_lst_0,'String', M0,'Value', []);
        set(ST_lst_1,'String', M1,'Value', []);
        set(ST_lst_2,'String', M2,'Value', []);
        set(ST_COV_VAL,'String','');
    end    
end

function threshold_type(~,~)

    thr_type = ST_THRES_POP.String{ST_THRES_POP.Value};

    is_perm  = any(strcmpi(thr_type, {'Uncorrected (Non-parametric)', ...
                                      'FDR (Non-parametric)', ...
                                      'NBS FWE (Extent)', ...
                                      'NBS FWE (Intensity)', ...
                                      'Threshold-free NBS FWE'}));

    is_nbs   = any(strcmpi(thr_type, {'NBS FWE (Extent)', 'NBS FWE (Intensity)'}));
    is_tfnbs = strcmpi(thr_type, 'Threshold-free NBS FWE');
    is_net   = is_nbs || is_tfnbs;

    % Number of permutations
    if is_perm
        set(ST_PERM_TXT, 'enable', 'on');
        set(ST_PERM_VAL, 'enable', 'on');
    else
        set(ST_PERM_TXT, 'enable', 'off');
        set(ST_PERM_VAL, 'enable', 'off');
    end

    % Primary threshold only for classical NBS
    if is_nbs
        set(ST_THRES_VAL_TXT, 'enable', 'on');
        set(ST_THRES_VAL_UNI, 'enable', 'on');
    else
        set(ST_THRES_VAL_TXT, 'enable', 'off');
        set(ST_THRES_VAL_UNI, 'enable', 'off');
    end

    % E and H only for TFNBS
    if is_tfnbs
        set(ST_E_TXT, 'enable', 'on');
        set(ST_E_VAL, 'enable', 'on');
        set(ST_H_TXT, 'enable', 'on');
        set(ST_H_VAL, 'enable', 'on');
    else
        set(ST_E_TXT, 'enable', 'off');
        set(ST_E_VAL, 'enable', 'off');
        set(ST_H_TXT, 'enable', 'off');
        set(ST_H_VAL, 'enable', 'off');
    end

    % Parallel only for NBS / TFNBS
    if is_net
        set(ST_PAR_TXT, 'enable', 'on');
        set(ST_PAR_CHK, 'enable', 'on');
    else
        set(ST_PAR_TXT, 'enable', 'off');
        set(ST_PAR_CHK, 'enable', 'off');
    end

    set(RES_RUN, 'enable', 'on');
end

% Run 
% Run Test
function run(~,~)
    test_type = (ST_test_type.String{ST_test_type.Value}); 
    alpha = safe_str2num_scalar(ST_ALP_val.String);
    thr_type = (ST_THRES_POP.String{ST_THRES_POP.Value});
    thr_key = threshold_key(thr_type);

    if isempty(thr_key)
        shortwarn('Selected threshold type is not supported for this analysis.');
        return;
    end

    val_contrast = str2num(ST_CONT_val.String);
    nperm      = str2double(ST_PERM_VAL.String);
    primary_p  = safe_str2num_scalar(ST_THRES_VAL_UNI.String);
    E          = safe_str2num_scalar(ST_E_VAL.String);
    H          = safe_str2num_scalar(ST_H_VAL.String);
    nSteps     = 100;
    start_t    = 0;
    use_parfor = logical(get(ST_PAR_CHK,'Value'));

    % Check covariates
    [use_glm, C, cov_ok] = get_current_covariates();
    if ~cov_ok
        return;
    end

    %----------------------------------------------------------------------
    % PAIRED T-TEST
    %----------------------------------------------------------------------
    if strcmpi(test_type, 'Paired t-test')
        if ~isempty(M1) && ~isempty(M2)

            flag_parameters = parameter_check();
            if flag_parameters == 1
                flag_thres_parameters = perm_thres_check();
                if flag_thres_parameters == 1

                    % Validate ROI dimensions
                    if isempty(matrices_1) || isempty(matrices_2)
                        shortwarn('Matrices are empty.');
                        return;
                    end
                    if size(matrices_1,1) ~= size(matrices_2,1) || size(matrices_1,2) ~= size(matrices_2,2)
                        shortwarn('The ROI×ROI dimensions differ between the two lists. Please select matrices with the same number of ROIs.');
                        set([ST_L1_CTR,ST_L2_CTR], 'ForegroundColor',[0.773, 0.353, 0.067]);
                        return;
                    end

                    % Validate subject counts for pairing
                    n1 = size(matrices_1,3);
                    n2 = size(matrices_2,3);
                    if n1 ~= n2
                        shortwarn(sprintf('Paired t-test requires the same number of subjects. Left: %d, Right: %d.', n1, n2));
                        set([ST_L1_CTR,ST_L2_CTR], 'ForegroundColor',[0.773, 0.353, 0.067]);
                        return;
                    end

                    set([ST_L1_CTR,ST_L2_CTR], 'ForegroundColor',[0.219, 0.341, 0.137]);
                    components = [];
                    score = [];

                    if use_glm
                        [glm_matrices, X, c_glm, exchange] = prepare_glm_inputs(test_type, val_contrast, C);

                        if strcmp(thr_key,'perm_uncorr') || strcmp(thr_key,'perm_FDR')
                            [sig,pval,tval,conval] = tmfc_glm_perm(glm_matrices, X, c_glm, alpha, thr_key, nperm, exchange);

                        elseif strcmp(thr_key,'NBS_extent') || strcmp(thr_key,'NBS_intensity')
                            [sig,pval,tval,conval,components] = tmfc_glm_nbs( ...
                                glm_matrices, X, c_glm, alpha, primary_p, nperm, thr_key, exchange, use_parfor);

                        elseif strcmp(thr_key,'TFNBS')
                            [sig,pval,tval,conval,score] = tmfc_glm_tfnbs( ...
                                glm_matrices, X, c_glm, alpha, nperm, E, H, nSteps, start_t, exchange, use_parfor);

                        else
                            [sig,pval,tval,conval] = tmfc_glm(glm_matrices, X, c_glm, alpha, thr_key);
                        end

                    else
                        groups = {matrices_1, matrices_2};

                        if strcmp(thr_key,'perm_uncorr') || strcmp(thr_key,'perm_FDR')
                            [sig,pval,tval,conval] = tmfc_ttest_perm(groups, val_contrast, alpha, thr_key, nperm);

                        elseif strcmp(thr_key,'NBS_extent') || strcmp(thr_key,'NBS_intensity')
                            [sig,pval,tval,conval,components] = tmfc_ttest_nbs( ...
                                groups, val_contrast, alpha, primary_p, nperm, thr_key, use_parfor);

                        elseif strcmp(thr_key,'TFNBS')
                            [sig,pval,tval,conval,score] = tmfc_ttest_tfnbs( ...
                                groups, val_contrast, alpha, nperm, E, H, nSteps, start_t, use_parfor);

                        else
                            [sig,pval,tval,conval] = tmfc_ttest(groups, val_contrast, alpha, thr_key);
                        end
                    end

                    fprintf('Generating results...\n');
                    tmfc_results_GUI(sig,pval,tval,conval,alpha,thr_type,nperm,components,score);
                    clear sig pval tval conval alpha thr_key thr_type nperm components score
                end
            end

        elseif ~isempty(M1) && isempty(M2)
            shortwarn('Please select the second set of matrix files to run a paired t-test.');
        elseif isempty(M1) && ~isempty(M2)
            shortwarn('Please select the first set of matrix files to run a paired t-test.');
        else
            shortwarn('Please select matrix files to run a paired t-test.');
        end

    %----------------------------------------------------------------------
    % ONE-SAMPLE T-TEST
    %----------------------------------------------------------------------
    elseif strcmpi(test_type, 'One-sample t-test')

        if ~isempty(M0)
            flag_parameters = parameter_check();
            if flag_parameters == 1
                flag_thres_parameters = perm_thres_check();
                if flag_thres_parameters == 1
                    set(ST_L0_CTR, 'ForegroundColor',[0.219, 0.341, 0.137]);
                    components = [];
                    score = [];

                    if use_glm
                        [glm_matrices, X, c_glm, exchange] = prepare_glm_inputs(test_type, val_contrast, C);

                        if strcmp(thr_key,'perm_uncorr') || strcmp(thr_key,'perm_FDR')
                            [sig,pval,tval,conval] = tmfc_glm_perm(glm_matrices, X, c_glm, alpha, thr_key, nperm, exchange);

                        elseif strcmp(thr_key,'NBS_extent') || strcmp(thr_key,'NBS_intensity')
                            [sig,pval,tval,conval,components] = tmfc_glm_nbs( ...
                                glm_matrices, X, c_glm, alpha, primary_p, nperm, thr_key, exchange, use_parfor);

                        elseif strcmp(thr_key,'TFNBS')
                            [sig,pval,tval,conval,score] = tmfc_glm_tfnbs( ...
                                glm_matrices, X, c_glm, alpha, nperm, E, H, nSteps, start_t, exchange, use_parfor);

                        else
                            [sig,pval,tval,conval] = tmfc_glm(glm_matrices, X, c_glm, alpha, thr_key);
                        end

                    else
                        if strcmp(thr_key,'perm_uncorr') || strcmp(thr_key,'perm_FDR')
                            [sig,pval,tval,conval] = tmfc_ttest_perm(matrices_0, val_contrast, alpha, thr_key, nperm);

                        elseif strcmp(thr_key,'NBS_extent') || strcmp(thr_key,'NBS_intensity')
                            [sig,pval,tval,conval,components] = tmfc_ttest_nbs( ...
                                matrices_0, val_contrast, alpha, primary_p, nperm, thr_key, use_parfor);

                        elseif strcmp(thr_key,'TFNBS')
                            [sig,pval,tval,conval,score] = tmfc_ttest_tfnbs( ...
                                matrices_0, val_contrast, alpha, nperm, E, H, nSteps, start_t, use_parfor);

                        else
                            [sig,pval,tval,conval] = tmfc_ttest(matrices_0, val_contrast, alpha, thr_key);
                        end
                    end

                    fprintf('Generating results...\n');
                    tmfc_results_GUI(sig,pval,tval,conval,alpha,thr_type,nperm,components,score);
                    clear sig pval tval conval alpha thr_key thr_type nperm components score
                end
            end

        else
            shortwarn('Please select matrix files to run a one-sample t-test.');
        end

    %----------------------------------------------------------------------
    % TWO-SAMPLE T-TEST
    %----------------------------------------------------------------------
    elseif strcmpi(test_type, 'Two-sample t-test')

        if ~isempty(M1) && ~isempty(M2)
            flag_parameters = parameter_check();
            if flag_parameters == 1
                flag_thres_parameters = perm_thres_check();
                if flag_thres_parameters == 1

                    if isempty(matrices_1) || isempty(matrices_2)
                        shortwarn('Matrices are empty.');
                        return;
                    end
                    if size(matrices_1,1) ~= size(matrices_2,1) || size(matrices_1,2) ~= size(matrices_2,2)
                        shortwarn('The ROI×ROI dimensions differ between the two lists. Please select matrices with the same number of ROIs.');
                        set([ST_L1_CTR,ST_L2_CTR], 'ForegroundColor',[0.773, 0.353, 0.067]);
                        return;
                    end

                    set([ST_L1_CTR,ST_L2_CTR], 'ForegroundColor',[0.219, 0.341, 0.137]);
                    components = [];
                    score = [];

                    if use_glm
                        [glm_matrices, X, c_glm, exchange] = prepare_glm_inputs(test_type, val_contrast, C);

                        if strcmp(thr_key,'perm_uncorr') || strcmp(thr_key,'perm_FDR')
                            [sig,pval,tval,conval] = tmfc_glm_perm(glm_matrices, X, c_glm, alpha, thr_key, nperm, exchange);

                        elseif strcmp(thr_key,'NBS_extent') || strcmp(thr_key,'NBS_intensity')
                            [sig,pval,tval,conval,components] = tmfc_glm_nbs( ...
                                glm_matrices, X, c_glm, alpha, primary_p, nperm, thr_key, exchange, use_parfor);

                        elseif strcmp(thr_key,'TFNBS')
                            [sig,pval,tval,conval,score] = tmfc_glm_tfnbs( ...
                                glm_matrices, X, c_glm, alpha, nperm, E, H, nSteps, start_t, exchange, use_parfor);

                        else
                            [sig,pval,tval,conval] = tmfc_glm(glm_matrices, X, c_glm, alpha, thr_key);
                        end

                    else
                        groups = {matrices_1, matrices_2};

                        if strcmp(thr_key,'perm_uncorr') || strcmp(thr_key,'perm_FDR')
                            [sig,pval,tval,conval] = tmfc_ttest2_perm(groups, val_contrast, alpha, thr_key, nperm);

                        elseif strcmp(thr_key,'NBS_extent') || strcmp(thr_key,'NBS_intensity')
                            [sig,pval,tval,conval,components] = tmfc_ttest2_nbs( ...
                                groups, val_contrast, alpha, primary_p, nperm, thr_key, use_parfor);

                        elseif strcmp(thr_key,'TFNBS')
                            [sig,pval,tval,conval,score] = tmfc_ttest2_tfnbs( ...
                                groups, val_contrast, alpha, nperm, E, H, nSteps, start_t, use_parfor);

                        else
                            [sig,pval,tval,conval] = tmfc_ttest2(groups, val_contrast, alpha, thr_key);
                        end
                    end

                    fprintf('Generating results...\n');
                    tmfc_results_GUI(sig,pval,tval,conval,alpha,thr_type,nperm,components,score);
                    clear sig pval tval conval alpha thr_key thr_type nperm components score
                end
            end

        elseif ~isempty(M1) && isempty(M2)
            shortwarn('Please select the second set of matrix files to run a two-sample t-test.');
        elseif isempty(M1) && ~isempty(M2)
            shortwarn('Please select the first set of matrix files to run a two-sample t-test.');
        else
            shortwarn('Please select matrix files to run a two-sample t-test.');
        end
    else
        shortwarn('Files must be ROI×ROI or ROI×ROI×Subjects.');
    end
end

% Parallel computations on/off
function toggle_parallel(src,~)
    if get(src,'Value') == 1
        set(src,'String','On');
    else
        set(src,'String','Off');
    end
end

% Check inputs
function flag = parameter_check(~,~)
    flag = 0;

    test_type = (ST_test_type.String{ST_test_type.Value});
    val_contrast = str2num(ST_CONT_val.String);
    val_alpha = safe_str2num_scalar(ST_ALP_val.String);

    if isempty(val_contrast)
        shortwarn('Please enter numeric values for the contrast.');
        return;
    end

    if isempty(val_alpha) || ~isscalar(val_alpha) || ~isfinite(val_alpha) || val_alpha < 0 || val_alpha > 1
        shortwarn('Please enter an alpha value between 0 and 1.');
        return;
    end

    % Determine whether covariates are present
    nCov = 0;
    txt = strtrim(get(ST_COV_VAL,'String'));

    if ~isempty(txt) || ~isempty(covariates_table)
        nRows = get_expected_nrows();
        if isempty(nRows) || nRows < 1
            shortwarn('Please select matrix files first.');
            return;
        end

        if ~isempty(txt)
            [Ctmp, ok, msg] = parse_covariates_input(txt, nRows);
            if ~ok
                shortwarn(msg);
                return;
            end
        else
            Ctmp = covariates_table;
        end

        if ~isempty(Ctmp)
            if all(isnan(Ctmp(:)))
                nCov = 0;
            else
                if any(~isfinite(Ctmp(:))) || any(isnan(Ctmp(:)))
                    shortwarn('Covariates must contain only finite numeric values.');
                    return;
                end
                nCov = size(Ctmp,2);
            end
        end
    end

    % Expected contrast length
    if nCov == 0
        if strcmpi(test_type, 'One-sample t-test')
            expected_len = 1;
        else
            expected_len = 2;
        end
    else
        if strcmpi(test_type, 'One-sample t-test')
            expected_len = 1 + nCov;
        else
            expected_len = 2 + nCov;
        end
    end

    if numel(val_contrast) ~= expected_len
        if nCov == 0
            if strcmpi(test_type, 'One-sample t-test')
                shortwarn('Please enter one contrast value.');
            else
                shortwarn('Please enter two contrast values.');
            end
        else
            shortwarn(sprintf('Please enter %d contrast values.', expected_len));
        end
        return;
    end

    if all(val_contrast == 0)
        shortwarn('Contrast must contain at least one non-zero value.');
        return;
    end

    flag = 1;
end 

% Handle alpha input
function x = safe_str2num_scalar(s)
    s = strtrim(s);
    if isempty(s), x = NaN; return; end
    % allow digits, decimal, + - * / ^, parentheses, whitespace, and e/E for exponents
    if isempty(regexp(s,'^[\d\.\+\-\*\/\^\(\)\seE]+$','once'))
        x = NaN; return;
    end
    tmp = str2num(s); 
    if isempty(tmp) || ~isscalar(tmp) || ~isfinite(tmp)
        x = NaN; return;
    end
    x = tmp;
end

% Validate permutation / primary threshold inputs 
function flag = perm_thres_check(~,~)
    flag = 0;
    thr_type = ST_THRES_POP.String{ST_THRES_POP.Value};

    switch thr_type
        case {'Uncorrected (Non-parametric)', 'FDR (Non-parametric)'}
            permutation_value = str2double(ST_PERM_VAL.String);
            is_posint = ~isnan(permutation_value) && permutation_value > 0 && mod(permutation_value,1)==0;

            if is_posint
                flag = 1;
            else
                shortwarn('Please enter a positive integer for the number of permutations.');
            end

        case {'NBS FWE (Extent)', 'NBS FWE (Intensity)'}
            permutation_value = str2double(ST_PERM_VAL.String);
            is_posint = ~isnan(permutation_value) && permutation_value > 0 && mod(permutation_value,1)==0;

            threshold_value = safe_str2num_scalar(ST_THRES_VAL_UNI.String);
            is_valid_thresh = ~isnan(threshold_value) && threshold_value > 0 && threshold_value < 1.0;

            if ~is_posint
                shortwarn('Please enter a positive integer for the number of permutations.');
            elseif ~is_valid_thresh
                shortwarn('Please enter a primary threshold (p-value) between 0 and 1.');
            else
                flag = 1;
            end

        case 'Threshold-free NBS FWE'
            permutation_value = str2double(ST_PERM_VAL.String);
            is_posint = ~isnan(permutation_value) && permutation_value > 0 && mod(permutation_value,1)==0;

            e_value = safe_str2num_scalar(ST_E_VAL.String);
            h_value = safe_str2num_scalar(ST_H_VAL.String);

            is_valid_e = ~isnan(e_value) && isfinite(e_value) && e_value > 0;
            is_valid_h = ~isnan(h_value) && isfinite(h_value) && h_value > 0;

            if ~is_posint
                shortwarn('Please enter a positive integer for the number of permutations.');
            elseif ~is_valid_e
                shortwarn('Please enter a positive numeric value for Extension parameter (E).');
            elseif ~is_valid_h
                shortwarn('Please enter a positive numeric value for Height parameter (H).');
            else
                flag = 1;
            end

        case {'Uncorrected (Parametric)', 'FDR (Parametric)', 'Bonferroni (Parametric)'}
            flag = 1;

        otherwise
            shortwarn('Unsupported threshold type.');
    end
end

%% Add covariates
function covariates_button(~,~)

    nRows = get_expected_nrows();
    if isempty(nRows) || nRows < 1
        shortwarn('Please select matrix files first. The number of covariate rows must match the number of subjects (or subject pairs).');
        return;
    end

    % First try to initialize from the text field
    txt = strtrim(get(ST_COV_VAL,'String'));

    if ~isempty(txt)
        [parsed_cov, ok, msg] = parse_covariates_input(txt, nRows);
        if ~ok
            shortwarn(msg);
            return;
        end
        covariates_table = parsed_cov;
        covariates_text = txt;
    elseif isempty(covariates_table)
        covariates_table = nan(nRows,1);
    else
        if size(covariates_table,1) ~= nRows
            covariates_table = nan(nRows, max(1,size(covariates_table,2)));
        end
    end

    selected_cell = [1 1];

    cov_fig = figure('Name','Covariates','NumberTitle','off','MenuBar','none','ToolBar','none', ...
        'Units','normalized','Position',[0.40 0.25 0.26 0.40],'Color','w','Resize','off', ...
        'WindowKeyPressFcn', @cov_fig_keypress);

    movegui(cov_fig,'center');

    uicontrol(cov_fig,'Style','text','String',sprintf('Rows required: %d', nRows), ...
        'Units','normalized','Position',[0.08 0.91 0.40 0.05], ...
        'BackgroundColor','w','HorizontalAlignment','left','FontUnits','normalized','FontSize',0.45);

    uit = uitable(cov_fig,'Data',covariates_table,'Units','normalized', ...
        'Position',[0.08 0.22 0.84 0.66], ...
        'ColumnEditable',true(1,size(covariates_table,2)), ...
        'CellSelectionCallback', @table_cell_select);

    uicontrol(cov_fig,'Style','pushbutton','String','Add column', ...
        'Units','normalized','Position',[0.08 0.09 0.18 0.07], ...
        'Callback',@(src,evt) add_cov_column());

    uicontrol(cov_fig,'Style','pushbutton','String','Remove column', ...
        'Units','normalized','Position',[0.29 0.09 0.18 0.07], ...
        'Callback',@(src,evt) remove_cov_column());

    uicontrol(cov_fig,'Style','pushbutton','String','Paste', ...
        'Units','normalized','Position',[0.50 0.09 0.16 0.07], ...
        'Callback',@(src,evt) paste_from_clipboard());

    uicontrol(cov_fig,'Style','pushbutton','String','OK', ...
        'Units','normalized','Position',[0.70 0.09 0.22 0.07], ...
        'Callback',@(src,evt) accept_covariates());

    function table_cell_select(~, evt)
        if ~isempty(evt.Indices)
            selected_cell = evt.Indices(1,:);
        end
    end

    function cov_fig_keypress(~, evt)
        if ~isempty(evt.Modifier) && any(strcmpi(evt.Modifier,'control')) && strcmpi(evt.Key,'v')
            paste_from_clipboard();
        end
    end

    function add_cov_column()
        dat = get(uit,'Data');
        if isempty(dat)
            dat = nan(nRows,1);
        else
            dat(:,end+1) = nan(nRows,1);
        end
        set(uit,'Data',dat,'ColumnEditable',true(1,size(dat,2)));
    end

    function remove_cov_column()
        dat = get(uit,'Data');
        if isempty(dat) || size(dat,2) <= 1
            dat = nan(nRows,1);
        else
            dat(:,end) = [];
        end
        set(uit,'Data',dat,'ColumnEditable',true(1,size(dat,2)));
    end

    function paste_from_clipboard()

        try
            clip = clipboard('paste');
        catch
            shortwarn('Cannot access clipboard.');
            return;
        end

        [block, ok, msg] = parse_clipboard_numeric_block(clip);
        if ~ok
            shortwarn(msg);
            return;
        end

        dat = get(uit,'Data');
        if isempty(dat)
            dat = nan(nRows, size(block,2));
        end

        r0 = selected_cell(1);
        c0 = selected_cell(2);

        r1 = r0 + size(block,1) - 1;
        c1 = c0 + size(block,2) - 1;

        % Expand table if needed
        if size(dat,1) < r1
            dat(end+1:r1,1:size(dat,2)) = nan;
        end
        if size(dat,2) < c1
            dat(:,end+1:c1) = nan;
        end

        dat(r0:r1, c0:c1) = block;

        if size(dat,1) ~= nRows
            shortwarn(sprintf('Pasted data must fit %d rows.', nRows));
            return;
        end

        set(uit,'Data',dat,'ColumnEditable',true(1,size(dat,2)));
    end

    function accept_covariates()
        dat = get(uit,'Data');
        covariates_table = dat;
        covariates_text = matrix_to_cov_string(dat);
        set(ST_COV_VAL,'String',covariates_text);
        if isgraphics(cov_fig)
            close(cov_fig);
        end
    end
end

function [C, ok, msg] = parse_covariates_input(txt, nRows)

    C = [];
    ok = false;
    msg = '';

    txt = strtrim(txt);
    if isempty(txt)
        C = nan(nRows,1);
        ok = true;
        return;
    end

    % First try: direct numeric / MATLAB expression
    try
        C = eval(txt);
    catch
        C = [];
    end

    % Second try: pasted block from Excel/txt
    if isempty(C)
        try
            txt2 = strrep(txt, sprintf('\r'), '');
            txt2 = strrep(txt2, sprintf('\t'), ' ');
            C = str2num(txt2); 
        catch
            C = [];
        end
    end

    if ~isnumeric(C) || isempty(C) || ~ismatrix(C) || any(~isfinite(C(:)))
        msg = 'Covariates must evaluate to a finite numeric 2D matrix.';
        return;
    end

    % If user entered a row vector matching nRows, convert to column
    if size(C,1) == 1 && size(C,2) == nRows
        C = C.';
    end

    if size(C,1) ~= nRows
        msg = sprintf('Covariates must have %d row(s).', nRows);
        return;
    end

    ok = true;
end

function [M, ok, msg] = parse_clipboard_numeric_block(txt)

    M = [];
    ok = false;
    msg = '';

    if isempty(txt)
        msg = 'Clipboard is empty.';
        return;
    end

    try
        % Normalize line endings
        txt = strrep(txt, sprintf('\r\n'), sprintf('\n'));
        txt = strrep(txt, sprintf('\r'), sprintf('\n'));

        % Split into rows and remove empty trailing rows
        rows = regexp(txt, '\n', 'split');
        rows = rows(~cellfun(@(x) isempty(strtrim(x)), rows));

        if isempty(rows)
            msg = 'Clipboard does not contain a valid numeric block.';
            return;
        end

        split_rows = cell(numel(rows),1);
        nCols = 0;

        for i = 1:numel(rows)
            cells_i = regexp(rows{i}, '\t', 'split');

            % remove trailing empty cells
            while ~isempty(cells_i) && isempty(cells_i{end})
                cells_i(end) = [];
            end

            split_rows{i} = cells_i;
            nCols = max(nCols, numel(cells_i));
        end

        if nCols == 0
            msg = 'Clipboard does not contain a valid numeric block.';
            return;
        end

        M = nan(numel(rows), nCols);

        for i = 1:numel(rows)
            cells_i = split_rows{i};
            for j = 1:numel(cells_i)
                token = strtrim(cells_i{j});

                if isempty(token)
                    M(i,j) = NaN;
                else
                    % optional support for decimal comma
                    token = strrep(token, ',', '.');

                    val = str2double(token);
                    if isnan(val)
                        msg = 'Clipboard contains non-numeric values.';
                        M = [];
                        ok = false;
                        return;
                    end
                    M(i,j) = val;
                end
            end
        end

        ok = true;

    catch
        M = [];
        ok = false;
        msg = 'Clipboard does not contain a valid numeric block.';
    end
end

function nRows = get_expected_nrows()

    nRows = [];

    test_strings = get(ST_test_type,'String');
    test_value   = get(ST_test_type,'Value');
    contender    = test_strings{test_value};

    if strcmpi(contender,'One-sample t-test')
        if ~isempty(matrices_0)
            nRows = size(matrices_0,3);
        end

    elseif strcmpi(contender,'Paired t-test')
        if ~isempty(matrices_1) && ~isempty(matrices_2)
            if size(matrices_1,3) == size(matrices_2,3)
                nRows = size(matrices_1,3);
            end
        end

    elseif strcmpi(contender,'Two-sample t-test')
        if ~isempty(matrices_1) && ~isempty(matrices_2)
            nRows = size(matrices_1,3) + size(matrices_2,3);
        end
    end
end

function txt = matrix_to_cov_string(M)
    if isempty(M)
        txt = '';
        return;
    end

    C = cell(size(M,1),1);
    for ii = 1:size(M,1)
        rowtxt = strtrim(sprintf('%.10g ', M(ii,:)));
        C{ii} = rowtxt;
    end
    txt = strjoin(C, '; ');
end

function covariates_edit_callback(~,~)
    covariates_text = get(ST_COV_VAL,'String');
end

function [use_glm, C, ok] = get_current_covariates()

    use_glm = false;
    C = [];
    ok = true;

    nRows = get_expected_nrows();

    txt = strtrim(get(ST_COV_VAL,'String'));

    if isempty(txt) && isempty(covariates_table)
        return;
    end

    if ~isempty(txt)
        [C, ok, msg] = parse_covariates_input(txt, nRows);
        if ~ok
            shortwarn(msg);
            return;
        end
    else
        C = covariates_table;
    end

    if isempty(C)
        return;
    end

    if size(C,1) ~= nRows
        shortwarn(sprintf('Covariates must have %d row(s).', nRows));
        ok = false;
        return;
    end

    % treat all-NaN table as "no covariates"
    if all(isnan(C(:)))
        C = [];
        return;
    end

    if any(~isfinite(C(:))) || any(isnan(C(:)))
        shortwarn('Covariates must contain only finite numeric values.');
        ok = false;
        return;
    end

    use_glm = true;
end

    function [glm_matrices, X, c_glm, exchange] = prepare_glm_inputs(test_name, user_contrast, C)

    exchange = [];
    nCov = size(C,2);

    switch lower(test_name)

        case 'one-sample t-test'
            % GUI contrast:
            % [main cov1 cov2 ...]
            %
            % GLM design:
            % [intercept cov1 cov2 ...]
            %
            % Same contrast directly
            glm_matrices = matrices_0;
            X = [ones(size(glm_matrices,3),1), C];
            c_glm = user_contrast(:);

        case 'paired t-test'
            % GUI contrast:
            % [cond1 cond2 cov1 cov2 ...]
            %
            % Internal paired GLM here is run on difference matrices:
            % D = cond1*A + cond2*B
            % GLM design:
            % [intercept cov1 cov2 ...]
            %
            % Main paired effect example:
            % [1 -1 0 0] -> D = A - B, test intercept
            %
            % Covariate effect example:
            % [0 0 1 0] -> D = 0*A + 0*B, impossible for difference-based GLM
            %
            % Therefore, for paired GLM in this simplified GUI implementation,
            % the first two weights must define the paired difference.

            if numel(user_contrast) ~= 2 + nCov
                error('Paired GLM contrast must contain 2 + number_of_covariates values.');
            end

            pair_weights = user_contrast(1:2);
            cov_weights  = user_contrast(3:end);

            if all(pair_weights == 0)
                shortwarn('For paired tests with covariates, the first two contrast weights cannot both be zero in this GUI implementation.');
                error('Invalid paired GLM contrast.');
            end

            glm_matrices = pair_weights(1)*matrices_1 + pair_weights(2)*matrices_2;
            X = [ones(size(glm_matrices,3),1), C];
            c_glm = [1; cov_weights(:)];

        case 'two-sample t-test'
            % GUI contrast:
            % [group1 group2 cov1 cov2 ...]
            %
            % GLM design:
            % [intercept group cov1 cov2 ...]
            %
            % Main effect:
            % [1 -1 0 0] -> [0 1 0 0]
            % [-1 1 0 0] -> [0 -1 0 0]
            % Covariate:
            % [0 0 1 0]  -> [0 0 1 0]

            if numel(user_contrast) ~= 2 + nCov
                error('Two-sample GLM contrast must contain 2 + number_of_covariates values.');
            end

            n1 = size(matrices_1,3);
            n2 = size(matrices_2,3);

            glm_matrices = cat(3, matrices_1, matrices_2);

            group = [ones(n1,1); zeros(n2,1)];
            X = [ones(n1+n2,1), group, C];

            main_weights = user_contrast(1:2);
            cov_weights  = user_contrast(3:end);

            c_glm = [0; main_weights(1) - main_weights(2); cov_weights(:)];

        otherwise
            error('Unsupported test type.');
    end
end

threshold_type();
uiwait(stats_GUI);

function on_close(h, ~)
    try, uiresume(h); end
    delete(h);
end

end

%% Select *.mat files 
function list_sel = select_mat_file(~,~)

    [files, path] = uigetfile('*.mat', 'Select matrix files', 'MultiSelect', 'on');

    if isequal(files,0)
        list_sel = {};
        return;
    end

    if ischar(files)
        files = {files};
    end

    list_sel = fullfile(path, files).';
end

%% Check if the selected *.mat files contain multiple variables
%  0 = single variable in all files
%  1 = at least one file has 0 or >1 variables
% -1 = empty input (no files)
function flag = multi_var_check(input_file)
    if isempty(input_file) || isempty(input_file{1})
        flag = -1;  % nothing to check
        return;
    end
    flag = 0; 
    for i = 1:size(input_file,1)
        fname = input_file{i,:};
        try
            varlist = who('-file', fname);
        catch 
            shortwarn(sprintf('Cannot read file "%s" as a valid MAT-file.', fname));
            flag = 1;
            return;
        end

        if isempty(varlist)
            shortwarn(sprintf('No variables found in file: %s', fname));
            flag = 1;
            return;
        elseif numel(varlist) > 1
            shortwarn(sprintf('Multiple variables found in file: %s', fname));
            flag = 1;
            return;
        end
    end
end

%% Threshold type: Long title -> Short title 
function thr_key = threshold_key(thr_type)
    thr_key = '';
    switch thr_type
        case 'Uncorrected (Parametric)'
            thr_key = 'uncorr';
        case 'FDR (Parametric)'
            thr_key = 'FDR';
        case 'Bonferroni (Parametric)'
            thr_key = 'Bonf';
        case 'Uncorrected (Non-parametric)'
            thr_key = 'perm_uncorr';
        case 'FDR (Non-parametric)'
            thr_key = 'perm_FDR';
        case 'NBS FWE (Extent)'
            thr_key = 'NBS_extent';
        case 'NBS FWE (Intensity)'
            thr_key = 'NBS_intensity';
        case 'Threshold-free NBS FWE'
            thr_key = 'TFNBS';
    end
end

%% Short warning
function shortwarn(msg)
    s = warning('query','backtrace');
    warning('off','backtrace');
    warning(msg);
    warning(s.state,'backtrace');
end


