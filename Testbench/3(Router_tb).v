module router_tb;
reg clk;
reg reset;
reg wr_en;
reg rd_en;
reg [7:0] packet_in;
wire [7:0] packet_out;
wire [2:0] route;
wire in_ready;
wire out_valid;
wire full;
wire empty;
// Instantiate Router
router #(.X(1'b0), .Y(1'b0)) uut(
    .clk(clk),
    .reset(reset),
    .in_valid(wr_en),
    .in_ready(in_ready),
    .in_packet(packet_in),
    .out_valid(out_valid),
    .out_ready(rd_en),
    .packet_out(packet_out),
    .out_route(route),
    .full(full),
    .empty(empty)
);
// Clock Generation
always #5 clk = ~clk;
// Monitor Values
initial
begin
    $monitor("Time=%0t | valid=%b ready=%b packet_out=%b route=%0d | full=%b empty=%b",
             $time, out_valid, in_ready, packet_out, route, full, empty);
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
    rd_en = 1;
    #80;
    rd_en = 0;
    #20;
    $finish;
end
endmodule
