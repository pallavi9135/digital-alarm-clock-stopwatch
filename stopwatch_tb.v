`timescale 1ns / 1ps

module stopwatch_tb;

    reg        clk = 0;
    reg        rst = 1;
    reg        start_stop = 0;
    reg        clear = 0;
    wire       tick_1hz, tick_100hz;
    wire       running;
    wire [6:0] cs;
    wire [5:0] sw_sec, sw_min;

    // chhota DIV: 1 centisecond = 2 clk = 20 ns
    clk_divider #(.DIV_1HZ(10), .DIV_100HZ(2)) u_div (
        .clk(clk), .rst(rst),
        .tick_1hz(tick_1hz), .tick_100hz(tick_100hz)
    );

    stopwatch u_sw (
        .clk(clk), .rst(rst), .tick_100hz(tick_100hz),
        .start_stop(start_stop), .clear(clear),
        .running(running), .cs(cs), .sec(sw_sec), .min(sw_min)
    );

    always #5 clk = ~clk;

    
    integer gold;
    always @(posedge clk) begin
        if (rst)                    gold <= 0;
        else if (clear && !running) gold <= 0;
        else if (running && tick_100hz) gold <= gold + 1;
    end

    wire [31:0] dut_total = sw_min * 6000 + sw_sec * 100 + cs;

    task pulse_ss;
        begin @(posedge clk); #1 start_stop = 1; @(posedge clk); #1 start_stop = 0; end
    endtask

    task pulse_clear;
        begin @(posedge clk); #1 clear = 1; @(posedge clk); #1 clear = 0; end
    endtask

    task report(input ok, input [8*40:1] name);
        begin
            if (ok) $display("PASS: %0s  (%02d:%02d.%02d)", name, sw_min, sw_sec, cs);
            else    $display("FAIL: %0s  (%02d:%02d.%02d)", name, sw_min, sw_sec, cs);
        end
    endtask

    reg [31:0] frozen;

    initial begin
        #30 rst = 0;
        @(posedge clk); #1;

        // 1. Reset ke baad
        report(running === 0 && dut_total === 0, "reset: stopped at 00:00.00");

        // 2. Start
        pulse_ss; #1;
        report(running === 1, "start: running");

        // 3. 1.5 second chalne do, phir stop
        while (gold < 150) @(posedge clk);
        #1;
        pulse_ss; #1;
        report(running === 0, "stop: running low");
        report(sw_min === 0 && sw_sec === 1 && dut_total === gold, "1.5 s counted, matches reference");

        // 4. Ruke hue time hold hona chahiye
        frozen = dut_total;
        repeat (40) @(posedge clk);
        #1;
        report(dut_total === frozen, "stopped: time holds");

        // 5. Resume
        pulse_ss;
        repeat (60) @(posedge clk);
        #1;
        report(running === 1 && dut_total > frozen && dut_total === gold, "resume: continues from stopped time");

        // 6. Chalte waqt clear ignore hona chahiye
        pulse_clear; #1;
        report(dut_total !== 0, "clear ignored while running");

        // 7. Stop karke clear
        pulse_ss;
        pulse_clear; #1;
        report(dut_total === 0 && gold === 0, "clear when stopped: 00:00.00");

        // 8. Minute rollover: 60 second (6000 cs) ke baad
        pulse_ss;
        while (gold < 6050) @(posedge clk);
        #1;
        pulse_ss; #1;
        report(sw_min === 1 && sw_sec === 0, "minute rollover: 01:00.xx");
        report(dut_total === gold, "total matches reference after rollover");

        $display("Simulation complete");
        $finish;
    end

endmodule