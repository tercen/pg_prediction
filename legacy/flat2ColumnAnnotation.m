function aColAnnotation = flat2ColumnAnnotation(flatColumn, rowSeq, colSeq)
aColAnnotation = flatColumn(rowSeq == 1);
aColAnnotation = aColAnnotation(colSeq(rowSeq ==1));