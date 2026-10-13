`timescale 1ns / 1ps

module clk_divider #(
    parameter DIV_1HZ   = 100_000_000,
    parameter DIV_100HZ = 1_000_000
)(
    input  wire clk,
    input  wire rst,
    output reg  tick_1hz,
    output reg  tick_100hz
);
    reg [26:0] c1;
    reg [19:0] c2;

    always @(posedge clk) begin
        if (rst) begin
            c1 <= 0; c2 <= 0;
            tick_1hz <= 0; tick_100hz <= 0;
        end else begin
            tick_1hz   <= 0;
            tick_100hz <= 0;

            if (c1 == DIV_1HZ - 1) begin
                c1 <= 0; tick_1hz <= 1;
            end else c1 <= c1 + 1;

            if (c2 == DIV_100HZ - 1) begin
                c2 <= 0; tick_100hz <= 1;
            end else c2 <= c2 + 1;
        end
    end
endmodule