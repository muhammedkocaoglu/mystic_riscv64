`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2022 07:27:14 PM
// Design Name: 
// Module Name: mystic_riscv
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


module mystic_riscv(
      input  wire          clk_i,       
      input  wire          rstn_i,   
      input  wire          core_disable_n,    

      input  wire [31:0]   instr_i,
      input  wire          is_compressed_i,
      input  wire          instr_ready_i,

      output wire  [4:0]   byte_len_o,
      output wire          data_cache_l1_read_o,
      output wire          data_cache_l1_write_o,
      output wire [63:0]   data_cache_l1_din_o,
      output wire  [7:0]   data_cache_l1_wr_strb_o,
      output wire [31:0]   data_cache_l1_addr_o,
      input  wire [63:0]   data_cache_l1_dout_i,
      input  wire          data_cache_l1_ready_i,

      output wire [31:0]   PC_o,
      output wire          PC_read_o
   );

   wire           decoder_opcode_ready_int;
   wire  [70:0]   decoder_opcode_int;

   wire  [63:0]   regfile_rd1_int;
   wire  [63:0]   regfile_rd2_int;
   wire           regfile_WriteEnable_int;
   reg           regfile_WriteEnable_reg;
   reg           regfile_WriteEnable_reg1;
   reg           regfile_WriteEnable_reg2;
   wire [63:0]    regfile_WriteData_int;
   reg [63:0]    regfile_WriteData_reg;
   reg [63:0]    regfile_WriteData_reg1;
   reg [63:0]    regfile_WriteData_reg2;
   wire [31:0]    branch_immediate_int;
   reg [31:0]    branch_immediate_reg;
   reg [31:0]    branch_immediate_reg1;
   reg [31:0]    branch_immediate_reg2;
   wire           execute_ready_int;
   reg           execute_ready_reg;
   reg           execute_ready_reg1;
   reg           execute_ready_reg2;
   wire           is_branch_int;
   reg           is_branch_reg;
   reg           is_branch_reg1;
   reg           is_branch_reg2;
   wire           is_jalr_int;
   reg           is_jalr_reg;
   reg           is_jalr_reg1;
   reg           is_jalr_reg2;
   wire [31:0]    PC_next_int;

   wire [31:0]   instr_decompressed_int;
   reg [31:0]   instr_decompressed_int_reg;
   reg [31:0]   instr_decompressed_int_reg_second;
   reg [31:0]   instr_decompressed_int_reg1;
   reg [31:0]   instr_decompressed_int_reg2;
   reg [31:0]   instr_decompressed_int_reg3;
   wire          instr_decompressed_ready_int;
   reg          instr_decompressed_ready_int_reg;
   reg          instr_decompressed_ready_int_reg1;
   reg          instr_decompressed_ready_int_reg2;
   reg          instr_decompressed_ready_int_reg3;

   wire             zicsr_we_int;
   wire   [63:0]    zicsr_din_int;
   wire   [11:0]    zicsr_addr_int;
   wire   [63:0]    zicsr_dout_int;

   mystic_compressed_decoder mystic_compressed_decoder_inst (
      .clk_i                        (clk_i                        ),
      .rstn_i                       (rstn_i                       ),
      .is_compressed_i              (is_compressed_i              ),
      .instr_ready_i                (instr_ready_i                ),
      .instr_i                      (instr_i                      ),
      .instr_decompressed_o         (instr_decompressed_int       ),
      .instr_decompressed_ready_o   (instr_decompressed_ready_int )
   );

   always @(posedge clk_i) begin
      instr_decompressed_int_reg1  <= instr_decompressed_int;
      instr_decompressed_int_reg2  <= instr_decompressed_int_reg1;
      instr_decompressed_int_reg3  <= instr_decompressed_int_reg2;
      instr_decompressed_int_reg   <= instr_decompressed_int_reg3;
      instr_decompressed_int_reg_second   <= instr_decompressed_int_reg3;
      instr_decompressed_ready_int_reg1 <= instr_decompressed_ready_int;
      instr_decompressed_ready_int_reg2 <= instr_decompressed_ready_int_reg1;
      instr_decompressed_ready_int_reg3 <= instr_decompressed_ready_int_reg2;
      instr_decompressed_ready_int_reg <= instr_decompressed_ready_int_reg3;
   end

   mystic_main_decoder mystic_main_decoder_inst (
      .clk_i                  (clk_i                        ),
      .rstn_i                 (rstn_i                       ),
      .instr_cache_l1_ready_i (instr_decompressed_ready_int_reg ),
      .instr_i                (instr_decompressed_int_reg       ),
      .decoder_opcode_ready_o (decoder_opcode_ready_int     ),
      .decoder_opcode_o       (decoder_opcode_int           ),
      .byte_len_o             (byte_len_o                   ),
      .PC_next_i              (PC_next_int                  ),
      .PC_current_i           (PC_o                         ),

      .data_cache_l1_read_o   (data_cache_l1_read_o         ),
      .data_cache_l1_write_o  (data_cache_l1_write_o        ),
      .data_cache_l1_din_o    (data_cache_l1_din_o          ),
      .data_cache_l1_wr_strb_o(data_cache_l1_wr_strb_o      ),
      .data_cache_l1_addr_o   (data_cache_l1_addr_o         ),
      .data_cache_l1_dout_i   (data_cache_l1_dout_i         ),
      .data_cache_l1_ready_i  (data_cache_l1_ready_i        ),

        .regfile_rd1_i          (regfile_rd1_int                ), // data1 read from register file
        .regfile_rd2_i          (regfile_rd2_int                ), // data2 read from register file
        .regfile_WriteEnable_o  (regfile_WriteEnable_int        ), // write command
        .regfile_WriteData_o    (regfile_WriteData_int          ), // data to be written to register file
        .execute_ready_o        (execute_ready_int              ),
        .is_branch_o            (is_branch_int                  ),
        .is_jalr_o              (is_jalr_int                    ),
        .branch_immediate_o     (branch_immediate_int           ),
        .zicsr_we_o             (zicsr_we_int                   ),
        .zicsr_din_o            (zicsr_din_int                  ),
        .zicsr_addr_o           (zicsr_addr_int                 ),
        .zicsr_dout_i           (zicsr_dout_int                 )
   );

   
   
   always @(posedge clk_i) begin
    regfile_WriteEnable_reg1 <= regfile_WriteEnable_int;
    regfile_WriteEnable_reg2 <= regfile_WriteEnable_reg1;
    regfile_WriteEnable_reg <= regfile_WriteEnable_reg2;

    regfile_WriteData_reg1   <= regfile_WriteData_int;
    regfile_WriteData_reg2   <= regfile_WriteData_reg1;
    regfile_WriteData_reg   <= regfile_WriteData_reg2;

    execute_ready_reg1       <= execute_ready_int;
    execute_ready_reg2       <= execute_ready_reg1;
    execute_ready_reg       <= execute_ready_reg2;

    is_branch_reg1           <= is_branch_int;
    is_branch_reg2           <= is_branch_reg1;
    is_branch_reg           <= is_branch_reg2;

    is_jalr_reg1             <= is_jalr_int;
    is_jalr_reg2             <= is_jalr_reg1;
    is_jalr_reg             <= is_jalr_reg2;

    branch_immediate_reg1    <= branch_immediate_int;
    branch_immediate_reg2    <= branch_immediate_reg1;
    branch_immediate_reg    <= branch_immediate_reg2;
   end

   mystic_zicsr mystic_zicsr_inst (
        .clk_i          (clk_i),
        .zicsr_we_i     (zicsr_we_int),
        .rstn_i         (rstn_i),
        .core_disable_n (core_disable_n),
        .zicsr_addr_i   (zicsr_addr_int),
        .zicsr_din_i    (zicsr_din_int),
        .zicsr_dout_o   (zicsr_dout_int)
    );

   mystic_regfile mystic_regfile_inst (
      .clk_i                  (clk_i                     ),                     //
      .rstn_i                 (rstn_i                    ),                    //
      .instr_rs1_i            (instr_decompressed_int_reg_second[19:15]            ), // Instr[19:15]
      .instr_rs2_i            (instr_decompressed_int_reg_second[24:20]            ), // Instr[24:20]
      .instr_rd_i             (instr_decompressed_int_reg_second[11:7]             ), // Instr[11:7]
      .regfile_WriteEnable_i  (regfile_WriteEnable_reg   ), //
      .regfile_WriteData_i    (regfile_WriteData_reg     ), // 
      .regfile_rd1_o          (regfile_rd1_int           ), //
      .regfile_rd2_o          (regfile_rd2_int           ) // 
   );

   mystic_PC_controller mystic_PC_controller_inst (
      .clk_i                  (clk_i                     ),       
      .rstn_i                 (rstn_i                    ),   
      .is_compressed_i        (is_compressed_i           ),
      .is_branch_i            (is_branch_reg             ),
      .is_jalr_i              (is_jalr_reg               ),
      .branch_immediate_i     (branch_immediate_reg      ),
      .instr_ready_i          (instr_ready_i             ),
      .execute_ready_i        (execute_ready_reg         ),
      .PC_o                   (PC_o                      ),
      .PC_next_o              (PC_next_int               ),
      .PC_read_o              (PC_read_o                 )
   );


endmodule
