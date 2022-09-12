`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2022 07:45:50 AM
// Design Name: 
// Module Name: tb_mystic_alu
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


module tb_mystic_alu(

   );

   logic         clk_i = 1;
   logic         rstn_i;
   logic [5:0]   alu_opcode_i;
   logic         alu_opcode_valid_i;

   logic [63:0]  alu_srcA;
   logic [63:0]  alu_srcB;
   logic [63:0]  alu_result;
   logic         alu_ready_o;

   mystic_alu mystic_alu_inst (
      .clk_i               (clk_i               ),
      .rstn_i              (rstn_i              ),
      .alu_opcode_i        (alu_opcode_i        ),
      .alu_opcode_valid_i  (alu_opcode_valid_i  ),

      .alu_srcA            (alu_srcA            ),
      .alu_srcB            (alu_srcB            ),
      .alu_result          (alu_result          ),
      .alu_ready_o         (alu_ready_o         )
   );

   always #5 clk_i   <= ~clk_i;
   
   initial begin
      #20;
      @(negedge clk_i);
      @(negedge clk_i);
      rstn_i   <= 1'b0;
      @(negedge clk_i);
      @(negedge clk_i);
      rstn_i   <= 1'b1;
      alu_opcode_i   <= 6'b000000;
      alu_opcode_valid_i   <= 1'b1;
      alu_srcA       <= 64'h0000000014aed4aa;
      alu_srcB       <= 64'h00000000aefbc479;
      @(negedge clk_i);
      alu_opcode_valid_i   <= 1'b0;

      #50;
      @(negedge clk_i);
      alu_opcode_i   <= 6'b000000;
      alu_opcode_valid_i   <= 1'b1;
      alu_srcA       <= 64'h0000000000000003;
      alu_srcB       <= 64'hFFFFFFFFFFFFFFF7;
      @(negedge clk_i);
      alu_opcode_valid_i   <= 1'b0;

      #1000;
      $stop;
   end
endmodule
