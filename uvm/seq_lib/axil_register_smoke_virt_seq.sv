class axil_register_smoke_virt_seq extends axil_register_base_virtual_sequence;
    // 冒烟测试是验证环境中最简单、最基本的测试用例，它主要用于验证环境通路
    `uvm_object_utils(axil_register_smoke_virt_seq)

    function new(string name = "axil_register_smoke_virt_seq");
        super.new(name);
    endfunction

    virtual task body();
        // 声明两个底层的原子物理序列
        axil_register_write_seq  wr_seq;
        axil_register_read_seq   rd_seq;

        `uvm_info(get_type_name(), "Executing Smoke Virtual Sequence...", UVM_LOW)
        // get_type_name()用于获取类型名，get_full_name()用于获取实例名
        
        // 1. 执行写操作
        `uvm_do_on_with(wr_seq, p_sequencer.agt_sqr, {
            addr == 32'h0000_0004;
            data == 32'hAAAA_BBBB;
        })

        // 2. 执行读操作（读刚才写的地址）
        `uvm_do_on_with(rd_seq, p_sequencer.agt_sqr, {
            addr == 32'h0000_0004;
        })
        
        `uvm_info(get_type_name(), "Smoke Virtual Sequence finished", UVM_LOW)
    endtask
endclass