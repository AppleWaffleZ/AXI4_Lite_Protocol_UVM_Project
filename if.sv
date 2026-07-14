// ============================================================
// if.sv
// AXI4-Lite interface: bundles all 5 channels.
// No UVM dependency - must be compiled before driver.sv/monitor.sv
// since they declare "virtual axi4lite_if" handles.
// ============================================================

interface axi4lite_if #(parameter ADDR_WIDTH = 8, DATA_WIDTH = 32)
    (input logic ACLK, input logic ARESETn);

    logic [ADDR_WIDTH-1:0]   AWADDR;
    logic                    AWVALID;
    logic                    AWREADY;

    logic [DATA_WIDTH-1:0]   WDATA;
    logic [DATA_WIDTH/8-1:0] WSTRB;
    logic                    WVALID;
    logic                    WREADY;

    logic [1:0]              BRESP;
    logic                    BVALID;
    logic                    BREADY;

    logic [ADDR_WIDTH-1:0]   ARADDR;
    logic                    ARVALID;
    logic                    ARREADY;

    logic [DATA_WIDTH-1:0]   RDATA;
    logic [1:0]              RRESP;
    logic                    RVALID;
    logic                    RREADY;

endinterface
