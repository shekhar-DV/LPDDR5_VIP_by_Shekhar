TOP_MODULE = top
# Your specific UVM path
UVM_HOME   = /remote/pviphome01/shekharc/uvm-1.1c

# Only design files here. 
# Make sure lpddr5_controller_pkg.sv includes the driver/transaction files internally.
SV_FILES   = lpddr5_controller_pkg.sv lpddr5_controller_top.sv

DEFINES    = +define+LP5_BANK_WIDTH=4 +define+LP5_ROW_WIDTH=16 +define+LP5_COL_WIDTH=8 +define+LP5_BL16=16 +define+LP5_BL32=32 +define+DATA_WIDTH=32

QUESTA_FLAGS = -sv $(DEFINES) +incdir+$(UVM_HOME)/src +incdir+./ -suppress 2583,2589,2581,2217,2240,2227,2283,1902,2275,2875

# Added -64 to match GCC. Removed path from -sv_lib.
VSIM_FLAGS   = -64 +suppress=vopt-8885,vopt-2064 +UVM_TESTNAME=test_WR16 +UVM_VERBOSITY=UVM_LOW -do "run -all; quit"

all: clean compile dpi simulate

compile:
	vlib work
	# --- CRITICAL STEP: Compile UVM 1.1c Source explicitly ---
	# This forces vsim to use 1.1c instead of the built-in 1.1d
	vlog -sv +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
	
	# Compile your design
	vlog $(QUESTA_FLAGS) $(SV_FILES)

dpi:
	# Compile the DPI C code for UVM 1.1c
	gcc -m64 -fPIC -shared -I$$MTIHOME/include -o uvm_dpi.so $(UVM_HOME)/src/dpi/uvm_dpi.c

simulate:
	# Add current dir to library path so it finds uvm_dpi.so
	export LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):. 
	
	# Use -sv_lib uvm_dpi (NO .so extension)
	vsim -c -sv_lib uvm_dpi $(VSIM_FLAGS) work.$(TOP_MODULE)

clean:
	rm -rf work transcript vsim.wlf *.wlf *.ucdb coverage uvm_dpi.so