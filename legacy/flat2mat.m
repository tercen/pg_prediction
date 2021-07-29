function M = flat2mat(fColumn, rowSeq, colSeq)
% M = flat2mat(fColumn, rowSeq, colSeq)
M = nan(max(rowSeq), max(colSeq));
M(sub2ind(size(M), rowSeq, colSeq)) = fColumn; 
