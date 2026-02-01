`include "uvm_macros.svh"

class axil_register_basic_seq extends uvm_sequence #(axil_register_transaction);
    `uvm_object_utils(axil_register_basic_seq)
    
    function new(string name = "axil_register_basic_seq");
        super.new(name);        
    endfunction

    virtual task body();
        bit [31:0] addr_q[$]; // 地址队列，用于存储写入的地址
        bit [7:0]  cnt = 8'h00;

        req = axil_register_transaction::type_id::create("req");
    endtask
endclass