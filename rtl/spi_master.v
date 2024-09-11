// /+FHDR-------------------------------------------------------------------------
// FILE NAME      : spi_master.v
// PROJECT        : SPI
// AUTHOR         : Junho Lee
// AUTHOR's EMAIL : bless4088@gmail.com
// ------------------------------------------------------------------------------
// DESCRIPTION
// SPI Master Module
// ------------------------------------------------------------------------------
// PARAMETERS
// NAME(DEFAULT)         DESCRIPTION
// SYS_FREQ              System Clock Frequency
// SCK_FREQ              SPI Clock Frequency
// ------------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR           DESCRIPTION
// 1.0     2024-04-25  Junho Lee     Initial version
// ------------------------------------------------------------------------------
// REUSE ISSUES
// * Clock Domains  : System level posedge clock (clk)
// * Reset Strategy : System level negedge reset (rst_n)
// * Instantiations : N/A
// * Synthesizable  : Y (Design Compiler, Xilinx Vivado)
// * Other          :
// -FHDR-------------------------------------------------------------------------
module spi_master #(
    parameter SYS_FREQ = 100_000_000, // 100MHz
    parameter SCK_FREQ = 25_000_000 // SCK Clock = 25MHz
) (
    // System Signal
    input             clk,
    input             rst_n,


    // External Signal
    input             miso_i, // MISO
    output wire       mosi_o, // MOSI
    output wire       sck_o,    // SCK
    output wire       cs_n_o, // CS
    
    // Internal Signal
    input [7:0]       tx_byte_i,
    input             tx_byte_valid_i,
    output wire       ready_o,
    output wire [7:0] rx_byte_o,
    output wire       rx_byte_valid_o
);

    wire com_done;
    reg [7:0] tx_data;

    // FSM.STATE.ENUM
    localparam IDLE  = 3'b001;
    localparam SEND  = 3'b010;
    localparam STOP  = 3'b100;

    // FSM.STATE.REGISTER
    reg [2:0] state_cs;
    reg [2:0] state_ns;

    //-----------------------------------------------------------------
    // FSM.NAME : state
    // FSM.ENUM : IDLE, SEND, STOP
    //-----------------------------------------------------------------
    reg send_en;
    reg spi_tx;
    reg cs_n;
    reg rx_byte_valid;
    reg ready;
    // FSM.STATE.TRANSITION
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_cs <= IDLE;
        end else begin
            state_cs <= state_ns;
        end
    end

    always @ (*) begin
        state_ns = state_cs;
        send_en = 1'b0;
	cs_n = 1'b1;
        spi_tx = 1'b1;
        rx_byte_valid = 1'b0;
        ready = 1'b0;
        case(state_cs)
            IDLE : begin
                ready = 1'b1;
                if(tx_byte_valid_i) begin
                    send_en = 1'b1;
                    state_ns = SEND;
                end
            end
            SEND: begin
		cs_n = 1'b0;
                spi_tx = tx_data[7];
                if(com_done) begin
                    state_ns = STOP;
                end
            end
            STOP : begin
                rx_byte_valid = 1'b1;
                state_ns = IDLE;
            end
            default : begin
                state_ns = IDLE;
            end
        endcase
    end // always @ (*)

    //-----------------------------------------------------------------
    // Title       : SCK Generation
    //-----------------------------------------------------------------
    // Local Parameter
    localparam ClockRatio = SYS_FREQ / SCK_FREQ; // Clock Ratio is system clock / spi sck
    localparam CountMax = ClockRatio / 2; // Counter Max value is half of ClockRatio
    localparam CW = $clog2(CountMax);

    wire sck_en;
    assign sck_en = (state_cs == SEND);

    reg [CW-1:0] sck_cnt;
    wire [CW-1:0] n_sck_cnt;
    wire sck_last;

    assign sck_last = (sck_cnt == CountMax - 1);
    assign n_sck_cnt = sck_last ? {CW{1'b0}} : sck_cnt + 1'b1;

    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sck_cnt <= {CW{1'b0}};
        end else begin
            if(sck_en) begin
                sck_cnt <= n_sck_cnt;
            end
        end
    end

    reg sck;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sck <= 1'b0;
        end else begin
            if(sck_en & sck_last) begin
                sck <= ~sck;
            end
        end
    end

    // Edge Detection
    wire sck_posedge;
    wire sck_negedge;

    assign sck_posedge = sck_last & !sck;
    assign sck_negedge = sck_last & sck;

    //-----------------------------------------------------------------
    // Title       : Data Control
    //-----------------------------------------------------------------
    reg [2:0] idx;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tx_data <= 8'd0;
        end else begin
            if(tx_byte_valid_i & ready) begin
                tx_data <= tx_byte_i;
            end else if(sck_negedge) begin
                tx_data <= {tx_data[6:0], 1'b0};
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            idx <= 3'd0;
        end else begin
            if(send_en) begin
                idx <= 3'd7;
            end else if(sck_negedge) begin
                idx <= idx - 1'b1;
            end
        end
    end

    reg [7:0] rx_data;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rx_data <= 8'd0;
        end else begin
            if(sck_posedge & (state_cs == SEND)) begin
                rx_data <= {rx_data[6:0], miso_i};
            end
        end
    end

    assign com_done = !(|idx) & sck_negedge;
    //-----------------------------------------------------------------
    // Title       : Output Assignment
    //-----------------------------------------------------------------
    assign sck_o = sck_en ? sck : 1'b0;
    assign mosi_o = spi_tx;
    assign cs_n_o = cs_n;
    assign ready_o = ready;
    assign rx_byte_o = rx_data;
    assign rx_byte_valid_o = rx_byte_valid;
endmodule
