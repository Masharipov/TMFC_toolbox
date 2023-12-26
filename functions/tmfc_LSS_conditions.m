function [cond_list] = LSS_conditions()

    try
    LG_C = evalin('base', 'tmfc');
    
        try
        load(LG_C.subjects(1).paths);

        k = 1;
        for i = 1:length(SPM.Sess)
            for j = 1:length({SPM.Sess(i).U(:).name})
                cond_list(k).sess = i;
                cond_list(k).number = j;
                cond_list(k).name = char(SPM.Sess(i).U(j).name);
                cond_list(k).list_name = [char(SPM.Sess(i).U(j).name) ' (Sess' num2str(i) ')'];
                k = k + 1;
            end 
        end
        catch 
            warning("Subjects, not selected, please select subjects & try again");
        end
    catch
        warning("TMFC varaible doesn't exist, Please launch TMFC Toolbox");
    end
    
end

% GUI window: Select conditions of interest
% All conditions:
% cond_list(k).list_name

% Remove conditions of no interest from cond_list
% tmfc.LSS_conditions = cond_list;
