module router_tb;
reg clk;
reg reset;
reg wr_en;
reg rd_en;
reg [7:0] packet_in;
wire left;
wire right;
wire up;
wire down;
wire [7:0] packet_out;
wire full;
wire empty;
// Instantiate Router
router uut(
    .clk(clk),
    .reset(reset),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .packet_in(packet_in),
    .left(left),
    .right(right),
    .up(up),
    .down(down),
    .packet_out(packet_out),
    .full(full),
    .empty(empty)
);
// Clock Generation
always #5 clk = ~clk;
// Monitor Values
initial
begin
    $monitor("Time=%0t | packet_out=%b | left=%b right=%b up=%b down=%b | full=%b empty=%b",
             $time, packet_out, left, right, up, down, full, empty);
end
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, router_tb);
    // Initialize
    clk = 0;
    reset = 1;
    wr_en = 0;
    rd_en = 0;
    packet_in = 8'b00000000;
    // Reset
    #10;
    reset = 0;
    // Write Packets
    #10;
    wr_en = 1;
    packet_in = 8'b00_111111;
    #10;
    packet_in = 8'b01_101010;
    #10;
    packet_in = 8'b10_110011;
    #10;
    packet_in = 8'b11_001100;
    #10;
    wr_en = 0;
    // Read Packets
    #20;
    rd_en = 1;
    #40;
    rd_en = 0;
    #20;
    $finish;
end
endmodule
