function tmfc_major_reset()

    DR_RESET = evalin('base', 'tmfc');

    % Project Variables of group 1
    DR_RESET.subjects = struct;
    DR_RESET.project_path = '';
    DR_RESET.subjects(1).paths = '';
    
    % Project Variables of group 2
    DR_RESET.FIR_window = NaN; 
    DR_RESET.FIR_bins = NaN;   
    
    DR_RESET.subjects(1).FIR = [];
    DR_RESET.subjects(1).LSS_after_FIR = [];
    DR_RESET.subjects(1).LSS_without_FIR = [];
    
    DR_RESET.LSS_after_FIR.conditions = [];
    DR_RESET.LSS_without_FIR.conditions = [];

    DR_RESET.ROIs_set = [];
    
    assignin('base', 'tmfc', DR_RESET);
    
    try
    h1 = findobj('Tag','MAIN_WINDOW');              % Find the Main GUI using its handle
    g1data = guidata(h1);                        % Get Handles and Data associated to Main GUI

    set(g1data.SUB_stat,"ForegroundColor","red");
    set(g1data.SUB_stat,'String',"Not selected");      % Assigning the variable to the Main GUI static text
    
    set(g1data.FIR_TR_stat,"ForegroundColor","#C55A11");
    set(g1data.FIR_TR_stat,'String',"Not done");      % Assigning the variable to the Main GUI static text
    
    set(g1data.LSS_R_stat,"ForegroundColor","#C55A11");
    set(g1data.LSS_R_stat,'String',"Not done");      % Assigning the variable to the Main GUI static text
    
    set(g1data.LSS_RW_stat,"ForegroundColor","red");
    set(g1data.LSS_RW_stat,'String',"Not selected");      % Assigning the variable to the Main GUI static text
    catch
        
        warning("TMFC GUI window not found, TMFC variable reset");
        
    end
    
    
end