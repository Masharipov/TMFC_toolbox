function tmfc_major_reset()

    DR_RESET = evalin('base', 'tmfc');

    % Project Variables of group 1
    DR_RESET.subjects = struct;
    DR_RESET.subjects(1).paths = "";
    DR_RESET.project_path = "";
    
    % Project Variables of group 2
    DR_RESET.FIR_window = 0; %32
    DR_RESET.FIR_bins = 0;   %16
    DR_RESET.subjects(1).FIR = [];
    
    % Project Variables of group 3
    DR_RESET.LSS_residual_ts.conditions = "";
    DR_RESET.LSS_original_ts.conditions = "";
    DR_RESET.subjects(1).LSS_residual_ts = [];
    DR_RESET.subjects(1).LSS_original_ts = [];
    
    % Project Variables of group 4
    DR_RESET.ROIs(1).paths = "";
    DR_RESET.ROIs_set_name = "";
    
    % Project Variables of group 5
    DR_RESET.subjects(1).BSC = [];
    
    % Project Variables of group 6
    DR_RESET.subjects(1).VOI = [];
    DR_RESET.subjects(1).PPIterm = [];
    DR_RESET.subjects(1).gPPI = [];
    
    assignin('base', 'tmfc', DR_RESET);
    
    try
    h1 = findobj('Tag','MAIN_WINDOWS');              % Find the Main GUI using its handle
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
        warning("TFMC GUI window not found, TMFC variable reset");
    end
    
    
end