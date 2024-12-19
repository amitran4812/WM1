\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   
   // ########################################################
   // #                                                      #
   // #  Empty template for Tiny Tapeout Makerchip Projects  #
   // #                                                      #
   // ########################################################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   var(my_design, tt_um_example)   /// The name of your top-level TT module, to match your info.yml.
   var(target, ASIC)   /// Note, the FPGA CI flow will set this to FPGA.
   //-------------------------------------------------------
   
   var(in_fpga, 1)   /// 1 to include the demo board. (Note: Logic will be under /fpga_pins/fpga.)
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_if_defined_as(MAKERCHIP, 1, 0, 1): Debounce unless in Makerchip.
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_defined_as(MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/5744600215af09224b7235479be84c30c6e50cb7/tlv_lib/tiny_tapeout_lib.tlv'])


\TLV my_design()
   
   
   
   // ==================
   // |                |
   // | YOUR CODE HERE |
   // |                |
   // ==================
   
   // Note that pipesignals assigned here can be found under /fpga_pins/fpga.
   
   
   
   
   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   //*uo_out = 8'b0;
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])

// Set up the Tiny Tapeout lab environment.
\TLV tt_lab()
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , my_design)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0] uio_in, uio_out, uio_oe;'])
   logic [31:0] r;  // a random value
   always @(posedge clk) r <= m5_if_defined_as(MAKERCHIP, 1, ['$urandom()'], ['0']);
   assign ui_in = r[7:0];
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   /*
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         ui_in = 8'h0;
      #10 // Step 5 cycles, past reset.
         ui_in = 8'hFF;
      // ...etc.
   end
   */

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   assign passed = top.cyc_cnt > 80;
   assign failed = 1'b0;
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
\SV
	module washingMachine (pour, spin, drain, heat, s, temp_hot, h, c_full, c_emp, clk, reset, stop);
   output reg pour, spin, drain, heat;
   input s, temp_hot, h, c_full, c_emp, clk, reset, stop;
   parameter [2:0] Init = 3'b000, Wait = 3'b001, Heat = 3'b010, Pour = 3'b011, Spin = 3'b100, Drain = 3'b101, Pause = 3'b110;
   reg [43:0] count;
   reg [2:0] currentState, nextState;
   reg [1:0] a;
   reg t;
 /*  always@(posedge clk) 
      begin
         if(reset)                     //Set Counter to Zero
            count <= 0;
         else if(a == 2'b01 && currentState == Spin )            //load the counter with data value
            count <= 44'd1800000000000;                           //wash
         else if(a == 2'b10  && currentState == Spin )
            count <= 44'd900000000000;                            //rinse 
         else if(a == 2'b11 && currentState == Spin )
            count <= 44'd300000000000;                            //spin
         else                                                    //count down
            count <= count - 1;
         	if(count == 44'b0 && !reset)
            	t <= 1'b1;
         	else
            	t <= 1'b0; */
   always @(posedge clk)
   //always@(currentState)
      begin
         if (stop)
            currentState <= Init;
         else
         	currentState <= nextState;
      end   
   always@(currentState, s, h, c_full, c_emp)
      begin 
         case (currentState)
         Init: nextState = Wait;
         Wait:
            begin
               if (s)
                  begin
                  if (temp_hot)
                     nextState = Heat;
                  else
                     nextState = Pour;
                  end
               else 
                  nextState = Wait;	
            end
         Heat: 
            begin 
               if (h)
                  nextState = Pour;
               else
                  nextState = Heat;
            end
         Pour:
            begin
               if (c_full)
                  nextState = Spin;
               else
                  nextState = Pour;
            end
         Spin:
            begin
               if (t)
                  nextState = Drain;
               else 
                  nextState = Spin;
            end
         Drain:
            begin
               if (c_emp)
                  begin 
                     case(a)
                        2'b01: nextState = Pour;
                        2'b10: nextState = Spin;
                        default: nextState = Init;
                     endcase
                  end
               else 
                  nextState = Drain;
            end
         default: nextState = Init;
         endcase
      end
   always_ff @(posedge clk)
      begin
         case(currentState)
            Init: 
               begin
                  a<=0;
                  heat<=0;
                  pour<=0;
                  spin<=0;
                  drain<=0;
               end
            Heat: 
               begin
                  heat<=1;
                  pour<=0;
                  spin<=0;
                  drain<=0;
               end
            Pour: 
               begin
                  pour<=1;
                  heat<=0;
                  spin<=0;
                  drain<=0;
               end
            Spin: 
               begin
                  spin<=1;
                  a<=a+1;
                  heat<=0;
                  pour<=0;
                  drain<=0;
                  if(reset)                     //Set Counter to Zero
            			count <= 0;
         			else if(a == 2'b01)            //load the counter with data value
                     count <= 44'd1800000000000;                   //wash
                  else if(a == 2'b10)
                     count <= 44'd900000000000;                            //rinse 
                  else if(a == 2'b11)
                     count <= 44'd300000000000;                            //spin
                  else                                                    //count down
                     count <= count - 1;
                  
                  if(count == 44'b0 && !reset)
                     t <= 1'b1;
                  else
                     t <= 1'b0;
               end
            Drain: 
               begin
                  drain<=1;
                  heat<=0;
                  pour<=0;
                  spin<=0;
               end
            default: a<=0;
         endcase
      end
   endmodule


// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   wire reset = ! rst_n;

   // List all potentially-unused inputs to prevent warnings
   wire _unused = &{ena, clk, rst_n, 1'b0};

\TLV
   /* verilator lint_off UNOPTFLAT */
   m5_if(m5_in_fpga, ['m5+tt_lab()'], ['m5+my_design()'])

\SV_plus
   
   // ==========================================
   // If you are using Verilog for your design,
   // your Verilog logic goes here.
   // Note, output assignments are in my_design.
   // ==========================================
	reg pour, spin, drain, heat;
   wire s = ui_in[0], temp_hot = ui_in[1], h = ui_in[2], c_full = ui_in[3], c_emp = ui_in[4], stop = ui_in[5];
   //wire heat = uo_out[0], pour = uo_out[1], spin = uo_out[2], drain = uo_out[3];
   assign uo_out = {4'b0, heat, pour, spin, drain}; 
   washingMachine washingMachine(.*);
   
endmodule


	
