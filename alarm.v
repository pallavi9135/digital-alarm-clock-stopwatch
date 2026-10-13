`timescale 1ns / 1ps

module alarm (
    input  wire       clk,
    input  wire       rst,
    input  wire       set_alarm,   // 1 = alarm time set kar rahe hain
    input  wire       inc_hr,      // 1-cycle pulse
    input  wire       inc_min,     // 1-cycle pulse
    input  wire       alarm_en,    // alarm on/off switch
    input  wire       dismiss,     // buzzer band karo
    input  wire [4:0] hours,       // current time (timekeeper se)
    input  wire [5:0] mins,
    output reg  [4:0] alarm_hr,
    output reg  [5:0] alarm_min,
    output reg        ringing
);
    reg blocked;   // dismiss ke baad, isi minute mein dobara na bajne ke liye

    wire match = alarm_en && (hours == alarm_hr) && (mins == alarm_min);

    always @(posedge clk) begin
        if (rst) begin
            alarm_hr  <= 0;
            alarm_min <= 0;
            ringing   <= 0;
            blocked   <= 0;
        end else begin
            // alarm time set karna
            if (set_alarm) begin
                if (inc_hr)  alarm_hr  <= (alarm_hr  == 23) ? 5'd0 : alarm_hr  + 1;
                if (inc_min) alarm_min <= (alarm_min == 59) ? 6'd0 : alarm_min + 1;
            end

            // alarm bajana
            if (!match) begin
                ringing <= 0;
                blocked <= 0;
            end else if (dismiss) begin
                ringing <= 0;
                blocked <= 1;
            end else if (!blocked) begin
                ringing <= 1;
            end
        end
    end
endmodule