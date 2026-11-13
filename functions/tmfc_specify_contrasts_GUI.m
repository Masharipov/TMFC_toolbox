function [tmfc] = tmfc_specify_contrasts_GUI(tmfc,ROI_set_number,TMFC_analysis)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window to specify contrasts.
% 
% FORMAT [tmfc] = tmfc_specify_contrasts_GUI(tmfc,ROI_set_number,TMFC_analysis)
%   tmfc               - The tmfc structure (see TMFC.m)
%   ROI_set_number     - Number of the ROI set in the tmfc structure
%   TMFC_analysis      - TMFC analysis type:
%                          1: gPPI
%                          2: gPPI-FIR
%                          3: BSC-LSS
%                          4: BSC-LSS after FIR
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

existing_contrasts = get_contrasts_info(tmfc,ROI_set_number,TMFC_analysis);

if size(existing_contrasts,1) ~= 0 
    % If contrasts are present open GUI
    tmfc = specify_contrasts_GUI(tmfc,ROI_set_number,TMFC_analysis,existing_contrasts); 
else
    % Show warning if contrasts not generated
    switch(TMFC_analysis)
        case 1
            warning('gPPI: Default contrasts have not been calculated.');
        case 2 
            warning('gPPI FIR: Default contrasts have not been calculated.');
        case 3
            warning('BSC: Default contrasts have not been calculated.');
        case 4
            warning('BSC FIR: Default contrasts have not been calculated.');
    end   
end
end

%% =====================[ Specify contrasts GUI ]==========================
function [tmfc] = specify_contrasts_GUI(tmfc,ROI_set_number,TMFC_analysis,existing_contrasts)
    
    contrasts = struct;
    contrast_count = 1;
    new_contrasts = {};

    SC_MW = figure('Name', 'Contrast manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.30 0.3 0.46],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','on','CloseRequestFcn', @SC_MW_exit);
    SC_MW_S1  = uicontrol(SC_MW,'Style','text','String', 'Define contrasts','Units', 'normalized', 'Position',[0.270 0.93 0.450 0.05],'fontunits','normalized', 'fontSize', 0.64,'backgroundcolor','w');

    SC_MW_S2  = uicontrol(SC_MW,'Style','text','String', 'Existing contrasts:','Units', 'normalized', ...
        'Position',[0.045 0.86 0.300 0.05],'HorizontalAlignment', 'left', ...
        'fontunits','points','fontSize',10,'backgroundcolor','w');
    SC_MW_S3 = uicontrol(SC_MW , 'Style', 'text', 'String', 'No. :: Title :: Contrast weights','Max', 100,'Units', 'normalized', ...
        'Position',[0.045 0.816 0.900 0.045], ...
        'fontunits','points','fontSize',10,'HorizontalAlignment','left','backgroundcolor','w');
    SC_MW_LB1 = uicontrol(SC_MW , 'Style', 'listbox', 'String', existing_contrasts,'Value', [],'Max', 100,'Units', 'normalized', 'Position',[0.045 0.62 0.920 0.200],'fontunits','points', 'fontSize', 11,'Enable','inactive');

    SC_MW_S4  = uicontrol(SC_MW,'Style','text','String','Add new contrasts:','Units','normalized', ...
        'Position',[0.045 0.535 0.450 0.05],'HorizontalAlignment','left', ...
        'fontunits','points','fontSize',10,'backgroundcolor','w');
    SC_MW_S5 = uicontrol(SC_MW,'Style','text','String', 'No. :: Title :: Contrast weights','Max',100,'Units','normalized', ...
        'Position',[0.045 0.492 0.900 0.045], ...
        'fontunits','points','fontSize',10,'HorizontalAlignment','left','backgroundcolor','w');
    SC_MW_LB2 = uicontrol(SC_MW,'Style','listbox','String', new_contrasts,'Value', [],'Max',100,'Units', 'normalized', ...
        'Position',[0.045 0.26 0.920 0.230],'fontunits','points', 'fontSize', 11,'callback', @MW_LB2_select);

    SC_MW_add = uicontrol(SC_MW,'Style','pushbutton','String', 'Add new',...
        'Units','normalized','Position',[0.045 0.15 0.210 0.075],...
        'fontunits','normalized','fontSize',0.36,'callback',@MW_add);

    SC_MW_load = uicontrol(SC_MW,'Style','pushbutton','String', 'Load from TXT',...
        'Units','normalized','Position',[0.275 0.15 0.210 0.075],...
        'fontunits','normalized','fontSize',0.32,'callback',@MW_load_txt);

    SC_MW_rem = uicontrol(SC_MW,'Style','pushbutton','String', 'Remove selected',...
        'Units','normalized','Position',[0.505 0.15 0.210 0.075],...
        'fontunits','normalized','fontSize',0.32,'callback',@MW_remove);

    SC_MW_rem_all = uicontrol(SC_MW,'Style','pushbutton','String', 'Remove all',...
        'Units','normalized','Position',[0.735 0.15 0.230 0.075],...
        'fontunits','normalized','fontSize',0.36,'callback',@MW_remove_all);

    SC_MW_conf = uicontrol(SC_MW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.045 0.05 0.21 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @MW_confirm);
    SC_MW_help = uicontrol(SC_MW,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.735 0.05 0.23 0.075],'fontunits','normalized', 'fontSize', 0.36,'callback', @MW_help);
    movegui(SC_MW,'center');

    SC_MW_SE2 = {}; 

    %----------------------------------------------------------------------
    % Exit
    %----------------------------------------------------------------------
    function SC_MW_exit (~,~)
        uiresume(SC_MW);
        disp('Contrasts not specified.');
    end

    %----------------------------------------------------------------------
    function MW_LB2_select(~,~)
        index = get(SC_MW_LB2, 'Value');  % Retrieves the users selection 
        SC_MW_SE2 = index;             
    end

    %----------------------------------------------------------------------
    %  Add new contrast
    %----------------------------------------------------------------------
    function MW_add(~,~)

        [title_contrast, weights_contrast] = specify_contrast(tmfc, ROI_set_number, TMFC_analysis);

        if ~isempty(title_contrast)

        	if ~isfield(contrasts, 'no')
            	% Initial assignment of contrasts
                contrasts(contrast_count).no = size(existing_contrasts,1)+1;
                contrasts(contrast_count).title = title_contrast;
                contrasts(contrast_count).weights = str2num(weights_contrast);

                cont_str = horzcat('No ',num2str(contrasts(contrast_count).no),' :: ',contrasts(contrast_count).title,' :: ', 'c = [',num2str(contrasts(contrast_count).weights),']');
                new_contrasts = vertcat(new_contrasts, cont_str);
                set(SC_MW_LB2, 'string', new_contrasts);
                contrast_count = contrast_count + 1;
            else
                % Subsequent additions of contrast
                contrasts(contrast_count).no = size(existing_contrasts,1)+contrast_count;
                contrasts(contrast_count).title = title_contrast;
                contrasts(contrast_count).weights = str2num(weights_contrast);

                cont_str = horzcat('No ',num2str(contrasts(contrast_count).no),' :: ',contrasts(contrast_count).title,' :: ', 'c = [',num2str(contrasts(contrast_count).weights),']');
                new_contrasts = vertcat(new_contrasts, cont_str);
                set(SC_MW_LB2, 'string', new_contrasts);
                contrast_count = contrast_count + 1;
            end
            fprintf('Contrast added: %s.\n',title_contrast);
        else
            fprintf(2,'No contrasts added.\n');
        end
    end
    
    %----------------------------------------------------------------------
    % Load contrasts from TXT file
    %----------------------------------------------------------------------
    function MW_load_txt(~,~)

        % Number of conditions of interest
        switch(TMFC_analysis)
            case 1
                nCondOfInterest = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(1).weights);
            case 2
                nCondOfInterest = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(1).weights);
            case 3
                nCondOfInterest = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC(1).weights);
            case 4
                nCondOfInterest = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(1).weights);
        end

        % Select TXT file
        [file_name,file_path] = uigetfile({'*.txt','Text files (*.txt)'},'Select contrast list');
        if isequal(file_name,0)
            fprintf('No contrast file selected.\n');
            return;
        end
        contrast_file = fullfile(file_path,file_name);

        % Open TXT file
        fid = fopen(contrast_file,'rt');
        if fid == -1
            fprintf(2,'Could not open contrast file: %s\n',contrast_file);
            return;
        end
        cleanupObj = onCleanup(@() fclose(fid));

        % Temporary structure.
        % Nothing is added to the GUI until the whole file is validated.
        imported_contrasts = struct('title',{},'weights',{});

        line_number = 0;
        import_count = 0;

        while true
            line = fgetl(fid);
            if ~ischar(line)
                break;
            end
            line_number = line_number + 1;

            % Remove UTF-8 BOM if present
            if line_number == 1
                if length(line) >= 3 && isequal(double(line(1:3)),[239 187 191])
                    line = line(4:end);
                elseif ~isempty(line) && double(line(1)) == 65279
                    line = line(2:end);
                end
            end

            % Ignore empty lines
            if isempty(strtrim(line))
                continue;
            end

            % Find TAB separating title and weights
            tab_pos = find(line == sprintf('\t'),1,'first');

            if isempty(tab_pos)
                fprintf(2,['Invalid contrast file, line %d. Contrast title and weights must be separated by a TAB.\n'],line_number);
                return;
            end

            title_contrast = strtrim(line(1:tab_pos-1));
            weights_contrast = strtrim(line(tab_pos+1:end));

            % -------------------------------------------------------------
            % Validate title
            % -------------------------------------------------------------
            if isempty(title_contrast)
                fprintf(2,'Invalid contrast file, line %d: title is empty.\n',line_number);
                return;
            end

            if ~isempty(str2num(title_contrast))
                fprintf(2,['Invalid contrast file, line %d: the title cannot consist only of numbers.\n'],line_number);
                return;
            end

            % -------------------------------------------------------------
            % Validate weights
            % -------------------------------------------------------------
            if isempty(weights_contrast)
                fprintf(2,['Invalid contrast file, line %d: contrast weights are empty.\n'],line_number);
                return;
            end

            % Permit numeric expressions and selected MATLAB functions.
            % No other function names are allowed.
            weights_check = weights_contrast;
            weights_check = strrep(weights_check,'repmat','');
            weights_check = strrep(weights_check,'ones','');
            weights_check = strrep(weights_check,'zeros','');

            if isempty(regexp(weights_check, ...
                    '^[0-9eE\.\+\-\[\]\(\)/,\s]+$','once'))

                fprintf(2,['Invalid contrast file, line %d: ' ...
                    'invalid characters in contrast weights.\n'], ...
                    line_number);
                return;
            end

            weights = str2num(weights_contrast);

            if isempty(weights)
                fprintf(2,['Invalid contrast file, line %d: contrast weights are not valid numeric values.\n'],line_number);
                return;
            end

            if length(weights) ~= nCondOfInterest
                fprintf(2,['Invalid contrast file, line %d: contrast contains %d weights, but %d are required.\n'],line_number,length(weights),nCondOfInterest);
                return;
            end

            if any(isnan(weights)) || any(isinf(weights))
                fprintf(2,['Invalid contrast file, line %d: contrast weights contain NaN or Inf.\n'],line_number);
                return;
            end

            % Store only after this line has passed all checks
            import_count = import_count + 1;
            imported_contrasts(import_count).title = title_contrast;
            imported_contrasts(import_count).weights = weights;
        end

        if isempty(imported_contrasts)
            fprintf(2,'No contrasts found in the selected TXT file.\n');
            return;
        end

        % -------------------------------------------------------------
        % All lines are valid. Add them to the current contrast list.
        % -------------------------------------------------------------
        for iCon = 1:length(imported_contrasts)
            contrasts(contrast_count).no = size(existing_contrasts,1) + contrast_count;
            contrasts(contrast_count).title = imported_contrasts(iCon).title;
            contrasts(contrast_count).weights = imported_contrasts(iCon).weights;

            cont_str = horzcat( ...
                'No ',num2str(contrasts(contrast_count).no), ...
                ' :: ',contrasts(contrast_count).title, ...
                ' :: c = [', ...
                num2str(contrasts(contrast_count).weights),']');

            new_contrasts = vertcat(new_contrasts,cont_str);
            contrast_count = contrast_count + 1;
        end

        % Update GUI
        set(SC_MW_LB2,'Value',[]);
        SC_MW_SE2 = {};
        set(SC_MW_LB2,'String',new_contrasts);

        fprintf('%d contrast(s) loaded from %s.\n',length(imported_contrasts),file_name);
    end

    %----------------------------------------------------------------------
    % Remove single contrast
    %----------------------------------------------------------------------
    function MW_remove(~,~)

        if isfield(contrasts, 'no')
            if isempty(SC_MW_SE2)
                fprintf(2,'No contrasts selected to remove.\n');
            else
                if length(SC_MW_SE2)>1
                    disp('Selected contrasts have been removed.');
                else
                    disp('Selected contrast has been removed.');
                end

                % Removing contrasts
                contrasts(SC_MW_SE2) = [];
                contrast_count = contrast_count - length(SC_MW_SE2);

                % Re-setting GUI variables
                new_contrasts = {};
                SC_MW_SE2 = {};

                % Generation of Strings
                for iCon = 1:length(contrasts)
                   contrasts(iCon).no = size(existing_contrasts,1)+iCon;
                   contrast_string = horzcat('No ',num2str(contrasts(iCon).no),' :: ',contrasts(iCon).title,' :: ', 'c = [',num2str(contrasts(iCon).weights),']');
                   new_contrasts = vertcat(new_contrasts, contrast_string);
                end

                set(SC_MW_LB2,'Value',[]);               
                set(SC_MW_LB2, 'string', new_contrasts);
            end
        else
            fprintf(2,'No contrasts present to remove.\n');
        end
    end

    %----------------------------------------------------------------------
    % Remove all contrasts
    %----------------------------------------------------------------------
    function MW_remove_all(~,~)
        if isfield(contrasts, 'no')
            % Reset variables & GUI
            contrasts = struct;
            new_contrasts = {};
            SC_MW_SE2 = {};
            contrast_count = 1;

            set(SC_MW_LB2,'Value',[]);
            set(SC_MW_LB2, 'string', new_contrasts);
            disp('All Contrasts have been removed.');
        else
        	fprintf(2,'No contrasts present to remove.\n');
        end
    end

    %----------------------------------------------------------------------
    % Confirm added contrasts]
    %----------------------------------------------------------------------
    function MW_confirm(~,~)
        if isempty(new_contrasts)
            fprintf(2,'Please specify new contrast(s). \n');
        else
            tmfc = add_new_contrasts(tmfc,contrasts,TMFC_analysis,ROI_set_number);
            fprintf('Number of newly added contrasts for processing: %d.\n',length(new_contrasts));
            uiresume(SC_MW);
        end
    end

    %----------------------------------------------------------------------
    % Help window
    %----------------------------------------------------------------------
    function MW_help(~,~)   

        SC_HW = figure('Name', 'Contrast manager: Help', 'NumberTitle', 'off', ...
            'Units', 'normalized', 'Position', [0.67 0.27 0.30 0.70], ...
            'color','w','MenuBar', 'none','ToolBar', 'none','Resize','off', 'WindowStyle', 'Modal');
               
        string_info = { ...
            'Existing contrasts are contrasts that have been calculated previously. By default, the TMFC toolbox calculates contrasts for each condition of interest ("Condition > Baseline").','', ...
            'Suppose you have two separate runs (sessions) and two conditions of interest: "Cond A" and "Cond B".','', ...
            'The default contrasts will be:','', ...
            '1) Cond A (Run1), c = [1 0 0 0]', ...
            '2) Cond B (Run1), c = [0 1 0 0]', ...
            '3) Cond A (Run2), c = [0 0 1 0]', ...
            '4) Cond B (Run2), c = [0 0 0 1]','', ...
            'Where "c" is a contrast weight vector.','', ...
            'To add a new contrast manually:','', ...
            '1) Press "Add new".', ...
            '2) Enter a contrast title (e.g. "CondA_vs_CondB").', ...
            '3) Enter contrast weights, e.g. c = [0.5 -0.5 0.5 -0.5].', ...
            '4) Press "OK".','', ...
            'To add multiple contrasts from a TXT file:','', ...
            '1) Press "Load from TXT".', ...
            '2) Select a .txt file containing one contrast per line.', ...
            '3) Each line must contain a contrast title and contrast weights separated by a TAB.', ...
            '4) For the example above, the TXT file could contain:','', ...
            'CondA_vs_CondB<TAB>[1 -1 1 -1]/2', ...
            'CondA_plus_CondB<TAB>[1 1 1 1]/2','', ...
            'The number of contrast weights must equal the number of conditions of interest.', ...
            'Numeric expressions such as [1 -1 1 -1]/2 are allowed.'};
        SC_HW_S1 = uicontrol(SC_HW,'Style','text','String',string_info , ...
            'Units', 'normalized', 'Position', [0.055 0.12 0.89 0.85], ...
            'HorizontalAlignment', 'left', ...
            'fontunits','points','fontSize', 11,'backgroundcolor','w');
        SC_HW_OK = uicontrol(SC_HW,'Style','pushbutton','String', 'OK','Units', 'normalized', ...
            'Position', [0.35 0.030 0.30 0.07], ...
            'fontunits','points','fontSize', 12,'callback', @SC_HW_close);
        movegui(SC_HW,'center');

        function SC_HW_close(~,~)
            close(SC_HW);
        end
    end

    uiwait(SC_MW);
    delete(SC_MW);
end

%% ============[ Get info about contrasts from TMFC structure ]============
function [contrasts_string] = get_contrasts_info(tmfc,ROI_set_number,tmfc_analysis)

    contrasts = {};
    contrasts_string = {};

    switch (tmfc_analysis)

    % gPPI ----------------------------------------------------------------
    case 1           
        % Generate list of existing contrasts
        contrasts = vertcat(contrasts, tmfc.ROI_set(ROI_set_number).contrasts.gPPI.title);
        % Create string of existing contrasts for GUI
        for iCon = 1:size(contrasts,1)
            single_contrast = horzcat('No ',num2str(iCon),' :: ',contrasts{iCon},' :: ', 'c = [',num2str(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(iCon).weights),']');
            contrasts_string = vertcat(contrasts_string, single_contrast);
        end

    % gPPI FIR ------------------------------------------------------------
    case 2        
        % Generate list of existing contrasts
        contrasts = vertcat(contrasts, tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR.title);
        % Create string of existing contrasts for GUI
        for iCon = 1:size(contrasts,1)
            single_contrast = horzcat('No ',num2str(iCon),' :: ',contrasts{iCon},' :: ', 'c = [',num2str(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(iCon).weights),']');
            contrasts_string = vertcat(contrasts_string, single_contrast);
        end

    % BSC -----------------------------------------------------------------
    case 3        
        % Generate list of existing contrasts
        contrasts = vertcat(contrasts, tmfc.ROI_set(ROI_set_number).contrasts.BSC.title);
        % Create string of existing contrasts for GUI
        for iCon = 1:size(contrasts,1)
            single_contrast = horzcat('No ',num2str(iCon),' :: ',contrasts{iCon},' :: ', 'c = [',num2str(tmfc.ROI_set(ROI_set_number).contrasts.BSC(iCon).weights),']');
            contrasts_string = vertcat(contrasts_string, single_contrast);
        end

    % BSC_after_FIR -------------------------------------------------------
    case 4        
        % Generate list of existing contrasts
        contrasts = vertcat(contrasts, tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR.title);
        % Create string of existing contrasts for GUI
        for iCon = 1:size(contrasts,1)
            single_contrast = horzcat('No ',num2str(iCon),' :: ',contrasts{iCon},' :: ', 'c = [',num2str(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(iCon).weights),']');
            contrasts_string = vertcat(contrasts_string, single_contrast);
        end
    end
end

%% =============[ Specify contrast weights and title GUI ]=================
function [title,weights] = specify_contrast(tmfc, ROI_set_number,TMFC_analysis)

	default_contrasts = {}; % Variable to store default contrasts

    % Get default contrasts info
    switch(TMFC_analysis)
        case 1
            nCondOfInterest = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(1).weights);
            for iCon=1:nCondOfInterest
                default_contrasts = vertcat(default_contrasts, strcat('C',num2str(iCon),' : ', 32,tmfc.ROI_set(ROI_set_number).contrasts.gPPI(iCon).title));   
            end

        case 2 
            nCondOfInterest = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(1).weights);
            for iCon=1:nCondOfInterest
                default_contrasts = vertcat(default_contrasts, strcat('C',num2str(iCon),' : ', 32,tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(iCon).title));   
            end

        case 3 
            nCondOfInterest = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC(1).weights);
            for iCon=1:nCondOfInterest
                default_contrasts = vertcat(default_contrasts, strcat('C',num2str(iCon),' : ', 32,tmfc.ROI_set(ROI_set_number).contrasts.BSC(iCon).title));   
            end

        case 4 
            nCondOfInterest = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(1).weights);
            for iCon=1:nCondOfInterest
                default_contrasts = vertcat(default_contrasts, strcat('C',num2str(iCon),' : ', 32,tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(iCon).title));   
            end
    end

    % Display conditions of interest  
    sample_weights_string = {};
    if length(default_contrasts) == 1
        sample_weights_string = strcat('Weights: [C1]');
    elseif length(default_contrasts) == 2
        sample_weights_string = strcat('Weights: [C1 C2]');
    elseif length(default_contrasts) == 3
        sample_weights_string = strcat('Weights: [C1 C2 C3]');
    elseif length(default_contrasts) == 4
        sample_weights_string = strcat('Weights: [C1 C2 C3 C4]');
    else
        sample_weights_string = strcat('Weights: [C1 C2 ...', 32, 'C', num2str(nCondOfInterest),']');
    end

    % SW = Specify weights
    SW_MW = figure('Name', 'Define new contrast', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.64 0.46 0.25 0.22],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','on', 'CloseRequestFcn', @MW_exit, 'WindowStyle','modal');

    SW_MW_S1  = uicontrol(SW_MW,'Style','text','String', 'Define contrast title and contrast weights','Units', 'normalized', 'Position',[0.2 0.875 0.600 0.08],'fontunits','normalized', 'fontSize', 0.74,'backgroundcolor','w');
    SW_MW_S2 = uicontrol(SW_MW,'Style','text','String', 'Conditions of interest:','Units', 'normalized', 'Position',[0.04 0.75 0.3 0.07],'fontunits','normalized', 'fontSize', 0.83,'HorizontalAlignment', 'left','backgroundcolor','w');
    SW_MW_S3  = uicontrol(SW_MW,'Style','text','String', 'Title','Units', 'normalized', 'Position',[0.2105 0.34 0.10 0.07],'fontunits','normalized', 'fontSize', 0.80,'backgroundcolor','w');
    SW_MW_S4  = uicontrol(SW_MW,'Style','text','String', sample_weights_string,'Units', 'normalized', 'Position',[0.54 0.34 0.40 0.07],'fontunits','normalized', 'fontSize', 0.80,'backgroundcolor','w');

    SW_MW_LB1 = uicontrol(SW_MW, 'Style','listbox', 'String', default_contrasts,'Max',100,'Units', 'normalized', 'Position',[0.04 0.45 0.920 0.280],'fontunits','points', 'fontSize', 11);

    %SW_MW_CT = Contrast Title
    %SW_MW_CW = Contrast Weight
    SW_MW_CT = uicontrol(SW_MW,'Style','edit','String', '','Units', 'normalized','Position',[0.04 0.23 0.440 0.10],'fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'center');
    SW_MW_CW = uicontrol(SW_MW,'Style','edit','String', '','Units', 'normalized','Position',[0.52 0.23 0.440 0.10],'fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'center');

    SW_MW_confirm = uicontrol(SW_MW,'Style','pushbutton', 'String', 'OK','Units', 'normalized','Position',[0.20 0.06 0.24 0.11],'fontunits','normalized', 'fontSize', 0.42, 'callback', @check_contrast);
    SW_MW_cancel = uicontrol(SW_MW,'Style','pushbutton', 'String', 'Cancel','Units', 'normalized','Position',[0.56 0.06 0.24 0.11],'fontunits','normalized', 'fontSize', 0.42, 'callback', @MW_exit);

    movegui(SW_MW,'center');

    %----------------------------------------------------------------------
    % Check new contrast
    %----------------------------------------------------------------------
    function check_contrast(~,~)

        contrast_title = get(SW_MW_CT, 'String');
        contrast_weight = get(SW_MW_CW, 'String');

        if strcmp(contrast_title,'') || strcmp(contrast_title(1),' ') 
            fprintf(2,'Title not entered or invalid, please re-enter.\n');            

        elseif ~isempty(str2num(contrast_title(1)))
            fprintf(2,'The title name cannot consist only of numbers, please re-enter.\n');

        elseif strcmp(contrast_weight, '') || strcmp(contrast_weight, ' ')
            fprintf(2,'Contrast weights not entered or invalid, please re-enter.\n');

        elseif isempty(str2num(contrast_weight))
            fprintf(2,'Contrast weights are not numeric, please re-enter.\n');

        elseif length(str2num(contrast_weight)) > nCondOfInterest
            fprintf(2,'Contrast length is greater than the number of conditions of interest, please re-enter.\n');

        elseif length(str2num(contrast_weight)) < nCondOfInterest
            fprintf(2,'Contrast length is less than the number of conditions of interest, please re-enter.\n');

        else
            title = contrast_title;
            weights = contrast_weight;
            uiresume(SW_MW);
        end
    end

    %--------------------------------------------------------------------------
    function MW_exit(~,~)
        title = [];
        weights = [];
        uiresume(SW_MW); 
    end

    uiwait(SW_MW);
    delete(SW_MW);
end

%% ==============[ Assign new contrasts to TMFC structure ]================
function [tmfc] = add_new_contrasts(tmfc,contrasts,TMFC_analysis,ROI_set_number)
    switch (TMFC_analysis)
        case 1
            % gPPI
            existing_contrasts = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI);
            for iCon = 1:length(contrasts)
               tmfc.ROI_set(ROI_set_number).contrasts.gPPI(existing_contrasts+iCon).title = contrasts(iCon).title;
               tmfc.ROI_set(ROI_set_number).contrasts.gPPI(existing_contrasts+iCon).weights = contrasts(iCon).weights; 
            end

        case 2
            % gPPI FIR
            existing_contrasts = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR);
            for iCon = 1:length(contrasts)
               tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(existing_contrasts+iCon).title = contrasts(iCon).title;
               tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(existing_contrasts+iCon).weights = contrasts(iCon).weights; 
            end

        case 3
            % BSC
            existing_contrasts = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC);
            for iCon = 1:length(contrasts)
               tmfc.ROI_set(ROI_set_number).contrasts.BSC(existing_contrasts+iCon).title = contrasts(iCon).title;
               tmfc.ROI_set(ROI_set_number).contrasts.BSC(existing_contrasts+iCon).weights = contrasts(iCon).weights; 
            end

        case 4
            % BSC FIR
            existing_contrasts = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR);
            for iCon = 1:length(contrasts)
               tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(existing_contrasts+iCon).title = contrasts(iCon).title;
               tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(existing_contrasts+iCon).weights = contrasts(iCon).weights; 
            end
    end   
end
