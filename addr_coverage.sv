// ============================================================
// addr_coverage.sv
// Depends on: sequence_item.sv
// A second subscriber on the monitor's analysis port - tracks
// which addresses have been exercised, independent of the
// scoreboard's pass/fail checking.
// ============================================================

class axi4lite_addr_coverage extends uvm_subscriber #(axi4lite_seq_item);
    `uvm_component_utils(axi4lite_addr_coverage)

    bit seen [bit [7:0]]; // addresses observed at least once

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write(axi4lite_seq_item t);
        seen[t.addr] = 1; // just record it - no pass/fail logic at all
    endfunction

    function void report_phase(uvm_phase phase);
        string addr_list = "";
        bit [7:0] a;

        `uvm_info("COV", $sformatf("Distinct addresses exercised: %0d", seen.num()), UVM_LOW)

        if (seen.first(a)) begin
            do begin
                addr_list = {addr_list, $sformatf("0x%0h ", a)};
            end while (seen.next(a));
        end
        `uvm_info("COV", $sformatf("Addresses: %s", addr_list), UVM_LOW)
    endfunction
endclass
