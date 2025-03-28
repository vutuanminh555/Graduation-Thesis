`ifndef PARAM_DEF_H
`define PARAM_DEF_H

// constant
`define ENCODE_MODE             1'b0
`define DECODE_MODE             1'b1

`define MAX_CODE_RATE           3
`define MAX_CONSTRAINT_LENGTH   9
`define MAX_STATE_NUM           256 // = 2 ^ (MAX_CONSTRAINT_LENGTH - 1), must be hardcoded         
`define RADIX                   4 // transition per state


// derivative
`define MAX_STATE_REG_NUM       `MAX_CONSTRAINT_LENGTH-1 
`define DECODE_BIT_NUM          `RADIX/2 // = log2(`RADIX)
`define TRACEBACK_DEPTH         5*`MAX_SHIFT_REG_NUM*`MAX_CODE_RATE/2 // equal 5*(K-1)*code rate with radix-2 and half of that with radix-4
`define DATA_FRAME_LENGTH       `TRACEBACK_DEPTH/`MAX_CODE_RATE
`define MAX_TRANSITION_NUM      `RADIX*`MAX_STATE_NUM       

// select constraint length 
`define CONSTR_LEN_5            2'b00
`define CONSTR_LEN_7            2'b01
`define CONSTR_LEN_9            2'b10

// select code rate
`define CODE_RATE_2             1'b0 // 1/2
`define CODE_RATE_3             1'b1 // 1/3

`endif
