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

//testbench

module fifo_tb;
reg clk;
reg reset;
reg wr_en;
reg rd_en;
reg [7:0] data_in;
wire [7:0] data_out;
wire full;
wire empty;
// Instantiate FIFO
fifo uut(
    .clk(clk),
    .reset(reset),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
);
// Clock Generation
always #5 clk = ~clk;
initial
begin
    // Generate waveform file
    $dumpfile("dump.vcd");
    $dumpvars(0, fifo_tb);
    // Initialize signals
    clk = 0;
    reset = 1;
    wr_en = 0;
    rd_en = 0;
    data_in = 0;
    // Apply Reset
    #10;
    reset = 0;
    // Write Data
    #10;
    wr_en = 1;
    data_in = 8'hAA;
    #10;
    data_in = 8'h55;
    #10;
    data_in = 8'hF0;
    #10;
    data_in = 8'h0F;
    // Stop Writing
    #10;
    wr_en = 0;
    // Read Data
    #10;
    rd_en = 1;
    #40;
    // Stop Reading
    rd_en = 0;
    #20;
    $finish;
end
endmodule
