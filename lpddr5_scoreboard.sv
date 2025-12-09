//############################################################################
// File:        lpddr5_scoreboard.sv
// Author:      Ashutosh
// Description:  A UVM scoreboard that tracks LPDDR5 read and write transactions by   logical address and compares read data against the corresponding expected write data. It stores writes and reads in per-address queues, matches them during check_phase, and reports total matches or mismatches at the end of simulation.
// Date : 
// Macros Used:
// ----------------------------------------------------------------------------------
//   `LP5_BANK_WIDTH         – BANK WIDTH
//   `LP5_ROW_WIDTH          – ROW WIDTH
//   `LP5_COL_WIDTH          – COLUMN WIDTH
//############################################################################

`ifndef LPDDR5_SCOREBOARD_SV
`define LPDDR5_SCOREBOARD_SV

//Physical Address width
`define  ADDR_WIDTH (`LP5_BANK_WIDTH +`LP5_ROW_WIDTH  +`LP5_COL_WIDTH)

class lpddr5_scoreboard extends uvm_scoreboard;

  // Factory registration 
  `uvm_component_utils(lpddr5_scoreboard)

  uvm_analysis_imp#(lpddr5_transaction, lpddr5_scoreboard) sbd_imp;

  // ------------------------------------------------------------
  // Associative queues indexed by logical address
  // ------------------------------------------------------------
  lpddr5_transaction wr_q[bit [`ADDR_WIDTH-1:0]][$];
  lpddr5_transaction rd_q[bit [`ADDR_WIDTH-1:0]][$];

  int total_match;
  int total_mismatch;

  // ------------------------------------------------------------
  function new(string name="lpddr5_scoreboard",uvm_component parent=null);
    super.new(name,parent);
  endfunction

  // ------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sbd_imp = new("sbd_imp", this);
  endfunction

  // ------------------------------------------------------------
  // Make phyical address from bank,row,col
  // ------------------------------------------------------------
  function bit [`ADDR_WIDTH-1:0] make_addr( bit [`LP5_BANK_WIDTH-1:0] bank,bit [`LP5_ROW_WIDTH-1:0]  row,bit [`LP5_COL_WIDTH-1:0]  col);
    return {bank, row, col};
  endfunction

  // ------------------------------------------------------------
  // Write method
  // ------------------------------------------------------------
  function void write(lpddr5_transaction lp_tx);

    bit [`ADDR_WIDTH-1:0] key = make_addr(lp_tx.bank,lp_tx.row,lp_tx.col);
    case (lp_tx.cmd)

      WR16,WR32,MASK_WR : begin
        wr_q[key].push_back(lp_tx);
      end
      RD16,RD32 : begin
        rd_q[key].push_back(lp_tx);
      end

    endcase
  endfunction

  // ------------------------------------------------------------
  // Check Phase
  // ------------------------------------------------------------
  function void check_phase (uvm_phase phase);
    `uvm_info("SBD_RUN","inside sbd check phase",UVM_NONE);
    foreach (rd_q[key]) begin
      if (rd_q[key].size() > 0 && wr_q[key].size() > 0) begin

        lpddr5_transaction wr_t = wr_q[key].pop_front();
        lpddr5_transaction rd_t = rd_q[key].pop_front();

        int bl = wr_t.burst_length;
        int match = 0;
        int mismatches = 0;

        // start comparing write and read data of each beat present in BL 16/32 .
        for (int i = 0;i<bl;i++) begin
          if (wr_t.DATA[i] == rd_t.DATA[i])
            match++;
          else
            mismatches++;
        end

        // check total match and mismatch 
        if (mismatches == 0)
          total_match++;
        else
          total_mismatch++;
      end
    end 
  endfunction

  // ------------------------------------------------------------
  // Report Phase to print final results
  // ------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    if(total_mismatch > 0) begin
      `uvm_error("SBD_REPORT", $sformatf("Total Mismatches: %0d", total_mismatch));
    end else begin
      `uvm_info("SBD_REPORT", $sformatf("Total Matches: %0d", total_match), UVM_NONE);
      `uvm_info("SBD_REPORT", "############## Test Passed ############", UVM_NONE);
    end
  endfunction

endclass

`endif
