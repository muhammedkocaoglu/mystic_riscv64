`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Muhammed KOCAOGLU
// E-mail: mdkocaoglu@gmail.com
//
// Create Date: 06/01/2022 09:29:08 AM
// Design Name: 
// Module Name: mystic_divider
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


module mystic_divider(
   input   wire          clk_i,
   input   wire          rstn_i,
   input   wire          div_enable_i,
   input   wire          div_is_upper_signed_i,
   input   wire          div_is_lower_signed_i,
   input   wire [63:0]   div_upper_operand_i,
   input   wire [63:0]   div_lower_operand_i,
   output  reg  [63:0]   div_result_o,
   output  reg  [63:0]   div_rem_o,
   output  reg           div_ready_o,
   output  reg           div_exception_o
);

reg [2:0] state;
localparam S_IDLE        = 3'b001;
localparam S_DIVIDE      = 3'b010;
localparam S_DONE        = 3'b100;

reg  [31:0] cntr;

reg  [63:0]   div_upper_operand_int;
reg  [63:0]   div_lower_operand_int;
reg           div_enable_int;
reg  [63:0]   div_result_int;
reg  [63:0]   div_rem_int;
reg           div_ready_int;
reg           div_exception_int;

reg  [1:0]    div_polarity;

always @(posedge clk_i, negedge rstn_i) begin
    if (!rstn_i) begin
        state               <= S_IDLE;
        div_ready_o         <= 1'b0;
        div_exception_o     <= 1'b0;
        div_polarity        <= 2'b00;
    end else begin

        case(state) 
            S_IDLE: begin
                div_ready_int       <= 1'b0;
                div_ready_o         <= 1'b0;
                div_exception_int   <= 1'b0;
                div_polarity        <= 2'b00;
                cntr                <= 0;
                if (div_enable_i) begin
                    if (div_lower_operand_int == {64{1'b0}}) begin
                        div_exception_int       <= 1'b1;
                        div_ready_int           <= 1'b1;
                        state                   <= S_DONE;
                    end else begin 
                        state                   <= S_DIVIDE;
                        div_upper_operand_int   <= {{24{1'b0}}, div_upper_operand_i[40:0]};
                        div_lower_operand_int   <= {{32{1'b0}}, div_lower_operand_i[31:0]};
                        // div_upper_operand_int   <= div_upper_operand_i;
                        // div_lower_operand_int   <= div_lower_operand_i;
                        if (div_is_upper_signed_i) begin
                            if (div_upper_operand_i[63]) begin
                                div_upper_operand_int   <= $unsigned(-div_upper_operand_i);
                                div_polarity[0]         <= 1'b1;                                    
                            end
                        end
                        
                        if (div_is_lower_signed_i) begin 
                            if (div_lower_operand_i[63]) begin
                                div_lower_operand_int   <= $unsigned(-div_lower_operand_i);
                                div_polarity[1]         <= 1'b1;                                    
                            end
                        end
                    end
                end
            end

            S_DIVIDE: begin
                if (div_upper_operand_int == div_lower_operand_int) begin
                    div_result_int          <= cntr + 1;
                    div_rem_int             <= 0;
                    div_ready_int           <= 1'b1;
                    state                   <= S_DONE;
                end else if (div_upper_operand_int < div_lower_operand_int) begin
                    div_result_int          <= cntr;
                    div_rem_int             <= div_upper_operand_int;
                    div_ready_int           <= 1'b1;
                    state                   <= S_DONE;
                end else begin 
                    div_upper_operand_int   <= div_upper_operand_int - div_lower_operand_int;
                    cntr                    <= cntr + 1;
                end
            end

            S_DONE: begin
                div_ready_o             <= div_ready_int;
                div_exception_o         <= div_exception_int;
                state                   <= S_IDLE;
                case (div_polarity) 
                    2'b00: begin
                        div_result_o    <= div_result_int;
                        div_rem_o       <= div_rem_int;
                    end
                    2'b01: begin
                        div_result_o    <= $unsigned(-div_result_int);
                        div_rem_o       <= $unsigned(-div_rem_int);
                    end
                    2'b10: begin
                        div_result_o    <= $unsigned(-div_result_int);
                        div_rem_o       <= div_rem_int;
                    end
                    2'b11: begin
                        div_result_o    <= div_result_int;
                        div_rem_o       <= $unsigned(-div_rem_int);   
                    end
                endcase
            end

            default: begin
                state   <= S_IDLE;
            end
            
        endcase
    end
end
endmodule