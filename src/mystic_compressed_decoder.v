`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/20/2022 07:54:20 PM
// Design Name: 
// Module Name: mystic_compressed_decoder
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


module mystic_compressed_decoder(
      input  wire          clk_i,
      input  wire          rstn_i,
      input  wire          is_compressed_i,
      input  wire          instr_ready_i,
      input  wire [31:0]   instr_i,
      output reg  [31:0]   instr_decompressed_o,
      output reg           instr_decompressed_ready_o
   );

   localparam OPCODE_LOAD     = 7'h03;
   localparam OPCODE_OP_IMM   = 7'h13;
   localparam OPCODE_STORE    = 7'h23;
   localparam OPCODE_OP       = 7'h33;
   localparam OPCODE_LUI      = 7'h37;
   localparam OPCODE_BRANCH   = 7'h63;
   localparam OPCODE_JALR     = 7'h67;
   localparam OPCODE_JAL      = 7'h6f;

   
   localparam S_C_LW          = 16'b010_???_???_??_???_00; // 01 - ibex
   localparam S_C_LD          = 16'b011_???_???_??_???_00; // 02 - 
   localparam S_C_SW          = 16'b110_???_???_??_???_00; // 03 - ibex
   localparam S_C_SD          = 16'b111_???_???_??_???_00; // 04 - 
   localparam S_C_NOP         = 16'b000_?_00000_??_???_01; // 05 - ibex
   localparam S_C_ADDI        = 16'b000_?_?????_??_???_01; // 06 - ibex
   localparam S_C_ADDIW       = 16'b001_?_?????_??_???_01; // 07 - 
   localparam S_C_LI          = 16'b010_?_?????_??_???_01; // 08 - ibex
   localparam S_C_ADDI16SP    = 16'b011_?_00010_??_???_01; // 09 - ibex
   localparam S_C_LUI         = 16'b011_?_?????_??_???_01; // 10 - ibex
   localparam S_C_SRLI        = 16'b100_?_00_???_?????_01; // 11 - ibex
   localparam S_C_SRAI        = 16'b100_?_01_???_?????_01; // 12 - ibex
   localparam S_C_ANDI        = 16'b100_?_10_???_?????_01; // 13 - ibex
   localparam S_C_SUB         = 16'b100_011_???_00_???_01; // 14 - ibex
   localparam S_C_XOR         = 16'b100_011_???_01_???_01; // 15 - ibex
   localparam S_C_OR          = 16'b100_011_???_10_???_01; // 16 - ibex
   localparam S_C_AND         = 16'b100_011_???_11_???_01; // 17 - ibex
   localparam S_C_SUBW        = 16'b100_111_???_00_???_01; // 18 - 
   localparam S_C_ADDW        = 16'b100_111_???_01_???_01; // 19 - 
   localparam S_C_J           = 16'b101_???_???_??_???_01; // 20 - ibex
   localparam S_C_BEQZ        = 16'b110_???_???_??_???_01; // 21 - ibex
   localparam S_C_BNEZ        = 16'b111_???_???_??_???_01; // 22 - ibex
   localparam S_C_SLLI        = 16'b000_?_?????_??_???_10; // 23 - ibex
   localparam S_C_LWSP        = 16'b010_?_?????_??_???_10; // 24 - ibex
   localparam S_C_LDSP        = 16'b011_?_?????_??_???_10; // 25 - -----
   localparam S_C_JR          = 16'b100_0_?????_00_000_10; // 26 - ibex
   localparam S_C_JALR        = 16'b100_1_?????_00_000_10; // 27 - ibex
   localparam S_C_MV          = 16'b100_0_?????_??_???_10; // 28 - ibex
   localparam S_C_ADD         = 16'b100_1_?????_??_???_10; // 29 - ibex
   localparam S_C_SWSP        = 16'b110_?_?????_??_???_10; // 30 - ibex
   localparam S_C_SDSP        = 16'b111_?_?????_??_???_10; // 31 - -----
   localparam S_C_ADDI4SPN    = 16'b000_???_???_??_???_00; // 32 - ibex


   reg [39:0]  instr_opcode_debug;


   reg [3:0] state;
   localparam S_IDLE       = 0;
   localparam S_DECODE     = 1;

   reg [3:0]  cntr;
   reg [11:0] instr_offset;
   reg [11:0] instr_immediate;
   reg [4:0]  instr_rd;
   reg [4:0]  instr_rs1;
   reg [4:0]  instr_rs2;

   always @(posedge clk_i, negedge rstn_i) begin
      if (!rstn_i) begin
         state    <= S_IDLE;
      end else begin
         instr_decompressed_ready_o <= 1'b0;
         case (state) 
            S_IDLE: begin
               cntr  <= 0;
               if (instr_ready_i) begin
                  if (is_compressed_i) begin
                     state    <= S_DECODE;
                  end else begin
                     instr_decompressed_o       <= instr_i;
                     instr_decompressed_ready_o <= 1'b1;
                  end
               end
            end

            S_DECODE: begin
               
               casez (instr_i[15:0])
                  S_C_LW: begin
                     instr_opcode_debug   <= 1;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {5'b00000, instr_i[5], instr_i[12:10], instr_i[6],
                       2'b00, 2'b01, instr_i[9:7], 3'b010, 2'b01, instr_i[4:2], {OPCODE_LOAD}};
                  end

                  S_C_LD: begin
                     instr_opcode_debug   <= 2;
                     if (cntr == 0) begin
                        instr_rd       <= {2'b01, instr_i[4:2]};
                        instr_offset   <= {4'b0000, instr_i[6:5], instr_i[12:10], 3'b000};
                        instr_rs1      <= {2'b01, instr_i[9:7]};
                        cntr           <= cntr + 1;
                     end else begin
                        instr_decompressed_o <= {instr_offset, instr_rs1, 3'b011, instr_rd, 7'b0000011};
                        instr_decompressed_ready_o <= 1'b1;
                        state    <= S_IDLE;
                     end
                  end

                  S_C_SW: begin
                     instr_opcode_debug   <= 3;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {5'b0, instr_i[5], instr_i[12], 2'b01, instr_i[4:2],
                       2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6],
                       2'b00, {OPCODE_STORE}};
                  end

                  S_C_SD: begin
                     instr_opcode_debug   <= 4;
                     if (cntr == 0) begin
                        instr_rs2      <= {2'b01, instr_i[4:2]};
                        instr_rs1      <= {2'b01, instr_i[9:7]};
                        instr_offset   <= {4'b0000, instr_i[6:5], instr_i[12:10], 3'b000};
                        cntr           <= cntr + 1;
                     end else begin
                        instr_decompressed_o <= {instr_offset[11:5], instr_rs2, instr_rs1, 3'b011, instr_offset[4:0], 7'b0100011};
                        instr_decompressed_ready_o <= 1'b1;
                        state    <= S_IDLE;
                     end
                  end

                  S_C_NOP: begin
                     instr_opcode_debug   <= 5;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2],
                       instr_i[11:7], 3'b0, instr_i[11:7], {OPCODE_OP_IMM}};
                  end

                  S_C_ADDI: begin
                     instr_opcode_debug   <= 6;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2],
                       instr_i[11:7], 3'b0, instr_i[11:7], {OPCODE_OP_IMM}};
                  end

                  S_C_ADDIW: begin
                     instr_opcode_debug   <= 7;
                     if (cntr == 0) begin
                        instr_rd          <= instr_i[11:7];
                        instr_immediate   <= {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2]};
                        cntr              <= cntr + 1;
                     end else begin
                        instr_decompressed_o <= {instr_immediate, instr_rd, 3'b000, instr_rd, 7'b0011011};
                        instr_decompressed_ready_o <= 1'b1;
                        state    <= S_IDLE;
                     end
                  end

                  S_C_LI: begin // x[rd] = sext(imm)
                     instr_opcode_debug   <= 8;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 5'b0,
                       3'b0, instr_i[11:7], {OPCODE_OP_IMM}};
                  end

                  S_C_ADDI16SP: begin
                     instr_opcode_debug   <= 9;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {{3 {instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2],
                         instr_i[6], 4'b0, 5'h02, 3'b000, 5'h02, {OPCODE_OP_IMM}};
                  end

                  S_C_LUI: begin
                     instr_opcode_debug   <= 10;
                     instr_decompressed_o <= {{15 {instr_i[12]}}, instr_i[6:2], instr_i[11:7], {OPCODE_LUI}};
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                  end

                  S_C_SRLI: begin // +
                     instr_opcode_debug   <= 11;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {1'b0, instr_i[10], 5'b0, instr_i[6:2], 2'b01, instr_i[9:7],
                           3'b101, 2'b01, instr_i[9:7], {OPCODE_OP_IMM}};
                  end

                  S_C_SRAI: begin // +
                     instr_opcode_debug   <= 12;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {1'b0, instr_i[10], 5'b0, instr_i[6:2], 2'b01, instr_i[9:7],
                           3'b101, 2'b01, instr_i[9:7], {OPCODE_OP_IMM}};
                  end

                  S_C_ANDI: begin // +
                     instr_opcode_debug   <= 13;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 2'b01, instr_i[9:7],
                           3'b111, 2'b01, instr_i[9:7], {OPCODE_OP_IMM}};
                  end

                  S_C_SUB: begin // +
                     instr_opcode_debug   <= 14;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {2'b01, 5'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7],
                               3'b000, 2'b01, instr_i[9:7], {OPCODE_OP}};
                  end

                  S_C_XOR: begin // +
                     instr_opcode_debug   <= 15;
                     instr_decompressed_ready_o <= 1'b1;
                     state    <= S_IDLE;
                     instr_decompressed_o <= {7'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b100,
                               2'b01, instr_i[9:7], {OPCODE_OP}};
                  end

                  S_C_OR: begin // + 
                     instr_opcode_debug   <= 16;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {7'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b110,
                     2'b01, instr_i[9:7], {OPCODE_OP}};
                  end

                  S_C_AND: begin // + 
                     instr_opcode_debug   <= 17;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {7'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b111,
                               2'b01, instr_i[9:7], {OPCODE_OP}};
                  end

                  S_C_SUBW: begin // mk
                     instr_opcode_debug   <= 18;
                     if (cntr == 0) begin
                        instr_rd          <= {2'b01, instr_i[9:7]}; 
                        instr_rs2         <= {2'b01, instr_i[4:2]}; 
                        cntr              <= cntr + 1;
                     end else begin
                        instr_decompressed_ready_o <= 1'b1;
                        instr_decompressed_o <= {7'b0100000, instr_rs2, instr_rd, 3'b000, instr_rd, 7'b0111011};
                        instr_decompressed_ready_o <= 1'b1;
                        state    <= S_IDLE;
                     end
                  end

                  S_C_ADDW: begin // mk
                     instr_opcode_debug   <= 19;
                     if (cntr == 0) begin
                        instr_rd          <= {2'b01, instr_i[9:7]}; 
                        instr_rs2         <= {2'b01, instr_i[4:2]}; 
                        cntr              <= cntr + 1;
                     end else begin
                        instr_decompressed_ready_o <= 1'b1;
                        instr_decompressed_o <= {7'b0000000, instr_rs2, instr_rd, 3'b000, instr_rd, 7'b0111011};
                        instr_decompressed_ready_o <= 1'b1;
                        state    <= S_IDLE;
                     end
                  end

                  S_C_J: begin // +
                     instr_opcode_debug   <= 20;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {instr_i[12], instr_i[8], instr_i[10:9], instr_i[6],
                                 instr_i[7], instr_i[2], instr_i[11], instr_i[5:3],
                                 {9 {instr_i[12]}}, 4'b0, ~instr_i[15], {OPCODE_JAL}};
                  end

                  S_C_BEQZ: begin // ibex
                     instr_opcode_debug   <= 21;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {{4 {instr_i[12]}}, instr_i[6:5], instr_i[2], 5'b0, 2'b01,
                                 instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3],
                                 instr_i[12], {OPCODE_BRANCH}};
                  end

                  S_C_BNEZ: begin // +
                     instr_opcode_debug   <= 22;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {{4 {instr_i[12]}}, instr_i[6:5], instr_i[2], 5'b0, 2'b01,
                        instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3],
                        instr_i[12], {OPCODE_BRANCH}};
                  end

                  S_C_SLLI: begin // +
                     instr_opcode_debug   <= 23;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {7'b0, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], {OPCODE_OP_IMM}};
                  end

                  S_C_LWSP: begin
                     instr_opcode_debug   <= 24;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {4'b0, instr_i[3:2], instr_i[12], instr_i[6:4], 2'b00, 5'h02,
                                                3'b010, instr_i[11:7], OPCODE_LOAD};
                  end

                  S_C_LDSP: begin
                     instr_opcode_debug   <= 25;
                     if (cntr == 0) begin
                        instr_rd          <= instr_i[11:7]; 
                        instr_rs1         <= 5'b00010; 
                        instr_offset      <= {3'b000, instr_i[4:2], instr_i[12], instr_i[6:5], 3'b000};
                        cntr              <= cntr + 1;
                     end else begin
                        instr_decompressed_ready_o <= 1'b1;
                        instr_decompressed_o <= {instr_offset, instr_rs1, 3'b011, instr_rd, 7'b0000011};
                        instr_decompressed_ready_o <= 1'b1;
                        state    <= S_IDLE;
                     end
                  end

                  S_C_JR: begin
                     instr_opcode_debug   <= 26;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {12'b0, instr_i[11:7], 3'b0, 5'b0, {OPCODE_JALR}};
                  end

                  S_C_JALR: begin
                     instr_opcode_debug   <= 27;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {12'b0, instr_i[11:7], 3'b000, 5'b00001, {OPCODE_JALR}};
                  end

                  S_C_MV: begin
                     instr_opcode_debug   <= 28;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {7'b0, instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], {OPCODE_OP}};
                  end

                  S_C_ADD: begin
                     instr_opcode_debug   <= 29;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {7'b0, instr_i[6:2], instr_i[11:7], 3'b0, instr_i[11:7], {OPCODE_OP}};
                  end

                  S_C_SWSP: begin
                     instr_opcode_debug   <= 30;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {4'b0, instr_i[8:7], instr_i[12], instr_i[6:2], 5'h02, 3'b010,
                                 instr_i[11:9], 2'b00, {OPCODE_STORE}};
                  end

                  S_C_SDSP: begin
                     instr_opcode_debug   <= 31;
                     if (cntr == 0) begin
                        instr_rs2         <= instr_i[6:2]; 
                        instr_rs1         <= 5'b00010; 
                        instr_offset      <= {3'b000, instr_i[9:7], instr_i[12:10], 3'b000};
                        cntr              <= cntr + 1;
                     end else begin
                        instr_decompressed_ready_o <= 1'b1;
                        instr_decompressed_o <= {instr_offset[11:5], instr_rs2, instr_rs1, 3'b011, instr_offset[4:0], 7'b0100011};
                        instr_decompressed_ready_o <= 1'b1;
                        state    <= S_IDLE;
                     end
                  end

                  S_C_ADDI4SPN: begin
                     instr_opcode_debug   <= 32;
                     instr_decompressed_ready_o <= 1'b1;
                     state <= S_IDLE;
                     instr_decompressed_o <= {2'b0, instr_i[10:7], instr_i[12:11], instr_i[5],
                              instr_i[6], 2'b00, 5'h02, 3'b000, 2'b01, instr_i[4:2], {OPCODE_OP_IMM}};
                  end
               endcase
            end
         endcase
      end
   end
endmodule
