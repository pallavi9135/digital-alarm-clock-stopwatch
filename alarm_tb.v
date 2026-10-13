`timescale 1ns / 1ps

module alarm_tb;

    reg        clk = 0;
    reg        rst = 1;
    reg        set_mode = 0, set_alarm = 0;
    reg        inc_hr = 0, inc_min = 0;
    reg        alarm_en = 1, dismiss = 0;
    wire       tick_1hz, tick_100hz;
    wire [4:0] hours, alarm_hr;
    wire [5:0] mins, secs, alarm_min;
    wire       ringing;

    // chhote DIV: 1 "second" = 10 clk = 100 ns
    clk_divider #(.DIV_1HZ(10), .DIV_100HZ(2)) u_div (
        .clk(clk), .rst(rst),
        .tick_1hz(tick_1hz), .tick_100hz(tick_100hz)
    );

    timekeeper u_time (
        .clk(clk), .rst(rst), .tick_1hz(tick_1hz),
        .set_mode(set_mode), .inc_hr(inc_hr), .inc_min(inc_min),
        .hours(hours), .mins(mins), .secs(secs)
    );

    alarm u_alarm (
        .clk(clk), .rst(rst),
        .set_alarm(set_alarm), .inc_hr(inc_hr), .inc_min(inc_min),
        .alarm_en(alarm_en), .dismiss(dismiss),
        .hours(hours), .mins(mins),
        .alarm_hr(alarm_hr), .alarm_min(alarm_min), .ringing(ringing)
    );

    always #5 clk = ~clk;

    task pulse_hr;
        begin @(posedge clk); #1 inc_hr = 1; @(posedge clk); #1 inc_hr = 0; end
    endtask

    task pulse_min;
        begin @(posedge clk); #1 inc_min = 1; @(posedge clk); #1 inc_min = 0; end
    endtask

    task pulse_dismiss;
        begin @(posedge clk); #1 dismiss = 1; @(posedge clk); #1 dismiss = 0; end
    endtask

    task wait_ticks(input integer n);
        begin
            repeat (n) @(posedge tick_1hz);
            repeat (2) @(posedge clk);
            #1;
        end
    endtask

    task exit_set_mode;
        begin
            @(posedge tick_1hz);
            @(posedge clk);
            #1 set_mode = 0;
        end
    endtask

    task report(input ok, input [8*40:1] name);
        begin
            if (ok) $display("PASS: %0s  (time %02d:%02d:%02d)", name, hours, mins, secs);
            else    $display("FAIL: %0s  (time %02d:%02d:%02d)", name, hours, mins, secs);
        end
    endtask

    integer i;

    initial begin
        #30 rst = 0;
        @(posedge clk); #1;

        // 1. Alarm 08:30 set karo
        set_alarm = 1;
        for (i = 0; i < 8;  i = i + 1) pulse_hr;
        for (i = 0; i < 30; i = i + 1) pulse_min;
        set_alarm = 0;
        report(alarm_hr === 8 && alarm_min === 30, "alarm set to 08:30");

        // 2. Current time 08:29 set karo
        set_mode = 1;
        for (i = 0; i < 8;  i = i + 1) pulse_hr;
        for (i = 0; i < 29; i = i + 1) pulse_min;
        #20;
        report(hours === 8 && mins === 29 && secs === 0, "time set to 08:29:00");
        exit_set_mode;

        // 3. 08:29:59: abhi alarm nahi bajna chahiye
        wait_ticks(59);
        report(ringing === 0, "not ringing at 08:29:59");

        // 4. 08:30:00: alarm bajna chahiye
        wait_ticks(1);
        report(ringing === 1, "ringing at 08:30:00");

        // 5. Dismiss na karo to bajta rahe
        wait_ticks(5);
        report(ringing === 1, "still ringing at 08:30:05");

        // 6. Dismiss
        pulse_dismiss;
        report(ringing === 0, "dismiss stops the alarm");

        // 7. Usi minute mein dobara nahi bajna chahiye
        wait_ticks(10);
        report(ringing === 0, "stays off for rest of the minute");

        // 8. Minute badalne ke baad
        wait_ticks(45);
        report(ringing === 0, "off at 08:31:00");

        // 9. Alarm 08:32 set karo aur alarm_en = 0
        set_alarm = 1;
        pulse_min; pulse_min;
        set_alarm = 0;
        alarm_en = 0;
        wait_ticks(61);
        report(ringing === 0, "alarm disabled, no ring at 08:32");

        // 10. Alarm enable karo, to turant bajna chahiye (08:32 chal raha hai)
        alarm_en = 1;
        repeat (2) @(posedge clk);
        #1;
        report(ringing === 1, "ring after enabling at 08:32");

        $display("Simulation complete");
        $finish;
    end

endmodule
