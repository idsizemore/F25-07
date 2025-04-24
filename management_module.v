// management_module.v

module management_module(clock, reset, _tpm_init, nv_mode, cmd_code, cmd_param, phEnable, shEnable, ehEnable, s_initialized, saved_mode, responseCode);
	input clock;
	input reset;
	input _tpm_init;       // _TPM_Init signal
	input [1:0] nv_mode;
	input [29:0] cmd_code;
	input cmd_param;
	output phEnable;
	output shEnable;
	output ehEnable;
	output s_initialized;
	output [1:0] saved_mode;
	output [3:0] responseCode;
	
	localparam TPM_RC_INITIALIZE = 4'b0001, TPM_RC_VALUE = 4'b0010, TPM_RC_SUCCESS = 4'b1111, TPM_RC_FAILURE = 4'b0000;	// returnCode Codes
	localparam TPM2_STARTUP = 30'd0, TPM2_SHUTDOWN = 30'd1, TPM2_SELFTEST = 30'd2, TPM2_INCREMENTALSELFTEST = 30'd3, TPM2_GETTESTRESULT = 30'd4, TPM2_GETCAPABILITY = 30'd5;	// Command codes
	localparam TPM_SU_CLEAR = 1'b0, TPM_SU_STATE = 1'b1; // startupType
	localparam FAILURE_MODE = 2'd0, OPERATIONAL_MODE = 2'd1, SELF_TEST_MODE = 2'd3;	// Operational modes
	localparam POWER_OFF_STATE = 3'b000, INITIALIZATION_STATE = 3'b001, STARTUP_STATE = 3'b010, OPERATIONAL_STATE = 3'b011, SELF_TEST_STATE = 3'b100, FAILURE_MODE_STATE = 3'b101, SHUTDOWN_STATE = 3'b110;	// Operational states
	
	reg power_loss, orderly, shutdownType, pHierarchy, sHierarchy, eHierarchy, restoreSuccessful, untested, test_successful;
	reg phEnable, shEnable, ehEnable, s_initialized;
	reg [3:0] responseCode, returnCode;
	reg [2:0] op_state, state;
	reg [1:0] saved_mode;
	
	always@(posedge clock or negedge reset) begin
		if(reset) begin
			power_loss <= 1'b1;
			phEnable <= 1'b0;
			shEnable <= 1'b0;
			ehEnable <= 1'b0;
			op_state <= POWER_OFF_STATE;
			responseCode <= TPM_RC_SUCCESS;
		end
		else if(_tpm_init) begin
			phEnable <= 1'b1;
			shEnable <= sHierarchy;
			ehEnable <= eHierarchy;
			if(nv_mode == SELF_TEST_MODE) begin
				op_state <= SELF_TEST_STATE;
			end
			else begin
				op_state <= INITIALIZATION_STATE;
			end
		end
		else begin
			phEnable <= pHierarchy;
			shEnable <= sHierarchy;
			ehEnable <= eHierarchy;
			op_state <= state;
			responseCode <= returnCode;
		end
	end
	
	always@(cmd_code, op_state, phEnable, shEnable, ehEnable, cmd_param, orderly, shutdownType, restoreSuccessful, untested, test_successful) begin
		pHierarchy = phEnable;
		sHierarchy = shEnable;
		eHierarchy = ehEnable;
		saved_mode = OPERATIONAL_MODE;
		case(op_state)
			POWER_OFF_STATE: 		 begin
											 state = POWER_OFF_STATE;	 
										 end
			INITIALIZATION_STATE: begin
										    if(cmd_code == TPM2_STARTUP) begin
												 s_initialized = 1'b0;
												 if(!orderly) begin
													 shutdownType = TPM_SU_CLEAR;
												 end
											 	 state = STARTUP_STATE;
											 end
									 		 else begin
												 s_initialized = 1'b0;
												 returnCode = TPM_RC_INITIALIZE;
												 state = INITIALIZATION_STATE;
											 end
										 end
			STARTUP_STATE:			 begin
											 if(shutdownType == TPM_SU_STATE) begin
												 // Restore saved state
												 if(cmd_param == TPM_SU_CLEAR) begin
													 // Set PCR to default initialization state
													 // TPM Restart
													 // On TPM Resart platformAuth is set to an EmptyAuth, and platformPolicy is set to an EpmtyPolicy
													 sHierarchy = 1'b1;
													 eHierarchy = 1'b1;
													 s_initialized = 1'b1;
													 returnCode = TPM_RC_SUCCESS;
													 state = OPERATIONAL_STATE;
												 end
												 else begin
													 if(restoreSuccessful) begin
														 // TPM Resume
														 s_initialized = 1'b1;
														 returnCode = TPM_RC_SUCCESS;
														 state = OPERATIONAL_STATE;
													 end
													 else begin
														 s_initialized = 1'b0;
														 returnCode = TPM_RC_FAILURE;
														 state = FAILURE_MODE_STATE;
													 end
												 end
											 end
											 else begin
												 if(cmd_param == TPM_SU_STATE) begin
													 returnCode = TPM_RC_VALUE;
													 state = INITIALIZATION_STATE;
												 end
												 else begin
													 // Set default state
													 // TPM Reset
													 sHierarchy = 1'b1;
													 eHierarchy = 1'b1;
													 s_initialized = 1'b1;
													 returnCode = TPM_RC_SUCCESS;
													 state = OPERATIONAL_STATE;
												 end
											 end
										 end
			OPERATIONAL_STATE: 	 begin
											if(cmd_code == TPM2_SELFTEST || cmd_code == TPM2_INCREMENTALSELFTEST) begin
												 state = SELF_TEST_STATE;
											 end
											 else if(cmd_code == TPM2_SHUTDOWN) begin
												 state = SHUTDOWN_STATE;
											 end
											 else begin
												 // Process command
												 returnCode = TPM_RC_SUCCESS;
												 state = OPERATIONAL_STATE;
											 end
										 end
			SELF_TEST_STATE:		 begin
											 saved_mode = SELF_TEST_MODE;
											 if(untested) begin
												 // Test required functions
												 if(test_successful) begin
													 returnCode = TPM_RC_SUCCESS;
													 state = OPERATIONAL_STATE;
												 end
												 else begin
													 returnCode = TPM_RC_FAILURE;
													 state = FAILURE_MODE_STATE;
												 end
											 end
											 else begin
												 state = OPERATIONAL_STATE;
											 end
										 end
			FAILURE_MODE_STATE:	 begin
											 if(cmd_code == TPM2_GETTESTRESULT) begin
												 // return test results
												 state = FAILURE_MODE_STATE;
											 end
											 else if(cmd_code == TPM2_GETCAPABILITY) begin
												 // return capability
												 state = FAILURE_MODE_STATE;
											 end
											 else begin
												 returnCode = TPM_RC_FAILURE;
												 state = FAILURE_MODE_STATE;
											 end
										 end
			SHUTDOWN_STATE:		 begin
											 if(cmd_param == TPM_SU_STATE) begin
												 // Preserves majority of TPM operational state data in NV memory, to be restored in startup
												 returnCode = TPM_RC_SUCCESS;
												 state = POWER_OFF_STATE;
											 end
											 else begin
												 // Preserve a minimal amount of TPM operational state in NV memory, enough to preserve TPM timing functions
												 returnCode = TPM_RC_SUCCESS;
												 state = POWER_OFF_STATE;
											 end
										 end
			default:					 begin
											 state = 3'bxxx;
										 end
		endcase
	end
	
endmodule