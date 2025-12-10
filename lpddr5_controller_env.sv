//############################################################################
// File:        lpddr5_controller_env.sv
// Author:      Nithin
// Date:        
// Description: 
//############################################################################

`ifndef LPDDR5_CONTROLLER_ENV_SV
	`define LPDDR5_CONTROLLER_ENV_SV
class lpddr5_controller_env extends uvm_env;
  `uvm_component_utils(lpddr5_controller_env)
  
 // lpddr5_ck_rdqs_agent ck_rdqs_agent;
  lpddr5_controller_agent controller_agent;
  
 // lpddr5_wck_agent wck_agent;
  lpddr5_scoreboard sbd;

//lpddr5_timing configuration handle
  lpddr5_timing_configuration timing_config;
  
  //lpddr5_mode_register_configuration handle
//   lpddr5_mode_register_configuration mode_config;
  
  //lpddr5_command_configuration handle
  lpddr5_command_configuration cmd_config;
  
  function new(string name = "",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  ///creating memory for the controller, scoreboard and configuration class
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
	  `uvm_info("lpddr5_controller_env", "Inside build phase", UVM_LOW)
    //construct for lpddr5_controller
    controller_agent = lpddr5_controller_agent::type_id::create("controller_agent",this);
    //construct for lpddr5_scoreboard
    sbd = lpddr5_scoreboard::type_id::create("sbd",this);
    //construct for timing config
    timing_config = lpddr5_timing_configuration::type_id::create("timing_config");
	//construct for mode register
//     mode_config = lpddr5_mode_register_configuration::type_id::create("mode_config");
    //construct for command configuration
    cmd_config =  lpddr5_command_configuration::type_id::create("cmd_config");
    //assigning tck_avg_ns to simulation_cycle
//    timing_config.simulation_cycle = timing_config.tck_avg_ns;
  endfunction
  
  //connecting monitor and scoreboard by analysis port declare in the monitor
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
     `uvm_info("lpddr5_controller_env", "Inside connect phase", UVM_LOW)
    controller_agent.controller_monitor.ap_port.connect(sbd.sbd_imp);
  endfunction
endclass
`endif
