`timescale 1ns/1ps

module tb_uart_button_12345;

    // -----------------------------
    // Testbench signals
    // -----------------------------
    reg clk;
    reg button;
    wire tx;

    // -----------------------------
    // DUT instance
    // -----------------------------
    uart_button_12345 DUT (
        .clk(clk),
        .button(button),
        .tx(tx)
    );

    // -----------------------------
    // 100 MHz clock generation
    // Period = 10 ns
    // -----------------------------
    always #5 clk = ~clk;

    // -----------------------------
    // Test sequence
    // -----------------------------
    initial begin
        // Initial values
        clk    = 0;
        button = 0;

        // Wait for reset-like settling
        #100;

        // -------- Button press --------
        // Press button
        button = 1;
        #50_000_000;   // hold ~50 ms (debounce safe)

        // Release button
        button = 0;

        // Wait long enough for "12345" to transmit
        #10_000_000;

        // End simulation
        $stop;
    end

endmodule
