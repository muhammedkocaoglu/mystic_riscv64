`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/30/2022 09:14:53 AM
// Design Name: 
// Module Name: bram_sp
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


module mystic_bram_sp #(
      parameter BRAM_DATA_WIDTH = 24,
      parameter BRAM_ADDR_WIDTH = 8,
      parameter INIT_FILE = "C:/Users/TUTEL/Desktop/TEKNOFEST/tekno_sw/outputs/hex/uart_test.hex"
   )(
      input  wire                             clk_i,
      input  wire                             rstn_i,
      input  wire                             bram_we_i,
      input  wire    [BRAM_ADDR_WIDTH-1:0]    bram_addr_i,
      input  wire    [BRAM_DATA_WIDTH-1:0]    bram_din_i,
      output reg     [BRAM_DATA_WIDTH-1:0]    bram_dout_o
   );
    
   (* ram_style = "block" *) 
   reg [BRAM_DATA_WIDTH-1:0] ram [2**BRAM_ADDR_WIDTH-1:0];

   wire  [BRAM_ADDR_WIDTH-1:0]   bram_addr_int;
   wire                          bram_we_int;
   wire  [BRAM_DATA_WIDTH-1:0]   bram_din_int;
   reg   [19:0]                  reset_cntr;
   reg                           reset_valid;

//    assign bram_addr_int          = reset_valid ? reset_cntr    : bram_addr_i;
   assign bram_addr_int     = bram_addr_i;
//    assign bram_we_int            = reset_valid ? 1'b1          : bram_we_i;
   assign bram_we_int       =  bram_we_i;
//    assign bram_din_int           = reset_valid ? 0             : bram_din_i;
   assign bram_din_int      =  bram_din_i;

    initial begin
        $readmemh(INIT_FILE, ram, 0, 2**BRAM_ADDR_WIDTH-1);
    end
    
   always @(posedge clk_i) begin
      if (bram_we_int) begin
         ram[bram_addr_int]	<= bram_din_int;
      end
      bram_dout_o	<= ram[bram_addr_int];
   end

    // reset all elements of the block ram
   always @(posedge clk_i, negedge rstn_i) begin
      if (!rstn_i) begin
         reset_cntr  <= 0;
         reset_valid <= 1'b0;
      end else begin
         if (reset_cntr >= 2**BRAM_ADDR_WIDTH) begin
            reset_cntr  <= reset_cntr;
            reset_valid <= 1'b0;
         end else begin
            reset_cntr  <= reset_cntr + 1;
            reset_valid <= 1'b0;
         end
      end
   end
    
endmodule
    
