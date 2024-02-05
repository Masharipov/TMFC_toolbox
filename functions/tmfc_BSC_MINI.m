function tmfc_BSC_MINI()

BSC_G2 = figure("Name", "BSC", "NumberTitle", "off", "Units", "normalized", "Position", [0.4 0.45 0.22 0.18],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off');

BSC_G2_E0  = uicontrol(BSC_G2,'Style','text',"String", "Define contrast title and contrast weights","Units", "normalized", "Position",[0.115 0.82 0.800 0.12],'fontunits','normalized', 'fontSize', 0.70,'backgroundcolor','w');

BSC_G2_T  = uicontrol(BSC_G2,'Style','text',"String", "Title","Units", "normalized", "Position",[0.070 0.62 0.250 0.11],'fontunits','normalized', 'fontSize', 0.74,'backgroundcolor','w','fontweight', 'bold');
BSC_G2_C1  = uicontrol(BSC_G2,'Style','text',"String", "C1","Units", "normalized", "Position",[0.400 0.62 0.070 0.11],'fontunits','normalized', 'fontSize', 0.74,'backgroundcolor','w','fontweight', 'bold');
BSC_G2_C2  = uicontrol(BSC_G2,'Style','text',"String", "C2","Units", "normalized", "Position",[0.545 0.62 0.070 0.11],'fontunits','normalized', 'fontSize', 0.74,'backgroundcolor','w','fontweight', 'bold');
BSC_G2_C3  = uicontrol(BSC_G2,'Style','text',"String", "C3","Units", "normalized", "Position",[0.69 0.62 0.070 0.11],'fontunits','normalized', 'fontSize', 0.80,'backgroundcolor','w','fontweight', 'bold');
BSC_G2_C4  = uicontrol(BSC_G2,'Style','text',"String", "C4","Units", "normalized", "Position",[0.83 0.62 0.070 0.11],'fontunits','normalized', 'fontSize', 0.80,'backgroundcolor','w','fontweight', 'bold');


BSC_G2_T_A = uicontrol(BSC_G2,'Style','edit',"String", "CondA-CondB","Units", "normalized",'fontunits','normalized', 'fontSize', 0.50,"HorizontalAlignment", "center");
BSC_G2_C1_A = uicontrol(BSC_G2,'Style','edit',"String", "0.5","Units", "normalized",'fontunits','normalized', 'fontSize', 0.50,"HorizontalAlignment", "center");
BSC_G2_C2_A = uicontrol(BSC_G2,'Style','edit',"String", "-0.5","Units", "normalized",'fontunits','normalized', 'fontSize', 0.50,"HorizontalAlignment", "center");
BSC_G2_C3_A = uicontrol(BSC_G2,'Style','edit',"String", "0.5","Units", "normalized",'fontunits','normalized', 'fontSize', 0.50,"HorizontalAlignment", "center");
BSC_G2_C4_A = uicontrol(BSC_G2,'Style','edit',"String", "-0.5","Units", "normalized",'fontunits','normalized', 'fontSize', 0.50,"HorizontalAlignment", "center");

BSC_OK = uicontrol(BSC_G2,'Style','pushbutton', "String", "OK","Units", "normalized",'fontunits','normalized', 'fontSize', 0.40);
BSC_CCL = uicontrol(BSC_G2,'Style','pushbutton', "String", "Cancel","Units", "normalized",'fontunits','normalized', 'fontSize', 0.40);


BSC_G2_T_A.Position = [0.04 0.42 0.300 0.160];
BSC_G2_C1_A.Position = [0.375 0.42 0.120 0.160];
BSC_G2_C2_A.Position = [0.52 0.42 0.120 0.160];
BSC_G2_C3_A.Position = [0.665 0.42 0.120 0.160];
BSC_G2_C4_A.Position = [0.810 0.42 0.120 0.160];

BSC_OK.Position = [0.20 0.12 0.250 0.180];
BSC_CCL.Position = [0.60 0.12 0.250 0.180];


set(BSC_CCL, "callback", @CANCEL_BSC);


    function CANCEL_BSC(~,~)
        close(BSC_G2);        
    end

end