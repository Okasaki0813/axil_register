class axil_register_read_seq extends uvm_sequence#(axil_register_transaction);
    `uvm_object_utils(axil_register_read_seq)

    rand bit [31:0] addr;

    function new(string name = "axil_register_read_seq");
        super.new(name);
    endfunction

    virtual task body();
        req = axil_register_transaction::type_id::create("req");
        
        start_item(req);
        req.operation = axil_register_transaction::READ;
        req.addr      = this.addr;
        finish_item(req);

        // 关键：等待读操作返回结果
        // get_response(rsp); 
        // tr.data = rsp.data;
    endtask
endclass