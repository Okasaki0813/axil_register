`ifndef AXIL_REGISTER_BASE_DRIVER_SV
`define AXIL_REGISTER_BASE_DRIVER_SV

`include "uvm_macros.svh"

class axil_register_base_driver extends uvm_driver#(axil_register_transaction);

    `uvm_component_utils(axil_register_base_driver)

    virtual taxi_axil_if vif;

    function new(string name = "axil_register_base_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            axil_register_transaction tr;
            seq_item_port.get_next_item(tr);
            drive_transaction(tr);
            seq_item_port.item_done();
        end
    endtask

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (!uvm_config_db#(virtual taxi_axil_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found!")
        end
    endfunction

    virtual task drive_transaction(axil_register_transaction tr);
    endtask

endclass

`endif // AXIL_REGISTER_BASE_DRIVER_SV