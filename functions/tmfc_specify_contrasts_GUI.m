function [tmfc] = tmfc_specify_contrasts_GUI(tmfc,ROI_set_number,TMFC_analysis)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for LSS regression. Allows to choose conditions of
% interest for LSS regression.
% 
% FORMAT [tmfc] = tmfc_specify_contrasts_GUI(tmfc,ROI_set_number,TMFC_analysis)
%   tmfc           - The tmfc structure (see TMFC.m)
%   ROI_set_number - Number of the ROI set in the tmfc structure
%   TMFC_type      - TMFC analysis type
%                    1: gPPI
%                    2: gPPI-FIR
%                    3: BSC-LSS
%                    4: BSC-LSS after FIR
%
% =========================================================================
%
% Copyright (C) 2024 Ruslan Masharipov
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.
%
% Contact email: masharipov@ihb.spb.ru

LST_1 = {};
LST_2 = {};
carbs = struct;
ctr = 1;

LST_1 = genset_1(tmfc,TMFC_analysis,ROI_set_number);
ctr_L1 = size(LST_1);
if ctr_L1(1) == 0 
    switch(TMFC_analysis)
        case 1
            warning('gPPI: Default contrasts have not calculated.');
        case 2 
            warning('gPPI FIR: Default contrasts have not calculated.');
        case 3
            warning('BSC: Default contrasts have not calculated.');
        case 4
            warning('BSC FIR: Default contrasts have not calculated.');
	end
else
    worker();
end
function worker()
    SC_G1 = figure('Name', 'Contrast manager', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.40 0.30 0.24 0.46],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','CloseRequestFcn', @stable_Exit);%'WindowStyle','modal',
    SC_Title  = uicontrol(SC_G1,'Style','text','String', 'Define contrasts','Units', 'normalized', 'Position',[0.270 0.93 0.450 0.05],'fontunits','normalized', 'fontSize', 0.64,'backgroundcolor','w');

    SC_B1_T  = uicontrol(SC_G1,'Style','text','String', 'Existing contrasts:','Units', 'normalized', 'Position',[0.045 0.86 0.300 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.62,'backgroundcolor','w');
    SC_B1_FT = uicontrol(SC_G1 , 'Style', 'text', 'String', 'No## :: Title :: Contrast weights','Max', 100,'Units', 'normalized', 'Position',[0.045 0.816 0.900 0.045],'fontunits','normalized', 'fontSize', 0.62,'HorizontalAlignment','left','backgroundcolor','w');
    SC_B1_lst = uicontrol(SC_G1 , 'Style', 'listbox', 'String', LST_1,'Max', 100,'Units', 'normalized', 'Position',[0.045 0.62 0.920 0.200],'fontunits','normalized', 'fontSize', 0.15,'Enable','inactive');

    SC_B2_T  = uicontrol(SC_G1,'Style','text','String', 'Add new contrasts:','Units', 'normalized', 'Position',[0.045 0.535 0.450 0.05],'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.62,'backgroundcolor','w');
    SC_B2_FT = uicontrol(SC_G1 , 'Style', 'text', 'String', 'No## :: Title :: Contrast weights','Max', 100,'Units', 'normalized', 'Position',[0.045 0.492 0.900 0.045],'fontunits','normalized', 'fontSize', 0.62,'HorizontalAlignment','left','backgroundcolor','w');
    SC_B2_lst = uicontrol(SC_G1 , 'Style', 'listbox', 'String', LST_2,'Max',100,'Units', 'normalized', 'Position',[0.045 0.26 0.920 0.230],'fontunits','normalized', 'fontSize', 0.14);

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

    movegui(SC_G1,'center');

    selection_2 = {};
%% Exit
    function stable_Exit (~,~)
        delete(SC_G1);
        disp('Contrasts not confirmed.');
    end

%% Selection from list box
    function action_select_2(~,~)
        index = get(SC_B2_lst, 'Value');  % Retrieves the users selection LIVE
        selection_2 = index;             
    end

%%  Add new contrast
    function action3(~,~)
        [D, c] = tmfc_BSC_MINI(tmfc,TMFC_analysis,ROI_set_number);
        if ~isempty(D)
            if ~isfield(carbs, 'no')
                % first addition
                carbs(ctr).no = ctr_L1(1)+1;
                carbs(ctr).title = D;
                carbs(ctr).weights = str2num(c);


                biege = horzcat('No ',num2str(carbs(ctr).no),' :: ',carbs(ctr).title,' :: ', 'c = [',num2str(carbs(ctr).weights),']');
                LST_2 = vertcat(LST_2, biege);
                set(SC_B2_lst, 'string', LST_2);
                ctr = ctr + 1;

            else
                % future additions
                carbs(ctr).no = ctr_L1(1)+ctr;
                carbs(ctr).title = D;
                carbs(ctr).weights = str2num(c);

                biege = horzcat('No ',num2str(carbs(ctr).no),' :: ',carbs(ctr).title,' :: ', 'c = [',num2str(carbs(ctr).weights),']');
                LST_2 = vertcat(LST_2, biege);
                set(SC_B2_lst, 'string', LST_2);
                ctr = ctr + 1;

            end

            fprintf('Contrast added: %s.\n',D);
        else
            disp('No contrasts added.');
        end
    end

%% Remove a Contrast
    function action4(~,~)
        if isfield(carbs, 'no')
            if isempty(selection_2)
                warning('No contrasts selected to remove.');
            else
                hold = length(selection_2);
                if hold>1
                    disp('Selected contrasts have been removed.');
                else
                    disp('Selected contrast has been removed.');
                end

                carbs(selection_2) = [];
                ctr = ctr - length(selection_2);

                LST_2 = {};
                selection_2 = {};
                for i = 1:length(carbs)
                   carbs(i).no = ctr_L1(1)+i;
                   biege = horzcat('No ',num2str(carbs(i).no),' :: ',carbs(i).title,' :: ', 'c = [',carbs(i).weights,']');
                   LST_2 = vertcat(LST_2, biege);
                end

                set(SC_B2_lst,'Value',[]);               
                set(SC_B2_lst, 'string', LST_2);
            end
        else
            warning('No contrasts present to remove.');
        end

    end

%% Remove all Contrasts
    function action5(~,~)
        if isfield(carbs, 'no')
            carbs = struct;
            LST_2 = {};
            selection_2 = {};
            ctr = 1;
            set(SC_B2_lst,'Value',[]);
            set(SC_B2_lst, 'string', LST_2);
            disp('All Contrasts have been removed.');
        else
            warning('No contrasts present to remove.');
        end
    end

%%  OKAY Confirm
    function action6(~,~)

        if isempty(LST_2)
            warning('Please specify new contrast(s)');
        else
            tmfc = Finisher(tmfc,carbs,TMFC_analysis,ROI_set_number);
            fprintf('Number of newly added contrast for processing: %d\n',length(LST_2));
            delete(SC_G1);
        end


    end

%% Help Window
    function action7(~,~)   
        disp('Help window');
    end
uiwait();
end


end
%%
function [constructor_2] = genset_1(tmfc,A_case,ROI_set_number)

switch (A_case)

% gPPI
case 1        
    constructor = {};
    for i=1:length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI)
        constructor = vertcat(constructor, tmfc.ROI_set(ROI_set_number).contrasts.gPPI(i).title);
    end

    eject = size(constructor);
    constructor_2 = {};
    for i = 1:eject(1)
        biege = horzcat('No ',num2str(i),' :: ',constructor{i},' :: ', 'c = [',num2str(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(i).weights),']');
        constructor_2 = vertcat(constructor_2, biege);
    end


    % gPPI FIR
case 2        
    constructor = {};
    for i=1:length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR)
        constructor = vertcat(constructor, tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(i).title);
    end

    eject = size(constructor);
    constructor_2 = {};
    for i = 1:eject(1)
        biege = horzcat('No ',num2str(i),' :: ',constructor{i},' :: ', 'c = [',num2str(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(i).weights),']');
        constructor_2 = vertcat(constructor_2, biege);
    end


    % BSC
case 3        
    constructor = {};
    for i=1:length(tmfc.ROI_set(ROI_set_number).contrasts.BSC)
        constructor = vertcat(constructor, tmfc.ROI_set(ROI_set_number).contrasts.BSC(i).title);
    end

    eject = size(constructor);
    constructor_2 = {};
    for i = 1:eject(1)
        biege = horzcat('No ',num2str(i),' :: ',constructor{i},' :: ', 'c = [',num2str(tmfc.ROI_set(ROI_set_number).contrasts.BSC(i).weights),']');
        constructor_2 = vertcat(constructor_2, biege);
    end



% BSC_after_FIR
case 4        
    constructor = {};
    for i=1:length(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR)
        constructor = vertcat(constructor, tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(i).title);
    end

    eject = size(constructor);
    constructor_2 = {};
    for i = 1:eject(1)
        biege = horzcat('No ',num2str(i),' :: ',constructor{i},' :: ', 'c = [',num2str(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(i).weights),']');
        constructor_2 = vertcat(constructor_2, biege);
    end
end

end

%%

function [TTL,C1] = tmfc_BSC_MINI(tmfc,TMFC_analysis,ROI_set_number)

switch(TMFC_analysis)

    case 1
        Czs = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI(1).weights);
        constructor = {};
        for i=1:Czs
            constructor = vertcat(constructor, strcat('C',num2str(i),' : ', 32,tmfc.ROI_set(ROI_set_number).contrasts.gPPI(i).title));   
        end

    case 2 
        Czs = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(1).weights);
        constructor = {};
        for i=1:Czs
            constructor = vertcat(constructor, strcat('C',num2str(i),' : ', 32,tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(i).title));   
        end

    case 3 
        Czs = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC(1).weights);
        constructor = {};
        for i=1:Czs
            constructor = vertcat(constructor, strcat('C',num2str(i),' : ', 32,tmfc.ROI_set(ROI_set_number).contrasts.BSC(i).title));   
        end

    case 4 
        Czs = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(1).weights);
        constructor = {};
        for i=1:Czs
            constructor = vertcat(constructor, strcat('C',num2str(i),' : ', 32,tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(i).title));   
        end

end


ddr = {};
if Czs >1
    if length(constructor) == 1
        ddr = strcat('Weights: [C1]');
    elseif length(constructor) == 2
        ddr = strcat('Weights: [C1 C2]');
    elseif length(constructor) == 3
        ddr = strcat('Weights: [C1 C2 C3]');
    elseif length(constructor) == 4
        ddr = strcat('Weights: [C1 C2 C3 C4]');
    else
        ddr = strcat('Weights: [C1 C2 ...', 32, 'C', num2str(Czs),']');
    end
end

SC_G2 = figure('Name', 'BSC', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.64 0.46 0.25 0.22],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off', 'CloseRequestFcn', @stable_exit, 'WindowStyle','modal');

SC_G2_E0  = uicontrol(SC_G2,'Style','text','String', 'Define contrast title and contrast weights','Units', 'normalized', 'Position',[0.2 0.875 0.600 0.08],'fontunits','normalized', 'fontSize', 0.74,'backgroundcolor','w');

SC_G2_COI = uicontrol(SC_G2,'Style','text','String', 'Conditions of interest:','Units', 'normalized', 'Position',[0.04 0.75 0.28 0.07],'fontunits','normalized', 'fontSize', 0.79,'HorizontalAlignment', 'left','backgroundcolor','w');
SC_G2_LST = uicontrol(SC_G2, 'Style','listbox', 'String', constructor,'Max',100,'Units', 'normalized', 'Position',[0.04 0.45 0.920 0.280],'fontunits','normalized', 'fontSize', 0.18);

SC_G2_TT  = uicontrol(SC_G2,'Style','text','String', 'Title','Units', 'normalized', 'Position',[0.2105 0.34 0.10 0.07],'fontunits','normalized', 'fontSize', 0.80,'backgroundcolor','w');
SC_G2_C1  = uicontrol(SC_G2,'Style','text','String', ddr,'Units', 'normalized', 'Position',[0.54 0.34 0.40 0.07],'fontunits','normalized', 'fontSize', 0.80,'backgroundcolor','w');

SC_G2_T_A = uicontrol(SC_G2,'Style','edit','String', '','Units', 'normalized','Position',[0.04 0.23 0.440 0.10],'fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'center');
SC_G2_C1_A = uicontrol(SC_G2,'Style','edit','String', '','Units', 'normalized','Position',[0.52 0.23 0.440 0.10],'fontunits','normalized', 'fontSize', 0.50,'HorizontalAlignment', 'center');

SC_G2_OK = uicontrol(SC_G2,'Style','pushbutton', 'String', 'OK','Units', 'normalized','Position',[0.20 0.06 0.24 0.11],'fontunits','normalized', 'fontSize', 0.42);
SC_G2_CCL = uicontrol(SC_G2,'Style','pushbutton', 'String', 'Cancel','Units', 'normalized','Position',[0.56 0.06 0.24 0.11],'fontunits','normalized', 'fontSize', 0.42);

movegui(SC_G2,'center');

set(SC_G2_CCL, 'callback', @stable_exit);
set(SC_G2_OK, 'callback', @get_contrasts);

function get_contrasts(~,~)

    TT_L = get(SC_G2_T_A, 'String');
    C1_L = get(SC_G2_C1_A, 'String');

    if strcmp(TT_L,'') || strcmp(TT_L(1),' ') 
        warning('Name not entered or is invalid, please re-enter.');            
    elseif ~isempty(str2num(TT_L(1)))
        warning('Name cannot being with a numeric, please re-enter.');

    elseif strcmp(C1_L, '') || strcmp(C1_L, ' ')
        warning('Contrast C1 not entered or is invalid, please re-enter.');
    elseif isempty(str2num(C1_L))
         warning('Contrast C1 is not numeric, please re-enter.');

    elseif length(str2num(C1_L)) > Czs
        warning('Entered contrast length is greater than the number of conditions of interest", please re-enter.');
    elseif length(str2num(C1_L)) < Czs
        warning('Entered contrast length is greater than the number of conditions of interest", please re-enter.');


    else
        delete(SC_G2);       
        TTL = TT_L;
        C1 = C1_L;

    end
end


function stable_exit(~,~)
    delete(SC_G2);       
    TTL = [];
    C1 = [];
end

uiwait();
end


function [TTL,C1,C2,C3,C4] = tmfc_BSC_MINI_old()

SC_G2 = figure('Name', 'BSC', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.64 0.46 0.22 0.18],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off', 'CloseRequestFcn', @stable_exit, 'WindowStyle','modal');

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

movegui(SC_G2,'center');

set(SC_G2_CCL, 'callback', @stable_exit);
set(SC_G2_OK, 'callback', @get_contrasts);

function get_contrasts(~,~)

    TT_L = get(SC_G2_T_A, 'String');
    C1_L = get(SC_G2_C1_A, 'String');
    C2_L = get(SC_G2_C2_A, 'String');
    C3_L = get(SC_G2_C3_A, 'String');
    C4_L = get(SC_G2_C4_A, 'String');

    if strcmp(TT_L,'') || strcmp(TT_L(1),' ') 
        warning('Name not entered or is invalid, please re-enter.');            
    elseif ~isempty(str2num(TT_L(1)))
        warning('Name cannot being with a numeric, please re-enter.');

    elseif strcmp(C1_L, '') || strcmp(C1_L, ' ')
        warning('Contrast C1 not entered or is invalid, please re-enter.');
     elseif isempty(str2num(C1_L))
         warning('Contrast C1 is not numeric, please re-enter.');

    elseif strcmp(C2_L, '') || strcmp(C2_L, ' ')
        warning('Contrast C2 not entered or is invalid, please re-enter.');
     elseif isempty(str2num(C2_L))
         warning('Contrast C2 is not numeric, please re-enter.');

    elseif strcmp(C3_L, '') || strcmp(C3_L, ' ')
        warning('Contrast C3 not entered or is invalid, please re-enter.');
     elseif isempty(str2num(C3_L))
         warning('Contrast C3 is not numeric, please re-enter.');

    elseif strcmp(C4_L, '') || strcmp(C4_L, ' ')
        warning('Contrast C4 not entered or is invalid, please re-enter.');
     elseif isempty(str2num(C4_L))
         warning('Contrast C4 is not numeric, please re-enter.');

    else

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


%%
function [tmfc] = Finisher(tmfc,carbs,TMFC_analysis,ROI_set_number)

    switch (TMFC_analysis)

        case 1
            % gPPI
            yard = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI);
            for i = 1:length(carbs)
               tmfc.ROI_set(ROI_set_number).contrasts.gPPI(yard+i).title = carbs(i).title;
               tmfc.ROI_set(ROI_set_number).contrasts.gPPI(yard+i).weights = carbs(i).weights; 
            end

        case 2
            % gPPI FIR
            yard = length(tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR);
            for i = 1:length(carbs)
               tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(yard+i).title = carbs(i).title;
               tmfc.ROI_set(ROI_set_number).contrasts.gPPI_FIR(yard+i).weights = carbs(i).weights; 
            end

        case 3
            % BSC
            yard = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC);
            for i = 1:length(carbs)
               tmfc.ROI_set(ROI_set_number).contrasts.BSC(yard+i).title = carbs(i).title;
               tmfc.ROI_set(ROI_set_number).contrasts.BSC(yard+i).weights = carbs(i).weights; 
            end

        case 4
            % BSC FIR
            yard = length(tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR);
            for i = 1:length(carbs)
               tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(yard+i).title = carbs(i).title;
               tmfc.ROI_set(ROI_set_number).contrasts.BSC_after_FIR(yard+i).weights = carbs(i).weights; 
            end
    end
    
end