`include "uvm_macros.svh"

class axil_register_driver extends uvm_driver#(axil_register_transaction); // #后面跟的是driver需要传输的transaction的类型
    `uvm_component_utils(axil_register_driver)

    virtual taxi_axil_if vif;

    function new(string name = "axil_register_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        // 初始化信号，防止初始状态为不定态
        vif.awvalid <= 0;
        vif.wvalid  <= 0;
        vif.arvalid <= 0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    extern task drive_transfer(axil_register_transaction tr);
endclass

task axil_register_driver::drive_transfer(axil_register_transaction tr);
    repeat(tr.delay) @(posedge vif.clk); // 为什么这里要等待几个时钟周期？
                                         // 验证不同延迟下模块工作的稳定性
                                         // delay大，保持空闲
                                         // delay小，实现连续传输

    if(tr.operation == axil_register_transaction::WRITE) begin // 为什么要在WRITE前面加上axil_register_transaction？不加不行吗？
                                                               // 让编译器在变量WRITE对应的类中搜索该变量
        // `uvm_info(get_type_name(), $sformatf("Starting WRITE: addr='h%0h, data='h%0h", tr.addr, tr.data), UVM_LOW)

        fork // 此处使用fork-join结构是为了实现写数据通道与写地址通道的分离，让这两个通道并行运行
            begin // 驱动AW通道
                vif.awaddr  <= tr.addr;
                vif.awprot  <= tr.prot;
                vif.awuser  <= tr.user;
                vif.awvalid <= 1'b1;
                wait(vif.awready == 1'b1);
                @(posedge vif.clk);
                vif.awvalid <= 1'b0;
            end

            begin // 驱动W通道
                vif.wdata   <= tr.data;
                vif.wstrb   <= tr.strb;
                vif.wuser   <= tr.user;
                vif.wvalid  <= 1'b1;
                wait(vif.wready  == 1'b1);
                @(posedge vif.clk);
                vif.wvalid <= 1'b0;
            end
        join

        vif.bready <= 1'b1; // 告诉下游模块：我已经准备好接收你的写响应信号了

        wait(vif.bvalid == 1'b1); // 等待下游模块给出写响应信号

        tr.resp = vif.bresp; // 将响应结果存入数据包中，方便后面scoreboard进行检查

        @(posedge vif.clk);
        vif.bready <= 1'b0;

        // `uvm_info(get_type_name(), "AW and W handshake finished.", UVM_HIGH)
    end else if (tr.operation == axil_register_transaction::READ) begin
        vif.araddr  <= tr.addr;
        vif.arprot  <= tr.prot;
        vif.aruser  <= tr.user;
        vif.arvalid <= 1'b1;

        wait(vif.arready == 1'b1);

        @(posedge vif.clk);
        vif.arvalid <= 1'b0;
        vif.rready <= 1'b1;

        wait(vif.rvalid == 1'b1);
        tr.data = vif.rdata;
        tr.resp = vif.rresp;

        // `uvm_info(get_type_name(), $sformatf("Read Back Data: 'h%0h", vif.rdata), UVM_MEDIUM)

        @(posedge vif.clk);
        vif.rready <= 1'b0;
    end
endtask