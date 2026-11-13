function [threshold, mask_status] = tmfc_F_contrast_GUI(ROI_set_name)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% GUI for selecting F-contrast threshold and masking options.
%
% FORMAT [threshold, mask_status] = tmfc_F_contrast_GUI()
% FORMAT [threshold, mask_status] = tmfc_F_contrast_GUI(ROI_set_name)
%
% Optional input:
%   ROI_set_name - ROI set name displayed in the GUI window
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin < 1
    ROI_set_name = '';
end

threshold = 0.005;
mask_status = 0;

GUI_name = 'Select ROIs: F-contrast';

if ~isempty(ROI_set_name)
    GUI_name = [GUI_name ': ' ROI_set_name];
end

F_contrast_MW = figure('Name', GUI_name, 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.38 0.44 0.28 0.2],'Resize','on','MenuBar', 'none', 'ToolBar', 'none','Tag','tmfc_F_contrast_GUI', 'color', 'w','WindowStyle','modal','CloseRequestFcn', @exit_MW); 

MW_txt_1 = uicontrol(F_contrast_MW,'Style','text','String', 'Omnibus F-Contrast will be used to move spheres to local maxima','Units', 'normalized', 'Position',[0.02 0.8 0.95 0.12],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w');
MW_txt_2 = uicontrol(F_contrast_MW,'Style','text','String', 'Enter a threshold for F-contrast:','Units' ,'normalized', 'Position',[0.150 0.58 0.55 0.12],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w');
MW_txt_3 = uicontrol(F_contrast_MW,'Style','text','String', 'Mask ROI images by thresholded F-map:','Units', 'normalized', 'Position',[0.03 0.37 0.68 0.12],'fontunits','normalized', 'fontSize', 0.58,'backgroundcolor','w');

MW_E1 = uicontrol(F_contrast_MW , 'Style', 'edit', 'String', threshold,'Units', 'normalized', 'Position',[0.7 0.59 0.180 0.115],'fontunits','normalized', 'fontSize', 0.58);
MW_E2 = uicontrol(F_contrast_MW , 'Style', 'popupmenu', 'String', {'No', 'Yes'},'Units', 'normalized', 'Position',[0.7 0.35 0.180 0.15],'fontunits','normalized', 'fontSize', 0.45);
    
MW_OK = uicontrol(F_contrast_MW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.2 0.1 0.25 0.15],'fontunits','normalized', 'fontSize', 0.4,'callback', @read_data);
MW_HELP = uicontrol(F_contrast_MW,'Style','pushbutton','String', 'Help','Units', 'normalized','Position',[0.55 0.1 0.25 0.15],'fontunits','normalized', 'fontSize', 0.4,'callback', @help_window);
movegui(F_contrast_MW, 'center');

    % Read and exit data
    function read_data(~,~)
        tmp_thresh = str2double(get(MW_E1, 'String'));
        tmp_mask = get(MW_E2, 'value');
        
        if ~isnan(tmp_thresh) && isreal(tmp_thresh) && tmp_thresh >= 0 && tmp_thresh <= 1
            
            threshold = tmp_thresh;
            
            if tmp_mask == 2
                mask_status = 1;
            end
            
            fprintf('Selected threshold for F-contrast: %f \n', threshold);
            
            uiresume(F_contrast_MW);
            
        else
            fprintf(2,'Please enter a threshold value between 0.0 and 1.0 \n');
        end        
        
    end

    function help_window(~,~)
        F_contrast_HW = figure('Name', 'F-contrast: Help', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.30 0.44 0.28 0.25],'Resize','off','MenuBar', 'none', 'ToolBar', 'none', 'color', 'w','WindowStyle','modal'); 
        
        string_help = {'The center of the moving sphere will be moved to the local maximum inside a fixed sphere of larger radius.','',...
            'Local maxima are determined using the omnibus F-contrast for the selected conditions of interest.','',...
            'Additionally, moving spheres can be masked by the thresholded F-map of an individual subject. This can significantly reduce ROI size.',''};

        if isunix; fontscale = 0.8; else; fontscale = 1; end
        
        FC_HW_txt = uicontrol(F_contrast_HW,'Style','text','String', string_help,'Units', 'normalized', 'Position',[0.055 0.2 0.9 0.75],'fontunits','normalized', 'fontSize', 0.087*fontscale, 'horizontalAlignment', 'left','backgroundcolor','w');
        FC_HW_OK = uicontrol(F_contrast_HW,'Style','pushbutton','String', 'OK','Units', 'normalized','Position',[0.37 0.05 0.25 0.14],'fontunits','normalized', 'fontSize', 0.4,'callback', @close_HW);
        movegui(F_contrast_HW, 'center');
    
        function close_HW(~,~)
            close(F_contrast_HW);
        end
    end

    % If exit, do we return default values or ''
    function exit_MW(~,~)
        threshold = '';
        mask_status = '';
        uiresume(F_contrast_MW);
    end

uiwait(F_contrast_MW);
delete(F_contrast_MW);
end