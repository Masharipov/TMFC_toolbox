function options = tmfc_motion_definition_GUI()

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI to define motion parameter indices for FD calculation.
%
% OUTPUT
%   options.translation_idx - indices of translational regressors
%   options.rotation_idx    - indices of rotational regressors
%   options.rotation_unit   - 'rad' or 'deg'
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% Default options
options.translation_idx = [1 2 3];
options.rotation_idx = [4 5 6];
options.rotation_unit = 'rad';

set_FD_rot = {'Radians (e.g., SPM, FSL, fMRIPrep)','Degrees (e.g., HCP, AFNI)'};

GUI = figure('Name','Motion definition for FD','NumberTitle','off', ...
    'Units','normalized','Position',[0.38 0.40 0.30 0.22], ...
    'MenuBar','none','ToolBar','none','Color','w', ...
    'WindowStyle','modal','Resize','off','CloseRequestFcn',@close_GUI);

movegui(GUI,'center');

uicontrol(GUI,'Style','text','String','Specify motion regressors used for framewise displacement (FD) calculation:', ...
    'Units','normalized','Position',[0.06 0.82 0.88 0.10], ...
    'fontunits','normalized','fontsize',0.6, ...
    'HorizontalAlignment','left','BackgroundColor','w');

uicontrol(GUI,'Style','text','String','Translational regressors:', ...
    'Units','normalized','Position',[0.06 0.62 0.34 0.08], ...
    'fontunits','normalized','fontsize',0.80, ...
    'HorizontalAlignment','left','BackgroundColor','w');

uicontrol(GUI,'Style','text','String','Rotational regressors:', ...
    'Units','normalized','Position',[0.52 0.62 0.30 0.08], ...
    'fontunits','normalized','fontsize',0.80, ...
    'HorizontalAlignment','left','BackgroundColor','w');

E_trans = uicontrol(GUI,'Style','edit','String',num2str(options.translation_idx), ...
    'Units','normalized','Position',[0.365 0.61 0.12 0.10], ...
    'HorizontalAlignment','center','fontunits','normalized','fontsize',0.6, ...
    'BackgroundColor','w');

E_rot = uicontrol(GUI,'Style','edit','String',num2str(options.rotation_idx), ...
    'Units','normalized','Position',[0.785 0.61 0.12 0.10], ...
    'HorizontalAlignment','center','fontunits','normalized','fontsize',0.6, ...
    'BackgroundColor','w');

uicontrol(GUI,'Style','text','String','Rotation units:', ...
    'Units','normalized','Position',[0.06 0.40 0.28 0.08], ...
    'fontunits','normalized','fontsize',0.80, ...
    'HorizontalAlignment','left','BackgroundColor','w');

P_rot = uicontrol(GUI,'Style','popupmenu','String',set_FD_rot, ...
    'Units','normalized','Position',[0.365 0.375 0.54 0.12], ...
    'fontunits','normalized','fontsize',0.5);

uicontrol(GUI,'Style','pushbutton','String','OK', ...
    'Units','normalized','Position',[0.38 0.12 0.24 0.12], ...
    'fontunits','normalized','fontsize',0.42,'callback',@export_options);

uiwait(GUI);
delete(GUI);

    function export_options(~,~)

        trans_idx = str2double(strsplit(strtrim(get(E_trans,'String'))));
        rot_idx = str2double(strsplit(strtrim(get(E_rot,'String'))));

        if numel(trans_idx) ~= 3 || numel(rot_idx) ~= 3
            error('You must enter exactly three indices for both translational and rotational regressors.');
        elseif ~all(trans_idx == floor(trans_idx) & trans_idx > 0)
            error('Please enter positive integers for translational regressors.');
        elseif ~all(rot_idx == floor(rot_idx) & rot_idx > 0)
            error('Please enter positive integers for rotational regressors.');
        elseif numel(unique(trans_idx)) ~= 3
            error('Translational indices must be unique.');
        elseif numel(unique(rot_idx)) ~= 3
            error('Rotational indices must be unique.');
        elseif any(ismember(trans_idx,rot_idx))
            error('Translational and rotational indices must not overlap.');
        else
            options.translation_idx = trans_idx;
            options.rotation_idx = rot_idx;
        end

        rot_select = get(P_rot,'Value');
        if rot_select == 1
            options.rotation_unit = 'rad';
        else
            options.rotation_unit = 'deg';
        end

        uiresume(GUI);
    end

    function close_GUI(~,~)
        options = [];
        uiresume(GUI);
    end
end