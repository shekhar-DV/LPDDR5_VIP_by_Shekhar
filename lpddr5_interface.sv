//########################################################################################################
// File:        lpddr5_interface.sv
// Author:      Prateek
// Date:        25/11/2025  
// Description:  This interface defines all signal-level connections between the LPDDR5
// 				 controller DUT

// 				The interface also provides:
// 					1. Clocking blocks (driver_cb, monitor_cb) for accurate timing control
// 					   and race-free signal sampling/driving using SystemVerilog semantics.
// 					2. Modports (driver_port and monitor_port) to clearly separate driving

// This file uses several timing and width macros that MUST be declared in
// the lpddr5_timing_configurations Component.

// --------------------------------------------------------------------------------------------------
// MACROS USED:- 1. `LP5_WCK_WIDTH			   	-width of WCK (can be 1 bit or 2 bit )
//				 2. `LP5_COMMAND_ADDRESS_WIDTH 	-Width of CA bus (as per LPDDR5 spec mode registers)
//				 3. `LP5_RDQS_WIDTH			   	-Width of RDQS (Read Data Strobe) signal - 2bits
//				 4. `LP5_DMI_WIDTH				-Width of DMI (Data Mask Inversion) signal - 2bits
//				 5. `DATA_WIDTH				-DQ bus width (x16 / x32 device configuration) - 16bits
//#########################################################################################################

interface lpddr5_interface(input logic reset_n);// active low reset

  logic ck_t;						// true clock

  logic ck_c; 						// complement clock

  logic [`LP5_WCK_WIDTH-1:0]wck_t;	// true write clock

  logic [`LP5_WCK_WIDTH-1:0]wck_c;	// complement write clock

  logic cs; 						//chip selct

  logic [`LP5_COMMAND_ADDRESS_WIDTH-1:0] ca;  // command address which is of 7 bits

  logic [`LP5_RDQS_WIDTH-1:0]rdqs_t; // read data strobe true

  logic [`LP5_RDQS_WIDTH-1:0]rdqs_c;// read data strobe complement

  logic [`LP5_DMI_WIDTH-1:0]dmi; 	// data mask inversion

  logic zq; 						// ZQ calibaration

  logic [`DATA_WIDTH-1:0]dq;		//data queue


  // clocking block defines the synchronisation for the monitor interface signals 
  // -----------------------------------------------------
  // MONITOR CLOCKING BLOCK (for sampling)
  // -----------------------------------------------------
  clocking monitor_cb @(posedge wck_t[0] or negedge wck_t[0]);
    default input #1 output #1;

    input ca;
    input dq;
    input dmi;
    input rdqs_t;
    input rdqs_c;
  endclocking
  
  
  // clocking block defines the synchronisation for the driver interface signals 
  // -----------------------------------------------------
  // DRIVER CLOCKING BLOCK (for writing)
  // -----------------------------------------------------
  clocking driver_cb @(posedge wck_t[0] or negedge wck_t[0]);
    default input #1 output #1;

    output ca;
    output rdqs_c;
    output dmi;
    output dq;
    output rdqs_t;   // strobe during read but not required in driver to capture so it is output
  endclocking
  
  
  //modport used to connect LPDDR VIP driver
  // -----------------------------------------------------
  // MODPORT FOR DRIVER
  // -----------------------------------------------------
//  modport driver_mp(clocking driver_cb,
//                     output ck_c,
//                     output ck_t,
//                     output wck_t,
//                     output wck_c,
//                     output ca,
//                     output zq,
//                     output rdqs_c,
//                     input  reset_n,
//                     inout  dmi,
//                     inout  rdqs_t
//                    );
//
//  //modport used to connect LPDDR VIP monitor
//  // -----------------------------------------------------
//  // MODPORT FOR MONITOR
//  // -----------------------------------------------------
//  modport monitor_mp (clocking monitor_cb,
//        			  input ck_t,
//        			  input ck_c,
//        			  input wck_t,
//        			  input wck_c,
//        			  input reset_n
//     				 );
//     
      
  // modport used to connect our testbench to external interfaces.
  // Use this in top.sv to connect local wires to the interface.
  // Example: assign ck_t_local = pif.controller_mp.ck_t;
  // -----------------------------------------------------
  // MODPORT FOR TOP CONNECTION
  // -----------------------------------------------------
//     modport controller_mp(output ck_c,
//                           output ck_t,
//                           output wck_t,
//                           output wck_c,
//                           output rdqs_c,
//                           output cs,
//                           output ca,
//                           output zq,
//                           inout  dmi,
//                           inout  dq, 
//                           inout  rdqs_t
//                        );

endinterface




