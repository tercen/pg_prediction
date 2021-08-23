function [aNumeric, aHeader] = dataFrameOperator(folder)
% Class Predictor
% Version 3.0 (R2016A MCR)
% Creator: Rik de Wijn
% Last Modification Data: 2016-3-22
% Support status: supported
% Type: Matlab Operator Step
% Description: Predicts the class of new samples based on a previously
% stored classifier. The Operator prompts the user for selecting this
% classifier from the file system. This is a generic operator supporting
% all classifiers that created using the BN - Matlab Operator
% interface. The Operator relies on the spotID's to verify that the stored
% classifier is consistent with the new input data.
% 
%INPUT:
%Array data from Bionavigator Spreadsheet. Optionally, grouping can be defined using a single DataColor. 
%Using more than a single value per cell results in an error, missing values are not allowed.
%SpotID's have to specified in the BN spreadsheet
%
%OUTPUT (RETURNED TO BIONAVIGATOR):
%Per sample: 
%y<ClassName>, class affinity p for each class predicted using the
%classifier. The predicted class is the one with the largest affinity.
%pamIndex (2 class prediction only): y predictions converted to the "PamIndex" format.
%
%OUTPUT (SHOWRESULTS)
%1. Plot of cross validated y predictions in "PamIndex" format (Only for 2-class prediction when grouping is available). 
%2. Tab delimited text file (.xls, best viewed using MS-Excel) with details
% on predictions and classifier performance (only when grouping is
% available).
% global data
% %% Predict
% %# function mgPlsda
% %% input formatting and checking
% if length(unique(data.QuantitationType)) ~= 1
%     error('Predict cannot handle multiple quantitation types');
% end
% % predictor matrix
% X = flat2mat(data.value, data.rowSeq, data.colSeq)';
% if any(isnan(X(:)))
%     error('Missing values are not allowed');
% end
% % response variable
% varType     = get(data, 'VarDescription');
% varNames    = get(data, 'VarNames');
% yName = varNames(contains(varType, 'Color'));
% if length(yName) > 1 
%     error('Grouping must be defined using exactly one data color');
% end
% if ~isempty(yName)
%     yName = char(yName);
%     y = flat2ColumnAnnotation(data.(yName), data.rowSeq, data.colSeq);
% else
%     y = [];
% end
% % retrieve spot ID's for later use
% bID = strcmp('Spot', varType) & strcmp('ID', varNames);
% if sum(bID) ~= 1
%     error('Spot ID could not be retrieved')
% end
% spotID = flat2RowAnnotation(data.ID, data.rowSeq, data.colSeq);
% % create sample labels
% labelIdx = find(contains(varType, 'Array'));
% for i=1:length(labelIdx)
%     label(:,i) = nominal(flat2ColumnAnnotation(data.(varNames{labelIdx(i)}), data.rowSeq, data.colSeq));
%     % (creating a nominal nicely handles different types of experimental
%     % factors)
% end
% for i=1:size(label,1)
%     strLabel{i} =paste(cellstr(label(i,:)), '/');
% end
%% Propmt for saved classifier and load
fpath = fullfile(folder, 'classPredictRunData.mat');
if exist(fpath, 'file')
    runData = load(fpath);
    if isfield(runData, 'lastUsed')
        dftName = runData.lastUsed;
        filter = '*.*';
    else
         dftName = pwd;
         filter = '*.mat';
    end
else
    dftName = pwd;
    filter = '*.mat';
end
[name,path] = uigetfile(filter, 'Open a classifier', dftName);
if name == 0
    error('A classifier must be selected');
end
lastUsed = fullfile(path,name);
try
    classifier = load(lastUsed);
catch
    error(['Error while loading: ',lastUsed])
end
if ~isfield(classifier, 'spotID') || ~isfield(classifier, 'finalModel')
    error('The selected file does not appear to contain a valid classifier');
end
if ~isequal(spotID, classifier.spotID)
    error('Spot ID''s of the saved classifier do not correspond to that of the new data');
end
%% Set-up and get the predictions
cr = cvResults;
cr.partitionType = 'Not applicable';
cr.models = classifier.finalModel;
cr.sampleNames = strLabel;
cr.group = y;
if ~isempty(cr.group)
    cr.title = 'Test set validation results';
else
    cr.title = 'New sample prediction results';
end
[cr.yPred, cr.cPred] = classifier.finalModel.predict(X);
cr.y = round(cr.yPred);
%% text output to file
fname = [datestr(now,30),'PredictionResults.xls'];
fpath = fullfile(folder, fname);
fid = fopen(fpath, 'w');
if fid == -1
    error('Unable to open file for writing results')
end
try
    cr.print(fid);
    fclose(fid);
catch
    fclose(fid);
    error(lasterr)
end
%% save run data
runDataFile = fullfile(folder, 'classPredictRunData.mat');
save(runDataFile, 'cr', 'lastUsed');
%% output formatting for return to BN
aHeader{1} = 'rowSeq';
aNumeric(:,1) = double(data.rowSeq);
aHeader{2} = 'colSeq';
aNumeric(:,2) = double(data.colSeq);
lIdx = sub2ind(size(X'), data.rowSeq, data.colSeq); % linear index for converting matrix to flat output
for i=1:length(classifier.finalModel.uGroup)
    aHeader{2+i} = ['y', char(classifier.finalModel.uGroup(i))];
    yPred = repmat(cr.yPred(:,i)', size(X,2),1);
    aNumeric(:, 2 + i) = yPred(lIdx);
end
if length(classifier.finalModel.uGroup) == 2
    aHeader{size(aNumeric,2)+ 1} = 'PamIndex';
    yPred = repmat(cr.yPred(:,2)', size(X,2), 1);
    pamIndex = 2 * yPred -1;
    aNumeric(:, size(aNumeric,2)+1) = pamIndex(lIdx);
end