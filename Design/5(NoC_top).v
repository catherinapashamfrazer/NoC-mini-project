// ============================================================================
// Module: noc_top (Top-Level 2x2 Mesh Network-on-Chip)
// Description: Connects 4 routers in a 2x2 grid. A traffic generator injects
//              packets at Router (0,0), and they are routed using XY routing to
//              local sinks at each node.
//              Includes combinational priority arbitration at Node (1,1) to
//              prevent collisions and packet loss.
// ============================================================================
module noc_top(
    input clk,                          // Clock signal
    input reset,                        // Reset signal (active high)
    output tg_valid,                    // Monitors traffic generator valid output
    output [7:0] tg_packet,             // Monitors traffic generator packet output
    output [3:0] sink_valid,            // Valid packet outputs at each sink (0 to 3)
    output [31:0] sink_packet           // 4 concatenated 8-bit packets for the sinks
);

    // Direction code constants used to identify packet paths
    localparam [2:0] ROUTE_LOCAL = 3'd0;
    localparam [2:0] ROUTE_WEST  = 3'd1;
    localparam [2:0] ROUTE_EAST  = 3'd2;
    localparam [2:0] ROUTE_NORTH = 3'd3;
    localparam [2:0] ROUTE_SOUTH = 3'd4;

    // Handshake signals between Traffic Generator and Router 00
    wire tg_ready;

    // Interface wires for each router's input/output ports
    // rXX_in_ready: asserted when router is ready to receive
    // rXX_out_valid: asserted when router has data to send
    // rXX_packet: the 8-bit data packet output
    // rXX_route: the decoded 3-bit direction code
    // rXX_out_ready: handshaking to pop data from router's output
    wire r00_in_ready, r01_in_ready, r10_in_ready, r11_in_ready;
    wire r00_out_valid, r01_out_valid, r10_out_valid, r11_out_valid;
    wire [7:0] r00_packet, r01_packet, r10_packet, r11_packet;
    wire [2:0] r00_route, r01_route, r10_route, r11_route;
    wire r00_out_ready, r01_out_ready, r10_out_ready, r11_out_ready;

    // Registers to capture delivered packets at the local sinks
    reg [3:0] sink_valid_r;
    reg [31:0] sink_packet_r;

    // ------------------------------------------------------------------------
    // 1. Traffic Generator (Source)
    // Generates packets to inject into Node (0,0)
    // ------------------------------------------------------------------------
    traffic_generator src(
        .clk(clk),
        .reset(reset),
        .ready(tg_ready),
        .valid(tg_valid),
        .packet_out(tg_packet)
    );

    // ------------------------------------------------------------------------
    // 2. Router Instances (2x2 Grid)
    // ------------------------------------------------------------------------
    
    // Router (0,0) - Top-Left Node
    router #(.X(1'b0), .Y(1'b0)) r00(
        .clk(clk), .reset(reset),
        .in_valid(tg_valid),
        .in_ready(r00_in_ready),
        .in_packet(tg_packet),
        .out_valid(r00_out_valid),
        .out_ready(r00_out_ready),
        .out_packet(r00_packet),
        .out_route(r00_route),
        .full(), .empty()
    );

    // Router (1,0) - Top-Right Node
    router #(.X(1'b1), .Y(1'b0)) r01(
        .clk(clk), .reset(reset),
        .in_valid(r00_out_valid && (r00_route == ROUTE_EAST)), // Input from r00 going East
        .in_ready(r01_in_ready),
        .in_packet(r00_packet),
        .out_valid(r01_out_valid),
        .out_ready(r01_out_ready),
        .out_packet(r01_packet),
        .out_route(r01_route),
        .full(), .empty()
    );

    // Router (0,1) - Bottom-Left Node
    router #(.X(1'b0), .Y(1'b1)) r10(
        .clk(clk), .reset(reset),
        .in_valid(r00_out_valid && (r00_route == ROUTE_SOUTH)), // Input from r00 going South
        .in_ready(r10_in_ready),
        .in_packet(r00_packet),
        .out_valid(r10_out_valid),
        .out_ready(r10_out_ready),
        .out_packet(r10_packet),
        .out_route(r10_route),
        .full(), .empty()
    );

    // ------------------------------------------------------------------------
    // 3. Arbitration Logic at Node (1,1) - Bottom-Right Node
    // Node (1,1) can receive packets from r01 (routing South) OR r10 (routing East).
    // If both send simultaneously, we arbitrate using a priority multiplexer:
    // r01 (South) is prioritized; r10 (East) is stalled until r01 completes.
    // ------------------------------------------------------------------------
    
    // Request signals: Asserted if a router wants to send a packet to Router 11
    wire r01_req_r11 = r01_out_valid && (r01_route == ROUTE_SOUTH);
    wire r10_req_r11 = r10_out_valid && (r10_route == ROUTE_EAST);

    // Grant signals: Decide which router gets access
    wire r01_gnt_r11 = r01_req_r11;                    // Always grant to r01 if it requests (high priority)
    wire r10_gnt_r11 = r10_req_r11 && !r01_req_r11;     // Grant to r10 only if r01 is not requesting

    // Multiplexer for Router 11's input port
    wire r11_in_valid        = r01_req_r11 || r10_req_r11;
    wire [7:0] r11_in_packet = r01_gnt_r11 ? r01_packet : r10_packet;

    // Router (1,1) Instance
    router #(.X(1'b1), .Y(1'b1)) r11(
        .clk(clk), .reset(reset),
        .in_valid(r11_in_valid),
        .in_ready(r11_in_ready),
        .in_packet(r11_in_packet),
        .out_valid(r11_out_valid),
        .out_ready(r11_out_ready),
        .out_packet(r11_packet),
        .out_route(r11_route),
        .full(), .empty()
    );

    // ------------------------------------------------------------------------
    // 4. Output Handshake and Backpressure Routing
    // Tells each router when its output packet is accepted by the next hop.
    // ------------------------------------------------------------------------
    
    // Traffic generator gets ready from Router 00
    assign tg_ready = r00_in_ready;

    // Router 00 output is accepted based on the direction the packet wants to go
    assign r00_out_ready = (r00_route == ROUTE_LOCAL) ? 1'b1 :
                           (r00_route == ROUTE_EAST)  ? r01_in_ready :
                           (r00_route == ROUTE_SOUTH) ? r10_in_ready : 1'b0;

    // Router 01 output ready: if routing South to r11, must hold grant from Arbiter
    assign r01_out_ready = (r01_route == ROUTE_LOCAL) ? 1'b1 :
                           (r01_route == ROUTE_WEST)  ? r00_in_ready :
                           (r01_route == ROUTE_SOUTH) ? (r11_in_ready && r01_gnt_r11) : 1'b0;

    // Router 10 output ready: if routing East to r11, must hold grant from Arbiter
    assign r10_out_ready = (r10_route == ROUTE_LOCAL) ? 1'b1 :
                           (r10_route == ROUTE_NORTH) ? r00_in_ready :
                           (r10_route == ROUTE_EAST)  ? (r11_in_ready && r10_gnt_r11) : 1'b0;

    // Router 11 output ready: can only deliver locally since it is the grid boundary (1,1)
    assign r11_out_ready = (r11_route == ROUTE_LOCAL) ? 1'b1 :
                           (r11_route == ROUTE_WEST)  ? r10_in_ready :
                           (r11_route == ROUTE_NORTH) ? r01_in_ready : 1'b0;

    // ------------------------------------------------------------------------
    // 5. Packet Sinks
    // Captures packets that arrive at their destinations (Local route)
    // ------------------------------------------------------------------------
    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            sink_valid_r  <= 4'b0000;
            sink_packet_r <= 32'h00000000;
        end
        else
        begin
            // Default to no valid packets arriving in this cycle
            sink_valid_r <= 4'b0000;

            // Router 00 local delivery
            if (r00_out_valid && (r00_route == ROUTE_LOCAL))
            begin
                sink_valid_r[0]    <= 1'b1;
                sink_packet_r[7:0] <= r00_packet;
            end

            // Router 01 local delivery
            if (r01_out_valid && (r01_route == ROUTE_LOCAL))
            begin
                sink_valid_r[1]     <= 1'b1;
                sink_packet_r[15:8] <= r01_packet;
            end

            // Router 10 local delivery
            if (r10_out_valid && (r10_route == ROUTE_LOCAL))
            begin
                sink_valid_r[2]      <= 1'b1;
                sink_packet_r[23:16] <= r10_packet;
            end

            // Router 11 local delivery
            if (r11_out_valid && (r11_route == ROUTE_LOCAL))
            begin
                sink_valid_r[3]      <= 1'b1;
                sink_packet_r[31:24] <= r11_packet;
            end
        end
    end

    // Assign registers to output pins
    assign sink_valid  = sink_valid_r;
    assign sink_packet = sink_packet_r;

endmodule
