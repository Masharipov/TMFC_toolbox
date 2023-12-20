function BSC_GUI()

    BSC_G1 = figure("Name", "BSC", "NumberTitle", "off", "Units", "normalized", "Position", [0.40 0.30 0.22 0.46],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off');
    
    % Initializing Elements of the UI
    BSC_E0  = uicontrol(BSC_G1,'Style','text',"String", "Define contrasts","Units", "normalized", "Position",[0.270 0.92 0.450 0.05],'fontunits','normalized', 'fontSize', 0.62,'backgroundcolor','w');
    
    BSC_E1  = uicontrol(BSC_G1,'Style','text',"String", "All conditions:","Units", "normalized", "Position",[0.045 0.85 0.450 0.05],"HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.62,'backgroundcolor','w');
    BSC_E1_lst = uicontrol(BSC_G1 , 'Style', 'listbox', "String", ["C1 - CondA (Sess1)","C2 - CondB (Sess1)","C3 - CondA (Sess2)","C4 - CondB (Sess2)"],'Max', 100,"Units", "normalized", "Position",[0.045 0.65 0.900 0.200],'fontunits','normalized', 'fontSize', 0.15);
    
    
    BSC_E2  = uicontrol(BSC_G1,'Style','text',"String", "Contrasts:","Units", "normalized", "Position",[0.045 0.57 0.450 0.05],"HorizontalAlignment", "left",'fontunits','normalized', 'fontSize', 0.62,'backgroundcolor','w');
    BSC_E2_lst_1 = uicontrol(BSC_G1 , 'Style', 'listbox', "String", "№### :: Title :: Contrast weights",'Max', 100,"Units", "normalized", "Position",[0.045 0.53 0.900 0.045],'fontunits','normalized', 'fontSize', 0.62);
    Contrasts_Data = ["№001 :: CondA (Sess1) :: c = [1 0 0 0]", "№002 :: CondB (Sess1) :: c = [0 1 0 0]", "№003 :: CondA (Sess2) :: c = [0 0 1 0]", "№004 :: CondB (Sess2) :: c = [0 0 0 1]", "№005 :: CondA-CondB :: c = [0.5 -0.5 0.5 -0.5]", "№006 :: Sess1-Sess2 :: c = [0.5 0.5 -0.5 -0.5]"];
    
    BSC_E2_lst_2 = uicontrol(BSC_G1 , 'Style', 'listbox', "String", Contrasts_Data,'Max',100,"Units", "normalized", "Position",[0.045 0.29 0.900 0.230],'fontunits','normalized', 'fontSize', 0.12);
    
    BSC_ADD = uicontrol(BSC_G1,'Style','pushbutton',"String", "Add new","Units", "normalized","Position",[0.045 0.18 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);
    BSC_REM = uicontrol(BSC_G1,'Style','pushbutton',"String", "Remove selected","Units", "normalized","Position",[0.360 0.18 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);
    BSC_REVA = uicontrol(BSC_G1,'Style','pushbutton',"String", "Remove all","Units", "normalized","Position",[0.680 0.18 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);
    BSC_OK = uicontrol(BSC_G1,'Style','pushbutton',"String", "OK","Units", "normalized","Position",[0.045 0.08 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);
    BSC_HELP = uicontrol(BSC_G1,'Style','pushbutton',"String", "Help","Units", "normalized","Position",[0.680 0.08 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);

    set(BSC_E1_lst, 'Value', []);
    set(BSC_E2_lst_1, 'Value', []);
    set(BSC_E2_lst_2, 'Value', []);
    %set(BSC_E2_lst_1, 'Enable', "off");  
    
end