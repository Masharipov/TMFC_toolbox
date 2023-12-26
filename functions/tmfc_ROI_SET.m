function tmfc_ROI_SET(~,~)

    ROI_1 = figure("Name", "Select ROIs", "NumberTitle", "off", "Units", "normalized", "Position", [0.62 0.50 0.16 0.16],'Resize','off','color','w','MenuBar', 'none','ToolBar', 'none');
    
    % Initializing Elements of the UI
    ROI_S_Q = uicontrol(ROI_1,'Style','text',"String", "Enter a name for the ROI set","Units", "normalized", 'fontunits','normalized', 'fontSize', 0.40);
    ROI_S_A = uicontrol(ROI_1,'Style','edit',"String","","Units", "normalized",'fontunits','normalized', 'fontSize', 0.45,"HorizontalAlignment","left");

    ROI_OK= uicontrol(ROI_1,'Style','pushbutton', "String", "OK","Units", "normalized",'fontunits','normalized', 'fontSize', 0.45);
    ROI_Help = uicontrol(ROI_1,'Style','pushbutton', "String", "Help","Units", "normalized",'fontunits','normalized', 'fontSize', 0.45);
    
    ROI_S_Q.Position = [0.16 0.60 0.700 0.230];
    ROI_S_A.Position = [0.12 0.44 0.800 0.190];
    
    ROI_OK.Position = [0.12 0.14 0.310 0.180];
    ROI_Help.Position = [0.61 0.14 0.310 0.180];
    
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
end