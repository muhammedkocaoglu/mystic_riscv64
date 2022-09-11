`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/14/2022 07:53:48 PM
// Design Name:
// Module Name: uart_tx_top
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


module uart_tx_top(
      input  wire           clk_i,
      input  wire           rstn_i,
      input  wire           UART_Kontrol_Yazmaci_tx_Active, // tx active when UART_Kontrol_Yazmaci_tx = 1 else do not send data to outside world
      input  wire           UART_Veri_Yazma_Yazmaci_enable, // write enable  ilgili adres master taraindan gelince enable 1 oluyor ve veri buffer a yaziliyor
      input  wire   [15:0]  baud_div,   // clkfreq/baudrate as input
      input  wire   [7:0]   UART_Veri_Yazma_Yazmaci_wdata, // fifo icine yazilacak olan veriler. UART_Kontrol_Yazmaci_tx_Active avtif oldugunda fifo icinden disari gidecek olan veri ayni zamanda
      output wire           UART_Durum_Yazmaci_tx_full,    // indicates that fifo is full
      output wire           UART_Durum_Yazmaci_tx_empty,     // indicates that fifo is empty
      output wire           uart_tx_o // serial data out
   );

   // fifo signals
   reg   [7:0]    fifo_w_data;
   wire  [7:0]    fifo_r_data;
   reg            fifo_rd;
   reg            fifo_wr;

   // uart transmitter signals
   reg   [7:0]    din_i;
   reg            tx_start_i;
   wire           tx_done_tick_o;

   reg [3:0] state;
   parameter S_IDLE                    = 4'b0001;
   parameter S_UART_TRANSMIT           = 4'b0010;
   parameter S_FIFO_READ               = 4'b0100;
   parameter S_UART_DURUM_YAZMACI      = 4'b1000;
   

   // fifo icerisine veri yazan blok
   always @(posedge clk_i, negedge rstn_i) begin
      if (!rstn_i) begin
         fifo_wr <= 1'b0;
      end else begin
         fifo_wr <= 1'b0;
         if ( UART_Veri_Yazma_Yazmaci_enable && !UART_Durum_Yazmaci_tx_full ) begin // yazma ile ilgili adres gelsin ve fifo full olmasin
            fifo_wr     <= 1'b1;  // bu durumda fifo icine gelen veriyi yaz
            fifo_w_data <= UART_Veri_Yazma_Yazmaci_wdata;
         // fifo yazma aktiflestir, zaten 1 byte veri dogrudan bagli asagida instance da, hemen yazar
         end
      end
   end

   // simdi transmit islemine bakalim... 
   // Ne zaman trasnmit etsin?? 
   // 1. configure edilmis olmali, 
   // kontrol yazmacindaki tx aktif olmali
   always @(posedge clk_i, negedge rstn_i)
   begin
      if (!rstn_i)
      begin
         tx_start_i  <= 1'b0;
         fifo_rd     <= 1'b0;
         state       <= S_IDLE;
      end
      else
      begin
         tx_start_i  <= 1'b0;
         fifo_rd     <= 1'b0;
         case (state)
            S_IDLE: begin
               if ( UART_Kontrol_Yazmaci_tx_Active && !UART_Durum_Yazmaci_tx_empty ) begin
                  fifo_rd     <= 1'b1;
                  din_i       <= fifo_r_data;
                  state       <= S_FIFO_READ;
               end
            end

            S_FIFO_READ: begin
               //din_i       <= fifo_r_data;
               tx_start_i  <= 1'b1;
               state       <= S_UART_TRANSMIT;
            end

            S_UART_TRANSMIT: begin
               if (tx_done_tick_o) begin // gonderim tamamlandi
                  state   <= S_IDLE;
               end
            end

            default: begin
               state   <= S_IDLE;
            end
         endcase
      end
   end

   uart_tx uart_tx_Inst (
      .clk_i            (clk_i                              ),
      .rstn_i           (rstn_i                             ),
      .din_i            (din_i                              ),
      .baud_div         (baud_div                           ), // clkfreq/baudrate as input
      .tx_start_i       (tx_start_i                         ),
      .tx_o             (uart_tx_o                          ),
      .tx_done_tick_o   (tx_done_tick_o                     )
   );

   fifo # (
      .B(8),  // number of bits in a word
      .W(5)   // number of address bits 2**5 = 32
   )
   fifo_uart_rx_Inst (
      .clk                 (clk_i                           ),
      .rstn_i              (rstn_i                          ),
      .rd                  (fifo_rd                         ),
      .wr                  (fifo_wr                         ), 
      .w_data              (fifo_w_data                     ),
      .empty               (UART_Durum_Yazmaci_tx_empty     ),
      .full                (UART_Durum_Yazmaci_tx_full      ),
      .r_data              (fifo_r_data                     )
   );
endmodule
