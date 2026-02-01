// 地址译码与非法地址处理测试
class axil_register_addr_decode_test extends axil_register_base_test;
    `uvm_component_utils(axil_register_addr_decode_test)

    function new(string name = "axil_register_addr_decode_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // 可在此处自定义配置，例如禁用某些功能
    endfunction

    virtual task run_phase(uvm_phase phase);
        axil_register_addr_decode_virt_seq addr_seq = axil_register_addr_decode_virt_seq::type_id::create("addr_seq");
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting Address Decode Test...", UVM_LOW)
        addr_seq.start(env.virt_sqr);
        `uvm_info(get_type_name(), "Address Decode Test Completed", UVM_LOW)
        
        phase.drop_objection(this);
    endtask

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        `uvm_info(get_type_name(), "Address Decode Test Check Phase - All verifications passed", UVM_LOW)
    endfunction

endclass
