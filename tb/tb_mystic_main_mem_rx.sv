`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/11/2022 01:44:08 PM
// Design Name: 
// Module Name: tb_mystic_main_mem_rx
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


module tb_mystic_main_mem_rx(

    );

    logic  [7:0]   din_i;
    logic          tx_start_i;
    logic          tx_done_tick_o;

    logic  		  clk_i = 1;
    logic  		  rstn_i = 0;
    logic  		  rx_i;
    logic  [15:0] baud_div = 868; // clkfreq/baudrate as input
    logic         disable_core_n; // active low
    logic  [7:0]  uart_mem_dout;
    logic  [17:0] uart_mem_addr;
    logic         uart_mem_we;

    always #10 clk_i   <= ~clk_i;

    logic [7:0] my_queue[$] = {8'hAB, 8'hCD, 8'h12, 8'h34};

    initial begin
        rstn_i <= 0;
        @(negedge clk_i);
        @(negedge clk_i);
        @(negedge clk_i);
        rstn_i <= 1;

        for (int i = 0; i < 25; i++) begin
            my_queue.push_back($urandom());
        end

        @(negedge clk_i);
        @(negedge clk_i);

        @(negedge clk_i);
        @(negedge clk_i);


        for (int i = 0; i < 25; i++) begin
            @(negedge clk_i);
            tx_start_i  <= 1'b1;
            din_i   <= my_queue[i];
            @(negedge clk_i);
            tx_start_i  <= 1'b0;
            @(posedge tx_done_tick_o);
        end


    end

    mystic_main_mem_rx mystic_main_mem_rx(
        .clk_i             (clk_i),
        .rstn_i            (rstn_i),
        .rx_i              (rx_i),
        .baud_div          (baud_div), // clkfreq/baudrate as input
        .disable_core_n    (disable_core_n), // active low
        .uart_mem_dout     (uart_mem_dout),
        .uart_mem_addr     (uart_mem_addr),
        .uart_mem_we       (uart_mem_we)
    );

    uart_tx uart_tx (
        .clk_i          (clk_i),
        .rstn_i         (rstn_i),
        .din_i          (din_i),
        .baud_div       (baud_div), // clkfreq/baudrate as input
        .tx_start_i     (tx_start_i),
        .tx_o           (rx_i),
        .tx_done_tick_o (tx_done_tick_o)
    );
endmodule
