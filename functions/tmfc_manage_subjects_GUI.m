function [action, selected_subjects] = tmfc_manage_subjects_GUI(tmfc)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Manage subjects in an existing TMFC project.
%
% FORMAT [action, selected_subjects] = tmfc_manage_subjects_GUI(tmfc)
%
% Outputs:
%   action             - 'add'
%                        'remove'
%                        'remove_all'
%                        'close'
%
%   selected_subjects  - Indices of subjects selected for removal
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

action = 'close';
selected_subjects = [];

if ~isfield(tmfc,'subjects') || isempty(tmfc.subjects)
    return;
end

nSub = length(tmfc.subjects);

% Backward compatibility: subject names
if ~isfield(tmfc.subjects,'name')
    for iSub = 1:nSub
        tmfc.subjects(iSub).name = ['Subject_' num2str(iSub,'%04.f')];
    end
end

% Subject list
subject_list = cell(nSub,1);

for iSub = 1:nSub
    subject_list{iSub} = sprintf('%d. %s',iSub,tmfc.subjects(iSub).name);
end

% Main window
MW = figure('Name','Manage subjects', ...
    'NumberTitle','off', ...
    'Units','normalized', ...
    'Position',[0.36 0.28 0.30 0.48], ...
    'MenuBar','none', ...
    'ToolBar','none', ...
    'Color','w', ...
    'Resize','off', ...
    'WindowStyle','modal', ...
    'CloseRequestFcn',@close_GUI);

movegui(MW,'center');

% Header
uicontrol(MW,'Style','text', ...
    'String',sprintf('Current subjects: %d',nSub), ...
    'Units','normalized', ...
    'Position',[0.05 0.88 0.90 0.07], ...
    'BackgroundColor','w', ...
    'FontUnits','normalized', ...
    'FontSize',0.48);

% Subject list
LB = uicontrol(MW,'Style','listbox', ...
    'String',subject_list, ...
    'Min',0, ...
    'Max',2, ...
    'Value',[], ...
    'Units','normalized', ...
    'Position',[0.07 0.34 0.86 0.52], ...
    'FontUnits','points', ...
    'FontSize',11);

% Add subjects
uicontrol(MW,'Style','pushbutton', ...
    'String','Add subjects', ...
    'Units','normalized', ...
    'Position',[0.07 0.22 0.40 0.08], ...
    'FontUnits','normalized', ...
    'FontSize',0.32, ...
    'Callback',@add_subjects);

% Remove selected
uicontrol(MW,'Style','pushbutton', ...
    'String','Remove selected', ...
    'Units','normalized', ...
    'Position',[0.53 0.22 0.40 0.08], ...
    'FontUnits','normalized', ...
    'FontSize',0.32, ...
    'Callback',@remove_selected);

% Remove all
uicontrol(MW,'Style','pushbutton', ...
    'String','Remove all subjects', ...
    'Units','normalized', ...
    'Position',[0.07 0.11 0.40 0.08], ...
    'FontUnits','normalized', ...
    'FontSize',0.32, ...
    'Callback',@remove_all);

% Close
uicontrol(MW,'Style','pushbutton', ...
    'String','Close', ...
    'Units','normalized', ...
    'Position',[0.53 0.11 0.40 0.08], ...
    'FontUnits','normalized', ...
    'FontSize',0.32, ...
    'Callback',@close_GUI);

uiwait(MW);

if ishandle(MW)
    delete(MW);
end

% -------------------------------------------------------------------------
function add_subjects(~,~)
    action = 'add';
    selected_subjects = [];
    uiresume(MW);
end

% -------------------------------------------------------------------------
    function remove_selected(~,~)

    idx = get(LB,'Value');

    if isempty(idx)
        warndlg('Select one or more subjects to remove.','Manage subjects');
        return;
    end

    % Selecting all subjects is equivalent to "Remove all subjects"
    if numel(idx) == nSub
        action = 'remove_all';
        selected_subjects = 1:nSub;
    else
        action = 'remove';
        selected_subjects = idx;
    end

    uiresume(MW);
end
% -------------------------------------------------------------------------
function remove_all(~,~)
    action = 'remove_all';
    selected_subjects = 1:nSub;
    uiresume(MW);
end

% -------------------------------------------------------------------------
function close_GUI(~,~)
    action = 'close';
    selected_subjects = [];
    uiresume(MW);
end

end