`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/06/2022 11:49:57 PM
// Design Name: 
// Module Name: mystic_alu
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
// 00000 add

module mystic_alu(
      input  wire          clk_i,
      input  wire          rstn_i,
      input  wire  [5:0]   alu_opcode_i,
      input  wire          alu_opcode_valid_i,

      input  wire  [63:0]  alu_srcA_i,
      input  wire  [63:0]  alu_srcB_i,
      output reg   [63:0]  alu_result_o,
      output reg           alu_ready_o
   );

   reg [3:0] state;
   localparam S_IDLE    = 0;
   localparam S_EXECUTE = 1;

   reg  [5:0]  alu_opcode_reg;

   reg [3:0] cntr;

   always @(posedge clk_i, negedge rstn_i ) begin
      if (!rstn_i) begin
         state <= S_IDLE;
      end else begin
         alu_ready_o   <= 1'b0;
         case (state)
            S_IDLE: begin
               cntr  <= 4'b0000;
               if (alu_opcode_valid_i) begin
                  state             <= S_EXECUTE;
                  alu_opcode_reg    <= alu_opcode_i;
               end
            end

            S_EXECUTE: begin
               
               
               case (alu_opcode_reg)
                  6'b000000: begin // ADD
                    alu_result_o   <= alu_srcA_i + alu_srcB_i;
                    alu_ready_o    <= 1'b1;
                    state          <= S_IDLE;
                     
                  end 

                  6'b000001:  begin // AND
                     alu_result_o   <= alu_srcA_i & alu_srcB_i;
                     alu_ready_o    <= 1'b1;
                     state          <= S_IDLE;
                  end 

                  6'b000010:   begin // OR
                     alu_result_o   <= alu_srcA_i | alu_srcB_i;
                     alu_ready_o    <= 1'b1;
                     state          <= S_IDLE;
                  end

                  6'b000011: begin // SLL
                     alu_result_o   <= alu_srcA_i << alu_srcB_i;
                     alu_ready_o    <= 1'b1;
                     state          <= S_IDLE;
                  end

                  6'b000100: begin // SRA
                     alu_result_o   <= alu_srcA_i >>> alu_srcB_i;
                     alu_ready_o    <= 1'b1;
                     state          <= S_IDLE;
                  end

                  6'b000101: begin // SRL
                     alu_result_o   <= alu_srcA_i >> alu_srcB_i;
                     alu_ready_o    <= 1'b1;
                     state          <= S_IDLE;
                  end

                  6'b000110: begin // XOR
                     alu_result_o   <= alu_srcA_i ^ alu_srcB_i;
                     alu_ready_o    <= 1'b1;
                     state          <= S_IDLE;
                  end

                  6'b000111: begin // SUB
                     alu_result_o   <= alu_srcA_i - alu_srcB_i;
                     alu_ready_o    <= 1'b1;
                     state          <= S_IDLE;
                  end

                  default: begin // 
                     state    <= S_IDLE;
                  end
               endcase
            end

         endcase
      end
   end
     

endmodule
