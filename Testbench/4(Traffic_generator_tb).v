module traffic_generator_tb;
reg clk;
reg reset;
wire valid;
wire [7:0] packet_out;
traffic_generator uut(
    .clk(clk),
    .reset(reset),
    .ready(1'b1),
    .valid(valid),
    .packet_out(packet_out)
);
always #5 clk = ~clk;
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0,traffic_generator_tb);
    clk = 0;
    reset = 1;
    #10;
    reset = 0;
    #100;
    $finish;
end
initial
begin
    $monitor("Time=%0t valid=%b Packet=%b",$time,valid,packet_out);
end
endmodule
