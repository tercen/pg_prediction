function aRowAnnotation = flat2RowAnnotation(flatColumn, rowSeq, colSeq)
aRowAnnotation = flatColumn(colSeq == 1);
aRowAnnotation = aRowAnnotation(rowSeq(colSeq ==1));