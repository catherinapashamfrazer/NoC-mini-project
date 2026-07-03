// ============================================================================
// Module: fifo (First-In, First-Out Buffer)
// Description: Stores up to 4 packets (each 8 bits wide). It helps manage the
//              flow of data between two circuits running at different speeds,
//              preventing data loss when one is busy.
// ============================================================================
module fifo(
    input clk,                  // Clock signal to synchronize operations
    input reset,                // Reset signal to clear the buffer (active high)
    input wr_en,                // Write Enable: Request to store data_in
    input rd_en,                // Read Enable: Request to retrieve data_out
    input [7:0] data_in,        // 8-bit input data packet
    output reg [7:0] data_out,  // 8-bit output data packet
    output reg full,            // High when buffer is full (cannot write)
    output reg empty            // High when buffer is empty (cannot read)
);

    // Internal memory: An array of 4 locations, each 8 bits wide
    reg [7:0] mem [0:3];

    // Pointers to keep track of where to write and read next
    // 2-bit pointers wrap around naturally (0 -> 1 -> 2 -> 3 -> 0)
    reg [1:0] wr_ptr;           
    reg [1:0] rd_ptr;           

    // Counter to track the current number of packets in the FIFO (range: 0 to 4)
    reg [2:0] count;            

    // Actual execution signals determined by handshake and status flags
    wire do_write;
    wire do_read;

    // We can read only if there is data in the FIFO
    assign do_read = rd_en && !empty;

    // We can write if there is space, OR if we are reading at the same time (simultaneous pop and push)
    assign do_write = wr_en && (!full || do_read);

    // Sequential block: Updates pointers, memory, and flags on clock ticks or reset
    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            // On reset, clear everything and mark buffer as empty
            wr_ptr   <= 2'b00;
            rd_ptr   <= 2'b00;
            count    <= 3'b000;
            data_out <= 8'h00;
            full     <= 1'b0;
            empty    <= 1'b1;
        end
        else
        begin
            // 1. Handle Write Operation
            if (do_write)
            begin
                mem[wr_ptr] <= data_in;       // Store data at write pointer
                wr_ptr      <= wr_ptr + 1'b1; // Advance write pointer
            end

            // 2. Handle Read Operation
            if (do_read)
            begin
                data_out <= mem[rd_ptr];      // Output data from read pointer
                rd_ptr   <= rd_ptr + 1'b1;    // Advance read pointer
            end

            // 3. Update Count
            // Simultaneous read and write: count remains the same
            if (do_write && !do_read)
            begin
                count <= count + 1'b1;
            end
            else if (do_read && !do_write)
            begin
                count <= count - 1'b1;
            end

            // 4. Update Status Flags
            // full = 1 if we wrote and didn't read to reach 4 items, or if we were already full and did neither/both
            full  <= (do_write && !do_read && (count == 3)) || (full && !(do_read && !do_write));
            // empty = 1 if we read and didn't write to reach 0 items, or if we were already empty and did neither/both
            empty <= (do_read && !do_write && (count == 1)) || (empty && !(do_write && !do_read));
        end
    end

endmodule
