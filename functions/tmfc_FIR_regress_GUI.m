function tmfc_FIR_regress_GUI(~,~)

FIR_1 = figure("Name", "FIR task regression", "NumberTitle", "off", "Units", "normalized", "Position", [0.38 0.44 0.22 0.18],'Resize','off', "Tag", "FIR_REG_NUM", 'WindowStyle','modal'); %X Y W H
set(gcf,'color','w');
set(FIR_1, 'MenuBar', 'none');
set(FIR_1, 'ToolBar', 'none');

FIR_D1 = uicontrol(FIR_1,'Style','text',"String", "Enter FIR window length (in seconds):","Units", "normalized", "HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.40);
FIR_D2 = uicontrol(FIR_1,'Style','text',"String", "Enter the number of FIR time bins:","Units", "normalized", "HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.40);

FIR_E1 = uicontrol(FIR_1,'Style','edit',"Units", "normalized", "HorizontalAlignment", "center");%,"InputType", "digits");%, "HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.054
FIR_E2 = uicontrol(FIR_1,'Style','edit',"Units", "normalized", "HorizontalAlignment", "center");%, "HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.054

FIR_OK = uicontrol(FIR_1,'Style','pushbutton',"String", "OK","Units", "normalized");%,'fontunits','normalized', 'fontSize', 0.35
FIR_HELP = uicontrol(FIR_1,'Style','pushbutton', "String", "Help","Units", "normalized");%,'fontunits','normalized', 'fontSize', 0.35

FIR_D1.Position = [0.08 0.62 0.65 0.200];
FIR_D2.Position = [0.08 0.37 0.65 0.200];
set(FIR_D1,'backgroundcolor',get(FIR_1,'color'));
set(FIR_D2,'backgroundcolor',get(FIR_1,'color'));

FIR_E1.Position = [0.76 0.67 0.185 0.170];
FIR_E2.Position = [0.76 0.42 0.185 0.170];

FIR_OK.Position = [0.21 0.13 0.230 0.170];
FIR_HELP.Position = [0.52 0.13 0.230 0.170];

%set(FIR_E1, 'callback', );
%set(FIR_E2, 'callback', );

set(FIR_OK, 'callback', @EXTRACT);
set(FIR_HELP, 'callback', @FIR_1_HELP_POP);


    function FIR_1_HELP_POP(~,~)
        
            FIR_1_HELP = figure("Name", "FIR task regression: Help", "NumberTitle", "off", "Units", "normalized", "Position", [0.62 0.26 0.22 0.48],'Resize','off'); %X Y W H
            set(gcf,'color','w');
            set(FIR_1_HELP, 'MenuBar', 'none');
            set(FIR_1_HELP, 'ToolBar', 'none');

            THE_DETAILS = ["Finite impulse response (FIR) task regression are used to remove co-activations from BOLD time-series.","",...
                "Co-activations are simultaneous (de)activations", "without communication between brain regions.",...
                "",...
                "Co-activations spuriously inflate task-modulated","functional connectivity (TMFC) estimates.","",...
                "This option regress out (1) co-activations with any","possible shape and (2) confounds specified in the original",...
                "SPM.mat file (e.g., motion, physiological noise, etc).",...
                "","Functional images for residual time-series(Res_*.nii in",...
                "FIR_GLM folders) will be further used for TMFC analysis.","",...
                "Typically, the FIR window length covers the duration of",...
                "the event and an additional 18s to account for the likely",...
                "duration of the hemodynamic response.","",...
                "Typically, the FIR time bin is equal to one repetition time",...
                "(TR). Therefore, the number of FIR time bins is equal to:",""];
                THE_DETAILS_2 = ["Number of FIR bins = FIR window length/TR"];

            LS2_DTS_1 = uicontrol(FIR_1_HELP,'Style','text',"String", THE_DETAILS,"Units", "normalized", "HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.035);
            LS2_DTS_2 = uicontrol(FIR_1_HELP,'Style','text',"String", THE_DETAILS_2,"Units", "normalized", "HorizontalAlignment", "Center",'fontunits','normalized', 'fontSize', 0.30);%,'fontunits','normalized', 'fontSize', 0.054);
            LS2_OK = uicontrol(FIR_1_HELP,'Style','pushbutton', "String", "OK","Units", "normalized",'fontunits','normalized', 'fontSize', 0.35);

            set(LS2_DTS_1,'backgroundcolor',get(FIR_1_HELP,'color'));
            set(LS2_DTS_2,'backgroundcolor',get(FIR_1_HELP,'color'));

            LS2_DTS_1.Position = [0.06 0.16 0.885 0.800];
            LS2_DTS_2.Position = [0.06 0.10 0.885 0.10];
            LS2_OK.Position = [0.39 0.04 0.240 0.070];

            set(LS2_OK, "callback", @CLOSE_LS2_OK);

            function CLOSE_LS2_OK(~,~)
                close(FIR_1_HELP);
            end
    end

    function EXTRACT(~,~)
        
       Window = str2double(get(FIR_E1, 'String'));
       bins = str2double(get(FIR_E2, 'String'));

       if isnan(Window)
           warning("Please enter the number of windows");
       elseif ~isnan(Window) & isnan(bins)
           warning("Please eneter the number of bins");
       else
           DMG = evalin('base', 'tmfc');
           DMG.FIR_window = Window; 
           DMG.FIR_bins = bins;   
           assignin('base', 'tmfc', DMG); 
           close(FIR_1);
       end
       
    end

end