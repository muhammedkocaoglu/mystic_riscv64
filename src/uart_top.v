`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Muhammed KOCAOGLU
// 
// Create Date: 06/24/2022 01:15:46 AM
// Design Name: 
// Module Name: uart_top
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


module uart_top(
   input  wire          clk_i,
   input  wire          rstn_i,
   input  wire          uart_rx_i,
   output wire          uart_tx_o,
   input  wire          uart_enable_i,
   input  wire          uart_read_i,
   input  wire   [31:0] uart_addr_i,
   input  wire   [31:0] uart_din_i,
   output reg    [31:0] uart_dout_o,
   output reg           uart_ready_o
);

localparam   [31:0]  UART_KONTROL_YAZMACI_ADDR     = 32'h4000_0000;  // uart kontrol yazmaci address
localparam   [31:0]  UART_DURUM_YAZMACI_ADDR       = 32'h4000_0004;  // uart durum yazmaci address
localparam   [31:0]  UART_VERI_OKUMA_YAZMACI_ADDR  = 32'h4000_0008;
localparam   [31:0]  UART_VERI_YAZMA_YAZMACI_ADDR  = 32'h4000_000c;

reg [6:0] state;
parameter S_IDLE           = 7'b0000001;
parameter S_UART_CTRL      = 7'b0000010;
parameter S_UART_STATUS    = 7'b0000100;
parameter S_UART_RDATA     = 7'b0001000;
parameter S_UART_WDATA     = 7'b0010000;
parameter S_UART_CTRL_RD   = 7'b0100000;
parameter S_UART_DELAY     = 7'b1000000;


// uart rx
reg   [15:0]      baud_div;
reg               UART_Kontrol_Yazmaci_rx_Active;
wire              UART_Durum_Yazmaci_rx_full;    // indicates that fifo is full   
wire              UART_Durum_Yazmaci_rx_empty;   // indicates that fifo is empty
wire  [7:0]       UART_Veri_Okuma_Yazmaci_rdata; // is read when the related address is true
reg               UART_Veri_Okuma_Yazmaci_enable;
wire              UART_Veri_Okundu;

// uart tx
reg               UART_Kontrol_Yazmaci_tx_Active; // tx active when UART_Kontrol_Yazmaci_tx = 1 else do not send data to outside world
reg               UART_Veri_Yazma_Yazmaci_enable; // write enable  ilgili adres master taraindan gelince enable 1 oluyor ve veri buffer a yaziliyor
reg   [7:0]       UART_Veri_Yazma_Yazmaci_wdata; // fifo icine yazilacak olan veriler. UART_Kontrol_Yazmaci_tx_Active avtif oldugunda fifo icinden disari gidecek olan veri ayni zamanda
wire              UART_Durum_Yazmaci_tx_full;    // indicates that fifo is full
wire              UART_Durum_Yazmaci_tx_empty;     // indicates that fifo is empty

reg  [31:0]       cntr;


//wire [3:0] uart_state;

// assign uart_state = 

always @(posedge clk_i, negedge rstn_i) begin
   if (!rstn_i) begin
      state    <= S_IDLE;
      cntr     <= 0;
      uart_dout_o <= 32'h0000_0000;
   end else begin
      uart_ready_o   <= 1'b0;
      UART_Veri_Okuma_Yazmaci_enable   <= 1'b0;
      UART_Veri_Yazma_Yazmaci_enable   <= 1'b0;
      case(state)
         S_IDLE: begin
            if (uart_enable_i) begin
               case (uart_addr_i) 
                    UART_KONTROL_YAZMACI_ADDR: begin
                        if (uart_read_i) begin
                            state <= S_UART_CTRL_RD;
                        end else begin
                            state    <= S_UART_CTRL;
                            baud_div <= uart_din_i[31:16];
                            UART_Kontrol_Yazmaci_tx_Active   <= uart_din_i[0];
                            UART_Kontrol_Yazmaci_rx_Active   <= uart_din_i[1];
                        end
                    end
                    
                    UART_DURUM_YAZMACI_ADDR: begin
                        state    <= S_UART_STATUS;
                        cntr     <= 0;
                    end

                    UART_VERI_OKUMA_YAZMACI_ADDR: begin
                        state    <= S_UART_RDATA;
                        UART_Veri_Okuma_Yazmaci_enable   <= 1'b1;
                    end

                    UART_VERI_YAZMA_YAZMACI_ADDR: begin
                        state    <= S_UART_WDATA;
                    end
               endcase
            end
         end

         S_UART_CTRL_RD: begin
            uart_dout_o[0]       <= UART_Kontrol_Yazmaci_tx_Active;
            uart_dout_o[1]       <= UART_Kontrol_Yazmaci_rx_Active;
            uart_dout_o[15:2]    <= 0;
            uart_dout_o[31:16]   <= baud_div;
            uart_ready_o         <= 1'b1;
            state                <= S_IDLE;
         end

         S_UART_CTRL: begin
            uart_ready_o   <= 1'b1;
            state          <= S_IDLE;
         end

         S_UART_STATUS: begin
            uart_ready_o   <= 1'b1;
            uart_dout_o    <= {{28{1'b0}},   UART_Durum_Yazmaci_rx_empty, 
                                             UART_Durum_Yazmaci_tx_empty,
                                             UART_Durum_Yazmaci_rx_full, 
                                             UART_Durum_Yazmaci_tx_full};
            state          <= S_IDLE;
         end

         S_UART_RDATA: begin
            if (UART_Veri_Okundu) begin
               uart_dout_o    <= {{24{1'b0}}, UART_Veri_Okuma_Yazmaci_rdata};
               uart_ready_o   <= 1'b1;
               state          <= S_IDLE;
            end
         end

         S_UART_WDATA: begin
            UART_Veri_Yazma_Yazmaci_enable   <= 1'b1;
            UART_Veri_Yazma_Yazmaci_wdata    <= uart_din_i[7:0];
            uart_ready_o   <= 1'b1;
            //state          <= S_UART_DELAY;
            state          <= S_IDLE;
         end

         S_UART_DELAY: begin
            if (cntr == 2) begin
               
                if (UART_Durum_Yazmaci_tx_full) begin
                    cntr  <= 2;
                end else begin
                    cntr  <= 0;
                    uart_ready_o   <= 1'b1;
                    state          <= S_IDLE;
                end
            end else begin
               cntr  <= cntr + 1;
            end
         end

         default: begin
            state <= S_IDLE; 
         end   
      endcase
   end
end


uart_rx_top uart_rx_top_inst (
   .clk_i                              (clk_i                           ),
   .rstn_i                             (rstn_i                          ),
   .UART_Kontrol_Yazmaci_rx_Active     (UART_Kontrol_Yazmaci_rx_Active  ), // rx active when UART_Kontrol_Yazmaci_rx = 1 else discard the incoming serial data
   .UART_Veri_Okuma_Yazmaci_enable     (UART_Veri_Okuma_Yazmaci_enable  ),      // read enable  ilgili adres master taraindan gelince enable 1 oluyor ve veri okunuyor
   .uart_rx_i                          (uart_rx_i                       ),  // serial data in
   .baud_div                           (baud_div                        ),   // clkfreq/baudrate as input
   .UART_Durum_Yazmaci_rx_full         (UART_Durum_Yazmaci_rx_full      ),    // indicates that fifo is full   
   .UART_Durum_Yazmaci_rx_empty        (UART_Durum_Yazmaci_rx_empty     ),     // indicates that fifo is empty
   .UART_Veri_Okuma_Yazmaci_rdata      (UART_Veri_Okuma_Yazmaci_rdata   ), // is read when the related address is true
   .UART_Veri_Okundu                   (UART_Veri_Okundu                )
);

uart_tx_top uart_tx_top_inst (
   .clk_i                              (clk_i                           ),
   .rstn_i                             (rstn_i                          ),
   .UART_Kontrol_Yazmaci_tx_Active     (UART_Kontrol_Yazmaci_tx_Active  ), // tx active when UART_Kontrol_Yazmaci_tx = 1 else do not send data to outside world
   .UART_Veri_Yazma_Yazmaci_enable     (UART_Veri_Yazma_Yazmaci_enable  ), // write enable  ilgili adres master taraindan gelince enable 1 oluyor ve veri buffer a yaziliyor
   .baud_div                           (baud_div                        ), // clkfreq/baudrate as input
   .UART_Veri_Yazma_Yazmaci_wdata      (UART_Veri_Yazma_Yazmaci_wdata   ), // fifo icine yazilacak olan veriler. UART_Kontrol_Yazmaci_tx_Active avtif oldugunda fifo icinden disari gidecek olan veri ayni zamanda
   .UART_Durum_Yazmaci_tx_full         (UART_Durum_Yazmaci_tx_full      ), // indicates that fifo is full
   .UART_Durum_Yazmaci_tx_empty        (UART_Durum_Yazmaci_tx_empty     ), // indicates that fifo is empty
   .uart_tx_o                          (uart_tx_o                       )  // serial data out
   );

endmodule
