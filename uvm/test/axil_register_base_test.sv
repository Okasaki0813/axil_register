`ifndef UVM_TEST_AXIL_REGISTER_BASE_TEST_SV
`define UVM_TEST_AXIL_REGISTER_BASE_TEST_SV

class axil_register_base_test extends uvm_test;
    `uvm_component_utils(axil_register_base_test)

    axil_register_env env;
    axil_register_config cfg;

    function new(string name = "axil_register_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = axil_register_config::type_id::create("cfg");
        if (cfg == null) begin
            `uvm_fatal("CFG_CREATE_FAIL", "Failed to create axil_register_config object!")
        end

        cfg.has_master      = 1;            // 默认启用master
        cfg.has_slave       = 1;            // 默认启用slave  
        cfg.enable_scb      = 1;            // 默认启用scoreboard
        cfg.master_active   = UVM_ACTIVE;
        cfg.slave_active    = UVM_ACTIVE;
        cfg.enable_cov      = 0;            // 默认不收集覆盖率（提高仿真速度）

        uvm_config_db#(axil_register_config)::set(this, "env", "cfg", cfg);
        
        env = axil_register_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "Base test: No specific test defined", UVM_LOW)
    endtask

    // virtual function void end_of_elaboration_phase(uvm_phase phase);
    //        super.end_of_elaboration_phase(phase);
    //        uvm_top.print_topology(); // 打印uvm验证环境的层级结构
    // endfunction
endclass

`endif // UVM_TEST_AXIL_REGISTER_BASE_TEST_SV