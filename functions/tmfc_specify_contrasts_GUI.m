function tmfc_specify_contrasts_GUI(~,~)

    LST_1 = {};
    LST_2 = {};
    

    SC_G1 = figure('Name', 'Contrast manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.30 0.24 0.46],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off');
    SC_Title  = uicontrol(SC_G1,'Style','text','String', 'Define contrasts','Units', 'normalized', 'Position',[0.270 0.93 0.450 0.05],'fontunits','normalized', 'fontSize', 0.64,'backgroundcolor','w');
    
    SC_B1_T  = uicontrol(SC_G1,'Style','text','String', 'Existing contrasts:','Units', 'normalized', 'Position',[0.045 0.86 0.300 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.62,'backgroundcolor','w');
    SC_B1_FT = uicontrol(SC_G1 , 'Style', 'text', 'String', '№### :: Title :: Contrast weights','Max', 100,'Units', 'normalized', 'Position',[0.045 0.816 0.900 0.045],'fontunits','normalized', 'fontSize', 0.62,'HorizontalAlignment','left','backgroundcolor','w');
    SC_B1_lst = uicontrol(SC_G1 , 'Style', 'listbox', 'String', LST_1,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.62 0.920 0.200],'fontunits','normalized', 'fontSize', 0.15);
        
    SC_B2_T  = uicontrol(SC_G1,'Style','text','String', 'Add new contrasts:','Units', 'normalized', 'Position',[0.045 0.535 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.62,'backgroundcolor','w');
    SC_B2_FT = uicontrol(SC_G1 , 'Style', 'text', 'String', '№### :: Title :: Contrast weights','Max', 100,'Units', 'normalized', 'Position',[0.045 0.492 0.900 0.045],'fontunits','normalized', 'fontSize', 0.62,'HorizontalAlignment','left','backgroundcolor','w');
    SC_B2_lst = uicontrol(SC_G1 , 'Style', 'listbox', 'String', LST_2,'Max',100,'Units', 'normalized', 'Position',[0.045 0.26 0.920 0.230],'fontunits','normalized', 'fontSize', 0.12);
      
    SC_ADD = uicontrol(SC_G1,'Style','pushbutton','String', 'Add new','Units', 'normalized','Position',[0.045 0.15 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);
    SC_REM = uicontrol(SC_G1,'Style','pushbutton','String', 'Remove selected','Units', 'normalized','Position',[0.360 0.15 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);
    SC_REVA = uicontrol(SC_G1,'Style','pushbutton','String', 'Remove all','Units', 'normalized','Position',[0.680 0.15 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);
    SC_OK = uicontrol(SC_G1,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.045 0.05 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);
    SC_HELP = uicontrol(SC_G1,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.680 0.05 0.290 0.075],'fontunits','normalized', 'fontSize', 0.36);

    set(SC_B1_lst, 'Value', []);    
    set(SC_B1_lst, 'callback', @action_select_1)
    set(SC_B2_lst, 'Value', []);
    set(SC_B2_lst, 'callback', @action_select_2)
    
    set(SC_ADD, 'callback', @action3)
    set(SC_REM, 'callback', @action4)
    set(SC_REVA, 'callback', @action5)
    set(SC_OK, 'callback', @action6)
    set(SC_HELP, 'callback', @action7)
    
    selection_1 = {};
    selection_2 = {};
    
    %set(BSC_E2_lst_1,'backgroundcolor',get(BSC_G1,'color'));
    %set(BSC_E2_lst_1, 'Enable', 'off');  

%     function LSS_stable_Exit(~,~)
%         try
%            h88 = findobj('Tag', 'MAIN_WINDOW');
%            setappdata(h88, 'LSS_NO_COND', 1); 
%         end
%         delete(LSS_GUI);
%     end

%% Selection from list box
    function action_select_1(~,~)
        index = get(SC_B1_lst, 'Value');  % Retrieves the users selection LIVE
        selection_1 = index;      
    end

    function action_select_2(~,~)
        index = get(SC_B2_lst, 'Value');  % Retrieves the users selection LIVE
        selection_2 = index;             
    end
    


%%  Add new contrast
    function action3
        disp('Add new stuff');
    end
%% Remove a Contrast
    function action4
        disp('Remove Contrasts');
    end
%% Remova all Contrasts
    function action5
        disp('Remove all contrasts');
    end
%%  OKAY Confirm
    function action6
        disp('Okay Confimr existing list of contrast');
    end
%% Help Window
    function action7
        disp('Help window');
    end
end



