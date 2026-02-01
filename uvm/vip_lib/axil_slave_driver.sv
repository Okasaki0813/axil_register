`ifndef AXIL_SLAVE_DRIVER_SV
`define AXIL_SLAVE_DRIVER_SV

`include "uvm_macros.svh"

class axil_slave_driver extends axil_register_driver;
    `uvm_component_utils(axil_slave_driver)
    virtual taxi_axil_if vif; // 建议不要在定义时带 modport，在 connect 时指定即可
    
    // 声明类级别的标志位和存储器
    bit aw_done = 1'b0; // 写地址通道握手标志位
    bit w_done  = 1'b0; // 写数据通道握手标志位
    logic [31:0] saved_addr; // 用于暂存awaddr，防止2个时钟周期后vif.awaddr发生变化
    bit [31:0] mem_model [bit [31:0]]; // 关联数组作为 Memory Model

    // 地址限制：默认值（包含）。默认行为与之前一致：超过 0x0000_3FFF 返回 DECERR。
    // 这是可配置的成员，支持通过 uvm_config_db 在 top/test 中覆盖。
    logic [31:0] addr_limit;

    // RESP 常量，便于维护与阅读
    localparam logic [1:0] RESP_OKAY   = 2'b00;
    localparam logic [1:0] RESP_DECERR = 2'b10;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // 增加 build_phase 来获取接口
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase); // 必须调用 super，确保父类的 get 也能执行（如果有的话）
        
        // 从数据库中获取名为 "vif" 的接口，并赋值给本地的 vif 变量
        if (!uvm_config_db#(virtual taxi_axil_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("SLV_DRV", "Virtual interface not found for slave driver!")
        end

        // 尝试从 config_db 获取地址上限，如果未设置则使用默认值
        if (!uvm_config_db#(logic[31:0])::get(this, "", "addr_limit", addr_limit)) begin
            addr_limit = 32'h0000_3FFF; // backward-compatible default
        end
        `uvm_info(get_type_name(), $sformatf("Slave driver build_phase: vif initialized, addr_limit=0x%0h", addr_limit), UVM_LOW)
    endfunction

    virtual task run_phase(uvm_phase phase);
        int cycle_cnt = 0;

        // 初始化：Slave 默认拉高 Ready
        vif.awready <= 1'b1;
        vif.wready  <= 1'b1;
        vif.arready <= 1'b1;
        vif.bvalid  <= 1'b0;
        vif.rvalid  <= 1'b0;

        `uvm_info(get_type_name(), "Slave driver run_phase started", UVM_LOW)

        forever begin
            @(posedge vif.clk);
            if (!vif.rst) begin
                vif.bvalid  <= 1'b0;
                vif.awready <= 1'b1;
                vif.wready  <= 1'b1;
                vif.rvalid  <= 1'b0;
                vif.arready <= 1'b1;
                aw_done     <= 1'b0;
                w_done      <= 1'b0;
                `uvm_info(get_type_name(), "Reset detected, clearing response signals", UVM_LOW)
            end else begin
                // 默认保持 Ready 为 1 (模拟理想从机)
                // Ready 信号应该默认为 1，以便主机能够发送请求
                if (!vif.bvalid) vif.awready <= 1'b1;
                if (!vif.bvalid) vif.wready  <= 1'b1;
                if (!vif.rvalid) vif.arready <= 1'b1;

                // 调试输出：每 200 拍打印一次当前信号状态
                
                cycle_cnt++;
                if ((cycle_cnt % 200) == 0) begin
                    `uvm_info(get_type_name(), $sformatf("Slave running: aw_done=%0b w_done=%0b bvalid=%0b awvalid=%0b awready=%0b wvalid=%0b wready=%0b arready=%0b rvalid=%0b", 
                        aw_done, w_done, vif.bvalid, vif.awvalid, vif.awready, vif.wvalid, vif.wready, vif.arready, vif.rvalid), UVM_MEDIUM)
                end

                // 模拟反压：每拍有 30% 的概率拉低 Ready，模拟从机忙碌
                // vif.awready <= ( $urandom_range(0, 99) < 70 ); 
                // vif.wready  <= ( $urandom_range(0, 99) < 70 );
                // vif.arready <= ( $urandom_range(0, 99) < 70 );
                // `uvm_info("SLV_DRV", $sformatf("awready = 'b%0b, wready = 'b%0b, arready = 'b%0b", vif.awready, vif.wready, vif.arready), UVM_HIGH)
                
                // 注意：一旦 valid 和 ready 握手，下一拍通常要处理逻辑，
                // 这里的简单随机化可能导致握手变慢，这正是我们要测试的。

                // 独立捕捉各通道的握手信号
                if (vif.awvalid && vif.awready) begin 
                    aw_done = 1'b1;
                    saved_addr = vif.awaddr;
                    `uvm_info(get_type_name(), $sformatf("Slave: AW handshake detected, addr=0x%0h", vif.awaddr), UVM_MEDIUM)
                end

                if (vif.wvalid && vif.wready) begin
                    w_done = 1'b1;
                    `uvm_info(get_type_name(), $sformatf("Slave: W handshake detected, data=0x%0h", vif.wdata), UVM_MEDIUM)
                end

                // 检查是否两个通道都握手成功，且没有进行中的写响应
                if (aw_done && w_done && !vif.bvalid) begin
                    // 暂存当前事务的数据，防止被下一拍覆盖
                    logic [31:0] addr_to_store = saved_addr;
                    logic [31:0] data_to_store = vif.wdata; // 假设数据通道此时稳定
                    logic [31:0] wstrb_mask;    // 32位掩码
                    logic [31:0] old_data;      // 原有数据
                    logic [31:0] new_combined_data;

                    `uvm_info(get_type_name(), $sformatf("Slave: Write transaction detected, aw_done=%0b w_done=%0b addr=0x%0h", aw_done, w_done, addr_to_store), UVM_LOW)

                    // 立即清除状态位，准备接收下一个请求 
                    aw_done = 1'b0; 
                    w_done  = 1'b0;

                    addr_to_store = saved_addr;

                    // 生成 32 位掩码：利用位复制技巧
                    // 将 wstrb 的每一位扩展为 8 位
                    wstrb_mask = {{8{vif.wstrb[3]}}, {8{vif.wstrb[2]}}, {8{vif.wstrb[1]}}, {8{vif.wstrb[0]}}};

                    // 获取旧数据（如果不存在则默认为0）
                    old_data = mem_model.exists(addr_to_store) ? mem_model[addr_to_store] : 32'h0;

                    // 混合数据：(新数据 & 掩码) | (旧数据 & ~掩码)
                    new_combined_data = (vif.wdata & wstrb_mask) | (old_data & ~wstrb_mask);

                    // 更新存储
                    mem_model[addr_to_store] = new_combined_data;

                    `uvm_info("SLV_MEM", $sformatf("WSTRB Write: Addr='h%0h, Data='h%0h, Mask='b%04b, Final='h%0h", 
                    addr_to_store, vif.wdata, vif.wstrb, new_combined_data), UVM_HIGH)

                    fork
                        begin
                            automatic logic [31:0] current_awaddr = saved_addr;
                            `uvm_info(get_type_name(), $sformatf("Slave: B response fork started, will delay 2 cycles then set bvalid, addr=0x%0h", current_awaddr), UVM_LOW)
                            repeat(2) @(posedge vif.clk);   // 模拟从机延迟
                                                            // 这个等待可能会导致slave无法检测到master发送的新的握手信号，从而漏掉事务
                                                            // 解决方法：使用fork-join_none结构
                            vif.bvalid <= 1'b1;
                            vif.bresp  <= (current_awaddr > addr_limit) ? RESP_DECERR : RESP_OKAY;
                            `uvm_info(get_type_name(), $sformatf("Slave: bvalid set, bresp=0x%0h, waiting for bready...", vif.bresp), UVM_LOW)
                        
                            // 响应握手成功：Master 已收到 (bready=1)，Slave 撤回 bvalid
                            do begin
                                @(posedge vif.clk);
                            end while (!vif.bready);

                            vif.bvalid <= 1'b0;
                            `uvm_info(get_type_name(), $sformatf("Slave: bready seen, bvalid cleared, write response complete"), UVM_LOW)
                        end
                    join_none
                end

                if (vif.arvalid && vif.arready && !vif.rvalid) begin
                    `uvm_info("SLV_DRV", $sformatf("Read request received at addr 'h%0h", vif.araddr), UVM_LOW)

                    fork
                        begin
                            automatic logic [31:0] current_araddr = vif.araddr;
                            repeat(2) @(posedge vif.clk);
                            vif.rvalid <= 1'b1;
                            vif.rresp  <= (current_araddr > addr_limit) ? RESP_DECERR : RESP_OKAY;                
                            // --- 动态读取存储模型 ---
                            if (mem_model.exists(current_araddr)) begin
                                vif.rdata <= mem_model[current_araddr]; // 读出之前写过的值
                            end else begin
                                vif.rdata <= 32'hDEAD_BEEF; // 如果没写过，返回一个特征值表示“未定义”
                            end

                            do begin
                                @(posedge vif.clk);
                            end while(!vif.rready);

                            vif.rvalid <= 1'b0;
                        end
                    join_none
                end
            end
        end
    endtask
endclass

`endif // AXIL_SLAVE_DRIVER_SV