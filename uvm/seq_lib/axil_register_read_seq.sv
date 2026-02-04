`ifndef AXIL_REGISTER_READ_SEQ_SV
`define AXIL_REGISTER_READ_SEQ_SV

class axil_register_read_seq extends uvm_sequence#(axil_register_transaction);

    `uvm_object_utils(axil_register_read_seq)

    rand bit [31:0] addr;
    bit [31:0]      read_data;
    bit             got_response = 0;

    function new(string name = "axil_register_read_seq");
        super.new(name);
    endfunction

    virtual task body();
        axil_register_transaction rsp;

        req = axil_register_transaction::type_id::create("req");
        
        start_item(req);

        req.operation = axil_register_transaction::READ;
        req.addr      = this.addr;
        
        finish_item(req);

        get_response(rsp);
        this.read_data = rsp.data;  // 保存读回的数据
        this.got_response = 1;

        `uvm_info(get_type_name(), 
            $sformatf("Read addr=0x%0h, data=0x%0h", addr, read_data), 
            UVM_MEDIUM)
    endtask

endclass

`endif // AXIL_REGISTER_READ_SEQ_SV