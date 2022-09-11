`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Muhammed KOCAOGLU
// E-mail: mdkocaoglu@gmail.com
// 
// Create Date: 06/22/2022 08:21:24 AM
// Design Name: 
// Module Name: mystic_multiplier
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


module mystic_multiplier(
   input  wire             clk_i,
   input  wire             rstn_i,
   input  wire             mult_is_left_signed_i,
   input  wire             mult_is_right_signed_i,
   input  wire             mult_enable_i,
   input  wire   [63:0]    mult_data_left_i,
   input  wire   [63:0]    mult_data_right_i,
   output wire   [63:0]    mult_result_upper_o,
   output wire   [63:0]    mult_result_lower_o,
   output reg              mult_ready_o
);

reg [7:0] cntr;

reg [127:0] ADVAL;

reg [4:0] state;
localparam S_IDLE  = 5'b00001;
localparam S_DELAY = 5'b00010;
localparam S_MULT  = 5'b00100;
localparam S_DONE  = 5'b01000;

reg   [127:0] mult_result_reg;
reg   [127:0] mult_result_int;
reg   [63:0]  mult_data_left_reg;
reg   [63:0]  mult_data_right_reg;
reg   [1:0]   mul_polarity;

always @(posedge clk_i, negedge rstn_i) begin
   if (!rstn_i) begin
      state <= S_IDLE;
   end else begin 
      mult_ready_o      <= 1'b0;
      case (state)
         S_IDLE: begin
            mul_polarity    <= 2'b00;
            if (mult_enable_i) begin
               state           <= S_DELAY;
               cntr            <= 0;
               mult_result_reg <= 0;

               mult_data_left_reg      <= mult_data_left_i;
               mult_data_right_reg     <= mult_data_right_i;

               if (mult_is_left_signed_i) begin
                  if (mult_data_left_i[63]) begin
                     mult_data_left_reg      <= $unsigned(-mult_data_left_i);
                     mul_polarity[0]         <= 1'b1;                                    
                  end
               end
               
               if (mult_is_right_signed_i) begin 
                  if (mult_data_right_i[63]) begin
                     mult_data_right_reg     <= $unsigned(-mult_data_right_i);
                     mul_polarity[1]         <= 1'b1;                                    
                  end
               end
            end
         end 

         S_DELAY: begin
            ADVAL   <= {{64{1'b0}}, mult_data_right_reg};
            state   <= S_MULT;
         end

         S_MULT: begin
            if (cntr < 64) begin
               if (mult_data_left_reg[cntr]) begin
                  mult_result_reg <= mult_result_reg + ADVAL;
               end
               ADVAL   <= {ADVAL[126:0], 1'b0}; // shift left
               cntr    <= cntr + 1;
            end else begin 
               state   <= S_DONE;
            end
         end

         S_DONE: begin
            mult_ready_o    <= 1'b1;
            state           <= S_IDLE;
            case (mul_polarity)
               2'b00: mult_result_int   <= mult_result_reg;
               2'b01: mult_result_int   <= $unsigned(-mult_result_reg);
               2'b10: mult_result_int   <= $unsigned(-mult_result_reg);
               2'b11: mult_result_int   <= mult_result_reg;
            endcase
         end

         default: begin
            state <= S_IDLE;
         end
      endcase
   end
end

assign mult_result_upper_o = mult_result_int[127:64];
assign mult_result_lower_o = mult_result_int[63:0];

endmodule