function tmfc_ROI_SET(~,~)

    ROI_1 = figure("Name", "Select ROIs", "NumberTitle", "off", "Units", "normalized", "Position", [0.62 0.50 0.16 0.14],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');
    
    % Initializing Elements of the UI
    ROI_S_Q = uicontrol(ROI_1,'Style','text',"String", "Enter a name for the ROI set","Units", "normalized", 'fontunits','normalized', 'fontSize', 0.40);
    ROI_S_A = uicontrol(ROI_1,'Style','edit',"String","","Units", "normalized",'fontunits','normalized', 'fontSize', 0.45,"HorizontalAlignment","left");

    ROI_OK= uicontrol(ROI_1,'Style','pushbutton', "String", "OK","Units", "normalized",'fontunits','normalized', 'fontSize', 0.45);
    ROI_Help = uicontrol(ROI_1,'Style','pushbutton', "String", "Help","Units", "normalized",'fontunits','normalized', 'fontSize', 0.45);
    
    ROI_S_Q.Position = [0.14 0.60 0.700 0.230];
    ROI_S_A.Position = [0.10 0.44 0.800 0.190];
    
    ROI_OK.Position = [0.10 0.16 0.310 0.180];
    ROI_Help.Position = [0.59 0.16 0.310 0.180];
    
    set(ROI_S_Q,'backgroundcolor',get(ROI_1,'color'));

    % Assigning Functions Callbacks for each Element (button, listbox etc)
    
    set(ROI_OK, 'callback', @get_name);
    set(ROI_Help, 'callback', @help_win_R);


    function get_name(~,~)

        name = get(ROI_S_A, 'String');
        
        if name ~= "" & name ~= " "
            GN = evalin("base", "tmfc");
            GN.ROIs_set_name = string(name); % can be saved as Character array
            disp("Name set """+ name+"""");
            close(ROI_1);
            assignin("base", "tmfc", GN);
        else
            warning("Name not entered or is invalid, please re-enter");
        end
        
    end

    function help_win_R(~,~)
        
        RH_1 = figure("Name", "Select ROIs", "NumberTitle", "off", "Units", "normalized", "Position", [0.50 0.40 0.16 0.16],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');
        RH_TEXT = uicontrol(RH_1,'Style','text',"String", "HELP Window under development","Units", "normalized", 'fontunits','normalized', 'fontSize', 0.40);
        RH_OK= uicontrol(RH_1,'Style','pushbutton', "String", "OK","Units", "normalized",'fontunits','normalized', 'fontSize', 0.45);
        
        RH_TEXT.Position = [0.16 0.60 0.700 0.230];
        RH_OK.Position = [0.35 0.14 0.310 0.180];
        
        set(RH_TEXT,'backgroundcolor',get(RH_1,'color'));
        set(RH_OK, "callback", @RH_CL);
        
        function RH_CL(~,~)
            close(RH_1);
        end
        
    end

    
function ROI_2(~,~)


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

         

function ROI_3(~,~)


    ROI_3_INFO1 = {'Warning, the following ROIs do not',...
        'contain data for at least one subject and',...
        'will be excluded from the analysis:'};
    
    TEST_SET_R3 = {'№ 99: ROI_name_X', '№ 105: ROI_name_Y'};
    
    ROI_3 = figure('Name', 'Select ROIs', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.35 0.40 0.28 0.35],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');

    ROI_3_disp = uicontrol(ROI_3 , 'Style', 'listbox', 'String', TEST_SET_R3,'Max', 100,'Units', 'normalized', 'Position',[0.048 0.22 0.91 0.40],'fontunits','normalized', 'fontSize', 0.105);

    ROI_3_S1 = uicontrol(ROI_3,'Style','text','String', ROI_3_INFO1,'Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.24);
    ROI_3_S2 = uicontrol(ROI_3,'Style','text','String', 'Empty ROIs:','Units', 'normalized', 'fontunits','normalized', 'fontSize', 0.55);
    
    ROI_3_OK = uicontrol(ROI_3,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.4);
     
    ROI_3_S1.Position = [0.20 0.73 0.600 0.2]; % X, y, W, H
    ROI_3_S2.Position = [0.04 0.62 0.200 0.08];
     
    ROI_3_OK.Position = [0.38 0.07 0.28 0.10]; % W H
     
    set(ROI_3_S1,'backgroundcolor',get(ROI_3,'color'));
    set(ROI_3_S2,'backgroundcolor',get(ROI_3,'color'));
    set(ROI_3_disp, 'Value', []);
    
    %set(ROI_3_OK, 'callback', @function1);


end


function ROI_4(~,~)


    ROI_4_INFO1 = {'Remove heavily cropped ROIs with insufficient data, if necessary.'};
    
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
    
    
    ROI_4_S1.Position = [0.10 0.89 0.8 0.06]; % X, y, W, H
    ROI_4_REM_SEL.Position = [0.048 0.49 0.24 0.07]; % X, y, W, H
    ROI_4_REM_THRS.Position = [0.32 0.49 0.40 0.07]; % X, y, W, H
    ROI_4_A.Position = [0.74 0.49 0.1 0.07]; % X, y, W, H
    ROI_4_S2.Position = [0.84 0.485 0.13 0.06]; % X, y, W, H
    ROI_4_S3.Position = [0.05 0.40 0.2 0.06]; % X, y, W, H
    ROI_4_OK.Position = [0.05 0.06 0.24 0.07]; % X, y, W, H
    ROI_4_RET_SEL.Position = [0.39 0.06 0.24 0.07]; % X, y, W, H
    ROI_4_RET_ALL.Position = [0.72 0.06 0.24 0.07]; % X, y, W, H
    
     
    set(ROI_4_S1,'backgroundcolor',get(ROI_4,'color'));
    set(ROI_4_S2,'backgroundcolor',get(ROI_4,'color'));
    set(ROI_4_S3,'backgroundcolor',get(ROI_4,'color'));
    set(ROI_4_disp_1, 'Value', []);
    set(ROI_4_disp_2, 'Value', []);
    
    


end

          


end