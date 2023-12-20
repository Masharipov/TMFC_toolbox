function GPPI_GUI_2_WITHOUT()  

    GPPI_G2_WH = figure("Name", "gPPI", "NumberTitle", "off", "Units", "normalized", "Position", [0.40 0.26 0.205 0.400],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off',"Tag", "MAIN_WINDOWS");
    
    GPPI_WH_TXT = uicontrol(GPPI_G2_WH,'Style','text',"String", ["gPPI based on original time-series","(without FIR task regression)"],"Units", "normalized", "Position",[0.200 0.865 0.600 0.09],'fontunits','normalized', 'fontSize', 0.35,'backgroundcolor','w');

    VOIs_2 = uicontrol(GPPI_G2_WH,'Style','pushbutton', "String", "VOIs","Units", "normalized", "Position",[0.06 0.71 0.40 0.11],'fontunits','normalized', 'fontSize', 0.32);
    VOIs_2_stat = uicontrol(GPPI_G2_WH,'Style','text',"String", "Not done","ForegroundColor","#C55A11","Units", "normalized", "Position",[0.55 0.74 0.40 0.0515],'backgroundcolor','w','fontunits','normalized', 'fontSize', 0.68, "Tag","GPPI_2_WH_1");
    
    PPIs_2 = uicontrol(GPPI_G2_WH,'Style','pushbutton', "String", "PPIs","Units", "normalized", "Position",[0.06 0.55 0.40 0.11],'fontunits','normalized', 'fontSize', 0.32);
    PPIs_2_stat = uicontrol(GPPI_G2_WH,'Style','text',"String", "Not done","ForegroundColor","#C55A11","Units", "normalized", "Position",[0.55 0.58 0.40 0.0515],'backgroundcolor','w','fontunits','normalized', 'fontSize', 0.68, "Tag","GPPI_2_WH_2");
    
    PPIs_GL_2 = uicontrol(GPPI_G2_WH,'Style','pushbutton', "String", "PPI GLMs","Units", "normalized", "Position",[0.06 0.39 0.40 0.11],'fontunits','normalized', 'fontSize', 0.32);
    PPIs_GL_2_stat = uicontrol(GPPI_G2_WH,'Style','text',"String", "Not done","ForegroundColor","#C55A11","Units", "normalized", "Position",[0.55 0.42 0.40 0.0515],'backgroundcolor','w','fontunits','normalized', 'fontSize', 0.68, "Tag","GPPI_2_WH_3");
    
    GPPI_MTX_2 = uicontrol(GPPI_G2_WH,'Style','pushbutton', "String", "gPPI matrix","Units", "normalized", "Position",[0.06 0.23 0.40 0.11],'fontunits','normalized', 'fontSize', 0.32);
    GPPI_MTX_2_stat = uicontrol(GPPI_G2_WH,'Style','text',"String", "Not done","ForegroundColor","#C55A11","Units", "normalized", "Position",[0.55 0.26 0.40 0.0515],'backgroundcolor','w','fontunits','normalized', 'fontSize', 0.68, "Tag","GPPI_2_WH_4");
    
    SYM_2 = uicontrol(GPPI_G2_WH,'Style','pushbutton', "String", "Symmetry","Units", "normalized", "Position",[0.06 0.07 0.40 0.11],'fontunits','normalized', 'fontSize', 0.32);
    SYM_2_stat = uicontrol(GPPI_G2_WH,'Style','text',"String", "Unknown","ForegroundColor","#C55A11","Units", "normalized", "Position",[0.55 0.10 0.40 0.0515],'backgroundcolor','w','fontunits','normalized', 'fontSize', 0.68, "Tag","GPPI_2_WH_5");
    
end