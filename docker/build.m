addpath(genpath('/pg_prediction/CV/'));
addpath(genpath('/pg_prediction/legacy/'));
addpath(genpath('/pg_prediction/mgPlsda'));

res = compiler.build.standaloneApplication('/pg_prediction/ppr_prediction_main.m', ...
            'TreatInputsAsNumeric', false,...
            'OutputDir', '/pg_prediction/standalone');
        
