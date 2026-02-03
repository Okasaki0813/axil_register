`ifndef AXIL_REGISTER_BASE_MONITOR_SV
`define AXIL_REGISTER_BASE_MONITOR_SV

`include "uvm_macros.svh"

class axil_register_base_monitor extends uvm_monitor;
    `uvm_component_utils(axil_register_base_monitor)

    virtual taxi_axil_if vif;
    uvm_analysis_port#(axil_register_transaction) ap;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            collect_write_data();
            collect_read_data();
        join
    endtask

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (!uvm_config_db#(virtual taxi_axil_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found!")
        end
    endfunction

    pure virtual task collect_write_data();
    pure virtual task collect_read_data();
endclass

`endif // AXIL_REGISTER_BASE_MONITOR_SV