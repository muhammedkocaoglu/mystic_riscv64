`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Muhammed KOCAOĞLU
// E-mail  : mdkocaoglu@gmail.com
// Create Date: 06/07/2022 12:02:19 AM
// Design Name: 
// Module Name: mystic_regfile
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


module mystic_regfile (
   input  wire          clk_i,                     //
   input  wire          rstn_i,                    //
   input  wire  [4:0]   instr_rs1_i,               // Instr[19:15]
   input  wire  [4:0]   instr_rs2_i,               // Instr[24:20]
   input  wire  [4:0]   instr_rd_i,                // Instr[11:7]
   input  wire          regfile_WriteEnable_i,     //
   input  wire  [63:0]  regfile_WriteData_i,       // 
   output reg   [63:0]  regfile_rd1_o,             //
   output reg   [63:0]  regfile_rd2_o              // 
);

    wire  [63:0]  regfile_rd1_reg;             //
    reg   [63:0]  regfile_rd1_reg2;             //
    reg  [63:0]  regfile_rd1_reg3;             // 
    reg  [63:0]  regfile_rd1_reg4;             // 

    wire  [63:0]  regfile_rd2_reg;             //
    reg  [63:0]  regfile_rd2_reg2;             // 
    reg  [63:0]  regfile_rd2_reg3;             // 
    reg  [63:0]  regfile_rd2_reg4;             // 

   reg [63:0] rf[31:0];

   initial begin
      rf[0]  = {64{1'b0}};
      rf[1]  = {64{1'b0}}; // 64'h0000000000000001;
      rf[2]  = {64{1'b0}}; // 64'h0000000000000011;
      rf[3]  = {64{1'b0}}; // 64'h0000000000000111;
      rf[4]  = {64{1'b0}}; // 64'h0000000000001111;
      rf[5]  = {64{1'b0}}; // 64'h0000000040000000;
      rf[6]  = {64{1'b0}}; // 64'h0000000000111111;
      rf[7]  = {64{1'b0}}; // 64'h0000000001111111;
      rf[8]  = {64{1'b0}}; // 64'h0000000011111111;
      rf[9]  = {64{1'b0}}; // 64'h0000000111111111;
      rf[10] = {64{1'b0}}; // 64'h0000001111111111;
      rf[11] = {64{1'b0}}; // 64'h0000011111111111;
      rf[12] = {64{1'b0}}; // 64'h0000111111111111;
      rf[13] = {64{1'b0}}; // 64'h0001111111111111;
      rf[14] = {64{1'b0}}; // 64'h0011111111111111;
      rf[15] = {64{1'b0}}; // 64'h0111111111111111;
      rf[16] = {64{1'b0}}; // 64'h1111111111111111;
      rf[17] = {64{1'b0}}; // 64'h0000000000000002;
      rf[18] = {64{1'b0}}; // 64'h0000000000000022;
      rf[19] = {64{1'b0}}; // 64'h0000000000000222;
      rf[20] = {64{1'b0}}; // 64'h0000000000002222;
      rf[21] = {64{1'b0}}; // 64'h0000000000022222;
      rf[22] = {64{1'b0}}; // 64'h0000000000222222;
      rf[23] = {64{1'b0}}; // 64'h0000000002222222;
      rf[24] = {64{1'b0}}; // 64'h0000000022222222;
      rf[25] = {64{1'b0}}; // 64'h0000000222222222;
      rf[26] = {64{1'b0}}; // 64'h0000002222222222;
      rf[27] = {64{1'b0}}; // 64'h0000022222222222;
      rf[28] = {64{1'b0}}; // 64'h0000222222222222;
      rf[29] = {64{1'b0}}; // 64'h0002222222222222;
      rf[30] = {64{1'b0}}; // 64'h0022222222222222;
      rf[31] = {64{1'b0}}; // 64'h0222222222222222;
      rf[32] = {64{1'b0}}; // 64'h2222222222222222;
   end
   // three ported register file
   // read two ports combinationally (instr_rs1/RD1, instr_rs2/RD2)
   // write third port on rising edge of clock (instr_rd/WD3/regfile_WriteEnable)
   // register 0 hardwired to 0
   integer i=0;
   always @(posedge clk_i, negedge rstn_i) begin
      if (!rstn_i) begin 
         for (i = 0; i < 32; i = i+1) begin
            rf[i] =  {64{1'b0}};
         end
      end else if (regfile_WriteEnable_i) begin
         rf[instr_rd_i] <= regfile_WriteData_i;
      end
   end
   assign regfile_rd1_reg = (instr_rs1_i != 0) ? rf[instr_rs1_i] : 0;
   assign regfile_rd2_reg = (instr_rs2_i != 0) ? rf[instr_rs2_i] : 0;

   always @(posedge clk_i) begin
    regfile_rd1_reg2    <= regfile_rd1_reg;
    regfile_rd1_reg3    <= regfile_rd1_reg2;
    regfile_rd1_reg4    <= regfile_rd1_reg3;
    regfile_rd1_o       <= regfile_rd1_reg4;

    regfile_rd2_reg2    <= regfile_rd2_reg;
    regfile_rd2_reg3    <= regfile_rd2_reg2;
    regfile_rd2_reg4    <= regfile_rd2_reg3;
    regfile_rd2_o       <= regfile_rd2_reg4;
   end
endmodule