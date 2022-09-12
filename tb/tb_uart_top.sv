`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/25/2022 06:52:21 AM
// Design Name: 
// Module Name: tb_uart_top
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


module tb_uart_top(

   );

   logic          clk_i = 1;
   logic          rstn_i;
   logic  [7:0]   din_i;
   logic  [15:0]  baud_div; // clkfreq/baudrate as input
   logic          tx_start_i;
   logic          tx_o;
   logic          tx_done_tick_o;


   logic          uart_rx_i;
   logic          uart_tx_o;
   logic          uart_enable_i;
   logic   [31:0] uart_addr_i;
   logic   [31:0] uart_din_i;
   logic   [31:0] uart_dout_o;
   logic          uart_ready_o;

   uart_top uart_top_inst (
      .clk_i            (clk_i           ),
      .rstn_i           (rstn_i          ),
      .uart_rx_i        (uart_rx_i       ),
      .uart_tx_o        (uart_tx_o       ),
      .uart_enable_i    (uart_enable_i   ),
      .uart_addr_i      (uart_addr_i     ),
      .uart_din_i       (uart_din_i      ),
      .uart_dout_o      (uart_dout_o     ),
      .uart_ready_o     (uart_ready_o    )
   );

   assign uart_rx_i = tx_o;
   assign baud_div = 99;
   // div = 100_000_000/115200-1 = 867d = 363h = 0011_01110_0011b
   // div = 100_000_000/1_000_000-1 = 99d

   always #5 clk_i <= ~clk_i;

   initial begin
      rstn_i   <= 1'b0;
      @(posedge clk_i);
      @(negedge clk_i);
      @(negedge clk_i);
      rstn_i   <= 1'b1;
      @(negedge clk_i);
      @(negedge clk_i);
      uart_enable_i        <= 1'b1;
      uart_addr_i          <= 32'h2000_0000;
      uart_din_i[0]        <= 1'b1;
      uart_din_i[1]        <= 1'b1;
      uart_din_i[15:2]     <= 0;
      uart_din_i[31:16]    <= baud_div;
      @(negedge clk_i);
      uart_enable_i  <= 1'b0;
      #10_000;
      @(negedge clk_i);
      uart_enable_i        <= 1'b1;
      uart_addr_i          <= 32'h2000_0004;
      @(negedge clk_i);
      uart_enable_i        <= 1'b0;

      #10_000;
      @(negedge clk_i);
      uart_enable_i        <= 1'b1;
      uart_addr_i          <= 32'h2000_0004;
      @(negedge clk_i);
      uart_enable_i        <= 1'b0;

      #10_000_000;

      #10_000;
      @(negedge clk_i);
      uart_enable_i        <= 1'b1;
      uart_addr_i          <= 32'h2000_0008;
      @(negedge clk_i);
      uart_enable_i        <= 1'b0;

      #10_000;
      @(negedge clk_i);
      uart_enable_i        <= 1'b1;
      uart_addr_i          <= 32'h2000_0008;
      @(negedge clk_i);
      uart_enable_i        <= 1'b0;

      #10_000;
      @(negedge clk_i);
      uart_enable_i        <= 1'b1;
      uart_addr_i          <= 32'h2000_0008;
      @(negedge clk_i);
      uart_enable_i        <= 1'b0;

      #10_000;
      @(negedge clk_i);
      uart_enable_i        <= 1'b1;
      uart_addr_i          <= 32'h2000_000c;
      uart_din_i           <= 8'ha4;
      @(negedge clk_i);
      uart_enable_i        <= 1'b0;

      #100_000;
      $stop;
   end

   logic [31:0] cntr = 0;
   always @(posedge clk_i) begin
      tx_start_i  <= 1'b0;
      if (cntr == 10_000) begin
         cntr        <= 0;
         din_i       <= $urandom();
         tx_start_i  <= 1'b1;
      end else begin
         cntr        <= cntr + 1;
      end
   end

   uart_tx uart_tx_inst (
      .clk_i              (clk_i              ),
      .rstn_i             (rstn_i             ),
      .din_i              (din_i              ),
      .baud_div           (baud_div           ), // clkfreq/baudrate as input
      .tx_start_i         (tx_start_i         ),
      .tx_o               (tx_o               ),
      .tx_done_tick_o     (tx_done_tick_o     )
   );
endmodule
