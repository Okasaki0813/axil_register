`ifndef AXIL_REGISTER_DRIVER_SV
`define AXIL_REGISTER_DRIVER_SV

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
        vif.awvalid <= 1'b0;
        vif.wvalid  <= 1'b0;
        vif.arvalid <= 1'b0;

        forever begin
            `uvm_info(get_type_name(), $sformatf("Driver waiting for next item..."), UVM_LOW)
            seq_item_port.get_next_item(req);
            `uvm_info(get_type_name(), $sformatf("Driver got item: op=%0d addr=0x%08h", req.operation, req.addr), UVM_LOW)
            drive_transfer(req);
            seq_item_port.item_done();
            `uvm_info(get_type_name(), $sformatf("Driver completed item: addr=0x%0h, resp=%0d", req.addr, req.resp), UVM_LOW)
        end
    endtask

    extern task drive_transfer(axil_register_transaction tr);
endclass

task axil_register_driver::drive_transfer(axil_register_transaction tr);
    int aw_wait_cnt = 0;
    int w_wait_cnt  = 0;
    int b_wait_cnt  = 0;
    int ar_wait_cnt = 0;
    int r_wait_cnt  = 0;

    repeat(tr.delay) @(posedge vif.clk); // 为什么这里要等待几个时钟周期？
                                         // 验证不同延迟下模块工作的稳定性
                                         // delay大，保持空闲
                                         // delay小，实现连续传输

    `uvm_info(get_type_name(), $sformatf("drive_transfer: op=%0d addr=0x%0h data=0x%0h strb=0x%0h", tr.operation, tr.addr, tr.data, tr.strb), UVM_MEDIUM)

    if(tr.operation == axil_register_transaction::WRITE) begin // 为什么要在WRITE前面加上axil_register_transaction？不加不行吗？
                                                               // 让编译器在变量WRITE对应的类中搜索该变量
        // `uvm_info(get_type_name(), $sformatf("Starting WRITE: addr='h%0h, data='h%0h", tr.addr, tr.data), UVM_LOW)
        `uvm_info(get_type_name(), "drive_transfer: starting AW/W parallel handshake", UVM_MEDIUM)

        // 驱动 AW/W 通道，并在可能的等待点增加周期性调试输出，防止长时间阻塞难以定位
        fork
            begin // 驱动AW通道
                vif.awaddr  <= tr.addr;
                vif.awprot  <= tr.prot;
                vif.awuser  <= tr.user;
                vif.awvalid <= 1'b1;
                // 等待 awready，并在每 100 个时钟周期打印一次状态
                while (!vif.awready) begin
                    @(posedge vif.clk);
                    aw_wait_cnt++;
                    if ((aw_wait_cnt % 100) == 0) begin
                        `uvm_warning(get_type_name(), $sformatf("AW waiting... cycles=%0d awvalid=%0b awready=%0b awaddr=0x%0h", aw_wait_cnt, vif.awvalid, vif.awready, vif.awaddr))
                    end
                end
                @(posedge vif.clk);
                vif.awvalid <= 1'b0;
                `uvm_info(get_type_name(), $sformatf("AW handshake done after %0d cycles, awready=%0b", aw_wait_cnt, vif.awready), UVM_LOW)
            end

            begin // 驱动W通道
                // 同上：对写数据通道也使用阻塞赋值
                vif.wdata   = tr.data;
                vif.wstrb   = tr.strb;
                vif.wuser   = tr.user;
                vif.wvalid  = 1'b1;
                while (!vif.wready) begin
                    @(posedge vif.clk);
                    w_wait_cnt++;
                    if ((w_wait_cnt % 100) == 0) begin
                        `uvm_warning(get_type_name(), $sformatf("W waiting... cycles=%0d wvalid=%0b wready=%0b wdata=0x%0h", w_wait_cnt, vif.wvalid, vif.wready, vif.wdata))
                    end
                end
                @(posedge vif.clk);
                vif.wvalid = 1'b0;
                `uvm_info(get_type_name(), $sformatf("W handshake done after %0d cycles, wready=%0b", w_wait_cnt, vif.wready), UVM_LOW)
            end
        join

        `uvm_info(get_type_name(), $sformatf("drive_transfer: AW/W join complete, awvalid=%0b wvalid=%0b awready=%0b wready=%0b", vif.awvalid, vif.wvalid, vif.awready, vif.wready), UVM_LOW)

        // 写响应阶段
        // 告知从设备我们准备好接收 B 响应；使用阻塞赋值立即生效
        vif.bready = 1'b1; // 告诉下游模块：我已经准备好接收你的写响应信号了

        while (!vif.bvalid) begin
            @(posedge vif.clk);
            b_wait_cnt++;
            if ((b_wait_cnt % 50) == 0) begin
                `uvm_warning(get_type_name(), $sformatf("B waiting... cycles=%0d bvalid=%0b bready=%0b bresp=0x%0h", b_wait_cnt, vif.bvalid, vif.bready, vif.bresp))
            end
        end

        `uvm_info(get_type_name(), $sformatf("B valid seen after %0d cycles, bvalid=%0b bresp=0x%0h", b_wait_cnt, vif.bvalid, vif.bresp), UVM_LOW)

        tr.resp = vif.bresp; // 将响应结果存入数据包中，方便后面scoreboard进行检查

        @(posedge vif.clk);
        vif.bready = 1'b0;
        `uvm_info(get_type_name(), $sformatf("drive_transfer: write complete, resp=0x%0h" , tr.resp), UVM_LOW)
    end else if (tr.operation == axil_register_transaction::READ) begin
        `uvm_info(get_type_name(), $sformatf("drive_transfer: starting READ addr=0x%0h", tr.addr), UVM_MEDIUM)

        // 读请求同样使用阻塞赋值以保证时序一致性
        vif.araddr  = tr.addr;
        vif.arprot  = tr.prot;
        vif.aruser  = tr.user;
        vif.arvalid = 1'b1;

        while (!vif.arready) begin
            @(posedge vif.clk);
            ar_wait_cnt++;
            if ((ar_wait_cnt % 100) == 0) begin
                `uvm_warning(get_type_name(), $sformatf("AR waiting... cycles=%0d arvalid=%0b arready=%0b araddr=0x%0h", ar_wait_cnt, vif.arvalid, vif.arready, vif.araddr))
            end
        end

        @(posedge vif.clk);
        vif.arvalid = 1'b0;
        vif.rready = 1'b1;

        while (!vif.rvalid) begin
            @(posedge vif.clk);
            r_wait_cnt++;
            if ((r_wait_cnt % 50) == 0) begin
                `uvm_warning(get_type_name(), $sformatf("R waiting... cycles=%0d rvalid=%0b rready=%0b rresp=0x%0h", r_wait_cnt, vif.rvalid, vif.rready, vif.rresp))
            end
        end

        `uvm_info(get_type_name(), $sformatf("R valid seen after %0d cycles, rvalid=%0b rresp=0x%0h rdata=0x%0h", r_wait_cnt, vif.rvalid, vif.rresp, vif.rdata), UVM_LOW)

        tr.data = vif.rdata;
        tr.resp = vif.rresp;

        @(posedge vif.clk);
        vif.rready = 1'b0;
        `uvm_info(get_type_name(), $sformatf("drive_transfer: read complete, resp=0x%0h data=0x%0h" , tr.resp, tr.data), UVM_LOW)
    end
endtask

`endif // AXIL_REGISTER_DRIVER_SV