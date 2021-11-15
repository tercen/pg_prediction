#https://github.com/tercen/operator_runtimes
FROM tercen/runtime-matlab-image:r2020b-1

COPY standalone/ppr_prediction_main /mcr/exe/ppr_prediction_main
COPY standalone/run_ppr_prediction_main.sh /mcr/exe/run_ppr_prediction_main.sh