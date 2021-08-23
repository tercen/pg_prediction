function [exitCode, X, y, spotID, strLabel] = ppr_data_format()
    exitCode = 0;
    global data
    global metaData

    X = flat2mat(data.value, data.rowSeq, data.colSeq)';
    
    if any(isnan(X(:)))
        exitCode = -7;
        pgp_util_error_message(exitCode);
        return
%         error('Missing values are not allowed');
        
    end
    % response variable
    varType     = metaData(:,2);
    %get(data, 'VarDescription');
    varNames    = metaData(:,1);

%     get(data, 'VarNames');
    yName = varNames(contains(varType, 'Color', 'IgnoreCase', true));
    
    if length(yName) ~= 1
        exitCode = -8;
        pgp_util_error_message(exitCode);
        return
%         error('Grouping must be defined using exactly one data color');
    end
    yName = char(yName);
    
    y = flat2ColumnAnnotation(data.(yName), data.rowSeq, data.colSeq);
    nGroups = length(unique(y));
    if nGroups < 2
        exitCode = -9;
        pgp_util_error_message(exitCode);
        return
%         error('Grouping must contain at least two different levels');
    end
    
    
    % retrieve spot ID's for later use
    bID = strcmpi('Spot', varType) & strcmpi('ID', varNames);
    if sum(bID) ~= 1
        exitCode = -10;
        pgp_util_error_message(exitCode);
        return
%         error('Spot ID could not be retrieved')
    end
    spotID = flat2RowAnnotation(data.ID, data.rowSeq, data.colSeq);
    
    
    % create sample labels
    labelIdx = find(contains(varType, 'Array', 'IgnoreCase', true));
    for i=1:length(labelIdx)
        label(:,i) = nominal(flat2ColumnAnnotation(data.(varNames{labelIdx(i)}), data.rowSeq, data.colSeq));
        % (creating a nominal nicely handles different types of experimental
        % factors)
    end
    for i=1:size(label,1)
        strLabel{i} =paste(cellstr(label(i,:)), '/');
    end
    
end