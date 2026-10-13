`timescale 1ns / 1ps

module clock_tb;

    reg        clk = 0;
    reg        rst = 1;
    reg        set_mode = 0;
    reg        inc_hr = 0, inc_min = 0;
    wire       tick_1hz, tick_100hz;
    wire [4:0] hours;
    wire [5:0] mins, secs;

    // chhote DIV, taaki sim tez chale: 1 "second" = 10 clk = 100 ns
    clk_divider #(.DIV_1HZ(10), .DIV_100HZ(2)) u_div (
        .clk(clk), .rst(rst),
        .tick_1hz(tick_1hz), .tick_100hz(tick_100hz)
    );

    timekeeper u_time (
        .clk(clk), .rst(rst), .tick_1hz(tick_1hz),
        .set_mode(set_mode), .inc_hr(inc_hr), .inc_min(inc_min),
        .hours(hours), .mins(mins), .secs(secs)
    );

    always #5 clk = ~clk;

    task pulse_hr;
        begin @(posedge clk); #1 inc_hr = 1; @(posedge clk); #1 inc_hr = 0; end
    endtask

    task pulse_min;
        begin @(posedge clk); #1 inc_min = 1; @(posedge clk); #1 inc_min = 0; end
    endtask

    // n tick_1hz ke baad time check karo
    task wait_ticks(input integer n);
        begin
            repeat (n) @(posedge tick_1hz);
            repeat (2) @(posedge clk);
            #1;
        end
    endtask

    task check(input [4:0] h, input [5:0] m, input [5:0] s);
        begin
            if (hours === h && mins === m && secs === s)
                $display("PASS: %02d:%02d:%02d", hours, mins, secs);
            else
                $display("FAIL: got %02d:%02d:%02d, expected %02d:%02d:%02d",
                          hours, mins, secs, h, m, s);
        end
    endtask

    // set mode se bahar aate waqt tick se align karo
    task exit_set_mode;
        begin
            @(posedge tick_1hz);
            @(posedge clk);
            #1 set_mode = 0;
        end
    endtask

    integer i;

    initial begin
        #30 rst = 0;
        @(posedge clk); #1;

        // 1. Reset ke baad 00:00:00
        check(0, 0, 0);

        // 2. Time set karo: 12:30
        set_mode = 1;
        for (i = 0; i < 12; i = i + 1) pulse_hr;
        for (i = 0; i < 30; i = i + 1) pulse_min;
        #20;
        check(12, 30, 0);

        // 3. 5 second chalne do
        exit_set_mode;
        wait_ticks(5);
        check(12, 30, 5);

        // 4. Time set karo: 23:59
        set_mode = 1;
        for (i = 0; i < 11; i = i + 1) pulse_hr;
        for (i = 0; i < 29; i = i + 1) pulse_min;
        #20;
        check(23, 59, 0);

        // 5. 59 second baad 23:59:59
        exit_set_mode;
        wait_ticks(59);
        check(23, 59, 59);

        // 6. Ek second aur: midnight rollover 00:00:00
        wait_ticks(1);
        check(0, 0, 0);

        $display("Simulation complete");
        $finish;
    end

endmodule
