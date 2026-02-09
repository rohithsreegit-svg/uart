//=====================================================
// TOP MODULE : Button -> UART prints "12345"
//=====================================================
module uart_button_12345 (
    input  wire clk,        // 100 MHz clock
    input  wire button,     // Push button
    output wire tx           // UART TX pin
);

    // -------------------------------------------------
    // Button debounce
    // -------------------------------------------------
    reg [19:0] db_cnt = 0;
    reg btn_sync = 0;
    reg btn_pulse = 0;

    always @(posedge clk) begin
        btn_pulse <= 0;
        if (button == btn_sync)
            db_cnt <= 0;
        else begin
            db_cnt <= db_cnt + 1;
            if (db_cnt == 20'hFFFFF) begin
                btn_sync <= button;
                if (button)
                    btn_pulse <= 1;
            end
        end
    end

    // -------------------------------------------------
    // UART signals
    // -------------------------------------------------
    reg  tx_start = 0;
    reg  [7:0] tx_byte;
    wire tx_done;

    // -------------------------------------------------
    // FSM to send "12345"
    // -------------------------------------------------
    reg [2:0] state = 0;

    always @(posedge clk) begin
        tx_start <= 0;

        case (state)
            0: if (btn_pulse) begin
                    tx_byte  <= "1";
                    tx_start <= 1;
                    state    <= 1;
               end
            1: if (tx_done) begin
                    tx_byte  <= "2";
                    tx_start <= 1;
                    state    <= 2;
               end
            2: if (tx_done) begin
                    tx_byte  <= "3";
                    tx_start <= 1;
                    state    <= 3;
               end
            3: if (tx_done) begin
                    tx_byte  <= "4";
                    tx_start <= 1;
                    state    <= 4;
               end
            4: if (tx_done) begin
                    tx_byte  <= "5";
                    tx_start <= 1;
                    state    <= 5;
               end
            5: if (tx_done)
                    state <= 0;
        endcase
    end

    // -------------------------------------------------
    // UART Transmitter Instance
    // -------------------------------------------------
    uart_tx #(
        .CLKS_PER_BIT(868)   // 100 MHz / 115200 baud
    ) UART_TX_INST (
        .clk(clk),
        .tx_start(tx_start),
        .tx_byte(tx_byte),
        .tx_serial(tx),
        .tx_done(tx_done)
    );

endmodule


//=====================================================
// UART TRANSMITTER MODULE
//=====================================================
module uart_tx #(
    parameter CLKS_PER_BIT = 868
)(
    input  wire       clk,
    input  wire       tx_start,
    input  wire [7:0] tx_byte,
    output reg        tx_serial,
    output reg        tx_done
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;
    localparam CLEAN = 3'd4;

    reg [2:0] state = IDLE;
    reg [12:0] clk_cnt = 0;
    reg [2:0] bit_idx = 0;
    reg [7:0] data = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                tx_serial <= 1'b1;
                tx_done   <= 1'b0;
                clk_cnt   <= 0;
                bit_idx   <= 0;
                if (tx_start) begin
                    data  <= tx_byte;
                    state <= START;
                end
            end

            START: begin
                tx_serial <= 1'b0;
                if (clk_cnt < CLKS_PER_BIT-1)
                    clk_cnt <= clk_cnt + 1;
                else begin
                    clk_cnt <= 0;
                    state   <= DATA;
                end
            end

            DATA: begin
                tx_serial <= data[bit_idx];
                if (clk_cnt < CLKS_PER_BIT-1)
                    clk_cnt <= clk_cnt + 1;
                else begin
                    clk_cnt <= 0;
                    if (bit_idx < 7)
                        bit_idx <= bit_idx + 1;
                    else begin
                        bit_idx <= 0;
                        state   <= STOP;
                    end
                end
            end

            STOP: begin
                tx_serial <= 1'b1;
                if (clk_cnt < CLKS_PER_BIT-1)
                    clk_cnt <= clk_cnt + 1;
                else begin
                    clk_cnt <= 0;
                    tx_done <= 1'b1;
                    state   <= CLEAN;
                end
            end

            CLEAN: begin
                tx_done <= 1'b0;
                state   <= IDLE;
            end
        endcase
    end
endmodule
