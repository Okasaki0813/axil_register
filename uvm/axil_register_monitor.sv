`include "uvm_macros.svh"

class axil_register_monitor extends uvm_monitor;
    `uvm_component_utils(axil_register_monitor)

    virtual taxi_axil_if vif;

    uvm_analysis_port #(axil_register_transaction) ap; // 分析端口用于将数据包从monitor发送至scoreboard

    function new(string name = "axil_register_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            collect_write_data();
            collect_read_data();
        join
    endtask

    extern task collect_write_data();
    extern task collect_read_data();
endclass

task axil_register_monitor::collect_write_data();
    axil_register_transaction tr;

    forever begin
        tr = axil_register_transaction::type_id::create("tr"); // type_id是什么？create()又是用来干嘛的？
                                                               // type_id是工厂中该名字的类模板
                                                               // create()方便日后修改类中的方法时，工厂自动生成新的对象（工厂覆盖）
        tr.operation = axil_register_transaction::WRITE;

        fork
            begin
                // 捕捉写地址AW
                wait(vif.awvalid === 1'b1 && vif.awready === 1'b1);
                tr.addr = vif.awaddr;
                tr.prot = vif.awprot;
                tr.user = vif.awuser;
            end

            begin
                // 捕捉写数据W
                wait(vif.wvalid === 1'b1 && vif.wready === 1'b1);
                tr.data = vif.wdata;
                tr.strb = vif.wstrb;
            end
        join

        // 捕捉写响应
        wait(vif.bvalid === 1'b1 && vif.bready === 1'b1);
        tr.resp = vif.bresp;

        // 将数据发送给scoreboard
        @(posedge vif.clk);
        ap.write(tr); // 这个write函数是ap自带的
        `uvm_info(get_type_name(), "Collected a WRITE transaction", UVM_HIGH)
    end
endtask

task axil_register_monitor::collect_read_data();
    axil_register_transaction tr;

    forever begin
        tr = axil_register_transaction::type_id::create("tr");
        tr.operation = axil_register_transaction::READ;

        // 捕捉读地址信号AR
        wait(vif.arvalid === 1'b1 && vif.arready === 1'b1);
        tr.addr = vif.araddr;
        tr.prot = vif.arprot;
        tr.user = vif.aruser;

        // 捕捉读数据信号R
        wait(vif.rvalid === 1'b1 && vif.rready === 1'b1);
        tr.data = vif.rdata;
        tr.resp = vif.rresp;

        @(posedge vif.clk);
        ap.write(tr);
    end
endtask