`include "param_def.sv"
`timescale 1ns / 1ps

module endec_interface (  sys_clk, rst, en,
                        i_code_rate, 
                        i_constr_len,
                        //i_mode_sel,
                        i_gen_poly_flat,
                        i_encoder_data_frame,
                        i_decoder_data_frame,
                        o_encoder_data, o_encoder_done,
                        o_decoder_data, o_decoder_done);

input wire sys_clk, rst, en;

// Configuration inputs
input wire i_code_rate;
input wire i_constr_len;
//input wire i_mode_sel;

// Generator polynomial inputs (flattened)
input wire [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;

// Encoder interface
input wire [127:0] i_encoder_data_frame;
output wire [383:0] o_encoder_data;
output wire o_encoder_done;

// Decoder interface
input wire [383:0] i_decoder_data_frame;
output wire [127:0] o_decoder_data;
output wire o_decoder_done;

// Instantiate the original module
endec E1 (
    .sys_clk(sys_clk),
    .rst(rst),
    .en(en),
    .i_code_rate(i_code_rate),
    .i_constr_len(i_constr_len),
    .i_gen_poly_flat(i_gen_poly_flat),
    //.i_mode_sel(i_mode_sel),
    .i_encoder_data_frame(i_encoder_data_frame),
    .i_decoder_data_frame(i_decoder_data_frame),
    .o_encoder_data(o_encoder_data),
    .o_encoder_done(o_encoder_done),
    .o_decoder_data(o_decoder_data),
    .o_decoder_done(o_decoder_done));

endmodule



// `include "param_def.sv"
// `timescale 1ns / 1ps
// module endec_interface( sys_clk, rst_n,
//                         axi_rx_tdata,
//                         axi_rx_tlast,
//                         axi_rx_tready,
//                         axi_rx_tvalid,
//                         axi_tx_tdata,
//                         axi_tx_tlast,
//                         axi_tx_tready,
//                         axi_tx_tvalid);

// input wire sys_clk, rst_n;

// // AXI RX
// input wire [31:0] axi_rx_tdata;
// input wire axi_rx_tlast; // valid and ready must already be high
// output reg axi_rx_tready; // active high
// input wire axi_rx_tvalid; // active high, deactivate when handshake is complete, handshake complete when both signal is high

// // AXI TX
// output reg [31:0] axi_tx_tdata;
// output reg axi_tx_tlast; // signal last transfer in a packet
// input wire axi_tx_tready;
// output reg axi_tx_tvalid;


// // Config signals
// reg rst; // internal reset signal
// reg en;
// reg i_code_rate;
// reg i_constr_len;
// //reg i_mode_sel;
// reg [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;

// // data for 1 packet
// reg [127:0] i_encoder_data_frame;
// wire [383:0] o_encoder_data; // 383
// wire o_encoder_done;
// reg [383:0] i_decoder_data_frame;
// wire [127:0] o_decoder_data;
// wire o_decoder_done;

// // for FSM
// reg [2:0] state; 
// reg [2:0] nxt_state;
// localparam [2:0] RST = 3'b000;
// localparam [2:0] CONF = 3'b001;
// localparam [2:0] ENCODE = 3'b010;
// localparam [2:0] DECODE = 3'b011;
// localparam [2:0] s4 = 3'b100;
// localparam [2:0] s5 = 3'b101;
// localparam [2:0] s6 = 3'b110;
// localparam [2:0] s7 = 3'b111;

// reg [6:0] i_e_count; // fixed
// reg [8:0] o_e_count;
// reg [8:0] i_d_count;
// reg [6:0] o_d_count; // fixed


// // buffer, need 4, 8, 12



// // AXI RX - TX
// always @(posedge sys_clk) // need to reset endec after finish processing
// begin
//     if(rst_n == 0)
//     begin
//         axi_rx_tready <= 0;
//         i_code_rate <= 0;
//         i_constr_len <= 0;
//         //i_mode_sel <= 0;
//         i_gen_poly_flat <= 0;
//         i_encoder_data_frame <= 0;
//         i_decoder_data_frame <= 0;

//         axi_tx_tdata <= 0;
//         axi_tx_tlast <= 0; 
//         axi_tx_tvalid <= 0;

//         i_e_count <= 127;
//         o_e_count <= 383;
//         i_d_count <= 383;
//         o_d_count <= 127;
//     end
//     else
//     begin
//         case(state)

//             RST:
//             begin
//                 axi_rx_tready <= 1; // ready to receive config signal
//                 i_code_rate <= 0;
//                 i_constr_len <= 0;
//                 //i_mode_sel <= 0;
//                 i_gen_poly_flat <= 0;
//                 i_encoder_data_frame <= 0;
//                 i_decoder_data_frame <= 0;

//                 axi_tx_tdata <= 0;
//                 axi_tx_tvalid <= 0;
//                 axi_tx_tlast <= 0;
//             end

//             CONF:
//             begin
//                 if(axi_rx_tvalid == 1 && axi_rx_tready == 1 && axi_rx_tlast == 1) // handshake, config data only has 1 transfer per packet
//                 begin // implicit axi_rx_tready = 1 from reset
//                     i_code_rate <= axi_rx_tdata[28];
//                     i_constr_len <= axi_rx_tdata[27];
//                     //i_mode_sel <= axi_rx_tdata[29];
//                     i_gen_poly_flat <= axi_rx_tdata[26:0];
//                 end

//                 axi_tx_tdata <= 0;
//                 axi_tx_tvalid <= 0;
//                 axi_tx_tlast <= 0;
//             end

//             ENCODE:
//             begin
//                 if(axi_rx_tvalid == 1 && axi_rx_tready == 1)
//                 begin
//                     i_encoder_data_frame[i_e_count -:31] <= axi_rx_tdata;
//                     i_e_count <= i_e_count - 32;
//                     if(axi_rx_tlast == 1) // last transfer of packet
//                     begin
//                         axi_rx_tready <= 0;
//                         i_e_count <= 0;
//                     end
//                 end


//                 if(o_encoder_done == 1)
//                     axi_tx_tvalid <= 1;
//                 else
//                     axi_tx_tvalid <= 0;

//                 if(axi_tx_tvalid == 1 && axi_tx_tready == 1) // output signal ready
//                 begin
//                     axi_tx_tdata <= o_encoder_data[o_e_count -:31];
//                     o_e_count <= o_e_count - 32;
//                     if(o_e_count == 63) // 31
//                     begin
//                         axi_tx_tlast <= 1;
//                         axi_rx_tready <= 1;
//                     end
//                 end
//             end

//             DECODE: // need fixing 
//             begin
//                 if(axi_rx_tvalid == 1 && axi_rx_tready == 1)
//                 begin
//                     i_decoder_data_frame[i_d_count -:31] <= axi_rx_tdata; // need to use count
//                     i_d_count <= i_d_count - 32;
//                     if(axi_rx_tlast == 1) // last transfer of packet
//                     begin
//                         axi_rx_tready <= 0;
//                         i_d_count <= 0;
//                     end
//                 end


//                 if(o_decoder_done == 1)
//                     axi_tx_tvalid <= 1;
//                 else
//                     axi_tx_tvalid <= 0;

//                 if(axi_tx_tvalid == 1 && axi_tx_tready == 1) // output signal ready
//                 begin
//                     axi_tx_tdata <= o_decoder_data[o_d_count -:31];
//                     o_d_count <= o_d_count - 32;
//                     if(o_d_count == 63) // 31
//                     begin
//                         axi_tx_tlast <= 1;
//                         axi_rx_tready <= 1;
//                     end
//                 end
//             end

//             default:
//             begin
//                 axi_rx_tready <= 0;
//                 i_code_rate <= 0;
//                 i_constr_len <= 0;
//                 //i_mode_sel <= 0;
//                 i_gen_poly_flat <= 0;
//                 i_encoder_data_frame <= 0;
//                 i_decoder_data_frame <= 0;

//                 axi_tx_tdata <= 0;
//                 axi_tx_tlast <= 0;
//                 axi_tx_tvalid <= 0;
//             end

//         endcase
//     end
// end


// //  FSM
// always @(posedge sys_clk) 
// begin
//     if(rst_n == 0)
//     begin
//         state <= RST;
//     end
//     else
//     begin
//         state <= nxt_state;
//     end
// end

// always @(*) // internal reset and en signal
// begin
//     case(state)
//         RST: 
//         begin
//             rst = 0;
//             en = 1;
//             nxt_state = CONF;
//         end
//         CONF: 
//         begin
//             rst = 1; // RST + CONF = rst pulse
//             en = 1;
//             if(axi_rx_tdata[29] == `DECODE_MODE)
//                 nxt_state = DECODE;
//             else if(axi_rx_tdata[29] == `ENCODE_MODE)
//                 nxt_state = ENCODE;
//             else
//                 nxt_state = RST;
//         end
//         ENCODE:
//         begin
//             rst = 1;
//             en = 1;
//             if(axi_tx_tvalid == 0 || axi_tx_tlast == 0 || axi_tx_tready == 0) // processing data or sending data
//                 nxt_state = ENCODE;
//             else
//                 nxt_state = RST; // reset after processing data 
//         end
//         DECODE:
//         begin
//             rst = 1;
//             en = 1;
//             if(axi_tx_tvalid == 0 || axi_tx_tlast == 0 || axi_tx_tready == 0) // processing data or sending data
//                 nxt_state = DECODE;
//             else
//                 nxt_state = RST;
//         end
//         default:
//         begin
//             rst = 1;
//             en = 0;
//             nxt_state = RST;
//         end
//     endcase
// end

// // Instantiate the original module
// endec E1 (
//     .sys_clk(sys_clk),
//     .rst(rst),
//     .en(en),
//     .i_code_rate(i_code_rate),
//     .i_constr_len(i_constr_len),
//     .i_gen_poly_flat(i_gen_poly_flat),
//     //.i_mode_sel(i_mode_sel),
//     .i_encoder_data_frame(i_encoder_data_frame),
//     .i_decoder_data_frame(i_decoder_data_frame),
//     .o_encoder_data(o_encoder_data),
//     .o_encoder_done(o_encoder_done),
//     .o_decoder_data(o_decoder_data),
//     .o_decoder_done(o_decoder_done));

// endmodule
