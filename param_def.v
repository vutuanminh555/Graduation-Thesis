// constant
`define MAX_CODE_RATE           3
`define MAX_CONSTRAINT_LENGTH   9
`define MAX_STATE_NUM           256 // = 2 ^ (MAX_CONSTRAINT_LENGTH - 1), must be hardcoded         
`define RADIX                   4 // transition per state

// derivative
`define MAX_SHIFT_REG_NUM       `MAX_CONSTRAINT_LENGTH-1 
`define DECODE_BIT_NUM          `RADIX/2
`define TRACEBACK_DEPTH         5*`MAX_SHIFT_REG_NUM*`MAX_CODE_RATE/2 // equal 5*(K-1)*code rate with radix-2 and half of that with radix-4
`define DATA_FRAME_LENGTH       `TRACEBACK_DEPTH/`MAX_CODE_RATE
`define MAX_TRANSITION_NUM      `RADIX*`MAX_STATE_NUM       



