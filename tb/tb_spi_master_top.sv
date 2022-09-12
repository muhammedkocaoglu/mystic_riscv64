`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/26/2022 11:44:16 AM
// Design Name: 
// Module Name: tb_spi_master_top
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


module tb_spi_master_top(

   );
   logic         clk_i = 1;
   logic         rstn_i = 0;
   logic         spi_enable_i;
   logic  [31:0] spi_addr_i;
   logic  [31:0] spi_din_i;
   logic         spi_cs_o;
   logic         spi_sclk_o;
   logic         spi_mosi_o;
   logic         spi_miso_i;
   logic [ 31:0] spi_dout_o;
   logic         spi_ready_o;

   localparam sck_div = (100_000_000/(2*1_000_000)) - 1;

   spi_master_top spi_master_top_inst (
      .clk_i            (clk_i               ),
      .rstn_i           (rstn_i              ),
      .spi_enable_i     (spi_enable_i        ),
      .spi_addr_i       (spi_addr_i          ),
      .spi_din_i        (spi_din_i           ),
      .spi_cs_o         (spi_cs_o            ),
      .spi_sclk_o       (spi_sclk_o          ),
      .spi_mosi_o       (spi_mosi_o          ),
      .spi_miso_i       (spi_miso_i          ),
      .spi_dout_o       (spi_dout_o          ),
      .spi_ready_o      (spi_ready_o         )
   );

   always #5 clk_i   <= ~clk_i;

   initial begin
      @(negedge clk_i);
      @(negedge clk_i);
      @(negedge clk_i);
      rstn_i   <= 1'b1;
      @(negedge clk_i);
      @(negedge clk_i);
      spi_enable_i      <= 1'b1;
      spi_addr_i        <= 32'h2001_0000;
      spi_din_i[0]      <= 1'b1; 
      spi_din_i[1]      <= 1'b0; 
      spi_din_i[2]      <= 1'b0; 
      spi_din_i[3]      <= 1'b0; 
      spi_din_i[15:4]   <= 12'b0;
      spi_din_i[31:16]  <= sck_div;
      @(negedge clk_i);
      spi_enable_i      <= 1'b0;
      #100;


      @(negedge clk_i);
      spi_addr_i        <= 32'h2001_0010;
      spi_din_i[8:0]    <= 4;
      spi_din_i[9]      <= 1'b1;
      spi_din_i[13:12]  <= 2'b00;
      spi_enable_i      <= 1'b1;
      @(negedge clk_i);
      spi_enable_i      <= 1'b0;
      #60_000;


      @(negedge clk_i);
      spi_addr_i        <= 32'h2001_0010;
      spi_din_i[8:0]    <= 11;
      spi_din_i[9]      <= 1'b1;
      spi_din_i[13:12]  <= 2'b01;
      spi_enable_i      <= 1'b1;
      @(negedge clk_i);
      spi_enable_i      <= 1'b0;
      #100_000;

      repeat (4) begin
         @(negedge clk_i);
         spi_addr_i        <= 32'h2001_000c;
         spi_din_i         <= $urandom();
         spi_enable_i      <= 1'b1;
         @(negedge clk_i);
         spi_enable_i      <= 1'b0;

         @(spi_ready_o == 1'b1);
         #50;
      end
      

      
      @(negedge clk_i);
      spi_addr_i        <= 32'h2001_0010;
      spi_din_i[8:0]    <= 11;
      spi_din_i[9]      <= 1'b1;
      spi_din_i[13:12]  <= 2'b10; // mosi
      spi_enable_i      <= 1'b1;
      @(negedge clk_i);
      spi_enable_i      <= 1'b0;
      


      #100_000;
      $stop;
   end


   logic [7:0] miso_cntr = 0;

   always @(posedge clk_i) begin 
      if (miso_cntr == 42) begin
         miso_cntr   <= 0;
         spi_miso_i  <= $urandom(); // random data, only for simulation purposes 
      end else begin 
         miso_cntr   <= miso_cntr + 1;
      end
   end
endmodule
