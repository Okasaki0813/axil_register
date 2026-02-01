class axil_register_ral_virt_seq extends axil_register_base_virtual_sequence;
    `uvm_object_utils(axil_register_ral_virt_seq)

    function new(string name = "axil_register_ral_virt_seq");
        super.new(name);
    endfunction

    virtual task body();
        uvm_status_e    status; // 这是什么？
                                // 这是一个枚举类型变量，用于存放操作的执行结果（如 UVM_IS_OK 代表成功，UVM_NOT_OK 代表失败）。每次调用 read/write 后都要检查它。
        uvm_reg_data_t  data;   // 这又是什么？
                                // 这是 UVM 定义的一个数据类型（默认通常是 64 位宽逻辑变量），专门用来存放从寄存器读出或写入寄存器的数据。

        if (rm == null) begin
            `uvm_fatal("RAL_SEQ", "RegModel handle is null!")
        end

        `uvm_info(get_type_name(), "Starting RAL based sequence...", UVM_LOW)

        // --- 动作 1：前门写操作 (Frontdoor Write) ---
        // 直接通过寄存器名写值。参数：状态返回变量，写入的数据，路径（UVM_FRONTDOOR）
        rm.REG_DATA.write(status, 32'h5555_AAAA, UVM_FRONTDOOR);   // 这里的write函数是哪个类里的？
                                                    // 该函数最终定义在 uvm_reg 基类中。因为你的 reg_data 继承自 uvm_reg，所以它拥有这个功能。
        `uvm_info(get_type_name(), "RAL Write REG_DATA finished", UVM_LOW)

        // --- 动作 2：前门读操作 (Frontdoor Read) ---
        // 参数：状态返回变量，读回数据的存放变量，路径
        rm.REG_DATA.read(status, data);
        `uvm_info(get_type_name(), $sformatf("RAL Read REG_DATA: 'h%0h", data), UVM_LOW)

        // --- 动作 3：使用镜像值比对 ---
        // 读回数据后，RAL 会自动更新内部镜像值。你可以检查当前硬件值是否符合预期
        rm.REG_DATA.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
        
        `uvm_info(get_type_name(), "RAL sequence finished", UVM_LOW)
    endtask
endclass