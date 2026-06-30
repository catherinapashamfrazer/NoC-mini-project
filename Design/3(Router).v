module fifo(
    input clk,
    input reset,
    input wr_en,
    input rd_en,
    input [7:0] data_in,
    output reg [7:0] data_out,
    output reg full,
    output reg empty
);
reg [7:0] mem [0:3];    // 4-location FIFO
reg [1:0] wr_ptr;
reg [1:0] rd_ptr;
reg [2:0] count;
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        count  <= 0;
        full   <= 0;
        empty  <= 1;
    end
    else
    begin
        // Write Operation
        if(wr_en && !full)
        begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
        // Read Operation
        if(rd_en && !empty)
        begin
            data_out <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end
        // Status Flags
        full  <= (count == 4);
        empty <= (count == 0);
    end
end
endmodule
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
module router #(
    parameter X = 1'b0,
    parameter Y = 1'b0
)(
    input clk,
    input reset,
    input in_valid,
    output in_ready,
    input [7:0] in_packet,
    output out_valid,
    input out_ready,
    output [7:0] out_packet,
    output [2:0] out_route,
    output full,
    output empty
);
wire [7:0] fifo_out;
wire fifo_read;
wire local_hit;

assign in_ready = !full;
assign out_valid = !empty;
assign out_packet = fifo_out;
assign fifo_read = out_ready && out_valid;

fifo fifo_inst(
    .clk(clk),
    .reset(reset),
    .wr_en(in_valid && in_ready),
    .rd_en(fifo_read),
    .data_in(in_packet),
    .data_out(fifo_out),
    .full(full),
    .empty(empty)
);

routing_logic #(
    .X(X),
    .Y(Y)
) rl_inst(
    .dest(fifo_out[7:6]),
    .route(out_route),
    .local_hit(local_hit)
);
endmodule
