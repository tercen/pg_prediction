function ppr_parse_training_json(jsonFile)

global TrainingResults;

fid = fopen(jsonFile);
raw = fread(fid, inf);
str = char(raw');
fclose(fid);

jsonParams = jsondecode(str);

% cvResults  = '';
finalModel = '';
spotID     = {};
for i = 1:length(jsonParams)
    obj = jsonParams{i};
%     disp( obj.obj_type )
    if isfield(obj, 'obj_type')
        % Final training model object
        if strcmpi( obj.obj_type, 'mgPlsda')
            trainingObj = obj.obj_data;
            finalModel  = mgPlsda(true);
            finalModel  = set_obj_fields( finalModel, trainingObj );
            finalModel.finish_init();           
        end
        
%         if strcmpi( obj.obj_type, 'cvResults')
%             cvObj = obj.obj_data;
%             cvRes = cvResults;
%             cvRes = set_obj_fields( cvRes, cvObj );
%         end
%         
        if strcmpi( obj.obj_name, 'SpotID')
            spotID = obj.data;
        
        end
    end
end

TrainingResults.spotID = spotID;
TrainingResults.finalModel = finalModel;
% ~isfield(classifier, 'spotID') || ~isfield(classifier, 'finalModel')
end

function obj = set_obj_fields( obj, jsonObj )
fieldNames = fieldnames( jsonObj );

for j = 1:length(fieldNames)
    
    if contains(fieldNames{j}, 'datatype')
        
        dt    = jsonObj.(fieldNames{j});
        fname = strrep( fieldNames{j}, '_datatype', '');
        
    
        if strcmp(dt, 'logical')
%             obj.(fname) = logical( jsonObj.(fname));
            
            try
                obj = obj.set_pvt_field(fname, logical( jsonObj.(fname) ));
            catch
                obj.(fname) =  logical( jsonObj.(fname) );
            end
        elseif strcmp(dt, 'nominal')
%             obj.(fname) = nominal( jsonObj.(fname));
            
            try
                obj = obj.set_pvt_field(fname, nominal( jsonObj.(fname) ));
            catch
                obj.(fname) =  nominal( jsonObj.(fname) );
            end
            
        elseif strcmp(dt, 'double') || ...
                strcmp(dt, 'char') || ...
                strcmp(dt, 'cell')
            
            try
                obj = obj.set_pvt_field(fname, jsonObj.(fname));
            catch
                obj.(fname) =  jsonObj.(fname);
            end
            
        elseif isempty(jsonObj.(fname))
            obj.(fname) = [];
        elseif strcmp(dt, 'cvpartition')
            
            cvObj = jsonObj.(fname);
            if strcmp( cvObj.Type, 'leaveout' )
                obj.(fname) = cvpartition(cvObj.NumObservations, 'leaveout');
            else
                obj.(fname) = cvpartition(cvObj.NumObservations, 'k', cvObj.NumTestSets);
            end
            
        else
            obj.(fname) = eval( dt );
            obj.(fname) = set_obj_fields( obj.(fname), jsonObj.(fname) );
        end
    end
end

end



% ppr_parse_training_json('/media/thiago/EXTRALINUX/Upwork/code/pg_plsda/test/output/plsda_results_training.txt')