/*############################################################################
// File:        lpddr5_transaction.sv
// Author:      Chaitanya
// Date:        
/ Description:  class is the base transaction object used by the LPDDR VIP to represent all protocol-level commands, 
                  address fields, and data associated with LPDDR5 operations.
//############################################################################*/
 
`ifndef LPDDR5_TRANSACTION_SV
`define LPDDR5_TRANSACTION_SV
`include "uvm_macros.svh"      // <- ADD THIS: UVM Macros
import uvm_pkg::*; 

 `include "lpddr5_common.svi"
// ---------------------------------------------------
// COMMAND TYPES
// ---------------------------------------------------
`define LP5_CMD_DES         0
`define LP5_CMD_NOP         1
`define LP5_CMD_PD          2
`define LP5_CMD_ACT         3
`define LP5_CMD_PRE         4
`define LP5_CMD_REF         5
`define LP5_CMD_MASK_WR     6
`define LP5_CMD_WR16        7
`define LP5_CMD_WR32        8
`define LP5_CMD_RD16        9
`define LP5_CMD_RD32        10
`define LP5_CMD_CAS         11
`define LP5_CMD_SRE         12
`define LP5_CMD_SRX         13
`define LP5_CMD_MRW         14
`define LP5_CMD_MRR         15
`define LP5_CMD_ZQC         16
`define LP5_CMD_MPC         17

  typedef enum logic [5:0] {
    DES      = `LP5_CMD_DES,
    NOP      = `LP5_CMD_NOP,
    PD       = `LP5_CMD_PD,
    ACT      = `LP5_CMD_ACT,
    PRE      = `LP5_CMD_PRE,
    REF      = `LP5_CMD_REF,
    MASK_WR  = `LP5_CMD_MASK_WR,
    WR16     = `LP5_CMD_WR16,
    WR32     = `LP5_CMD_WR32,
    RD16     = `LP5_CMD_RD16,
    RD32     = `LP5_CMD_RD32,
    CAS      = `LP5_CMD_CAS,
    SRE      = `LP5_CMD_SRE,
    SRX      = `LP5_CMD_SRX,
    MRW      = `LP5_CMD_MRW,
    MRR      = `LP5_CMD_MRR,
    ZQC      = `LP5_CMD_ZQC,
    MPC      = `LP5_CMD_MPC
  } lpddr5_cmd_e;
 
//-----------------------------------------------------
// LPDDR5 Transaction Class
//-----------------------------------------------------
class lpddr5_transaction extends uvm_sequence_item;
 
  //--------------------------------------------------
  // ENUM using macro values
  //--------------------------------------------------

 
  // -----------------------------------------------
  // Variables
  // -----------------------------------------------
  rand lpddr5_cmd_e cmd;
  rand bit [`LP5_BANK_WIDTH-1:0] bank;
  rand bit [`LP5_ROW_WIDTH-1:0]  row;
  rand bit [`LP5_COL_WIDTH-1:0]  col;
 
  rand int unsigned burst_length; // BL16 or BL32
 
  rand bit [`DATA_WIDTH-1:0] DATA[$];
  rand bit [1:0] DATA_MASK[$];
 
 // rand bit [1:0] dmi;
 
  rand bit [7:0]  mr_addr;
  rand bit [15:0] mr_data;
 
  // -----------------------------------------------
  // Constraints
  // -----------------------------------------------
  constraint c_burst_len {
    burst_length inside {`LP5_BL16, `LP5_BL32};
  }
 
  constraint c_data_size {
    DATA.size() == burst_length;
    DATA_MASK.size() == burst_length;
  }
 
   // Bank must be within implemented bank address space
  constraint c_bank_range {
    
    bank inside { [0 : (1<<`LP5_BANK_WIDTH)-1] };
  }

  // Row must be within implemented row address space
  constraint c_row_range {
    row inside { [0 : (1<<`LP5_ROW_WIDTH)-1] };
  }

  // Column must be within implemented column address space
 
  constraint c_col_range {
    col inside { [0 : (1<<`LP5_COL_WIDTH)-1] };
  }
    
  // -----------------------------------------------
  // UVM Registration
  // -----------------------------------------------
  `uvm_object_utils(lpddr5_transaction)
 
  function new(string name="lpddr5_transaction");
    super.new(name);
  endfunction
 
  // -----------------------------------------------
  // do_copy()
  // -----------------------------------------------
  function void do_copy(uvm_object rhs);
    lpddr5_transaction tx;
    if(!$cast(tx, rhs)) begin
      `uvm_fatal("COPY_ERR","Copy cast failed")
    end
 
    this.cmd          = tx.cmd;
    this.bank         = tx.bank;
    this.row          = tx.row;
    this.col          = tx.col;
    this.burst_length = tx.burst_length;
    this.DATA         = tx.DATA;
    this.DATA_MASK      = tx.DATA_MASK;
    this.mr_addr      = tx.mr_addr;
    this.mr_data      = tx.mr_data;
  endfunction
 
  // -----------------------------------------------
  // do_compare()
  // -----------------------------------------------
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    lpddr5_transaction tx;
    if(!$cast(tx, rhs))
      return 0;
 
    return (
      (cmd == tx.cmd) &&
      (bank == tx.bank) &&
      (row  == tx.row) &&
      (col  == tx.col) &&
      (burst_length == tx.burst_length)
    );
  endfunction
 
  // -----------------------------------------------
  // convert2string()
  // -----------------------------------------------
  function string convert2string();
    string s;
    s = $sformatf("----- LPDDR5 Tx -----\n");
    s = {s, $sformatf("CMD           : %s\n", cmd.name())};
    s = {s, $sformatf("Bank          : %0d\n", bank)};
    s = {s, $sformatf("Row           : 0x%0h\n", row)};
    s = {s, $sformatf("Col           : 0x%0h\n", col)};
    s = {s, $sformatf("Burst Length  : %0d\n", burst_length)};
   // s = {s, $sformatf("DATA          : 0x%0h\n", DATA)};
  //  s = {s, $sformatf("DATA_MASK     : 0x%0h\n", DATA_MASK)};
    s = {s, $sformatf("MR Addr       : 0x%0h\n", mr_addr)};
    s = {s, $sformatf("MR Data       : 0x%0h\n", mr_data)};
    return s;
  endfunction
 
  // -----------------------------------------------
  // print()
  // -----------------------------------------------
  function void do_print(uvm_printer printer);
    printer.print_string("cmd", cmd.name());
    printer.print_int("bank", bank, `LP5_BANK_WIDTH);
    printer.print_int("row", row, `LP5_ROW_WIDTH);
    printer.print_int("col", col, `LP5_COL_WIDTH);
   // printer.print_int("DATA", DATA, `DATA_WIDTH);
   // printer.print_int("DATA_MASK", DATA_MASK, `DATA_WIDTH);
    printer.print_int("burst_length", burst_length, 32);
    printer.print_int("mr_addr", mr_addr, 8);
    printer.print_int("mr_data", mr_data, 16);
  endfunction
 
endclass
 
`endif
