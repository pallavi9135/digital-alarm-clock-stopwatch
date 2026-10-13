`timescale 1ns / 1ps

module stopwatch (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_100hz,   // 100 Hz tick (clk_divider se)
    input  wire       start_stop,   // 1-cycle pulse: start/stop toggle
    input  wire       clear,        // 1-cycle pulse: reset (sirf ruke hue)
    output reg        running,
    output reg  [6:0] cs,           // centisecond 0-99
    output reg  [5:0] sec,          // 0-59
    output reg  [5:0] min           // 0-59
);
    always @(posedge clk) begin
        if (rst) begin
            running <= 0;
            cs <= 0; sec <= 0; min <= 0;
        end else begin
            if (start_stop) running <= ~running;

            if (clear && !running) begin
                cs <= 0; sec <= 0; min <= 0;
            end else if (running && tick_100hz) begin
                if (cs == 99) begin
                    cs <= 0;
                    if (sec == 59) begin
                        sec <= 0;
                        min <= (min == 59) ? 6'd0 : min + 1;
                    end else sec <= sec + 1;
                end else cs <= cs + 1;
            end
        end
    end
endmodule