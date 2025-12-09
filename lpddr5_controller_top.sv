//####################################################################################
// File:        	top.sv
// Author:      	Nisha
// Date:        
// Description: 	Instantiates interface
//					Top-level module for LPDDR5 testbench.
//   				Instantiates lpddr5_interface and connects internal signals.
//					Creates the LPDDR5 timing configuration object and passes it to UVM components.
//   				Provides reset generation.
//																		 
// This file uses several timing and width macros that MUST be declared in
// the lpddr5_timing_configurations Component.
//																					
// Timing Parameters Used (from lpddr5_timing_configuration):
// ----------------------------------------------------------------------------------
//   tINT0_ns          	– (max)Maximum voltage ramp time at power-up [20 ms]
//   tINT1_ns           – (min)Reset initialization time before reset_n de-assertion [200 us]
//   tINIT2_ns          – (min)Minimum CS low time before RESET_n high [10 ns]
//																					
// Macros Used:
// ----------------------------------------------------------------------------------
//   `LP5_WCK_WIDTH         – Width of WCK signals
//   `LP5_COMMAND_ADDRESS_WIDTH – Width of CA (command/address) bus
//   `LP5_RDQS_WIDTH        – Width of read DQS signals
//   `LP5_DMI_WIDTH         – Width of DMI bus
//   `LP5_DATA_WIDTH        – Width of DQ data bus
//
// Included files:	lpddr5_test.sv
//####################################################################################
 
`timescale 1ns/1ps
 
`include "lpddr5_controller_pkg.sv"
`include "lpddr5_interface.sv"
`include "lpddr5_timing_configuration.sv"
module top;
  import lpddr5_controller_pkg::*;
  import uvm_pkg::*;      
    `include "uvm_macros.svh"

  // -------------------------------------------------------------
  // Internal signals 
  // -------------------------------------------------------------
  logic                 			reset_n_int = 0;
  wire                 				ck_t_int;
  wire                 				ck_c_int;
  wire [`LP5_WCK_WIDTH-1:0]     		wck_t_int;
  wire [`LP5_WCK_WIDTH-1:0]     		wck_c_int;
  wire                 				cs_int;
  wire [`LP5_COMMAND_ADDRESS_WIDTH-1:0] 	ca_int;
  wire [`LP5_RDQS_WIDTH-1:0]           		rdqs_t_int;
  wire [`LP5_RDQS_WIDTH-1:0]           		rdqs_c_int;
  wire [`LP5_DMI_WIDTH-1:0]           		dmi_int;
  wire                 				zq_int;
  wire [`LP5_DATA_WIDTH-1:0] 			dq_int;
  
  // -------------------------------------------------------------
  // Connecting internal signals to interface internal nets
  // -------------------------------------------------------------
//   assign pif.ck_t   = ck_t_int;
//   assign pif.ck_c   = ck_c_int;
//   assign pif.wck_t  = wck_t_int;
//   assign pif.wck_c  = wck_c_int;
//   assign pif.cs     = cs_int;
//   assign pif.ca     = ca_int;
//   assign pif.rdqs_t = rdqs_t_int;
//   assign pif.rdqs_c = rdqs_c_int;
//   assign pif.dmi    = dmi_int;
//   assign pif.zq     = zq_int;
//   assign pif.dq     = dq_int;
  
  
  //Create object of timing configuration class and allocate memory
  lpddr5_timing_configuration timing_config = new();

  // ----------------------------------------------------
  // Interface instantiation
  // ----------------------------------------------------
  lpddr5_interface pif (.reset_n (reset_n_int));
  

  // UVM virtual interface and timing configuration
  initial begin
     uvm_config_db#(virtual lpddr5_interface)::set(uvm_root::get(), "*", "vif", pif);
     uvm_config_db#(lpddr5_timing_configuration)::set(uvm_root::get(), "*", "timing_config", timing_config);
  end

  // ----------------------------------------------------
  // Reset Generation Logic
  // ----------------------------------------------------
  initial begin
    reset_n_int = 'x;
    pif.cs 	= 'x;
    
    #(timing_config.tINIT0_ns);	// 20ms Max voltage-ramp time at power-up
    reset_n_int = 0;		// assert reset
    
    #(timing_config.tINIT2_ns)  // 10ns Min CS low time before RESET_n high
    pif.cs 	= 0;

    #(timing_config.tINIT1_ns); 	// 200us wait tINIT time = 200us min
    reset_n_int = 1;		// deassert reset
  end


  // Start UVM test
  initial begin
    run_test("test_WR16");	// run the test
  end
  
  // Waveform dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
//   initial begin
//     #10000 $finish;
//   end
endmodule