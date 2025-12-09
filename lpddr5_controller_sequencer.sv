//############################################################################
// File:        lpddr5_controller_sequencer.sv
// Author:      Priya
// Description: 
//   UVM sequencer for LPDDR5 controller transactions.
//   - Acts as the middle layer between sequences and the controller driver.
//   - Handles lpddr5_transaction items and hands them to the driver via
//     the standard UVM seq_item_port/seq_item_export connection.
//############################################################################


`ifndef LPDDR5_CONTROLLER_SEQUENCER_SV
	`define LPDDR5_CONTROLLER_SEQUENCER_SV
// lpddr5_controller_sequencer:
// - Extends uvm_sequencer parametrized with lpddr5_transaction.
// - Sequences will run on this sequencer.
// - The driver will connect its seq_item_port to this sequencer’s
//   seq_item_export in the agent.

class lpddr5_controller_sequencer extends uvm_sequencer#(lpddr5_transaction);
   // Register this sequencer with the UVM factory so it can be created using
  // type_id::create() and overridden if needed.
  
  `uvm_component_utils(lpddr5_controller_sequencer)

  function new(string name = "",uvm_component parent);
    super.new(name,parent);
  endfunction
  
endclass

`endif
