function tmfc_select_ROIs_GUI(~,~)

ROI_ADRS = string(spm_select(inf,'any','Select ROI masks',{},pwd));
LOR = length(ROI_ADRS);

if ROI_ADRS(1) ~= ""
    
    disp(LOR+" ROIs selected");

    try
    R_H = findobj('Tag','MAIN_WINDOWS');              % Find the Main GUI using its handle
    R1data = guidata(R_H);                        % Get Handles and Data associated to Main GUI
    set(R1data.ROI_stat,"ForegroundColor","#385723");
    set(R1data.ROI_stat,'String',LOR+" selected");      % Assigning the variable to the Main GUI static text
    catch
        warning("Please close older instances of TMFC Toolbox");
    end
    
    RBC = evalin("base", 'tmfc');

    for i = 1:LOR
        RBC.ROIs(i).paths = ROI_ADRS(i);
    end
    assignin('base', 'tmfc', RBC);    
    
end

end