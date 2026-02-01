class axil_register_write_seq extends uvm_sequence#(axil_register_transaction);
    `uvm_object_utils(axil_register_write_seq)

    // 定义随机化变量，方便在 virtual sequence 中使用 with 约束
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0]  strb;

    function new(string name = "axil_register_write_seq");
        super.new(name);
    endfunction

    virtual task body();
        // 创建一个 transaction 对象

        `uvm_info(get_type_name(), $sformatf("Writing data..."), UVM_LOW)

        req = axil_register_transaction::type_id::create("req");
        
        start_item(req); // 开始握手
        
        `uvm_info(get_type_name(), $sformatf("Writing started..."), UVM_LOW)
        
        // 将序列中的变量值传递给 transaction
        req.operation = axil_register_transaction::WRITE;
        req.addr      = this.addr;
        req.data      = this.data;
        req.strb      = this.strb;
        
        `uvm_info(get_type_name(), $sformatf("About to finish_item(req) and hand to driver"), UVM_LOW)
        finish_item(req); // 结束握手并发送给 driver

        `uvm_info(get_type_name(), $sformatf("finish_item returned; waiting for driver to complete"), UVM_LOW)

        // 这里可以等待 driver 把响应填回并完成（driver 会调用 item_done）
        `uvm_info(get_type_name(), $sformatf("Writing data succeed! resp=%0d", req.resp), UVM_LOW)
    endtask
endclass