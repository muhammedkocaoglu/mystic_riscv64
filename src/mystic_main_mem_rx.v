`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2022 01:17:25 PM
// Design Name: 
// Module Name: mystic_main_mem_rx
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


module mystic_main_mem_rx(
        input  wire  		clk_i,
        input  wire  		rstn_i,
        input  wire  		rx_i,
        input  wire  [15:0] baud_div, // clkfreq/baudrate as input
        output reg          disable_core_n, // active low
        output reg   [7:0]  uart_mem_dout,
        output reg   [17:0] uart_mem_addr,
        output reg          uart_mem_we
    );

    wire        rx_done_tick_o;
    wire  [7:0] dout_o;

    reg [3:0] state;
    parameter S_IDLE    = 4'b0001;
    parameter S_DATA    = 4'b0010;
    parameter S_FILL_0  = 4'b0100;

    reg [20:0]      cntr;
    reg [31:0]      cntr_timeout;
    reg [4*8-1:0]   header_buffer;



    always @(posedge clk_i, negedge rstn_i) begin
        if (!rstn_i) begin
            cntr  <= 0;
            cntr_timeout    <= 0;
            disable_core_n  <= 1'b1;
            header_buffer   <= 0;
            state   <= S_IDLE;
        end else begin
            uart_mem_we     <= 1'b0;
            case (state)
                S_IDLE: begin
                    disable_core_n  <= 1'b1;
                    cntr_timeout    <= 0;
                    cntr    <= 0;
                    if (rx_done_tick_o) begin
                        header_buffer   <= {header_buffer[23:0], dout_o};
                    end

                    if (header_buffer == 32'hABCD1234) begin
                        state <= S_DATA;
                        disable_core_n  <= 1'b0;
                    end
                end

                S_DATA: begin
                    if (rx_done_tick_o) begin
                        uart_mem_dout   <= dout_o;
                        uart_mem_addr   <= cntr;
                        cntr            <= cntr + 1;
                        uart_mem_we     <= 1'b1;
                        cntr_timeout    <= 0;
                    end else begin
                        cntr_timeout    <= cntr_timeout + 1;
                    end
                    
                    if (cntr_timeout >= 200_000) begin
                        state <= S_FILL_0;
                        header_buffer   <= 0;
                    end
                end

                S_FILL_0: begin
                    if (cntr >= 2**17) begin
                        state <= S_IDLE;
                        cntr <= 0;
                    end else begin
                        uart_mem_dout   <= 0;
                        uart_mem_addr   <= cntr;
                        cntr            <= cntr + 1;
                        uart_mem_we     <= 1'b1;
                    end
                end

            default: begin
                state <= S_IDLE;
            end
           endcase
        end
     end

uart_rx uart_rx (
    .clk_i           (clk_i           ),
    .rstn_i          (rstn_i          ),
    .rx_i            (rx_i            ),
    .baud_div        (baud_div        ), // clkfreq/baudrate as input
    .dout_o          (dout_o          ),
    .rx_done_tick_o  (rx_done_tick_o  )             
);


endmodule
