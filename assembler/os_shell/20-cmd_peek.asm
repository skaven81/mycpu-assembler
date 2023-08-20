# vim: syntax=asm-mycpu

# Peek at a byte or range of bytes

:cmd_peek

# Get our first argument
LDI_D $user_input_tokens+2      # D points at first argument pointer
LDA_D_AH                        # put high byte of first arg pointer into AH
INCR_D
LDA_D_AL                        # put low byte of first arg pointer into AL
INCR_D
ALUOP_FLAGS %A%+%AH%            # check if null
JZ .usage

LDA_D_AH                        # put second arg pointer into A
INCR_D                          # |
LDA_D_AL                        # |
INCR_D                          # |
ALUOP_FLAGS %A%+%AH%            # check if null
JZ .peek_single_arg

# Handle two-arg form
LDI_A $user_input_tokens+2      # Get pointer to first arg into C
LDA_A_CH                        # |
LDI_A $user_input_tokens+3      # |
LDA_A_CL                        # |
CALL :strtoi                    # Convert to number in A, BL has flags
ALUOP_FLAGS %B%+%BL%
JNZ .abort_bad_start_address
ALUOP_PUSH %A%+%AH%             # store start address on the stack for now
ALUOP_PUSH %A%+%AL%             # |

LDI_A $user_input_tokens+4      # Get pointer to second arg into C
LDA_A_CH                        # |
LDI_A $user_input_tokens+5      # |
LDA_A_CL                        # |
LDA_C_BL                        # Get first char of arg into BL
ALUOP_PUSH %A%+%AL%
LDI_AL '+'
ALUOP_FLAGS %A&B%+%AL%+%BL%     # is first char '+'?
POP_AL
JEQ .get_end_from_range

# second arg is not a range modifier, so just
# process it as a second address
CALL :strtoi                    # Convert to number in A, BL has flags
ALUOP_FLAGS %B%+%BL%
JNZ .abort_bad_end_address
ALUOP_BH %A%+%AH%
ALUOP_BL %A%+%AL%               # Copy end address into B
POP_AL
POP_AH                          # Pop start address into A
JMP .process_range

# second arg is a range modifier
.get_end_from_range
INCR_C                          # move to first char after the +
CALL :strtoi                    # Convert to number in A, BL has flags
ALUOP_FLAGS %B%+%BL%
JNZ .abort_bad_range
ALUOP_BH %A%+%AH%
ALUOP_BL %A%+%AL%               # Copy range into B
POP_AL
POP_AH                          # Pop start address into A
CALL :add16_to_b                # B=B+A -> end address

.process_range
LDA_A_DL                        # Pull byte from addr@A
ALUOP_PUSH %B%+%BL%
ALUOP_PUSH %A%+%AL%
MOV_DL_AL
LDI_BL 0x20
ALUOP_FLAGS %A-B%+%BL%+%AL%
POP_AL
POP_BL
JNO .process_range_normal
PUSH_DL
LDI_DL '.'                      # Substitute '.' for control chars
CALL :heap_push_DL              
POP_DL
CALL :heap_push_DL
JMP .process_range_cont

.process_range_normal
CALL :heap_push_DL              
CALL :heap_push_DL              

.process_range_cont
CALL :heap_push_AL
CALL :heap_push_AH
LDI_C .simple_peek
CALL :printf
CALL :incr16_a
ALUOP_PUSH %B%+%BH%
ALUOP_PUSH %B%+%BL%
CALL :sub16_b_minus_a           # If B-A overflows, we are done
POP_BL
POP_BH
JNO .process_range
RET

# Handle single-arg form
.peek_single_arg
LDI_A $user_input_tokens+2      # Get pointer to first arg into C
LDA_A_CH                        # |
LDI_A $user_input_tokens+3      # |
LDA_A_CL                        # |
CALL :strtoi                    # Convert to number in A, BL has flags
ALUOP_FLAGS %B%+%BL%
JNZ .abort_bad_start_address
LDA_A_BL                        # Grab peek byte into BL
ALUOP_PUSH %A%+%AH%
LDI_AH 0x20
ALUOP_FLAGS %B-A%+%AH%+%BL%     # see if BL contains a control char
POP_AH
JNO .peek_sa_normal
ALUOP_PUSH %B%+%BL%
LDI_BL '.'                      # substitute '.' for control chars
CALL :heap_push_BL
POP_BL
CALL :heap_push_BL
JMP .peek_sa_cont

.peek_sa_normal
CALL :heap_push_BL
CALL :heap_push_BL
.peek_sa_cont
CALL :heap_push_AL
CALL :heap_push_AH
LDI_C .simple_peek
CALL :printf
RET

.abort_bad_start_address
CALL :heap_push_BL
CALL :heap_push_C
LDI_C .bad_start_addr_str
CALL :printf
RET

.abort_bad_end_address
POP_TD                          # the start address was on the stack,
POP_TD                          # so we need to discard it.
CALL :heap_push_BL
CALL :heap_push_C
LDI_C .bad_end_addr_str
CALL :printf
RET

.abort_bad_range
POP_TD                          # the start address was on the stack,
POP_TD                          # so we need to discard it.
CALL :heap_push_BL
DECR_C                          # back to the "+"
CALL :heap_push_C
LDI_C .bad_range_str
CALL :printf
RET


.usage
LDI_C .helpstr
CALL :print
RET

.helpstr "Usage: peek <start-addr> [<end-addr>|+<delta>]\n\0"
.bad_start_addr_str "Error: %s is not a valid start address. strtoi flags: 0x%x\n\0"
.bad_end_addr_str "Error: %s is not a valid end address. strtoi flags: 0x%x\n\0"
.bad_range_str "Error: %s is not a valid range specifier. strtoi flags: 0x%x\n\0"
.simple_peek "0x%x%x: 0x%x (%c)\n\0"
