module traffic_generator(
    input clk,
    input reset,
    input ready,
    output reg valid,
    output reg [7:0] packet_out
);
reg [1:0] count;

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
        count <= 2'b00;
        valid <= 1'b1;
        packet_out <= build_packet(2'b00, 2'b00);
    end
    else if (valid && ready)
    begin
        case (count)
            2'd0: packet_out <= build_packet(2'b01, 2'd0);
            2'd1: packet_out <= build_packet(2'b10, 2'd1);
            2'd2: packet_out <= build_packet(2'b11, 2'd2);
            default: packet_out <= packet_out;
        endcase

        if (count == 2'd3)
        begin
            valid <= 1'b0;
        end
        else
        begin
            count <= count + 1'b1;
        end
    end
end
endmodule
