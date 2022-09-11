`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/11/2022 10:54:28 AM
// Design Name: 
// Module Name: mystic_PC_controller
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


module mystic_PC_controller(
      input  wire          clk_i,       
      input  wire          rstn_i,   
      input  wire          is_compressed_i,
      input  wire          is_branch_i,
      input  wire          is_jalr_i,
      input  wire [31:0]   branch_immediate_i,
      input  wire          instr_ready_i,
      input  wire          execute_ready_i,
      output reg  [31:0]   PC_o,
      output reg  [31:0]   PC_next_o,
      output reg           PC_read_o
   );

   reg [3:0] state;
   localparam S_INIT       = 0;
   localparam S_IDLE       = 1;
   localparam S_WAIT       = 2;

   // reg  [31:0]   PC_next;
   reg  [31:0]   PC_current;

   always @(posedge clk_i , negedge rstn_i) begin
      if (!rstn_i) begin
         PC_o  <= 32'h0000_0000;
         PC_read_o   <= 1'b0;
         PC_next_o  <= 32'h0000_0000;
         state <= S_INIT;
      end else begin
         PC_read_o   <= 1'b0;
         case(state) 
            S_INIT: begin
               PC_o        <= 32'h0000_0000;
               PC_read_o   <= 1'b1;
               state       <= S_IDLE;
            end

            S_IDLE: begin
               if (instr_ready_i) begin
                  state <= S_WAIT;
                  if (is_compressed_i) begin
                     PC_next_o  <= PC_o + 2;
                  end else begin
                     PC_next_o  <= PC_o + 4;
                  end
               end
            end

            S_WAIT: begin
               if (execute_ready_i) begin
                  if (is_branch_i) begin
                     PC_o        <= PC_o + branch_immediate_i;
                  end else if (is_jalr_i) begin 
                     PC_o        <= branch_immediate_i;
                  end else begin
                     PC_o        <= PC_next_o;
                  end
                  PC_read_o   <= 1'b1;
                  state       <= S_IDLE;
               end
            end
         endcase
      end
   end
endmodule
