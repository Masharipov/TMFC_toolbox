function [TTL,C1,C2,C3,C4] = tmfc_BSC_MINI()

    SC_G2 = figure('Name', 'BSC', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.4 0.45 0.22 0.18],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off', 'CloseRequestFcn', @stable_exit);

    SC_G2_E0  = uicontrol(SC_G2,'Style','text','String', 'Define contrast title and contrast weights','Units', 'normalized', 'Position',[0.115 0.82 0.800 0.12],'fontunits','normalized', 'fontSize', 0.70,'backgroundcolor','w');

    SC_G2_TT  = uicontrol(SC_G2,'Style','text','String', 'Title','Units', 'normalized', 'Position',[0.070 0.62 0.250 0.11],'fontunits','normalized', 'fontSize', 0.74,'backgroundcolor','w','fontweight', 'bold');
    SC_G2_C1  = uicontrol(SC_G2,'Style','text','String', 'C1','Units', 'normalized', 'Position',[0.400 0.62 0.070 0.11],'fontunits','normalized', 'fontSize', 0.74,'backgroundcolor','w','fontweight', 'bold');
    SC_G2_C2  = uicontrol(SC_G2,'Style','text','String', 'C2','Units', 'normalized', 'Position',[0.545 0.62 0.070 0.11],'fontunits','normalized', 'fontSize', 0.74,'backgroundcolor','w','fontweight', 'bold');
    SC_G2_C3  = uicontrol(SC_G2,'Style','text','String', 'C3','Units', 'normalized', 'Position',[0.69 0.62 0.070 0.11],'fontunits','normalized', 'fontSize', 0.80,'backgroundcolor','w','fontweight', 'bold');
    SC_G2_C4  = uicontrol(SC_G2,'Style','text','String', 'C4','Units', 'normalized', 'Position',[0.83 0.62 0.070 0.11],'fontunits','normalized', 'fontSize', 0.80,'backgroundcolor','w','fontweight', 'bold');


    SC_G2_T_A = uicontrol(SC_G2,'Style','edit','String', '','Units', 'normalized','fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'center');
    SC_G2_C1_A = uicontrol(SC_G2,'Style','edit','String', '','Units', 'normalized','fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'center');
    SC_G2_C2_A = uicontrol(SC_G2,'Style','edit','String', '','Units', 'normalized','fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'center');
    SC_G2_C3_A = uicontrol(SC_G2,'Style','edit','String', '','Units', 'normalized','fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'center');
    SC_G2_C4_A = uicontrol(SC_G2,'Style','edit','String', '','Units', 'normalized','fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'center');

    SC_G2_OK = uicontrol(SC_G2,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.40);
    SC_G2_CCL = uicontrol(SC_G2,'Style','pushbutton', 'String', 'Cancel','Units', 'normalized','fontunits','normalized', 'fontSize', 0.40);


    SC_G2_T_A.Position = [0.04 0.42 0.300 0.160];
    SC_G2_C1_A.Position = [0.375 0.42 0.120 0.160];
    SC_G2_C2_A.Position = [0.52 0.42 0.120 0.160];
    SC_G2_C3_A.Position = [0.665 0.42 0.120 0.160];
    SC_G2_C4_A.Position = [0.810 0.42 0.120 0.160];

    SC_G2_OK.Position = [0.20 0.12 0.250 0.180];
    SC_G2_CCL.Position = [0.60 0.12 0.250 0.180];


    set(SC_G2_CCL, 'callback', @stable_exit);
    set(SC_G2_OK, 'callback', @get_contrasts);
    
    function get_contrasts(~,~)
        
        TT_L = get(SC_G2_T_A, 'String');
        C1_L = get(SC_G2_C1_A, 'String');
        C2_L = get(SC_G2_C2_A, 'String');
        C3_L = get(SC_G2_C3_A, 'String');
        C4_L = get(SC_G2_C4_A, 'String');
        
        if strcmp(TT_L,'') || strcmp(TT_L(1),' ') 
            warning('Name not entered or is invalid, please re-enter');            
        elseif ~isempty(str2num(TT_L(1)))
            warning('Name cannot being with a numeric, please re-enter');
            
        elseif strcmp(C1_L, '') || strcmp(C1_L, ' ')
            warning('Contrast C1 not entered or is invalid, please re-enter');
         elseif isempty(str2num(C1_L))
             warning('Contrast C1 is not numeric, please re-enter');
            
        elseif strcmp(C2_L, '') || strcmp(C2_L, ' ')
            warning('Contrast C2 not entered or is invalid, please re-enter');
         elseif isempty(str2num(C2_L))
             warning('Contrast C2 is not numeric, please re-enter');
            
        elseif strcmp(C3_L, '') || strcmp(C3_L, ' ')
            warning('Contrast C3 not entered or is invalid, please re-enter');
         elseif isempty(str2num(C3_L))
             warning('Contrast C3 is not numeric, please re-enter');
            
        elseif strcmp(C4_L, '') || strcmp(C4_L, ' ')
            warning('Contrast C4 not entered or is invalid, please re-enter');
         elseif isempty(str2num(C4_L))
             warning('Contrast C4 is not numeric, please re-enter');
            
        else
            
            fprintf('Name set %s\n', TT_L);
            fprintf('Contrast 1 is %s\n', C1_L);
            fprintf('Contrast 2 is %s\n', C2_L);
            fprintf('Contrast 3 is %s\n', C3_L);
            fprintf('Contrast 4 is %s\n', C4_L);
            delete(SC_G2);       
            TTL = TT_L;
            C1 = C1_L;
            C2 = C2_L;
            C3 = C3_L;
            C4 = C4_L;
            
        end
    end


    function stable_exit(~,~)
        delete(SC_G2);       
        TTL = [];
        C1 = [];
        C2 = [];
        C3 = [];
        C4 = [];
    end

    uiwait();
end
