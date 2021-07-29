function showResults(folder)
runDataFile = fullfile(folder, 'classPredictRunData.mat');
if exist(runDataFile, 'file');
    runData = load(runDataFile);
else
    return
end
try
    eval(['!open "',folder,'"']);
catch
    msgbox(['Unable to open: ',folder], 'Predict Show Results');
end

% PamIndex plot if applicable
if length(runData.cr.models(1).uGroup) == 2 && ~isempty(runData.cr.group)
   figure
   runData.cr.pamIndex('unstack');
   figure
   runData.cr.pamIndex('stack');
   set(gcf, 'Name', 'Predictions')
end



