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
%   tmfc.subjects.path     - List of paths to SPM.mat files for N subjects
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
% check if the code is called from GUI or CLI
OPD = findobj('Tag', 'MAIN_WINDOW');


if isempty(OPD)
    % if code is called from CUI 
    GDR = tmfc;
    
    if ~isempty(GDR.subjects(1).path)
    disable_GUI();
        
    [ns_1, ns_2] = ROI_F1();
    
    if ns_1 == 1
        GDR.ROI_set = struct;
        Fitter(1);
        ROI_set = GDR.ROI_set(1);
    else
        disp('ROIs not selected');
        enable_GUI();
        ROI_set = -1;
    end
    else
        warning('Please select subjects to continue selection of ROIs');
        ROI_set = -1;
    end
    
else
    % if the code is called from GUI 
    GDR = evalin('base', 'tmfc');  
    %ROI_set = GDR.ROI_set;
    
    if ~isempty(GDR.subjects(1).path)
    
    disable_GUI();
    % check for existing ROI sets
    %ROI_exist = ROI_F0();
    % ROI_set = -1 (ROIs not selected or ROI select window is closed)
    % ROI_set = 0 (if ROIs are selected for the first time, then use the
    % first ROI set)
    % ROI_set = position (if there are many ROIs then use the position
    % returned by the user's selection)
    
    if isempty(GDR.ROI_set)
        ROI_exist = 0;
    else
        ROI_exist = 1;
    end
    
    
    
    switch (ROI_exist)
        
        case 0 % Add new ROI set (Primary addition)
            
            [ns_1, ns_2] = ROI_F1();

            if ns_1 == 1
                
                GDR.ROI_set = struct;
                try
                    Fitter(1);
                    if full_flag == 1
                        assignin('base', 'tmfc',GDR);
                        enable_GUI();
                        % add selection of index from the whole list
                        ROI_set = 1;
                        
                    else
                       disp('ROIs have not been selected');
                       enable_GUI();
                       ROI_set = -1;
                    end
                    
                catch 
                    disp('ROIs have not been selected');
                    enable_GUI();
                    ROI_set = -1;
                end
                
            else
                disp('ROIs not selected');
                enable_GUI();
                ROI_set = -1;
            end
            
        case 1 % Add ROI set to existing list (Secondary addition)
            
            lst_4 = {};
            for l = 1:length(GDR.ROI_set)
                matter = {l,horzcat(GDR.ROI_set(l).set_name, ' (',num2str(length(GDR.ROI_set(l).ROIs)),' ROIs)')};
                lst_4 = vertcat(lst_4, matter);
            end  
            
            [R_ans, pos] = ROI_F2(lst_4);
            SZ_4 = size(lst_4);
            
            if R_ans == 1
                
                [ns_1, ns_2] = ROI_F1();
                
                if ns_1 == 1
                    Fitter(SZ_4(1)+1);
                    if full_flag == 1
                        assignin('base', 'tmfc', GDR);
                        enable_GUI();
                        % add selection of index from the whole list
                        ROI_set = SZ_4(1)+1;
                    else
                        disp('ROIs have not been selected');
                        enable_GUI();
                        ROI_set = -1;
                    end
                else
                    disp('ROIs have not been selected');
                    enable_GUI();
                    ROI_set = -1;
                end
            elseif R_ans == 0 & pos ~= 0
                fprintf('Selected ROI for processing is: %s \n', char(lst_4(pos,2)));
                enable_GUI(); 
                ROI_set = pos;
            else
               disp('ROIs have not been selected');
               enable_GUI();
               ROI_set = -1;
            end
                      
    end
    
    else
        warning('Please select subjects to continue selection of ROIs');
    end
          
end



function Fitter(NUM)
      
                Flag_1 = 0;
                Flag_2 = 0;
                Flag_3 = 0;
                
                CTR = NUM;
                GDR.ROI_set(CTR).set_name = ns_2;
                GDR.ROI_set(CTR).subjects = struct;
                GDR.ROI_set(CTR).subjects = struct;
                
                GDR.ROI_set(CTR).contrasts.BSC_after_FIR(1).title = '';
                GDR.ROI_set(CTR).contrasts.BSC_after_FIR(1).weights = [];
                GDR.ROI_set(CTR).contrasts.BSC_without_FIR(1).title = '';
                GDR.ROI_set(CTR).contrasts.BSC_without_FIR(1).weights = [];
                
                GDR.ROI_set(CTR).contrasts.gPPI_after_FIR(1).title = '';
                GDR.ROI_set(CTR).contrasts.gPPI_after_FIR(1).weights = [];
                GDR.ROI_set(CTR).contrasts.gPPI_without_FIR(1).title = '';
                GDR.ROI_set(CTR).contrasts.gPPI_without_FIR(1).weights = [];
                
                
                
                try
                % Select ROIs
                [paths] = spm_select(inf,'any','Select ROI masks',{},pwd);
                for i = 1:size(paths,1)
                    GDR.ROI_set(CTR).ROIs(i).path = deblank(paths(i,:));
                    [~, GDR.ROI_set(CTR).ROIs(i).name, ~] = fileparts(deblank(paths(i,:)));
                end
                
                
                
                
                % Create 'Masked_ROIs' folder
                if ~isfolder([GDR.project_path filesep 'Masked_ROIs' filesep GDR.ROI_set(CTR).set_name])
                    mkdir([GDR.project_path filesep 'Masked_ROIs' filesep GDR.ROI_set(CTR).set_name]);
                end
                
                
                if ~isempty(paths)
                    Flag_1 = 1;
                end
                
                catch
                    
                    disp('ROIs not selected');
                    close(w);
                    enable_GUI();
                
                end
                
                
                if Flag_1 == 1
                    
                    % Create group mean binary mask
                    for i = 1:length(GDR.subjects)
                        sub_mask{i,1} = [GDR.subjects(i).path(1:end-7) 'mask.nii'];
                    end
                    group_mask = [GDR.project_path filesep 'Masked_ROIs' filesep GDR.ROI_set(CTR).set_name filesep 'group_mean_mask.nii'];
                    spm_imcalc(sub_mask,group_mask,'prod(X)',{1,0,1,2});



                    % Calculate ROI size before masking
                    w = waitbar(0,'Please wait...','Name','Calculating raw ROI sizes');
                    group_mask = spm_vol(group_mask);
                    N = numel(GDR.ROI_set(CTR).ROIs);
                    for i = 1:N
                        ROI_mask = spm_vol(GDR.ROI_set(CTR).ROIs(i).path);           
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
                        GDR.ROI_set(CTR).ROIs(i).raw_size = nnz(Y);
                        try
                            waitbar(i/N,w,['ROI № ' num2str(i,'%.f')]);
                        end
                    end

                    try
                        close(w);
                    end

                    % Mask the ROI images by the goup mean binary mask
                    w = waitbar(0,'Please wait...','Name','Masking ROIs by group mean mask');
                    input_images{1,1} = group_mask.fname;
                    for i = 1:N
                        input_images{2,1} = GDR.ROI_set(CTR).ROIs(i).path;
                        ROI_mask = [GDR.project_path filesep 'Masked_ROIs' filesep GDR.ROI_set(CTR).set_name filesep GDR.ROI_set(CTR).ROIs(i).name '_masked.nii'];
                        spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
                        try
                            waitbar(i/N,w,['ROI № ' num2str(i,'%.f')]);
                        end
                    end

                    try
                        close(w)
                    end

                    % Calculate ROI size after masking
                    w = waitbar(0,'Please wait...','Name','Calculating masked ROI sizes');
                    for i = 1:N
                        GDR.ROI_set(CTR).ROIs(i).masked_size = nnz(spm_read_vols(spm_vol([GDR.project_path filesep 'Masked_ROIs' filesep GDR.ROI_set(CTR).set_name filesep GDR.ROI_set(CTR).ROIs(i).name '_masked.nii'])));
                        GDR.ROI_set(CTR).ROIs(i).masked_size_percents = 100*GDR.ROI_set(CTR).ROIs(i).masked_size/GDR.ROI_set(CTR).ROIs(i).raw_size;
                        try
                            waitbar(i/N,w,['ROI № ' num2str(i,'%.f')]);
                        end
                    end

                    try
                        close(w)
                    end
                    
                    Flag_2 = 1;
                end
                    
                    
                if Flag_2 == 1 & Flag_1 == 1
                    
                    % Remove Empty ROIs
                    %biege = {};
                    a = {};
                    in_ctr = 1;
                    for i = 1:length(GDR.ROI_set(CTR).ROIs)
                        if GDR.ROI_set(CTR).ROIs(i).masked_size_percents == 0
                            a{in_ctr,1} = i;
                            a{in_ctr,2} = GDR.ROI_set(CTR).ROIs(i).name;
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
                            GDR.ROI_set(CTR).ROIs(a{i,1}-s) = [];
                            s = s +1;
                        end    

                        if isempty(GDR.ROI_set(CTR).ROIs)
                           Flag_3 = 0;
                           disp('No eligible ROIs left for selection, Please try again');
                        else
                            Flag_3 = 1;
                        end
                    else
                        Flag_3 = 1;
%                         disp('No eligible ROIs left for selection, Please try again');
%                         disp('check 1');
                    end
                    
                end
                
                if Flag_1 == 1 & Flag_2 == 1 & Flag_3 == 1
                    GDR = ROI_F4(GDR, CTR);
                    if ~isempty(GDR) 
                        full_flag = 1;
                        enable_GUI();
                    end
                end
                %assignin('base', 'RVP',GDR);
                
                
end

    
        


end

% GUI to add new ROI set
function [RF1_flag, ret_name] = ROI_F1(~,~)
    
    ROI_1 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.62 0.50 0.16 0.14],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none','WindowStyle', 'modal','CloseRequestFcn', @stable_exit);

    % Initializing Elements of the UI
    ROI_1_S1 = uicontrol(ROI_1,'Style','text','String', 'Enter a name for the ROI set','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.40);
    ROI_1_A1 = uicontrol(ROI_1,'Style','edit','String','','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45,'HorizontalAlignment','left');

    ROI_1_OK= uicontrol(ROI_1,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45);
    ROI_1_Help = uicontrol(ROI_1,'Style','pushbutton', 'String', 'Help','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45);

    ROI_1_S1.Position = [0.14 0.60 0.700 0.230];
    ROI_1_A1.Position = [0.10 0.44 0.800 0.190];

    ROI_1_OK.Position = [0.10 0.16 0.310 0.180];
    ROI_1_Help.Position = [0.59 0.16 0.310 0.180];

    set(ROI_1_S1,'backgroundcolor',get(ROI_1,'color'));

    % Assigning Functions Callbacks for each Element (button, listbox etc)

    set(ROI_1_OK, 'callback', @get_name);
    set(ROI_1_Help, 'callback', @help_win_R);
    
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
            fprintf('Name set %s\n', name);
            delete(ROI_1);
            RF1_flag = 1;
            ret_name = name;
        else
            warning('Name not entered or is invalid, please re-enter');
        end

    end

    function help_win_R(~,~)

        ROI_1_H = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.50 0.40 0.16 0.16],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');
        RH_TEXT = uicontrol(ROI_1_H,'Style','text','String', 'HELP Window under development','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.40);
        RH_OK= uicontrol(ROI_1_H,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45);

        RH_TEXT.Position = [0.16 0.60 0.700 0.230];
        RH_OK.Position = [0.35 0.14 0.310 0.180];

        set(RH_TEXT,'backgroundcolor',get(ROI_1_H,'color'));
        set(RH_OK, 'callback', @RH_CL);

        function RH_CL(~,~)
            close(ROI_1_H);
        end

    end
    uiwait();
end

function [new_flag, position] = ROI_F2(LIST_SETS,~)
    
    new_flag = 0;
    position = 0;
    
    ROI_2 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.28 0.35],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

    ROI_2_disp = uicontrol(ROI_2 , 'Style', 'listbox', 'String', LIST_SETS(:,2),'Units', 'normalized', 'Position',[0.048 0.25 0.91 0.49],'fontunits','normalized', 'fontSize', 0.09);

    ROI_2_S1 = uicontrol(ROI_2,'Style','text','String', 'Select ROI set','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.58);
    ROI_2_S2 = uicontrol(ROI_2,'Style','text','String', 'Sets:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.64);
    
    ROI_2_OK = uicontrol(ROI_2,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_2_Select = uicontrol(ROI_2,'Style','pushbutton', 'String', 'Select new ROI set','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
     
    ROI_2_S1.Position = [0.29 0.85 0.400 0.09];
    ROI_2_S2.Position = [0.04 0.74 0.100 0.08];
     
    ROI_2_OK.Position = [0.16 0.10 0.28 0.10]; % W H
    ROI_2_Select.Position = [0.56 0.10 0.28 0.10];
    
    selection_3 = {};
    set(ROI_2_disp, 'Value', 1);
    selection_3 = 1;
    
    set(ROI_2_S1,'backgroundcolor',get(ROI_2,'color'));
    set(ROI_2_S2,'backgroundcolor',get(ROI_2,'color'));
    set(ROI_2_disp, 'callback', @action_select_M1);
    
    set(ROI_2_OK, 'callback', @ROI_F2_OK);
    set(ROI_2_Select, 'callback', @ROI_F2_SELECT);
    
     
    function action_select_M1(~,~)
        index = get(ROI_2_disp, 'Value');  % Retrieves the users selection LIVE
        selection_3 = index;    
    end

    
    
    function ROI_F2_OK(~,~)
        new_flag = 0;
        position = selection_3;
        close(ROI_2);
    end

    function ROI_F2_SELECT(~,~)
        new_flag = 1;
        close(ROI_2);
        position = 0;
    end
    
    uiwait();
    
end

function ROI_F3(dis_data)


    ROI_3_INFO1 = {'Warning, the following ROIs do not',...
        'contain data for at least one subject and',...
        'will be excluded from the analysis:'};
       
    ROI_3 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.28 0.35],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

    ROI_3_disp = uicontrol(ROI_3 , 'Style', 'listbox', 'String', dis_data,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.22 0.91 0.40],'fontunits','normalized', 'fontSize', 0.105);

    ROI_3_S1 = uicontrol(ROI_3,'Style','text','String', ROI_3_INFO1,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.22);
    ROI_3_S2 = uicontrol(ROI_3,'Style','text','String', 'Empty ROIs:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.55);
    
    ROI_3_OK = uicontrol(ROI_3,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
     
    ROI_3_S1.Position = [0.20 0.73 0.600 0.2]; 
    ROI_3_S2.Position = [0.04 0.62 0.200 0.08];
     
    ROI_3_OK.Position = [0.38 0.07 0.28 0.10]; % W H
     
    set(ROI_3_S1,'backgroundcolor',get(ROI_3,'color'));
    set(ROI_3_S2,'backgroundcolor',get(ROI_3,'color'));
    set(ROI_3_disp, 'Value', []);
    
    set(ROI_3_OK, 'callback', @ROI_3_function);
    
    function ROI_3_function(~,~)
        close(ROI_3);
    end
    fprintf('Removed %s ', num2str(length(dis_data)) ,' ROIs from the ROI set');
    fprintf('\n');
    disp('');
    uiwait();

end

function [EXPORT] = ROI_F4(GDR, CTR)
    % create full list
    
    builder = {};
    EXPORT = [];
    for i = 1:length(GDR.ROI_set(CTR).ROIs)
        gray = {i,horzcat('№ ',num2str(i),': ',GDR.ROI_set(CTR).ROIs(i).name, ' :: ', num2str(GDR.ROI_set(CTR).ROIs(i).raw_size),' voxels', ' :: ' , num2str(GDR.ROI_set(CTR).ROIs(i).masked_size),' voxels ' , ':: ',num2str(GDR.ROI_set(CTR).ROIs(i).masked_size_percents), ' %'), GDR.ROI_set(CTR).ROIs(i).masked_size_percents};
        builder = vertcat(builder, gray);
    end
    
    lst_1 = builder;
    lst_2 = {};
    
    
    ROI_4_INFO1 = {'Remove heavily cropped ROIs with insufficient data, if necessary.'};

    selection_1 = {};          % Variable to store the selected list of conditions in BOX 1(as INDEX)
    selection_2 = {};          % Variable to store the selected list of conditions in BOX 2(as INDEX)
    
        
    ROI_4 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.32 0.48],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none','Windowstyle', 'Modal');

    ROI_4_disp_1 = uicontrol(ROI_4 , 'Style', 'listbox', 'String', lst_1(:,2,1),'Max', 100,'Units', 'normalized', 'Position',[0.048 0.58 0.91 0.30],'fontunits','normalized', 'fontSize', 0.100);
    ROI_4_disp_2 = uicontrol(ROI_4 , 'Style', 'listbox', 'String', lst_2,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.15 0.91 0.25],'fontunits','normalized', 'fontSize', 0.11);

    ROI_4_S1 = uicontrol(ROI_4,'Style','text','String', ROI_4_INFO1,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.54);
    ROI_4_S2 = uicontrol(ROI_4,'Style','text','String', '% threshold','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.44);
    ROI_4_S3 = uicontrol(ROI_4,'Style','text','String', 'Removed ROIs:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.50);
   
    ROI_4_REM_SEL = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Remove selected','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_REM_THRS = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Remove ROIs under % threshold','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_OK = uicontrol(ROI_4,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_RET_SEL = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Return selected','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_RET_ALL = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Return all','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_A = uicontrol(ROI_4,'Style','edit','String',[],'Units', 'normalized','fontunits','normalized', 'fontSize', 0.42,'HorizontalAlignment','center');
    
    
    ROI_4_S1.Position = [0.10 0.89 0.8 0.06]; 
    ROI_4_REM_SEL.Position = [0.048 0.49 0.24 0.07]; 
    ROI_4_REM_THRS.Position = [0.32 0.49 0.40 0.07]; 
    ROI_4_A.Position = [0.74 0.49 0.1 0.07]; 
    ROI_4_S2.Position = [0.84 0.485 0.13 0.06]; 
    ROI_4_S3.Position = [0.05 0.40 0.2 0.06]; 
    ROI_4_OK.Position = [0.05 0.06 0.24 0.07]; 
    ROI_4_RET_SEL.Position = [0.39 0.06 0.24 0.07]; 
    ROI_4_RET_ALL.Position = [0.72 0.06 0.24 0.07]; 
    
     
    set(ROI_4_S1,'backgroundcolor',get(ROI_4,'color'));
    set(ROI_4_S2,'backgroundcolor',get(ROI_4,'color'));
    set(ROI_4_S3,'backgroundcolor',get(ROI_4,'color'));
    set(ROI_4_disp_1, 'Value', []);
    set(ROI_4_disp_1, 'callback', @action_select_1);
    set(ROI_4_disp_2, 'Value', []);
    set(ROI_4_disp_2, 'callback', @action_select_2);
    
   
    set(ROI_4_REM_SEL, 'callback', @action_3);
    set(ROI_4_REM_THRS, 'callback', @action_4);
    set(ROI_4_RET_SEL, 'callback', @action_6);
    set(ROI_4_RET_ALL, 'callback', @action_7);
    set(ROI_4_OK, 'callback', @action_8);
        
    
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
                warning('Enetered threshold is beyond the bounds, please enter a threshold between 0 and 100%');
                
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
                
                
                % compiling the removal list
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
                if new_ones(1) == 2
                        g_check = size(lst_2);
                        fprintf('ROIs selected: %d \n', g_check(1));
                    elseif new_ones(1) == 0
                        warning('All ROIs below this threshold have already been removed');
                    else
                        fprintf('%d',new_ones(1));
                        fprintf(' ROIs selected at threshold %d ', thres); 
                        fprintf('%% \n');
                        
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
            fprintf('%d',lion(1));
            fprintf(' ROIs have been returned \n');
        end
    end


    function action_8(~,~)
        if isempty(lst_2)
            disp('No ROIs selected for removal, exporting existing set');
            EXPORT = GDR;
            close(ROI_4);
        else
            disp('Exporting ROIs after removal of selected cropped regions');
            h_size = size(lst_2);
            inder = 0;
            for h = 1:h_size(1)
                GDR.ROI_set(CTR).ROIs(lst_2{h,1,1} - inder) = [];
                inder = inder + 1;
            end
            EXPORT = GDR;
            close(ROI_4);
        end
    end
    
    

    uiwait();
    

end

function enable_GUI(~,~)
                    try
                        h_FREZ_1 = findobj('Tag','MAIN_WINDOW');
                        F_data_1 = guidata(h_FREZ_1); 
                        set([F_data_1.SUB,F_data_1.FIR_TR, F_data_1.LSS_R, F_data_1.LSS_RW, F_data_1.BSC, F_data_1.gPPI,F_data_1.save_p, F_data_1.open_p, F_data_1.change_p, F_data_1.settings,F_data_1.BGFC],'Enable', 'on');
                    end
end

function disable_GUI(~,~)

                    try
                        h_FREZ_1 = findobj('Tag','MAIN_WINDOW');
                        F_data_1 = guidata(h_FREZ_1); 
                        set([F_data_1.SUB,F_data_1.FIR_TR, F_data_1.LSS_R, F_data_1.LSS_RW, F_data_1.BSC, F_data_1.gPPI,F_data_1.save_p, F_data_1.open_p, F_data_1.change_p, F_data_1.settings,F_data_1.BGFC],'Enable', 'off');
                    end
end
