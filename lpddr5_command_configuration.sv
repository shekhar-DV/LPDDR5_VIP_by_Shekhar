//############################################################################
// File:        lpddr5_command_configurations.sv
// Author:      Chaitanya
// Date:        
// Description:  
//############################################################################

`ifndef LPDDR5_COMMAND_TASKS_SV
//`define LPDDR5_COMMAND_TASKS_SV
 
// Macros assumed defined in your transaction class header
`define LP5_CA_WIDTH 7


class lpddr5_command_configuration extends uvm_object;
  `uvm_object_utils(lpddr5_command_configuration)
  virtual lpddr5_interface vif; 
  
  function new(string name = "");
    super.new(name);
  endfunction
  
 
// Fixed timing parameters (adjust as needed)
real tck_avg_ps         = 1500;   // 1 GHz clock cycle in picoseconds
bit [6:0] nop_ca_value = 7'b000_0000;
real simulation_cycle   = 1000;
 
// Interface signals (connect these to your DUT)


// logic [`LP5_CA_WIDTH-1:0] ca;
// logic cs_p;
logic SystemClock;


//   task body();
//     assert( 
//   endtask
  
// Drive CA bus with fixed delay
  task automatic drive_ca(input logic [`LP5_CA_WIDTH-1:0] ca_val);
    uvm_config_db#(virtual lpddr5_interface)::get(uvm_root::get(),"","vif",vif);
    vif.ca <= #((tck_avg_ps / 4) * 1ps) ca_val;
endtask
 
// Drive CS signal with fixed delay
  task automatic drive_cs_p(input logic val);
    uvm_config_db#(virtual lpddr5_interface)::get(uvm_root::get(),"","vif",vif);
    vif.cs <= #((tck_avg_ps / 4) * 1ps) val;
endtask
 
// NOP / deselect cycle driver
task deselect;
begin
  @(negedge SystemClock);
  drive_cs_p(0);
  drive_ca('x);                             // Driving CA signals when CS is low, CA[6:0] = {X,X,X,X,X,X,X}
end
endtask : deselect
 
task drive_nop();
   begin
    @(negedge SystemClock);
     #((((simulation_cycle/4))*0.001)*1ns)
     drive_cs_p(1'b1);
    drive_ca( nop_ca_value);
  end
endtask
 
task  drive_act(
  //input logic ba3_or_c5,
  input logic [3-1:0] bank_addr,
  input logic [18-1:0]  row_addr
);
 
  begin
    logic[6:0]row_addr_1;
    logic[10:0]row_addr_2;
    row_addr_1 = row_addr[17:11];
    row_addr_2 = row_addr[10:0];
    //ACT-1 commond
    @(negedge SystemClock);
    #((((simulation_cycle/4))*0.001)*1ns)
    drive_cs_p(1'b1);
    drive_ca({row_addr_1[6:3], 3'b111});
    @(posedge SystemClock);
     #((((simulation_cycle/4))*0.001)*1ns)
    drive_cs_p($urandom_range(0,1));
    drive_ca({row_addr_1[2:0], bank_addr});
//ACT-2 command
    @(negedge SystemClock);
     #((((simulation_cycle/4))*0.001)*1ns)
    drive_cs_p(1'b1);
    drive_ca({row_addr_2[10:7], 3'b011});
    @(posedge SystemClock);
     #((((simulation_cycle/4))*0.001)*1ns)
    drive_cs_p($urandom_range(0,1));
    drive_ca(row_addr_2[6:0]);
  end
endtask
 
task drive_cas(
  input bit [2:0] as_bits,                   // CA bits for address/control 
  input logic cdr_hold,                      // CDR hold bit (typically 1)
  input logic [3:0] lp_bits,                 // Low power or mode bits
  input logic wr_x,                          // Write enable disable bit
  input bit bl                            // Burst length bit
);
  logic [6:0] ca_rise;
  logic [6:0] ca_fall;
 
  begin
    // Construct CA bus signals for rising and falling edges
    ca_rise = {as_bits, cdr_hold, 3'b100}; // CA[6:0] for rising edge per spec
    ca_fall = {bl, 1'b0, wr_x, lp_bits};   // CA[6:0] for falling edge
 
    @(posedge SystemClock);
     #((((simulation_cycle/4))*0.001)*1ns)
    drive_cs_p(1'b1);
    drive_ca(ca_rise);
 
    @(negedge SystemClock);
     #((((simulation_cycle/4))*0.001)*1ns)
    drive_cs_p($urandom_range(0,1));  // CS don't care on falling edge per spec
    drive_ca(ca_fall);
  end
endtask
//need to pass the dq here
task automatic write_cmd(
  input logic [3-1:0] bank_addr,  // BA0,BA1,BA2
  input logic [18-1:0] bank_group, // BG0,BG1
  input logic [1:0] c_bits,                      // C0, C1 on CA4, CA5 (command bits)
  input logic       ap                         // Auto Precharge (AP) on CA6
);
 
  logic [6:0] ca_rise_value;
  logic [6:0] ca_fall_value;
 
  begin
    // Construct CA for rising edge: CA6= C5, CA5=C4, CA4=C3, CA3=C2, CA2=1, CA1=1, CA0=0
    // C2,C3,C4,C5 are command bits that you need to set per write command spec
    // For WRITE command per spec: CA0=0(L), CA1=1(H), CA2=1(H). CA3..CA6 are command pattern bits.
    // We'll fix CA3..CA6 to '1001' or '100' per your specific implementation or make them inputs if needed.
    ca_rise_value = 7'b1001100;  //  Adjust bits CA6..CA3 per your command spec
 
    // Construct CA for falling edge: CA6=AP, CA5=C1, CA4=C0, CA3=BG1/B4, CA2=BG0/BA2, CA1=BA1, CA0=BA0
    ca_fall_value = {ap, c_bits[1], c_bits[0], bank_group[1], bank_group[0], bank_addr[1], bank_addr[0]};
 
    @(posedge SystemClock);
    drive_cs_p(1'b1);
    drive_ca(ca_rise_value);
 
    @(negedge SystemClock);
    drive_cs_p($urandom_range(0,1));  // CS don't care on falling edge per spec
    drive_ca(ca_fall_value);
  end
endtask
 
//need to pass the dq here
task automatic read_cmd(
  input logic [`LP5_BANK_WIDTH-1:0] bank_addr,  // BA0,BA1,BA2
  input logic [`LP5_BANK_WIDTH-1:0] bank_group, // BG0,BG1
  input logic [1:0] c_bits,                      // C0, C1 on CA4, CA5 (command bits)
  input logic       ap                         // Auto Precharge (AP) on CA6
);
 
  logic [6:0] ca_rise_value;
  logic [6:0] ca_fall_value;
 
  begin
    // Rising edge CA signals: CA0=0(L), CA1=1(H), CA2=1(H), CA3..CA6 command bits (example pattern)
    ca_rise_value = 7'b1001000;  // Adjust bits per your design's READ command pattern
 
    // Falling edge CA signals: CA6=AP, CA5=C1, CA4=C0, CA3=BG1/B4, CA2=BG0/BA2, CA1=BA1, CA0=BA0
    ca_fall_value = {ap, c_bits[1], c_bits[0], bank_group[1], bank_group[0], bank_addr[1], bank_addr[0]};
 
    @(posedge SystemClock);
    drive_cs_p(1'b1);
    drive_ca(ca_rise_value);
 
    @(negedge SystemClock);
    drive_cs_p($urandom_range(0,1));  // CS don't care on falling edge per spec
    drive_ca(ca_fall_value);
  end
endtask
 
task automatic refresh_cmd(
  input bit          per_bank,          // 0: All Banks refresh, 1: Per Bank refresh
  input logic [2:0]  bank_addr         // BA0, BA1, BG0/BA2 for per-bank refresh
  );
  logic [6:0] ca_rise_val;
  logic [6:0] ca_fall_val;
 
  begin
    // Rising edge CA: CA[6:0] = {L, H, H, L, H, H, H, L} per spec
    // Assigning CA0=0(L), CA1=0(L), CA2=0(L) and other bits for example
    // Let's fix as per your spec: CA6=0(L), CA5=1(H), CA4=1(H), CA3=1(H), CA2=0(L), CA1=0(L), CA0=0(L)
    ca_rise_val = 7'b0111000;
 
    // Falling edge CA: 
    // CA6 = AB
    // CA5 = SB1/V
    // CA4 = SB0/V
    // CA3 = RFM/V
    // CA2 = BG0/BA2 (bank_addr[2])
    // CA1 = BA1 (bank_addr[1])
    // CA0 = BA0 (bank_addr[0])
    ca_fall_val = {per_bank, 3'b111, bank_addr[2], bank_addr[1], bank_addr[0]};
 
    @(negedge SystemClock);
    drive_cs_p(1'b1);
    drive_ca(ca_rise_val);
 
    @(posedge SystemClock);
    drive_cs_p($urandom_range(0,1));  // CS don't care on falling edge per spec
    drive_ca(ca_fall_val);
  end
endtask
 
// Precharge: per-bank or all-bank
// AB = 0 → per-bank, AB = 1 → precharge all banks
task automatic precharge(
  input logic [3:0] bank_addr,  // BA[2:0] (+ optional BG/BA3 depending on your mapping)
  input bit         ab          // Address bit AB (0: per-bank, 1: all-bank)
);
  begin
    // Rising edge: fixed CA pattern for PRE (example {L,H,H,L,L,L,L} = 7'b0110000)
    @(negedge SystemClock);
    #(((simulation_cycle/4))*0.001*1ns);
    drive_cs_p(1'b1);
    drive_ca(7'b0110000);   // CA[6:0] = {L,H,H,L,L,L,L} - adjust if your spec differs
 
    // Falling edge: bank + AB information
    @(posedge SystemClock);
    #(((simulation_cycle/4))*0.001*1ns);
    drive_cs_p($urandom%2); // CS don't-care on this edge
    //  mapping: CA[6:0] = {AB, 1'b0, 1'b0, bank_addr[2], bank_addr[1], bank_addr[0], 1'b0}
    drive_ca({ab, 1'b0, 1'b0, bank_addr[2:0]});
 
    deselect();
  end
endtask : precharge
 
endclass
 
`endif // LPDDR5_COMMAND_TASKS_SVr
