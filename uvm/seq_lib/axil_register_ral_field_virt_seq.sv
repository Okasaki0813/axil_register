`ifndef AXIL_REGISTER_RAL_FIELD_VIRT_SEQ_SV
`define AXIL_REGISTER_RAL_FIELD_VIRT_SEQ_SV

class axil_register_ral_field_virt_seq extends axil_register_base_virtual_sequence;
    `uvm_object_utils(axil_register_ral_field_virt_seq)

    function new(string name = "axil_register_ral_field_virt_seq");
        super.new(name);
    endfunction

    virtual task body();
        uvm_status_e status;

        if (rm == null) `uvm_fatal("RAL_SEQ", "rm handle is null!")
        
        `uvm_info(get_type_name(), "Starting RAL Field-level Access Sequence...", UVM_LOW)

        // 步骤 1: 通过 RAL 给寄存器写一个背景值 (全字写)
        // 此时 Adapter 应该自动生成 strb = 4'b1111
        rm.REG_DATA.write(status, 32'h1122_3344, UVM_FRONTDOOR);

        // 步骤 2: 仅修改寄存器中的某个字段 (Field-level update)
        // 假设我们要把低 16 位修改为 0xAAAA
        // 注意：这里使用 set() 只改变模型期望值，不产生总线动作
        rm.REG_DATA.fld_low.set(16'hAAAA);
        
        // 步骤 3: 同步模型到硬件 (update)
        // RAL 会对比镜像值 (h11223344) 和期望值 (hXXXXAAAA)
        // 它会自动发现只有低两个字节变了，从而触发一个带有 strb = 4'b0011 的 AXI 写操作
        rm.REG_DATA.update(status);

        // 步骤 4: 前门读取验证
        rm.REG_DATA.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
    endtask
endclass

`endif