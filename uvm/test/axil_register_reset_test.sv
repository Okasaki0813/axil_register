`ifndef AXIL_REGISTER_RESET_TEST_SV
`define AXIL_REGISTER_RESET_TEST_SV

// 复位测试 - 验证模块复位后的初始化状态
class axil_register_reset_test extends axil_register_base_test;
    `uvm_component_utils(axil_register_reset_test)

    function new(string name = "axil_register_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // 可选：在 build_phase 中自定义配置
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // 可在此处禁用 scoreboard 或 coverage，专注于复位验证
        // cfg.enable_scb = 0;
        // cfg.enable_cov = 0;
    endfunction

    // 主测试逻辑：启动复位序列
    virtual task run_phase(uvm_phase phase);
        axil_register_reset_virt_seq reset_seq = axil_register_reset_virt_seq::type_id::create("reset_seq");
        
        phase.raise_objection(this); // 告诉 UVM 框架有活动进行，防止提前结束仿真
        
        `uvm_info(get_type_name(), "Starting Reset Test...", UVM_LOW)
        reset_seq.start(env.virt_sqr); // 在虚拟 sequencer 上执行复位序列
        `uvm_info(get_type_name(), "Reset Test Completed", UVM_LOW)
        
        phase.drop_objection(this); // 告诉 UVM 框架活动已结束
    endtask

    // 可选：在 check_phase 中进行最终的验证和覆盖率统计
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        `uvm_info(get_type_name(), "Reset Test Check Phase - All verifications passed", UVM_LOW)
    endfunction

endclass

`endif // AXIL_REGISTER_RESET_TEST_SV
