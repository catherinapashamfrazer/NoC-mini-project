// ============================================================================
// Module: router (NoC Router Node)
// Description: Represents a single routing node in the 2x2 Network-on-Chip.
//              It contains a FIFO buffer to store incoming packets temporarily
//              and routing logic to decide where to send the packet next.
// ============================================================================
module router #(
    parameter X = 1'b0,         // X-coordinate of this router in the grid
    parameter Y = 1'b0          // Y-coordinate of this router in the grid
)(
    input clk,                  // Clock signal
    input reset,                // Reset signal (active high)
    
    // Input interface (from preceding router or traffic generator)
    input in_valid,             // High when incoming data is valid
    output in_ready,            // High when this router is ready to receive data (not full)
    input [7:0] in_packet,      // 8-bit incoming packet
    
    // Output interface (to succeeding router or local sink)
    output out_valid,           // High when outgoing data is ready
    input out_ready,            // High when succeeding node is ready to accept data
    output [7:0] out_packet,    // 8-bit outgoing packet
    output [2:0] out_route,     // 3-bit direction code for the outgoing packet
    
    // Internal status outputs (optional monitoring)
    output full,                // Buffer full flag
    output empty                // Buffer empty flag
);

    // Internal wires for connecting FIFO and Routing Logic
    wire [7:0] fifo_out;        // Holds the packet at the head of the FIFO
    wire fifo_read;             // Enabled when we read from the FIFO
    wire local_hit;             // Asserted if destination matches current coordinates

    // Handshake logic:
    // 1. We are ready to accept inputs if our internal FIFO is not full
    assign in_ready = !full;
    // 2. We have valid outputs if our internal FIFO is not empty
    assign out_valid = !empty;
    // 3. The packet at the head of the FIFO is our output packet
    assign out_packet = fifo_out;
    // 4. We pop the FIFO when succeeding node accepts the packet (out_ready) and we actually have data (out_valid)
    assign fifo_read = out_ready && out_valid;

    // Instantiate the FIFO buffer to temporarily store incoming packets
    // This FIFO is defined in Design/1(FIFO).v
    fifo fifo_inst(
        .clk(clk),
        .reset(reset),
        .wr_en(in_valid && in_ready), // Write if incoming data is valid and we are ready
        .rd_en(fifo_read),            // Read if succeeding router takes our output
        .data_in(in_packet),
        .data_out(fifo_out),
        .full(full),
        .empty(empty)
    );

    // Instantiate the Routing Logic to decode destination and choose path
    // This Routing Logic is defined in Design/2(Routing_logic).v
    routing_logic #(
        .X(X),
        .Y(Y)
    ) rl_inst(
        .dest(fifo_out[7:6]),         // Destination coordinates are stored in bits [7:6] of packet
        .route(out_route),            // Outputs the direction code (East, South, Local, etc.)
        .local_hit(local_hit)         // Outputs if the packet is destined for this node
    );

endmodule
