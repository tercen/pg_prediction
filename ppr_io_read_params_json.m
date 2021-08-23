function [ exitCode] = ppr_io_read_params_json(jsonFile)
exitCode = 0;

global data
global metaData
global TrainingDataFile
global OutputFile
global OutputFileMat
global QuantitationType

OutputFile       = '';
OutputFileMat    = '';
QuantitationType = 'median';


if ~exist(jsonFile, 'file')
    exitCode = -1;
    ppr_util_error_message(exitCode, jsonFile);
    return
end


% Read JSON file into a string
fid = fopen(jsonFile);
raw = fread(fid, inf);
str = char(raw');
fclose(fid);


try
    jsonParams = jsondecode(str);
    
    
    data        = table();
    metaData    = cell(0, 2);
    paramIdx    = 1;
    bValueFound = false;
    
    rowFactor = '';
    colFactor = '';
    
    for i = 1:length(jsonParams)
        param = jsonParams{i};
        isDataObj = isfield(param, 'name' ) && ...
            isfield(param, 'type' ) && ...
            isfield(param, 'data' );
        
        if isDataObj == true
            data.(param.name)    = param.data;
            metaData{paramIdx,1} = param.name;
            metaData{paramIdx,2} = param.type;
            
            if strcmpi( param.type, 'value' )
                if bValueFound == false
                    data.value = param.data;
                    bValueFound = true;
                else
                    exitCode = -12;
                    ppr_util_error_message(exitCode);
                end
            end
            
            paramIdx = paramIdx +1;
        else
            param = internal_sfield_to_upper(param);
            
            if isfield(param, 'ROWFACTOR')
                rowFactor = strrep(param.ROWFACTOR, '.', '_');
            end
            
            if isfield(param, 'COLFACTOR')
                colFactor = strrep(param.COLFACTOR, '.', '_');
            end
            
            if isfield(param, 'QUANTITATIONTYPE')
                QuantitationType = param.QUANTITATIONTYPE;
            end
            
            
            if isfield(param, 'TRAININGDATAFILE')
                TrainingDataFile = param.TRAININGDATAFILE;
                
                isValid = ischar(TrainingDataFile) && ...
                    ~isempty(TrainingDataFile) && ...
                    ~isfolder(TrainingDataFile) && ...
                    exist(TrainingDataFile, 'file');
                
                if ~isValid
                    exitCode = -11;
                    ppr_util_error_message(exitCode, 'TrainingDataFile');
                end
            end
            
            if isfield(param, 'OUTPUTFILE')
                OutputFile = param.OUTPUTFILE;
                
                isValid = ischar(OutputFile) && ...
                    ~isempty(OutputFile) && ...
                    ~isfolder(OutputFile);
                
                if ~isValid
                    exitCode = -11;
                    ppr_util_error_message(exitCode, 'OutputFile');
                end
            end
            
             if isfield(param, 'OUTPUTFILEMAT')
                OutputFileMat = param.OUTPUTFILEMAT;
                
                isValid = ischar(OutputFileMat) && ...
                    ~isempty(OutputFileMat) && ...
                    ~isfolder(OutputFileMat);
                
                if ~isValid
                    exitCode = -11;
                    ppr_util_error_message(exitCode, 'OutputFileMat');
                end
            end
        end
    end
    
catch 
    exitCode = -2;
    ppr_util_error_message(exitCode, jsonFile);
end

if exitCode == 0
    if isempty(rowFactor) || isempty(colFactor) || ...
        ~is_table_col(data, rowFactor) || ~is_table_col(data, colFactor)
        exitCode = -13;
        ppr_util_error_message(exitCode);
        return
    end

    nEntries = size(data, 1);
    
    % Do not sort the unique IDs nor uniqueCols
    uniqueIds  = unique(data.(rowFactor), 'stable');
    uniqueCols = unique(data.(colFactor), 'stable');
        
    data.rowSeq = zeros( nEntries, 1);
    data.colSeq = zeros( nEntries, 1);

    for i = 1:nEntries

        data.rowSeq(i) = internal_find_in_array( data.(rowFactor)(i), uniqueIds  );
        data.colSeq(i) = internal_find_in_array( data.(colFactor)(i), uniqueCols  );

    end
    
    metaData{paramIdx,1} = 'rowSeq'; 
    metaData{paramIdx,2} = 'rowSeq'; paramIdx = paramIdx + 1;
    metaData{paramIdx,1} = 'colSeq'; 
    metaData{paramIdx,2} = 'colSeq'; paramIdx = paramIdx + 1;

    
    % ======================
    % Read-in training data
    ppr_parse_training_json(TrainingDataFile)
    
    
end
end


function s = internal_sfield_to_upper(s)
% upperfnames: converts all the field names in a structure to upper case
% get the structure field names
fnames = fieldnames(s);

for i = 1:length(fnames)
    fname = fnames{i};

    if ~strcmp(fname, upper(fname))

        s.(upper(fname)) = s.(fname);
        s = rmfield(s, fname);
    end
end
end


function idx = internal_find_in_array(str, strList)

    idx = -1;
    for i = 1:length(strList)
        if strcmp( str, strList{i} )
            idx = i;
            break
        end
    end
end


function bIsCol = is_table_col( tbl, colName )
    bIsCol = any(strcmp(colName,tbl.Properties.VariableNames));
end
