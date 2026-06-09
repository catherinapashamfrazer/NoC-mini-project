module routing_logic(
    input [1:0] dest,
    output reg left,
    output reg right,
    output reg up,
    output reg down
);
always @(*)
begin
    left = 0;
    right = 0;
    up = 0;
    down = 0;
    case(dest)
        2'b00: left  = 1;
        2'b01: right = 1;
        2'b10: up    = 1;
        2'b11: down  = 1;
    endcase
end
endmodule
