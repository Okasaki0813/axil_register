`ifndef AXIL_REGISTER_RAL_FIELD_TEST_SV
`define AXIL_REGISTER_RAL_FIELD_TEST_SV

class axil_register_ral_field_test extends axil_register_base_test;
    `uvm_component_utils(axil_register_ral_field_test)

    function new(string name = "axil_register_ral_field_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    // 重写 run_phase，使用 RAL 的字段访问 API
    virtual task run_phase(uvm_phase phase);
        uvm_status_e status;
        uvm_reg_data_t data;

        phase.raise_objection(this);
        
        `uvm_info("FIELD_TEST", "Step 1: Write initial background value 32'h11223344", UVM_LOW)
        env.rm.REG_DATA.write(status, 32'h1122_3344, UVM_FRONTDOOR);

        // 手动将模型状态设为“与硬件一致且干净”
        env.rm.REG_DATA.predict(32'h1122_3344);

        `uvm_info("FIELD_TEST", "Step 2: Update only fld_low to 16'hAAAA", UVM_LOW)
        // 使用 set() 仅改变模型内部期望值 (Desired Value)
        env.rm.REG_DATA.fld_low.set(16'hAAAA);
        
        // 调用 update()。RAL 会发现 fld_high 没变，只有 fld_low 脏了 (Dirty)
        // 于是 Adapter 的 reg2bus 会收到一个 byte_en=4'b0011 的请求
        env.rm.REG_DATA.update(status);

        #100ns;

        `uvm_info("FIELD_TEST", "Step 3: Mirror check. Expected Final Value: 32'h1122AAAA", UVM_LOW)
        env.rm.REG_DATA.mirror(status, UVM_CHECK, UVM_FRONTDOOR);

        phase.drop_objection(this);
    endtask
endclass

`endif