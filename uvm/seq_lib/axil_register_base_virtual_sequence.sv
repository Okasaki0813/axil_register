class axil_register_base_virtual_sequence extends uvm_sequence;
    `uvm_object_utils(axil_register_base_virtual_sequence)

    axil_register_reg_block rm;
    
    `uvm_declare_p_sequencer(axil_register_virtual_sequencer) // 这个宏用于让virtual sequence有权限访问virtual sequencer内部的agent

    function new(string name = "axil_register_base_virtual_sequence");
        super.new(name);
    endfunction

    // 这里通常可以放一些所有剧本通用的等待复位完成的逻辑
    virtual task body();
        `uvm_info(get_type_name(), "Base virtual sequence body started", UVM_LOW)
    endtask
endclass