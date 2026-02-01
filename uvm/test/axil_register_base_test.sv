`ifndef UVM_TEST_AXIL_REGISTER_BASE_TEST_SV
`define UVM_TEST_AXIL_REGISTER_BASE_TEST_SV

`include "uvm_macros.svh"

class axil_register_base_test extends uvm_test;
// base test的作用
// 1. 实例化env
// 2. 设置基础配置
    `uvm_component_utils(axil_register_base_test)

    axil_register_env env;
    axil_register_config cfg; // 实例化配置对象cfg

    function new(string name = "axil_register_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = axil_register_config::type_id::create("cfg");

        // 检查cfg是否从top获取了vif并将其存入cfg对象中
        if(!uvm_config_db#(virtual taxi_axil_if)::get(this, "", "vif", cfg.vif)) begin
            `uvm_fatal("NOVIF", "Test layer cannot get virtual interface vif from config_db!")
        end

        // 使用 "env*" 确保 env 及其所有子组件（如 agent）都能通过通配符拿到配置
        uvm_config_db#(axil_register_config)::set(this, "env*", "cfg", cfg);

        env = axil_register_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        // 这里留空，具体的激励启动由 smoke_test 等子类去实现
    endtask

    virtual function void end_of_elaboration_phase(uvm_phase phase);
           super.end_of_elaboration_phase(phase);
           uvm_top.print_topology(); // 打印uvm验证环境的层级结构
    endfunction
endclass

`endif // UVM_TEST_AXIL_REGISTER_BASE_TEST_SV