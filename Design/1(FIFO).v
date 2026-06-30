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
reg [2:0] next_count;
wire do_read;
wire do_write;

assign do_read = rd_en && !empty;
assign do_write = wr_en && (!full || do_read);

always @(*)
begin
    next_count = count;
    if (do_write)
        next_count = next_count + 1'b1;
    if (do_read)
        next_count = next_count - 1'b1;
end

always @(posedge clk or posedge reset)
begin
    if (reset)
    begin
        wr_ptr <= 2'b00;
        rd_ptr <= 2'b00;
        count <= 3'b000;
        data_out <= 8'h00;
        full <= 1'b0;
        empty <= 1'b1;
    end
    else
    begin
        if (do_write)
        begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1'b1;
        end

        if (do_read)
        begin
            data_out <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1'b1;
        end

        count <= next_count;
        full <= (next_count == 3'd4);
        empty <= (next_count == 3'd0);
    end
end
endmodule
