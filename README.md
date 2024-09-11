# SPI(Serial Peripheral Interface) Master RTL Module
### Parameter list
| **Name** |     **Description**    |
|:--------:|:----------------------:|
| SYS_FREQ | System Clock Frequency |
| SCK_FREQ | SPI Clock Frequency    |

### I/O list
| **Sort** | **Bit** |     **Name**    |            **Description**           |
|----------|---------|:---------------:|:------------------------------------:|
| Input    |    1    | clk             | Main clock signal                    |
| Input    |    1    | rst_n           | Active low reset signal              |
| Input    |    1    | miso_i          | SPI master input/slave output signal |
| Input    |    1    | tx_byte_valid_i | TX data valid signal                 |
| Input    |    8    | tx_byte_i       | TX data signal                       |
| Output   |    1    | mosi_o          | SPI master output/slave input signal |
| Output   |    1    | sck_o           | SPI Clock signal                     |
| Output   |    1    | cs_n_o          | SPI Chip Select signal               |
| Output   |    1    | ready_o         | Module ready signal                  |
| Output   |    1    | rx_byte_valid_o | RX data valid signal                 |
| Output   |    8    | rx_byte_o       | RX data signal                       |

Language : Verilog HDL