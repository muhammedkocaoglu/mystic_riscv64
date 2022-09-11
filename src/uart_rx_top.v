`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/13/2022 02:48:07 PM
// Design Name:
// Module Name: uart_rx_top
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


module uart_rx_top(
      input  wire             clk_i,
      input  wire             rstn_i,
      input  wire             UART_Kontrol_Yazmaci_rx_Active, // rx active when UART_Kontrol_Yazmaci_rx = 1 else discard the incoming serial data
      input  wire             UART_Veri_Okuma_Yazmaci_enable, // read enable  ilgili adres master taraindan gelince enable 1 oluyor ve veri okunuyor
      input  wire             uart_rx_i,  // serial data in
      input  wire   [15:0]    baud_div,   // clkfreq/baudrate as input
      output wire             UART_Durum_Yazmaci_rx_full,    // indicates that fifo is full   
      output wire             UART_Durum_Yazmaci_rx_empty,     // indicates that fifo is empty
      output reg     [7:0]    UART_Veri_Okuma_Yazmaci_rdata, // is read when the related address is true
      output reg              UART_Veri_Okundu
   );

   // fifo signals
   reg   [7:0] fifo_w_data;
   wire  [7:0] fifo_r_data;
   reg         fifo_rd;
   reg         fifo_wr;

   wire        rx_done_tick_o;  // 
   wire  [7:0] wire_uart_rx_dout_o;
   reg   [7:0] cntr;

   reg [3:0] state;
   parameter S_IDLE        = 4'b0001;
   parameter S_FIFO_WRITE  = 4'b0010;
   parameter S_FIFO_READ   = 4'b0100;

   always @(posedge clk_i, negedge rstn_i) begin
      if (!rstn_i) begin
         fifo_wr           <= 1'b0;
         fifo_w_data       <= 8'h00;
         cntr              <= 8'h00;
         fifo_rd           <= 1'b0;
         state             <= S_IDLE;
      end else begin
         
         // herhangi bir zamanda veri gelirse fifo icine yazsın mı????, bunun icin enable olması gerekiyor mu sor?????
         fifo_wr <= 1'b0;
         if (rx_done_tick_o && !UART_Durum_Yazmaci_rx_full && UART_Kontrol_Yazmaci_rx_Active) begin // fifo dolu olmamadı onemli, yoksa fifo yapsı yanlis calisiyor
            fifo_wr         <= 1'b1; // fifoya yazmayi aktiflestir
            fifo_w_data     <= wire_uart_rx_dout_o; // gelen veriyi disari basma, fifoya doldur
         end

         fifo_rd           <= 1'b0;
         UART_Veri_Okundu  <= 1'b0;
         case (state) 
            S_IDLE: begin
               if (UART_Veri_Okuma_Yazmaci_enable && !UART_Durum_Yazmaci_rx_empty) begin // bos olmamasına dikkat et, bos ise okuyacagin veri yok cunku
                  fifo_rd     <= 1'b1;
                  UART_Veri_Okuma_Yazmaci_rdata  <= fifo_r_data;
                  state       <= S_FIFO_READ;
                  cntr        <= 0;
               end
            end

            S_FIFO_READ: begin
              // if (cntr == 1) begin
               //   UART_Veri_Okuma_Yazmaci_rdata  <= fifo_r_data;
               UART_Veri_Okundu  <= 1'b1;
               state    <= S_IDLE;
               //end else begin 
               //   cntr  <= cntr + 1;
               //end
            end
         endcase
      end
   end 

   uart_rx uart_rx_Inst (
      .clk_i          (clk_i                          ),
      .rstn_i         (rstn_i                         ),
      .rx_i           (uart_rx_i                      ),
      .baud_div       (baud_div                       ), // clkfreq/baudrate as input
      .dout_o         (wire_uart_rx_dout_o            ),
      .rx_done_tick_o (rx_done_tick_o                 )
   );

   fifo # (
      .B(8),  // number of bits in a word
      .W(5)   // number of address bits 2**5 = 32
   )
   fifo_uart_rx_Inst
   (
      .clk            (clk_i                          ),
      .rstn_i         (rstn_i                         ),
      .rd             (fifo_rd                        ),
      .wr             (fifo_wr                        ),
      .w_data         (fifo_w_data                    ),
      .empty          (UART_Durum_Yazmaci_rx_empty    ),
      .full           (UART_Durum_Yazmaci_rx_full     ),
      .r_data         (fifo_r_data                    )
   );
endmodule
