classdef cv
    properties
        partition
        reps = 1;
        model
        verbose = true;
    end
   
    
    methods
        % 
        function oc = set.partition(oc, p)
            if ~isequal(class(p), 'cvpartition')
                error('p must be an object of class ''cvpartition''');
            else
                oc.partition = p;
            end
        end
        %
        function oc = set.verbose(oc, p)
            if ~islogical(p)
                error('property verbose must be logical');
            else
                oc.verbose = p;
            end
        end
        %
        function [cr,cPred,yPred, pPost] = run(oc, X, grp,names)
            if nargin < 4
                names = [];
            end
            if size(X,1) ~= length(grp)
                error('length of group should correspond to the number of rows of X');
            end
           
            %cPred = nan(size(grp));
            yPred = nan(length(grp), length(unique(grp)) );
            cPred = grp;
            pPost = nan(size(grp));
            if oc.verbose
                hWb = waitbar(0, 'Cross Validation in progress ...');
            end       
            for n= 1:oc.reps
                if n>1
                    oc.partition = repartition(oc.partition);
                end
                cr(n) = cvResults;
                cr(n).partitionType = oc.partition.Type;
                cr(n).folds = oc.partition.NumTestSets;
                cr(n).sampleNames = names;
                cr(n).group = grp;
                cr(n).models = repmat(oc.model, oc.partition.NumTestSets,1);
                for i=1:oc.partition.NumTestSets
                    
                    if oc.verbose
                        waitbar( ((n-1)*oc.partition.NumTestSets+i)/(oc.reps*oc.partition.NumTestSets));
                        %dispind(i, oc.partition.NumTestSets)
                    end
                    
                    try
                        [cr(n).models(i),cr(n).y] = oc.model.train(X(oc.partition.training(i),:), grp(oc.partition.training(i)));
                    catch aTrainingError
                         if isequal(aTrainingError.identifier, 'classification:lessThanTwoGroups') || ...
                           isequal(aTrainingError.identifier, 'classification:groupWithoutExample')
                       
                            error(...
                                'At least one of the groups is to small to run the requested cross validation. Try changing cross validation settings' ...
                             );
                       
                        else
                            rethrow(aTrainingError);
                        end
                    end
                    
                        %[yPred(oc.partition.test(i)), cPred(oc.partition.test(i))] = cr(n).models(i).predict(X(oc.partition.test(i),:));
                 
                    [yp,cp]  = cr(n).models(i).predict(X(oc.partition.test(i),:));

                    if isequal(oc.partition.Type, 'loobspartition')
                        % handle loo-bootstrap case
                        % not implemented
                    else
                        % normal cross validation
                        yPred(oc.partition.test(i),:) = yp;
                        cPred(oc.partition.test(i)) = cp;
                    end
                    
                    %  [yPred(oc.partition.test(i),:),cPred(oc.partition.test(i))]  = cr(n).models(i).predict(X(oc.partition.test(i),:)); 
                     % [~, pPost(oc.partition.test(i))]  = cr(n).models(i).cPredict(yPred(oc.partition.test(i)));
                end
                

            cr(n).yPred = yPred;
            cr(n).cPred = cPred;            
            end
            if oc.verbose
                close(hWb);
            end
        end
        %
        function [pErr, pcvRes] = runPermutations(oc, X, grp, nPer)
            if nPer < 1
                pErr = [];
                pcvRes = [];
                return
            end
            
            RandStream.setGlobalStream ...
                (RandStream('mt19937ar','seed',sum(100*clock)));
            bWaitBar = oc.verbose;
            if bWaitBar
                h = waitbar(0, 'running permutations');
            end
            oc.verbose = false;
            for i=1:nPer
                if bWaitBar
                    waitbar(i/nPer); 
                end
                 pgrp = grp(randperm(length(grp)));
                 pcvRes(i,:) = oc.run(X, pgrp);
                 pErr = [pcvRes(1:i).mcr];   
                 save pErr.mat pErr   
            end
            if bWaitBar
                close(h);
            end
            pErr = [pcvRes.mcr];            
        end
        %      
    end    
end
