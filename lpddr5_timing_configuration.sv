//############################################################################
// File:        lpddr5_timing_configurations.sv
// Author:      Ganesh and nitish 
// Date:        
// Description:  which contains all timing parameters 
//############################################################################

`ifndef LPDDR5_TIMING_CONFIGURATIONS_SV
`define LPDDR5_TIMING_CONFIGURATIONS_SV

class lpddr5_timing_configuration extends uvm_object;

  `uvm_object_utils(lpddr5_timing_configuration)

  function new(string name = "");
    super.new(name);
  endfunction


  ///////temp for excution//
  bit byte_mode_enable=0;
  int rl_orig_int;
  bit rdcfe_bit_orig;
  bit dbi_rd_orig;
  bit ckr_orig;
  bit[1:0] bk_org_orig;


 // real simulation_cycle =12;
  byte MR10_OP;

  bit dvfsc_orig;
  bit link_recc_en_orig;
  /////////////////////////////////////

  //Clock time-Period in ns
  real tck_avg_ns = 2.5;

  //Power-Up -- Reset -- Initilisation training 
  //Max voltage-ramp time at power-up
  rand int tINIT0_ns=20000000; //<=20ms
  //Min Reset_n low time after completion of voltage ramp
  rand int tINIT1_ns=200000;//>=200us
  //Min CS low time before RESET_n high
  rand int tINIT2_ns=10; //>=10ns
  //Min CS low time after RESET_n high
  rand int tINIT3_ns=2000000;   //>=2ms
  //Min stable clock before first CS high
  rand int tINIT4_ck=5;  //>=5*tCK
  //Min idle time before first MRW/MRR command
  rand int tINIT5_ns=2000;  //>=2us
  //ZQCAL latch quiet time 
  int tZQLAT_ns=30; //max(30ns,4nCK)
  //Min RESET_n low time for Reset initialization with stable power
  int tPW_RESET_ns =100; //>=100ns

  //randomizes tINIT parameters within valid limits and should be called at every power-up(start of simulation)
  function void randomize_INIT();
    this.randomize(tINIT0_ns,tINIT1_ns,tINIT2_ns,tINIT3_ns,tINIT4_ck,tINIT5_ns);
  endfunction

 constraint tINIT_c
  {
     tINIT0_ns inside {[0:20000000]};
     tINIT1_ns inside {[ 200000:1000000]};
     tINIT2_ns inside {[ 10:100]};
     tINIT3_ns inside {[ 2000000:10000000]};
     tINIT4_ck inside {[ 5:50]};
     tINIT5_ns inside {[ 2000:10000]};
//    tINIT0_ns == 10;// for simulation only
//    tINIT1_ns == 10;// for simulation only
//    tINIT2_ns == 10;// for simulation only
//    tINIT3_ns == 10;// for simulation only
//    tINIT4_ck == 10;// for simulation only
//    tINIT5_ns == 10;// for simulation only
  }// for simulation only



  //WCK signals
  real tWCKENL_wr_ck = 0;
  real tWCKENL_rd_ck = 0;
  real tWCKENL_fs_ck = 0;

  real tWCKPRE_Static_wr_ck = 1;
  real tWCKPRE_Static_rd_ck = 1;
  real tWCKPRE_Static_fs_ck = 1;

  real tWCKPRE_toggle_wr_ck = 3;
  real tWCKPRE_toggle_rd_ck = 3;
  real tWCKPRE_toggle_fs_ck = 0;

  real tWCKPST_wck = 2.5;
  real tRPRE_wck = 4;
  real tRPST_wck = 0.5;

  real tWCK2DQI_ns = (tck_avg_ns/4)/4; //wck_tp=ck_tp/4 & wck2dqi= wck/4
  real tWCK2DQO_ns = (tck_avg_ns/4)/4; //wck_tp=ck_tp/4 & wck2dqi= wck/4


  //Effective burst_length
  real effective_bl_ck = 2;
  real effective_bl_min_ck = 4;
  real effective_bl_max_ck = 8;

  //Self Refresh Timing
  real tESPD_ck = 2;//Delay from SRE command to PDE 


  //Minimum time to wait to issue any valid command after issuing Self Refresh Exit.
  real txsr_ns = 220;


  //Minimum time to wait to issue any valid command after issuing Power Down Exit.
  real txp_ns = 7.5;

  //READ Burst End to PRECHARGE Delay.

  real trbtp_ns = 7.5;


  //Row Precharge time for single bank.

  real trppb_ns = 18;


  //Row Precharge time for all bank.

  real trpab_ns = 21;


  //Active to Act
  real trrd_ns = 10;


  //Mode register set command delay.
  real tmrd_ns = 14;



  //Mode Register Write command Period.

  real tmrw_ns = 10;



  // Minimum self refresh time (entry to exit).

  real tsr_ns = 15; 

  //Frequency Set Point Switching Time

  real tfc_short_ns = 200;

  real tfc_middle_ns = 200;

  real tfc_long_ns = 250;


  //Activate_1 to Activate_2 maximum delay

  real taad_ck = 8; 

  //Minimum interval from Power Down Entry to Power Down Exit
  real tcspd_ns = 10; 


  //Delay from Power Down Entry to valid clock requirement

  real tcslck_ns = 5; 

  //Delay from Self Refresh Entry to valid clock requirement
  real tsreck_ns = 5; 


  //Delay from Power Down Exit to valid clock requirement

  real tckcsh_ck = 2; 

  //RAS to CAS Delay.

  real trcd_ns = 18;




  ///////////////////////task  get_tWCKPST_wck ///////////////////////////////////////
  task get_tWCKPST_wck (output real local_twckpst_wck );
    begin
      case(MR10_OP[3:2])
        2'b01 : local_twckpst_wck = 4.5;
        2'b10 : local_twckpst_wck = 6.5;
        default : local_twckpst_wck = 2.5;
      endcase
      tWCKPST_wck =local_twckpst_wck;
    end
  endtask : get_tWCKPST_wck 



  //task to get effective burst length for all ckr ,i.e, bl/n and bl/n_min and bl/n_max
  function void effective_burst_length(int burst_length, bit diff_bg);

    automatic int data_rate;
    automatic int global_ckr;

    begin
      if(ckr_orig) global_ckr =2; //1 == 2:1
      else global_ckr         =4; //0 == 4:1

      data_rate = (2*global_ckr*1000)/(tck_avg_ns); //global_ckr == ratio 

      case(ckr_orig) //MR18_OP[7]
        0 : begin //4:1
          case(bk_org_orig)
            2'b01 : begin  //8B mode (MR3_OP[4:3])
              if(burst_length==16)begin
                effective_bl_ck = burst_length/global_ckr ;
                effective_bl_min_ck = burst_length/global_ckr ;
                effective_bl_max_ck =  burst_length/global_ckr;
              end
              else begin
                effective_bl_ck = burst_length/(2*global_ckr) ; // for BL=16: 16/(2*4)=2 ; for BL=32: 32/(2*4) = 4; 
                effective_bl_min_ck = burst_length/(2*global_ckr) ;
                effective_bl_max_ck = burst_length/(2*global_ckr) ;
              end
            end
            2'b10 : begin //16B mode
              if(data_rate > 1600) begin
                `uvm_error("EFFECTIVE_BURST_LENGTH", $psprintf("In 16B Bank mode only data_rate lesser than 1600 Mbps is supported, data_rate observed %0d", data_rate));
              end
              else begin
                effective_bl_ck = burst_length/(2*global_ckr) ; // for BL=16: 16/(2*4)=2 ; for BL=32: 32/(2*4) = 4; 
                effective_bl_min_ck = burst_length/(2*global_ckr) ;
                effective_bl_max_ck = burst_length/(2*global_ckr) ;
              end
            end
            2'b00 : begin //BG_mode
              if(data_rate <= 1600) begin
                `uvm_error("EFFECTIVE_BURST_LENGTH", $psprintf("In 4B/4G Bank mode only data_rate greater than 1600 Mbps is supported, data_rate observed %0d", data_rate));
              end
              else begin
                if(diff_bg == 1'b1) begin
                  if(burst_length ==16) begin
                    effective_bl_ck = burst_length/(2*global_ckr) ; // for BL=16: 16/(2*4)=2 
                    effective_bl_min_ck = burst_length/(2*global_ckr) ; // for BL=16: 16/(2*4)=2 
                    effective_bl_max_ck = (2*burst_length)/(2*global_ckr) ; // for BL=16: 2*16/(2*4)=4` 
                  end
                  else begin
                    effective_bl_ck = (0.5*burst_length)/(2*global_ckr) ; // for BL=32: 0.5*32/(2*4) = 2; 
                    effective_bl_min_ck = (1.5*burst_length)/(2*global_ckr) ; // for BL=32: 1.5*32/(2*4) = 6; 
                    effective_bl_max_ck = (2*burst_length)/(2*global_ckr) ; // for BL=32: 2*32/(2*4) = 8;
                  end
                end
                else begin
                  if(burst_length ==16) begin
                    effective_bl_ck = (2*burst_length)/(2*global_ckr) ; // this is when same/diff bank with same bank group, 2*BL/(2*4)  for BL=16: 4 
                    effective_bl_min_ck = burst_length/(2*global_ckr) ; // this is when same/diff bank with same bank group, BL/(2*4)  for BL=16: 2 
                    effective_bl_max_ck = (2*burst_length)/(2*global_ckr) ; // this is when same/diff bank with same bank group, 2*BL/(2*4)  for BL=16: 4
                  end
                  else begin
                    effective_bl_ck = (2*burst_length)/(2*global_ckr) ; // for BL=32: 2*32/(2*4) = 8; 
                    effective_bl_min_ck = (1.5*burst_length)/(2*global_ckr) ; // for BL=32: 1.5*32/(2*4) = 6; 
                    effective_bl_max_ck = (2*burst_length)/(2*global_ckr) ; // for BL=32: 2*32/(2*4) = 8; 
                  end
                end
              end
            end
            default : begin
              effective_bl_ck = burst_length/(2*global_ckr) ; 
              effective_bl_min_ck = burst_length/(2*global_ckr) ; 
              effective_bl_max_ck = burst_length/(2*global_ckr) ; 
            end
          endcase
        end
        1 : begin //2:1
          if(data_rate > 1600) begin
            `uvm_error("EFFECTIVE_BURST_LENGTH", $psprintf("In wck:ck Ratio = 2:1 only data_rate less than and equal to 1600 Mbps is supported, data_rate observed %0d", data_rate));
          end
          else begin
            case(bk_org_orig)
              2'b01 : begin  //8B
                effective_bl_ck = burst_length/(2*global_ckr) ; // 32/(2*2) = 8; 
                effective_bl_min_ck = 32/(2*global_ckr) ; // 32/(2*2) = 8; 
                effective_bl_max_ck = 32/(2*global_ckr) ; // 32/(2*2) = 8; 
              end
              2'b10 : begin //16B
                  effective_bl_ck = burst_length/(2*global_ckr) ; // for BL16: 16/(2*2)= 4; 32/(2*2) = 8; 
                  effective_bl_min_ck = burst_length/(2*global_ckr) ; // 32/(2*2) = 8; 
                  effective_bl_max_ck = burst_length/(2*global_ckr) ; // 32/(2*2) = 8; 
              end
              default : begin
                effective_bl_ck = burst_length/(2*global_ckr) ; 
                effective_bl_min_ck = burst_length/(2*global_ckr) ; 
                effective_bl_max_ck = burst_length/(2*global_ckr) ; 
              end
            endcase
          end
        end
        default : begin
          effective_bl_ck = burst_length/(2*global_ckr) ; 
          effective_bl_min_ck = burst_length/(2*global_ckr) ; 
          effective_bl_max_ck = burst_length/(2*global_ckr) ; 
        end
      endcase
    end
  endfunction : effective_burst_length


  ////////////////////////task get_trpre_and_trpst_wck //////////////////////////////////

  task get_trpre_and_trpst_wck( output real local_trpre_wck , output real local_trpst_wck);
    begin
      if(MR10_OP[0]==0) begin // toggle mode
        case(MR10_OP[5:4]) //RDQS_PRE len
          2'b00 : local_trpre_wck = 0;
          2'b01 : local_trpre_wck = 2;
          2'b10 : local_trpre_wck = 4;
          2'b11 : local_trpre_wck = 4;
          default : local_trpre_wck = 0;
        endcase
        case(MR10_OP[7:6])// RDQS_PST len
          2'b01 : local_trpst_wck = 2.5;
          2'b10 : local_trpst_wck = 4.5;
          default : local_trpst_wck = 0.5;
        endcase
      end
      else begin //static
        case(MR10_OP[5:4])//RDQS_PRE len
          2'b00 : local_trpre_wck = 4;
          2'b01 : local_trpre_wck = 2;
          2'b10 : local_trpre_wck = 0;
          2'b11 : local_trpre_wck = 3;
          default : local_trpre_wck = 4;
        endcase
        case(MR10_OP[7:6])// RDQS_PST len
          2'b01 : local_trpst_wck = 2.5;
          2'b10 : local_trpst_wck = 4.5;
          default : local_trpst_wck = 0.5;
        endcase

      end

      tRPRE_wck = local_trpre_wck;
      tRPST_wck = local_trpst_wck;
    end
  endtask : get_trpre_and_trpst_wck


  ////////////////////////////task  get_twckenl_and_twckpre_toggle_and_twckpre_static_wr_ck/////////////////////////

  task get_twckenl_and_twckpre_toggle_and_twckpre_static_wr_ck(bit ratio,real tck_avg_ns,bit wls,output real local_twckenl_wr,output real local_twckpre_toggle_wr, output real local_twckpre_static_wr);
    begin
      case({ratio,wls}) //ratio = CKR reg MR18 OP[7] , WLS = MR3 OP[5], here ratio                                      
        'b00 : begin // 4:1 and setA
          if(tck_avg_ns >= 14.925 && tck_avg_ns<200) begin
            local_twckenl_wr     = 0;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 1;
          end
          else if(tck_avg_ns >=7.518 && tck_avg_ns <14.925) begin
            local_twckenl_wr     = 0;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 1;
          end
          else if(tck_avg_ns >=5 && tck_avg_ns <7.518) begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 1;
          end
          else if(tck_avg_ns >=3.745 && tck_avg_ns <5) begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=2.906 && tck_avg_ns <3.745) begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=2.5 && tck_avg_ns <2.906) begin
            local_twckenl_wr     = 2;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=2.141 && tck_avg_ns <2.5) begin
            local_twckenl_wr     = 2;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 3;
          end
          else if(tck_avg_ns >=1.876 && tck_avg_ns <2.141) begin
            local_twckenl_wr     = 2;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 3;
          end
          else if(tck_avg_ns >=1.666 && tck_avg_ns <1.876) begin
            local_twckenl_wr     = 3;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 3;
          end
          else if(tck_avg_ns >=1.453 && tck_avg_ns <1.666) begin
            local_twckenl_wr     = 3;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 4;
          end
          else if(tck_avg_ns >=1.333 && tck_avg_ns <1.453) begin
            local_twckenl_wr     = 4;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 4;
          end
          else if(tck_avg_ns >=1.25  && tck_avg_ns <1.333) begin
            local_twckenl_wr     = 4;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 4;
          end
          else begin
            local_twckenl_wr     = 0;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 1;
          end
        end
        'b01 : begin // 4:1 and setB
          if(tck_avg_ns >= 14.925 && tck_avg_ns<200) begin
            local_twckenl_wr     = 0;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 1;
          end
          else if(tck_avg_ns >=7.518 && tck_avg_ns <14.925) begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 1;
          end
          else if(tck_avg_ns >=5 && tck_avg_ns <7.518) begin
            local_twckenl_wr     = 2;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 1;
          end
          else if(tck_avg_ns >=3.745 && tck_avg_ns <5) begin
            local_twckenl_wr     = 2;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=2.906 && tck_avg_ns <3.745) begin
            local_twckenl_wr     = 4;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=2.5 && tck_avg_ns <2.906) begin
            local_twckenl_wr     = 5;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=2.141 && tck_avg_ns <2.5) begin
            local_twckenl_wr     = 5;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 3;
          end
          else if(tck_avg_ns >=1.876 && tck_avg_ns <2.141) begin
            local_twckenl_wr     = 7;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 3;
          end
          else if(tck_avg_ns >=1.666 && tck_avg_ns <1.876) begin
            local_twckenl_wr     = 8;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 3;
          end
          else if(tck_avg_ns >=1.453 && tck_avg_ns <1.666) begin
            local_twckenl_wr     = 9;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 4;
          end
          else if(tck_avg_ns >=1.333 && tck_avg_ns <1.453) begin
            local_twckenl_wr     = 10;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 4;
          end
          else if(tck_avg_ns >=1.25  && tck_avg_ns <1.333) begin
            local_twckenl_wr     = 11;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 4;
          end
          else begin
            local_twckenl_wr     = 0;
            local_twckpre_toggle_wr = 2;
            local_twckpre_static_wr = 1;
          end
        end
        'b10 : begin //2:1 and setA
          if(tck_avg_ns >= 7.518 && tck_avg_ns < 100) begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 3;
            local_twckpre_static_wr = 1;
          end
          else if(tck_avg_ns >=3.745 && tck_avg_ns <7.518) begin
            local_twckenl_wr     = 0;
            local_twckpre_toggle_wr = 3;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=2.5 && tck_avg_ns <3.745) begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 4;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=1.876 && tck_avg_ns <2.5) begin
            local_twckenl_wr     = 2;
            local_twckpre_toggle_wr = 4;
            local_twckpre_static_wr = 3;
          end
          else if(tck_avg_ns >=1.453 && tck_avg_ns <1.876) begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 4;
            local_twckpre_static_wr = 4;
          end
          else if(tck_avg_ns >=1.25 && tck_avg_ns <1.453) begin
            local_twckenl_wr     = 3;
            local_twckpre_toggle_wr = 4;
            local_twckpre_static_wr = 4;
          end
          else begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 3;
            local_twckpre_static_wr = 1;
          end
        end
        'b11 : begin //2:1 and setB
          if(tck_avg_ns >= 7.518 && tck_avg_ns < 100) begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 3;
            local_twckpre_static_wr = 1;
          end
          else if(tck_avg_ns >=3.745 && tck_avg_ns <7.518) begin
            local_twckenl_wr     = 2;
            local_twckpre_toggle_wr = 3;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=2.5 && tck_avg_ns <3.745) begin
            local_twckenl_wr     = 3;
            local_twckpre_toggle_wr = 4;
            local_twckpre_static_wr = 2;
          end
          else if(tck_avg_ns >=1.876 && tck_avg_ns <2.5) begin
            local_twckenl_wr     = 4;
            local_twckpre_toggle_wr = 4;
            local_twckpre_static_wr = 3;
          end
          else if(tck_avg_ns >=1.453 && tck_avg_ns <1.876) begin
            local_twckenl_wr     = 7;
            local_twckpre_toggle_wr = 4;
            local_twckpre_static_wr = 4;
          end
          else if(tck_avg_ns >=1.25 && tck_avg_ns <1.453) begin
            local_twckenl_wr     = 9;
            local_twckpre_toggle_wr = 4;
            local_twckpre_static_wr = 4;
          end
          else begin
            local_twckenl_wr     = 1;
            local_twckpre_toggle_wr = 3;
            local_twckpre_static_wr = 1;
          end
        end
      endcase
      tWCKENL_wr_ck = local_twckenl_wr;
      tWCKPRE_toggle_wr_ck = local_twckpre_toggle_wr;
      tWCKPRE_Static_wr_ck = local_twckpre_static_wr;
    end
  endtask : get_twckenl_and_twckpre_toggle_and_twckpre_static_wr_ck





  ////////////////////////////////////task get_twckenl_and_twckpre_toggle_and_twckpre_static_rd_ck//////////////////



  task get_twckenl_and_twckpre_toggle_and_twckpre_static_rd_ck(bit ratio,real tck_avg_ns,output real local_twckenl_rd,output real local_twckpre_toggle_rd, output real local_twckpre_static_rd);
    begin
      if(dvfsc_orig == 2'b00) begin//DVFSC Disabled or MR19 OP[1:0] = 00
        case({ratio,((dbi_rd_orig) | (rdcfe_bit_orig ))}) //ratio = CKR / reg MR18 OP[7] ; read dbi = MR3 OP[6] ; read data copy = MR21 OP[5] 
          //(dbi_rd_orig) | (rdcfe_bit_orig ) = set0/1/2
          'b00 : begin // ckr=4:1 or set 0/1 
            if(tck_avg_ns >= 14.925 && tck_avg_ns<200) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]
                local_twckenl_rd     = 0; //set0
                local_twckpre_toggle_rd = 3;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0; //set1
                local_twckpre_toggle_rd = 3;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=7.518 && tck_avg_ns <14.925) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0; //set0
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0; //set1
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=5 && tck_avg_ns <7.518) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1; // set0
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1; // set1
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=3.745 && tck_avg_ns <5) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1; //set0
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2; //set1
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.906 && tck_avg_ns <3.745) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2; //set0
                local_twckpre_toggle_rd = 5;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2; //set1
                local_twckpre_toggle_rd = 5;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.5 && tck_avg_ns <2.906) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3; //set0
                local_twckpre_toggle_rd = 5;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 4; //set1
                local_twckpre_toggle_rd = 5;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.141 && tck_avg_ns <2.5) begin
              if(link_recc_en_orig == 2'b01 ) begin//RECC Enabled MR22 OP[7:6]=01
                if(byte_mode_enable == 0) begin //x16 mode latency
                  local_twckenl_rd     = 5; //set0
                  local_twckpre_toggle_rd = 5;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 6; //set1
                  local_twckpre_toggle_rd = 5;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency
                  local_twckenl_rd     = 3; //set0
                  local_twckpre_toggle_rd = 5;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 4; //set1
                  local_twckpre_toggle_rd = 5;
                end
              end
              local_twckpre_static_rd=3;
            end
            else if(tck_avg_ns >=1.876 && tck_avg_ns <2.141) begin
              if(link_recc_en_orig == 2'b01 ) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency
                  local_twckenl_rd     = 5;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 6;
                  local_twckpre_toggle_rd = 6;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 4;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 5;
                  local_twckpre_toggle_rd = 6;
                end
              end
              local_twckpre_static_rd=3;
            end
            else if(tck_avg_ns >=1.666 && tck_avg_ns <1.876) begin
              if(link_recc_en_orig == 2'b01) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 7;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 8;
                  local_twckpre_toggle_rd = 6;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 5;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 6;
                  local_twckpre_toggle_rd = 6;
                end
              end
              local_twckpre_static_rd=3;
            end
            else if(tck_avg_ns >=1.453 && tck_avg_ns <1.666) begin
              if(link_recc_en_orig == 2'b01) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 8;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 9;
                  local_twckpre_toggle_rd = 6;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 6;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 7;
                  local_twckpre_toggle_rd = 6;
                end
              end
              local_twckpre_static_rd=4;
            end
            else if(tck_avg_ns >=1.333 && tck_avg_ns <1.453) begin
              if(link_recc_en_orig == 2'b01 ) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 8;
                  local_twckpre_toggle_rd = 7;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 10;
                  local_twckpre_toggle_rd = 7;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 6;
                  local_twckpre_toggle_rd = 7;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 7;
                  local_twckpre_toggle_rd = 7;
                end
              end
              local_twckpre_static_rd=4;
            end
            else if(tck_avg_ns >=1.25  && tck_avg_ns <1.333) begin
              if(link_recc_en_orig == 2'b01) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 9;
                  local_twckpre_toggle_rd = 7;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 11;
                  local_twckpre_toggle_rd = 7;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 7;
                  local_twckpre_toggle_rd = 7;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 8;
                  local_twckpre_toggle_rd = 7;
                end
              end
              local_twckpre_static_rd=4;
            end
            else begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              local_twckpre_static_rd=1;
            end
          end
          'b01 : begin 
            if(tck_avg_ns >= 14.925 && tck_avg_ns<200) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=7.518 && tck_avg_ns <14.925) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=5 && tck_avg_ns <7.518) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1;
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=3.745 && tck_avg_ns <5) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.906 && tck_avg_ns <3.745) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 5;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3;
                local_twckpre_toggle_rd = 5;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.5 && tck_avg_ns <2.906) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 4;
                local_twckpre_toggle_rd = 5;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 4;
                local_twckpre_toggle_rd = 5;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.141 && tck_avg_ns <2.5) begin
              if(link_recc_en_orig == 2'b01) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 5;
                  local_twckpre_toggle_rd = 5;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 6;
                  local_twckpre_toggle_rd = 5;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 4;
                  local_twckpre_toggle_rd = 5;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 5;
                  local_twckpre_toggle_rd = 5;
                end
              end
              local_twckpre_static_rd=3;
            end
            else if(tck_avg_ns >=1.876 && tck_avg_ns <2.141) begin
              if(link_recc_en_orig == 2'b01) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 5;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 6;
                  local_twckpre_toggle_rd = 6;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 5;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 6;
                  local_twckpre_toggle_rd = 6;
                end
              end
              local_twckpre_static_rd=3;
            end
            else if(tck_avg_ns >=1.666 && tck_avg_ns <1.876) begin
              if(link_recc_en_orig == 2'b01) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 7;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 8;
                  local_twckpre_toggle_rd = 6;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 6;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 7;
                  local_twckpre_toggle_rd = 6;
                end
              end
              local_twckpre_static_rd=3;
            end
            else if(tck_avg_ns >=1.453 && tck_avg_ns <1.666) begin
              if(link_recc_en_orig == 2'b01) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 8;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 9;
                  local_twckpre_toggle_rd = 6;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 7;
                  local_twckpre_toggle_rd = 6;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 8;
                  local_twckpre_toggle_rd = 6;
                end
              end
              local_twckpre_static_rd=4;
            end
            else if(tck_avg_ns >=1.333 && tck_avg_ns <1.453) begin
              if(link_recc_en_orig == 2'b01) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 8;
                  local_twckpre_toggle_rd = 7;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 10;
                  local_twckpre_toggle_rd = 7;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 7;
                  local_twckpre_toggle_rd = 7;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 9;
                  local_twckpre_toggle_rd = 7;
                end
              end
              local_twckpre_static_rd=4;
            end
            else if(tck_avg_ns >= 1.25   && tck_avg_ns <1.333) begin
              if(link_recc_en_orig == 2'b01) begin//RECC Enabled, 
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 9;
                  local_twckpre_toggle_rd = 7;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 11;
                  local_twckpre_toggle_rd = 7;
                end
              end
              else begin
                if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 8;
                  local_twckpre_toggle_rd = 7;
                end
                else begin //x8 mode latency or MR0 OP[1]

                  local_twckenl_rd     = 10;
                  local_twckpre_toggle_rd = 7;
                end
              end
              local_twckpre_static_rd=4;
            end
            else begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              local_twckpre_static_rd=1;
            end
          end
          'b10 : begin 
            if(tck_avg_ns >= 7.518 && tck_avg_ns<100) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=3.745 && tck_avg_ns <7.518) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 7;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 7;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.5 && tck_avg_ns <3.745) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1;
                local_twckpre_toggle_rd = 8;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1;
                local_twckpre_toggle_rd = 8;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=1.876 && tck_avg_ns <2.5) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 8;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 4;
                local_twckpre_toggle_rd = 8;
              end
              local_twckpre_static_rd=3;
            end
            else if(tck_avg_ns >=1.453 && tck_avg_ns <1.876) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3;
                local_twckpre_toggle_rd = 10;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3;
                local_twckpre_toggle_rd = 10;
              end
              local_twckpre_static_rd=4;
            end
            else if(tck_avg_ns >=1.25 && tck_avg_ns <1.453) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 5;
                local_twckpre_toggle_rd = 10;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 7;
                local_twckpre_toggle_rd = 10;
              end
              local_twckpre_static_rd=4;
            end
            else begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              local_twckpre_static_rd=2;
            end
          end
          'b11 : begin 
            if(tck_avg_ns >= 7.518 && tck_avg_ns<100) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=3.745 && tck_avg_ns <7.518) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 7;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 7;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.5 && tck_avg_ns <3.745) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1;
                local_twckpre_toggle_rd = 8;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3;
                local_twckpre_toggle_rd = 8;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=1.876 && tck_avg_ns <2.5) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 4;
                local_twckpre_toggle_rd = 8;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 4;
                local_twckpre_toggle_rd = 8;
              end
              local_twckpre_static_rd=3;
            end
            else if(tck_avg_ns >=1.453 && tck_avg_ns <1.876) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3;
                local_twckpre_toggle_rd = 10;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 5;
                local_twckpre_toggle_rd = 10;
              end
              local_twckpre_static_rd=4;
            end
            else if(tck_avg_ns >=1.25 && tck_avg_ns <1.453) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 7;
                local_twckpre_toggle_rd = 10;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 7;
                local_twckpre_toggle_rd = 10;
              end
              local_twckpre_static_rd=4;
            end
            else begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              local_twckpre_static_rd=1;
            end
          end
        endcase
      end
      else if(dvfsc_orig == 2'b01) begin//DVFSC Enabled
        case({ratio,(dbi_rd_orig | rdcfe_bit_orig )})
          'b00 : begin 
            if(tck_avg_ns >= 14.925 && tck_avg_ns<200) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=7.518 && tck_avg_ns <14.925) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1;
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=5 && tck_avg_ns <7.518) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=1;
            end
            else begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              local_twckpre_static_rd=1;
            end
          end
          'b01 : begin 
            if(tck_avg_ns >= 14.925 && tck_avg_ns<200) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=7.518 && tck_avg_ns <14.925) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1;
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 1;
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=5 && tck_avg_ns <7.518) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 4;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3;
                local_twckpre_toggle_rd = 4;
              end
              local_twckpre_static_rd=1;
            end
            else begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 3;
              end
              local_twckpre_static_rd=1;
            end
          end
          'b10 : begin 
            if(tck_avg_ns >= 7.518 && tck_avg_ns<100) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=3.745 && tck_avg_ns <7.518) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 7;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 7;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.5 && tck_avg_ns <3.745) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3;
                local_twckpre_toggle_rd = 8;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3;
                local_twckpre_toggle_rd = 8;
              end
              local_twckpre_static_rd=2;
            end
            else begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              local_twckpre_static_rd=1;
            end
          end
          'b11 : begin 
            if(tck_avg_ns >= 7.518 && tck_avg_ns<100) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              local_twckpre_static_rd=1;
            end
            else if(tck_avg_ns >=3.745 && tck_avg_ns <7.518) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 7;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 2;
                local_twckpre_toggle_rd = 7;
              end
              local_twckpre_static_rd=2;
            end
            else if(tck_avg_ns >=2.5 && tck_avg_ns <3.745) begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 3;
                local_twckpre_toggle_rd = 8;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 5;
                local_twckpre_toggle_rd = 8;
              end
              local_twckpre_static_rd=2;
            end
            else begin
              if(byte_mode_enable == 0) begin //x16 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              else begin //x8 mode latency or MR0 OP[1]

                local_twckenl_rd     = 0;
                local_twckpre_toggle_rd = 6;
              end
              local_twckpre_static_rd=1;
            end
          end
        endcase
      end

      tWCKENL_rd_ck = local_twckenl_rd;
      tWCKPRE_toggle_rd_ck = local_twckpre_toggle_rd;
      tWCKPRE_Static_rd_ck = local_twckpre_static_rd;
    end
  endtask


  /////////////////////////task get_twckenl_and_twckpre_static_fs_ck///////////////////////////////

  task get_twckenl_and_twckpre_static_fs_ck(bit ratio,real tck_avg_ns,output real local_twckenl_fast,output real local_twckpre_static_fast);
    begin
      case({ratio}) //ratio = CKR reg MR18 OP[7]
        'b0 :  begin //4:1
          if(tck_avg_ns >= 14.925 && tck_avg_ns <200) begin
            local_twckenl_fast     = 0;
            local_twckpre_static_fast = 1;
          end
          else if(tck_avg_ns >=7.518 && tck_avg_ns <14.925) begin
            local_twckenl_fast     = 0;
            local_twckpre_static_fast = 1;
          end
          else if(tck_avg_ns >=5 && tck_avg_ns <7.518) begin
            local_twckenl_fast     = 1;
            local_twckpre_static_fast = 1;
          end
          else if(tck_avg_ns >=3.745 && tck_avg_ns <5) begin
            local_twckenl_fast     = 1;
            local_twckpre_static_fast = 2;
          end
          else if(tck_avg_ns >=2.906 && tck_avg_ns <3.745) begin
            local_twckenl_fast     = 1;
            local_twckpre_static_fast = 2;
          end
          else if(tck_avg_ns >=2.5 && tck_avg_ns <2.906) begin
            local_twckenl_fast     = 1;
            local_twckpre_static_fast = 2;
          end
          else if(tck_avg_ns >=2.141 && tck_avg_ns <2.5) begin
            local_twckenl_fast     = 1;
            local_twckpre_static_fast = 3;
          end
          else if(tck_avg_ns >=1.876 && tck_avg_ns <2.141) begin
            local_twckenl_fast     = 1;
            local_twckpre_static_fast = 3;
          end
          else if(tck_avg_ns >=1.666 && tck_avg_ns <1.876) begin
            local_twckenl_fast     = 2;
            local_twckpre_static_fast = 3;
          end
          else if(tck_avg_ns >=1.453 && tck_avg_ns <1.666) begin
            local_twckenl_fast     = 2;
            local_twckpre_static_fast = 4;
          end
          else if(tck_avg_ns >=1.333 && tck_avg_ns <1.453) begin
            local_twckenl_fast     = 2;
            local_twckpre_static_fast = 4;
          end
          else if(tck_avg_ns >=1.25 && tck_avg_ns <1.333) begin
            local_twckenl_fast     = 2;
            local_twckpre_static_fast = 4;
          end
          else begin
            local_twckenl_fast     = 0;
            local_twckpre_static_fast = 1;
          end
        end
        'b1  : begin //2:1
          if(tck_avg_ns >= 7.518 && tck_avg_ns <100) begin
            local_twckenl_fast     = 0;
            local_twckpre_static_fast = 1;
          end
          else if(tck_avg_ns >=3.745 && tck_avg_ns <7.518) begin
            local_twckenl_fast     = 0;
            local_twckpre_static_fast = 2;
          end
          else if(tck_avg_ns >=2.5 && tck_avg_ns <3.745) begin
            local_twckenl_fast     = 1;
            local_twckpre_static_fast = 2;
          end
          else if(tck_avg_ns >=1.876 && tck_avg_ns <2.5) begin
            local_twckenl_fast     = 1;
            local_twckpre_static_fast = 3;
          end
          else if(tck_avg_ns >=1.453 && tck_avg_ns <1.876) begin
            local_twckenl_fast     = 1;
            local_twckpre_static_fast = 4;
          end
          else if(tck_avg_ns >=1.25 && tck_avg_ns <1.453) begin
            local_twckenl_fast     = 2;
            local_twckpre_static_fast = 4;
          end
          else begin
            local_twckenl_fast     = 0;
            local_twckpre_static_fast = 1;
          end
        end
      endcase


      tWCKENL_fs_ck=local_twckenl_fast;
      tWCKPRE_Static_fs_ck=local_twckpre_static_fast;
    end
  endtask : get_twckenl_and_twckpre_static_fs_ck;


//task to get the twckpre_toggle_fs value which is same as RL value
  task get_twckpre_toggle_fs_ck (bit ratio,real tck_avg_ns,bit[1:0] dvfsc,output int local_twckpre_toggle_fs_ck);
    begin
      automatic int rl;
      automatic int nwr;
      read_latency(ratio, tck_avg_ns, dvfsc, rl, nwr);
      local_twckpre_toggle_fs_ck=rl;
      tWCKPRE_toggle_fs_ck=rl; 
    end
  endtask


  

  //////////////////////////////////////////////////////////
  int ratio;   
//   real tck_avg_ns=1500;
  bit wls;

  bit dvfsc_enabled;
  int wl_ck;

  //////////////////////////////////////write_latency task/////////////////////////////////////  

  task write_latency(bit ratio, real tck_avg_ns, bit dvfsc_enabled,
                     bit wls, output int wl_ck);

    if (dvfsc_enabled == 0) begin

      case ({ratio, wls})  // ratio: 0 -> 4:1, 1 -> 2:1; wls: 0 -> SETA, 1 -> SETB

        'b00: begin
          if (tck_avg_ns >= 14.925) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 2; // x16
            end else begin
              wl_ck = 2; // x8
            end
          end
          else if (tck_avg_ns >= 7.518 && tck_avg_ns < 14.925) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 2;
            end else begin
              wl_ck = 2;
            end
          end
          else if (tck_avg_ns >= 5 && tck_avg_ns < 7.518) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 3;
            end else begin
              wl_ck = 3;
            end
          end
          else if (tck_avg_ns >= 3.745 && tck_avg_ns < 5) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 4;
            end else begin
              wl_ck = 4;
            end
          end
          else if (tck_avg_ns >= 2.906 && tck_avg_ns < 3.745) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 4;
            end else begin
              wl_ck = 4;
            end
          end
          else if (tck_avg_ns >= 2.5 && tck_avg_ns < 2.906) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 5;
            end else begin
              wl_ck = 5;
            end
          end
          else if (tck_avg_ns >= 2.141 && tck_avg_ns < 2.5) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 6;
            end else begin
              wl_ck = 6;
            end
          end
          else if (tck_avg_ns >= 1.876 && tck_avg_ns < 2.141) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 6;
            end else begin
              wl_ck = 6;
            end
          end
          else if (tck_avg_ns >= 1.666 && tck_avg_ns < 1.876) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 7;
            end else begin
              wl_ck = 7;
            end
          end
          else if (tck_avg_ns >= 1.453 && tck_avg_ns < 1.666) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 8;
            end else begin
              wl_ck = 8;
            end
          end
          else if (tck_avg_ns >= 1.333 && tck_avg_ns < 1.453) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 9;
            end else begin
              wl_ck = 9;
            end
          end
          else if (tck_avg_ns >= 1.25 && tck_avg_ns < 1.333) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 9;
            end else begin
              wl_ck = 9;
            end
          end
        end

        'b01: begin
          if (tck_avg_ns >= 14.925) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 2;
            end else begin
              wl_ck = 2;
            end
          end
          else if (tck_avg_ns >= 7.518 && tck_avg_ns < 14.925) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 3;
            end else begin
              wl_ck = 3;
            end
          end
          else if (tck_avg_ns >= 5 && tck_avg_ns < 7.518) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 4;
            end else begin
              wl_ck = 4;
            end
          end
          else if (tck_avg_ns >= 3.745 && tck_avg_ns < 5) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 5;
            end else begin
              wl_ck = 5;
            end
          end
          else if (tck_avg_ns >= 2.906 && tck_avg_ns < 3.745) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 7;
            end else begin
              wl_ck = 7;
            end
          end
          else if (tck_avg_ns >= 2.5 && tck_avg_ns < 2.906) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 8;
            end else begin
              wl_ck = 8;
            end
          end
          else if (tck_avg_ns >= 2.141 && tck_avg_ns < 2.5) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 9;
            end else begin
              wl_ck = 9;
            end
          end
          else if (tck_avg_ns >= 1.876 && tck_avg_ns < 2.141) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 11;
            end else begin
              wl_ck = 11;
            end
          end
          else if (tck_avg_ns >= 1.666 && tck_avg_ns < 1.876) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 12;
            end else begin
              wl_ck = 12;
            end
          end
          else if (tck_avg_ns >= 1.453 && tck_avg_ns < 1.666) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 13;
            end else begin
              wl_ck = 13;
            end
          end
          else if (tck_avg_ns >= 1.333 && tck_avg_ns < 1.453) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 15;
            end else begin
              wl_ck = 15;
            end
          end
          else if (tck_avg_ns >= 1.25 && tck_avg_ns < 1.333) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 16;
            end else begin
              wl_ck = 16;
            end
          end
          else begin
            if (byte_mode_enable == 0) begin
              wl_ck = 2;
            end else begin
              wl_ck = 2;
            end
          end
        end

        'b10: begin
          if (tck_avg_ns >= 7.518) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 4;
            end else begin
              wl_ck = 4;
            end
          end
          else if (tck_avg_ns >= 3.745 && tck_avg_ns < 7.518) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 4;
            end else begin
              wl_ck = 4;
            end
          end
          else if (tck_avg_ns >= 2.5 && tck_avg_ns < 3.745) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 6;
            end else begin
              wl_ck = 6;
            end
          end
          else if (tck_avg_ns >= 1.876 && tck_avg_ns < 2.5) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 8;
            end else begin
              wl_ck = 8;
            end
          end
          else if (tck_avg_ns >= 1.453 && tck_avg_ns < 1.876) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 8;
            end else begin
              wl_ck = 8;
            end
          end
          else if (tck_avg_ns >= 1.25 && tck_avg_ns < 1.454) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 10;
            end else begin
              wl_ck = 10;
            end
          end
          else begin
            if (byte_mode_enable == 0) begin
              wl_ck = 4;
            end else begin
              wl_ck = 4;
            end
          end
        end

        'b11: begin
          if (tck_avg_ns >= 7.518) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 4;
            end else begin
              wl_ck = 4;
            end
          end
          else if (tck_avg_ns >= 3.745 && tck_avg_ns < 7.518) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 6;
            end else begin
              wl_ck = 6;
            end
          end
          else if (tck_avg_ns >= 2.5 && tck_avg_ns < 3.745) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 8;
            end else begin
              wl_ck = 8;
            end
          end
          else if (tck_avg_ns >= 1.876 && tck_avg_ns < 2.5) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 10;
            end else begin
              wl_ck = 10;
            end
          end
          else if (tck_avg_ns >= 1.453 && tck_avg_ns < 1.876) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 14;
            end else begin
              wl_ck = 14;
            end
          end
          else if (tck_avg_ns >= 1.25 && tck_avg_ns < 1.454) begin
            if (byte_mode_enable == 0) begin
              wl_ck = 16;
            end else begin
              wl_ck = 16;
            end
          end
          else begin
            if (byte_mode_enable == 0) begin
              wl_ck = 4;
            end else begin
              wl_ck = 4;
            end
          end
        end

        default: begin
          if (byte_mode_enable == 0) begin
            wl_ck = 2;
          end else begin
            wl_ck = 2;
          end
        end

      endcase
    end

    // change_wls(wls);mode reg 3;
    // @(negedge SystemClock);

    // mrw(8'h03,{2'b00,1'b1,2'b01,3'b110});

  endtask



  //////////////////////////////////////////////change_wl_task/////////////////////////////////////////////////////  



  //  task change_wl(bit ratio,int wl_ck,real tck_avg_ns,bit wls,output wl_opcode);
  task change_wl(bit ratio,real tck_avg_ns,bit wls,output int wl_opcode);
    begin
      automatic bit [3:0] wl_opcode;


      case(ratio)  //ratio :0 :4:1 and 1: 2:1 
        //wls -> 0 for SETA and 1 for SETB

        0 : begin  
          if (tck_avg_ns >= 14.925) begin                      // freq = 67 MHz
            wl_opcode = 0000;
          end
          else if (tck_avg_ns >= 7.518  && tck_avg_ns < 14.925) begin // 67�133 MHz
            wl_opcode = 0001;
          end
          else if (tck_avg_ns >= 5      && tck_avg_ns < 7.518) begin  // 133�200 MHz
            wl_opcode = 0010;
          end
          else if (tck_avg_ns >= 3.745  && tck_avg_ns < 5) begin      // 200�267 MHz
            wl_opcode = 0011;
          end
          else if (tck_avg_ns >= 2.906  && tck_avg_ns < 3.745) begin  // 267�344 MHz
            wl_opcode = 0100;
          end
          else if (tck_avg_ns >= 2.5    && tck_avg_ns < 2.906) begin  // 344�400 MHz
            wl_opcode = 0101;
          end
          else if (tck_avg_ns >= 2.141  && tck_avg_ns < 2.5) begin    // 400�467 MHz
            wl_opcode = 0110;
          end 
          else if (tck_avg_ns >= 1.876  && tck_avg_ns < 2.141) begin  // 467�533 MHz
            wl_opcode = 0111;
          end
          else if (tck_avg_ns >= 1.666  && tck_avg_ns < 1.876) begin  // 533�600 MHz
            wl_opcode = 1000;
          end
          else if (tck_avg_ns >= 1.453  && tck_avg_ns < 1.666) begin  // 600�688 MHz
            wl_opcode = 1001;
          end
          else if (tck_avg_ns >= 1.333  && tck_avg_ns < 1.453) begin  // 688�750 MHz
            wl_opcode = 1010;
          end
          else if (tck_avg_ns >= 1.25  && tck_avg_ns < 1.333) begin   // 750�800 MHz
            wl_opcode = 1011;
          end
        end




        1 : begin  
          if (tck_avg_ns >= 7.518) begin                       // 10�133 MHz
            wl_opcode = 0000;
          end
          else if (tck_avg_ns >= 3.745 && tck_avg_ns < 7.518) begin   // 133�267 MHz
            wl_opcode = 0001;
          end
          else if (tck_avg_ns >= 2.5   && tck_avg_ns < 3.745) begin   // 267�400 MHz
            wl_opcode = 0010;
          end
          else if (tck_avg_ns >= 1.876 && tck_avg_ns < 2.5) begin     // 400�533 MHz
            wl_opcode = 0011;
          end
          else if (tck_avg_ns >= 1.454 && tck_avg_ns < 1.876) begin   // 533�688 MHz
            wl_opcode = 0100;
          end
          else if (tck_avg_ns >= 1.25  && tck_avg_ns < 1.454) begin   // 688�800 MHz
            wl_opcode = 0101;
          end
        end


      endcase
    end


    // change_ckr(ratio)  //Mode reg 18
    // mrw(8'h12,{1'b0,3'b000,3'b000}); //4:1 ratio 


    // mrw(6'h01,5'b10110); //mode reg 1 (ck mode and wl)

    // mr_write_1(wl_opcode,ck_mode_orig_wck_mode_orig)
  endtask




  ////////////////////////////////////READ LAtency Task///////////////////////////////////////////          

  task read_latency(bit ratio,real tck_avg_ns,bit[1:0] dvfsc,output int rl,output int nwr);

    if (dvfsc_enabled == 00) begin

      case ({ratio, (dbi_rd_orig | rdcfe_bit_orig)})

        // ---------------------------------------------------------
        // SET0 and SET1
        // ---------------------------------------------------------
        'b00: begin
          if (tck_avg_ns >= 14.925) begin
            if (byte_mode_enable == 0) begin
              rl = 3;
              nwr = 3;
            end else begin
              rl = 3;
              nwr = 3;
            end
          end
          else if (tck_avg_ns >= 7.518 && tck_avg_ns < 14.925) begin
            if (byte_mode_enable == 0) begin
              rl = 4;
              nwr = 5;
            end else begin
              rl = 4;
              nwr = 5;
            end
          end
          else if (tck_avg_ns >= 5 && tck_avg_ns < 7.518) begin
            if (byte_mode_enable == 0) begin
              rl = 5;
              nwr = 7;
            end else begin
              rl = 5;
              nwr = 8;
            end
          end
          else if (tck_avg_ns >= 3.745 && tck_avg_ns < 5) begin
            if (byte_mode_enable == 0) begin
              rl = 6;
              nwr = 10;
            end else begin
              rl = 7;
              nwr = 10;
            end
          end
          else if (tck_avg_ns >= 2.906 && tck_avg_ns < 3.745) begin
            if (byte_mode_enable == 0) begin
              rl = 8;
              nwr = 12;
            end else begin
              rl = 8;
              nwr = 13;
            end
          end
          else if (tck_avg_ns >= 2.5 && tck_avg_ns < 2.906) begin
            if (byte_mode_enable == 0) begin
              rl = 9;
              nwr = 14;
            end else begin
              rl = 10;
              nwr = 15;
            end
          end
          else if (tck_avg_ns >= 2.141 && tck_avg_ns < 2.5) begin
            if (byte_mode_enable == 0) begin
              rl = 10;
              nwr = 16;
            end else begin
              rl = 11;
              nwr = 17;
            end
          end
          else if (tck_avg_ns >= 1.876 && tck_avg_ns < 2.141) begin
            if (byte_mode_enable == 0) begin
              rl = 12;
              nwr = 19;
            end else begin
              rl = 13;
              nwr = 20;
            end
          end
          else if (tck_avg_ns >= 1.666 && tck_avg_ns < 1.876) begin
            if (byte_mode_enable == 0) begin
              rl = 13;
              nwr = 21;
            end else begin
              rl = 14;
              nwr = 22;
            end
          end
          else if (tck_avg_ns >= 1.453 && tck_avg_ns < 1.666) begin
            if (byte_mode_enable == 0) begin
              rl = 15;
              nwr = 24;
            end else begin
              rl = 16;
              nwr = 25;
            end
          end
          else if (tck_avg_ns >= 1.333 && tck_avg_ns < 1.453) begin
            if (byte_mode_enable == 0) begin
              rl = 16;
              nwr = 26;
            end else begin
              rl = 17;
              nwr = 28;
            end
          end
          else if (tck_avg_ns >= 1.25 && tck_avg_ns < 1.333) begin
            if (byte_mode_enable == 0) begin
              rl = 17;
              nwr = 28;
            end else begin
              rl = 18;
              nwr = 29;
            end
          end

          rl_orig_int = rl;
        end

        // ---------------------------------------------------------
        // SET1 and SET2 (4:1)
        // ---------------------------------------------------------
        'b01: begin
          if (tck_avg_ns >= 14.925) begin
            if (byte_mode_enable == 0) begin
              rl = 3;
              nwr = 3;
            end else begin
              rl = 3;
              nwr = 3;
            end
          end
          else if (tck_avg_ns >= 7.518 && tck_avg_ns < 14.925) begin
            if (byte_mode_enable == 0) begin
              rl = 4;
              nwr = 5;
            end else begin
              rl = 4;
              nwr = 5;
            end
          end
          else if (tck_avg_ns >= 5 && tck_avg_ns < 7.518) begin
            if (byte_mode_enable == 0) begin
              rl = 5;
              nwr = 7;
            end else begin
              rl = 6;
              nwr = 8;
            end
          end
          else if (tck_avg_ns >= 3.745 && tck_avg_ns < 5) begin
            if (byte_mode_enable == 0) begin
              rl = 7;
              nwr = 10;
            end else begin
              rl = 7;
              nwr = 10;
            end
          end
          else if (tck_avg_ns >= 2.906 && tck_avg_ns < 3.745) begin
            if (byte_mode_enable == 0) begin
              rl = 8;
              nwr = 12;
            end else begin
              rl = 9;
              nwr = 13;
            end
          end
          else if (tck_avg_ns >= 2.5 && tck_avg_ns < 2.906) begin
            if (byte_mode_enable == 0) begin
              rl = 10;
              nwr = 14;
            end else begin
              rl = 10;
              nwr = 15;
            end
          end
          else if (tck_avg_ns >= 2.141 && tck_avg_ns < 2.5) begin
            if (byte_mode_enable == 0) begin
              rl = 11;
              nwr = 16;
            end else begin
              rl = 12;
              nwr = 17;
            end
          end
          else if (tck_avg_ns >= 1.876 && tck_avg_ns < 2.141) begin
            if (byte_mode_enable == 0) begin
              rl = 13;
              nwr = 19;
            end 
            else begin
              rl = 14;
              nwr = 20;
            end
          end
          else if (tck_avg_ns >= 1.666 && tck_avg_ns < 1.876) begin
            if (byte_mode_enable == 0) begin
              rl = 14;
              nwr = 21;
            end 
            else begin
              rl = 15;
              nwr = 22;
            end
          end
          else if (tck_avg_ns >= 1.453 && tck_avg_ns < 1.666) begin
            if (byte_mode_enable == 0) begin
              rl = 16;
              nwr = 24;
            end else begin
              rl = 17;
              nwr = 25;
            end
          end
          else if (tck_avg_ns >= 1.333 && tck_avg_ns < 1.453) begin
            if (byte_mode_enable == 0) begin
              rl = 17;
              nwr = 26;
            end else begin
              rl = 19;
              nwr = 28;
            end
          end
          else if (tck_avg_ns >= 1.25 && tck_avg_ns < 1.333) begin
            if (byte_mode_enable == 0) begin
              rl = 18;
              nwr = 28;
            end else begin
              rl = 20;
              nwr = 29;
            end
          end
        end

        // ---------------------------------------------------------
        // SET1 and SET2 (2:1)
        // ---------------------------------------------------------
        'b10: begin
          if (tck_avg_ns >= 7.518) begin
            if (byte_mode_enable == 0) begin
              rl = 6;
              nwr = 5;
            end else begin
              rl = 6;
              nwr = 5;
            end
          end
          else if (tck_avg_ns >= 3.745 && tck_avg_ns < 7.518) begin
            if (byte_mode_enable == 0) begin
              rl = 8;
              nwr = 10;
            end else begin
              rl = 8;
              nwr = 10;
            end
          end
          else if (tck_avg_ns >= 2.5 && tck_avg_ns < 3.745) begin
            if (byte_mode_enable == 0) begin
              rl = 10;
              nwr = 14;
            end else begin
              rl = 10;
              nwr = 15;
            end
          end
          else if (tck_avg_ns >= 1.876 && tck_avg_ns < 2.5) begin
            if (byte_mode_enable == 0) begin
              rl = 12;
              nwr = 19;
            end else begin
              rl = 14;
              nwr = 20;
            end
          end
          else if (tck_avg_ns >= 1.453 && tck_avg_ns < 1.876) begin
            if (byte_mode_enable == 0) begin
              rl = 16;
              nwr = 24;
            end else begin
              rl = 16;
              nwr = 25;
            end
          end
          else if (tck_avg_ns >= 1.25 && tck_avg_ns < 1.453) begin
            if (byte_mode_enable == 0) begin
              rl = 18;
              nwr = 28;
            end else begin
              rl = 20;
              nwr = 29;
            end
          end
          else begin
            if (byte_mode_enable == 0) begin
              rl = 6;
              nwr = 5;
            end else begin
              rl = 6;
              nwr = 5;
            end
          end

          rl_orig_int = rl;
        end

        // ---------------------------------------------------------
        // SET1 & SET2 (alternate path)
        // ---------------------------------------------------------
        'b11: begin
          if (tck_avg_ns >= 7.518) begin
            if (byte_mode_enable == 0) begin
              rl = 6;
              nwr = 5;
            end else begin
              rl = 6;
              nwr = 5;
            end
          end
          else if (tck_avg_ns >= 3.745 && tck_avg_ns < 7.518) begin
            if (byte_mode_enable == 0) begin
              rl = 8;
              nwr = 10;
            end else begin
              rl = 8;
              nwr = 10;
            end
          end
          else if (tck_avg_ns >= 2.5 && tck_avg_ns < 3.745) begin
            if (byte_mode_enable == 0) begin
              rl = 10;
              nwr = 14;
            end else begin
              rl = 12;
              nwr = 15;
            end
          end
          else if (tck_avg_ns >= 1.876 && tck_avg_ns < 2.5) begin
            if (byte_mode_enable == 0) begin
              rl = 14;
              nwr = 19;
            end else begin
              rl = 14;
              nwr = 20;
            end
          end
          else if (tck_avg_ns >= 1.453 && tck_avg_ns < 1.876) begin
            if (byte_mode_enable == 0) begin
              rl = 16;
              nwr = 24;
            end else begin
              rl = 18;
              nwr = 25;
            end
          end
          else if (tck_avg_ns >= 1.25 && tck_avg_ns < 1.453) begin
            if (byte_mode_enable == 0) begin
              rl = 20;
              nwr = 28;
            end else begin
              rl = 20;
              nwr = 29;
            end
          end
          else begin
            if (byte_mode_enable == 0) begin
              rl = 6;
              nwr = 5;
            end else begin
              rl = 6;
              nwr = 5;
            end
          end

          rl_orig_int = rl;
        end

        default: begin
          if (byte_mode_enable == 0) begin
            rl = 3;
            nwr = 3;
          end else begin
            rl = 3;
            nwr = 3;
          end
          rl_orig_int = rl;
        end

      endcase
    end

  endtask


  ///////////////////////////change_rl_nwr_modifed task/////////////////////////


  task change_rl_nwr_modified (bit ratio,bit dvfsc,int rl,int nwr);
    begin
      automatic bit [3:0] rl_opcode;
      automatic bit [3:0] nwr_opcode;
      automatic real simulation_cycle=tck_avg_ns*1000;
      case (ratio)
        0: begin
          if ((simulation_cycle/1000) >= 14.925) begin
            rl_opcode = 4'b0000;
            nwr_opcode = 4'b0000;
          end
          else if (((simulation_cycle/1000) < 14.925) && ((simulation_cycle/1000) >= 7.518) ) begin
            rl_opcode = 4'b0001;
            nwr_opcode = 4'b0001;
          end
          else if (((simulation_cycle/1000) < 7.518) && ((simulation_cycle/1000) >= 5) ) begin
            rl_opcode = 4'b0010;
            nwr_opcode = 4'b0010;
          end
          else if (((simulation_cycle/1000) < 5) && ((simulation_cycle/1000) >= 3.745) ) begin
            rl_opcode = 4'b0011;
            nwr_opcode = 4'b0011;
          end
          else if (((simulation_cycle/1000) < 3.745) && ((simulation_cycle/1000) >= 2.906) ) begin
            rl_opcode = 4'b0100;
            nwr_opcode = 4'b0100;
          end
          else if (((simulation_cycle/1000) < 2.906) && ((simulation_cycle/1000) >= 2.5) ) begin
            rl_opcode = 4'b0101;
            nwr_opcode = 4'b0101;
          end
          else if (((simulation_cycle/1000) < 2.5) && ((simulation_cycle/1000) >= 2.141) ) begin
            rl_opcode = 4'b0110;
            nwr_opcode = 4'b0110;
          end
          else if (((simulation_cycle/1000) < 2.141) && ((simulation_cycle/1000) >= 1.876) ) begin
            rl_opcode = 4'b0111;
            nwr_opcode = 4'b0111;
          end
          else if (((simulation_cycle/1000) < 1.876) && ((simulation_cycle/1000) >= 1.666) ) begin
            rl_opcode = 4'b1000;
            nwr_opcode = 4'b1000;
          end
          else if (((simulation_cycle/1000) < 1.666) && ((simulation_cycle/1000) >= 1.453) ) begin
            rl_opcode = 4'b1001;
            nwr_opcode = 4'b1001;
          end
          else if (((simulation_cycle/1000) < 1.453) && ((simulation_cycle/1000) >= 1.333) ) begin
            rl_opcode = 4'b1010;
            nwr_opcode = 4'b1010;
          end

          else if (((simulation_cycle/1000) >=1.25) && ((simulation_cycle/1000) <1.333) ) begin
            rl_opcode = 4'b1011;
            nwr_opcode = 4'b1011;
          end



          else begin
            rl_opcode = 4'b1011;
            nwr_opcode = 4'b1011;
          end
        end  
        // end




        1: begin
          if ((simulation_cycle/1000) >= 7.518) begin
            rl_opcode = 4'b0000;
            nwr_opcode = 4'b0000;
          end
          else if (((simulation_cycle/1000) < 7.518) && ((simulation_cycle/1000) >= 3.745) ) begin
            rl_opcode = 4'b0001;
            nwr_opcode = 4'b0001;
          end
          else if (((simulation_cycle/1000) < 3.745) && ((simulation_cycle/1000) >= 2.5) ) begin
            rl_opcode = 4'b0010;
            nwr_opcode = 4'b0010;
          end
          else if (((simulation_cycle/1000) < 2.5) && ((simulation_cycle/1000) >= 1.876) ) begin
            rl_opcode = 4'b0011;
            nwr_opcode = 4'b0011;
          end
          else if (((simulation_cycle/1000) < 1.876) && ((simulation_cycle/1000) >= 1.453) ) begin
            rl_opcode = 4'b0100;
            nwr_opcode = 4'b0100;
          end
          else if (((simulation_cycle/1000) < 1.453) && ((simulation_cycle/1000) >= 1.25) ) begin
            rl_opcode = 4'b0101;
            nwr_opcode = 4'b0101;
          end
          else begin // Need to take default value
            rl_opcode = 4'b0101;
            nwr_opcode = 4'b0101;
          end  
        end
      endcase

      /*  @(negedge SystemClock);
    change_ckr(ratio);
    @(negedge SystemClock);
    mr_write_2 (nwr_opcode,rl_opcode);
    rl_orig_int = rl;*/
    end
  endtask : change_rl_nwr_modified


  //////////////////////////////




endclass
`endif
