// 寄存器的管理器，负责将多个uvm_reg实例组织在一起，并定义它们的基地址和地址映射表
`ifndef AXIL_REGISTER_REG_DATA_SV
`define AXIL_REGISTER_REG_DATA_SV

`include "uvm_macros.svh"

class axil_register_reg_data extends uvm_reg;
    `uvm_object_utils(axil_register_reg_data)

    rand uvm_reg_field fld_low;
    rand uvm_reg_field fld_high;

    function new(string name = "axil_register_reg_data");
        // 参数：名字，总位宽，是否支持覆盖率
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        fld_low = uvm_reg_field::type_id::create("fld_low");
        // 参数：父类，位宽，最低位位置，访问权限，是否易失，复位值，是否有复位，是否可随机，是否可单独存取
        fld_low.configure(this, 16, 0, "RW", 0, 16'h0, 1, 1, 1);

        fld_high = uvm_reg_field::type_id::create("fld_high");
        // 注意：起始位置设为 16
        fld_high.configure(this, 16, 16, "RW", 0, 16'h0, 1, 1, 1);
    endfunction
endclass

`endif // AXIL_REGISTER_REG_DATA_SV