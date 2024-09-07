function [ROI_set] = tmfc_select_ROIs_GUI(tmfc)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for selecting ROI masks. Creates group mean binary 
% mask based on 1st-level masks (see SPM.VM) and applies it to all selected
% ROIs. Empty ROIs will be removed. Masked ROIs will be limited to only
% voxels which have data for all subjects. The dimensions, orientation, and
% voxel sizes of the masked ROI images will be adjusted according to the
% group mean binary mask.
%
% FORMAT [ROI_set] = tmfc_select_ROIs_GUI(tmfc)
%
%   tmfc.subjects.path     - Paths to individual SPM.mat files
%   tmfc.project_path      - The path where all results will be saved
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


full_flag = 0;
% % check if the code is called from GUI or CLI
% OPD = findobj('Tag', 'TMFC_GUI');



% if code is called from CLI 

if ~isempty(tmfc.subjects(1).path)

[ns_1, ns_2] = ROI_F1();

    if ns_1 == 1
        ROI_set = struct;
        Fitter(1);
        if full_flag ~= 1
            ROI_set = [];
        end
    else
        warning('ROIs not selected.');
        ROI_set = -1;
    end
else
    warning('Please select subjects to continue selection of ROIs.');
    ROI_set = -1;
end


function Fitter(NUM)

    Flag_1 = 0;
    Flag_2 = 0;
    Flag_3 = 0;
    
    CTR = NUM;
    ROI_set(CTR).set_name = ns_2;
    
    if isfield(tmfc,'project_path')
    
        try
            % Select ROIs
            [paths] = spm_select(inf,'any','Select ROI masks',{},pwd);
            for i = 1:size(paths,1)
                [~, ROI_set(CTR).ROIs(i).name, ~] = fileparts(deblank(paths(i,:)));
                ROI_set(CTR).ROIs(i).path = deblank(paths(i,:));
                ROI_set(CTR).ROIs(i).path_masked = fullfile(tmfc.project_path,'ROI_sets',ROI_set(CTR).set_name,'Masked_ROIs',[ROI_set(CTR).ROIs(i).name '_masked.nii']);
            end

            % Clear & create 'Masked_ROIs' folder
            if isdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set(CTR).set_name))
                rmdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set(CTR).set_name),'s');
            end

            if ~isdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set(CTR).set_name,'Masked_ROIs'))
                mkdir(fullfile(tmfc.project_path,'ROI_sets',ROI_set(CTR).set_name,'Masked_ROIs'));
            end

            if ~isempty(paths)
                Flag_1 = 1;
            end

        catch
            warning('ROIs not selected.');
        end
     
    else
        warning('TMFC project folder not selected.');
        disp('ROIs not selected.');
    end
    
    
    
    if Flag_1 == 1
        % Create group mean binary mask
        for i = 1:length(tmfc.subjects)
            sub_mask{i,1} = [tmfc.subjects(i).path(1:end-7) 'mask.nii'];
        end
        group_mask = fullfile(tmfc.project_path,'ROI_sets',ROI_set(CTR).set_name,'Masked_ROIs','Group_mask.nii');

        if length(tmfc.subjects) == 1
            copyfile(sub_mask{1,1},group_mask);
        else
            spm_imcalc(sub_mask,group_mask,'prod(X)',{1,0,1,2});
        end
        
    
        % Calculate ROI size before masking
        w = waitbar(0,'Please wait...','Name','Calculating raw ROI sizes');
        group_mask = spm_vol(group_mask);
        N = numel(ROI_set(CTR).ROIs);
        for i = 1:N
            ROI_mask = spm_vol(ROI_set(CTR).ROIs(i).path);           
            Y = zeros(group_mask.dim(1:3));
            % Loop through slices
            for p = 1:group_mask.dim(3)
                % Adjust dimensions, orientation, and voxel sizes to group mask
                B = spm_matrix([0 0 -p 0 0 0 1 1 1]);
                X = zeros(1,prod(group_mask.dim(1:2))); 
                M = inv(B * inv(group_mask.mat) * ROI_mask.mat);
                d = spm_slice_vol(ROI_mask, M, group_mask.dim(1:2), 1);
                d(isnan(d)) = 0;
                X(1,:) = d(:)';
                Y(:,:,p) = reshape(X,group_mask.dim(1:2));
            end
            % Raw ROI size (in voxels)
            ROI_set(CTR).ROIs(i).raw_size = nnz(Y);
            try
                waitbar(i/N,w,['ROI No ' num2str(i,'%.f')]);
            end
        end
    
        try
            close(w);
        end
    
        % Mask the ROI images by the goup mean binary mask
        w = waitbar(0,'Please wait...','Name','Masking ROIs by group mean mask');
        input_images{1,1} = group_mask.fname;
        for i = 1:N
            input_images{2,1} = ROI_set(CTR).ROIs(i).path;
            ROI_mask = ROI_set(CTR).ROIs(i).path_masked;
            spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
            try
                waitbar(i/N,w,['ROI No ' num2str(i,'%.f')]);
            end
        end
    
        try
            close(w)
        end
    
        % Calculate ROI size after masking
        w = waitbar(0,'Please wait...','Name','Calculating masked ROI sizes');
        for i = 1:N
            ROI_set(CTR).ROIs(i).masked_size = nnz(spm_read_vols(spm_vol(ROI_set(CTR).ROIs(i).path_masked)));
            ROI_set(CTR).ROIs(i).masked_size_percents = 100*ROI_set(CTR).ROIs(i).masked_size/ROI_set(CTR).ROIs(i).raw_size;
            try
                waitbar(i/N,w,['ROI No ' num2str(i,'%.f')]);
            end
        end
    
        try
            close(w)
        end
    
        Flag_2 = 1;
    end
    
    
    if Flag_2 == 1 && Flag_1 == 1
    
        % Remove Empty ROIs
        %biege = {};
        a = {};
        in_ctr = 1;
        for i = 1:length(ROI_set(CTR).ROIs)
            if ROI_set(CTR).ROIs(i).masked_size_percents == 0
                a{in_ctr,1} = i;
                a{in_ctr,2} = ROI_set(CTR).ROIs(i).name;
                in_ctr = in_ctr + 1;
            end
        end
    
        if ~isempty(a)
            constructor = {};
            eject = size(a);
            for i = 1:eject(1)
                biege = horzcat('№ ',num2str(a{i,1}),': ',a{i,2});
                %disp(biege);
                constructor = vertcat(constructor, biege);
            end
            ROI_F3(constructor);
    
            % removing the empty ROIs
            s = 0;
            for i = 1:eject(1)
                ROI_set(CTR).ROIs(a{i,1}-s) = [];
                s = s +1;
            end    
    
            if isempty(ROI_set(CTR).ROIs)
               Flag_3 = 0;
               warning('No eligible ROIs left for selection, please try again.');
            else
                Flag_3 = 1;
            end
        else
            Flag_3 = 1;
    %                         disp('No eligible ROIs left for selection, Please try again');
    %                         disp('check 1');
        end
    
    end
    
    if Flag_1 == 1 && Flag_2 == 1 && Flag_3 == 1
        ROI_set = ROI_F4(ROI_set, CTR);
        if ~isempty(ROI_set) 
            full_flag = 1;
            
        end
    end      
end      
end

% GUI to add new ROI set
function [RF1_flag, ret_name] = ROI_F1(~,~)
    
    ROI_1 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.62 0.50 0.16 0.14],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none','WindowStyle', 'modal','CloseRequestFcn', @stable_exit);

    % Initializing Elements of the UI
    ROI_1_S1 = uicontrol(ROI_1,'Style','text','String', 'Enter a name for the ROI set','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.40,'backgroundcolor',get(ROI_1,'color'),'Position',[0.14 0.60 0.700 0.230]);
    ROI_1_A1 = uicontrol(ROI_1,'Style','edit','String','','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45,'HorizontalAlignment','left','Position',[0.10 0.44 0.800 0.190]);
    ROI_1_OK= uicontrol(ROI_1,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45,'Position',[0.10 0.16 0.310 0.180],'callback', @get_name);
    ROI_1_Help = uicontrol(ROI_1,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45,'Position',[0.59 0.16 0.310 0.180], 'callback', @help_win_R);

    %set(ROI_1_S1,'backgroundcolor',get(ROI_1,'color'));
    movegui(ROI_1,'center');
    
    RF1_flag = 0; 
    ret_name = '';

    function stable_exit(~,~)
       delete(ROI_1);
       RF1_flag = 0; 
       ret_name = '';
    end
    
    
    function get_name(~,~)

        name = get(ROI_1_A1, 'String');
        
        % check for existing name

        if ~strcmp(name,'') & ~strcmp(name(1),' ')            
            fprintf('Name ROI set %s\n', name);
            delete(ROI_1);
            RF1_flag = 1;
            ret_name = name;
        else
            warning('Name not entered or is invalid, please re-enter');
        end

    end

    function help_win_R(~,~)

        help_data = {'First, define a name for the set of ROIs. TMFC results for this ROI set will be stored in:','','"TMFC_project_name\ROI_sets\ROI_set_name"','',...
    'Second, select one or more ROI masks (*.nii files). TMFC toolbox will create a group mean binary mask based on individual subjects 1st-level masks (see SPM.VM) and apply it to all selected ROIs Empty ROIs will be excluded from further analysis. Masked ROIs will be limited to only voxels which have data for all subjects. The dimensions, orientation, and voxel sizes of the masked ROI images will be adjusted according to the group mean binary mask. These files will be stored in "Masked_ROIs"',...
    '','Third, exclude heavily cropped ROIs from further analysis, if necessary.','','Note: You can define several ROI sets and switch between them. Push the "ROI_set" button and then push "Add new ROI set". Each time you need to switch between ROI sets push the "ROI_set" button.'};


        ROI_1_H = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.67 0.31 0.16 0.36],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none','Windowstyle', 'Modal');
        RH_TEXT = uicontrol(ROI_1_H,'Style','text','String', help_data,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.0365,'HorizontalAlignment', 'left', 'Position',[0.05 0.14 0.89 0.82],'backgroundcolor',get(ROI_1_H,'color'));
        RH_OK= uicontrol(ROI_1_H,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45,'Position',[0.34 0.06 0.30 0.06],'callback', @RH_CL);
        
        %movegui(ROI_1_H,'center');

        function RH_CL(~,~)
            close(ROI_1_H);
        end

    end
    uiwait();
end

function ROI_F3(dis_data)

    ROI_3_INFO1 = {'Warning, the following ROIs do not',...
        'contain data for at least one subject and',...
        'will be excluded from the analysis:'};
       
    ROI_3 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.28 0.35],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

    ROI_3_disp = uicontrol(ROI_3 , 'Style', 'listbox', 'String', dis_data,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.22 0.91 0.40],'fontunits','normalized', 'fontSize', 0.105,'Value', []);
    ROI_3_S1 = uicontrol(ROI_3,'Style','text','String', ROI_3_INFO1,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.22,'backgroundcolor',get(ROI_3,'color'), 'Position',[0.20 0.73 0.600 0.2]);
    ROI_3_S2 = uicontrol(ROI_3,'Style','text','String', 'Empty ROIs:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.55,'backgroundcolor',get(ROI_3,'color'), 'Position',[0.04 0.62 0.200 0.08]);    
    ROI_3_OK = uicontrol(ROI_3,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4, 'Position',[0.38 0.07 0.28 0.10],'callback', @ROI_3_function);
    movegui(ROI_3,'center');
        
    function ROI_3_function(~,~)
        close(ROI_3);
    end
    fprintf('Removed %s ', num2str(length(dis_data)) ,' ROIs from the ROI set\n');
    uiwait();
end

function [EXPORT] = ROI_F4(ROI_set, CTR)
    % Create full list
    
    builder = {};
    EXPORT = [];
    for i = 1:length(ROI_set(CTR).ROIs)
        gray = {i,horzcat('No ',num2str(i),': ',ROI_set(CTR).ROIs(i).name, ' :: ', num2str(ROI_set(CTR).ROIs(i).raw_size),' voxels', ' :: ' , num2str(ROI_set(CTR).ROIs(i).masked_size),' voxels ' , ':: ',num2str(ROI_set(CTR).ROIs(i).masked_size_percents), ' %'), ROI_set(CTR).ROIs(i).masked_size_percents};
        builder = vertcat(builder, gray);
    end
    
    lst_1 = builder;
    lst_2 = {};
    
    
    ROI_4_INFO1 = {'Remove heavily cropped ROIs with insufficient data, if necessary.'};
    ROI_4_INFO2 = {'No # :: ROI name :: Voxels before masking :: Voxels after masking :: Percent left'};

    selection_1 = {};          % Variable to store the selected list of conditions in BOX 1(as INDEX)
    selection_2 = {};          % Variable to store the selected list of conditions in BOX 2(as INDEX)
    
        
    ROI_4 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.32 0.55],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none','Windowstyle', 'Modal');

    ROI_4_disp_1 = uicontrol(ROI_4 , 'Style', 'listbox', 'String', lst_1(:,2,1),'Max', 100,'Units', 'normalized', 'Position',[0.048 0.565 0.91 0.30],'fontunits','normalized', 'fontSize', 0.098, 'Value', [], 'callback', @action_select_1);
    ROI_4_disp_2 = uicontrol(ROI_4 , 'Style', 'listbox', 'String', lst_2,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.14 0.91 0.25],'fontunits','normalized', 'fontSize', 0.10, 'Value', [], 'callback', @action_select_2);

    ROI_4_S1 = uicontrol(ROI_4,'Style','text','String', ROI_4_INFO1,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.54,'Position',[0.10 0.92 0.8 0.05],'backgroundcolor',get(ROI_4,'color'));
    ROI_4_S1a = uicontrol(ROI_4,'Style','text','String', ROI_4_INFO2,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.64,'HorizontalAlignment', 'left','Position',[0.048 0.87 0.91 0.040],'backgroundcolor',get(ROI_4,'color'));
    ROI_4_S2 = uicontrol(ROI_4,'Style','text','String', '% threshold','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.44,'HorizontalAlignment', 'left','Position',[0.84 0.475 0.13 0.055],'backgroundcolor',get(ROI_4,'color'));
    ROI_4_S3 = uicontrol(ROI_4,'Style','text','String', 'Removed ROIs:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'left','Position',[0.05 0.395 0.2 0.05],'backgroundcolor',get(ROI_4,'color'));
    
    ROI_4_REM_SEL = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Remove selected','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.047 0.48 0.24 0.063], 'callback', @action_3);
    ROI_4_REM_THRS = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Remove ROIs under % threshold','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.32 0.48 0.40 0.063], 'callback', @action_4);
    ROI_4_OK = uicontrol(ROI_4,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.047 0.056 0.24 0.063], 'callback', @action_8);
    ROI_4_RET_SEL = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Return selected','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.39 0.056 0.24 0.063], 'callback', @action_6);
    ROI_4_RET_ALL = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Return all','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4,'Position',[0.72 0.056 0.24 0.063], 'callback', @action_7);
    ROI_4_A = uicontrol(ROI_4,'Style','edit','String',[],'Units', 'normalized','fontunits','normalized', 'fontSize', 0.42,'HorizontalAlignment','center','Position',[0.74 0.48 0.1 0.06]);

    movegui(ROI_4,'center');    
    
    function action_select_1(~,~)
        index = get(ROI_4_disp_1, 'Value');  % Retrieves the users selection LIVE
        selection_1 = index;      
    end

    function action_select_2(~,~)
        index = get(ROI_4_disp_2, 'Value');  % Retrieves the users selection LIVE
        selection_2 = index;             
    end
   
    function action_3(~,~)
        
        % Checking if there is a selection from the user
        if isempty(selection_1)

            % if no selection, raise warning 
            warning('No ROIs selected');

        else

            % Else continue to add selected condition to removal list

            len_exst = length(lst_2);     % Find length of existing subjects in selected condition
            NEW_ROI = {};               % Creation of empty array to store new paths
            new_ones = 0;
            pres_len = 0;
            
            % Based on the selection add variables to a selected list
            NEW_ROI = vertcat(NEW_ROI, lst_1(selection_1,:,:)); %lst_1(j)); %lst_1(j,:)
            
            % check if new ROIs belong to existing list
            if ~isempty(lst_2)
                len_maker = size(NEW_ROI);
                len_maker_2 = size(lst_2);
                if len_maker(1) >= 2
                    % in the event there is more than 1 element to be added
                    bumper = [];
                    cmtr = 1;
                    for a = 1:len_maker(1)
                        for b = 1:len_maker_2(1)
                            if strcmp(NEW_ROI(a,2,1), lst_2(b,2,1))
                               bumper(cmtr) = a;
                               cmtr = cmtr+1;
                            end
                        end
                    end
                                     
                else
                    bumper = [];
                    cmtr = 1;
                    ls2_sz = size(lst_2);
                    for b = 1:ls2_sz(1)
                        if strcmp(NEW_ROI(1,2,1),lst_2(b,2,1))
                            bumper(cmtr) = b;
                            cmtr = cmtr+1;
                        end
                    end
                                        
                end
                
                % if there are new ROIs added to LST_2
                if length(bumper)>=2
                    drummer = 0;
                    for c = 1:length(bumper)
                        NEW_ROI(bumper(c)-drummer,:,:) = [];
                        drummer = drummer + 1;
                    end
                    new_ones = size(NEW_ROI);
                else
                    DFR = size(NEW_ROI);
                    for e = 1:DFR(1)
                        if NEW_ROI{e,1,1} == bumper
                            NEW_ROI(e,:,:) = [];
                        end
                    end
                    new_ones = size(NEW_ROI);
                end
                
               
                lst_2 = sortrows(vertcat(lst_2, NEW_ROI),1);
                
                pres_len = len_exst - new_ones(1);
                
                
            else
                lst_2 = vertcat(lst_2, NEW_ROI); 
                pres_len = length(lst_2);
                new_ones = 2;
            end


            % Logical condition to check if newly selected conditions have been added
            if new_ones(1) == 2
                    g_check = size(lst_2);
                    fprintf('ROIs selected: %d \n', g_check(1));
            elseif new_ones(1) == 0
                    warning('Newly selected ROIs are already present in the list, no new ROIs to remove');
            else
                    fprintf('New selected ROIs : %d \n', new_ones(1)); 
            end 

            % Set sorted list of conditions into GUI
            set(ROI_4_disp_2, 'String', lst_2(:,2,1));

        end
        
    end


    function action_4(~,~)

        lst_3 = {};
        len_exst = size(lst_2);
        new_ones = 0;
        pres_len = 0;
        name = get(ROI_4_A, 'String');
                
        if ~strcmp(name,'') & ~strcmp(name(1),' ')    
            
            thres = str2double(name);
            
            if isnan(thres)
                warning('Entered threshold should be a numeric character, please re-enter');
            elseif (thres<0) | (thres>100)
                warning('Entered threshold is beyond the bounds, please enter a threshold between 0 and 100%');
            else
                sz_rd = size(lst_1);
                bpm = [];
                ctr_g = 1;
                for aa = 1:sz_rd(1)
                    if lst_1{aa,3,1} <= thres
                        bpm(ctr_g) = aa;
                        ctr_g = ctr_g + 1;
                    end
                end
                lst_3 = lst_1(bpm, :, :);
                
                % Compiling the removal list
                if isempty(lst_2)
                    % if removing for the first time
                    lst_2 = vertcat(lst_2, lst_3); 
                    new_ones = 2;
                else
                    len_maker = size(lst_3);
                    len_maker_2 = size(lst_2);
                    
                    if len_maker(1) >= 2
                        % in the event there is more than 1 element to be added
                        bumper = [];
                        cmtr = 1;
                        for a = 1:len_maker(1)
                            for b = 1:len_maker_2(1)
                                if strcmp(lst_3(a,2,1), lst_2(b,2,1))
                                   bumper(cmtr) = a;
                                   cmtr = cmtr+1;
                                end
                            end
                        end

                    else
                        bumper = [];
                        cmtr = 1;
                        ls2_sz = size(lst_2);
                        for b = 1:ls2_sz(1)
                            if strcmp(lst_3(1,2,1),lst_2(b,2,1))
                                bumper(cmtr) = b;
                                cmtr = cmtr+1;
                            end
                        end

                    end

                    % if there are new ROIs added to LST_2
                    if length(bumper)>=2
                        drummer = 0;
                        for c = 1:length(bumper)
                            lst_3(bumper(c)-drummer,:,:) = [];
                            drummer = drummer + 1;
                        end
                        new_ones = size(lst_3);
                    else
                        lst_3(bumper,:,:) = [];
                        new_ones = size(lst_3);
                    end


                    lst_2 = sortrows(vertcat(lst_2, lst_3),1);

          
                end
                set(ROI_4_disp_2, 'String', lst_2(:,2,1));
                % Logical condition to check if newly selected conditions have been added
                if new_ones(1) == 2 && size(lst_2,1) ~= 0
                        g_check = size(lst_2); 
                        fprintf('ROIs selected: %d \n', g_check(1));
                        disp('do we reach here');
                        assignin('base', 'new_ones', new_ones);
                        assignin('base', 'lst_2', lst_2);
                        assignin('base', 'lst_3', lst_3);
                elseif new_ones(1) == 2 && size(lst_2,1) == 0
                        warning('ROIs below this threshold do not exist');
                    elseif new_ones(1) == 0
                        warning('All ROIs below this threshold have already been removed');
                    else
                        fprintf('%d ROIs selected at threshold %d \n', new_ones(1),thres);     
                end 
                end
        else
            warning('Threshold not entered or is invalid, please re-enter');
        end
    end

    function action_6(~,~)
        
        if isempty(lst_2)
            warning('No ROIs present to return');
        elseif isempty(selection_2)
            warning('No ROIs selected to return');
        else
            if length(selection_2) >= 2
                hippo = 0;
                for c = 1:length(selection_2)
                    lst_2(selection_2(c)-hippo,:,:) = [];
                    hippo = hippo + 1;
                end
                fprintf('Number of ROIs removed are %d \n', hippo);
            else
                lst_2(selection_2,:,:) = [];
                fprintf('Selected ROI has been removed \n');
            end
            
            if isempty(lst_2)
                lst_2 = {};
               set(ROI_4_disp_2, 'String', lst_2); 
            else
                set(ROI_4_disp_2, 'String', lst_2(:,2,1));
                set(ROI_4_disp_2, 'Value', []);
            end
            
        end
        
    end


    function action_7(~,~)
        if isempty(lst_2)
            warning('No ROIs present to return');
        else
            lion = size(lst_2);
            lst_2 = {};
            set(ROI_4_disp_2, 'String', lst_2);
            set(ROI_4_disp_2, 'Value', []);
            fprintf('%d ROIs have been returned \n',lion(1));
        end
    end


    function action_8(~,~)
        if isempty(lst_2)
            disp('Exporting existing set of ROis, No ROIs selected for removal');
            EXPORT = ROI_set;
            close(ROI_4);
        else
            disp('Exporting ROIs after removal of selected cropped regions');
            h_size = size(lst_2);
            inder = 0;
            for h = 1:h_size(1)
                ROI_set(CTR).ROIs(lst_2{h,1,1} - inder) = [];
                inder = inder + 1;
            end
            EXPORT = ROI_set;
            close(ROI_4);
        end
    end
        
    uiwait();
   
end

