function beta_scrubbing_options = tmfc_beta_scrubbing_GUI(tmfc,FD,mode)

% =======[ Task-Modulated Functional Connectivity (TMFC) Toolbox ]=========
%
% Opens a GUI with FD plots. Allows the user to select beta scrubbing
% parameters and displays the number of flagged beta values.
%
% FORMAT: beta_scrubbing_options = tmfc_beta_scrubbing_GUI(tmfc,FD)
%
% beta scrubbing parameters:
%   FD_thr          - FD threshold in mm
%   time_window     - Time window in seconds from trial onset
%   min_flagged_TRs - Minimum number of flagged TRs required to remove beta
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin < 3 || isempty(mode)
    mode = 'LSS';
end

switch mode
    case 'LSS'
        cond_list = tmfc.LSS.conditions;
    case 'LSS_after_FIR'
        cond_list = tmfc.LSS_after_FIR.conditions;
    otherwise
        error('Unknown mode: %s. Use ''LSS'' or ''LSS_after_FIR''.', mode);
end

nSub = length(tmfc.subjects);
nCond = length(cond_list);

% -------------------------------------------------------------------------
% Precompute usable trial onsets for all subjects/conditions
% -------------------------------------------------------------------------
disp('Preparing beta-scrubbing information...');

for iSub = 1:nSub
    SPM = load(tmfc.subjects(iSub).path).SPM;
    RT = SPM.xY.RT;

    beta_info(iSub).Subject = tmfc.subjects(iSub).name;
    beta_info(iSub).RT = RT;

    for jCond = 1:nCond
        iSess = cond_list(jCond).sess;
        iU    = cond_list(jCond).number;

        tEnd = (SPM.nscan(iSess)-1)*RT;
        tMax = tEnd - 8;

        ons = SPM.Sess(iSess).U(iU).ons;

        if strcmpi(SPM.xBF.UNITS,'scans')
            ons_sec = ons * RT;
        else
            ons_sec = ons;
        end

        keep = (ons_sec >= 0) & (ons_sec <= tMax);

        beta_info(iSub).Cond(jCond).sess = iSess;
        beta_info(iSub).Cond(jCond).trial_onsets_sec = ons_sec(keep);
        beta_info(iSub).Cond(jCond).n_beta = sum(keep);
        beta_info(iSub).Cond(jCond).file_name = cond_list(jCond).file_name;
    end
end

% -------------------------------------------------------------------------
% Create GUI figure
% -------------------------------------------------------------------------
FD_MW = figure('Name','Beta scrubbing','NumberTitle','off','Units','normalized', ...
    'Position',[0.20 0.1 0.55 0.82],'MenuBar','none','ToolBar','none', ...
    'Color','w','CloseRequestFcn',@FD_MW_exit);

FD_MW_txt1 = uicontrol(FD_MW,'Style','text','String','Select subject:', ...
    'Units','normalized','Position',[0.075 0.94 0.85 0.038], ...
    'fontunits','normalized','FontSize',0.55,'HorizontalAlignment','Left', ...
    'backgroundcolor','w');

FD_MW_LB1 = uicontrol(FD_MW,'Style','listbox','String',[],'Max',1,'Value',1, ...
    'Units','normalized','Position',[0.075 0.76 0.85 0.180], ...
    'FontUnits','points','FontSize',11.5,'callback',@update_plot);

movegui(FD_MW,'center');

% Create axes for plot
ax_frame = axes('Parent',FD_MW,'Units','normalized', ...
    'Position',[0.075 0.43 .85 .3],'Color',[0.75 0.75 0.75]);
box(ax_frame,'on');
xlabel(ax_frame,'Scans','FontSize',9);
ylabel(ax_frame,'FD, [mm]','FontSize',9);
S = plot(ax_frame,[0]);

% GUI elements
if isunix; fontscale = 0.85; else; fontscale = 1; end

note_str = {'NOTE: Beta values are flagged for removal if the number of scans with FD above threshold within the selected time window from trial onset is greater than or equal to the selected minimum number of flagged TRs.'};

FD_MW_panel_1 = uipanel(FD_MW,'Units','normalized','Position',[0.075 0.15 0.48 0.22], ...
    'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');

FD_MW_panel_2 = uipanel(FD_MW,'Units','normalized','Position',[0.57 0.15 0.356 0.22], ...
    'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');

FD_MW_info_box = uicontrol(FD_MW,'Style','text','String',[], ...
    'Units','normalized','Position',[0.09 0.160 0.45 0.2], ...
    'fontunits','normalized','FontSize',0.09*fontscale, ...
    'HorizontalAlignment','left','backgroundcolor','w');

FD_MW_threshold = uicontrol(FD_MW,'Style','pushbutton', ...
    'String','Set FD threshold [mm]:', ...
    'Units','normalized','Position',[0.61 0.30 0.22 0.045], ...
    'FontUnits','normalized','FontSize',0.34,'callback',@get_FDthr);

FD_MW_window_button = uicontrol(FD_MW,'Style','pushbutton', ...
    'String','Set window [s]:', ...
    'Units','normalized','Position',[0.61 0.24 0.22 0.045], ...
    'FontUnits','normalized','FontSize',0.34,'callback',@get_window);

FD_MW_nTR_button = uicontrol(FD_MW,'Style','pushbutton', ...
    'String','Set min flagged TRs:', ...
    'Units','normalized','Position',[0.61 0.18 0.22 0.045], ...
    'FontUnits','normalized','FontSize',0.34,'callback',@get_nTR);

FD_MW_thres_edit = uicontrol(FD_MW,'Style','Edit','String','0.5', ...
    'Units','normalized','Position',[0.84 0.30 0.07 0.045], ...
    'FontUnits','normalized','FontSize',0.4,'backgroundcolor','w');

FD_MW_window_edit = uicontrol(FD_MW,'Style','Edit','String','12', ...
    'Units','normalized','Position',[0.84 0.24 0.07 0.045], ...
    'FontUnits','normalized','FontSize',0.4,'backgroundcolor','w');

FD_MW_nTR_edit = uicontrol(FD_MW,'Style','Edit','String','1', ...
    'Units','normalized','Position',[0.84 0.18 0.07 0.045], ...
    'FontUnits','normalized','FontSize',0.4,'backgroundcolor','w');

FD_MW_note_txt = uicontrol(FD_MW,'Style','text','String',note_str, ...
    'Units','normalized','Position',[0.075 0.06 0.85 0.078], ...
    'fontunits','normalized','FontSize',0.22*fontscale, ...
    'HorizontalAlignment','left','backgroundcolor','w');

FD_MW_OK = uicontrol(FD_MW,'Style','pushbutton','String','OK', ...
    'Units','normalized','Position',[0.30 0.03 0.15 0.045], ...
    'FontUnits','normalized','FontSize',0.34,'callback',@confirm_options);

FD_MW_SAVE = uicontrol(FD_MW,'Style','pushbutton','String','Save', ...
    'Units','normalized','Position',[0.55 0.03 0.15 0.045], ...
    'FontUnits','normalized','FontSize',0.34,'callback',@save_data);

flagged = [];
N_25prc = 0; N_50prc = 0; N_75prc = 0; N_95prc = 0;
mean_flagged = 0; sd_flagged = 0; max_flagged = 0; min_flagged = 0;
mean_flagged_prc = 0; sd_flagged_prc = 0; max_flagged_prc = 0; min_flagged_prc = 0;
mean_FD = 0; sd_FD = 0; max_FD = 0;

% Default beta-scrubbing options
beta_scrubbing_options.FD_thr = 0.5;
beta_scrubbing_options.time_window = 12;
beta_scrubbing_options.min_flagged_TRs = 1;

plot_data(beta_scrubbing_options.FD_thr,1);

% Update FD plot
% -------------------------------------------------------------------------
function update_plot(~,~)
    selected_subject = get(FD_MW_LB1,'Value');
    plot_data(beta_scrubbing_options.FD_thr,selected_subject);
end

% Close GUI
% -------------------------------------------------------------------------
function FD_MW_exit(~,~)
    beta_scrubbing_options = [];
    fprintf(2,'Beta scrubbing cancelled. BSC LSS computation was not initiated.\n');
    uiresume(FD_MW);
end

% Change beta-scrubbing options
% -------------------------------------------------------------------------
    function get_FDthr(~,~)
    temp_val = str2double(get(FD_MW_thres_edit,'String'));
    if isnan(temp_val) || temp_val < 0
        fprintf(2,'Please enter a non-negative value for the FD threshold.\n');
    else
        beta_scrubbing_options.FD_thr = temp_val;
        selected_subject = get(FD_MW_LB1,'Value');
        plot_data(beta_scrubbing_options.FD_thr,selected_subject);
    end
end

function get_window(~,~)
    temp_val = str2double(get(FD_MW_window_edit,'String'));
    if isnan(temp_val) || temp_val < 0
        fprintf(2,'Please enter a non-negative value for the time window.\n');
    else
        beta_scrubbing_options.time_window = temp_val;
        selected_subject = get(FD_MW_LB1,'Value');
        plot_data(beta_scrubbing_options.FD_thr,selected_subject);
    end
end

function get_nTR(~,~)
    temp_val = str2double(get(FD_MW_nTR_edit,'String'));
    if isnan(temp_val) || temp_val < 1 || mod(temp_val,1) ~= 0
        fprintf(2,'Please enter a positive integer for the minimum number of flagged TRs.\n');
    else
        beta_scrubbing_options.min_flagged_TRs = temp_val;
        selected_subject = get(FD_MW_LB1,'Value');
        plot_data(beta_scrubbing_options.FD_thr,selected_subject);
    end
end

% Export selected options
% -------------------------------------------------------------------------
function confirm_options(~,~)
    fprintf('Selected beta scrubbing options: FD threshold = %.3f mm, window = %.3f s, min flagged TRs = %d.\n', ...
        beta_scrubbing_options.FD_thr, ...
        beta_scrubbing_options.time_window, ...
        beta_scrubbing_options.min_flagged_TRs);
    uiresume(FD_MW);
end

% Generate FD plot
% -------------------------------------------------------------------------
function plot_data(FD_threshold,iSub)

    if exist('ax_frame','var') && ishandle(ax_frame), delete(ax_frame); end
    if exist('S','var') && ishandle(S), delete(S); end

    ax_frame = axes('Parent',FD_MW,'Units','normalized', ...
        'Position',[0.075 0.43 .85 .3],'Color',[0.75 0.75 0.75]);
    box(ax_frame,'on');
    xlabel(ax_frame,'Scans','FontSize',9);
    ylabel(ax_frame,'FD, [mm]','FontSize',9);

    FD_ts = []; sess_sum = 0; sess = 0;
    for jSess = 1:length(FD(iSub).Sess)
        FD_ts = [FD_ts; FD(iSub).Sess(jSess).FD_ts];
        sess_sum = sess_sum + length(FD(iSub).Sess(jSess).FD_ts) + 1;
        sess = [sess; sess_sum];
    end

    S = plot(ax_frame, FD_ts,'Color',[0 0.447 0.7410]);
    xlim(ax_frame,'tight');
    x = xlim(ax_frame);
    y = ylim(ax_frame);
    hold(ax_frame,'on');

    for jSess = 1:length(FD(iSub).Sess)
        if jSess > 1
            plot(ax_frame, [sess(jSess) sess(jSess)],[y(1) y(2)],'-k');
        end
        text(ax_frame, sess(jSess)+10, y(2), {['Run ' num2str(jSess)]}, ...
            'VerticalAlignment','top');
    end

    S = plot(ax_frame, [x(1) x(2)],[FD_threshold FD_threshold],'--', ...
        'Color',[0.9 0.2 0.2],'LineWidth',2);
    text(ax_frame, x(2)+2, FD_threshold, {'FDthr'});

    update_text();
end

% Update text info
% -------------------------------------------------------------------------
function update_text(~,~)

    for jSub = 1:nSub
        flagged(jSub).Cond = struct([]);
        flagged(jSub).total = 0;
        flagged(jSub).total_prc = 0;
        flagged(jSub).n_total_betas = 0;

        for jCond = 1:nCond
            iSess = beta_info(jSub).Cond(jCond).sess;
            ons_sec = beta_info(jSub).Cond(jCond).trial_onsets_sec(:);
            RT = beta_info(jSub).RT;
            FD_ts = FD(jSub).Sess(iSess).FD_ts;

            flagged_trials = tmfc_flag_betas_from_FD(FD_ts,ons_sec,RT,beta_scrubbing_options);

            flagged(jSub).Cond(jCond).sess = iSess;
            flagged(jSub).Cond(jCond).file_name = beta_info(jSub).Cond(jCond).file_name;
            flagged(jSub).Cond(jCond).flagged_beta = flagged_trials;
            flagged(jSub).Cond(jCond).n_flagged = sum(flagged_trials);
            flagged(jSub).Cond(jCond).n_total = length(flagged_trials);

            flagged(jSub).total = flagged(jSub).total + flagged(jSub).Cond(jCond).n_flagged;
            flagged(jSub).n_total_betas = flagged(jSub).n_total_betas + flagged(jSub).Cond(jCond).n_total;
        end

        if flagged(jSub).n_total_betas > 0
            flagged(jSub).total_prc = 100*flagged(jSub).total/flagged(jSub).n_total_betas;
        else
            flagged(jSub).total_prc = NaN;
        end
    end

    N_25prc = sum([flagged.total_prc] > 25);
    N_50prc = sum([flagged.total_prc] > 50);
    N_75prc = sum([flagged.total_prc] > 75);
    N_95prc = sum([flagged.total_prc] > 95);

    mean_flagged = round(mean([flagged.total]),1);
    mean_flagged_prc = round(mean([flagged.total_prc]),1);
    sd_flagged = round(std([flagged.total]),1);
    sd_flagged_prc = round(std([flagged.total_prc]),1);
    max_flagged = max([flagged.total]);
    max_flagged_prc = max([flagged.total_prc]);
    min_flagged = min([flagged.total]);
    min_flagged_prc = min([flagged.total_prc]);

    mean_FD = mean([FD.FD_mean]);
    sd_FD = std([FD.FD_mean]);
    max_FD = max([FD.FD_max]);

    lb1_str = {};
    for jSub = 1:nSub
        lb1_str = [lb1_str; {strcat(tmfc.subjects(jSub).name,' :: (', ...
            num2str(round(flagged(jSub).total_prc,1),'%.1f'), ...
            '% flagged betas) :: (', ...
            num2str(flagged(jSub).total), ...
            ' betas flagged) ')}];
    end

    stat_str = { ...
        strcat('Subjects with >25% flagged beta values:',[' ' num2str(N_25prc)]), ...
        strcat('Subjects with >50% flagged beta values:',[' ' num2str(N_50prc)]), ...
        strcat('Subjects with >75% flagged beta values:',[' ' num2str(N_75prc)]), ...
        strcat('Subjects with >95% flagged beta values:',[' ' num2str(N_95prc)]), ...
        '------------------------------------------------------------------------------', ...
        strcat('Mean number of flagged beta values across subjects:',[' ' num2str(round(mean_flagged,1),'%.1f')],' (',num2str(round(mean_flagged_prc,1),'%.1f'),'%)'), ...
        strcat('SD number of flagged beta values across subjects:',  [' ' num2str(round(sd_flagged,1),'%.1f')],' (',num2str(round(sd_flagged_prc,1),'%.1f'),'%)'), ...
        strcat('Max number of flagged beta values across subjects:', [' ' num2str(max_flagged)],' (',num2str(round(max_flagged_prc,1),'%.1f'),'%)'), ...
        strcat('Min number of flagged beta values across subjects:', [' ' num2str(min_flagged)],' (',num2str(round(min_flagged_prc,1),'%.1f'),'%)')};

    set(FD_MW_info_box,'String',stat_str)
    set(FD_MW_LB1,'String',lb1_str);
end

% Save group statistics and optional settings
% -------------------------------------------------------------------------
function save_data(~,~)
[filename, pathname] = uiputfile('*.mat', 'Save beta scrubbing group statistics');
if isequal(filename,0) || isequal(pathname,0)
    fprintf(2,'Beta scrubbing group statistics not saved: file name or path not selected.\n');
else
    fullpath = fullfile(pathname, filename);

    FDthr = beta_scrubbing_options.FD_thr;
    window = beta_scrubbing_options.time_window;
    min_flagged_TRs = beta_scrubbing_options.min_flagged_TRs;

    save(fullpath,'FD','beta_info','beta_scrubbing_options','flagged', ...
        'N_25prc','N_50prc','N_75prc','N_95prc', ...
        'mean_flagged','sd_flagged','max_flagged','min_flagged', ...
        'mean_flagged_prc','sd_flagged_prc','max_flagged_prc','min_flagged_prc', ...
        'mean_FD','sd_FD','max_FD');
    fprintf('Beta scrubbing group statistics saved: %s\n', fullpath);
end
end

uiwait(FD_MW);
delete(FD_MW);
end

% =========================================================================
% Flag beta values based on FD in post-onset time window
function flagged_beta = tmfc_flag_betas_from_FD(FD_ts,trial_onsets_sec,RT,beta_scrubbing_options)

flagged_beta = zeros(length(trial_onsets_sec),1);
scan_times = (0:length(FD_ts)-1)' * RT;

for kTrial = 1:length(trial_onsets_sec)
    t1 = trial_onsets_sec(kTrial);
    t2 = t1 + beta_scrubbing_options.time_window;

    idx = find(scan_times >= t1 & scan_times <= t2);

    if isempty(idx)
        continue
    end

    nFlagged = sum(FD_ts(idx) > beta_scrubbing_options.FD_thr);

    if nFlagged >= beta_scrubbing_options.min_flagged_TRs
        flagged_beta(kTrial) = 1;
    end
end
end