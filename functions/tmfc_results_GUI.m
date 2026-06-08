function tmfc_results_GUI(sig,pval,tval,conval,alpha,correction,nperm,components,score)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI displaying results from statistical tests
% on functional connectivity matrices.
%
% =========================================================================
% Copyright (C) 2025 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin == 0

    [file, path] = uigetfile('*.mat', 'Select TMFC results *.mat file created by TMFC statistics');
    if isequal(file,0)
        file = '';
    else
        file = fullfile(path, file); 
    end   

    if ~isempty(file)
        loaded_path = load(file);
        variable_name_L = fieldnames(loaded_path);
        tmfc_results = loaded_path.(variable_name_L{1});
        try
            if all(isfield(tmfc_results,{'sig','pval','tval','conval','alpha','correction'}) == 1)
                disp('File Loaded');
                sig = tmfc_results.sig;
                pval = tmfc_results.pval;
                tval = tmfc_results.tval;
                conval = tmfc_results.conval;
                alpha = tmfc_results.alpha;
                correction = tmfc_results.correction;

                if isfield(tmfc_results,'nperm')
                    nperm = tmfc_results.nperm;
                else
                    nperm = [];
                end

                if isfield(tmfc_results,'components')
                    components = tmfc_results.components;
                else
                    components = [];
                end

                if isfield(tmfc_results,'score')
                    score = tmfc_results.score;
                else
                    score = [];
                end

                create_plot();
            else
                warning('Selected .mat file is not in TMFC results format. Please select valid TMFC results .mat file.');
                clear file tmfc_results
            end
        catch
            warning('Selected .mat file is not in TMFC results format. Please select valid TMFC results .mat file.');
            clear file
        end
    else
        warning('Selected .mat file is empty or not in TMFC results format. Please select valid TMFC results .mat file.');
        clear file
    end

elseif nargin >= 6
    if nargin < 7 || isempty(nperm)
        nperm = [];
    end
    if nargin < 8 || isempty(components)
        components = [];
    end
    if nargin < 9 || isempty(score)
        score = [];
    end
    create_plot();
end

function create_plot(~,~)
    if isempty(sig)
        warning('TMFC results are empty or invalid; nothing to display.');
        return
    else
        res_win = figure('Name','TMFC_results','NumberTitle','off', ...
            'Units','normalized','Position',[0.225 0.28 0.55 0.42], ...
            'Tag','TMFC_results','WindowStyle','modal');
        
        movegui(res_win,'center');

        plot_title = results_title(correction, alpha);
        
        ax1 = subplot(1,2,1,'Parent',res_win);
        imagesc(ax1,conval);
        try, subtitle(ax1,'Group mean'); catch, title(ax1,'Group mean'); end
        axis(ax1,'square'); colorbar(ax1); caxis(ax1,tmfc_axis(conval,1));

        ax2 = subplot(1,2,2,'Parent',res_win);
        imagesc(ax2, sig);
        try, subtitle(ax2, plot_title, 'Interpreter','none');
        catch, title(ax2, plot_title, 'Interpreter','none'); end
        axis(ax2,'square'); colorbar(ax2);
        
        colormap(ax1,'turbo');  
        set(findall(res_win,'-property','FontSize'),'FontSize',16);

        uicontrol(res_win,'Style','text','String','Results','Units','normalized', ...
            'Position',[0.461 0.92 0.09 0.05],'FontUnits','normalized','FontSize',0.75);

        save_data_btn = uicontrol('Parent',res_win,'Style','pushbutton','String','Save data', ...
            'Units','normalized','Position',[0.18 0.05 0.210 0.054], ...
            'FontUnits','normalized','FontSize',0.36);
        
        save_plot_btn = uicontrol('Parent',res_win,'Style','pushbutton','String','Save plot', ...
            'Units','normalized','Position',[0.62 0.05 0.210 0.054], ...
            'FontUnits','normalized','FontSize',0.36);

        set(save_data_btn,'callback', @int_data_saver)
        set(save_plot_btn ,'callback', @int_plot_saver)

        tmfc_results.sig = sig;
        tmfc_results.pval = pval;
        tmfc_results.tval = tval;
        tmfc_results.conval = conval;
        tmfc_results.alpha = alpha;
        tmfc_results.correction = correction;

        if ~isempty(nperm)
            tmfc_results.nperm = nperm;
        end

        if ~isempty(components)
            tmfc_results.components = components;
        end

        if ~isempty(score)
            tmfc_results.score = score;
        end
    end
end

function save_stat = int_data_saver(~,~)

    [filename_SO, pathname_SO] = uiputfile('*.mat', 'Save TMFC variable as');
    save_stat = 0;
    
    if isequal(filename_SO, 0) || isequal(pathname_SO, 0)
        warning('Results were not saved. File name or save directory not selected.');    
        return
    else
        fullpath = fullfile(pathname_SO, filename_SO);
        save_stat = saver(fullpath);
        if save_stat == 1
            fprintf('Results were saved in: %s\n', fullpath);
        else
            disp('Results were not saved.');
        end
    end       
end

function save_plot = int_plot_saver(~,~)
       
    [filename_SO, pathname_SO] = uiputfile('*.png', 'Save TMFC plot as');    
    save_plot = 0;
   
    if isequal(filename_SO, 0) || isequal(pathname_SO, 0)
        warning('Plot was not saved. File name or save directory not selected.');
        return
    else
        fullpath = fullfile(pathname_SO, filename_SO);
        save_plot = saver_plot(fullpath);
        if save_plot == 1
            fprintf('Plot was saved in: %s\n', fullpath);
        else
            disp('Plot was not saved.');
        end
    end   
end 

function savestat_flag =  saver(save_path)
    try 
        save(save_path,'tmfc_results');
        savestat_flag = 1;
    catch 
        savestat_flag = 0;
    end
end

function saveplot_flag =  saver_plot(save_path)
    saveplot_flag = 0;
    temp_res_win = [];

    try
        plot_title = results_title(correction, alpha);

        temp_res_win = figure('NumberTitle','off','Units','normalized', ...
            'Position',[0.4 0.25 0.55 0.42],'Tag','TMFC_results','Visible','off');

        ax1 = subplot(1,2,1,'Parent',temp_res_win);
        imagesc(ax1, conval);
        try, subtitle(ax1,'Group mean'); catch, title(ax1,'Group mean'); end
        axis(ax1,'square'); colorbar(ax1); caxis(ax1, tmfc_axis(conval,1));

        ax2 = subplot(1,2,2,'Parent',temp_res_win);
        imagesc(ax2, sig);
        try, subtitle(ax2, plot_title, 'Interpreter','none');
        catch, title(ax2, plot_title, 'Interpreter','none'); end
        axis(ax2,'square'); colorbar(ax2);

        try, colormap(ax1,'turbo'); end
        set(findall(temp_res_win,'-property','FontSize'),'FontSize',16);

        saveas(temp_res_win,save_path);
        saveplot_flag = 1;
    catch ME
        disp(['File not saved: ' ME.message]);
    end

    if ~isempty(temp_res_win) && isgraphics(temp_res_win)
        delete(temp_res_win);
    end
end
end

%% Title for result plot
function txt = results_title(correction, alpha)
switch correction
    case {'Uncorrected (Parametric)','uncorr'}
        txt = ['p-uncorr<', num2str(alpha)];
    case {'FDR (Parametric)','FDR'}
        txt = ['pFDR<', num2str(alpha)];
    case {'Bonferroni (Parametric)','Bonf'}
        txt = ['pBonf<', num2str(alpha)];
    case {'Uncorrected (Non-parametric)','perm_uncorr'}
        txt = ['p-perm-uncorr<', num2str(alpha)];
    case {'FDR (Non-parametric)','perm_FDR'}
        txt = ['p-permFDR<=', num2str(alpha)];
    case {'NBS FWE (Extent)','NBS_extent'}
        txt = ['NBS extent, pFWE<', num2str(alpha)];
    case {'NBS FWE (Intensity)','NBS_intensity'}
        txt = ['NBS intensity, pFWE<', num2str(alpha)];
    case {'Threshold-free NBS FWE','TFNBS'}
        txt = ['TFNBS, pFWE<', num2str(alpha)];
    otherwise
        txt = correction;
end
end

%% Threshold type: Long title -> Short title
function thr_key = threshold_key(thr_type)
    thr_key = '';
    switch thr_type
        case 'Uncorrected (Parametric)';      thr_key = 'uncorr';
        case 'FDR (Parametric)';              thr_key = 'FDR';
        case 'Bonferroni (Parametric)';       thr_key = 'Bonf';
        case 'Uncorrected (Non-parametric)';  thr_key = 'perm_uncorr';
        case 'FDR (Non-parametric)';          thr_key = 'perm_FDR';
        case 'NBS FWE (Extent)';              thr_key = 'NBS_extent';
        case 'NBS FWE (Intensity)';           thr_key = 'NBS_intensity';
        case 'Threshold-free NBS FWE';        thr_key = 'TFNBS';
        case {'uncorr','FDR','Bonf','perm_uncorr','perm_FDR', ...
              'NBS_extent','NBS_intensity','TFNBS'}
            thr_key = thr_type;
        otherwise
            thr_key = '';
    end
end