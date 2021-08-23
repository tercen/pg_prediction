function ppr_prediction_main(arglist)

global TrainingResults;
global TrainingDataFile;
global OutputFileMat;
global data;

[params, exitCode] = parse_arguments(arglist);

if exitCode == 0
    % Read data and training results
    [ exitCode] = ppr_io_read_params_json(params.infile);
    
end

if exitCode == 0
    [exitCode, X, y, spotID, strLabel] = ppr_data_format();
end

if exitCode == 0
    [exitCode, cr] = ppr_predict(X, y, strLabel, spotID);
end


if exitCode == 0
    ppr_io_save_results(cr, TrainingDataFile, X);
end



fprintf('Program finished with error code %d\n', exitCode);

end % END of function pamsoft_grid



function [params, exitCode] = parse_arguments(argline)
    exitCode = 0;
    params   = struct;
    if isempty(argline)
        exitCode = -1000;
        ppr_util_error_message(exitCode);
        return
    end
    
    argStrIdx   = strfind(argline, '--');
    argStrValid = regexp(argline, '--infile=.+', 'ONCE');
    
    if isempty(argStrValid) 
        exitCode = -1000;
        ppr_util_error_message(exitCode);
        return
    end

    % @TODO Create regex validation of the parameter passed to ensure the
    % code below works with the expected format
    
    nArgs     = length(argStrIdx);

    for i = 1:nArgs-1
        arg = argline(argStrIdx(i)+2:argStrIdx(i+1)-1);
        arg = strrep(arg, '-', '');
        
        if contains( arg, '=' ) 
            [argName, argVal] = strtok(arg, '=');
        else
            [argName, argVal] = strtok(arg, ' ');
        end
        
        params.(argName) = strtrim(argVal(2:end));
       
    end
    
    arg = argline(argStrIdx(end)+2:end);
    arg = strrep(arg, '-', '');
    
    if contains( arg, '=' ) 
        [argName, argVal] = strtok(arg, '=');
    else
        [argName, argVal] = strtok(arg, ' ');
    end

    params.(argName) = strtrim(argVal(2:end));
end