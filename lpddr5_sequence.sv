`ifndef LPDDR5_SEQUENCES_SV
`define LPDDR5_SEQUENCES_SV

class lpddr5_sequence extends uvm_sequence #(lpddr5_transaction);
  `uvm_object_utils(lpddr5_sequence)
 
  function new(string name="");
    super.new(name);
  endfunction
  
   task pre_body();
  endtask
  task post_body();
  endtask
  
endclass

// Standard Write 16 Sequence
class write_16_seq extends lpddr5_sequence ;
  `uvm_object_utils(write_16_seq)
  function new(string name="write_16");
    super.new(name);
  endfunction
  lpddr5_transaction tx;
  task body();
    tx=lpddr5_transaction::type_id::create("tx");
    `uvm_do_with(req,{req.burst_length==16;req.cmd==ACT;})
    tx.bank=req.bank;
    tx.row=req.row;
    tx.col=req.col;
    `uvm_do_with(req,{req.burst_length==16;req.cmd==CAS;req.bank==tx.bank;req.row==tx.row;tx.col==req.col;})
    `uvm_do_with(req,{req.burst_length == 16 ;req.cmd==WR16;req.bank==tx.bank;req.row==tx.row;tx.col==req.col;})
  endtask
endclass


class write_back2back_seq extends lpddr5_sequence;
  `uvm_object_utils(write_back2back_seq)
  
  function new(string name="write_back2back_seq");
    super.new(name);
  endfunction
  
  lpddr5_transaction tx;
  
  task body();
    tx=lpddr5_transaction::type_id::create("tx");
    
    `uvm_do_with(req,{req.burst_length==16; req.cmd==ACT;})
    tx.bank = req.bank;
    tx.row  = req.row;
    
    `uvm_do_with(req,{req.burst_length==16; req.cmd==CAS; req.bank==tx.bank;})
    
    `uvm_do_with(req,{req.burst_length==16; req.cmd==WR16; req.bank==tx.bank;})
    
    `uvm_do_with(req,{req.burst_length==16; req.cmd==WR16; req.bank==tx.bank;})
    
  endtask
endclass

`endif