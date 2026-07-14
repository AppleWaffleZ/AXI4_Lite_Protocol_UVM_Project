# AXI4-Lite UVM Testbench

A working, verified UVM testbench for a 4-register AXI4-Lite slave. Runs on
[EDA Playground](https://www.edaplayground.com/) with a full UVM library
(tested on Siemens VCS with UVM 1.2 - see note on Questa below).

**Status: passing.** Last verified run: 4/4 writes and 4/4 reads observed
correctly, scoreboard reports `4 checks passed, 0 errors`.

## Files

| File | Role |
|---|---|
| `design.sv` | DUT - AXI4-Lite slave, 4 x 32-bit registers at `0x00/0x04/0x08/0x0C` |
| `if.sv` | Interface bundling all 5 AXI4-Lite channels |
| `sequence_item.sv` | One write or read transaction (`axi4lite_seq_item`) |
| `sequencer.sv` | `axi4lite_sequencer` typedef |
| `driver.sv` | Drives pins from sequence items; waits for reset first |
| `monitor.sv` | Passively observes the bus; publishes both writes and reads |
| `write_read_transaction_seq.sv` | Writes each register then reads it back, with inline logging |
| `agent.sv` | Bundles driver + sequencer + monitor |
| `scoreboard.sv` | Models last-written value per address, checks every read against it |
| `env.sv` | Wires agent + scoreboard together |
| `test.sv` | Runs the sequence |
| `testbench.sv` | `` `include`` chain (in dependency order) + top module (clock/reset/DUT/`run_test`) |

## How to run on EDA Playground

1. Design pane: paste `design.sv`.
2. Testbench pane: create a tab per file above (name them exactly as
   listed - the `` `include`` statements in `testbench.sv` reference these
   names literally).
3. UVM/OVM dropdown: set to a real version (e.g. 1.2) - without this,
   `uvm_pkg` won't resolve.
4. Simulator: **VCS** is confirmed working. Questa has been observed to
   hang/get killed (exit 137) during its DPI auto-compile step on some
   EDA Playground server instances - this is a known class of platform
   issue, not a bug in this code. If you hit that, switch simulators
   rather than debugging the testbench.
5. Check **"Open EPWave after run"** to get a waveform automatically.
6. Run.

## What a passing run looks like

```
UVM_INFO ... [RNTST] Running test axi4lite_base_test...
UVM_INFO scoreboard.sv ... [SCBD] Observed: WRITE addr=0x0 data=0xcafe0000 resp=0
UVM_INFO write_read_transaction_seq.sv ... [write_read_transaction_seq] WRITE addr=0x0 data=0xcafe0000 -> resp=0
UVM_INFO write_read_transaction_seq.sv ... [write_read_transaction_seq] READ  addr=0x0 <- data=0xcafe0000 resp=0
... (repeats for 0x4, 0x8, 0xc) ...
UVM_INFO scoreboard.sv ... [SCBD] Scoreboard summary: 4 checks passed, 0 errors
```

## How the pieces fit together (the parts that weren't obvious at first)

**Reset synchronization.** The driver explicitly waits for `ARESETn` to go
high before driving any stimulus (`driver.sv`), and `AWREADY`/`ARREADY` in
the DUT are gated with `!ARESETn` (`design.sv`) so they can't glitch high
during reset regardless of testbench timing. Without both of these, the
first write handshake can appear to "complete" combinationally while the
DUT is still in reset, the driver drops `AWVALID`/`WVALID` believing it
succeeded, and then waits forever for a `BVALID` that can never arrive
since the pulse that would trigger it is already gone. That's a real
reset-timing deadlock, not a hypothetical one - it's what this project
hit and fixed.

**Read tracking in the monitor.** Unlike a write (where address and data
arrive on the same beat), a read's address (`AR`) and its data (`R`)
arrive at different times. `monitor.sv` handles this with a small queue
(`ar_addr_q`): push the address when `AR` completes, pop it and pair it
with the incoming data when `R` completes. A queue (rather than a single
variable) keeps this correct even if the design is later extended to
pipeline multiple outstanding reads.

**Scoreboard is a real checker, not just a logger.** `scoreboard.sv` keeps
a `model[addr]` of the last value written to each address (built purely
from observed bus traffic, not copied from DUT internals) and compares
every observed read against it, raising `uvm_error` on mismatch and
tallying a pass/fail summary in `report_phase`.

**Sequence-level logging vs. scoreboard checking.** `uvm_info` calls were
added directly in `write_read_transaction_seq.sv` after each
`finish_item()`. This works because `start_item`/`finish_item` pass the
same object handle through the sequencer to the driver (not a copy) - so
fields the driver fills in (`resp`, and the read-back `data`) are visible
back in the sequence once `finish_item()` returns. This is useful for
quick "did my stimulus round-trip correctly" visibility during
development; the scoreboard is the actual pass/fail authority.

## Known simplifications / good next extensions

These are deliberate scope cuts, not bugs:

1. **`WSTRB` is driven (always `4'hF`, full-word writes) but never checked
   by the DUT.** `design.sv`'s write logic unconditionally writes all 4
   bytes regardless of `WSTRB`. A spec-compliant slave should only update
   the byte lanes whose strobe bit is set. Good next exercise: add
   per-byte conditional writes in `design.sv`, then write a sequence that
   does a partial (single-byte) write and have the scoreboard verify only
   that byte changed.
2. **Only one transaction is outstanding at a time.** The driver fully
   completes each write or read before starting the next - there's no
   pipelining, and no ID-based out-of-order completion (this is
   AXI4-Lite, which has no ID fields at all).
3. **No error-injection tests.** Nothing currently exercises `SLVERR`
   (writing/reading an out-of-range address) even though `design.sv`
   implements it. Adding a sequence that deliberately hits an invalid
   address and checking the scoreboard/response for `SLVERR` would be a
   natural addition.
4. **No randomization.** The sequence is fully directed (fixed addresses,
   fixed data pattern). Randomizing `data` (and, for a burst-capable
   design, `addr`/burst length) would exercise more of the state space.
5. **This is AXI4-Lite, not full AXI4.** No bursts, no IDs, no exclusive
   access. Extending the DUT to a burst-capable slave with ID-tagged
   outstanding transactions would be the natural "next tier" project,
   and would let the monitor/scoreboard patterns here (queue-based
   pairing, model-based checking) be extended to handle out-of-order
   completion.
