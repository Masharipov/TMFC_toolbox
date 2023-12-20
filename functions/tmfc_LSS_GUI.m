function LSS_GUI

    %Creation of BASE OUTLINE for Window                                  %[startingX startingY Width Height]
    LS_1 = figure("Name", "LSS Regression", "NumberTitle", "off", "Units", "normalized", "Position", [0.30 0.40 0.35 0.26],'Resize','off','MenuBar', 'none','ToolBar', 'none','color','w', "Tag", "LSS_GUI_B");
    
    % Initializing Elements of the UI
    LS_M = uicontrol(LS_1,'Style','text',"String", "Estimate LSS models using:","Units", "normalized",'fontweight', 'bold', 'fontunits','normalized', 'fontSize', 0.3);
    
    LS_G1_Q = uicontrol(LS_1,'Style','pushbutton',"String", "<html>Residual time-series after FIR task regression <br> &emsp&emsp&emsp&emsp&emsp&emsp (recommended)","Units", "normalized",'fontunits','normalized', 'fontSize', 0.22);%,"BackgroundColor", [0.95 0.95 0.95]);
    LS_G1_A = uicontrol(LS_1,'Style','text',"String", "Not done","ForegroundColor","red","Units", "normalized",'fontunits','normalized', 'fontSize', 0.6);
    
    LS_G2_Q = uicontrol(LS_1,'Style','pushbutton',"String", "Original time-series without FIR task regression","Units", "normalized",'fontunits','normalized', 'fontSize', 0.22);
    LS_G2_A = uicontrol(LS_1,'Style','text',"String", "Not done","ForegroundColor","red","Units", "normalized",'fontunits','normalized', 'fontSize', 0.6);
 
    LS_Help = uicontrol(LS_1,'Style','pushbutton', "String", "Help","Units", "normalized",'fontunits','normalized', 'fontSize', 0.38);

    % Assigning Positions of elements
    % FORMAT OF Position: X, Y, width, height
    
    LS_M.Position = [0.32 0.75 0.350 0.180];
    
    LS_G1_Q.Position = [0.05 0.58 0.660 0.230];
    LS_G1_A.Position = [0.75 0.64 0.200 0.090];
    
    LS_G2_Q.Position = [0.05 0.28 0.660 0.230];
    LS_G2_A.Position = [0.75 0.34 0.200 0.090];
    
    LS_Help.Position = [0.42 0.08 0.180 0.130];
    
    set(LS_M,'backgroundcolor',get(LS_1,'color'));
    set(LS_G1_A,'backgroundcolor',get(LS_1,'color'));
    set(LS_G2_A,'backgroundcolor',get(LS_1,'color'));
    

    % Assigning Functions Callbacks for each Element (button, listbox etc)
    set(LS_G1_Q, "callback", @LSS_B1);  
    set(LS_G2_Q, "callback", @LSS_B2);  
    set(LS_Help, 'callback', @help_details)
    %waitforbuttonpress;
    
    function LSS_B1(~,~)
       
        try
        ALL_LSS_conds = LSS_conditions();
        LSS_GUI_BIG(ALL_LSS_conds);
        %uiwait();
        catch
            warning("Subjects not selected");
        end
        
        
    end
    
    
    
    function help_details(~,~)
        LS_2 = figure("Name", "FIR task regression: Help", "NumberTitle", "off", "Units", "normalized", "Position", [0.65 0.36 0.26 0.37],'Resize','off'); %X Y W H
        set(gcf,'color','w');
        set(LS_2, 'MenuBar', 'none');
        set(LS_2, 'ToolBar', 'none');

        THE_DETAILS = ["Finite impulse response (FIR) task regression are used to", "remove co-activations from BOLD time-series.","",...
            "Co-activations are simultaneous (de)activations", "without communication between brain regions.",...
            "",...
            "Co-activations spuriously inflate task-modulated","functional connectivity (TMFC) estimates.","",...
            "FIR model regress out (1) co-activations with any possible",...
            "shape and (2) cofounds specified in the original",...
            "SPM.mat file (e.g., motion, physiological noise, etc).",...
            "","Functional images for residgual time-series(Res\_*.nii in",...
            "FIR\_GLM folders) can be further used for TMFC analysis."];

        LS2_DTS = uicontrol(LS_2,'Style','text',"String", THE_DETAILS,"Units", "normalized", "HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.054);
        LS2_OK = uicontrol(LS_2,'Style','pushbutton', "String", "OK","Units", "normalized",'fontunits','normalized', 'fontSize', 0.35);

        set(LS2_DTS,'backgroundcolor',get(LS_2,'color'));
        LS2_DTS.Position = [0.06 0.16 0.885 0.800];
        LS2_OK.Position = [0.39 0.04 0.240 0.100];
        
        set(LS2_OK, "callback", @CLOSE_LS2_OK);
        
        function CLOSE_LS2_OK(~,~)
                close(LS_2);
        end
    end
    
    
    
    
end