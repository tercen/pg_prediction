function addFactorColumn(dataColumn, levels, name, type)
global data
if isempty(data)
    data = dataset;
end
warning('off');
type = paste(cellstr(type),',');
aData = dataset({nominal(dataColumn(:), levels), name});
aData = set(aData, 'VarDescription', cellstr(type));
data = [data,aData];

