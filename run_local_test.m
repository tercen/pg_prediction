
addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/legacy'))
addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/mgPlsda'))
addpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/CV'))

ppr_prediction_main('--infile=/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/test/test_input.json');
 
rmpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/legacy'))
rmpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/mgPlsda'))
rmpath(genpath('/media/thiago/EXTRALINUX/Upwork/code/pg_prediction/CV'))