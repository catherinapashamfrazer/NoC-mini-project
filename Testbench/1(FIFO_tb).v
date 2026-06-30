module fifo_tb;
reg clk;
reg reset;
reg wr_en;
reg rd_en;
reg [7:0] data_in;
wire [7:0] data_out;
wire full;
wire empty;
reg [7:0] expected [0:3];
integer i;
integer read_index;
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
    expected[0] = 8'hAA;
    expected[1] = 8'h55;
    expected[2] = 8'hF0;
    expected[3] = 8'h0F;
    read_index = 0;
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
    for (i = 0; i < 4; i = i + 1)
    begin
        #10;
        if (data_out !== expected[read_index])
        begin
            $fatal(1, "FIFO data mismatch at %0d: got %h expected %h", read_index, data_out, expected[read_index]);
        end
        read_index = read_index + 1;
    end
    // Stop Reading
    rd_en = 0;
    #20;
    if (!empty || full)
    begin
        $fatal(1, "FIFO flags not in expected state at end");
    end
    $finish;
end
endmodule
