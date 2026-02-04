`ifndef AXIL_REGISTER_BASE_AGENT_SV
`define AXIL_REGISTER_BASE_AGENT_SV

class axil_register_base_agent extends uvm_agent;
    `uvm_component_utils(axil_register_base_agent)

    axil_register_config    cfg;

    uvm_analysis_port#(axil_register_transaction) ap;

    function new(string name = "axil_register_base_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap = new("ap", this);

        if (!uvm_config_db#(axil_register_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "Configuration object not found!")
        end

        if (get_is_active() == UVM_ACTIVE) begin

        end
    endfunction
endclass

`endif // AXIL_REGISTER_BASE_AGENT_SV