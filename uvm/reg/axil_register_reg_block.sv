`ifndef AXIL_REGISTER_REG_BLOCK_SV
`define AXIL_REGISTER_REG_BLOCK_SV

`include "uvm_macros.svh"

class axil_register_reg_block extends uvm_reg_block;
    `uvm_object_utils(axil_register_reg_block)
    
    rand axil_register_reg_data  REG_DATA; // 实例化寄存器

    function new(string name = "axil_register_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // 创建寄存器实例
        REG_DATA = axil_register_reg_data::type_id::create("REG_DATA");
        REG_DATA.configure(this, null, ""); // 父类，后门路径
        REG_DATA.build();

        // 创建地址映射表 (Address Map)
        // 参数：名字，基地址，系统总线位宽（字节），字节序
        default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN);
        // 将寄存器加入映射表：寄存器实例，偏移地址，访问权限
        default_map.add_reg(REG_DATA, 32'h0, "RW");
        
        lock_model(); // 锁定模型，禁止进一步修改
    endfunction
endclass

`endif // AXIL_REGISTER_REG_BLOCK_SV