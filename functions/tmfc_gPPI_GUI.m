function gPPI_GUI

    %Creation of BASE OUTLINE for Window                                  %[startingX startingY Width Height]
    GPPI_1 = figure("Name", "gPPI", "NumberTitle", "off", "Units", "normalized", "Position", [0.30 0.40 0.35 0.26],'Resize','off','MenuBar', 'none','ToolBar', 'none','color','w');
    
    % Initializing Elements of the UI
    GPPI_M = uicontrol(GPPI_1,'Style','text',"String", "Estimate gPPI models using:","Units", "normalized",'fontweight', 'bold', 'fontunits','normalized', 'fontSize', 0.3);
    
    GP_G1_Q = uicontrol(GPPI_1,'Style','pushbutton',"String", "<html>Residual time-series after FIR task regression <br> &emsp&emsp&emsp&emsp&emsp&emsp (recommended)","Units", "normalized",'fontunits','normalized', 'fontSize', 0.22,"HorizontalAlignment", "center");%,"BackgroundColor", [0.95 0.95 0.95]);
    GP_G1_A = uicontrol(GPPI_1,'Style','text',"String", "Not done","ForegroundColor","red","Units", "normalized",'fontunits','normalized', 'fontSize', 0.6);
    
    GP_G2_Q = uicontrol(GPPI_1,'Style','pushbutton',"String", ["Original time-series without FIR task regression"],"Units", "normalized",'fontunits','normalized', 'fontSize', 0.22);
    GP_G2_A = uicontrol(GPPI_1,'Style','text',"String", "Not done","ForegroundColor","red","Units", "normalized",'fontunits','normalized', 'fontSize', 0.6);
 
    GP_Help = uicontrol(GPPI_1,'Style','pushbutton', "String", "Help","Units", "normalized",'fontunits','normalized', 'fontSize', 0.35);

    % Assigning Positions of elements
    % FORMAT OF Position: X, Y, width, height
    
    GPPI_M.Position = [0.32 0.75 0.350 0.180];
    
    GP_G1_Q.Position = [0.05 0.58 0.660 0.230];
    GP_G1_A.Position = [0.75 0.64 0.200 0.090];
    
    GP_G2_Q.Position = [0.05 0.28 0.660 0.230];
    GP_G2_A.Position = [0.75 0.34 0.200 0.090];
    
    GP_Help.Position = [0.42 0.08 0.180 0.130];
    
    set(GPPI_M,'backgroundcolor',get(GPPI_1,'color'));
    set(GP_G1_A,'backgroundcolor',get(GPPI_1,'color'));
    set(GP_G2_A,'backgroundcolor',get(GPPI_1,'color'));
    
    set(GP_Help, 'callback', @GP_help_details)
  
    
    function GP_help_details(~,~)
        GP_2 = figure("Name", "FIR task regression: Help", "NumberTitle", "off", "Units", "normalized", "Position", [0.65 0.36 0.26 0.37],'Resize','off'); %X Y W H
        set(gcf,'color','w');
        set(GP_2, 'MenuBar', 'none');
        set(GP_2, 'ToolBar', 'none');

        THE_DETAILS = ["Finite impulse response (FIR) task regression are used to remove co-activations from BOLD time-series.","",...
            "Co-activations are simultaneous (de)activations without communication between brain regions. ",...
            "",...
            "Co-activations spuriously inflate task-modulated functional connectivity (TMFC) estimates.","",...
            "FIR model regress out (1) co-activations with any possible shape and (2) confounds specified in the original SPM.mat file (e.g., motion, physiological noise, etc).",...
            "","Functional images for residual time-series (Res_*.nii in FIR_GLM folders) can be further used for TMFC analysis."];

        GP2_DTS = uicontrol(GP_2,'Style','text',"String", THE_DETAILS,"Units", "normalized", "HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.054);
        GP2_OK = uicontrol(GP_2,'Style','pushbutton', "String", "OK","Units", "normalized",'fontunits','normalized', 'fontSize', 0.35);

        set(GP2_DTS,'backgroundcolor',get(GP_2,'color'));
        GP2_DTS.Position = [0.06 0.16 0.885 0.800];
        GP2_OK.Position = [0.39 0.04 0.240 0.100];
        
        set(GP2_OK, "callback", @CLOSE_GP2_OK);
        
        function CLOSE_GP2_OK(~,~)
            close(GP_2);
        end
    end
    
    
    
    
end