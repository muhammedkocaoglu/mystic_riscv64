`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2022 11:10:36 AM
// Design Name: 
// Module Name: mystic_main_mem
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


module mystic_main_mem(
        input  logic        clk_i,
        input  logic        rstn_i,
        input  logic        we_i,
        input  logic        rd_instr_i,
        input  logic        rd_data_i,
        input  logic [4:0]  byte_len_i,
        input  logic [31:0] addr_i,
        input  logic [63:0] din_i,
        output logic [63:0] dout_o,
        output logic [31:0] instr_o,
        output logic        dout_ready_o,
        output logic        is_compressed_o,

        input wire          disable_core_n, // active low
        input wire   [7:0]  uart_mem_dout,
        input wire   [17:0] uart_mem_addr,
        input wire          uart_mem_we
    );
    parameter INIT_FILE = "D:/Desktop/tekno_test/teknofest_files/teknofest_files/test_codes/tekno_example_math/my_ram.txt";

    localparam BRAM_ADDR_WIDTH = 17;
    localparam BRAM_DATA_WIDTH = 8;

    logic                        bram_we_int;
    logic  [BRAM_ADDR_WIDTH-1:0] bram_addr_int;
    logic  [BRAM_DATA_WIDTH-1:0] bram_din_int;
    logic  [BRAM_DATA_WIDTH-1:0] bram_dout_int;

    logic [63:0] dout_reg;
    logic [63:0] din_reg;
    logic [31:0] instr_reg;

    typedef enum logic [7:0] {
        S_IDLE              = 8'b00000001,
        S_READ              = 8'b00000010,
        S_WRITE             = 8'b00000100,
        S_READ_INSTR_0      = 8'b00001000,
        S_READ_INSTR_1      = 8'b00010000,
        S_READ_INSTR_2      = 8'b00100000,
        S_READ_INSTR_3      = 8'b01000000,
        S_READ_INSTR_DELAY  = 8'b10000000
    } states_t;
    
    states_t state;

    logic [7:0] cntr;
    logic [1:0] c_opcode;


    always_ff @(posedge clk_i, negedge rstn_i) begin
        if(!rstn_i) begin
            state <= S_IDLE;
            cntr <= 0;
        end else begin 
            if (!disable_core_n) begin
                bram_we_int     <= uart_mem_we;
                bram_addr_int   <= uart_mem_addr[BRAM_ADDR_WIDTH-1:0];
                bram_din_int    <= uart_mem_dout;
                state <= S_IDLE;
                cntr <= 0;
            end else begin

                dout_ready_o    <= 1'b0;
                is_compressed_o    <= 1'b0;
                case (state)
                    S_IDLE: begin
                        if (rd_data_i) begin
                            state <= S_READ;
                            cntr <= 0;
                            bram_addr_int   <= addr_i;
                        end

                        if (we_i) begin
                            state <= S_WRITE;
                            cntr <= 0;
                            bram_addr_int   <= addr_i;
                            bram_we_int <= 1'b1;
                            din_reg     <= {8'h00, din_i[8*8-1:1*8]}; 
                            bram_din_int    <= din_i[7:0];
                        end

                        if (rd_instr_i) begin
                            state <= S_READ_INSTR_DELAY;
                            cntr <= 0;
                            bram_addr_int   <= addr_i;
                        end
                    end

                    S_READ: begin
                        if (cntr == 8) begin
                            cntr <= 0;
                            dout_ready_o    <= 1'b1;
                            state <= S_IDLE;
                        end else begin
                            cntr <= cntr + 1;
                        end
                        bram_addr_int   <= bram_addr_int + 1;
                        dout_reg    <= {bram_dout_int, dout_reg[8*8-1:1*8]};
                    end

                    S_WRITE: begin
                        din_reg <= din_reg >> 8;
                        bram_din_int    <= din_reg[7:0];
                        bram_we_int <= 1'b1;
                        cntr <= cntr + 1;
                        bram_addr_int   <= bram_addr_int + 1;
                        if (cntr == byte_len_i-1) begin
                            dout_ready_o    <= 1'b1;
                            bram_we_int <= 1'b0;
                            state <= S_IDLE;
                        end
                    end

                    S_READ_INSTR_DELAY: begin
                        state <= S_READ_INSTR_0;
                        bram_addr_int   <= bram_addr_int + 1;
                    end

                    S_READ_INSTR_0: begin
                        bram_addr_int   <= bram_addr_int + 1;
                        instr_reg[7:0]   <= bram_dout_int;
                        c_opcode        <= bram_dout_int[1:0];
                        state <= S_READ_INSTR_1;
                    end

                    S_READ_INSTR_1: begin
                        bram_addr_int   <= bram_addr_int + 1;
                        instr_reg[15:8]   <= bram_dout_int;
                        if (c_opcode != 2'b11) begin
                            state <= S_IDLE;
                            instr_reg[31:16] <= 16'h0000;
                            is_compressed_o    <= 1'b1;
                            dout_ready_o    <= 1'b1;
                        end else begin
                            state <= S_READ_INSTR_2;
                        end
                    end

                    S_READ_INSTR_2: begin
                        bram_addr_int   <= bram_addr_int + 1;
                        instr_reg[23:16]   <= bram_dout_int;
                        state <= S_READ_INSTR_3;
                    end

                    S_READ_INSTR_3: begin
                        bram_addr_int <= 0;
                        instr_reg[31:24] <= bram_dout_int;
                        state <= S_IDLE;
                        dout_ready_o <= 1'b1;
                    end
                        
                    default: begin
                        state <= S_IDLE;
                    end
                endcase

            end
        end
    end

    assign dout_o = dout_reg; 
    assign instr_o = instr_reg; 

    mystic_bram_sp  #(
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .INIT_FILE(INIT_FILE)
    )
    mystic_bram_sp_inst (
        .clk_i        (clk_i),
        .rstn_i       (rstn_i),
        .bram_we_i    (bram_we_int),
        .bram_addr_i  (bram_addr_int),
        .bram_din_i   (bram_din_int ),
        .bram_dout_o  (bram_dout_int)
    );

endmodule
