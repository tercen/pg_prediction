classdef cvResults
    properties
        title = 'Cross Validation Results';
        sampleNames
        group
        y
        cPred
        yPred
        models;
        partitionType = '';
        folds = 0;
    end
    methods
        function [cMat, grp] = confusionMatrix(oc)
            if length(oc) > 1
                error('method confusionMatrix not defined for arrays of ''cvResults'' objects');
            end
            [cMat, grp] = confusionmat(oc.group, oc.cPred);
        end
        %
        function p = mcr(oc)
            p = nan(length(oc(:)),1);

            for i=1:length(oc(:))
                cMat = oc(i).confusionMatrix;
                n = sum(cMat(:));
                k = n - sum(diag(cMat));
                p(i)   =  k/n;
            end
            
        end
        %
        function [p, grp] = predval(oc)
            for i=1:length(oc)
                [cMat, grp]=oc(i).confusionMatrix;
                p(:,i)  = diag(cMat)./(sum(cMat)');
            end
        end
        %
        function [h,t] = pamIndex(oc,style)
            if nargin < 2
                style = 'unstack';
            end
            nGroups = length(unique(oc.group));
            if nGroups > 2
                error('PamIndex only defined for 2-group classification')
            end        
            if size(oc.y,2) > 1
                % convert to PamIndex style
                yPred = 2*oc.yPred(:,2)-1;
            else
                yPred = oc.yPred;
            end
            [pred, idxSort] = sort(yPred);
            group = oc.group(idxSort);
            switch style
                case 'waterfall'
                    uGroup = unique(group);
                    pred = -pred;
                    h(1) = bar(find(group == uGroup(1)), pred(group == uGroup(1)));
                    set(h(1), 'facecolor', 'b');
                    hold on
                    h(2) = bar(find(group == uGroup(2)), pred(group == uGroup(2))); 
                    set(h(2), 'facecolor', 'r');
                    legend(h, cellstr(uGroup));
                    xlabel('Sample #');
                    ylabel('Prediction');
                    set(gca, 'ytick', [-max(oc.y(:)),0,max(oc.y(:))]...
                        ,'ygrid','on'...
                        ,'xtick',1:length(pred) );
                    if ~isempty(oc.sampleNames)
                        if length(oc.sampleNames) ~= length(pred)
                            error('wrong number of sample names');
                        end
                        labels = oc.sampleNames(idxSort);
                        set(gca, 'xtick', 1:length(labels), 'xticklabels', labels);
                    end
                    v = get(gcf, 'position');
                    v = v .*[1,1,1.75,1];;
                    set(gcf, 'position', v);
                    
                case 'unstack'
                    h = gscatter(1:length(pred), pred, group,'br','o^', 10);
                    set(h(1), 'markerfacecolor', 'b');
                    set(h(2), 'markerfacecolor', 'r');  
                    xlabel('Sample #')
                    ylabel('Predicition');
                    set(gca, 'ytick', [-max(oc.y(:)),0,max(oc.y(:))], 'ygrid','on');
                    if ~isempty(oc.sampleNames)
                        if length(oc.sampleNames) ~= length(pred)
                            error('wrong number of sample names');
                        end
                        labels = oc.sampleNames(idxSort);
                        t = text(1:length(pred), pred, labels);
                    end
                case 'stack'
                    group = nominal(group);
                    y = double(group);
                    h = gscatter(y, pred, group, 'br', 'o^', 10, 'off');
                    set(gca, 'XTick', unique(y), 'XTickLabel', char(unique(group)), ...
                             'ytick', [-max(oc.y(:)),0,max(oc.y(:))], 'ygrid','on');
                    xlabel('Group')
                    ylabel('Prediction');
                    t = [];
                otherwise
                    error('Invalid option for PamIndex style')
            end
        end
        %
        function print(oc, fid, addInfo)
            if nargin < 2 || isempty(fid)
                % print to stdout
                fid = 1;
            end
            if nargin < 3
                addInfo = [];
            end
            fprintf(fid, '%s %s\n',class(oc.models),oc.title);
            fprintf(fid, '%s\n\n', datestr(now));                
            if ~isempty(oc.group) && ~isempty(oc.cPred)    
                fprintf(fid, 'Classifier Performance\n');
                fprintf(fid, 'Cross Validation Type\t%s\tfolds\t%d\n\n',oc.partitionType, oc.folds);
                fprintf(fid, 'Miss Classification Rate\t%5.3g\n',oc.mcr);
                [pv, grp] = oc.predval;
                grp = oc.grp2char(grp);
                for i=1:length(pv)
                    fprintf(fid,'%s Predictive Value\t%5.3g\n', char(grp(i)), pv(i));
                end
                fprintf(fid, '\nConfusion Matrix\n%10s\t', 'class');
                [cMat, grp] = oc.confusionMatrix;
                grp = oc.grp2char(grp);
                for i =1:length(cMat)                    
                    fprintf(fid, '%10s\t', char(grp(i)) );
                end
                fprintf(fid, '\n');
                for i=1:length(cMat)
                    fprintf(fid, '%10s\t', char(grp(i)) );
                    fprintf(fid, '%10d\t', cMat(i,:));
                    fprintf(fid, '\n');
                end
                
            end
            if ~isempty(oc.sampleNames)
                fprintf(fid, '\nSamples\n');
                if length(oc.sampleNames) ~= length(oc.cPred)
                    fprintf(fid, 'wrong number of sample names');
                    error('wrong number of sample names');
                end
                fldHdrs = oc.createFieldHeaders;
                for i=1:length(fldHdrs)
                    fprintf(fid, '%s', fldHdrs{i});
                    fprintf(fid, '\t');
                end
                fprintf(fid, '\n');
                grp = cellstr(oc.grp2char(oc.group));
                cpred = cellstr(oc.grp2char(oc.cPred));
                for i=1:length(oc.sampleNames)
                    % handle the case of no grouping available
                   
                    if length(grp) > 1
                        strGrp= grp{i};
                    else
                        strGrp = grp{1};
                    end
                    fprintf(fid, '%d\t%s\t%s\t%s\t',i,oc.sampleNames{i}, strGrp, cpred{i});
                    for j = 1:size(oc.yPred,2)
                        fprintf(fid, '%3.3g\t', oc.yPred(i,j) );
                    end
                    if length(unique(oc.group)) == 2
                        fprintf(fid, '%3.3g\n\n', 2*oc.yPred(i,2)-1 );
                    else
                        fprintf(fid, '\n');
                    end
                end
            end
            if any(strcmp('summary', methods(oc.models)))
                fprintf(fid, '\nClassifier Summary\n');
                aSummary = oc.models(1).summary;
                fieldNames = fieldnames(aSummary);
                for i=1:length(fieldNames)
                    fprintf(fid, '%s\t%s\n', fieldNames{i}, aSummary.(fieldNames{i}) );
                end
            end
            if~isempty(addInfo)
                fprintf(fid, '\nAdditional Information\n');
                for i=1:length(addInfo)
                    fprintf(fid, '%s\n', addInfo{i});
                end
            end
            
        end
    end
    
    methods (Static = true)

    end
    %
    methods (Access = private)
        function fields = createFieldHeaders(oc)
            fields{1} = '#';
            fields{2} = 'Sample name';
            fields{3} = 'Class';
            fields{4} = 'Class prediction';
            uGroups = oc.models(1).uGroup;
            %uGroups = cellstr(oc.grp2char(uGroups));
            n = length(fields);
            for i = 1:length(uGroups)
                fields{n+i} = sprintf('%s%s', 'y', uGroups{i});
            end
            if length(uGroups) == 2
                fields{end+1} = 'PamIndex';
            end
        end
    end
    methods (Access = private, Static = true)
        function grp = grp2char(grp)
            if isnumeric(grp)
                grp = cellstr(num2str(grp));
            elseif ischar(grp)
                grp = cellstr(grp);
            end
        end        
        %
        function p = epost(et, n, k)
            p = (et.^k).*(1-et).^(n-k);
        end
    end
end
