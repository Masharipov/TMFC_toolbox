function tmfc_results_simulation()

RES_GUI = figure('Name', 'TMFC: Results', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.45 0.25 0.22 0.56],'MenuBar', 'none','ToolBar', 'none','color','w','Resize','off','WindowStyle','modal');%,'CloseRequestFcn', @LSS_stable_Exit);

% Initializing Elements of the UI

RES_T1  = uicontrol(RES_GUI,'Style','text','String', 'TMFC Results Synopsis','Units', 'normalized', 'Position',[0.270 0.93 0.460 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w', 'FontWeight', 'bold');
RES_POP_1  = uicontrol(RES_GUI,'Style','popupmenu','String', {'Paired T - Test', 'One Sampled T - Test', 'Two Sampled T - Test'},'Units', 'normalized', 'Position',[0.045 0.87 0.91 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');

RES_lst_1 = uicontrol(RES_GUI , 'Style', 'listbox', 'String', {'Path to files R1', 'RM1_1', 'RM1_2'},'Max', 100,'Units', 'normalized', 'Position',[0.045 0.56 0.440 0.300],'fontunits','normalized', 'fontSize', 0.07);
RES_lst_2 = uicontrol(RES_GUI , 'Style', 'listbox', 'String', {'Path to files R2', 'RM2_1', 'RM2_2'},'Max', 100,'Units', 'normalized', 'Position',[0.52 0.56 0.440 0.300],'fontunits','normalized', 'fontSize', 0.07);

RES_L1_SEL = uicontrol(RES_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized','Position',[0.045 0.49 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);
RES_L1_REM = uicontrol(RES_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized','Position',[0.275 0.49 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);

RES_L2_SEL = uicontrol(RES_GUI,'Style','pushbutton','String', 'Select','Units', 'normalized','Position',[0.52 0.49 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);
RES_L2_REM = uicontrol(RES_GUI,'Style','pushbutton','String', 'Remove','Units', 'normalized','Position',[0.75 0.49 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);

RES_CONT = uipanel(RES_GUI,'Units', 'normalized','Position',[0.046 0.41 0.44 0.07],'HighLightColor',[0.78 0.78 0.78],'BorderType', 'line','BackgroundColor','w');
RES_CONT_txt  = uicontrol(RES_GUI,'Style','text','String', 'Contrast: ','Units', 'normalized', 'Position',[0.095 0.42 0.38 0.04],'fontunits','normalized', 'fontSize', 0.55, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_CONT_val  = uicontrol(RES_GUI,'Style','edit','String', '-1 1','Units', 'normalized', 'Position',[0.278 0.422 0.18 0.045],'fontunits','normalized', 'fontSize', 0.50);


RES_ALP = uipanel(RES_GUI,'Units', 'normalized','Position',[0.52 0.41 0.44 0.07],'HighLightColor',[0.78 0.78 0.78],'BorderType', 'line','BackgroundColor','w');
RES_ALP_txt  = uicontrol(RES_GUI,'Style','text','String', 'Alpha: ','Units', 'normalized', 'Position',[0.583 0.42 0.35 0.04],'fontunits','normalized', 'fontSize', 0.55, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_ALP_val  = uicontrol(RES_GUI,'Style','edit','String', '0.005','Units', 'normalized', 'Position',[0.755 0.422 0.18 0.045],'fontunits','normalized', 'fontSize', 0.50);

RES_THRES_TXT = uicontrol(RES_GUI,'Style','text','String', 'Threshold: ','Units', 'normalized', 'Position',[0.098 0.335 0.38 0.04],'fontunits','normalized', 'fontSize', 0.58, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_THRES_POP = uicontrol(RES_GUI,'Style','popupmenu','String', {'Uncorrected (Parametric)', 'FDR (Parametric)', 'Uncorrected (Non-Parametric)','FDR (Non-Parametric)','NBS FWE(Non-Parametric)','NBS TFCE(Non-Parametric)'},'Units', 'normalized', 'Position',[0.358 0.33 0.6 0.05],'fontunits','normalized', 'fontSize', 0.50,'backgroundcolor','w');


RES_THRES_VAL_TXT = uicontrol(RES_GUI,'Style','text','String', 'Threshold Value (units): ','Units', 'normalized', 'Position',[0.098 0.27 0.38 0.04],'fontunits','normalized', 'fontSize', 0.58, 'HorizontalAlignment','Left','backgroundcolor','w');
RES_THRES_VAL_UNI = uicontrol(RES_GUI,'Style','edit','String', '100.00','Units', 'normalized', 'Position',[0.76 0.274 0.2 0.04],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w');


RES_PERM_TXT = uicontrol(RES_GUI,'Style','text','String', 'Permutations: ','Units', 'normalized', 'Position',[0.098 0.21 0.38 0.04],'fontunits','normalized', 'fontSize', 0.58, 'HorizontalAlignment','Left','backgroundcolor','w', 'enable', 'off');
RES_PERM_VAL = uicontrol(RES_GUI,'Style','edit','String', '5000','Units', 'normalized', 'Position',[0.76 0.214 0.2 0.04],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w','enable', 'off');

RES_RUN = uicontrol(RES_GUI, 'Style', 'pushbutton', 'String', 'Run!','Units', 'normalized','Position',[0.4 0.05 0.210 0.054],'fontunits','normalized', 'fontSize', 0.36);
end

