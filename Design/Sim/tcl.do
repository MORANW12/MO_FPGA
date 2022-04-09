do sim_test_compile.do
do sim_test_simulate.do
add wave -position insertpoint sim:/sim_test/inst_JPEG_LS_top/*
restart
run 3us