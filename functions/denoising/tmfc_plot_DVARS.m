function tmfc_plot_DVARS(preDVARS,postDVARS,FD,options,SPM_paths,subject_paths,anat_paths,func_paths,masks)

% =======[ Task-Modulated Functional Connectivity Denoise Toolbox ]========
% 
% Opens a GUI with FD-DVARS plots before and after noise regression.
%
% FORMAT: tmfc_plot_DVARS(preDVARS,postDVARS,FD)
% Allows saving group FD-DVARS statistics only.
%
% FORMAT: tmfc_plot_DVARS(preDVARS,postDVARS,FD,options,SPM_paths,subject_paths,anat_paths,func_paths,masks)
% Allows saving group FD-DVARS statistics and TMFC denoise settings.
%
% =========================================================================
% Copyright (C) 2025 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru


% FD-DVARS input only
if nargin == 3
    options = []; SPM_paths = []; subject_paths = []; anat_paths = []; func_paths = []; masks = [];
end

hasRWLS = isstruct(options) && isfield(options,'rWLS') && options.rWLS==1;

if hasRWLS
    DVARS_label = 'DVARS_{GM} (normalized)';        
else
    DVARS_label = 'DVARS_{GM} (de-meaned)';
end

% GUI elements
DVARS_MW = figure('Name','Framewise displacement and DVARS','NumberTitle','off','Units','normalized','Position',[0.25 0.09 0.50 0.80],'MenuBar','none','ToolBar','none','Color','w','CloseRequestFcn',@DVARS_MW_exit);
DVARS_MW_txt = uicontrol(DVARS_MW,'Style','text','String','Select subject:','Units','normalized','Position',[0.075 0.94 0.85 0.038],'fontunits','normalized','FontSize',0.55,'HorizontalAlignment','Left','backgroundcolor','w');
DVARS_MW_LB1 = uicontrol(DVARS_MW,'Style','listbox','String',[],'Max',1,'Value',1,'Units','normalized','Position',[0.075 0.76 0.85 0.180],'FontUnits','points','FontSize',12,'callback',@update_plot);
movegui(DVARS_MW,'center');

% Create axes for FD plot
ax_frame_1 = axes('Parent',DVARS_MW,'Units','normalized','Position',[0.075 0.53 .85 .2],'Color',[0.75 0.75 0.75]);
box(ax_frame_1,'on'); xlabel(ax_frame_1,'Scans','FontSize',9); ylabel(ax_frame_1,'FD, [mm]','FontSize',9); 

% Create axes for DVARS plot
ax_frame_2 = axes('Parent',DVARS_MW,'Units','normalized','Position',[0.075 0.23 .85 .25],'Color',[0.75 0.75 0.75]);
box(ax_frame_2,'on');  xlabel(ax_frame_2,'Scans','FontSize',9); ylabel(ax_frame_2,DVARS_label,'FontSize',9);

% Statistics, Save & Ok buttons
DVARS_MW_LB2 = uicontrol(DVARS_MW,'Style','listbox','Enable','inactive','String',[],'min', 1, 'max', 3,'Value',[],'Units','normalized','Position',[0.075 0.090 0.85 0.075],'FontUnits','points','FontSize',12,'callback',@update_plot);

DVARS_MW_OK = uicontrol(DVARS_MW,'Style','pushbutton','String','OK', ...
    'Units','normalized','Position',[0.09 0.03 0.15 0.045], ...
    'FontUnits','normalized','FontSize',0.34,'callback',@DVARS_MW_exit);

DVARS_MW_SAVE = uicontrol(DVARS_MW,'Style','pushbutton','String','Save', ...
    'Units','normalized','Position',[0.32 0.03 0.15 0.045], ...
    'FontUnits','normalized','FontSize',0.34,'callback',@save_data);

DVARS_MW_REPORT = uicontrol(DVARS_MW,'Style','pushbutton','String','Report', ...
    'Units','normalized','Position',[0.54 0.03 0.15 0.045], ...
    'FontUnits','normalized','FontSize',0.34,'callback',@create_report);

DVARS_MW_QC_PLOTS = uicontrol(DVARS_MW,'Style','pushbutton','String','QC plots', ...
    'Units','normalized','Position',[0.76 0.03 0.15 0.045], ...
    'FontUnits','normalized','FontSize',0.34,'callback',@open_qc_plots);


group_mean_pre_FD_DVARS_corr = 0; group_mean_post_FD_DVARS_corr = 0;
group_SD_pre_FD_DVARS_corr = 0; group_SD_post_FD_DVARS_corr = 0;

% Initial plotting for subject 1
plot_data(1);

% Close GUI
%--------------------------------------------------------------------------
function DVARS_MW_exit(~,~)
    uiresume(DVARS_MW);
end

% Select subject from the list
%--------------------------------------------------------------------------
function update_plot(~,~)
    selected_subject = get(DVARS_MW_LB1,'Value');
    plot_data(selected_subject); 
end

% Update plot for selected subject
%--------------------------------------------------------------------------
function plot_data(iSub)
    
    if exist('ax_frame_1','var') && ishandle(ax_frame_1), delete(ax_frame_1); end
    if exist('ax_frame_2','var') && ishandle(ax_frame_2), delete(ax_frame_2); end
    
    % Prepare FD and DVARS time series -------------------------------------
    FD_ts = []; preDVARS_ts = []; postDVARS_ts = [];
    sess_sum = 0; sess = 0;
    for jSess = 1:length(FD(iSub).Sess)
        FD_ts = [FD_ts; FD(iSub).Sess(jSess).FD_ts];
        if hasRWLS
            preDVARS_ts = [preDVARS_ts; NaN(3,1); tmfc_zscore(preDVARS(iSub).DVARS.Sess(jSess).DVARS_ts(4:end-1)); NaN];
        else
            preDVARS_ts = [preDVARS_ts; NaN(3,1); spm_detrend(preDVARS(iSub).DVARS.Sess(jSess).DVARS_ts(4:end-1)); NaN];
        end
        if ~isempty(postDVARS)
            if hasRWLS
                postDVARS_ts = [postDVARS_ts; NaN(3,1); tmfc_zscore(postDVARS(iSub).DVARS.Sess(jSess).DVARS_ts(4:end-1)); NaN];
            else
                postDVARS_ts = [postDVARS_ts; NaN(3,1); spm_detrend(postDVARS(iSub).DVARS.Sess(jSess).DVARS_ts(4:end-1)); NaN];
            end
        end
        sess_sum = sess_sum + length(FD(iSub).Sess(jSess).FD_ts) + 1;
        sess = [sess; sess_sum];
    end

    % Plotting FD
    ax_frame_1 = axes('Parent',DVARS_MW,'Units','normalized','Position',[0.075 0.53 .85 .2],'Color',[0.75 0.75 0.75]);
    box(ax_frame_1,'on'); xlabel(ax_frame_1,'Scans','FontSize',9); ylabel(ax_frame_1,'FD, [mm]','FontSize',9);
    S1 = plot(ax_frame_1, FD_ts,'Color',[0 0.447 0.7410]); xlabel(ax_frame_1,'Scans'); ylabel(ax_frame_1,'FD, [mm]'); xlim(ax_frame_1,'tight'); x = xlim(ax_frame_1); y = ylim(ax_frame_1); hold(ax_frame_1,'on');
    
    % Plot sessions
    for jSess = 1:length(FD(iSub).Sess)
        if jSess>1
            S1 = plot(ax_frame_1, [sess(jSess) sess(jSess)],[y(1) y(2)],'-k');
        end
        text(ax_frame_1,sess(jSess)+10,y(2),{['Run ' num2str(jSess)]},'VerticalAlignment','top'); hold(ax_frame_1,'on');
    end
    
    
    % DVARS Plot ----------------------------------------------------------
    if isempty(postDVARS)
        tmp = preDVARS_ts;
    else
        tmp = [preDVARS_ts; postDVARS_ts];
    end
    tmp(isnan(tmp)) = [];
    y1 = max(tmp); y2 = min(tmp);

    ax_frame_2 = axes('Parent',DVARS_MW,'Units','normalized','Position',[0.075 0.23 .85 .25],'Color',[0.75 0.75 0.75]);
    box(ax_frame_2,'on'); xlabel(ax_frame_2,'Scans','FontSize',9); ylabel(ax_frame_2,DVARS_label,'FontSize',9); 
    plot(ax_frame_2,preDVARS_ts,'Color',[0 0.447 0.7410]); hold(ax_frame_2,'on'); xlabel(ax_frame_2,'Scans'); ylabel(ax_frame_2,DVARS_label); xlim(ax_frame_2,'tight');  ylim(ax_frame_2,[y2*1.3 y1*1.1]); x = xlim(ax_frame_2);
    if ~isempty(postDVARS)
        plot(ax_frame_2,postDVARS_ts,'Color',[0.8500 0.3250 0.0980]); hold(ax_frame_2,'on');
    end
    
    for jSess = 1:length(FD(iSub).Sess)
        if jSess>1
            plot(ax_frame_2, [sess(jSess) sess(jSess)],[y2*1.3 y1*1.1],'-k');
        end
        text(ax_frame_2,sess(jSess)+10,y1*1.1,{['Run ' num2str(jSess)]},'VerticalAlignment','top'); hold(ax_frame_2,'on');
    end
    
    text(ax_frame_2,x(2)+2,y1*0.5,{'Before'},'Color',[0 0.447 0.7410]); hold(ax_frame_2,'on');
    if ~isempty(postDVARS)
        text(ax_frame_2,x(2)+2,0,{'After'},'Color',[0.8500 0.3250 0.0980]);
    end
    
    update_txt();
end

% Update text info
%--------------------------------------------------------------------------
function update_txt(~,~)
    % Function to update subjects list and mean corr text
    LB1_str = {}; temp_str = {};
    for iSub = 1:length(FD)
        if ~isempty(postDVARS)
            temp_str = [FD(iSub).Subject ' :: Mean FD-DVARS correlation: [before/after denoising] = [' ...
                              num2str(round(preDVARS(iSub).DVARS.Mean_FD_DVARS_corr,2),'%.2f') '/' ...
                              num2str(round(postDVARS(iSub).DVARS.Mean_FD_DVARS_corr,2),'%.2f') ']']; 
        else
            temp_str = [FD(iSub).Subject ' :: Mean FD-DVARS correlation: [before denoising] = [' ...
                              num2str(round(preDVARS(iSub).DVARS.Mean_FD_DVARS_corr,2),'%.2f') ']']; 
        end
        LB1_str = [LB1_str; {temp_str}];
    end
    set(DVARS_MW_LB1,'String',LB1_str);
    
    % Mean correlation calculation and text generation
    pre_FD_DVARS_corr = []; post_FD_DVARS_corr = [];
    for iSub = 1:length(FD)
        pre_FD_DVARS_corr = [pre_FD_DVARS_corr preDVARS(iSub).DVARS.Mean_FD_DVARS_corr];
        if ~isempty(postDVARS)
            post_FD_DVARS_corr = [post_FD_DVARS_corr postDVARS(iSub).DVARS.Mean_FD_DVARS_corr];
        end
    end
    group_mean_pre_FD_DVARS_corr = mean(pre_FD_DVARS_corr);
    group_SD_pre_FD_DVARS_corr = std(pre_FD_DVARS_corr);
    if ~isempty(postDVARS)
        group_mean_post_FD_DVARS_corr = mean(post_FD_DVARS_corr);
        group_SD_post_FD_DVARS_corr = std(post_FD_DVARS_corr);
    else
        group_mean_post_FD_DVARS_corr = [];
        group_SD_post_FD_DVARS_corr = [];
    end

    text_info{1,1} = ['Mean (SD) FD-DVARS correlation across subjects before denoising: ' num2str(round(group_mean_pre_FD_DVARS_corr,2),'%.2f') ' (' num2str(round(group_SD_pre_FD_DVARS_corr,2),'%.2f') ')'];
    if ~isempty(postDVARS)
        text_info{1,2} = ['Mean (SD) FD-DVARS correlation across subjects after denoising: ' num2str(round(group_mean_post_FD_DVARS_corr,2),'%.2f') ' (' num2str(round(group_SD_post_FD_DVARS_corr,2),'%.2f') ')'];
    end

    set(DVARS_MW_LB2,'String',text_info);    
end

%--------------------------------------------------------------------------
% Save group statistics & user-specified TMFC denoise settings
%--------------------------------------------------------------------------
function save_data(~,~)
    if isempty(SPM_paths)
        [filename, pathname] = uiputfile('*.mat', 'Save FD-DVARS group statistics');
        if isequal(filename,0) || isequal(pathname,0)
            fprintf(2,'FD-DVARS group statistics not saved: file name or path not selected.\n'); 
        else
            fullpath = fullfile(pathname, filename);
            save(fullpath,'FD','preDVARS','postDVARS', ...
                'group_mean_pre_FD_DVARS_corr','group_mean_post_FD_DVARS_corr', ...
                'group_SD_pre_FD_DVARS_corr','group_SD_post_FD_DVARS_corr');
            fprintf('FD-DVARS group statistics saved: %s\n', fullpath);
        end
    else   
        [filename, pathname] = uiputfile('*.mat', 'Save FD-DVARS group statistics and TMFC denoise settings');
        if isequal(filename,0) || isequal(pathname,0)
            fprintf(2,'FD-DVARS group statistics not saved: file name or path not selected.\n'); 
        else
            fullpath = fullfile(pathname, filename);
            denoising_settings.SPM_paths = SPM_paths;
            denoising_settings.subject_paths = subject_paths;
            denoising_settings.options = options;
            denoising_settings.anat_paths = anat_paths;
            denoising_settings.func_paths = func_paths; 
            denoising_settings.masks = masks; 
            save(fullpath,'denoising_settings','FD','preDVARS','postDVARS', ...
                'group_mean_pre_FD_DVARS_corr','group_mean_post_FD_DVARS_corr', ...
                'group_SD_pre_FD_DVARS_corr','group_SD_post_FD_DVARS_corr');
            fprintf('FD-DVARS group statistics and TMFC denoise settings saved: %s\n', fullpath);
        end
    end
end

%--------------------------------------------------------------------------
% Create denoising and QC report
%--------------------------------------------------------------------------
function create_report(~,~)

    if isempty(SPM_paths) || isempty(options)
        errordlg(['The report can be created only when tmfc_plot_DVARS is called ', ...
                  'with denoising settings, paths, and masks.'], ...
                  'TMFC denoise report');
        fprintf(2,'TMFC_denoise report was not created: denoising settings are missing.\n');
        return
    end

    update_txt();

    % Build report as one plain text string
    report_txt = build_report_text();

    % Convert text string to cell array of lines for proper GUI display
    report_lines = regexp(report_txt, '\r\n|\n|\r', 'split')';
    if ~isempty(report_lines) && isempty(report_lines{end})
        report_lines(end) = [];
    end

    % Report GUI window
    REPORT_W = figure('Name','TMFC_denoise report', ...
        'NumberTitle','off', ...
        'Units','normalized', ...
        'Position',[0.23 0.08 0.54 0.82], ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Color','w', ...
        'WindowStyle','normal');

    movegui(REPORT_W,'center');

    uicontrol(REPORT_W,'Style','text', ...
        'String','TMFC_denoise report. Select the text below to copy it, or press Save to write a .txt file.', ...
        'Units','normalized', ...
        'Position',[0.04 0.94 0.92 0.035], ...
        'FontUnits','normalized', ...
        'FontSize',0.50, ...
        'HorizontalAlignment','left', ...
        'BackgroundColor','w');

    REPORT_EDIT = uicontrol(REPORT_W,'Style','edit', ...
        'String',report_lines, ...
        'Units','normalized', ...
        'Position',[0.04 0.10 0.92 0.83], ...
        'Min',0, ...
        'Max',2, ...
        'HorizontalAlignment','left', ...
        'FontName','Consolas', ...
        'FontSize',10, ...
        'BackgroundColor','w');

    uicontrol(REPORT_W,'Style','pushbutton', ...
        'String','Save', ...
        'Units','normalized', ...
        'Position',[0.32 0.035 0.16 0.045], ...
        'FontUnits','normalized', ...
        'FontSize',0.34, ...
        'Callback',@save_report_txt);

    uicontrol(REPORT_W,'Style','pushbutton', ...
        'String','Close', ...
        'Units','normalized', ...
        'Position',[0.52 0.035 0.16 0.045], ...
        'FontUnits','normalized', ...
        'FontSize',0.34, ...
        'Callback',@close_report_window);

    function save_report_txt(~,~)

        [filename, pathname] = uiputfile('*.txt','Save TMFC_denoise report','TMFC_denoise_report.txt');

        if isequal(filename,0) || isequal(pathname,0)
            fprintf(2,'TMFC_denoise report was not saved: file name or path not selected.\n');
            return
        end

        fullpath = fullfile(pathname,filename);

        % Use UTF-8 to avoid encoding problems in Windows/Notepad.
        fid = fopen(fullpath,'w','n','UTF-8');
        if fid == -1
            errordlg(['Could not create report file: ' fullpath],'TMFC denoise report');
            fprintf(2,'Could not create report file: %s\n',fullpath);
            return
        end

        fprintf(fid,'%s',report_txt);
        fclose(fid);

        fprintf('TMFC_denoise report saved: %s\n',fullpath);
    end

    function close_report_window(~,~)
        if ishghandle(REPORT_W)
            close(REPORT_W);
        end
    end
end

%--------------------------------------------------------------------------
% Build report text
%--------------------------------------------------------------------------
function report_txt = build_report_text()

    toolbox_version = 'v1.5.0';
    generated_on = datestr(now,'yyyy-mm-dd HH:MM:SS');

    pipeline_str = get_pipeline_string();

    FD_summary       = get_FD_summary();
    DVARS_summary    = get_DVARS_summary();
    task_summary     = get_task_summary();
    spike_summary    = get_spike_summary();
    acompcor_summary = get_acompcor_summary();
    reg_summary      = get_regressor_summary(spike_summary,acompcor_summary);

    L = {};

    L = add_line(L,'TMFC_denoise report');
    L = add_line(L,['Generated by TMFC_denoise ' toolbox_version]);
    L = add_line(L,['Generated on: ' generated_on]);
    L = add_line(L,'');
    L = add_line(L,'============================================================');
    L = add_line(L,'SHORT REPORT');
    L = add_line(L,'============================================================');
    L = add_line(L,'');
    L = add_line(L,get_short_methods_text(pipeline_str,FD_summary,DVARS_summary,task_summary,spike_summary,acompcor_summary,reg_summary));
    L = add_line(L,'');
    L = add_line(L,'============================================================');
    L = add_line(L,'FULL REPORT');
    L = add_line(L,'============================================================');
    L = add_line(L,'');
    L = add_line(L,'DENOISING OPTIONS');
    L = add_line(L,'------------------------------------------------------------');
    L = add_line(L,['Selected pipeline: ' pipeline_str]);
    L = add_line(L,['Head motion model: ' options.motion]);
    L = add_line(L,['Rotation unit: ' options.rotation_unit]);
    L = add_line(L,['Head radius for FD calculation: ' num2str(options.head_radius) ' mm']);

    if options.rWLS == 1
        L = add_line(L,'rWLS: enabled');
    else
        L = add_line(L,'rWLS: disabled');
    end

    if options.spikereg == 1
        L = add_line(L,['Spike regression: enabled, FD > ' fmt(options.spikeregFDthr,2) ' mm']);
    else
        L = add_line(L,'Spike regression: disabled');
    end

    if sum(options.aCompCor) ~= 0
        if options.aCompCor(1) == 0.5
            L = add_line(L,'aCompCor: aCompCor50');
        else
            L = add_line(L,['aCompCor: fixed number of PCs, WM = ' num2str(options.aCompCor(1)) ', CSF = ' num2str(options.aCompCor(2))]);
        end

        if options.aCompCor_ort == 1
            L = add_line(L,'aCompCor pre-orthogonalization: enabled with respect to HMP and HPF regressors');
        else
            L = add_line(L,'aCompCor pre-orthogonalization: disabled');
        end
    else
        L = add_line(L,'aCompCor: disabled');
    end

    L = add_line(L,['WM/CSF signal regression: ' options.WM_CSF]);
    L = add_line(L,['Global signal regression: ' options.GSR]);
    L = add_line(L,'');

    L = add_line(L,'MASK PARAMETERS');
    L = add_line(L,'------------------------------------------------------------');

    if isfield(options,'GMmask')
        L = add_line(L,['GM probability threshold for DVARS mask: ' fmt(options.GMmask.prob,2)]);
        L = add_line(L,'GM mask used for DVARS: not dilated');
    else
        L = add_line(L,'GM mask parameters: not available');
    end

    if use_wm_csf_masks()
        if isfield(options,'WMmask')
            L = add_line(L,['WM probability threshold: ' fmt(options.WMmask.prob,2)]);
            L = add_line(L,['WM erosion cycles: ' num2str(options.WMmask.erode)]);
        else
            L = add_line(L,'WM mask parameters: not available');
        end

        if isfield(options,'CSFmask')
            L = add_line(L,['CSF probability threshold: ' fmt(options.CSFmask.prob,2)]);
            L = add_line(L,['CSF erosion cycles: ' num2str(options.CSFmask.erode)]);
        else
            L = add_line(L,'CSF mask parameters: not available');
        end

        if isfield(options,'GMmask')
            L = add_line(L,['GM dilation cycles used for CSF-mask refinement: ' num2str(options.GMmask.dilate)]);
            L = add_line(L,'Note: the dilated GM mask is used only to remove voxels adjacent to GM from the CSF mask, not for DVARS calculation.');
        end
    end

    if use_gsr()
        L = add_line(L,'Whole-brain mask: used to extract the global signal for GSR.');
    end

    L = add_line(L,'');

    L = add_line(L,'MOTION SUMMARY');
    L = add_line(L,'------------------------------------------------------------');
    L = add_line(L,['Number of subjects: ' num2str(FD_summary.nSub)]);
    L = add_line(L,['Mean FD across subjects: mean = ' fmt(FD_summary.meanFD.mean,2) ...
                    ' mm, SD = ' fmt(FD_summary.meanFD.sd,2) ...
                    ', range = ' fmt(FD_summary.meanFD.min,2) '-' fmt(FD_summary.meanFD.max,2) ' mm']);
    L = add_line(L,['Maximum FD across subjects: mean = ' fmt(FD_summary.maxFD.mean,2) ...
                    ' mm, SD = ' fmt(FD_summary.maxFD.sd,2) ...
                    ', range = ' fmt(FD_summary.maxFD.min,2) '-' fmt(FD_summary.maxFD.max,2) ' mm']);
    L = add_line(L,['Flagged scans at FD > ' fmt(FD_summary.FDthr,2) ' mm: mean = ' ...
                    fmt(FD_summary.flagged_pct.mean,2) '%, SD = ' fmt(FD_summary.flagged_pct.sd,2) ...
                    ', range = ' fmt(FD_summary.flagged_pct.min,2) '-' fmt(FD_summary.flagged_pct.max,2) '%']);
    L = add_line(L,['Subjects with >25% flagged scans: ' num2str(FD_summary.nSub_25pct) ' of ' num2str(FD_summary.nSub)]);
    L = add_line(L,'');

    L = add_line(L,'TASK-CORRELATED MOTION');
    L = add_line(L,'------------------------------------------------------------');
    L = add_line(L,['Mean signed task-FD correlation across subjects: mean = ' fmt(task_summary.taskFD_mean.mean,2) ...
        ', SD = ' fmt(task_summary.taskFD_mean.sd,2)]);
    L = add_line(L,['Mean absolute task-FD correlation across subjects: mean = ' fmt(task_summary.taskFD_meanabs.mean,2) ...
        ', SD = ' fmt(task_summary.taskFD_meanabs.sd,2)]);
    L = add_line(L,['Maximum absolute task-FD correlation across subjects: mean = ' fmt(task_summary.taskFD_maxabs.mean,2) ...
        ', SD = ' fmt(task_summary.taskFD_maxabs.sd,2) ...
        ', maximum observed = ' fmt(task_summary.taskFD_maxabs.max,2)]);

    if isfield(task_summary,'top_taskFD_unique') && ~isempty(task_summary.top_taskFD_unique)
        L = add_line(L,'Top 5 task regressors by maximum absolute task-FD correlation:');
        for iTop = 1:length(task_summary.top_taskFD_unique)
            L = add_line(L,[num2str(iTop) '. ' task_summary.top_taskFD_unique(iTop).name ...
                ': max |r| = ' fmt(task_summary.top_taskFD_unique(iTop).abs_r,2) ...
                ', signed r = ' fmt(task_summary.top_taskFD_unique(iTop).r,2)]);
        end
    end

    if isfield(task_summary,'top_taskFD') && ~isempty(task_summary.top_taskFD)
        L = add_line(L,'Top 5 individual task-FD correlations:');
        for iTop = 1:length(task_summary.top_taskFD)
            L = add_line(L,[num2str(iTop) '. ' task_summary.top_taskFD(iTop).name ...
                ' | subject = ' task_summary.top_taskFD(iTop).subject ...
                ', run = ' num2str(task_summary.top_taskFD(iTop).run) ...
                ', r = ' fmt(task_summary.top_taskFD(iTop).r,2)]);
        end
    end

    L = add_line(L,'');

    L = add_line(L,'SPIKE REGRESSION SUMMARY');
    L = add_line(L,'------------------------------------------------------------');
    if options.spikereg == 1
        L = add_line(L,['SpikeReg file pattern: SpikeReg_[FDthr_' fmt(options.spikeregFDthr,2) 'mm].mat']);
        L = add_line(L,['Number of spike regressors per subject: mean = ' fmt(spike_summary.nSpike.mean,1) ...
                        ', SD = ' fmt(spike_summary.nSpike.sd,1) ...
                        ', range = ' fmt(spike_summary.nSpike.min,0) '-' fmt(spike_summary.nSpike.max,0)]);
    else
        L = add_line(L,'Spike regression was not selected.');
    end
    L = add_line(L,'');

    L = add_line(L,'ACOMPCOR SUMMARY');
    L = add_line(L,'------------------------------------------------------------');
    if strcmpi(acompcor_summary.type,'none')
        L = add_line(L,'aCompCor was not selected.');
    else
        L = add_line(L,['aCompCor file: ' acompcor_summary.file_name]);

        if strcmpi(acompcor_summary.type,'fixed')
            L = add_line(L,['Fixed WM PCs per run/session: ' num2str(options.aCompCor(1))]);
            L = add_line(L,['Fixed CSF PCs per run/session: ' num2str(options.aCompCor(2))]);
            L = add_line(L,['WM variance explained: mean = ' fmt(acompcor_summary.WM_var.mean,1) ...
                            '%, SD = ' fmt(acompcor_summary.WM_var.sd,1) '%']);
            L = add_line(L,['CSF variance explained: mean = ' fmt(acompcor_summary.CSF_var.mean,1) ...
                            '%, SD = ' fmt(acompcor_summary.CSF_var.sd,1) '%']);
        else
            L = add_line(L,['Total WM PCs per subject: mean = ' fmt(acompcor_summary.WM_nPCs.mean,1) ...
                            ', SD = ' fmt(acompcor_summary.WM_nPCs.sd,1) ...
                            ', range = ' fmt(acompcor_summary.WM_nPCs.min,0) '-' fmt(acompcor_summary.WM_nPCs.max,0)]);
            L = add_line(L,['Total CSF PCs per subject: mean = ' fmt(acompcor_summary.CSF_nPCs.mean,1) ...
                            ', SD = ' fmt(acompcor_summary.CSF_nPCs.sd,1) ...
                            ', range = ' fmt(acompcor_summary.CSF_nPCs.min,0) '-' fmt(acompcor_summary.CSF_nPCs.max,0)]);
            L = add_line(L,'Variance explained: 50% separately for WM and CSF by definition.');
        end
    end
    L = add_line(L,'');

    L = add_line(L,'NUISANCE REGRESSOR SUMMARY');
    L = add_line(L,'------------------------------------------------------------');
    L = add_line(L,['HMP columns in selected nuisance model per run/session: ' num2str(reg_summary.hmp_total)]);
    L = add_line(L,['Additional HMP expansion columns generated by TMFC_denoise per run/session: ' num2str(reg_summary.hmp_added)]);
    L = add_line(L,['Fixed aCompCor regressors per run/session: ' num2str(reg_summary.acompcor_fixed_per_run)]);
    L = add_line(L,['WM/CSF signal regressors per run/session: ' num2str(reg_summary.phys_per_run)]);
    L = add_line(L,['GSR regressors per run/session: ' num2str(reg_summary.gsr_per_run)]);
    L = add_line(L,['Fixed additional regressors per run/session: ' num2str(reg_summary.fixed_per_run)]);

    if reg_summary.total_added.mean == 0 && ~reg_summary.has_variable_regressors
        L = add_line(L,'No additional nuisance regressors were generated by TMFC_denoise.');
    elseif reg_summary.has_variable_regressors
        L = add_line(L,['Total additional TMFC_denoise regressors per subject: mean = ' fmt(reg_summary.total_added.mean,1) ...
                        ', SD = ' fmt(reg_summary.total_added.sd,1) ...
                        ', range = ' fmt(reg_summary.total_added.min,0) '-' fmt(reg_summary.total_added.max,0)]);
        L = add_line(L,'Note: the total number varies across subjects because SpikeReg and/or aCompCor50 was selected.');
    else
        if reg_summary.same_nRuns && reg_summary.nRuns_common == 1
            L = add_line(L,['Total additional TMFC_denoise regressors per subject: ' num2str(reg_summary.fixed_per_run)]);
        elseif reg_summary.same_nRuns
            L = add_line(L,['Total additional TMFC_denoise regressors per subject: ' ...
                            num2str(reg_summary.fixed_per_run * reg_summary.nRuns_common) ...
                            ' across ' num2str(reg_summary.nRuns_common) ' runs/sessions.']);
        else
            L = add_line(L,'Total additional TMFC_denoise regressors per subject varied only because the number of runs/sessions differed across subjects.');
            L = add_line(L,['Total additional TMFC_denoise regressors per subject: mean = ' fmt(reg_summary.total_added.mean,1) ...
                            ', SD = ' fmt(reg_summary.total_added.sd,1) ...
                            ', range = ' fmt(reg_summary.total_added.min,0) '-' fmt(reg_summary.total_added.max,0)]);
        end
    end

    L = add_line(L,'Note: this count excludes regressors already present in the original SPM.mat file, except when explicitly described as the selected HMP model.');
    L = add_line(L,'');

    L = add_line(L,'TASK-DVARS QC SUMMARY');
    L = add_line(L,'------------------------------------------------------------');
    L = add_line(L,['Before denoising, mean signed task-DVARS correlation: mean = ' fmt(task_summary.preTaskDV_mean.mean,2) ...
                    ', SD = ' fmt(task_summary.preTaskDV_mean.sd,2)]);
    L = add_line(L,['Before denoising, mean absolute task-DVARS correlation: mean = ' fmt(task_summary.preTaskDV_meanabs.mean,2) ...
                    ', SD = ' fmt(task_summary.preTaskDV_meanabs.sd,2)]);
    L = add_line(L,['Before denoising, maximum absolute task-DVARS correlation: mean = ' fmt(task_summary.preTaskDV_maxabs.mean,2) ...
                    ', SD = ' fmt(task_summary.preTaskDV_maxabs.sd,2) ...
                    ', maximum observed = ' fmt(task_summary.preTaskDV_maxabs.max,2)]);
    if ~isempty(postDVARS)
        L = add_line(L,['After denoising, mean signed task-DVARS correlation: mean = ' fmt(task_summary.postTaskDV_mean.mean,2) ...
                        ', SD = ' fmt(task_summary.postTaskDV_mean.sd,2)]);
        L = add_line(L,['After denoising, mean absolute task-DVARS correlation: mean = ' fmt(task_summary.postTaskDV_meanabs.mean,2) ...
                        ', SD = ' fmt(task_summary.postTaskDV_meanabs.sd,2)]);
        L = add_line(L,['After denoising, maximum absolute task-DVARS correlation: mean = ' fmt(task_summary.postTaskDV_maxabs.mean,2) ...
                        ', SD = ' fmt(task_summary.postTaskDV_maxabs.sd,2) ...
                        ', maximum observed = ' fmt(task_summary.postTaskDV_maxabs.max,2)]);
    end

    report_txt = sprintf('%s\n',L{:});
end

%--------------------------------------------------------------------------
% Short report for manuscript
%--------------------------------------------------------------------------
function txt = get_short_methods_text(pipeline_str,FD_summary,DVARS_summary,task_summary,spike_summary,acompcor_summary,reg_summary)

    % Head motion text
    if strcmpi(options.motion,'6HMP')
        motion_txt = 'six head motion parameters (HMP)';
    elseif strcmpi(options.motion,'12HMP')
        motion_txt = '12 head motion regressors, consisting of six head motion parameters (HMP) and their temporal derivatives';
    elseif strcmpi(options.motion,'24HMP')
        motion_txt = ['24 head motion regressors, consisting of six head motion parameters (HMP), ' ...
                      'their temporal derivatives, six squared HMP, and six squared temporal derivatives'];
    else
        motion_txt = options.motion;
    end

    % Spike regression text
    if options.spikereg == 1
        spike_txt = [' Spike regressors were added for time points with framewise displacement (FD) > ' ...
                     fmt(options.spikeregFDthr,2) ' mm, resulting in ' ...
                     fmt(spike_summary.nSpike.mean,1) ' spike regressors per subject on average ' ...
                     '(SD = ' fmt(spike_summary.nSpike.sd,1) ').'];
    else
        spike_txt = '';
    end

    % aCompCor text
    if strcmpi(acompcor_summary.type,'none')
        acc_txt = '';
    elseif strcmpi(acompcor_summary.type,'fixed')
        acc_txt = [' Anatomical component-based noise correction (aCompCor) was applied using ' ...
                   num2str(options.aCompCor(1)) ' white matter (WM) and ' ...
                   num2str(options.aCompCor(2)) ' cerebrospinal fluid (CSF) principal components per run/session.'];

        if isfinite(acompcor_summary.WM_var.mean) && isfinite(acompcor_summary.CSF_var.mean)
            acc_txt = [acc_txt ' These components explained on average ' ...
                       fmt(acompcor_summary.WM_var.mean,1) '% of WM variance and ' ...
                       fmt(acompcor_summary.CSF_var.mean,1) '% of CSF variance.'];
        end
    else
        acc_txt = [' Anatomical component-based noise correction explaining 50% of variance ' ...
                   'in white matter (WM) and cerebrospinal fluid (CSF) masks (aCompCor50) was applied. ' ...
                   'The number of components was selected separately for WM and CSF. Across subjects, this yielded on average ' ...
                   fmt(acompcor_summary.WM_nPCs.mean,0) ' WM and ' ...
                   fmt(acompcor_summary.CSF_nPCs.mean,0) ' CSF components.'];
    end

    % aCompCor orthogonalization text
    if sum(options.aCompCor) ~= 0 && options.aCompCor_ort == 1
        acc_ort_txt = ' Before principal component extraction, WM and CSF signals were pre-orthogonalized with respect to HMP and high-pass filter regressors.';
    else
        acc_ort_txt = '';
    end

    % WM/CSF Phys text
    if strcmpi(options.WM_CSF,'none')
        phys_txt = '';
    elseif strcmpi(options.WM_CSF,'2Phys')
        phys_txt = ' Mean WM and CSF signals were also included as nuisance regressors.';
    elseif strcmpi(options.WM_CSF,'4Phys')
        phys_txt = ' Mean WM and CSF signals and their temporal derivatives were also included as nuisance regressors.';
    elseif strcmpi(options.WM_CSF,'8Phys')
        phys_txt = ' Mean WM and CSF signals, their temporal derivatives, and quadratic terms were also included as nuisance regressors.';
    else
        phys_txt = '';
    end

    % GSR text
    if strcmpi(options.GSR,'none')
        gsr_txt = '';
    elseif strcmpi(options.GSR,'GSR')
        gsr_txt = ' The global signal was also included as a nuisance regressor.';
    elseif strcmpi(options.GSR,'2GSR')
        gsr_txt = ' The global signal and its temporal derivative were also included as nuisance regressors.';
    elseif strcmpi(options.GSR,'4GSR')
        gsr_txt = ' The global signal, its temporal derivative, and quadratic terms were also included as nuisance regressors.';
    else
        gsr_txt = '';
    end

    % rWLS text
    if options.rWLS == 1
        rwls_txt = [' Robust weighted least squares (rWLS) was used for model estimation. ' ...
            'This approach continuously down-weights time points affected by noise.'];
    else
        rwls_txt = '';
    end

    % Mask text
    mask_txt = get_mask_methods_text();

    % FD-DVARS change text
    dvars_change_txt = get_FD_DVARS_change_text(DVARS_summary);

    % Task correlation text
    task_txt = [' The mean absolute task-FD correlation across subjects was ' ...
        fmt(task_summary.taskFD_meanabs.mean,2) ' (SD = ' ...
        fmt(task_summary.taskFD_meanabs.sd,2) '), and the mean maximum absolute task-FD correlation was ' ...
        fmt(task_summary.taskFD_maxabs.mean,2) ' (SD = ' ...
        fmt(task_summary.taskFD_maxabs.sd,2) ').'];

    if ~isempty(postDVARS)
        task_txt = [task_txt ' After denoising, the mean absolute task-DVARS correlation was ' ...
            fmt(task_summary.postTaskDV_meanabs.mean,2) ' (SD = ' ...
            fmt(task_summary.postTaskDV_meanabs.sd,2) ...
            '), and the mean maximum absolute task-DVARS correlation was ' ...
            fmt(task_summary.postTaskDV_maxabs.mean,2) ' (SD = ' ...
            fmt(task_summary.postTaskDV_maxabs.sd,2) ').'];
    else
        task_txt = [task_txt ' Before denoising, the mean absolute task-DVARS correlation was ' ...
            fmt(task_summary.preTaskDV_meanabs.mean,2) ' (SD = ' ...
            fmt(task_summary.preTaskDV_meanabs.sd,2) ...
            '), and the mean maximum absolute task-DVARS correlation was ' ...
            fmt(task_summary.preTaskDV_maxabs.mean,2) ' (SD = ' ...
            fmt(task_summary.preTaskDV_maxabs.sd,2) ').'];
    end

    % Regressor count text
    reg_txt = get_regressor_methods_text(reg_summary);

    % Final report text
    txt = ['Denoising was performed using TMFC_denoise v1.5.0. The selected denoising strategy included ' ...
           motion_txt '.' spike_txt acc_txt acc_ort_txt phys_txt gsr_txt rwls_txt ' ' ...
           mask_txt ' The mean FD across subjects was ' ...
           fmt(FD_summary.meanFD.mean,2) ' mm (SD = ' fmt(FD_summary.meanFD.sd,2) ...
           '), and ' fmt(FD_summary.flagged_pct.mean,1) ...
           '% of scans exceeded FD > ' fmt(FD_summary.FDthr,2) ' mm on average (SD = ' ...
           fmt(FD_summary.flagged_pct.sd,1) '%). ' dvars_change_txt task_txt reg_txt];
end

%--------------------------------------------------------------------------
% Nuisance regressor count text for manuscript report
%--------------------------------------------------------------------------
function reg_txt = get_regressor_methods_text(reg_summary)

    % Pure 6HMP, or no additional regressors
    if reg_summary.total_added.mean == 0 && ~reg_summary.has_variable_regressors
        reg_txt = '';
        return
    end

    % Variable cases: SpikeReg and/or aCompCor50
    if reg_summary.has_variable_regressors
        reg_txt = [' The total number of additional nuisance regressors generated by TMFC_denoise was ' ...
                   fmt(reg_summary.total_added.mean,1) ' per subject on average (SD = ' ...
                   fmt(reg_summary.total_added.sd,1) ').'];
        return
    end

    % Fixed cases: exact number
    if reg_summary.fixed_per_run > 0
        if reg_summary.same_nRuns && reg_summary.nRuns_common == 1
            reg_txt = [' TMFC_denoise generated ' num2str(reg_summary.fixed_per_run) ...
                       ' additional nuisance regressors per subject.'];
        elseif reg_summary.same_nRuns
            nSubRegs = reg_summary.fixed_per_run * reg_summary.nRuns_common;
            reg_txt = [' TMFC_denoise generated ' num2str(reg_summary.fixed_per_run) ...
                       ' additional nuisance regressors per run/session (' num2str(nSubRegs) ...
                       ' per subject across ' num2str(reg_summary.nRuns_common) ' runs/sessions).'];
        else
            reg_txt = [' TMFC_denoise generated ' num2str(reg_summary.fixed_per_run) ...
                       ' additional nuisance regressors per run/session; the total number per subject depended on the number of runs/sessions.'];
        end
    else
        reg_txt = '';
    end
end

%--------------------------------------------------------------------------
% Mask parameters text for manuscript report
%--------------------------------------------------------------------------
function mask_txt = get_mask_methods_text()

    mask_txt = '';

    % GM mask for DVARS
    if isfield(options,'GMmask')
        mask_txt = ['The gray matter (GM) mask used for derivative of root mean square variance over voxels (DVARS) calculation ' ...
                    'was created by thresholding the GM probability map at ' fmt(options.GMmask.prob,2) '.'];
    else
        mask_txt = ['The gray matter (GM) mask was used to calculate the derivative of root mean square variance over voxels (DVARS).'];
    end

    % WM/CSF masks only if aCompCor or Phys is selected
    if use_wm_csf_masks()
        if isfield(options,'WMmask') && isfield(options,'CSFmask') && isfield(options,'GMmask')
            mask_txt = [mask_txt ' WM and CSF masks used for tissue-based nuisance regression were thresholded at ' ...
                        fmt(options.WMmask.prob,2) ' and ' fmt(options.CSFmask.prob,2) ...
                        ', respectively, and eroded by ' num2str(options.WMmask.erode) ' and ' ...
                        num2str(options.CSFmask.erode) ' cycles. To reduce GM contamination in the CSF mask, ' ...
                        'the GM mask was dilated by ' num2str(options.GMmask.dilate) ...
                        ' cycles and subtracted from the CSF mask.'];
        else
            mask_txt = [mask_txt ' WM and CSF masks were used for tissue-based nuisance regression, but mask parameters were not available in the current report object.'];
        end
    end

    % Whole-brain mask only if GSR is selected
    if use_gsr()
        mask_txt = [mask_txt ' A whole-brain mask was used to extract the global signal for GSR.'];
    end
end

%--------------------------------------------------------------------------
% FD-DVARS change text
%--------------------------------------------------------------------------
function txt = get_FD_DVARS_change_text(DVARS_summary)

    pre_val = DVARS_summary.pre.mean;
    post_val = DVARS_summary.post.mean;

    if ~isfinite(pre_val) || ~isfinite(post_val)
        txt = 'FD-DVARS correlations after denoising were not available.';
        return
    end

    txt = ['The mean FD-DVARS correlation changed from ' fmt(pre_val,2) ...
           ' before denoising to ' fmt(post_val,2) ' after denoising.'];
end

%--------------------------------------------------------------------------
% Pipeline string
%--------------------------------------------------------------------------
function pipeline_str = get_pipeline_string()

    parts = {options.motion};

    if options.rWLS == 1
        parts{end+1} = 'rWLS';
    end

    if options.spikereg == 1
        parts{end+1} = ['SpikeReg_' fmt(options.spikeregFDthr,2) 'mm'];
    end

    if sum(options.aCompCor) ~= 0
        if options.aCompCor(1) == 0.5
            if options.aCompCor_ort == 1
                parts{end+1} = 'aCompCor50_Ort';
            else
                parts{end+1} = 'aCompCor50';
            end
        else
            if options.aCompCor_ort == 1
                parts{end+1} = ['aCompCor_' num2str(options.aCompCor(1)) 'WM_' num2str(options.aCompCor(2)) 'CSF_Ort'];
            else
                parts{end+1} = ['aCompCor_' num2str(options.aCompCor(1)) 'WM_' num2str(options.aCompCor(2)) 'CSF'];
            end
        end
    end

    if ~strcmpi(options.GSR,'none')
        parts{end+1} = options.GSR;
    end

    if ~strcmpi(options.WM_CSF,'none')
        parts{end+1} = options.WM_CSF;
    end

    pipeline_str = parts{1};
    for i = 2:numel(parts)
        pipeline_str = [pipeline_str ' + ' parts{i}];
    end
end

%--------------------------------------------------------------------------
% FD summary
%--------------------------------------------------------------------------
function S = get_FD_summary()

    S.nSub = length(FD);

    FD_mean = nan(1,S.nSub);
    FD_max  = nan(1,S.nSub);
    flagged_pct = nan(1,S.nSub);

    if isfield(options,'spikeregFDthr')
        S.FDthr = options.spikeregFDthr;
    else
        S.FDthr = 0.5;
    end

    for iSub = 1:S.nSub
        FD_mean(iSub) = FD(iSub).FD_mean;
        FD_max(iSub)  = FD(iSub).FD_max;

        nScan = 0;
        nFlag = 0;
        for jSess = 1:length(FD(iSub).Sess)
            ts = FD(iSub).Sess(jSess).FD_ts;
            nScan = nScan + numel(ts);
            nFlag = nFlag + sum(ts > S.FDthr);
        end

        if nScan > 0
            flagged_pct(iSub) = 100*nFlag/nScan;
        end
    end

    S.meanFD = vec_stats(FD_mean);
    S.maxFD = vec_stats(FD_max);
    S.flagged_pct = vec_stats(flagged_pct);
    S.nSub_25pct = sum(flagged_pct > 25);
end

%--------------------------------------------------------------------------
% DVARS summary
%--------------------------------------------------------------------------
function S = get_DVARS_summary()

    pre = nan(1,length(preDVARS));
    post = nan(1,length(preDVARS));

    for iSub = 1:length(preDVARS)
        pre(iSub) = preDVARS(iSub).DVARS.Mean_FD_DVARS_corr;
        if ~isempty(postDVARS) && length(postDVARS) >= iSub && isfield(postDVARS(iSub),'DVARS')
            post(iSub) = postDVARS(iSub).DVARS.Mean_FD_DVARS_corr;
        end
    end

    S.pre = vec_stats(pre);

    if ~isempty(postDVARS)
        S.post = vec_stats(post);
        S.reduction = vec_stats(pre - post);
    else
        S.post = empty_stats();
        S.reduction = empty_stats();
    end
end

%--------------------------------------------------------------------------
% Task-FD and task-DVARS summary
%--------------------------------------------------------------------------
function S = get_task_summary()

    taskFD_mean    = nan(1,length(FD));
    taskFD_meanabs = nan(1,length(FD));
    taskFD_maxabs  = nan(1,length(FD));

    preTaskDV_mean    = nan(1,length(preDVARS));
    preTaskDV_meanabs = nan(1,length(preDVARS));
    preTaskDV_maxabs  = nan(1,length(preDVARS));

    postTaskDV_mean    = nan(1,length(preDVARS));
    postTaskDV_meanabs = nan(1,length(preDVARS));
    postTaskDV_maxabs  = nan(1,length(preDVARS));

    % Collect all task-FD correlations for top-regressor reporting
    all_task_names = {};
    all_task_r = [];
    all_subject = {};
    all_run = [];

    for iSub = 1:length(FD)

        if isfield(FD(iSub),'taskFD_corr_mean')
            taskFD_mean(iSub) = FD(iSub).taskFD_corr_mean;
        end

        if isfield(FD(iSub),'taskFD_corr_maxabs')
            taskFD_maxabs(iSub) = FD(iSub).taskFD_corr_maxabs;
        end

        subj_taskFD = [];

        if isfield(FD(iSub),'Sess')
            for jSess = 1:length(FD(iSub).Sess)
                if isfield(FD(iSub).Sess(jSess),'taskFD_corr') && ...
                   isfield(FD(iSub).Sess(jSess),'task_names') && ...
                   ~isempty(FD(iSub).Sess(jSess).taskFD_corr)

                    r = FD(iSub).Sess(jSess).taskFD_corr;
                    names = FD(iSub).Sess(jSess).task_names;

                    subj_taskFD = [subj_taskFD r(:)'];

                    for k = 1:numel(r)
                        if isfinite(r(k))
                            all_task_r(end+1,1) = r(k);

                            if numel(names) >= k
                                all_task_names{end+1,1} = names{k};
                            else
                                all_task_names{end+1,1} = ['Task regressor ' num2str(k)];
                            end

                            all_subject{end+1,1} = FD(iSub).Subject;
                            all_run(end+1,1) = jSess;
                        end
                    end
                end
            end
        end

        subj_taskFD = subj_taskFD(isfinite(subj_taskFD));
        if ~isempty(subj_taskFD)
            taskFD_meanabs(iSub) = mean(abs(subj_taskFD));
        end
    end

    for iSub = 1:length(preDVARS)

        if isfield(preDVARS(iSub).DVARS,'taskDVARS_corr_mean')
            preTaskDV_mean(iSub) = preDVARS(iSub).DVARS.taskDVARS_corr_mean;
        end

        if isfield(preDVARS(iSub).DVARS,'taskDVARS_corr_maxabs')
            preTaskDV_maxabs(iSub) = preDVARS(iSub).DVARS.taskDVARS_corr_maxabs;
        end

        subj_pre_taskDV = [];
        if isfield(preDVARS(iSub).DVARS,'Sess')
            for jSess = 1:length(preDVARS(iSub).DVARS.Sess)
                if isfield(preDVARS(iSub).DVARS.Sess(jSess),'taskDVARS_corr') && ...
                   ~isempty(preDVARS(iSub).DVARS.Sess(jSess).taskDVARS_corr)

                    subj_pre_taskDV = [subj_pre_taskDV preDVARS(iSub).DVARS.Sess(jSess).taskDVARS_corr(:)'];
                end
            end
        end

        subj_pre_taskDV = subj_pre_taskDV(isfinite(subj_pre_taskDV));
        if ~isempty(subj_pre_taskDV)
            preTaskDV_meanabs(iSub) = mean(abs(subj_pre_taskDV));
        end

        if ~isempty(postDVARS) && length(postDVARS) >= iSub && isfield(postDVARS(iSub),'DVARS')

            if isfield(postDVARS(iSub).DVARS,'taskDVARS_corr_mean')
                postTaskDV_mean(iSub) = postDVARS(iSub).DVARS.taskDVARS_corr_mean;
            end

            if isfield(postDVARS(iSub).DVARS,'taskDVARS_corr_maxabs')
                postTaskDV_maxabs(iSub) = postDVARS(iSub).DVARS.taskDVARS_corr_maxabs;
            end

            subj_post_taskDV = [];
            if isfield(postDVARS(iSub).DVARS,'Sess')
                for jSess = 1:length(postDVARS(iSub).DVARS.Sess)
                    if isfield(postDVARS(iSub).DVARS.Sess(jSess),'taskDVARS_corr') && ...
                       ~isempty(postDVARS(iSub).DVARS.Sess(jSess).taskDVARS_corr)

                        subj_post_taskDV = [subj_post_taskDV postDVARS(iSub).DVARS.Sess(jSess).taskDVARS_corr(:)'];
                    end
                end
            end

            subj_post_taskDV = subj_post_taskDV(isfinite(subj_post_taskDV));
            if ~isempty(subj_post_taskDV)
                postTaskDV_meanabs(iSub) = mean(abs(subj_post_taskDV));
            end
        end
    end

    S.taskFD_mean       = vec_stats(taskFD_mean);
    S.taskFD_meanabs    = vec_stats(taskFD_meanabs);
    S.taskFD_maxabs     = vec_stats(taskFD_maxabs);

    S.preTaskDV_mean    = vec_stats(preTaskDV_mean);
    S.preTaskDV_meanabs = vec_stats(preTaskDV_meanabs);
    S.preTaskDV_maxabs  = vec_stats(preTaskDV_maxabs);

    S.postTaskDV_mean    = vec_stats(postTaskDV_mean);
    S.postTaskDV_meanabs = vec_stats(postTaskDV_meanabs);
    S.postTaskDV_maxabs  = vec_stats(postTaskDV_maxabs);

    % Raw subject-level values for QC plots
    S.taskFD_mean_raw       = taskFD_mean;
    S.taskFD_meanabs_raw    = taskFD_meanabs;
    S.taskFD_maxabs_raw     = taskFD_maxabs;

    S.preTaskDV_mean_raw       = preTaskDV_mean;
    S.preTaskDV_meanabs_raw    = preTaskDV_meanabs;
    S.preTaskDV_maxabs_raw     = preTaskDV_maxabs;

    S.postTaskDV_mean_raw       = postTaskDV_mean;
    S.postTaskDV_meanabs_raw    = postTaskDV_meanabs;
    S.postTaskDV_maxabs_raw     = postTaskDV_maxabs;

    % Top 5 individual task-FD correlations
    S.top_taskFD = get_top_taskFD(all_task_names,all_task_r,all_subject,all_run,5);

    % Top 5 unique regressor names by maximum absolute task-FD correlation
    S.top_taskFD_unique = get_top_taskFD_unique(all_task_names,all_task_r,5);
end

%--------------------------------------------------------------------------
% Top task-FD correlations: individual observations
%--------------------------------------------------------------------------
function top = get_top_taskFD(names,r,subjects,runs,nTop)

    top = struct('name',{},'r',{},'abs_r',{},'subject',{},'run',{});

    if isempty(r)
        return
    end

    [~,idx] = sort(abs(r),'descend');
    idx = idx(1:min(nTop,numel(idx)));

    for i = 1:numel(idx)
        k = idx(i);
        top(i).name = names{k};
        top(i).r = r(k);
        top(i).abs_r = abs(r(k));
        top(i).subject = subjects{k};
        top(i).run = runs(k);
    end
end

%--------------------------------------------------------------------------
% Top unique task-FD regressor names by maximum absolute correlation
%--------------------------------------------------------------------------
function top = get_top_taskFD_unique(names,r,nTop)

    top = struct('name',{},'r',{},'abs_r',{});

    if isempty(r)
        return
    end

    clean_names = cell(size(names));
    for i = 1:numel(names)
        clean_names{i} = clean_task_name(names{i});
    end

    unique_names = unique(clean_names,'stable');

    max_abs = nan(numel(unique_names),1);
    max_r = nan(numel(unique_names),1);

    for i = 1:numel(unique_names)
        idx = strcmp(clean_names,unique_names{i});
        rr = r(idx);
        [max_abs(i),ii] = max(abs(rr));
        max_r(i) = rr(ii);
    end

    [~,ord] = sort(max_abs,'descend');
    ord = ord(1:min(nTop,numel(ord)));

    for i = 1:numel(ord)
        k = ord(i);
        top(i).name = unique_names{k};
        top(i).r = max_r(k);
        top(i).abs_r = max_abs(k);
    end
end

%--------------------------------------------------------------------------
% Clean SPM task-regressor names for reporting
%--------------------------------------------------------------------------
function name_out = clean_task_name(name_in)

    name_out = name_in;

    % Remove common SPM session prefix, e.g. "Sn(1) "
    name_out = regexprep(name_out,'^Sn\(\d+\)\s*','');

    % Remove common basis-function suffix, e.g. "*bf(1)"
    name_out = regexprep(name_out,'\*bf\(\d+\)$','');

    % Remove leading/trailing spaces
    name_out = strtrim(name_out);
end

%--------------------------------------------------------------------------
% Spike regression summary
%--------------------------------------------------------------------------
function S = get_spike_summary()

    nSpike = nan(1,length(SPM_paths));

    if ~isfield(options,'spikereg') || options.spikereg == 0
        S.nSpike = empty_stats();
        S.nSpike_raw = [];
        return
    end

    outname = sprintf('SpikeReg_[FDthr_%.2fmm].mat',options.spikeregFDthr);

    for iSub = 1:length(SPM_paths)
        GLM_subfolder = fileparts(SPM_paths{iSub});
        f = fullfile(GLM_subfolder,'TMFC_denoise',outname);

        if exist(f,'file')
            tmp = load(f,'SpikeReg');
            n = 0;
            for jSess = 1:length(tmp.SpikeReg)
                n = n + size(tmp.SpikeReg(jSess).Sess,2);
            end
            nSpike(iSub) = n;
        else
            % Fallback to FD thresholding if SpikeReg file is absent
            n = 0;
            for jSess = 1:length(FD(iSub).Sess)
                n = n + sum(FD(iSub).Sess(jSess).FD_ts > options.spikeregFDthr);
            end
            nSpike(iSub) = n;
        end
    end

    S.nSpike = vec_stats(nSpike);
    S.nSpike_raw = nSpike;
end

%--------------------------------------------------------------------------
% aCompCor summary
%--------------------------------------------------------------------------
function S = get_acompcor_summary()

    S.type = 'none';
    S.file_name = '';
    S.WM_nPCs = empty_stats();
    S.CSF_nPCs = empty_stats();
    S.WM_var = empty_stats();
    S.CSF_var = empty_stats();
    S.total_raw = zeros(1,length(SPM_paths));

    if ~isfield(options,'aCompCor') || sum(options.aCompCor) == 0
        return
    end

    acompcor_fname = get_acompcor_fname();
    S.file_name = [acompcor_fname '.mat'];

    if options.aCompCor(1) == 0.5
        S.type = 'aCompCor50';
    else
        S.type = 'fixed';
    end

    WM_nPCs = nan(1,length(SPM_paths));
    CSF_nPCs = nan(1,length(SPM_paths));
    WM_var = nan(1,length(SPM_paths));
    CSF_var = nan(1,length(SPM_paths));
    total = nan(1,length(SPM_paths));

    for iSub = 1:length(SPM_paths)

        if isempty(masks) || ~isfield(masks,'glm_paths')
            continue
        end

        f = fullfile(masks.glm_paths{iSub},[acompcor_fname '.mat']);

        if ~exist(f,'file')
            continue
        end

        if strcmpi(S.type,'fixed')
            tmp = load(f,'aCompCor');

            nWM = 0;
            nCSF = 0;
            for jSess = 1:length(tmp.aCompCor.Sess)
                nWM = nWM + size(tmp.aCompCor.Sess(jSess).WM_PCs,2);
                nCSF = nCSF + size(tmp.aCompCor.Sess(jSess).CSF_PCs,2);
            end

            WM_nPCs(iSub) = nWM;
            CSF_nPCs(iSub) = nCSF;
            total(iSub) = nWM + nCSF;

            if isfield(tmp.aCompCor,'WM_mean_variance_explained')
                WM_var(iSub) = tmp.aCompCor.WM_mean_variance_explained;
            end
            if isfield(tmp.aCompCor,'CSF_mean_variance_explained')
                CSF_var(iSub) = tmp.aCompCor.CSF_mean_variance_explained;
            end

        else
            tmp = load(f,'aCompCor50');

            if isfield(tmp.aCompCor50,'WM_nPCs')
                WM_nPCs(iSub) = tmp.aCompCor50.WM_nPCs;
            end
            if isfield(tmp.aCompCor50,'CSF_nPCs')
                CSF_nPCs(iSub) = tmp.aCompCor50.CSF_nPCs;
            end

            total(iSub) = WM_nPCs(iSub) + CSF_nPCs(iSub);
        end
    end

    S.WM_nPCs = vec_stats(WM_nPCs);
    S.CSF_nPCs = vec_stats(CSF_nPCs);
    S.WM_var = vec_stats(WM_var);
    S.CSF_var = vec_stats(CSF_var);
    S.total = vec_stats(total);
    S.total_raw = total;
end

%--------------------------------------------------------------------------
% aCompCor filename
%--------------------------------------------------------------------------
function fname = get_acompcor_fname()

    if (options.aCompCor(1) >= 1 || options.aCompCor(2) >= 1) && options.aCompCor_ort == 0
        fname = ['[aCompCor_' num2str(options.aCompCor(1)) 'WM_' num2str(options.aCompCor(2)) 'CSF]'];
    elseif (options.aCompCor(1) >= 1 || options.aCompCor(2) >= 1) && options.aCompCor_ort == 1
        fname = ['[aCompCor_' num2str(options.aCompCor(1)) 'WM_' num2str(options.aCompCor(2)) 'CSF_Ort]'];
    elseif options.aCompCor(1) == 0.5 && options.aCompCor_ort == 0
        fname = '[aCompCor50]';
    elseif options.aCompCor(1) == 0.5 && options.aCompCor_ort == 1
        fname = '[aCompCor50_Ort]';
    else
        fname = '';
    end
end

%--------------------------------------------------------------------------
% Regressor count summary
%--------------------------------------------------------------------------
function S = get_regressor_summary(spike_summary,acompcor_summary)

    switch upper(options.motion)
        case '6HMP'
            S.hmp_total = 6;
            S.hmp_added = 0;
        case '12HMP'
            S.hmp_total = 12;
            S.hmp_added = 6;
        case '24HMP'
            S.hmp_total = 24;
            S.hmp_added = 18;
        otherwise
            S.hmp_total = NaN;
            S.hmp_added = NaN;
    end

    switch upper(options.WM_CSF)
        case '2PHYS'
            S.phys_per_run = 2;
        case '4PHYS'
            S.phys_per_run = 4;
        case '8PHYS'
            S.phys_per_run = 8;
        otherwise
            S.phys_per_run = 0;
    end

    switch upper(options.GSR)
        case 'GSR'
            S.gsr_per_run = 1;
        case '2GSR'
            S.gsr_per_run = 2;
        case '4GSR'
            S.gsr_per_run = 4;
        otherwise
            S.gsr_per_run = 0;
    end

    % Fixed aCompCor has an exact number of regressors per run/session.
    % aCompCor50 is variable and is counted from aCompCor50 files.
    if use_fixed_acompcor()
        S.acompcor_fixed_per_run = sum(options.aCompCor);
    else
        S.acompcor_fixed_per_run = 0;
    end

    S.fixed_per_run = S.hmp_added + S.phys_per_run + S.gsr_per_run + S.acompcor_fixed_per_run;
    S.has_variable_regressors = use_variable_regressor_count();

    nRuns = nan(1,length(FD));
    total_added = nan(1,length(FD));

    for iSub = 1:length(FD)
        nRuns(iSub) = length(FD(iSub).Sess);

        nFixed = S.fixed_per_run * nRuns(iSub);

        if options.spikereg == 1 && ~isempty(spike_summary.nSpike_raw)
            nSpike = spike_summary.nSpike_raw(iSub);
        else
            nSpike = 0;
        end

        if use_acompcor50() && isfield(acompcor_summary,'total_raw') && numel(acompcor_summary.total_raw) >= iSub
            nACC = acompcor_summary.total_raw(iSub);
        else
            nACC = 0;
        end

        total_added(iSub) = nFixed + nSpike + nACC;
    end

    S.nRuns = vec_stats(nRuns);
    S.nRuns_raw = nRuns;

    unique_runs = unique(nRuns(isfinite(nRuns)));
    S.same_nRuns = numel(unique_runs) == 1;
    if S.same_nRuns
        S.nRuns_common = unique_runs;
    else
        S.nRuns_common = NaN;
    end

    S.total_added = vec_stats(total_added);
    S.total_added_raw = total_added;
end

%--------------------------------------------------------------------------
% Report helper flags
%--------------------------------------------------------------------------
function tf = use_acompcor()
    tf = isfield(options,'aCompCor') && any(options.aCompCor ~= 0);
end

function tf = use_acompcor50()
    tf = use_acompcor() && options.aCompCor(1) == 0.5;
end

function tf = use_fixed_acompcor()
    tf = use_acompcor() && options.aCompCor(1) ~= 0.5;
end

function tf = use_phys()
    tf = isfield(options,'WM_CSF') && ~strcmpi(options.WM_CSF,'none');
end

function tf = use_gsr()
    tf = isfield(options,'GSR') && ~strcmpi(options.GSR,'none');
end

function tf = use_wm_csf_masks()
    tf = use_acompcor() || use_phys();
end

function tf = use_variable_regressor_count()
    tf = (isfield(options,'spikereg') && options.spikereg == 1) || use_acompcor50();
end

%--------------------------------------------------------------------------
% Statistics helper
%--------------------------------------------------------------------------
function S = vec_stats(x)

    x = x(:)';
    x = x(isfinite(x));

    if isempty(x)
        S = empty_stats();
    else
        S.mean = mean(x);
        S.sd = std(x);
        S.min = min(x);
        S.max = max(x);
    end
end

function S = empty_stats()
    S.mean = NaN;
    S.sd = NaN;
    S.min = NaN;
    S.max = NaN;
end

%--------------------------------------------------------------------------
% Formatting helpers
%--------------------------------------------------------------------------
function s = fmt(x,n)

    if nargin < 2
        n = 2;
    end

    if isempty(x) || ~isfinite(x)
        s = 'N/A';
    else
        s = sprintf(['%0.' num2str(n) 'f'],x);
    end
end


function L = add_line(L,str)
    L{end+1,1} = str;
end

%--------------------------------------------------------------------------
% Open QC figures
%--------------------------------------------------------------------------
function open_qc_plots(~,~)

    selected_subject = get(DVARS_MW_LB1,'Value');
    if isempty(selected_subject) || selected_subject < 1 || selected_subject > length(FD)
        selected_subject = 1;
    end

    % 1) Selected subject FD/DVARS figure
    h1 = create_subject_FD_DVARS_figure(selected_subject);
    set(h1,'Visible','on');
    figure(h1);

    % 2) Group FD-DVARS figure
    h2 = create_group_FD_DVARS_figure();
    set(h2,'Visible','on');
    figure(h2);

    % 3) Motion summary figures
    h3 = create_motion_summary_figure();
    set(h3,'Visible','on');
    figure(h3);
    h_motion_box = create_motion_boxplots_figure();
    set(h_motion_box,'Visible','on');
    figure(h_motion_box);

    % 4) Task correlations figures
    h4 = create_task_correlations_figure();
    set(h4,'Visible','on');
    figure(h4);

    h_task_box = create_task_correlations_boxplots_figure();
    set(h_task_box,'Visible','on');
    figure(h_task_box);

    fprintf('TMFC_denoise QC plots opened. Use the MATLAB figure window to save them manually.\n');
end

%--------------------------------------------------------------------------
% Create selected-subject FD/DVARS figure
%--------------------------------------------------------------------------
function h = create_subject_FD_DVARS_figure(iSub)

    [FD_ts,preDVARS_ts,postDVARS_ts,sess] = get_subject_FD_DVARS_ts(iSub);

    h = figure('Name','TMFC denoise QC: subject FD-DVARS', ...
        'NumberTitle','off', ...
        'Units','normalized', ...
        'Position',[0.25 0.20 0.50 0.60], ...
        'Color','w', ...
        'Visible','on');

    % FD plot
    ax1 = subplot(2,1,1,'Parent',h);
    plot(ax1,FD_ts,'Color',[0 0.447 0.7410]);
    box(ax1,'on');
    xlabel(ax1,'Scans');
    ylabel(ax1,'FD, [mm]');
    title(ax1,['Subject: ' FD(iSub).Subject],'Interpreter','none');
    xlim(ax1,'tight');
    hold(ax1,'on');

    y = ylim(ax1);
    nRuns = length(FD(iSub).Sess);

    for jSess = 1:nRuns
        if jSess > 1
            plot(ax1,[sess(jSess) sess(jSess)],[y(1) y(2)],'-k');
        end
        text(ax1,sess(jSess)+10,y(2),['Run ' num2str(jSess)], ...
            'VerticalAlignment','top');
    end

    % DVARS plot
    ax2 = subplot(2,1,2,'Parent',h);

    if isempty(postDVARS_ts)
        tmp = preDVARS_ts;
    else
        tmp = [preDVARS_ts; postDVARS_ts];
    end
    tmp(isnan(tmp)) = [];

    if isempty(tmp)
        y1 = 1; y2 = -1;
    else
        y1 = max(tmp);
        y2 = min(tmp);
    end

    plot(ax2,preDVARS_ts,'Color',[0 0.447 0.7410]);
    hold(ax2,'on');

    if ~isempty(postDVARS_ts)
        plot(ax2,postDVARS_ts,'Color',[0.8500 0.3250 0.0980]);
    end

    box(ax2,'on');
    xlabel(ax2,'Scans');
    ylabel(ax2,DVARS_label);
    xlim(ax2,'tight');

    if y1 > y2
        ylim(ax2,[y2*1.3 y1*1.1]);
    end

    x = xlim(ax2);
    y = ylim(ax2);

    nRuns = length(FD(iSub).Sess);

    for jSess = 1:nRuns
        if jSess > 1
            plot(ax2,[sess(jSess) sess(jSess)],[y(1) y(2)],'-k');
        end
        text(ax2,sess(jSess)+10,y(2),['Run ' num2str(jSess)], ...
            'VerticalAlignment','top');
    end

    text(ax2,x(2)+2,y(1)+0.75*(y(2)-y(1)),'Before', ...
        'Color',[0 0.447 0.7410]);

    if ~isempty(postDVARS_ts)
        text(ax2,x(2)+2,y(1)+0.50*(y(2)-y(1)),'After', ...
            'Color',[0.8500 0.3250 0.0980]);
    end
end

%--------------------------------------------------------------------------
% Prepare selected-subject FD/DVARS time series
%--------------------------------------------------------------------------
function [FD_ts,preDVARS_ts,postDVARS_ts,sess] = get_subject_FD_DVARS_ts(iSub)

    FD_ts = [];
    preDVARS_ts = [];
    postDVARS_ts = [];
    sess_sum = 0;
    sess = 0;

    for jSess = 1:length(FD(iSub).Sess)

        FD_ts = [FD_ts; FD(iSub).Sess(jSess).FD_ts];

        if hasRWLS
            preDVARS_ts = [preDVARS_ts; NaN(3,1); ...
                tmfc_zscore(preDVARS(iSub).DVARS.Sess(jSess).DVARS_ts(4:end-1)); NaN];
        else
            preDVARS_ts = [preDVARS_ts; NaN(3,1); ...
                spm_detrend(preDVARS(iSub).DVARS.Sess(jSess).DVARS_ts(4:end-1)); NaN];
        end

        if ~isempty(postDVARS)
            if hasRWLS
                postDVARS_ts = [postDVARS_ts; NaN(3,1); ...
                    tmfc_zscore(postDVARS(iSub).DVARS.Sess(jSess).DVARS_ts(4:end-1)); NaN];
            else
                postDVARS_ts = [postDVARS_ts; NaN(3,1); ...
                    spm_detrend(postDVARS(iSub).DVARS.Sess(jSess).DVARS_ts(4:end-1)); NaN];
            end
        end

        sess_sum = sess_sum + length(FD(iSub).Sess(jSess).FD_ts) + 1;
        sess = [sess; sess_sum];
    end
end

%--------------------------------------------------------------------------
% Create group FD-DVARS figure
%--------------------------------------------------------------------------
function h = create_group_FD_DVARS_figure()

    pre_corr = nan(1,length(preDVARS));
    post_corr = nan(1,length(preDVARS));

    for iSub = 1:length(preDVARS)
        pre_corr(iSub) = preDVARS(iSub).DVARS.Mean_FD_DVARS_corr;

        if ~isempty(postDVARS) && length(postDVARS) >= iSub && isfield(postDVARS(iSub),'DVARS')
            post_corr(iSub) = postDVARS(iSub).DVARS.Mean_FD_DVARS_corr;
        end
    end

    c_before = [0 0.4470 0.7410];
    c_after  = [0.8500 0.3250 0.0980];

    h = figure('Name','TMFC denoise QC: group FD-DVARS', ...
        'NumberTitle','off', ...
        'Units','normalized', ...
        'Position',[0.20 0.25 0.60 0.50], ...
        'Color','w', ...
        'Visible','off');

    % ---------------------------------------------------------------------
    % Left subplot: paired subject-wise FD-DVARS correlations
    % ---------------------------------------------------------------------
    ax1 = subplot(1,2,1,'Parent',h);

    if ~isempty(postDVARS)
        for iSub = 1:length(pre_corr)
            plot(ax1,[1 2],[pre_corr(iSub) post_corr(iSub)],'-o', ...
                'Color',[0.60 0.60 0.60], ...
                'MarkerSize',4);
            hold(ax1,'on');
        end

        plot(ax1,[1 2],[tmfc_nanmean(pre_corr) tmfc_nanmean(post_corr)],'-o', ...
            'Color','k', ...
            'LineWidth',2, ...
            'MarkerFaceColor','k', ...
            'MarkerSize',6);

        set(ax1,'XTick',[1 2],'XTickLabel',{'Before','After'});
        xlim(ax1,[0.5 2.5]);
    else
        plot(ax1,ones(size(pre_corr)),pre_corr,'o', ...
            'Color',c_before, ...
            'MarkerSize',4);
        hold(ax1,'on');

        plot(ax1,1,tmfc_nanmean(pre_corr),'o', ...
            'Color','k', ...
            'MarkerFaceColor','k', ...
            'MarkerSize',6);

        set(ax1,'XTick',1,'XTickLabel',{'Before'});
        xlim(ax1,[0.5 1.5]);
    end

    box(ax1,'on');
    ylabel(ax1,'Mean FD-DVARS correlation');
    title(ax1,'Subject-wise change');

    % ---------------------------------------------------------------------
    % Right subplot: standard boxplot with overlaid subject data points
    % ---------------------------------------------------------------------
    ax2 = subplot(1,2,2,'Parent',h);
    hold(ax2,'on');

    if ~isempty(postDVARS)
        plot_standard_box_with_points(ax2,1,pre_corr,c_before);
        plot_standard_box_with_points(ax2,2,post_corr,c_after);

        set(ax2,'XTick',[1 2],'XTickLabel',{'Before','After'});
        xlim(ax2,[0.5 2.5]);
    else
        plot_standard_box_with_points(ax2,1,pre_corr,c_before);

        set(ax2,'XTick',1,'XTickLabel',{'Before'});
        xlim(ax2,[0.5 1.5]);
    end

    box(ax2,'on');
    ylabel(ax2,'Mean FD-DVARS correlation');
    title(ax2,'Boxplot with subject data');

    % Use the same y-limits for both subplots
    all_y = pre_corr(:);
    if ~isempty(postDVARS)
        all_y = [all_y; post_corr(:)];
    end
    all_y = all_y(isfinite(all_y));

    if isempty(all_y)
        common_ylim = [-1 1];
    else
        y_min = min([all_y; 0]);
        y_max = max([all_y; 0]);
        y_rng = y_max - y_min;

        if y_rng == 0
            y_rng = 1;
        end

        common_ylim = [y_min - 0.10*y_rng, y_max + 0.10*y_rng];
    end

    ylim(ax1,common_ylim);
    ylim(ax2,common_ylim);

    line(ax1,xlim(ax1),[0 0],'Color','k','LineStyle','--');
    line(ax2,xlim(ax2),[0 0],'Color','k','LineStyle','--');

    % Small note for interpretability
    text(ax2,0.5,common_ylim(1) - 0.08*(common_ylim(2)-common_ylim(1)), ...
        'Box: Q1-Q3, line: median, whiskers: 1.5 x IQR', ...
        'Units','data', ...
        'FontSize',8, ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','top');
end

%--------------------------------------------------------------------------
% Plot standard Tukey boxplot with overlaid individual subject data points
%--------------------------------------------------------------------------
function plot_standard_box_with_points(ax,xpos,yvals,color_val)

    yvals = yvals(:);
    yvals = yvals(isfinite(yvals));

    if isempty(yvals)
        return
    end

    % Tukey boxplot statistics
    q1  = local_percentile(yvals,25);
    med = local_percentile(yvals,50);
    q3  = local_percentile(yvals,75);
    iqr_val = q3 - q1;

    lower_limit = q1 - 1.5*iqr_val;
    upper_limit = q3 + 1.5*iqr_val;

    lower_vals = yvals(yvals >= lower_limit);
    upper_vals = yvals(yvals <= upper_limit);

    if isempty(lower_vals)
        lower_whisker = min(yvals);
    else
        lower_whisker = min(lower_vals);
    end

    if isempty(upper_vals)
        upper_whisker = max(yvals);
    else
        upper_whisker = max(upper_vals);
    end

    box_width = 0.34;
    cap_width = 0.20;

    % Box: Q1-Q3
    patch(ax, ...
        [xpos-box_width/2 xpos+box_width/2 xpos+box_width/2 xpos-box_width/2], ...
        [q1 q1 q3 q3], ...
        color_val, ...
        'FaceAlpha',0.20, ...
        'EdgeColor',color_val, ...
        'LineWidth',1.2);

    % Median line
    plot(ax,[xpos-box_width/2 xpos+box_width/2],[med med], ...
        'Color','k', ...
        'LineWidth',1.5);

    % Whisker vertical line
    plot(ax,[xpos xpos],[lower_whisker upper_whisker], ...
        'Color',color_val, ...
        'LineWidth',1.2);

    % Whisker caps
    plot(ax,[xpos-cap_width/2 xpos+cap_width/2],[lower_whisker lower_whisker], ...
        'Color',color_val, ...
        'LineWidth',1.2);

    plot(ax,[xpos-cap_width/2 xpos+cap_width/2],[upper_whisker upper_whisker], ...
        'Color',color_val, ...
        'LineWidth',1.2);

    % Deterministic jittered individual data points
    n = numel(yvals);
    if n == 1
        jitter = 0;
    else
        jitter = 0.16*(local_rank_jitter(n) - 0.5);
    end

    xj = xpos + jitter(:);

    try
        scatter(ax,xj,yvals,28, ...
            'MarkerFaceColor',color_val, ...
            'MarkerEdgeColor',color_val, ...
            'MarkerFaceAlpha',0.35, ...
            'MarkerEdgeAlpha',0.35);
    catch
        % Fallback for older MATLAB versions without alpha support
        scatter(ax,xj,yvals,28, ...
            'MarkerFaceColor',color_val, ...
            'MarkerEdgeColor',color_val);
    end
end

%--------------------------------------------------------------------------
% Percentile without requiring the Statistics Toolbox
%--------------------------------------------------------------------------
function q = local_percentile(x,p)

    x = sort(x(:));
    n = numel(x);

    if n == 0
        q = NaN;
        return
    end

    if n == 1
        q = x(1);
        return
    end

    pos = 1 + (n-1)*(p/100);
    lo = floor(pos);
    hi = ceil(pos);

    if lo == hi
        q = x(lo);
    else
        q = x(lo) + (pos-lo)*(x(hi)-x(lo));
    end
end

%--------------------------------------------------------------------------
% Deterministic jitter between 0 and 1
%--------------------------------------------------------------------------
function jitter = local_rank_jitter(n)

    if n <= 1
        jitter = 0;
        return
    end
    jitter = mod((1:n)'*0.61803398875,1);
    jitter = jitter - mean(jitter) + 0.5;
end

%--------------------------------------------------------------------------
% NaN-safe mean
%--------------------------------------------------------------------------
function m = tmfc_nanmean(x)

    x = x(isfinite(x));

    if isempty(x)
        m = NaN;
    else
        m = mean(x);
    end
end

%--------------------------------------------------------------------------
% Create motion summary figure
%--------------------------------------------------------------------------
function h = create_motion_summary_figure()

    FD_summary = get_FD_summary();

    nSub = length(FD);
    FD_mean = nan(1,nSub);
    FD_max = nan(1,nSub);
    flagged_pct = nan(1,nSub);

    for iSub = 1:nSub
        FD_mean(iSub) = FD(iSub).FD_mean;
        FD_max(iSub) = FD(iSub).FD_max;

        nScan = 0;
        nFlag = 0;
        for jSess = 1:length(FD(iSub).Sess)
            ts = FD(iSub).Sess(jSess).FD_ts;
            nScan = nScan + numel(ts);
            nFlag = nFlag + sum(ts > FD_summary.FDthr);
        end

        if nScan > 0
            flagged_pct(iSub) = 100*nFlag/nScan;
        end
    end

    h = figure('Name','TMFC denoise QC: motion summary', ...
        'NumberTitle','off', ...
        'Units','normalized', ...
        'Position',[0.20 0.15 0.60 0.70], ...
        'Color','w', ...
        'Visible','on');

    subplot(3,1,1);
    bar(FD_mean);
    box on
    ylabel('Mean FD, [mm]');
    title('Mean framewise displacement');
    xlim([0 nSub+1]);

    subplot(3,1,2);
    bar(FD_max);
    box on
    ylabel('Max FD, [mm]');
    title('Maximum framewise displacement');
    xlim([0 nSub+1]);

    subplot(3,1,3);
    bar(flagged_pct);
    box on
    xlabel('Subjects');
    ylabel('Flagged scans, [%]');
    title(['Percentage of scans with FD > ' fmt(FD_summary.FDthr,2) ' mm']);
    xlim([0 nSub+1]);
    hold on
    y = ylim;
    line([0 nSub+1],[25 25], ...
        'Color','k','LineStyle','--');
    ylim([min(y(1),0) max(y(2),27.5)]);
end

%--------------------------------------------------------------------------
% Create task correlations figure
%--------------------------------------------------------------------------
function h = create_task_correlations_figure()

    task_summary = get_task_summary();

    if ~isempty(postDVARS)
        taskDV_meanabs = task_summary.postTaskDV_meanabs_raw;
        taskDV_maxabs  = task_summary.postTaskDV_maxabs_raw;
        dv_label = 'After denoising';
    else
        taskDV_meanabs = task_summary.preTaskDV_meanabs_raw;
        taskDV_maxabs  = task_summary.preTaskDV_maxabs_raw;
        dv_label = 'Before denoising';
    end

    nSub = length(FD);

    h = figure('Name','TMFC denoise QC: task correlations', ...
        'NumberTitle','off', ...
        'Units','normalized', ...
        'Position',[0.20 0.15 0.60 0.70], ...
        'Color','w', ...
        'Visible','on');

    subplot(2,2,1);
    bar(task_summary.taskFD_meanabs_raw);
    box on
    title('Mean absolute task-FD');
    ylabel('|r|');
    xlabel('Subjects');
    xlim([0 nSub+1]);

    subplot(2,2,2);
    bar(task_summary.taskFD_maxabs_raw);
    box on
    title('Maximum absolute task-FD');
    ylabel('Max |r|');
    xlabel('Subjects');
    xlim([0 nSub+1]);

    subplot(2,2,3);
    bar(taskDV_meanabs);
    box on
    title(['Mean absolute task-DVARS (' dv_label ')']);
    ylabel('|r|');
    xlabel('Subjects');
    xlim([0 nSub+1]);

    subplot(2,2,4);
    bar(taskDV_maxabs);
    box on
    title(['Maximum absolute task-DVARS (' dv_label ')']);
    ylabel('Max |r|');
    xlabel('Subjects');
    xlim([0 nSub+1]);
end

%--------------------------------------------------------------------------
% Create motion summary figure: boxplots with overlaid subject data
%--------------------------------------------------------------------------
function h = create_motion_boxplots_figure()

    nSub = length(FD);

    FD_mean = nan(nSub,1);
    FD_max = nan(nSub,1);
    flagged_pct = nan(nSub,1);

    if isfield(options,'spikeregFDthr')
        FDthr = options.spikeregFDthr;
    else
        FDthr = 0.5;
    end

    for iSub = 1:nSub

        FD_mean(iSub) = FD(iSub).FD_mean;
        FD_max(iSub)  = FD(iSub).FD_max;

        nScan = 0;
        nFlag = 0;

        for jRun = 1:length(FD(iSub).Sess)
            ts = FD(iSub).Sess(jRun).FD_ts;
            nScan = nScan + numel(ts);
            nFlag = nFlag + sum(ts > FDthr);
        end

        if nScan > 0
            flagged_pct(iSub) = 100 * nFlag / nScan;
        end
    end

    color_val = [0 0.4470 0.7410]; 

    h = figure('Name','TMFC denoise QC: motion summary (boxplots)', ...
        'NumberTitle','off', ...
        'Units','normalized', ...
        'Position',[0.20 0.15 0.60 0.70], ...
        'Color','w', ...
        'Visible','off');

    % Mean FD
    ax1 = subplot(1,3,1,'Parent',h);
    draw_boxplot_with_points(ax1,FD_mean,color_val);
    ylabel(ax1,'Mean FD, [mm]');
    title(ax1,'Mean framewise displacement');

    % Max FD
    ax2 = subplot(1,3,2,'Parent',h);
    draw_boxplot_with_points(ax2,FD_max,color_val);
    ylabel(ax2,'Max FD, [mm]');
    title(ax2,'Maximum framewise displacement');

    % Percentage of flagged scans
    ax3 = subplot(1,3,3,'Parent',h);
    draw_boxplot_with_points(ax3,flagged_pct,color_val);
    ylabel(ax3,'Flagged scans, %');
    title(ax3,['Percentage of scans with FD > ' num2str(FDthr,'%.2f') ' mm']);

end

%--------------------------------------------------------------------------
% Standard boxplot with overlaid subject data points
%--------------------------------------------------------------------------
function draw_boxplot_with_points(ax,yvals,color_val)

    yvals = yvals(:);
    yvals = yvals(isfinite(yvals));

    axes(ax); cla(ax); hold(ax,'on');

    boxplot(ax,yvals, ...
        'Positions',1, ...
        'Widths',0.35, ...
        'Colors','k', ...
        'Symbol','k+');

    jitter = (rand(size(yvals)) - 0.5) * 0.16;
    scatter(ax,1 + jitter,yvals,28, ...
        'MarkerFaceColor',color_val, ...
        'MarkerEdgeColor',color_val, ...
        'MarkerFaceAlpha',0.35, ...
        'MarkerEdgeAlpha',0.35);

    set(ax,'XTick',[]);
    xlim(ax,[0.6 1.4]);
    box(ax,'on');

end

%--------------------------------------------------------------------------
% Create task-correlation QC figure: boxplots with overlaid subject data
%--------------------------------------------------------------------------
function h = create_task_correlations_boxplots_figure()

    nSub = length(FD);

    taskFD_meanabs = nan(nSub,1);
    taskFD_maxabs  = nan(nSub,1);

    taskDVARS_meanabs = nan(nSub,1);
    taskDVARS_maxabs  = nan(nSub,1);

    % Use after-denoising task-DVARS if available; otherwise use before
    if ~isempty(postDVARS)
        DVARS_source = postDVARS;
        dvars_stage_txt = 'after denoising';
    else
        DVARS_source = preDVARS;
        dvars_stage_txt = 'before denoising';
    end

    % Collect task-FD and task-DVARS correlations
    for iSub = 1:nSub

        % Task-FD correlations
        subj_taskFD = [];

        if isfield(FD(iSub),'Sess')
            for jRun = 1:length(FD(iSub).Sess)
                if isfield(FD(iSub).Sess(jRun),'taskFD_corr') && ...
                        ~isempty(FD(iSub).Sess(jRun).taskFD_corr)

                    subj_taskFD = [subj_taskFD; FD(iSub).Sess(jRun).taskFD_corr(:)];
                end
            end
        end

        subj_taskFD = subj_taskFD(isfinite(subj_taskFD));

        if ~isempty(subj_taskFD)
            taskFD_meanabs(iSub) = mean(abs(subj_taskFD));
            taskFD_maxabs(iSub)  = max(abs(subj_taskFD));
        end

        % Task-DVARS correlations
        subj_taskDVARS = [];

        if length(DVARS_source) >= iSub && isfield(DVARS_source(iSub),'DVARS') && ...
                isfield(DVARS_source(iSub).DVARS,'Sess')

            for jRun = 1:length(DVARS_source(iSub).DVARS.Sess)
                if isfield(DVARS_source(iSub).DVARS.Sess(jRun),'taskDVARS_corr') && ...
                        ~isempty(DVARS_source(iSub).DVARS.Sess(jRun).taskDVARS_corr)

                    subj_taskDVARS = [subj_taskDVARS; DVARS_source(iSub).DVARS.Sess(jRun).taskDVARS_corr(:)];
                end
            end
        end

        subj_taskDVARS = subj_taskDVARS(isfinite(subj_taskDVARS));

        if ~isempty(subj_taskDVARS)
            taskDVARS_meanabs(iSub) = mean(abs(subj_taskDVARS));
            taskDVARS_maxabs(iSub)  = max(abs(subj_taskDVARS));
        end
    end

    color_val = [0 0.4470 0.7410]; 

    h = figure('Name','TMFC denoise QC: task correlations (boxplots)', ...
        'NumberTitle','off', ...
        'Units','normalized', ...
        'Position',[0.20 0.15 0.60 0.65], ...
        'Color','w', ...
        'Visible','off');

    % Mean absolute task-FD
    ax1 = subplot(2,2,1,'Parent',h);
    draw_boxplot_with_points(ax1,taskFD_meanabs,color_val);
    set_positive_boxplot_ylim(ax1,taskFD_meanabs);
    ylabel(ax1,'|r|');
    title(ax1,'Mean absolute task-FD');

    % Maximum absolute task-FD
    ax2 = subplot(2,2,2,'Parent',h);
    draw_boxplot_with_points(ax2,taskFD_maxabs,color_val);
    set_positive_boxplot_ylim(ax2,taskFD_maxabs);
    ylabel(ax2,'Max |r|');
    title(ax2,'Maximum absolute task-FD');

    % Mean absolute task-DVARS
    ax3 = subplot(2,2,3,'Parent',h);
    draw_boxplot_with_points(ax3,taskDVARS_meanabs,color_val);
    set_positive_boxplot_ylim(ax3,taskDVARS_meanabs);
    ylabel(ax3,'|r|');
    title(ax3,['Mean absolute task-DVARS (' dvars_stage_txt ')']);

    % Maximum absolute task-DVARS
    ax4 = subplot(2,2,4,'Parent',h);
    draw_boxplot_with_points(ax4,taskDVARS_maxabs,color_val);
    set_positive_boxplot_ylim(ax4,taskDVARS_maxabs);
    ylabel(ax4,'Max |r|');
    title(ax4,['Maximum absolute task-DVARS (' dvars_stage_txt ')']);

end

%--------------------------------------------------------------------------
% Set tight y-axis limits for positive boxplot values
%--------------------------------------------------------------------------
function set_positive_boxplot_ylim(ax,yvals)

    yvals = yvals(:);
    yvals = yvals(isfinite(yvals));

    if isempty(yvals)
        ylim(ax,[0 1]);
        return
    end

    y_min = min(yvals);
    y_max = max(yvals);

    if y_max == y_min
        pad = max(0.01,0.25*y_max);
    else
        pad = max(0.01,0.15*(y_max-y_min));
    end

    y_low  = max(0,y_min-pad);
    y_high = y_max+pad;

    if y_high <= y_low
        y_high = y_low + 0.01;
    end

    ylim(ax,[y_low y_high]);
end

uiwait(DVARS_MW);
delete(DVARS_MW);
end