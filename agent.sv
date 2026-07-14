// ============================================================
// agent.sv
// Depends on: driver.sv, sequencer.sv, monitor.sv
// Must compile BEFORE: env.sv
// ============================================================

class axi4lite_agent extends uvm_agent;
    `uvm_component_utils(axi4lite_agent)

    axi4lite_driver    drv;
    axi4lite_sequencer sqr;
    axi4lite_monitor   mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = axi4lite_driver::type_id::create("drv", this);
        sqr = axi4lite_sequencer::type_id::create("sqr", this);
        mon = axi4lite_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass
