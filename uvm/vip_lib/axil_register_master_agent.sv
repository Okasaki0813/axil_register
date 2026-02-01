`ifndef AXIL_REGISTER_MASTER_AGENT_SV
`define AXIL_REGISTER_MASTER_AGENT_SV

`include "uvm_macros.svh"

// axil_register_master_agent
// 说明: 重命名自 axil_register_agent，作为 Master 侧的 UVM agent。
// 本文件与原逻辑一致，仅改名以便与 Slave/其他 agent 区分。
class axil_register_master_agent extends uvm_agent;
    `uvm_component_utils(axil_register_master_agent)

    // 虚拟接口句柄，由 testbench 在 config_db 中设置
    virtual taxi_axil_if    vif;

    axil_register_sequencer sqr;
    axil_register_driver    drv;
    axil_register_monitor   mon;

    function new(string name = "axil_register_master_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // uvm_config_db::get(scope, inst_name, field_name, value)
        // - scope (this): 从当前组件开始查找配置
        // - inst_name (""): 空字符串表示通配，允许搜索子层级
        // - field_name ("vif"): 与 set 时使用的键名对应
        // - vif: 接收虚拟接口句柄的变量
        if(!uvm_config_db#(virtual taxi_axil_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("vif not found at path: %s", get_full_name()))
        end

        // create(name, parent) 中的第二个参数用于指定父组件（owner）
        // 将组件挂到父组件下，构建 UVM 层级树，便于 reporting/configuration/path 查询
        mon = axil_register_monitor::type_id::create("mon", this);

        // 仅当 agent 处于激活状态（UVM_ACTIVE）时创建 sequencer 和 driver
        if(get_is_active() == UVM_ACTIVE) begin
            sqr = axil_register_sequencer::type_id::create("sqr", this);
            drv = axil_register_driver::type_id::create("drv", this);
        end
    endfunction

    // 在类内声明方法，在类外实现是 SystemVerilog/UE惯用风格之一：
    // - 保持类定义清晰简短
    // - 便于把实现放在文件底部或单独文件中实现
    extern virtual function void connect_phase(uvm_phase phase);
endclass

function void axil_register_master_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // 仅当 agent 激活时，连接 driver 的虚拟接口与 sequencer 的端口
    if (get_is_active() == UVM_ACTIVE) begin
        drv.vif = this.vif; // 将接口句柄传递给 driver
        drv.seq_item_port.connect(sqr.seq_item_export); // 连接 sequencer <-> driver
    end

    // monitor 总是需要接口以观察信号，因此也要传递 vif
    mon.vif = this.vif;
endfunction

`endif // AXIL_REGISTER_MASTER_AGENT_SV
