addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/CV/'));
addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/legacy/'));
addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/mgPlsda'));

res = compiler.build.standaloneApplication('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/ppr_prediction_main.m', ...
            'TreatInputsAsNumeric', false,...
            'OutputDir', '/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/standalone');
        

delete('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/standalone/mccExcludedFiles.log');
delete('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/standalone/readme.txt');
delete('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/standalone/requiredMCRProducts.txt');

rmpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/CV/'));
rmpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/legacy/'));
rmpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/mgPlsda'));
