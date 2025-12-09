`ifndef LPDDR5_CONTROLLER_AGENT_SV
`define LPDDR5_CONTROLLER_AGENT_SV

// - Active agent here (we always create driver + sequencer + monitor).
class lpddr5_controller_agent extends uvm_agent;
  `uvm_component_utils(lpddr5_controller_agent)  // Factory registration

  // Driver:
  // - Pulls sequence items from sequencer.
  // - Drives lpddr5_interface (vif) pins towards DUT.
  lpddr5_controller_driver controller_driver;
  
  // Sequencer:
  // - Middleman between sequences and driver.
  // - Sequences call start() on this; driver fetches items from it.
  lpddr5_controller_sequencer controller_sequencer;
  
  // Monitor:
  // - Passive observer.
  // - Samples lpddr5_interface (vif) pins.
  // - Sends observed transactions out via analysis port to scoreboard.
  lpddr5_controller_monitor controller_monitor;
  
  // -------------------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------------------
  function new(string name = "", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // -------------------------------------------------------------------------
  // ------------- build_phase:----------------
  // -------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create driver instance under this agent
    controller_driver =
      lpddr5_controller_driver::type_id::create("controller_driver", this);

    // Create sequencer instance under this agent
    controller_sequencer =
      lpddr5_controller_sequencer::type_id::create("controller_sequencer", this);

    // Create monitor instance under this agent
    controller_monitor =
      lpddr5_controller_monitor::type_id::create("controller_monitor", this);
  endfunction
  
  // -------------------------------------------------------------------------
  // connect_phase:
  // - Hook up sequencer <-> driver TLM connection.
  // - Data path: sequence -> sequencer -> driver.
  // -------------------------------------------------------------------------
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect driver’s seq_item_port to sequencer’s seq_item_export.
    // This allows driver to call:
    //   - get_next_item()
    //   - item_done()
    // on the sequencer and receive sequence items.
    controller_driver.seq_item_port.connect(controller_sequencer.seq_item_export);
  endfunction
  
endclass

`endif // LPDDR5_CONTROLLER_AGENT_SV
