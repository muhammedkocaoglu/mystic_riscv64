`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/25/2022 06:45:59 AM
// Design Name: 
// Module Name: tb_uart_tx_top
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


module tb_uart_tx_top(

   );
   
   logic           clk_i = 1;
   logic           rstn_i;
   logic           UART_Kontrol_Yazmaci_tx_Active; // tx active when UART_Kontrol_Yazmaci_tx = 1 else do not send data to outside world
   logic           UART_Veri_Yazma_Yazmaci_enable; // write enable  ilgili adres master taraindan gelince enable 1 oluyor ve veri buffer a yaziliyor
   logic   [15:0]  baud_div;   // clkfreq/baudrate as input
   logic   [7:0]   UART_Veri_Yazma_Yazmaci_wdata; // fifo icine yazilacak olan veriler. UART_Kontrol_Yazmaci_tx_Active avtif oldugunda fifo icinden disari gidecek olan veri ayni zamanda
   logic           UART_Durum_Yazmaci_tx_full;    // indicates that fifo is full
   logic           UART_Durum_Yazmaci_tx_empty;     // indicates that fifo is empty
   logic           uart_tx_o; // serial data out

   uart_tx_top uart_tx_top_inst (
      .clk_i                            (clk_i                            ),
      .rstn_i                           (rstn_i                           ),
      .UART_Kontrol_Yazmaci_tx_Active   (UART_Kontrol_Yazmaci_tx_Active   ),  // tx active when UART_Kontrol_Yazmaci_tx = 1 else do not send data to outside world
      .UART_Veri_Yazma_Yazmaci_enable   (UART_Veri_Yazma_Yazmaci_enable   ),  // write enable  ilgili adres master taraindan gelince enable 1 oluyor ve veri buffer a yaziliyor
      .baud_div                         (baud_div                         ),  // clkfreq/baudrate as input
      .UART_Veri_Yazma_Yazmaci_wdata    (UART_Veri_Yazma_Yazmaci_wdata    ),  // fifo icine yazilacak olan veriler. UART_Kontrol_Yazmaci_tx_Active avtif oldugunda fifo icinden disari gidecek olan veri ayni zamanda
      .UART_Durum_Yazmaci_tx_full       (UART_Durum_Yazmaci_tx_full       ),  // indicates that fifo is full
      .UART_Durum_Yazmaci_tx_empty      (UART_Durum_Yazmaci_tx_empty      ),  // indicates that fifo is empty
      .uart_tx_o                        (uart_tx_o                        )   // serial data out
   );

   always #5 clk_i <= ~clk_i;

   initial begin
      rstn_i   <= 1'b0;
      @(posedge clk_i);
      @(negedge clk_i);
      @(negedge clk_i);
      rstn_i   <= 1'b1;
   end
endmodule
