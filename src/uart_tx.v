`timescale 1ns / 1ps

module uart_tx (
   input  wire          clk_i,
   input  wire          rstn_i,
   input  wire  [7:0]   din_i,
   input  wire  [15:0]  baud_div, // clkfreq/baudrate as input
   input  wire          tx_start_i,
   output reg           tx_o,
   output reg           tx_done_tick_o
);

   parameter S_IDLE    = 2'b00;
   parameter S_START   = 2'b01;
   parameter S_DATA    = 2'b10;
   parameter S_STOP    = 2'b11;

   reg [1:0]    state = 0;

   integer bittimer = 0;
   integer bitcntr = 0;
   reg [7:0] shreg = 0;


   always @(posedge clk_i, negedge rstn_i) begin
      if (!rstn_i) begin
         state             <= S_IDLE;
         tx_o              <= 1'b1;         // Drive Line High for Idle
         tx_done_tick_o    <= 1'b0;
         bitcntr           <= 0;
         shreg             <= 8'h00;
         bittimer		      <= 0;
      end else begin
         case (state)
               S_IDLE: begin
                  tx_o            <= 1'b1;         // Drive Line High for Idle
                  tx_done_tick_o  <= 1'b0;
                  bitcntr         <= 0;

                  if (tx_start_i  == 1'b1) begin
                     tx_o        <= 1'b0;
                     shreg	    <= din_i;
                     state       <= S_START;
                  end else begin
                     state       <= S_IDLE;
                  end
               end // case: S_IDLE


               // Send out Start Bit. Start bit = 0
               S_START: begin
                  // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
                  if (bittimer == baud_div-1) begin
                     state			    <= S_DATA;
                     tx_o				<= shreg[0];
                     shreg[7]			<= shreg[0];
                     shreg[6:0]	        <= shreg[7:1];
                     bittimer			<= 0;
                  end else begin
                     bittimer			<= bittimer + 1;
                  end
               end // case: S_START

               // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish
               S_DATA: begin
                  if (bitcntr == 7) begin
                     if (bittimer == baud_div-1) begin
                           bitcntr				<= 0;
                           state			    <= S_STOP;
                           tx_o				<= 1;
                           bittimer			<= 0;
                     end else begin
                           bittimer			<= bittimer + 1;
                     end
                  end else begin
                     // Check if we have sent out all bits
                     if (bittimer == baud_div-1) begin
                           shreg[7]			<= shreg[0];
                           shreg[6:0]     <= shreg[7:1];
                           tx_o				<= shreg[0];
                           bitcntr        <= bitcntr + 1;
                           bittimer			<= 0;
                     end else begin
                           bittimer			<= bittimer + 1;
                     end
                  end
               end // case: S_DATA

               // Send out Stop bit.  Stop bit = 1
               S_STOP  :
               begin
                  // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                  if (bittimer == baud_div-1) begin // stop bit 1 olarak aldım // parameter c_stopbitlim = (c_clkfreq/c_baudrate)*c_stopbit; c_stopbit=baud_div=1
                     state			    <= S_IDLE;
                     tx_done_tick_o		<= 1;
                     bittimer			<= 0;
                  end else begin
                     bittimer			<= bittimer + 1;
                  end
               end // case: s_Tx_STOP_BIT

               default: begin
                  state <= S_IDLE;
               end
         endcase
      end

   end

endmodule
