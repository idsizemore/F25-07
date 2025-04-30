// management_module.v

module management_module(		 
		 clock, 
		 reset_n,
		 tpm_cc,
		 cmd_param,
		 orderlyInput,
		 restoreSuccessful,
		 testsRun,
		 testsPassed,
		 untested,
		 op_state,
		 phEnable,
		 phEnableNV,
		 shEnable,
		 ehEnable,
		 s_initialized,
		 shutdownSave,
		 platformAuthSelect, 
		 platformPolicySelect,
		 platformAlgSelect,
		 nv_writeLockedSelect,
		 nv_writtenSelect,
		 nullProofGenEnable,
		 nullSeedGenEnable,
		 contextArraySelect,
		 contextCount,
		 commandAuditDigestSelect,
		 objectContextID_state,
		 newContextEncryptionKeyEnable,
		 restartCount,
		 clearCount,
		 resetCount,
		 pcrUpdateCount,
		 commitCount,
		 commitNonceGenEnable,
		 commitArraySelect,
		 pcrSaveSelect,
		 act_timeoutSelect,
		 act_signaledSelect,
		 act_authPolicySelect,
		 act_hashAlgSelect,
		 shutdownState
		 );
		 
	input 		  clock;						// Input clock signal
	input 		  reset_n;						// Input reset signal
	input  [31:0] tpm_cc;					// 32-bit input command
	input  [15:0] cmd_param;				// 16-bit input command parameters
	input			  orderlyInput;
	input         restoreSuccessful;
	input	 [15:0] testsRun;
	input	 [15:0] testsPassed;
	input	 [15:0] untested;
	output [2:0]  op_state;
	output 		  phEnable;					// 1-bit output platform hierarchy enable
	output 		  phEnableNV;				// 1-bit output platform hiearchy NV memory enable
	output 		  shEnable;					// 1-bit output owner hierarchy enable
	output 		  ehEnable;					// 1-bit output privacy administrator hierarchy enable
	output 		  s_initialized;			// 1-bit output intialized bit
	output        shutdownSave;			// 1-bit output shutdownType
	output		  platformAuthSelect;
	output		  platformPolicySelect;
	output		  platformAlgSelect;
	output	 	  nv_writeLockedSelect;
	output	     nv_writtenSelect;
	output		  nullProofGenEnable;
	output		  nullSeedGenEnable;
	output	 	  contextArraySelect;
	output [31:0] contextCount;
	output		  commandAuditDigestSelect;
	output [31:0] objectContextID_state;
	output	     newContextEncryptionKeyEnable;
	output [31:0] restartCount;
	output [31:0] clearCount;
	output [31:0] resetCount;
	output [31:0] pcrUpdateCount;
	output [31:0] commitCount;
	output		  commitNonceGenEnable;
	output		  commitArraySelect;
	output [1:0]  pcrSaveSelect;
	output		  act_timeoutSelect;
	output	 	  act_signaledSelect;
	output	     act_authPolicySelect;
	output	     act_hashAlgSelect;
	output 		  shutdownState;
	
	
	// Command Codes
	localparam TPM_CC_CHANGEEPS 		     = 32'h00000124,
				  TPM_CC_CHANGEPPS 			  = 32'h00000125,
				  TPM_CC_CLEAR 				  = 32'h00000126,
				  TPM_CC_INCREMENTALSELFTEST = 32'h00000142,
				  TPM_CC_SELFTEST 			  = 32'h00000143,
				  TPM_CC_STARTUP 				  = 32'h00000144, 
				  TPM_CC_SHUTDOWN 		     = 32'h00000145,
				  TPM_CC_GETTESTRESULT 		  = 32'h0000017C,
				  TPM_CC_GETCAPABILITY 		  = 32'h0000017A;
	
	localparam TPM_SU_CLEAR = 1'b0, TPM_SU_STATE = 1'b1; // startupType
	
	localparam CLEAR = 1'b0, SET = 1'b1;
	localparam PRESERVED = 1'b1, DEFAULT = 1'b0;
	localparam FULL_DEFAULT = 2'd0, PS_PRESERVED = 2'd1, FULL_PRESERVED = 2'd2;
	localparam TPMI_YES = 1'b1;
	
	localparam TPM_DONE = 2'd0, TPM_RESET = 2'd1, TPM_RESTART = 2'd2, TPM_RESUME = 2'd3;
	
	localparam POWER_OFF_STATE = 3'b000, INITIALIZATION_STATE = 3'b001, STARTUP_STATE = 3'b010, OPERATIONAL_STATE = 3'b011, SELF_TEST_STATE = 3'b100, FAILURE_MODE_STATE = 3'b101, SHUTDOWN_STATE = 3'b110;	// Operational states
	
	reg orderly, shutdownState, pHierarchy, nvEnable, sHierarchy, eHierarchy, orderlyState, shutdownSave;
	reg phEnable, phEnableNV, shEnable, ehEnable, s_initialized;
	reg platformAuthSelect, 
		 platformPolicySelect,
		 platformAlgSelect,
		 nv_writeLockedSelect,
		 nv_writtenSelect,
		 nullProofGenEnable,
		 nullSeedGenEnable,
		 contextArraySelect,
		 commandAuditDigestSelect,
		 newContextEncryptionKeyEnable,
		 commitNonceGenEnable,
		 commitArraySelect,
		 act_timeoutSelect,
		 act_signaledSelect,
		 act_authPolicySelect,
		 act_hashAlgSelect,
		 initialized;
		 
	reg [1:0] startup_state, startup_sequence, pcrSaveSelect;
	reg [2:0] op_state, state;
	reg [31:0] objectContextID, contextCount, restartCount, clearCount, resetCount, pcrUpdateCount, commitCount;
	reg [31:0] objectContextID_state, contextCount_state, restartCount_state, clearCount_state, resetCount_state, pcrUpdateCount_state, commitCount_state;
	
	wire startupEnable;
	
	always@(posedge clock or negedge reset_n) begin
		if(!reset_n) begin
			phEnable     <= 1'b0;
			phEnableNV   <= 1'b0;
			shEnable   	 <= 1'b0;
			ehEnable   	 <= 1'b0;
			orderly		 <= orderlyInput;
			op_state     <= POWER_OFF_STATE;
			startup_sequence <= 2'd0;
			contextCount  <= 32'd0;
			objectContextID <= 32'd0;
			restartCount   <= 32'd0;
			clearCount    <= 32'd0;
			resetCount     <= 32'd0;
			pcrUpdateCount <= 32'd0;
			commitCount    <= 32'd0;
			s_initialized  <= 1'b0;
			shutdownSave <= 1'b0;
		end
		else begin
			phEnable     <= pHierarchy;
			phEnableNV   <= nvEnable;
			shEnable     <= sHierarchy;
			ehEnable     <= eHierarchy;
			orderly		 <= orderlyState;
			op_state     <= state;
			if(startupEnable) begin
				startup_sequence <= startup_state;
				contextCount  <= contextCount_state;
				objectContextID <= objectContextID_state;
				restartCount  <= restartCount_state;
				clearCount    <= clearCount_state;
				resetCount    <= resetCount_state;
				pcrUpdateCount <= pcrUpdateCount_state;
				commitCount    <= commitCount_state;
				s_initialized <= initialized;
			end
			shutdownSave <= shutdownState;
		end
	end

	assign startupEnable = (state == STARTUP_STATE);
	
	always@(startup_sequence, shutdownSave, tpm_cc, op_state, phEnable, shEnable, ehEnable, cmd_param, orderly, restoreSuccessful, untested, testsPassed, testsRun) begin
		pHierarchy = phEnable;
		orderlyState = orderly;
		startup_state = startup_sequence;
		shutdownState = shutdownSave;
		case(op_state)
			POWER_OFF_STATE: 		 begin
											 state = INITIALIZATION_STATE;
										 end
			INITIALIZATION_STATE: begin
										    if(tpm_cc == TPM_CC_STARTUP) begin
											 	 state = STARTUP_STATE;
											 end
									 		 else begin
												 state = INITIALIZATION_STATE;
											 end
										 end
			STARTUP_STATE:			 begin
											 pHierarchy = 1'b1;
											 // Flush all transient contexts (objects, sessions, and sequences)
											 // if(lockoutRecovery == 0): lockoutAuth = 1'b1;
											 
											 if(orderly == TPM_SU_STATE) begin
												 // Restore saved state
												 if(cmd_param[0] == TPM_SU_CLEAR) begin
													 startup_state = TPM_RESTART;	// TPM Restart
													 state = OPERATIONAL_STATE;
												 end
												 else begin
													 if(restoreSuccessful) begin
														 startup_state = TPM_RESUME;	// TPM Resume
														 state = OPERATIONAL_STATE;
													 end
													 else begin
														 state = FAILURE_MODE_STATE;
													 end
												 end
											 end
											 else begin
												 if(cmd_param[0] == TPM_SU_STATE) begin
													 state = INITIALIZATION_STATE;
												 end
												 else begin
													 startup_state = TPM_RESET;	// TPM Reset
													 state = OPERATIONAL_STATE;
												 end
											 end
										 end
			OPERATIONAL_STATE: 	 begin
											if(tpm_cc == TPM_CC_SELFTEST || tpm_cc == TPM_CC_INCREMENTALSELFTEST) begin
												 state = SELF_TEST_STATE;
											end
											else if(tpm_cc == TPM_CC_SHUTDOWN) begin
												 state = SHUTDOWN_STATE;
											end
											else begin
												 // Process command
												 state = OPERATIONAL_STATE;
											end
										 end
			SELF_TEST_STATE:		 begin
											 if(testsPassed == testsRun) begin
												if(cmd_param[0] == TPMI_YES) begin
													if(testsPassed == 16'd40) begin
														state = OPERATIONAL_STATE;
													end
													else begin
														state = SELF_TEST_STATE;
													end
												end
												else begin
													if(untested == 16'd0) begin
														state = OPERATIONAL_STATE;
													end
													else begin
														state = SELF_TEST_STATE;
													end
												end
											 end
											 else begin
												 state = FAILURE_MODE_STATE;
											 end
										 end
			FAILURE_MODE_STATE:	 begin
											 if(tpm_cc == TPM_CC_GETTESTRESULT) begin
												 // return test results
												 state = FAILURE_MODE_STATE;
											 end
											 else if(tpm_cc == TPM_CC_GETCAPABILITY) begin
												 // return capability
												 state = FAILURE_MODE_STATE;
											 end
											 else begin
												 state = FAILURE_MODE_STATE;
											 end
										 end
			SHUTDOWN_STATE:		 begin
											 // save volatile portion of clock to NV memory
											 orderlyState = 1'b1;	// set shutdown as orderly
											 // NV indexes with the TPMA_NV_ORDERLY attribute will be updated
											 if(cmd_param[0] == TPM_SU_STATE) begin
												 // save tracking info for saved session contexts to NV memory
												 // save contextCounter to NV
												 // save savePCR to NV
												 // save pcrUpdateCounter to NV
												 // save TPMA_NV_WRITESTCLEAR
												 // save TPMA_NV_READSTCLEAR
												 // For each ACT:
													// save counter value to NV
													// save authPolicy to NV
												 // save commandAuditDigest and count
												 shutdownState = TPM_SU_STATE;		// set shutdown as orderly
												 state = OPERATIONAL_STATE;
											 end
											 else begin
												shutdownState = TPM_SU_CLEAR;
												state = OPERATIONAL_STATE;
											 end
										 end
			default:					 begin
											 state = 3'bxxx;
										 end
		endcase
	end
	
	always@(startup_sequence, resetCount, restartCount, clearCount, contextCount, objectContextID, pcrUpdateCount, commitCount, phEnableNV, shEnable, ehEnable, s_initialized) begin
		if(startup_sequence == TPM_RESET) begin
			restartCount_state = 32'd0;
			clearCount_state = 32'd0;
			resetCount_state = resetCount + 1'b1;
			
			nvEnable = 1'b1;
			sHierarchy = 1'b1;
			eHierarchy = 1'b1;
			
			platformAuthSelect = DEFAULT; // platformAuth set to empty buffer
			platformPolicySelect = DEFAULT;// platformPolicy set to empty buffer
			platformAlgSelect = DEFAULT;
													 
			// For each NV index: 
			nv_writeLockedSelect = DEFAULT;	// if((TPMA_NV_WRITEDEFINE == CLEAR)||(TPMA_NV_WRITTEN == CLEAR)): TPMA_NV_WRITELOCKED = CLEAR;
			// if(TPMA_NV_ORDERLY == SET): TPMA_NV_WRITTEN = CLEAR (unless the type is TPM_NT_COUNTER)
			nv_writtenSelect = DEFAULT;
			// else: advance the orderly counters;
			// if(TPMA_NV_CLEAR_STCLEAR == SET): TPMA_NV_WRITTEN = CLEAR;
			
			nullProofGenEnable = SET;
			nullSeedGenEnable = SET;
													 
			contextArraySelect = DEFAULT;	//(set saved session contexts to initial value)
			contextCount_state = DEFAULT;
			
			commandAuditDigestSelect = DEFAULT;
			
			objectContextID_state = DEFAULT;	// objectContextID = 0;
			newContextEncryptionKeyEnable = SET;	// Generate new context encryption key;
			
			pcrUpdateCount_state = DEFAULT;
			commitCount_state = DEFAULT;
			commitNonceGenEnable = SET;
			commitArraySelect = DEFAULT;
																			 
			pcrSaveSelect = FULL_DEFAULT;	// pcrSave set to zero digest (default, which can change based on platform specifications);
													 
			// For each ACT: 
			act_timeoutSelect = DEFAULT;		// timeout = 0, 
			act_signaledSelect = DEFAULT;	// if(preserveSignaled == CLEAR): signaled = CLEAR,
			act_authPolicySelect = DEFAULT;	// authPolicy set to empty buffer,
			act_hashAlgSelect = DEFAULT;		// hashAlg = TPM_ALG_NULL;
													 
			initialized = 1'b1;
		end
		else if(startup_sequence == TPM_RESTART) begin
			restartCount_state = restartCount + 1'b1;
			clearCount_state = clearCount + 1'b1;
			resetCount_state = resetCount;
			
			nvEnable = 1'b1;
			sHierarchy = 1'b1;
			eHierarchy = 1'b1;
			
			platformAuthSelect = DEFAULT; // platformAuth set to empty buffer
			platformPolicySelect = DEFAULT;// platformPolicy set to empty buffer
			platformAlgSelect = DEFAULT;
													 
			// For each NV index: 
			nv_writeLockedSelect = DEFAULT;	// if((TPMA_NV_WRITEDEFINE == CLEAR)||(TPMA_NV_WRITTEN == CLEAR)): TPMA_NV_WRITELOCKED = CLEAR;
			nv_writtenSelect = DEFAULT;	// if(TPMA_NV_CLEAR_STCLEAR == SET): TPMA_NV_WRITTEN = CLEAR;
													 
			// Reset PCR in all banks to default initial conditions
			pcrSaveSelect = FULL_DEFAULT;
			
			nullProofGenEnable = CLEAR;
			nullSeedGenEnable = CLEAR;
			
			contextArraySelect = PRESERVED;
			contextCount_state = contextCount;
			
			commandAuditDigestSelect = PRESERVED;
			
			objectContextID_state = objectContextID;
			newContextEncryptionKeyEnable = CLEAR;
			
			pcrUpdateCount_state = pcrUpdateCount;
			
			commitCount_state = commitCount;
			commitNonceGenEnable = CLEAR;
			commitArraySelect = PRESERVED;
													 
			// For each ACT: 
			act_timeoutSelect = DEFAULT;		// timeout = 0, 
			act_signaledSelect = DEFAULT;	// if(preserveSignaled == CLEAR): signaled = CLEAR,
			act_authPolicySelect = DEFAULT;	// authPolicy set to empty buffer,
			act_hashAlgSelect = DEFAULT;		// hashAlg = TPM_ALG_NULL;
													 
			initialized = 1'b1;
		end
		else if(startup_sequence == TPM_RESUME) begin
			restartCount_state = restartCount + 1'b1;
			clearCount_state = clearCount;
			resetCount_state = resetCount;
			
			nvEnable = phEnableNV;
			sHierarchy = shEnable;
			eHierarchy = ehEnable;
			
			platformAuthSelect = PRESERVED;
			platformPolicySelect = PRESERVED;
			platformAlgSelect = PRESERVED;
			
			nv_writeLockedSelect = PRESERVED;
			nv_writtenSelect = PRESERVED;
			
			pcrSaveSelect = PS_PRESERVED;
			
			nullProofGenEnable = CLEAR;
			nullSeedGenEnable = CLEAR;
			
			contextArraySelect = PRESERVED;
			contextCount_state = contextCount;
			
			commandAuditDigestSelect = PRESERVED;
			
			objectContextID_state = objectContextID;
			newContextEncryptionKeyEnable = CLEAR;
			
			pcrUpdateCount_state = pcrUpdateCount;
			
			commitCount_state = commitCount;
			commitNonceGenEnable = CLEAR;
			commitArraySelect = PRESERVED;
														 
			// For each ACT: timeout, singaled, and authPolicy values preserved;
			act_timeoutSelect = PRESERVED;
			act_signaledSelect = PRESERVED;
			act_authPolicySelect = PRESERVED;
														 
			initialized = 1'b1;
		end
		else begin
			restartCount_state = restartCount;
			clearCount_state = clearCount;
			resetCount_state = resetCount;
			
			nvEnable = phEnableNV;
			sHierarchy = shEnable;
			eHierarchy = ehEnable;
			
			platformAuthSelect = PRESERVED;
			platformPolicySelect = PRESERVED;
			platformAlgSelect = PRESERVED;
			
			nv_writeLockedSelect = PRESERVED;
			nv_writtenSelect = PRESERVED;
			
			pcrSaveSelect = FULL_PRESERVED;
			
			nullProofGenEnable = CLEAR;
			nullSeedGenEnable = CLEAR;
			
			contextArraySelect = PRESERVED;
			contextCount_state = contextCount;
			
			commandAuditDigestSelect = PRESERVED;
			
			objectContextID_state = objectContextID;
			newContextEncryptionKeyEnable = CLEAR;
			
			pcrUpdateCount_state = pcrUpdateCount;
			
			commitCount_state = commitCount;
			commitNonceGenEnable = CLEAR;
			commitArraySelect = PRESERVED;
														 
			// For each ACT: timeout, singaled, and authPolicy values preserved;
			act_timeoutSelect = PRESERVED;
			act_signaledSelect = PRESERVED;
			act_authPolicySelect = PRESERVED;
														 
			initialized = s_initialized;
		end
	end
	
endmodule
