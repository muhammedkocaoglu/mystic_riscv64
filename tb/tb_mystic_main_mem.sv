`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2022 11:43:09 AM
// Design Name: 
// Module Name: tb_mystic_main_mem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_mystic_main_mem(

    );


    logic        clk_i = 1;
    logic        rstn_i = 0;
    logic        we_i = 0;
    logic        rd_data_i = 0;
    logic [4:0]  byte_len_i = 0;
    logic [31:0] addr_i;
    logic [63:0] din_i;
    logic [63:0] dout_o;
    logic [31:0] instr_o;
    logic        dout_ready_o;
    logic        is_compressed_o;
    logic        rd_instr_i;


    always #5 clk_i  <= ~clk_i;

    initial begin
        rstn_i  <= 0;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        rstn_i  <= 1;
        #5000000;

        @(negedge clk_i);
        @(negedge clk_i);
        we_i    <= 1'b1;
        byte_len_i  <= 8;
        addr_i  <= 0;
        din_i   <= 64'h0123456789abcdef;
        @(negedge clk_i);
        we_i    <= 1'b0;

        #200;
        @(negedge clk_i);
        @(negedge clk_i);
        rd_data_i <= 1'b1;
        byte_len_i  <= 4;
        addr_i  <= 2;
        @(negedge clk_i);
        rd_data_i <= 1'b0;


        #200;
        @(negedge clk_i);
        @(negedge clk_i);
        rd_instr_i <= 1'b1;
        @(negedge clk_i);
        rd_instr_i <= 1'b0;

        #500;
        $stop;
    end

    mystic_main_mem mystic_main_mem(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .we_i(we_i),
        .rd_instr_i(rd_instr_i),
        .rd_data_i(rd_data_i),
        .byte_len_i(byte_len_i),
        .addr_i(addr_i),
        .din_i(din_i),
        .dout_o(dout_o),
        .instr_o(instr_o),
        .dout_ready_o(dout_ready_o),
        .is_compressed_o(is_compressed_o)
    );
endmodule
