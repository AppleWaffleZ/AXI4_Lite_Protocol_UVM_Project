// ============================================================
// scoreboard.sv
// Depends on: sequence_item.sv
// Must compile BEFORE: env.sv
// ============================================================

class axi4lite_scoreboard extends uvm_subscriber #(axi4lite_seq_item);
    `uvm_component_utils(axi4lite_scoreboard)

    // Model of "last value written" per address, built purely from what
    // the monitor observed on the bus - not copied from the DUT internals.
    bit [31:0] model   [bit [7:0]];
    bit        written [bit [7:0]]; // has this address ever been written?

    int num_checks;
    int num_errors;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write(axi4lite_seq_item t);
        `uvm_info("SCBD", $sformatf("Observed: %s", t.convert2string()), UVM_LOW)

        if (t.is_write) begin
            model[t.addr]   = t.data;
            written[t.addr] = 1;
        end else begin
            if (!written.exists(t.addr) || !written[t.addr]) begin
                `uvm_warning("SCBD",
                    $sformatf("READ from addr=0x%0h with no prior WRITE observed - nothing to check against",
                              t.addr))
            end else if (t.data !== model[t.addr]) begin
                num_errors++;
                `uvm_error("SCBD",
                    $sformatf("MISMATCH addr=0x%0h: expected=0x%0h actual=0x%0h",
                              t.addr, model[t.addr], t.data))
            end else begin
                num_checks++;
                `uvm_info("SCBD",
                    $sformatf("MATCH addr=0x%0h data=0x%0h", t.addr, t.data), UVM_LOW)
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCBD",
            $sformatf("Scoreboard summary: %0d checks passed, %0d errors",
                      num_checks, num_errors), UVM_LOW)
    endfunction
endclass
