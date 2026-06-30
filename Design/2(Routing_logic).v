module routing_logic #(
    parameter X = 1'b0,
    parameter Y = 1'b0
)(
    input [1:0] dest,
    output reg [2:0] route,
    output reg local_hit
);
localparam [2:0] ROUTE_LOCAL = 3'd0;
localparam [2:0] ROUTE_WEST  = 3'd1;
localparam [2:0] ROUTE_EAST  = 3'd2;
localparam [2:0] ROUTE_NORTH = 3'd3;
localparam [2:0] ROUTE_SOUTH = 3'd4;

always @(*)
begin
    route = ROUTE_LOCAL;
    local_hit = 1'b0;

    if (dest == {Y, X})
    begin
        local_hit = 1'b1;
    end
    else if (dest[0] > X)
    begin
        route = ROUTE_EAST;
    end
    else if (dest[0] < X)
    begin
        route = ROUTE_WEST;
    end
    else if (dest[1] > Y)
    begin
        route = ROUTE_SOUTH;
    end
    else
    begin
        route = ROUTE_NORTH;
    end
end
endmodule
