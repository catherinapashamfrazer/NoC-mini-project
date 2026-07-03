// ============================================================================
// Module: traffic_generator (Stimulus Source)
// Description: Injects a sequence of 4 test packets into the NoC mesh on reset
//              to verify routing paths and measure network latency.
// ============================================================================
module traffic_generator(
    input clk,                  // Clock signal
    input reset,                // Reset signal (active high)
    input ready,                // High if succeeding router is ready to receive
    output reg valid,           // High when generating valid packet data
    output reg [7:0] packet_out // 8-bit generated packet
);

    reg [1:0] count;            // Counter to track which packet is being sent

    // Helper function to build 8-bit packets in the format:
    // Bits [7:6]: Destination coordinates
    // Bits [5:4]: Sequence number
    // Bits [3:2]: Duplicate destination (redundant/unused payload)
    // Bits [1:0]: Constant signature/marker (2'b01)
    function [7:0] build_packet;
        input [1:0] dest;
        input [1:0] seq;
        begin
            build_packet = {dest, seq, dest, 2'b01};
        end
    endfunction

    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            // On reset, prepare to send packet 0 (to node 00)
            count      <= 2'b00;
            valid      <= 1'b1;
            packet_out <= build_packet(2'b00, 2'b00); // 8'h01
        end
        else if (valid && ready)
        begin
            // After successful injection (valid & ready handshake):
            // Set up next packet based on the current counter
            case (count)
                2'd0: packet_out <= build_packet(2'b01, 2'd0); // Packet 1 -> Node 01 (8'h45)
                2'd1: packet_out <= build_packet(2'b10, 2'd1); // Packet 2 -> Node 10 (8'h99)
                2'd2: packet_out <= build_packet(2'b11, 2'd2); // Packet 3 -> Node 11 (8'hED)
                default: packet_out <= packet_out;
            endcase

            // Stop generating after 4 packets (count reaches 3)
            if (count == 2'd3)
            begin
                valid <= 1'b0; // De-assert valid (no more packets to send)
            end
            else
            begin
                count <= count + 1'b1; // Move to next packet
            end
        end
    end

endmodule
