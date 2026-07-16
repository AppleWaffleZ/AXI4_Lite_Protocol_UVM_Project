// ------------------------------------------------------------
// Environment
// ------------------------------------------------------------
class axi4lite_env extends uvm_env;
    `uvm_component_utils(axi4lite_env)

    axi4lite_agent       	agent;
    axi4lite_scoreboard  	scbd;
  	axi4lite_addr_coverage	cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = axi4lite_agent::type_id::create("agent", this);
        scbd  = axi4lite_scoreboard::type_id::create("scbd", this);
      	cov   = axi4lite_addr_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.mon.ap.connect(scbd.analysis_export);
      	agent.mon.ap.connect(cov.analysis_export);
    endfunction
endclass

