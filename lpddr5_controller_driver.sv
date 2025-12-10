

//############################################################################
// File:        lpddr5_controller_driver.sv
// Author:      Shekhar & Prateek
// Date:
// Description: This file implements the UVM driver for the LPDDR5 controller
//              interface.
//
// The driver is responsible for:
// 1. Generating and controlling CK and WCK clocks based on the configured
//    WCK:CK ratio (2:1 or 4:1) and timing parameters from configuration.
// 2. Handling LPDDR5 Write timing requirements per JEDEC specification:
//    - Write Latency (WL)
//    - WCK Enable Latency (tWCKENL)
//    - Static and Toggle Preambles (tWCKPRE_Static, tWCKPRE_Toggle)
//    - Postamble (tWCKPST)
// 3. Driving command and address signals via lpddr5_command_configuration.
// 4. Driving data signals with precise WCK synchronization.
//
// CONFIGURATION OBJECTS:
//              1. lpddr5_command_configuration (Command logic)
//              2. lpddr5_timing_configuration  (Timing parameters)
//
//############################################################################

`ifndef LPDDR5_CONTROLLER_DRIVER_SV
`define LPDDR5_CONTROLLER_DRIVER_SV
//`include "lpddr5_command_configuration.sv"

class lpddr5_controller_driver extends uvm_driver#(lpddr5_transaction);
  `uvm_component_utils(lpddr5_controller_driver)

  virtual lpddr5_interface driver_vif;

  lpddr5_command_configuration cmd_cfg;
  lpddr5_timing_configuration  t_cfg;


  // FIFO to pass write data from command thread to data driving thread
  uvm_tlm_analysis_fifo #(lpddr5_transaction) write_data_fifo;

  event data_write_complete;

  // Master switch for WCK toggling. Controlled by command logic.
  bit drive_wck = common::drive_wck; 

  // Local timing variables (converted from ns to clock cycles)
  real local_nwr_ck;
  real local_wl_ck;              
  real local_twckpre_static_wr_ck; 
  real local_twckpre_toggle_wr_ck; 
  real local_twckenl_wr_ck; 

  real local_rl_ck;              
  real local_twckpre_static_rd_ck; 
  real local_twckpre_toggle_rd_ck; 
  real local_twckenl_rd_ck;

  real local_twckpst_wck;        

  bit current_ratio = 0;                
  bit clock_stop = common::clock_stop; 

  function new(string name = "", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual lpddr5_interface)::get(this, "", "vif", driver_vif))
      `uvm_fatal("DRV", "Could not get vif")

      write_data_fifo = new("write_data_fifo", this);
    cmd_cfg = lpddr5_command_configuration::type_id::create("cmd_cfg");
    uvm_config_db#(lpddr5_timing_configuration)::get(this,"","timing_config",t_cfg);
  endfunction

  task run_phase(uvm_phase phase);
    reset_default();


    // Convert timing config (ns) into cycles for driver usage
    calculate_timing_params(); 

    wait(driver_vif.reset_n);

    fork
      clock_generation(); // Starts CK and WCK generators
      command_drive();    // Main thread for CS/CA
      sync_cfg_clock();   // Sync command object to interface clock
    join
  endtask

  // Helper to convert timing config values into clock cycles
  function void calculate_timing_params();
    t_cfg.write_latency(current_ratio, t_cfg.tck_avg_ns, 0, 0, local_wl_ck);
    t_cfg.read_latency(current_ratio,t_cfg.tck_avg_ns,0,local_rl_ck,local_nwr_ck);
    t_cfg.get_twckenl_and_twckpre_toggle_and_twckpre_static_wr_ck(
      current_ratio, 
      t_cfg.tck_avg_ns, 
      0, 
      local_twckenl_wr_ck,      
      local_twckpre_toggle_wr_ck, 
      local_twckpre_static_wr_ck
    );

    t_cfg.get_tWCKPST_wck(local_twckpst_wck);

    `uvm_info("DRV_TIMING", $sformatf("tCK=%0fns, WL=%0d, tWCKENL=%0d, PreStatic=%0d, PreToggle=%0d, PST_WCK=%0f", 
                                      t_cfg.tck_avg_ns, local_wl_ck, local_twckenl_wr_ck, local_twckpre_static_wr_ck, local_twckpre_toggle_wr_ck, local_twckpst_wck), UVM_LOW)
  endfunction

  // Keep the command config object in sync with interface clock edges
  task sync_cfg_clock();
    forever begin
      @(driver_vif.ck_t);
      cmd_cfg.SystemClock = driver_vif.ck_t;
    end
  endtask

  // Main task for driving Command/Address bus
  task command_drive();
    $display("****************inside command drive******************");

    // Ensure CS is low during init
    driver_vif.cs <= 0;
    #(t_cfg.tINIT3_ns); 
    $display("before stable clock");
    repeat(t_cfg.tINIT4_ck) @(posedge driver_vif.ck_t);

    $display("after stable clock");
    forever begin
      $display("inside forever");
      seq_item_port.get_next_item(req);

      $display("get_next_item exec");

      // Drive the actual command on CA/CS pins
      drive_tx(req);


      $display("##############################");
      req.print();

      // Check if we need to start WCK for a Write Sync CAS
      if(req.cmd == CAS) begin
        // Check operands: WS_WR=1, WS_RD=0, WS_FS=0
        if(driver_vif.ca[4]==1 && driver_vif.ca[5]==0 && driver_vif.ca[6]==0) begin
          // Wait for WCK enable latency before toggling
//          repeat(local_twckenl_wr_ck) @(posedge driver_vif.ck_t);
          drive_wck = 1; 
        end
        else drive_wck = 0;
      end


      // If it's a write, offload the data burst handling to the data_drive thread
      if(req.cmd inside {WR16,WR32,MASK_WR}) begin
        write_data_fifo.write(req);
        data_drive();
      end
      else begin
        driver_vif.dq <= 'X;
      end

      seq_item_port.item_done();
    end
  endtask

  // Decodes transaction command and calls low-level pin wiggling tasks
  task drive_tx(lpddr5_transaction tx);
    case(tx.cmd)
      ACT:      cmd_cfg.drive_act(tx.bank, tx.row);
      DES:      cmd_cfg.deselect();
      NOP:      cmd_cfg.drive_nop();
      PRE:      cmd_cfg.precharge(tx.bank, 0);
      REF:      cmd_cfg.refresh_cmd(0, tx.bank);
      WR16:     cmd_cfg.write_cmd(tx.bank, tx.bank, tx.col, 0);
      RD16:     cmd_cfg.read_cmd(tx.bank, tx.bank, tx.col, 0);
      CAS:      cmd_cfg.drive_cas(3'b001, 1, 4'b0000, 0, tx.burst_length);
      default:  cmd_cfg.deselect();
    endcase
    if (tx.cmd inside {WR16, WR32, RD16, RD32, PRE, REF, MASK_WR}) begin
      cmd_cfg.deselect();
    end
  endtask

  // Handles the Data portion of Write commands
  task data_drive();
    bit[14:0] ecc_bits;
    lpddr5_transaction wr_req;
    int bl;
    int preamble_wait_cycles;
    bit[1:0] write_link_ecc_enabled=2'b01; //for compilation purpose only, replace by MR later

    write_data_fifo.get(wr_req);
    $display("got from fifo in data_drive");
   
    //enable and wl should run parallely and wl should come after 1 clock cycle once enable is started
    fork
      begin
        // Wait for WCK enable latency
        preamble_wait_cycles = local_twckenl_wr_ck;
        if (preamble_wait_cycles > 0) begin
          repeat (preamble_wait_cycles) @(posedge driver_vif.ck_t);
        end
      end
    
      begin
        // Wait for Write Latency (WL)
        if (local_wl_ck > 0) begin
          repeat(local_wl_ck+1) @(posedge driver_vif.ck_t);
        end
      end
    join



    // Drive WCK Preamble (Static Low + Toggling)
    //     repeat (local_twckpre_static_wr_ck) @(posedge driver_vif.ck_t);
    //     repeat (local_twckpre_toggle_wr_ck) @(posedge driver_vif.ck_t);

    // Generate ECC bits when WECC is enable in MR
    if(write_link_ecc_enabled==2'b01) begin
      generate_write_ecc(wr_req.DATA_MASK, wr_req.DATA, ecc_bits);
    end



    // Drive Data Burst synchronized to WCK
    bl = wr_req.burst_length;
    for (int i = 0; i < bl; i++) begin
      @(driver_vif.driver_cb); 
      if (i < wr_req.DATA.size()) begin
        driver_vif.driver_cb.dq <= wr_req.DATA[i];
        // Handle Masking if needed
        if (wr_req.cmd == MASK_WR) driver_vif.driver_cb.dmi <= wr_req.DATA_MASK[i];
        else driver_vif.driver_cb.dmi <= 0;

        // Handle WECC if required
        if(write_link_ecc_enabled==2'b01) begin
          if(i!=0) driver_vif.driver_cb.rdqs_t[0]<= ecc_bits[i-1];
          else     driver_vif.driver_cb.rdqs_t[0]<= 'X;
        end
      end
    end

    // Burst done, clean up bus
    @(driver_vif.driver_cb);
    driver_vif.driver_cb.dq       <= 'X;
    driver_vif.driver_cb.dmi      <= 'X;
    driver_vif.driver_cb.rdqs_t[0]<= 'X;


    // Maintain WCK for Postamble duration
    repeat (local_twckpst_wck) @(driver_vif.wck_t);

    // Done with write, stop WCK
    drive_wck = 0;

  endtask

  task reset_default();
    driver_vif.ck_c    = 'X;
    driver_vif.ck_t    = 'X;
    driver_vif.wck_c   = 'X; 
    driver_vif.wck_t   = 'X;
    driver_vif.cs      = 'X;
    driver_vif.dq      = 'X; 
    driver_vif.dmi     = 'X;
    driver_vif.ca      = 'X;
  endtask

  //===============================================================
  // Top-level clock generation task
  // Spawns two forever processes:
  //   1. CK generation (base clock)
  //   2. WCK generation (write clock with ratio support)
  //===============================================================



  task clock_generation();
    fork
      forever begin
        wck_generation(clock_stop, drive_wck, current_ratio);
      end

      forever begin
        ck_generation(clock_stop);
      end
    join
  endtask


  //===============================================================
  // CK GENERATION
  // - Generates CK_t / CK_c differential clock
  // - If clock_stop = 1 → drive CK as 'x (stopped state)
  // - Ensures proper initialization before toggling
  // - CK period = tck_avg_ns
  //===============================================================
  task ck_generation(bit clock_stop);
    real simulation_cycle = t_cfg.tck_avg_ns;

    if (!clock_stop) begin
      if (driver_vif.ck_c === 'x || driver_vif.ck_t === 'x) begin
        driver_vif.ck_c = 0;
        driver_vif.ck_t = 1;
      end
      driver_vif.ck_c = ~driver_vif.ck_c;
      driver_vif.ck_t = ~driver_vif.ck_t;
      #(simulation_cycle/2); 
    end
    else begin
      driver_vif.ck_c = 'x;
      driver_vif.ck_t = 'x;
      #(simulation_cycle/2); 
    end
  endtask

  //===============================================================
  // WCK GENERATION
  // - Generates WCK_t/WCK_c differential clock
  // - drive_wck == 1 → toggle based on ratio
  // - drive_wck == 0 → put WCK in 'x (stopped state)
  // - ratio:
  //      1 → 2:1 (WCK runs at 2× CK frequency)
  //      0 → 4:1 (WCK runs at 4× CK frequency)
  // - Uses a helper 'pre_tog' to align first edges cleanly
  //===============================================================

  task wck_generation(bit clock_stop, bit drive_wck, bit ratio);
    real simulation_cycle = t_cfg.tck_avg_ns;

    if (clock_stop == 0) begin
      if (drive_wck == 1) begin // Toggle
        if (driver_vif.wck_c === 'x || driver_vif.wck_t === 'x) begin
          driver_vif.wck_c = 0;
          driver_vif.wck_t = 1;
          repeat(local_twckpre_static_wr_ck) @(posedge driver_vif.ck_c);
          pre_tog(ratio);
        end

        if (ratio == 1) begin
          driver_vif.wck_c = ~driver_vif.wck_c;
          driver_vif.wck_t = ~driver_vif.wck_t;
          #(simulation_cycle/4);

        end
        else begin
          driver_vif.wck_c = ~driver_vif.wck_c;
          driver_vif.wck_t = ~driver_vif.wck_t;
          #(simulation_cycle/8); 

        end
      end

      else begin // Stop (0)
        driver_vif.wck_t = 'x;
        driver_vif.wck_c = 'x;
        #(simulation_cycle/4); 
      end
    end
    else begin
      driver_vif.wck_c = 'x;
      driver_vif.wck_t = 'x;
      #(simulation_cycle/4); 
    end
  endtask

  //===============================================================
  // PRE-TOGGLE ALIGNMENT BLOCK
  // Ensures correct duty-cycle alignment based on ratio
  // Called only on first activation to avoid phase mismatch
  // Ratio:
  //    0 = 4:1 mode → smaller high/low windows
  //    1 = 2:1 mode → wider high/low windows
  //===============================================================

  task pre_tog(bit ratio);
    real simulation_cycle = t_cfg.tck_avg_ns;
    if(ratio==0)
      begin//4:1 => sim/8
        repeat(local_twckpre_toggle_wr_ck)begin
          driver_vif.wck_c=~driver_vif.wck_c;
          driver_vif.wck_t=~driver_vif.wck_t;
          #(simulation_cycle/4);
        end
        repeat(local_twckpre_toggle_wr_ck)begin
          driver_vif.wck_c=~driver_vif.wck_c;
          driver_vif.wck_t=~driver_vif.wck_t;
          #(simulation_cycle/8);
        end
      end
    if(ratio==1)
      begin//2:1 => sim/4
        repeat(local_twckpre_toggle_wr_ck)begin
          driver_vif.wck_c=~driver_vif.wck_c;
          driver_vif.wck_t=~driver_vif.wck_t;
          #(simulation_cycle/2);
        end
        repeat(local_twckpre_toggle_wr_ck)begin
          driver_vif.wck_c=~driver_vif.wck_c;
          driver_vif.wck_t=~driver_vif.wck_t;
          #(simulation_cycle/4);
        end
      end
  endtask



  typedef bit [`DATA_WIDTH-1:0] databus_q[$];
  typedef bit [1:0]             dmibus_q[$];

  task generate_write_ecc(dmibus_q dmi, databus_q dq, output bit[14:0] ecc_bits);
    bit [5:0] dmi_ecc;
    bit [8:0] wr_ecc;

    //logic for ecc generation for dmi transactions
    dmi_ecc = 6'b111111; //for demo purpose only

    //logic for ecc generation for write_dq transactions
    wr_ecc  = 9'b101010101; //for demo purpose only

    ecc_bits = {wr_ecc,dmi_ecc};
  endtask



endclass
`endif
