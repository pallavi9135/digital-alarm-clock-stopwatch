`timescale 1ns / 1ps

module timekeeper (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_1hz,
    input  wire       set_mode,   // 1 = time set kar rahe hain (clock ruka rahega)
    input  wire       inc_hr,     // 1-cycle pulse
    input  wire       inc_min,    // 1-cycle pulse
    output reg  [4:0] hours,      // 0-23
    output reg  [5:0] mins,       // 0-59
    output reg  [5:0] secs        // 0-59
);
    always @(posedge clk) begin
        if (rst) begin
            hours <= 0; mins <= 0; secs <= 0;
        end else if (set_mode) begin
            secs <= 0;
            if (inc_hr)  hours <= (hours == 23) ? 5'd0 : hours + 1;
            if (inc_min) mins  <= (mins  == 59) ? 6'd0 : mins  + 1;
        end else if (tick_1hz) begin
            if (secs == 59) begin
                secs <= 0;
                if (mins == 59) begin
                    mins  <= 0;
                    hours <= (hours == 23) ? 5'd0 : hours + 1;
                end else mins <= mins + 1;
            end else secs <= secs + 1;
        end
    end
endmodule
