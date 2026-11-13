function [conditions] = tmfc_get_conditions(SPM_path,condition_names,bf,session_mode)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Gets information about conditions from an SPM.mat file.
%
% FORMAT [conditions] = tmfc_get_conditions(SPM_path)
%   SPM_path          - Path to individual subject SPM.mat file
%
% FORMAT [conditions] = tmfc_get_conditions(SPM_path,condition_names)
%   condition_names   - Cell array with condition names to include
%                       (e.g., {'Task_A','Task_B'})
%
% FORMAT [conditions] = tmfc_get_conditions(SPM_path,condition_names,bf)
%   bf                - Basis functions to include:
%                       1 = HRF
%                       2 = time derivative
%                       3 = dispersion derivative
%                       (e.g., 1 or [1 2 3])
%
% FORMAT [conditions] = tmfc_get_conditions(SPM_path,condition_names,bf,session_mode)
%   session_mode      - 'strict'   - return conditions for all runs
%                       'repeated' - use Run 1 as a template for all runs
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

if nargin < 2
    condition_names = {};
end

if nargin < 3
    bf = [];
end

if nargin < 4 || isempty(session_mode)
    session_mode = 'strict';
end

if ~strcmp(session_mode,'strict') && ~strcmp(session_mode,'repeated')
    error('Invalid session mode.');
end

conditions = struct([]);

try
    SPM = load(SPM_path).SPM;

    [bf_names,bf_file] = get_hrf_basis_info(SPM);
    nBF = length(bf_names);

    if strcmp(session_mode,'repeated')
        sessions = 1;
    else
        sessions = 1:length(SPM.Sess);
    end

    kCond = 1;
    for iSess = sessions
        for jCond = 1:length(SPM.Sess(iSess).U)
            for kPmod = 1:length(SPM.Sess(iSess).U(jCond).name)
                for kBF = 1:nBF
                    cond_name = char(SPM.Sess(iSess).U(jCond).name(kPmod));

                    if ~isempty(condition_names) && ~any(strcmp(cond_name,condition_names))
                        continue;
                    end

                    if ~isempty(bf) && ~any(kBF == bf)
                        continue;
                    end

                    conditions(kCond).sess = iSess;
                    conditions(kCond).number = jCond;
                    conditions(kCond).pmod = kPmod;
                    conditions(kCond).bf = kBF;
                    conditions(kCond).name = cond_name;

                    if strcmp(session_mode,'repeated')
                        run_name = 'All runs';
                    else
                        run_name = ['Run' num2str(iSess)];
                    end

                    if kBF == 1
                        conditions(kCond).list_name = [cond_name ' (' run_name ', Cond' num2str(jCond) ')'];
                    else
                        conditions(kCond).list_name = [cond_name ' | ' bf_names{kBF} ' (' run_name ', Cond' num2str(jCond) ')'];
                    end
                    base_file_name = ['[Run_' num2str(iSess) ']_[Cond_' num2str(jCond) ']_[' regexprep(cond_name,' ','_') ']'];

                    if kBF == 1
                        conditions(kCond).file_name = base_file_name;
                    else
                        conditions(kCond).file_name = [base_file_name '_[' bf_file{kBF} ']'];
                    end

                    kCond = kCond + 1;
                end
            end
        end
    end

catch
    disp('Selected SPM.mat file does not exist or is invalid.');
    conditions = struct([]);
end

end

%% ===========[ Function to define HRF basis functions ]===================
function [bf_names,bf_file] = get_hrf_basis_info(SPM)

    switch lower(strtrim(SPM.xBF.name))

        case 'hrf'
            bf_names = {'HRF'};
            bf_file  = {'HRF'};

        case 'hrf (with time derivative)'
            bf_names = {'HRF','Time derivative'};
            bf_file  = {'HRF','TimeDeriv'};

        case 'hrf (with time and dispersion derivatives)'
            bf_names = {'HRF','Time derivative','Dispersion derivative'};
            bf_file  = {'HRF','TimeDeriv','DispDeriv'};

        otherwise
            error('TMFC supports only canonical HRF, time derivative, and dispersion derivative.');

    end
end
