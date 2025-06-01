`ifndef PARAM_DEF_H
`define PARAM_DEF_H

`define MAX_CODE_RATE           3
`define MAX_CONSTRAINT_LENGTH   9
`define RADIX                   4 

`define MAX_STATE_NUM           256        
`define MAX_STATE_REG_NUM       `MAX_CONSTRAINT_LENGTH-1 
`define OUTPUT_BIT_NUM          2
`define TRACEBACK_DEPTH         64
`define SLICED_INPUT_NUM        6

// select code rate
`define CODE_RATE_2             1'b0
`define CODE_RATE_3             1'b1 

`endif