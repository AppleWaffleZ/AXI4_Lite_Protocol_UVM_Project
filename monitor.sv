// ============================================================
// monitor.sv
// Depends on: if.sv, sequence_item.sv
// Must compile BEFORE: agent.sv
// ============================================================

class axi4lite_monitor extends uvm_monitor;
    `uvm_component_utils(axi4lite_monitor)

    virtual axi4lite_if vif;
    uvm_analysis_port #(axi4lite_seq_item) ap;

    // Holds read addresses whose AR handshake has completed but whose
    // R data hasn't arrived yet. AXI4-Lite only has one outstanding
    // transaction at a time in this simple design, so this queue will
    // normally hold at most one entry - but using a queue (rather than
    // a single variable) means this monitor still works correctly if
    // the DUT/driver are later extended to pipeline multiple reads.
    bit [7:0] ar_addr_q[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "virtual interface not set")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.ACLK);

            // Write: address and data arrive together on this simple slave,
            // so one beat is enough to publish a full write transaction.
            if (vif.AWVALID && vif.AWREADY && vif.WVALID && vif.WREADY) begin
                axi4lite_seq_item tr = axi4lite_seq_item::type_id::create("tr");
                tr.is_write = 1;
                tr.addr     = vif.AWADDR;
                tr.data     = vif.WDATA;
                ap.write(tr);
            end

            // Read address phase: remember the address, data isn't back yet.
            if (vif.ARVALID && vif.ARREADY) begin
                ar_addr_q.push_back(vif.ARADDR);
            end

            // Read data phase: pair the returned data with the oldest
            // pending address and publish the completed read transaction.
            if (vif.RVALID && vif.RREADY) begin
                axi4lite_seq_item tr = axi4lite_seq_item::type_id::create("tr");
                tr.is_write = 0;
                tr.data     = vif.RDATA;
                tr.resp     = vif.RRESP;
                if (ar_addr_q.size() == 0) begin
                    `uvm_warning("MON", "R beat seen with no pending AR address - check AR/R sequencing")
                    tr.addr = 8'h00;
                end else begin
                    tr.addr = ar_addr_q.pop_front();
                end
                ap.write(tr);
            end
        end
    endtask
endclass
