// ============================================================================
// Module: routing_logic
// Description: Decodes the destination coordinates from the packet and decides
//              which path (direction) the packet should take next to reach its
//              target.
//              It implements "XY routing", which resolves the X coordinate
//              (left/right) first, and then resolves the Y coordinate (up/down).
// ============================================================================
module routing_logic #(
    parameter X = 1'b0,         // X-coordinate of this router in the 2x2 grid
    parameter Y = 1'b0          // Y-coordinate of this router in the 2x2 grid
)(
    input [1:0] dest,           // 2-bit destination coordinate: dest[0] is X, dest[1] is Y
    output reg [2:0] route,     // 3-bit direction choice output
    output reg local_hit        // High if the packet has arrived at its destination
);

    // Direction code constants
    localparam [2:0] ROUTE_LOCAL = 3'd0; // Consume packet at the current node
    localparam [2:0] ROUTE_WEST  = 3'd1; // Route West (left)
    localparam [2:0] ROUTE_EAST  = 3'd2; // Route East (right)
    localparam [2:0] ROUTE_NORTH = 3'd3; // Route North (up)
    localparam [2:0] ROUTE_SOUTH = 3'd4; // Route South (down)

    always @(*)
    begin
        // Default values: assume packet has reached its destination
        route     = ROUTE_LOCAL;
        local_hit = 1'b0;

        // Step 1: Check if the packet has reached the destination node
        // In our 2x2 grid, {Y, X} combines the current node's row and column.
        if (dest == {Y, X})
        begin
            local_hit = 1'b1; // Packet is for us! Deliver locally.
        end
        
        // Step 2: If not local, resolve horizontal (X) distance first
        else if (dest[0] > X)
        begin
            route = ROUTE_EAST; // Destination is to our right
        end
        else if (dest[0] < X)
        begin
            route = ROUTE_WEST; // Destination is to our left
        end
        
        // Step 3: If X matches, resolve vertical (Y) distance next
        else if (dest[1] > Y)
        begin
            route = ROUTE_SOUTH; // Destination is below us
        end
        else
        begin
            route = ROUTE_NORTH; // Destination is above us (since Y is not equal and not greater)
        end
    end

endmodule
