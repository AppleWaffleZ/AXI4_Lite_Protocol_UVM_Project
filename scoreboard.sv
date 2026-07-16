// ============================================================
// scoreboard.sv
// Depends on: sequence_item.sv
// Must compile BEFORE: env.sv
// ============================================================

class axi4lite_scoreboard extends uvm_subscriber #(axi4lite_seq_item);
    `uvm_component_utils(axi4lite_scoreboard)

    localparam OKAY   = 2'b00;
    localparam SLVERR = 2'b10;

    // Model of "last value written" per address, built purely from what
    // the monitor observed on the bus - not copied from the DUT internals.
    bit [31:0] model   [bit [7:0]];
    bit        written [bit [7:0]]; // has this address ever been successfully written?

    int num_checks;
    int num_errors;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Mirrors the DUT's own address decode (design.sv): only addr[7:4]==0
    // is mapped to a real register; anything else should come back SLVERR.
    function bit addr_is_valid(bit [7:0] addr);
        return (addr[7:4] == 4'h0);
    endfunction

    function void write(axi4lite_seq_item t);
        bit exp_valid;
        bit [1:0] exp_resp;

        `uvm_info("SCBD", $sformatf("Observed: %s", t.convert2string()), UVM_LOW)

        exp_valid = addr_is_valid(t.addr);
        exp_resp  = exp_valid ? OKAY : SLVERR;

        // Check the response code itself, regardless of read or write -
        // this is what actually catches address-decode bugs.
        if (t.resp !== exp_resp) begin
            num_errors++;
            `uvm_error("SCBD",
                $sformatf("%s resp mismatch addr=0x%0h: expected=%s actual=%0d",
                          t.is_write ? "WRITE" : "READ", t.addr,
                          exp_valid ? "OKAY" : "SLVERR", t.resp))
        end

        if (t.is_write) begin
            // Only update the model if the write actually should have
            // landed - a rejected (SLVERR) write never touched a register.
            if (exp_valid) begin
                model[t.addr]   = t.data;
                written[t.addr] = 1;
            end
        end else begin
            if (!exp_valid) begin
                // Out-of-range read: nothing to compare data against,
                // the resp check above already covered correctness here.
                num_checks++;
            end else if (!written.exists(t.addr) || !written[t.addr]) begin
                `uvm_warning("SCBD",
                    $sformatf("READ from addr=0x%0h with no prior WRITE observed - nothing to check against",
                              t.addr))
            end else if (t.data !== model[t.addr]) begin
                num_errors++;
                `uvm_error("SCBD",
                           $sformatf("[%0t ns] MISMATCH addr=0x%0h: expected=0x%0h actual=0x%0h",
                              $time ,t.addr, model[t.addr], t.data))
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
