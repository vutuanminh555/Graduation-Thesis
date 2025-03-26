`include "param_def.v"
`timescale 1ns / 1ps

module endec_tb(); 

reg clk, rst, en; // need changing
reg [`MAX_CODE_RATE -1:0] i_code_rate;
reg [`MAX_CONSTRAINT_LENGTH - 1:0] i_constr_len;
reg [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE - 1:0];
reg i_mode_sel;
reg i_encoder_bit;
reg [`TRACEBACK_DEPTH - 1:0] i_decoder_data_frame;


wire [`MAX_CODE_RATE - 1:0] o_encoder_data;
wire o_encoder_done;
wire [`DATA_FRAME_LENGTH - 1:0] o_decoder_data;
wire o_decoder_done;

// reg [5:0] count;
// reg [12:0] index;
// integer file_outputs;
// reg [15:0] in_ram [0:1024];

endec E1 (  .sys_clk(clk), // add code rate. constraint length. poly input 
            .rst(rst),
            .en(en),
            .i_code_rate(i_code_rate),
            .i_constr_len(i_constr_len),
            .i_gen_poly(i_gen_poly),
            .i_mode_sel(i_mode_sel),
            .i_encoder_bit(i_encoder_bit), 
            .i_decoder_data_frame(i_decoder_data_frame), 
            .o_encoder_data(o_encoder_data),
            .o_encoder_done(o_encoder_done),
            .o_decoder_data(o_decoder_data), 
            .o_decoder_done(o_decoder_done));

always #5 clk = ~clk;

initial 
begin
        // Khởi tạo tín hiệu
        clk = 0;
        rst = 1;
        en = 1;
        
        // Reset
        #10 rst = 0;
        #1 rst = 1;
        
end

initial
begin
    i_code_rate = 2;
    i_constr_len = 3;
    i_gen_poly[0] = 9'b000000111;
    i_gen_poly[1] = 9'b000000101;
    i_mode_sel = `DECODE_MODE;
    i_encoder_bit = 0;
    i_decoder_data_frame = 0;
end

// initial
// begin
//      index <= 1;
//      $readmemb("C:/Users/vutua/Downloads/Viterbi-Decoder-main/Viterbi-Decoder-main/input - Viterbi.txt", in_ram); 
//      file_outputs = $fopen("output.txt", "w");
//      i_data = in_ram[0];
// end

// always @ (posedge o_done)
// begin
//     $display("Output data from input line %d is: %b\n", index, o_data);
//     $fwrite(file_outputs, "%b\n", o_data);
//     index <= index + 1;
//     i_data <= in_ram [index];
//     rst = 0;
//     #1 rst = 1;

//     if(index >=1026)
//     begin
//         $fclose(file_outputs);
//         $finish;
//     end
// end


//direct test
// initial
// begin
//     i_data = 16'b1101101010100110;
// end

// always @ (posedge o_done)
// begin
//     $display("Output data is: %b\n", o_data);
//     $finish;
// end

endmodule
