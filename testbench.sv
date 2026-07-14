// ============================================================
// testbench.sv
// This is the file EDA Playground actually compiles first from
// the Testbench pane. It pulls in every other tab via `include,
// in dependency order, then defines the top module.
//
// IMPORTANT: adding a file as a tab in EDA Playground does NOT
// automatically compile it - it only gets compiled if something
// `includes it (or if it's added to the file list separately in
// tool settings). The `include chain below is what makes the
// split-file structure actually work.
// ============================================================

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "if.sv"                        // interface - no UVM dependency
`include "sequence_item.sv"             // depends on: nothing
`include "sequencer.sv"                 // depends on: sequence_item.sv
`include "driver.sv"                    // depends on: if.sv, sequence_item.sv
`include "monitor.sv"                   // depends on: if.sv, sequence_item.sv
`include "write_read_transaction_seq.sv"// depends on: sequence_item.sv, sequencer.sv
`include "agent.sv"                     // depends on: driver.sv, sequencer.sv, monitor.sv
`include "scoreboard.sv"                // depends on: sequence_item.sv
`include "env.sv"                       // depends on: agent.sv, scoreboard.sv
`include "axi4lite_base_test.sv"        // depends on: env.sv, write_read_transaction_seq.sv

// ------------------------------------------------------------
// Top-level: clock/reset, DUT, interface binding, run_test
// ------------------------------------------------------------
module top;
    logic clk;
    logic rst_n;

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        #20 rst_n = 1;
    end

    axi4lite_if #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) vif(.ACLK(clk), .ARESETn(rst_n));

    axi4lite_slave #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) dut (
        .ACLK    (clk),
        .ARESETn (rst_n),
        .AWADDR  (vif.AWADDR),  .AWVALID(vif.AWVALID), .AWREADY(vif.AWREADY),
        .WDATA   (vif.WDATA),   .WSTRB(vif.WSTRB), .WVALID(vif.WVALID), .WREADY(vif.WREADY),
        .BRESP   (vif.BRESP),   .BVALID(vif.BVALID), .BREADY(vif.BREADY),
        .ARADDR  (vif.ARADDR),  .ARVALID(vif.ARVALID), .ARREADY(vif.ARREADY),
        .RDATA   (vif.RDATA),   .RRESP(vif.RRESP), .RVALID(vif.RVALID), .RREADY(vif.RREADY)
    );

    initial begin
        uvm_config_db#(virtual axi4lite_if)::set(null, "*", "vif", vif);
        run_test("axi4lite_base_test");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top);
    end
endmodule
