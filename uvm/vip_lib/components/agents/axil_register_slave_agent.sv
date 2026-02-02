`ifndef AXIL_REGISTER_SLAVE_AGENT_SV
`define AXIL_REGISTER_SLAVE_AGENT_SV

`include "uvm_macros.svh"

// Slave agent: 为 DUT 提供从设备行为（驱动 bresp/rresp 等）和 monitor
class axil_register_slave_agent extends uvm_agent;
    `uvm_component_utils(axil_register_slave_agent)

    virtual taxi_axil_if    vif;

    axil_slave_driver    drv;
    axil_register_monitor mon;

    function new(string name = "axil_register_slave_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // 获取 vif
        if(!uvm_config_db#(virtual taxi_axil_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("SLVAGT", $sformatf("vif not found for %s", get_full_name()))
        end
        `uvm_info(get_type_name(), $sformatf("Slave agent build_phase: vif acquired, starting to create components"), UVM_LOW)

        mon = axil_register_monitor::type_id::create("mon", this);

        // 创建从设备驱动：从设备通常不需要 sequencer
        drv = axil_slave_driver::type_id::create("drv", this);
        `uvm_info(get_type_name(), $sformatf("Slave agent build_phase: slave driver created %s", drv.get_full_name()), UVM_LOW)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // 连接 vif
        if (drv != null) begin
            drv.vif = this.vif;
            `uvm_info(get_type_name(), $sformatf("Slave agent connect_phase: vif assigned to slave driver %s", drv.get_full_name()), UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), "Slave driver is null!")
        end
        if (mon != null) begin
            mon.vif = this.vif;
            `uvm_info(get_type_name(), $sformatf("Slave agent connect_phase: vif assigned to monitor %s", mon.get_full_name()), UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), "Monitor is null!")
        end
    endfunction
endclass

`endif // AXIL_REGISTER_SLAVE_AGENT_SV
