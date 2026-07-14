// ============================================================
// driver.sv
// Depends on: if.sv, sequence_item.sv
// Must compile BEFORE: agent.sv
// ============================================================

class axi4lite_driver extends uvm_driver #(axi4lite_seq_item);
    `uvm_component_utils(axi4lite_driver)

    virtual axi4lite_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi4lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "virtual interface not set")
    endfunction

    task run_phase(uvm_phase phase);
        vif.AWVALID <= 0; vif.WVALID <= 0; vif.BREADY <= 1;
        vif.ARVALID <= 0; vif.RREADY <= 1;

        // Wait for reset to deassert before driving anything - otherwise
        // combinational READY signals can glitch high mid-reset and the
        // driver will think a handshake completed when it didn't.
        @(posedge vif.ARESETn);
        @(posedge vif.ACLK);

        forever begin
            axi4lite_seq_item req;
            seq_item_port.get_next_item(req);
            if (req.is_write) do_write(req);
            else               do_read(req);
            seq_item_port.item_done();
        end
    endtask

    task do_write(axi4lite_seq_item req);
        @(posedge vif.ACLK);
        vif.AWADDR  <= req.addr;
        vif.AWVALID <= 1;
        vif.WDATA   <= req.data;
        vif.WSTRB   <= '1;
        vif.WVALID  <= 1;
        do @(posedge vif.ACLK); while (!(vif.AWREADY && vif.WREADY));
        vif.AWVALID <= 0;
        vif.WVALID  <= 0;
        do @(posedge vif.ACLK); while (!vif.BVALID);
        req.resp = vif.BRESP;
    endtask

    task do_read(axi4lite_seq_item req);
        @(posedge vif.ACLK);
        vif.ARADDR  <= req.addr;
        vif.ARVALID <= 1;
        do @(posedge vif.ACLK); while (!vif.ARREADY);
        vif.ARVALID <= 0;
        do @(posedge vif.ACLK); while (!vif.RVALID);
        req.data = vif.RDATA;
        req.resp = vif.RRESP;
    endtask
endclass
