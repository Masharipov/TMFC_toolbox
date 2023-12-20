function varargout = tmfc_FIR_restart_GUI(~,~)

FIR_RECOMP = figure("Name", "FIR task regression", "NumberTitle", "off", "Units", "normalized", "Position", [0.38 0.44 0.16 0.16],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', "Tag", "Restart_FIR"); %X Y W H

FIR_D1 = uicontrol(FIR_RECOMP,'Style','text',"String", ["Recompute FIR task","regression for all subjects.?"],"Units", "normalized", "HorizontalAlignment", "center",'fontunits','normalized', 'fontSize', 0.38);

FIR_OK = uicontrol(FIR_RECOMP,'Style','pushbutton',"String", "OK","Units", "normalized",'fontunits','normalized', 'fontSize', 0.48);
FIR_CCL = uicontrol(FIR_RECOMP,'Style','pushbutton', "String", "Cancel","Units", "normalized",'fontunits','normalized', 'fontSize', 0.48);

FIR_D1.Position = [0.10 0.55 0.80 0.260];
set(FIR_D1,'backgroundcolor',get(FIR_RECOMP,'color'));

FIR_OK.Position = [0.14 0.25 0.320 0.170];
FIR_CCL.Position = [0.52 0.25 0.320 0.170];

set(FIR_CCL, 'callback', @CANCEL);
set(FIR_OK, 'callback', @ACC);


    function CANCEL(~,~)
        close(FIR_RECOMP);
    end

    function ACC(~,~)
        h3 = findobj("Tag", "MAIN_WINDOWS");
        setappdata(h3, "RESTART_FIR", 1);
        close(FIR_RECOMP);
    end

end