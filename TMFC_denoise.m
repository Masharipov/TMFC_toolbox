function output_paths = TMFC_denoise(SPM_paths,subject_paths,options,anat_paths,func_paths,display_FD,estimate_GLMs,clear_all,seg_paths)

% =[Task-Modulated Functional Connectivity (TMFC) Denoise Toolbox v1.5.1]=
% 
% The TMFC denoise toolbox updates the selected general linear model with
% the addition of noise regressors. It can be used prior to TMFC analysis 
% (gPPI or BSC) or standard task activation analysis. The general linear model
% must be specified and estimated in the SPM8/12/25 software (user needs
% to select the corresponding SPM.mat files).
% 
% Extraction of BOLD signals from whole-brain, GM, WM, and CSF masks 
% requires structural T1 images in native space and unsmoothed, realigned
% functional images in MNI space. If the source SPM.mat files specify paths
% to smoothed functional images, then unsmoothed functional images should
% be stored in the same folders without the smoothing prefix. 
%
% NOTE: All regressors specified in the original general linear model will
% be included in the updated model along with noise regressors. That is, 
% if the original model already contains expansions of the six motion parameters
% or physiological regressors, they may be duplicated in the updated model.
% Thus, it is necessary to select models that include six standard motion
% regressors and other confound regressors that will not be calculated by
% the TMFC denoise toolbox.
%
% Functionality of the TMFC denoise toolbox:
%
% (1) Calculates head motion parameters (temporal derivatives and quadratic
%     terms). Temporal derivatives are computed as backward differences
%     (Van Dijk et al., 2012). Quadratic terms represent 6 squared motion
%     parameters and 6 squared temporal derivatives (Satterthwaite et al., 2012).
%
% (2) Calculates framewise displacement (FD) as the sum of the absolute values
%     of the derivatives of translational and rotational motion parameters
%     (Power et al., 2012).
%
% (3) Creates spike regressors based on a user-defined FD threshold. For each
%     flagged time point, a unit impulse function is included in the general
%     linear model; it has the value 1 at that time point and 0 elsewhere.
%     (Lemieux et al., 2007; Satterthwaite et al., 2012).
%
% (4) Creates aCompCor regressors (Behzadi et al., 2007). Calculates a fixed
%     number of principal components (PCs) or variable number of PCs
%     explaining 50% of the signal variability separately for the eroded WM
%     and CSF masks (Muschelli et al., 2014).   
% 
% (5) Creates WM/CSF regressors (Fox et al., 2005). Calculates average
%     BOLD signals separately for eroded WM and CSF masks. Optionally
%     calculates derivatives and quadratic terms (Parkes et al., 2017).
%
% (6) Creates GSR regressors (Fox et al., 2005, 2009). Calculates the average
%     BOLD signal for the whole-brain mask. Optionally calculates
%     derivatives and quadratic terms (Parkes et al., 2017).
%
% (7) Calculates the temporal Derivative of root mean square VARiance over voxelS (DVARS).
%     DVARS is computed as the root mean square (RMS) of the differentiated
%     BOLD time series within the GM mask (Muschelli et al., 2014).
%     Also computes FD–DVARS correlations. 
%     DVARS is computed both before and after noise regression 
%     (for the original and updated GLM, respectively).
%
% (8) Adds noise regressors to the original model and estimates the updated model.
%     The noise regressors and the updated model will be stored in the TMFC_denoise subfolder.
%
% (9) Optionally applies robust weighted least squares (rWLS) for model estimation
%     (Diedrichsen & Shadmehr, 2005).
%     It assumes that each image has its own variance parameter; some scans
%     may be disrupted by noise (high variance). In the first pass, SPM 
%     estimates the noise variances; in the second pass, each image
%     is reweighted by the inverse of its variance.
%
% -------------------------------------------------------------------------
% FORMAT: output_paths = TMFC_denoise
% Will call GUIs to select SPM.mat files, define denoising options, select
% structural and functional files, define FD threshold for spike regression.
%
% FORMAT: output_paths = TMFC_denoise(SPM_paths,subject_paths,options,anat_paths,func_paths)
% FORMAT: output_paths = TMFC_denoise(SPM_paths,subject_paths,options,anat_paths,func_paths,display_FD,estimate_GLMs,clear_all)
% FORMAT: output_paths = TMFC_denoise(SPM_paths,subject_paths,options,anat_paths,func_paths,display_FD,estimate_GLMs,clear_all,seg_paths)
% Performs noise regression without calling the GUI.
% 
% INPUTS: 
% SPM_paths             - Cell array containing paths to SPM.mat files that
%                         need to be re-estimated with noise regressors
%                         (e.g., C:\fMRI_project\sub-01\stat\GLM-01\SPM.mat)
%
% subject_paths         - Cell array of subject folders corresponding to SPM_paths
%                         (e.g., C:\fMRI_project\sub-01)
%         
% options.motion        - '6HMP' : do not add additional motion regressors
%                       - '12HMP': add 6 temporal derivatives
%                       - '24HMP': add 6 temporal derivatives and 12 quadratic terms
%
% Order of motion regressors in SPM.Sess.C structure:
% options.translation_idx - [1 2 3] (default)
% options.rotation_idx    - [4 5 6] (default)
% In SPM, HCP, and fMRIPrep the first three regressors are translations; 
% in FSL and AFNI the first three are rotations.
%
% options.rotation_unit - Rotation units:
%                       - 'rad' (radians, e.g., SPM, FSL, fMRIPrep)
%                       - 'deg' (degrees, e.g., HCP, AFNI)
%
% options.head_radius   - Approximate head radius in mm (Default: 50)
%
% options.DVARS         - 0 (none) or 1 (calculate)
%
% options.aCompCor      - Number of aCompCor regressors for the WM mask
%                         and CSF masks (Default: [5 5]; None: [0 0];
%                         aCompCor50%: [0.5 0.5])
% options.aCompCor_ort  - Pre-orthogonalize WM and CSF signals w.r.t. high-pass
%                         filter (HPF) regressors and head motion
%                         regressors prior to PC calculation (Default: 1)
%
% options.rWLS          - 0 (none) or 1 (apply rWLS)
%
% options.spikereg      - 0 (none) or 1 (add spike regressors)
% options.spikeregFDthr - FD threshold for creating spike regressors in mm (Default: 0.5)
%
% options.WM_CSF        - 'none' : do not add WM and CSF regressors
%                       - '2Phys': add WM and CSF signals 
%                       - '4Phys': add WM and CSF signals and 2 temporal derivatives
%                       - '8Phys': add WM and CSF signals, 2 temporal derivatives, and 4 quadratic terms
%
% options.GSR           - 'none': do not add whole-brain signal
%                       - 'GSR' : add whole-brain signal
%                       - '2GSR': add whole-brain signal and its temporal derivative
%                       - '4GSR': add whole-brain signal, its temporal derivative, and 2 quadratic terms
%
% options.parallel      - 0 or 1: Sequential or parallel computation
%
% options.GMmask.prob   - Probability threshold for the liberal GM mask (Default: 0.95)
% options.WMmask.prob   - Probability threshold for the WM mask (Default: 0.99)
% options.CSFmask.prob  - Probability threshold for the CSF mask (Default: 0.99)
% options.GMmask.dilate - Dilation cycles for the GM mask (Default: 2 voxels)
% options.WMmask.erode  - Erosion cycles for the WM mask (Default: 3 voxels)
% options.CSFmask.erode - Erosion cycles for the CSF mask (Default: 2 voxels)
%
% anat_paths{iSub}.fname  - Cell array containing paths to structural T1 images
%
% func_paths{iSub}.fname  - Cell array containing paths to realigned, normalized, and unsmoothed functional images
% (NOTE: Structural images must be in the native space; functional images must be in MNI space)
%
% seg_paths             - Optional existing SPM segmentation output.
%
%                         If empty, the user will be asked whether to search
%                         automatically for existing segmentation files.
%
%                         If 'auto', the toolbox searches the folder of each
%                         selected anatomical image for:
%                         c1*.nii, c2*.nii, c3*.nii, y_*.nii, and m*.nii.
%
%                         If a structure array is provided, it should contain:
%                         seg_paths(iSub).GM  - c1 image
%                         seg_paths(iSub).WM  - c2 image
%                         seg_paths(iSub).CSF - c3 image
%                         seg_paths(iSub).def - y_ deformation field
%                         seg_paths(iSub).m   - optional bias-corrected T1
%
%                         If c1/c2/c3/y_ are complete, segmentation is skipped
%                         for that subject. If m is missing, the raw anatomical
%                         image is used for the skull-stripped QC image.
%
% display_FD    - 1 or 0 : Display individual FD plots (Default: 1)
% estimate_GLMs - 1 or 0 : Estimate GLMs with noise regressors (Default: 1)
% clear_all     - 1 or 0 : Delete any existing files in 'TMFC_denoise'
%                          subfolders before creating new files (Default: 0)  
%
% OUTPUT: 
% output_paths  - Cell array containing paths to estimated GLMs
%                 with added noise regressors. 
%
% =========================================================================
%
% Copyright (C) 2026 Ruslan Masharipov
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.
%
% Contact email: masharipov@ihb.spb.ru

%-Check SPM version
%--------------------------------------------------------------------------
if exist('spm','file')
    spm_version = spm('Ver');
    if ~isequal(spm_version,'SPM12') && ~isequal(spm_version,'SPM25')
        warning('Your SPM version: %s. TMFC_denoise toolbox was tested only with SPM12 and SPM25.', spm_version)
    end
else
    error('SPM not found on MATLAB path.');
end

%-Check TMFC_denoise version
%--------------------------------------------------------------------------
localVer  = 'v1.5.1';
try
    r = webread(sprintf('https://api.github.com/repos/%s/%s/releases/latest', ...
                        'IHB-IBR-department','TMFC_denoise'), ...
                         weboptions('Timeout',5));
    latestVer = r.tag_name;
catch
    latestVer = '';
end
disp(['==============[TMFC denoise ' localVer ']==============']);
if isempty(latestVer)
    fprintf(2,['Could not check for updates automatically. ' ...
        'Please check the latest version on GitHub:\n' ...
        'https://github.com/IHB-IBR-department/TMFC_denoise/releases\n']);
elseif ~strcmp(localVer,latestVer)
    fprintf('Update available: %s. Please visit: https://github.com/IHB-IBR-department/TMFC_denoise/releases\n',latestVer);
end

output_paths = [];

% Project setup files are used only when the GUI is started without inputs
gui_project_mode = (nargin == 0);
loaded_setup = false;
autosave_path = '';

if gui_project_mode
    SPM_paths = [];
    subject_paths = [];
    options = [];
    anat_paths = [];
    func_paths = [];
    seg_paths = [];

    start_mode = tmfc_choose_analysis_mode();

    switch start_mode
        case 'New analysis'
            % Select folder for automatic setup saves
            autosave_dir = uigetdir(pwd,'Select folder for TMFC_denoise autosaves');
            if isequal(autosave_dir,0), return; end
        case 'Load saved analysis'
            [setup_file, setup_dir] = uigetfile('*.mat','Open a saved TMFC_denoise analysis setup');
            if isequal(setup_file,0), return; end
            project_file = fullfile(setup_dir,setup_file);
            saved = load(project_file,'setup');
            if ~isfield(saved,'setup') || ~isstruct(saved.setup) || ...
                    ~isscalar(saved.setup) || ~isfield(saved.setup,'format') || ...
                    ~strcmp(saved.setup.format,'TMFC_denoise_setup')
                error('Not a valid TMFC_denoise analysis setup: %s',project_file);
            end
            required = {'SPM_paths','subject_paths','options','anat_paths','func_paths','seg_paths'};
            for iField = 1:numel(required)
                if ~isfield(saved.setup,required{iField})
                    error('The selected setup is missing: %s',required{iField});
                end
            end
            SPM_paths = saved.setup.SPM_paths;
            subject_paths = saved.setup.subject_paths;
            options = saved.setup.options;
            anat_paths = saved.setup.anat_paths;
            func_paths = saved.setup.func_paths;
            seg_paths = saved.setup.seg_paths;
            loaded_setup = true;
            autosave_dir = setup_dir;
            fprintf('TMFC denoise: Loaded analysis setup from %s\n',project_file);
        otherwise
            return;
    end
end

%-Prepare inputs
%--------------------------------------------------------------------------

% Select SPM.mat files
if (nargin<1 && ~gui_project_mode) || isempty(SPM_paths)
    [SPM_paths,subject_paths] = tmfc_select_subjects_GUI(0);
end
if isempty(SPM_paths); warning('Select SPM.mat files.'); return, end

% Check SPM.mat files
for iSub = 1:length(SPM_paths)
    if ~exist(SPM_paths{iSub},'file')
        error(['SPM file not found: ' SPM_paths{iSub}]); 
    end
end

% Subject paths
if nargin<2 || isempty(subject_paths)
    if isempty(subject_paths)
        subject_paths = cellstr(spm_select(inf,'dir', ...
            'Select ALL subject folders (same order as SPMs)'));
    end
end
if numel(subject_paths) ~= numel(SPM_paths)
    error(['The number of selected subject folders (' num2str(numel(subject_paths)) ...
           ') must match the number of SPM.mat files (' num2str(numel(SPM_paths)) ').']);
end

if gui_project_mode
    if ~iscell(SPM_paths) || ~iscell(subject_paths) || ...
            any(~cellfun(@ischar,SPM_paths)) || any(~cellfun(@ischar,subject_paths))
        error('SPM_paths and subject_paths must be cell arrays of paths.');
    end
    if any(~cellfun(@(p) exist(p,'dir') == 7,subject_paths))
        error('At least one subject folder does not exist.');
    end

    % Create a new autosave without overwriting existing setup files
    autosave_path = tmfc_new_autosave_path(autosave_dir);

    tmfc_write_setup(autosave_path,SPM_paths,subject_paths,options, ...
        anat_paths,func_paths,seg_paths,'files_selected',localVer);
    fprintf('TMFC denoise setup autosave: %s\n',autosave_path);
end

% Define denoising options
if gui_project_mode
    if loaded_setup && ~isempty(options)
        options = tmfc_denoise_options_GUI(options);
    else
        options = tmfc_denoise_options_GUI();
    end
elseif nargin<3 || isempty(options)
    options = tmfc_denoise_options_GUI();
end
if isempty(options)
    if gui_project_mode, return; end
    error('Denoising options not selected.');
end
if gui_project_mode
    tmfc_write_setup(autosave_path,SPM_paths,subject_paths,options, ...
        anat_paths,func_paths,seg_paths,'denoising_options',localVer);
end

% Check whether tissue masks are needed
need_masks = sum(options.aCompCor)~=0 || ~strcmpi(options.WM_CSF,'none') || ~strcmpi(options.GSR,'none') || options.DVARS == 1;

% Existing SPM segmentation paths
if nargin<9 && ~gui_project_mode
    seg_paths = [];
end

% Select structural T1 images in native space
if gui_project_mode && loaded_setup && need_masks && ~isempty(anat_paths)
    if ~tmfc_setup_anat_valid(anat_paths,numel(SPM_paths))
        warning('Saved anatomical paths are incomplete or missing. Please select them again.');
        anat_paths = [];
        seg_paths = [];  % Previous segmentation references may no longer match
    end
end
if (nargin<4 && ~gui_project_mode) || isempty(anat_paths)
    if need_masks
        anat_paths = tmfc_select_anat_GUI(subject_paths);
        if isempty(anat_paths); error('Select structural T1 files.'); end
    else
        anat_paths = [];
    end
end
if gui_project_mode
    tmfc_write_setup(autosave_path,SPM_paths,subject_paths,options, ...
        anat_paths,func_paths,seg_paths,'anatomical_paths',localVer);
end

% Optionally reuse existing SPM segmentation output
if need_masks && ((nargin<9 && ~gui_project_mode) || isempty(seg_paths))
    answer = questdlg(['Use existing SPM segmentation output if available?' sprintf('\n\n') ...
                       'The toolbox will automatically search the anatomical image folder ' ...
                       'for c1/c2/c3 tissue probability maps and the matching y_ deformation field. ' ...
                       'Subjects with missing files will be segmented as usual.'], ...
                       'TMFC denoise', ...
                       'Segment T1 images','Use existing if available','Segment T1 images');

    switch answer
        case 'Use existing if available'
            seg_paths = 'auto';
        otherwise
            seg_paths = [];
    end
end

% Select realigned and unsmoothed functional images in MNI space
if gui_project_mode && loaded_setup && need_masks && ~isempty(func_paths)
    if ~tmfc_setup_func_valid(func_paths,numel(SPM_paths))
        warning('Saved functional paths are incomplete, missing or compressed. Please select them again.');
        func_paths = [];
    end
end
if (nargin<5 && ~gui_project_mode) || isempty(func_paths)
    if need_masks
        func_paths = tmfc_select_func_GUI(SPM_paths,subject_paths);
        if isempty(func_paths); error('Select unsmoothed functional files.'); end
    else
        func_paths = [];
    end
end
if gui_project_mode
    tmfc_write_setup(autosave_path,SPM_paths,subject_paths,options, ...
        anat_paths,func_paths,seg_paths,'input_paths',localVer);
end

% Display individual FD plots
if nargin<6 || isempty(display_FD), display_FD = 1; end

% Estimate GLMs with noise regressors 
if nargin<7 || isempty(estimate_GLMs), estimate_GLMs = 1; end

% Clear "TMFC_denoise" subfolders
if nargin<8 || isempty(clear_all)
    answer = questdlg('Delete previously created TMFC_denoise files?', ...
    'TMFC denoise', ...
    'Do not delete','Delete','Do not delete');
    switch answer
        case 'Do not delete'
            clear_all = 0;
        case 'Delete'
            clear_all = 1;
    end
end

%-Create TMFC_denoise subfolders
%--------------------------------------------------------------------------
for iSub = 1:length(SPM_paths)
    GLM_subfolder = fileparts(SPM_paths{iSub});
    if clear_all == 1 && exist(fullfile(GLM_subfolder,'TMFC_denoise'),'dir')
        rmdir(fullfile(GLM_subfolder,'TMFC_denoise'),'s');
    end
    if ~exist(fullfile(GLM_subfolder,'TMFC_denoise'),'dir')
        mkdir(fullfile(GLM_subfolder,'TMFC_denoise'));
    end
    clear GLM_subfolder
end

%-Calculate head motion parameters (HMP) and framewise displacement (FD)
%--------------------------------------------------------------------------
if ~strcmpi(options.motion,'6HMP') || options.spikereg == 1 || display_FD == 1 || options.DVARS == 1
    disp('Head motion assessment...'); tic;
    FD = tmfc_head_motion(SPM_paths,subject_paths,options);
    hms = fix(mod((toc), [0, 3600, 60]) ./ [3600, 60, 1]);
    disp(['Done in ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec].']);
end

%-Plot FD time series and select FDthr for spike regression
%--------------------------------------------------------------------------
if display_FD == 1
    FDthr = tmfc_plot_FD(FD,options,SPM_paths,subject_paths,anat_paths,func_paths);
    options.spikeregFDthr = FDthr;
    if gui_project_mode
        tmfc_write_setup(autosave_path,SPM_paths,subject_paths,options, ...
            anat_paths,func_paths,seg_paths,'FD_threshold',localVer);
    end
end

%-Create spike regressors
%--------------------------------------------------------------------------
if options.spikereg == 1
    disp('----------------------------------------');
    disp('Creating spike regressors...'); tic;
    tmfc_spikereg(SPM_paths,options);
    hms = fix(mod((toc), [0, 3600, 60]) ./ [3600, 60, 1]);
    disp(['Done in ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec].']);
end

%-Create GM/WM/CSF and whole-brain masks
%--------------------------------------------------------------------------
if sum(options.aCompCor)~=0 || ~strcmpi(options.WM_CSF,'none') || ~strcmpi(options.GSR,'none')  || options.DVARS == 1
    if isempty(anat_paths); error('Select structural T1 files.'); end
    if isempty(func_paths); error('Select unsmoothed functional files.'); end
    disp('----------------------------------------');
    change_masks = ~tmfc_setup_mask_params_valid(options);
    if gui_project_mode && loaded_setup && ~change_masks
        mask_answer = questdlg('Change the previously selected mask parameters?', ...
            'TMFC denoise', 'Keep previous', 'Change', 'Cancel', 'Keep previous');
        switch mask_answer
            case 'Keep previous'
                change_masks = false;
            case 'Change'
                change_masks = true;
            otherwise
                return;
        end
    end
    if change_masks
        [options.GMmask.prob, options.WMmask.prob, options.CSFmask.prob, ...
         options.GMmask.dilate, options.WMmask.erode, options.CSFmask.erode] = tmfc_masks_GUI();
    end
    if gui_project_mode
        tmfc_write_setup(autosave_path,SPM_paths,subject_paths,options, ...
            anat_paths,func_paths,seg_paths,'mask_parameters',localVer);
    end
    disp('Creating binary masks...'); tic;
    masks = tmfc_create_masks(SPM_paths,subject_paths,anat_paths,func_paths,options,seg_paths);
    hms = fix(mod((toc), [0, 3600, 60]) ./ [3600, 60, 1]);
    disp(['Done in ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec].']);
end

%-Calculate physiological regressors
%--------------------------------------------------------------------------
if sum(options.aCompCor)~=0 || ~strcmpi(options.WM_CSF,'none') || ~strcmpi(options.GSR,'none')
    disp('----------------------------------------');
    disp('Calculating physiological regressors...'); tic;
    tmfc_physioreg(SPM_paths,subject_paths,func_paths,masks,options);
    hms = fix(mod((toc), [0, 3600, 60]) ./ [3600, 60, 1]);
    disp(['Done in ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec].']);
end

%-Estimate updated GLMs with noise regressors
%--------------------------------------------------------------------------
if estimate_GLMs == 1
    disp('----------------------------------------');
    disp('Estimating GLMs with noise regressors...'); tic;
    if ~exist('masks','var'); masks = []; end
    output_paths = tmfc_estimate_updated_GLMs(SPM_paths,masks,options);
    hms = fix(mod((toc), [0, 3600, 60]) ./ [3600, 60, 1]);
    disp(['Done in ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec].']);
end

%-Calculate and plot DVARS
%--------------------------------------------------------------------------
if options.DVARS == 1
    disp('----------------------------------------');
    disp('Calculating DVARS...'); tic;
    if ~exist('masks','var'); masks = []; end
    [preDVARS,postDVARS] = tmfc_calculate_DVARS(FD,SPM_paths,options,masks,output_paths);
    tmfc_plot_DVARS(preDVARS,postDVARS,FD,options,SPM_paths,subject_paths,anat_paths,func_paths,masks);
    hms = fix(mod((toc), [0, 3600, 60]) ./ [3600, 60, 1]);
    disp(['Done in ' num2str(hms(1),'%02.f') ':' num2str(hms(2),'%02.f') ':' num2str(hms(3),'%02.f') ' [hr:min:sec].']);
end

if gui_project_mode
    tmfc_write_setup(autosave_path,SPM_paths,subject_paths,options, ...
        anat_paths,func_paths,seg_paths,'completed',localVer);
    save_answer = questdlg('Save the analysis setup?', ...
        'TMFC denoise', 'Save a copy', 'Not now', 'Not now');
    if strcmp(save_answer,'Save a copy')
        [save_file, save_dir] = uiputfile('*.mat','Save TMFC_denoise analysis setup', ...
            fullfile(fileparts(autosave_path),'TMFC_denoise_project.mat'));
        if ~isequal(save_file,0)
            copy_path = fullfile(save_dir,save_file);
            tmfc_write_setup(copy_path,SPM_paths,subject_paths,options, ...
                anat_paths,func_paths,seg_paths,'completed',localVer);
            fprintf('TMFC denoise project saved: %s\n',copy_path);
        end
    end
end

end

% -------------------------------------------------------------------------
% Helpers for the GUI-only analysis setup workflow
% -------------------------------------------------------------------------
function path_out = tmfc_new_autosave_path(folder)
date_str = datestr(now,'dd_mm_yyyy');
time_str = lower(strrep(datestr(now,'HH_MM AM'),' ',''));
base = ['TMFC_denoise_autosave_[' date_str ']_[' time_str ']'];
path_out = fullfile(folder,[base '.mat']);
i = 1;
while exist(path_out,'file')
    path_out = fullfile(folder,sprintf('%s_%02d.mat',base,i));
    i = i+1;
end
end

function tmfc_write_setup(filename,SPM_paths,subject_paths,options,anat_paths,func_paths,seg_paths,stage,version)
setup.format = 'TMFC_denoise_setup';
setup.format_version = 1;
setup.TMFC_version = version;
setup.updated = datestr(now,30);
setup.stage = stage;
setup.SPM_paths = SPM_paths;
setup.subject_paths = subject_paths;
setup.options = options;
setup.anat_paths = anat_paths;
setup.func_paths = func_paths;
setup.seg_paths = seg_paths;

% Write to a temporary file first so a failed save does not corrupt a
% previous checkpoint. The target is replaced only after save completes.
tmp = [filename '.tmp.mat'];
save(tmp,'setup');
[ok,msg] = movefile(tmp,filename,'f');
if ~ok
    error('Failed to save TMFC_denoise setup to %s: %s',filename,msg);
end
end

function tf = tmfc_setup_mask_params_valid(options)
tf = isstruct(options) && isscalar(options) && ...
    isfield(options,'GMmask') && isfield(options,'WMmask') && ...
    isfield(options,'CSFmask') && isfield(options.GMmask,'prob') && ...
    isfield(options.GMmask,'dilate') && isfield(options.WMmask,'prob') && ...
    isfield(options.WMmask,'erode') && isfield(options.CSFmask,'prob') && ...
    isfield(options.CSFmask,'erode');
end

function tf = tmfc_setup_anat_valid(paths,nSub)
tf = iscell(paths) && numel(paths) == nSub;
if ~tf, return; end
for k = 1:nSub
    if ~ischar(paths{k}) || isempty(paths{k}) || exist(paths{k},'file') ~= 2
        tf = false;
        return;
    end
end
end

function tf = tmfc_setup_func_valid(paths,nSub)
tf = isstruct(paths) && numel(paths) == nSub && isfield(paths,'fname');
if ~tf, return; end
for k = 1:nSub
    fnames = paths(k).fname;
    if ~iscell(fnames) || isempty(fnames)
        tf = false;
        return;
    end
    for j = 1:numel(fnames)
        entry = fnames{j};
        if ~ischar(entry) || isempty(entry)
            tf = false;
            return;
        end
        img = regexprep(entry,',\d+$','');
        if ~isempty(regexpi(img,'\.nii\.gz$','once')) || exist(img,'file') ~= 2
            tf = false;
            return;
        end
    end
end
end

function mode = tmfc_choose_analysis_mode()
mode = '';

h = dialog('Name','TMFC denoise', ...
    'Position',[500 500 430 110], ...
    'Color','w', ...
    'Resize','off', ...
    'WindowStyle','modal', ...
    'CloseRequestFcn',@cancel_selection);

movegui(h,'center');

uicontrol(h,'Style','pushbutton', ...
    'String','New analysis', ...
    'Position',[20 30 185 50], ...
    'FontSize',11, ...
    'Callback',@(~,~)select_mode('New analysis'));

uicontrol(h,'Style','pushbutton', ...
    'String','Load saved analysis', ...
    'Position',[225 30 185 50], ...
    'FontSize',11, ...
    'Callback',@(~,~)select_mode('Load saved analysis'));

uiwait(h);

if isgraphics(h)
    delete(h);
end

function select_mode(selected_mode)
    mode = selected_mode;
    uiresume(h);
end

function cancel_selection(~,~)
    mode = '';
    uiresume(h);
end
end
