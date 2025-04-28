`ifndef PARAM_DEF_H
`define PARAM_DEF_H

// constant
`define ENCODE_MODE             1'b0
`define DECODE_MODE             1'b1

`define MAX_CODE_RATE           3
`define MAX_CONSTRAINT_LENGTH   9
`define RADIX                   4 

`define MAX_STATE_NUM           256 // = 2 ^ (MAX_CONSTRAINT_LENGTH - 1)        
`define MAX_STATE_REG_NUM       `MAX_CONSTRAINT_LENGTH-1 
`define OUTPUT_BIT_NUM          2 // = log2(`RADIX)
`define TRACEBACK_DEPTH         64 // = traceback_depth*decode_bit_num
`define SLICED_INPUT_NUM        6 //`MAX_CODE_RATE*DECODE_BIT_NUM

// select code rate
`define CODE_RATE_2             1'b0
`define CODE_RATE_3             1'b1 

// select constraint length
`define CONSTR_LEN_3            1'b1 
`define CONSTR_LEN_5            1'b0 
`define CONSTR_LEN_7            1'b0
`define CONSTR_LEN_9            1'b0


`endif