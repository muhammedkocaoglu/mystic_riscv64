`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/21/2022 10:20:09 AM
// Design Name: 
// Module Name: mystic_zicsr
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


module mystic_zicsr(
        input  wire         clk_i,
        input  wire         rstn_i,
        input  wire         core_disable_n,
        input  wire         zicsr_we_i,
        input  wire [11:0]  zicsr_addr_i,
        input  wire [63:0]  zicsr_din_i,
        output reg  [63:0]  zicsr_dout_o
    );

    wire  [11:0]    bram_addr_int;
    wire            bram_we_int;
    wire  [63:0]    bram_din_int;
    reg   [19:0]    reset_cntr;

    reg  [63:0]  zicsr_dout_reg0;
    reg  [63:0]  zicsr_dout_reg1;
    reg  [63:0]  zicsr_dout_reg2;

    (* ram_style = "block" *) reg [63:0] ram [0:4095];

    generate
    integer ram_index;
    initial
        for (ram_index = 0; ram_index < 4096; ram_index = ram_index + 1) begin  
            ram[ram_index] = {64{1'b0}};
        end
    endgenerate


    assign bram_addr_int          = (core_disable_n == 1'b0) ? reset_cntr    : zicsr_addr_i;
    assign bram_we_int            = (core_disable_n == 1'b0) ? 1'b1          : zicsr_we_i;
    assign bram_din_int           = (core_disable_n == 1'b0) ? 0             : zicsr_din_i;

    always @(posedge clk_i) begin
        if (bram_we_int) begin
            ram[bram_addr_int]   <= bram_din_int;
        end
        zicsr_dout_reg0 <= ram[bram_addr_int];
        zicsr_dout_reg1 <= zicsr_dout_reg0;
        zicsr_dout_reg2 <= zicsr_dout_reg1;
        zicsr_dout_o    <= zicsr_dout_reg2;
    end


    // reset all elements of the block ram
    always @(posedge clk_i) begin
        if (!core_disable_n) begin
            if (reset_cntr >= 5000) begin
                reset_cntr  <= reset_cntr;
            end else begin
                reset_cntr  <= reset_cntr + 1;
            end
        end else begin
            reset_cntr  <= 0;
        end
    end
endmodule
