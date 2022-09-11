`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2022 09:20:40 PM
// Design Name: 
// Module Name: tb_top
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


module tb_top(

    );

    logic  [7:0]   din_i;
    logic          tx_start_i;
    logic          tx_done_tick_o;
    
    logic [31:0] PC_current_i;
    logic execute_ready_o;

    logic         clk_i = 1;
    logic         rst_ni;
    logic         program_rx_i;
    logic         prog_mode_led_o;
 
    logic         uart_tx_o;
    logic         uart_rx_i;
 
    logic         spi_cs_o;
    logic         spi_sck_o;
    logic         spi_mosi_o;
    logic         spi_miso_i;

 
    logic         iomem_valid;
    logic         iomem_ready;
    logic [ 3:0]  iomem_wstrb;
    logic [31:0]  iomem_addr;
   
   
    logic [31:0]  iomem_wdata;
    logic [31:0]  iomem_rdata;

    top top_inst (
      .clk_i               (clk_i             ),
      .rst_ni              (rst_ni            ),
      .program_rx_i        (program_rx_i      ),
      .prog_mode_led_o     (prog_mode_led_o   ),
   
      .uart_tx_o           (uart_tx_o         ),
      .uart_rx_i           (uart_rx_i         ),
   
      .spi_cs_o            (spi_cs_o          ),
      .spi_sck_o           (spi_sck_o         ),
      .spi_mosi_o          (spi_mosi_o        ),
      .spi_miso_i          (spi_miso_i        )
      
   );


   assign PC_current_i = tb_top.top_inst.mystic_soc_inst.mystic_riscv_inst.mystic_main_decoder_inst.PC_current_i;
   assign execute_ready_o = tb_top.top_inst.mystic_soc_inst.mystic_riscv_inst.mystic_main_decoder_inst.execute_ready_o;


    always #10 clk_i   <= ~clk_i;

    logic [7:0] my_queue[$] = {8'hAB, 8'hCD, 8'h12, 8'h34,
    8'h97, 
    8'h11, 
    8'h00, 
    8'h20, 
    8'h93, 
    8'h81, 
    8'h01, 
    8'h80, 
    8'h97, 
    8'h02, 
    8'h01, 
    8'h20, 
    8'h93, 
    8'h82, 
    8'h82, 
    8'hFF,
    8'h13, 
    8'h81, 
    8'h02, 
    8'h00, 
    8'h17, 
    8'h02};

//    initial begin
//     #500_000;
//     @(negedge clk_i);
//     @(negedge clk_i);
//     @(negedge clk_i);

//     // for (int i = 0; i < 25; i++) begin
//     //     my_queue.push_back($urandom());
//     // end

//     @(negedge clk_i);
//     @(negedge clk_i);

//     @(negedge clk_i);
//     @(negedge clk_i);


//     for (int i = 0; i < 8000; i++) begin
//         @(negedge clk_i);
//         tx_start_i  <= 1'b1;
//         din_i   <= my_queue[i];
//         @(negedge clk_i);
//         tx_start_i  <= 1'b0;
//         @(posedge tx_done_tick_o);
//     end


// end
   
   initial begin
      #20;
      @(negedge clk_i);
      @(negedge clk_i);
      rst_ni   <= 1'b0;
      @(negedge clk_i);
      @(negedge clk_i);
      rst_ni   <= 1'b1;

      #1000000000;
      #1000000000;

      $stop;
   end


   uart_tx uart_tx (
    .clk_i          (clk_i),
    .rstn_i         (rst_ni),
    .din_i          (din_i),
    .baud_div       (868), // clkfreq/baudrate as input
    .tx_start_i     (tx_start_i),
    .tx_o           (uart_rx_i),
    .tx_done_tick_o (tx_done_tick_o)
);
endmodule
