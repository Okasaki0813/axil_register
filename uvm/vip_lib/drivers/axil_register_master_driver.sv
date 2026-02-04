`ifndef AXIL_REGISTER_MASTER_DRIVER_SV
`define AXIL_REGISTER_MASTER_DRIVER_SV

`include "uvm_macros.svh"

class axil_register_master_driver extends axil_register_base_driver;
    `uvm_component_utils(axil_register_master_driver)

    function new(string name = "axil_register_master_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axil_register_transaction rsp;

        forever begin
            seq_item_port.get_next_item(req);

            drive_transaction(req);

            rsp = axil_register_transaction::type_id::create("rsp");
            rsp.copy(req);

            seq_item_port.put_response(rsp);

            seq_item_port.item_done();
        end
    endtask
    extern task drive_transaction(axil_register_transaction tr);
endclass

// 该任务负责将数据按照协议时序发送给DUT
task axil_register_master_driver::drive_transaction(axil_register_transaction tr);
    int aw_wait_cnt = 0;
    int w_wait_cnt  = 0;
    int b_wait_cnt  = 0;
    int ar_wait_cnt = 0;
    int r_wait_cnt  = 0;

    repeat(tr.delay) @(posedge vif.clk); // 验证不同延迟下模块工作的稳定性
                                         // 有delay时，模块保持空闲
                                         // 无delay时，模块进行连续传输

    `uvm_info(get_type_name(), $sformatf("drive_transaction: op=%0d addr=0x%0h data=0x%0h strb=0x%0h", tr.operation, tr.addr, tr.data, tr.strb), UVM_MEDIUM)

    if(tr.operation == axil_register_transaction::WRITE) begin // 在WRITE前面加上axil_register_transaction，是为了让编译器在变量WRITE对应的类中搜索该变量
        `uvm_info(get_type_name(), "drive_transaction: starting AW/W parallel handshake", UVM_MEDIUM)

        fork // 使用fork-join结构分别驱动AW和W通道是为了解耦二者的握手过程
            begin // 驱动AW通道
                vif.awaddr  <= tr.addr;
                vif.awprot  <= tr.prot;
                vif.awuser  <= tr.user;
                vif.awvalid <= 1'b1;

                // 等待 awready，并且每隔 100 个时钟周期打印一次状态
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
                vif.wdata   <= tr.data;
                vif.wstrb   <= tr.strb;
                vif.wuser   <= tr.user;
                vif.wvalid  <= 1'b1;

                while (!vif.wready) begin
                    @(posedge vif.clk);
                    w_wait_cnt++;
                    if ((w_wait_cnt % 100) == 0) begin
                        `uvm_warning(get_type_name(), $sformatf("W waiting... cycles=%0d wvalid=%0b wready=%0b wdata=0x%0h", w_wait_cnt, vif.wvalid, vif.wready, vif.wdata))
                    end
                end

                @(posedge vif.clk);
                vif.wvalid <= 1'b0;
                
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
        vif.bready <= 1'b0;
        `uvm_info(get_type_name(), $sformatf("drive_transfer: write complete, resp=0x%0h" , tr.resp), UVM_LOW)
    end else if (tr.operation == axil_register_transaction::READ) begin
        `uvm_info(get_type_name(), $sformatf("drive_transfer: starting READ addr=0x%0h", tr.addr), UVM_MEDIUM)

        vif.araddr  <= tr.addr;
        vif.arprot  <= tr.prot;
        vif.aruser  <= tr.user;
        vif.arvalid <= 1'b1;

        while (!vif.arready) begin
            @(posedge vif.clk);
            ar_wait_cnt++;
            if ((ar_wait_cnt % 100) == 0) begin
                `uvm_warning(get_type_name(), $sformatf("AR waiting... cycles=%0d arvalid=%0b arready=%0b araddr=0x%0h", ar_wait_cnt, vif.arvalid, vif.arready, vif.araddr))
            end
        end

        @(posedge vif.clk);
        vif.arvalid <= 1'b0;
        vif.rready  <= 1'b1;

        while (!vif.rvalid) begin
            @(posedge vif.clk);
            r_wait_cnt++;
            if ((r_wait_cnt % 50) == 0) begin
                `uvm_warning(get_type_name(), $sformatf("R waiting... cycles=%0d rvalid=%0b rready=%0b rresp=0x%0h", r_wait_cnt, vif.rvalid, vif.rready, vif.rresp))
            end
        end

        `uvm_info(get_type_name(), $sformatf("R valid seen after %0d cycles, rvalid=%0b rresp=0x%0h rdata=0x%0h", r_wait_cnt, vif.rvalid, vif.rresp, vif.rdata), UVM_LOW)

        tr.data <= vif.rdata;
        tr.resp <= vif.rresp;

        @(posedge vif.clk);
        vif.rready <= 1'b0;
        `uvm_info(get_type_name(), $sformatf("drive_transfer: read complete, resp=0x%0h data=0x%0h" , tr.resp, tr.data), UVM_LOW)
    end
endtask

`endif // AXIL_REGISTER_MASTER_DRIVER_SV