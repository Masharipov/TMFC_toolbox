function [conditions] = tmfc_conditions_GUI(SPM_path,input_case)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window to select conditions of interest.
% 
% FORMAT [conditions] = tmfc_conditions_GUI(SPM_path, input_case)
%   SPM_path          - Path to individual subject SPM.mat file
%   input_case        - Selection mode (three options):
%                       1 = Specify ROI set
%                       2 = gPPI and gPPI-FIR
%                       3 = LSS and LSS after FIR
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% Get all conditions from the SPM.mat file
all_cond = generate_conditions(SPM_path);

% Check if SPM.mat is not empty
if isempty(all_cond)
    error('Selected SPM.mat file is empty or invalid.');
else
    % Select conditions via GUI
    conditions = conditions_GUI(all_cond, input_case);
end
end


%% =========[ Select conditions of interest for analysis via GUI ]=========
function [conditions] = conditions_GUI(all_cond, input_case)

    cond_L1 = {};       % Variable to store all conditions in GUI 
    cond_L2 = {};       % Variable to store selected conditions in GUI 
    conditions_MW_SE1 = {};   % Variable to store the selected list of conditions in BOX 1 (as INDEX)
    conditions_MW_SE2 = {};   % Variable to store the selected list of conditions in BOX 2 (as INDEX)

    switch(input_case)
        case 1
            MW_string = 'Select ROIs: Select conditions';
            HW_string = 'Select ROIs: Help';
        case 2
            MW_string = 'gPPI: Select conditions';
            HW_string = 'gPPI: Help';  
        case 3
            MW_string = 'LSS: Select conditions';
            HW_string = 'LSS: Help';
            all_cond([all_cond(:).pmod]~=1 | [all_cond(:).bf]~=1)=[];
    end


    for iCond = 1:length(all_cond)
        cond_L1 = vertcat(cond_L1, all_cond(iCond).list_name);        
    end
    
    conditions_MW = figure('Name', MW_string, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.45 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','on','WindowStyle','modal','CloseRequestFcn', @MW_exit);

    if isunix; fontscale0 = 0.9; else; fontscale0 = 1; end

    cond_MW_S1  = uicontrol(conditions_MW,'Style','text','String', 'Select conditions of interest','Units', 'normalized', 'Position',[0.270 0.93 0.490 0.05],'fontunits','normalized', 'fontSize', 0.50*fontscale0,'backgroundcolor','w');
    cond_MW_S2  = uicontrol(conditions_MW,'Style','text','String', 'All conditions:','Units', 'normalized', 'Position',[0.045 0.88 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
    cond_MW_S3  = uicontrol(conditions_MW,'Style','text','String', 'Conditions of interest:','Units', 'normalized', 'Position',[0.045 0.425 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
    cond_MW_LB1 = uicontrol(conditions_MW , 'Style', 'listbox', 'String', cond_L1,'Max', 1000,'Units', 'normalized', 'Position',[0.045 0.59 0.900 0.300],'fontunits','points', 'fontSize', 11,'Value', [],'callback', @MW_LB1_select);
    cond_MW_LB2 = uicontrol(conditions_MW , 'Style', 'listbox', 'String', cond_L2,'Max', 1000,'Units', 'normalized', 'Position',[0.045 0.135 0.900 0.300],'fontunits','points', 'fontSize', 11,'Value', [],'callback', @MW_LB2_select);

    cond_MW_add = uicontrol(conditions_MW,'Style','pushbutton','String', 'Add selected','Units', 'normalized','Position',[0.045 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_add);
    cond_MW_add_all = uicontrol(conditions_MW,'Style','pushbutton','String', 'Add all','Units', 'normalized','Position',[0.360 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_add_all); 
    cond_MW_help = uicontrol(conditions_MW,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.680 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_help); 

    cond_MW_confirm = uicontrol(conditions_MW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.045 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_confirm); 
    cond_MW_remove = uicontrol(conditions_MW,'Style','pushbutton','String', 'Remove selected','Units', 'normalized','Position',[0.360 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_remove); 
    cond_MW_remove_all = uicontrol(conditions_MW,'Style','pushbutton','String', 'Remove all','Units', 'normalized','Position',[0.680 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32,'callback', @MW_remove_all);
    movegui(conditions_MW,'center');

    %----------------------------------------------------------------------
    % Function to close conditions GUI without selection of conditions
    %----------------------------------------------------------------------
    function MW_exit(~,~)
        conditions = NaN;
        uiresume(conditions_MW);
    end

    %----------------------------------------------------------------------
    function MW_LB1_select(~,~)
        index = get(cond_MW_LB1, 'Value'); 
        conditions_MW_SE1 = index;      
    end

    %----------------------------------------------------------------------
    function MW_LB2_select(~,~)
        index = get(cond_MW_LB2, 'Value');  
        conditions_MW_SE2 = index;             
    end

    %----------------------------------------------------------------------
    % Function to add single condition
    %----------------------------------------------------------------------
    function MW_add(~,~)
        
        if isempty(conditions_MW_SE1)
            fprintf(2,'No conditions selected.\n');
        else
            len_exist = length(cond_L2);     
            new_conds = {};                  

            % Based on the selection add variables to a selected list
            new_conds = vertcat(new_conds,cond_L1(conditions_MW_SE1)); 

            % Addition & extraction of unique selected conditions
            cond_L2 = vertcat(cond_L2,new_conds);
            new_cond_count = length(unique(cond_L2)) - len_exist;
            cond_L2 = unique(cond_L2);

            % Check if newly selected conditions have been added
            if new_cond_count == 0
                fprintf(2,'Newly selected conditions are already present in the list, no new conditions added.\n');
            else
                fprintf('Conditions selected: %d. \n', new_cond_count(1)); 
                cond_L2 = sort_selected_conditions(cond_L2,all_cond);
            end 

            % Set sorted list of conditions into GUI
            set(cond_MW_LB2,'String',cond_L2);
        end
    end

    %----------------------------------------------------------------------
    % Function to add all conditions 
    %----------------------------------------------------------------------
    function MW_add_all(~,~) 

        if length(cond_L2) == length(cond_L1)
            fprintf(2,'All conditions are already selected.\n');
        else
        	len_exist = length(cond_L2);
            new_conds = {};                                             
            new_conds = vertcat(new_conds,cond_L1);             

            % Addition & extraction of unique selected conditions
            cond_L2 = vertcat(cond_L2,new_conds);
            new_cond_count = length(unique(cond_L2)) - len_exist;
            cond_L2 = unique(cond_L2);

            % Check if newly selected conditions have been added
            if new_cond_count == 0
                fprintf(2,'Newly selected conditions are already present in the list, no new conditions added.\n');
            else
                fprintf('New conditions selected: %d. \n', new_cond_count(1)); 
                cond_L2 = sort_selected_conditions(cond_L2,all_cond);
            end 

            % Set sorted list of conditions into GUI
            set(cond_MW_LB2,'String',cond_L2);
        end
    end

    %----------------------------------------------------------------------
    % Function to export list of conditions
    %----------------------------------------------------------------------
    function MW_confirm(~,~)

    	if isempty(cond_L2)
        	fprintf(2,'Please select conditions.\n');
        else
            cond = struct;
            n_cond = 1;
            for jCond = 1:length(all_cond)
               for kCond = 1:length(cond_L2)
                   match = strcmp(all_cond(jCond).list_name,cond_L2(kCond));
                   if match == 1
                       cond(n_cond).sess = all_cond(jCond).sess;
                       cond(n_cond).number = all_cond(jCond).number;
                       cond(n_cond).pmod = all_cond(jCond).pmod;
                       cond(n_cond).bf = all_cond(jCond).bf;
                       cond(n_cond).name = all_cond(jCond).name;
                       cond(n_cond).list_name = all_cond(jCond).list_name;
                       cond(n_cond).file_name = all_cond(jCond).file_name;
                       n_cond = n_cond + 1;
                   end
               end
            end
            disp(strcat(num2str(length(cond_L2)),' conditions successfully selected.'));
            conditions = cond;
            clear cond n_cond jCond kCond match
            uiresume(conditions_MW);
        end
    end

    %----------------------------------------------------------------------
    % Function to remove single condition
    %----------------------------------------------------------------------
    function MW_remove(~,~)
        if isempty(cond_L2)
        	fprintf(2,'No conditions present to remove.\n');
        elseif isempty(conditions_MW_SE2)
        	fprintf(2,'No conditions selected to remove.\n');
        else
            cond_L2(conditions_MW_SE2,:) = [];
            fprintf('Number of conditions removed: %d. \n', length(conditions_MW_SE2));
            set(cond_MW_LB2, 'Value', []);
            set(cond_MW_LB2, 'String', cond_L2);
            conditions_MW_SE2 = {};
        end
    end

    %----------------------------------------------------------------------
    % Function to remove all conditions
    %----------------------------------------------------------------------
    function MW_remove_all(~,~) 
        if isempty(cond_L2)
            fprintf(2,'No conditions present to remove.\n');  
        else
            cond_L2 = {};                                             
            set(cond_MW_LB2, 'String', []);
            conditions_MW_SE2 = {};
            disp('All selected conditions have been removed.');
        end
    end

    %----------------------------------------------------------------------
    % Help window for conditions selection
    %----------------------------------------------------------------------
    function MW_help(~,~)

        cond_HW = figure('Name', HW_string, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.67 0.31 0.22 0.50],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off', 'WindowStyle', 'Modal');

        if strcmp(HW_string, 'Select ROIs: Help')

            fontscale = 1;

            string_info = {'Suppose you have two separate sessions.','Both sessions contain task regressors for "Cond A", "Cond B" and "Errors"','',...
            'If you are only interested in "Cond A" and "Cond B" comparison, the following conditions should be selected:','','Cond A (Sess1)',...
            'Cond B (Sess1)','Cond A (Sess2)','Cond B (Sess2)','','For all selected conditions of interest, the TMFC toolbox will calculate the omnibus F-contrast.',...
            '','The moving sphere’s center will be shifted to the local maximum within a larger fixed-radius sphere.','',...
            'Local maxima are determined using the omnibus F-contrast for the selected conditions of interest.'};
            
        elseif strcmp(HW_string, 'gPPI: Help')

            fontscale = 1;

            string_info = {'Suppose you have two separate sessions.','','Both sessions contain task regressors for', '"Cond A", "Cond B" and "Errors"', '','If you are only interested in "Cond A" and "Cond B" comparison, the following conditions should be selected:',...
            '','1)  Cond A (Sess1)','2)  Cond B (Sess1)','3)  Cond A (Sess2)','4)  Cond B (Sess2)','','For all selected conditions of interest, the TMFC toolbox will create psychophysiological (PPI) regressors. Thus, for each condition of interest, the generalized PPI (gPPI) model will contain two regressors: (1) psychological regressor and (2) PPI regressor.'...
            '','For trials of no interest (here, "Errors"), the gPPI model will contain only the psychological regressor.'}; 
        
        else

            if isunix; fontscale = 0.9; else; fontscale = 1; end

            string_info = {'Suppose you have two separate sessions.','','Both sessions contain task regressors for', '"Cond A", "Cond B" and "Errors"', '','If you are only interested in "Cond A" and "Cond B" comparison, the following conditions should be selected:',...
            '','1)  Cond A (Sess1)','2)  Cond B (Sess1)','3)  Cond A (Sess2)','4)  Cond B (Sess2)','','For all selected conditions of interest, the TMFC toolbox will calculate individual trial beta-images using Least-Squares Separate (LSS) approach.',...
            '','For each individual trial (event), the LSS approach estimates a separate general linear model (GLM) with two regressors. The first regressor models the expected BOLD response to the current trial of interest, and the second (nuisance) regressor models the BOLD response to all other trials (of interest and no interest).',...
            '','For trials of no interest (here, "Errors"), separate GLMs will not be estimated. Trials of no interest will be used only for the second (nuisance) regressor.'};
        end
    
        % Create if-else chain, compare if HW_string == ROI, gPPI, LSS and
        % then assign the respective help string, change window size if
        % required. 

        cond_HW_S1 = uicontrol(cond_HW,'Style','text','String',string_info ,'Units', 'normalized', 'Position', [0.05 0.12 0.89 0.85], 'HorizontalAlignment', 'left','backgroundcolor','w','fontunits','normalized', 'fontSize', 0.0301*fontscale);
        cond_HW_OK = uicontrol(cond_HW,'Style','pushbutton','String', 'OK','Units', 'normalized', 'Position', [0.34 0.06 0.30 0.06],'callback', @cond_HW_close,'fontunits','normalized', 'fontSize', 0.35);
        movegui(cond_HW,'center');

        function cond_HW_close(~,~)
        	close(cond_HW);
        end
    end

    uiwait(conditions_MW);
    delete(conditions_MW);
end


%% ===========[ Function to get information about conditions ]=============
function [cond_list] = generate_conditions(SPM_path)
    cond_list = {}; 
    try
        load(SPM_path);

        [bf_names,bf_file] = get_hrf_basis_info(SPM);
        nBF = length(bf_names);

        kCond = 1;
        for iSess = 1:length(SPM.Sess)
            for jCond = 1:length(SPM.Sess(iSess).U)
                for kPmod = 1:length(SPM.Sess(iSess).U(jCond).name)
                    for kBF = 1:nBF
                        cond_name = char(SPM.Sess(iSess).U(jCond).name(kPmod));

                        cond_list(kCond).sess = iSess;
                        cond_list(kCond).number = jCond;
                        cond_list(kCond).pmod = kPmod;
                        cond_list(kCond).bf = kBF;
                        cond_list(kCond).name = cond_name;

                        if kBF == 1
                            cond_list(kCond).list_name = ...
                                [cond_name ...
                                ' (Sess' num2str(iSess) ', Cond' num2str(jCond) ')'];
                        else
                            cond_list(kCond).list_name = ...
                                [cond_name ' | ' bf_names{kBF} ...
                                ' (Sess' num2str(iSess) ', Cond' num2str(jCond) ')'];
                        end

                        base_file_name = ...
                            ['[Sess_' num2str(iSess) ']_[Cond_' num2str(jCond) ']_[' ...
                            regexprep(cond_name,' ','_') ']'];

                        if kBF == 1
                            cond_list(kCond).file_name = base_file_name;
                        else
                            cond_list(kCond).file_name = ...
                                [base_file_name '_[' bf_file{kBF} ']'];
                        end

                        kCond = kCond + 1;
                    end
                end
            end 
        end
    catch 
        disp('Selected SPM.mat file does not exist or is invalid.');
        cond_list = {};
    end
end

%% ========[ Function to perform sorting of selected conditions ]==========
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

    [~,index] = sortrows([[temp.sess]' [temp.number]' [temp.pmod]' [temp.bf]']);
    reindexed_list = temp(index); 

    sorted_list = {};
    for iCond = 1:length(reindexed_list) 
        sorted_list = vertcat(sorted_list, reindexed_list(iCond).list_name);
    end

    clear index temp sort_index iCond jCond reindexed_list
end

%% ===========[ Function to define HRF basis functions ]===================
function [bf_names,bf_file] = get_hrf_basis_info(SPM)

    switch lower(strtrim(SPM.xBF.name))

        case 'hrf'
            bf_names = {'HRF'};
            bf_file  = {'HRF'};

        case 'hrf (with time derivative)'
            bf_names = {'HRF','Time derivative'};
            bf_file  = {'HRF','TimeDeriv'};

        case 'hrf (with time and dispersion derivatives)'
            bf_names = {'HRF','Time derivative','Dispersion derivative'};
            bf_file  = {'HRF','TimeDeriv','DispDeriv'};

        otherwise
            error('TMFC supports only canonical HRF, time derivative, and dispersion derivative.');

    end
end