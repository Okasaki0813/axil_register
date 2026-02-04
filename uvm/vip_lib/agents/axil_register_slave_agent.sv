`ifndef AXIL_REGISTER_SLAVE_AGENT_SV
`define AXIL_REGISTER_SLAVE_AGENT_SV

class axil_register_slave_agent extends axil_register_base_agent;
    `uvm_component_utils(axil_register_slave_agent)

    virtual taxi_axil_if                slv_vif;
    axil_register_slave_driver          slv_drv;
    axil_register_monitor               slv_mon;

    function new(string name = "axil_register_slave_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        slv_vif = cfg.slv_vif;

        if (slv_vif == null) begin
            `uvm_fatal("NOVIF", "Slave vif is null in config!")
        end

        slv_mon = axil_register_monitor::type_id::create("slv_mon", this);

        if (cfg.slave_active == UVM_ACTIVE) begin
            slv_drv = axil_register_slave_driver::type_id::create("slv_drv", this);
        end        
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if (cfg.slave_active == UVM_ACTIVE) begin
            slv_drv.vif = slv_vif;
        end

        slv_mon.vif = slv_vif;
        slv_mon.ap.connect(this.ap);
    endfunction
endclass

`endif // AXIL_REGISTER_SLAVE_AGENT_SV
