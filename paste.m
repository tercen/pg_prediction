function str = paste(aCellStr, sep)
if nargin == 1
    sep = ' ';
end
str = aCellStr{1};
for i=2:length(aCellStr)
    str = [str,sep, aCellStr{i}];
end


