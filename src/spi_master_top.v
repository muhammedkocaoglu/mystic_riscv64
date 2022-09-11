`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/20/2022 11:08:19 AM
// Design Name: 
// Module Name: spi_master_top
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


module spi_master_top(
      input  wire         clk_i,
      input  wire         rstn_i,
      input  wire         spi_enable_i,
      input  wire  [31:0] spi_addr_i,
      input  wire  [31:0] spi_din_i,
      output wire         spi_cs_o,
      output wire         spi_sclk_o,
      output wire         spi_mosi_o,
      input  wire         spi_miso_i,
      output reg   [31:0] spi_dout_o,
      output reg          spi_ready_o
   );

   // mosi fifo signals
   localparam FIFO_B = 32; // 32 bits
   localparam FIFO_W = 3;  // 2^3 = 8 data
   reg                  mosi_fifo_rd;
   reg                  mosi_fifo_wr;
   reg  [FIFO_B-1:0]    mosi_fifo_w_data;
   wire                 mosi_fifo_empty;
   wire                 mosi_fifo_full;
   wire [FIFO_B-1:0]    mosi_fifo_r_data;

   // miso fifo signals
   reg                  miso_fifo_rd;
   reg                  miso_fifo_wr;
   reg  [FIFO_B-1:0]    miso_fifo_w_data;
   wire                 miso_fifo_empty;
   wire                 miso_fifo_full;
   wire [FIFO_B-1:0]    miso_fifo_r_data;

   reg                  spi_ctrl_enable;
   reg                  spi_rst;
   reg                  cpol_i;
   reg                  cpha_i;
   reg                  en_i;
   reg  [26:0]          clkdiv_i;
   reg  [7:0]           mosi_data_i;
   wire [7:0]           miso_data_o;
   wire                 data_ready_o;

   reg [4:0] state;
   localparam S_IDLE       = 5'b00001;
   localparam S_SPI_CMD    = 5'b00010;
   localparam S_MISO_RX    = 5'b00100;
   localparam S_MOSI_TX    = 5'b01000;
   localparam S_EMPTY_LOOP = 5'b10000;


   reg   [8:0]    spi_cmd_length;
   reg   [8:0]    spi_cmd_cntr;
   reg   [8:0]    spi_cmd_cntr_prev;
   reg   [31:0]   spi_cmd_buffer;
   reg   [1:0]    spi_cmd_direction;
   reg            spi_cmd_cs_active;

   reg            error_occured;
   reg            spi_once;


   always @(posedge clk_i, negedge rstn_i) begin
      if (!rstn_i) begin
         spi_ctrl_enable         <= 1'b0;
         spi_rst                 <= 1'b0;
         cpha_i                  <= 1'b0;
         cpol_i                  <= 1'b0;
         spi_cmd_length          <= {9{1'b0}};
         spi_cmd_direction       <= 2'b00;
         spi_cmd_cs_active       <= 1'b0;
         clkdiv_i                <= {16{1'b0}};
         state                   <= S_IDLE;
      end else begin
         spi_ready_o    <= 1'b0;
         mosi_fifo_rd   <= 1'b0;
         mosi_fifo_wr   <= 1'b0;
         error_occured  <= 1'b0;
         miso_fifo_wr   <= 1'b0;
         miso_fifo_rd   <= 1'b0;
         //en_i           <= 1'b0;

         if (spi_enable_i && spi_addr_i == 32'h2001_0000) begin
            spi_ctrl_enable   <= spi_din_i[0];
            spi_rst           <= spi_din_i[1];
            cpha_i            <= spi_din_i[2];
            cpol_i            <= spi_din_i[3];
            clkdiv_i          <= spi_din_i[31:16];
            spi_ready_o       <= 1'b1;
         end

         if ((spi_enable_i == 1'b1) && (spi_addr_i == 32'h2001_0004)) begin
            spi_ready_o <= 1'b1;
            //if (spi_ctrl_enable == 1'b1) begin
               spi_dout_o  <= {{28{1'b0}},   mosi_fifo_empty, 
               mosi_fifo_empty, miso_fifo_full, mosi_fifo_full};
            //end
         end

         // read from miso buffer
         if ((spi_enable_i == 1'b1) && (spi_addr_i == 32'h2001_0008)) begin
            spi_ready_o       <= 1'b1;
            //if (spi_ctrl_enable == 1'b1) begin
               spi_dout_o        <= miso_fifo_r_data;
               miso_fifo_rd      <= 1'b1;
            //end else begin
            //   spi_dout_o        <= 32'hFFFF_FFFF; // cannot read, spi is not enabled yet
            //end
         end

         // write to mosi buffer
         if ((spi_enable_i == 1'b1) && (spi_addr_i == 32'h2001_000c)) begin
            spi_ready_o       <= 1'b1;
            //if (spi_ctrl_enable == 1'b1) begin
               mosi_fifo_wr      <= 1'b1;
               mosi_fifo_w_data  <= spi_din_i;
            //end
         end


         case (state)
            S_IDLE: begin
               spi_cmd_cntr         <= 0;
               spi_cmd_cntr_prev    <= 0;
               spi_once             <= 1'b0;
               if ((spi_enable_i == 1'b1) && (spi_addr_i == 32'h2001_0010)) begin 
                  spi_ready_o    <= 1'b1;
                  if (spi_ctrl_enable == 1'b1) begin
                     state    <= S_SPI_CMD;
                     spi_cmd_direction <= spi_din_i[13:12];
                     spi_cmd_cs_active <= spi_din_i[9];
                     spi_cmd_length    <= spi_din_i[8:0];
                  end
                  
               end
            end

            S_SPI_CMD: begin
               case (spi_cmd_direction) 
                  2'b00: begin
                     state <= S_EMPTY_LOOP;
                     en_i  <= 1'b1;
                  end
                  2'b01: begin
                     state <= S_MISO_RX;
                     en_i  <= 1'b1;
                  end
                  2'b10: begin
                     state          <=  S_MOSI_TX;
                     if (mosi_fifo_empty == 0) begin
                        mosi_fifo_rd   <= 1'b1;
                     end
                     spi_cmd_buffer <= mosi_fifo_r_data;
                  end
                  2'b11: begin
                     state <= S_IDLE;
                     error_occured  <= 1'b1;
                  end
               endcase
            end

            S_EMPTY_LOOP: begin
               mosi_data_i <= 8'hAB; // empty loop, does not matter
               if (data_ready_o) begin
                  en_i           <= 1'b1; 
                  spi_cmd_cntr   <= spi_cmd_cntr + 1;
               end

               if (spi_cmd_cntr == spi_cmd_length) begin
                  state <= S_IDLE;
                  if (spi_cmd_cs_active == 1'b0) begin
                     en_i     <= 1'b0;
                  end
               end
            end

            S_MISO_RX: begin
               if (data_ready_o) begin
                  spi_cmd_cntr   <= spi_cmd_cntr + 1;
                  spi_cmd_buffer <= {spi_cmd_buffer[3*8-1:0], miso_data_o}; // shift left
               end

               spi_cmd_cntr_prev <= spi_cmd_cntr;

               if (spi_cmd_cntr == spi_cmd_length) begin
                  //en_i              <= 1'b0;
                  state             <= S_IDLE;
                  if (!miso_fifo_full) begin
                     miso_fifo_wr      <= 1'b1;
                     spi_cmd_buffer    <= 32'h0000_0000;
                     miso_fifo_w_data  <= spi_cmd_buffer;
                  end
                  if (spi_cmd_cs_active == 1'b0) begin
                     en_i     <= 1'b0;
                  end
               end else if (spi_cmd_cntr[1:0] == 2'b00 && spi_cmd_cntr_prev[1:0] == 2'b11) begin // multiple of 4, multiple write to fifo is prevented
                  if (!miso_fifo_full) begin
                     miso_fifo_wr      <= 1'b1;
                     spi_cmd_buffer    <= 32'h0000_0000;
                     miso_fifo_w_data  <= spi_cmd_buffer;
                  end
               end
            end

            S_MOSI_TX: begin
               
               if (spi_once == 1'b0) begin // start transmission
                  spi_once <= 1'b1;
                  en_i     <= 1'b1;
                  spi_cmd_buffer <= {8'h00, spi_cmd_buffer[4*8-1:1*8]}; // shift right
                  mosi_data_i    <= spi_cmd_buffer[7:0];
                  spi_cmd_cntr   <= spi_cmd_cntr + 1;
               end

               if (data_ready_o) begin
                  spi_cmd_cntr   <= spi_cmd_cntr + 1;
                  mosi_data_i    <= spi_cmd_buffer[7:0];
                  spi_cmd_buffer <= {8'h00, spi_cmd_buffer[4*8-1:1*8]}; // shift right
               end

               spi_cmd_cntr_prev <= spi_cmd_cntr;

               if (spi_cmd_cntr == spi_cmd_length + 1) begin
                  state    <= S_IDLE;
                  spi_once <= 1'b0;
                  if (spi_cmd_cs_active == 1'b0) begin
                     en_i     <= 1'b0;
                  end
               end else if ((spi_cmd_cntr[1:0] == 2'b00) && (spi_cmd_cntr_prev[1:0] == 2'b11)) begin // multiple of 4 
                  if (mosi_fifo_empty == 0) begin
                     mosi_fifo_rd   <= 1'b1;
                  end
                  //spi_once       <= 1'b0;
                  spi_cmd_buffer <= mosi_fifo_r_data;
               end
            end
         endcase
      end
   end

   spi_master spi_master_inst (
      .clk_i          (clk_i           ),
      .rstn_i         (rstn_i          ),
      .en_i           (en_i            ),
      .cpol_i         (cpol_i          ),
      .cpha_i         (cpha_i          ),
      .clkdiv_i       (clkdiv_i        ),
      .mosi_data_i    (mosi_data_i     ),
      .miso_data_o    (miso_data_o     ),
      .data_ready_o   (data_ready_o    ),
      .cs_o           (spi_cs_o        ),
      .sclk_o         (spi_sclk_o      ),
      .mosi_o         (spi_mosi_o      ),
      .miso_i         (spi_miso_i      )
   );  

   fifo # (
      .B(FIFO_B),  // number of bits in a word
      .W(FIFO_W)   // number of address bits 2^3 = 8 tane
   )
   mosi_fifo_inst (
      .clk           (clk_i            ), 
      .rstn_i        (rstn_i           ), 
      .rd            (mosi_fifo_rd     ), 
      .wr            (mosi_fifo_wr     ),
      .w_data        (mosi_fifo_w_data ),
      .empty         (mosi_fifo_empty  ),
      .full          (mosi_fifo_full   ),
      .r_data        (mosi_fifo_r_data )
   );

   fifo # (
      .B(FIFO_B),  // number of bits in a word
      .W(FIFO_W)   // number of address bits 2^3 = 8 tane
   )
   miso_fifo_inst (
      .clk           (clk_i            ), 
      .rstn_i        (rstn_i           ), 
      .rd            (miso_fifo_rd     ), 
      .wr            (miso_fifo_wr     ),
      .w_data        (miso_fifo_w_data ),
      .empty         (miso_fifo_empty  ),
      .full          (miso_fifo_full   ),
      .r_data        (miso_fifo_r_data )
   );
endmodule
