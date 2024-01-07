function tmfc_FIR_GUI(OPS, TT)

% This function is the GUI interface for FIR Regression in TMFC toolbox
% The function takes 2 inputs as parameters, where
% OPS = Case of exuection (i.e. FIR from START, RESTART, CONTINUATION) 
% TT = Variable to indicate the index of CONTINUATION for CASE 3

% Supporting functions to create & use GUI windows


% Switch case to select appropriate case as in TMFC/FIR_REG()
switch (OPS)
    
    % GUI window to ask for FIR Windows & Bins
    case 1
        FIR_regress_GUI();
        
    % GUI Window to ask if user wants to Restart computation of all subjs
    case 2
        FIR_restart_GUI();
     
    % GUI Window to ask if user wants to continue from specific subject or
    % Full restart 
    case 3
        FIR_continue_GUI(TT);
        
end

    
    % Function to generate GUI window and acquire WINDOWS & BINS for 
    % FIR regression
    function FIR_regress_GUI(~,~)

        FIR_1 = figure('Name', 'FIR task regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.22 0.18],'Resize','off', 'Tag', 'FIR_REG_NUM', 'WindowStyle','modal'); %X Y W H
        set(gcf,'color','w');
        set(FIR_1, 'MenuBar', 'none');
        set(FIR_1, 'ToolBar', 'none');

        FIR_D1 = uicontrol(FIR_1,'Style','text','String', 'Enter FIR window length (in seconds):','Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40);
        FIR_D2 = uicontrol(FIR_1,'Style','text','String', 'Enter the number of FIR time bins:','Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.40);

        FIR_E1 = uicontrol(FIR_1,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center');%,'InputType', 'digits');%, 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.054
        FIR_E2 = uicontrol(FIR_1,'Style','edit','Units', 'normalized', 'HorizontalAlignment', 'center');%, 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.054

        FIR_OK = uicontrol(FIR_1,'Style','pushbutton','String', 'OK','Units', 'normalized');%,'fontunits','normalized', 'fontSize', 0.35
        FIR_HELP = uicontrol(FIR_1,'Style','pushbutton', 'String', 'Help','Units', 'normalized');%,'fontunits','normalized', 'fontSize', 0.35

        FIR_D1.Position = [0.08 0.62 0.65 0.200];
        FIR_D2.Position = [0.08 0.37 0.65 0.200];
        set(FIR_D1,'backgroundcolor',get(FIR_1,'color'));
        set(FIR_D2,'backgroundcolor',get(FIR_1,'color'));

        FIR_E1.Position = [0.76 0.67 0.185 0.170];
        FIR_E2.Position = [0.76 0.42 0.185 0.170];

        FIR_OK.Position = [0.21 0.13 0.230 0.170];
        FIR_HELP.Position = [0.52 0.13 0.230 0.170];

        set(FIR_OK, 'callback', @EXTRACT);
        set(FIR_HELP, 'callback', @FIR_1_HELP_POP);


        % Generates the HELP WINDOW within the GUI 
        function FIR_1_HELP_POP(~,~)

                FIR_1_HELP = figure('Name', 'FIR task regression: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.62 0.26 0.22 0.48],'Resize','off'); %X Y W H
                set(gcf,'color','w');
                set(FIR_1_HELP, 'MenuBar', 'none');
                set(FIR_1_HELP, 'ToolBar', 'none');

                THE_DETAILS = {'Finite impulse response (FIR) task regression are used to remove co-activations from BOLD time-series.','',...
                    'Co-activations are simultaneous (de)activations', 'without communication between brain regions.',...
                    '',...
                    'Co-activations spuriously inflate task-modulated','functional connectivity (TMFC) estimates.','',...
                    'This option regress out (1) co-activations with any','possible shape and (2) confounds specified in the original',...
                    'SPM.mat file (e.g., motion, physiological noise, etc).',...
                    '','Functional images for residual time-series(Res_*.nii in',...
                    'FIR_GLM folders) will be further used for TMFC analysis.','',...
                    'Typically, the FIR window length covers the duration of',...
                    'the event and an additional 18s to account for the likely',...
                    'duration of the hemodynamic response.','',...
                    'Typically, the FIR time bin is equal to one repetition time',...
                    '(TR). Therefore, the number of FIR time bins is equal to:',''};
                    THE_DETAILS_2 = {'Number of FIR bins = FIR window length/TR'};

                LS2_DTS_1 = uicontrol(FIR_1_HELP,'Style','text','String', THE_DETAILS,'Units', 'normalized', 'HorizontalAlignment', 'left','fontunits','normalized', 'fontSize', 0.035);
                LS2_DTS_2 = uicontrol(FIR_1_HELP,'Style','text','String', THE_DETAILS_2,'Units', 'normalized', 'HorizontalAlignment', 'Center','fontunits','normalized', 'fontSize', 0.30);%,'fontunits','normalized', 'fontSize', 0.054);
                LS2_OK = uicontrol(FIR_1_HELP,'Style','pushbutton', 'String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.35);

                set(LS2_DTS_1,'backgroundcolor',get(FIR_1_HELP,'color'));
                set(LS2_DTS_2,'backgroundcolor',get(FIR_1_HELP,'color'));

                LS2_DTS_1.Position = [0.06 0.16 0.885 0.800];
                LS2_DTS_2.Position = [0.06 0.10 0.885 0.10];
                LS2_OK.Position = [0.39 0.04 0.240 0.070];

                set(LS2_OK, 'callback', @CLOSE_LS2_OK);

                function CLOSE_LS2_OK(~,~)
                    close(FIR_1_HELP);
                end
        end

        % Function to extract the entered number from the user
        function EXTRACT(~,~)

           Window = str2double(get(FIR_E1, 'String'));
           bins = str2double(get(FIR_E2, 'String'));

           if isnan(Window)
               warning('Please enter the number of windows');
           elseif ~isnan(Window) & isnan(bins)
               warning('Please eneter the number of bins');
           else
               DMG = evalin('base', 'tmfc');
               DMG.FIR_window = Window; 
               DMG.FIR_bins = bins;   
               assignin('base', 'tmfc', DMG); 
               close(FIR_1);
           end

        end

    end


    % Function to generate GUI window and ask to Restart computation from
    % the start of subjects
    function varargout = FIR_restart_GUI(~,~)

        FIR_RECOMP = figure('Name', 'FIR task regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.16 0.16],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Restart_FIR'); %X Y W H

        FIR_D1 = uicontrol(FIR_RECOMP,'Style','text','String', {'Recompute FIR task','regression for all subjects.?'},'Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);

        FIR_OK = uicontrol(FIR_RECOMP,'Style','pushbutton','String', 'OK','Units', 'normalized','fontunits','normalized', 'fontSize', 0.48);
        FIR_CCL = uicontrol(FIR_RECOMP,'Style','pushbutton', 'String', 'Cancel','Units', 'normalized','fontunits','normalized', 'fontSize', 0.48);

        FIR_D1.Position = [0.10 0.55 0.80 0.260];
        set(FIR_D1,'backgroundcolor',get(FIR_RECOMP,'color'));

        FIR_OK.Position = [0.14 0.25 0.320 0.170];
        FIR_CCL.Position = [0.52 0.25 0.320 0.170];

        set(FIR_CCL, 'callback', @CANCEL);
        set(FIR_OK, 'callback', @ACC);

        % Function to close the Window
        function CANCEL(~,~)
            close(FIR_RECOMP);
        end

        % Function to set state of Restart in APP Data of main Window
        function ACC(~,~)
            h3 = findobj('Tag', 'MAIN_WINDOW');
            setappdata(h3, 'RESTART_FIR', 1);
            close(FIR_RECOMP);
        end

    end

    % Funciton to generate GUI window and ask to Continue from last
    % computed index or restart from the start
    function FIR_continue_GUI(INDEX)

        FIR_MIDCOMP = figure('Name', 'FIR task regression', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.20 0.20],'Resize','off','color','w','MenuBar', 'none', 'ToolBar', 'none', 'Tag', 'Contd_FIR'); %X Y W H

        FIR_Q1 = uicontrol(FIR_MIDCOMP,'Style','text','String', 'Start FIR task regression from','Units', 'normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);
        FIR_Q2 = uicontrol(FIR_MIDCOMP,'Style','text','String', strcat('subject №',num2str(INDEX),'?'), 'Units','normalized', 'HorizontalAlignment', 'center','fontunits','normalized', 'fontSize', 0.38);

        FIR_YES = uicontrol(FIR_MIDCOMP,'Style','pushbutton','String', 'Yes','Units', 'normalized','fontunits','normalized', 'fontSize', 0.28);
        FIR_RESTART = uicontrol(FIR_MIDCOMP,'Style','pushbutton', 'String', '<html>&#160 No, start from <br>the first subject','Units', 'normalized','fontunits','normalized', 'fontSize', 0.28);

        FIR_Q1.Position = [0.10 0.55 0.80 0.260];
        FIR_Q2.Position = [0.10 0.40 0.80 0.260];

        set([FIR_Q1,FIR_Q2],'backgroundcolor',get(FIR_MIDCOMP,'color'));

        FIR_YES.Position = [0.12 0.15 0.320 0.270];
        FIR_RESTART.Position = [0.56 0.15 0.320 0.270];

        set(FIR_YES, 'callback', @contd);
        set(FIR_RESTART, 'callback', @RESTART);

        % Function to set status in MAIN_WINDOW appdata (To continue from
        % last processed subject) 
        function contd(~,~)
            h6 = findobj('Tag', 'MAIN_WINDOW');
            setappdata(h6, 'CONTD_FIR', 1);
            close(FIR_MIDCOMP);
        end
        % Function to set status in MAIN_WINDOW appdata (To Restart from
        % the first subject)
        function RESTART(~,~)
            h6 = findobj('Tag', 'MAIN_WINDOW');
            setappdata(h6, 'CONTD_FIR', 2);
            close(FIR_MIDCOMP);
        end

    end


end

