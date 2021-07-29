classdef mgPlsda
    properties
        features = [];
        autoscale = false;
        predmethod = 'nearest';
        partition = [];
        optmetric = 'chisqr';
        bagging = 'none';
        numberOfBags = 20;
        
    end
    properties(SetAccess = private)
        beta;
        scalePars;
        n;
        yFit;
        group;
        uGroup;
        initializing;
    end 
    methods
        function obj = mgPlsda( bInit )
            
            if nargin == 0
                bInit = false;
            end
            
            obj.initializing = bInit;
            
        end
        
        
        function bVal = is_private(oc, prop)
            bVal = false;
            if strcmp(prop, 'beta')
                bVal = true;
            end
            
            if strcmp(prop, 'scalePars')
                bVal = true;
            end
            
            if strcmp(prop, 'n')
                bVal = true;
            end
            
            if strcmp(prop, 'yFit')
                bVal = true;
            end
            
            if strcmp(prop, 'group')
                bVal = true;
            end
            
            if strcmp(prop, 'uGroup')
                bVal = true;
            end
        end
        
        function oc = finish_init(oc)
            oc.initializing = false;
        end
        
        
        
        
        %
        function oc = set_pvt_field(oc, fname, val)
            if oc.initializing == true
                oc.(fname) = val; 
            else
                error('Can only set private fields during initialization');
            end
        end
        
        
        %
        function oc = set.bagging(oc,p)
            switch p
                case 'none';
                    oc.bagging = 'none';
                case 'balance'
                    oc.bagging = 'balance';
                case 'bootstrap'
                    oc.bagging = 'bootstrap';
                case 'jackknife'
                    oc.bagging = 'jackknife';
                otherwise
                    error('Property ''bagging'' must be ''none'', ''balance'', ''bootstrap'', or ''jackknife''')
            end
        end
        %
        function oc = set.partition(oc,p)
            if ~isequal(class(p), 'cvpartition') && ~isequal(class(p), 'loobspartition')
                error('p must be an object of class ''cvpartition'' or ''loobspartition''');
            else
                oc.partition = p;
            end
        end
        %
        function oc = set.autoscale(oc, p)
            if ~islogical(p)
                error('Property ''verbose'' must be logical');
            end
            oc.autoscale = p;
        end
        %
        function oc = set.predmethod(oc, p)
            switch p
                case 'nearest'
                    oc.predmethod = p;
                case 'lda'
                    oc.predmethod = p;
                otherwise
                    error('Property ''predmethod'' must be ''nearest'' or ''lda''')
            end
        end
        %
        function oc = set.optmetric(oc, p)
            switch p
                case 'chisqr'
                    oc.optmetric = p;
                case 'mcr'
                    oc.optmetric = p;
                otherwise
                    error('Property ''optmetric'' must be ''chisqr'' or ''mcr''')
            end
        end
        
        function s = summary(oc)
            s.general       = 'PLS-DA, author: R. de Wijn (c) 2015 PamGene International BV';
            s.features      = sprintf('%s', num2str(oc.features));
            s.autoscale     = num2str(oc.autoscale);
            s.predMethod    = oc.predmethod;
            if ~isempty(oc.partition)
                s.partitionType = oc.partition.Type;
                s.partitionNumberOfFolds = num2str(oc.partition.NumTestSets);
            end
            s.bagging = oc.bagging;
            s.numberOfBags = num2str(oc.numberOfBags);
        end
        %
        function [oc,y, plsInfo] = train(oc, X, group)
            % [oc,y] = plsda.train(oc, X, group)
            % train pls-da classifier
            % IN: mgPlsda object, X predictor matrix, group: grouping of
            % observation in X
            % OUT: oc trained mgPlsda object, y response used
            % plsInfo
            if ~isvector(group)
                error('group must be a vector');
            end
          
            if length(unique(group)) < 2
                error('classification:lessThanTwoGroups', 'there must be at least two groups in the data');
            end
            [y, uGrp] = oc.grp2y(group);
            if length(uGrp) > length(unique(group))
                error('classification:groupWithoutExample', 'for at least one of the groups there is no example in the data');
            end
            
            oc.uGroup = uGrp;            
            if size(X,1) ~= size(y,1)
                error('length of group should correspond to the number of rows of X');
            end
            oc.group = group; % store for later use
            
            % scaling
            if oc.autoscale
                oc.scalePars(1,:) = mean(X);
                oc.scalePars(2,:) = std(X);
            else
                oc.scalePars = [zeros(1, size(X,2)); ones(1, size(X,2))];
            end
            X = oc.scale(X);
            % if length features > 1 use CV to select the
            % optimal component number  
            if length(oc.features) > 1
                if isempty(oc.partition)
                    error('property ''partition'' is undefined')
                end
               [oc.n, plsInfo.oMetric]  = oc.plsSelectComp(X,y);
            else
                oc.n = oc.features;
            end
            
            lvCount = levelcounts(group);
            if isequal(oc.bagging, 'balance') && all(lvCount == lvCount(1))
                oc.bagging = 'none';
            end
            switch oc.bagging
                case 'none'
                    [plsInfo.XL,...
                     plsInfo.YL,...
                     plsInfo.XS,...
                     plsInfo.YS,...
                     oc.beta, ...
                     plsInfo.pctVar, ...
                     plsInfo.MSE,...
                     plsInfo.stats] = plsregress(X, y, oc.n);
                    
                case 'balance'
                    for i=1:oc.numberOfBags
                        bBag = oc.balancedBag(group);
                        [~,~,~,~,beta(:,:,i)] = plsregress(X(bBag,:), y(bBag,:), oc.n);
                    end
                    oc.beta = beta;
                case 'bootstrap'
                    bFail = false(oc.numberOfBags,1);
                    [~, bIdx] = bootstrp(oc.numberOfBags, [], group);
                    for i=1:oc.numberOfBags
                        bsX = X(bIdx(:,i),:);
                        bsy = y(bIdx(:,i),:);
                        bsgrp = group(bIdx(:,i));
                        bBag = oc.balancedBag(bsgrp);
                        nc = min( min(levelcounts(bsgrp(bBag))), oc.n);  
                        try
                            [~,~,~,~,beta(:,:,i)] = plsregress(bsX(bBag,:), bsy(bBag,:), nc);
                        catch
                            bFail(i) = true;
                        end
                    end
                    oc.beta = beta(:,:,~bFail);
                case 'jackknife'
                    oc.numberOfBags = length(group);
                    jn = cvpartition(group, 'leave');
                    for i=1:oc.numberOfBags
                        jnX = X(jn.training(i),:);
                        jny = y(jn.training(i),:);
                        jngrp = group(jn.training(i));
                        bBag = oc.balancedBag(jngrp);
                        [~,~,~,~,beta(:,:,i)] = plsregress(jnX(bBag,:), jny(bBag,:), oc.n);
                    end
                    oc.beta = beta;
                otherwise
                    error('Invalid value for bagging')             
            end
            
            oc.yFit = oc.yPredict(X);
        end
        %
        function yPred = yPredict(oc, X)
            if isempty(oc.beta)
                error('plsda object not trained for predicition')
            end
            if size(X,2) ~= size(oc.beta,1)-1
                error('The number of features in X does not correspond with that in the trained model');
            end
            X = oc.scale(X);
            for i=1:size(oc.beta,3)
                yPred(:,:,i) = [ones(size(X,1),1), X] * oc.beta(:,:,i);
            end
            yPred = median(yPred,3);
        end
        %
        function [cPred, p] = cPredict(oc, yPred)
            if isempty(oc.group)
                error('plsda object not trained for predicition')
            end
            
            switch oc.predmethod
                case 'nearest'
                    if nargout == 2
                        %warning('PLSDA:NoP', 'output arg p will not be calculated for this predicition method')
                        p = nan(size(yPred));
                    end
                    cPred = oc.y2grp(yPred);
                case 'lda'
                    [cPred,~,p] = classify(yPred(:, 2:end), oc.yFit(:, 2:end), oc.group, 'linear', 'empirical');
                    p = max(p,[],2);
            end
        end
        %
        function [yPred, cPred] = predict(oc, X)
            % [yPred, cPred, classes] = mgPlsda.predict(oc, X)
            % In:oc trained mgPlsda object, X: predictor matrix
            % Out: yPred: y prediction matrix, cPred: class predictions
            % classes: list of possible classes.
            yPred = oc.yPredict(X);
            cPred = oc.cPredict(yPred);
        end
        %
        function [y, uGrp] = grp2y(oc, grp)
            [gidx, uGrp] = grp2idx(grp);
            y = zeros(length(gidx), max(gidx));
            for i=1:size(y,1)
                y(i, gidx(i)) = 1;
            end
            
        end
        %
        function grp = y2grp(oc, y)
            if size(y,2) ~= size(oc.group,1)
                y = y';
            end
            
            
            
            % @TODO Why unique? What is the expected input?
            uGroup = unique(oc.group);
            [~, gIdx] = max(y, [],2);
            for i=1:size(y,1)
                % WAS uGroup
                grp(i) = oc.group(gIdx(i));
            end
            
        end
        %
    end

    methods (Access = private, Static = true)
       function bIn = balancedBag(grp)
            lvCount = levelcounts(grp);
            nIn = min(lvCount);
            grp = uint16(grp);
            bIn = false(size(grp));
            pIdx = nan(size(grp));
            for i=1:length(lvCount)
                pIdx(grp == i) = randperm(lvCount(i));
            end
            bIn(pIdx <= nIn) = true;
       end
       
    end

    methods (Access = private)
        %
        function X = scale(oc, X)
%             X=X';
            sp = oc.scalePars;

            try 
                % @FIXME
                % JSON might read this with different orientations
                % It would be better to check row or column format for each
                % of the properties, though
                X = (X - repmat(sp(1,:), size(X,1), 1)) ./ repmat(sp(2,:),size(X,1),1);
            catch
                sp = sp';
                X = (X - repmat(sp(1,:), size(X,1), 1)) ./ repmat(sp(2,:),size(X,1),1);
            end
        end
        %
        function [n,oMetric] = plsSelectComp(oc, X, y)
            % find the optimal number of pls components using internal
            % cross validation
            nf = oc.features;
            grp = oc.y2grp(y);
            if isequal(oc.partition.Type, 'kfold')
                prt = cvpartition(grp, 'kfold', oc.partition.NumTestSets);
            else
                prt = cvpartition(grp, 'leaveout');
            end
            
            for j =1:length(nf)
                ypred = nan(size(y));
                for i=1:prt.NumTestSets
                    trnX = X(prt.training(i),:);
                    trny = y(prt.training(i),:);
                    tstX = X(prt.test(i),:);
                    
                    if oc.autoscale
                        m = mean(trnX);
                        s = std(trnX);
                        trnX = (trnX-repmat(m, size(trnX,1), 1))./repmat(s, size(trnX,1), 1);
                        tstX = (tstX-repmat(m, size(tstX,1), 1))./repmat(s, size(tstX,1), 1);
                    end
                    opt = oc;
                    opt.features = nf(j);
                    try
                        opt = opt.train(trnX, oc.y2grp(trny));
                    catch aTrainingError
                        if isequal(aTrainingError.identifier, 'classification:lessThanTwoGroups') || ...
                           isequal(aTrainingError.identifier, 'classification:groupWithoutExample')
                       
                            error(...
                                'At least one of the groups is to small to run the requested component optimization. Try changing optimization settings' ...
                             );
                       
                        else
                            rethrow(aTrainingError);
                        end
                    end
                        
                        
                    ypred(prt.test(i),:) = opt.predict(tstX);
                end
                if isequal(oc.optmetric, 'chisqr')
                    ChiSqr(j) = sum( (y(:) -ypred(:)).^2);
                elseif isequal(oc.optmetric, 'mcr')
                    grpPred = oc.y2grp(ypred);
                    mcr(j) = sum(grpPred ~= grp);
                end
            end
            if isequal(oc.optmetric , 'chisqr')
                [oMetric, idx] = min(ChiSqr);           
            elseif isequal(oc.optmetric, 'mcr')
                [oMetric, idx] = min(mcr);               
            else
                error('Invalid value for ''optmetric''')
            end
            n = nf(idx);
        end
        %
    end
end
