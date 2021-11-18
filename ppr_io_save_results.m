function ppr_io_save_results(cr, lastUsed, X)

global data;
global OutputFile;
global OutputFileMat;
global TrainingResults;
classifier = TrainingResults;


%-------------------------------------------
% Saving prediction results
%-------------------------------------------
if ~isempty(OutputFileMat)
    
    cvResults = cv;
    % Both can be recovered from the operator
    inputX   = X;
    classifier = lastUsed;
    save(OutputFileMat, 'cvResults', 'inputX', 'classifier');
end


if ~isempty(OutputFile)
    % Start by 0 index
    aHeader{1}    = 'rowSeq';
    aNumeric(:,1) = double(data.rowSeq - 1);
    aHeader{2}    = 'colSeq';
    aNumeric(:,2) = double(data.colSeq - 1);

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

    tbl = table( aNumeric );


    if exist(OutputFile, 'file')
        delete( OutputFile );
    end
    
    fid = fopen(OutputFile, 'w+');
    for qi = 1:length(aHeader)
        fprintf(fid, '%s', aHeader{qi});

        if qi < length(aHeader)
            fprintf(fid, ',');
        end
    end
    fclose(fid);



    writetable(tbl, OutputFile,'WriteRowNames',false, ...
        'QuoteStrings',true, 'WriteMode','Append');

end



end % END of main funciton



