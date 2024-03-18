function [tmfc] = major_reset(tmfc)

% tmfc = rmfield(tmfc, 'subjects');
% tmfc = rmfield(tmfc,'project_path');

tmfc = rmfield(tmfc,'ROI_set');
tmfc = rmfield(tmfc,'ROI_set_number');
tmfc = rmfield(tmfc,'LSS');
tmfc = rmfield(tmfc,'FIR');
tmfc = rmfield(tmfc,'LSS_after_FIR');

set(handles.TMFC_GUI_S1,'String', 'Not selected','ForegroundColor',[1, 0, 0]);
set(handles.TMFC_GUI_S2,'String', 'Not selected','ForegroundColor',[1, 0, 0]);
set(handles.TMFC_GUI_S3,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
set(handles.TMFC_GUI_S4,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
set(handles.TMFC_GUI_S6,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
set(handles.TMFC_GUI_S8,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);
set(handles.TMFC_GUI_S10,'String', 'Not done','ForegroundColor',[0.773, 0.353, 0.067]);

end