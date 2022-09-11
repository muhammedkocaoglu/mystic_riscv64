`timescale 1ns / 1ps


module top(
   input  clk_i,
   input  rst_ni,
 
   output uart_tx_o,
   input  uart_rx_i,
   
   output spi_cs_o,
   output spi_sck_o,
   output spi_mosi_o,
   input  spi_miso_i
);

wire          disable_core_n; // active low
wire   [7:0]  uart_mem_dout;
wire   [17:0] uart_mem_addr;
wire          uart_mem_we;

wire        iomem_valid;
wire        iomem_ready;
wire [ 3:0] iomem_wstrb;
wire [31:0] iomem_addr;
wire [63:0] iomem_wdata;
wire [63:0] iomem_rdata;

wire [ 3:0] main_mem_wstrb;
wire        main_mem_rd_en;


wire iomem_rd_instr_o;
wire iomem_is_compressed_i;
wire [31:0] iomem_instr_i;
wire [4:0]  iomem_byte_len_o;

wire        iomem_rd_o;
wire        iomem_we;

wire rst_n;
assign rst_n = rst_ni & disable_core_n;


mystic_soc mystic_soc_inst (
    .clk_i                  (clk_i        ),
    .rst_n                  (rst_n        ),
    .core_disable_n         (disable_core_n),   

    .iomem_rd_o             (iomem_rd_o),
    .iomem_ready            (iomem_ready),
    .iomem_we               (iomem_we),
    
    .iomem_byte_len_o       (iomem_byte_len_o),

    .iomem_addr             (iomem_addr   ),
    .iomem_wdata            (iomem_wdata  ),
    .iomem_rdata            (iomem_rdata  ),

    .iomem_instr_i          (iomem_instr_i),
    .iomem_is_compressed_i  (iomem_is_compressed_i),
    .iomem_rd_instr_o       (iomem_rd_instr_o),

    .spi_cs_o               (spi_cs_o     ),
    .spi_sck_o              (spi_sck_o    ),
    .spi_mosi_o             (spi_mosi_o   ),
    .spi_miso_i             (spi_miso_i   ),
    .uart_tx_o              (uart_tx_o    ),
    .uart_rx_i              (uart_rx_i    )
);

mystic_main_mem mystic_main_mem(
    .clk_i                  (clk_i),
    .rstn_i                 (rst_ni),
    .we_i                   (iomem_we),
    .rd_instr_i             (iomem_rd_instr_o),
    .rd_data_i              (iomem_rd_o),
    .byte_len_i             (iomem_byte_len_o),
    .addr_i                 (iomem_addr),
    .din_i                  (iomem_wdata),
    .dout_o                 (iomem_rdata),
    .instr_o                (iomem_instr_i),
    .dout_ready_o           (iomem_ready),
    .is_compressed_o        (iomem_is_compressed_i),

    .disable_core_n         (disable_core_n ), // active low
    .uart_mem_dout          (uart_mem_dout  ),
    .uart_mem_addr          (uart_mem_addr  ),
    .uart_mem_we            (uart_mem_we    )
);

mystic_main_mem_rx mystic_main_mem_rx(
        .clk_i              (clk_i          ),
        .rstn_i             (rst_ni         ),
        .rx_i               (uart_rx_i      ),
        .baud_div           (868            ), // clkfreq/baudrate as input
        .disable_core_n     (disable_core_n ), // active low
        .uart_mem_dout      (uart_mem_dout  ),
        .uart_mem_addr      (uart_mem_addr  ),
        .uart_mem_we        (uart_mem_we    )
    );


endmodule