module noc_top_tb;
reg clk;
reg reset;
wire [7:0] tg_packet;
wire tg_valid;
wire [3:0] sink_valid;
wire [31:0] sink_packet;

noc_top uut(
    .clk(clk),
    .reset(reset),
    .tg_valid(tg_valid),
    .tg_packet(tg_packet),
    .sink_valid(sink_valid),
    .sink_packet(sink_packet)
);

always #5 clk = ~clk;

integer cycle;
integer injected_packets;
integer delivered_packets;
integer total_delay;
integer max_delay;
integer first_inject_cycle;
integer last_delivery_cycle;
integer results_fd;
real active_cycles;
real avg_delay_cycles;
real throughput_packets_per_cycle;
real traffic_percent;
reg test_done;
integer i;
reg [7:0] prev_tg_packet;
reg prev_tg_valid;
reg prev_tg_ready;

reg [7:0] expected_packets [0:3];
integer inject_cycle [0:255];
integer deliver_cycle [0:255];
reg seen_inject [0:255];
reg seen_deliver [0:255];

function [7:0] sink_byte;
    input [31:0] packed_packet;
    input integer index;
    begin
        case (index)
            0: sink_byte = packed_packet[7:0];
            1: sink_byte = packed_packet[15:8];
            2: sink_byte = packed_packet[23:16];
            default: sink_byte = packed_packet[31:24];
        endcase
    end
endfunction

function integer expected_sink;
    input [7:0] packet;
    begin
        case (packet[7:6])
            2'b00: expected_sink = 0;
            2'b01: expected_sink = 1;
            2'b10: expected_sink = 2;
            default: expected_sink = 3;
        endcase
    end
endfunction

task record_injection;
    input [7:0] packet;
    begin
        if (injected_packets >= 4)
        begin
            $fatal(1, "Unexpected extra packet injection: %02h", packet);
        end

        if (packet != expected_packets[injected_packets])
        begin
            $fatal(1, "Injection order mismatch at index %0d: got %02h expected %02h",
                   injected_packets, packet, expected_packets[injected_packets]);
        end

        if (!seen_inject[packet])
        begin
            seen_inject[packet] = 1'b1;
            inject_cycle[packet] = cycle;
            injected_packets = injected_packets + 1;

            if (injected_packets == 1)
            begin
                first_inject_cycle = cycle;
            end

            $display("INJECT cycle=%0d packet=%02h dest=%0d", cycle, packet, expected_sink(packet));
        end
    end
endtask

task record_delivery;
    input integer sink_index;
    input [7:0] packet;
    integer delay_cycles;
    begin
        if (expected_sink(packet) != sink_index)
        begin
            $fatal(1, "Packet %02h reached sink %0d but expected sink %0d", packet, sink_index, expected_sink(packet));
        end

        if (!seen_inject[packet])
        begin
            $fatal(1, "Packet %02h was delivered before injection was recorded", packet);
        end

        if (seen_deliver[packet])
        begin
            $fatal(1, "Packet %02h was delivered more than once", packet);
        end

        seen_deliver[packet] = 1'b1;
        deliver_cycle[packet] = cycle;
        delivered_packets = delivered_packets + 1;
        last_delivery_cycle = cycle;

        delay_cycles = cycle - inject_cycle[packet];
        total_delay = total_delay + delay_cycles;
        if (delay_cycles > max_delay)
        begin
            max_delay = delay_cycles;
        end

        $display("DELIVER cycle=%0d sink=%0d packet=%02h delay=%0d", cycle, sink_index, packet, delay_cycles);

        if (delivered_packets == 4)
        begin
            test_done = 1'b1;
        end
    end
endtask

initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0, noc_top_tb);

    clk = 1'b0;
    reset = 1'b1;
    cycle = 0;
    injected_packets = 0;
    delivered_packets = 0;
    total_delay = 0;
    max_delay = 0;
    first_inject_cycle = 0;
    last_delivery_cycle = 0;
    test_done = 1'b0;

    expected_packets[0] = 8'h01;
    expected_packets[1] = 8'h45;
    expected_packets[2] = 8'h99;
    expected_packets[3] = 8'hED;

    results_fd = $fopen("Analysis/noc_results.csv", "w");
    if (results_fd == 0)
    begin
        $fatal(1, "Unable to open Analysis/noc_results.csv for writing");
    end

    $fdisplay(results_fd, "traffic_percent,avg_latency_cycles,throughput_packets_per_cycle,packets_delivered,packet_loss_percent");

    for (i = 0; i < 256; i = i + 1)
    begin
        inject_cycle[i] = 0;
        deliver_cycle[i] = 0;
        seen_inject[i] = 1'b0;
        seen_deliver[i] = 1'b0;
    end

    #20;
    reset = 1'b0;

    fork
        begin : wait_for_completion
            wait (test_done);
            #10;

            if (injected_packets != 4)
            begin
                $fatal(1, "Expected 4 injected packets, got %0d", injected_packets);
            end

            if (delivered_packets != 4)
            begin
                $fatal(1, "Expected 4 delivered packets, got %0d", delivered_packets);
            end

            active_cycles = last_delivery_cycle - first_inject_cycle + 1;
            if (active_cycles <= 0.0)
            begin
                active_cycles = 1.0;
            end

            avg_delay_cycles = 1.0 * total_delay / delivered_packets;
            throughput_packets_per_cycle = delivered_packets / active_cycles;
            traffic_percent = 100.0 * injected_packets / active_cycles;

            $fdisplay(results_fd, "%0.2f,%0.2f,%0.4f,%0d,%0.2f",
                     traffic_percent,
                     avg_delay_cycles,
                     throughput_packets_per_cycle,
                     delivered_packets,
                     0.0);
            $fclose(results_fd);

            $display("SUMMARY first_inject_cycle=%0d last_delivery_cycle=%0d total_delay=%0d avg_delay=%0d max_delay=%0d",
                     first_inject_cycle,
                     last_delivery_cycle,
                     total_delay,
                     total_delay / delivered_packets,
                     max_delay);
            $finish;
        end
        begin : timeout_guard
            #1000;
            $fatal(1, "Timeout waiting for all packets to be injected and delivered");
        end
    join_any
    disable fork;
end

always @(posedge clk)
begin
    if (reset)
    begin
        cycle = 0;
    end
    else
    begin
        #1;
        cycle = cycle + 1;

        if (prev_tg_valid && prev_tg_ready)
        begin
            record_injection(prev_tg_packet);
        end

        if (sink_valid[0])
        begin
            record_delivery(0, sink_byte(sink_packet, 0));
        end

        if (sink_valid[1])
        begin
            record_delivery(1, sink_byte(sink_packet, 1));
        end

        if (sink_valid[2])
        begin
            record_delivery(2, sink_byte(sink_packet, 2));
        end

        if (sink_valid[3])
        begin
            record_delivery(3, sink_byte(sink_packet, 3));
        end
    end
end

always @(negedge clk)
begin
    if (reset)
    begin
        prev_tg_packet = 8'h00;
        prev_tg_valid = 1'b0;
        prev_tg_ready = 1'b0;
    end
    else
    begin
        prev_tg_packet = tg_packet;
        prev_tg_valid = tg_valid;
        prev_tg_ready = uut.tg_ready;
    end
end

endmodule
