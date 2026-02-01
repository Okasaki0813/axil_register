// adapter在RAL和总线事务之间扮演翻译官的角色
`ifndef AXIL_REGISTER_REG_ADAPTER_SV
`define AXIL_REGISTER_REG_ADAPTER_SV

`include "uvm_macros.svh"

class axil_register_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(axil_register_reg_adapter);

    function new(string name = "axil_register_reg_adapter");    // 如果function不加返回值类型，返回值的默认类型是1bit的logic
                                                                // 这是构造函数，它是一个特例，不允许声明返回值类型，它默认返回该类的对象实例
        super.new(name);
        provides_responses = 0;
        supports_byte_enable = 1;
    endfunction

    // 在 Sequence 中调用 reg.write/read 时，UVM 自动调用此函数
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw); // const让函数内部只能读取rw的内容，不能修改它
                                                                             // ref表示引用传递
                                                                             // uvm_reg_bus_op是uvm_reg类中的一个结构体
                                                                            
        axil_register_transaction tr;
        tr = axil_register_transaction::type_id::create("tr");

        tr.operation = (rw.kind == UVM_WRITE) ? axil_register_transaction::WRITE : axil_register_transaction::READ;
        tr.addr      = rw.addr;
        tr.data      = rw.data;

        if (rw.kind == UVM_WRITE) begin
            tr.strb = rw.byte_en;
        end else begin
            tr.strb = 4'b0000;
        end

        return tr;
    endfunction

    // 当监视器捕捉到事务并反馈给 RAL 时，UVM 自动调用此函数更新镜像值
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        axil_register_transaction tr;
        
        if(!$cast(tr, bus_item)) begin // cast函数是类型转换函数
            `uvm_fatal("ADAPT", "Provided bus_item is not of the correct type") // 为什么这里不用get_type_name了？
            return; // 退出当前函数
        end

        rw.kind   = (tr.operation == axil_register_transaction::WRITE) ? UVM_WRITE : UVM_READ;
        rw.addr   = tr.addr;
        rw.data   = tr.data;
        rw.status = UVM_IS_OK;
    endfunction
endclass

`endif // AXIL_REGISTER_REG_ADAPTER_SV