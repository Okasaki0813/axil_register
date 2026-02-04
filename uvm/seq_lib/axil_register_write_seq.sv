`ifndef AXIL_REGISTER_WRITE_SEQ_SV
`define AXIL_REGISTER_WRITE_SEQ_SV

class axil_register_write_seq extends uvm_sequence#(axil_register_transaction);

    `uvm_object_utils(axil_register_write_seq)

    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0]  strb;

    constraint addr_alignment {
        addr[1:0] == 2'b00;  // 32位对齐
    }

    constraint default_strb {
        strb == 4'b1111;  // 默认全字节使能
    }

    function new(string name = "axil_register_write_seq");
        super.new(name);
    endfunction

    virtual task body();
        req = axil_register_transaction::type_id::create("req");
        
        start_item(req); // 开始握手
        
        req.operation = axil_register_transaction::WRITE;
        req.addr      = this.addr;
        req.data      = this.data;
        req.strb      = this.strb;

        finish_item(req); // 结束握手并将req发送给 driver
    endtask

endclass

`endif // AXIL_REGISTER_WRITE_SEQ_SV