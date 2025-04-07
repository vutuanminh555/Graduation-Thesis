`ifndef PARAM_DEF_H
`define PARAM_DEF_H

// constant
`define ENCODE_MODE             1'b0
`define DECODE_MODE             1'b1

`define MAX_CODE_RATE           3
`define MAX_CONSTRAINT_LENGTH   9
`define RADIX                   4 // transition per state


`define MAX_STATE_NUM           256 // = 2 ^ (MAX_CONSTRAINT_LENGTH - 1)        
`define MAX_STATE_REG_NUM       `MAX_CONSTRAINT_LENGTH-1 
`define DECODE_BIT_NUM          2 //`RADIX/2 // = log2(`RADIX)
`define TRACEBACK_DEPTH         64 // 7*K (can use 5K instead)
`define MAX_OUTPUT_BIT_NUM      126 // = traceback_depth*decode_bit_num
`define DATA_FRAME_LENGTH       21 //`TRACEBACK_DEPTH/`MAX_CODE_RATE
`define MAX_TRANSITION_NUM      1024 //`RADIX*`MAX_STATE_NUM  
`define SLICED_INPUT_NUM        6 //`MAX_CODE_RATE*DECODE_BIT_NUM  
`define MAX_INPUT_NUM           64

// select code rate
`define CODE_RATE_2             1'b0 // 1/2
`define CODE_RATE_3             1'b1 // 1/3

// select constraint length
`define CONSTR_LEN_3            2'b00
`define CONSTR_LEN_5            2'b01
`define CONSTR_LEN_7            2'b10
`define CONSTR_LEN_9            2'b11


`endif
