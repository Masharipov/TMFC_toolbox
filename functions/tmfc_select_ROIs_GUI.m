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


% Enter a name for the ROI set
% !!! PUT CODE HERE FOR ROI SET NAME (from tmfc_ROI_SET)

% check if the code is called from GUI or CUI
OPD = findobj('Tag', 'MAIN_WINDOW');

if isempty(OPD)
    % if code is called from CUI 
    Operation_mode = 0; % Command line
    ROI_set = tmfc.ROI_set;
else
    % if the code is called from GUI 
    Operation_mode = 1; % GUI
    GDR = evalin('base', 'tmfc');  
    %ROI_set = GDR.ROI_set;
    
    % check for existing ROI sets
    ROI_exist = ROI_F0();
    
    switch (ROI_exist)
        
        case 0 % Add new ROI set (Primary addition)
            
            [ns_1, ns_2] = ROI_F1();

            if ns_1 == 1
                GDR.ROI_set = struct;
                Fitter(1);
                assignin('base', 'tmfc',GDR);
            end
            
        case 1 % Add ROI set to existing list (Secondary addition)
            ROI_F2();
                        % have to create condition to check for already existing names 
            % While loop to check for multiple same named ROIs - if entered by user
            
                      
    end
    
    
    
    
    %[ns_1, ns_2] = ROI_F1();
    

       
end




% TEMPORARY CODE:

        

% !!! YOU CAN ALSO ADD ALL NECESSARY SUPPLEMENTARY CODE FROM tmfc_select_ROIs_GUI_OLD


% 



% 










% Remove empty ROIs
% !!! FIND EMPTY ROIs (see ROI_set.ROIs.masked_size == 0)
% !!! ADD GUI HERE WHERE WE NOTIFY USER THAT EMPTY ROIs WILL BE REMOVED
% !!! SHOW WHICH ROIs WILL BE REMOVED
% !!! REMOVE EMPTY ROIs FROM THE ROI_set variable

% Remove cropped ROIs
% !!! ADD GUI HERE WHERE USER CAN REMOVW HIGHLY CROPPED IMAGES 
% !!! REMOVE THESE ROIs FROM THE ROI_set variable

% !!! UPDATE TMFC variable if function was called via TMFC GUI


function Fitter(NUM)
      
                CTR = NUM;
                GDR.ROI_set(CTR).set_name = ns_2;
                
                
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
                    close(w)
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
                
                a = {};
                in_ctr = 1;
                for i = 1:length(GDR.ROI_set(1).ROIs)
                    if GDR.ROI_set(CTR).ROIs(i).masked_size_percents == 0
                        a{in_ctr,1} = i;
                        a{in_ctr,2} = GDR.ROI_set(CTR).ROIs(i).name;
                        in_ctr = in_ctr + 1;
                    end
                end
                
                if ~isempty(a)
                    constructor = {};
                    for i = 1:length(a)
                        biege = horzcat('№ ',num2str(a{i,1}),': ',a{i,2});
                        disp(biege);
                        constructor = vertcat(constructor, biege);
                    end
                    
                    ROI_F3(constructor);
                    
                    s = 0;
                    for i = 1:length(a)
                        GDR.ROI_set(CTR).ROIs(a{i,1}-s) = [];
                        s = s +1;
                    end    

                    
                end
                
                
end

    

         




function ROI_F4(~,~)


    ROI_4_INFO1 = {'Remove heavily cropped ROIs with insufficient data, if necessary.'};
    lst_1 = {};
    lst_2 = {};
    selection_1 = {};          % Variable to store the selected list of conditions in BOX 1(as INDEX)
    selection_2 = {};          % Variable to store the selected list of conditions in BOX 2(as INDEX)
    
    TEST_SET_R4 = {'№ 1: ROI_name_1 :: 250 voxels :: 20 voxels :: 8%',...
        '№ 2: ROI_name_2 :: 600 voxels :: 600 voxels :: 100%',...
        '№ 3: ROI_name_3 :: 400 voxels :: 200 voxels :: 50%',...
        '№ 4: ROI_name_3 :: 100 voxels :: 9 voxels :: 9 %'};
    
    TEST_SET_R42 = {'№ 1: ROI_name_1 :: 250 voxels :: 20 voxels :: 8%',...
        '№ 4: ROI_name_3 :: 100 voxels :: 9 voxels :: 9 %'};
    
    ROI_4 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.32 0.48],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

    ROI_4_disp_1 = uicontrol(ROI_4 , 'Style', 'listbox', 'String', TEST_SET_R4,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.58 0.91 0.30],'fontunits','normalized', 'fontSize', 0.105);
    ROI_4_disp_2 = uicontrol(ROI_4 , 'Style', 'listbox', 'String', TEST_SET_R42,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.15 0.91 0.25],'fontunits','normalized', 'fontSize', 0.13);

    ROI_4_S1 = uicontrol(ROI_4,'Style','text','String', ROI_4_INFO1,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.54);
    ROI_4_S2 = uicontrol(ROI_4,'Style','text','String', '% threshold','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.44);
    ROI_4_S3 = uicontrol(ROI_4,'Style','text','String', 'Removed ROIs:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.50);
   
    ROI_4_REM_SEL = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Remove selected','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_REM_THRS = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Remove ROIs under % threshold','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_OK = uicontrol(ROI_4,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_RET_SEL = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Return selected','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_RET_ALL = uicontrol(ROI_4,'Style','pushbutton', 'String', 'Return all','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_4_A = uicontrol(ROI_4,'Style','edit','String','10','Units', 'normalized','fontunits','normalized', 'fontSize', 0.42,'HorizontalAlignment','center');
    
    
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
    set(ROI_4_disp_1, 'callback', @action_select_1)
    set(ROI_4_disp_2, 'Value', []);
    set(ROI_4_disp_2, 'callback', @action_select_2)
    
   
    set(ROI_4_REM_SEL, 'callback', @action_3)
    set(ROI_4_REM_THRS, 'callback', @action_4)
    %set(ROI_4_A, 'callback', @action_5)
    set(ROI_4_RET_SEL, 'callback', @action_6)
    set(ROI_4_RET_ALL, 'callback', @action_7)
    set(ROI_4_OK, 'callback', @action_8);
        
    function action_select_1(~,~)
        index = get(ROI_4_disp_1, 'Value');  % Retrieves the users selection LIVE
        selection_1 = index;      
    end

    function action_select_2(~,~)
        index = get(ROI_4_disp_2, 'Value');  % Retrieves the users selection LIVE
        selection_2 = index;             
    end
    

end


end
% initial sorting - maybe not needed
function [out_list] = sorter_1(in_list)
    [~,index] = sortrows([in_list.sess; in_list.number]');
    out_list = in_list(index); 
    clear index
end




% GUI to check if previously existing ROIs 
function [STATS_0] = ROI_F0(~,~)
      
    ROI_0 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.16 0.16],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none','WindowStyle', 'modal','CloseRequestFcn', @stable_exit_ROI_0);
    
    % Initializing Elements of the UI
    ROI_0_S = uicontrol(ROI_0,'Style','text','String', ['Have any ROI sets been previously selected?'],'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.38);
    

    ROI_0_YES = uicontrol(ROI_0,'Style','pushbutton', 'String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45);
    ROI_0_NO = uicontrol(ROI_0,'Style','pushbutton', 'String', 'No','Units', 'normalized','fontunits','normalized', 'fontSize', 0.45);

    ROI_0_S.Position = [0.10 0.55 0.80 0.260];
    ROI_0_YES.Position = [0.14 0.25 0.320 0.170];
    ROI_0_NO.Position = [0.52 0.25 0.320 0.170];
    
    set(ROI_0_S,'backgroundcolor',get(ROI_0,'color'));

    % Assigning Functions Callbacks for each Element (button, listbox etc)

    set(ROI_0_YES, 'callback', @ROI_0_YES_ACTION);
    set(ROI_0_NO, 'callback', @ROI_0_NO_ACTION);
    
    function stable_exit_ROI_0(~,~)
       delete(ROI_0); 
       STATS_0 = NaN;
    end
    
    
    function ROI_0_YES_ACTION(~,~)
        delete(ROI_0);
        STATS_0 = 1;
    end

    function ROI_0_NO_ACTION(~,~)
        delete(ROI_0);
        STATS_0 = 0;
    end
    uiwait();
end

% Secondary sorting - to use
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

function ROI_F2(~,~)


    TEST_SET = {'ROI_set1 (300 ROIs)','ROI_set2 (240 ROIs)'};
    ROI_2 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.28 0.35],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

    ROI_2_disp = uicontrol(ROI_2 , 'Style', 'listbox', 'String', TEST_SET,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.25 0.91 0.49],'fontunits','normalized', 'fontSize', 0.09);

    ROI_2_S1 = uicontrol(ROI_2,'Style','text','String', 'Select ROI set','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.58);
    ROI_2_S2 = uicontrol(ROI_2,'Style','text','String', 'Sets:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.64);
    
    ROI_2_OK = uicontrol(ROI_2,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
    ROI_2_Select = uicontrol(ROI_2,'Style','pushbutton', 'String', 'Select new ROI set','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
     
    ROI_2_S1.Position = [0.29 0.85 0.400 0.09];
    ROI_2_S2.Position = [0.04 0.74 0.100 0.08];
     
    ROI_2_OK.Position = [0.16 0.10 0.28 0.10]; % W H
    ROI_2_Select.Position = [0.56 0.10 0.28 0.10];
     
    set(ROI_2_S1,'backgroundcolor',get(ROI_2,'color'));
    set(ROI_2_S2,'backgroundcolor',get(ROI_2,'color'));
    set(ROI_2_disp, 'Value', []);
    
    %set(ROI_2_OK, 'callback', @function1);
    %set(ROI_2_Select, 'callback', @function2);


end

function ROI_F3(dis_data)


    ROI_3_INFO1 = {'Warning, the following ROIs do not',...
        'contain data for at least one subject and',...
        'will be excluded from the analysis:'};
       
    ROI_3 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.28 0.35],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

    ROI_3_disp = uicontrol(ROI_3 , 'Style', 'listbox', 'String', dis_data,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.22 0.91 0.40],'fontunits','normalized', 'fontSize', 0.105);

    ROI_3_S1 = uicontrol(ROI_3,'Style','text','String', ROI_3_INFO1,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.24);
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
    disp('');
    uiwait();

end
         