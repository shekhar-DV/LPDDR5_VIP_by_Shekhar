typedef enum int unsigned {
	MR0  = 0,
	MR1  = 1,
	MR2  = 2,
	MR3  = 3,
	MR4  = 4,
	MR5  = 5,
	MR6  = 6,
	MR7  = 7,
	MR8  = 8,
	MR9  = 9,
	MR10 = 10,
	MR11 = 11,
	MR12 = 12,
	MR13 = 13,
	MR14 = 14,
	MR15 = 15,
	MR16 = 16,
	MR17 = 17,
	MR18 = 18,
	MR19 = 19,
	MR20 = 20,
	MR21 = 21,
	MR22 = 22,
	MR23 = 23,
	MR24 = 24,
	MR25 = 25,
	MR26 = 26,
	MR27 = 27,
	MR28 = 28,
	MR29 = 29,
	MR30 = 30,
	MR31 = 31,
	MR32 = 32,
	MR33 = 33,
	MR34 = 34,
	MR35 = 35,
	MR36 = 36,
	MR37 = 37,
	MR38 = 38,
	MR39 = 39,
	MR40 = 40,
	MR41 = 41,
	MR42 = 42,
	MR43 = 43,
	MR44 = 44,
	MR45 = 45,
	MR46 = 46,
	MR47 = 47,
	MR48 = 48,
	MR49 = 49,
	MR50 = 50,
	MR51 = 51,
	MR52 = 52,
	MR53 = 53,
	MR54 = 54,
	MR55 = 55,
	MR56 = 56,
	MR57 = 57,
	MR58 = 58,
	MR59 = 59,
	MR60 = 60,
	MR61 = 61,
	MR62 = 62,
	MR63 = 63
} lpddr5_mr_e;

class lpddr5_mode_register_configuration extends lpddr5_configuration_base;
	`uvm_object_utils(lpddr5_mode_register_configuration)

	function new(string name = "lpddr5_mode_register_configuration");
	  super.new(name);
	endfunction

//%%%%%%%%%%%%%%%%% Mode register operand tasks variable declaration %%%%%%%%%%%%%%%%%%%%%%%%
	// MR1
	bit [3:0] wl_orig;
	bit       ck_mode_orig;
	bit       wck_mode_orig;

	// MR2
	bit [3:0] nwr_orig;
	bit [3:0] rl_orig;
	
	// MR3
	bit       dbi_wr_orig;
	bit       dbi_rd_orig;
	bit       wls_orig;
	bit [1:0] bk_org_orig;
	bit [2:0] pdds_orig;

	// MR10
	bit [1:0] rdqs_pst_orig = 2'b00;
	bit [1:0] rdqs_pre_orig = 2'b00;
	bit [1:0] wck_pst_orig  = 2'b00;
	bit       rdqs_pre_2_orig = 1'b0; // Only for LPDDR5X
	bit       rpst_mode_orig   = 1'b0; // 0: toggle, 1: static (per spec)
	real      rdqs_pre_wck = 4.0;
	real      rdqs_pst_wck = 0.5;
	real      wckpst_wck   = 2.0; // 2.5-0.5 as in comment: last 0.5 in block data
	

//%%%%%%%%%%%%%%%%%%%% Operand tasks %%%%%%%%%%%%%%%%%%%%%%%%%%
	// MR1: WL, CK_MODE, WCK_MODE
	task write_mr1(bit [3:0] wl, bit ck_mode, bit wck_mode);
		bit [7:0] op;
		op = {wl, ck_mode, wck_mode, 2'b00};  // BL field RFU in some revs
		mrw(MR1, op);
	endtask
	
	// MR2: NWR, RL
	task write_mr2(bit [3:0] nwr, bit [3:0] rl);
		bit [7:0] op;
		op = {nwr, rl};
		mrw(MR2, op);
	endtask
	
	// MR3: DBI_WR, DBI_RD, WLS, BK_ORG, PDDS
	task write_mr3(bit dbi_wr, bit dbi_rd, bit wls, bit [1:0] bk_org, bit [2:0] pdds);
		bit [7:0] op;
		op = {dbi_wr, dbi_rd, wls, bk_org, pdds};
		mrw(MR3, op);
	endtask

	// MR10: RDQS_PST[7:6], RDQS_PRE[5:4], WCK_PST[3:2], RDQS_PRE_2[1], RPST_MODE[0]
	task write_mr10(bit [1:0] rdqs_pst, bit [1:0] rdqs_pre, bit [1:0] wck_pst, bit rdqs_pre_2, bit rpst_mode);
		bit [7:0] op;
		op = {rdqs_pst, rdqs_pre, wck_pst, rdqs_pre_2, rpst_mode};
		mrw(bit'(MR10), op);
	endtask

//%%%%%%%%%%%%%%%%%%%%% Task to drive MODE REGISTER WRITE (MRW) command %%%%%%%%%%%%%%%%%%%%%
task mrw(bit[6:0]mr_addr,bit[7:0]mr_op);
	begin
		logic      mr_op_1;
	  	logic [6:0]mr_op_2;
	
	  	// Below Function will update global orig values for mr_addr, 
	  	// When user directly calls mrw() task in testcase 
	  	// hence its respective global orig bits also needs to be updated
	  	mr_op = update_all_mr_op(mr_addr, mr_op);
	
		// MRW-2 uses OP7 separately with some fixed control bits and then later drives OP[6:0] on CA.
	  	mr_op_1 = mr_op[7];
	  	mr_op_2 = mr_op[6:0];

		//%%%%%%%%%%%%%%%%%%%%%%% MRW-1 Setup phase %%%%%%%%%%%%%%%%%%%%%%%%%%%%
	  	@(negedge SystemClock);
	  	#((((simulation_cycle/4))*0.001)*1ns);
	  	drive_cs_p(1);
	  	drive_ca({7'b1011000});   // Driving CA signals when CS is high, CA[6:0] = {H,L,H,H,L,L,L}

		//%%%%%%%%%%%%%%%%%%%%%%% MRW-1 Execute phase %%%%%%%%%%%%%%%%%%%%%%%%%%%%
	  	@(posedge SystemClock);
	  	#((((simulation_cycle/4))*0.001)*1ns);
	  	drive_cs_p($urandom%1);  //As per our spec on falling edge cs is don't care(x) hence generating random value between 0 and 1
	  	drive_ca(mr_addr); 

		//%%%%%%%%%%%%%%%%%%%%%%% MRW-2 Setup phase %%%%%%%%%%%%%%%%%%%%%%%%%%%%
	  	@(negedge SystemClock);
	  	#((((simulation_cycle/4))*0.001)*1ns);
	  	drive_cs_p(1);
	  	drive_ca({mr_op_1,6'b001000});  // Driving CA signals when CS is high, CA[6:0] = {OP7,L,L,H,L,L,L} 

		//%%%%%%%%%%%%%%%%%%%%%%% MRW-2 Execute phase %%%%%%%%%%%%%%%%%%%%%%%%%%%%
	  	@(posedge SystemClock);
	  	#((((simulation_cycle/4))*0.001)*1ns);
	  	drive_cs_p($urandom%1);      //As per our spec on falling edge cs is don't care(x) hence generating random value between 0 and 1
	  	drive_ca(mr_op_2[6:0]);      // Driving CA signals when CS is don't care, CA[6:0] = {OP6,OP5,OP4,OP3,OP2,OP1,OP0}

	  	//When CBT is enabled the DQ/DMI should be low at posedge of MRW_2
	  	if(cbt_orig != 2'b00) begin
	  	  if(cbt_mode_orig == 1'b0) begin
	  	    dq[7] = 'b0;
	  	  end
	  	  else begin
	  	    dq[7] = 'b0;
	  	    dmi[0] = 'b0;
	  	  end
	  	end

    	// MRW to valid cmd delay ( tMRW )
    	tmrd = ($ceil(mem_cfg.timing_cfg.tmrd_ns/(simulation_cycle*0.001)) > 5) ? $ceil(mem_cfg.timing_cfg.tmrd_ns/(simulation_cycle*0.001)) : 5  ;
    	repeat(tmrd)@(negedge SystemClock);

		// Clear CS & CA
	  	@(negedge SystemClock);
	  	fork
	  	  begin
	  	    #((((simulation_cycle/4))*0.001)*1ns);
	  	    drive_cs_p(0);
	  	    drive_ca('x);
	  	  end
	  	join_none
	end
endtask : mrw

// Function to generate Operands
function bit [7:0] update_all_mr_op(bit [6:0] local_mr_addr, bit [7:0] local_mr_op);
	begin
		case (local_mr_addr)
			'd01 : begin
				ck_mode_orig = local_mr_op[3];
				wl_orig		 = local_mr_op[7:4];
				wck_mode_orig= local_mr_op[2];
			end
			'd02 : begin
				rl_orig  = local_mr_op[3:0];  // & get_nrbtp();
				nwr_orig = local_mr_op[7:4];
			end
			'd03 : begin
				pdds_orig 	= local_mr_op[2:0];
				bk_org_orig = local_mr_op[4:3];
				wls_orig    = local_mr_op[5];
				dbi_rd_orig = local_mr_op[6];
				dbi_wr_orig = local_mr_op[7];
			end
			'd10 : begin
        		rdqs_pst_orig   = local_mr_op[7:6];
        		rdqs_pre_orig   = local_mr_op[5:4];
        		wck_pst_orig    = local_mr_op[3:2];
        		rdqs_pre_2_orig = local_mr_op[1];
        		rpst_mode_orig  = local_mr_op[0];

        		// Decode WCK_PST into wckpst_wck (same logic as your old task)
        		case (wck_pst_orig)
        			2'b00: wckpst_wck = 2.0; // 2.5-0.5
        			2'b01: wckpst_wck = 4.0; // 4.5-0.5
        			2'b10: wckpst_wck = 6.0; // 6.5-0.5
        			default: wckpst_wck = 2.0;
				endcase

		
		return local_mr_op;

	end
endfunction
	
endclass
