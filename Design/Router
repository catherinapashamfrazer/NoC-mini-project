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
module router(
    input clk,
    input reset,
    input wr_en,
    input rd_en,
    input [7:0] packet_in,
    output left,
    output right,
    output up,
    output down,
    output [7:0] packet_out,
    output full,
    output empty
);
wire [7:0] fifo_out;
// FIFO Instance
fifo fifo_inst(
    .clk(clk),
    .reset(reset),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(packet_in),
    .data_out(fifo_out),
    .full(full),
    .empty(empty)
);
// Routing Logic Instance
routing_logic rl_inst(
    .dest(fifo_out[7:6]),
    .left(left),
    .right(right),
    .up(up),
    .down(down)
);
// Forward packet from FIFO output
assign packet_out = fifo_out;
endmodule
