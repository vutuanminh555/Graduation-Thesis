`timescale 1ns / 1ps

module viterbi_decoder_tb();

reg clk,rst,en;
reg [15:0] i_data;

wire [7:0] o_data;
wire o_done;

reg [5:0] count;
reg [12:0] index;
integer file_outputs;
reg [15:0] in_ram [0:1024];

viterbi_decoder V1 (.sys_clk(clk),
                    .rst(rst),
                    .en(en),
                    .i_data(i_data),
                    .o_data(o_data),
                    .o_done(o_done));

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
initial
begin
    i_data = 16'b1101101010100110;
end

always @ (posedge o_done)
begin
    $display("Output data is: %b\n", o_data);
    $finish;
end

endmodule
