`ifndef AXIL_SLAVE_DRIVER_SV
`define AXIL_SLAVE_DRIVER_SV

`include "uvm_macros.svh"

class axil_register_slave_driver extends axil_register_base_driver;
    `uvm_component_utils(axil_register_slave_driver)

    // Slave特有的响应配置
    typedef enum {
    RESP_OKAY    = 2'b00,  // 正常访问 OK (Normal Access)
    RESP_EXOKAY  = 2'b01,  // 独占访问 OK (Exclusive Access OK) - 用于原子操作
    RESP_SLVERR  = 2'b10,  // 从设备错误 (Slave Error) - Slave内部错误
    RESP_DECERR  = 2'b11   // 解码错误 (Decode Error) - 地址无效/未映射
} resp_type_t;
    
    resp_type_t default_resp = RESP_OKAY;

    int write_response_delay = 0;
    int read_response_delay = 1;  // 读通常有至少1周期延迟

    // 寄存器模型（模拟Slave的存储）
    logic [DATA_W-1:0] register_map [logic [ADDR_W-1:0]];
    
    function new(string name = "axil_slave_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 获取Slave特有配置
        if (uvm_config_db#(resp_type_t)::get(this, "", "default_resp", default_resp)) begin
            `uvm_info(get_type_name(), $sformatf("Default response set to %0d", default_resp), UVM_LOW)
        end
    endfunction

    // 启动Slave响应任务
    extern task run_phase(uvm_phase phase);

    extern task drive_transaction(axil_register_transaction tr);

    // Slave特有方法：响应请求（注意：不是驱动transaction！）
    extern task handle_write_request();
    extern task handle_read_request();

    // 处理写入的辅助函数
    extern function void process_write(
        input logic [ADDR_W-1:0] addr,
        input logic [DATA_W-1:0] data,
        input logic [STRB_W-1:0] strb
    );
    
    // 处理读取的辅助函数
    extern function void process_read(
        input  logic [ADDR_W-1:0] addr,
        output logic [DATA_W-1:0] data,
        output logic [1:0]        resp
    );
    
    // 复位检查
    extern task wait_for_reset_release();
    
    
endclass

task axil_register_slave_driver::wait_for_reset_release();
    if (vif.rst === 1'b1) begin
        `uvm_info(get_type_name(), "Waiting for reset deassertion", UVM_MEDIUM)
        wait(vif.rst === 1'b0);
        @(posedge vif.clk);
    end
endtask

task axil_register_slave_driver::run_phase(uvm_phase phase);
    // 不在slave_driver中调用super.run_phase()！因为Slave不需要从sequence获取transaction
    
    `uvm_info(get_type_name(), "Slave driver run_phase started", UVM_LOW)
    
    // Slave不主动获取transaction，而是响应interface上的信号
    fork
        handle_write_request();  // 监听并响应写请求
        handle_read_request();   // 监听并响应读请求
    join
endtask

task axil_register_slave_driver::drive_transaction(axil_register_transaction tr);
    // Slave driver通常不需要这个任务，因为Slave不主动驱动transaction
    // 但UVM框架要求实现纯虚函数，所以可以留空或添加警告
    
    `uvm_info(get_type_name(), 
                 "Slave driver does not actively drive transactions", 
                 UVM_LOW)
endtask

task axil_register_slave_driver::handle_write_request();
    forever begin
        logic [ADDR_W-1:0] awaddr;
        logic [2:0]        awprot;
        logic [DATA_W-1:0] wdata;
        logic [STRB_W-1:0] wstrb;

        // 等待AW有效信号
        wait(vif.awvalid === 1'b1);
        vif.awready <= 1'b1; // 表示该模块准备好接收地址

        @(posedge vif.clk iff vif.awvalid && vif.awready);
        awaddr = vif.awaddr;
        awprot = vif.awprot;
        vif.awready <= 1'b0; // 地址接收完毕，撤销ready信号

        // 等待W有效信号
        wait(vif.wvalid === 1'b1);
        vif.wready <= 1'b1; // 表示该模块准备好接收数据

        @(posedge vif.clk iff vif.wvalid && vif.wready);
        wdata = vif.wdata;
        wstrb = vif.wstrb;
        vif.wready <= 1'b0; // 数据接收完毕，撤销ready信号

        `uvm_info(get_type_name(),
                 $sformatf("Received WRITE: addr=0x%0h, data=0x%0h, strb=0x%0h",
                          awaddr, wdata, wstrb),
                 UVM_HIGH)

        // 处理写入延迟
        repeat(write_response_delay) @(posedge vif.clk);

        // 模拟写入寄存器
        process_write(awaddr, wdata, wstrb);

        // 发送写响应
        vif.bresp  <= default_resp;
        vif.bvalid <= 1'b1;

        wait(vif.bready === 1'b1); // 等待主设备准备好接收响应
        @(posedge vif.clk);
        vif.bvalid <= 1'b0; // 响应发送完毕，撤销valid信号
    end
endtask

task axil_register_slave_driver::handle_read_request();
    forever begin
        logic [ADDR_W-1:0] araddr;
        logic [2:0]        arprot;

        logic [DATA_W-1:0] rdata;
        logic [1:0]        rresp;

        // 等待AR有效信号
        wait(vif.arvalid === 1'b1);
        vif.arready <= 1'b1; // 表示该模块准备好接收地址

        @(posedge vif.clk iff vif.arvalid && vif.arready);
        araddr = vif.araddr;
        arprot = vif.arprot;
        vif.arready <= 1'b0; // 地址接收完毕，撤销ready信号

        `uvm_info(get_type_name(),
                 $sformatf("Received READ: addr=0x%0h", araddr),
                 UVM_HIGH)

        // 处理读取延迟
        repeat(read_response_delay) @(posedge vif.clk);

        // 处理读取请求（获取数据）
        process_read(araddr, rdata, rresp);

        // 发送读响应
        vif.rdata  <= rdata;
        vif.rresp  <= rresp;
        vif.rvalid <= 1'b1;

        wait(vif.rready === 1'b1); // 等待主设备准备好接收数据
        @(posedge vif.clk);
        vif.rvalid <= 1'b0; // 数据发送完毕，撤销valid信号

        `uvm_info(get_type_name(),
                 $sformatf("Sent READ response: addr=0x%0h, data=0x%0h, resp=%0d",
                          araddr, rdata, rresp),
                 UVM_HIGH)
    end
endtask

function void axil_register_slave_driver::process_write(
    input logic [ADDR_W-1:0] addr,
    input logic [DATA_W-1:0] data,
    input logic [STRB_W-1:0] strb
);
    // 如果是首次访问该地址，先初始化为0
    if (!register_map.exists(addr)) begin
        register_map[addr] = '0;
    end

    // 根据写掩码更新寄存器
    for (int i = 0; i < STRB_W; i++) begin
        if (strb[i]) begin
            register_map[addr][i*8 +: 8] = data[i*8 +: 8];
        end
    end

    `uvm_info(get_type_name(),
             $sformatf("Register at addr=0x%0h updated to 0x%0h",
                      addr, register_map[addr]),
             UVM_HIGH)
endfunction

function void axil_register_slave_driver::process_read(
    input  logic [ADDR_W-1:0] addr,
    output logic [DATA_W-1:0] data,
    output logic [1:0]        resp
);
    // 检查地址是否有效
    if (register_map.exists(addr)) begin
        data = register_map[addr];
        resp = RESP_OKAY;
    end else begin
        // 地址无效：返回0和错误响应
        data = '0;
        resp = RESP_DECERR;  // 地址解码错误
    end
endfunction

`endif // AXIL_REGISTER_SLAVE_DRIVER_SV