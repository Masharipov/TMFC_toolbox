function [varargout] = tmfc_select_subjects_GUI(FigH, RUN_CHECK)

% UIWAIT IS USED HERE TO Accomodate WITHOUT CHECKING SELECTION
% Select_subjects_GUI performs selection of subjects using the SPM Select
% Function. The function can work in two modes i.e. via TMFC main window
% route or independently as a single file where the selected subject paths
% undergo 4 stages of checking and verificaiton after which it is exported
% to the TMFC varaible or the Addresses variable in the base workspace. 

% When running this code independtenly FigH can be left as [] i.e. 
% tmfc_select_subjects_GUI([], 0) - No checks
% tmfc_select_subjects_GUI([], 1) - With checks


CHECK_STATUS = RUN_CHECK;

try
    h_FREZ = findobj('Tag','MAIN_WINDOWS');
    F_data = guidata(h_FREZ); 
    set([F_data.SUB,F_data.FIR_TR, F_data.LSS_R, F_data.LSS_RW, F_data.BSC, F_data.gppi,F_data.save_p, F_data.open_p, F_data.change_p, F_data.settings,F_data.bgrd],'Enable', "off");
end
            
            
if CHECK_STATUS == 1
                                    % Selection of Project Path from the User
        path = spm_select(1,'dir','Select a folder for the new TMFC project',{},pwd);
        if path == ""
            warning("Project Path Not selected, Subjects not saved");
            try
            h1_UNFREZ = findobj('Tag','MAIN_WINDOWS');
            F1_data = guidata(h1_UNFREZ); 
            set([F1_data.SUB,F1_data.FIR_TR, F1_data.LSS_R, F1_data.LSS_RW, F1_data.BSC, F1_data.gppi,F1_data.save_p, F1_data.open_p, F1_data.change_p, F1_data.settings,F1_data.bgrd],'Enable', "on");
            end
            return;
        else
            PROJECT_PATHS = path;
            disp("Proceeding with Subject Selection");
        end
        
end

% Creation of Figure for the Window
f = figure("Name", "Subject Manager", "NumberTitle", "off", "Units", "normalized", "Position", [0.32 0.26 0.35 0.575],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off', "Tag", "Select_SUBS",'WindowStyle', "modal",'CloseRequestFcn', @Closeaction);


% Initializing Elements of the UI (Buttons, Stats, Boxes etc) 
b1 = uicontrol(f,'Style','pushbutton', "String", "Select subject folders","Units", "normalized", "Position",[0.033 0.850 0.455 0.095]);
b1_Stat = uicontrol(f,'Style','text',"String", "Not Selected","ForegroundColor","red","Units", "normalized", "Position",[0.500 0.820 0.450 0.095],'backgroundcolor','w');

b2 = uicontrol(f,'Style','pushbutton', "String", "Select SPM.mat file for Subject №1","Units", "normalized", "Position",[0.033 0.750 0.455 0.095]);
b2_Stat = uicontrol(f,'Style','text',"String", "Not Selected","ForegroundColor","red","Units", "normalized", "Position",[0.500 0.720 0.450 0.095],'backgroundcolor','w');

b3 = uicontrol(f,'Style','pushbutton', "String", "Add new subject","Units", "normalized", "Position",[0.033 0.14 0.300 0.095]);
b4 = uicontrol(f,'Style','pushbutton', "String", "Remove selected subject","Units", "normalized", "Position",[0.346 0.14 0.300 0.095]);
b5 = uicontrol(f,'Style','pushbutton', "String", "OK","Units", "normalized", "Position",[0.390 0.04 0.200 0.080]);

lst = uicontrol(f, 'Style', 'listbox', "String", "",'Max',100,"Units", "normalized", "Position",[0.033 0.250 0.920 0.490]);
clr = uicontrol(f,'Style','pushbutton', "String", "Clear all subjects","Units", "normalized", "Position",[0.660 0.14 0.300 0.095]);


% Assigning Functions Callbacks for each Element (button, listbox etc)
set(b1, 'callback', @action_1)
set(b2, 'callback', @action_2)
set(clr, 'callback', @action_clr)
set(lst, 'callback', @action_select)
set(b3, 'callback', @action_3)
set(b4, 'callback', @action_4)
set(b5, 'callback', @action_5)
set(lst, 'Value', []);

% Define the function that will be called when the figure is closed
function Closeaction(hObject, eventdata)
    try
        h1_UNFREZ = findobj('Tag','MAIN_WINDOWS');
        F1_data = guidata(h1_UNFREZ); 
        set([F1_data.SUB,F1_data.FIR_TR, F1_data.LSS_R, F1_data.LSS_RW, F1_data.BSC, F1_data.gppi,F1_data.save_p, F1_data.open_p, F1_data.change_p, F1_data.settings,F1_data.bgrd],'Enable', "on");
    end
    delete(f);
end



% Local Variables that work throughout the RunTime upto checking stage
main_subjects = {};      % Variable to store Subject Addresses
file_address = {};       % Variable to store full .extension Addresses 
mm_add = {};             % Varaible to store the selected .extension file

selection = {};          % Variable to store the selected list of addreses(as INDEX)
add_subs = {};           % Variable used to create & merge new subjects



% Execution function for Main Subject Selection
    function action_1(~,~)
        
        set(lst, "String", "");                   % Intializing display list in the GUI 
        main_subjects = sub_folder();             % Prompt for SPM_DIR select 
        main_subjects = unique(main_subjects);    % Filtering new selection for repetitions
        len_subs_A1 = size(main_subjects);        % Calculation of Size of added subjects
        

        % Logical & Warning Conditions
        if isempty(main_subjects)
            disp("0 Subjects selected");
            set(b1_Stat,"String", "Not selected","ForegroundColor","red");
            set(b2_Stat,"String", "Not selected","ForegroundColor","red");
            mm_add = "";
            file_address = "";
        else
            fprintf("Subjects selected are: %d \n", len_subs_A1(1));
            disp("Proceed to Select SPM.mat file");
            set(b1_Stat,"String", len_subs_A1(1)+" selected","ForegroundColor","#385723");
            set(b2_Stat,"String", "Not selected","ForegroundColor","red");
            mm_add = "";
            file_address = "";
        end
        
        
        if file_address == "" & mm_add == "" & main_subjects == ""
            warning("No Subjects selected");
            mm_add = "";
            file_address = "";
            main_subjects = "";
            set(b1_Stat,"String", "Not selected","ForegroundColor","red");
            set(b2_Stat,"String", "Not selected","ForegroundColor","red");
        end
        
    end




    % Execution function for .EXTENSION file selection from the first Subject
    function action_2(~,~)

        % Logical & Warning Condition
        if isempty(main_subjects)
            warning("Please select subject folders");        
            
        elseif file_address == "" & main_subjects == "" 
            warning("Please select subject folders");
            set(b2_Stat,"String", "Not selected","ForegroundColor","red");
            set(lst, "String", "");
            
        else
            
            [file_address, mm_add] = mat_file(main_subjects);              % Creation of full list of Subs with .FILE extension
            if mm_add ~= ""
                set(lst, "String", file_address);                          % Display Full Address of Subs in the GUI
                disp("The SPM.mat file has been succesfully selected");
                set(b2_Stat,"String", "Selected","ForegroundColor","#385723");
            end
            
        end
        
    end




    % Clear Function: To Clear all existing subjects & .FILE extensions
    function action_clr(~,~)
        
        % Logical & Warning condition
        if isempty(main_subjects) | file_address == ""
            warning("No subjects present to clear");
        else
            main_subjects = {};
            file_address = {};
            mm_add = {};
            set(lst, "String", "");                                         % Clearing Display
            disp("All selected subjects have been cleared");
            set(b1_Stat,"String", "None selected","ForegroundColor","red");
            set(b2_Stat,"String", "None selected","ForegroundColor","red");
        end 
        
        
    end




    % Function to select the respective item from the user via index
    function action_select(~,~)
        index = get(lst, 'Value');                                          % Retrieves the users selection LIVE
        selection = index;                                                  % variable for full selection
    end




    % Function to Add new Subjects to Existing List 
    function action_3(~,~)
        
        % Logical & Warning Condition (Iteration i)
        if isempty(main_subjects) | file_address == ""
            warning("No existing list of subjects present, Please select subjects via ""Select subject folders"" button");
            
        elseif isempty(mm_add)
            warning("Cannot add new subjects without SPM.mat, Please select subjects via ""Select subject folders"" button and proceed to Select SPM.mat file");

        else
            
            add_subs = mid_sub_folder();                                    % Addition Function
            
            if isempty(add_subs)
                warning("No newly selected subjects");
            else
                len_exst = size(file_address);                              % Size of existing subjects
                len_subs_3 = size(add_subs);                                % Length of Size of new subjects
                NEW_paths = {};                                             % Creation of empty array

                
                % Loop to append .FILE Extension to the Newly selected subjects
                for j = 1:len_subs_3(1)
                   NEW_paths =  vertcat(NEW_paths,strcat(char(add_subs(j,:)),char(mm_add)));
                end

                file_address = vertcat(file_address, NEW_paths);            % Joining exisiting list of subjects with new Subjects
                new_ones = size(unique(file_address)) - len_exst(1);        % Removing Duplicates
                file_address = unique(file_address);
               
                % Warning & logical Condition (Iteration ii)
                if new_ones(1) == 0
                    warning("Newly selected subjects are already present in the list, no new subjects added");
                else
                    fprintf("New subjects selected are: %d \n", new_ones(1)); 
                end 
                
            end 
            
            set(lst, "String", file_address);                               % Updating display with new Subjects
            len_subs = size(file_address);
            set(b1_Stat,"String", len_subs(1)+" selected","ForegroundColor","#385723");
            
        end
    end




    % Function to remove subjects via selection from action_Select
    function action_4(~,~) 
        
        % Logical & Warning Condition
        if isempty(selection)
            warning("There are no selected subjects to remove from the list, please select subjects once again");
        else
            file_address(selection,:) = [];                                 % Nullifying the Indexs selected as per the user
            holder = size(selection);
            fprintf("Number of subjects removed are: %d \n", holder(2));
            
            set(lst,'Value',[]);                                             % Setting Min select value to 1 since it gives a warning of dynamic mismatch
            
            set(lst, "String", file_address);                               % Updating the display with the new list of subjects after removal 
            selection ={};
            
            if size(file_address) < 1
                set(b1_Stat,"String", "Not selected","ForegroundColor","red");
            else
                len_subs = size(file_address);
                set(b1_Stat,"String", len_subs(1)+" selected","ForegroundColor","#385723")
            end
        end
    end 




    % Function to perform final Deletion of variables in Workspace -> 4 stage checking -> selection of Project Path -> Exporting to a variable
    function file_func = action_5(~,~)

        file_correct = {};
        file_incorrect = {};
        file_exist = {};
        file_not_exist = {};
        file_dir = {};
        file_no_dir = {};
        funct_check= {};
        file_func = {};
        file_no_func = {};
        
    
        % Pre conditions to verify existence of subujects 
        if isempty(main_subjects)
            warning("There are no selected subjects, please select subjects and SPM.mat files");
            
        % Condition to check for selected SPM.mat file but not subjects
        elseif (isempty(file_address) & isempty(mm_add)) | (main_subjects ~= "" & mm_add == "");
            warning("Please select SPM.mat file for the first subject");
        
        % Condition to check for Action cleared SPM.mat & Subjects
        elseif file_address == "" & mm_add ~= "";
            warning("Please Re-select the subjects and the SPM.mat file if required");
            
        
        % 4 Stage File Checking
        else
        close(f);                                       % Close Select Subjects GUI    
        
        if CHECK_STATUS == 1




                [file_exist,file_not_exist] = SPM_EXT_CHK(file_address);         % Stage 1 - File Existence check

                if size(file_address) == size(file_not_exist) | file_exist == ""
                    warning("STAGE 1 CHECK FAILED: All files are missing from the directories, Please try again");
                    Royal_Reset();

                else

                    [file_correct, file_incorrect] = SPM_COND(file_exist);       % Stage 2 - File Correct/Incorrect Check

                    if size(file_incorrect) == size(file_exist) | file_correct == ""
                        warning("STAGE 2 CHECK FAILED: All files have incorrect conditions, Please try again");
                        Royal_Reset();
                    else

                        [file_dir,file_no_dir] = CHECK_DIR(file_correct);        % Stage 3 - File Directory exist/Not exist

                        if size(file_no_dir) == size(file_correct) | file_dir == ""
                            warning("STAGE 3 CHECK FAILED: The directories are missing from All selected Files, Please try again");
                            Royal_Reset();
                        else

                            [file_func,file_no_func] = CHECK_FUNCTION(file_dir); % Stage 4 - File Functional files exist/Not exist

                            if size(file_no_func) == size(file_dir) | file_func == ""
                                warning("STAGE 4 CHECK FAILED: Files are missing from All directories, Please try again");
                                Royal_Reset();
                            else

                                % NEED TO ADD CONDITION IF PROJECT PATH IS NOT
                                % SELECTED


                                %flag = 1;
                                %warning("All Selected Subjects & their respective paths are stored in variable ""Addresses"" ");


                                % Synchronization of all Data with the main
                                % TMFC_variable in base workspace & TMFC_GUI 

                                h = findobj('Tag','MAIN_WINDOWS');              % Find the Main GUI using its handle

                                if ~isempty(h)
                                    
                                    try

                                        tmfc_major_reset();                              % Function to reset & Clear all prior calculated data

                                     
                                        g1data = guidata(h);                        % Get Handles and Data associated to Main GUI

                                        ADRS = size(file_func);                     % Variable with the size of the final subjects after all checking

                                        set(g1data.SUB_stat,"ForegroundColor","#385723");
                                        set(g1data.SUB_stat,'String',ADRS(1)+" selected");      % Assigning the variable to the Main GUI static text
                                        set([g1data.SUB,g1data.FIR_TR, g1data.LSS_R, g1data.LSS_RW, g1data.BSC, g1data.gppi,g1data.save_p, g1data.open_p, g1data.change_p, g1data.settings,g1data.bgrd],'Enable', "on");
                                    catch 
                                        warning("Please close older instances of TMFC toolbox");
                                        
                                    end


                                    try



                                    FD = evalin('base', 'tmfc');                % Creating a local copy of the TMFC variable from the base workspace

                                    for i = 1:length(file_func)                 % Assigning the subject paths to the respective structure variable
                                        FD.subjects(i).paths = char(file_func(i));
                                        FD.subjects(i).FIR = NaN;
                                        FD.subjects(i).LSS_residual_ts = NaN;
                                        FD.subjects(i).LSS_original_ts = NaN;
                                        FD.subjects(i).BSC = NaN;
                                        FD.subjects(i).VOI = NaN;
                                        FD.subjects(i).PPIterm = NaN;
                                        FD.subjects(i).gPPI = NaN;
                                    end
                                    disp(ADRS(1)+" subjects selected");
                                    FD.project_path = PROJECT_PATHS;            % Assigning the Project paths to the respective structure variable 

                                    assignin('base', 'tmfc', FD);               % Updating the TMFC variable to the base workspace after performing all modifications to its local copy

                                    end

                                else                                            % if else is used here in order to support independent execution
                                    assignin('base', "Addresses", char(file_func));   % In case TMFC window doesn't exist, it will create a single variable called Addresses & assing it to the base.

                                end 
                                %Royal_Reset();


                            end

                        end 

                   end

                end
        else
            varargout{1} = file_address;                                    % Exporting the selected subjects if selected without checks as FUNCTION output 
        end  
            
        end                                                                 % Closing the If condition for checking & opertaions 
        
    end      % Closing Function 5
        % Function to perform clearing & Reset of the Select SUBS GUI
        function Royal_Reset(~,~)
            main_subjects = {};
            file_address = {};
            mm_add = {};
            %set(lst, "String", ""); %Intializing list in GUI workspace
            set(b1_Stat,"String", "Not selected","ForegroundColor","red");
            set(b2_Stat,"String", "Not selected","ForegroundColor","red");
            h_UNFREZ = findobj('Tag','MAIN_WINDOWS');
            UF_data = guidata(h_UNFREZ); 
            set([UF_data.SUB,UF_data.FIR_TR, UF_data.LSS_R, UF_data.LSS_RW, UF_dataBSC, UF_data.gppi,UF_data.save_p, UF_data.open_p, UF_data.change_p, UF_data.settings,UF_data.bgrd],'Enable', "on");
        end
    
uiwait(f);
return;


end          % Closing the select_subjects_GUI function





% External Functions that are used within the execution of Select_SUB_GUI



% Function to choose Subjects for the first time
function subjects = sub_folder(~,~)        

        subs_f = spm_select(inf,'dir','Select folders of all subjects',{},pwd,'..');
        
        subjects = {};                % Cell to store subjects
        len_subs = size(subs_f);      % Length of Subjects

        % Updating list of Subjects
        for i = 1: len_subs(1)
            subjects = vertcat(subjects, subs_f(i,:));
        end
        
end                



% Function to Select .FILE extension & Concatinate to the Selected subjects
function [full_path, mat_adrs] = mat_file(x)
        
        % Selection of .FILE extension for the first subject based on the users choice. 
        [mat_f] = spm_select( 1,'any','Select SPM.mat file for the first subject',{}, x(1,:), 'SPM.*');
        
        % Extract the .FILE extension part from the first subject 
        [mat_adrs] = replace(mat_f, x(1,:),""); 
        
        len_subs = size(x);
        
        full_path = {}; % Creation of variable to store all the new Full paths of the subjects 
        
        % Concationation & creation of a full scale list of variables
        for i = 1:len_subs(1)
           full_path =  vertcat(full_path,strcat(char(x(i,:)),char(mat_adrs)));
        end
        
end 



% Function to perform Addition of Subjects during execution 
function New_subjects = mid_sub_folder(~,~)        

        N_subs_f = spm_select(inf,'dir','Select NEW subject folders',{},pwd,'..');
        
        New_subjects = {};
        N_len_subs = size(N_subs_f);

        for i = 1: N_len_subs(1)
            New_subjects = vertcat(New_subjects, N_subs_f(i,:));
        end
        
end        



% CHECK - 1: FILE EXISTENCE
function [file_exist,file_not_exist] = SPM_EXT_CHK(Y_1)

            file_exist = {};
            file_not_exist = {};     
            
            % Condition to verify if file exists in the location
            for i = 1:length(Y_1) 
                if exist(Y_1{i}, 'file')
                    file_exist{i,1} = Y_1{i};
                else
                    file_not_exist{i,1} = Y_1{i};
                end                
            end 
            
            
            % Checks if the variables storing the existing files are empty or full
            try
                file_exist = file_exist(~cellfun('isempty', file_exist)); 
            end

            try 
                file_not_exist = file_not_exist(~cellfun('isempty',file_not_exist)); 
            end

            
            % Resulting Condition: If all files are NOT present as per the paths
            if length(file_exist) ~= length(Y_1) 
                
                % Creation of Pop up Window & show the respective files that are missing
                f_1 = figure("Name", "Subject Manager", "NumberTitle", "off", "Units", "normalized", "Position", [0.32 0.26 0.35 0.18], 'color', 'w', 'MenuBar', 'none', 'ToolBar', 'none','Resize','off');

                % Initializing Elements of the UI
                lst_1 = uicontrol(f_1, 'Style', 'listbox', "String", "",'Max',100,"Units", "normalized", "Position", [0.025 0.280 0.940 0.490]);
                G1_Stat = uicontrol(f_1,'Style','text',"String", "Warning, the following SPM.mat files are missing:","Units", "normalized", "Position",[0.280 0.820 0.450 0.095], 'backgroundcolor', 'w');
                G1 = uicontrol(f_1,'Style','pushbutton', "String", "OK","Units", "normalized", "Position",[0.4 0.05 0.180 0.180]);

                % Assigning Functions Callbacks for each Element (button, listbox etc)
                set(lst_1, "String", file_not_exist);                 
                set(G1, "Callback", @action_close_GUI_1);
                waitforbuttonpress;
                set(lst_1, "String", "");  
            end
            
            function action_close_GUI_1(~,~)
                close(f_1);
            end
        
end


% CHECK - 2: SPM CONDITIONS
function [file_correct, file_incorrect] = SPM_COND(Y_2) 

            file_incorrect = {};
            file_correct = {};
            
            if length(Y_2) > 1

                w = waitbar(0,'Check conditions','Name','Check SPM.mat files');

                % Reference SPM.mat file
                file_correct{1,1} = Y_2{1};
                SPM_ref = load(Y_2{1});

                % Reference structure for conditions
                for j = 1:length(SPM_ref.SPM.Sess)
                    cond_ref(j).sess = struct('name', {SPM_ref.SPM.Sess(j).U(:).name});
                end

                % Start check
                for i = 2:length(Y_2)
                    
                    % SPM.mat file to check
                    SPM = load(Y_2{i});

                    % Structure for conditions to check
                    for j = 1:length(SPM.SPM.Sess)
                        cond(j).sess = struct('name', {SPM.SPM.Sess(j).U(:).name});
                    end 

                    if ~isequaln(cond_ref, cond)
                        file_incorrect{i,1} = Y_2{i};
                    else
                        file_correct{i,1} = Y_2{i};
                    end

                    try
                        waitbar(i/length(Y_2),w);
                    end

                    clear SPM cond
                end
                
            else
                file_correct = Y_2;
            end
            
            % Closing Waitbar pop up
            try
                close(w)
            end
            
            % Listing empty Correct & Incorrect files
            try
                file_correct = file_correct(~cellfun('isempty', file_correct));
            end

            try
                file_incorrect = file_incorrect(~cellfun('isempty', file_incorrect));
            end

            % GUI for Correct & Incorrect files
            if length(file_correct) ~=  length(Y_2)
                
                % Creation of GUI Figure
                f_2 = figure("Name", "Subject Manager", "NumberTitle", "off", "Units", "normalized", "Position", [0.32 0.26 0.35 0.18], 'color', 'w','MenuBar', 'none','ToolBar', 'none','Resize','off');

                % Initializing Elements of the UI
                lst_2 = uicontrol(f_2, 'Style', 'listbox', "String", "",'Max',100,"Units", "normalized", "Position", [0.025 0.280 0.940 0.490]);
                G2_Stat = uicontrol(f_2,'Style','text',"String", "Warning, in the following SPM.mat files different conditions are specified:","Units", "normalized", "Position", [0.110 0.820 0.800 0.095], 'backgroundcolor', 'w');
                G2 = uicontrol(f_2,'Style','pushbutton', "String", "OK","Units", "normalized", "Position", [0.4 0.05 0.180 0.180]);

                % Assigning Functions Callbacks for each Element (button, listbox etc)
                set(lst_2, "String", file_incorrect);  
                set(G2, 'callback', @action_close_GUI_2)
                waitforbuttonpress;
                
            end
            
    function action_close_GUI_2(~,~)
            close(f_2);
    end


end


% CHECK - 3: SPM DIRECTORIES 
function [file_dir,file_no_dir] = CHECK_DIR(Y_3)

            file_dir = {};
            file_no_dir = {};
            w = waitbar(0,'Check directories','Name','Check SPM.mat files');

            for i = 1:length(Y_3) 
                
                %SPM.mat file to check
                SPM = load(Y_3{i});
                if exist(SPM.SPM.swd, 'dir') 
                    file_dir{i,1} = Y_3{i};
                else
                    file_no_dir{i,1} = Y_3{i};
                end
                clear SPM
                try
                    waitbar(i/length(Y_3),w);
                end
            end

            
            try
                close(w)
            end

            
            try
                file_dir = file_dir(~cellfun('isempty', file_dir));
            end

            
            try 
                file_no_dir = file_no_dir(~cellfun('isempty',file_no_dir)); 
            end
            
            
            if length(file_dir) ~=  length(Y_3)
                
                % Creation of Figure window
                f_3 = figure("Name", "Subject Manager", "NumberTitle", "off", "Units", "normalized", "Position", [0.32 0.26 0.35 0.18], 'color', 'w','MenuBar', 'none','ToolBar', 'none','Resize','off');

                % Initializing Elements of the UI
                lst_3 = uicontrol(f_3, 'Style', 'listbox', "String", "",'Max',100,"Units", "normalized", "Position", [0.025 0.280 0.940 0.490]);
                G3_Stat = uicontrol(f_3,'Style','text',"String", "Warning, the output folder (SPM.swd) specified in the following SPM.mat files do not exist: ","Units", "normalized", "Position", [0.110 0.820 0.800 0.095], 'backgroundcolor', 'w');
                G3 = uicontrol(f_3,'Style','pushbutton', "String", "OK","Units", "normalized", "Position", [0.4 0.05 0.180 0.180]);

                % Assigning Functions Callbacks for each Element (button, listbox etc)
                set(lst_3, "String", file_no_dir);  
                set(G3, 'callback', @action_close_GUI_3)
                waitforbuttonpress;
            end
            
            function action_close_GUI_3(~,~)
                close(f_3);
            end
            
end
            
% CHECK - 4: SPM FUNCTIONAL FILES 
function [file_func,file_no_func] = CHECK_FUNCTION(Y_4)

            file_func = {};
            file_no_func = {};
            w = waitbar(0,'Check functional files','Name','Check SPM.mat files');

            for i = 1:length(Y_4) 
                
                %SPM.mat file to check
                SPM = load(Y_4{i});
                
                %Check functional files
                for j = 1:length(SPM.SPM.xY.VY)
                    funct_check(j) = exist(SPM.SPM.xY.VY(j).fname, 'file');
                end
                
                if nnz(funct_check) == length(SPM.SPM.xY.VY)
                    file_func{i,1} = Y_4{i};
                else
                    file_no_func{i,1} = Y_4{i};
                end
                clear SPM funct_check      
                
                try
                    waitbar(i/length(Y_4),w);
                end
                
            end

            try
                close(w)
            end

            
            try
                file_func = file_func(~cellfun('isempty', file_func));
            end

            
            try 
                file_no_func = file_no_func(~cellfun('isempty',file_no_func)); 
            end
            
            if length(file_func) ~=  length(Y_4)
                
                % Creation of Figure for GUI window
                f_4 = figure("Name", "Subject Manager", "NumberTitle", "off", "Units", "normalized", "Position", [0.32 0.26 0.35 0.18], 'color', 'w','MenuBar', 'none','ToolBar', 'none','Resize','off');

                % Initializing Elements of the UI
                lst_4 = uicontrol(f_4, 'Style', 'listbox', "String", "",'Max',100,"Units", "normalized", "Position", [0.025 0.280 0.940 0.490]);
                G4_Stat = uicontrol(f_4,'Style','text',"String", "Warning, the functional files specified in the following SPM.mat files do not exist:","Units", "normalized", "Position", [0.110 0.820 0.800 0.095], 'backgroundcolor', 'w');
                G4 = uicontrol(f_4,'Style','pushbutton', "String", "OK","Units", "normalized", "Position", [0.4 0.05 0.180 0.180]);

                % Assigning Functions Callbacks for each Element (button, listbox etc)
                set(lst_4, "String", file_no_func);  
                set(G4, 'callback', @action_close_GUI_4)
                waitforbuttonpress;
            end
            
            function action_close_GUI_4(~,~)
                close(f_4);
            end

end 

% END 