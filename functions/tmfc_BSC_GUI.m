function tmfc_BSC_GUI(tmfc, ROI_set_number)

ROI_set_num = ROI_set_number;

D = bsc_type();




if D == 20
    R = evalin('base', 'tmfc');
    valuator = R;
    L = tmfc_BSC_after_FIR(R,ROI_set_num );
    sub_size = size(R.subjects);
    
    for i = 1:sub_size(2)
        valuator.ROI_set(ROI_set_num).subjects(i).BSC_after_FIR = L(i);
    end
    
    assignin('base', 'tmfc', valuator);
    
elseif D == 21
    
    disp('under progress');
    %tmfc_BSC_without_FIR(tmfc,ROI_set_number);
    
    
else
    disp('incorrect entry');
    
    
end







end


function [action_BSC] = bsc_type(~,~)


    %Creation of BASE OUTLINE for Window                                  %[startingX startingY Width Height]
    BSC_LSS_SEL = figure("Name", "BSC LSS", "NumberTitle", "off", "Units", "normalized", "Position", [0.40 0.45 0.28 0.20],'Resize','off','MenuBar', 'none','ToolBar', 'none','color','w','CloseRequestFcn', @BSC_Sel_stable_Exit);
    
    % Initializing Elements of the UI
    BSC_LSS_F1 = uicontrol(BSC_LSS_SEL,'Style','pushbutton',"String", 'BSC-LSS after FIR task regression (recommended)',"Units", "normalized",'fontunits','normalized', 'fontSize', 0.22,"HorizontalAlignment", "center");%,"BackgroundColor", [0.95 0.95 0.95]);
    BSC_LSS_F2 = uicontrol(BSC_LSS_SEL,'Style','pushbutton',"String", 'BSC-LSS without FIR task regression ',"Units", "normalized",'fontunits','normalized', 'fontSize', 0.22);
    
    BSC_LSS_F1.Position = [0.05 0.58 0.90 0.30];
    BSC_LSS_F2.Position = [0.05 0.18 0.90 0.30];
    
    set(BSC_LSS_F1, "callback", @function1);
    set(BSC_LSS_F2, "callback", @function2);
    
    function BSC_Sel_stable_Exit(~,~)
        delete(BSC_LSS_SEL); 
        action_BSC = -1;
    end
    
    function function1(~,~)
        disp('peforming BSC LSS after FIR task regression');
        delete(BSC_LSS_SEL); 
        action_BSC = 20;
    end
    
    function function2(~,~)
        disp('peforming BSC LSS without FIR task regression');
        delete(BSC_LSS_SEL); 
        action_BSC = 21;
    end

    uiwait();
end

