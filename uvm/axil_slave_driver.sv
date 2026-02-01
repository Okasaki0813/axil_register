`ifndef AXIL_SLAVE_DRIVER_SV
`define AXIL_SLAVE_DRIVER_SV

`include "uvm_macros.svh"

class axil_slave_driver extends axil_register_driver;
    `uvm_component_utils(axil_slave_driver)
    virtual taxi_axil_if vif; // 建议不要在定义时带 modport，在 connect 时指定即可

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
    endfunction
    
    // 声明关联数组作为 Memory Model
    // 键是地址，值是数据
    bit [31:0] mem_model [bit [31:0]];

    virtual task run_phase(uvm_phase phase);
        bit aw_done = 1'b0; // 写地址通道握手标志位
        bit w_done  = 1'b0; // 写数据通道握手标志位
        logic [31:0] saved_addr; // 用于暂存awaddr，防止2个时钟周期后vif.awaddr发生变化

        // 初始化：Slave 默认拉高 Ready
        vif.awready <= 1'b0;
        vif.wready  <= 1'b0;
        vif.bvalid  <= 1'b0;
        vif.arready <= 1'b0;
        vif.rvalid  <= 1'b0;

        forever begin
            @(posedge vif.clk);
            if (vif.rst) begin
                vif.bvalid  <= 1'b0;
                vif.awready <= 1'b0;
                vif.wready  <= 1'b0;
                vif.rvalid  <= 1'b0;
                aw_done     <= 1'b0;
                w_done      <= 1'b0;
            end else begin
                // 默认保持 Ready 为 1 (模拟理想从机)
                vif.awready <= 1'b1;
                vif.wready  <= 1'b1;
                vif.arready <= 1'b1;

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
                end

                if (vif.wvalid && vif.wready)
                    w_done = 1'b1;

                // 核心逻辑：地址和数据都握手成功 (Valid & Ready 同时为 1)
                // if (vif.awvalid && vif.awready && vif.wvalid && vif.wready) begin   // 不能这么写，因为写地址和写数据很难在同一个时钟节拍内同时完成握手
                                                                                    // 解决方案：解耦写地址通道和写数据通道的握手成功信号        
                // `uvm_info("SLV_DRV", $sformatf("aw_done = 'b%0b, w_done = 'b%0b, vif.bvalid = 'b%0b", aw_done, w_done, vif.bvalid), UVM_HIGH)
                if (aw_done && w_done && !vif.bvalid) begin // 加上!bvalid是为了保证slave的响应发给master后再处理下一个事务
                    // 暂存当前事务的数据，防止被下一拍覆盖
                    logic [31:0] addr_to_store = saved_addr;
                    logic [31:0] data_to_store = vif.wdata; // 假设数据通道此时稳定
                    logic [31:0] wstrb_mask;    // 32位掩码
                    logic [31:0] old_data;      // 原有数据
                    logic [31:0] new_combined_data;

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
                            repeat(2) @(posedge vif.clk);   // 模拟从机延迟
                                                            // 这个等待可能会导致slave无法检测到master发送的新的握手信号，从而漏掉事务
                                                            // 解决方法：使用fork-join_none结构
                            vif.bvalid <= 1'b1;
                            vif.bresp  <= (current_awaddr > 32'h3FFF) ? 2'b10 : 2'b00;
                        
                            // 响应握手成功：Master 已收到 (bready=1)，Slave 撤回 bvalid
                            do begin
                                @(posedge vif.clk);
                            end while (!vif.bready);

                            vif.bvalid <= 1'b0;
                        end
                    join_none
                end

                if (vif.arvalid && vif.arready && !vif.rvalid) begin;
                    `uvm_info("SLV_DRV", $sformatf("Read request received at addr 'h%0h", vif.araddr), UVM_LOW)

                    fork
                        begin
                            automatic logic [31:0] current_araddr = vif.araddr;
                            repeat(2) @(posedge vif.clk);
                            vif.rvalid <= 1'b1;
                            vif.rresp  <= (current_araddr > 32'h0000_3FFF) ? 2'b10 : 2'b00;                
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