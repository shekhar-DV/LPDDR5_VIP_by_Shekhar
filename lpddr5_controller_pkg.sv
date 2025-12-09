//############################################################################
// File:        lpddr5_controller_pkg.sv
// Author:      
// Date:        
// Description:  
//############################################################################

`ifndef LPDDR5_CONTROLLER_PKG_SV
	`define LPDDR5_CONTROLLER_PKG_SV

`include "uvm_macros.svh"
`include "uvm_pkg.sv"

package lpddr5_controller_pkg;
	import uvm_pkg::*;
	`include "lpddr5_common.svi"
	

	`include "lpddr5_timing_configuration.sv"

//	`include "lpddr5_mode_register_configuration.sv"

	`include "lpddr5_transaction.sv"
	`include "lpddr5_sequence.sv"
	`include "lpddr5_command_configuration.sv"

	`include "lpddr5_controller_sequencer.sv"
	
	`include "lpddr5_controller_driver.sv"

	`include "lpddr5_controller_monitor.sv"

	`include "lpddr5_scoreboard.sv"

	`include "lpddr5_controller_agent.sv"
	`include "lpddr5_controller_env.sv"
	`include "lpddr5_controller_test.sv"
endpackage
`endif

