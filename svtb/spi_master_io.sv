interface spi_master_io (input bit clk);
    // Parameter
    parameter            SYS_FREQ = 100_000_000;
    parameter            SCK_FREQ = 25_000_000 ;
    
    // Logic
    logic            rst_n;
    logic            miso_i;
    logic            mosi_o;
    logic            sck_o;
    logic            cs_n_o;
    logic      [7:0] tx_byte_i;
    logic            tx_byte_valid_i;
    logic            ready_o;
    logic      [7:0] rx_byte_o;
    logic            rx_byte_valid_o;
    

    clocking cb @(posedge clk);
        default input #1ns output #1ns;

        output   rst_n;
        output   miso_i;
        input    mosi_o;
        input    sck_o;
        input    cs_n_o;
        output   tx_byte_i;
        output   tx_byte_valid_i;
        input    ready_o;
        input    rx_byte_o;
        input    rx_byte_valid_o;
        
    endclocking: cb

    // modport
    modport TB(clocking cb, input clk);

endinterface
