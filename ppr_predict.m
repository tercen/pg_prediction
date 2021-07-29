function [exitCode, cr] = ppr_predict(X, y, strLabel, spotID)
    exitCode = 0;
    
    global TrainingResults
    classifier = TrainingResults;

    if ~isequal(spotID, classifier.spotID)
    %     error('Spot ID''s of the saved classifier do not correspond to that of the new data');
        exitCode = -14;
        ppr_util_error_message(exitCode);
    end

    cr = cvResults;
    cr.partitionType = 'Not applicable';
    cr.models        = classifier.finalModel;
    cr.sampleNames   = strLabel;
    cr.group         = y;

    if ~isempty(cr.group)
        cr.title = 'Test set validation results';
    else
        cr.title = 'New sample prediction results';
    end
    [cr.yPred, cr.cPred] = classifier.finalModel.predict(X);
    cr.y = round(cr.yPred);


end