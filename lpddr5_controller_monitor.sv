//############################################################################
// File:        lpddr5_controller_monitor.sv
// Author:      Mayuresh
// Date:        
// Description: lpddr5_controller_monitor.sv is a verification component that passively monitors the LPDDR5 interface. It samples command/address signals on the CK_t/CK_c clock pair and captures data activity on the WCK_t/WCK_c strobe pair. The monitor translates these sampled transactions into structured packets and forwards them to the scoreboard for protocol checking, data integrity validation, and functional comparison.  
//############################################################################

`ifndef LPDDR5_CONTROLLER_MONITOR_SV
`define LPDDR5_CONTROLLER_MONITOR_SV

//=====================================
//defination of enum to sample the cmd
//=====================================

typedef enum int {
  LP5_CMD_DES,            
  LP5_CMD_NOP ,              
  LP5_CMD_PD,           
  LP5_CMD_ACT, 
  LP5_CMD_ACT1,
  LP5_CMD_ACT2,
  LP5_CMD_PRE,        
  LP5_CMD_REF,        
  LP5_CMD_MASK_WR,         
  LP5_CMD_WR16,        
  LP5_CMD_WR32,      
  LP5_CMD_RD16,     
  LP5_CMD_RD32,         
  // LP5_CMD_CAS,      
  LP5_CMD_SRE,  
  LP57CMD_SRX,
  LP5_CMD_MRW,
  LP5_CMD_MRW1,
  LP5_CMD_MRW2,
  LP5_CMD_MRR,
  LP5_CMD_ZQC,
  LP5_CMD_MPC              
}cmd_type;

//==============================================================
// Defination of struct to send data between cmd and data thread
//==============================================================


typedef struct{

  cmd_type command ;				
  int unsigned latency;
  int unsigned burst_len;
  bit [`LP5_COL_WIDTH-1:0] cad; //COLUMN ADDRESS
  bit[`LP5_ROW_WIDTH-1:0]rad;	//ROW ADDRESS
  bit [6:0] cmd;
  bit [6:0]  mr_addr;
  bit [7:0] mr_op;
  bit [15:0] mr_data;
  bit [3:0] ba;

} cmd_data_job;

//==============================================================
//Defination of enum which monitor current bank organization
//============================================================
typedef enum {ORG_BG, ORG_B8,ORG_B16} organization_type;


//--------------------------------------------------------------
// MONITOR CLASS
//--------------------------------------------------------------

class lpddr5_controller_monitor extends uvm_monitor;

  //========================================================
  //factory registration
  //========================================================
  `uvm_component_utils(lpddr5_controller_monitor)


  virtual lpddr5_interface vif;//virtual interface 

  cmd_data_job job; // struct to send data btw cmd and data thread;

  organization_type current_org = ORG_BG;// default organiztion is BG mode
  lpddr5_timing_configuration cfg ; //handle for the config class

  int current_burst_ln;
  bit current_ratio;
  real local_twckenl_wr_ck;      
  real local_twckpre_toggle_wr_ck; 
  real local_twckpre_static_wr_ck;



  //=================================
  //port declaration 
  //=================================

  uvm_analysis_port #(lpddr5_transaction) ap_port;//exteranal

  //=============================================================
  //TLM fifo to exchange data between cmd thread and data thread
  //=============================================================

  uvm_tlm_analysis_fifo #(cmd_data_job)  job_fifo;//internal




  function new(string name = "",uvm_component parent);
    super.new(name,parent);
  endfunction


  //=======================================================
  //BUILD PHASE 
  //=======================================================
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    ap_port = new("ap_port",this);
    job_fifo = new("job_fifo", this);
    if(!uvm_config_db#(virtual lpddr5_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set")
      assert  (uvm_config_db#(lpddr5_timing_configuration)::get(this, "", "timing_config", cfg));
  endfunction 

  //======================================================
  //RUN PHASE 
  //======================================================

  task run_phase(uvm_phase phase);

    fork
      monitor_command_thread(); //Command Thread 
      monitor_data_thread();    //Data  Thread 
    join

  endtask

  //====================================================
  // THREAD: command decoder (ck domain)
  //====================================================


  task monitor_command_thread();
    logic [0:6] ca_rise, ca_fall;
    logic [13:0] full_cmd_vec;

    cmd_type decode_type; //enum to saple decoded command 

    forever begin 

      @(posedge vif.ck_t);  // Sync to CK Rising Edge (Start of the command cycle)
      if(vif.cs == 1) begin 

        ca_rise = vif.ca;  //Capture Rising Edge CA (First 7 bits)


        @(negedge vif.ck_t);
        ca_fall = vif.ca;

        full_cmd_vec = {ca_rise, ca_fall}; //Reconstruct 14-bit Command Vector

        decode_type= decode_command(full_cmd_vec); //to decode command type

        //****************************************************
        //we want to enter data thread in 2 conditons  
        // 1. if it's write or  read Command 
        // 2. if it's MMR OR MRW command 
        //****************************************************


        if ( decode_type == LP5_CMD_WR16 ||
          decode_type== LP5_CMD_WR32 ||
          decode_type== LP5_CMD_RD16 ||
          decode_type== LP5_CMD_RD32 || 
          decode_type== LP5_CMD_MRW2 ||
          decode_type== LP5_CMD_MRR) begin 

          job_fifo.write(job);//sending captured data to data thread 


        end


      end 


    end 


  endtask 


  // ====================================================================
  // THREAD : DATA COLLECTOR (WCK Domain)
  // ====================================================================
  task monitor_data_thread();



    //  forever begin 
    // fifo_job.get(job);
    //-----------------------------------------------------------------
    //calculating the dealys
    //-----------------------------------------------------------------
    cfg.get_twckenl_and_twckpre_toggle_and_twckpre_static_wr_ck(
      current_ratio, 
      cfg.tck_avg_ns, 
      0, 
      local_twckenl_wr_ck,      
      local_twckpre_toggle_wr_ck, 
      local_twckpre_static_wr_ck
    );

    //       if(job.command ==  LP5_CMD_WR16, )begin 

    //       end


    //    end 
  endtask




  //==================================================
  //The function to decode command 
  //==================================================

  function cmd_type decode_command(logic [13:0] cmd_vec);

    casez(cmd_vec) 

      //cmd_vec is then cmd is ACTIVATE 

      14'b11???????????? : begin 

        // if the command is act1
        if (cmd_vec[11]) begin

          //decoding the bank group and and address depeds on the organization 

          job.ba =  cmd_vec[6:3];
          if(current_org == ORG_BG)begin 
            job.ba =  cmd_vec[6:3];  

          end
          else if(current_org == ORG_B16)begin
            job.ba =  cmd_vec[6:3];  
          end

          else begin 
            job.ba =  cmd_vec[6:3];  
          end

          job.rad[17:14] = cmd_vec[10:7];
          job.rad[13:11] = cmd_vec[7:0];

          return LP5_CMD_ACT1;

        end
        //if the command is act2

        else begin 
          job.rad[10:7] = cmd_vec[10:7]; 
          job.rad[6:0] = cmd_vec[6:0];

          return LP5_CMD_ACT2;
        end

      end          

      //decoding write16 command     
      14'b011??????????? : begin 
        job.burst_len = 16;
        job.cad[5:0] ={cmd_vec[9:7],cmd_vec[2:1],cmd_vec[10]};
        job.ba = cmd_vec[13:10];
        return  LP5_CMD_WR16;
      end

      //decoding write 32 command 
      14'b0010?????????? : begin 
        job.burst_len = 32;
        job.cad[5:0] ={cmd_vec[9:7],cmd_vec[2:1],1'b0};//zero padding on lsb
        job.ba = cmd_vec[13:10];
        return  LP5_CMD_WR16;
      end


      //decoding read 16 command


      14'b100??????????? : begin 
        job.burst_len = 16;
        job.cad[5:0] ={cmd_vec[9:7],cmd_vec[2:1],cmd_vec[10]};
        job.ba = cmd_vec[13:10];
        return  LP5_CMD_RD16;
      end

      //decoding MRW2        

      14'b000100???????? : begin 
        job.mr_data = {cmd_vec[7:0]};

        return LP5_CMD_MRW2;
      end 

      //decoding MRW1        

      14'b0001101??????? : begin 
        job.mr_data = {cmd_vec[7] , cmd_vec[6:0]};

        return LP5_CMD_MRW1;
      end 

      //decoding MRR       

      14'b0001101??????? : begin 
        job.mr_addr =  cmd_vec[6:0];

        return LP5_CMD_MRR;
      end 

    endcase

  endfunction 











endclass
`endif
