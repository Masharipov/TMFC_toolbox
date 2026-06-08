function options = tmfc_denoise_options_GUI()

% =[Task-Modulated Functional Connectivity (TMFC) Denoise Toolbox v1.5.0]=
% 
% Opens a GUI to select denoising options.
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

%-Default options
%--------------------------------------------------------------------------
options = struct; 
options.motion = '24HMP';
options.translation_idx = [1 2 3];
options.rotation_idx = [4 5 6];
options.rotation_unit = 'rad';
options.head_radius = 50;
options.DVARS = 1;
options.aCompCor = [5 5];
options.aCompCor_ort = 1;
options.rWLS = 0;
options.spikereg = 0;
options.spikeregFDthr = 0.5;
options.WM_CSF = 'none';
options.GSR = 'none';
options.parallel = 0;

% These options can be selected via tmfc_masks_GUI.m:
% options.GMmask.prob = 0.95;
% options.WMmask.prob = 0.99;
% options.CSFmask.prob = 0.99;
% options.GMmask.dilate = 2;
% options.WMmask.erode = 3;
% options.CSFmask.erode = 2;

%-Options GUI
%--------------------------------------------------------------------------
set_HMP = {'Add 6 temporal derivatives and 12 quadratic terms (24HMP)','Add 6 temporal derivatives (12HMP)','Use standard 6 head motion parameters (6HMP)'};
set_FD_rot = {'Radians (e.g., SPM, FSL, fMRIPrep)','Degrees (e.g., HCP, AFNI)'};
set_DVARS = {'Calculate DVARS and FD-DVARS correlations','None'};
set_ACC = {'Add fixed number of aCompCor regressors','Add regressors explaining 50% of variance in WM/CSF (aCompCor50)','None'};
set_ACC_PO = {'Pre-orthogonalize w.r.t. HMP and HPF', 'None'};
set_rWLS = {'None', 'Apply rWLS for model estimation'};
set_SR = {'None','Add spike regressors'};
set_WM_CSF = {'None','Add WM and CSF signals (2Phys)','Add WM and CSF signals along with their temporal derivatives (4Phys)','Add WM and CSF signals, 2 derivatives, and 4 quadratic terms (8Phys)'};
set_GSR = {'None','Add whole-brain signal (GSR)','Add whole-brain signal and its temporal derivative (2GSR)','Add whole-brain signal, its temporal derivative, and 2 quadratic terms (4GSR)'};
set_PAR = {'None','Enable parallel computations'};

tmfc_DN_GUI = figure('Name','TMFC denoise v1.5.0','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', ...
    'Units', 'normalized', 'Position', [0.345 0.062 0.310 0.850], 'color', 'w', 'Tag', 'TMFC_DN_GUI','resize','on', ...
    'CloseRequestFcn',@close_options_GUI);

movegui(tmfc_DN_GUI,'center');

DN_MP_1 = uipanel(tmfc_DN_GUI,'Units','normalized','Position',[0.025 0.915 0.95 0.078],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DN_MP_2 = uipanel(tmfc_DN_GUI,'Units','normalized','Position',[0.025 0.747 0.95 0.162],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DN_MP_3 = uipanel(tmfc_DN_GUI,'Units','normalized','Position',[0.025 0.663 0.95 0.078],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DN_MP_4 = uipanel(tmfc_DN_GUI,'Units','normalized','Position',[0.025 0.497 0.95 0.160],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DN_MP_5 = uipanel(tmfc_DN_GUI,'Units','normalized','Position',[0.025 0.413 0.95 0.078],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DN_MP_6 = uipanel(tmfc_DN_GUI,'Units','normalized','Position',[0.025 0.329 0.95 0.078],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DN_MP_7 = uipanel(tmfc_DN_GUI,'Units','normalized','Position',[0.025 0.246 0.95 0.078],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DN_MP_8 = uipanel(tmfc_DN_GUI,'Units','normalized','Position',[0.025 0.162 0.95 0.078],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DN_MP_9 = uipanel(tmfc_DN_GUI,'Units','normalized','Position',[0.025 0.077 0.95 0.078],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');


% Head motion parameters (HMP) GUI elements
DN_HMP_txt = uicontrol(tmfc_DN_GUI,'Style','text','String','Head motion parameters (HMP)','Units','normalized','Position',[0.048 0.962 0.9 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DN_HMP_pop = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_HMP,'Units','normalized','Position',[0.048 0.88 0.90 0.073],'fontunits','normalized','fontsize',0.207);

% Framewise Displacement (FD) GUI elements
DN_FD_txt_1 = uicontrol(tmfc_DN_GUI,'Style','text','String','Framewise displacement (FD)','Units','normalized','Position',[0.048 0.879 0.9 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DN_FD_txt_2 = uicontrol(tmfc_DN_GUI,'Style','text','String','Specify the order of motion regressors in the SPM.Sess.C structure (see Help)','Units','normalized','Position',[0.048 0.848 0.9 0.024],'fontunits','normalized','fontsize',0.625,'HorizontalAlignment','left','backgroundcolor','w');
DN_FD_txt_3 = uicontrol(tmfc_DN_GUI,'Style','text','String','Rotation units:','Units','normalized','Position',[0.048 0.786 0.5 0.024],'fontunits','normalized','fontsize',0.625,'HorizontalAlignment','left','backgroundcolor','w');

DN_FD_TR = uicontrol(tmfc_DN_GUI,'Style','text','String','Translational regressors:','Units','normalized','Position',[0.048 0.816 0.29 0.024],'fontunits','normalized','fontsize',0.625,'HorizontalAlignment','left','backgroundcolor','w');
DN_FD_RR = uicontrol(tmfc_DN_GUI,'Style','text','String','Rotational regressors:','Units','normalized','Position',[0.515 0.816 0.29 0.024],'fontunits','normalized','fontsize',0.625,'HorizontalAlignment','left','backgroundcolor','w');
DN_FD_TR_E = uicontrol(tmfc_DN_GUI,'Style','edit','String',num2str(options.translation_idx),'Units','normalized','HorizontalAlignment','center','Position',[0.360 0.815 0.11 0.03],'fontunits','normalized','fontsize',0.55);
DN_FD_RR_E = uicontrol(tmfc_DN_GUI,'Style','edit','String',num2str(options.rotation_idx),'Units','normalized','HorizontalAlignment','center','Position',[0.839 0.815 0.11 0.03],'fontunits','normalized','fontsize',0.55);
DN_FD_pop_2 = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_FD_rot,'Units','normalized','Position',[0.048 0.713 0.90 0.073],'fontunits','normalized','fontsize',0.208);

% DVARS GUI elements
DN_DVARS_txt = uicontrol(tmfc_DN_GUI,'Style','text','String','Derivative of root mean square variance over voxels (DVARS)','Units','normalized','Position',[0.048 0.71 0.9 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DN_DVARS_pop = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_DVARS,'Units','normalized','Position',[0.048 0.63 0.90 0.073],'fontunits','normalized','fontsize',0.207); 

% Anatomical CompCor (ACC) GUI elements
DN_ACC_txt_1 = uicontrol(tmfc_DN_GUI,'Style','text','String','Anatomical component correction (aCompCor)','Units','normalized','Position',[0.048 0.625 0.9 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DN_ACC_pop = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_ACC,'Units','normalized','Position',[0.048 0.545 0.90 0.073],'fontunits','normalized','fontsize',0.208,'callback',@ACC_value);

DN_ACC_txt_2 = uicontrol(tmfc_DN_GUI,'Style','text','String','Number of PCs for WM:','Units','normalized','Position',[0.048 0.548 0.33 0.024],'fontunits','normalized','fontsize',0.625,'HorizontalAlignment','left','backgroundcolor','w');
DN_ACC_txt_3 = uicontrol(tmfc_DN_GUI,'Style','text','String','Number of PCs for CSF:','Units','normalized','Position',[0.515 0.548 0.33 0.024],'fontunits','normalized','fontsize',0.625,'HorizontalAlignment','left','backgroundcolor','w');

DN_ACC_PO_pop = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_ACC_PO,'Units','normalized','Position',[0.048 0.465 0.90 0.073],'fontunits','normalized','fontsize',0.208,'callback',@ACC_PO_value);
DN_ACC_E1 = uicontrol(tmfc_DN_GUI,'Style','edit','String',num2str(options.aCompCor(1)),'Units','normalized','HorizontalAlignment','center','Position',[0.360 0.548 0.11 0.03],'fontunits','normalized','fontsize',0.55);
DN_ACC_E2 = uicontrol(tmfc_DN_GUI,'Style','edit','String',num2str(options.aCompCor(2)),'Units','normalized','HorizontalAlignment','center','Position',[0.839 0.548 0.11 0.03],'fontunits','normalized','fontsize',0.55);

% Robust weighted least squares (rWLS)
DN_rWLS_txt = uicontrol(tmfc_DN_GUI,'Style','text','String','Robust weighted least squares (rWLS)','Units','normalized','Position',[0.048 0.461 0.9 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DN_rWLS_pop = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_rWLS,'Units','normalized','Position',[0.048 0.38 0.90 0.073],'fontunits','normalized','fontsize',0.208);

% Spike regression (SR) GUI elements
DN_SR_txt = uicontrol(tmfc_DN_GUI,'Style','text','String','Spike regression (SpikeReg)','Units','normalized','Position',[0.048 0.377 0.90 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DN_SR_pop = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_SR,'Units','normalized','Position',[0.048 0.295 0.90 0.073],'fontunits','normalized','fontsize',0.208);

% White matter (WM) and cerebrospinal fluid (CSF) signal regression
DN_WM_CSM_txt = uicontrol(tmfc_DN_GUI,'Style','text','String','WM and CSF signal regression (Phys)','Units','normalized','Position',[0.048 0.293 0.90 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DN_WM_CSM_pop = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_WM_CSF,'Units','normalized','Position',[0.048 0.21 0.90 0.073],'fontunits','normalized','fontsize',0.208);

% Global signal regression (GSR)
DN_GSR_txt = uicontrol(tmfc_DN_GUI,'Style','text','String','Global signal regression (GSR)','Units','normalized','Position',[0.048 0.209 0.90 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DN_GSR_pop = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_GSR,'Units','normalized','Position',[0.048 0.13 0.90 0.073],'fontunits','normalized','fontsize',0.208);

% Parallel computations
DN_PAR_txt = uicontrol(tmfc_DN_GUI,'Style','text','String','Parallel computations','Units','normalized','Position',[0.048 0.125 0.90 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DN_PAR_pop = uicontrol(tmfc_DN_GUI,'Style','popupmenu','String',set_PAR,'Units','normalized','Position',[0.048 0.045 0.90 0.073],'fontunits','normalized','fontsize',0.208);

% OK and Help Buttons 
DN_OK = uicontrol(tmfc_DN_GUI,'Style','pushbutton','String','OK','Units','normalized','Position',[0.16 0.02 0.240 0.04],'FontUnits','normalized','fontsize',0.38,'callback',@export_options);
DN_HELP = uicontrol(tmfc_DN_GUI,'Style','pushbutton','String','Help','Units','normalized','Position',[0.6 0.02 0.240 0.04],'FontUnits','normalized','fontsize',0.38,'callback',@help_options);

% Enter the number of PCs for aCompCor
function ACC_value(~,~)
    approach = (DN_ACC_pop.String{DN_ACC_pop.Value});
    if strcmp(approach,'Add fixed number of aCompCor regressors')
        set(DN_ACC_E1,'enable','on');
        set(DN_ACC_E2,'enable','on');
        set(DN_ACC_txt_2,'enable','on');
        set(DN_ACC_txt_3,'enable','on');
        set(DN_ACC_E1,'String','5');
        set(DN_ACC_E2,'String','5');
        set(DN_ACC_PO_pop, 'enable', 'on');
        options.aCompCor = [5 5];
        
    elseif strcmp(approach, 'Add regressors explaining 50% of variance in WM/CSF (aCompCor50)')
        set(DN_ACC_E1,'enable','off');
        set(DN_ACC_E2,'enable','off');
        set(DN_ACC_txt_2,'enable','off');
        set(DN_ACC_txt_3,'enable','off');
        set(DN_ACC_E1,'String','0.5');
        set(DN_ACC_E2,'String','0.5');
        set(DN_ACC_PO_pop, 'enable', 'on');
        
        options.aCompCor = [0.5 0.5];
        
    elseif strcmp(approach,'None')
        set(DN_ACC_E1,'enable','off');
        set(DN_ACC_E2,'enable','off');
        set(DN_ACC_txt_2,'enable','off');
        set(DN_ACC_txt_3,'enable','off');
        set(DN_ACC_E1,'String','0');
        set(DN_ACC_E2,'String','0');
        set(DN_ACC_PO_pop, 'enable', 'off');
        options.aCompCor = [0 0];
        options.aCompCor_ort = 0;
    end
end

function ACC_PO_value(~,~)
    approach = (DN_ACC_PO_pop.String{DN_ACC_PO_pop.Value});
    if strcmp(approach, 'Pre-orthogonalize w.r.t. HMP and HPF')
        options.aCompCor_ort = 1;
    else
        options.aCompCor_ort = 0;
    end    
end

% Close GUI
function close_options_GUI(~,~)
    options = [];
    uiresume(tmfc_DN_GUI);
end

% Help GUI window
function help_options(~,~)
    tmfc_denoise_help();
end

% Export options
function export_options(~,~)
    
    % Head motion parameters (HMP)
    HMP_select{1} = get(DN_HMP_pop,'String');
    HMP_select{2} = get(DN_HMP_pop,'Value');    
    if strcmp(HMP_select{1}{HMP_select{2}},'Add 6 temporal derivatives and 12 quadratic terms (24HMP)')
    	options.motion = '24HMP';
    elseif strcmp(HMP_select{1}{HMP_select{2}},'Add 6 temporal derivatives (12HMP)')
    	options.motion = '12HMP';       
    elseif strcmp(HMP_select{1}{HMP_select{2}},'Use standard 6 head motion parameters (6HMP)')
    	options.motion = '6HMP';       
    end
    clear HMP_select
    
    % Framewise displacement (FD): motion regressors 
    trans_idx = str2double(strsplit(strtrim(get(DN_FD_TR_E,'String'))));
    rot_idx = str2double(strsplit(strtrim(get(DN_FD_RR_E,'String'))));
        
    if size(trans_idx, 2) ~= 3 || size(rot_idx, 2) ~= 3
        error('You must enter exactly three indices for both translational and rotational regressors. Please try again.');
    elseif ~all(trans_idx == floor(trans_idx) & trans_idx> 0)
        error('Please enter positive integers for translational regressors.');
    elseif ~all(rot_idx == floor(rot_idx) & rot_idx > 0)
        error('Please enter positive integers for rotational regressors.');
    elseif length(trans_idx) ~= length(unique(trans_idx))
        error('Translational indices must be unique. Please re-enter.');
    elseif length(rot_idx) ~= length(unique(rot_idx))
        error('Rotational indices must be unique. Please re-enter.');    
    elseif any(ismember(trans_idx, rot_idx))
        error('Translational and rotational indices must not overlap. Please re-enter.');
    else
        options.translation_idx = trans_idx;
        options.rotation_idx = rot_idx;
    end

    FD_select_2{1} = get(DN_FD_pop_2,'String');
    FD_select_2{2} = get(DN_FD_pop_2,'Value');            
    if strcmp(FD_select_2{1}{FD_select_2{2}},'Radians (e.g., SPM, FSL, fMRIPrep)')
    	options.rotation_unit = 'rad';
    elseif strcmp(FD_select_2{1}{FD_select_2{2}},'Degrees (e.g., HCP, AFNI)')
    	options.rotation_unit = 'deg';                   
    end
    clear FD_select_2    
    
    % Derivative of root mean square variance over voxels (DVARS)
    DVARS_select{1} = get(DN_DVARS_pop, 'String');
    DVARS_select{2} = get(DN_DVARS_pop, 'Value');
    if strcmp(DVARS_select{1}{DVARS_select{2}}, 'Calculate DVARS and FD-DVARS correlations')
        options.DVARS = 1;
    else
        options.DVARS = 0;
    end
    
    % Anatomical component correction (aCompCor)
    ACC_select{1} = get(DN_ACC_pop,'String');
    ACC_select{2} = get(DN_ACC_pop,'Value');            
    if strcmp(ACC_select{1}{ACC_select{2}},'Add fixed number of aCompCor regressors')
        nPC_WM = str2double(get(DN_ACC_E1,'String'));
        nPC_CSF = str2double(get(DN_ACC_E2,'String'));                  
        if isnan(nPC_WM) || isnan(nPC_CSF)
            error('Please enter positive integers for the WM/CSF number of PCs.');
        elseif ~(nPC_WM > 0 && floor(nPC_WM) == nPC_WM) || ~(nPC_CSF > 0 && floor(nPC_CSF) == nPC_CSF)
            error('Please enter natural numbers for WM/CSF PCs.');
        elseif (nPC_WM > 100) || (nPC_CSF > 100)
            error('The number of principal components must be between 1 and 100. Please re-enter.'); 
        else
            options.aCompCor = [nPC_WM nPC_CSF];
        end
        
    elseif strcmp(ACC_select{1}{ACC_select{2}}, 'Add regressors explaining 50% of variance in WM/CSF (aCompCor50)')
        options.aCompCor = [0.5 0.5];

    elseif strcmp(ACC_select{1}{ACC_select{2}},'None')
    	options.aCompCor = [0 0];                   
    end
    clear ACC_select    

    % Robust weighted least squares (rWLS)
    rWLS_select{1} = get(DN_rWLS_pop,'String');
    rWLS_select{2} = get(DN_rWLS_pop,'Value'); 
    if strcmp(rWLS_select{1}{rWLS_select{2}},'Apply rWLS for model estimation')
        options.rWLS = 1;
    elseif strcmp(rWLS_select{1}{rWLS_select{2}},'None')
        options.rWLS = 0;
    end
    
    % Spike Regression (SpikeReg)
    SR_select{1} = get(DN_SR_pop,'String');
    SR_select{2} = get(DN_SR_pop,'Value');            
    if strcmp(SR_select{1}{SR_select{2}},'None')
    	options.spikereg = 0;
    elseif strcmp(SR_select{1}{SR_select{2}},'Add spike regressors')
    	options.spikereg = 1;                   
    end
    clear SR_select    
    
    % WM/CSF regression (Phys)
    WM_CSM_select{1} = get(DN_WM_CSM_pop,'String');
    WM_CSM_select{2} = get(DN_WM_CSM_pop,'Value');            
    if strcmp(WM_CSM_select{1}{WM_CSM_select{2}},'None')
    	options.WM_CSF = 'none';
    elseif strcmp(WM_CSM_select{1}{WM_CSM_select{2}},'Add WM and CSF signals (2Phys)')
    	options.WM_CSF = '2Phys';        
    elseif strcmp(WM_CSM_select{1}{WM_CSM_select{2}},'Add WM and CSF signals along with their temporal derivatives (4Phys)')
    	options.WM_CSF = '4Phys';        
    elseif strcmp(WM_CSM_select{1}{WM_CSM_select{2}},'Add WM and CSF signals, 2 derivatives, and 4 quadratic terms (8Phys)')
    	options.WM_CSF = '8Phys';                   
    end
    clear WM_CSM_select    
    
    % Global signal regression (GSR)
    GSR_select{1} = get(DN_GSR_pop,'String');
    GSR_select{2} = get(DN_GSR_pop,'Value');
    if strcmp(GSR_select{1}{GSR_select{2}},'None')
    	options.GSR = 'none';
    elseif strcmp(GSR_select{1}{GSR_select{2}},'Add whole-brain signal (GSR)')
    	options.GSR = 'GSR';        
    elseif strcmp(GSR_select{1}{GSR_select{2}},'Add whole-brain signal and its temporal derivative (2GSR)')
    	options.GSR = '2GSR';        
    elseif strcmp(GSR_select{1}{GSR_select{2}},'Add whole-brain signal, its temporal derivative, and 2 quadratic terms (4GSR)')
    	options.GSR = '4GSR';                   
    end
    clear GSR_select
    
    % Parallel computations
    PAR_select{1}  = get(DN_PAR_pop, 'String');
    PAR_select{2}  = get(DN_PAR_pop, 'Value');
    if strcmp(PAR_select{1}{PAR_select{2}},'None')
        options.parallel = 0;
    elseif strcmp(PAR_select{1}{PAR_select{2}},'Enable parallel computations')
        options.parallel = 1;
    end
    
    disp('Denoising options selected.');
    uiresume(tmfc_DN_GUI);
end

uiwait(tmfc_DN_GUI);
delete(tmfc_DN_GUI);
end
function tmfc_denoise_help()

HMP_str = {'Motion parameters are taken from the SPM.mat file (user-specified regressors of no interest; see SPM.Sess.C.C). Temporal derivatives are computed as backward differences (Van Dijk et al., 2012). Quadratic terms comprise 6 squared motion parameters and 6 squared temporal derivatives (Satterthwaite et al., 2012). In SPM, HCP, and fMRIPrep the first three motion regressors are translations; in FSL and AFNI the first three are rotations. Adding confound regressors in the SPM batch changes the indices of the motion regressors defined via "Multiple regressors" *.txt/*.mat file (they appear last in SPM.Sess.C).'};
FD_str = {'FD is computed at each time point as the sum of the absolute values of the derivatives of translational and rotational motion parameters (Power et al., 2012).'};
DVARS_str = {'DVARS is computed as the root mean square of the differentiated BOLD time series within the GM mask, before and after denoising (Muschelli et al., 2014). Additionally, the FD-DVARS correlation is computed. A low FD-DVARS correlation is expected if denoising is successful.'};
AA_str = {'Extract non-neuronal, noise-related principal components (PCs) from WM and CSF signals (Behzadi et al., 2007; Muschelli et al., 2014). This approach performs well in relatively low-motion samples (Parkes et al., 2017). WM and CSF signals can be pre-orthogonalized w.r.t. high-pass filter (HPF) regressors and head motion parameters to improve predictive power (Mascali et al., 2021).'};
rWLS_str = {'In the first pass, the rWLS algorithm estimates the noise variance of each image. In the second pass, images are weighted by 1/variance rather than being excluded by an arbitrary threshold. This yields a "soft" down-weighting: the higher an image''s variance, the smaller its influence on the results (Diedrichsen and Shadmehr, 2005).'};
SR_str = {'For each flagged time point, a unit impulse (1 at that time point, 0 elsewhere) is included as a spike regressor (Lemieux et al., 2007; Satterthwaite et al., 2012). Spike regression combined with WM/CSF regression performs well in high-motion samples (Parkes et al., 2017).'};
WM_CSM_str = {'Extract average WM/CSF signals to account for physiological fluctuations of non-neuronal origin (Fox et al., 2005). Optionally, calculate derivatives, squares, and squared derivatives (Parkes et al., 2017).'};
GSR_str = {'Extract the average whole-brain signal to account for head motion and physiological fluctuations of non-neuronal origin (Fox et al., 2005, 2009). Optionally calculate derivatives, squares, and squared derivatives (Parkes et al., 2017). Note that GSR may also remove BOLD signal fluctuations of neuronal origin (Chen et al., 2012) and can introduce spurious negative correlations (Murphy et al., 2008).'};

tmfc_DN_help = figure('Name','TMFC denoise: Help','MenuBar', 'none', 'ToolBar', 'none','NumberTitle', 'off', 'Units', 'norm', 'Position', [0.3 0.065 0.40 0.850], 'color', 'w', 'Tag', 'tmfc_DN_help','resize','on','WindowStyle','Modal');
movegui(tmfc_DN_help, 'center');

DNH_MP_1 = uipanel(tmfc_DN_help,'Units','normalized','Position',[0.025 0.835 0.95 0.155],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DNH_MP_2 = uipanel(tmfc_DN_help,'Units','normalized','Position',[0.025 0.750 0.95 0.079],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DNH_MP_3 = uipanel(tmfc_DN_help,'Units','normalized','Position',[0.025 0.648 0.95 0.096],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DNH_MP_4 = uipanel(tmfc_DN_help,'Units','normalized','Position',[0.025 0.506 0.95 0.135],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DNH_MP_5 = uipanel(tmfc_DN_help,'Units','normalized','Position',[0.025 0.385 0.95 0.115],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DNH_MP_6 = uipanel(tmfc_DN_help,'Units','normalized','Position',[0.025 0.284 0.95 0.095],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DNH_MP_7 = uipanel(tmfc_DN_help,'Units','normalized','Position',[0.025 0.200 0.95 0.078],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
DNH_MP_8 = uipanel(tmfc_DN_help,'Units','normalized','Position',[0.025 0.079 0.95 0.115],'HighlightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');

if isunix; fontscale = 0.85; else; fontscale = 1; end

DNH_HMP_txt = uicontrol(tmfc_DN_help,'Style','text','String','Head motion parameters (HMP)','Units','normalized','Position',[0.048 0.962 0.9 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DNH_HMP_des = uicontrol(tmfc_DN_help,'Style','text','String',HMP_str,'Units','normalized','Position',[0.048 0.837 0.9 0.120],'fontunits','normalized','fontsize',0.13*fontscale,'HorizontalAlignment','left','backgroundcolor','w');

DNH_FD_txt = uicontrol(tmfc_DN_help,'Style','text','String','Framewise displacement (FD)','Units','normalized','Position',[0.048 0.800 0.5 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DNH_FD_des = uicontrol(tmfc_DN_help,'Style','text','String',FD_str,'Units','normalized','Position',[0.048 0.751 0.9 0.045],'fontunits','normalized','fontsize',0.33*fontscale,'HorizontalAlignment','left','backgroundcolor','w');
 
DNH_DVARS_txt = uicontrol(tmfc_DN_help,'Style','text','String','Derivative of root mean square variance over voxels (DVARS)','Units','normalized','Position',[0.048 0.716 0.9 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DNH_DVARS_des = uicontrol(tmfc_DN_help,'Style','text','String',DVARS_str,'Units','normalized','Position',[0.048 0.651 0.9 0.062],'fontunits','normalized','fontsize',0.24*fontscale,'HorizontalAlignment','left','backgroundcolor','w');
 
DNH_ACC_txt = uicontrol(tmfc_DN_help,'Style','text','String','Anatomical component correction (aCompCor)','Units','normalized','Position',[0.048 0.611 0.9 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DNH_ACC_des = uicontrol(tmfc_DN_help,'Style','text','String',AA_str,'Units','normalized','Position',[0.048 0.508 0.9 0.10],'fontunits','normalized','fontsize',0.15*fontscale,'HorizontalAlignment','left','backgroundcolor','w');
  
DNH_rWLS_txt = uicontrol(tmfc_DN_help,'Style','text','String','Robust weighted least squares (rWLS)','Units','normalized','Position',[0.048 0.471 0.9 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DNH_rWLS_des = uicontrol(tmfc_DN_help,'Style','text','String',rWLS_str,'Units','normalized','Position',[0.048 0.388 0.9 0.08],'fontunits','normalized','fontsize',0.19*fontscale,'HorizontalAlignment','left','backgroundcolor','w');
 
DNH_SR_txt = uicontrol(tmfc_DN_help,'Style','text','String','Spike regression (SpikeReg)','Units','normalized','Position',[0.048 0.351 0.90 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DNH_SR_des = uicontrol(tmfc_DN_help,'Style','text','String',SR_str,'Units','normalized','Position',[0.048 0.286 0.9 0.062],'fontunits','normalized','fontsize',0.24*fontscale,'HorizontalAlignment','left','backgroundcolor','w');
 
DNH_WM_CSM_txt = uicontrol(tmfc_DN_help,'Style','text','String','WM and CSF signal regression (Phys)','Units','normalized','Position',[0.048 0.251 0.90 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DNH_WM_CSM_des = uicontrol(tmfc_DN_help,'Style','text','String',WM_CSM_str,'Units','normalized','Position',[0.048 0.204 0.9 0.045],'fontunits','normalized','fontsize',0.33*fontscale,'HorizontalAlignment','left','backgroundcolor','w');
 
DNH_GSR_txt = uicontrol(tmfc_DN_help,'Style','text','String','Global signal regression (GSR)','Units','normalized','Position',[0.048 0.166 0.90 0.021],'fontunits','normalized','fontsize',0.80,'HorizontalAlignment','left','fontweight','bold','backgroundcolor','w');
DNH_GSR_des = uicontrol(tmfc_DN_help,'Style','text','String',GSR_str,'Units','normalized','Position',[0.048 0.084 0.9 0.08],'fontunits','normalized','fontsize',0.19*fontscale,'HorizontalAlignment','left','backgroundcolor','w');
 
DNH_OK = uicontrol(tmfc_DN_help,'Style','pushbutton','String','OK','Units','normalized','Position',[0.365 0.02 0.240 0.04],'FontUnits','normalized','fontsize',0.38,'callback',@close_window);

    function close_window(~,~)
       close(tmfc_DN_help);
    end
end
