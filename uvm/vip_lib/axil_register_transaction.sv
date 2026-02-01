import uvm_pkg::*;
`include "uvm_macros.svh"

class axil_register_transaction extends uvm_sequence_item;

    rand logic [31:0] addr;
    rand logic [31:0] data;
    rand logic [3:0]  strb; // 写掩码
    rand logic [2:0]  prot;
    rand logic [31:0] user;
    logic      [1:0]  resp;

    typedef enum {READ, WRITE} op_type_e;
    rand op_type_e  operation;  // 区分读操作/写操作
    rand int        delay;      // 两个事务之间的时钟周期延迟

    constraint c_delay {delay inside {[0:10]};}
    constraint c_addr  {addr[1:0] == 2'b00;}
    constraint c_strb  {(operation == READ) -> strb == 0;}

    `uvm_object_utils_begin(axil_register_transaction)
        `uvm_field_int (addr,                 UVM_ALL_ON)
        `uvm_field_int (data,                 UVM_ALL_ON)
        `uvm_field_int (strb,                 UVM_ALL_ON)
        `uvm_field_int (prot,                 UVM_ALL_ON)
        `uvm_field_int (user,                 UVM_ALL_ON)
        `uvm_field_int (resp,                 UVM_ALL_ON)
        `uvm_field_enum(op_type_e, operation, UVM_ALL_ON)
        `uvm_field_int (delay,                UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axil_register_transaction");
        super.new(name);
    endfunction

endclass