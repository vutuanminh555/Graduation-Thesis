`include "param_def.sv"
`timescale 1ns / 1ps

module trellis_diagr(   clk, rst, en_td, 
                        i_fwd_prv_st, i_ood,
                        o_bck_prv_st, o_td_full, o_td_empty);

input logic clk, rst, en_td;
input logic i_ood;
input logic [`MAX_STATE_REG_NUM - 1:0] i_fwd_prv_st [`MAX_STATE_NUM];

output logic [`MAX_STATE_REG_NUM - 1:0] o_bck_prv_st [`MAX_STATE_NUM];
output logic o_td_full;
output logic o_td_empty;
// need to use multiple bram and long data to achieve parallel data access
logic [`MAX_STATE_REG_NUM - 1:0] td_mem [`MAX_STATE_NUM][`TRACEBACK_DEPTH]; // use single port  BRAM

logic [6:0] depth; // need to decrease traceback depth to 5*K

logic wrk_mode;

always_ff @(posedge clk) // save data to memory 
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            for(int j = 0; j < `TRACEBACK_DEPTH; j++)
            begin
                td_mem[i][j] <= 0;
            end
        end
        depth <= 0; 
    end
    else
    begin
        if(en_td == 1)
        begin
            if(wrk_mode == 0) // creating trellis diagram
            begin
                for(int i = 0; i < `MAX_STATE_NUM; i++)
                begin
                    td_mem[i][depth] <= i_fwd_prv_st[i]; 
                end
                if(i_ood == 0)
                    depth <= depth + 1;
            end
            else if(wrk_mode == 1) // output transition to traceback
            begin
                depth <= depth - 1; 
            end
        end
        else
        begin

        end
    end
end

always_comb // output data
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            o_bck_prv_st[i] = 0;
        end
        o_td_empty = 0;
        o_td_full = 0;
    end
    else
    begin
        if(en_td == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                o_bck_prv_st[i] = td_mem[i][depth];
            end
            if(wrk_mode == 0)
            begin
                if(depth == `TRACEBACK_DEPTH - 1)
                begin
                    o_td_empty = 0; 
                    o_td_full = 1;
                end
                else
                begin
                    o_td_empty = 0; 
                    o_td_full = 0;
                end
            end
            else if(wrk_mode == 1)
            begin
                if(depth == 0)
                begin
                    o_td_empty = 1; 
                    o_td_full = 0;
                end
                else
                begin
                    o_td_empty = 0; 
                    o_td_full = 0;
                end
            end
            else
            begin
                o_td_empty = 0;
                o_td_full = 0;
            end
        end
        else
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                o_bck_prv_st[i] = 0;
            end
            o_td_empty = 0;
            o_td_full = 0;
        end
    end
end

always_ff @(posedge clk) // change working mode, use sequential logic to sync with traceback module
begin
    if(rst == 0)
    begin
        wrk_mode <= 0;
    end
    else
    begin
        if(en_td == 1)
        begin 
            if(o_td_full == 1 || i_ood == 1) // only need enable pulse
                wrk_mode <= 1;
        end
        else
        begin
            wrk_mode <= 0;
        end
    end
end

endmodule

//`include"xpm_memory.sv"
// `include "param_def.sv"
// `timescale 1ns / 1ps

// module trellis_diagr(   clk, rst, en_td, 
//                         i_fwd_prv_st, i_ood,
//                         o_bck_prv_st, o_td_full, o_td_empty);

// input logic clk, rst, en_td;
// input logic i_ood;
// input logic [`MAX_STATE_REG_NUM - 1:0] i_fwd_prv_st [`MAX_STATE_NUM];

// output logic [`MAX_STATE_REG_NUM - 1:0] o_bck_prv_st [`MAX_STATE_NUM];
// output logic o_td_full;
// output logic o_td_empty;

// // need to use multiple bram and long data to achieve parallel data access
// //(* ram_style = "block" *) logic [`MAX_STATE_REG_NUM - 1:0] td_mem [`MAX_STATE_NUM][`TRACEBACK_DEPTH]; // use single port  BRAM

// logic [7:0] depth; 

// logic wrk_mode;
// logic wrk_mode_delay;

// // Parameters for BRAM configuration
// localparam BRAM_DATA_WIDTH = 32;
// localparam BRAM_ADDR_WIDTH = 8; //$clog2(TRACEBACK_DEPTH)
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
//         .MEMORY_SIZE(BRAM_DATA_WIDTH * `TRACEBACK_DEPTH * 2), // use both port A and B for writing and reading
//         .MESSAGE_CONTROL(0),
//         .READ_DATA_WIDTH_A(BRAM_DATA_WIDTH),
//         .READ_DATA_WIDTH_B(BRAM_DATA_WIDTH),
//         .READ_LATENCY_A(1),
//         .READ_LATENCY_B(1),
//         .READ_RESET_VALUE_A("1"), // default read value when read data is invalid
//         .READ_RESET_VALUE_B("2"),
//         .RST_MODE_A("SYNC"),
//         .RST_MODE_B("SYNC"),
//         .SIM_ASSERT_CHK(0), // simulation debug
//         .USE_EMBEDDED_CONSTRAINT(0), // apply optimal placement constraint for distributed RAM (LUT)
//         .USE_MEM_INIT(0),
//         .WAKEUP_TIME("disable_sleep"),
//         .WRITE_DATA_WIDTH_A(BRAM_DATA_WIDTH),
//         .WRITE_DATA_WIDTH_B(BRAM_DATA_WIDTH),
//         .WRITE_MODE_A("WRITE_FIRST"), // written data doesnt affect read data
//         .WRITE_MODE_B("WRITE_FIRST")
//     ) td_mem (
//         .douta(bram_douta[i]), // data out
//         .doutb(bram_doutb[i]),
//         .addra(bram_addra[i]), 
//         .addrb(bram_addrb[i]),
//         .clka(clk),
//         .clkb(clk),
//         .dina(bram_dina[i]), // data in
//         .dinb(bram_dinb[i]),
//         .ena(en_td), // enable signal for all instances
//         .enb(en_td),
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
//         .wea(en_td && (wrk_mode == 0)), // write enable signal
//         .web(en_td && (wrk_mode == 0)) 
//     );
// end
// endgenerate

// always_ff @(posedge clk) 
// begin
//     if (rst == 0) 
//     begin
//         depth <= 0;
//         //wrk_mode <= 0;
//         for (int i = 0; i < `MAX_STATE_NUM; i++) 
//         begin
//             o_bck_prv_st[i] <= 0;
//         end
//         for (int i = 0; i < NUM_BRAMS; i++) // only reset data at address 0 ?
//         begin
//             bram_dina[i] <= 0;
//             bram_dinb[i] <= 0;
//             bram_addra[i] <= depth;
//             bram_addrb[i] <= depth + 1;
//         end
//     end
//     else
//     begin
//         if(en_td == 1)
//         begin
//             if(wrk_mode == 0) // write mode
//             begin
//                 for(int i = 0; i < NUM_BRAMS; i++) // working, memory need 1 cycle delay to store data
//                 begin
//                     bram_addra[i] <= depth;
//                     bram_addrb[i] <= depth + 1;
//                     bram_dina[i] <= {i_fwd_prv_st[i*8 + 3], i_fwd_prv_st[i*8 + 2], i_fwd_prv_st[i*8 + 1], i_fwd_prv_st[i*8]}; // not hardware intensive, can be inferred as bit shift
//                     bram_dinb[i] <= {i_fwd_prv_st[i*8 + 7], i_fwd_prv_st[i*8 + 6], i_fwd_prv_st[i*8 + 5], i_fwd_prv_st[i*8 + 4]};
//                     // if(i<1)
//                     // begin
//                     // $display("BRAM instance is: %d", i);
//                     // $display("depth value is: %d", depth);
//                     // $display("bram_dina value is: %b", bram_dina[i]);
//                     // $display("bram_dinb value is: %b\n", bram_dinb[i]);
//                     // end
//                 end

//                 if(i_ood == 0) 
//                     depth <= depth + 2;
//             end
//             if(wrk_mode_delay == 1) // read mode 
//             begin
//                 for(int i = 0; i < NUM_BRAMS; i++) //32 BRAMs, each holds 8 state value
//                 begin
//                     bram_addra[i] <= depth;
//                     bram_addrb[i] <= depth + 1;

//                     // o_bck_prv_st[i*8] <= bram_douta[i][7:0]; // need to have 1 cycle delay compared to address
//                     // o_bck_prv_st[i*8 + 1] <= bram_douta[i][15:8];
//                     // o_bck_prv_st[i*8 + 2] <= bram_douta[i][23:16];
//                     // o_bck_prv_st[i*8 + 3] <= bram_douta[i][31:24];

//                     // o_bck_prv_st[i*8 + 4] <= bram_doutb[i][7:0];
//                     // o_bck_prv_st[i*8 + 5] <= bram_doutb[i][15:8];
//                     // o_bck_prv_st[i*8 + 6] <= bram_doutb[i][23:16];
//                     // o_bck_prv_st[i*8 + 7] <= bram_doutb[i][31:24];
//                 end
                
//                 depth <= depth - 2;
//             end


//             // if (o_td_full == 1 || i_ood == 1) 
//             // begin
//             //     wrk_mode <= 1;
//             // end
//         end
//         else
//         begin
//             for (int i = 0; i < `MAX_STATE_NUM; i++) 
//             begin
//                 o_bck_prv_st[i] <= 0;
//             end
//         end
//     end
// end

// always_ff @(posedge clk)
// begin
//     if(rst == 0)
//     begin
//         wrk_mode <= 0;
//         wrk_mode_delay <= 0;
//     end
//     else
//     begin
//         wrk_mode_delay <= wrk_mode;
//         if (o_td_full == 1 || i_ood == 1) 
//             begin
//                 wrk_mode <= 1;
//             end
//     end
// end

// // Output data
// always_ff @(posedge clk)
// begin
//     if (rst == 0)
//     begin
//         // for (int i = 0; i < `MAX_STATE_NUM; i++) 
//         // begin
//         //     o_bck_prv_st[i] <= 0;
//         // end
//         o_td_empty <= 0;
//         o_td_full <= 0;
//     end
//     else
//     begin
//         if(en_td == 1)
//         begin
//             // for(int i = 0; i < NUM_BRAMS; i++) //32 BRAMs, each holds 8 state value
//             // begin
//             //     bram_addra[i] <= depth;
//             //     bram_addrb[i] <= depth + 1;

//             //     o_bck_prv_st[i*8] <= bram_douta[i][7:0];
//             //     o_bck_prv_st[i*8 + 1] <= bram_douta[i][15:8];
//             //     o_bck_prv_st[i*8 + 2] <= bram_douta[i][23:16];
//             //     o_bck_prv_st[i*8 + 3] <= bram_douta[i][31:24];

//             //     o_bck_prv_st[i*8 + 4] <= bram_doutb[i][7:0];
//             //     o_bck_prv_st[i*8 + 5] <= bram_doutb[i][15:8];
//             //     o_bck_prv_st[i*8 + 6] <= bram_doutb[i][23:16];
//             //     o_bck_prv_st[i*8 + 7] <= bram_doutb[i][31:24];
//             // end

//         if(wrk_mode == 0) 
//         begin
//             o_td_empty <= 0;
//             if(depth == `TRACEBACK_DEPTH - 1)
//             o_td_full <= 1;
//         end
//         if(wrk_mode == 1)
//         begin
//             if(depth == 0)
//             o_td_empty <= 1;
//             o_td_full <= 0;
//         end
//         end 
//         else 
//         begin
//             // for (int i = 0; i < `MAX_STATE_NUM; i++) 
//             // begin
//             //     o_bck_prv_st[i] <= 0;
//             // end
//             o_td_empty <= 0;
//             o_td_full <= 0;
//         end
//     end
// end

// endmodule