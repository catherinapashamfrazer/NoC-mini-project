module routing_logic_tb;
reg [1:0] dest;
wire [2:0] route;
wire local_hit;
routing_logic #(.X(1'b0), .Y(1'b0)) uut(
    .dest(dest),
    .route(route),
    .local_hit(local_hit)
);
initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, routing_logic_tb);
    dest = 2'b00;
    #20;
    if (!local_hit || route !== 3'd0) $fatal(1, "Expected local route for 00");
    dest = 2'b01;
    #20;
    if (route !== 3'd2) $fatal(1, "Expected east route for 01");
    dest = 2'b10;
    #20;
    if (route !== 3'd4) $fatal(1, "Expected south route for 10");
    dest = 2'b11;
    #20;
    if (route !== 3'd2) $fatal(1, "Expected east-first XY route for 11");
    $finish;
end
endmodule
