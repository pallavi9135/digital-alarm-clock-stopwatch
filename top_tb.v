`timescale 1ns / 1ps

module top_tb;

    reg clk = 0, rst = 1;
    reg btn_mode = 0, btn_hr = 0, btn_min = 0, btn_ss = 0, btn_clear = 0;
    reg alarm_en = 1;

    wire [1:0] mode;
    wire [4:0] hours, alarm_hr;
    wire [5:0] mins, secs, alarm_min, sw_min, sw_sec;
    wire [6:0] sw_cs;
    wire       ringing, sw_running;

    // chhote DIV: 1 "second" = 10 clk, 1 centisecond = 2 clk
    top #(.DIV_1HZ(10), .DIV_100HZ(2)) dut (
        .clk(clk), .rst(rst),
        .btn_mode(btn_mode), .btn_hr(btn_hr), .btn_min(btn_min),
        .btn_ss(btn_ss), .btn_clear(btn_clear), .alarm_en(alarm_en),
        .mode(mode), .hours(hours), .mins(mins), .secs(secs),
        .alarm_hr(alarm_hr), .alarm_min(alarm_min), .ringing(ringing),
        .sw_running(sw_running), .sw_min(sw_min), .sw_sec(sw_sec), .sw_cs(sw_cs)
    );

    always #5 clk = ~clk;

    task press_mode;  begin btn_mode  = 1; repeat (4) @(posedge clk); btn_mode  = 0; repeat (6) @(posedge clk); end endtask
    task press_hr;    begin btn_hr    = 1; repeat (4) @(posedge clk); btn_hr    = 0; repeat (6) @(posedge clk); end endtask
    task press_min;   begin btn_min   = 1; repeat (4) @(posedge clk); btn_min   = 0; repeat (6) @(posedge clk); end endtask
    task press_ss;    begin btn_ss    = 1; repeat (4) @(posedge clk); btn_ss    = 0; repeat (6) @(posedge clk); end endtask
    task press_clear; begin btn_clear = 1; repeat (4) @(posedge clk); btn_clear = 0; repeat (6) @(posedge clk); end endtask

    task report(input ok, input [8*40:1] name);
        begin
            if (ok) $display("PASS: %0s", name);
            else    $display("FAIL: %0s  (mode=%0d time=%02d:%02d:%02d)", name, mode, hours, mins, secs);
        end
    endtask

    integer i, t;

    initial begin
        #30 rst = 0;
        repeat (3) @(posedge clk);
        #1;
        report(mode === 0 && hours === 0 && mins === 0, "reset: CLOCK mode, 00:00");

        // Time set karo: 09:05
        press_mode;
        report(mode === 1, "mode -> SET_TIME");
        for (i = 0; i < 9; i = i + 1) press_hr;
        for (i = 0; i < 5; i = i + 1) press_min;
        report(hours === 9 && mins === 5 && secs === 0, "time set to 09:05:00");

        // Alarm set karo: 09:06
        press_mode;
        report(mode === 2, "mode -> SET_ALARM");
        for (i = 0; i < 9; i = i + 1) press_hr;
        for (i = 0; i < 6; i = i + 1) press_min;
        report(alarm_hr === 9 && alarm_min === 6, "alarm set to 09:06");
        report(hours === 9 && mins === 5, "clock time unaffected by alarm setting");

        // Stopwatch
        press_mode;
        report(mode === 3, "mode -> STOPWATCH");
        press_ss;
        report(sw_running === 1, "stopwatch started");
        repeat (250) @(posedge clk);
        #1;
        report(sw_sec === 1, "stopwatch counted past 1 second");
        press_ss;
        report(sw_running === 0, "stopwatch stopped");
        press_clear;
        report(sw_min === 0 && sw_sec === 0 && sw_cs === 0, "stopwatch cleared");

        // CLOCK mode mein wapas, alarm ka wait
        press_mode;
        report(mode === 0, "mode wraps back to CLOCK");

        t = 0;
        while (!ringing && t < 3000) begin @(posedge clk); t = t + 1; end
        #1;
        report(ringing === 1 && hours === 9 && mins === 6, "alarm rings at 09:06");

        press_ss;   // CLOCK mode mein btn_ss = alarm dismiss
        report(ringing === 0, "button dismisses the alarm");

        $display("Simulation complete");
        $finish;
    end

endmodule
