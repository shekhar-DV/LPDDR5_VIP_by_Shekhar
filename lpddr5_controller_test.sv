//############################################################################

// File:        lpddr5_test.sv

// Author:      Nisha

// Description: LPDDR5 Base Test + All Testcases

//############################################################################

`ifndef LPDDR5_TEST_SV

`define LPDDR5_TEST_SV
 
// ---------------------------------------------------------

// BASE TEST

// ---------------------------------------------------------

class lpddr5_test extends uvm_test;

  `uvm_component_utils(lpddr5_test)
 
  lpddr5_controller_env env;
 
  function new(string name = "", uvm_component parent);

    super.new(name, parent);

  endfunction
 
  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    `uvm_info("lpddr5_test", "Inside build_phase", UVM_LOW)

    env = lpddr5_controller_env::type_id::create("env", this);

  endfunction
 
  virtual function void end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);

    `uvm_info("lpddr5_test", "Inside end_of_elaboration_phase", UVM_LOW)

    uvm_top.print_topology();
  endfunction
 
  virtual task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    run_seq();   // call child test sequence

    phase.drop_objection(this);

    phase.phase_done.set_drain_time(this, 100);

  endtask
 
  // Child tests will override this

  virtual task run_seq();

  endtask
 
endclass
 
 
// ---------------------------------------------------------

// TESTCASE 1 : WR_16

// ---------------------------------------------------------

class test_WR16 extends lpddr5_test;

  `uvm_component_utils(test_WR16)
 
  function new(string name = "", uvm_component parent);

    super.new(name, parent);

  endfunction
 
  virtual task run_seq();

    write_16_seq seq;

    seq = write_16_seq::type_id::create("seq");

    seq.start(env.controller_agent.controller_sequencer);

  endtask
 
endclass
 
`endif // LPDDR5_TEST_SV
 
