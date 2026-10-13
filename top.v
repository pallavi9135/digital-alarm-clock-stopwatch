`timescale 1ns / 1ps


module edge_pulse (
    input  wire clk,
    input  wire in,
    output wire pulse
);
    reg s1 = 0, s2 = 0, s3 = 0;
    always @(posedge clk) begin
        s1 <= in; s2 <= s1; s3 <= s2;
    end
    assign pulse = s2 & ~s3;
endmodule

module top #(
    parameter DIV_1HZ   = 100_000_000,
    parameter DIV_100HZ = 1_000_000
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       btn_mode,    
    input  wire       btn_hr,      
    input  wire       btn_min,     
    input  wire       btn_ss,      
    input  wire       btn_clear,   
    input  wire       alarm_en,
    output reg  [1:0] mode,        
    output wire [4:0] hours,
    output wire [5:0] mins,
    output wire [5:0] secs,
    output wire [4:0] alarm_hr,
    output wire [5:0] alarm_min,
    output wire       ringing,
    output wire       sw_running,
    output wire [5:0] sw_min,
    output wire [5:0] sw_sec,
    output wire [6:0] sw_cs
);
    localparam CLOCK = 2'd0, SET_TIME = 2'd1, SET_ALARM = 2'd2, STOPWATCH = 2'd3;

    wire p_mode, p_hr, p_min, p_ss, p_clr;
    edge_pulse e0 (.clk(clk), .in(btn_mode),  .pulse(p_mode));
    edge_pulse e1 (.clk(clk), .in(btn_hr),    .pulse(p_hr));
    edge_pulse e2 (.clk(clk), .in(btn_min),   .pulse(p_min));
    edge_pulse e3 (.clk(clk), .in(btn_ss),    .pulse(p_ss));
    edge_pulse e4 (.clk(clk), .in(btn_clear), .pulse(p_clr));

    // Mode FSM
    always @(posedge clk) begin
        if (rst)         mode <= CLOCK;
        else if (p_mode) mode <= mode + 1;
    end

    wire tick_1hz, tick_100hz;

    clk_divider #(.DIV_1HZ(DIV_1HZ), .DIV_100HZ(DIV_100HZ)) u_div (
        .clk(clk), .rst(rst),
        .tick_1hz(tick_1hz), .tick_100hz(tick_100hz)
    );

    timekeeper u_time (
        .clk(clk), .rst(rst), .tick_1hz(tick_1hz),
        .set_mode(mode == SET_TIME),
        .inc_hr(p_hr), .inc_min(p_min),
        .hours(hours), .mins(mins), .secs(secs)
    );

    alarm u_alarm (
        .clk(clk), .rst(rst),
        .set_alarm(mode == SET_ALARM),
        .inc_hr(p_hr), .inc_min(p_min),
        .alarm_en(alarm_en),
        .dismiss(p_ss && mode != STOPWATCH),
        .hours(hours), .mins(mins),
        .alarm_hr(alarm_hr), .alarm_min(alarm_min), .ringing(ringing)
    );

    stopwatch u_sw (
        .clk(clk), .rst(rst), .tick_100hz(tick_100hz),
        .start_stop(p_ss && mode == STOPWATCH),
        .clear(p_clr && mode == STOPWATCH),
        .running(sw_running), .cs(sw_cs), .sec(sw_sec), .min(sw_min)
    );
endmodule