`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/06/2022 10:23:59 PM
// Design Name: 
// Module Name: mystic_main_decoder
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


module mystic_main_decoder(
        input  wire          clk_i,
        input  wire          rstn_i,
        input  wire          instr_cache_l1_ready_i,
        input  wire [31:0]   instr_i,
        input  wire [31:0]   PC_next_i,
        input  wire [31:0]   PC_current_i,
        output reg           decoder_opcode_ready_o,
        output reg  [70:0]   decoder_opcode_o,
        output reg   [4:0]   byte_len_o,

        output reg           data_cache_l1_read_o,
        output reg           data_cache_l1_write_o,
        output reg  [63:0]   data_cache_l1_din_o,
        output reg   [7:0]   data_cache_l1_wr_strb_o,
        output reg  [31:0]   data_cache_l1_addr_o,
        input  wire [63:0]   data_cache_l1_dout_i,
        input  wire          data_cache_l1_ready_i,           

        input  wire  [63:0]  regfile_rd1_i,              // data1 read from register file
        input  wire  [63:0]  regfile_rd2_i,              // data2 read from register file
        output reg           regfile_WriteEnable_o,      // write command
        output reg   [63:0]  regfile_WriteData_o,        // data to be written to register file
        output reg           execute_ready_o,
        output reg           is_branch_o,
        output reg           is_jalr_o,
        output reg   [31:0]  branch_immediate_o,

        output reg          zicsr_we_o,
        output reg   [63:0] zicsr_din_o,
        output reg   [11:0] zicsr_addr_o,
        input  wire  [63:0] zicsr_dout_i
   );

   localparam S_ADD     = 32'b0000000_?????_?????_000_?????_0110011; // 1   // +
   localparam S_SUB     = 32'b0100000_?????_?????_000_?????_0110011; // 2   // + 
   localparam S_SLL     = 32'b0000000_?????_?????_001_?????_0110011; // 3   // +
   localparam S_SLT     = 32'b0000000_?????_?????_010_?????_0110011; // 4   // +
   localparam S_SLTU    = 32'b0000000_?????_?????_011_?????_0110011; // 5   // +
   localparam S_XOR     = 32'b0000000_?????_?????_100_?????_0110011; // 6   // +
   localparam S_SRL     = 32'b0000000_?????_?????_101_?????_0110011; // 7   // +
   localparam S_SRA     = 32'b0100000_?????_?????_101_?????_0110011; // 8   // +
   localparam S_OR      = 32'b0000000_?????_?????_110_?????_0110011; // 9   // +
   localparam S_AND     = 32'b0000000_?????_?????_111_?????_0110011; // 10  // +

   localparam S_MUL     = 32'b0000001_?????_?????_000_?????_0110011; // 11  // +
   localparam S_MULH    = 32'b0000001_?????_?????_001_?????_0110011; // 12  // +
   localparam S_MULHSU  = 32'b0000001_?????_?????_010_?????_0110011; // 13  // - bunu test et buyuk sayilarla
   localparam S_MULHU   = 32'b0000001_?????_?????_011_?????_0110011; // 14  // +
   localparam S_DIV     = 32'b0000001_?????_?????_100_?????_0110011; // 15  // +
   localparam S_DIVU    = 32'b0000001_?????_?????_101_?????_0110011; // 16  // +
   localparam S_REM     = 32'b0000001_?????_?????_110_?????_0110011; // 17  // +
   localparam S_REMU    = 32'b0000001_?????_?????_111_?????_0110011; // 18  // +

   localparam S_HMDST   = 32'b0000101_?????_?????_001_?????_0110011; // 19  // + ozel
   localparam S_SLADD   = 32'b0010000_?????_?????_010_?????_0110011; // 20  // + ozel
   localparam S_PKG     = 32'b0000100_?????_?????_100_?????_0110011; // 21  // + ozel

   /////////////////////////////
   localparam S_ADDI    = 32'b???????_?????_?????_000_?????_0010011; // 22 // + 
   localparam S_SLTI    = 32'b???????_?????_?????_010_?????_0010011; // 23 // + 
   localparam S_SLTIU   = 32'b???????_?????_?????_011_?????_0010011; // 24 // + 
   localparam S_XORI    = 32'b???????_?????_?????_100_?????_0010011; // 25 // + 
   localparam S_ORI     = 32'b???????_?????_?????_110_?????_0010011; // 26 // + 
   localparam S_ANDI    = 32'b???????_?????_?????_111_?????_0010011; // 27 // + 

   localparam S_SLLI    = 32'b000000_??????_?????_001_?????_0010011; // 28 // + bundan 2 tane var, biri shamt 6, biri 7 bit
   localparam S_SRLI    = 32'b000000_??????_?????_101_?????_0010011; // 29 // + bundan 2 tane var, biri shamt 6, biri 7 bit
   localparam S_SRAI    = 32'b010000_??????_?????_101_?????_0010011; // 30 // + bundan 2 tane var, biri shamt 6, biri 7 bit

   localparam S_CNTZ    = 32'b0110000_00001_?????_001_?????_0010011; // 31 // + ozel
   localparam S_CNTP    = 32'b0110000_00010_?????_001_?????_0010011; // 32 // + ozel
   localparam S_RVRS    = 32'b0110101_11000_?????_101_?????_0010011; // 33 // + ozel

   ////////////////////////////
   localparam S_LB      = 32'b???????_?????_?????_000_?????_0000011; // 34 // +
   localparam S_LH      = 32'b???????_?????_?????_001_?????_0000011; // 35 // +
   localparam S_LW      = 32'b???????_?????_?????_010_?????_0000011; // 36 // +
   localparam S_LBU     = 32'b???????_?????_?????_100_?????_0000011; // 37 // +
   localparam S_LHU     = 32'b???????_?????_?????_101_?????_0000011; // 38 // +
   localparam S_LWU     = 32'b???????_?????_?????_110_?????_0000011; // 39 // +
   localparam S_LD      = 32'b???????_?????_?????_011_?????_0000011; // 40 // +

   ////////////////////////////
   localparam S_SB      = 32'b???????_?????_?????_000_?????_0100011; // 41 // +
   localparam S_SH      = 32'b???????_?????_?????_001_?????_0100011; // 42 // +
   localparam S_SW      = 32'b???????_?????_?????_010_?????_0100011; // 43 // +
   localparam S_SD      = 32'b???????_?????_?????_011_?????_0100011; // 44 // +

   ////////////////////////////
   localparam S_BEQ     = 32'b???????_?????_?????_000_?????_1100011; // 45 // +
   localparam S_BNE     = 32'b???????_?????_?????_001_?????_1100011; // 46 // +
   localparam S_BLT     = 32'b???????_?????_?????_100_?????_1100011; // 47 // +
   localparam S_BGE     = 32'b???????_?????_?????_101_?????_1100011; // 48 // +
   localparam S_BLTU    = 32'b???????_?????_?????_110_?????_1100011; // 49 // +
   localparam S_BGEU    = 32'b???????_?????_?????_111_?????_1100011; // 50 // +

   ///////////////////////////
   localparam S_LUI     = 32'b???????_?????_?????_???_?????_0110111; // 51 // +
   

   ///////////////////////////
   localparam S_JAL     = 32'b???????_?????_?????_???_?????_1101111; // 52 // +

   ///////////////////////////
   localparam S_AUIPC   = 32'b???????_?????_?????_???_?????_0010111; // 53 // + test etmedim

   ///////////////////////////
   localparam S_JALR    = 32'b???????_?????_?????_???_?????_1100111; // 54 // -

   ///////////////////////////
   localparam S_ADDIW   = 32'b???????_?????_?????_000_?????_0011011; // 55 // +
   localparam S_SLLIW   = 32'b0000000_?????_?????_001_?????_0011011; // 56 // +
   localparam S_SRLIW   = 32'b0000000_?????_?????_101_?????_0011011; // 57 // +
   localparam S_SRAIW   = 32'b0100000_?????_?????_101_?????_0011011; // 58 // +

   ///////////////////////////
   localparam S_ADDW    = 32'b0000000_?????_?????_000_?????_0111011; // 59 // +
   localparam S_SUBW    = 32'b0100000_?????_?????_000_?????_0111011; // 60 // +
   localparam S_SLLW    = 32'b0000000_?????_?????_001_?????_0111011; // 61 // +
   localparam S_SRLW    = 32'b0000000_?????_?????_101_?????_0111011; // 62 // +
   localparam S_SRAW    = 32'b0100000_?????_?????_101_?????_0111011; // 63 // +
   localparam S_MULW    = 32'b0000001_?????_?????_000_?????_0111011; // 64 // +
   localparam S_DIVW    = 32'b0000001_?????_?????_100_?????_0111011; // 65 // + test edilmedi
   localparam S_DIVUW   = 32'b0000001_?????_?????_101_?????_0111011; // 66 // + test edilmedi
   localparam S_REMW    = 32'b0000001_?????_?????_110_?????_0111011; // 67 // + test edilmedi
   localparam S_REMUW   = 32'b0000001_?????_?????_111_?????_0111011; // 68 // + test edilmedi

    // status register states
    localparam S_CSRRS  = 32'b???????_?????_?????_010_?????_1110011; // 69 
    localparam S_CSRRW  = 32'b???????_?????_?????_001_?????_1110011; // 70

    // multiplication signals
    reg            mult_is_signed_int;
    reg            mult_enable_int;
    reg    [63:0]  mult_data_left_int;
    reg    [63:0]  mult_data_right_int;
    wire           mult_ready_int;
    reg            mult_is_left_signed_int;
    reg            mult_is_right_signed_int;
    wire   [63:0]  mult_result_upper_int;
    wire   [63:0]  mult_result_lower_int;

    // division signals
    reg            div_enable_int;
    reg            div_is_upper_signed_int;
    reg            div_is_lower_signed_int;
    reg   [63:0]   div_upper_operand_int;
    reg   [63:0]   div_lower_operand_int;
    wire  [63:0]   div_result_int;
    wire  [63:0]   div_rem_int;
    wire           div_ready_int;
    wire           div_exception_int;
    
    reg [8:0] state;
    localparam S_IDLE   = 9'b000000001;
    localparam S_WAIT1  = 9'b000000010;
    localparam S_WAIT2  = 9'b000000100;
    localparam S_WAIT3  = 9'b000001000;
    localparam S_WAIT4  = 9'b000010000;
    localparam S_WAIT5  = 9'b000100000;
    localparam S_WAIT6  = 9'b001000000;
    localparam S_DECODE = 9'b010000000;

    reg [31:0]   instr_reg;
    reg [31:0]   instr_reg2;
    reg [31:0]   instr_reg3;
    reg [31:0]   instr_reg4;
    reg [31:0]   instr_reg5;
    reg [31:0]   instr_reg6;

    reg [31:0]   data_addr;

    reg [31:0]   PC_temp;

    reg [63:0]   instr_immediate;
    reg [2:0]    wr_strb_addr;

    reg [7:0] cntr;

    integer i;
    integer i_cntp;
    reg [7:0] cntp_num;


    // ALU
    reg  [5:0]   alu_opcode_i;
    reg          alu_opcode_valid_i;

    reg  [63:0]  alu_srcA;
    reg  [63:0]  alu_srcB;
    wire [63:0]  alu_result;
    wire         alu_ready_o;

    reg [6:0]   humming_distance;

    
    always @(posedge clk_i, negedge rstn_i ) begin : main_dec_block
        if (!rstn_i) begin
            state    <= S_IDLE;
            cntr     <= 0;
            PC_temp  <= 0;
            data_cache_l1_din_o  <= {64{1'b0}};
        end else begin
            decoder_opcode_ready_o  <= 1'b0;
            regfile_WriteEnable_o   <= 1'b0;
            execute_ready_o         <= 1'b0;
            data_cache_l1_read_o    <= 1'b0; 
            data_cache_l1_write_o   <= 1'b0;
            is_branch_o             <= 1'b0;
            alu_opcode_valid_i      <= 1'b0;
            mult_enable_int         <= 1'b0;
            div_enable_int          <= 1'b0;
            is_jalr_o               <= 1'b0;
            zicsr_we_o              <= 1'b0;    
            case (state)
                S_IDLE: begin
                cntr  <= 0;
                branch_immediate_o      <= {32{1'b0}};
                cntp_num                <= {8{1'b0}};
                if (instr_cache_l1_ready_i) begin
                    state             <= S_WAIT1;
                    decoder_opcode_o  <= {70{1'b0}};
                    instr_reg   <= instr_i;
                    instr_reg2   <= instr_i;
                    instr_reg3   <= instr_i;
                    instr_reg4   <= instr_i;
                    instr_reg5   <= instr_i;
                    instr_reg6   <= instr_i;
                end
                end

                S_WAIT1: begin
                    state <= S_WAIT2;
                end

                S_WAIT2: begin
                    state <= S_WAIT3;
                end

                S_WAIT3: begin
                    state <= S_WAIT4;
                end

                S_WAIT4: begin
                    state <= S_WAIT5;
                end

                S_WAIT5: begin
                    state <= S_WAIT6;
                end

                S_WAIT6: begin
                    state <= S_DECODE;
                end

                S_DECODE: begin
                casez (instr_reg)
                    S_ADD: begin
                        decoder_opcode_o        <= 1;
                        if (cntr == 0) begin
                            $display("S_ADD");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000000; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= regfile_rd2_i;
                            cntr                 <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SUB: begin
                        decoder_opcode_o        <= 2;
                        if (cntr == 0) begin
                            $display("S_SUB");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000111; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= regfile_rd2_i;
                            cntr                 <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end
                    
                    S_SLL: begin // 3
                        decoder_opcode_o           <= 3;
                        if (cntr == 0) begin
                            $display("S_SLL");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000011; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= regfile_rd2_i;
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SLT: begin
                        $display("S_SLT");
                        decoder_opcode_o        <= 4;
                        regfile_WriteEnable_o   <= 1'b1;
                        state                   <= S_IDLE;
                        decoder_opcode_ready_o  <= 1'b1;
                        execute_ready_o         <= 1'b1;
                        if ($signed(regfile_rd1_i) < $signed(regfile_rd2_i)) begin
                            regfile_WriteData_o  <= 1; 
                        end else begin
                            regfile_WriteData_o  <= {64{1'b0}}; 
                        end
                    end

                    S_SLTU: begin
                        $display("S_SLTU");
                        decoder_opcode_o        <= 5;
                        regfile_WriteEnable_o   <= 1'b1;
                        state                   <= S_IDLE;
                        decoder_opcode_ready_o  <= 1'b1;
                        execute_ready_o         <= 1'b1;
                        if ($unsigned(regfile_rd1_i) < $unsigned(regfile_rd2_i)) begin
                            regfile_WriteData_o  <= 1; 
                        end else begin
                            regfile_WriteData_o  <= 0; 
                        end
                    end

                    
                    S_XOR: begin
                        decoder_opcode_o        <= 6;
                        if (cntr == 0) begin
                            $display("S_XOR");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000110; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= regfile_rd2_i;
                            cntr                 <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_SRL: begin
                        decoder_opcode_o        <= 7;
                        if (cntr == 0) begin
                            $display("S_SRL");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000101; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= regfile_rd2_i;
                            cntr                 <= cntr + 1;
                        end
                        // burada illegal condition var, onu implement et gerekirse

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_SRA: begin
                        decoder_opcode_o        <= 8;
                        if (cntr == 0) begin
                            $display("S_SRA");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000100; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= regfile_rd2_i;
                            cntr                 <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end


                    S_OR: begin // 9
                        decoder_opcode_o           <= 9;
                        if (cntr == 0) begin
                            $display("S_OR");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000010; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= regfile_rd2_i;
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end


                    S_AND: begin // 10
                        decoder_opcode_o           <= 10;
                        if (cntr == 0) begin
                            $display("S_AND");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000001; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= regfile_rd2_i;
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_MUL: begin
                        decoder_opcode_o        <= 11;
                        if (cntr == 0) begin
                            $display("S_MUL");
                            mult_is_left_signed_int    <= 1'b1;
                            mult_is_right_signed_int   <= 1'b1;
                            mult_enable_int            <= 1'b1;
                            mult_data_left_int         <= regfile_rd1_i;
                            mult_data_right_int        <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (mult_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= mult_result_lower_int;
                            state                      <= S_IDLE;
                            mult_is_left_signed_int    <= 1'b0;
                            mult_is_right_signed_int   <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_MULH: begin
                        decoder_opcode_o        <= 12;
                        if (cntr == 0) begin
                            $display("S_MULH");
                            mult_is_left_signed_int    <= 1'b1;
                            mult_is_right_signed_int   <= 1'b1;
                            mult_enable_int            <= 1'b1;
                            mult_data_left_int         <= regfile_rd1_i;
                            mult_data_right_int        <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (mult_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= mult_result_upper_int;
                            state                      <= S_IDLE;
                            mult_is_left_signed_int    <= 1'b0;
                            mult_is_right_signed_int   <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_MULHSU: begin // burada kaldım
                        decoder_opcode_o              <= 13;
                        if (cntr == 0) begin
                            $display("S_MULHSU");
                            mult_is_left_signed_int    <= 1'b1;
                            mult_is_right_signed_int   <= 1'b0;
                            mult_enable_int            <= 1'b1;
                            mult_data_left_int         <= regfile_rd1_i;
                            mult_data_right_int        <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (mult_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= mult_result_upper_int;
                            state                      <= S_IDLE;
                            mult_is_left_signed_int    <= 1'b0;
                            mult_is_right_signed_int   <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_MULHU: begin
                        decoder_opcode_o              <= 14;
                        if (cntr == 0) begin
                            $display("S_MULHU");
                            mult_is_left_signed_int    <= 1'b0;
                            mult_is_right_signed_int   <= 1'b0;
                            mult_enable_int            <= 1'b1;
                            mult_data_left_int         <= regfile_rd1_i;
                            mult_data_right_int        <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (mult_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= mult_result_upper_int;
                            state                      <= S_IDLE;
                            mult_is_left_signed_int    <= 1'b0;
                            mult_is_right_signed_int   <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_DIV: begin
                        decoder_opcode_o              <= 15;
                        if (cntr == 0) begin
                            $display("S_DIV");
                            div_is_upper_signed_int    <= 1'b1;
                            div_is_lower_signed_int    <= 1'b1;
                            div_enable_int             <= 1'b1;
                            div_upper_operand_int      <= regfile_rd1_i;
                            div_lower_operand_int      <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (div_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= div_result_int;
                            state                      <= S_IDLE;
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_DIVU: begin
                        decoder_opcode_o              <= 16;
                        if (cntr == 0) begin
                            $display("S_DIVU");
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            div_enable_int             <= 1'b1;
                            div_upper_operand_int      <= regfile_rd1_i;
                            div_lower_operand_int      <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (div_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= div_result_int;
                            state                      <= S_IDLE;
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_REM: begin
                        decoder_opcode_o              <= 17;
                        if (cntr == 0) begin
                            $display("S_REM");
                            div_is_upper_signed_int    <= 1'b1;
                            div_is_lower_signed_int    <= 1'b1;
                            div_enable_int             <= 1'b1;
                            div_upper_operand_int      <= regfile_rd1_i;
                            div_lower_operand_int      <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (div_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= div_rem_int;
                            state                      <= S_IDLE;
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_REMU: begin
                        decoder_opcode_o              <= 18;
                        if (cntr == 0) begin
                            $display("S_REMU");
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            div_enable_int             <= 1'b1;
                            div_upper_operand_int      <= regfile_rd1_i;
                            div_lower_operand_int      <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (div_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= div_rem_int;
                            state                      <= S_IDLE;
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_HMDST: begin
                        $display("S_HMDST");
                        decoder_opcode_o        <= 19;
                        regfile_WriteEnable_o   <= 1'b1;
                        state                   <= S_IDLE;
                        decoder_opcode_ready_o  <= 1'b1;
                        execute_ready_o         <= 1'b1;
                        humming_distance = {7{1'b0}};
                        for (i = 0; i < 64; i = i + 1) begin
                            if (regfile_rd1_i[i] != regfile_rd2_i[i]) begin
                            humming_distance = humming_distance + 1;
                            end
                        end
                        regfile_WriteData_o     <= {{57{1'b0}}, humming_distance};
                    end

                    S_SLADD: begin
                        decoder_opcode_o        <= 20;
                        if (cntr == 0) begin
                            $display("S_SLADD");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000000; 
                            alu_srcA             <= regfile_rd1_i << 1;
                            alu_srcB             <= regfile_rd2_i;
                            cntr                 <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_PKG: begin
                        $display("S_PKG");
                        decoder_opcode_o        <= 21;
                        regfile_WriteEnable_o   <= 1'b1;
                        regfile_WriteData_o     <= {regfile_rd2_i[31:0], regfile_rd1_i[31:0]};
                        state                   <= S_IDLE;
                        decoder_opcode_ready_o  <= 1'b1;
                        execute_ready_o         <= 1'b1;
                    end

                    S_ADDI:begin
                        decoder_opcode_o        <= 22;
                        if (cntr == 0) begin
                            $display("S_ADDI");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000000; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= {{52{instr_reg2[31]}}, instr_reg2[31:20]};
                            cntr                 <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SLTI: begin
                        decoder_opcode_o        <= 23;
                        if (cntr == 0) begin
                            $display("S_SLTI");
                            instr_immediate      <= {{52{instr_reg2[31]}}, instr_reg2[31:20]};
                            cntr                 <= cntr + 1;
                        end else begin 
                            regfile_WriteEnable_o   <= 1'b1;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            if ($signed(regfile_rd1_i) < $signed(instr_immediate)) begin
                            regfile_WriteData_o  <= 1; 
                            end else begin
                            regfile_WriteData_o  <= {64{1'b0}}; 
                            end
                        end
                    end

                    S_SLTIU: begin
                        decoder_opcode_o           <= 24;
                        if (cntr == 0) begin
                            $display("S_SLTIU");
                            instr_immediate         <= {{52{instr_reg2[31]}}, instr_reg2[31:20]};
                            cntr                    <= cntr + 1;
                        end else begin 
                            regfile_WriteEnable_o   <= 1'b1;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            if ($unsigned(regfile_rd1_i) < $unsigned(instr_immediate)) begin
                            regfile_WriteData_o  <= 1; 
                            end else begin
                            regfile_WriteData_o  <= {64{1'b0}}; 
                            end
                        end
                    end

                    S_XORI: begin
                        decoder_opcode_o           <= 25;
                        if (cntr == 0) begin
                            $display("S_XORI");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000110; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= {{52{instr_reg2[31]}}, instr_reg2[31:20]};
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_ORI: begin
                        decoder_opcode_o           <= 26;
                        if (cntr == 0) begin
                            $display("S_ORI");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000010; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= {{52{instr_reg2[31]}}, instr_reg2[31:20]};
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_ANDI: begin
                        decoder_opcode_o           <= 27;
                        if (cntr == 0) begin
                            $display("S_ANDI");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000001; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= {{52{instr_reg2[31]}}, instr_reg2[31:20]};
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            $display("");
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SLLI: begin
                        decoder_opcode_o           <= 28;
                        if (cntr == 0) begin
                            $display("S_SLLI");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000011; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= {{58{1'b0}}, instr_reg2[25:20]};
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SRLI: begin
                        decoder_opcode_o           <= 29;
                        if (cntr == 0) begin
                            $display("S_SRLI");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000101; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= {{58{1'b0}}, instr_reg2[25:20]};
                            cntr                    <= cntr + 1;
                        end
                        // burada illegal condition var, onu implement et gerekirse

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_SRAI: begin
                        decoder_opcode_o           <= 30;
                        if (cntr == 0) begin
                            $display("S_SRAI");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000100; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= {{58{1'b0}}, instr_reg2[25:20]};
                            cntr                    <= cntr + 1;
                        end
                        // burada illegal condition var, onu implement et gerekirse

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= alu_result;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_CNTZ: begin
                        $display("S_CNTZ");
                        decoder_opcode_o           <= 31;
                        regfile_WriteEnable_o      <= 1'b1;
                        regfile_WriteData_o        <= 64;
                        state                      <= S_IDLE;
                        decoder_opcode_ready_o     <= 1'b1;
                        execute_ready_o            <= 1'b1;
                        for (i = 63; i >= 0; i = i-1) begin
                            if (regfile_rd1_i[i]) begin
                            regfile_WriteData_o  <= i;
                            end
                        end
                    end

                    S_CNTP: begin
                        $display("S_CNTP");
                        decoder_opcode_o        <= 32;
                        regfile_WriteEnable_o   <= 1'b1;
                        state                   <= S_IDLE;
                        decoder_opcode_ready_o  <= 1'b1;
                        execute_ready_o         <= 1'b1;
                        for (i_cntp = 0; i_cntp < 64; i_cntp = i_cntp+1) begin
                            if (regfile_rd1_i[i_cntp]) begin
                            cntp_num  = cntp_num + 1;
                            end
                        end
                        regfile_WriteData_o     <= cntp_num;
                    end

                    S_RVRS: begin
                        $display("S_RVRS");
                        decoder_opcode_o                 <= 33;
                        regfile_WriteData_o[8*1-1:8*0]   <= regfile_rd1_i[8*8-1:8*7];
                        regfile_WriteData_o[8*2-1:8*1]   <= regfile_rd1_i[8*7-1:8*6];
                        regfile_WriteData_o[8*3-1:8*2]   <= regfile_rd1_i[8*6-1:8*5];
                        regfile_WriteData_o[8*4-1:8*3]   <= regfile_rd1_i[8*5-1:8*4];
                        regfile_WriteData_o[8*5-1:8*4]   <= regfile_rd1_i[8*4-1:8*3];
                        regfile_WriteData_o[8*6-1:8*5]   <= regfile_rd1_i[8*3-1:8*2];
                        regfile_WriteData_o[8*7-1:8*6]   <= regfile_rd1_i[8*2-1:8*1];
                        regfile_WriteData_o[8*8-1:8*7]   <= regfile_rd1_i[8*1-1:8*0];
                        regfile_WriteEnable_o            <= 1'b1;
                        state                            <= S_IDLE;
                        decoder_opcode_ready_o           <= 1'b1;
                        execute_ready_o                  <= 1'b1;
                    end

                    S_LB: begin // 0000011
                        decoder_opcode_o        <= 34;
                        byte_len_o  <= 1;
                        if (cntr == 0) begin
                            $display("S_LB");
                            cntr  <= cntr + 1;
                            data_cache_l1_read_o <= 1'b1;    
                            // data_cache_l1_addr_o <= 32'h4000_0010; //  
                            data_cache_l1_addr_o    <= regfile_rd1_i + {{52{instr_reg3[31]}} ,instr_reg3[31:20]}; 
                        end
                        
                        if (data_cache_l1_ready_i) begin
                            regfile_WriteData_o  <= {{56{data_cache_l1_dout_i[7]}}, data_cache_l1_dout_i[7:0]};
                            regfile_WriteEnable_o   <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_LH: begin
                        byte_len_o  <= 2;
                        decoder_opcode_o        <= 35;
                        if (cntr == 0) begin
                            $display("S_LH");
                            cntr  <= cntr + 1;
                            data_cache_l1_read_o <= 1'b1;    
                            // data_cache_l1_addr_o <= 32'h4000_0010; // regfile_rd1_i + {{20{instr_i[31]}} ,instr_i[31:20]};                    
                            data_cache_l1_addr_o <= regfile_rd1_i + {{52{instr_reg3[31]}} ,instr_reg3[31:20]};                    
                        end
                        
                        if (data_cache_l1_ready_i) begin
                            regfile_WriteData_o  <= {{48{data_cache_l1_dout_i[15]}}, data_cache_l1_dout_i[15:0]};
                            regfile_WriteEnable_o   <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_LW: begin // 0000011
                        byte_len_o  <= 4;
                        decoder_opcode_o        <= 36;
                        if (cntr == 0) begin
                            $display("S_LW, offset = %b, rs1_addr = %d, rs1_data = %h", instr_reg3[31:20], instr_reg3[19:15], regfile_rd1_i);
                            cntr  <= cntr + 1;
                            data_cache_l1_read_o <= 1'b1;    
                            //data_cache_l1_addr_o <= 32'h4000_0010; // regfile_rd1_i + {{52{instr_i[31]}} ,instr_i[31:20]};      
                            instr_immediate = {{52{instr_reg3[31]}} ,instr_reg3[31:20]};   
                            data_cache_l1_addr_o <= regfile_rd1_i + instr_immediate;                     
                        end
                        
                        if (data_cache_l1_ready_i) begin
                            regfile_WriteData_o  <= {{32{data_cache_l1_dout_i[31]}}, data_cache_l1_dout_i[31:0]};
                            regfile_WriteEnable_o   <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_LBU: begin
                        byte_len_o  <= 1;
                        decoder_opcode_o        <= 37;
                        if (cntr == 0) begin
                            $display("S_LBU");
                            cntr  <= cntr + 1;
                            data_cache_l1_read_o <= 1'b1;    
                            // data_cache_l1_addr_o <= 32'h4000_0010; // regfile_rd1_i + {{20{instr_i[31]}} ,instr_i[31:20]};                    
                            data_cache_l1_addr_o <= regfile_rd1_i + {{52{instr_reg3[31]}} ,instr_reg3[31:20]};                    
                        end
                        
                        if (data_cache_l1_ready_i) begin
                            regfile_WriteData_o  <= {{56{1'b0}}, data_cache_l1_dout_i[7:0]};
                            regfile_WriteEnable_o   <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    
                    S_LHU: begin
                        byte_len_o  <= 2;
                        decoder_opcode_o        <= 38;
                        if (cntr == 0) begin
                            $display("S_LHU");
                            cntr  <= cntr + 1;
                            data_cache_l1_read_o <= 1'b1;    
                            data_cache_l1_addr_o <= regfile_rd1_i + {{52{instr_reg3[31]}} ,instr_reg3[31:20]};                    
                        end
                        
                        if (data_cache_l1_ready_i) begin
                            regfile_WriteData_o  <= {{48{1'b0}}, data_cache_l1_dout_i[15:0]};
                            regfile_WriteEnable_o   <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_LWU: begin 
                        byte_len_o  <= 4;
                        decoder_opcode_o        <= 39;
                        if (cntr == 0) begin
                            $display("S_LWU");
                            cntr  <= cntr + 1;
                            data_cache_l1_read_o <= 1'b1;    
                            data_cache_l1_addr_o <= regfile_rd1_i + {{52{instr_reg3[31]}} ,instr_reg3[31:20]};                    
                        end
                        
                        if (data_cache_l1_ready_i) begin
                            regfile_WriteData_o  <= {{32{1'b0}}, data_cache_l1_dout_i[31:0]};
                            regfile_WriteEnable_o   <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_LD: begin
                        byte_len_o  <= 8;
                        decoder_opcode_o        <= 40;
                        if (cntr == 0) begin
                            $display("S_LD");
                            cntr                 <= cntr + 1;
                            data_cache_l1_read_o <= 1'b1;    
                            data_cache_l1_addr_o <= regfile_rd1_i + {{52{instr_reg3[31]}} ,instr_reg3[31:20]};                    
                        end
                        
                        if (data_cache_l1_ready_i) begin
                            regfile_WriteData_o     <= data_cache_l1_dout_i;
                            regfile_WriteEnable_o   <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_SB: begin
                        byte_len_o  <= 1;
                        decoder_opcode_o           <= 41;
                        if (cntr == 0) begin
                            $display("S_SB");
                            instr_immediate         <= {{52{instr_reg3[31]}}, instr_reg3[31:25], instr_reg3[11:7]};
                            cntr                    <= cntr + 1;
                        end else if (cntr == 1) begin 
                            cntr  <= cntr + 1;
                            data_cache_l1_addr_o    <= regfile_rd1_i + instr_immediate; // regfile_rd1_i + instr_immediate;
                            wr_strb_addr            <= regfile_rd1_i + instr_immediate; // 3 bits
                            data_cache_l1_wr_strb_o[7:0]  <= 8'b00000000;
                        end else if (cntr == 2) begin
                            cntr  <= cntr + 1;
                            data_cache_l1_write_o                     <= 1'b1;
                            data_cache_l1_wr_strb_o[wr_strb_addr]     <= 1'b1;
                            data_cache_l1_din_o                       <= {8{regfile_rd2_i[7:0]}};
                        end

                        if (data_cache_l1_ready_i) begin
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_SH: begin
                        byte_len_o  <= 2;
                        decoder_opcode_o           <= 42;
                        if (cntr == 0) begin
                            $display("S_SH");
                            instr_immediate         <= {{52{instr_reg3[31]}}, instr_reg3[31:25], instr_reg3[11:7]};
                            cntr                    <= cntr + 1;
                        end else if (cntr == 1) begin 
                            cntr  <= cntr + 1;
                            data_cache_l1_addr_o <= regfile_rd1_i + instr_immediate; // regfile_rd1_i + instr_immediate;
                            wr_strb_addr         <= regfile_rd1_i + instr_immediate; // 3 bits
                            data_cache_l1_wr_strb_o[7:0]  <= 8'b00000000;
                        end else if (cntr == 2) begin
                            cntr  <= cntr + 1;
                            data_cache_l1_write_o                     <= 1'b1;
                            data_cache_l1_wr_strb_o[wr_strb_addr]     <= 1'b1;
                            data_cache_l1_wr_strb_o[wr_strb_addr+1]   <= 1'b1;
                            data_cache_l1_din_o                       <= {4{regfile_rd2_i[15:0]}};
                        end

                        if (data_cache_l1_ready_i) begin
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_SW: begin
                        byte_len_o  <= 4;
                        decoder_opcode_o           <= 43;
                        if (cntr == 0) begin
                            $display("S_SW");
                            instr_immediate         <= {{52{instr_reg3[31]}}, instr_reg3[31:25], instr_reg3[11:7]};
                            cntr                    <= cntr + 1;
                        end else if (cntr == 1) begin 
                            cntr  <= cntr + 1;
                            data_cache_l1_addr_o <= regfile_rd1_i + instr_immediate; // 32'h4000_0000
                            wr_strb_addr         <= regfile_rd1_i + instr_immediate; // 3 bits
                            data_cache_l1_wr_strb_o[7:0]  <= 8'b00000000;
                        end else if (cntr == 2) begin
                            cntr  <= cntr + 1;
                            data_cache_l1_write_o                     <= 1'b1;
                            data_cache_l1_wr_strb_o[wr_strb_addr+0]   <= 1'b1;
                            data_cache_l1_wr_strb_o[wr_strb_addr+1]   <= 1'b1;
                            data_cache_l1_wr_strb_o[wr_strb_addr+2]   <= 1'b1;
                            data_cache_l1_wr_strb_o[wr_strb_addr+3]   <= 1'b1;
                            data_cache_l1_din_o                       <= {2{regfile_rd2_i[31:0]}};
                        end

                        if (data_cache_l1_ready_i) begin
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_SD: begin
                        byte_len_o  <= 8;
                        decoder_opcode_o  <= 44;
                        if (cntr == 0) begin
                            $display("S_SD");
                            instr_immediate         <= {{52{instr_reg3[31]}}, instr_reg3[31:25], instr_reg3[11:7]};
                            cntr                    <= cntr + 1;
                        end else if (cntr == 1) begin 
                            cntr  <= cntr + 1;
                            data_cache_l1_addr_o <= regfile_rd1_i + instr_immediate; // regfile_rd1_i + instr_immediate;
                            wr_strb_addr         <= regfile_rd1_i + instr_immediate; // 3 bits
                            data_cache_l1_wr_strb_o[7:0]  <= 8'b00000000;
                        end else if (cntr == 2) begin
                            cntr  <= cntr + 1;
                            data_cache_l1_write_o      <= 1'b1;
                            data_cache_l1_wr_strb_o    <= 8'b1111_1111;
                            data_cache_l1_din_o        <= regfile_rd2_i;
                        end

                        if (data_cache_l1_ready_i) begin
                            execute_ready_o         <= 1'b1;
                            state                   <= S_IDLE;
                        end
                    end

                    S_BEQ: begin
                        $display("S_BEQ");
                        decoder_opcode_o        <= 45;
                        execute_ready_o         <= 1'b1;
                        state                   <= S_IDLE;
                        if (regfile_rd1_i == regfile_rd2_i) begin
                            is_branch_o             <= 1'b1;
                            branch_immediate_o      <= {{19{instr_reg3[31]}}, 
                            instr_reg3[31], instr_reg3[7], 
                            instr_reg3[30:25], instr_reg3[11:8], 1'b0};
                        end
                    end

                    S_BNE: begin : bne
                        reg [31:0] imm_test;
                        imm_test = {{19{instr_reg4[31]}}, 
                        instr_reg4[31], instr_reg4[7], 
                        instr_reg4[30:25], instr_reg4[11:8], 1'b0};
                        $display("S_BNE, immediate: %d", $signed(imm_test));
                        decoder_opcode_o        <= 46;
                        execute_ready_o         <= 1'b1;
                        state                   <= S_IDLE;
                        if (regfile_rd1_i != regfile_rd2_i) begin
                            is_branch_o             <= 1'b1;
                            branch_immediate_o      <= {{19{instr_reg4[31]}}, 
                            instr_reg4[31], instr_reg4[7], 
                            instr_reg4[30:25], instr_reg4[11:8], 1'b0};
                        end
                    end : bne

                    S_BLT: begin
                        $display("S_BLT");
                        decoder_opcode_o        <= 47;
                        execute_ready_o         <= 1'b1;
                        state                   <= S_IDLE;
                        if ($signed(regfile_rd1_i) < $signed(regfile_rd2_i)) begin
                            is_branch_o             <= 1'b1;
                            branch_immediate_o      <= {{19{instr_reg4[31]}}, 
                            instr_reg4[31], instr_reg4[7], 
                            instr_reg4[30:25], instr_reg4[11:8], 1'b0};
                        end
                    end

                    S_BGE: begin
                        $display("S_BGE");
                        decoder_opcode_o        <= 48;
                        execute_ready_o         <= 1'b1;
                        state                   <= S_IDLE;
                        if ($signed(regfile_rd1_i) >= $signed(regfile_rd2_i)) begin
                            is_branch_o             <= 1'b1;
                            branch_immediate_o      <= {{19{instr_reg4[31]}}, 
                            instr_reg4[31], instr_reg4[7], 
                            instr_reg4[30:25], instr_reg4[11:8], 1'b0};
                        end
                    end
    //----------------
                    S_BLTU: begin
                        $display("S_BLTU");
                        decoder_opcode_o        <= 49;
                        execute_ready_o         <= 1'b1;
                        state                   <= S_IDLE;
                        if ($unsigned(regfile_rd1_i) < $unsigned(regfile_rd2_i)) begin
                            is_branch_o             <= 1'b1;
                            branch_immediate_o      <= {{19{instr_reg4[31]}}, 
                            instr_reg4[31], instr_reg4[7], 
                            instr_reg4[30:25], instr_reg4[11:8], 1'b0};
                        end
                    end

                    S_BGEU: begin
                        $display("S_BGEU");
                        decoder_opcode_o        <= 50;
                        execute_ready_o         <= 1'b1;
                        state                   <= S_IDLE;
                        if ($unsigned(regfile_rd1_i) >= $unsigned(regfile_rd2_i)) begin
                            is_branch_o             <= 1'b1;
                            branch_immediate_o      <= {{19{instr_reg4[31]}}, 
                            instr_reg4[31], instr_reg4[7], 
                            instr_reg4[30:25], instr_reg4[11:8], 1'b0};
                        end
                    end

                    S_LUI: begin // 0110111
                        $display("S_LUI: rd_addr = %d, rd_data: %h", instr_reg4[11:7], {{32{instr_reg4[31]}}, instr_reg4[31:12], 12'h000});
                        decoder_opcode_o        <= 51;
                        regfile_WriteEnable_o   <= 1'b1;
                        regfile_WriteData_o     <= {{32{instr_reg4[31]}}, instr_reg4[31:12], 12'h000};
                        state                   <= S_IDLE;
                        decoder_opcode_ready_o  <= 1'b1;
                        execute_ready_o         <= 1'b1;
                    end

                    S_JAL: begin // 1101111
                        $display("S_JAL");
                        decoder_opcode_o        <= 52;
                        regfile_WriteEnable_o   <= 1'b1;
                        regfile_WriteData_o     <= {{32{1'b0}}, PC_next_i}; // ;{{44{1'b0}}, PC_next_i[19:0]}
                        execute_ready_o         <= 1'b1;
                        state                   <= S_IDLE;
                        is_branch_o             <= 1'b1;
                        branch_immediate_o      <= {{11{instr_reg5[31]}}, 
                        instr_reg5[31], instr_reg5[19:12], 
                        instr_reg5[20], instr_reg5[30:21], 1'b0};
                    end

                    S_AUIPC: begin
                        decoder_opcode_o        <= 53;
                        if (cntr == 0) begin
                            $display("S_AUIPC");
                            instr_immediate      <= {{32{instr_reg5[31]}}, instr_reg5[31:12], {12{1'b0}}};
                            cntr                 <= cntr + 1;
                        end else begin 
                            regfile_WriteEnable_o   <= 1'b1;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            regfile_WriteData_o     <= instr_immediate + PC_current_i; 
                        end
                    end

                    S_JALR: begin // kontrol et burayi
                        decoder_opcode_o        <= 54;
                        if (cntr == 0) begin
                            $display("S_JALR");
                            PC_temp     <= {{44{1'b0}}, PC_next_i[19:0]}; // PC_current_i + 4;
                            cntr        <= cntr + 1;
                        end else begin 
                            branch_immediate_o      <= regfile_rd1_i + {{20{instr_reg5[31]}}, instr_reg5[31:20]}; 
                            is_jalr_o               <= 1'b1;
                            regfile_WriteEnable_o   <= 1'b1;
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                            regfile_WriteData_o     <= PC_temp; 
                        end
                    end

                    S_ADDIW: begin
                        decoder_opcode_o        <= 55;
                        if (cntr == 0) begin
                            $display("S_ADDIW");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000000; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= {{52{instr_reg5[31]}}, instr_reg5[31:20]};
                            cntr                 <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= {{32{alu_result[31]}} ,alu_result[31:0]};
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SLLIW: begin
                        decoder_opcode_o        <= 56;
                        if (cntr == 0) begin
                            $display("S_SLLIW");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000011; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= {{58{1'b0}}, instr_reg5[25:20]};
                            cntr                 <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= {{32{alu_result[31]}} ,alu_result[31:0]};
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SRLIW: begin
                        decoder_opcode_o        <= 57;
                        if (cntr == 0) begin
                            $display("S_SRLIW");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000101; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= {{58{1'b0}}, instr_reg5[25:20]};
                            cntr                 <= cntr + 1;
                        end
                        // burada illegal condition var, onu implement et gerekirse

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= {{32{alu_result[31]}} ,alu_result[31:0]};
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_SRAIW: begin
                        decoder_opcode_o        <= 58;
                        if (cntr == 0) begin
                            $display("S_SRAIW");
                            alu_opcode_valid_i   <= 1'b1;
                            alu_opcode_i         <= 6'b000100; 
                            alu_srcA             <= regfile_rd1_i;
                            alu_srcB             <= {{58{1'b0}}, instr_reg5[25:20]};
                            cntr                 <= cntr + 1;
                        end
                        // burada illegal condition var, onu implement et gerekirse

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= {{32{alu_result[31]}}, alu_result[31:0]};
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_ADDW: begin
                        decoder_opcode_o           <= 59;
                        if (cntr == 0) begin
                            $display("S_ADDW");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000000; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= regfile_rd2_i;
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= {{32{alu_result[31]}}, alu_result[31:0]};
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SUBW: begin
                        decoder_opcode_o           <= 60;
                        if (cntr == 0) begin
                            $display("S_SUBW");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000111;  
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= regfile_rd2_i;
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= {{32{alu_result[31]}}, alu_result[31:0]};
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SLLW: begin
                        decoder_opcode_o           <= 61;
                        if (cntr == 0) begin
                            $display("S_SLLW");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000011; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= {{59{1'b0}}, regfile_rd2_i[4:0]};
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= {{32{alu_result[31]}}, alu_result[31:0]};
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end 
                    end

                    S_SRLW: begin
                        decoder_opcode_o           <= 62;
                        if (cntr == 0) begin
                            $display("S_SRLW");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000101; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= {{59{1'b0}}, regfile_rd2_i[4:0]};
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= {{32{alu_result[31]}}, alu_result[31:0]};
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_SRAW: begin
                        decoder_opcode_o           <= 63;
                        if (cntr == 0) begin
                            $display("S_SRAW");
                            alu_opcode_valid_i      <= 1'b1;
                            alu_opcode_i            <= 6'b000100; 
                            alu_srcA                <= regfile_rd1_i;
                            alu_srcB                <= {{59{1'b0}}, regfile_rd2_i[4:0]};
                            cntr                    <= cntr + 1;
                        end

                        if (alu_ready_o) begin
                            regfile_WriteEnable_o   <= 1'b1;
                            regfile_WriteData_o     <= {{32{alu_result[31]}}, alu_result[31:0]};
                            state                   <= S_IDLE;
                            decoder_opcode_ready_o  <= 1'b1;
                            execute_ready_o         <= 1'b1;
                        end
                    end

                    S_MULW: begin
                        decoder_opcode_o              <= 64;
                        if (cntr == 0) begin
                            $display("S_MULW");
                            mult_is_left_signed_int    <= 1'b0;
                            mult_is_right_signed_int   <= 1'b0;
                            mult_enable_int            <= 1'b1;
                            mult_data_left_int         <= regfile_rd1_i;
                            mult_data_right_int        <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (mult_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= {{32{mult_result_lower_int[31]}}, mult_result_lower_int[31:0]}; // burada kaldim
                            state                      <= S_IDLE;
                            mult_is_left_signed_int    <= 1'b0;
                            mult_is_right_signed_int   <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_DIVW: begin
                        decoder_opcode_o              <= 65;
                        if (cntr == 0) begin
                            $display("S_DIVW");
                            div_is_upper_signed_int    <= 1'b1;
                            div_is_lower_signed_int    <= 1'b1;
                            div_enable_int             <= 1'b1;
                            div_upper_operand_int      <= regfile_rd1_i;
                            div_lower_operand_int      <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (div_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= {{32{div_result_int[31]}}, div_result_int[31:0]};
                            state                      <= S_IDLE;
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_DIVUW: begin
                        decoder_opcode_o              <= 66;
                        if (cntr == 0) begin
                            $display("S_DIVUW");
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            div_enable_int             <= 1'b1;
                            div_upper_operand_int      <= regfile_rd1_i;
                            div_lower_operand_int      <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (div_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= {{32{div_result_int[31]}}, div_result_int[31:0]};
                            state                      <= S_IDLE;
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_REMW: begin
                        decoder_opcode_o              <= 67;
                        if (cntr == 0) begin
                            $display("S_REMW");
                            div_is_upper_signed_int    <= 1'b1;
                            div_is_lower_signed_int    <= 1'b1;
                            div_enable_int             <= 1'b1;
                            div_upper_operand_int      <= regfile_rd1_i;
                            div_lower_operand_int      <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (div_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= {{32{div_rem_int[31]}}, div_rem_int[31:0]};
                            state                      <= S_IDLE;
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_REMUW: begin
                        decoder_opcode_o              <= 68;
                        if (cntr == 0) begin
                            $display("S_REMUW");
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            div_enable_int             <= 1'b1;
                            div_upper_operand_int      <= regfile_rd1_i;
                            div_lower_operand_int      <= regfile_rd2_i;
                            cntr                       <= cntr + 1;
                        end

                        if (div_ready_int) begin
                            regfile_WriteEnable_o      <= 1'b1;
                            regfile_WriteData_o        <= {{32{div_rem_int[31]}}, div_rem_int[31:0]};
                            state                      <= S_IDLE;
                            div_is_upper_signed_int    <= 1'b0;
                            div_is_lower_signed_int    <= 1'b0;
                            decoder_opcode_ready_o     <= 1'b1;
                            execute_ready_o            <= 1'b1;
                        end
                    end

                    S_CSRRS: begin
                        zicsr_we_o  <= 1'b1;
                        zicsr_din_o <= zicsr_dout_i | regfile_rd1_i;
                        zicsr_addr_o    <= instr_reg6[31:20];
                        regfile_WriteEnable_o      <= 1'b1;
                        regfile_WriteData_o        <= zicsr_dout_i;
                        execute_ready_o            <= 1'b1;
                        decoder_opcode_ready_o     <= 1'b1;
                        state                      <= S_IDLE;
                    end

                    S_CSRRW: begin
                        zicsr_we_o  <= 1'b1;
                        zicsr_din_o <= regfile_rd1_i;
                        zicsr_addr_o    <= instr_reg6[31:20];
                        regfile_WriteEnable_o      <= 1'b1;
                        regfile_WriteData_o        <= zicsr_dout_i;
                        execute_ready_o            <= 1'b1;
                        decoder_opcode_ready_o     <= 1'b1;
                        state                      <= S_IDLE;
                    end
                    
                endcase
                end
            endcase
        end
    end : main_dec_block

    // initial begin
    //    if (regfile_WriteData_o === 4'hx) begin
    //       $stop;
    //    end 
    // end

    mystic_alu mystic_alu_inst(
        .clk_i                  (clk_i                     ),
        .rstn_i                 (rstn_i                    ),
        .alu_opcode_i           (alu_opcode_i              ),
        .alu_opcode_valid_i     (alu_opcode_valid_i        ),

        .alu_srcA_i             (alu_srcA                  ),
        .alu_srcB_i             (alu_srcB                  ),
        .alu_result_o           (alu_result                ),
        .alu_ready_o            (alu_ready_o               )
    );

    mystic_multiplier mystic_multiplier_inst (
        .clk_i                  (clk_i                     ),
        .rstn_i                 (rstn_i                    ),
        .mult_is_left_signed_i  (mult_is_left_signed_int   ),
        .mult_is_right_signed_i (mult_is_right_signed_int  ),
        .mult_enable_i          (mult_enable_int           ),
        .mult_data_left_i       (mult_data_left_int        ),
        .mult_data_right_i      (mult_data_right_int       ),
        .mult_result_upper_o    (mult_result_upper_int     ),
        .mult_result_lower_o    (mult_result_lower_int     ),
        .mult_ready_o           (mult_ready_int            )
    );

    mystic_divider mystic_divider_inst (
        .clk_i                  (clk_i                     ),
        .rstn_i                 (rstn_i                    ),
        .div_enable_i           (div_enable_int            ),
        .div_is_upper_signed_i  (div_is_upper_signed_int   ),
        .div_is_lower_signed_i  (div_is_lower_signed_int   ),
        .div_upper_operand_i    (div_upper_operand_int     ),
        .div_lower_operand_i    (div_lower_operand_int     ),
        .div_result_o           (div_result_int            ),
        .div_rem_o              (div_rem_int               ),
        .div_ready_o            (div_ready_int             ),
        .div_exception_o        (div_exception_int         )
    );

endmodule