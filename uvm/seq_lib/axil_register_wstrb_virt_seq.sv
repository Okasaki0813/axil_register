`ifndef AXIL_REGISTER_WSTRB_VIRT_SEQ_SV
`define AXIL_REGISTER_WSTRB_VIRT_SEQ_SV

class axil_register_wstrb_virt_seq extends axil_register_base_virtual_sequence;
    `uvm_object_utils(axil_register_wstrb_virt_seq)

    function new(string name = "axil_register_wstrb_virt_seq");
        super.new(name);
    endfunction

    virtual task body();
        axil_register_write_seq wr_seq;
        axil_register_read_seq  rd_seq;

        `uvm_info(get_type_name(), "Starting WSTRB specialized sequence...", UVM_LOW)

        // 步骤 1: 初始化背景值 (Full Write: h11223344)
        `uvm_do_on_with(wr_seq, p_sequencer.agt_sqr, {
            addr == 32'h0000_0010;
            data == 32'h1122_3344;
            strb == 4'b1111; 
        })

        // 步骤 2: 局部改写 (Partial Write: 只改低两个字节为 hAAAA)
        // 预期结果: h1122AAAA
        `uvm_do_on_with(wr_seq, p_sequencer.agt_sqr, {
            addr == 32'h0000_0010;
            data == 32'hDEAD_AAAA; // 高位数据应被掩码滤掉
            strb == 4'b0011; 
        })

        // 步骤 3: 验证结果
        `uvm_do_on_with(rd_seq, p_sequencer.agt_sqr, {
            addr == 32'h0000_0010;
        })
    endtask
endclass

`endif // AXIL_REGISTER_WSTRB_VIRT_SEQ_SV