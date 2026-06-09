module routing_logic_tb;
reg [1:0] dest;
wire left;
wire right;
wire up;
wire down;
routing_logic uut(
    .dest(dest),
    .left(left),
    .right(right),
    .up(up),
    .down(down)
);
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, routing_logic_tb);
    dest = 2'b00;
    #20;
    dest = 2'b01;
    #20;
    dest = 2'b10;
    #20;
    dest = 2'b11;
    #20;
    $finish;
end
endmodule
