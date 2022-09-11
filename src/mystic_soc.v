`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/08/2022 10:36:33 PM
// Design Name: 
// Module Name: mystic_soc
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


module mystic_soc(
      input  wire        clk_i,       
      input  wire        rst_n,      
      input  wire        core_disable_n,    
      output reg         iomem_rd_o,
      input  wire        iomem_ready,
      output reg         iomem_we,

      output reg  [4:0]  iomem_byte_len_o,

      output reg  [31:0] iomem_addr,
      input  wire [63:0] iomem_rdata,
      output reg  [63:0] iomem_wdata,

      input  wire [31:0] iomem_instr_i,
      input  wire        iomem_is_compressed_i,
      output reg         iomem_rd_instr_o,

      output wire        spi_cs_o,   
      output wire        spi_sck_o,  
      output wire        spi_mosi_o, 
      input  wire        spi_miso_i,  
      output wire        uart_tx_o,  
      input  wire        uart_rx_i
   );

   reg   [31:0]     core_instr_i;
   reg              core_is_instr_compressed;
   reg              core_instr_ready;
   wire  [31:0]     PC_int;
   wire             PC_read_int;

   wire             core_data_read;
   wire             core_data_write;
   reg              core_data_ready;
   wire [31:0]      core_data_addr;
   reg  [63:0]      core_din; 
   wire [63:0]      core_dout; 
   wire  [4:0]      byte_len_o;


   mystic_riscv mystic_riscv_inst(
      .clk_i                     (clk_i),       
      .rstn_i                    (rst_n),       
      .core_disable_n            (core_disable_n),
      .instr_i                   (core_instr_i),
      .is_compressed_i           (core_is_instr_compressed),
      .instr_ready_i             (core_instr_ready),
      .byte_len_o                (byte_len_o),

      .data_cache_l1_read_o      (core_data_read),
      .data_cache_l1_write_o     (core_data_write),
      .data_cache_l1_din_o       (core_dout),
      .data_cache_l1_wr_strb_o   (),
      .data_cache_l1_addr_o      (core_data_addr),
      .data_cache_l1_dout_i      (core_din),
      .data_cache_l1_ready_i     (core_data_ready),

      .PC_o                      (PC_int),
      .PC_read_o                 (PC_read_int)
   );

    reg [3:0] state;
    localparam S_IDLE          = 0;
    localparam S_DATA_LOAD     = 1;
    localparam S_DATA_STORE    = 2;
    localparam S_INST          = 3;
    localparam S_UART          = 4;
    localparam S_SPI           = 5;
    localparam S_TIMER_LOAD    = 6;

    reg [7:0] cntr;

    // UART Peripheral
    reg            uart_enable_i;
    reg     [31:0] uart_addr_i;
    reg     [31:0] uart_din_i;
    wire    [31:0] uart_dout_o;
    wire           uart_ready_o;

    // SPI Peripheral
    reg            spi_enable_i;
    reg     [31:0] spi_addr_i;
    reg     [31:0] spi_din_i;
    wire    [31:0] spi_dout_o;
    wire           spi_ready_o;

    reg            uart_read_i;

    reg [31:0]  timer;

   always @(posedge clk_i, negedge rst_n ) begin
      if (!rst_n) begin
         state    <= S_IDLE;
      end else begin
            core_data_ready         <= 1'b0;
            core_instr_ready         <= 1'b0;
            uart_enable_i           <= 1'b0;
            uart_read_i             <= 1'b0;
            spi_enable_i            <= 1'b0;
            iomem_rd_instr_o        <= 1'b0;
            iomem_rd_o         <= 1'b0;
            core_is_instr_compressed   <= 1'b0;
            iomem_we                <= 1'b0;
         case(state) 
            S_IDLE: begin
             
               cntr  <= 0;
               
               if (core_data_read) begin
                    if (core_data_addr == 32'h4000_0000 || core_data_addr == 32'h4000_0004 || core_data_addr == 32'h4000_0008 || core_data_addr == 32'h4000_000c) begin
                       uart_enable_i  <= 1'b1;
                       uart_read_i    <= 1'b1;
                       uart_addr_i    <= core_data_addr;
                       uart_din_i     <= core_dout[31:0];
                       state          <= S_UART;
                    end else begin
                        if (core_data_addr[29]) begin
                            iomem_addr  <= core_data_addr[15:0] + 2048*4;
                        end else begin
                            iomem_addr    <= core_data_addr;
                        end
                        state <= S_DATA_LOAD;
                        iomem_rd_o <= 1'b1;
                    end
                end

               if (core_data_write) begin
                  if (core_data_addr == 32'h4000_0000 || core_data_addr == 32'h4000_0004 || core_data_addr == 32'h4000_0008 || core_data_addr == 32'h4000_000c) begin
                     uart_enable_i  <= 1'b1;
                     uart_read_i    <= 1'b0;
                     uart_addr_i    <= core_data_addr;
                     uart_din_i     <= core_dout[31:0];
                     state          <= S_UART;
                //   end else if (core_data_addr == 32'h2001_0000 || core_data_addr == 32'h2001_0004 || core_data_addr == 32'h2001_0008 || core_data_addr == 32'h2001_000c || core_data_addr == 32'h2001_0010) begin 
                //      spi_enable_i  <= 1'b1;
                //      spi_addr_i    <= core_data_addr;
                //      spi_din_i     <= core_dout[31:0];
                //      state         <= S_SPI;
                end else begin
                    if (core_data_addr[29]) begin
                        iomem_addr  <= core_data_addr[15:0] + 2048*4;
                    end else begin
                        iomem_addr    <= core_data_addr;
                    end

                    state <= S_DATA_STORE;
                    iomem_we   <= 1'b1;
                    iomem_byte_len_o    <= byte_len_o;
                    iomem_wdata <= core_dout;
                 end
               end

               if (PC_read_int) begin
                    iomem_rd_instr_o   <= 1'b1;
                    iomem_addr        <= PC_int;
                    state             <= S_INST;
               end
            end

            S_DATA_STORE: begin
                if (iomem_ready) begin
                    core_data_ready   <= 1'b1;
                    state    <= S_IDLE;
                end
            end

            S_DATA_LOAD: begin
                if (iomem_ready) begin
                    core_din    <= iomem_rdata;
                    core_data_ready   <= 1'b1;
                    state    <= S_IDLE;
                end
            end

            S_INST: begin
                if (iomem_ready) begin
                    core_instr_ready  <= 1'b1;
                    core_instr_i   <= iomem_instr_i;
                    core_is_instr_compressed   <= iomem_is_compressed_i;
                    state   <= S_IDLE;
                end
            end

            S_UART: begin
               if (uart_ready_o) begin
                  state <= S_IDLE;
                  core_data_ready  <= 1'b1;
                  core_din    <= uart_dout_o;
               end
            end

            S_SPI: begin
               if (spi_ready_o) begin
                  state <= S_IDLE;
                  core_data_ready  <= 1'b1;
                  core_din    <= spi_dout_o;
               end
            end

            S_TIMER_LOAD: begin
               state <= S_IDLE;
               core_data_ready  <= 1'b1;
               core_din    <= timer;
            end
         endcase
      end
   end


    always @(posedge clk_i) begin
        if (!rst_n) begin
            timer <= 32'h0;
        end else begin
            timer <= timer + 32'h1;
        end
    end

    uart_top uart_top_inst (
        .clk_i            (clk_i                  ),
        .rstn_i           (rst_n                  ),
        .uart_rx_i        (uart_rx_i              ),
        .uart_tx_o        (uart_tx_o              ),
        .uart_enable_i    (uart_enable_i          ),
        .uart_read_i      (uart_read_i            ),
        .uart_addr_i      (uart_addr_i            ),
        .uart_din_i       (uart_din_i             ),
        .uart_dout_o      (uart_dout_o            ),
        .uart_ready_o     (uart_ready_o           )
    );


    spi_master_top spi_master_top_inst (
        .clk_i            (clk_i                  ),
        .rstn_i           (rst_n                  ),
        .spi_enable_i     (spi_enable_i           ),
        .spi_addr_i       (spi_addr_i             ),
        .spi_din_i        (spi_din_i              ),
        .spi_cs_o         (spi_cs_o               ),
        .spi_sclk_o       (spi_sck_o              ),
        .spi_mosi_o       (spi_mosi_o             ),
        .spi_miso_i       (spi_miso_i             ),
        .spi_dout_o       (spi_dout_o             ),
        .spi_ready_o      (spi_ready_o            )
    );
endmodule
