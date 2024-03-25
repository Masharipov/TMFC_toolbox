function tmfc_gPPI_GUI()

                                                                                               
    GPPI_GUI = figure("Name", "gPPI", "NumberTitle", "off", "Units", "normalized", "Position", [0.45 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off');
    
    % Initializing Elements of the UI
    GPPI_E0  = uicontrol(GPPI_GUI,'Style','text',"String", "Select conditions of interest","Units", "normalized", "Position",[0.270 0.93 0.450 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
    
    GPPI_E1  = uicontrol(GPPI_GUI,'Style','text',"String", "All conditions:","Units", "normalized", "Position",[0.045 0.88 0.450 0.05],"HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
    GPPI_E1_lst = uicontrol(GPPI_GUI , 'Style', 'listbox', "String", ["CondA (Sess1)","CondB (Sess1)","Errors (Sess1)","CondA (Sess2)","CondB (Sess2)","Errors (Sess2)"],'Max', 100,"Units", "normalized", "Position",[0.045 0.59 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07);
    
    GPPI_ADD = uicontrol(GPPI_GUI,'Style','pushbutton',"String", "Add selected","Units", "normalized","Position",[0.045 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
    GPPI_ADA = uicontrol(GPPI_GUI,'Style','pushbutton',"String", "Add all","Units", "normalized","Position",[0.360 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
    GPPI_HELP = uicontrol(GPPI_GUI,'Style','pushbutton',"String", "Help","Units", "normalized","Position",[0.680 0.50 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
    
    GPPI_E2  = uicontrol(GPPI_GUI,'Style','text',"String", "Conditions of interest:","Units", "normalized", "Position",[0.045 0.425 0.450 0.05],"HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');
    GPPI_E2_lst = uicontrol(GPPI_GUI , 'Style', 'listbox', "String", ["CondA (Sess1)","CondB (Sess1)","CondA (Sess2)","CondB (Sess2)"],'Max', 100,"Units", "normalized", "Position",[0.045 0.135 0.900 0.300],'fontunits','normalized', 'fontSize', 0.07);
    
    GPPI_OK = uicontrol(GPPI_GUI,'Style','pushbutton',"String", "OK","Units", "normalized","Position",[0.045 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
    GPPI_REV = uicontrol(GPPI_GUI,'Style','pushbutton',"String", "Remove selected","Units", "normalized","Position",[0.360 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
    GPPI_REVA = uicontrol(GPPI_GUI,'Style','pushbutton',"String", "Remove all","Units", "normalized","Position",[0.680 0.05 0.270 0.065],'fontunits','normalized', 'fontSize', 0.32);
    
    
    
    set(GPPI_HELP, 'callback', @GPPI_H);
    
    function GPPI_H(~,~)

        GPPI_H_W = figure("Name", "LSS regression: Help", "NumberTitle", "off", "Units", "normalized", "Position", [0.65 0.15 0.22 0.40],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off');

        Data_1 = ["Suppose you have two separate sessions.","","Both sessions contains task regressors for", "“Cond A”, “Cond B” and “Errors”", "","If you are only interested in “Cond A” and “Cond B” comparison, the following conditions should be selected:",...
            "","1)  Cond A (Sess1)","2)  Cond B (Sess1)","3)  Cond A (Sess2)","4)  Cond B (Sess2)","","For all selected conditions of interest, the TMFC toolbox will create psycho-physiological (PPI) regressors. Thus, for each condition of interest, the generalized PPI (gPPI) model will contain two regressors: (1) psychological regressor and (2) PPI regressor."...
            "","For trials of no interest (here, “Errors”), the gPPI model will contain only the psychological regressor."];

        GPPI_W1 = uicontrol(GPPI_H_W,'Style','text',"String",Data_1 ,"Units", "normalized", "Position", [0.05 0.15 0.89 0.83], "HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.041,'backgroundcolor','w');
        GPPI_H_OK = uicontrol(GPPI_H_W,'Style','pushbutton',"String", "OK","Units", "normalized", "Position", [0.34 0.04 0.30 0.08]);%,'fontunits','normalized', 'fontSize', 0.35

        set(GPPI_H_OK, "callback", @GPPI_H_close);


        function GPPI_H_close(~,~);
            close(GPPI_H_W);
        end
    end

    
    
end