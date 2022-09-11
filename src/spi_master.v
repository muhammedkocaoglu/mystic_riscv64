`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/20/2022 09:55:25 AM
// Design Name: 
// Module Name: spi_master
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


module spi_master(
        input  wire         clk_i,
        input  wire         rstn_i,
        input  wire         en_i,
        input  wire         cpol_i,
        input  wire         cpha_i,
        input  wire [26:0]  clkdiv_i,
        input  wire [7:0]   mosi_data_i,
        output reg  [7:0]   miso_data_o,
        output reg          data_ready_o,
        output reg          cs_o,
        output reg          sclk_o,
        output reg          mosi_o,
        input  wire         miso_i
    );  
    
    reg [7:0] write_reg;
    reg [7:0] read_reg;  

    reg sclk_en;
    reg sclk;
    reg sclk_prev;
    reg sclk_rise;
    reg sclk_fall;


    reg mosi_en;
    reg miso_en;
    reg once;

    reg [4:0]  cntr;
    reg [26:0] edgecntr;

    reg [1:0] state;
    localparam S_IDLE        = 2'b01;
    localparam S_TRANSFER    = 2'b10;

    always @(*) begin
        case ({cpol_i, cpha_i})
            2'b00: begin
                mosi_en = sclk_fall;
			    miso_en	= sclk_rise;
            end

            2'b01: begin
                mosi_en = sclk_rise;
			    miso_en	= sclk_fall;
            end

            2'b10: begin
                mosi_en = sclk_rise;
                miso_en	= sclk_fall;
            end

            2'b11: begin
                mosi_en = sclk_fall;
                miso_en	= sclk_rise;	
            end
        endcase
    end

    always @(*) begin
        if (sclk && !sclk_prev) begin
            sclk_rise = 1'b1;
        end else begin
            sclk_rise = 1'b0;
        end

        if (!sclk && sclk_prev) begin
            sclk_fall = 1'b1;
        end else begin
            sclk_fall = 1'b0;
        end
    end

    always @(posedge clk_i, negedge rstn_i) begin
        if (!rstn_i) begin
            data_ready_o <= 1'b0;
            cs_o			<= 1'b1;
			mosi_o			<= 1'b0;
			sclk_o	        <= 1'b0;
			data_ready_o	<= 1'b0;			
			sclk_en			<= 1'b0;
			cntr			<= 0; 
            once            <= 1'b0;
            state           <= S_IDLE;
        end else begin
            data_ready_o    <=  1'b0;
	        sclk_prev	    <= sclk;
            case(state) 
                S_IDLE: begin
                    cs_o			<= 1'b1;
                    mosi_o			<= 1'b0;
                    data_ready_o	<= 1'b0;			
                    sclk_en			<= 1'b0;
                    cntr			<= 0; 

                    if (!cpol_i) begin
                        sclk_o	<= 1'b0;
                    end else begin
                        sclk_o	<= 1'b1;
                    end

                    if (en_i) begin
                        state		<= S_TRANSFER;
                        sclk_en		<= 1'b1;
                        write_reg	<= mosi_data_i;
                        mosi_o		<= mosi_data_i[7];
                        read_reg	<= 8'h00;
                    end
                end

                S_TRANSFER: begin
                    cs_o	<= 1'b0;
                    mosi_o	<= write_reg[7];

                    if (cpha_i) begin	
 
                        if (cntr == 0) begin
                            sclk_o	<= sclk;
                            if (miso_en) begin
                                read_reg[0]		<= miso_i;
                                read_reg[7:1] 	<= read_reg[6:0];
                                cntr			<= cntr + 1;
                                once            <= 1'b1;
                            end			
                        end else if (cntr == 8) begin
                            if (once) begin
                                data_ready_o	<= 1'b1;
                                once            <= 1'b0;				       
                            end					
                            miso_data_o		<= read_reg;
                            if (mosi_en) begin
                                if (en_i) begin
                                    write_reg	<= mosi_data_i;
                                    mosi_o		<= mosi_data_i[7];	
                                    sclk_o		<= sclk;							
                                    cntr		<= 0;
                                end else begin 
                                    state	<= S_IDLE;
                                    cs_o	<= 1'b1;							
                                end
                            end
                        end else if (cntr == 9) begin
                            if (miso_en) begin
                                state	<= S_IDLE;
                                cs_o	<= 1'b1;
                            end					
                        end else begin 
                            sclk_o	<= sclk;
                            if (miso_en) begin
                                read_reg[0]     <= miso_i;
                                read_reg[7:1] 	<= read_reg[6:0];
                                cntr            <= cntr + 1;
                            end
                            if (mosi_en) begin
                                mosi_o	<= write_reg[7];
                                write_reg[7:1] 	<= write_reg[6:0];
                            end
                        end
         
                    end else begin	// cpha_i = '0'
         
                        if (cntr == 0) begin
                            sclk_o	<= sclk;					
                            if (miso_en) begin
                                read_reg[0]			<= miso_i;
                                read_reg[7:1] 	    <= read_reg[6:0];
                                cntr				<= cntr + 1;
                                once                <= 1'b1;
                            end
                        end else if (cntr == 8) begin				
                            if (once) begin
                                data_ready_o    <= 1'b1;
                                once            <= 1'b0;                      
                            end
                            miso_data_o		<= read_reg;
                            sclk_o			<= sclk;
                            if (mosi_en) begin
                                if (en_i) begin
                                    write_reg	<= mosi_data_i;
                                    mosi_o		<= mosi_data_i[7];		
                                    cntr		<= 0;
                                end else begin
                                    cntr	<= cntr + 1;
                                end
                                if (miso_en) begin
                                    state	<= S_IDLE;
                                    cs_o	<= 1'b1;							
                                end
                            end		
                        end else if (cntr == 9) begin
                            if (miso_en) begin
                                state	<= S_IDLE;
                                cs_o	<= 1'b1;
                            end
                        end else begin
                            sclk_o	<= sclk;
                            if (miso_en) begin
                                read_reg[0]     <= miso_i;
                                read_reg[7:1] 	<= read_reg[6:0];
                                cntr            <= cntr + 1;
                            end
                            if (mosi_en) begin
                                write_reg[7:1] 	<= write_reg[6:0];
                            end
                        end			
         
                    end
                end
            endcase
        end
    end

    always @(posedge clk_i, negedge rstn_i) begin
        if (!rstn_i) begin
            edgecntr	<= 0;
            sclk	    <= 1'b0;
        end else begin
            if (sclk_en) begin
                if (edgecntr == clkdiv_i-1) begin
                    sclk 		<= ~sclk;
                    edgecntr	<= 0;
                end else begin 
                    edgecntr	<= edgecntr + 1;
                end
            end else begin 
                edgecntr	<= 0;
                if (!cpol_i) begin
                    sclk	<= 1'b0;
                end else begin 
                    sclk	<= 1'b1;
                end
            end
        end
    end
endmodule
