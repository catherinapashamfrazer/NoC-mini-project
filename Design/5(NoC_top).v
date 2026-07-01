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
reg [7:0] mem [0:3];
reg [1:0] wr_ptr;
reg [1:0] rd_ptr;
reg [2:0] count;
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        wr_ptr   <= 0;
        rd_ptr   <= 0;
        count    <= 0;
        data_out <= 0;
        full     <= 0;
        empty    <= 1;
    end
    else
    begin
        case ({wr_en && !full, rd_en && !empty})
        2'b10:
        begin
            // Write only
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
        2'b01:
        begin
            // Read only
            data_out <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end
        2'b11:
        begin
            // Simultaneous read and write
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
            data_out <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            // Count remains same
        end
        default:
        begin
        end
        endcase
        full  <= (count == 4);
        empty <= (count == 0);
    end
end
endmodule
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
module noc_top(
    input clk,
    input reset,
    output tg_valid,
    output [7:0] tg_packet,
    output [3:0] sink_valid,
    output [31:0] sink_packet
);
localparam [2:0] ROUTE_LOCAL = 3'd0;
localparam [2:0] ROUTE_WEST  = 3'd1;
localparam [2:0] ROUTE_EAST  = 3'd2;
localparam [2:0] ROUTE_NORTH = 3'd3;
localparam [2:0] ROUTE_SOUTH = 3'd4;

wire tg_ready;
wire r00_in_ready;
wire r01_in_ready;
wire r10_in_ready;
wire r11_in_ready;
wire r00_out_valid;
wire r01_out_valid;
wire r10_out_valid;
wire r11_out_valid;
wire [7:0] r00_packet;
wire [7:0] r01_packet;
wire [7:0] r10_packet;
wire [7:0] r11_packet;
wire [2:0] r00_route;
wire [2:0] r01_route;
wire [2:0] r10_route;
wire [2:0] r11_route;
wire r00_out_ready;
wire r01_out_ready;
wire r10_out_ready;
wire r11_out_ready;
reg [3:0] sink_valid_r;
reg [31:0] sink_packet_r;

traffic_generator src(
    .clk(clk),
    .reset(reset),
    .ready(tg_ready),
    .valid(tg_valid),
    .packet_out(tg_packet)
);

router #(.X(1'b0), .Y(1'b0)) r00(
    .clk(clk),
    .reset(reset),
    .in_valid(tg_valid),
    .in_ready(r00_in_ready),
    .in_packet(tg_packet),
    .out_valid(r00_out_valid),
    .out_ready(r00_out_ready),
    .out_packet(r00_packet),
    .out_route(r00_route),
    .full(),
    .empty()
);

router #(.X(1'b1), .Y(1'b0)) r01(
    .clk(clk),
    .reset(reset),
    .in_valid(r00_out_valid && (r00_route == ROUTE_EAST)),
    .in_ready(r01_in_ready),
    .in_packet(r00_packet),
    .out_valid(r01_out_valid),
    .out_ready(r01_out_ready),
    .out_packet(r01_packet),
    .out_route(r01_route),
    .full(),
    .empty()
);

router #(.X(1'b0), .Y(1'b1)) r10(
    .clk(clk),
    .reset(reset),
    .in_valid(r00_out_valid && (r00_route == ROUTE_SOUTH)),
    .in_ready(r10_in_ready),
    .in_packet(r00_packet),
    .out_valid(r10_out_valid),
    .out_ready(r10_out_ready),
    .out_packet(r10_packet),
    .out_route(r10_route),
    .full(),
    .empty()
);

router #(.X(1'b1), .Y(1'b1)) r11(
    .clk(clk),
    .reset(reset),
    .in_valid((r01_out_valid && (r01_route == ROUTE_SOUTH)) || (r10_out_valid && (r10_route == ROUTE_EAST))),
    .in_ready(r11_in_ready),
    .in_packet(r01_out_valid && (r01_route == ROUTE_SOUTH) ? r01_packet : r10_packet),
    .out_valid(r11_out_valid),
    .out_ready(r11_out_ready),
    .out_packet(r11_packet),
    .out_route(r11_route),
    .full(),
    .empty()
);

assign tg_ready = r00_in_ready;

assign r00_out_ready = (r00_route == ROUTE_LOCAL) ? 1'b1 :
                       (r00_route == ROUTE_EAST)  ? r01_in_ready :
                       (r00_route == ROUTE_SOUTH) ? r10_in_ready : 1'b0;

assign r01_out_ready = (r01_route == ROUTE_LOCAL) ? 1'b1 :
                       (r01_route == ROUTE_WEST)  ? r00_in_ready :
                       (r01_route == ROUTE_SOUTH) ? r11_in_ready : 1'b0;

assign r10_out_ready = (r10_route == ROUTE_LOCAL) ? 1'b1 :
                       (r10_route == ROUTE_NORTH) ? r00_in_ready :
                       (r10_route == ROUTE_EAST)  ? r11_in_ready : 1'b0;

assign r11_out_ready = (r11_route == ROUTE_LOCAL) ? 1'b1 :
                       (r11_route == ROUTE_WEST)  ? r10_in_ready :
                       (r11_route == ROUTE_NORTH) ? r01_in_ready : 1'b0;

always @(posedge clk or posedge reset)
begin
    if (reset)
    begin
        sink_valid_r <= 4'b0000;
        sink_packet_r <= 32'h00000000;
    end
    else
    begin
        sink_valid_r <= 4'b0000;

        if (r00_out_valid && (r00_route == ROUTE_LOCAL))
        begin
            sink_valid_r[0] <= 1'b1;
            sink_packet_r[7:0] <= r00_packet;
        end

        if (r01_out_valid && (r01_route == ROUTE_LOCAL))
        begin
            sink_valid_r[1] <= 1'b1;
            sink_packet_r[15:8] <= r01_packet;
        end

        if (r10_out_valid && (r10_route == ROUTE_LOCAL))
        begin
            sink_valid_r[2] <= 1'b1;
            sink_packet_r[23:16] <= r10_packet;
        end

        if (r11_out_valid && (r11_route == ROUTE_LOCAL))
        begin
            sink_valid_r[3] <= 1'b1;
            sink_packet_r[31:24] <= r11_packet;
        end
    end
end

assign sink_valid = sink_valid_r;
assign sink_packet = sink_packet_r;

endmodule
