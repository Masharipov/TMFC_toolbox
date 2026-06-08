function output_paths = TMFC_denoise(SPM_paths,subject_paths,options,anat_paths,func_paths,display_FD,estimate_GLMs,clear_all,seg_paths)

% =[Task-Modulated Functional Connectivity (TMFC) Denoise Toolbox v1.5.0]=
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
localVer  = 'v1.5.0';
try
    r = webread(sprintf('https://api.github.com/repos/%s/%s/releases/latest', ...
                        'IHB-IBR-department','TMFC_denoise'), ...
                         weboptions('Timeout',5));
    latestVer = r.tag_name;
catch
    latestVer = '';
end
disp(['==============[TMFC denoise ' localVer ']==============']);
if ~isequal(localVer,latestVer) 
    disp(['Update available: ' latestVer '. Please visit: https://github.com/IHB-IBR-department/TMFC_denoise']);
end

output_paths = [];

%-Prepare inputs
%--------------------------------------------------------------------------

% Select SPM.mat files
if nargin<1 || isempty(SPM_paths)
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

% Define denoising options
if nargin<3 || isempty(options)
    options = tmfc_denoise_options_GUI;
end
if isempty(options); error('Denoising options not selected.'); end

% Check whether tissue masks are needed
need_masks = sum(options.aCompCor)~=0 || ~strcmpi(options.WM_CSF,'none') || ~strcmpi(options.GSR,'none') || options.DVARS == 1;

% Existing SPM segmentation paths
if nargin<9
    seg_paths = [];
end

% Select structural T1 images in native space
if nargin<4 || isempty(anat_paths)
    if need_masks
        anat_paths = tmfc_select_anat_GUI(subject_paths);
        if isempty(anat_paths); error('Select structural T1 files.'); end
    else
        anat_paths = [];
    end
end

% Optionally reuse existing SPM segmentation output
if need_masks && (nargin<9 || isempty(seg_paths))
    answer = questdlg(['Use existing SPM segmentation output if available?', newline, newline, ...
                       'The toolbox will automatically search the anatomical image folder ', ...
                       'for c1/c2/c3 tissue probability maps and the matching y_ deformation field. ', ...
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
if nargin<5 || isempty(func_paths)
    if (sum(options.aCompCor)~=0 || ~strcmpi(options.WM_CSF,'none') || ~strcmpi(options.GSR,'none') || options.DVARS == 1)
        func_paths = tmfc_select_func_GUI(SPM_paths,subject_paths);
        if isempty(func_paths); error('Select unsmoothed functional files.'); end
    else
        func_paths = [];
    end
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
    if ~isfield(options,'GMmask') || ~isfield(options,'WMmask') || ~isfield(options,'CSFmask') 
        [options.GMmask.prob, options.WMmask.prob, options.CSFmask.prob, ...
         options.GMmask.dilate, options.WMmask.erode, options.CSFmask.erode] = tmfc_masks_GUI();
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

end


