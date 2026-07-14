// ============================================================
// axi4lite_base_test.sv
// Depends on: env.sv, write_read_transaction_seq.sv
// This is the last `include before the top module in testbench.sv
// ============================================================

class axi4lite_base_test extends uvm_test;
    `uvm_component_utils(axi4lite_base_test)

    axi4lite_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi4lite_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        write_read_transaction_seq seq = write_read_transaction_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass
