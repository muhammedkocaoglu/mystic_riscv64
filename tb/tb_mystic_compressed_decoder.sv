`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/25/2022 08:42:48 PM
// Design Name: 
// Module Name: tb_mystic_compressed_decoder
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


module tb_mystic_compressed_decoder(

   );

   logic             clk_i = 1;
   logic             rstn_i;
   logic             is_compressed_i;
   logic             instr_ready_i;
   logic  [31:0]     instr_i;
   logic  [31:0]     instr_decompressed_o;
   logic             instr_decompressed_ready_o;

   mystic_compressed_decoder mystic_compressed_decoder(
      .clk_i                        (clk_i                       ),
      .rstn_i                       (rstn_i                      ),
      .is_compressed_i              (is_compressed_i             ),
      .instr_ready_i                (instr_ready_i               ),
      .instr_i                      (instr_i                     ),
      .instr_decompressed_o         (instr_decompressed_o        ),
      .instr_decompressed_ready_o   (instr_decompressed_ready_o  )
   );

   always #5 clk_i   <= ~clk_i;

   initial begin
      rstn_i   <= 1'b0;
      @(negedge clk_i);
      @(negedge clk_i);
      rstn_i   <= 1'b1;

      #50;
      @(negedge clk_i);
      instr_ready_i     <= 1'b1;
      is_compressed_i   <= 1'b1;
      instr_i           <= {{16{1'b0}}, 16'b010_110_111_01_000_00};
      @(negedge clk_i);
      instr_ready_i     <= 1'b0;
      is_compressed_i   <= 1'b0;

      #50;
      $stop;
   end
endmodule
