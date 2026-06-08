function FDthr = tmfc_plot_FD(FD,options,SPM_paths,subject_paths,anat_paths,func_paths)

% =======[ Task-Modulated Functional Connectivity Denoise Toolbox ]========
% 
% Opens a GUI with FD plots. Allows the user to select the FD threshold
% for spike regression.
%
% FORMAT: FDthr = tmfc_plot_FD(FD)
% Allows saving group FD statistics only.
%
% FORMAT: FDthr = tmfc_plot_FD(FD,options,SPM_paths,subject_paths,anat_paths,func_paths)
% Allows saving group FD statistics and TMFC denoise settings.
%
% =========================================================================
% Copyright (C) 2025 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% Display spike regression note
if nargin > 1
    if options.spikereg == 1
        spikenote = 'on';
    else
        spikenote = 'off';
    end
else
    spikenote = 'off';
end

% FD input only
if nargin == 1
    options = []; SPM_paths = []; subject_paths = []; anat_paths = []; func_paths = [];
end

% Create GUI figure
FD_MW = figure('Name','Framewise displacement','NumberTitle','off','Units','normalized','Position',[0.20 0.1 0.55 0.80],'MenuBar','none','ToolBar','none','Color','w','CloseRequestFcn',@FD_MW_exit);
FD_MW_txt1 = uicontrol(FD_MW,'Style','text','String','Select subject:','Units','normalized','Position',[0.075 0.94 0.85 0.038],'fontunits','normalized','FontSize',0.55,'HorizontalAlignment','Left','backgroundcolor','w');
FD_MW_LB1 = uicontrol(FD_MW,'Style','listbox','String',[],'Max',1,'Value',1,'Units','normalized','Position',[0.075 0.76 0.85 0.180],'FontUnits','points','FontSize',11.5,'callback',@update_plot);
movegui(FD_MW,'center');

% Create axes for plot
ax_frame = axes('Parent',FD_MW,'Units','normalized','Position',[0.075 0.43 .85 .3],'Color',[0.75 0.75 0.75]);
box(ax_frame,'on'); xlabel(ax_frame,'Scans','FontSize',9); ylabel(ax_frame,'FD, [mm]','FontSize',9); S = plot(ax_frame,[0]);


% GUI elements
if isunix; fontscale = 0.85; else; fontscale = 1; end
note_str = {'NOTE: The selected FD threshold will be used to create spike regressors (SpikeReg). For each flagged time point, a unit impulse is added to the GLM. The number of spike regressors equals the number of flagged scans.'};
FD_MW_panel_1 = uipanel(FD_MW,'Units','normalized','Position',[0.075 0.15 0.48 0.22],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
FD_MW_panel_2 = uipanel(FD_MW,'Units','normalized','Position',[0.57 0.15 0.356 0.22],'HighLightColor',[0.78 0.78 0.78],'BackgroundColor','w','BorderType','line');
FD_MW_info_box = uicontrol(FD_MW,'Style','text','String',[],'Units','normalized','Position',[0.09 0.160 0.45 0.2],'fontunits','normalized','FontSize',0.09*fontscale,'HorizontalAlignment','left','backgroundcolor','w');
FD_MW_threshold = uicontrol(FD_MW,'Style','pushbutton','String','Set FD threshold [mm]:','Units','normalized','Position',[0.66 0.27 0.18 0.050],'FontUnits','normalized','FontSize',0.34,'callback',@get_FDthr);
FD_MW_thres_edit = uicontrol(FD_MW,'Style','Edit','String','0.5','Units','normalized','Position',[0.66 0.20 0.18 0.050],'FontUnits','normalized','FontSize',0.4,'backgroundcolor','w');
FD_MW_note_txt = uicontrol(FD_MW,'Style','text','String',note_str,'Units','normalized','Position',[0.075 0.06 0.85 0.078],'fontunits','normalized','FontSize',0.22*fontscale,'HorizontalAlignment','left','backgroundcolor','w','Visible',spikenote);
FD_MW_OK = uicontrol(FD_MW,'Style','pushbutton','String','OK','Units','normalized','Position',[0.30 0.03 0.15 0.045],'FontUnits','normalized','FontSize',0.34,'callback',@confirm_FDthr);
FD_MW_SAVE = uicontrol(FD_MW,'Style','pushbutton','String','Save','Units','normalized','Position',[0.55 0.03 0.15 0.045],'FontUnits','normalized','FontSize',0.34,'callback',@save_data);

flagged = []; N_25prc = 0; N_50prc = 0; N_75prc = 0; N_95prc = 0;
mean_flagged = 0; sd_flagged = 0; max_flagged = 0; min_flagged = 0;
mean_flagged_prc = 0; sd_flagged_prc = 0; max_flagged_prc = 0; min_flagged_prc = 0;
mean_FD = 0; sd_FD = 0; max_FD = 0;

% Default FD threshold
%--------------------------------------------------------------------------
FDthr = 0.5;
plot_data(FDthr,1);

% Update FD plot
%--------------------------------------------------------------------------
function update_plot(~,~)
    selected_subject = get(FD_MW_LB1,'Value');
    plot_data(FDthr,selected_subject);
end

% Close GUI
%--------------------------------------------------------------------------
function FD_MW_exit(~,~)
    FDthr = 0.5;
    if strcmp(spikenote,'on')
        fprintf(2,'The default FD threshold of 0.5 mm will be applied for spike regression.\n');
    end
    uiresume(FD_MW);
end

% Change FDthr
%--------------------------------------------------------------------------
function get_FDthr(~,~)    
    temp_prefix = str2double(get(FD_MW_thres_edit,'String'));
    if isnan(temp_prefix)
        fprintf(2,'Please enter a non-negative value for the FD threshold.\n');
    elseif temp_prefix < 0
        fprintf(2,'Please enter a non-negative value for the FD threshold.\n');
    else
        FDthr = temp_prefix;
        selected_subject = get(FD_MW_LB1,'Value');
        plot_data(FDthr,selected_subject);
    end
end

% Export selected FDthr
%--------------------------------------------------------------------------
function confirm_FDthr(~,~)
    fprintf('Selected FD threshold is: %.3f mm.\n',FDthr);
    uiresume(FD_MW);
end

% Generate FD plot
%--------------------------------------------------------------------------
function plot_data(FD_threshold,iSub)

    if exist('ax_frame','var') && ishandle(ax_frame), delete(ax_frame); end
    if exist('S','var') && ishandle(S), delete(S); end

    % Create plot outline
    ax_frame = axes('Parent',FD_MW,'Units','normalized','Position',[0.075 0.43 .85 .3],'Color',[0.75 0.75 0.75]);
    box(ax_frame,'on'); xlabel(ax_frame,'Scans','FontSize',9); ylabel(ax_frame,'FD, [mm]','FontSize',9);
    
    FD_ts = []; sess_sum = 0; sess = 0;
    for jSess = 1:length(FD(iSub).Sess)
        FD_ts = [FD_ts; FD(iSub).Sess(jSess).FD_ts];
        sess_sum = sess_sum + length(FD(iSub).Sess(jSess).FD_ts) + 1;
        sess = [sess; sess_sum];
    end

    % Plot FD time-series
    S = plot(ax_frame, FD_ts,'Color',[0 0.447 0.7410]); 
    xlim(ax_frame,'tight'); x = xlim(ax_frame); y = ylim(ax_frame); 
    hold(ax_frame,'on');

    % Plot sessions
    for jSess = 1:length(FD(iSub).Sess)
        if jSess>1
            plot(ax_frame, [sess(jSess) sess(jSess)],[y(1) y(2)],'-k'); 
        end
        text(ax_frame, sess(jSess)+10, y(2), {['Run ' num2str(jSess)]}, 'VerticalAlignment','top');
    end
    % Plot FD threshold
    S = plot(ax_frame, [x(1) x(2)],[FD_threshold FD_threshold],'--','Color',[0.9 0.2 0.2],'LineWidth',2); text(ax_frame, x(2)+2, FD_threshold, {'FDthr'}); 
    update_text();
end

% Update text info
%--------------------------------------------------------------------------
function update_text(~,~)

    for jSub = 1:length(FD) 
        scans = 0;
        for jSess = 1:length(FD(jSub).Sess)
            flagged(jSub).Sess(jSess) = sum(FD(jSub).Sess(jSess).FD_ts > FDthr);
            scans = scans + length(FD(jSub).Sess(jSess).FD_ts);
        end
        flagged(jSub).total = sum(flagged(jSub).Sess);
        flagged(jSub).total_prc = 100*flagged(jSub).total/scans;
        clear scans
    end

    N_25prc = sum([flagged.total_prc]>25);
    N_50prc = sum([flagged.total_prc]>50);
    N_75prc = sum([flagged.total_prc]>75);
    N_95prc = sum([flagged.total_prc]>95);
    mean_flagged = round(mean([flagged.total]),1); mean_flagged_prc = round(mean([flagged.total_prc]),1);
    sd_flagged = round(std([flagged.total]),1); sd_flagged_prc = round(std([flagged.total_prc]),1);
    max_flagged = max([flagged.total]); max_flagged_prc = max([flagged.total_prc]);
    min_flagged = min([flagged.total]); min_flagged_prc = min([flagged.total_prc]);
    mean_FD = mean([FD.FD_mean]);
    sd_FD = std([FD.FD_mean]);
    max_FD = max([FD.FD_max]);
    
    lb1_str = {};
    for jSub = 1:length(FD)
        lb1_str = [lb1_str; {strcat(FD(jSub).Subject, ...
            ' :: (', num2str(round(flagged(jSub).total_prc,1),'%.1f'), ...
            '% above FDthr) :: (', num2str(flagged(jSub).total), ...
            ' scans flagged) ')}];
    end
    
    stat_str = {strcat(num2str(N_25prc),' subjects have >25% scans above FD threshold'),...
        strcat(num2str(N_50prc),' subjects have >50% scans above FD threshold'),...
        strcat(num2str(N_75prc),' subjects have >75% scans above FD threshold'),...
        strcat(num2str(N_95prc),' subjects have >95% scans above FD threshold'),...
        '------------------------------------------------------------------------------',...
        strcat('Mean number of flagged scans across subjects:',[' ' num2str(round(mean_flagged,1),'%.1f')],' (',num2str(round(mean_flagged_prc,1),'%.1f'),'%)'),...
        strcat('SD number of flagged scans across subjects:',  [' ' num2str(round(sd_flagged,1),'%.1f')],' (',num2str(round(sd_flagged_prc,1),'%.1f'),'%)'),...
        strcat('Max number of flagged scans across subjects:', [' ' num2str(max_flagged)],' (',num2str(round(max_flagged_prc,1),'%.1f'),'%)'),...
        strcat('Min number of flagged scans across subjects:', [' ' num2str(min_flagged)],' (',num2str(round(min_flagged_prc,1),'%.1f'),'%)')};
    
    set(FD_MW_info_box,'String',stat_str)
    set(FD_MW_LB1,'String',lb1_str);
end

% Save group statistics & user-specified TMFC denoise settings
%--------------------------------------------------------------------------
function save_data(~,~)
    if isempty(SPM_paths)
        [filename, pathname] = uiputfile('*.mat', 'Save FD group statistics');
        if isequal(filename,0) || isequal(pathname,0)
            fprintf(2,'FD group statistics not saved: file name or path not selected.\n'); 
        else
            fullpath = fullfile(pathname, filename);
            save(fullpath,'FD','FDthr','flagged','N_25prc','N_50prc','N_75prc','N_95prc', ...
                'mean_flagged','sd_flagged','max_flagged','min_flagged', ...
                'mean_flagged_prc','sd_flagged_prc','max_flagged_prc','min_flagged_prc', ...
                'mean_FD','sd_FD','max_FD');
            fprintf('FD group statistics saved: %s\n', fullpath);
        end
    else   
        [filename, pathname] = uiputfile('*.mat', 'Save FD group statistics and TMFC denoise settings');
        if isequal(filename,0) || isequal(pathname,0)
            fprintf(2,'FD group statistics not saved: file name or path not selected.\n'); 
        else
            fullpath = fullfile(pathname, filename);
            denoising_settings.SPM_paths = SPM_paths;
            denoising_settings.subject_paths = subject_paths;
            denoising_settings.options = options;
            denoising_settings.anat_paths = anat_paths;
            denoising_settings.func_paths = func_paths; 
            save(fullpath,'denoising_settings','FD','FDthr','flagged', ...
                'N_25prc','N_50prc','N_75prc','N_95prc', ...
                'mean_flagged','sd_flagged','max_flagged','min_flagged', ...
                'mean_flagged_prc','sd_flagged_prc','max_flagged_prc','min_flagged_prc', ...
                'mean_FD','sd_FD','max_FD');
            fprintf('FD group statistics and TMFC denoise settings saved: %s\n', fullpath);
        end
    end
end

uiwait(FD_MW);
delete(FD_MW);
end