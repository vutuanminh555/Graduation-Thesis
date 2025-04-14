`include "param_def.sv"
`timescale 1ns / 1ps

module add_compare_select(  clk, rst, en_acs,
                            i_constr_len, i_dist, 
                            o_fwd_prv_st, o_sel_node);

input logic clk, rst, en_acs;
input logic [1:0] i_constr_len;
input logic [2:0] i_dist [`MAX_STATE_NUM][`RADIX]; // distance per transition

output logic [`MAX_STATE_REG_NUM - 1:0] o_fwd_prv_st [`MAX_STATE_NUM]; // hold next state value for each state (index: current state, value: nxt state)
output logic [`MAX_STATE_REG_NUM - 1:0] o_sel_node;

logic [8:0] node_mem [`MAX_STATE_NUM]; // node value, switch to dual port bram, use multiple ram with long data to achieve parallel data access

logic [8:0] min_node;

logic [9:0] min_pm;
logic [`MAX_STATE_REG_NUM - 1:0] min_prv_st;

always_ff @(posedge clk) // update and save pm value for each node
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            node_mem[i] <= 0;
        end
    end
    else 
    begin
        if(en_acs == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++) // add value from distance of the shortest path, node_mem has 1 cycle delay to i_dist
            begin
                node_mem[i] <= node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}]; // input bit order is reversed
            end
        end
        else
        begin

        end
    end
end

always_comb // compare all transition to next state, choose smallest distance and output value, need to switch to sequential to read data from bram 
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            o_fwd_prv_st[i] = 0;
        end
        min_pm = 10'b1111111111;
        min_prv_st = 0;
    end
    else 
    begin
        if(en_acs == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++) // calculating min_pm
            begin
                min_pm = 10'b1111111111; // can always choose at least 1 path
                min_prv_st = 0; // reset value for the next iteration
                for(int j = 0; j < `RADIX; j++) // find path with smallest distance 
                begin
                    if(i_constr_len == `CONSTR_LEN_3) 
                    begin
                        if(node_mem[{i[7:2],j[1:0]}] + i_dist[{i[7:2],j[1:0]}][{i[0],i[1]}] < min_pm) // nxt_state have the same input but different previous state
                        begin
                            min_pm = node_mem[{i[7:2],j[1:0]}] + i_dist[{i[7:2],j[1:0]}][{i[0],i[1]}];
                            min_prv_st = {i[7:2],j[1:0]};
                        end
                    end
                    else // constraint length 5-7-9
                    begin
                        if(node_mem[{j[1:0],i[7:2]}] + i_dist[{j[1:0],i[7:2]}][{i[0],i[1]}] < min_pm)
                        begin
                            min_pm = node_mem[{j[1:0],i[7:2]}] + i_dist[{j[1:0],i[7:2]}][{i[0],i[1]}]; // priority: 00 > 01 > 10 > 11
                            min_prv_st = {j[1:0],i[7:2]};
                        end
                    end
                end 
                o_fwd_prv_st[i] = min_prv_st ; // output address is next state, value is previous state
            end
        end
        else 
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                o_fwd_prv_st[i] = 0;
            end
            min_pm = 10'b1111111111;
            min_prv_st = 0;
        end
    end
end

always_comb // calculate and output min_node
begin
    min_node = 9'b111111111; // avoid infer latch
    o_sel_node = 0;
    // if(rst == 0)
    // begin
    //     min_node = 9'b111111111;
    //     o_sel_node = 0;
    // end
    // else
    // begin
        if(en_acs == 1)
        begin
            min_node = 9'b111111111;
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                if(node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}] < min_node) // compare to node_mem[i], avoid 1 cycle delay
                begin
                    min_node = node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}];
                    o_sel_node = i;
                end
            end
        end
        else
        begin
            min_node = 9'b111111111;
            o_sel_node = 0;
        end
    //end
end

endmodule

// `include "param_def.sv"
// `timescale 1ns / 1ps

// module add_compare_select(  clk, rst, en_acs,
//                             i_constr_len, i_dist, 
//                             o_fwd_prv_st, o_sel_node);

// input logic clk, rst, en_acs;
// input logic [1:0] i_constr_len;
// input logic [2:0] i_dist [`MAX_STATE_NUM][`RADIX]; // distance per transition

// output logic [`MAX_STATE_REG_NUM - 1:0] o_fwd_prv_st [`MAX_STATE_NUM]; // hold next state value for each state (index: current state, value: nxt state)
// output logic [`MAX_STATE_REG_NUM - 1:0] o_sel_node;

// //logic [8:0] node_mem [`MAX_STATE_NUM]; // node value, switch to dual port bram, use multiple ram with long data to achieve parallel data access

// logic [8:0] min_node;

// logic [9:0] min_pm;
// logic [`MAX_STATE_REG_NUM - 1:0] min_prv_st;

// // Parameters for BRAM configuration
// localparam BRAM_DATA_WIDTH = 36;
// localparam BRAM_ADDR_WIDTH = 2;
// localparam NUM_BRAMS = 32;

// // BRAM interface signals
// logic [BRAM_ADDR_WIDTH - 1:0] bram_addra [NUM_BRAMS]; 
// logic [BRAM_ADDR_WIDTH - 1:0] bram_addrb [NUM_BRAMS];
// logic [BRAM_DATA_WIDTH - 1:0] bram_dina [NUM_BRAMS]; 
// logic [BRAM_DATA_WIDTH - 1:0] bram_dinb [NUM_BRAMS];
// logic [BRAM_DATA_WIDTH - 1:0] bram_douta [NUM_BRAMS]; 
// logic [BRAM_DATA_WIDTH - 1:0] bram_doutb [NUM_BRAMS];

// logic sbiterra [NUM_BRAMS];
// logic sbiterrb [NUM_BRAMS];
// logic dbiterra [NUM_BRAMS];
// logic dbiterrb [NUM_BRAMS];

// // Generate 32 True Dual-Port BRAMs using XPM macro
// generate
// genvar i;
// for (i = 0; i < NUM_BRAMS; i = i + 1) 
// begin
//     xpm_memory_tdpram #(
//         .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),
//         .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),
//         .BYTE_WRITE_WIDTH_A(BRAM_DATA_WIDTH), // not using byte write
//         .BYTE_WRITE_WIDTH_B(BRAM_DATA_WIDTH),
//         .CLOCKING_MODE("common_clock"),
//         .MEMORY_INIT_FILE("none"),
//         .MEMORY_INIT_PARAM("0"),
//         .MEMORY_OPTIMIZATION("false"), // true: area, false: performance
//         .MEMORY_PRIMITIVE("block"),
//         .MEMORY_SIZE(BRAM_ADDR_WIDTH * BRAM_DATA_WIDTH), // use both port A and B for writing and reading
//         .MESSAGE_CONTROL(1),
//         .READ_DATA_WIDTH_A(BRAM_DATA_WIDTH),
//         .READ_DATA_WIDTH_B(BRAM_DATA_WIDTH),
//         .READ_LATENCY_A(1),
//         .READ_LATENCY_B(1),
//         .READ_RESET_VALUE_A("1"), // default read value when read data is invalid
//         .READ_RESET_VALUE_B("2"),
//         .RST_MODE_A("SYNC"),
//         .RST_MODE_B("SYNC"),
//         .SIM_ASSERT_CHK(1), // simulation debug
//         .USE_EMBEDDED_CONSTRAINT(0), // apply optimal placement constraint for distributed RAM (LUT)
//         .USE_MEM_INIT(0),
//         .WAKEUP_TIME("disable_sleep"),
//         .WRITE_DATA_WIDTH_A(BRAM_DATA_WIDTH),
//         .WRITE_DATA_WIDTH_B(BRAM_DATA_WIDTH),
//         .WRITE_MODE_A("WRITE_FIRST"), // written data doesnt affect read data
//         .WRITE_MODE_B("WRITE_FIRST")
//     ) node_mem (
//         .douta(bram_douta[i]), // data out
//         .doutb(bram_doutb[i]),
//         .addra(bram_addra[i]), 
//         .addrb(bram_addrb[i]),
//         .clka(clk),
//         .clkb(clk),
//         .dina(bram_dina[i]), // data in
//         .dinb(bram_dinb[i]),
//         .ena(en_acs), // enable signal for all instances
//         .enb(en_acs),
//         .injectdbiterra(1'b0), // simulate double bit error for ECC
//         .injectdbiterrb(1'b0),
//         .injectsbiterra(1'b0), // simulate single bit error for ECC
//         .injectsbiterrb(1'b0),
//         .sbiterra(sbiterra[i]), // flag detect error bits
//         .sbiterrb(sbiterrb[i]),
//         .dbiterra(dbiterra[i]), 
//         .dbiterrb(dbiterrb[i]),
//         .regcea(1'b1), // update data based on address 
//         .regceb(1'b1),
//         .rsta(!rst), // active high
//         .rstb(!rst),
//         .sleep(1'b0), // enable sleep mode
//         .wea(1'b1), // always write
//         .web(1'b1) 
//     );
// end
// endgenerate

// always_ff @(posedge clk) // update and save pm value for each node
// begin
//     if(rst == 0)
//     begin
//         // for(int i = 0; i < `MAX_STATE_NUM; i++)
//         // begin
//         //     node_mem[i] <= 0;
//         // end
//     end
//     else 
//     begin
//         if(en_acs == 1)
//         begin
//             // for(int i = 0; i < `MAX_STATE_NUM; i++) // add value from distance of the shortest path, node_mem has 1 cycle delay to i_dist
//             // begin
//             //     node_mem[i] <= node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}]; // input bit order is reversed
//             // end
//         end
//         else
//         begin

//         end
//     end
// end

// always_comb // compare all transition to next state, choose smallest distance and output value, need to switch to sequential to read data from bram 
// begin
//     if(rst == 0)
//     begin
//         for(int i = 0; i < `MAX_STATE_NUM; i++)
//         begin
//             o_fwd_prv_st[i] = 0;
//         end
//         min_pm = 10'b1111111111;
//         min_prv_st = 0;
//     end
//     else 
//     begin
//         if(en_acs == 1)
//         begin
//             for(int i = 0; i < `MAX_STATE_NUM; i++) // calculating min_pm
//             begin
//                 min_pm = 10'b1111111111; // can always choose at least 1 path
//                 min_prv_st = 0; // reset value for the next iteration
//                 for(int j = 0; j < `RADIX; j++) // find path with smallest distance 
//                 begin
//                     if(i_constr_len == `CONSTR_LEN_3) 
//                     begin
//                         if(node_mem[{i[7:2],j[1:0]}] + i_dist[{i[7:2],j[1:0]}][{i[0],i[1]}] < min_pm) // nxt_state have the same input but different previous state
//                         begin
//                             min_pm = node_mem[{i[7:2],j[1:0]}] + i_dist[{i[7:2],j[1:0]}][{i[0],i[1]}];
//                             min_prv_st = {i[7:2],j[1:0]};
//                         end
//                     end
//                     else // constraint length 5-7-9
//                     begin
//                         if(node_mem[{j[1:0],i[7:2]}] + i_dist[{j[1:0],i[7:2]}][{i[0],i[1]}] < min_pm)
//                         begin
//                             min_pm = node_mem[{j[1:0],i[7:2]}] + i_dist[{j[1:0],i[7:2]}][{i[0],i[1]}]; // priority: 00 > 01 > 10 > 11
//                             min_prv_st = {j[1:0],i[7:2]};
//                         end
//                     end
//                 end 
//                 o_fwd_prv_st[i] = min_prv_st ; // output address is next state, value is previous state
//             end
//         end
//         else 
//         begin
//             for(int i = 0; i < `MAX_STATE_NUM; i++)
//             begin
//                 o_fwd_prv_st[i] = 0;
//             end
//             min_pm = 10'b1111111111;
//             min_prv_st = 0;
//         end
//     end
// end

// always_comb // calculate and output min_node
// begin
//     min_node = 9'b111111111; // avoid infer latch
//     o_sel_node = 0;
//     // if(rst == 0)
//     // begin
//     //     min_node = 9'b111111111;
//     //     o_sel_node = 0;
//     // end
//     // else
//     // begin
//         if(en_acs == 1)
//         begin
//             min_node = 9'b111111111;
//             for(int i = 0; i < `MAX_STATE_NUM; i++)
//             begin
//                 if(node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}] < min_node) // compare to node_mem[i], avoid 1 cycle delay
//                 begin
//                     min_node = node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}];
//                     o_sel_node = i;
//                 end
//             end
//         end
//         else
//         begin
//             min_node = 9'b111111111;
//             o_sel_node = 0;
//         end
//     //end
// end

// endmodule