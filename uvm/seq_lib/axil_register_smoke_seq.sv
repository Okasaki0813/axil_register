`ifndef AXIL_REGISTER_SMOKE_SEQ_SV
`define AXIL_REGISTER_SMOKE_SEQ_SV

class axil_register_smoke_seq extends axil_register_base_virtual_sequence;
    // 冒烟测试是验证环境中最简单、最基本的测试用例，它主要用于验证环境通路
    `uvm_object_utils(axil_register_smoke_seq)

    bit [31:0] write_data = 32'hAAAA_BBBB;
    bit [31:0] read_data;

    function new(string name = "axil_register_smoke_seq");
        super.new(name);
    endfunction

    virtual task body();
        axil_register_write_seq  wr_seq;
        axil_register_read_seq   rd_seq;

        `uvm_info(get_type_name(), "Executing Smoke Sequence...", UVM_LOW)
        
        // 执行写操作
        `uvm_do_on_with(wr_seq, p_sequencer.agt_sqr, {
            addr == 32'h0000_0004;
            data == write_data;
            strb == 4'b1111;
        })

        // 执行读操作
        `uvm_do_on_with(rd_seq, p_sequencer.agt_sqr, {
            addr == 32'h0000_0004;
        })

        // 检查读回的数据是否与写入的数据一致
        read_data = rd_seq.read_data;
        if (read_data === write_data) begin
            `uvm_info(get_type_name(), 
                $sformatf("SUCCESS: Write 0x%0h, Read back 0x%0h", 
                         write_data, read_data), 
                UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), 
                $sformatf("FAIL: Wrote 0x%0h, but read back 0x%0h", 
                         write_data, read_data))
        end
        
        `uvm_info(get_type_name(), "Smoke Virtual Sequence finished!", UVM_LOW)
    endtask
endclass

`endif // AXIL_REGISTER_SMOKE_SEQ_SV