function tmfc_FIR_continue_GUI(INDEX)

FIR_MIDCOMP = figure("Name", "FIR task regression", "NumberTitle", "off", "Units", "normalized", "Position", [0.38 0.44 0.20 0.20],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', "Tag", "Contd_FIR"); %X Y W H

FIR_Q1 = uicontrol(FIR_MIDCOMP,'Style','text',"String", "Start FIR task regression from","Units", "normalized", "HorizontalAlignment", "center",'fontunits','normalized', 'fontSize', 0.38);
FIR_Q2 = uicontrol(FIR_MIDCOMP,'Style','text',"String", "subject №"+INDEX+"?", "Units","normalized", "HorizontalAlignment", "center",'fontunits','normalized', 'fontSize', 0.38);

FIR_YES = uicontrol(FIR_MIDCOMP,'Style','pushbutton',"String", "Yes","Units", "normalized",'fontunits','normalized', 'fontSize', 0.28);
FIR_RESTART = uicontrol(FIR_MIDCOMP,'Style','pushbutton', "String", "<html>&#160 No, start from <br>the first subject","Units", "normalized",'fontunits','normalized', 'fontSize', 0.28);

FIR_Q1.Position = [0.10 0.55 0.80 0.260];
FIR_Q2.Position = [0.10 0.40 0.80 0.260];

set([FIR_Q1,FIR_Q2],'backgroundcolor',get(FIR_MIDCOMP,'color'));

FIR_YES.Position = [0.12 0.15 0.320 0.270];
FIR_RESTART.Position = [0.56 0.15 0.320 0.270];

set(FIR_YES, 'callback', @contd);
set(FIR_RESTART, 'callback', @RESTART);

    function contd(~,~)
        h6 = findobj("Tag", "MAIN_WINDOWS");
        setappdata(h6, "CONTD_FIR", 1);
        close(FIR_MIDCOMP);
    end


    function RESTART(~,~)
        h6 = findobj("Tag", "MAIN_WINDOWS");
        setappdata(h6, "CONTD_FIR", 2);
        close(FIR_MIDCOMP);
    end






end