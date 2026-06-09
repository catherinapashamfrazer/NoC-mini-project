module noc_top_tb;
reg clk;
reg reset;
wire [7:0] tg_packet;
wire [7:0] router1_out;
wire [7:0] router2_out;
wire [7:0] final_packet;
wire left1,right1,up1,down1;
wire left2,right2,up2,down2;
noc_top uut(
    .clk(clk),
    .reset(reset),
    .final_packet(final_packet),
    .left1(left1),
    .right1(right1),
    .up1(up1),
    .down1(down1),
    .left2(left2),
    .right2(right2),
    .up2(up2),
    .down2(down2),
    .tg_packet(tg_packet),
    .router1_out(router1_out),
    .router2_out(router2_out)
);
// Clock
always #5 clk = ~clk;
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0,noc_top_tb);
    clk = 0;
    reset = 1;
    #20;
    reset = 0;
    #250;
    $finish;
end
initial
begin
    $monitor(
    "T=%0t TG=%h R1=%h R2=%h FINAL=%h | L1=%b R1=%b U1=%b D1=%b | L2=%b R2=%b U2=%b D2=%b",
    $time,
    tg_packet,
    router1_out,
    router2_out,
    final_packet,
    left1,right1,up1,down1,
    left2,right2,up2,down2
    );
end
endmodule
