// ============================================================
// sequencer.sv
// Depends on: sequence_item.sv (must be included first)
// Must compile BEFORE: driver.sv (connect_phase references it via agent),
//                       write_read_transaction_seq.sv, agent.sv
// ============================================================

typedef uvm_sequencer #(axi4lite_seq_item) axi4lite_sequencer;
