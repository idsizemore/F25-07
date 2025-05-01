//management_module_top.v

module management_module_top(CLOCK_50, KEY, SW, HEX4, HEX3, HEX2, HEX1, HEX0, LED);
	input        CLOCK_50;
	input  [3:0] KEY;
	input  [9:0] SW;
	output [6:0] HEX4;
	output [6:0] HEX3;
	output [6:0] HEX2;
	output [6:0] HEX1;
	output [6:0] HEX0;
	output [9:0] LED;
	
	wire [31:0] tpm_cc_in;
	wire [15:0] cc_param_in;
	wire [15:0] testsRunIn;
	wire [15:0] testsPassedIn;
	wire [15:0] untestedIn;
	
	wire [2:0] op_stateOut;
	
	wire shutdownSaveOut,
		  platformAuthSelectOut, 
		  platformPolicySelectOut,
		  platformAlgSelectOut,
		  nv_writeLockedSelectOut,
		  nv_writtenSelectOut,
		  nullProofGenEnableOut,
		  nullSeedGenEnableOut,
		  contextArraySelectOut,
		  newContextEncryptionKeyEnableOut,
		  commandAuditDigestSelectOut,
		  commitNonceGenEnableOut,
		  commitArraySelectOut,
		  pcrSaveSelectOut,
		  act_timeoutSelectOut,
		  act_signaledSelectOut,
		  act_authPolicySelectOut,
		  act_hashAlgSelectOut;
		  
	wire [31:0] contextCountOut,
					objectContextIDOut,
					restartCountOut,
					clearCountOut,
					resetCountOut,
					pcrUpdateCountOut,
					commitCountOut;
					
	reg  [3:0] hex4, hex3, hex2, hex1, hex0;
	
	localparam POWER_OFF_STATE = 3'b000, INITIALIZATION_STATE = 3'b001, STARTUP_STATE = 3'b010, OPERATIONAL_STATE = 3'b011, SELF_TEST_STATE = 3'b100, FAILURE_MODE_STATE = 3'b101, SHUTDOWN_STATE = 3'b110;	// Operational states
	
	assign tpm_cc_in = {24'h1, SW[7:0]};
	assign cc_param_in = {15'h0, SW[8]};
	
	assign testsRunIn = 16'd40;
	assign testsPassedIn = (SW[9] == 1'b1)? 16'd40 : 16'd3;
	assign untestedIn = 16'd40;
	assign LED[5] = (op_stateOut == INITIALIZATION_STATE);
	assign LED[6] = (op_stateOut == STARTUP_STATE);
	assign LED[7] = (op_stateOut == OPERATIONAL_STATE);
	assign LED[8] = (op_stateOut == FAILURE_MODE_STATE);
	assign LED[9] = (op_stateOut == SHUTDOWN_STATE);
	
	management_module u1(CLOCK_50, 
		 KEY[0],
		 KEY[1],
		 tpm_cc_in,
		 cc_param_in,
		 1'b0,
		 testsRunIn,
		 testsPassedIn,
		 untestedIn,
		 op_stateOut,
		 LED[4],
		 LED[3],
		 LED[2],
		 LED[1],
		 LED[0],
		 shutdownSaveOut,
		 platformAuthSelectOut, 
		 platformPolicySelectOut,
		 platformAlgSelectOut,
		 nv_writeLockedSelectOut,
		 nv_writtenSelectOut,
		 nullProofGenEnableOut,
		 nullSeedGenEnableOut,
		 contextArraySelectOut,
		 contextCountOut,
		 commandAuditDigestSelectOut,
		 objectContextIDOut,
		 newContextEncryptionKeyEnableOut,
		 restartCountOut,
		 clearCountOut,
		 resetCountOut,
		 pcrUpdateCountOut,
		 commitCountOut,
		 commitNonceGenEnableOut,
		 commitArraySelectOut,
		 pcrSaveSelectOut,
		 act_timeoutSelectOut,
		 act_signaledSelectOut,
		 act_authPolicySelectOut,
		 act_hashAlgSelectOut);
		 
	sevensegdecoder_proc_emmaw21 u2(hex4, HEX4);
	sevensegdecoder_proc_emmaw21 u3(hex3, HEX3);
	sevensegdecoder_proc_emmaw21 u4(hex2, HEX2);
	sevensegdecoder_proc_emmaw21 u5(hex1, HEX1);
	sevensegdecoder_proc_emmaw21 u6(hex0, HEX0);
	
	always@(op_stateOut) begin
		case(op_stateOut)
			POWER_OFF_STATE: 		 {hex4, hex3, hex2, hex1, hex0} = 20'h20FF5;
			INITIALIZATION_STATE: {hex4, hex3, hex2, hex1, hex0} = 20'h17195;
			STARTUP_STATE: 		 {hex4, hex3, hex2, hex1, hex0} = 20'h59A89;
			OPERATIONAL_STATE: 	 {hex4, hex3, hex2, hex1, hex0} = 20'h02E89;
			SELF_TEST_STATE: 		 {hex4, hex3, hex2, hex1, hex0} = 20'h5E6F9;
			FAILURE_MODE_STATE: 	 {hex4, hex3, hex2, hex1, hex0} = 20'hFA165;
			SHUTDOWN_STATE:		 {hex4, hex3, hex2, hex1, hex0} = 20'h53495;
			default:		 			 {hex4, hex3, hex2, hex1, hex0} = 20'h00000;
		endcase
	end
		 
endmodule

/*module management_module_top(CLOCK_50, KEY, SW, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LED);
	input        CLOCK_50;
	input  [3:0] KEY;
	input  [9:0] SW;
	output [6:0] HEX5;
	output [6:0] HEX4;
	output [6:0] HEX3;
	output [6:0] HEX2;
	output [6:0] HEX1;
	output [6:0] HEX0;
	output [9:0] LED;
	
	localparam OP_STATE = 9'd1, STARTUP = 9'd2, SELF_TEST = 9'd3, ENABLES = 9'd4, SELECTBITS = 9'd5, RESTART_COUNT = 9'd5, CLEAR_COUNT = 9'd5, RESET_COUNT = 9'd6;
	
	always@(SW) begin
		case(SW)
			OP_STATE:
			STARTUP:
			SELF_TEST:
			ENABLES:
			SELECTBITS:
			RESTART_COUNT:
			CLEAR_COUNT:
			RESET_COUNT:
			default:
		endcase
	end
endmodule
*/
