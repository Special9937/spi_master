
module spi_master_top;
    
    parameter            SYS_FREQ = 100_000_000;
    parameter            SCK_FREQ = 25_000_000 ;
    parameter            PERIOD = 10;

    bit SystemClock;

    spi_master_io #(
        .SYS_FREQ        (SYS_FREQ),
        .SCK_FREQ        (SCK_FREQ)
    ) spi_master_io (
        SystemClock
    );
    
    spi_master_program #(
        .SYS_FREQ        (SYS_FREQ),
        .SCK_FREQ        (SCK_FREQ)
    ) test (
        spi_master_io
    );

    spi_master #(
        .SYS_FREQ        (SYS_FREQ),
        .SCK_FREQ        (SCK_FREQ)
    ) dut (
        .clk              (SystemClock),
        .rst_n            (spi_master_io.rst_n),
        .miso_i           (spi_master_io.miso_i),
        .mosi_o           (spi_master_io.mosi_o),
        .sck_o            (spi_master_io.sck_o),
        .cs_n_o           (spi_master_io.cs_n_o),
        .tx_byte_i        (spi_master_io.tx_byte_i),
        .tx_byte_valid_i  (spi_master_io.tx_byte_valid_i),
        .ready_o          (spi_master_io.ready_o),
        .rx_byte_o        (spi_master_io.rx_byte_o),
        .rx_byte_valid_o  (spi_master_io.rx_byte_valid_o)
    );

    initial begin
        SystemClock = 1;
        forever begin
            #(PERIOD/2)
            SystemClock = ~SystemClock;
        end
    end

endmodule
