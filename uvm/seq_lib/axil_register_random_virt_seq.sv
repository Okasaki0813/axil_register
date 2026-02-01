class axil_register_random_virt_seq extends axil_register_base_virtual_sequence;
    `uvm_object_utils(axil_register_random_virt_seq)

    function new(string name = "axil_register_random_virt_seq");
        super.new(name);
    endfunction

    virtual task body();
        axil_register_write_seq wr_seq;
        axil_register_read_seq  rd_seq;
        bit [31:0] last_addr;

        repeat(50) begin // 为什么这个名为body的task要声明为virtual类型？用于实现多态，即方便子类重写父类中的同名方法
            `uvm_do_on_with(wr_seq, p_sequencer.agt_sqr, {
                addr >= 32'h0; addr <= 32'h40;
                addr[1:0] == 2'b00;
            })                                      // uvm_do_on宏中的参数分别是什么意思？
                                                    // wr_seq是要执行的sequence的实例名
                                                    // p_sequencer.agt_sqr指定运行该seqeunce的sequencer的句柄
            last_addr = wr_seq.addr;
            `uvm_do_on_with(rd_seq, p_sequencer.agt_sqr, {
                addr == last_addr;
            })
        end
    endtask
endclass