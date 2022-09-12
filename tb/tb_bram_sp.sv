`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/12/2022 04:40:55 PM
// Design Name: 
// Module Name: tb_bram_sp
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


module tb_bram_sp #(
   parameter BRAM_DATA_WIDTH = 80,
   parameter BRAM_ADDR_WIDTH = 8
);


   logic                            clk_i = 1;
   logic                            bram_we_i;
   logic   [7:0]                    bram_write_strobe_i;
   logic   [BRAM_ADDR_WIDTH-1:0]    bram_addr_i;
   logic   [BRAM_DATA_WIDTH-1:0]    bram_din_i;
   logic   [BRAM_DATA_WIDTH-1:0]    bram_dout_o;

      
   bram_sp 
   #(
      .BRAM_DATA_WIDTH  (BRAM_DATA_WIDTH        ),
      .BRAM_ADDR_WIDTH  (BRAM_ADDR_WIDTH        )
   )
   bram_sp_inst
   (
      .clk_i               (clk_i               ),
      .bram_we_i           (bram_we_i           ),
      .bram_write_strobe_i (bram_write_strobe_i ),
      .bram_addr_i         (bram_addr_i         ),
      .bram_din_i          (bram_din_i          ),
      .bram_dout_o         (bram_dout_o         )
   );

   always #5 clk_i <= ~clk_i;

   initial begin
      #20;
      @(negedge clk_i);
      @(negedge clk_i);
      bram_addr_i          <= 8'b0000_0001;
      bram_write_strobe_i  <= 8'b1111_1111;
      bram_din_i           <= {$urandom(), $urandom(), $urandom()};
      @(negedge clk_i);
      $display("data: %h", bram_din_i);
      @(negedge clk_i);
      $stop;
   end
endmodule
