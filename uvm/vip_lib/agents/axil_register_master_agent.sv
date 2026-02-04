`ifndef AXIL_REGISTER_MASTER_AGENT_SV
`define AXIL_REGISTER_MASTER_AGENT_SV

class axil_register_master_agent extends axil_register_base_agent;
    `uvm_component_utils(axil_register_master_agent)

    virtual taxi_axil_if            mst_vif;

    axil_register_sequencer         mst_sqr;
    axil_register_master_driver     mst_drv;
    axil_register_monitor           mst_mon;

    function new(string name = "axil_register_master_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mst_vif = cfg.mst_vif;

        if (mst_vif == null) begin
            `uvm_fatal("NOVIF", "Master vif is null in config!")
        end

        mst_mon = axil_register_monitor::type_id::create("mst_mon", this);

        if(cfg.master_active == UVM_ACTIVE) begin
            mst_sqr = axil_register_sequencer::type_id::create("mst_sqr", this);
            mst_drv = axil_register_master_driver::type_id::create("mst_drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if(cfg.master_active == UVM_ACTIVE) begin
            mst_drv.vif = mst_vif;
            mst_drv.seq_item_port.connect(mst_sqr.seq_item_export);
        end

        mst_mon.vif = mst_vif;
        mst_mon.ap.connect(this.ap);
    endfunction
endclass

`endif // AXIL_REGISTER_MASTER_AGENT_SV

// uvm_config_db::get(scope, inst_name, field_name, value)
// - scope (this): 从当前组件开始查找配置
// - inst_name (""): 空字符串表示通配，允许搜索子层级
// - field_name ("vif"): 与 set 时使用的键名对应
// - vif: 接收虚拟接口句柄的变量