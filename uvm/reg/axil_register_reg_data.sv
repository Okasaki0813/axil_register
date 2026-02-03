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
        fld_low.configure(this, 16, 0, "RW", 0, 16'h0, 1, 1, 1);
        // 参数详解：
        // 1. this: 父寄存器
        // 2. 16: 字段位宽
        // 3. 0: 最低位位置（LSB位置）
        // 4. "RW": 访问权限（RW/RO/WO等）
        // 5. 0: 是否易失（volatile），0=非易失，1=易失
        // 6. 16'h0: 复位值
        // 7. 1: 是否有复位（1=有）
        // 8. 1: 是否可随机化（1=可随机）
        // 9. 1: 是否可单独存取（1=可单独访问）

        fld_high = uvm_reg_field::type_id::create("fld_high");
        // 注意：起始位置设为 16
        fld_high.configure(this, 16, 16, "RW", 0, 16'h0, 1, 1, 1);
    endfunction
endclass

`endif // AXIL_REGISTER_REG_DATA_SV