module noc_top_tb;
reg clk;
reg reset;
wire [7:0] tg_packet;
wire tg_valid;
wire [3:0] sink_valid;
wire [31:0] sink_packet;
noc_top uut(
    .clk(clk),
    .reset(reset),
    .tg_valid(tg_valid),
    .tg_packet(tg_packet),
    .sink_valid(sink_valid),
    .sink_packet(sink_packet)
);
// Clock
always #5 clk = ~clk;
integer delivered;
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0,noc_top_tb);
    clk = 0;
    reset = 1;
    delivered = 0;
    #20;
    reset = 0;
    #200;
    if (delivered != 4)
    begin
        $fatal(1, "Expected 4 delivered packets, got %0d", delivered);
    end
    $finish;
end
initial
begin
    $monitor("T=%0t TG=%h V=%b sink=%b delivered=%0d", $time, tg_packet, tg_valid, sink_valid, delivered);
end
always @(posedge clk)
begin
    if (|sink_valid) delivered = delivered + 1;
end
endmodule
