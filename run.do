# Compile DUT and Testbench
vlog lpddr5_controller_top.sv +incdir+/remote/pviphome01/uvm-1.2/src 

# Simulate (Added -64 flag)
vsim -64 -novopt -suppress 12110 top \
    -sv_lib /global/apps/mentor_graphics/questa_10.7d/questasim/uvm-1.2/linux/uvm_dpi \
    +UVM_TESTNAME=test_WR16 +UVM_VERBOSITY=UVM_MEDIUM \
    
add wave sim:/top/pif/*

run -all