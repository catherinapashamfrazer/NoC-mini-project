module traffic_generator(
    input clk,
    input reset,
    output reg [7:0] packet_out
);
reg [1:0] count;
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        count <= 0;
        packet_out <= 8'b00000000;
    end
    else
    begin
        case(count)
            2'd0: packet_out <= 8'b00_111111;
            2'd1: packet_out <= 8'b01_101010;
            2'd2: packet_out <= 8'b10_110011;
            2'd3: packet_out <= 8'b11_001100;
        endcase
        count <= count + 1;
    end
end
endmodule
